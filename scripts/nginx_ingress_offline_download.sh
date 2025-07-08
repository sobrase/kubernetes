#!/usr/bin/env bash
set -euo pipefail

NGINX_IC_VERSION="${NGINX_IC_VERSION:-4.0.1}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$(pwd)/nginx_ingress_offline}"

mkdir -p "$DOWNLOAD_DIR/manifests" "$DOWNLOAD_DIR/images"

BASE_URL="https://raw.githubusercontent.com/nginx/kubernetes-ingress/v${NGINX_IC_VERSION}"

FILES=(
  "deploy/crds.yaml"
  "deployments/common/ns-and-sa.yaml"
  "deployments/common/ingress-class.yaml"
  "deployments/common/nginx-config.yaml"
  "deployments/rbac/rbac.yaml"
  "deployments/daemon-set/nginx-ingress.yaml"
  "deployments/daemon-set/nginx-plus-ingress.yaml"
)

for file in "${FILES[@]}"; do
  echo "Downloading $file"
  curl -L "$BASE_URL/$file" -o "$DOWNLOAD_DIR/manifests/$(basename $file)"
done

IMAGES=$(grep -hoE 'image: *[^ ]+' "$DOWNLOAD_DIR"/manifests/*.yaml | awk '{print $2}' | sort -u)

for img in $IMAGES; do
  echo "Pulling $img"
  docker pull "$img"
  out_name=$(echo "$img" | tr '/:' '_').tar
  docker save "$img" -o "$DOWNLOAD_DIR/images/$out_name"
done

echo "All assets downloaded in $DOWNLOAD_DIR"
