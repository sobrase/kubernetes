#!/usr/bin/env bash
set -euo pipefail

KUBE_VERSION="${KUBE_VERSION:-1.32.0}"
OFFLINE_DIR="${OFFLINE_DIR:-$(pwd)/offline}"
DOWNLOAD_DIR="$OFFLINE_DIR/k8s"

mkdir -p "$DOWNLOAD_DIR/images" "$DOWNLOAD_DIR/packages"

# Ensure Kubernetes apt repository is available
if ! apt-cache show kubeadm >/dev/null 2>&1; then
  echo "Kubernetes apt repository missing. Adding default repository."
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl gpg
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION%%.*}/deb/Release.key" \
    | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION%%.*}/deb/ /" \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
  sudo apt-get update
fi

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
