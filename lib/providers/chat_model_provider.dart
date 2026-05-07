import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/available_model.dart';
import '../models/available_model.dart' as available_model;
import '../models/model_registry.dart';

/// 负责聊天相关的模型配置和提供商管理
/// 职责：选择聊天模型、管理提供商、配置提供商 URL
class ChatModelProvider with ChangeNotifier {
  final ModelRegistry? modelRegistry;

  // 当前选定的聊天模型提供商
  String _selectedProvider = 'OpenAI';
  static const String _selectedProviderKey = 'selected_model_provider';

  // 当前选定的聊天模型
  String _selectedModel = 'gpt-5.5';
  static const String _selectedModelKey = 'openai_selected_model';

  // 兼容旧版本的单一 URL 存储键
  static const String _providerUrlKey = 'openai_provider_url';

  // 当前 provider 的自定义 URL（按 provider 保存）
  Map<String, String> _providerUrls = {};
  static const String _providerUrlsKey = 'chat_provider_urls_map';

  // 每个 provider 最近一次选择的模型
  Map<String, String> _providerSelectedModels = {};
  static const String _providerSelectedModelsKey =
      'chat_provider_selected_models_map';

  // 兼容旧版本的“当前 provider 附加自定义模型”存储键
  static const String _legacyCustomModelsKey = 'custom_models_list';

  // 当前 provider 附加的自定义模型（按 provider 保存）
  Map<String, List<String>> _customModelsByProvider = {};
  static const String _customModelsByProviderKey =
      'chat_custom_models_by_provider_map';

  // 自定义提供商及其基础模型
  Map<String, List<String>> _customProviders = {};
  static const String _customProvidersKey = 'custom_providers_map';

  // 预设的提供商基础 URL
  static const Map<String, String> defaultBaseUrls = {
    'OpenAI': 'https://api.openai.com/v1',
    'Google': 'https://generativelanguage.googleapis.com/v1beta',
    'Anthropic': 'https://api.anthropic.com/v1',
  };

  // 分类的预设模型（按提供商组织）
  final Map<String, List<String>> _categorizedPresetModels = {
    'OpenAI': [
      'gpt-5.5',
      'gpt-5.4',
      'gpt-5.4-mini',
      'gpt-5.4-nano',
      'gpt-5.1',
      'gpt-5-mini',
      'gpt-5-nano',
      'gpt-4.1',
      'gpt-4.1-mini',
      'gpt-4.1-nano',
      'gpt-4o',
      'gpt-4o-mini',
    ],
    'Google': [
      'gemini-2.5-pro',
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash',
    ],
    'Anthropic': [
      'claude-opus-4-1',
      'claude-sonnet-4-0',
      'claude-3-7-sonnet-latest',
      'claude-3-5-haiku-latest',
    ],
  };

  // ==================== Getters ====================

  String get selectedProvider => _selectedProvider;
  String get selectedModel => _selectedModel;
  String? get rawProviderUrl => _providerUrls[_selectedProvider];
  List<String> get customModels =>
      List.unmodifiable(_customModelsByProvider[_selectedProvider] ?? const []);

  /// 获取当前选定提供商的所有可用模型（预设 + 自定义 provider + 当前 provider 附加模型）
  List<String> get availableModels {
    return _buildAvailableModelsForProvider(_selectedProvider);
  }

  /// 获取所有提供商名称（预设 + 自定义）
  List<String> get allProviderNames {
    final names = <String>[
      ...defaultBaseUrls.keys,
      ..._customProviders.keys,
      ..._customModelsByProvider.keys,
      ..._providerUrls.keys,
      ..._providerSelectedModels.keys,
    ];
    return List.unmodifiable(names.toSet().toList());
  }

  /// 获取当前提供商的解析后 URL（优先自定义，其次默认）
  String get providerUrl => _resolveProviderUrlForProvider(_selectedProvider);

  // ==================== 初始化 ====================

  ChatModelProvider({this.modelRegistry}) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _selectedProvider = prefs.getString(_selectedProviderKey) ?? 'OpenAI';
    _selectedModel = prefs.getString(_selectedModelKey) ?? 'gpt-5.5';

    _customProviders = _decodeStringListMap(
      prefs.getString(_customProvidersKey),
      'Error loading custom providers',
    );
    _customModelsByProvider = _decodeStringListMap(
      prefs.getString(_customModelsByProviderKey),
      'Error loading provider custom models',
    );
    _providerUrls = _decodeStringMap(
      prefs.getString(_providerUrlsKey),
      'Error loading provider URL map',
    );
    _providerSelectedModels = _decodeStringMap(
      prefs.getString(_providerSelectedModelsKey),
      'Error loading provider selected model map',
    );

    final legacyProviderUrl = _normalizeNullableInput(
      prefs.getString(_providerUrlKey),
    );
    if (legacyProviderUrl != null &&
        !_providerUrls.containsKey(_selectedProvider)) {
      _providerUrls[_selectedProvider] = legacyProviderUrl;
    }

    final legacyCustomModels =
        prefs.getStringList(_legacyCustomModelsKey) ?? const <String>[];
    if (legacyCustomModels.isNotEmpty &&
        (_customModelsByProvider[_selectedProvider] ?? const <String>[])
            .isEmpty) {
      _customModelsByProvider[_selectedProvider] =
          legacyCustomModels
              .map((model) => model.trim())
              .where((model) => model.isNotEmpty)
              .toSet()
              .toList();
    }

    if (!defaultBaseUrls.containsKey(_selectedProvider) &&
        !_hasAnyModelsForProvider(_selectedProvider) &&
        _selectedModel.trim().isNotEmpty) {
      _customProviders[_selectedProvider] = <String>[_selectedModel];
    }

    _providerSelectedModels[_selectedProvider] = _selectedModel;
    _validateSelectedModelForProvider();
    await _persistProviderMaps(prefs);
    await _persistLegacySelectedProviderState(prefs);
    await syncModelsToRegistry();
    notifyListeners();
  }

  // ==================== 模型选择 ====================

  /// 设置选定的聊天模型
  Future<void> setSelectedModel(String model) async {
    final normalizedModel = model.trim();
    if (normalizedModel.isEmpty) {
      return;
    }

    final available = _buildAvailableModelsForProvider(_selectedProvider);
    if (!available.contains(normalizedModel) ||
        _selectedModel == normalizedModel) {
      return;
    }

    _selectedModel = normalizedModel;
    _providerSelectedModels[_selectedProvider] = normalizedModel;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedModelKey, normalizedModel);
    await _persistProviderSelectedModels(prefs);
    await syncModelsToRegistry();
    notifyListeners();
  }

  /// 设置选定的提供商
  Future<void> setSelectedProvider(String provider) async {
    final normalizedProvider = provider.trim();
    if (normalizedProvider.isEmpty || _selectedProvider == normalizedProvider) {
      return;
    }

    _selectedProvider = normalizedProvider;
    _validateSelectedModelForProvider();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedProviderKey, _selectedProvider);
    await prefs.setString(_selectedModelKey, _selectedModel);
    await _persistProviderMaps(prefs);
    await _persistLegacySelectedProviderState(prefs);
    await syncModelsToRegistry();
    notifyListeners();
  }

  /// 设置当前或指定提供商的 URL
  Future<void> setProviderUrl(String? url, {String? provider}) async {
    final targetProvider = (provider ?? _selectedProvider).trim();
    if (targetProvider.isEmpty) {
      return;
    }

    final normalizedUrl = _normalizeNullableInput(url);
    final storedKey = _findStoredProviderKey(_providerUrls, targetProvider);

    if (normalizedUrl == null) {
      _providerUrls.remove(storedKey ?? targetProvider);
    } else {
      _providerUrls[storedKey ?? targetProvider] = normalizedUrl;
    }

    final prefs = await SharedPreferences.getInstance();
    await _persistProviderUrls(prefs);
    await syncModelsToRegistry();
    notifyListeners();
  }

  // ==================== 自定义模型管理 ====================

  /// 添加当前提供商的附加自定义模型
  Future<void> addCustomModel(String model) async {
    final normalizedModel = model.trim();
    if (normalizedModel.isEmpty) {
      return;
    }

    final currentModels = _customModelsByProvider.putIfAbsent(
      _selectedProvider,
      () => <String>[],
    );
    if (_buildAvailableModelsForProvider(_selectedProvider).contains(
      normalizedModel,
    )) {
      return;
    }

    currentModels.add(normalizedModel);

    final prefs = await SharedPreferences.getInstance();
    await _persistCustomModelsByProvider(prefs);
    await syncModelsToRegistry();
    notifyListeners();
  }

  /// 移除当前提供商的附加自定义模型
  Future<void> removeCustomModel(String model) async {
    final models = _customModelsByProvider[_selectedProvider];
    if (models == null || !models.remove(model)) {
      return;
    }

    if (models.isEmpty) {
      _customModelsByProvider.remove(_selectedProvider);
    }

    _validateSelectedModelForProvider();

    final prefs = await SharedPreferences.getInstance();
    await _persistCustomModelsByProvider(prefs);
    await prefs.setString(_selectedModelKey, _selectedModel);
    await _persistProviderSelectedModels(prefs);
    await syncModelsToRegistry();
    notifyListeners();
  }

  /// 添加自定义提供商及其基础模型
  Future<void> addCustomProvider(String provider, List<String> models) async {
    final normalizedProvider = provider.trim();
    final normalizedModels =
        models
            .map((model) => model.trim())
            .where((model) => model.isNotEmpty)
            .toSet()
            .toList();

    if (normalizedProvider.isEmpty ||
        normalizedModels.isEmpty ||
        defaultBaseUrls.containsKey(normalizedProvider)) {
      return;
    }

    final existingModels = _customProviders[normalizedProvider] ?? [];
    _customProviders[normalizedProvider] = {
      ...existingModels,
      ...normalizedModels,
    }.toList();

    final prefs = await SharedPreferences.getInstance();
    await _persistCustomProviders(prefs);
    await syncModelsToRegistry();
    notifyListeners();
  }

  /// 移除自定义提供商
  Future<void> removeCustomProvider(String provider) async {
    final storedProviderKey = _findStoredProviderKey(
      _customProviders,
      provider.trim(),
    );
    final targetProvider = storedProviderKey ?? provider.trim();
    if (targetProvider.isEmpty) {
      return;
    }

    _customProviders.remove(targetProvider);
    _customModelsByProvider.remove(targetProvider);
    _providerUrls.remove(targetProvider);
    _providerSelectedModels.remove(targetProvider);

    if (_selectedProvider == targetProvider) {
      _selectedProvider = 'OpenAI';
      _validateSelectedModelForProvider();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedProviderKey, _selectedProvider);
    await prefs.setString(_selectedModelKey, _selectedModel);
    await _persistProviderMaps(prefs);
    await _persistLegacySelectedProviderState(prefs);
    await syncModelsToRegistry();
    notifyListeners();
  }

  // ==================== 验证和同步 ====================

  /// 验证所选模型是否与提供商兼容
  void _validateSelectedModelForProvider() {
    final available = _buildAvailableModelsForProvider(_selectedProvider);
    final savedModel = _providerSelectedModels[_selectedProvider];

    if (savedModel != null && available.contains(savedModel)) {
      _selectedModel = savedModel;
      return;
    }

    if (available.contains(_selectedModel)) {
      _providerSelectedModels[_selectedProvider] = _selectedModel;
      return;
    }

    if (available.isNotEmpty) {
      _selectedModel = available.first;
      _providerSelectedModels[_selectedProvider] = _selectedModel;
      return;
    }

    _selectedProvider = 'OpenAI';
    _selectedModel = _categorizedPresetModels['OpenAI']!.first;
    _providerSelectedModels[_selectedProvider] = _selectedModel;
  }

  /// 将模型同步到模型注册表
  Future<void> syncModelsToRegistry() async {
    if (modelRegistry == null) {
      return;
    }

    modelRegistry!.clearType(available_model.ModelType.text);

    for (final entry in _categorizedPresetModels.entries) {
      for (final model in entry.value) {
        modelRegistry!.registerModel(
          AvailableModel(
            id: model,
            name: model,
            provider: entry.key,
            type: available_model.ModelType.text,
            supportsStreaming: entry.key != 'Google',
            baseUrl: _resolveProviderUrlForProvider(entry.key),
          ),
        );
      }
    }

    for (final entry in _customProviders.entries) {
      for (final model in entry.value) {
        modelRegistry!.registerModel(
          AvailableModel(
            id: model,
            name: model,
            provider: entry.key,
            type: available_model.ModelType.text,
            supportsStreaming: true,
            baseUrl: _resolveProviderUrlForProvider(entry.key),
          ),
        );
      }
    }

    for (final entry in _customModelsByProvider.entries) {
      for (final model in entry.value) {
        modelRegistry!.registerModel(
          AvailableModel(
            id: model,
            name: model,
            provider: entry.key,
            type: available_model.ModelType.text,
            supportsStreaming: entry.key != 'Google',
            baseUrl: _resolveProviderUrlForProvider(entry.key),
          ),
        );
      }
    }
  }

  // ==================== 导入/导出 ====================

  /// 导出聊天模型配置为 Map
  Map<String, dynamic> toMap() {
    return {
      _selectedProviderKey: _selectedProvider,
      _selectedModelKey: _selectedModel,
      _providerUrlKey: rawProviderUrl,
      _legacyCustomModelsKey: customModels,
      _customProvidersKey: _customProviders,
      _providerUrlsKey: _providerUrls,
      _providerSelectedModelsKey: _providerSelectedModels,
      _customModelsByProviderKey: _customModelsByProvider,
    };
  }

  /// 从 Map 导入聊天模型配置
  Future<void> fromMap(Map<String, dynamic> data) async {
    final importedProvider =
        (data[_selectedProviderKey] as String?)?.trim() ?? _selectedProvider;
    final importedModel =
        (data[_selectedModelKey] as String?)?.trim() ?? _selectedModel;

    _selectedProvider = importedProvider.isEmpty ? 'OpenAI' : importedProvider;
    _selectedModel = importedModel.isEmpty
        ? _categorizedPresetModels['OpenAI']!.first
        : importedModel;

    if (data.containsKey(_customProvidersKey)) {
      _customProviders = _decodeDynamicStringListMap(
        data[_customProvidersKey],
        'Error parsing custom providers JSON',
      );
    }

    if (data.containsKey(_customModelsByProviderKey)) {
      _customModelsByProvider = _decodeDynamicStringListMap(
        data[_customModelsByProviderKey],
        'Error parsing provider custom models JSON',
      );
    } else if (data.containsKey(_legacyCustomModelsKey)) {
      final legacyModels = data[_legacyCustomModelsKey];
      if (legacyModels is List) {
        _customModelsByProvider[_selectedProvider] =
            legacyModels
                .map((model) => model.toString().trim())
                .where((model) => model.isNotEmpty)
                .toSet()
                .toList();
      }
    }

    if (data.containsKey(_providerUrlsKey)) {
      _providerUrls = _decodeDynamicStringMap(data[_providerUrlsKey]);
    }
    final legacyProviderUrl = _normalizeNullableInput(
      data[_providerUrlKey] as String?,
    );
    if (legacyProviderUrl != null) {
      _providerUrls[_selectedProvider] = legacyProviderUrl;
    }

    if (data.containsKey(_providerSelectedModelsKey)) {
      _providerSelectedModels = _decodeDynamicStringMap(
        data[_providerSelectedModelsKey],
      );
    }

    if (!defaultBaseUrls.containsKey(_selectedProvider) &&
        !_hasAnyModelsForProvider(_selectedProvider) &&
        _selectedModel.isNotEmpty) {
      _customProviders[_selectedProvider] = <String>[_selectedModel];
    }

    _providerSelectedModels[_selectedProvider] = _selectedModel;
    _validateSelectedModelForProvider();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedProviderKey, _selectedProvider);
    await prefs.setString(_selectedModelKey, _selectedModel);
    await _persistProviderMaps(prefs);
    await _persistLegacySelectedProviderState(prefs);
    await syncModelsToRegistry();
    notifyListeners();
  }

  // ==================== Internal helpers ====================

  List<String> _buildAvailableModelsForProvider(String provider) {
    final modelsToShow = <String>[];
    final presetModels = _categorizedPresetModels[provider];
    if (presetModels != null) {
      modelsToShow.addAll(presetModels);
    }

    final customProviderModels = _customProviders[provider];
    if (customProviderModels != null) {
      modelsToShow.addAll(customProviderModels);
    }

    final customModels = _customModelsByProvider[provider];
    if (customModels != null) {
      modelsToShow.addAll(customModels);
    }

    return List.unmodifiable(modelsToShow.toSet().toList());
  }

  bool _hasAnyModelsForProvider(String provider) {
    return _buildAvailableModelsForProvider(provider).isNotEmpty;
  }

  String _resolveProviderUrlForProvider(String provider) {
    String baseUrl =
        _providerUrls[provider]?.trim() ??
        defaultBaseUrls[provider] ??
        defaultBaseUrls['OpenAI']!;

    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    if (defaultBaseUrls.containsKey(provider)) {
      return baseUrl;
    }

    baseUrl = baseUrl.replaceAll(RegExp(r'/chat/completions.*$'), '');
    baseUrl = baseUrl.replaceAll(RegExp(r'/models(?!/v\d+).*$'), '');

    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    try {
      final uri = Uri.parse(baseUrl);
      final path = uri.path;
      final hasVersionPath =
          RegExp(r'/(v\d+|v\d+beta|v\d+alpha)$').hasMatch(path);

      if (!hasVersionPath && (path.isEmpty || path == '/')) {
        final buffer = StringBuffer('${uri.scheme}://${uri.host}');
        if (uri.hasPort && uri.port != 80 && uri.port != 443) {
          buffer.write(':${uri.port}');
        }
        buffer.write('/v1');
        return buffer.toString();
      }
    } catch (_) {
      if (!baseUrl.contains('/v') && !baseUrl.contains('/api/')) {
        return '$baseUrl/v1';
      }
    }

    return baseUrl;
  }

  Future<void> _persistProviderMaps(SharedPreferences prefs) async {
    await _persistCustomProviders(prefs);
    await _persistCustomModelsByProvider(prefs);
    await _persistProviderUrls(prefs);
    await _persistProviderSelectedModels(prefs);
  }

  Future<void> _persistCustomProviders(SharedPreferences prefs) async {
    if (_customProviders.isEmpty) {
      await prefs.remove(_customProvidersKey);
      return;
    }
    await prefs.setString(_customProvidersKey, json.encode(_customProviders));
  }

  Future<void> _persistCustomModelsByProvider(SharedPreferences prefs) async {
    final currentModels = _customModelsByProvider[_selectedProvider] ?? const [];
    await prefs.setStringList(_legacyCustomModelsKey, currentModels);

    if (_customModelsByProvider.isEmpty) {
      await prefs.remove(_customModelsByProviderKey);
      return;
    }
    await prefs.setString(
      _customModelsByProviderKey,
      json.encode(_customModelsByProvider),
    );
  }

  Future<void> _persistProviderUrls(SharedPreferences prefs) async {
    if (_providerUrls.isEmpty) {
      await prefs.remove(_providerUrlsKey);
    } else {
      await prefs.setString(_providerUrlsKey, json.encode(_providerUrls));
    }
    await _persistLegacySelectedProviderState(prefs);
  }

  Future<void> _persistProviderSelectedModels(SharedPreferences prefs) async {
    if (_providerSelectedModels.isEmpty) {
      await prefs.remove(_providerSelectedModelsKey);
      return;
    }
    await prefs.setString(
      _providerSelectedModelsKey,
      json.encode(_providerSelectedModels),
    );
  }

  Future<void> _persistLegacySelectedProviderState(
    SharedPreferences prefs,
  ) async {
    final currentRawUrl = rawProviderUrl;
    if (currentRawUrl == null) {
      await prefs.remove(_providerUrlKey);
    } else {
      await prefs.setString(_providerUrlKey, currentRawUrl);
    }
  }

  Map<String, String> _decodeStringMap(String? encoded, String debugLabel) {
    if (encoded == null || encoded.isEmpty) {
      return {};
    }

    try {
      final decoded = json.decode(encoded) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, value?.toString().trim() ?? ''),
      )..removeWhere((key, value) => value.isEmpty);
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
      return _decodeStringMap(rawValue, 'Error parsing provider string map');
    }

    if (rawValue is Map) {
      return rawValue.map(
        (key, value) => MapEntry(
          key.toString(),
          value?.toString().trim() ?? '',
        ),
      )..removeWhere((key, value) => value.isEmpty);
    }

    return {};
  }

  Map<String, List<String>> _decodeStringListMap(
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
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$debugLabel: $error');
      }
      return {};
    }
  }

  Map<String, List<String>> _decodeDynamicStringListMap(
    dynamic rawValue,
    String debugLabel,
  ) {
    if (rawValue == null) {
      return {};
    }

    if (rawValue is String) {
      return _decodeStringListMap(rawValue, debugLabel);
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

  String? _normalizeNullableInput(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _findStoredProviderKey(
    Map<String, dynamic> values,
    String targetProvider,
  ) {
    if (values.containsKey(targetProvider)) {
      return targetProvider;
    }

    for (final provider in values.keys) {
      if (provider.toLowerCase() == targetProvider.toLowerCase()) {
        return provider;
      }
    }

    return null;
  }
}
