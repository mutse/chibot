import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class OpenAIService {
  Future<String> getChatResponse({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    required String providerBaseUrl, // 新增：基础 URL
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is not set.');
    }

    // 拼接完整的 API 端点
    // 确保 providerBaseUrl 后面没有斜杠，并且正确拼接 /chat/completions
    final String endpoint = providerBaseUrl.endsWith('/')
        ? '${providerBaseUrl}chat/completions'
        : '$providerBaseUrl/chat/completions';

    final uri = Uri.parse(endpoint);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    List<Map<String, String>> apiMessages =
        messages.map((msg) => msg.toApiJson()).toList();

    final body = jsonEncode({
      'model': model,
      'messages': apiMessages,
      'temperature': 0.7,
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'].toString().trim();
        } else if (data['error'] != null) { // 某些API（如Ollama）错误格式不同
          throw Exception('API Error: ${data['error']['message']} (Type: ${data['error']['type']})');
        }
        else {
          throw Exception('No response choices found and no error field. Response: ${response.body}');
        }
      } else {
        print('API Error: ${response.statusCode}');
        print('API Response: ${response.body}');
        // 尝试解析错误信息
        String errorMessage = 'Failed to get response from OpenAI: ${response.statusCode} ${response.reasonPhrase}';
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData['error'] != null && errorData['error']['message'] != null) {
            errorMessage += '\nDetails: ${errorData['error']['message']}';
          } else if (errorData['detail'] != null) { // 兼容某些其他API的错误格式
             errorMessage += '\nDetails: ${errorData['detail']}';
          } else {
             errorMessage += '\nResponse: ${response.body}';
          }
        } catch (_) {
          errorMessage += '\nResponse: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in OpenAIService: $e');
      rethrow;
    }
  }
}
