import '../core/exceptions.dart';
import '../core/logger.dart';
import '../core/shared_preferences_manager.dart';
import '../constants/shared_preferences_keys.dart';
import '../repositories/interfaces.dart';

class SettingsRepositoryImpl extends SettingsRepository {
  SettingsRepositoryImpl();

  @override
  Future<T?> getValue<T>(String key) async {
    try {
      logDebug('Getting setting value: $key');

      if (T == String) {
        return await SharedPreferencesManager.getString(key) as T?;
      } else if (T == int) {
        return await SharedPreferencesManager.getInt(key) as T?;
      } else if (T == bool) {
        return await SharedPreferencesManager.getBool(key) as T?;
      } else if (T == List<String>) {
        return await SharedPreferencesManager.getStringList(key) as T?;
      } else {
        throw ValidationException(
          'Unsupported type for settings: $T',
          'type',
          code: 'UNSUPPORTED_TYPE',
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to get setting value: $key',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException) rethrow;
      throw StorageException(
        'Failed to get setting value',
        code: 'GET_SETTING_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setValue<T>(String key, T value) async {
    try {
      logDebug('Setting value: $key');

      if (value is String) {
        await SharedPreferencesManager.setString(key, value);
      } else if (value is int) {
        await SharedPreferencesManager.setInt(key, value);
      } else if (value is bool) {
        await SharedPreferencesManager.setBool(key, value);
      } else if (value is List<String>) {
        await SharedPreferencesManager.setStringList(key, value);
      } else {
        throw ValidationException(
          'Unsupported type for settings: ${value.runtimeType}',
          'type',
          code: 'UNSUPPORTED_TYPE',
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to set setting value: $key',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException) rethrow;
      throw StorageException(
        'Failed to set setting value',
        code: 'SET_SETTING_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> removeValue(String key) async {
    try {
      logDebug('Removing setting: $key');
      await SharedPreferencesManager.remove(key);
    } catch (e, stackTrace) {
      logError(
        'Failed to remove setting: $key',
        error: e,
        stackTrace: stackTrace,
      );
      throw StorageException(
        'Failed to remove setting',
        code: 'REMOVE_SETTING_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return await SharedPreferencesManager.containsKey(key);
    } catch (e, stackTrace) {
      logError(
        'Failed to check if setting exists: $key',
        error: e,
        stackTrace: stackTrace,
      );
      throw StorageException(
        'Failed to check if setting exists',
        code: 'CHECK_SETTING_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      logInfo('Clearing all settings');
      await SharedPreferencesManager.clear();
    } catch (e, stackTrace) {
      logError('Failed to clear settings', error: e, stackTrace: stackTrace);
      throw StorageException(
        'Failed to clear settings',
        code: 'CLEAR_SETTINGS_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<String?> getApiKey(String provider) async {
    final key = _getApiKeyKey(provider);
    return await getValue<String>(key);
  }

  @override
  Future<void> setApiKey(String provider, String apiKey) async {
    final key = _getApiKeyKey(provider);
    await setValue<String>(key, apiKey);
  }

  @override
  Future<String?> getSelectedModel(String provider) async {
    final key = _getSelectedModelKey(provider);
    return await getValue<String>(key);
  }

  @override
  Future<void> setSelectedModel(String provider, String model) async {
    final key = _getSelectedModelKey(provider);
    await setValue<String>(key, model);
  }

  // Helper methods
  String _getApiKeyKey(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return SharedPreferencesKeys.apiKey;
      case 'google':
      case 'gemini':
        return SharedPreferencesKeys.apiKey; // For now, using same key
      case 'anthropic':
      case 'claude':
        return SharedPreferencesKeys.claudeApiKey;
      case 'image':
        return SharedPreferencesKeys.imageApiKey;
      case 'tavily':
        return SharedPreferencesKeys.tavilyApiKey;
      default:
        return '${provider}_api_key';
    }
  }

  String _getSelectedModelKey(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
      case 'google':
      case 'gemini':
      case 'anthropic':
      case 'claude':
        return SharedPreferencesKeys.selectedModel;
      case 'image':
        return SharedPreferencesKeys.selectedImageModel;
      default:
        return '${provider}_selected_model';
    }
  }
}
