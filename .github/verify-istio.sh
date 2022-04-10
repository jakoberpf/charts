#!/bin/bash
set -euo pipefail

CHART_DIRS="$(git diff --find-renames --name-only "$(git rev-parse --abbrev-ref HEAD)" remotes/origin/main -- charts | grep '[cC]hart.yaml' | sed -e 's#/[Cc]hart.yaml##g')"

# test charts
for CHART_DIR in ${CHART_DIRS}; do
  CHART_NAME="$(yq '.name' ${CHART_DIR}/Chart.yaml)"
  helm install "${CHART_NAME}" "${CHART_DIR}"

  sudo echo "127.0.0.1 ${CHART_NAME}.example.com" | sudo tee -a /etc/hosts

  # yq -i '.a.b[0].c = "cool"' file.yaml
done
