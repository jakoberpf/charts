#!/bin/bash
set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)

CHART_DIRS="$(git diff --find-renames --name-only "$(git rev-parse --abbrev-ref HEAD)" remotes/origin/main -- charts | grep '[cC]hart.yaml' | sed -e 's#/[Cc]hart.yaml##g')"

# generate certificate authority
if [[ ! -f ".tls/example.com.key" || ! -f ".tls/example.com.crt" ]]; then
  mkdir -p .tls && cd .tls
  openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
  cd ${GIT_ROOT}
fi

# generate certificates
for CHART_DIR in ${CHART_DIRS}; do
  CHART_NAME="$(yq '.name' ${CHART_DIR}/Chart.yaml)"
  mkdir -p ${CHART_DIR}/.tls && cd ${CHART_DIR}/.tls
  if [[ ! -f "${CHART_NAME}.example.com.csr" || ! -f "${CHART_NAME}.example.com.key" || ! -f "${CHART_NAME}.example.com.crt" ]]; then
    openssl req -out "${CHART_NAME}.example.com.csr" -newkey rsa:2048 -nodes -keyout "${CHART_NAME}.example.com.key" -subj "/CN=${CHART_NAME}.example.com/O=${CHART_NAME} organization"
    openssl x509 -req -sha256 -days 365 -CA ${GIT_ROOT}/.tls/example.com.crt -CAkey ${GIT_ROOT}/.tls/example.com.key -set_serial 0 -in "${CHART_NAME}.example.com.csr" -out "${CHART_NAME}.example.com.crt"
  fi
  if [ ! "$(kubectl get -n istio-system secrets -o json | jq -r ".items[].metadata.name | select (. == \"${CHART_NAME}-credential\")")" == "${CHART_NAME}-credential" ]; then
    kubectl create -n istio-system secret tls "${CHART_NAME}-credential" --key="${CHART_NAME}.example.com.key" --cert="${CHART_NAME}.example.com.crt"
  else
    kubectl delete -n istio-system secret "${CHART_NAME}-credential"
    kubectl create -n istio-system secret tls "${CHART_NAME}-credential" --key="${CHART_NAME}.example.com.key" --cert="${CHART_NAME}.example.com.crt"
  fi
  cd ${GIT_ROOT}
done
