#!/bin/bash
set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)
CHART_DIRS="$(git diff --find-renames --name-only "$(git rev-parse --abbrev-ref HEAD)" remotes/origin/main -- charts | grep '[cC]hart.yaml' | sed -e 's#/[Cc]hart.yaml##g')"
KUBEVAL_VERSION="v0.16.1"
SCHEMA_LOCATION="https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/"

# install kubeval
curl --silent --show-error --fail --location --output /tmp/kubeval.tar.gz https://github.com/instrumenta/kubeval/releases/download/"${KUBEVAL_VERSION}"/kubeval-linux-amd64.tar.gz
tar -xf /tmp/kubeval.tar.gz kubeval

git submodule init charts/teleport/clone

# validate charts
for CHART_DIR in ${CHART_DIRS}; do
  cd "${CHART_DIR}"
  helm dependency build
  helm template . | ${GIT_ROOT}/kubeval --strict --ignore-missing-schemas --kubernetes-version "${KUBERNETES_VERSION#v}" --schema-location "${SCHEMA_LOCATION}"
  cd "${GIT_ROOT}"
done
