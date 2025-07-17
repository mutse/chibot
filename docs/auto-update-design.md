 # Auto-Update Design Document

## Overview

This document outlines the design and implementation of auto-update functionality for the Chibot Flutter application, which fetches updates from GitHub releases and provides seamless installation across multiple platforms.

## Architecture

### Core Components

1 **UpdateService** - Main service class handling update operations
2. **GitHub API Integration** - Fetches latest release information
3. **Platform-Specific Handlers** - Manages different installation methods per platform
4. **Download Manager** - Handles file downloads and installation

### Flow Diagram

```
App Startup → Check for Updates → Fetch Latest Release → Compare Versions → 
Download Update → Install Update → Restart App
```

## Implementation Details

### 1. GitHub API Integration

#### API Endpoint
```dart
static const String githubApiUrl =https://api.github.com/repos/mutse/chibot/releases/latest';
```

#### Response Structure
The GitHub API returns release information in JSON format:
```json
[object Object]
  tag_name":v10.2  name:Release v10.2body":Release notes...",
  assets: [
   [object Object]
      name": chibot-v1.2.3k",
     browser_download_url: ttps://...",
     size: 12345678
    }
  ]
}
```

### 2. Version Comparison

#### Current Implementation
- Fetches latest release from GitHub
- Compares with current app version
- Determines if update is needed

#### Recommended Enhancement
```dart
class VersionComparator {
  static bool isUpdateAvailable(String currentVersion, String latestVersion) {
    // Implement semantic versioning comparison
    return _compareVersions(currentVersion, latestVersion) < 0 }
  
  static int _compareVersions(String v1, String v2) {
    // Parse semantic versions and compare
  }
}
```

### 3. Platform-Specific Handling

#### Android
- **File Type**: `.apk`
- **Installation**: Direct APK installation
- **Storage**: External storage directory
- **Permissions**: Requires `REQUEST_INSTALL_PACKAGES` permission

#### iOS
- **File Type**: App Store link
- **Installation**: Redirects to App Store
- **Limitations**: Cannot install directly due to iOS restrictions

#### Windows
- **File Type**: `.exe`
- **Installation**: Downloads and opens installer
- **Storage**: Downloads directory

#### macOS
- **File Type**: `.dmg`
- **Installation**: Downloads and opens DMG
- **Storage**: Downloads directory

#### Linux
- **File Type**: `.AppImage`
- **Installation**: Downloads and opens AppImage
- **Storage**: Downloads directory

### 4. Download and Installation Process

#### Download Flow1 **Validate URL**: Ensure download URL is accessible
2**Check Storage**: Verify sufficient storage space
3**Download File**: Use Dio for reliable downloads
4. **Verify Integrity**: Optional checksum verification
5. **Install**: Platform-specific installation

#### Error Handling
- Network connectivity issues
- Insufficient storage space
- Invalid download URLs
- Installation failures
- Permission denials

## Security Considerations

### 1. HTTPS Only
- All downloads must use HTTPS
- Validate SSL certificates
- Prevent man-in-the-middle attacks

### 2. File Integrity
```dart
class SecurityValidator[object Object]static Future<bool> verifyChecksum(String filePath, String expectedHash) async [object Object]  // Implement SHA-256 verification
  }
  
  static Future<bool> verifySignature(String filePath, String signature) async {
    // Implement digital signature verification
  }
}
```

### 3. miting
- Implement exponential backoff for failed requests
- Respect GitHub API rate limits
- Cache release information appropriately

## User Experience

### 1. Update Notification
- **Silent Check**: Background update checks
- **User Notification**: Clear update prompts
- **Progress Indication**: Download and installation progress
- **Error Feedback**: User-friendly error messages

### 2. Update Options
- **Automatic**: Install immediately
- **Manual**: User initiates installation
- **Defer**: Remind later
- **Skip**: Skip this version

### 3. Update Channels
- **Stable**: Production releases
- **Beta**: Pre-release versions
- **Nightly**: Development builds

## Configuration

### 1. Update Settings
```dart
class UpdateConfig {
  static const bool enableAutoCheck = true;
  static const Duration checkInterval = Duration(hours: 24 static const bool enableSilentDownload = false;
  static const List<String> allowedChannels = [stable'];
}
```

### 2. GitHub Repository Configuration
- Repository owner and name
- API authentication (optional)
- Release tag patterns
- Asset naming conventions

## Error Handling and Recovery

### 1. Network Failures
- Retry with exponential backoff
- Fallback to cached release info
- User notification of connectivity issues

### 2. Download Failures
- Resume interrupted downloads
- Clean up partial downloads
- Retry with different mirrors

### 3. Installation Failures
- Rollback to previous version
- Provide manual installation instructions
- Log detailed error information

## Monitoring and Analytics

### 1. Update Metrics
- Update check frequency
- Download success rates
- Installation success rates
- User adoption rates

### 2. Error Tracking
- Network error types
- Download failure reasons
- Installation failure causes
- User feedback collection

## Testing Strategy

### 1. Unit Tests
- Version comparison logic
- URL generation
- Platform detection

### 2. Integration Tests
- GitHub API integration
- Download functionality
- Installation processes

### 3. End-to-End Tests
- Complete update flow
- Error scenarios
- Cross-platform compatibility

## Deployment Considerations

### 1. Release Process
+ **Tag Creation**: Create semantic version tags
+ **Asset Upload**: Upload platform-specific binaries
+ **Release Notes**: Provide detailed changelog
+ **Pre-release**: Mark as pre-release for beta testing

### 2. Binary Distribution
- **Android**: APK files with proper signing
- **Windows**: MSI/EXE installers
- **macOS**: DMG files with code signing
- **Linux**: AppImage or package files

### 3. Release Automation
- GitHub Actions for automated builds
- Automated testing before release
- Asset upload automation
- Release note generation

## Future Enhancements

### 1pdates
- Implement binary diff updates
- Reduce download sizes
- Faster update process

### 2. Background Updates
- Silent background downloads
- Automatic installation during app restart
- User preference management

### 3. Multi-Channel Support
- Development channel
- Beta channel
- Release candidate channel
- Stable channel

### 4. Advanced Features
- Update scheduling
- Bandwidth management
- Update rollback functionality
- A/B testing support

## Dependencies

### Required Packages
```yaml
dependencies:
  http: ^1.10dio: ^5.0.0  path_provider: ^20.0
  open_file: ^3.30
  url_launcher: ^6.1.0
```

### Optional Packages
```yaml
dependencies:
  crypto: ^300cksum verification
  shared_preferences: ^20update preferences
  connectivity_plus: ^4.0For network status
```

## Conclusion

This auto-update system provides a robust, secure, and user-friendly way to distribute application updates through GitHub releases. The implementation supports multiple platforms while maintaining security and providing excellent user experience.

The modular design allows for easy extension and customization based on specific requirements, while the comprehensive error handling ensures reliability across different network conditions and user environments.