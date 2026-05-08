import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 负责管理所有 API 密钥的提供者
/// 职责：存储、加载、更新各个 AI 服务的 API 密钥
class ApiKeyProvider with ChangeNotifier {
  // OpenAI API Key
  String? _openaiApiKey;
  static const String _openaiApiKeyKey = 'openai_api_key';

  // Claude API Key
  String? _claudeApiKey;
  static const String _claudeApiKeyKey = 'claude_api_key';

  // Google API Key (用于 Gemini 和图像生成)
  String? _googleApiKey;
  static const String _googleApiKeyKey = 'google_api_key';

  // FLUX Kontext API Key
  String? _fluxKontextApiKey;
  static const String _fluxKontextApiKeyKey = 'flux_kontext_api_key';

  // Tavily API Key (用于网络搜索)
  String? _tavilyApiKey;
  static const String _tavilyApiKeyKey = 'tavily_api_key';

  // Google Search API Key
  String? _googleSearchApiKey;
  static const String _googleSearchApiKeyKey = 'google_search_api_key';

  // Google Search Engine ID
  String? _googleSearchEngineId;
  static const String _googleSearchEngineIdKey = 'google_search_engine_id';

  // 自定义文本提供商 API Key（按 provider 保存）
  Map<String, String> _customProviderApiKeys = {};
  static const String _customProviderApiKeysKey =
      'custom_provider_api_keys_map';

  // 自定义图像提供商 API Key（按 provider 保存）
  Map<String, String> _customImageProviderApiKeys = {};
  static const String _customImageProviderApiKeysKey =
      'custom_image_provider_api_keys_map';

  // ==================== Getters ====================

  String? get openaiApiKey => _openaiApiKey;
  String? get claudeApiKey => _claudeApiKey;
  String? get googleApiKey => _googleApiKey;
  String? get fluxKontextApiKey => _fluxKontextApiKey;
  String? get tavilyApiKey => _tavilyApiKey;
  String? get googleSearchApiKey => _googleSearchApiKey;
  String? get googleSearchEngineId => _googleSearchEngineId;
  Map<String, String> get customProviderApiKeys =>
      Map.unmodifiable(_customProviderApiKeys);
  Map<String, String> get customImageProviderApiKeys =>
      Map.unmodifiable(_customImageProviderApiKeys);

  // 便利 getter：用于向后兼容（旧代码中使用 apiKey 指代 OpenAI）
  String? get apiKey => _openaiApiKey;

  // ==================== 便利方法：根据提供商获取 API Key ====================

  String? getApiKeyForProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return _openaiApiKey;
      case 'google':
      case 'gemini':
        return _googleApiKey;
      case 'anthropic':
      case 'claude':
        return _claudeApiKey;
      default:
        return _getCustomProviderApiKey(provider);
    }
  }

  String? getImageApiKeyForProvider(String provider) {
    switch (provider.trim().toLowerCase()) {
      case 'openai':
        return _openaiApiKey;
      case 'google':
      case 'gemini':
        return _googleApiKey;
      case 'black forest labs':
      case 'blackforestlabs':
      case 'flux':
      case 'bfl':
        return _fluxKontextApiKey;
      case 'stability ai':
      case 'stabilityai':
      case 'stability':
        return _getCustomImageProviderApiKey('Stability AI');
      default:
        return _getCustomImageProviderApiKey(provider) ??
            _getCustomProviderApiKey(provider);
    }
  }

  Future<void> setApiKeyForProvider(String provider, String? key) async {
    switch (provider.toLowerCase()) {
      case 'openai':
        await setOpenaiApiKey(key);
        return;
      case 'google':
      case 'gemini':
        await setGoogleApiKey(key);
        return;
      case 'anthropic':
      case 'claude':
        await setClaudeApiKey(key);
        return;
      default:
        await _setCustomProviderApiKey(provider, key);
    }
  }

  Future<void> setImageApiKeyForProvider(String provider, String? key) async {
    switch (provider.trim().toLowerCase()) {
      case 'openai':
        await setOpenaiApiKey(key);
        return;
      case 'google':
      case 'gemini':
        await setGoogleApiKey(key);
        return;
      case 'black forest labs':
      case 'blackforestlabs':
      case 'flux':
      case 'bfl':
        await setFluxKontextApiKey(key);
        return;
      case 'stability ai':
      case 'stabilityai':
      case 'stability':
        await _setCustomImageProviderApiKey('Stability AI', key);
        return;
      default:
        await _setCustomImageProviderApiKey(provider, key);
    }
  }

  // ==================== 初始化 ====================

  ApiKeyProvider() {
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    _openaiApiKey = prefs.getString(_openaiApiKeyKey);
    _claudeApiKey = prefs.getString(_claudeApiKeyKey);
    _googleApiKey = prefs.getString(_googleApiKeyKey);
    _fluxKontextApiKey = prefs.getString(_fluxKontextApiKeyKey);
    _tavilyApiKey = prefs.getString(_tavilyApiKeyKey);
    _googleSearchApiKey = prefs.getString(_googleSearchApiKeyKey);
    _googleSearchEngineId = prefs.getString(_googleSearchEngineIdKey);
    _customProviderApiKeys = _decodeStringMap(
      prefs.getString(_customProviderApiKeysKey),
      'Error loading custom provider API keys',
    );
    _customImageProviderApiKeys = _decodeStringMap(
      prefs.getString(_customImageProviderApiKeysKey),
      'Error loading custom image provider API keys',
    );
    notifyListeners();
  }

  // ==================== Setters ====================

  Future<void> setOpenaiApiKey(String? key) async {
    _openaiApiKey = _normalizeNullableInput(key);
    final prefs = await SharedPreferences.getInstance();
    await _persistNullableString(prefs, _openaiApiKeyKey, _openaiApiKey);
    notifyListeners();
  }

  Future<void> setClaudeApiKey(String? key) async {
    _claudeApiKey = _normalizeNullableInput(key);
    final prefs = await SharedPreferences.getInstance();
    await _persistNullableString(prefs, _claudeApiKeyKey, _claudeApiKey);
    notifyListeners();
  }

  Future<void> setGoogleApiKey(String? key) async {
    _googleApiKey = _normalizeNullableInput(key);
    final prefs = await SharedPreferences.getInstance();
    await _persistNullableString(prefs, _googleApiKeyKey, _googleApiKey);
    notifyListeners();
  }

  Future<void> setFluxKontextApiKey(String? key) async {
    _fluxKontextApiKey = _normalizeNullableInput(key);
    final prefs = await SharedPreferences.getInstance();
    await _persistNullableString(
      prefs,
      _fluxKontextApiKeyKey,
      _fluxKontextApiKey,
    );
    notifyListeners();
  }

  Future<void> setTavilyApiKey(String? key) async {
    _tavilyApiKey = _normalizeNullableInput(key);
    final prefs = await SharedPreferences.getInstance();
    await _persistNullableString(prefs, _tavilyApiKeyKey, _tavilyApiKey);
    notifyListeners();
  }

  Future<void> setGoogleSearchApiKey(String? key) async {
    _googleSearchApiKey = _normalizeNullableInput(key);
    final prefs = await SharedPreferences.getInstance();
    await _persistNullableString(
      prefs,
      _googleSearchApiKeyKey,
      _googleSearchApiKey,
    );
    notifyListeners();
  }

  Future<void> setGoogleSearchEngineId(String? id) async {
    _googleSearchEngineId = _normalizeNullableInput(id);
    final prefs = await SharedPreferences.getInstance();
    await _persistNullableString(
      prefs,
      _googleSearchEngineIdKey,
      _googleSearchEngineId,
    );
    notifyListeners();
  }

  // ==================== 验证方法 ====================

  /// 检查指定提供商是否已配置 API Key
  bool hasApiKeyForProvider(String provider) {
    final key = getApiKeyForProvider(provider);
    return key != null && key.trim().isNotEmpty;
  }

  /// 检查所有必需的 API Key 是否已配置
  bool get hasAllRequiredKeys {
    return _hasConfiguredValue(_openaiApiKey) ||
        _hasConfiguredValue(_googleApiKey) ||
        _hasConfiguredValue(_claudeApiKey) ||
        _customProviderApiKeys.values.any(_hasConfiguredValue) ||
        _customImageProviderApiKeys.values.any(_hasConfiguredValue);
  }

  // ==================== 导入/导出 ====================

  /// 导出所有 API 密钥为 Map（用于设置导出）
  Map<String, dynamic> toMap() {
    return {
      _openaiApiKeyKey: _openaiApiKey,
      _claudeApiKeyKey: _claudeApiKey,
      _googleApiKeyKey: _googleApiKey,
      _fluxKontextApiKeyKey: _fluxKontextApiKey,
      _tavilyApiKeyKey: _tavilyApiKey,
      _googleSearchApiKeyKey: _googleSearchApiKey,
      _googleSearchEngineIdKey: _googleSearchEngineId,
      _customProviderApiKeysKey: _customProviderApiKeys,
      _customImageProviderApiKeysKey: _customImageProviderApiKeys,
    };
  }

  /// 从 Map 导入 API 密钥
  Future<void> fromMap(Map<String, dynamic> data) async {
    if (data.containsKey(_openaiApiKeyKey)) {
      await setOpenaiApiKey(data[_openaiApiKeyKey] as String?);
    }
    if (data.containsKey(_claudeApiKeyKey)) {
      await setClaudeApiKey(data[_claudeApiKeyKey] as String?);
    }
    if (data.containsKey(_googleApiKeyKey)) {
      await setGoogleApiKey(data[_googleApiKeyKey] as String?);
    }
    if (data.containsKey(_fluxKontextApiKeyKey)) {
      await setFluxKontextApiKey(data[_fluxKontextApiKeyKey] as String?);
    }
    if (data.containsKey(_tavilyApiKeyKey)) {
      await setTavilyApiKey(data[_tavilyApiKeyKey] as String?);
    }
    if (data.containsKey(_googleSearchApiKeyKey)) {
      await setGoogleSearchApiKey(data[_googleSearchApiKeyKey] as String?);
    }
    if (data.containsKey(_googleSearchEngineIdKey)) {
      await setGoogleSearchEngineId(data[_googleSearchEngineIdKey] as String?);
    }
    if (data.containsKey(_customProviderApiKeysKey)) {
      await _importCustomProviderApiKeys(data[_customProviderApiKeysKey]);
    }
    if (data.containsKey(_customImageProviderApiKeysKey)) {
      await _importCustomImageProviderApiKeys(
        data[_customImageProviderApiKeysKey],
      );
    }
  }

  // ==================== Internal helpers ====================

  String? _getCustomProviderApiKey(String provider) {
    final normalizedProvider = provider.trim();
    if (normalizedProvider.isEmpty) {
      return null;
    }

    return _getStoredStringMapValue(_customProviderApiKeys, normalizedProvider);
  }

  String? _getCustomImageProviderApiKey(String provider) {
    final normalizedProvider = provider.trim();
    if (normalizedProvider.isEmpty) {
      return null;
    }

    return _getStoredStringMapValue(
      _customImageProviderApiKeys,
      normalizedProvider,
    );
  }

  Future<void> _setCustomProviderApiKey(String provider, String? key) async {
    final normalizedProvider = provider.trim();
    if (normalizedProvider.isEmpty) {
      return;
    }

    final normalizedKey = _normalizeNullableInput(key);
    final storedKey = _findStoredStringMapKey(
      _customProviderApiKeys,
      normalizedProvider,
    );
    if (normalizedKey == null) {
      _customProviderApiKeys.remove(storedKey ?? normalizedProvider);
    } else {
      _customProviderApiKeys[storedKey ?? normalizedProvider] = normalizedKey;
    }

    final prefs = await SharedPreferences.getInstance();
    await _persistStringMap(
      prefs,
      _customProviderApiKeysKey,
      _customProviderApiKeys,
    );
    notifyListeners();
  }

  Future<void> _importCustomProviderApiKeys(dynamic rawValue) async {
    final parsed = _decodeDynamicStringMap(rawValue);
    _customProviderApiKeys = parsed;

    final prefs = await SharedPreferences.getInstance();
    await _persistStringMap(
      prefs,
      _customProviderApiKeysKey,
      _customProviderApiKeys,
    );
    notifyListeners();
  }

  Future<void> _setCustomImageProviderApiKey(
    String provider,
    String? key,
  ) async {
    final normalizedProvider = provider.trim();
    if (normalizedProvider.isEmpty) {
      return;
    }

    final normalizedKey = _normalizeNullableInput(key);
    final storedKey = _findStoredStringMapKey(
      _customImageProviderApiKeys,
      normalizedProvider,
    );
    if (normalizedKey == null) {
      _customImageProviderApiKeys.remove(storedKey ?? normalizedProvider);
    } else {
      _customImageProviderApiKeys[storedKey ?? normalizedProvider] =
          normalizedKey;
    }

    final prefs = await SharedPreferences.getInstance();
    await _persistStringMap(
      prefs,
      _customImageProviderApiKeysKey,
      _customImageProviderApiKeys,
    );
    notifyListeners();
  }

  Future<void> _importCustomImageProviderApiKeys(dynamic rawValue) async {
    final parsed = _decodeDynamicStringMap(rawValue);
    _customImageProviderApiKeys = parsed;

    final prefs = await SharedPreferences.getInstance();
    await _persistStringMap(
      prefs,
      _customImageProviderApiKeysKey,
      _customImageProviderApiKeys,
    );
    notifyListeners();
  }

  String? _findStoredStringMapKey(Map<String, String> values, String key) {
    if (values.containsKey(key)) {
      return key;
    }

    for (final storedKey in values.keys) {
      if (storedKey.toLowerCase() == key.toLowerCase()) {
        return storedKey;
      }
    }

    return null;
  }

  String? _getStoredStringMapValue(Map<String, String> values, String key) {
    final directMatch = values[key];
    if (directMatch != null) {
      return directMatch;
    }

    final storedKey = _findStoredStringMapKey(values, key);
    if (storedKey == null) {
      return null;
    }

    return values[storedKey];
  }

  Map<String, String> _decodeStringMap(String? encoded, String debugLabel) {
    if (encoded == null || encoded.isEmpty) {
      return {};
    }

    try {
      final decoded = json.decode(encoded) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value?.toString() ?? ''))
        ..removeWhere((key, value) => value.trim().isEmpty);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$debugLabel: $error');
      }
      return {};
    }
  }

  Map<String, String> _decodeDynamicStringMap(dynamic rawValue) {
    if (rawValue == null) {
      return {};
    }

    if (rawValue is String) {
      return _decodeStringMap(
        rawValue,
        'Error parsing custom provider API map',
      );
    }

    if (rawValue is Map) {
      return rawValue.map(
        (key, value) =>
            MapEntry(key.toString(), value?.toString().trim() ?? ''),
      )..removeWhere((key, value) => value.isEmpty);
    }

    return {};
  }

  String? _normalizeNullableInput(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _persistNullableString(
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

  Future<void> _persistStringMap(
    SharedPreferences prefs,
    String key,
    Map<String, String> values,
  ) async {
    if (values.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, json.encode(values));
  }

  bool _hasConfiguredValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
