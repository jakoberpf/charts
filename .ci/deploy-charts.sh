#!/bin/bash
set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)
CHART_DIRS="$(git diff --find-renames --name-only "$(git rev-parse --abbrev-ref HEAD)" remotes/origin/main -- charts | grep '[cC]hart.yaml' | sed -e 's#/[Cc]hart.yaml##g')"

# deploy charts
for CHART_DIR in ${CHART_DIRS}; do
  CHART_NAME="$(yq '.name' ${CHART_DIR}/Chart.yaml)"
  cd ${CHART_DIR}
  if [ ! "$(kubectl get namespaces -o json | jq -r ".items[].metadata.name | select (. == \"${CHART_NAME}\")")" == "${CHART_NAME}" ]; then
    kubectl create namespace "${CHART_NAME}"
  fi

  if [ ! "$(kubectl get namespaces -o json | jq -r ".items[].metadata | select (.name == \"${CHART_NAME}\") | .labels.\"istio-injection\"")" == "enabled" ]; then
    kubectl label namespace "${CHART_NAME}" istio-injection=enabled
  fi
  helm dependency build
  helm upgrade "${CHART_NAME}" . --namespace "${CHART_NAME}" --install
  cd ${GIT_ROOT}
  .github/wait-until-pods-ready.sh 30 1
done