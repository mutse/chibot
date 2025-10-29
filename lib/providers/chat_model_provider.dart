import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/model_registry.dart';
import '../models/available_model.dart';
import 'package:chibot/models/available_model.dart' as available_model;

/// 负责聊天相关的模型配置和提供商管理
/// 职责：选择聊天模型、管理提供商、配置提供商 URL
class ChatModelProvider with ChangeNotifier {
  final ModelRegistry? modelRegistry;

  // 当前选定的聊天模型提供商
  String _selectedProvider = 'OpenAI';
  static const String _selectedProviderKey = 'selected_model_provider';

  // 当前选定的聊天模型
  String _selectedModel = 'gpt-4o';
  static const String _selectedModelKey = 'openai_selected_model';

  // 自定义提供商 URL
  String? _providerUrl;
  static const String _providerUrlKey = 'openai_provider_url';

  // 自定义模型列表
  List<String> _customModels = [];
  static const String _customModelsKey = 'custom_models_list';

  // 自定义提供商及其模型
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
    'OpenAI': ['gpt-4', 'gpt-4o', 'gpt-4.1'],
    'Google': [
      'gemini-2.0-flash',
      'gemini-2.5-pro-preview-06-05',
      'gemini-2.5-flash-preview-05-20',
    ],
    'Anthropic': ['claude-3-5-sonnet-20241022', 'claude-3-5-haiku-20241022'],
  };

  // ==================== Getters ====================

  String get selectedProvider => _selectedProvider;
  String get selectedModel => _selectedModel;
  String? get rawProviderUrl => _providerUrl;
  List<String> get customModels => List.unmodifiable(_customModels);

  /// 获取当前选定提供商的所有可用模型（包括自定义）
  List<String> get availableModels {
    List<String> modelsToShow = [];
    if (_categorizedPresetModels.containsKey(_selectedProvider)) {
      modelsToShow.addAll(_categorizedPresetModels[_selectedProvider] ?? []);
    } else if (_customProviders.containsKey(_selectedProvider)) {
      modelsToShow.addAll(_customProviders[_selectedProvider] ?? []);
    }
    modelsToShow.addAll(_customModels);
    return List.unmodifiable(modelsToShow.toSet().toList());
  }

  /// 获取所有提供商名称（预设 + 自定义）
  List<String> get allProviderNames {
    final names = defaultBaseUrls.keys.toList();
    names.addAll(_customProviders.keys);
    return List.unmodifiable(names.toSet().toList());
  }

  /// 获取提供商 URL（优先使用自定义，否则使用默认）
  String get providerUrl {
    String baseUrl = _providerUrl?.trim() ??
        defaultBaseUrls[_selectedProvider] ??
        defaultBaseUrls['OpenAI']!;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }

  // ==================== 初始化 ====================

  ChatModelProvider({this.modelRegistry}) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedProvider = prefs.getString(_selectedProviderKey) ?? 'OpenAI';
    _selectedModel = prefs.getString(_selectedModelKey) ?? 'gpt-4o';
    _providerUrl = prefs.getString(_providerUrlKey);
    _customModels = prefs.getStringList(_customModelsKey) ?? [];

    // 加载自定义提供商
    final String? customProvidersString = prefs.getString(_customProvidersKey);
    if (customProvidersString != null) {
      try {
        _customProviders = Map<String, List<String>>.from(
          json
              .decode(customProvidersString)
              .map((key, value) => MapEntry(key, List<String>.from(value))),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error loading custom providers: $e');
        }
        _customProviders = {};
      }
    }

    _validateSelectedModelForProvider();
    notifyListeners();
  }

  // ==================== 模型选择 ====================

  /// 设置选定的聊天模型
  Future<void> setSelectedModel(String model) async {
    if (_selectedModel != model) {
      _selectedModel = model;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedModelKey, model);
      await syncModelsToRegistry();
      notifyListeners();
    }
  }

  /// 设置选定的提供商
  Future<void> setSelectedProvider(String provider) async {
    if (_selectedProvider != provider) {
      _selectedProvider = provider;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedProviderKey, provider);
      _validateSelectedModelForProvider();
      await syncModelsToRegistry();
      notifyListeners();
    }
  }

  /// 设置自定义提供商 URL
  Future<void> setProviderUrl(String? url) async {
    _providerUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      await prefs.setString(_providerUrlKey, url);
    } else {
      await prefs.remove(_providerUrlKey);
    }
    notifyListeners();
  }

  // ==================== 自定义模型管理 ====================

  /// 添加自定义模型
  Future<void> addCustomModel(String model) async {
    if (!_customModels.contains(model)) {
      _customModels.add(model);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customModelsKey, _customModels);
      notifyListeners();
    }
  }

  /// 移除自定义模型
  Future<void> removeCustomModel(String model) async {
    if (_customModels.remove(model)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customModelsKey, _customModels);
      notifyListeners();
    }
  }

  /// 添加自定义提供商及其模型
  Future<void> addCustomProvider(String provider, List<String> models) async {
    _customProviders[provider] = models;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customProvidersKey, json.encode(_customProviders));
    notifyListeners();
  }

  /// 移除自定义提供商
  Future<void> removeCustomProvider(String provider) async {
    _customProviders.remove(provider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customProvidersKey, json.encode(_customProviders));
    notifyListeners();
  }

  // ==================== 验证和同步 ====================

  /// 验证所选模型是否与提供商兼容
  void _validateSelectedModelForProvider() {
    final available = availableModels;
    if (!available.contains(_selectedModel)) {
      // 如果当前模型不可用，选择该提供商的第一个模型
      if (available.isNotEmpty) {
        _selectedModel = available.first;
      } else {
        // 降级到 OpenAI 的默认模型
        _selectedProvider = 'OpenAI';
        _selectedModel = 'gpt-4o';
      }
    }
  }

  /// 将模型同步到模型注册表
  Future<void> syncModelsToRegistry() async {
    if (modelRegistry != null) {
      // 注册当前提供商的所有可用模型
      for (final model in availableModels) {
        modelRegistry!.registerModel(
          AvailableModel(
            id: model,
            name: model,
            provider: _selectedProvider,
            type: available_model.ModelType.text,
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
      _providerUrlKey: _providerUrl,
      _customModelsKey: _customModels,
      _customProvidersKey: _customProviders,
    };
  }

  /// 从 Map 导入聊天模型配置
  Future<void> fromMap(Map<String, dynamic> data) async {
    if (data.containsKey(_selectedProviderKey)) {
      _selectedProvider = data[_selectedProviderKey];
    }
    if (data.containsKey(_selectedModelKey)) {
      _selectedModel = data[_selectedModelKey];
    }
    if (data.containsKey(_providerUrlKey)) {
      _providerUrl = data[_providerUrlKey];
    }
    if (data.containsKey(_customModelsKey)) {
      _customModels = List<String>.from(data[_customModelsKey] ?? []);
    }
    if (data.containsKey(_customProvidersKey)) {
      _customProviders = Map<String, List<String>>.from(
        (data[_customProvidersKey] as Map).map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedProviderKey, _selectedProvider);
    await prefs.setString(_selectedModelKey, _selectedModel);
    if (_providerUrl != null) {
      await prefs.setString(_providerUrlKey, _providerUrl!);
    }
    await prefs.setStringList(_customModelsKey, _customModels);
    await prefs.setString(_customProvidersKey, json.encode(_customProviders));
    _validateSelectedModelForProvider();
    await syncModelsToRegistry();
    notifyListeners();
  }
}
