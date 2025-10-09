#!/bin/bash
# PhotoWatermark 一键放行脚本
# 用于移除 macOS Gatekeeper 隔离标记并启动应用

set -e

APP_PATH="/Applications/PhotoWatermark.app"

echo "=================================="
echo "PhotoWatermark 一键放行脚本"
echo "=================================="
echo

# 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "❌ 错误：未找到 PhotoWatermark.app"
    echo "   请确保已将应用拖入 Applications 文件夹"
    echo
    echo "按任意键退出..."
    read -n 1
    exit 1
fi

echo "🔍 检查隔离标记..."
if xattr -l "$APP_PATH" | grep -q com.apple.quarantine; then
    echo "📋 发现隔离标记，正在移除..."
    xattr -dr com.apple.quarantine "$APP_PATH"
    echo "✅ 隔离标记已移除"
else
    echo "✅ 无隔离标记"
fi

echo
echo "🔧 检查可执行权限..."
EXEC_PATH="$APP_PATH/Contents/MacOS/PhotoWatermark"
if [ -f "$EXEC_PATH" ]; then
    chmod +x "$EXEC_PATH"
    echo "✅ 可执行权限已设置"
else
    echo "⚠️  警告：可执行文件未找到，应用可能无法启动"
fi

echo
echo "🚀 启动 PhotoWatermark..."
open "$APP_PATH"

echo
echo "✅ 完成！PhotoWatermark 应该已经启动"
echo "   如果仍有问题，请检查系统设置 → 隐私与安全性"
echo
echo "按任意键关闭此窗口..."
read -n 1