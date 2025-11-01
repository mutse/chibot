# Code Changes Reference Guide

## 1. Video Settings Export/Import

### Added to `settings_xml_handler.dart`:

```dart
// Export video settings section
static void _writeVideoSettings(
  StringBuffer buffer,
  Map<String, dynamic> settings,
) {
  buffer.writeln('  <video_settings>');
  _writeXmlTag(
    buffer,
    'selected_video_provider',
    settings['selected_video_provider'],
    4,
  );
  _writeXmlTag(
    buffer,
    'video_resolution',
    settings['video_resolution'],
    4,
  );
  _writeXmlTag(
    buffer,
    'video_duration',
    settings['video_duration'],
    4,
  );
  _writeXmlTag(
    buffer,
    'video_quality',
    settings['video_quality'],
    4,
  );
  _writeXmlTag(
    buffer,
    'video_aspect_ratio',
    settings['video_aspect_ratio'],
    4,
  );
  buffer.writeln('  </video_settings>');
}

// Import video settings section
static Map<String, dynamic> _parseVideoSettings(String content) {
  final settings = <String, dynamic>{};
  final videoMatch = RegExp(
    r'<video_settings>(.*?)</video_settings>',
    dotAll: true,
  ).firstMatch(content);

  if (videoMatch != null) {
    final videoContent = videoMatch.group(1)!;
    settings['selected_video_provider'] = _extractTagValue(
      videoContent,
      'selected_video_provider',
    );
    settings['video_resolution'] = _extractTagValue(
      videoContent,
      'video_resolution',
    );
    settings['video_duration'] = _extractTagValue(
      videoContent,
      'video_duration',
    );
    settings['video_quality'] = _extractTagValue(
      videoContent,
      'video_quality',
    );
    settings['video_aspect_ratio'] = _extractTagValue(
      videoContent,
      'video_aspect_ratio',
    );
  }

  return settings;
}
```

---

## 2. Version Control and Validation

### Enhanced XML Export with Version:

```dart
static String exportToXml(Map<String, dynamic> settings) {
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<settings version="$schemaVersion" exported="${DateTime.now().toIso8601String()}">');

  // ... write all settings sections ...

  buffer.writeln('</settings>');
  return buffer.toString();
}

// Schema version constant
static const int schemaVersion = 1;
```

### Enhanced XML Import with Validation:

```dart
static Map<String, dynamic> importFromXml(String xmlContent) {
  try {
    // Validate XML structure
    if (xmlContent.trim().isEmpty) {
      throw InvalidSettingsException.malformedXml('The file is empty.');
    }

    if (!xmlContent.contains('<settings') || !xmlContent.contains('</settings>')) {
      throw InvalidSettingsException.malformedXml(
        'Missing required <settings> root element.',
      );
    }

    // Extract and validate version
    final versionMatch = RegExp(r'version="(\d+)"').firstMatch(xmlContent);
    if (versionMatch != null) {
      final exportedVersion = int.tryParse(versionMatch.group(1)!);
      if (exportedVersion != null && exportedVersion > schemaVersion) {
        throw SettingsVersionMismatchException(
          exportedVersion: exportedVersion,
          currentVersion: schemaVersion,
        );
      }
    }

    // ... parse sections ...

    return settings;
  } on SettingsException {
    rethrow;
  } catch (e) {
    throw InvalidSettingsException.malformedXml('$e');
  }
}
```

---

## 3. Google API Key Support

### Added to API Keys Export:

```dart
_writeEncryptedXmlTag(
  buffer,
  'google_api_key',
  settings['google_api_key'],
  4,
);
```

### Added to API Keys Import:

```dart
settings['google_api_key'] = _extractEncryptedTagValue(
  apiKeysContent,
  'google_api_key',
);
```

### Updated in UnifiedSettingsProvider:

```dart
Map<String, dynamic> _extractApiKeys(Map<String, dynamic> flat) {
  const keys = [
    'openai_api_key',
    'claude_api_key',
    'google_api_key',  // NEW
    'flux_kontext_api_key',
    'tavily_api_key',
    'google_search_api_key',
  ];
  // ... extract logic ...
}
```

---

## 4. Enhanced Error Handling

### Exception Classes (New File):

```dart
// Base exception
abstract class SettingsException implements Exception {
  final String message;
  final String? details;
  final StackTrace? stackTrace;

  SettingsException({
    required this.message,
    this.details,
    this.stackTrace,
  });
}

// Specific exceptions
class InvalidSettingsException extends SettingsException { /* ... */ }
class SettingsVersionMismatchException extends SettingsException { /* ... */ }
class DecryptionFailedException extends SettingsException { /* ... */ }
class SettingsValidationException extends SettingsException { /* ... */ }
class SettingsOperationCancelledException extends SettingsException { /* ... */ }
class SettingsFileException extends SettingsException { /* ... */ }
```

### Graceful Decryption Error Handling:

```dart
static String? _extractEncryptedTagValue(String content, String tag) {
  final match = RegExp('<$tag>(.*?)</$tag>').firstMatch(content);
  if (match != null) {
    final encryptedValue = _unescapeXml(match.group(1)!.trim());
    if (encryptedValue.isEmpty) return null;

    try {
      final decryptedValue = EncryptionUtils.aesDecrypt(encryptedValue);
      return decryptedValue;
    } catch (e) {
      // Log warning but don't fail import
      print('Warning: Failed to decrypt $tag: $e');
      return null;
    }
  }
  return null;
}
```

---

## 5. Enhanced UI Error Handling

### In SettingsScreen._exportSettings():

```dart
try {
  await unifiedSettings.syncModelsToRegistry();
  final xmlContent = await unifiedSettings.exportSettingsToXml();

  // ... file operations ...

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✅ 配置导出成功！'),
          Text('文件: $fileName', style: const TextStyle(fontSize: 12)),
          Text(
            '文件大小: ${(xmlContent.length / 1024).toStringAsFixed(2)} KB',
            style: const TextStyle(fontSize: 10, color: Colors.white60),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 6),
    ),
  );
} catch (e) {
  String errorTitle = '导出失败';
  String errorMessage = e.toString();

  if (e is FileSystemException) {
    errorTitle = '文件系统错误';
    if (e.message.contains('Permission denied')) {
      errorMessage = '权限不足: 无法写入该目录。请检查存储权限。';
    } else if (e.message.contains('No space')) {
      errorMessage = '磁盘空间不足。请清理存储空间。';
    } else {
      errorMessage = '文件操作失败: ${e.message}';
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('❌ $errorTitle'),
          Text(errorMessage, style: const TextStyle(fontSize: 12)),
        ],
      ),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 6),
    ),
  );
}
```

### In SettingsScreen._importSettingsFromFilePicker():

```dart
try {
  await unifiedSettings.importSettingsFromXml(xmlContent);
  setState(() {});

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅ 配置导入成功！'),
          Text('来源: $fileName', style: const TextStyle(fontSize: 12)),
        ],
      ),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 4),
    ),
  );
} catch (importError) {
  String errorMessage = '导入失败: 配置格式错误或不兼容';

  if (importError.toString().contains('version')) {
    errorMessage = '导入失败: 配置版本不兼容。此文件来自较新的应用版本。';
  } else if (importError.toString().contains('Invalid')) {
    errorMessage = '导入失败: 无效的配置文件。文件可能已损坏。';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('❌ 导入失败'),
          Text(errorMessage, style: const TextStyle(fontSize: 12)),
        ],
      ),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 6),
    ),
  );
}
```

---

## Integration Points

### Settings Export Flow:
1. User clicks "Export Config" button
2. `_exportSettings()` collects all settings via `UnifiedSettingsProvider`
3. `exportSettingsToXml()` converts to XML with version info
4. File written to platform-specific directory
5. Success feedback with file size and location

### Settings Import Flow:
1. User clicks "Import Config" button
2. Choose between platform directory or file picker
3. `importFromXml()` validates and parses XML
4. Version checking performed
5. Settings applied via individual providers
6. UI refreshed to reflect changes
7. Success/error feedback provided

---

## Key Features Summary

| Feature | Before | After |
|---------|--------|-------|
| Video Settings | ❌ Not exported | ✅ Full support |
| Google API Key | ❌ Mixed with image key | ✅ Explicit field |
| Version Tracking | ❌ None | ✅ v1 with migration path |
| Error Handling | ⚠️ Basic | ✅ 7 custom exceptions |
| User Feedback | ⚠️ Generic messages | ✅ Detailed, actionable messages |
| File Validation | ⚠️ Basic | ✅ Structure, version, content validation |
| Decryption Errors | ❌ Fatal | ✅ Graceful with warnings |
| File Size Info | ❌ None | ✅ Shown in success message |

---

## Testing Examples

### Export Test:
```
Settings Screen → Export Config Button
  ↓
Select Export
  ↓
File saved to ~/Documents/Chibot/chibot_config_2025-11-01T...xml
  ↓
Success: "✅ 配置导出成功！
         文件: chibot_config_2025-11-01...xml
         位置: /Users/user/Documents/Chibot
         文件大小: 8.45 KB"
```

### Import Test:
```
Settings Screen → Import Config → File Picker
  ↓
Select XML file
  ↓
Confirmation dialog with file details
  ↓
Click Confirm
  ↓
Import processing
  ↓
Success/Error feedback with details
```

---

## Compatibility Matrix

| Scenario | Status | Notes |
|----------|--------|-------|
| Export new config | ✅ Full | Includes all settings with version=1 |
| Import old config | ✅ Full | Backward compatible, missing fields ignored |
| Mixed versions | ✅ Safe | Version mismatch detected, warning provided |
| Corrupted keys | ✅ Recoverable | Graceful degradation, import continues |
| Missing directories | ✅ Auto-create | Directories created automatically |
| Permission denied | ✅ Error feedback | Clear message with recovery steps |

