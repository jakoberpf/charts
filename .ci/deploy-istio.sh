#!/usr/bin/env bash
set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)
cd $GIT_ROOT

ISTIO_VERSION="1.17.0"

istioctl operator init --tag=$ISTIO_VERSION

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
  profile: demo
  components:
    ingressGateways:
      - name: istio-ingressgateway
        k8s:
          service:
            type: NodePort
            ports:
              - name: status-port
                protocol: TCP
                port: 15021
                targetPort: 15021
              - name: http2
                protocol: TCP
                port: 80
                targetPort: 8080
                nodePort: 30080
              - name: https
                protocol: TCP
                port: 443
                targetPort: 8443
                nodePort: 30443
              - name: tcp
                protocol: TCP
                port: 31400
                targetPort: 31400
              - name: tls
                protocol: TCP
                port: 15443
                targetPort: 15443
EOF
