import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'flux_kontext_service.dart';
import 'flux_krea_service.dart';
import 'google_image_service.dart';

class ImageGenerationService {
  Future<String?> generateImage({
    required String apiKey,
    required String prompt,
    required String model,
    required String providerBaseUrl,
    String openAISize = '1024x1024', // Default for OpenAI
    int n = 1, // Number of images, primarily for OpenAI
    int maxWaitSeconds = 120, // Polling timeout for FLUX.1 Kontext
    int pollIntervalMs = 2000, // Polling interval for FLUX.1 Kontext
    String? aspectRatio,
  }) async {
    if (kDebugMode) {
      print('[ImageGenerationService] Starting image generation');
      print('[ImageGenerationService] Model: $model');
      print('[ImageGenerationService] Provider: $providerBaseUrl');
      print('[ImageGenerationService] Prompt: $prompt');
      print('[ImageGenerationService] Aspect ratio: $aspectRatio');
    }
    
    if (apiKey.isEmpty) {
      throw Exception('API Key is not set.');
    }
    if (prompt.isEmpty) {
      throw Exception('Prompt cannot be empty.');
    }

    Uri endpointUri;
    Map<String, String> headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> body = {};

    if (providerBaseUrl.contains('api.openai.com')) {
      endpointUri = Uri.parse('$providerBaseUrl/images/generations');
      headers['Authorization'] = 'Bearer $apiKey';
      body = {
        'model': model,
        'prompt': prompt,
        'n': n,
        'size': openAISize,
        // 'response_format': 'url', // or 'b64_json'
      };
    } else if (providerBaseUrl.contains('stability.ai')) {
      // Stability AI text-to-image endpoint
      // Reference: https://platform.stability.ai/docs/api-reference#tag/SDXL-1.0/operation/textToImage
      // Endpoint format: POST /v1/generation/{engine_id}/text-to-image
      String engineId = model; // Model should be the engine ID like 'stable-diffusion-xl-1024-v1-0'

      endpointUri = Uri.parse(
        '$providerBaseUrl/v1/generation/$engineId/text-to-image',
      );

      // Stability AI requires Bearer token authentication
      headers['Authorization'] = 'Bearer $apiKey';

      // Parse openAISize to extract width and height
      // Format is typically '1024x1024', '1152x896', etc.
      int width = 1024;
      int height = 1024;
      if (openAISize.contains('x')) {
        final parts = openAISize.split('x');
        if (parts.length == 2) {
          width = int.tryParse(parts[0]) ?? 1024;
          height = int.tryParse(parts[1]) ?? 1024;
        }
      }

      body = {
        'text_prompts': [
          {'text': prompt},
        ],
        'height': height,
        'width': width,
        'samples': n,
        'steps': 30,
        'cfg_scale': 7.0,
        // Optional parameters that can be added:
        // 'style_preset': 'digital-art',
        // 'seed': 0,
      };
    } else if (providerBaseUrl.contains('generativelanguage.googleapis.com') || 
               providerBaseUrl.contains('google')) {
      // Handle Google Generative AI models (including nano-banana)
      if (kDebugMode) {
        print('[ImageGenerationService] Detected Google Generative AI endpoint');
        print('[ImageGenerationService] Model: $model');
      }
      
      final googleService = GoogleImageService(apiKey: apiKey);
      try {
        if (aspectRatio != null && aspectRatio.isNotEmpty) {
          // Use direct aspect ratio if provided
          if (kDebugMode) {
            print('[ImageGenerationService] Using direct aspect ratio: $aspectRatio');
          }
          return await googleService.generateImage(
            prompt: prompt,
            model: model,
            aspectRatio: aspectRatio,
            maxWaitSeconds: maxWaitSeconds,
            pollIntervalMs: pollIntervalMs,
          );
        } else {
          // Fallback to OpenAI size mapping
          if (kDebugMode) {
            print('[ImageGenerationService] Using OpenAI size mapping: $openAISize');
          }
          return await googleService.generateImageWithOpenAISize(
            prompt: prompt,
            model: model,
            openAISize: openAISize,
            maxWaitTime: Duration(seconds: maxWaitSeconds),
            pollInterval: Duration(milliseconds: pollIntervalMs),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('[ImageGenerationService] Google Generative AI error: $e');
        }
        throw Exception('Google Generative AI error: $e');
      }
    } else if (providerBaseUrl.contains('api.bfl.ai')) {
      // Handle different FLUX.1 models based on the model parameter
      if (kDebugMode) {
        print('[ImageGenerationService] Detected FLUX.1 API endpoint');
        print('[ImageGenerationService] Model: $model');
      }
      
      if (model.contains('krea')) {
        // Use FLUX.1-Krea-dev model
        if (kDebugMode) {
          print('[ImageGenerationService] Using FLUX.1-Krea-dev service');
        }
        final fluxService = FluxKreaService(apiKey: apiKey);
        try {
          if (aspectRatio != null && aspectRatio.isNotEmpty) {
            // Use direct aspect ratio if provided
            if (kDebugMode) {
              print('[ImageGenerationService] Using direct aspect ratio: $aspectRatio');
            }
            return await fluxService.generateImage(
              prompt: prompt,
              aspectRatio: aspectRatio,
              maxWaitTime: Duration(seconds: maxWaitSeconds),
              pollInterval: Duration(milliseconds: pollIntervalMs),
            );
          } else {
            // Fallback to OpenAI size mapping
            if (kDebugMode) {
              print('[ImageGenerationService] Using OpenAI size mapping: $openAISize');
            }
            return await fluxService.generateImageWithOpenAISize(
              prompt: prompt,
              openAISize: openAISize,
              maxWaitTime: Duration(seconds: maxWaitSeconds),
              pollInterval: Duration(milliseconds: pollIntervalMs),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('[ImageGenerationService] FLUX.1-Krea-dev error: $e');
          }
          throw Exception('FLUX.1 Krea error: $e');
        }
      } else {
        // Use FLUX.1-Kontext for other models (pro, dev)
        if (kDebugMode) {
          print('[ImageGenerationService] Using FLUX.1-Kontext service');
        }
        final fluxService = FluxKontextService(apiKey: apiKey);
        try {
          if (aspectRatio != null && aspectRatio.isNotEmpty) {
            // Use direct aspect ratio if provided
            if (kDebugMode) {
              print('[ImageGenerationService] Using direct aspect ratio: $aspectRatio');
            }
            return await fluxService.generateImage(
              prompt: prompt,
              aspectRatio: aspectRatio,
              maxWaitTime: Duration(seconds: maxWaitSeconds),
              pollInterval: Duration(milliseconds: pollIntervalMs),
            );
          } else {
            // Fallback to OpenAI size mapping
            if (kDebugMode) {
              print('[ImageGenerationService] Using OpenAI size mapping: $openAISize');
            }
            return await fluxService.generateImageWithOpenAISize(
              prompt: prompt,
              openAISize: openAISize,
              maxWaitTime: Duration(seconds: maxWaitSeconds),
              pollInterval: Duration(milliseconds: pollIntervalMs),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('[ImageGenerationService] FLUX.1-Kontext error: $e');
          }
          throw Exception('FLUX.1 Kontext error: $e');
        }
      }
    } else {
      throw Exception(
        'Unsupported image generation provider or base URL. Supported: api.openai.com, stability.ai, api.bfl.ai, generativelanguage.googleapis.com',
      );
    }

    try {
      final response = await http.post(
        endpointUri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (providerBaseUrl.contains('api.openai.com')) {
          if (responseBody['data'] != null && responseBody['data'].isNotEmpty) {
            return responseBody['data'][0]['url'];
          } else {
            throw Exception('Image URL not found in OpenAI response.');
          }
        } else if (providerBaseUrl.contains('stability.ai')) {
          if (responseBody['artifacts'] != null &&
              responseBody['artifacts'].isNotEmpty) {
            final artifact = responseBody['artifacts'][0];
            if (artifact['base64'] != null) {
              return 'data:image/png;base64,${artifact['base64']}';
            }
            throw Exception(
              'Base64 image data not found in Stability AI response artifact.',
            );
          } else {
            throw Exception('Artifacts not found in Stability AI response.');
          }
        }
        return null; // Should not reach here if provider is supported
      } else {
        String errorMessage =
            'Failed to generate image. Status code: ${response.statusCode}';
        String responseBodyString = response.body;
        try {
          final errorBody = jsonDecode(responseBodyString);
          if (providerBaseUrl.contains('api.openai.com') &&
              errorBody['error'] != null &&
              errorBody['error']['message'] != null) {
            errorMessage += '\nError: ${errorBody['error']['message']}';
          } else if (providerBaseUrl.contains('stability.ai')) {
            if (errorBody['message'] != null) {
              // Stability AI often uses 'message'
              errorMessage += '\nError: ${errorBody['message']}';
            } else if (errorBody['errors'] != null &&
                errorBody['errors'].isNotEmpty) {
              errorMessage += '\nError: ${errorBody['errors'].join(', ')}';
            } else if (errorBody['name'] != null &&
                errorBody['message'] != null) {
              // Another Stability AI error format
              errorMessage +=
                  '\nError: ${errorBody['name']} - ${errorBody['message']}';
            }
          } else if (errorBody['error'] != null &&
              errorBody['error']['message'] != null) {
            // Generic fallback
            errorMessage += '\nError: ${errorBody['error']['message']}';
          }
        } catch (e) {
          // If error body is not JSON or doesn't match expected structure
          errorMessage += '\nResponse body: $responseBodyString';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in generateImage: $e');
      rethrow;
    }
  }
}
