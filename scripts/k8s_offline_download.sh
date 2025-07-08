#!/usr/bin/env bash
set -euo pipefail

# Kubernetes binaries and images
K8S_VERSION="${K8S_VERSION:-v1.32.0}"
ARCH="${ARCH:-amd64}"
OFFLINE_DIR="${OFFLINE_DIR:-$(pwd)/offline}"
DOWNLOAD_DIR="$OFFLINE_DIR/k8s"

mkdir -p "$DOWNLOAD_DIR/bin" "$DOWNLOAD_DIR/images"

# Download kubeadm, kubelet and kubectl binaries
for b in kubeadm kubelet kubectl; do
  url="https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/${ARCH}/${b}"
  echo "Downloading $url"
  curl -L "$url" -o "$DOWNLOAD_DIR/bin/${b}"
  chmod +x "$DOWNLOAD_DIR/bin/${b}"
done

# List required container images using downloaded kubeadm
IMAGES="$($DOWNLOAD_DIR/bin/kubeadm config images list --kubernetes-version="${K8S_VERSION}" | tr -d '\r')"

for img in $IMAGES; do
  docker pull "$img"
  name=$(echo "$img" | tr '/:' '_')
  docker save "$img" | gzip -c > "$DOWNLOAD_DIR/images/${name}.tar.gz"
done

echo "Artifacts stored in $DOWNLOAD_DIR"
