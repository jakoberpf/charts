#!/usr/bin/env bash

GIT_ROOT=$(git rev-parse --show-toplevel)

# Environment variables -- Standart
TEST_NAMESPACE="postgresql"
# Environment variables -- Custom
TEST_HOST="postgresql.example.com"
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

    # Deploy PostgreSQL
    helm dependency build
    helm upgrade --install postgresql $GIT_ROOT/charts/postgresql --values $GIT_ROOT/charts/postgresql/test/values.yaml -n $TEST_NAMESPACE
    # Wait for PGAdmin to be ready
    while ! curl -I --silent --fail --header "Host: $TEST_HOST" $TEST_UI; do
        echo >&2 'PGAdmin down, retrying in 1s...'
        ((c++)) && ((c==60)) && exit 0
        sleep 1
    done
}

@test "should get a the PostgreSQL Admin Web UI" {
    run bash -c "curl -s --header 'Host: $TEST_HOST' $TEST_UI"
    assert_output --partial 'Vaultwarden Web Vault'
}

@test "should be able to reach PostgreSQL Endpoint" {
    run bash -c "psql ..."
    assert_output --partial '...'
}

# teardown_file() {
#     kind delete cluster --name zerotier-gateway
# }
