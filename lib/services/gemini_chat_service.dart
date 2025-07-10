import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../constants/app_constants.dart';
import '../models/chat_message.dart';
import '../repositories/interfaces.dart';
import 'base_api_service.dart';

class GeminiService extends BaseApiService implements ChatService {
  GeminiService({
    required super.apiKey,
    String? baseUrl,
    super.timeout,
    super.maxRetries,
    super.client,
  }) : super(baseUrl: baseUrl ?? AppConstants.geminiBaseUrl);

  @override
  String get providerName => 'Google Gemini';

  @override
  List<String> get supportedModels => [
    'gemini-2.0-flash',
    'gemini-2.5-pro-preview-06-05',
    'gemini-2.5-flash-preview-05-20',
    'gemini-1.5-pro',
    'gemini-1.5-flash',
  ];

  @override
  Map<String, String> getHeaders() {
    return {'Content-Type': 'application/json'};
  }

  @override
  void validateResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleErrorResponse(response.statusCode, response.body);
    }
  }

  @override
  Future<void> validateConfiguration() async {
    validateApiKey();

    try {
      final response = await get('/models', queryParams: {'key': apiKey});
      if (response.statusCode != 200) {
        throw ConfigurationException(
          'Invalid API key or configuration for Gemini',
          code: 'INVALID_CONFIG',
        );
      }
    } catch (e) {
      if (e is ConfigurationException) rethrow;
      throw ConfigurationException(
        'Failed to validate Gemini configuration: ${e.toString()}',
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
      logWarning('Gemini configuration is invalid', error: e);
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

    if (!supportedModels.contains(model)) {
      throw ValidationException(
        'Model $model is not supported by Gemini',
        'model',
        code: 'UNSUPPORTED_MODEL',
      );
    }

    try {
      final contents = _buildContents(context, prompt);
      final requestBody = _buildGenerateRequest(contents, parameters);

      logInfo('Generating response with Gemini model: $model');

      final cleanModel = model.startsWith('gemini-') ? model : 'gemini-$model';
      final response = await post(
        '/models/$cleanModel:generateContent',
        queryParams: {'key': apiKey},
        body: requestBody,
      );

      final json = jsonDecode(response.body);

      if (json['candidates'] != null && json['candidates'].isNotEmpty) {
        final candidate = json['candidates'][0];
        final content = candidate['content'];

        if (content != null &&
            content['parts'] != null &&
            content['parts'].isNotEmpty) {
          final text = content['parts'][0]['text'] as String?;
          if (text != null) {
            // Gemini doesn't support streaming, so we yield the complete response
            yield text;
          }
        }
      }
    } catch (e) {
      logError('Failed to generate response with Gemini', error: e);
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

      final contents = [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ];

      final requestBody = _buildGenerateRequest(contents, {
        'maxOutputTokens': 20,
      });

      final response = await post(
        '/models/gemini-1.5-flash:generateContent',
        queryParams: {'key': apiKey},
        body: requestBody,
      );

      final json = jsonDecode(response.body);

      if (json['candidates'] != null && json['candidates'].isNotEmpty) {
        final candidate = json['candidates'][0];
        final content = candidate['content'];

        if (content != null &&
            content['parts'] != null &&
            content['parts'].isNotEmpty) {
          final text = content['parts'][0]['text'] as String?;
          if (text != null) {
            return text.trim().replaceAll(RegExp(r'^"|"$'), '');
          }
        }
      }

      return 'New Chat';
    } catch (e) {
      logWarning('Failed to generate title with Gemini', error: e);
      return 'New Chat';
    }
  }

  // Helper methods
  List<Map<String, dynamic>> _buildContents(
    List<ChatMessage> context,
    String prompt,
  ) {
    final contents = <Map<String, dynamic>>[];

    // Add context messages
    for (final message in context) {
      contents.add({
        'role': message.sender == MessageSender.user ? 'user' : 'model',
        'parts': [
          {'text': message.text},
        ],
      });
    }

    // Add current prompt
    contents.add({
      'role': 'user',
      'parts': [
        {'text': prompt},
      ],
    });

    // Limit context length
    if (contents.length > AppConstants.maxMessagesInContext) {
      final startIndex = contents.length - AppConstants.maxMessagesInContext;
      return contents.sublist(startIndex);
    }

    return contents;
  }

  String _buildGenerateRequest(
    List<Map<String, dynamic>> contents,
    Map<String, dynamic>? parameters,
  ) {
    final request = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 4096,
        ...?parameters,
      },
    };

    return jsonEncode(request);
  }

  void _handleErrorResponse(int statusCode, String responseBody) {
    String errorMessage = 'Gemini API request failed with status $statusCode';
    String? errorCode;
    Map<String, dynamic>? responseData;

    try {
      responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      if (responseData['error'] != null) {
        final error = responseData['error'] as Map<String, dynamic>;
        errorMessage = error['message'] ?? errorMessage;
        errorCode = error['code']?.toString();
      }
    } catch (e) {
      logWarning('Failed to parse Gemini error response', error: e);
    }

    throw ApiException(
      errorMessage,
      statusCode,
      code: errorCode ?? 'GEMINI_HTTP_$statusCode',
      responseData: responseData,
    );
  }
}
