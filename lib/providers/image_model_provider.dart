import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/model_registry.dart';
import '../models/available_model.dart';
import '../models/available_model.dart' as available_model;
import '../services/google_image_service.dart';

/// 负责图像生成相关的模型配置
/// 职责：选择图像生成模型、配置提供商、管理 Aspect Ratio
class ImageModelProvider with ChangeNotifier {
  final ModelRegistry? modelRegistry;
  // 当前选定的图像生成提供商
  String _selectedImageProvider = 'OpenAI';
  static const String _selectedImageProviderKey = 'selected_image_provider';

  // 当前选定的图像生成模型
  String _selectedImageModel = 'dall-e-3';
  static const String _selectedImageModelKey = 'selected_image_model';

  // 自定义图像生成提供商 URL
  String? _imageProviderUrl;
  static const String _imageProviderUrlKey = 'image_provider_url';

  // 自定义图像生成模型列表
  List<String> _customImageModels = [];
  static const String _customImageModelsKey = 'custom_image_models_list';

  // 自定义图像生成提供商
  Map<String, List<String>> _customImageProviders = {};
  static const String _customImageProvidersKey = 'custom_image_providers_map';

  // BFL Aspect Ratio 设置
  String? _bflAspectRatio;
  static const String _bflAspectRatioKey = 'bfl_aspect_ratio';

  // 模型类型选择
  available_model.ModelType _selectedModelType = available_model.ModelType.text;
  static const String _selectedModelTypeKey = 'selected_model_type';

  // 预设的图像生成提供商基础 URL
  static const Map<String, String> defaultImageBaseUrls = {
    'OpenAI': 'https://api.openai.com/v1',
    'Stability AI': 'https://api.stability.ai',
    'Black Forest Labs': 'https://api.bfl.ai/v1',
    'Google': 'https://generativelanguage.googleapis.com',
  };

  // 分类的预设图像生成模型
  final Map<String, List<String>> _categorizedPresetImageModels = {
    'OpenAI': ['dall-e-3'],
    'Stability AI': [
      'stable-diffusion-xl-1024-v1-0',
      'stable-diffusion-v1-6',
    ],
    'Black Forest Labs': ['flux-kontext-pro', 'flux-kontext-dev', 'flux-krea-dev'],
    'Google': GoogleImageService.getSupportedModels(),
  };

  // ==================== Getters ====================

  String get selectedImageProvider => _selectedImageProvider;
  String get selectedImageModel => _selectedImageModel;
  String? get rawImageProviderUrl => _imageProviderUrl;
  String? get bflAspectRatio => _bflAspectRatio;
  available_model.ModelType get selectedModelType => _selectedModelType;
  List<String> get customImageModels => List.unmodifiable(_customImageModels);

  /// 获取当前选定提供商的所有可用图像模型
  List<String> get availableImageModels {
    List<String> modelsToShow = [];
    if (_categorizedPresetImageModels.containsKey(_selectedImageProvider)) {
      modelsToShow.addAll(
        _categorizedPresetImageModels[_selectedImageProvider] ?? [],
      );
    } else if (_customImageProviders.containsKey(_selectedImageProvider)) {
      modelsToShow.addAll(_customImageProviders[_selectedImageProvider] ?? []);
    }
    modelsToShow.addAll(_customImageModels);
    return List.unmodifiable(modelsToShow.toSet().toList());
  }

  /// 获取所有图像生成提供商名称
  List<String> get allImageProviderNames {
    final names = defaultImageBaseUrls.keys.toList();
    names.addAll(_customImageProviders.keys);
    return List.unmodifiable(names.toSet().toList());
  }

  /// 获取图像生成提供商 URL
  String get imageProviderUrl {
    String baseUrl = _imageProviderUrl?.trim() ??
        defaultImageBaseUrls[_selectedImageProvider] ??
        defaultImageBaseUrls['OpenAI']!;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }

  // ==================== 初始化 ====================

  ImageModelProvider({this.modelRegistry}) {
    _loadSettings();
  }

  String _normalizeImageModelForProvider(String provider, String model) {
    if (provider == 'Google') {
      return GoogleImageService.normalizeModel(model);
    }
    return model.trim();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedImageProvider =
        prefs.getString(_selectedImageProviderKey) ?? 'OpenAI';
    _selectedImageModel = _normalizeImageModelForProvider(
      _selectedImageProvider,
      prefs.getString(_selectedImageModelKey) ?? 'dall-e-3',
    );
    _imageProviderUrl = prefs.getString(_imageProviderUrlKey);
    _customImageModels = prefs.getStringList(_customImageModelsKey) ?? [];
    _bflAspectRatio = prefs.getString(_bflAspectRatioKey);

    // 加载自定义图像生成提供商
    final String? customImageProvidersString =
        prefs.getString(_customImageProvidersKey);
    if (customImageProvidersString != null) {
      try {
        _customImageProviders = Map<String, List<String>>.from(
          json
              .decode(customImageProvidersString)
              .map((key, value) => MapEntry(key, List<String>.from(value))),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error loading custom image providers: $e');
        }
        _customImageProviders = {};
      }
    }

    // 加载模型类型
    final int? savedModelType = prefs.getInt(_selectedModelTypeKey);
    if (savedModelType != null &&
        savedModelType < available_model.ModelType.values.length) {
      _selectedModelType =
          available_model.ModelType.values[savedModelType];
    }

    _validateSelectedImageModelForProvider();
    // 初始化时同步模型到注册表
    await syncModelsToRegistry();
    notifyListeners();
  }

  // ==================== 模型选择 ====================

  /// 设置选定的图像生成模型
  Future<void> setSelectedImageModel(String model) async {
    final normalizedModel = _normalizeImageModelForProvider(
      _selectedImageProvider,
      model,
    );
    if (_selectedImageModel != normalizedModel) {
      _selectedImageModel = normalizedModel;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedImageModelKey, normalizedModel);
      notifyListeners();
    }
  }

  /// 设置选定的图像生成提供商
  Future<void> setSelectedImageProvider(String provider) async {
    if (_selectedImageProvider != provider) {
      _selectedImageProvider = provider;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedImageProviderKey, provider);
      _validateSelectedImageModelForProvider();
      notifyListeners();
    }
  }

  /// 设置自定义图像生成提供商 URL
  Future<void> setImageProviderUrl(String? url) async {
    _imageProviderUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      await prefs.setString(_imageProviderUrlKey, url);
    } else {
      await prefs.remove(_imageProviderUrlKey);
    }
    notifyListeners();
  }

  /// 设置 BFL Aspect Ratio
  Future<void> setBflAspectRatio(String? value) async {
    _bflAspectRatio = value;
    final prefs = await SharedPreferences.getInstance();
    if (value != null) {
      await prefs.setString(_bflAspectRatioKey, value);
    } else {
      await prefs.remove(_bflAspectRatioKey);
    }
    notifyListeners();
  }

  /// 设置模型类型
  Future<void> setSelectedModelType(available_model.ModelType type) async {
    if (_selectedModelType != type) {
      _selectedModelType = type;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_selectedModelTypeKey, type.index);
      notifyListeners();
    }
  }

  // ==================== 自定义模型管理 ====================

  /// 添加自定义图像生成模型
  Future<void> addCustomImageModel(String model) async {
    if (!_customImageModels.contains(model)) {
      _customImageModels.add(model);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customImageModelsKey, _customImageModels);
      notifyListeners();
    }
  }

  /// 移除自定义图像生成模型
  Future<void> removeCustomImageModel(String model) async {
    if (_customImageModels.remove(model)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customImageModelsKey, _customImageModels);
      notifyListeners();
    }
  }

  /// 添加自定义图像生成提供商
  Future<void> addCustomImageProvider(
    String provider,
    List<String> models,
  ) async {
    _customImageProviders[provider] = models;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customImageProvidersKey,
      json.encode(_customImageProviders),
    );
    // 同步到 ModelRegistry
    await syncModelsToRegistry();
    notifyListeners();
  }

  /// 移除自定义图像生成提供商
  Future<void> removeCustomImageProvider(String provider) async {
    _customImageProviders.remove(provider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customImageProvidersKey,
      json.encode(_customImageProviders),
    );
    notifyListeners();
  }

  // ==================== 验证 ====================

  /// 验证所选图像生成模型是否与提供商兼容
  void _validateSelectedImageModelForProvider() {
    final available = availableImageModels;
    if (!available.contains(_selectedImageModel)) {
      if (available.isNotEmpty) {
        _selectedImageModel = available.first;
      } else {
        _selectedImageProvider = 'OpenAI';
        _selectedImageModel = 'dall-e-3';
      }
    }
  }

  // ==================== 模型同步 ====================

  /// 将图像模型同步到模型注册表
  Future<void> syncModelsToRegistry() async {
    if (modelRegistry != null) {
      modelRegistry!.clearType(available_model.ModelType.image);
      // 1. 注册预设图像模型
      for (var provider in _categorizedPresetImageModels.keys) {
        for (var model in _categorizedPresetImageModels[provider]!) {
          final modelName = provider == 'Google'
              ? GoogleImageService.getDisplayName(model)
              : model;
          modelRegistry!.registerModel(
            AvailableModel(
              id: model,
              name: modelName,
              provider: provider,
              type: available_model.ModelType.image,
              supportsStreaming: false,
              capabilities: {},
              baseUrl: defaultImageBaseUrls[provider],
            ),
          );
        }
      }
      // 2. 注册自定义图像提供商及其模型
      for (var provider in _customImageProviders.keys) {
        for (var model in _customImageProviders[provider]!) {
          // 对于自定义提供商，如果当前选定的提供商是它，使用 _imageProviderUrl
          // 否则使用默认 URL 或 null（因为每个自定义提供商可能有自己的 URL，但目前只存储一个全局的）
          final baseUrl = (provider == _selectedImageProvider && _imageProviderUrl != null)
              ? _imageProviderUrl
              : defaultImageBaseUrls[provider];
          modelRegistry!.registerModel(
            AvailableModel(
              id: model,
              name: model,
              provider: provider,
              type: available_model.ModelType.image,
              supportsStreaming: false,
              capabilities: {},
              baseUrl: baseUrl,
            ),
          );
        }
      }
      // 3. 注册自定义图像模型（属于当前选定的提供商）
      for (var model in _customImageModels) {
        final baseUrl = _imageProviderUrl ??
            defaultImageBaseUrls[_selectedImageProvider] ??
            defaultImageBaseUrls['OpenAI']!;
        modelRegistry!.registerModel(
          AvailableModel(
            id: model,
            name: model,
            provider: _selectedImageProvider,
            type: available_model.ModelType.image,
            supportsStreaming: false,
            capabilities: {},
            baseUrl: baseUrl,
          ),
        );
      }
    }
  }

  // ==================== 导入/导出 ====================

  /// 导出图像生成配置为 Map
  Map<String, dynamic> toMap() {
    return {
      _selectedImageProviderKey: _selectedImageProvider,
      _selectedImageModelKey: _selectedImageModel,
      _imageProviderUrlKey: _imageProviderUrl,
      _customImageModelsKey: _customImageModels,
      _customImageProvidersKey: _customImageProviders,
      _bflAspectRatioKey: _bflAspectRatio,
      _selectedModelTypeKey: _selectedModelType.index,
    };
  }

  /// 从 Map 导入图像生成配置
  Future<void> fromMap(Map<String, dynamic> data) async {
    if (data.containsKey(_selectedImageProviderKey)) {
      _selectedImageProvider = data[_selectedImageProviderKey];
    }
    if (data.containsKey(_selectedImageModelKey)) {
      _selectedImageModel = _normalizeImageModelForProvider(
        _selectedImageProvider,
        data[_selectedImageModelKey],
      );
    }
    if (data.containsKey(_imageProviderUrlKey)) {
      _imageProviderUrl = data[_imageProviderUrlKey];
    }
    if (data.containsKey(_customImageModelsKey)) {
      _customImageModels = List<String>.from(data[_customImageModelsKey] ?? []);
    }
    if (data.containsKey(_customImageProvidersKey)) {
      final customImageProvidersData = data[_customImageProvidersKey];
      if (customImageProvidersData != null) {
        Map<String, List<String>> parsedProviders = {};

        if (customImageProvidersData is String && customImageProvidersData.isNotEmpty) {
          // Parse JSON string from XML export
          try {
            final decoded = json.decode(customImageProvidersData) as Map<String, dynamic>;
            parsedProviders = Map<String, List<String>>.from(
              decoded.map(
                (key, value) => MapEntry(key, List<String>.from(value as List)),
              ),
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error parsing custom image providers JSON: $e');
            }
            parsedProviders = {};
          }
        } else if (customImageProvidersData is Map) {
          // Already a Map from direct import
          parsedProviders = Map<String, List<String>>.from(
            customImageProvidersData.map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            ),
          );
        }

        _customImageProviders = parsedProviders;
      }
    }
    if (data.containsKey(_bflAspectRatioKey)) {
      _bflAspectRatio = data[_bflAspectRatioKey];
    }
    if (data.containsKey(_selectedModelTypeKey)) {
      final int typeIndex = data[_selectedModelTypeKey];
      if (typeIndex >= 0 &&
          typeIndex < available_model.ModelType.values.length) {
        _selectedModelType =
            available_model.ModelType.values[typeIndex];
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _selectedImageProviderKey,
      _selectedImageProvider,
    );
    await prefs.setString(_selectedImageModelKey, _selectedImageModel);
    if (_imageProviderUrl != null) {
      await prefs.setString(_imageProviderUrlKey, _imageProviderUrl!);
    }
    await prefs.setStringList(_customImageModelsKey, _customImageModels);
    await prefs.setString(
      _customImageProvidersKey,
      json.encode(_customImageProviders),
    );
    if (_bflAspectRatio != null) {
      await prefs.setString(_bflAspectRatioKey, _bflAspectRatio!);
    }
    await prefs.setInt(_selectedModelTypeKey, _selectedModelType.index);

    _validateSelectedImageModelForProvider();
    notifyListeners();
  }
}
