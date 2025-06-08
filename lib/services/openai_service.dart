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

  Stream<String> getChatResponse({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    required String providerBaseUrl, // 新增：基础 URL
  }) {
    if (apiKey.isEmpty) {
      // Instead of throwing, return a stream with an error event.
      // This allows the UI to handle the error gracefully.
      return Stream<String>.error(Exception('API Key is not set.'));
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
      // For streaming, we need to add 'stream': true to the request body for OpenAI compatible APIs
      // For Gemini, the API itself is unary, so true streaming isn't directly supported in the same way.
      // We will simulate streaming for Gemini by returning the full response as a single stream event.
      // However, if Gemini's SDK or a different endpoint supports streaming, that would be preferred.
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

      List<Map<String, String>> apiMessages = messages
          .map((msg) => msg.toApiJson())
          .where((item) => item != null)
          .cast<Map<String, String>>() // Cast to the correct type after filtering
          .toList();
      // For streaming, we need to add 'stream': true to the request body for OpenAI compatible APIs
      // For Gemini, the API itself is unary, so true streaming isn't directly supported in the same way.
      // We will simulate streaming for Gemini by returning the full response as a single stream event.
      // However, if Gemini's SDK or a different endpoint supports streaming, that would be preferred.
      requestBody = jsonEncode({
        'model': model,
        'messages': apiMessages,
        'temperature': 0.7,
        // Add stream: true for OpenAI compatible APIs
        if (!(model.toLowerCase().startsWith('google/gemini') || model.toLowerCase().startsWith('gemini-'))) 'stream': true,
      });
    }

    final uri = Uri.parse(endpointUrl);

    // For Gemini, since it's not a streaming API by default, we'll wrap the single response in a stream.
    if (model.toLowerCase().startsWith('google/gemini') || model.toLowerCase().startsWith('gemini-')) {
      Stream<String> generateGeminiResponse() async* {
        try {
          final response = await http.post(uri, headers: requestHeaders, body: requestBody);
          if (response.statusCode == 200) {
            final data = jsonDecode(utf8.decode(response.bodyBytes));
            if (data['candidates'] != null &&
                data['candidates'].isNotEmpty &&
                data['candidates'][0]['content'] != null &&
                data['candidates'][0]['content']['parts'] != null &&
                data['candidates'][0]['content']['parts'].isNotEmpty) {
              yield data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
            } else if (data['error'] != null && data['error']['message'] != null) {
              throw Exception('Gemini API Error: ${data['error']['message']} (Code: ${data['error']['code']})');
            } else {
              throw Exception('No valid response candidates found in Gemini API response. Body: ${response.body}');
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
              } else if (errorData['detail'] != null) {
                 errorMessage += '\nDetails: ${errorData['detail']}';
              } else {
                 errorMessage += '\nRaw Response: ${response.body}';
              }
            } catch (e) {
              errorMessage += '\nRaw Response: ${response.body}';
            }
            // Check if the error response is HTML, suggesting a configuration or network issue
            if (response.headers['content-type']?.toLowerCase().contains('text/html') ?? false) {
              throw Exception('Failed to connect to API: Received HTML response (Status ${response.statusCode}). Please check Provider URL, API key, and ensure the Generative Language API is enabled in your Google Cloud project.');
            }
            throw Exception(errorMessage);
          }
        } catch (e) {
          print('Error in Gemini Service: $e');
          yield* Stream<String>.error(e); // Yield the error to the stream
        }
      }
      return generateGeminiResponse();
    } else {
      // OpenAI-compatible streaming logic
      Stream<String> generateOpenAIResponse() async* {
        try {
          final request = http.Request('POST', uri);
          request.headers.addAll(requestHeaders);
          request.body = requestBody;

          final streamedResponse = await request.send();

          if (streamedResponse.statusCode == 200) {
            await for (var chunk in streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter())) {
              if (chunk.startsWith('data: ')) {
                final dataString = chunk.substring(6);
                if (dataString == '[DONE]') {
                  break;
                }
                try {
                  final data = jsonDecode(dataString);
                  if (data['choices'] != null && data['choices'].isNotEmpty) {
                    final delta = data['choices'][0]['delta'];
                    if (delta != null && delta['content'] != null) {
                      yield delta['content'].toString();
                    }
                  }
                } catch (e) {
                  // Handle potential JSON parsing errors for incomplete chunks, though LineSplitter should help
                  print('Error parsing stream chunk: $e, chunk: $dataString');
                }
              }
            }
          } else {
            final responseBody = await streamedResponse.stream.bytesToString();
            print('API Error: ${streamedResponse.statusCode} for model $model at $endpointUrl');
            print('API Response: $responseBody');
            String errorMessage = 'Failed to get response from API: ${streamedResponse.statusCode} ${streamedResponse.reasonPhrase}';
            try {
              final errorData = jsonDecode(responseBody);
              if (errorData['error'] != null && errorData['error']['message'] != null) {
                errorMessage += '\nDetails: ${errorData['error']['message']}';
                 if (errorData['error']['code'] != null) errorMessage += ' (Code: ${errorData['error']['code']})';
              } else if (errorData['detail'] != null) {
                 errorMessage += '\nDetails: ${errorData['detail']}';
              } else {
                errorMessage += '\nRaw Response: $responseBody';
              }
            } catch (e) {
              errorMessage += '\nRaw Response: $responseBody';
            }
            // Check if the error response is HTML, suggesting a configuration or network issue
            final contentType = streamedResponse.headers['content-type']?.toLowerCase();
            if (contentType?.contains('text/html') ?? false) {
              throw Exception('Failed to connect to API: Received HTML response (Status ${streamedResponse.statusCode}). Please check Provider URL and API key.');
            }
            throw Exception(errorMessage);
          }
        } catch (e) {
          print('Error in OpenAI/Compatible Service: $e');
          yield* Stream<String>.error(e); // Yield the error to the stream
        }
      }
      return generateOpenAIResponse();
    }
  }
}
