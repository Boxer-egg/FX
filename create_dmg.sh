#!/bin/bash

# 创建带 Applications 快捷方式的 DMG 安装包
# 用法: ./create_dmg.sh <app路径> [输出dmg名称]

set -e

# 配置
APP_PATH="${1:-ParticleFX.app}"
APP_NAME=$(basename "$APP_PATH" .app)
VOL_NAME="${APP_NAME}"
DMG_NAME="${2:-${APP_NAME}.dmg}"
TEMP_DMG="temp_${APP_NAME}.dmg"
MOUNT_POINT="/Volumes/${VOL_NAME}"

# 检查 app 是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "错误: 找不到 $APP_PATH"
    echo "用法: $0 <app路径> [输出dmg名称]"
    exit 1
fi

echo "=== 创建 DMG: $APP_NAME ==="

# 清理旧的临时文件
if [ -f "$TEMP_DMG" ]; then
    rm -f "$TEMP_DMG"
fi

# 1. 创建临时可读写 DMG（留足空间放图标和链接）
echo "创建临时 DMG..."
hdiutil create \
    "$TEMP_DMG" \
    -size 200m \
    -volname "$VOL_NAME" \
    -fs HFS+ \
    -type UDIF

# 2. 挂载 DMG
echo "挂载 DMG..."
hdiutil attach "$TEMP_DMG" -noverify -nobrowse

# 等待挂载完成
sleep 1

# 3. 复制 .app 到 DMG
echo "复制应用..."
cp -R "$APP_PATH" "$MOUNT_POINT/"

# 4. 创建 Applications 符号链接
echo "创建 Applications 链接..."
ln -sf /Applications "$MOUNT_POINT/Applications"

# 5. 创建背景图文件夹并设置窗口布局
echo "设置窗口布局..."
mkdir -p "$MOUNT_POINT/.background"

# 创建一个简单的背景图（可选：你可以替换为自己的背景图）
# 如果需要自定义背景图，取消下面这行的注释并修改路径：
# cp "background.png" "$MOUNT_POINT/.background/background.png"

# 使用 AppleScript 设置 Finder 窗口布局
osascript <<EOF
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 600, 450}

        set icon size of icon view options of container window to 96
        set text size of icon view options of container window to 14
        set arrangement of icon view options of container window to not arranged

        -- 设置图标位置 (左边放 app，右边放 Applications)
        set position of item "${APP_NAME}.app" of container window to {120, 200}
        set position of item "Applications" of container window to {380, 200}

        close
    end tell
end tell
EOF

# 等待 Finder 写入 .DS_Store
sleep 2

# 6. 卸载 DMG
echo "卸载 DMG..."
hdiutil detach "$MOUNT_POINT" -force || true

# 7. 转换为只读压缩 DMG
echo "压缩为最终 DMG..."
if [ -f "$DMG_NAME" ]; then
    rm -f "$DMG_NAME"
fi

hdiutil convert "$TEMP_DMG" \
    -format UDZO \
    -o "$DMG_NAME"

# 8. 清理
rm -f "$TEMP_DMG"

echo ""
echo "=== 完成 ==="
echo "输出文件: $DMG_NAME"
echo ""
echo "测试安装:"
echo "  hdiutil attach $DMG_NAME"
