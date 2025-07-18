import 'encryption_utils.dart';

class SettingsXmlHandler {
  static String exportToXml(Map<String, dynamic> settings) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<settings>');
    
    _writeApiKeys(buffer, settings);
    _writeProviderSettings(buffer, settings);
    _writeModelSettings(buffer, settings);
    _writeImageSettings(buffer, settings);
    _writeCustomSettings(buffer, settings);
    _writeWebSearchSettings(buffer, settings);
    
    buffer.writeln('</settings>');
    return buffer.toString();
  }

  static Map<String, dynamic> importFromXml(String xmlContent) {
    final settings = <String, dynamic>{};
    
    // Remove XML declaration and root tags
    String content = xmlContent.trim();
    if (content.startsWith('<?xml')) {
      content = content.substring(content.indexOf('>') + 1);
    }
    content = content.trim();
    if (content.startsWith('<settings>')) {
      content = content.substring(10);
    }
    if (content.endsWith('</settings>')) {
      content = content.substring(0, content.length - 11);
    }
    
    // Parse sections
    settings.addAll(_parseApiKeys(content));
    settings.addAll(_parseProviderSettings(content));
    settings.addAll(_parseModelSettings(content));
    settings.addAll(_parseImageSettings(content));
    settings.addAll(_parseCustomSettings(content));
    settings.addAll(_parseWebSearchSettings(content));
    
    return settings;
  }

  static void _writeApiKeys(StringBuffer buffer, Map<String, dynamic> settings) {
    buffer.writeln('  <api_keys>');
    _writeEncryptedXmlTag(buffer, 'openai_api_key', settings['openai_api_key'], 4);
    _writeEncryptedXmlTag(buffer, 'claude_api_key', settings['claude_api_key'], 4);
    _writeEncryptedXmlTag(buffer, 'image_api_key', settings['image_api_key'], 4);
    _writeEncryptedXmlTag(buffer, 'tavily_api_key', settings['tavily_api_key'], 4);
    // 新增 Google Search API Key
    _writeEncryptedXmlTag(buffer, 'google_search_api_key', settings['google_search_api_key'], 4);
    buffer.writeln('  </api_keys>');
  }

  static void _writeProviderSettings(StringBuffer buffer, Map<String, dynamic> settings) {
    buffer.writeln('  <provider_settings>');
    _writeXmlTag(buffer, 'selected_provider', settings['selected_model_provider'], 4);
    _writeXmlTag(buffer, 'provider_url', settings['openai_provider_url'], 4);
    _writeXmlTag(buffer, 'selected_model_type', settings['selected_model_type'], 4);
    buffer.writeln('  </provider_settings>');
  }

  static void _writeModelSettings(StringBuffer buffer, Map<String, dynamic> settings) {
    buffer.writeln('  <model_settings>');
    _writeXmlTag(buffer, 'selected_model', settings['openai_selected_model'], 4);
    
    // Custom models list
    final customModels = settings['custom_models_list'] as List<String>?;
    if (customModels != null && customModels.isNotEmpty) {
      buffer.writeln('    <custom_models>');
      for (final model in customModels) {
        _writeXmlTag(buffer, 'model', model, 6);
      }
      buffer.writeln('    </custom_models>');
    }
    
    // Custom providers map
    final customProviders = settings['custom_providers_map'] as String?;
    if (customProviders != null && customProviders.isNotEmpty) {
      _writeXmlTag(buffer, 'custom_providers', customProviders, 4);
    }
    
    buffer.writeln('  </model_settings>');
  }

  static void _writeImageSettings(StringBuffer buffer, Map<String, dynamic> settings) {
    buffer.writeln('  <image_settings>');
    _writeXmlTag(buffer, 'selected_image_provider', settings['selected_image_provider'], 4);
    _writeXmlTag(buffer, 'selected_image_model', settings['selected_image_model'], 4);
    _writeXmlTag(buffer, 'image_provider_url', settings['image_provider_url'], 4);
    
    // Custom image models list
    final customImageModels = settings['custom_image_models_list'] as List<String>?;
    if (customImageModels != null && customImageModels.isNotEmpty) {
      buffer.writeln('    <custom_image_models>');
      for (final model in customImageModels) {
        _writeXmlTag(buffer, 'model', model, 6);
      }
      buffer.writeln('    </custom_image_models>');
    }
    
    // Custom image providers map
    final customImageProviders = settings['custom_image_providers_map'] as String?;
    if (customImageProviders != null && customImageProviders.isNotEmpty) {
      _writeXmlTag(buffer, 'custom_image_providers', customImageProviders, 4);
    }
    
    buffer.writeln('  </image_settings>');
  }

  static void _writeCustomSettings(StringBuffer buffer, Map<String, dynamic> settings) {
    buffer.writeln('  <custom_settings>');
    // Add any additional custom settings here
    buffer.writeln('  </custom_settings>');
  }

  static void _writeWebSearchSettings(StringBuffer buffer, Map<String, dynamic> settings) {
    buffer.writeln('  <web_search_settings>');
    _writeEncryptedXmlTag(buffer, 'tavily_api_key', settings['tavily_api_key'], 4);
    // 新增 Google Search API Key
    _writeEncryptedXmlTag(buffer, 'google_search_api_key', settings['google_search_api_key'], 4);
    // 新增 Google Search Engine ID（不加密）
    _writeXmlTag(buffer, 'google_search_engine_id', settings['google_search_engine_id'], 4);
    buffer.writeln('  </web_search_settings>');
  }

  static void _writeXmlTag(StringBuffer buffer, String tag, dynamic value, int indent) {
    if (value == null) return;
    
    final spaces = ' ' * indent;
    final escapedValue = _escapeXml(value.toString());
    buffer.writeln('$spaces<$tag>$escapedValue</$tag>');
  }

  static void _writeEncryptedXmlTag(StringBuffer buffer, String tag, dynamic value, int indent) {
    if (value == null || value.toString().isEmpty) return;
    
    final spaces = ' ' * indent;
    final encryptedValue = EncryptionUtils.aesEncrypt(value.toString());
    final escapedValue = _escapeXml(encryptedValue);
    buffer.writeln('$spaces<$tag>$escapedValue</$tag>');
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _unescapeXml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  static Map<String, dynamic> _parseApiKeys(String content) {
    final settings = <String, dynamic>{};
    final apiKeysMatch = RegExp(r'<api_keys>(.*?)</api_keys>', dotAll: true).firstMatch(content);
    
    if (apiKeysMatch != null) {
      final apiKeysContent = apiKeysMatch.group(1)!;
      settings['openai_api_key'] = _extractEncryptedTagValue(apiKeysContent, 'openai_api_key');
      settings['claude_api_key'] = _extractEncryptedTagValue(apiKeysContent, 'claude_api_key');
      settings['image_api_key'] = _extractEncryptedTagValue(apiKeysContent, 'image_api_key');
      settings['tavily_api_key'] = _extractEncryptedTagValue(apiKeysContent, 'tavily_api_key');
      // 新增 Google Search API Key
      settings['google_search_api_key'] = _extractEncryptedTagValue(apiKeysContent, 'google_search_api_key');
    }
    
    return settings;
  }

  static Map<String, dynamic> _parseProviderSettings(String content) {
    final settings = <String, dynamic>{};
    final providerMatch = RegExp(r'<provider_settings>(.*?)</provider_settings>', dotAll: true).firstMatch(content);
    
    if (providerMatch != null) {
      final providerContent = providerMatch.group(1)!;
      settings['selected_model_provider'] = _extractTagValue(providerContent, 'selected_provider');
      settings['openai_provider_url'] = _extractTagValue(providerContent, 'provider_url');
      final modelTypeStr = _extractTagValue(providerContent, 'selected_model_type');
      if (modelTypeStr != null) {
        settings['selected_model_type'] = int.tryParse(modelTypeStr) ?? 0;
      }
    }
    
    return settings;
  }

  static Map<String, dynamic> _parseModelSettings(String content) {
    final settings = <String, dynamic>{};
    final modelMatch = RegExp(r'<model_settings>(.*?)</model_settings>', dotAll: true).firstMatch(content);
    
    if (modelMatch != null) {
      final modelContent = modelMatch.group(1)!;
      settings['openai_selected_model'] = _extractTagValue(modelContent, 'selected_model');
      settings['custom_providers_map'] = _extractTagValue(modelContent, 'custom_providers');
      
      // Parse custom models list
      final customModelsMatch = RegExp(r'<custom_models>(.*?)</custom_models>', dotAll: true).firstMatch(modelContent);
      if (customModelsMatch != null) {
        final customModelsContent = customModelsMatch.group(1)!;
        final models = <String>[];
        final modelMatches = RegExp(r'<model>(.*?)</model>').allMatches(customModelsContent);
        for (final match in modelMatches) {
          final model = _unescapeXml(match.group(1)!.trim());
          if (model.isNotEmpty) {
            models.add(model);
          }
        }
        settings['custom_models_list'] = models;
      }
    }
    
    return settings;
  }

  static Map<String, dynamic> _parseImageSettings(String content) {
    final settings = <String, dynamic>{};
    final imageMatch = RegExp(r'<image_settings>(.*?)</image_settings>', dotAll: true).firstMatch(content);
    
    if (imageMatch != null) {
      final imageContent = imageMatch.group(1)!;
      settings['selected_image_provider'] = _extractTagValue(imageContent, 'selected_image_provider');
      settings['selected_image_model'] = _extractTagValue(imageContent, 'selected_image_model');
      settings['image_provider_url'] = _extractTagValue(imageContent, 'image_provider_url');
      settings['custom_image_providers_map'] = _extractTagValue(imageContent, 'custom_image_providers');
      
      // Parse custom image models list
      final customImageModelsMatch = RegExp(r'<custom_image_models>(.*?)</custom_image_models>', dotAll: true).firstMatch(imageContent);
      if (customImageModelsMatch != null) {
        final customImageModelsContent = customImageModelsMatch.group(1)!;
        final models = <String>[];
        final modelMatches = RegExp(r'<model>(.*?)</model>').allMatches(customImageModelsContent);
        for (final match in modelMatches) {
          final model = _unescapeXml(match.group(1)!.trim());
          if (model.isNotEmpty) {
            models.add(model);
          }
        }
        settings['custom_image_models_list'] = models;
      }
    }
    
    return settings;
  }

  static Map<String, dynamic> _parseCustomSettings(String content) {
    final settings = <String, dynamic>{};
    // Add parsing for any additional custom settings here
    return settings;
  }

  static Map<String, dynamic> _parseWebSearchSettings(String content) {
    final settings = <String, dynamic>{};
    final webSearchMatch = RegExp(r'<web_search_settings>(.*?)</web_search_settings>', dotAll: true).firstMatch(content);
    
    if (webSearchMatch != null) {
      final webSearchContent = webSearchMatch.group(1)!;
      settings['tavily_api_key'] = _extractEncryptedTagValue(webSearchContent, 'tavily_api_key');
      // 新增 Google Search API Key
      settings['google_search_api_key'] = _extractEncryptedTagValue(webSearchContent, 'google_search_api_key');
      // 新增 Google Search Engine ID（不加密）
      settings['google_search_engine_id'] = _extractTagValue(webSearchContent, 'google_search_engine_id');
    }
    
    return settings;
  }

  static String? _extractTagValue(String content, String tag) {
    final match = RegExp('<$tag>(.*?)</$tag>').firstMatch(content);
    if (match != null) {
      final value = _unescapeXml(match.group(1)!.trim());
      return value.isEmpty ? null : value;
    }
    return null;
  }

  static String? _extractEncryptedTagValue(String content, String tag) {
    final match = RegExp('<$tag>(.*?)</$tag>').firstMatch(content);
    if (match != null) {
      final encryptedValue = _unescapeXml(match.group(1)!.trim());
      if (encryptedValue.isEmpty) return null;
      
      // 尝试AES解密，如果失败则尝试简单解密（向后兼容）
      final decryptedValue = EncryptionUtils.aesDecrypt(encryptedValue);
      return decryptedValue;
    }
    return null;
  }
}