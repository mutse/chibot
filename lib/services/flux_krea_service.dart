import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'base_api_service.dart';

class FluxKreaRequest {
  final String prompt;
  final String? aspectRatio;
  final int? seed;
  final bool? promptUpsampling;
  final int? safetyTolerance;
  final String? outputFormat;
  final String? image;
  final double? strength;
  final double? guidanceScale;

  FluxKreaRequest({
    required this.prompt,
    this.aspectRatio,
    this.seed,
    this.promptUpsampling,
    this.safetyTolerance,
    this.outputFormat,
    this.image,
    this.strength,
    this.guidanceScale,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'prompt': prompt,
      if (aspectRatio != null) 'aspect_ratio': aspectRatio,
      if (seed != null) 'seed': seed,
      if (promptUpsampling != null) 'prompt_upsampling': promptUpsampling,
      if (safetyTolerance != null) 'safety_tolerance': safetyTolerance,
      if (outputFormat != null) 'output_format': outputFormat,
      if (image != null) 'image': image,
      if (strength != null) 'strength': strength,
      if (guidanceScale != null) 'guidance_scale': guidanceScale,
    };
    return json;
  }
}

class FluxKreaResponse {
  final String id;
  final String status;
  final String pollingUrl;

  FluxKreaResponse({
    required this.id,
    required this.status,
    required this.pollingUrl,
  });

  factory FluxKreaResponse.fromJson(Map<String, dynamic> json) {
    return FluxKreaResponse(
      id: json['id'] ?? '',
      status: json['status'] ?? 'pending',
      pollingUrl: json['polling_url'] ?? '',
    );
  }
}

class FluxKreaResult {
  final String sampleUrl;
  final String? prompt;
  final Map<String, dynamic>? metadata;

  FluxKreaResult({required this.sampleUrl, this.prompt, this.metadata});

  factory FluxKreaResult.fromJson(Map<String, dynamic> json) {
    return FluxKreaResult(
      sampleUrl: json['result']?['sample'] ?? '',
      prompt: json['result']?['prompt'],
      metadata: json['result']?['metadata'],
    );
  }
}

class FluxKreaService extends BaseApiService {
  FluxKreaService({required String apiKey})
    : super(baseUrl: 'https://api.bfl.ai', apiKey: apiKey);

  @override
  String get providerName => 'BFL';

  @override
  Map<String, String> getHeaders() {
    return {'Content-Type': 'application/json', 'X-Key': apiKey};
  }

  @override
  void validateResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage = 'Request failed with status ${response.statusCode}';
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage =
            errorBody['error']?['message'] ??
            errorBody['message'] ??
            errorMessage;
      } catch (_) {}
      throw Exception('FLUX.1 Krea API error: $errorMessage');
    }
  }

  Future<FluxKreaResponse> _submitRequest(FluxKreaRequest request) async {
    if (kDebugMode) {
      print('[FLUX.1-Krea-dev] Starting image generation request');
      print('[FLUX.1-Krea-dev] Request URL: $baseUrl/v1/flux-dev');
      print('[FLUX.1-Krea-dev] Request body: ${jsonEncode(request.toJson())}');
    }

    try {
      final url = Uri.parse('$baseUrl/v1/flux-krea-dev');
      final headers = <String, String>{
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Key': apiKey,
      };

      final requestBody = jsonEncode(request.toJson());
      if (kDebugMode) {
        print('[FLUX.1-Krea-dev] Full request: $requestBody');
      }

      final stopwatch = Stopwatch()..start();
      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );
      stopwatch.stop();

      if (kDebugMode) {
        print('[FLUX.1-Krea-dev] Response status: ${response.statusCode}');
        print(
          '[FLUX.1-Krea-dev] Response time: ${stopwatch.elapsedMilliseconds}ms',
        );
        print('[FLUX.1-Krea-dev] Response headers: ${response.headers}');
        print('[FLUX.1-Krea-dev] Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final requestId = jsonResponse['id'];
        final status = jsonResponse['status'];

        // Validate the response structure
        if (requestId == null || requestId.isEmpty) {
          throw Exception('Invalid response: Missing or empty request ID');
        }

        if (kDebugMode) {
          print('[FLUX.1-Krea-dev] Request ID: $requestId');
          print('[FLUX.1-Krea-dev] Status: $status');
        }

        // Verify the request was accepted properly
        if (status == 'pending' || status == 'processing') {
          return FluxKreaResponse.fromJson(jsonResponse);
        } else if (status == 'error' || status == 'failed') {
          final errorMessage =
              jsonResponse['details']?['error'] ?? 'Request failed';
          throw Exception('Request failed immediately: $errorMessage');
        } else {
          // Unknown status, but proceed with valid ID
          return FluxKreaResponse.fromJson(jsonResponse);
        }
      } else {
        String errorMessage =
            'Request failed with status ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage =
              errorBody['error']?['message'] ??
              errorBody['message'] ??
              errorMessage;
        } catch (_) {
          // Keep default error message if parsing fails
        }

        if (kDebugMode) {
          print('[FLUX.1-Krea-dev] API Error: $errorMessage');
        }
        throw Exception('FLUX.1 Krea API error: $errorMessage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FLUX.1-Krea-dev] Exception in _submitRequest: $e');
      }
      rethrow;
    }
  }

  Future<FluxKreaResult> pollResult(String requestId) async {
    if (kDebugMode) {
      print('[FLUX.1-Krea-dev] Polling result for request: $requestId');
    }

    try {
      // Use the correct API endpoint format
      final url = Uri.parse(
        '$baseUrl/v1/get_result',
      ).replace(queryParameters: {'id': requestId});
      final headers = <String, String>{
        'accept': 'application/json',
        'X-Key': apiKey,
      };

      if (kDebugMode) {
        print('[FLUX.1-Krea-dev] Polling URL: $url');
      }

      final stopwatch = Stopwatch()..start();
      final response = await http.get(url, headers: headers);
      stopwatch.stop();

      if (kDebugMode) {
        print(
          '[FLUX.1-Krea-dev] Polling response status: ${response.statusCode}',
        );
        print(
          '[FLUX.1-Krea-dev] Polling response time: ${stopwatch.elapsedMilliseconds}ms',
        );
        print('[FLUX.1-Krea-dev] Polling response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final status = jsonResponse['status'] ?? '';

        if (kDebugMode) {
          print('[FLUX.1-Krea-dev] Polling status: $status');
          if (status == 'Ready') {
            print(
              '[FLUX.1-Krea-dev] Image URL: ${jsonResponse['result']?['sample']}',
            );
          }
        }

        // Handle different status responses
        if (status == 'Task not found') {
          throw Exception(
            'Task not found: Request ID $requestId may be invalid or expired',
          );
        } else if (status == 'Error') {
          final errorDetails = jsonResponse['details'] ?? {};
          throw Exception(
            'Task failed: ${errorDetails['error'] ?? 'Unknown error'}',
          );
        }

        return FluxKreaResult.fromJson(jsonResponse);
      } else if (response.statusCode == 404) {
        // Handle 404 specifically - task not found
        throw Exception(
          'Task not found (404): Request ID $requestId may be invalid or expired',
        );
      } else {
        // Try to parse error from response body
        String errorMessage = 'Failed to poll result: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage =
              errorBody['error']?['message'] ??
              errorBody['message'] ??
              errorMessage;
        } catch (_) {
          // Keep the default error message if parsing fails
        }

        if (kDebugMode) {
          print('[FLUX.1-Krea-dev] Polling failed: $errorMessage');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FLUX.1-Krea-dev] Exception in pollResult: $e');
      }
      rethrow;
    }
  }

  Future<String> generateImage({
    required String prompt,
    String? aspectRatio,
    int? seed,
    String? outputFormat = 'png',
    int? safetyTolerance,
    Duration maxWaitTime = const Duration(seconds: 60),
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    if (kDebugMode) {
      print('[FLUX.1-Krea-dev] generateImage called');
      print('[FLUX.1-Krea-dev] Prompt: $prompt');
      print('[FLUX.1-Krea-dev] Aspect ratio: $aspectRatio');
      print('[FLUX.1-Krea-dev] Seed: $seed');
      print('[FLUX.1-Krea-dev] Max wait time: ${maxWaitTime.inSeconds}s');
    }

    final request = FluxKreaRequest(
      prompt: prompt,
      aspectRatio: aspectRatio,
      seed: seed,
      outputFormat: outputFormat,
      safetyTolerance: safetyTolerance,
    );

    final response = await _submitRequest(request);
    final result = await _waitForResult(response.id, maxWaitTime, pollInterval);

    if (kDebugMode) {
      print('[FLUX.1-Krea-dev] Image generation completed: $result');
    }

    return result;
  }

  /// Generate image with OpenAI-style size parameter
  Future<String> generateImageWithOpenAISize({
    required String prompt,
    required String openAISize,
    String? outputFormat = 'png',
    int? safetyTolerance,
    Duration maxWaitTime = const Duration(seconds: 120),
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    if (kDebugMode) {
      print('[FLUX.1-Krea-dev] generateImageWithOpenAISize called');
      print('[FLUX.1-Krea-dev] Prompt: $prompt');
      print('[FLUX.1-Krea-dev] OpenAI size: $openAISize');
    }

    // Parse OpenAI-style size to aspect ratio for FLUX.1
    String? aspectRatio;
    if (openAISize == '1024x1024') {
      aspectRatio = '1:1';
    } else if (openAISize == '1792x1024') {
      aspectRatio = '16:9';
    } else if (openAISize == '1024x1792') {
      aspectRatio = '9:16';
    }

    if (kDebugMode) {
      print('[FLUX.1-Krea-dev] Mapped aspect ratio: $aspectRatio');
    }

    return generateImage(
      prompt: prompt,
      aspectRatio: aspectRatio ?? '1:1',
      outputFormat: outputFormat,
      safetyTolerance: safetyTolerance,
      maxWaitTime: maxWaitTime,
      pollInterval: pollInterval,
    );
  }

  Future<String> editImage({
    required String prompt,
    required String imageUrl,
    double? strength = 0.8,
    double? guidanceScale = 2.5,
    String? aspectRatio,
    Duration maxWaitTime = const Duration(seconds: 60),
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    final request = FluxKreaRequest(
      prompt: prompt,
      image: imageUrl,
      strength: strength,
      guidanceScale: guidanceScale,
      aspectRatio: aspectRatio,
    );

    final response = await _submitRequest(request);
    return await _waitForResult(response.id, maxWaitTime, pollInterval);
  }

  Future<String> _waitForResult(
    String requestId,
    Duration maxWaitTime,
    Duration pollInterval,
  ) async {
    final stopwatch = Stopwatch()..start();
    int retryCount = 0;
    const maxRetries = 3;

    if (kDebugMode) {
      print('[FLUX.1-Krea-dev] Starting polling process');
      print('[FLUX.1-Krea-dev] Request ID: $requestId');
      print('[FLUX.1-Krea-dev] Max wait time: ${maxWaitTime.inSeconds}s');
      print('[FLUX.1-Krea-dev] Poll interval: ${pollInterval.inSeconds}s');
    }

    while (stopwatch.elapsed < maxWaitTime) {
      if (kDebugMode) {
        print(
          '[FLUX.1-Krea-dev] Polling attempt - elapsed: ${stopwatch.elapsed.inSeconds}s',
        );
      }

      try {
        final result = await pollResult(requestId);

        // Reset retry count on successful poll
        retryCount = 0;

        // Check if image is ready and available
        if (result.sampleUrl.isNotEmpty) {
          if (kDebugMode) {
            print('[FLUX.1-Krea-dev] Image ready! URL: ${result.sampleUrl}');
            print(
              '[FLUX.1-Krea-dev] Total time: ${stopwatch.elapsed.inSeconds}s',
            );
          }
          return result.sampleUrl;
        } else {
          if (kDebugMode) {
            print('[FLUX.1-Krea-dev] Image not ready yet, continuing...');
          }
        }
      } catch (e) {
        final errorString = e.toString();

        // Handle critical errors that should stop polling immediately
        if (errorString.contains('Task not found') ||
            errorString.contains('404') ||
            errorString.contains('invalid or expired')) {
          if (kDebugMode) {
            print(
              '[FLUX.1-Krea-dev] Task not found or expired, stopping polling: $e',
            );
          }
          throw Exception(
            'Task not found: The image generation task may have expired or been removed from the server',
          );
        } else if (errorString.contains('Task failed') ||
            (errorString.contains('Error') &&
                !errorString.contains('network'))) {
          if (kDebugMode) {
            print('[FLUX.1-Krea-dev] Task failed, stopping polling: $e');
          }
          throw Exception('Image generation failed: $e');
        } else {
          // For network or temporary errors, retry with backoff
          retryCount++;
          if (retryCount >= maxRetries) {
            if (kDebugMode) {
              print('[FLUX.1-Krea-dev] Max retries reached, giving up: $e');
            }
            throw Exception('Polling failed after $maxRetries attempts: $e');
          }

          // Use exponential backoff for retries
          final retryDelay = Duration(
            milliseconds: pollInterval.inMilliseconds * (retryCount * 2),
          );

          if (kDebugMode) {
            print(
              '[FLUX.1-Krea-dev] Temporary error, retrying in ${retryDelay.inSeconds}s (attempt $retryCount/$maxRetries): $e',
            );
          }

          await Future.delayed(retryDelay);
          continue;
        }
      }

      await Future.delayed(pollInterval);
    }

    if (kDebugMode) {
      print(
        '[FLUX.1-Krea-dev] Timeout reached after ${maxWaitTime.inSeconds}s',
      );
    }

    throw Exception(
      'Image generation timed out after ${maxWaitTime.inSeconds} seconds. The task may still be processing on the server.',
    );
  }

  Future<bool> testConnection() async {
    if (kDebugMode) {
      print('[FLUX.1-Krea-dev] Testing connection');
    }

    try {
      final testPrompt = 'a simple test image';
      final url = Uri.parse('$baseUrl/v1/flux-dev');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Key': apiKey,
      };
      final body = {'prompt': testPrompt, 'aspect_ratio': '1:1'};

      if (kDebugMode) {
        print('[FLUX.1-Krea-dev] Test URL: $url');
        print('[FLUX.1-Krea-dev] Test body: ${jsonEncode(body)}');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        print('[FLUX.1-Krea-dev] Test response: ${response.statusCode}');
        print('[FLUX.1-Krea-dev] Test response body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('[FLUX.1-Krea-dev] Connection test failed: $e');
      }
      return false;
    }
  }
}
