#!/usr/bin/env bash
set -euo pipefail

CNI_VERSION="${CNI_VERSION:-v1.4.0}"
ARCH="${ARCH:-amd64}"
OFFLINE_DIR="${OFFLINE_DIR:-$(pwd)/offline}"
DOWNLOAD_DIR="$OFFLINE_DIR/cni"

mkdir -p "$DOWNLOAD_DIR"

URL="https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz"
echo "Downloading CNI plugins from $URL"
curl -L "$URL" -o "$DOWNLOAD_DIR/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz"

echo "CNI plugins saved in $DOWNLOAD_DIR"
