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

  KEY_URL="https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION%%.*}/deb/Release.key"
  REPO="deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION%%.*}/deb/ /"

  if ! curl -fsSL "$KEY_URL" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg; then
    echo "Primary key download failed, falling back to apt.kubernetes.io"
    curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" \
      | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
    REPO="deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main"
  fi

  echo "$REPO" | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
  sudo apt-get update
fi

# Download kube packages
PACKAGES=(kubeadm kubelet kubectl)
for pkg in "${PACKAGES[@]}"; do
  PKG_VERSION=$(apt-cache madison "$pkg" \
    | awk -v ver="$KUBE_VERSION" '$3 ~ "^" ver"-" {print $3; exit}')
  if [ -z "$PKG_VERSION" ]; then
    echo "Package $pkg version $KUBE_VERSION not found" >&2
    exit 1
  fi
  apt-get download "$pkg=$PKG_VERSION"
  mv "$pkg"_*".deb" "$DOWNLOAD_DIR/packages/"
done

# List required container images
IMAGES=$(kubeadm config images list --kubernetes-version "$KUBE_VERSION" | tr -d '\r')

for img in $IMAGES; do
  docker pull "$img"
  name=$(echo "$img" | tr '/:' '_')
  docker save "$img" | gzip -c > "$DOWNLOAD_DIR/images/${name}.tar.gz"
done

echo "Artifacts stored in $DOWNLOAD_DIR"
