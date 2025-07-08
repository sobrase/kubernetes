#!/usr/bin/env bash
set -euo pipefail

CRIO_VERSION="${CRIO_VERSION:-1.32}"
OS_FLAVOR="${OS_FLAVOR:-xUbuntu_22.04}"
ARCH="${ARCH:-amd64}"
OFFLINE_DIR="${OFFLINE_DIR:-$(pwd)/offline}"
DOWNLOAD_DIR="$OFFLINE_DIR/crio"

mkdir -p "$DOWNLOAD_DIR/packages" "$DOWNLOAD_DIR/images"

# Download CRI-O packages from the openSUSE repository
REPO_BASE="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/${CRIO_VERSION}/${OS_FLAVOR}/${ARCH}/"
echo "Fetching CRI-O packages from $REPO_BASE"
PACKAGE_URLS=$(curl -fsSL "$REPO_BASE" \
  | grep -oE "href=\"[^\"]*cri-o[^\"]*\\.(deb|rpm)\"" \
  | cut -d'"' -f2)

for url in $PACKAGE_URLS; do
    file="$DOWNLOAD_DIR/packages/$(basename "$url")"
    echo "Downloading $url"
    curl -L "$REPO_BASE$url" -o "$file"
done

# Container images used by CRI-O
IMAGES=(
    "quay.io/crio/crio:$CRIO_VERSION"
    "registry.k8s.io/pause:3.9"
)

for img in "${IMAGES[@]}"; do
    echo "Pulling $img"
    docker pull "$img"
    out_name=$(echo "$img" | tr '/:' '_').tar
    docker save "$img" -o "$DOWNLOAD_DIR/images/$out_name"
done

echo "All CRI-O assets downloaded in $DOWNLOAD_DIR"
echo "Transfer image tarballs to $DOWNLOAD_DIR/images on target nodes and load with:"
echo "  sudo crictl load $DOWNLOAD_DIR/images/<image>.tar"
