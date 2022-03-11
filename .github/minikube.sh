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
  name: example-istiocontrolplane
spec:
  hub: docker.io/querycapistio
  profile: demo
EOF

# deploy charts
for CHART_DIR in ${CHART_DIRS}; do
  helm install try "${CHART_DIR}"
done
