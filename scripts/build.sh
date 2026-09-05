#!/bin/bash
set -euo pipefail

UPSTREAM_OWNER=swc-project
UPSTREAM_REPO=swc
VERSION="${1}"
LIBC="${2}"
echo "   🏢 Org:   ${UPSTREAM_OWNER}"
echo "   📦 Proj:  ${UPSTREAM_REPO}"
echo "   🏷️  Ver:   ${VERSION}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DISTS="${ROOT_DIR}/dists"
SRCS="${ROOT_DIR}/srcs"

IFS=. read -r MAJOR_VER MINOR_VER PATCH_VER <<< "${VERSION#v}"
VER_NUM=$(( 10#${MAJOR_VER} * 1000000 + 10#${MINOR_VER} * 1000 + 10#${PATCH_VER} ))

mkdir -p "${DISTS}/${VERSION}" "${SRCS}"

# ==========================================
# 👇 用户自定义构建逻辑 (示例)
# ==========================================

echo "🔧 Compiling ${UPSTREAM_OWNER}/${UPSTREAM_REPO} ${VERSION}..."

# 1. 准备阶段：安装依赖、下载代码、应用补丁等
prepare()
{
    echo "📦 [Prepare] Setting up build environment..."
    
    git clone -b "${VERSION}" --depth 1 "https://github.com/${UPSTREAM_OWNER}/${UPSTREAM_REPO}.git" "${SRCS}/${VERSION}"

    echo "✅ [Prepare] Environment ready."
}

# 2. 编译阶段：核心构建命令
build()
{
    echo "🔨 [Build] Compiling source code..."
    
    if [ ${VER_NUM} -lt 1015000 ]; then
        local BUILD_BASE="${SRCS}/${VERSION}/bindings"
    else
        local BUILD_BASE="${SRCS}/${VERSION}"
    fi
    pushd "${BUILD_BASE}"
    RUSTFLAGS="-C target-feature=+lsx,+lasx -C target-feature=-crt-static" \
        cargo build --release --target "loongarch64-unknown-linux-${LIBC}" -p binding_core_node
    popd

    echo "✅ [Build] Compilation finished."
}

# 3. 后处理阶段：整理产物、清理临时文件、验证版本
post_build()
{
    echo "📦 [Post-Build] Organizing artifacts..."
    
    local PRODUCT="${DISTS}/${VERSION}/libbinding_core_node_${LIBC}.so"
    if [ ${VER_NUM} -lt 1015000 ]; then
        local TARGET_DIR="${SRCS}/${VERSION}/bindings/target"
    else
        local TARGET_DIR="${SRCS}/${VERSION}/target"
    fi

    cp "${TARGET_DIR}/loongarch64-unknown-linux-${LIBC}/release/libbinding_core_node.so" "${PRODUCT}"
    chown -R "${HOST_UID}:${HOST_GID}" "${DISTS}" "${SRCS}"
    rm -rf "${SRCS}"
    
    echo "✅ [Post-Build] Artifacts ready in ./dists/${VERSION}."
}

# 主入口
main()
{
    prepare
    build
    post_build
}

main

# ==========================================
# 👆 自定义逻辑结束
# ==========================================

cat > "${DISTS}/${VERSION}/release.txt" <<EOF
Project: ${UPSTREAM_REPO}
Organization: ${UPSTREAM_OWNER}
Version: ${VERSION}
Build Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "✅ Compilation finished."
ls -lh "${DISTS}/${VERSION}"
