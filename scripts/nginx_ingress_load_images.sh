#!/usr/bin/env bash
set -euo pipefail

OFFLINE_DIR="${OFFLINE_DIR:-/srv/k8s_offline}"
IMAGE_DIR="${IMAGE_DIR:-$OFFLINE_DIR/nginx_ingress/images}"

if [ ! -d "$IMAGE_DIR" ]; then
  echo "Image directory $IMAGE_DIR does not exist" >&2
  exit 1
fi

for tar in "$IMAGE_DIR"/*.tar; do
  [ -f "$tar" ] || continue
  echo "Loading $tar"
  crictl load "$tar"
done

echo "Loaded images from $IMAGE_DIR"

