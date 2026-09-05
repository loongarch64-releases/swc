#!/bin/bash
set -euo pipefail

UPSTREAM_OWNER=swc-project
UPSTREAM_REPO=swc
VERSION="${1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

DOCKER_IMAGE_NAME="${UPSTREAM_OWNER}/${UPSTREAM_REPO}-build-env"
DOCKERFILE_PATH="${ROOT_DIR}/Dockerfile.build"

PLATFORM='linux/loong64'

echo "🚀 Starting build process..."
echo "   🏢 Organization: ${UPSTREAM_OWNER}"
echo "   📦 Project:      ${UPSTREAM_REPO}"
echo "   🏷️  Version:      ${VERSION}"

RUN_PARAM=(
    --rm
    --platform "${PLATFORM}"
    -v "${ROOT_DIR}:/src:z"
    -w /src
    -e VERSION="${VERSION}"
    -e UPSTREAM_OWNER="${UPSTREAM_OWNER}"
    -e UPSTREAM_REPO="${UPSTREAM_REPO}"
    -e HOST_UID="$(id -u)"
    -e HOST_GID="$(id -g)"
)
LIBC=("gnu" "musl")
for libc in "${LIBC[@]}"; do
    echo "   🐳 Image Name:   ${DOCKER_IMAGE_NAME}-${libc}"

    if [ ! -f "${DOCKERFILE_PATH}.${libc}" ]; then
        echo "❌ Error: Dockerfile.build not found at ${DOCKERFILE_PATH}.${libc}"
        exit 1
    fi

    echo "🔨 Building Docker image: ${DOCKER_IMAGE_NAME}-${libc}..."
    docker build -t "${DOCKER_IMAGE_NAME}-${libc}" -f "${DOCKERFILE_PATH}.${libc}" "${ROOT_DIR}"

    echo "🏃 Running build inside ${DOCKER_IMAGE_NAME}-${libc}..."
    docker run "${RUN_PARAM[@]}" \
        "${DOCKER_IMAGE_NAME}-${libc}" \
        /bin/bash -c "./scripts/build.sh ${VERSION} ${libc}"
done

echo "✅ Build completed successfully!"
