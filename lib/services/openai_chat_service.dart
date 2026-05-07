import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../constants/app_constants.dart';
import '../models/chat_message.dart';
import '../repositories/interfaces.dart';
import 'base_api_service.dart';

class OpenAIService extends BaseApiService implements ChatService {
  OpenAIService({
    required super.apiKey,
    String? baseUrl,
    super.timeout,
    super.maxRetries,
    super.client,
  }) : super(baseUrl: baseUrl ?? AppConstants.openAIBaseUrl);

  bool get _isOpenRouter => baseUrl.contains('openrouter.ai');

  @override
  String get providerName => _isOpenRouter ? 'OpenRouter' : 'OpenAI';

  @override
  List<String> get supportedModels => [
    'gpt-5.5',
    'gpt-5.4',
    'gpt-5.4-mini',
    'gpt-5.4-nano',
    'gpt-5.1',
    'gpt-5-mini',
    'gpt-5-nano',
    'gpt-4.1',
    'gpt-4.1-mini',
    'gpt-4.1-nano',
    'gpt-4o',
    'gpt-4o-mini',
    'o3',
    'o4-mini',
  ];

  @override
  Map<String, String> getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    if (_isOpenRouter) {
      headers['X-Title'] = 'Chibot';
    }

    return headers;
  }

  @override
  void validateResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      handleErrorResponse(response.statusCode, response.body);
    }
  }

  @override
  Future<void> validateConfiguration() async {
    validateApiKey();

    try {
      final response = await get('/models');
      if (response.statusCode != 200) {
        throw ConfigurationException(
          'Invalid API key or configuration for OpenAI',
          code: 'INVALID_CONFIG',
        );
      }
    } catch (e) {
      if (e is ConfigurationException) rethrow;
      throw ConfigurationException(
        'Failed to validate OpenAI configuration: ${e.toString()}',
        code: 'CONFIG_VALIDATION_FAILED',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> isConfigured() async {
    try {
      await validateConfiguration();
      return true;
    } catch (e) {
      logWarning('OpenAI configuration is invalid', error: e);
      return false;
    }
  }

  @override
  Stream<String> generateResponse({
    required String prompt,
    required List<ChatMessage> context,
    required String model,
    Map<String, dynamic>? parameters,
  }) async* {
    validateApiKey();

    // Only validate supported models for official OpenAI API
    // Allow any model for custom base URLs (OpenAI-compatible providers)
    if (baseUrl == AppConstants.openAIBaseUrl && !supportedModels.contains(model)) {
      throw ValidationException(
        'Model $model is not supported by OpenAI',
        'model',
        code: 'UNSUPPORTED_MODEL',
      );
    }

    try {
      final messages = _buildMessages(context, prompt);
      final requestBody = _buildChatRequest(model, messages, parameters);

      logInfo('Generating response with model: $model');

      final response = await postStream('/chat/completions', body: requestBody);

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data.trim() == '[DONE]') {
              return;
            }

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;

              if (json['error'] != null) {
                final error = json['error'] as Map<String, dynamic>;
                final message =
                    _isOpenRouter
                        ? _buildOpenRouterErrorMessage(
                          statusCode: 0,
                          fallbackMessage:
                              error['message']?.toString() ??
                              'Streaming provider error',
                          errorData: error,
                        )
                        : (error['message']?.toString() ??
                            'Streaming provider error');

                throw ApiException(
                  message,
                  0,
                  code: error['code']?.toString() ?? 'STREAM_PROVIDER_ERROR',
                  responseData: json,
                );
              }

              final choices = json['choices'] as List?;

              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                final content = delta?['content'] as String?;

                if (content != null) {
                  yield content;
                }
              }
            } catch (e) {
              logWarning('Failed to parse streaming chunk', error: e);
              // Continue processing other chunks
            }
          }
        }
      }
    } catch (e) {
      logError('Failed to generate response', error: e);
      if (e is AppException) {
        rethrow;
      }
      throw ApiException(
        'Failed to generate response: ${e.toString()}',
        0,
        code: 'RESPONSE_GENERATION_FAILED',
        originalError: e,
      );
    }
  }

  @override
  Future<String> generateTitle(List<ChatMessage> messages) async {
    validateApiKey();

    if (messages.isEmpty) {
      return 'New Chat';
    }

    try {
      final firstMessage = messages.first;
      final prompt =
          'Generate a short, descriptive title (max 5 words) for this conversation: "${firstMessage.text}"';

      final requestBody = _buildChatRequest(
        'gpt-4.1-mini',
        [
          {'role': 'user', 'content': prompt},
        ],
        {'max_tokens': 20, 'temperature': 0.7},
      );

      final response = await post('/chat/completions', body: requestBody);
      final json = jsonDecode(response.body);

      final choices = json['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;

        if (content != null) {
          return content.trim().replaceAll(RegExp(r'^"|"$'), '');
        }
      }

      return 'New Chat';
    } catch (e) {
      logWarning('Failed to generate title', error: e);
      return 'New Chat';
    }
  }

  // Helper methods
  List<Map<String, String>> _buildMessages(
    List<ChatMessage> context,
    String prompt,
  ) {
    final messages = <Map<String, String>>[];

    // Add context messages
    for (final message in context) {
      final apiMessage = message.toApiJson();
      if (apiMessage != null) {
        messages.add(apiMessage);
      }
    }

    // Add current prompt
    messages.add({'role': 'user', 'content': prompt});

    // Limit context length
    if (messages.length > AppConstants.maxMessagesInContext) {
      final startIndex = messages.length - AppConstants.maxMessagesInContext;
      return messages.sublist(startIndex);
    }

    return messages;
  }

  String _buildChatRequest(
    String model,
    List<Map<String, String>> messages,
    Map<String, dynamic>? parameters,
  ) {
    final request = {
      'model': model,
      'messages': messages,
      'stream': true,
      'temperature': 0.7,
      'max_tokens': 4096,
      ...?parameters,
    };

    return jsonEncode(request);
  }

  @override
  void handleErrorResponse(int statusCode, String responseBody) {
    String errorMessage =
        '${_isOpenRouter ? 'OpenRouter' : 'OpenAI'} API request failed with status $statusCode';
    String? errorCode;
    Map<String, dynamic>? responseData;

    try {
      responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      if (responseData['error'] != null) {
        final error = responseData['error'] as Map<String, dynamic>;
        errorMessage = error['message'] ?? errorMessage;
        errorCode = error['code']?.toString();

        if (_isOpenRouter) {
          errorMessage = _buildOpenRouterErrorMessage(
            statusCode: statusCode,
            fallbackMessage: errorMessage,
            errorData: error,
          );
        }
      }
    } catch (e) {
      logWarning('Failed to parse OpenAI error response', error: e);
    }

    throw ApiException(
      errorMessage,
      statusCode,
      code: errorCode ?? 'OPENAI_HTTP_$statusCode',
      responseData: responseData,
    );
  }

  String _buildOpenRouterErrorMessage({
    required int statusCode,
    required String fallbackMessage,
    required Map<String, dynamic> errorData,
  }) {
    final metadata = errorData['metadata'];
    String? providerName;
    String? providerDetail;

    if (metadata is Map<String, dynamic>) {
      providerName = metadata['provider_name']?.toString();
      providerDetail = _extractOpenRouterProviderDetail(metadata['raw']);
    }

    final detail = <String>[
      if (providerName != null && providerName.isNotEmpty) 'provider: $providerName',
      if (providerDetail != null && providerDetail.isNotEmpty) providerDetail,
    ].join(' - ');

    if (statusCode == 429) {
      final prefix = 'OpenRouter rate limit exceeded';
      return detail.isEmpty ? '$prefix. Please retry shortly or switch to another model/provider.' : '$prefix ($detail).';
    }

    if (fallbackMessage == 'Provider returned error' && detail.isNotEmpty) {
      return 'OpenRouter provider error ($detail).';
    }

    return detail.isEmpty ? fallbackMessage : '$fallbackMessage ($detail)';
  }

  String? _extractOpenRouterProviderDetail(dynamic raw) {
    if (raw == null) return null;

    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (raw is Map<String, dynamic>) {
      final message = raw['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }

      final error = raw['error'];
      if (error is Map<String, dynamic>) {
        final nestedMessage = error['message']?.toString();
        if (nestedMessage != null && nestedMessage.trim().isNotEmpty) {
          return nestedMessage.trim();
        }
      }
    }

    return null;
  }
}
