import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GoogleImageService {
  final String apiKey;

  GoogleImageService({required this.apiKey});

  static const String baseUrl = 'https://generativelanguage.googleapis.com';

  Future<String?> generateImage({
    required String prompt,
    String model = 'nano-banana',
    String? aspectRatio,
    int maxWaitSeconds = 120,
    int pollIntervalMs = 2000,
  }) async {
    if (kDebugMode) {
      print('[GoogleImageService] Starting image generation');
      print('[GoogleImageService] Model: $model');
      print('[GoogleImageService] Prompt: $prompt');
      print('[GoogleImageService] Aspect ratio: $aspectRatio');
    }

    if (apiKey.isEmpty) {
      throw Exception('Google API Key is not set.');
    }
    if (prompt.isEmpty) {
      throw Exception('Prompt cannot be empty.');
    }

    try {
      // Google's generative AI API endpoint for image generation
      final Uri endpointUri = Uri.parse('$baseUrl/v1beta/models/$model:generateContent');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      };

      // Build request body for Google's API
      final Map<String, dynamic> body = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'candidateCount': 1,
        }
      };

      // Add aspect ratio if provided
      if (aspectRatio != null && aspectRatio.isNotEmpty) {
        body['generationConfig']['aspectRatio'] = aspectRatio;
      }

      if (kDebugMode) {
        print('[GoogleImageService] Making request to: $endpointUri');
        print('[GoogleImageService] Request body: ${jsonEncode(body)}');
      }

      final response = await http.post(
        endpointUri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        print('[GoogleImageService] Response status: ${response.statusCode}');
        print('[GoogleImageService] Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        
        // Parse Google's response format
        if (responseBody['candidates'] != null && 
            responseBody['candidates'].isNotEmpty) {
          final candidate = responseBody['candidates'][0];
          
          // Check for inline image data
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            final parts = candidate['content']['parts'];
            
            // Look for image data in parts
            for (final part in parts) {
              if (part['inlineData'] != null) {
                final inlineData = part['inlineData'];
                final mimeType = inlineData['mimeType'] ?? 'image/png';
                final data = inlineData['data'];
                
                if (data != null) {
                  return 'data:$mimeType;base64,$data';
                }
              }
            }
          }
          
          // Fallback: check for direct image URL
          if (candidate['imageUrl'] != null) {
            return candidate['imageUrl'];
          }
        }
        
        throw Exception('No image data found in Google response.');
      } else {
        String errorMessage = 'Failed to generate image. Status code: ${response.statusCode}';
        String responseBodyString = response.body;
        
        try {
          final errorBody = jsonDecode(responseBodyString);
          if (errorBody['error'] != null) {
            final error = errorBody['error'];
            if (error['message'] != null) {
              errorMessage += '\nError: ${error['message']}';
            }
            if (error['details'] != null) {
              errorMessage += '\nDetails: ${error['details']}';
            }
          }
        } catch (e) {
          errorMessage += '\nResponse body: $responseBodyString';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[GoogleImageService] Error in generateImage: $e');
      }
      rethrow;
    }
  }

  /// Generate image with OpenAI-compatible size parameter
  Future<String?> generateImageWithOpenAISize({
    required String prompt,
    String model = 'nano-banana',
    String openAISize = '1024x1024',
    Duration? maxWaitTime,
    Duration? pollInterval,
  }) async {
    // Convert OpenAI size to aspect ratio
    String? aspectRatio = _openAISizeToAspectRatio(openAISize);
    
    return await generateImage(
      prompt: prompt,
      model: model,
      aspectRatio: aspectRatio,
      maxWaitSeconds: maxWaitTime?.inSeconds ?? 120,
      pollIntervalMs: pollInterval?.inMilliseconds ?? 2000,
    );
  }

  /// Convert OpenAI size format to aspect ratio
  String? _openAISizeToAspectRatio(String openAISize) {
    switch (openAISize) {
      case '1024x1024':
        return '1:1';
      case '1792x1024':
        return '16:9';
      case '1024x1792':
        return '9:16';
      case '1344x768':
        return '7:4';
      case '768x1344':
        return '4:7';
      default:
        return '1:1'; // Default to square
    }
  }

  /// Get supported models for Google image generation
  static List<String> getSupportedModels() {
    return [
      'nano-banana',
      'gemini-pro-vision', // If Google supports this for image generation
    ];
  }

  /// Get supported aspect ratios
  static List<String> getSupportedAspectRatios() {
    return [
      '1:1',
      '16:9',
      '9:16',
      '4:3',
      '3:4',
      '7:4',
      '4:7',
    ];
  }
}