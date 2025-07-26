# Setup and Deployment Guide

This guide provides comprehensive instructions for setting up the Chi Chatbot application for development, testing, and production deployment across all supported platforms.

## 📋 Table of Contents

- [Development Environment Setup](#development-environment-setup)
- [Platform-Specific Setup](#platform-specific-setup)
- [Configuration](#configuration)
- [Building for Production](#building-for-production)
- [Deployment Strategies](#deployment-strategies)
- [CI/CD Pipeline](#cicd-pipeline)
- [Troubleshooting](#troubleshooting)

## 🛠️ Development Environment Setup

### Prerequisites

#### Required Software
- **Flutter SDK**: 3.0.0 or later
- **Dart SDK**: 2.17.0 or later
- **Git**: Version control
- **IDE**: VS Code, Android Studio, or IntelliJ IDEA

#### Platform-Specific Tools

| Platform | Required Tools |
|----------|----------------|
| **macOS** | Xcode Command Line Tools, CocoaPods |
| **Windows** | Visual Studio 2022, Windows 10 SDK |
| **Linux** | Build essentials, pkg-config, GTK3 |
| **Android** | Android Studio, Android SDK |
| **iOS** | Xcode, iOS Simulator |

### Installation Steps

#### 1. Install Flutter

**macOS/Linux:**
```bash
# Download Flutter SDK
cd ~
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

**Windows:**
```powershell
# Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
# Extract to C:\src\flutter
# Add to PATH: C:\src\flutter\bin
```

#### 2. Verify Installation

```bash
flutter doctor
```

Expected output should show checkmarks for:
- [✓] Flutter (Channel stable)
- [✓] Android toolchain
- [✓] Xcode (macOS only)
- [✓] Chrome (for web)
- [✓] Connected devices

#### 3. Clone Repository

```bash
git clone https://github.com/mutse/chibot.git
cd chibot
```

#### 4. Install Dependencies

```bash
flutter pub get

# For desktop platforms
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop

# For web
flutter config --enable-web
```

## 🔧 Platform-Specific Setup

### macOS Development

#### Additional Setup
```bash
# Install CocoaPods
sudo gem install cocoapods

# Accept Xcode licenses
sudo xcodebuild -license accept

# Install additional tools
xcode-select --install
```

#### Run on macOS
```bash
flutter run -d macos
```

### Windows Development

#### Additional Setup
1. Install Visual Studio 2022 with:
   - Desktop development with C++
   - Windows 10 SDK (10.0.19041.0 or later)

2. Install Windows App SDK (if targeting Windows 11)

#### Run on Windows
```bash
flutter run -d windows
```

### Linux Development

#### Additional Setup
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev

# Fedora
sudo dnf install clang cmake ninja-build pkg-config gtk3-devel

# Arch Linux
sudo pacman -S clang cmake ninja pkg-config gtk3
```

#### Run on Linux
```bash
flutter run -d linux
```

### Android Development

#### Setup Android Studio
1. Install Android Studio
2. Install Android SDK Platform-Tools
3. Create Android Virtual Device (AVD)
4. Set up device for development

#### Configure Android
```bash
# Check Android setup
flutter doctor --android-licenses

# List available devices
flutter devices
```

#### Run on Android
```bash
flutter run -d android
```

### iOS Development

#### Setup Xcode
1. Install Xcode from App Store
2. Open Xcode and accept licenses
3. Install iOS Simulator

#### Configure iOS
```bash
# List available simulators
xcrun simctl list devices

# Run on iOS simulator
flutter run -d "iPhone 14"
```

### Web Development

#### Setup Chrome
```bash
# Enable web support
flutter config --enable-web

# Run on Chrome
flutter run -d chrome
```

## ⚙️ Configuration

### Environment Configuration

#### Development Environment
Create `.env` file in project root:

```bash
# API Keys (for development only)
OPENAI_API_KEY=your-openai-key-here
GEMINI_API_KEY=your-gemini-key-here
CLAUDE_API_KEY=your-claude-key-here

# Optional: Custom API endpoints
CUSTOM_API_BASE_URL=https://your-custom-endpoint.com

# Development settings
DEBUG_MODE=true
ENABLE_LOGGING=true
```

#### Production Environment
Use environment variables or secure storage:

```bash
# Set environment variables
export OPENAI_API_KEY="your-production-key"
export GEMINI_API_KEY="your-production-key"
```

### Application Configuration

#### Settings Storage
The application stores configuration in:
- **Mobile**: SharedPreferences
- **Desktop**: Local storage
- **Web**: LocalStorage

#### Configuration Schema
```json
{
  "openai_api_key": "string",
  "gemini_api_key": "string", 
  "claude_api_key": "string",
  "selected_provider": "openai|gemini|claude|custom",
  "selected_model": "string",
  "custom_base_url": "string",
  "system_prompt": "string",
  "theme_mode": "light|dark|system",
  "language": "en|zh|de|fr|ja"
}
```

## 🚀 Building for Production

### Build Optimization

#### Pre-build Steps
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze
```

#### Build Configuration

**Android (APK):**
```bash
flutter build apk --release --split-per-abi
```

**Android (App Bundle):**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
# Then archive in Xcode
```

**macOS:**
```bash
flutter build macos --release
```

**Windows:**
```bash
flutter build windows --release
```

**Linux:**
```bash
flutter build linux --release
```

**Web:**
```bash
flutter build web --release --web-renderer canvaskit
```

### Build Outputs

| Platform | Output Location | File Type |
|----------|-----------------|-----------|
| Android | `build/app/outputs/apk/release/` | APK files |
| iOS | `build/ios/iphoneos/` | .app bundle |
| macOS | `build/macos/Build/Products/Release/` | .app bundle |
| Windows | `build/windows/runner/Release/` | .exe file |
| Linux | `build/linux/release/bundle/` | Executable |
| Web | `build/web/` | Web assets |

## 📦 Deployment Strategies

### Mobile Deployment

#### App Store Deployment (iOS)
1. **Prepare App Store Listing**
   ```bash
   # Update app metadata
   # - App name, description, screenshots
   # - Privacy policy, support URL
   # - App category, keywords
   ```

2. **Build and Archive**
   ```bash
   flutter build ios --release
   open ios/Runner.xcworkspace
   # Archive in Xcode
   # Upload to App Store Connect
   ```

3. **TestFlight Distribution**
   - Upload to TestFlight for beta testing
   - Invite internal and external testers
   - Collect feedback and crash reports

#### Google Play Store (Android)
1. **Prepare Play Store Listing**
   ```bash
   # Update app metadata
   # - App name, description, screenshots
   # - Privacy policy, support URL
   # - App category, contact details
   ```

2. **Build and Sign**
   ```bash
   # Generate keystore (first time)
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

   # Reference keystore in android/key.properties
   storePassword=your-store-password
   keyPassword=your-key-password
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

3. **Build Release**
   ```bash
   flutter build appbundle --release
   ```

4. **Upload to Play Console**
   - Upload .aab file
   - Complete store listing
   - Set up pricing and distribution

### Desktop Deployment

#### macOS Distribution
1. **Notarization Setup**
   ```bash
   # Create Developer ID Application certificate
   # In Xcode: Preferences > Accounts > Manage Certificates
   ```

2. **Build and Package**
   ```bash
   flutter build macos --release
   
   # Create DMG
   create-dmg build/macos/Build/Products/Release/Chi\ Chatbot.app
   ```

3. **Notarization**
   ```bash
   # Submit for notarization
   xcrun altool --notarize-app --primary-bundle-id "com.mutse.chibot"
   ```

#### Windows Distribution
1. **Code Signing**
   ```bash
   # Obtain code signing certificate
   # Sign the executable
   signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com build/windows/runner/Release/chibot.exe
   ```

2. **Create Installer**
   ```bash
   # Use tools like Inno Setup or WiX Toolset
   # Create .msi or .exe installer
   ```

#### Linux Distribution
1. **Package Creation**
   ```bash
   # Create .deb package
   flutter build linux --release
   dpkg-deb --build build/linux/release/bundle/

   # Create .rpm package
   flutter build linux --release
   # Use rpm-build tools
   ```

### Web Deployment

#### Static Hosting
1. **Build Web Version**
   ```bash
   flutter build web --release --web-renderer canvaskit
   ```

2. **Deploy to Hosting Services**
   - **GitHub Pages**: Push to `gh-pages` branch
   - **Netlify**: Drag and drop build/web folder
   - **Vercel**: Connect GitHub repository
   - **Firebase Hosting**: Use Firebase CLI

#### Firebase Hosting Example
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase
firebase init hosting

# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

## 🔄 CI/CD Pipeline

### GitHub Actions

#### Workflow Configuration
Create `.github/workflows/ci.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.0.0'
    - run: flutter pub get
    - run: flutter analyze
    - run: flutter test

  build:
    needs: test
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter build ${{ matrix.build_target }}
```

### Automated Releases

#### Release Workflow
```yaml
name: Release
on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter build apk --release
    - uses: softprops/action-gh-release@v1
      with:
        files: build/app/outputs/apk/release/app-release.apk
```

## 🔧 Troubleshooting

### Common Issues

#### Flutter Doctor Issues
```bash
# Android licenses
flutter doctor --android-licenses

# Xcode setup
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# CocoaPods issues
sudo gem install cocoapods
pod setup
```

#### Build Issues
```bash
# Clean build
flutter clean
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for issues
flutter analyze
```

#### Platform-Specific Issues

**Android:**
```bash
# Gradle issues
./gradlew clean
./gradlew build

# SDK issues
flutter doctor --android-licenses
```

**iOS:**
```bash
# Pod issues
cd ios
pod install
pod update

# Xcode issues
rm -rf ios/Pods
rm -rf ios/Podfile.lock
flutter clean
flutter pub get
cd ios && pod install
```

**Web:**
```bash
# Clear browser cache
# Check CORS settings
# Verify API endpoints
```

### Performance Issues

#### Build Size Optimization
```bash
# Analyze build size
flutter build apk --analyze-size

# Reduce app size
flutter build apk --split-per-abi --shrink
```

#### Memory Issues
```bash
# Profile memory usage
flutter run --profile
# Use DevTools for memory analysis
```

### Network Issues

#### API Connectivity
```bash
# Test API endpoints
curl -X POST https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4","messages":[{"role":"user","content":"test"}]}'
```

#### Proxy Configuration
```bash
# Set proxy for development
export HTTPS_PROXY=http://proxy.company.com:8080
export HTTP_PROXY=http://proxy.company.com:8080
```

## 📞 Support and Resources

### Getting Help

- **GitHub Issues**: [Create an issue](https://github.com/mutse/chibot/issues)
- **Documentation**: Check the [project wiki](https://github.com/mutse/chibot/wiki)
- **Community**: Join discussions in GitHub Discussions
- **Stack Overflow**: Tag questions with `flutter` and `chibot`

### Useful Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Platform-Specific Guides](https://flutter.dev/docs/deployment)
- [CI/CD Examples](https://github.com/flutter/gallery/tree/master/.github/workflows)
- [Flutter Community](https://flutter.dev/community)

---

**Need more help?** Check the [troubleshooting guide](TROUBLESHOOTING.md) or create an issue with detailed information about your setup and the problem you're experiencing.