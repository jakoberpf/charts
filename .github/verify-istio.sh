#!/bin/bash
set -euo pipefail

CHART_DIRS="$(git diff --find-renames --name-only "$(git rev-parse --abbrev-ref HEAD)" remotes/origin/main -- charts | grep '[cC]hart.yaml' | sed -e 's#/[Cc]hart.yaml##g')"

# test charts
for CHART_DIR in ${CHART_DIRS}; do
  CHART_NAME="$(yq '.name' ${CHART_DIR}/Chart.yaml)"

  sudo echo "127.0.0.1 ${CHART_NAME}.example.com" | sudo tee -a /etc/hosts

  # yq -i '.a.b[0].c = "cool"' file.yaml

  INGRESS_HOST="$(minikube ip)"
  INGRESS_DNS="${CHART_NAME}.example.com"

  INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
  SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
  TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}')

  curl -s -I -HHost:${INGRESS_DNS} "http://${INGRESS_HOST}:${INGRESS_PORT}"

  CODE=$(curl --write-out %{http_code} --output /dev/null -s -I -HHost:${INGRESS_DNS} "http://${INGRESS_HOST}:${INGRESS_PORT}")

  if [[ "$CODE" -ne 200 ]] ; then
    echo "IstioGateway (HTTP): $CODE"
  else
    echo "IstioGateway (HTTP): OK"
  fi

  CODE=$(curl --write-out %{http_code} --output /dev/null -s -I -HHost:${INGRESS_DNS} --resolve "${INGRESS_DNS}:${SECURE_INGRESS_PORT}:${INGRESS_HOST}" --cacert example.com.crt "https://${INGRESS_DNS}:${SECURE_INGRESS_PORT}/status/200")

  if [[ "$CODE" -ne 200 ]] ; then
    echo "IstioGateway (HTTPS): $CODE"
  else
    echo "IstioGateway (HTTPS): OK"
  fi

  CODE=$(curl --write-out %{http_code} --output /dev/null -s -I "http://${INGRESS_DNS}:${INGRESS_PORT}")

  if [[ "$CODE" -ne 200 ]] ; then
    echo "DNS (HTTP): $CODE"
  else
    echo "DNS (HTTP): OK"
  fi

  CODE=$(curl --write-out %{http_code} --output /dev/null -s -I -HHost:${INGRESS_DNS} --resolve "${INGRESS_DNS}:${SECURE_INGRESS_PORT}:${INGRESS_HOST}" --cacert example.com.crt "https://${INGRESS_DNS}:${SECURE_INGRESS_PORT}/status/200")

  if [[ "$CODE" -ne 200 ]] ; then
    echo "DNS (HTTPS): $CODE"
  else
    echo "DNS (HTTPS): OK"
  fi
done
