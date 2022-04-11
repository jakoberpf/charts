#!/bin/bash
set -euo pipefail

kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml

kubectl -n longhorn-system get svc