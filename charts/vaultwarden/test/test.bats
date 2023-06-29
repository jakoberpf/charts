#!/usr/bin/env bash

GIT_ROOT=$(git rev-parse --show-toplevel)

# Environment variables -- Standart
TEST_NAMESPACE="vaultwarden"
# Environment variables -- Custom
TEST_HOST="vaultwarden.example.com"
TEST_UI="http://localhost"

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

    # Generate secrets
    argon2bash64=$(echo -n "super-secret-password" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4)
    kubectl create secret generic vaultwarden-token -n $TEST_NAMESPACE --from-literal=token=$argon2bash64 --dry-run=client -o yaml | kubectl apply -f -
    kubectl create secret generic vaultwarden-smtp -n $TEST_NAMESPACE --from-literal=user=vaultwarden@example.com --from-literal=password=$(openssl rand 32 | base64) --dry-run=client -o yaml | kubectl apply -f -

    # Deploy Vaultwarden
    helm upgrade --install vaultwarden $GIT_ROOT/charts/vaultwarden --values $GIT_ROOT/charts/vaultwarden/test/values.yaml -n $TEST_NAMESPACE
    # Wait for Vaultwarden to be ready
    while ! curl -I --silent --fail --header "Host: $TEST_HOST" $TEST_UI; do
        echo >&2 'Vaultwarden down, retrying in 1s...'
        ((c++)) && ((c==60)) && exit 0
        sleep 1
    done
}

@test "should get a the vaultwarden web ui" {
    run bash -c "curl -s --header 'Host: $TEST_HOST' $TEST_UI"
    assert_output --partial 'Vaultwarden Web Vault'
}

# teardown_file() {
#     kind delete cluster --name zerotier-gateway
# }
