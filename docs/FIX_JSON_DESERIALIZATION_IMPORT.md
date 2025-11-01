# Fix #3: JSON Deserialization in Import Process

## Problem
Import was failing with error:
```
Error in importSettingsFromXml: type 'String' is not a subtype of type 'Map<dynamic, dynamic>' in type cast
```

This occurred because custom provider maps were being stored as JSON strings in the XML file, but the import code expected them to be Maps.

## Root Cause
- Custom providers are serialized to JSON strings in XML: `<custom_providers>{"provider":["model1","model2"]}</custom_providers>`
- When imported, these come as String values
- ChatModelProvider and ImageModelProvider's fromMap() methods expected Map types and cast directly: `as Map`
- This caused a type mismatch error

## Solution
Updated both providers to handle BOTH String (from XML) and Map (from direct import) formats:

### ChatModelProvider Fix
**File:** `lib/providers/chat_model_provider.dart` (line 294-325)

**Before:**
```dart
if (data.containsKey(_customProvidersKey)) {
  _customProviders = Map<String, List<String>>.from(
    (data[_customProvidersKey] as Map).map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    ),
  );
}
```

**After:**
```dart
if (data.containsKey(_customProvidersKey)) {
  final customProvidersData = data[_customProvidersKey];
  if (customProvidersData != null) {
    Map<String, List<String>> parsedProviders = {};

    if (customProvidersData is String && customProvidersData.isNotEmpty) {
      // Parse JSON string from XML export
      try {
        final decoded = json.decode(customProvidersData) as Map<String, dynamic>;
        parsedProviders = Map<String, List<String>>.from(
          decoded.map(
            (key, value) => MapEntry(key, List<String>.from(value as List)),
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing custom providers JSON: $e');
        }
        parsedProviders = {};
      }
    } else if (customProvidersData is Map) {
      // Already a Map from direct import
      parsedProviders = Map<String, List<String>>.from(
        (customProvidersData as Map).map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
    }

    _customProviders = parsedProviders;
  }
}
```

### ImageModelProvider Fix
**File:** `lib/providers/image_model_provider.dart` (line 359-390)

Applied the exact same fix for `_customImageProvidersKey`

## Impact
✅ Import now works with JSON-serialized custom providers
✅ Handles both String and Map formats gracefully
✅ Errors logged but don't crash import
✅ Backward compatible with direct Map imports

## Features Now Working

### Export → Import Roundtrip
1. Export settings → Creates XML with JSON-encoded custom providers
2. Import settings → Parses JSON strings back to Maps
3. Settings restored correctly ✅

### Example
**Exported XML:**
```xml
<custom_providers>{"MyProvider":["model1","model2"]}</custom_providers>
```

**Import Process:**
```
Read XML → String: '{"MyProvider":["model1","model2"]}'
          ↓
       Parse JSON
          ↓
       Map<String, List<String>>: {MyProvider: [model1, model2]}
          ↓
       Settings Restored ✅
```

## Test Results
✅ Flutter analyze: 0 errors
✅ Import with custom providers: Working
✅ Import without custom providers: Working
✅ Backward compatibility: Maintained
✅ Error handling: Graceful

## Files Modified
- `lib/providers/chat_model_provider.dart` (+32 lines)
- `lib/providers/image_model_provider.dart` (+32 lines)

Total: 64 lines added

## Summary
The import process now properly handles JSON-serialized custom provider maps, converting them back to their original Map format during import. This completes the export-import roundtrip and allows users to fully backup and restore their configuration settings.
