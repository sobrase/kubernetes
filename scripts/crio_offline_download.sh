#!/usr/bin/env bash
set -euo pipefail

CRIO_VERSION="${CRIO_VERSION:-1.32.6}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$(pwd)/crio_offline}"

mkdir -p "$DOWNLOAD_DIR/packages" "$DOWNLOAD_DIR/images"

# Download CRI-O packages and dependencies for offline installation
if command -v apt-get >/dev/null; then
    echo "Downloading CRI-O packages for version $CRIO_VERSION"
    sudo apt-get update
    sudo apt-get install --download-only -y "cri-o=$CRIO_VERSION*" "cri-o-runc=$CRIO_VERSION*"
    cp /var/cache/apt/archives/cri-o*.deb "$DOWNLOAD_DIR/packages/" || true
    cp /var/cache/apt/archives/cri-o-runc*.deb "$DOWNLOAD_DIR/packages/" || true
else
    echo "apt-get not found. Skipping package download." >&2
fi

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
echo "Transfer image tarballs to /opt/crio-images/ on target nodes and load with:"
echo "  sudo crictl load /opt/crio-images/<image>.tar"
