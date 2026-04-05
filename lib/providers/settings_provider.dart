import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import ModelType enum
import 'package:chibot/utils/settings_xml_handler.dart';
import 'package:chibot/services/flux_kontext_service.dart';
import 'package:chibot/services/flux_krea_service.dart';
import 'package:chibot/services/google_image_service.dart';
import 'dart:convert';
import '../models/model_registry.dart';
import '../models/available_model.dart' as available_model;

class SettingsProvider with ChangeNotifier {
  final ModelRegistry? modelRegistry;
  String _selectedProvider = 'OpenAI'; // 新增：默认提供商为 OpenAI
  String? _apiKey;
  String? _imageApiKey; // Added for image API key
  String? _claudeApiKey; // Added for Claude API key
  String _selectedModel = 'gpt-4o'; // 默认模型
  String? _providerUrl; // 新增：模型 Provider URL
  List<String> _customModels = []; // 新增：自定义模型列表
  Map<String, List<String>> _customProviders = {}; // 新增：自定义提供商及其模型列表

  // Image Generation Settings
  String _selectedImageProvider = 'OpenAI'; // Default image provider
  String _selectedImageModel = 'dall-e-3'; // Default image model
  String? _imageProviderUrl; // URL for the image generation provider
  List<String> _customImageModels = [];
  Map<String, List<String>> _customImageProviders =
      {}; // Added to force recompile
  String? _bflAspectRatio;
  static const String _bflAspectRatioKey = 'bfl_aspect_ratio';

  available_model.ModelType _selectedModelType =
      available_model.ModelType.text; // Default to text model type

  static const String _apiKeyKey = 'openai_api_key';
  static const String _imageApiKeyKey =
      'image_api_key'; // Added for image API key
  static const String _claudeApiKeyKey =
      'claude_api_key'; // Added for Claude API key
  static const String _selectedModelKey = 'openai_selected_model';
  static const String _providerUrlKey = 'openai_provider_url';
  static const String _customModelsKey = 'custom_models_list';
  static const String _selectedProviderKey = 'selected_model_provider';
  static const String _customProvidersKey = 'custom_providers_map';
  static const String _selectedModelTypeKey = 'selected_model_type';

  // Keys for Image Generation Settings
  static const String _selectedImageProviderKey = 'selected_image_provider';
  static const String _selectedImageModelKey = 'selected_image_model';
  static const String _imageProviderUrlKey = 'image_provider_url';
  static const String _customImageModelsKey = 'custom_image_models_list';
  static const String _customImageProvidersKey = 'custom_image_providers_map';

  String? _tavilyApiKey;
  static const String _tavilyApiKeyKey = 'tavily_api_key';

  // Google Search Settings
  String? _googleSearchApiKey;
  String? _googleSearchEngineId;
  bool _googleSearchEnabled = false;
  int _googleSearchResultCount = 10;
  String _googleSearchProvider = 'googleCustomSearch';

  static const String _googleSearchApiKeyKey = 'google_search_api_key';
  static const String _googleSearchEngineIdKey = 'google_search_engine_id';
  static const String _googleSearchEnabledKey = 'google_search_enabled';
  static const String _googleSearchResultCountKey =
      'google_search_result_count';
  static const String _googleSearchProviderKey = 'google_search_provider';

  bool _tavilySearchEnabled = false;
  static const String _tavilySearchEnabledKey = 'tavily_search_enabled';

  String? _fluxKontextApiKey; // Added for FLUX Kontext API key
  static const String _fluxKontextApiKeyKey = 'flux_kontext_api_key';

  // Video Generation Settings (Veo3)
  String? _veo3ApiKey;
  String _selectedVideoProvider = 'Google Veo3';
  String _videoResolution = '720p';
  String _videoDuration = '10s';
  String _videoQuality = 'standard';
  String _videoAspectRatio = '16:9';

  static const String _veo3ApiKeyKey = 'veo3_api_key';
  static const String _selectedVideoProviderKey = 'selected_video_provider';
  static const String _videoResolutionKey = 'video_resolution';
  static const String _videoDurationKey = 'video_duration';
  static const String _videoQualityKey = 'video_quality';
  static const String _videoAspectRatioKey = 'video_aspect_ratio';
  static const String _customOpenAiModelsKey = 'custom_openai_models';
  static const String _customOpenAiBaseUrlsKey = 'custom_openai_base_urls';
  static const String _customOpenAiApiKeysKey = 'custom_openai_api_keys';

  // 默认的各提供商 API 基础 URL
  static const Map<String, String> defaultBaseUrls = {
    'OpenAI': 'https://api.openai.com/v1',
    'Google':
        'https://generativelanguage.googleapis.com/v1beta', // Gemini API 基础 URL
    'Anthropic': 'https://api.anthropic.com/v1', // Claude API 基础 URL
  };

  // Default base URLs for image generation providers
  static const Map<String, String> defaultImageBaseUrls = {
    'OpenAI': 'https://api.openai.com/v1',
    'Stability AI':
        'https://api.stability.ai', // Example, confirm actual base URL
    'Black Forest Labs': 'https://api.bfl.ai/v1',
    'Google': 'https://generativelanguage.googleapis.com',
  };

  // Default base URLs for video generation providers
  static const Map<String, String> defaultVideoBaseUrls = {
    'Google Veo3': 'https://generativelanguage.googleapis.com/v1beta',
  };

  // 可选模型列表
  final List<String> _presetModels = [
    'gpt-4',
    'gpt-4o',
    'gpt-4.1',
    'gemini-2.0-flash',
    'gemini-2.5-pro-preview-06-05',
    'gemini-2.5-flash-preview-05-20',
  ];

  // 分类预设模型
  final Map<String, List<String>> _categorizedPresetModels = {
    'OpenAI': ['gpt-4', 'gpt-4o', 'gpt-4.1'],
    'Google': [
      'gemini-2.0-flash',
      'gemini-2.5-pro-preview-06-05',
      'gemini-2.5-flash-preview-05-20',
    ],
    'Anthropic': ['claude-3-5-sonnet-20241022', 'claude-3-5-haiku-20241022'],
  };

  // Preset models for image generation
  final Map<String, List<String>> _categorizedPresetImageModels = {
    'OpenAI': ['dall-e-3'],
    'Stability AI': [
      'stable-diffusion-xl-1024-v1-0', // Example model ID
      'stable-diffusion-v1-6', // Example model ID
      // Add other Stability AI models as needed
    ],
    'Black Forest Labs': ['flux-kontext-pro', 'flux-kontext-dev', 'flux-krea-dev'],
    'Google': GoogleImageService.getSupportedModels(),
  };

  // Getter for all provider names (preset and custom)
  List<String> get allProviderNames =>
      _buildAllProviderNames(defaultBaseUrls, _customProviders);

  SettingsProvider({this.modelRegistry}) {
    _loadSettings();
  }

  String? get apiKey => _apiKey;
  String get selectedModel => _selectedModel;
  String get selectedProvider => _selectedProvider;
  String? get imageApiKey => _imageApiKey; // Added getter for image API key
  String? get claudeApiKey => _claudeApiKey; // Added getter for Claude API key
  String? get tavilyApiKey => _tavilyApiKey;
  String? get googleSearchApiKey => _googleSearchApiKey;
  String? get googleSearchEngineId => _googleSearchEngineId;
  bool get googleSearchEnabled => _googleSearchEnabled;
  int get googleSearchResultCount => _googleSearchResultCount;
  String get googleSearchProvider => _googleSearchProvider;
  bool get tavilySearchEnabled => _tavilySearchEnabled;
  String? get fluxKontextApiKey => _fluxKontextApiKey;
  String? get bflAspectRatio => _bflAspectRatio;
  set bflAspectRatio(String? value) {
    _bflAspectRatio = value;
    _saveBflAspectRatio();
    notifyListeners();
  }

  Future<void> _saveBflAspectRatio() async {
    final prefs = await SharedPreferences.getInstance();
    if (_bflAspectRatio != null) {
      await prefs.setString(_bflAspectRatioKey, _bflAspectRatio!);
    } else {
      await prefs.remove(_bflAspectRatioKey);
    }
  }

  String _resolveBaseUrl(
    String? customUrl,
    String provider,
    Map<String, String> defaultUrls,
  ) {
    final baseUrl =
        customUrl?.trim() ?? defaultUrls[provider] ?? defaultUrls['OpenAI']!;
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  String? _normalizeNullableInput(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _persistNullableString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value);
  }

  Future<void> _setStringSetting(
    String key,
    String value,
    void Function(String value) assign,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    assign(value);
    await prefs.setString(key, value);
    notifyListeners();
  }

  Future<void> _setBoolSetting(
    String key,
    bool value,
    void Function(bool value) assign,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    assign(value);
    await prefs.setBool(key, value);
    notifyListeners();
  }

  Future<void> _setIntSetting(
    String key,
    int value,
    void Function(int value) assign,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    assign(value);
    await prefs.setInt(key, value);
    notifyListeners();
  }

  Future<void> _setSelectedModelIfAvailable({
    required String newModel,
    required List<String> availableModels,
    required String key,
    required void Function(String value) assign,
  }) async {
    if (!availableModels.contains(newModel)) return;
    await _setStringSetting(key, newModel, assign);
  }

  Future<void> _setProviderUrlInternal({
    required String? newUrl,
    required String key,
    required void Function(String? value) assign,
    required VoidCallback validate,
  }) async {
    final normalizedUrl = _normalizeNullableInput(newUrl);
    final prefs = await SharedPreferences.getInstance();
    assign(normalizedUrl);
    await _persistNullableString(prefs, key, normalizedUrl);
    notifyListeners();
    validate();
  }

  List<String> _normalizeModelNames(List<String> models) {
    return models.map((m) => m.trim()).where((m) => m.isNotEmpty).toList();
  }

  Future<void> _persistStringListSetting(String key, List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, values);
  }

  Future<void> _addCustomProviderWithModels({
    required String providerName,
    required List<String> models,
    required Map<String, String> defaultUrls,
    required Map<String, List<String>> targetProviders,
    required String storageKey,
  }) async {
    final normalizedProvider = providerName.trim();
    if (normalizedProvider.isEmpty || models.isEmpty) return;
    if (defaultUrls.containsKey(normalizedProvider)) return;

    targetProviders[normalizedProvider] = _normalizeModelNames(models);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, json.encode(targetProviders));
    notifyListeners();
  }

  Future<void> _removeCustomModelInternal({
    required String modelName,
    required List<String> targetModels,
    required String storageKey,
    required String selectedModel,
    required VoidCallback validateSelection,
  }) async {
    if (!targetModels.remove(modelName)) return;
    await _persistStringListSetting(storageKey, targetModels);
    if (selectedModel == modelName) {
      validateSelection();
    }
    notifyListeners();
  }

  Future<void> _addCustomTextModelInternal(String modelName) async {
    final normalizedName = modelName.trim();
    if (normalizedName.isEmpty ||
        _customModels.contains(normalizedName) ||
        _presetModels.contains(normalizedName)) {
      return;
    }
    _customModels.add(normalizedName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customModelsKey, _customModels);
    notifyListeners();
    _validateSelectedModelForProvider();
  }

  Map<String, List<String>> _decodeProvidersMap(
    String encoded,
    String errorPrefix,
  ) {
    try {
      final decoded = json.decode(encoded) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$errorPrefix: $e');
      }
      return {};
    }
  }

  Future<void> _importStringSetting(
    Map<String, dynamic> settingsMap,
    SharedPreferences prefs,
    String key,
    void Function(String value) assign,
  ) async {
    final value = settingsMap[key];
    if (value is! String) return;
    await prefs.setString(key, value);
    assign(value);
  }

  Future<void> _importBoolSetting(
    Map<String, dynamic> settingsMap,
    SharedPreferences prefs,
    String key,
    void Function(bool value) assign,
  ) async {
    final value = settingsMap[key];
    if (value is! bool) return;
    await prefs.setBool(key, value);
    assign(value);
  }

  Future<void> _importIntSetting(
    Map<String, dynamic> settingsMap,
    SharedPreferences prefs,
    String key,
    void Function(int value) assign,
  ) async {
    final value = settingsMap[key];
    if (value is! int) return;
    await prefs.setInt(key, value);
    assign(value);
  }

  Future<void> _importStringListSetting(
    Map<String, dynamic> settingsMap,
    SharedPreferences prefs,
    String key,
    void Function(List<String> value) assign,
  ) async {
    final value = settingsMap[key];
    if (value is! List) return;
    final listValue = List<String>.from(value);
    await prefs.setStringList(key, listValue);
    assign(listValue);
  }

  void _addOptionalExportStringList(
    SharedPreferences prefs,
    Map<String, dynamic> settingsMap,
    String key,
  ) {
    if (!prefs.containsKey(key)) return;
    settingsMap[key] = prefs.getStringList(key);
  }

  Map<String, dynamic> _buildExportSettingsMap(SharedPreferences prefs) {
    final settingsMap = <String, dynamic>{};
    settingsMap[_apiKeyKey] = prefs.getString(_apiKeyKey);
    settingsMap[_imageApiKeyKey] = prefs.getString(_imageApiKeyKey);
    settingsMap[_claudeApiKeyKey] = prefs.getString(_claudeApiKeyKey);
    settingsMap[_tavilyApiKeyKey] = prefs.getString(_tavilyApiKeyKey);
    settingsMap[_fluxKontextApiKeyKey] = prefs.getString(_fluxKontextApiKeyKey);
    settingsMap[_googleSearchApiKeyKey] = prefs.getString(_googleSearchApiKeyKey);
    settingsMap[_googleSearchEngineIdKey] = prefs.getString(
      _googleSearchEngineIdKey,
    );
    settingsMap[_googleSearchEnabledKey] = prefs.getBool(_googleSearchEnabledKey);
    settingsMap[_googleSearchResultCountKey] = prefs.getInt(
      _googleSearchResultCountKey,
    );
    settingsMap[_googleSearchProviderKey] = prefs.getString(
      _googleSearchProviderKey,
    );
    settingsMap[_tavilySearchEnabledKey] = prefs.getBool(_tavilySearchEnabledKey);
    settingsMap[_selectedModelKey] = prefs.getString(_selectedModelKey);
    settingsMap[_providerUrlKey] = prefs.getString(_providerUrlKey);
    settingsMap[_customModelsKey] = prefs.getStringList(_customModelsKey);
    settingsMap[_selectedProviderKey] = prefs.getString(_selectedProviderKey);
    settingsMap[_customProvidersKey] = prefs.getString(_customProvidersKey);
    settingsMap[_selectedModelTypeKey] = prefs.getInt(_selectedModelTypeKey);
    settingsMap[_selectedImageProviderKey] = prefs.getString(
      _selectedImageProviderKey,
    );
    settingsMap[_selectedImageModelKey] = prefs.getString(_selectedImageModelKey);
    settingsMap[_imageProviderUrlKey] = prefs.getString(_imageProviderUrlKey);
    settingsMap[_customImageModelsKey] = prefs.getStringList(_customImageModelsKey);
    settingsMap[_customImageProvidersKey] = prefs.getString(
      _customImageProvidersKey,
    );
    settingsMap[_bflAspectRatioKey] = _bflAspectRatio;
    settingsMap[_veo3ApiKeyKey] = prefs.getString(_veo3ApiKeyKey);
    settingsMap[_selectedVideoProviderKey] = prefs.getString(
      _selectedVideoProviderKey,
    );
    settingsMap[_videoResolutionKey] = prefs.getString(_videoResolutionKey);
    settingsMap[_videoDurationKey] = prefs.getString(_videoDurationKey);
    settingsMap[_videoQualityKey] = prefs.getString(_videoQualityKey);
    settingsMap[_videoAspectRatioKey] = prefs.getString(_videoAspectRatioKey);

    _addOptionalExportStringList(prefs, settingsMap, _customOpenAiModelsKey);
    _addOptionalExportStringList(prefs, settingsMap, _customOpenAiBaseUrlsKey);
    _addOptionalExportStringList(prefs, settingsMap, _customOpenAiApiKeysKey);
    return settingsMap;
  }

  void _loadApiSettings(SharedPreferences prefs) {
    _apiKey = prefs.getString(_apiKeyKey);
    _imageApiKey = prefs.getString(_imageApiKeyKey);
    _claudeApiKey = prefs.getString(_claudeApiKeyKey);
    _tavilyApiKey = prefs.getString(_tavilyApiKeyKey);
    _fluxKontextApiKey = prefs.getString(_fluxKontextApiKeyKey);
    _googleSearchApiKey = prefs.getString(_googleSearchApiKeyKey);
    _googleSearchEngineId = prefs.getString(_googleSearchEngineIdKey);
    _googleSearchEnabled = prefs.getBool(_googleSearchEnabledKey) ?? false;
    _googleSearchResultCount = prefs.getInt(_googleSearchResultCountKey) ?? 10;
    _googleSearchProvider =
        prefs.getString(_googleSearchProviderKey) ?? 'googleCustomSearch';
    _tavilySearchEnabled = prefs.getBool(_tavilySearchEnabledKey) ?? false;
  }

  void _loadTextModelSettings(SharedPreferences prefs) {
    _selectedModel = prefs.getString(_selectedModelKey) ?? 'gpt-4o';
    _providerUrl = prefs.getString(_providerUrlKey);
    _customModels = prefs.getStringList(_customModelsKey) ?? [];
    _customProviders = {};
    final customProvidersString = prefs.getString(_customProvidersKey);
    if (customProvidersString != null) {
      _customProviders = _decodeProvidersMap(
        customProvidersString,
        'Error loading custom providers',
      );
    }
    _selectedProvider = prefs.getString(_selectedProviderKey) ?? 'OpenAI';
    _selectedModelType = available_model.ModelType.values[
      prefs.getInt(_selectedModelTypeKey) ??
          available_model.ModelType.text.index
    ];
  }

  void _loadImageSettings(SharedPreferences prefs) {
    _selectedImageProvider = prefs.getString(_selectedImageProviderKey) ?? 'OpenAI';
    _selectedImageModel = _normalizeImageModelForProvider(
      _selectedImageProvider,
      prefs.getString(_selectedImageModelKey) ?? 'dall-e-3',
    );
    _imageProviderUrl = prefs.getString(_imageProviderUrlKey);
    _customImageModels = prefs.getStringList(_customImageModelsKey) ?? [];
    _customImageProviders = {};
    final customImageProvidersString = prefs.getString(_customImageProvidersKey);
    if (customImageProvidersString != null) {
      _customImageProviders = _decodeProvidersMap(
        customImageProvidersString,
        'Error loading custom image providers',
      );
    }
    _bflAspectRatio = prefs.getString(_bflAspectRatioKey);
  }

  void _loadVideoSettings(SharedPreferences prefs) {
    _veo3ApiKey = prefs.getString(_veo3ApiKeyKey);
    _selectedVideoProvider =
        prefs.getString(_selectedVideoProviderKey) ?? 'Google Veo3';
    _videoResolution = prefs.getString(_videoResolutionKey) ?? '720p';
    _videoDuration = prefs.getString(_videoDurationKey) ?? '10s';
    _videoQuality = prefs.getString(_videoQualityKey) ?? 'standard';
    _videoAspectRatio = prefs.getString(_videoAspectRatioKey) ?? '16:9';
  }

  Future<void> _importApiAndSearchSettings(
    Map<String, dynamic> settingsMap,
    SharedPreferences prefs,
  ) async {
    await _importStringSetting(
      settingsMap,
      prefs,
      _apiKeyKey,
      (value) => _apiKey = value,
    );
    await _importStringSetting(
      settingsMap,
      prefs,
      _imageApiKeyKey,
      (value) => _imageApiKey = value,
    );
    await _importStringSetting(
      settingsMap,
      prefs,
      _claudeApiKeyKey,
      (value) => _claudeApiKey = value,
    );
    await _importStringSetting(
      settingsMap,
      prefs,
      _tavilyApiKeyKey,
      (value) => _tavilyApiKey = value,
    );
    await _importStringSetting(
      settingsMap,
      prefs,
      _fluxKontextApiKeyKey,
      (value) => _fluxKontextApiKey = value,
    );
    await _importStringSetting(
      settingsMap,
      prefs,
      _googleSearchApiKeyKey,
      (value) => _googleSearchApiKey = value,
    );
    await _importStringSetting(
      settingsMap,
      prefs,
      _googleSearchEngineIdKey,
      (value) => _googleSearchEngineId = value,
    );
    await _importBoolSetting(
      settingsMap,
      prefs,
      _googleSearchEnabledKey,
      (value) => _googleSearchEnabled = value,
    );
    await _importIntSetting(
      settingsMap,
      prefs,
      _googleSearchResultCountKey,
      (value) => _googleSearchResultCount = value,
    );
    await _importStringSetting(
      settingsMap,
      prefs,
      _googleSearchProviderKey,
      (value) => _googleSearchProvider = value,
    );
    await _importBoolSetting(
      settingsMap,
      prefs,
      _tavilySearchEnabledKey,
      (value) => _tavilySearchEnabled = value,
    );
  }

  Future<void> _importTextModelSettings(
    Map<String, dynamic> settingsMap,
    SharedPreferences prefs,
  ) async {
    await _importStringSetting(
      settingsMap,
      prefs,
      _selectedModelKey,
      (value) => _selectedModel = value,
    );
    if (kDebugMode && settingsMap[_selectedModelKey] is String) {
      debugPrint('Imported selectedModel: $_selectedModel');
    }
    await _importStringSetting(
      settingsMap,
      prefs,
      _providerUrlKey,
      (value) => _providerUrl = value,
    );
    await _importStringListSetting(
      settingsMap,
      prefs,
      _customModelsKey,
      (value) => _customModels = value,
    );
    await _importStringSetting(
      settingsMap,
      prefs,
      _selectedProviderKey,
      (value) => _selectedProvider = value,
    );
    if (kDebugMode && settingsMap[_selectedProviderKey] is String) {
      debugPrint('Imported selectedProvider: $_selectedProvider');
    }

    final customProvidersRaw = settingsMap[_customProvidersKey];
    if (customProvidersRaw is String) {
      await prefs.setString(_customProvidersKey, customProvidersRaw);
      _customProviders = _decodeProvidersMap(
        customProvidersRaw,
        'Error parsing custom providers',
      );
    }

    if (!defaultBaseUrls.containsKey(_selectedProvider) &&
        !_customProviders.containsKey(_selectedProvider) &&
        _selectedModel.isNotEmpty) {
      _customProviders[_selectedProvider] = [_selectedModel];
      await prefs.setString(_customProvidersKey, json.encode(_customProviders));
      if (kDebugMode) {
        debugPrint(
          'Created custom provider $_selectedProvider with model $_selectedModel',
        );
      }
    }

    await _importIntSetting(
      settingsMap,
      prefs,
      _selectedModelTypeKey,
      (value) => _selectedModelType = available_model.ModelType.values[value],
    );
  }

  Future<void> _importImageSettings(
    Map<String, dynamic> settingsMap,
    SharedPreferences prefs,
  ) async {
    await _importStringSetting(
      settingsMap,
      prefs,
      _selectedImageProviderKey,
      (value) => _selectedImageProvider = value,
    );
    await _importStringSetting(
      settingsMap,
      prefs,
      _selectedImageModelKey,
      (value) => _selectedImageModel = value,
    );
    await _importStringSetting(
      settingsMap,
      prefs,
      _imageProviderUrlKey,
      (value) => _imageProviderUrl = value,
    );
    await _importStringListSetting(
      settingsMap,
      prefs,
      _customImageModelsKey,
      (value) => _customImageModels = value,
    );

    final customImageProvidersRaw = settingsMap[_customImageProvidersKey];
    if (customImageProvidersRaw is String) {
      await prefs.setString(_customImageProvidersKey, customImageProvidersRaw);
      _customImageProviders = _decodeProvidersMap(
        customImageProvidersRaw,
        'Error parsing custom image providers',
      );
    }

    if (settingsMap[_bflAspectRatioKey] != null) {
      _bflAspectRatio = settingsMap[_bflAspectRatioKey];
      await _saveBflAspectRatio();
    }
  }

  Future<void> _importOptionalOpenAiCompatibleSettings(
    Map<String, dynamic> settingsMap,
    SharedPreferences prefs,
  ) async {
    await _importStringListSetting(
      settingsMap,
      prefs,
      _customOpenAiModelsKey,
      (_) {},
    );
    await _importStringListSetting(
      settingsMap,
      prefs,
      _customOpenAiBaseUrlsKey,
      (_) {},
    );
    await _importStringListSetting(
      settingsMap,
      prefs,
      _customOpenAiApiKeysKey,
      (_) {},
    );
  }

  void _registerModelsToRegistry({
    required available_model.ModelType type,
    required Map<String, List<String>> providerModels,
    required Map<String, String> defaultUrls,
    required bool supportsStreaming,
  }) {
    if (modelRegistry == null) return;
    for (final provider in providerModels.keys) {
      for (final model in providerModels[provider]!) {
        final modelName = type == available_model.ModelType.image &&
                provider == 'Google'
            ? GoogleImageService.getDisplayName(model)
            : model;
        modelRegistry!.registerModel(
          available_model.AvailableModel(
            id: model,
            name: modelName,
            provider: provider,
            type: type,
            supportsStreaming: supportsStreaming,
            capabilities: {},
            baseUrl: defaultUrls[provider],
          ),
        );
      }
    }
  }

  void _registerCustomModelsToRegistry({
    required available_model.ModelType type,
    required List<String> models,
    required String provider,
    required String? baseUrl,
    required bool supportsStreaming,
  }) {
    if (modelRegistry == null) return;
    for (final model in models) {
      modelRegistry!.registerModel(
        available_model.AvailableModel(
          id: model,
          name: model,
          provider: provider,
          type: type,
          supportsStreaming: supportsStreaming,
          capabilities: {},
          baseUrl: baseUrl,
        ),
      );
    }
  }

  void _syncTextModelsToRegistry() {
    _registerModelsToRegistry(
      type: available_model.ModelType.text,
      providerModels: _categorizedPresetModels,
      defaultUrls: defaultBaseUrls,
      supportsStreaming: true,
    );
    _registerCustomModelsToRegistry(
      type: available_model.ModelType.text,
      models: _customModels,
      provider: _selectedProvider,
      baseUrl: _providerUrl,
      supportsStreaming: true,
    );
  }

  void _syncImageModelsToRegistry() {
    _registerModelsToRegistry(
      type: available_model.ModelType.image,
      providerModels: _categorizedPresetImageModels,
      defaultUrls: defaultImageBaseUrls,
      supportsStreaming: false,
    );
    _registerCustomModelsToRegistry(
      type: available_model.ModelType.image,
      models: _customImageModels,
      provider: _selectedImageProvider,
      baseUrl: _imageProviderUrl,
      supportsStreaming: false,
    );
  }

  String _pickFallbackModel({
    required String provider,
    required Map<String, List<String>> presetModels,
    required Map<String, List<String>> customProviders,
    required List<String> currentAvailableModels,
  }) {
    final presetProviderModels = presetModels[provider];
    if (presetProviderModels != null && presetProviderModels.isNotEmpty) {
      return presetProviderModels.first;
    }

    final customProviderModels = customProviders[provider];
    if (customProviderModels != null && customProviderModels.isNotEmpty) {
      return customProviderModels.first;
    }

    return currentAvailableModels.isNotEmpty ? currentAvailableModels.first : '';
  }

  void _persistSelectedModelAsync(String storageKey, String selectedModel) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(storageKey, selectedModel);
    });
  }

  String? _resolveProviderUrlForSelection(
    String provider,
    Map<String, String> defaultUrls,
  ) {
    return defaultUrls.containsKey(provider) ? defaultUrls[provider] : null;
  }

  Future<void> _persistSelectedProviderAndUrl(
    SharedPreferences prefs, {
    required String providerKey,
    required String provider,
    required String urlKey,
    required String? url,
  }) async {
    await prefs.setString(providerKey, provider);
    await _persistNullableString(prefs, urlKey, url);
  }

  List<String> _buildAvailableModels({
    required String selectedProvider,
    required Map<String, List<String>> presetModels,
    required Map<String, List<String>> customProviders,
    required List<String> customModels,
  }) {
    final modelsToShow = <String>[];
    final presetProviderModels = presetModels[selectedProvider];
    if (presetProviderModels != null) {
      modelsToShow.addAll(presetProviderModels);
    } else if (customProviders.containsKey(selectedProvider)) {
      modelsToShow.addAll(customProviders[selectedProvider] ?? []);
    }
    modelsToShow.addAll(customModels);
    return List.unmodifiable(modelsToShow.toSet().toList());
  }

  List<String> _buildAllProviderNames(
    Map<String, String> defaultUrls,
    Map<String, List<String>> customProviders,
  ) {
    final names = defaultUrls.keys.toList();
    names.addAll(customProviders.keys);
    return List.unmodifiable(names.toSet().toList());
  }

  // Getters for Image Generation Settings
  String get selectedImageProvider => _selectedImageProvider;
  String get selectedImageModel => _selectedImageModel;
  available_model.ModelType get selectedModelType => _selectedModelType;

  List<String> get availableImageModels {
    return _buildAvailableModels(
      selectedProvider: _selectedImageProvider,
      presetModels: _categorizedPresetImageModels,
      customProviders: _customImageProviders,
      customModels: _customImageModels,
    );
  }

  List<String> get allImageProviderNames =>
      _buildAllProviderNames(defaultImageBaseUrls, _customImageProviders);

  String get imageProviderUrl => _resolveBaseUrl(
    _imageProviderUrl,
    _selectedImageProvider,
    defaultImageBaseUrls,
  );

  String? get rawImageProviderUrl => _imageProviderUrl;

  List<String> get availableModels {
    return _buildAvailableModels(
      selectedProvider: _selectedProvider,
      presetModels: _categorizedPresetModels,
      customProviders: _customProviders,
      customModels: _customModels,
    );
  }

  List<String> get customModels => List.unmodifiable(_customModels);
  List<String> get customImageModels => List.unmodifiable(_customImageModels);

  // 获取 Provider URL，优先使用用户设置的URL，否则返回当前选定提供商的默认URL
  String get providerUrl => _resolveBaseUrl(
    _providerUrl,
    _selectedProvider,
    defaultBaseUrls,
  );

  // 返回给UI显示的原始Provider URL，可能是空的
  String? get rawProviderUrl => _providerUrl;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _loadApiSettings(prefs);
    _loadTextModelSettings(prefs);
    _loadImageSettings(prefs);
    _loadVideoSettings(prefs);

    notifyListeners();
    // Ensure the selected model is valid for the loaded provider
    _validateSelectedModelForProvider();
    _validateSelectedImageModelForProvider();
    // 新增：同步到 ModelRegistry
    syncModelsToRegistry();
  }

  void syncModelsToRegistry() {
    if (modelRegistry == null) return;
    _syncTextModelsToRegistry();
    _syncImageModelsToRegistry();
    // 5. 可扩展：注册 OpenAI 兼容自定义模型
  }

  Future<void> setSelectedProvider(String newProvider) async {
    if (_selectedProvider != newProvider) {
      _selectedProvider = newProvider;
      _providerUrl = _resolveProviderUrlForSelection(newProvider, defaultBaseUrls);

      final prefs = await SharedPreferences.getInstance();
      await _persistSelectedProviderAndUrl(
        prefs,
        providerKey: _selectedProviderKey,
        provider: newProvider,
        urlKey: _providerUrlKey,
        url: _providerUrl,
      );

      // _validateSelectedModelForProvider 会为新的提供商设置默认模型，并处理其持久化
      _validateSelectedModelForProvider();
      notifyListeners();
    }
  }

  void _validateSelectedModelForProvider() {
    final currentAvailableModels = availableModels;
    if (!currentAvailableModels.contains(_selectedModel)) {
      _selectedModel = _pickFallbackModel(
        provider: _selectedProvider,
        presetModels: _categorizedPresetModels,
        customProviders: _customProviders,
        currentAvailableModels: currentAvailableModels,
      );
      if (kDebugMode) {
        debugPrint('Model validation changed selectedModel to: $_selectedModel');
      }
      _persistSelectedModelAsync(_selectedModelKey, _selectedModel);
    }
  }

  Future<void> setApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = apiKey;
    await _persistNullableString(prefs, _apiKeyKey, apiKey);
    notifyListeners();
  }

  Future<void> setImageApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    _imageApiKey = apiKey;
    await _persistNullableString(prefs, _imageApiKeyKey, apiKey);
    notifyListeners();
  }

  Future<void> setClaudeApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    _claudeApiKey = apiKey;
    await _persistNullableString(prefs, _claudeApiKeyKey, apiKey);
    notifyListeners();
  }

  Future<void> setTavilyApiKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    _tavilyApiKey = key;
    await _persistNullableString(prefs, _tavilyApiKeyKey, key);
    notifyListeners();
  }

  Future<void> setFluxKontextApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    _fluxKontextApiKey = apiKey;
    await _persistNullableString(prefs, _fluxKontextApiKeyKey, apiKey);
    notifyListeners();
  }

  Future<void> setTavilySearchEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _tavilySearchEnabled = enabled;
    await prefs.setBool(_tavilySearchEnabledKey, enabled);
    notifyListeners();
  }

  // Methods for Image Generation Settings
  Future<void> setSelectedImageProvider(String newProvider) async {
    if (_selectedImageProvider != newProvider) {
      _selectedImageProvider = newProvider;
      _imageProviderUrl = _resolveProviderUrlForSelection(
        newProvider,
        defaultImageBaseUrls,
      );
      final prefs = await SharedPreferences.getInstance();
      await _persistSelectedProviderAndUrl(
        prefs,
        providerKey: _selectedImageProviderKey,
        provider: newProvider,
        urlKey: _imageProviderUrlKey,
        url: _imageProviderUrl,
      );
      _validateSelectedImageModelForProvider();
      notifyListeners();
    }
  }

  void _validateSelectedImageModelForProvider() {
    _selectedImageModel = _normalizeImageModelForProvider(
      _selectedImageProvider,
      _selectedImageModel,
    );
    final currentAvailableImageModels = availableImageModels;
    if (!currentAvailableImageModels.contains(_selectedImageModel)) {
      _selectedImageModel = _pickFallbackModel(
        provider: _selectedImageProvider,
        presetModels: _categorizedPresetImageModels,
        customProviders: _customImageProviders,
        currentAvailableModels: currentAvailableImageModels,
      );
      _persistSelectedModelAsync(_selectedImageModelKey, _selectedImageModel);
    }
  }

  Future<void> setSelectedImageModel(String newModel) async {
    final normalizedModel = _normalizeImageModelForProvider(
      _selectedImageProvider,
      newModel,
    );
    await _setSelectedModelIfAvailable(
      newModel: normalizedModel,
      availableModels: availableImageModels,
      key: _selectedImageModelKey,
      assign: (value) => _selectedImageModel = value,
    );
  }

  String _normalizeImageModelForProvider(String provider, String model) {
    if (provider == 'Google') {
      return GoogleImageService.normalizeModel(model);
    }
    return model.trim();
  }

  Future<void> setSelectedModelType(available_model.ModelType newType) async {
    if (_selectedModelType != newType) {
      await _setIntSetting(
        _selectedModelTypeKey,
        newType.index,
        (value) => _selectedModelType = available_model.ModelType.values[value],
      );
    }
  }

  Future<void> setImageProviderUrl(String? newUrl) async {
    await _setProviderUrlInternal(
      newUrl: newUrl,
      key: _imageProviderUrlKey,
      assign: (value) => _imageProviderUrl = value,
      validate: _validateSelectedImageModelForProvider,
    );
  }

  Future<void> addCustomImageModel(String modelName) async {
    if (modelName.trim().isEmpty ||
        _customImageModels.contains(modelName.trim()) ||
        (_categorizedPresetImageModels.values
            .expand((x) => x)
            .contains(modelName.trim()))) {
      return;
    }
    _customImageModels.add(modelName.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customImageModelsKey, _customImageModels);
    notifyListeners();
    _validateSelectedImageModelForProvider();
  }

  Future<void> removeCustomImageModel(String modelName) async {
    await _removeCustomModelInternal(
      modelName: modelName,
      targetModels: _customImageModels,
      storageKey: _customImageModelsKey,
      selectedModel: _selectedImageModel,
      validateSelection: _validateSelectedImageModelForProvider,
    );
  }

  Future<void> addCustomImageProviderWithModels(
    String providerName,
    List<String> models,
  ) async {
    await _addCustomProviderWithModels(
      providerName: providerName,
      models: models,
      defaultUrls: defaultImageBaseUrls,
      targetProviders: _customImageProviders,
      storageKey: _customImageProvidersKey,
    );
  }

  Future<void> addCustomTextModel(String modelName) async {
    await _addCustomTextModelInternal(modelName);
  }

  Future<void> setSelectedModel(String newModel) async {
    await _setSelectedModelIfAvailable(
      newModel: newModel,
      availableModels: availableModels,
      key: _selectedModelKey,
      assign: (value) => _selectedModel = value,
    );
  }

  Future<void> setProviderUrl(String? newUrl) async {
    await _setProviderUrlInternal(
      newUrl: newUrl,
      key: _providerUrlKey,
      assign: (value) => _providerUrl = value,
      validate: _validateSelectedModelForProvider,
    );
  }

  Future<void> addCustomModel(String modelName) async {
    await _addCustomTextModelInternal(modelName);
  }

  Future<void> addCustomProviderWithModels(
    String providerName,
    List<String> models,
  ) async {
    await _addCustomProviderWithModels(
      providerName: providerName,
      models: models,
      defaultUrls: defaultBaseUrls,
      targetProviders: _customProviders,
      storageKey: _customProvidersKey,
    );
  }

  Future<void> removeCustomModel(String modelName) async {
    await _removeCustomModelInternal(
      modelName: modelName,
      targetModels: _customModels,
      storageKey: _customModelsKey,
      selectedModel: _selectedModel,
      validateSelection: _validateSelectedModelForProvider,
    );
  }

  // Video Generation Settings Getters
  String? get veo3ApiKey => _veo3ApiKey;
  String get selectedVideoProvider => _selectedVideoProvider;
  String get videoResolution => _videoResolution;
  String get videoDuration => _videoDuration;
  String get videoQuality => _videoQuality;
  String get videoAspectRatio => _videoAspectRatio;

  // Video Generation Settings Setters
  Future<void> setVeo3ApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    _veo3ApiKey = apiKey;
    await _persistNullableString(prefs, _veo3ApiKeyKey, apiKey);
    notifyListeners();
  }

  Future<void> setSelectedVideoProvider(String provider) async {
    await _setStringSetting(
      _selectedVideoProviderKey,
      provider,
      (value) => _selectedVideoProvider = value,
    );
  }

  Future<void> setVideoResolution(String resolution) async {
    await _setStringSetting(
      _videoResolutionKey,
      resolution,
      (value) => _videoResolution = value,
    );
  }

  Future<void> setVideoDuration(String duration) async {
    await _setStringSetting(
      _videoDurationKey,
      duration,
      (value) => _videoDuration = value,
    );
  }

  Future<void> setVideoQuality(String quality) async {
    await _setStringSetting(
      _videoQualityKey,
      quality,
      (value) => _videoQuality = value,
    );
  }

  Future<void> setVideoAspectRatio(String aspectRatio) async {
    await _setStringSetting(
      _videoAspectRatioKey,
      aspectRatio,
      (value) => _videoAspectRatio = value,
    );
  }

  // Google Search Settings Methods
  Future<void> setGoogleSearchApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    _googleSearchApiKey = apiKey;
    await _persistNullableString(prefs, _googleSearchApiKeyKey, apiKey);
    notifyListeners();
  }

  Future<void> setGoogleSearchEngineId(String? engineId) async {
    final prefs = await SharedPreferences.getInstance();
    _googleSearchEngineId = engineId;
    await _persistNullableString(prefs, _googleSearchEngineIdKey, engineId);
    notifyListeners();
  }

  Future<void> setGoogleSearchEnabled(bool enabled) async {
    await _setBoolSetting(
      _googleSearchEnabledKey,
      enabled,
      (value) => _googleSearchEnabled = value,
    );
  }

  Future<void> setGoogleSearchResultCount(int count) async {
    await _setIntSetting(
      _googleSearchResultCountKey,
      count.clamp(1, 20),
      (value) => _googleSearchResultCount = value,
    );
  }

  Future<void> setGoogleSearchProvider(String provider) async {
    await _setStringSetting(
      _googleSearchProviderKey,
      provider,
      (value) => _googleSearchProvider = value,
    );
  }

  // Export settings to XML
  Future<String> exportSettingsToXml() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsMap = _buildExportSettingsMap(prefs);

      if (kDebugMode) {
        debugPrint('Settings map for export: $settingsMap');
      }

      return SettingsXmlHandler.exportToXml(settingsMap);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in exportSettingsToXml: $e');
      }
      throw Exception('Failed to export settings: $e');
    }
  }

  // Import settings from XML
  Future<void> importSettingsFromXml(String xmlContent) async {
    try {
      final settingsMap = SettingsXmlHandler.importFromXml(xmlContent);
      final prefs = await SharedPreferences.getInstance();

      // Clear existing settings first (optional, depends on requirements)
      // await _clearAllSettings(prefs);
      await _importApiAndSearchSettings(settingsMap, prefs);
      await _importTextModelSettings(settingsMap, prefs);
      await _importImageSettings(settingsMap, prefs);
      await _importOptionalOpenAiCompatibleSettings(settingsMap, prefs);

      // Now validate settings after all data is loaded
      _validateSelectedModelForProvider();
      _validateSelectedImageModelForProvider();

      notifyListeners();

      // Add a small delay to ensure UI updates properly
      await Future.delayed(const Duration(milliseconds: 100));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error importing settings from XML: $e');
      }
      throw Exception('Failed to import settings: $e');
    }
  }

  // Get the appropriate API key for the current provider
  String? getApiKeyForProvider(String provider) {
    switch (provider) {
      case 'OpenAI':
        return _apiKey;
      case 'Google':
        return _apiKey; // Using OpenAI key for now
      case 'Anthropic':
        return _claudeApiKey;
      case 'BFL':
        return _imageApiKey;
      default:
        return _apiKey;
    }
  }

  // Test FLUX.1 connection
  Future<bool> testFluxConnection() async {
    if (kDebugMode) {
      debugPrint('[SettingsProvider] Testing FLUX.1 connection');
      debugPrint('[SettingsProvider] Selected model: $_selectedImageModel');
      debugPrint('[SettingsProvider] API key available: ${_imageApiKey != null && _imageApiKey!.isNotEmpty}');
    }
    
    if (_imageApiKey == null || _imageApiKey!.isEmpty) {
      if (kDebugMode) {
        debugPrint('[SettingsProvider] No API key provided for FLUX.1 test');
      }
      return false;
    }

    try {
      // Test FLUX.1 Kontext connection
      if (_selectedImageModel.contains('kontext')) {
        if (kDebugMode) {
          debugPrint('[SettingsProvider] Testing FLUX.1-Kontext connection');
        }
        final fluxService = FluxKontextService(apiKey: _imageApiKey!);
        final result = await fluxService.testConnection();
        if (kDebugMode) {
          debugPrint('[SettingsProvider] FLUX.1-Kontext test result: $result');
        }
        return result;
      } 
      // Test FLUX.1 Krea connection
      else if (_selectedImageModel.contains('krea')) {
        if (kDebugMode) {
          debugPrint('[SettingsProvider] Testing FLUX.1-Krea-dev connection');
        }
        final fluxService = FluxKreaService(apiKey: _imageApiKey!);
        final result = await fluxService.testConnection();
        if (kDebugMode) {
          debugPrint('[SettingsProvider] FLUX.1-Krea-dev test result: $result');
        }
        return result;
      }
      
      if (kDebugMode) {
        debugPrint('[SettingsProvider] No FLUX.1 model selected');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SettingsProvider] FLUX.1 connection test failed: $e');
      }
      return false;
    }
  }

  // Get effective provider URL (removing trailing slashes)
  String get effectiveProviderUrl => providerUrl;
}
