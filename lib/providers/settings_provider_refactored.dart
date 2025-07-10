import 'package:flutter/foundation.dart';
import '../core/logger.dart';
import '../constants/app_constants.dart';
import '../constants/shared_preferences_keys.dart';
import '../repositories/interfaces.dart';
import '../repositories/settings_repository_impl.dart';

enum ModelType { text, image }

class SettingsProvider with ChangeNotifier {
  final SettingsRepository _repository;
  
  // Current settings state
  String _selectedProvider = AppConstants.defaultProvider;
  String _selectedModel = AppConstants.defaultTextModel;
  String _selectedImageProvider = AppConstants.defaultProvider;
  String _selectedImageModel = AppConstants.defaultImageModel;
  ModelType _selectedModelType = ModelType.text;
  
  // API keys
  String? _apiKey;
  String? _imageApiKey;
  String? _claudeApiKey;
  String? _tavilyApiKey;
  String? _bingApiKey;
  
  // Provider URLs
  String? _providerUrl;
  String? _imageProviderUrl;
  
  // Custom models and providers
  List<String> _customModels = [];
  List<String> _customImageModels = [];
  Map<String, List<String>> _customProviders = {};
  Map<String, List<String>> _customImageProviders = {};
  
  // Loading state
  bool _isLoading = false;
  
  SettingsProvider({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepositoryImpl() {
    _loadSettings();
  }
  
  // Getters
  String get selectedProvider => _selectedProvider;
  String get selectedModel => _selectedModel;
  String get selectedImageProvider => _selectedImageProvider;
  String get selectedImageModel => _selectedImageModel;
  ModelType get selectedModelType => _selectedModelType;
  
  String? get apiKey => _apiKey;
  String? get imageApiKey => _imageApiKey;
  String? get claudeApiKey => _claudeApiKey;
  String? get tavilyApiKey => _tavilyApiKey;
  String? get bingApiKey => _bingApiKey;
  
  String? get providerUrl => _providerUrl;
  String? get imageProviderUrl => _imageProviderUrl;
  
  List<String> get customModels => List.unmodifiable(_customModels);
  List<String> get customImageModels => List.unmodifiable(_customImageModels);
  Map<String, List<String>> get customProviders => Map.unmodifiable(_customProviders);
  Map<String, List<String>> get customImageProviders => Map.unmodifiable(_customImageProviders);
  
  bool get isLoading => _isLoading;
  
  // Computed properties
  List<String> get availableProviders => [
    'OpenAI',
    'Google',
    'Anthropic',
    ...customProviders.keys,
  ];
  
  List<String> get availableImageProviders => [
    'OpenAI',
    'Stability AI',
    ...customImageProviders.keys,
  ];
  
  List<String> get availableModels {
    final models = <String>[];
    
    switch (_selectedProvider) {
      case 'OpenAI':
        models.addAll(['gpt-4', 'gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo']);
        break;
      case 'Google':
        models.addAll([
          'gemini-2.0-flash',
          'gemini-2.5-pro-preview-06-05',
          'gemini-2.5-flash-preview-05-20',
        ]);
        break;
      case 'Anthropic':
        models.addAll([
          'claude-3-5-sonnet-20241022',
          'claude-3-5-haiku-20241022',
          'claude-3-opus-20240229',
          'claude-3-sonnet-20240229',
          'claude-3-haiku-20240307',
        ]);
        break;
      default:
        if (_customProviders.containsKey(_selectedProvider)) {
          models.addAll(_customProviders[_selectedProvider]!);
        }
    }
    
    models.addAll(_customModels);
    return List.unmodifiable(models.toSet().toList());
  }
  
  List<String> get availableImageModels {
    final models = <String>[];
    
    switch (_selectedImageProvider) {
      case 'OpenAI':
        models.addAll(['dall-e-3', 'dall-e-2']);
        break;
      case 'Stability AI':
        models.addAll(['stable-diffusion-xl-1024-v1-0', 'stable-diffusion-v1-6']);
        break;
      default:
        if (_customImageProviders.containsKey(_selectedImageProvider)) {
          models.addAll(_customImageProviders[_selectedImageProvider]!);
        }
    }
    
    models.addAll(_customImageModels);
    return List.unmodifiable(models.toSet().toList());
  }
  
  String get effectiveProviderUrl {
    if (_providerUrl?.isNotEmpty == true) {
      return _providerUrl!;
    }
    
    switch (_selectedProvider) {
      case 'OpenAI':
        return AppConstants.openAIBaseUrl;
      case 'Google':
        return AppConstants.geminiBaseUrl;
      case 'Anthropic':
        return AppConstants.claudeBaseUrl;
      default:
        return AppConstants.openAIBaseUrl;
    }
  }
  
  String get effectiveImageProviderUrl {
    if (_imageProviderUrl?.isNotEmpty == true) {
      return _imageProviderUrl!;
    }
    
    switch (_selectedImageProvider) {
      case 'OpenAI':
        return AppConstants.openAIBaseUrl;
      default:
        return AppConstants.openAIBaseUrl;
    }
  }
  
  // Settings operations
  Future<void> _loadSettings() async {
    try {
      _setLoading(true);
      
      logInfo('Loading settings');
      
      // Load basic settings
      _selectedProvider = await _repository.getValue<String>(SharedPreferencesKeys.selectedProvider) ?? AppConstants.defaultProvider;
      _selectedModel = await _repository.getValue<String>(SharedPreferencesKeys.selectedModel) ?? AppConstants.defaultTextModel;
      _selectedImageProvider = await _repository.getValue<String>(SharedPreferencesKeys.selectedImageProvider) ?? AppConstants.defaultProvider;
      _selectedImageModel = await _repository.getValue<String>(SharedPreferencesKeys.selectedImageModel) ?? AppConstants.defaultImageModel;
      
      final modelTypeIndex = await _repository.getValue<int>(SharedPreferencesKeys.selectedModelType) ?? ModelType.text.index;
      _selectedModelType = ModelType.values[modelTypeIndex];
      
      // Load API keys
      _apiKey = await _repository.getApiKey('openai');
      _imageApiKey = await _repository.getApiKey('image');
      _claudeApiKey = await _repository.getApiKey('claude');
      _tavilyApiKey = await _repository.getApiKey('tavily');
      _bingApiKey = await _repository.getApiKey('bing');
      
      // Load provider URLs
      _providerUrl = await _repository.getValue<String>(SharedPreferencesKeys.providerUrl);
      _imageProviderUrl = await _repository.getValue<String>(SharedPreferencesKeys.imageProviderUrl);
      
      // Load custom models
      _customModels = await _repository.getValue<List<String>>(SharedPreferencesKeys.customModels) ?? [];
      _customImageModels = await _repository.getValue<List<String>>(SharedPreferencesKeys.customImageModels) ?? [];
      
      // TODO: Load custom providers (need to implement JSON serialization)
      
      _validateSelectedModel();
      _validateSelectedImageModel();
      
      logInfo('Settings loaded successfully');
      
    } catch (e, stackTrace) {
      logError('Failed to load settings', error: e, stackTrace: stackTrace);
      // Continue with defaults
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> setSelectedProvider(String provider) async {
    if (_selectedProvider != provider) {
      _selectedProvider = provider;
      await _repository.setValue<String>(SharedPreferencesKeys.selectedProvider, provider);
      _validateSelectedModel();
      notifyListeners();
    }
  }
  
  Future<void> setSelectedModel(String model) async {
    if (availableModels.contains(model)) {
      _selectedModel = model;
      await _repository.setSelectedModel('text', model);
      notifyListeners();
    }
  }
  
  Future<void> setSelectedImageProvider(String provider) async {
    if (_selectedImageProvider != provider) {
      _selectedImageProvider = provider;
      await _repository.setValue<String>(SharedPreferencesKeys.selectedImageProvider, provider);
      _validateSelectedImageModel();
      notifyListeners();
    }
  }
  
  Future<void> setSelectedImageModel(String model) async {
    if (availableImageModels.contains(model)) {
      _selectedImageModel = model;
      await _repository.setSelectedModel('image', model);
      notifyListeners();
    }
  }
  
  Future<void> setSelectedModelType(ModelType type) async {
    if (_selectedModelType != type) {
      _selectedModelType = type;
      await _repository.setValue<int>(SharedPreferencesKeys.selectedModelType, type.index);
      notifyListeners();
    }
  }
  
  Future<void> setApiKey(String? apiKey) async {
    _apiKey = apiKey;
    if (apiKey?.isNotEmpty == true) {
      await _repository.setApiKey('openai', apiKey!);
    } else {
      await _repository.removeValue(SharedPreferencesKeys.apiKey);
    }
    notifyListeners();
  }
  
  Future<void> setImageApiKey(String? apiKey) async {
    _imageApiKey = apiKey;
    if (apiKey?.isNotEmpty == true) {
      await _repository.setApiKey('image', apiKey!);
    } else {
      await _repository.removeValue(SharedPreferencesKeys.imageApiKey);
    }
    notifyListeners();
  }
  
  Future<void> setClaudeApiKey(String? apiKey) async {
    _claudeApiKey = apiKey;
    if (apiKey?.isNotEmpty == true) {
      await _repository.setApiKey('claude', apiKey!);
    } else {
      await _repository.removeValue(SharedPreferencesKeys.claudeApiKey);
    }
    notifyListeners();
  }
  
  Future<void> setTavilyApiKey(String? apiKey) async {
    _tavilyApiKey = apiKey;
    if (apiKey?.isNotEmpty == true) {
      await _repository.setApiKey('tavily', apiKey!);
    } else {
      await _repository.removeValue(SharedPreferencesKeys.tavilyApiKey);
    }
    notifyListeners();
  }
  
  Future<void> setBingApiKey(String? apiKey) async {
    _bingApiKey = apiKey;
    if (apiKey?.isNotEmpty == true) {
      await _repository.setApiKey('bing', apiKey!);
    } else {
      await _repository.removeValue(SharedPreferencesKeys.bingApiKey);
    }
    notifyListeners();
  }
  
  Future<void> setProviderUrl(String? url) async {
    _providerUrl = url?.trim().isEmpty == true ? null : url?.trim();
    if (_providerUrl != null) {
      await _repository.setValue<String>(SharedPreferencesKeys.providerUrl, _providerUrl!);
    } else {
      await _repository.removeValue(SharedPreferencesKeys.providerUrl);
    }
    notifyListeners();
  }
  
  Future<void> setImageProviderUrl(String? url) async {
    _imageProviderUrl = url?.trim().isEmpty == true ? null : url?.trim();
    if (_imageProviderUrl != null) {
      await _repository.setValue<String>(SharedPreferencesKeys.imageProviderUrl, _imageProviderUrl!);
    } else {
      await _repository.removeValue(SharedPreferencesKeys.imageProviderUrl);
    }
    notifyListeners();
  }
  
  Future<void> addCustomModel(String model) async {
    if (model.trim().isNotEmpty && !_customModels.contains(model.trim())) {
      _customModels.add(model.trim());
      await _repository.setValue<List<String>>(SharedPreferencesKeys.customModels, _customModels);
      notifyListeners();
    }
  }
  
  Future<void> removeCustomModel(String model) async {
    if (_customModels.remove(model)) {
      await _repository.setValue<List<String>>(SharedPreferencesKeys.customModels, _customModels);
      if (_selectedModel == model) {
        _validateSelectedModel();
      }
      notifyListeners();
    }
  }
  
  Future<void> addCustomImageModel(String model) async {
    if (model.trim().isNotEmpty && !_customImageModels.contains(model.trim())) {
      _customImageModels.add(model.trim());
      await _repository.setValue<List<String>>(SharedPreferencesKeys.customImageModels, _customImageModels);
      notifyListeners();
    }
  }
  
  Future<void> removeCustomImageModel(String model) async {
    if (_customImageModels.remove(model)) {
      await _repository.setValue<List<String>>(SharedPreferencesKeys.customImageModels, _customImageModels);
      if (_selectedImageModel == model) {
        _validateSelectedImageModel();
      }
      notifyListeners();
    }
  }
  
  Future<void> clearAllSettings() async {
    await _repository.clear();
    _resetToDefaults();
    notifyListeners();
  }
  
  // Validation methods
  void _validateSelectedModel() {
    if (!availableModels.contains(_selectedModel)) {
      final models = availableModels;
      if (models.isNotEmpty) {
        _selectedModel = models.first;
        _repository.setSelectedModel('text', _selectedModel);
      }
    }
  }
  
  void _validateSelectedImageModel() {
    if (!availableImageModels.contains(_selectedImageModel)) {
      final models = availableImageModels;
      if (models.isNotEmpty) {
        _selectedImageModel = models.first;
        _repository.setSelectedModel('image', _selectedImageModel);
      }
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
      default:
        return _apiKey;
    }
  }
  
  String? get currentProviderApiKey => getApiKeyForProvider(_selectedProvider);
  
  void _resetToDefaults() {
    _selectedProvider = AppConstants.defaultProvider;
    _selectedModel = AppConstants.defaultTextModel;
    _selectedImageProvider = AppConstants.defaultProvider;
    _selectedImageModel = AppConstants.defaultImageModel;
    _selectedModelType = ModelType.text;
    _apiKey = null;
    _imageApiKey = null;
    _claudeApiKey = null;
    _tavilyApiKey = null;
    _bingApiKey = null;
    _providerUrl = null;
    _imageProviderUrl = null;
    _customModels = [];
    _customImageModels = [];
    _customProviders = {};
    _customImageProviders = {};
  }
  
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}