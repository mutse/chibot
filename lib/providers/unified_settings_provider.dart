import 'package:flutter/foundation.dart';
import 'api_key_provider.dart';
import 'chat_model_provider.dart';
import 'image_model_provider.dart';
import 'video_model_provider.dart';
import 'search_provider.dart';
import '../models/model_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/available_model.dart' as available_model;
import '../utils/settings_xml_handler.dart';

/// 统一的设置提供者聚合类
/// 这个类聚合了所有分解的提供者，提供向后兼容的 API
/// 可以用于逐步迁移从 SettingsProvider 到新的专职提供者
///
/// 使用示例：
/// ```dart
/// final settings = UnifiedSettingsProvider(
///   apiKeyProvider: apiKeyProvider,
///   chatModelProvider: chatModelProvider,
///   // ... 其他提供者
/// );
///
/// // 现有代码可以继续使用
/// settings.selectedModel
/// settings.selectedProvider
/// ```
class UnifiedSettingsProvider with ChangeNotifier {
  final ApiKeyProvider apiKeyProvider;
  final ChatModelProvider chatModelProvider;
  final ImageModelProvider imageModelProvider;
  final VideoModelProvider videoModelProvider;
  final SearchProvider searchProvider;

  // 跟踪当前选定的模型类型（文本、图像、视频）
  available_model.ModelType _selectedModelType = available_model.ModelType.text;
  static const String _selectedModelTypeKey = 'selected_model_type';

  UnifiedSettingsProvider({
    required this.apiKeyProvider,
    required this.chatModelProvider,
    required this.imageModelProvider,
    required this.videoModelProvider,
    required this.searchProvider,
  }) {
    // 订阅所有子提供者的变化
    apiKeyProvider.addListener(_onProviderChanged);
    chatModelProvider.addListener(_onProviderChanged);
    imageModelProvider.addListener(_onProviderChanged);
    videoModelProvider.addListener(_onProviderChanged);
    searchProvider.addListener(_onProviderChanged);
    _loadSelectedModelType();
  }

  Future<void> _loadSelectedModelType() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedModelType =
        available_model.ModelType.values[prefs.getInt(_selectedModelTypeKey) ??
            available_model.ModelType.text.index];
  }

  available_model.ModelType get selectedModelType => _selectedModelType;

  Future<void> setSelectedModelType(available_model.ModelType newType) async {
    if (_selectedModelType != newType) {
      _selectedModelType = newType;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_selectedModelTypeKey, newType.index);
      notifyListeners();
    }
  }

  void _onProviderChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    apiKeyProvider.removeListener(_onProviderChanged);
    chatModelProvider.removeListener(_onProviderChanged);
    imageModelProvider.removeListener(_onProviderChanged);
    videoModelProvider.removeListener(_onProviderChanged);
    searchProvider.removeListener(_onProviderChanged);
    super.dispose();
  }

  // ==================== API Key 相关的向后兼容 API ====================

  String? get apiKey => apiKeyProvider.apiKey;
  String? get imageApiKey => apiKeyProvider.googleApiKey;
  String? get claudeApiKey => apiKeyProvider.claudeApiKey;
  String? get tavilyApiKey => apiKeyProvider.tavilyApiKey;
  String? get fluxKontextApiKey => apiKeyProvider.fluxKontextApiKey;
  String? get googleSearchApiKey => apiKeyProvider.googleSearchApiKey;
  String? get googleSearchEngineId => searchProvider.googleSearchEngineId;

  String? getApiKeyForProvider(String provider) {
    return apiKeyProvider.getApiKeyForProvider(provider);
  }

  Future<void> setApiKey(String? key) => apiKeyProvider.setOpenaiApiKey(key);
  Future<void> setImageApiKey(String? key) =>
      apiKeyProvider.setGoogleApiKey(key);
  Future<void> setClaudeApiKey(String? key) =>
      apiKeyProvider.setClaudeApiKey(key);
  Future<void> setTavilyApiKey(String? key) =>
      apiKeyProvider.setTavilyApiKey(key);
  Future<void> setFluxKontextApiKey(String? key) =>
      apiKeyProvider.setFluxKontextApiKey(key);

  // ==================== 聊天模型相关的向后兼容 API ====================

  String get selectedModel => chatModelProvider.selectedModel;
  String get selectedProvider => chatModelProvider.selectedProvider;
  String? get rawProviderUrl => chatModelProvider.rawProviderUrl;
  String get providerUrl => chatModelProvider.providerUrl;
  List<String> get availableModels => chatModelProvider.availableModels;
  List<String> get allProviderNames => chatModelProvider.allProviderNames;
  List<String> get customModels => chatModelProvider.customModels;

  Future<void> setSelectedModel(String model) =>
      chatModelProvider.setSelectedModel(model);
  Future<void> setSelectedProvider(String provider) =>
      chatModelProvider.setSelectedProvider(provider);
  Future<void> setProviderUrl(String? url) =>
      chatModelProvider.setProviderUrl(url);
  Future<void> addCustomModel(String model) =>
      chatModelProvider.addCustomModel(model);
  Future<void> removeCustomModel(String model) =>
      chatModelProvider.removeCustomModel(model);
  Future<void> addCustomProvider(String provider, List<String> models) =>
      chatModelProvider.addCustomProvider(provider, models);
  Future<void> removeCustomProvider(String provider) =>
      chatModelProvider.removeCustomProvider(provider);
  Future<void> syncModelsToRegistry() =>
      chatModelProvider.syncModelsToRegistry();

  Future<void> syncImageModelsToRegistry() =>
      imageModelProvider.syncModelsToRegistry();

  // ==================== 图像生成相关的向后兼容 API ====================

  String get selectedImageProvider => imageModelProvider.selectedImageProvider;
  String get selectedImageModel => imageModelProvider.selectedImageModel;
  String? get rawImageProviderUrl => imageModelProvider.rawImageProviderUrl;
  String get imageProviderUrl => imageModelProvider.imageProviderUrl;
  List<String> get availableImageModels =>
      imageModelProvider.availableImageModels;
  List<String> get allImageProviderNames =>
      imageModelProvider.allImageProviderNames;
  List<String> get customImageModels => imageModelProvider.customImageModels;
  String? get bflAspectRatio => imageModelProvider.bflAspectRatio;

  Future<void> setSelectedImageModel(String model) =>
      imageModelProvider.setSelectedImageModel(model);
  Future<void> setSelectedImageProvider(String provider) =>
      imageModelProvider.setSelectedImageProvider(provider);
  Future<void> setImageProviderUrl(String? url) =>
      imageModelProvider.setImageProviderUrl(url);
  Future<void> setBflAspectRatio(String? value) =>
      imageModelProvider.setBflAspectRatio(value);
  Future<void> addCustomImageModel(String model) =>
      imageModelProvider.addCustomImageModel(model);
  Future<void> removeCustomImageModel(String model) =>
      imageModelProvider.removeCustomImageModel(model);
  Future<void> addCustomImageProvider(String provider, List<String> models) =>
      imageModelProvider.addCustomImageProvider(provider, models);
  Future<void> removeCustomImageProvider(String provider) =>
      imageModelProvider.removeCustomImageProvider(provider);

  // ==================== 视频生成相关的向后兼容 API ====================

  String get selectedVideoProvider => videoModelProvider.selectedVideoProvider;
  String get videoResolution => videoModelProvider.videoResolution;
  String get videoDuration => videoModelProvider.videoDuration;
  String get videoQuality => videoModelProvider.videoQuality;
  String get videoAspectRatio => videoModelProvider.videoAspectRatio;

  Future<void> setSelectedVideoProvider(String provider) =>
      videoModelProvider.setSelectedVideoProvider(provider);
  Future<void> setVideoResolution(String resolution) =>
      videoModelProvider.setVideoResolution(resolution);
  Future<void> setVideoDuration(String duration) =>
      videoModelProvider.setVideoDuration(duration);
  Future<void> setVideoQuality(String quality) =>
      videoModelProvider.setVideoQuality(quality);
  Future<void> setVideoAspectRatio(String aspectRatio) =>
      videoModelProvider.setVideoAspectRatio(aspectRatio);

  // ==================== 搜索相关的向后兼容 API ====================

  bool get googleSearchEnabled => searchProvider.googleSearchEnabled;
  int get googleSearchResultCount => searchProvider.googleSearchResultCount;
  String get googleSearchProvider => searchProvider.googleSearchProvider;
  bool get tavilySearchEnabled => searchProvider.tavilySearchEnabled;

  Future<void> setGoogleSearchApiKey(String? key) =>
      apiKeyProvider.setGoogleSearchApiKey(key);
  Future<void> setGoogleSearchEngineId(String? id) =>
      searchProvider.setGoogleSearchEngineId(id);
  Future<void> setGoogleSearchEnabled(bool enabled) =>
      searchProvider.setGoogleSearchEnabled(enabled);
  Future<void> setGoogleSearchResultCount(int count) =>
      searchProvider.setGoogleSearchResultCount(count);
  Future<void> setGoogleSearchProvider(String provider) =>
      searchProvider.setGoogleSearchProvider(provider);
  Future<void> setTavilySearchEnabled(bool enabled) =>
      searchProvider.setTavilySearchEnabled(enabled);

  // ==================== 全局导入/导出 ====================

  /// 导出所有设置为 Map
  Future<Map<String, dynamic>> exportSettings() async {
    return {
      'apiKeys': apiKeyProvider.toMap(),
      'chatModel': chatModelProvider.toMap(),
      'imageModel': imageModelProvider.toMap(),
      'videoModel': videoModelProvider.toMap(),
      'search': searchProvider.toMap(),
    };
  }

  /// 从 Map 导入所有设置
  Future<void> importSettings(Map<String, dynamic> data) async {
    if (data.containsKey('apiKeys')) {
      await apiKeyProvider.fromMap(data['apiKeys']);
    }
    if (data.containsKey('chatModel')) {
      await chatModelProvider.fromMap(data['chatModel']);
    }
    if (data.containsKey('imageModel')) {
      await imageModelProvider.fromMap(data['imageModel']);
    }
    if (data.containsKey('videoModel')) {
      await videoModelProvider.fromMap(data['videoModel']);
    }
    if (data.containsKey('search')) {
      await searchProvider.fromMap(data['search']);
    }
  }

  /// 导出所有设置为 XML 格式
  Future<String> exportSettingsToXml() async {
    try {
      final nestedSettings = await exportSettings();
      final flatMap = _flattenSettingsMap(nestedSettings);
      return SettingsXmlHandler.exportToXml(flatMap);
    } catch (e) {
      if (kDebugMode) {
        print('Error in exportSettingsToXml: $e');
      }
      throw Exception('Failed to export settings to XML: $e');
    }
  }

  /// 从 XML 格式导入所有设置
  Future<void> importSettingsFromXml(String xmlContent) async {
    try {
      final flatMap = SettingsXmlHandler.importFromXml(xmlContent);
      final nestedMap = _reconstructSettingsMap(flatMap);
      await importSettings(nestedMap);
    } catch (e) {
      if (kDebugMode) {
        print('Error in importSettingsFromXml: $e');
      }
      throw Exception('Failed to import settings from XML: $e');
    }
  }

  /// 将嵌套的设置 Map 展平为扁平 Map 用于 XML 处理
  Map<String, dynamic> _flattenSettingsMap(Map<String, dynamic> nested) {
    final flat = <String, dynamic>{};

    // 展平 API 密钥
    if (nested.containsKey('apiKeys')) {
      flat.addAll(nested['apiKeys'] as Map<String, dynamic>);
    }

    // 展平聊天模型设置
    if (nested.containsKey('chatModel')) {
      flat.addAll(nested['chatModel'] as Map<String, dynamic>);
    }

    // 展平图像模型设置
    if (nested.containsKey('imageModel')) {
      flat.addAll(nested['imageModel'] as Map<String, dynamic>);
    }

    // 展平视频模型设置
    if (nested.containsKey('videoModel')) {
      flat.addAll(nested['videoModel'] as Map<String, dynamic>);
    }

    // 展平搜索设置
    if (nested.containsKey('search')) {
      flat.addAll(nested['search'] as Map<String, dynamic>);
    }

    // 添加模型类型
    flat[_selectedModelTypeKey] = _selectedModelType.index;

    return flat;
  }

  /// 从扁平 Map 重建嵌套的设置 Map
  Map<String, dynamic> _reconstructSettingsMap(Map<String, dynamic> flat) {
    return {
      'apiKeys': _extractApiKeys(flat),
      'chatModel': _extractChatModel(flat),
      'imageModel': _extractImageModel(flat),
      'videoModel': _extractVideoModel(flat),
      'search': _extractSearch(flat),
    };
  }

  /// 从扁平 Map 提取 API 密钥设置
  Map<String, dynamic> _extractApiKeys(Map<String, dynamic> flat) {
    const keys = [
      'openai_api_key',
      'claude_api_key',
      'google_api_key',
      'flux_kontext_api_key',
      'tavily_api_key',
      'google_search_api_key',
    ];
    final extracted = <String, dynamic>{};
    for (final key in keys) {
      if (flat.containsKey(key)) {
        extracted[key] = flat[key];
      }
    }
    return extracted;
  }

  /// 从扁平 Map 提取聊天模型设置
  Map<String, dynamic> _extractChatModel(Map<String, dynamic> flat) {
    const keys = [
      'selected_model_provider',
      'openai_selected_model',
      'openai_provider_url',
      'custom_models_list',
      'custom_providers_map',
    ];
    final extracted = <String, dynamic>{};
    for (final key in keys) {
      if (flat.containsKey(key)) {
        extracted[key] = flat[key];
      }
    }
    return extracted;
  }

  /// 从扁平 Map 提取图像模型设置
  Map<String, dynamic> _extractImageModel(Map<String, dynamic> flat) {
    const keys = [
      'selected_image_provider',
      'selected_image_model',
      'image_provider_url',
      'custom_image_models_list',
      'custom_image_providers_map',
      'bfl_aspect_ratio',
    ];
    final extracted = <String, dynamic>{};
    for (final key in keys) {
      if (flat.containsKey(key)) {
        extracted[key] = flat[key];
      }
    }
    return extracted;
  }

  /// 从扁平 Map 提取视频模型设置
  Map<String, dynamic> _extractVideoModel(Map<String, dynamic> flat) {
    const keys = [
      'selected_video_provider',
      'video_resolution',
      'video_duration',
      'video_quality',
      'video_aspect_ratio',
    ];
    final extracted = <String, dynamic>{};
    for (final key in keys) {
      if (flat.containsKey(key)) {
        extracted[key] = flat[key];
      }
    }
    return extracted;
  }

  /// 从扁平 Map 提取搜索设置
  Map<String, dynamic> _extractSearch(Map<String, dynamic> flat) {
    const keys = [
      'google_search_enabled',
      'google_search_result_count',
      'google_search_provider',
      'tavily_search_enabled',
      'google_search_api_key',
      'google_search_engine_id',
    ];
    final extracted = <String, dynamic>{};
    for (final key in keys) {
      if (flat.containsKey(key)) {
        extracted[key] = flat[key];
      }
    }
    return extracted;
  }
}
