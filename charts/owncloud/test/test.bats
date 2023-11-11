#!/usr/bin/env bash

GIT_ROOT=$(git rev-parse --show-toplevel)

# Environment variables -- Standart
TEST_NAMESPACE="owncloud"
# Environment variables -- Custom
TEST_HOST="owncloud.example.com"
TEST_UI="localhost"

setup() {
    load "$GIT_ROOT/test/helpers/bats-support/load"
    load "$GIT_ROOT/test/helpers/bats-assert/load"
    load "$GIT_ROOT/test/helpers/bats-file/load"
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR:$PATH"
}

setup_file() {

    ## Use template script -- START

    # Create KinD cluster
    if [[ "$(kind get clusters)" != *"charts"* ]]; then
        kind create cluster --config=$GIT_ROOT/test/kind.yaml
    fi
    # Install and setup Istio
    istioctl install -f $GIT_ROOT/test/istio.yaml -y
    kubectl apply -f $GIT_ROOT/test/istio-ingress-class.yaml
    # Wait for Istio to be ready
    while ! curl -I --silent --fail http://localhost:15021/healthz/ready; do
        echo >&2 'Istio down, retrying in 1s...'
        sleep 1
    done
    # Create testing namespaces
    kubectl create namespace $TEST_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

    ## Use template script -- END

    # helm repo add jetstack https://charts.jetstack.io
    # helm repo add emberstack https://emberstack.github.io/helm-charts
    # helm repo update

    helm upgrade --install \
        cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --set installCRDs=true

    helm upgrade --install \
        cert-reflector emberstack/reflector \
        --namespace cert-reflector \
        --create-namespace
    
    kubectl apply -f $GIT_ROOT/test/cert-manager-selfsinged.yaml

    kubectl get secret owncloud -n $TEST_NAMESPACE -o json | jq '.data."ca.crt"' | xargs | base64 --decode >> $GIT_ROOT/charts/owncloud/test/ca.crt

    # Deploy Owncloud
    helm upgrade --install owncloud $GIT_ROOT/charts/owncloud --values $GIT_ROOT/charts/owncloud/test/values.yaml -n $TEST_NAMESPACE
    # Wait for Owncloud to be ready
    # while ! curl -I --silent --fail --header "Host: $TEST_HOST" http://$TEST_UI; do
    #     echo >&2 'Owncloud down, retrying in 1s...'
    #     ((c++)) && ((c==60)) && exit 0
    #     sleep 1
    # done
    sleep 60
}

@test "should get a redirect to https on http port" {
    run bash -c "curl -s --header 'Host: $TEST_HOST' http://$TEST_UI"
    assert_output --partial '<a href="https://owncloud.example.com/">Permanent Redirect</a>'
}

@test "should be able to reach owncloud" {
    run bash -c "curl -s --insecure --header 'Host: $TEST_HOST' https://$TEST_UI"
    assert_output --partial '<a href="https://owncloud.example.com/">Permanent Redirect</a>'
}

# teardown_file() {
#     kind delete cluster --name zerotier-gateway
# }
