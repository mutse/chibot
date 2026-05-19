import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';

/// 提供给各 Provider 的共享 SharedPreferences/JSON helpers。
///
/// 把 `api_key_provider`、`chat_model_provider`、`image_model_provider` 等里
/// 重复实现的 decode/persist/normalize 辅助函数集中到一处。
mixin ProviderStorageHelpers on ChangeNotifier {
  /// 解码以 JSON 字符串形式存储的 `Map<String, String>`。
  /// 解析失败返回空 map 并通过 [AppLogger] 记录。
  Map<String, String> decodeStringMap(String? encoded, String debugLabel) {
    if (encoded == null || encoded.isEmpty) {
      return {};
    }

    try {
      final decoded = json.decode(encoded) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, value?.toString().trim() ?? ''),
      )..removeWhere((key, value) => value.isEmpty);
    } catch (error, stackTrace) {
      AppLogger.warning(debugLabel, error: error, stackTrace: stackTrace);
      return {};
    }
  }

  /// 兼容直接传入 `Map`、JSON 字符串或 `null` 三种来源的解码。
  Map<String, String> decodeDynamicStringMap(
    dynamic rawValue, {
    String debugLabel = 'Error parsing string map',
  }) {
    if (rawValue == null) {
      return {};
    }

    if (rawValue is String) {
      return decodeStringMap(rawValue, debugLabel);
    }

    if (rawValue is Map) {
      return rawValue.map(
        (key, value) =>
            MapEntry(key.toString(), value?.toString().trim() ?? ''),
      )..removeWhere((key, value) => value.isEmpty);
    }

    return {};
  }

  /// 解码以 JSON 字符串形式存储的 `Map<String, List<String>>`。
  Map<String, List<String>> decodeStringListMap(
    String? encoded,
    String debugLabel,
  ) {
    if (encoded == null || encoded.isEmpty) {
      return {};
    }

    try {
      final decoded = json.decode(encoded) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList(),
        ),
      )..removeWhere((key, value) => value.isEmpty);
    } catch (error, stackTrace) {
      AppLogger.warning(debugLabel, error: error, stackTrace: stackTrace);
      return {};
    }
  }

  /// 兼容 Map / JSON 字符串 / null 三种来源的解码（List 版本）。
  Map<String, List<String>> decodeDynamicStringListMap(
    dynamic rawValue,
    String debugLabel,
  ) {
    if (rawValue == null) {
      return {};
    }

    if (rawValue is String) {
      return decodeStringListMap(rawValue, debugLabel);
    }

    if (rawValue is Map) {
      return rawValue.map(
        (key, value) => MapEntry(
          key.toString(),
          (value as List)
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList(),
        ),
      )..removeWhere((key, value) => value.isEmpty);
    }

    return {};
  }

  /// 把 `null` 或纯空白字符串归一化为 `null`，否则去除首尾空白。
  String? normalizeNullableInput(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// 当 [value] 为 `null` 时移除 key，否则保存。
  Future<void> persistNullableString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value);
  }

  /// 当 map 为空时移除 key，否则以 JSON 字符串保存。
  Future<void> persistStringMap(
    SharedPreferences prefs,
    String key,
    Map<String, dynamic> values,
  ) async {
    if (values.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, json.encode(values));
  }

  /// 大小写不敏感地在 map 中查找 key；用于处理用户输入大小写差异。
  String? findStoredStringMapKey(Map<String, dynamic> values, String key) {
    if (values.containsKey(key)) {
      return key;
    }

    final target = key.toLowerCase();
    for (final storedKey in values.keys) {
      if (storedKey.toLowerCase() == target) {
        return storedKey;
      }
    }

    return null;
  }

  /// 大小写不敏感地查 map 中的值（找不到时返回 null）。
  String? getStoredStringMapValue(Map<String, String> values, String key) {
    final direct = values[key];
    if (direct != null) {
      return direct;
    }

    final storedKey = findStoredStringMapKey(values, key);
    if (storedKey == null) {
      return null;
    }
    return values[storedKey];
  }

  /// 判断 [value] 是否为已配置（非空且非纯空白）。
  bool hasConfiguredValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
