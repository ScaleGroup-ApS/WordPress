#!/bin/bash
set -e

# DigitalOcean Container Registry
REGISTRY="${REGISTRY:-registry.digitalocean.com/scaleweb}"

# Git commit SHA for tagging
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "local")

# Parse command line arguments
PUSH=true
IMAGE="wordpress"
dockerfile="Dockerfile"
name="$IMAGE"

echo "🐳 Building Docker images..."
echo "Registry: $REGISTRY"
echo "Git SHA: $GIT_SHA"
[ "$PUSH" = true ] && echo "📤 Will push images to registry"
echo ""

echo "📦 Building $name..."
docker build -f "$dockerfile" \
-t ${REGISTRY}/${name}:latest \
-t ${REGISTRY}/${name}:${GIT_SHA} \
.

if [ "$PUSH" = true ]; then
echo "📤 Pushing $name:latest..."
docker push ${REGISTRY}/${name}:latest
echo "📤 Pushing $name:${GIT_SHA}..."
docker push ${REGISTRY}/${name}:${GIT_SHA}
fi

echo ""
echo "✅ All images built successfully!"
echo ""
echo "📊 Image sizes:"
docker images ${REGISTRY}/* --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "REPOSITORY|latest|${GIT_SHA}"

echo ""
if [ "$PUSH" = false ]; then
  echo "💡 To push images, run with --push flag:"
  echo "   $0 --push"
fi