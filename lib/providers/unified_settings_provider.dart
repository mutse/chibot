import 'package:flutter/foundation.dart';
import 'api_key_provider.dart';
import 'chat_model_provider.dart';
import 'image_model_provider.dart';
import 'video_model_provider.dart';
import 'search_provider.dart';
import '../models/model_registry.dart';

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
  String? get googleSearchApiKey => searchProvider.googleSearchApiKey;
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
      searchProvider.setGoogleSearchApiKey(key);
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
}
