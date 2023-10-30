#!/usr/bin/env bash

GIT_ROOT=$(git rev-parse --show-toplevel)

# Environment variables -- Standart
TEST_NAMESPACE="cloudflared"

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

    # Deploy secrets
    kubectl create secret generic tunnel-credentials --from-file=credentials.json=$GIT_ROOT/test/tunnel-credentials.json -n cloudflared --dry-run=client -o yaml | kubectl apply -f -

    # Deploy Vaultwarden
    helm upgrade --install cloudflared $GIT_ROOT/charts/cloudflared --values $GIT_ROOT/charts/cloudflared/test/values.yaml -n $TEST_NAMESPACE
    # Wait for Vaultwarden to be ready
    while ! curl -I --silent --fail --header "Host: $TEST_HOST" $TEST_UI; do
        echo >&2 'Vaultwarden down, retrying in 1s...'
        ((c++)) && ((c==60)) && exit 0
        sleep 1
    done
}

@test "should get a the vaultwarden web ui" {
    run bash -c "curl -s https://kubernetes-charts-testing-local.erpf.de/"
    assert_output --partial 'Cloudflare Tunnel Connection'
    assert_output --partial 'Congrats! You created a tunnel!'
}

# teardown_file() {
#     kind delete cluster --name zerotier-gateway
# }
