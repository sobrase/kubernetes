#!/usr/bin/env bash
set -euo pipefail

CILIUM_VERSION=${CILIUM_VERSION:-"1.16.0"}
OFFLINE_DIR="${OFFLINE_DIR:-$(pwd)/offline}"
DOWNLOAD_DIR="$OFFLINE_DIR/cilium"

mkdir -p "$DOWNLOAD_DIR/images" "$DOWNLOAD_DIR"

# Download helm chart
CHART_URL="https://helm.cilium.io/cilium-${CILIUM_VERSION}.tgz"
echo "Downloading Cilium chart $CHART_URL"
curl -L "$CHART_URL" -o "$DOWNLOAD_DIR/cilium-${CILIUM_VERSION}.tgz"

# Extract chart to access templates
mkdir -p "$DOWNLOAD_DIR/cilium_chart"
tar -xzf "$DOWNLOAD_DIR/cilium-${CILIUM_VERSION}.tgz" -C "$DOWNLOAD_DIR"
mv "$DOWNLOAD_DIR/cilium" "$DOWNLOAD_DIR/cilium_chart" 2>/dev/null || true

# Render manifests and collect image list
helm template cilium "$DOWNLOAD_DIR/cilium_chart/cilium" --namespace kube-system --include-crds > "$DOWNLOAD_DIR/cilium-rendered.yaml"
grep -oE 'image:.*' "$DOWNLOAD_DIR/cilium-rendered.yaml" | awk '{print $2}' | sort -u > "$DOWNLOAD_DIR/images.txt"

# Pull and save images for offline use
while read -r img; do
  echo "Pulling $img"
  docker pull "$img"
  out_name=$(echo "$img" | tr '/:' '_').tar
  docker save "$img" -o "$DOWNLOAD_DIR/images/$out_name"
done < "$DOWNLOAD_DIR/images.txt"

echo "All assets downloaded in $DOWNLOAD_DIR"
