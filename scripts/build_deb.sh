#!/bin/bash

# Configuration
APP_NAME="chibot"
VERSION="1.0.0"
MAINTAINER="Mutse Young <young@mutse.top>"
DESCRIPTION="Chibot AI app powered by Flutter"

# Build Flutter app
flutter build linux --release

# Create package directory
PACKAGE_DIR="${APP_NAME}_${VERSION}_amd64"
rm -rf $PACKAGE_DIR
mkdir -p $PACKAGE_DIR/DEBIAN
mkdir -p $PACKAGE_DIR/usr/bin
mkdir -p $PACKAGE_DIR/usr/share/applications
mkdir -p $PACKAGE_DIR/usr/share/pixmaps

# Create control file
cat > $PACKAGE_DIR/DEBIAN/control << EOF
Package: $APP_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libblkid1, liblzma5, libstdc++6
Maintainer: $MAINTAINER
Description: $DESCRIPTION
 Extended description of your Flutter application
 that can span multiple lines.
EOF

# Copy application files
cp -f build/linux/x64/release/bundle/$APP_NAME $PACKAGE_DIR/usr/bin/
cp -r build/linux/x64/release/bundle/data $PACKAGE_DIR/usr/bin/
cp -f build/linux/x64/release/bundle/lib $PACKAGE_DIR/usr/

# Make executable
chmod +x $PACKAGE_DIR/usr/bin/$APP_NAME

# Create desktop entry
cat > $PACKAGE_DIR/usr/share/applications/$APP_NAME.desktop << EOF
[Desktop Entry]
Name=$APP_NAME
Comment=$DESCRIPTION
Exec=/usr/bin/$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Utility;
EOF

# Copy icon (if exists)
if [ -f "assets/images/icon.png" ]; then
    cp assets/images/icon.png $PACKAGE_DIR/usr/share/pixmaps/$APP_NAME.png
fi

# Build package
dpkg-deb --build $PACKAGE_DIR

mv ${PACKAGE_DIR}.deb build/linux/x64/release

echo "Package created: ${PACKAGE_DIR}.deb"
