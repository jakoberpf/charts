#!/bin/bash
set -euo pipefail

CHART_DIRS="$(git diff --find-renames --name-only "$(git rev-parse --abbrev-ref HEAD)" remotes/origin/main -- charts | grep '[cC]hart.yaml' | sed -e 's#/[Cc]hart.yaml##g')"

# generate certificate authority
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt

# generate certificates
for CHART_DIR in ${CHART_DIRS}; do
  CHART_NAME="$(yq '.name' ${CHART_DIR}/Chart.yaml)"
  
  mkdir ${CHART_DIR}/.tls
  cd ${CHART_DIR} .tls

  openssl req -out "${CHART_NAME}.csr" -newkey rsa:2048 -nodes -keyout "${CHART_NAME}.key" -subj "/CN=${CHART_NAME}.example.com/O=${CHART_NAME} organization"
  openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in "${CHART_NAME}.csr" -out "${CHART_NAME}.crt"
  kubectl create -n istio-system secret tls "${CHART_NAME}-credentials" --key="${CHART_NAME}.key" --cert="${CHART_NAME}.crt"
done
