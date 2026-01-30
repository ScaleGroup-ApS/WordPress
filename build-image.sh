#!/bin/bash
set -e

# DigitalOcean Container Registry
REGISTRY="${REGISTRY:-registry.scaleweb.dk}"

# Git commit SHA for tagging
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "local")

# Parse command line arguments
PUSH=true
PLATFORM="${PLATFORM:-linux/arm64}"
IMAGE="wordpress"
dockerfile="Dockerfile"
name="$IMAGE"
builder="${BUILDER:-multiarch}"

echo "🐳 Building Docker images..."
echo "Registry: $REGISTRY"
echo "Git SHA: $GIT_SHA"
[ "$PUSH" = true ] && echo "📤 Will push images to registry"
echo ""

echo "📦 Building $name..."
echo "Platform: $PLATFORM"

# Ensure docker buildx is available
if ! docker buildx version >/dev/null 2>&1; then
  echo "⚠️ docker buildx not found. Install Docker Buildx to build multi-arch images."
  exit 1
fi

# Create and use a builder for multi-arch (register QEMU if needed)
if ! docker buildx inspect $builder >/dev/null 2>&1; then
  echo "🔧 Creating buildx builder '$builder' and enabling QEMU emulation..."
  docker buildx create --name $builder --use
  docker run --rm --privileged tonistiigi/binfmt --install all || true
fi

# Decide build flags
build_flags=()
if [ "$PUSH" = true ]; then
  build_flags+=(--push)
else
  if echo "$PLATFORM" | grep -q ","; then
    echo "⚠️ Multi-platform builds require --push. Use --push or set PLATFORM to a single value like linux/arm64."
    exit 1
  fi
  build_flags+=(--load)
fi

# Build with buildx (supports multi-arch and pushing)
docker buildx build --platform "$PLATFORM" "${build_flags[@]}" -f "$dockerfile" \
  -t ${REGISTRY}/${name}:latest \
  -t ${REGISTRY}/${name}:${GIT_SHA} \
  .

if [ "$PUSH" = true ]; then
  echo "📤 Images were pushed by buildx."
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