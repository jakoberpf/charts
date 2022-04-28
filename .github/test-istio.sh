#!/bin/bash
set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)

CHART_DIRS="$(git diff --find-renames --name-only "$(git rev-parse --abbrev-ref HEAD)" remotes/origin/main -- charts | grep '[cC]hart.yaml' | sed -e 's#/[Cc]hart.yaml##g')"

# test charts
for CHART_DIR in ${CHART_DIRS}; do
  CHART_NAME="$(yq '.name' ${CHART_DIR}/Chart.yaml)"

  cd ${CHART_DIR}

  # echo "Adding hosts entry"
  # sudo echo "127.0.0.1 ${CHART_NAME}.example.com"

  touch values-istio.yaml
  # yq -i '.persistence.enabled = true' values-istio.yaml
  yq -i '.ingress.enabled = true' values-istio.yaml
  yq -i '.ingress.hosts[0].host = "vaultwarden.example.com"' values-istio.yaml
  yq -i '.ingress.hosts[0].tls.secretName = "vaultwarden-credential"' values-istio.yaml
  yq -i '.ingress.istioGateway.enabled = true' values-istio.yaml
  yq -i '.ingress.certManager.enabled = false' values-istio.yaml
  yq -i '.ingress.certManager.issuerRef.name = "cloudflare-letsencrypt-prod"' values-istio.yaml

  helm upgrade ${CHART_NAME} . --namespace ${CHART_NAME} --values=values.yaml --values=values-istio.yaml

  echo "Setting up Istio Environment Variables"
  INGRESS_HOST="10.147.19.98"
  INGRESS_DNS="${CHART_NAME}.example.com"
  INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
  SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
  TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}')
  INGRESS_EXPECT_CODE=$(yq '.istio.code' test.yaml)

  echo "Running IstioGateway (HTTP) Test"
  CODE=$(curl --write-out %{http_code} --output /dev/null -s -I -HHost:${INGRESS_DNS} "http://${INGRESS_HOST}:${INGRESS_PORT}")
  if [[ "$CODE" -ne 200 ]] ; then
    echo "IstioGateway (HTTP): $CODE"
  else
    echo "IstioGateway (HTTP): OK"
  fi

  echo "Running IstioGateway (HTTPS) Test"
  CODE=$(curl --write-out %{http_code} --output /dev/null -s -I -HHost:${INGRESS_DNS} --resolve "${INGRESS_DNS}:${SECURE_INGRESS_PORT}:${INGRESS_HOST}" --cacert ${GIT_ROOT}/.tls/example.com.crt "https://${INGRESS_DNS}:${SECURE_INGRESS_PORT}")
  if [[ "$CODE" -ne 200 ]] ; then
    echo "IstioGateway (HTTPS): $CODE"
  else
    echo "IstioGateway (HTTPS): OK"
  fi

  echo "Running DNS (HTTP) Test"
  CODE=$(curl --write-out %{http_code} --output /dev/null -s -I "http://${INGRESS_DNS}:${INGRESS_PORT}")
  if [[ "$CODE" -ne 200 ]] ; then
    echo "DNS (HTTP): $CODE"
  else
    echo "DNS (HTTP): OK"
  fi

  echo "Running DNS (HTTPS) Test"
  CODE=$(curl --write-out %{http_code} --output /dev/null -s -I -HHost:${INGRESS_DNS} --resolve "${INGRESS_DNS}:${SECURE_INGRESS_PORT}:${INGRESS_HOST}" --cacert ${GIT_ROOT}/.tls/example.com.crt "https://${INGRESS_DNS}:${SECURE_INGRESS_PORT}")
  if [[ "$CODE" -ne 200 ]] ; then
    echo "DNS (HTTPS): $CODE"
  else
    echo "DNS (HTTPS): OK"
  fi

  cd ${GIT_ROOT}
done
