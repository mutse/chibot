import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/chat_model_provider.dart';
import 'package:chibot/providers/image_model_provider.dart';
import 'package:chibot/providers/video_model_provider.dart';
import 'package:chibot/providers/search_provider.dart';
import 'package:chibot/models/search_result.dart' as search_models;
import 'package:chibot/services/chat_service_factory.dart';
import 'package:chibot/services/service_manager.dart';
import 'package:chibot/services/image_generation_service_manager.dart';
import 'package:chibot/services/video_generation_service_manager.dart';
import 'package:chibot/services/service_config_validator.dart';
import 'package:chibot/services/search_service_factory.dart';
import 'package:chibot/services/web_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> resetMockPreferences() async {
    SharedPreferences.setMockInitialValues({});
    await Future<void>.delayed(Duration.zero);
  }

  group('ChatServiceFactory with New Providers', () {
    late ApiKeyProvider apiKeys;
    late ChatModelProvider chatModel;

    setUp(() async {
      await resetMockPreferences();
      apiKeys = ApiKeyProvider();
      chatModel = ChatModelProvider();
      await Future<void>.delayed(Duration.zero);
    });

    test('createFromProviders 应该抛出异常如果 API Key 未配置', () async {
      // API Key 默认为 null，不配置
      expect(
        () => ChatServiceFactory.createFromProviders(
          chatModel: chatModel,
          apiKeys: apiKeys,
        ),
        throwsException,
      );
    });

    test('createFromProviders 可以使用 OpenAI 提供者创建服务', () async {
      // 设置 API Key
      await apiKeys.setOpenaiApiKey('test-api-key');

      // createFromProviders 应该成功
      final service = ChatServiceFactory.createFromProviders(
        chatModel: chatModel,
        apiKeys: apiKeys,
      );

      expect(service, isNotNull);
      expect(service.providerName, equals('OpenAI'));
    });

    test('createFromProviders 支持多个提供商', () async {
      // OpenAI
      await apiKeys.setOpenaiApiKey('openai-key');
      var service = ChatServiceFactory.createFromProviders(
        chatModel: chatModel,
        apiKeys: apiKeys,
      );
      expect(service.providerName, equals('OpenAI'));

      // 切换到 Google
      await chatModel.setSelectedProvider('Google');
      await apiKeys.setGoogleApiKey('google-key');
      service = ChatServiceFactory.createFromProviders(
        chatModel: chatModel,
        apiKeys: apiKeys,
      );
      expect(service.providerName, equals('Google Gemini'));

      // 切换到 Anthropic
      await chatModel.setSelectedProvider('Anthropic');
      await apiKeys.setClaudeApiKey('claude-key');
      service = ChatServiceFactory.createFromProviders(
        chatModel: chatModel,
        apiKeys: apiKeys,
      );
      expect(service.providerName, equals('Anthropic Claude'));
    });
  });

  group('ServiceManager with New Providers', () {
    late ApiKeyProvider apiKeys;
    late ChatModelProvider chatModel;

    setUp(() async {
      await resetMockPreferences();
      apiKeys = ApiKeyProvider();
      chatModel = ChatModelProvider();
      await Future<void>.delayed(Duration.zero);
    });

    test('isProviderConfigured 检查 API Key 配置', () async {
      // 未配置
      expect(
        ServiceManager.isProviderConfigured(
          apiKeys: apiKeys,
          provider: 'OpenAI',
        ),
        isFalse,
      );

      // 配置后
      await apiKeys.setOpenaiApiKey('test-key');
      expect(
        ServiceManager.isProviderConfigured(
          apiKeys: apiKeys,
          provider: 'OpenAI',
        ),
        isTrue,
      );
    });

    test('isProviderConfigured 将空白 API Key 视为未配置', () async {
      await apiKeys.setOpenaiApiKey('   ');

      expect(
        ServiceManager.isProviderConfigured(
          apiKeys: apiKeys,
          provider: 'OpenAI',
        ),
        isFalse,
      );
    });

    test('getAvailableProviders 返回已配置的提供商', () async {
      // 没有提供商被配置
      var available = ServiceManager.getAvailableProviders(apiKeys: apiKeys);
      expect(available.isEmpty, isTrue);

      // 配置 OpenAI
      await apiKeys.setOpenaiApiKey('openai-key');
      available = ServiceManager.getAvailableProviders(apiKeys: apiKeys);
      expect(available, contains('OpenAI'));

      // 配置 Google
      await apiKeys.setGoogleApiKey('google-key');
      available = ServiceManager.getAvailableProviders(apiKeys: apiKeys);
      expect(available, containsAll(['OpenAI', 'Google']));
    });

    test('isChatConfigured 验证完整配置', () async {
      // 未配置
      expect(
        ServiceManager.isChatConfigured(chatModel: chatModel, apiKeys: apiKeys),
        isFalse,
      );

      // 仅设置 API Key
      await apiKeys.setOpenaiApiKey('test-key');
      expect(
        ServiceManager.isChatConfigured(chatModel: chatModel, apiKeys: apiKeys),
        isTrue, // 因为 chatModel 有默认模型
      );

      // 清空模型
      await chatModel.setSelectedModel('');
      expect(
        ServiceManager.isChatConfigured(chatModel: chatModel, apiKeys: apiKeys),
        isFalse,
      );
    });

    test('createAndValidateChatService 返回有效的服务', () async {
      await apiKeys.setOpenaiApiKey('test-key');

      final service = ServiceManager.createAndValidateChatService(
        chatModel: chatModel,
        apiKeys: apiKeys,
      );

      expect(service, isNotNull);
      expect(service.providerName, equals('OpenAI'));
    });

    test('createAndValidateChatService 抛出异常如果未配置', () async {
      expect(
        () => ServiceManager.createAndValidateChatService(
          chatModel: chatModel,
          apiKeys: apiKeys,
        ),
        throwsException,
      );
    });

    test('getAvailableModels 返回可用模型列表', () async {
      final models = ServiceManager.getAvailableModels(chatModel: chatModel);
      expect(models.isNotEmpty, isTrue);
      expect(models, contains('gpt-4o'));
    });
  });

  group('ImageGenerationServiceManager with New Providers', () {
    late ApiKeyProvider apiKeys;
    late ImageModelProvider imageModel;

    setUp(() async {
      await resetMockPreferences();
      apiKeys = ApiKeyProvider();
      imageModel = ImageModelProvider();
      await Future<void>.delayed(Duration.zero);
    });

    test('isImageGenerationConfigured 检查完整配置', () async {
      // 未配置
      expect(
        ImageGenerationServiceManager.isImageGenerationConfigured(
          imageModel: imageModel,
          apiKeys: apiKeys,
        ),
        isFalse,
      );

      // 仅设置 API Key
      await apiKeys.setOpenaiApiKey('openai-key');
      expect(
        ImageGenerationServiceManager.isImageGenerationConfigured(
          imageModel: imageModel,
          apiKeys: apiKeys,
        ),
        isTrue, // 因为 imageModel 有默认模型
      );
    });

    test('getAvailableImageModels 返回可用模型', () async {
      final models = ImageGenerationServiceManager.getAvailableImageModels(
        imageModel: imageModel,
      );
      expect(models.isNotEmpty, isTrue);
      expect(models, contains('dall-e-3'));
    });

    test('isImageProviderConfigured 检查特定提供商', () async {
      // 未配置
      expect(
        ImageGenerationServiceManager.isImageProviderConfigured(
          apiKeys: apiKeys,
          provider: 'OpenAI',
        ),
        isFalse,
      );

      // 配置后
      await apiKeys.setOpenaiApiKey('test-key');
      expect(
        ImageGenerationServiceManager.isImageProviderConfigured(
          apiKeys: apiKeys,
          provider: 'OpenAI',
        ),
        isTrue,
      );
    });
  });

  group('ServiceConfigValidator', () {
    test('hasText 忽略 null、空字符串和空白字符串', () {
      expect(ServiceConfigValidator.hasText(null), isFalse);
      expect(ServiceConfigValidator.hasText(''), isFalse);
      expect(ServiceConfigValidator.hasText('   '), isFalse);
      expect(ServiceConfigValidator.hasText(' value '), isTrue);
    });
  });

  group('SearchServiceFactory', () {
    late ApiKeyProvider apiKeys;
    late SearchProvider search;

    setUp(() async {
      await resetMockPreferences();
      apiKeys = ApiKeyProvider();
      search = SearchProvider(apiKeyProvider: apiKeys);
      await Future<void>.delayed(Duration.zero);
    });

    test('createSearchService 支持 Tavily', () async {
      await search.setTavilyApiKey('tavily-key');
      await search.setTavilySearchEnabled(true);

      final service = SearchServiceFactory.createSearchService(
        search: search,
        apiKeys: apiKeys,
      );

      expect(service, isNotNull);
      expect(service!.provider, equals(SearchBackend.tavily));
      expect(service.tavilyService, isA<WebSearchService>());
    });

    test('formatGoogleSearchResult 在空结果时返回兜底文案', () {
      final result = search_models.SearchResult(
        items: const [],
        query: search_models.SearchQuery(query: 'test'),
        timestamp: DateTime.now(),
        totalResults: 0,
      );

      expect(
        SearchServiceFactory.formatGoogleSearchResult(result),
        equals('未找到相关搜索结果。'),
      );
    });

    test('Tavily 响应优先使用 answer 摘要', () {
      final summary = WebSearchService.summarizeResponse('test', {
        'answer': 'direct answer',
        'results': [
          {
            'title': 'Ignored',
            'content': 'Ignored content',
            'url': 'https://a',
          },
        ],
      });

      expect(summary, equals('direct answer'));
    });

    test('Tavily 响应可以归一化为 SearchResult', () {
      final result = WebSearchService.parseSearchResult('test', {
        'results': [
          {
            'title': 'Example',
            'content': 'Example snippet',
            'url': 'https://example.com',
          },
        ],
      });

      expect(result.items, hasLength(1));
      expect(result.items.first.title, equals('Example'));
      expect(result.items.first.snippet, equals('Example snippet'));
      expect(result.items.first.link, equals('https://example.com'));
      expect(result.query.query, equals('test'));
    });
  });

  group('VideoGenerationServiceManager with New Providers', () {
    late ApiKeyProvider apiKeys;
    late VideoModelProvider videoModel;

    setUp(() async {
      await resetMockPreferences();
      apiKeys = ApiKeyProvider();
      videoModel = VideoModelProvider();
      await Future<void>.delayed(Duration.zero);
    });

    test('isVideoGenerationConfigured 检查完整配置', () async {
      // 未配置
      expect(
        VideoGenerationServiceManager.isVideoGenerationConfigured(
          videoModel: videoModel,
          apiKeys: apiKeys,
        ),
        isFalse,
      );

      // 配置后
      await apiKeys.setGoogleApiKey('google-key');
      expect(
        VideoGenerationServiceManager.isVideoGenerationConfigured(
          videoModel: videoModel,
          apiKeys: apiKeys,
        ),
        isTrue,
      );
    });

    test('validateVideoParams 验证视频参数', () async {
      // 默认参数应该有效
      expect(
        VideoGenerationServiceManager.validateVideoParams(
          videoModel: videoModel,
        ),
        isTrue,
      );

      // 设置无效的分辨率（通过直接设置，不通过 setter）
      // 由于没有无效的 setter，我们验证默认值是有效的
      expect(VideoModelProvider.supportedResolutions, contains('720p'));
    });

    test('getVideoConfigDescription 返回配置描述', () async {
      final description =
          VideoGenerationServiceManager.getVideoConfigDescription(
            videoModel: videoModel,
          );
      expect(description, isNotNull);
      expect(description.contains('720p'), isTrue);
      expect(description.contains('10s'), isTrue);
    });
  });
}
