import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';

class SharedPreferencesManager {
  static SharedPreferences? _prefs;
  
  static Future<SharedPreferences> get _instance async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
  
  // String operations
  static Future<void> setString(String key, String value) async {
    try {
      final prefs = await _instance;
      await prefs.setString(key, value);
      AppLogger.debug('Saved string to preferences: $key');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save string to preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to save string to preferences', 
        code: 'PREFS_SET_STRING_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  static Future<String?> getString(String key) async {
    try {
      final prefs = await _instance;
      final value = prefs.getString(key);
      AppLogger.debug('Retrieved string from preferences: $key = $value');
      return value;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve string from preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to retrieve string from preferences', 
        code: 'PREFS_GET_STRING_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  // Integer operations
  static Future<void> setInt(String key, int value) async {
    try {
      final prefs = await _instance;
      await prefs.setInt(key, value);
      AppLogger.debug('Saved int to preferences: $key = $value');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save int to preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to save int to preferences', 
        code: 'PREFS_SET_INT_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  static Future<int?> getInt(String key) async {
    try {
      final prefs = await _instance;
      final value = prefs.getInt(key);
      AppLogger.debug('Retrieved int from preferences: $key = $value');
      return value;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve int from preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to retrieve int from preferences', 
        code: 'PREFS_GET_INT_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  // Boolean operations
  static Future<void> setBool(String key, bool value) async {
    try {
      final prefs = await _instance;
      await prefs.setBool(key, value);
      AppLogger.debug('Saved bool to preferences: $key = $value');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save bool to preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to save bool to preferences', 
        code: 'PREFS_SET_BOOL_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  static Future<bool?> getBool(String key) async {
    try {
      final prefs = await _instance;
      final value = prefs.getBool(key);
      AppLogger.debug('Retrieved bool from preferences: $key = $value');
      return value;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve bool from preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to retrieve bool from preferences', 
        code: 'PREFS_GET_BOOL_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  // String list operations
  static Future<void> setStringList(String key, List<String> value) async {
    try {
      final prefs = await _instance;
      await prefs.setStringList(key, value);
      AppLogger.debug('Saved string list to preferences: $key (${value.length} items)');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save string list to preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to save string list to preferences', 
        code: 'PREFS_SET_STRING_LIST_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  static Future<List<String>> getStringList(String key) async {
    try {
      final prefs = await _instance;
      final value = prefs.getStringList(key) ?? [];
      AppLogger.debug('Retrieved string list from preferences: $key (${value.length} items)');
      return value;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve string list from preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to retrieve string list from preferences', 
        code: 'PREFS_GET_STRING_LIST_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  // JSON object operations
  static Future<void> setObject<T>(String key, T object, Map<String, dynamic> Function(T) toJson) async {
    try {
      final jsonString = jsonEncode(toJson(object));
      await setString(key, jsonString);
      AppLogger.debug('Saved object to preferences: $key');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save object to preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to save object to preferences', 
        code: 'PREFS_SET_OBJECT_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  static Future<T?> getObject<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) return null;
      
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final object = fromJson(jsonMap);
      AppLogger.debug('Retrieved object from preferences: $key');
      return object;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve object from preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to retrieve object from preferences', 
        code: 'PREFS_GET_OBJECT_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  // JSON object list operations
  static Future<void> setObjectList<T>(String key, List<T> objects, Map<String, dynamic> Function(T) toJson) async {
    try {
      final jsonList = objects.map((obj) => toJson(obj)).toList();
      final jsonString = jsonEncode(jsonList);
      await setString(key, jsonString);
      AppLogger.debug('Saved object list to preferences: $key (${objects.length} items)');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save object list to preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to save object list to preferences', 
        code: 'PREFS_SET_OBJECT_LIST_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  static Future<List<T>> getObjectList<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final objects = jsonList
          .cast<Map<String, dynamic>>()
          .map((json) => fromJson(json))
          .toList();
      AppLogger.debug('Retrieved object list from preferences: $key (${objects.length} items)');
      return objects;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve object list from preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to retrieve object list from preferences', 
        code: 'PREFS_GET_OBJECT_LIST_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  // Remove operations
  static Future<void> remove(String key) async {
    try {
      final prefs = await _instance;
      await prefs.remove(key);
      AppLogger.debug('Removed key from preferences: $key');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to remove key from preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to remove key from preferences', 
        code: 'PREFS_REMOVE_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  // Check if key exists
  static Future<bool> containsKey(String key) async {
    try {
      final prefs = await _instance;
      final exists = prefs.containsKey(key);
      AppLogger.debug('Checked key existence in preferences: $key = $exists');
      return exists;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check key existence in preferences: $key', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to check key existence in preferences', 
        code: 'PREFS_CONTAINS_KEY_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
  
  // Clear all preferences
  static Future<void> clear() async {
    try {
      final prefs = await _instance;
      await prefs.clear();
      AppLogger.info('Cleared all preferences');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear preferences', 
        error: e, stackTrace: stackTrace);
      throw StorageException('Failed to clear preferences', 
        code: 'PREFS_CLEAR_ERROR', originalError: e, stackTrace: stackTrace);
    }
  }
}