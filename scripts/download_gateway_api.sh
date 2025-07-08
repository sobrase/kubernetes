#!/bin/bash
set -euo pipefail

# Versions can be overridden via environment variables
NGINX_GATEWAY_VERSION="${NGINX_GATEWAY_VERSION:-2.0.1}"
# Gateway API release to download
GATEWAY_API_VERSION="${GATEWAY_API_VERSION:-v1.2.0}"
OFFLINE_DIR="${OFFLINE_DIR:-$(pwd)/offline}"
OUTDIR="$OFFLINE_DIR/gateway_api"

mkdir -p "$OUTDIR/manifests" "$OUTDIR/images"

NGINX_BASE="https://raw.githubusercontent.com/nginxinc/nginx-kubernetes-gateway/${NGINX_GATEWAY_VERSION}"
GATEWAY_BASE="https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}"

# Download manifests
curl -L "$NGINX_BASE/deploy/crds.yaml" -o "$OUTDIR/manifests/nginx-gateway-crds.yaml"
curl -L "$NGINX_BASE/deploy/default/deploy.yaml" -o "$OUTDIR/manifests/nginx-gateway-deploy.yaml"

for f in gatewayclasses gateways grpcroutes httproutes referencegrants; do
    curl -L "$GATEWAY_BASE/config/crd/standard/gateway.networking.k8s.io_${f}.yaml" \
        -o "$OUTDIR/manifests/gateway.networking.k8s.io_${f}.yaml"
done

# Docker images required for NGINX Gateway Fabric
IMAGES=(
    "ghcr.io/nginx/nginx-gateway-fabric:${NGINX_GATEWAY_VERSION}"
    "ghcr.io/nginx/nginx-gateway-fabric/nginx:${NGINX_GATEWAY_VERSION}"
)

for img in "${IMAGES[@]}"; do
    docker pull "$img"
    name=$(echo "$img" | tr '/:' '_')
    docker save "$img" | gzip -c > "$OUTDIR/images/${name}.tar.gz"
done

echo "Artifacts saved in $OUTDIR"
