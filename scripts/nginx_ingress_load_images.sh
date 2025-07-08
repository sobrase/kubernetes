#!/usr/bin/env bash
set -euo pipefail

IMAGE_DIR="${IMAGE_DIR:-$(pwd)/nginx_ingress_offline/images}"

if [ ! -d "$IMAGE_DIR" ]; then
  echo "Image directory $IMAGE_DIR does not exist" >&2
  exit 1
fi

for tar in "$IMAGE_DIR"/*.tar; do
  [ -f "$tar" ] || continue
  echo "Loading $tar"
  docker load -i "$tar"
done

echo "Loaded images from $IMAGE_DIR"

