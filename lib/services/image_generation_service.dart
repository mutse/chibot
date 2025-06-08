import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageGenerationService {
  Future<String?> generateImage({
    required String apiKey,
    required String prompt,
    required String model,
    required String providerBaseUrl,
    String openAISize = '1024x1024', // Default for OpenAI
    int n = 1, // Number of images, primarily for OpenAI
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is not set.');
    }
    if (prompt.isEmpty) {
      throw Exception('Prompt cannot be empty.');
    }

    Uri endpointUri;
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
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
      // Determine the Stability AI model from the generic model string if needed
      // For example, if 'model' is 'stable-diffusion-v1-6', use it directly.
      // The Stability AI API path often includes the engine ID.
      // Example: https://api.stability.ai/v1/generation/{engine_id}/text-to-image
      // We'll use a common engine, but this might need to be configurable or derived from `model`
      String engineId = model; // Assuming model is the engine ID like 'stable-diffusion-v1-6'
      // Stability AI image generation endpoint is typically v1/generation/{engine_id}/text-to-image
      // The error URL `https://api.stability.ai/v2beta/chat/completions` seems to be for chat models.
      // We need to ensure the correct image generation endpoint is used.
      // For Stability AI, the base URL should be something like 'https://api.stability.ai'.
      // The full endpoint for image generation is usually 'https://api.stability.ai/v1/generation/{engine_id}/text-to-image'
      // If the model is 'dall-e-3' or 'dall-e-2', it's an OpenAI model, not Stability AI.
      // The model 'command-r-plus' is a text model, not an image model.
      // It seems there's a mismatch in the model type being used for image generation.
      // Assuming the user intends to use a Stability AI image model, the endpoint should be:
      endpointUri = Uri.parse('$providerBaseUrl/v1/generation/$engineId/text-to-image');
      headers['Accept'] = 'application/json';
      headers['Authorization'] = apiKey; // Stability AI API key is often passed directly as 'key <API_KEY>' or just '<API_KEY>'
                                      // The 'Bearer' prefix is usually for OAuth tokens.
                                      // For Stability, it's often just the key itself or prefixed with 'key '.
                                      // Let's assume the key is passed directly as per some common patterns.
                                      // If it requires 'key ', the user should include it in their API key setting.

      body = {
        'text_prompts': [
          {'text': prompt, 'weight': 1.0}
        ],
        'cfg_scale': 7, // Default, can be adjusted
        'height': 1024, // Default, can be adjusted
        'width': 1024, // Default, can be adjusted
        'samples': n, // Number of images to generate
        'steps': 30, // Default, can be adjusted. More steps can mean better quality but longer time.
        // 'style_preset': 'enhance', // Optional: e.g., 'photographic', 'digital-art', etc.
        // 'seed': 0, // Optional: for reproducibility
      };
    } else {
      throw Exception('Unsupported image generation provider or base URL. Supported: api.openai.com, stability.ai');
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
          if (responseBody['artifacts'] != null && responseBody['artifacts'].isNotEmpty) {
            final artifact = responseBody['artifacts'][0];
            if (artifact['base64'] != null) {
              return 'data:image/png;base64,${artifact['base64']}';
            }
            throw Exception('Base64 image data not found in Stability AI response artifact.');
          } else {
            throw Exception('Artifacts not found in Stability AI response.');
          }
        }
        return null; // Should not reach here if provider is supported
      } else {
        String errorMessage = 'Failed to generate image. Status code: ${response.statusCode}';
        String responseBodyString = response.body;
        try {
          final errorBody = jsonDecode(responseBodyString);
          if (providerBaseUrl.contains('api.openai.com') && errorBody['error'] != null && errorBody['error']['message'] != null) {
            errorMessage += '\nError: ${errorBody['error']['message']}';
          } else if (providerBaseUrl.contains('stability.ai')) {
            if (errorBody['message'] != null) { // Stability AI often uses 'message'
              errorMessage += '\nError: ${errorBody['message']}';
            } else if (errorBody['errors'] != null && errorBody['errors'].isNotEmpty) {
              errorMessage += '\nError: ${errorBody['errors'].join(', ')}';
            } else if (errorBody['name'] != null && errorBody['message'] != null) { // Another Stability AI error format
                errorMessage += '\nError: ${errorBody['name']} - ${errorBody['message']}';
            }
          } else if (errorBody['error'] != null && errorBody['error']['message'] != null) { // Generic fallback
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