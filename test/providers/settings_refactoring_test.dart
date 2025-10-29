import 'package:flutter_test/flutter_test.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/chat_model_provider.dart';
import 'package:chibot/providers/image_model_provider.dart';
import 'package:chibot/providers/video_model_provider.dart';
import 'package:chibot/providers/search_provider.dart';
import 'package:chibot/providers/unified_settings_provider.dart';

void main() {
  group('ApiKeyProvider', () {
    late ApiKeyProvider apiKeys;

    setUp(() {
      apiKeys = ApiKeyProvider();
    });

    test('初始化时 API 密钥为空', () {
      expect(apiKeys.openaiApiKey, isNull);
      expect(apiKeys.claudeApiKey, isNull);
      expect(apiKeys.googleApiKey, isNull);
    });

    test('可以设置 OpenAI API 密钥', () async {
      await apiKeys.setOpenaiApiKey('test-key');
      expect(apiKeys.openaiApiKey, equals('test-key'));
      expect(apiKeys.apiKey, equals('test-key')); // 向后兼容
    });

    test('getApiKeyForProvider 返回正确的密钥', () {
      // 这个测试需要实际的持久化，暂时跳过
    });
  });

  group('ChatModelProvider', () {
    late ChatModelProvider chatModel;

    setUp(() {
      chatModel = ChatModelProvider();
    });

    test('初始化时使用默认模型', () {
      expect(chatModel.selectedModel, equals('gpt-4o'));
      expect(chatModel.selectedProvider, equals('OpenAI'));
    });

    test('availableModels 包含 OpenAI 模型', () {
      expect(
        chatModel.availableModels,
        containsAll(['gpt-4', 'gpt-4o', 'gpt-4.1']),
      );
    });

    test('自定义模型可以被添加和移除', () async {
      await chatModel.addCustomModel('custom-model');
      expect(chatModel.customModels, contains('custom-model'));

      await chatModel.removeCustomModel('custom-model');
      expect(chatModel.customModels, isNot(contains('custom-model')));
    });

    test('更改提供商时验证模型', () async {
      await chatModel.setSelectedProvider('Google');
      expect(
        chatModel.availableModels,
        containsAll([
          'gemini-2.0-flash',
          'gemini-2.5-pro-preview-06-05',
          'gemini-2.5-flash-preview-05-20'
        ]),
      );
    });
  });

  group('ImageModelProvider', () {
    late ImageModelProvider imageModel;

    setUp(() {
      imageModel = ImageModelProvider();
    });

    test('初始化时使用 OpenAI DALL-E-3', () {
      expect(imageModel.selectedImageProvider, equals('OpenAI'));
      expect(imageModel.selectedImageModel, equals('dall-e-3'));
    });

    test('availableImageModels 包含 OpenAI 模型', () {
      expect(imageModel.availableImageModels, contains('dall-e-3'));
    });

    test('可以设置 BFL Aspect Ratio', () async {
      await imageModel.setBflAspectRatio('21:9');
      expect(imageModel.bflAspectRatio, equals('21:9'));
    });

    test('更改提供商时验证图像模型', () async {
      await imageModel.setSelectedImageProvider('Black Forest Labs');
      expect(
        imageModel.availableImageModels,
        containsAll(['flux-kontext-pro', 'flux-kontext-dev', 'flux-krea-dev']),
      );
    });
  });

  group('VideoModelProvider', () {
    late VideoModelProvider videoModel;

    setUp(() {
      videoModel = VideoModelProvider();
    });

    test('初始化时使用默认视频设置', () {
      expect(videoModel.selectedVideoProvider, equals('Google Veo3'));
      expect(videoModel.videoResolution, equals('720p'));
      expect(videoModel.videoDuration, equals('10s'));
      expect(videoModel.videoQuality, equals('standard'));
      expect(videoModel.videoAspectRatio, equals('16:9'));
    });

    test('验证支持的分辨率', () {
      expect(
        VideoModelProvider.supportedResolutions,
        containsAll(['480p', '720p', '1080p']),
      );
    });

    test('只能设置支持的分辨率', () async {
      await videoModel.setVideoResolution('480p');
      expect(videoModel.videoResolution, equals('480p'));

      // 这不会改变值，因为不被支持
      await videoModel.setVideoResolution('4K');
      expect(videoModel.videoResolution, equals('480p'));
    });

    test('只能设置支持的时长', () async {
      await videoModel.setVideoDuration('5s');
      expect(videoModel.videoDuration, equals('5s'));
    });

    test('只能设置支持的质量', () async {
      await videoModel.setVideoQuality('high');
      expect(videoModel.videoQuality, equals('high'));
    });

    test('只能设置支持的宽高比', () async {
      await videoModel.setVideoAspectRatio('9:16');
      expect(videoModel.videoAspectRatio, equals('9:16'));
    });
  });

  group('SearchProvider', () {
    late SearchProvider search;

    setUp(() {
      search = SearchProvider();
    });

    test('初始化时搜索功能被禁用', () {
      expect(search.googleSearchEnabled, isFalse);
      expect(search.tavilySearchEnabled, isFalse);
    });

    test('可以启用 Google Search', () async {
      await search.setGoogleSearchApiKey('test-api-key');
      await search.setGoogleSearchEngineId('test-engine-id');
      await search.setGoogleSearchEnabled(true);

      expect(search.isGoogleSearchConfigured(), isTrue);
    });

    test('可以启用 Tavily Search', () async {
      await search.setTavilyApiKey('test-api-key');
      await search.setTavilySearchEnabled(true);

      expect(search.isTavilySearchConfigured(), isTrue);
    });

    test('hasSearchEngineConfigured 检查是否有活跃的搜索引擎', () async {
      expect(search.hasSearchEngineConfigured, isFalse);

      await search.setTavilyApiKey('test-key');
      await search.setTavilySearchEnabled(true);
      expect(search.hasSearchEngineConfigured, isTrue);
    });

    test('googleSearchResultCount 验证', () async {
      await search.setGoogleSearchResultCount(50);
      expect(search.googleSearchResultCount, equals(50));

      // 无效值不会改变
      await search.setGoogleSearchResultCount(150);
      expect(search.googleSearchResultCount, equals(50));
    });
  });

  group('UnifiedSettingsProvider', () {
    late ApiKeyProvider apiKeys;
    late ChatModelProvider chatModel;
    late ImageModelProvider imageModel;
    late VideoModelProvider videoModel;
    late SearchProvider search;
    late UnifiedSettingsProvider settings;

    setUp(() {
      apiKeys = ApiKeyProvider();
      chatModel = ChatModelProvider();
      imageModel = ImageModelProvider();
      videoModel = VideoModelProvider();
      search = SearchProvider();
      settings = UnifiedSettingsProvider(
        apiKeyProvider: apiKeys,
        chatModelProvider: chatModel,
        imageModelProvider: imageModel,
        videoModelProvider: videoModel,
        searchProvider: search,
      );
    });

    test('提供向后兼容的 API', () async {
      // 测试聊天模型 API
      await settings.setSelectedProvider('Google');
      expect(settings.selectedProvider, equals('Google'));

      // 测试 API 密钥 API
      await settings.setApiKey('test-key');
      expect(settings.apiKey, equals('test-key'));

      // 测试图像生成 API
      expect(settings.selectedImageProvider, equals('OpenAI'));

      // 测试视频 API
      expect(settings.videoResolution, equals('720p'));

      // 测试搜索 API
      expect(settings.googleSearchEnabled, isFalse);
    });

    test('导入导出工作正常', () async {
      // 设置一些值
      await settings.setSelectedProvider('Google');
      await settings.setApiKey('test-key');
      await settings.setSelectedImageModel('dall-e-3');

      // 导出
      final exported = await settings.exportSettings();

      // 验证导出的数据包含预期的值
      expect(exported, containsKey('apiKeys'));
      expect(exported, containsKey('chatModel'));
      expect(exported, containsKey('imageModel'));
      expect(exported, containsKey('videoModel'));
      expect(exported, containsKey('search'));
    });
  });
}
