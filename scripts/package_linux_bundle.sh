#!/usr/bin/env bash
set -e

# 计算脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 基础路径全基于绝对路径
BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
LIB_DIR="$BUNDLE_DIR/lib"
APPDIR="$PROJECT_ROOT/build/linux/AppDir"
APPIMAGE_DIR="$PROJECT_ROOT/build/linux/x64/release/AppImage"
OUTPUT_ZIP="$BUNDLE_DIR/chibot-linux.zip"
APPIMAGE_OUTPUT="$APPIMAGE_DIR/chibot-linux.AppImage"

echo ">>> Preparing directories..."
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPIMAGE_DIR"

while IFS= read -r sofile; do
    cp -u "$sofile" "$LIB_DIR/"
done < <(find "$PROJECT_ROOT" -name 'libflutter_linux_gtk.so')

echo ">>> Packaging bundle (zip legacy mode)..."
cd "$BUNDLE_DIR"
zip -r chibot-linux.zip .
cd -

echo ">>> Preparing AppDir structure..."
cp -v "$BUNDLE_DIR/chibot" "$APPDIR/usr/bin/"
cp -r "$BUNDLE_DIR/data" "$APPDIR/usr/bin/"
cp -v "$LIB_DIR/"*.so "$APPDIR/usr/lib/"


echo ">>> Generating icon..."
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
convert "$PROJECT_ROOT/assets/images/logo.png" -resize 256x256 "$APPDIR/chibot.png"
convert "$PROJECT_ROOT/assets/images/logo.png" -resize 256x256 "$APPDIR/usr/share/icons/hicolor/256x256/apps/chibot.png"

echo ">>> Preparing AppDir structure/chibot.desktop..."
cat << EOF > "$APPDIR/chibot.desktop"
[Desktop Entry]
Type=Application
Name=Chibot
Exec=chibot
Icon=chibot
Categories=Utility;
EOF

# 生成 AppRun 启动器
cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:$LD_LIBRARY_PATH"
exec "$HERE/usr/bin/chibot" "$@"
EOF

chmod +x "$APPDIR/AppRun"

echo ">>> Downloading linuxdeploy and appimagetool if not exist..."
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin"

if [ ! -f "$HOME/.local/bin/linuxdeploy-x86_64.AppImage" ]; then
    wget -O "$HOME/.local/bin/linuxdeploy-x86_64.AppImage" https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
    chmod +x "$HOME/.local/bin/linuxdeploy-x86_64.AppImage"
fi

if [ ! -f "$HOME/.local/bin/appimagetool-x86_64.AppImage" ]; then
    wget -O "$HOME/.local/bin/appimagetool-x86_64.AppImage" https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x "$HOME/.local/bin/appimagetool-x86_64.AppImage"
fi

echo ">>> Building AppImage..."
"$HOME/.local/bin/linuxdeploy-x86_64.AppImage" --appdir "$APPDIR" --output appimage

mv ./*.AppImage "$APPIMAGE_OUTPUT"
echo ">>> AppImage build complete: $APPIMAGE_OUTPUT"