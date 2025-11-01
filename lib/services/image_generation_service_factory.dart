import 'package:flutter/foundation.dart';
import 'google_image_service.dart';
import 'flux_kontext_service.dart';
import 'flux_krea_service.dart';

/// 图像生成服务工厂 - 根据提供商创建图像生成服务
///
/// 职责：
/// - 根据提供商和模型类型路由到正确的服务
/// - 处理服务初始化和配置
/// - 管理供应商特定的逻辑
class ImageGenerationServiceFactory {
  static const String google = 'google';
  static const String fluxKontext = 'fluxKontext';
  static const String fluxKrea = 'fluxKrea';
  static const String openAI = 'openai';
  static const String stabilityAI = 'stabilityAI';

  /// 根据供应商和模型创建图像生成服务
  static dynamic createImageService({
    required String provider,
    required String apiKey,
    required String model,
  }) {
    if (apiKey.isEmpty) {
      throw Exception('API Key is not set.');
    }

    switch (provider) {
      case google:
        return GoogleImageService(apiKey: apiKey);

      case fluxKontext:
        return FluxKontextService(apiKey: apiKey);

      case fluxKrea:
        return FluxKreaService(apiKey: apiKey);

      default:
        throw Exception('Unsupported image generation provider: $provider');
    }
  }

  /// 根据提供商URL检测和创建服务
  static dynamic createFromProviderUrl({
    required String providerBaseUrl,
    required String apiKey,
    required String model,
  }) {
    if (apiKey.isEmpty) {
      throw Exception('API Key is not set.');
    }

    if (kDebugMode) {
      print('[ImageGenerationServiceFactory] Provider URL: $providerBaseUrl');
      print('[ImageGenerationServiceFactory] Model: $model');
    }

    if (providerBaseUrl.contains('generativelanguage.googleapis.com') ||
        providerBaseUrl.contains('google')) {
      return GoogleImageService(apiKey: apiKey);
    } else if (providerBaseUrl.contains('api.bfl.ai')) {
      if (model.contains('krea')) {
        return FluxKreaService(apiKey: apiKey);
      } else {
        return FluxKontextService(apiKey: apiKey);
      }
    } else if (providerBaseUrl.contains('api.openai.com')) {
      // OpenAI image generation is handled in ImageGenerationService
      throw Exception('Use ImageGenerationService directly for OpenAI');
    } else if (providerBaseUrl.contains('stability.ai')) {
      // Stability AI is handled in ImageGenerationService
      throw Exception('Use ImageGenerationService directly for Stability AI');
    } else {
      throw Exception(
        'Unsupported image generation provider or base URL. Supported: api.openai.com, stability.ai, api.bfl.ai, generativelanguage.googleapis.com',
      );
    }
  }

  /// 判断是否为外部服务（需要通过专门服务处理）
  static bool requiresExternalService(String providerBaseUrl) {
    return providerBaseUrl.contains('api.openai.com') ||
        providerBaseUrl.contains('stability.ai');
  }

  /// 获取支持的图像提供商列表
  static List<String> get supportedProviders => [
    google,
    fluxKontext,
    fluxKrea,
    openAI,
    stabilityAI,
  ];

  /// 检查提供商是否受支持
  static bool isSupported(String provider) =>
      supportedProviders.contains(provider);

  /// 检查提供商URL是否受支持
  static bool isSupportedUrl(String providerBaseUrl) {
    return providerBaseUrl.contains('api.openai.com') ||
        providerBaseUrl.contains('stability.ai') ||
        providerBaseUrl.contains('generativelanguage.googleapis.com') ||
        providerBaseUrl.contains('google') ||
        providerBaseUrl.contains('api.bfl.ai');
  }
}
