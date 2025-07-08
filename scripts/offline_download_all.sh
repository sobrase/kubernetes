#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFLINE_DIR="${OFFLINE_DIR:-$(pwd)/offline}"

export OFFLINE_DIR

"$SCRIPT_DIR/k8s_offline_download.sh"
"$SCRIPT_DIR/cni_offline_download.sh"
"$SCRIPT_DIR/crio_offline_download.sh"
"$SCRIPT_DIR/cilium_offline_download.sh"
"$SCRIPT_DIR/nginx_ingress_offline_download.sh"
"$SCRIPT_DIR/download_gateway_api.sh"

echo "All components downloaded under $OFFLINE_DIR"
