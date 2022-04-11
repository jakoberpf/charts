#!/bin/bash
set -euo pipefail

CHART_DIRS="$(git diff --find-renames --name-only "$(git rev-parse --abbrev-ref HEAD)" remotes/origin/main -- charts | grep '[cC]hart.yaml' | sed -e 's#/[Cc]hart.yaml##g')"

# install istio
istioctl operator init --hub=docker.io/querycapistio --tag=1.13.1 # get version from https://github.com/querycap/istio

ISTIO_NAMESPACE=istio-system
if [ ! "$(kubectl get namespaces -o json | jq -r ".items[].metadata.name | select (. == \"$ISTIO_NAMESPACE\")")" == "$ISTIO_NAMESPACE" ]; then
    echo "Creating namespace $ISTIO_NAMESPACE"
    kubectl create namespace $ISTIO_NAMESPACE
else
    echo "Namespace $ISTIO_NAMESPACE exists, nothing to do"
fi

kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istiocontrolplane
spec:
  hub: docker.io/querycapistio
  profile: demo
  components:
    ingressGateways:
      - name: istio-ingressgateway
        k8s:
          service:
            type: NodePort
EOF

sleep 120

while [ "$(kubectl get pods -l=app='istio-operator' -n istio-system -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true" ]; do
   sleep 2
   echo "Waiting for Istio-Operator to be ready."
done

while [ "$(kubectl get pods -l=app='istio-ingressgateway' -n istio-system -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true" ]; do
   sleep 2
   echo "Waiting for Istio-IngressGateway to be ready."
done

kubectl get service -n istio-system

# deploy charts
for CHART_DIR in ${CHART_DIRS}; do
  CHART_NAME="$(yq '.name' ${CHART_DIR}/Chart.yaml)"
  helm install "${CHART_NAME}" "${CHART_DIR}"
done
