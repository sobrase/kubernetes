#!/usr/bin/env bash
set -euo pipefail

CILIUM_VERSION=${CILIUM_VERSION:-"1.14.2"}
DOWNLOAD_DIR=${DOWNLOAD_DIR:-"$(pwd)/cilium_offline"}

mkdir -p "$DOWNLOAD_DIR"

# Download helm chart
CHART_URL="https://github.com/cilium/cilium/releases/download/v${CILIUM_VERSION}/cilium-${CILIUM_VERSION}.tgz"
echo "Downloading Cilium chart $CHART_URL"
curl -L "$CHART_URL" -o "$DOWNLOAD_DIR/cilium-${CILIUM_VERSION}.tgz"

# Extract chart to access templates
mkdir -p "$DOWNLOAD_DIR/chart"
tar -xzf "$DOWNLOAD_DIR/cilium-${CILIUM_VERSION}.tgz" -C "$DOWNLOAD_DIR/chart"

# Render manifests and collect image list
helm template cilium "$DOWNLOAD_DIR/chart/cilium" --version "$CILIUM_VERSION" --namespace kube-system --include-crds > "$DOWNLOAD_DIR/cilium-rendered.yaml"
grep -oE 'image:.*' "$DOWNLOAD_DIR/cilium-rendered.yaml" | awk '{print $2}' | sort -u > "$DOWNLOAD_DIR/images.txt"

# Pull and save images for offline use
while read -r img; do
  echo "Pulling $img"
  docker pull "$img"
  out_name=$(echo "$img" | tr '/:' '_').tar
  docker save "$img" -o "$DOWNLOAD_DIR/$out_name"
done < "$DOWNLOAD_DIR/images.txt"

echo "All assets downloaded in $DOWNLOAD_DIR"
