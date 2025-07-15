#!/usr/bin/env bash
set -euo pipefail

CONTAINERD_VERSION="${CONTAINERD_VERSION:-1.6.32-1}"
OS_FLAVOR="${OS_FLAVOR:-debian}"
OS_VERSION="${OS_VERSION:-bullseye}"
ARCH="${ARCH:-amd64}"
OFFLINE_DIR="${OFFLINE_DIR:-$(pwd)/offline}"
DOWNLOAD_DIR="$OFFLINE_DIR/containerd"

mkdir -p "$DOWNLOAD_DIR/packages" "$DOWNLOAD_DIR/images"

REPO_BASE="https://download.docker.com/linux/${OS_FLAVOR}/dists/${OS_VERSION}/pool/stable/${ARCH}"
PACKAGE="containerd.io_${CONTAINERD_VERSION}_${ARCH}.deb"

echo "Downloading $PACKAGE from $REPO_BASE"
curl -L "$REPO_BASE/$PACKAGE" -o "$DOWNLOAD_DIR/packages/$PACKAGE"

IMAGES=(
  "registry.k8s.io/pause:3.9"
)

for img in "${IMAGES[@]}"; do
  echo "Pulling $img"
  docker pull "$img"
  out_name=$(echo "$img" | tr '/:' '_').tar
  docker save "$img" -o "$DOWNLOAD_DIR/images/$out_name"
done

echo "All containerd assets downloaded in $DOWNLOAD_DIR"
echo "Transfer image tarballs to $DOWNLOAD_DIR/images on target nodes and load with:"
echo "  sudo ctr -n k8s.io images import <image>.tar"
