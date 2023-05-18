#!/usr/bin/env bash

GIT_ROOT=$(git rev-parse --show-toplevel)

# Environment variables -- Standart
TEST_NAMESPACE="zerotier-controller"
# Environment variables -- Custom
TEST_HOST="zerotier.example.com"
TEST_UI="http://localhost"
TEST_API="http://localhost/api"

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
    # Wait for Istio to be ready
    while ! curl -I --silent --fail http://localhost:15021/healthz/ready; do
        echo >&2 'Istio down, retrying in 1s...'
        sleep 1
    done
    # Create testing namespaces
    kubectl create namespace $TEST_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

    ## Use template script -- END

    # Deploy Zerotier controller
    kubectl create secret generic zerotier-admin-credentials --from-literal=username=admin --from-literal=password=admin -n $TEST_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    helm upgrade --install zerotier-controller . --values test/values.yaml -n $TEST_NAMESPACE
    # Wait for Zerotier controller to be ready
    while ! curl -I --silent --fail --header "Host: $TEST_HOST" $TEST_UI/app/; do
        echo >&2 'Zerotier Controller down, retrying in 1s...'
        ((c++)) && ((c==10)) && exit 0
        sleep 1
    done
}

@test "should get a redirect to controller ui" {
    run bash -c "curl -s --header 'Host: $TEST_HOST' $TEST_UI"
    assert_output --partial 'Found. Redirecting to /app'
}

@test "should be able to curl controller ui" {
    run bash -c "curl -s --header 'Host: $TEST_HOST' $TEST_UI/app/"
    assert_output --partial '<meta name="description" content="ZeroUI"/>'
}

@test "should be able to curl controller api for networks and get an authentication error" {
    run bash -c "curl -s --header 'Host: $TEST_HOST' $TEST_API/network"
    assert_output --partial '{"error":"Specify token"}'
}

# teardown_file() {
#     kind delete cluster --name zerotier-gateway
# }
