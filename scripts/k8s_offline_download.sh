#!/usr/bin/env bash
set -euo pipefail

KUBE_VERSION="${KUBE_VERSION:-1.32.0}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$(pwd)/k8s_offline}"

mkdir -p "$DOWNLOAD_DIR/images" "$DOWNLOAD_DIR/packages"

# Download kube packages
PACKAGES=("kubeadm=${KUBE_VERSION}-00" "kubelet=${KUBE_VERSION}-00" "kubectl=${KUBE_VERSION}-00")
for pkg in "${PACKAGES[@]}"; do
  apt-get download "$pkg"
  mv *.deb "$DOWNLOAD_DIR/packages/"
done

# List required container images
IMAGES=$(kubeadm config images list --kubernetes-version "$KUBE_VERSION" | tr -d '\r')

for img in $IMAGES; do
  docker pull "$img"
  name=$(echo "$img" | tr '/:' '_')
  docker save "$img" | gzip -c > "$DOWNLOAD_DIR/images/${name}.tar.gz"
done

echo "Artifacts stored in $DOWNLOAD_DIR"
