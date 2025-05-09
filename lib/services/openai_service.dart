import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class OpenAIService {
  // Helper method to convert ChatMessage list to Gemini's 'contents' format
  List<Map<String, dynamic>> _chatMessagesToGeminiContents(List<ChatMessage> messages) {
    List<Map<String, dynamic>> geminiContents = [];
    for (var msg in messages) {
      geminiContents.add({
        "role": msg.sender == MessageSender.user ? "user" : "model",
        "parts": [{"text": msg.text}]
      });
    }
    // Gemini API requires that the history alternates between user and model.
    // If the last message was from the model, and we are sending a new user message,
    // it's fine. If the history ends with user, and we add another user message,
    // that's also fine for the API structure itself (though logically odd for a chat turn).
    // The current implementation directly maps messages.
    // For more robust conversation, role alternation might need stricter enforcement
    // or merging consecutive messages from the same role if the API requires.
    return geminiContents;
  }

  Future<String> getChatResponse({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    required String providerBaseUrl, // 新增：基础 URL
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is not set.');
    }

    String endpointUrl;
    Map<String, String> requestHeaders;
    String requestBody;

    // Check if the model is a Google Gemini model
    if (model.toLowerCase().startsWith('google/gemini') || model.toLowerCase().startsWith('gemini-')) {
      // providerBaseUrl for Gemini should be like 'https://generativelanguage.googleapis.com/v1beta'
      // The model name in settings might be 'google/gemini-x.x-pro' or 'gemini-x.x-pro'
      String geminiModelName = model.split('/').last; // Extracts 'gemini-x.x-pro'
      
      // Ensure providerBaseUrl does not end with a slash before appending model path
      String cleanProviderBaseUrl = providerBaseUrl.endsWith('/') 
          ? providerBaseUrl.substring(0, providerBaseUrl.length - 1)
          : providerBaseUrl;

      endpointUrl = '$cleanProviderBaseUrl/models/$geminiModelName:generateContent?key=$apiKey';
      
      requestHeaders = {
        'Content-Type': 'application/json',
      };

      final geminiContents = _chatMessagesToGeminiContents(messages);
      requestBody = jsonEncode({
        'contents': geminiContents,
        'generationConfig': {
          'temperature': 0.7,
        },
      });

    } else {
      // Existing OpenAI-compatible API logic
      // Ensure providerBaseUrl does not end with a slash before appending /chat/completions
      String cleanProviderBaseUrl = providerBaseUrl.endsWith('/') 
          ? providerBaseUrl.substring(0, providerBaseUrl.length - 1)
          : providerBaseUrl;
      endpointUrl = '$cleanProviderBaseUrl/chat/completions';

      requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

      List<Map<String, String>> apiMessages =
          messages.map((msg) => msg.toApiJson()).toList();
      requestBody = jsonEncode({
        'model': model,
        'messages': apiMessages,
        'temperature': 0.7,
      });
    }

    final uri = Uri.parse(endpointUrl);

    try {
      final response = await http.post(uri, headers: requestHeaders, body: requestBody);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (model.toLowerCase().startsWith('google/gemini') || model.toLowerCase().startsWith('gemini-')) {
          if (data['candidates'] != null &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0]['content'] != null &&
              data['candidates'][0]['content']['parts'] != null &&
              data['candidates'][0]['content']['parts'].isNotEmpty) {
            return data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
          } else if (data['error'] != null && data['error']['message'] != null) {
            throw Exception('Gemini API Error: ${data['error']['message']} (Code: ${data['error']['code']})');
          } else {
            throw Exception('No valid response candidates found in Gemini API response. Body: ${response.body}');
          }
        } else {
          // OpenAI-compatible response parsing
          if (data['choices'] != null && data['choices'].isNotEmpty) {
            return data['choices'][0]['message']['content'].toString().trim();
          } else if (data['error'] != null && data['error']['message'] != null) { 
            throw Exception('API Error: ${data['error']['message']} (Type: ${data['error']['type']})');
          } else {
            throw Exception('No response choices found and no error field. Response: ${response.body}');
          }
        }
      } else {
        print('API Error: ${response.statusCode} for model $model at $endpointUrl');
        print('API Response: ${response.body}');
        String errorMessage = 'Failed to get response from API: ${response.statusCode} ${response.reasonPhrase}';
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData['error'] != null && errorData['error']['message'] != null) {
            errorMessage += '\nDetails: ${errorData['error']['message']}';
            if (errorData['error']['code'] != null) errorMessage += ' (Code: ${errorData['error']['code']})';
            if (errorData['error']['status'] != null) errorMessage += ' (Status: ${errorData['error']['status']})';
          } else if (errorData['detail'] != null) { // Some other APIs (e.g. Ollama sometimes)
             errorMessage += '\nDetails: ${errorData['detail']}';
          } else {
             errorMessage += '\nRaw Response: ${response.body}';
          }
        } catch (e) {
          errorMessage += '\nRaw Response: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in Service (${model.startsWith("google/gemini") ? "Gemini" : "OpenAI/Compatible"}): $e');
      rethrow;
    }
  }
}
