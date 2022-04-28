#!/bin/bash
set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)

CHART_DIRS="$(git diff --find-renames --name-only "$(git rev-parse --abbrev-ref HEAD)" remotes/origin/main -- charts | grep '[cC]hart.yaml' | sed -e 's#/[Cc]hart.yaml##g')"

# generate certificates
for CHART_DIR in ${CHART_DIRS}; do
  CHART_NAME="$(yq '.name' ${CHART_DIR}/Chart.yaml)"
  
  cd ${CHART_DIR}
  
  SECRETS=( $(yq e -o=j -I=0 '.secrets[]' test.yaml) )
  
  for secret in "${SECRETS[@]}"; do
    secretname=( $(echo "${secret}" | yq e '.name' - ) )
    data=( $(echo "${secret}" | yq e -o=j -I=0 ".data" - ) )
    datafields=( $(echo "${data}" | yq "keys" - | tr '"' ' ' | tr '-' ' ' ) )
    secretdata=""
    for field in "${datafields[@]}"; do
      fieldkey=${field}
      fieldvalue=( $(echo "${data}" | yq ".${field}" - ) )
      secretdata="${secretdata} --from-literal=${fieldkey}=${fieldvalue}"
    done

    if [ ! "$(kubectl get namespaces -o json | jq -r ".items[].metadata.name | select (. == \"${CHART_NAME}\")")" == "${CHART_NAME}" ]; then
      kubectl create namespace "${CHART_NAME}"
    fi

    if [ ! "$(kubectl get -n "${CHART_NAME}" secrets -o json | jq -r ".items[].metadata.name | select (. == \"${secretname}\")")" == "${secretname}" ]; then
      kubectl create -n "${CHART_NAME}" secret generic $secretname $secretdata
    else
      kubectl delete -n "${CHART_NAME}" secret $secretname
      kubectl create -n "${CHART_NAME}" secret generic $secretname $secretdata
    fi

  done

  cd ${GIT_ROOT}
done
