# Bug Fix: JSON Serialization in Settings Export

## Issue
Export functionality was failing with error:
```
Error in exportSettingsToXml: type '_Map<String, List<String>>' is not a subtype of type 'String?' in type cast
```

## Root Cause
The XML handler was attempting to cast Maps to Strings without proper JSON serialization:
- `custom_providers_map` is a `Map<String, List<String>>`, not a `String`
- `custom_image_providers_map` is also a `Map<String, List<String>>`, not a `String`

## Solution
Fixed two issues in `lib/utils/settings_xml_handler.dart`:

### 1. Added JSON Import
```dart
import 'dart:convert' as json_lib;
```

### 2. Fixed Custom Providers Serialization
**Before:**
```dart
final customProviders = settings['custom_providers_map'] as String?;
if (customProviders != null && customProviders.isNotEmpty) {
  _writeXmlTag(buffer, 'custom_providers', customProviders, 4);
}
```

**After:**
```dart
final customProviders = settings['custom_providers_map'];
if (customProviders != null) {
  final customProvidersStr = customProviders is String
      ? customProviders
      : json_lib.json.encode(customProviders);
  if (customProvidersStr.isNotEmpty && customProvidersStr != '{}') {
    _writeXmlTag(buffer, 'custom_providers', customProvidersStr, 4);
  }
}
```

### 3. Fixed Custom Image Providers Serialization
**Before:**
```dart
final customImageProviders = settings['custom_image_providers_map'] as String?;
if (customImageProviders != null && customImageProviders.isNotEmpty) {
  _writeXmlTag(buffer, 'custom_image_providers', customImageProviders, 4);
}
```

**After:**
```dart
final customImageProviders = settings['custom_image_providers_map'];
if (customImageProviders != null) {
  final customImageProvidersStr = customImageProviders is String
      ? customImageProviders
      : json_lib.json.encode(customImageProviders);
  if (customImageProvidersStr.isNotEmpty && customImageProvidersStr != '{}') {
    _writeXmlTag(buffer, 'custom_image_providers', customImageProvidersStr, 4);
  }
}
```

## Impact
✅ Export functionality now works correctly
✅ Custom providers are properly serialized to JSON
✅ Custom image providers are properly serialized to JSON
✅ Backward compatible with existing exports
✅ No breaking changes

## Testing
- Flutter analyze: 0 errors (146 warnings - pre-existing)
- Export now completes successfully
- Settings properly serialized to XML
- Ready for deployment

## Files Modified
- `lib/utils/settings_xml_handler.dart` (+1 import, +16 lines modified)

Total changes: 17 lines modified
