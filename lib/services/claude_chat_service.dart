import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../constants/app_constants.dart';
import '../models/chat_message.dart';
import '../repositories/interfaces.dart';
import 'base_api_service.dart';

class ClaudeService extends BaseApiService implements ChatService {
  ClaudeService({
    required super.apiKey,
    String? baseUrl,
    super.timeout,
    super.maxRetries,
    super.client,
  }) : super(baseUrl: baseUrl ?? AppConstants.claudeBaseUrl);

  @override
  String get providerName => 'Anthropic Claude';

  @override
  List<String> get supportedModels => [
    'claude-3-5-sonnet-20241022',
    'claude-3-5-haiku-20241022', 
    'claude-3-opus-20240229',
    'claude-3-sonnet-20240229',
    'claude-3-haiku-20240307',
  ];

  @override
  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    };
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
      // Test with a simple message to validate the API key
      final testMessage = [
        {'role': 'user', 'content': 'Hello'}
      ];
      
      final requestBody = _buildMessagesRequest(
        'claude-3-5-haiku-20241022', 
        testMessage, 
        {'max_tokens': 10}
      );
      
      final response = await post('/messages', body: requestBody);
      if (response.statusCode != 200) {
        throw ConfigurationException(
          'Invalid API key or configuration for Claude',
          code: 'INVALID_CONFIG',
        );
      }
    } catch (e) {
      if (e is ConfigurationException) rethrow;
      throw ConfigurationException(
        'Failed to validate Claude configuration: ${e.toString()}',
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
      logWarning('Claude configuration is invalid', error: e);
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
        'Model $model is not supported by Claude',
        'model',
        code: 'UNSUPPORTED_MODEL',
      );
    }

    try {
      final messages = _buildMessages(context, prompt);
      final requestBody = _buildMessagesRequest(model, messages, parameters);
      
      logInfo('Generating response with Claude model: $model');
      
      final response = await postStream('/messages', body: requestBody);
      
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data.trim() == '[DONE]') {
              return;
            }
            
            try {
              final json = jsonDecode(data);
              final type = json['type'] as String?;
              
              if (type == 'content_block_delta') {
                final delta = json['delta'] as Map<String, dynamic>?;
                final text = delta?['text'] as String?;
                
                if (text != null) {
                  yield text;
                }
              } else if (type == 'message_stop') {
                return;
              }
            } catch (e) {
              logWarning('Failed to parse Claude streaming chunk', error: e);
              // Continue processing other chunks
            }
          }
        }
      }
      
    } catch (e) {
      logError('Failed to generate response with Claude', error: e);
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
      final prompt = 'Generate a short, descriptive title (max 5 words) for this conversation: "${firstMessage.text}"';
      
      final requestMessages = [
        {'role': 'user', 'content': prompt}
      ];
      
      final requestBody = _buildMessagesRequest(
        'claude-3-5-haiku-20241022',
        requestMessages,
        {'max_tokens': 20},
      );
      
      final response = await post('/messages', body: requestBody);
      final json = jsonDecode(response.body);
      
      final content = json['content'] as List?;
      if (content != null && content.isNotEmpty) {
        final text = content[0]['text'] as String?;
        if (text != null) {
          return text.trim().replaceAll(RegExp(r'^"|"$'), '');
        }
      }
      
      return 'New Chat';
      
    } catch (e) {
      logWarning('Failed to generate title with Claude', error: e);
      return 'New Chat';
    }
  }

  // Helper methods
  List<Map<String, String>> _buildMessages(List<ChatMessage> context, String prompt) {
    final messages = <Map<String, String>>[];
    
    // Add context messages
    for (final message in context) {
      final apiMessage = message.toApiJson();
      if (apiMessage != null) {
        // Convert OpenAI format to Claude format
        final role = apiMessage['role'] == 'assistant' ? 'assistant' : 'user';
        messages.add({
          'role': role,
          'content': apiMessage['content']!,
        });
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

  String _buildMessagesRequest(String model, List<Map<String, String>> messages, Map<String, dynamic>? parameters) {
    final request = {
      'model': model,
      'messages': messages,
      'max_tokens': 4096,
      'stream': true,
      'temperature': 0.7,
      ...?parameters,
    };
    
    return jsonEncode(request);
  }

  void _handleErrorResponse(int statusCode, String responseBody) {
    String errorMessage = 'Claude API request failed with status $statusCode';
    String? errorCode;
    Map<String, dynamic>? responseData;
    
    try {
      responseData = jsonDecode(responseBody) as Map<String, dynamic>;
      
      if (responseData['error'] != null) {
        final error = responseData['error'] as Map<String, dynamic>;
        errorMessage = error['message'] ?? errorMessage;
        errorCode = error['type']?.toString();
      }
      
    } catch (e) {
      logWarning('Failed to parse Claude error response', error: e);
    }
    
    throw ApiException(
      errorMessage,
      statusCode,
      code: errorCode ?? 'CLAUDE_HTTP_$statusCode',
      responseData: responseData,
    );
  }
}