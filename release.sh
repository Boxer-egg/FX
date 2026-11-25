#!/bin/bash

# 发布 ParticleFX：构建 → 打包 DMG → 上传 GitHub Release
# 用法: ./release.sh <版本号>
# 示例: ./release.sh 0.2
#
# 前置条件:
#   1. 已安装 gh 并登录 (gh auth login)
#   2. 本地提交已全部推送到 origin main（Release 标签基于远端代码）

set -euo pipefail

APP_NAME="ParticleFX"
REPO="Boxer-egg/FX"
VERSION="${1:-}"

# ---------- 前置检查 ----------
if [ -z "$VERSION" ]; then
    echo "错误: 缺少版本号"
    echo "用法: $0 <版本号>   例: $0 0.2"
    exit 1
fi

GH=$(command -v gh || echo /opt/homebrew/bin/gh)
if [ ! -x "$GH" ]; then
    echo "错误: 未找到 gh CLI，请先安装: brew install gh"
    exit 1
fi

if ! "$GH" auth status >/dev/null 2>&1; then
    echo "错误: gh 未登录，请先执行: gh auth login"
    exit 1
fi

# Release 标签基于远端 main，必须保证本地提交已推送
git fetch origin main --quiet
if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
    echo "错误: 本地 HEAD 与 origin/main 不一致，请先 git push"
    exit 1
fi

TAG="v${VERSION}"
if "$GH" release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
    echo "错误: Release $TAG 已存在，请先删除或换版本号"
    exit 1
fi

# ---------- 构建 ----------
echo "=== [1/3] 构建 $APP_NAME $VERSION ==="
make bundle VERSION="$VERSION"

# ---------- 打包 DMG ----------
DMG="${APP_NAME}-${VERSION}.dmg"
echo "=== [2/3] 打包 $DMG ==="
./create_dmg.sh "${APP_NAME}.app" "$DMG"

# ---------- 发布 Release ----------
echo "=== [3/3] 上传 Release $TAG 到 $REPO ==="
"$GH" release create "$TAG" "$DMG" \
    --repo "$REPO" \
    --title "$APP_NAME $VERSION" \
    --generate-notes

echo ""
echo "=== 发布完成 ==="
"$GH" release view "$TAG" --repo "$REPO" --web 2>/dev/null || true
