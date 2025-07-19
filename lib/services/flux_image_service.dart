import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class FluxKontextImageService {
  final String apiKey;
  final String baseUrl = 'https://api.bfl.ai/v1';

  FluxKontextImageService({required this.apiKey});

  /// Generate image using FLUX.1 Kontext with polling
  Future<String> generateImage({
    required String prompt,
    String? aspectRatio = '1:1',
    int? seed,
    String? outputFormat = 'png',
    int? safetyTolerance,
    Duration maxWaitTime = const Duration(seconds: 60),
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('FLUX.1 Kontext API key is required.');
    }
    if (prompt.isEmpty) {
      throw Exception('Prompt cannot be empty.');
    }

    try {
      // Step 1: Submit the request
      final submitResponse = await _submitTextToImageRequest(
        prompt: prompt,
        aspectRatio: aspectRatio,
        seed: seed,
        outputFormat: outputFormat,
        safetyTolerance: safetyTolerance,
      );

      // Step 2: Poll for result
      final imageUrl = await _pollForResult(
        requestId: submitResponse.id,
        maxWaitTime: maxWaitTime,
        pollInterval: pollInterval,
      );

      return imageUrl;
    } catch (e) {
      print('FLUX.1 Kontext generation error: $e');
      rethrow;
    }
  }

  /// Submit text-to-image request
  Future<FluxSubmitResponse> _submitTextToImageRequest({
    required String prompt,
    String? aspectRatio,
    int? seed,
    String? outputFormat,
    int? safetyTolerance,
  }) async {
    final url = Uri.parse('$baseUrl/flux-kontext-pro');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = {
      'prompt': prompt,
      if (aspectRatio != null) 'aspect_ratio': aspectRatio,
      if (seed != null) 'seed': seed,
      if (outputFormat != null) 'output_format': outputFormat,
      if (safetyTolerance != null) 'safety_tolerance': safetyTolerance,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    print(jsonEncode(body));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return FluxSubmitResponse.fromJson(jsonResponse);
    } else {
      print('FLUX.1 API error: ${response.statusCode} - ${response.body}');
      String errorMessage;
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage =
            errorBody['error']?['message'] ??
            errorBody['message'] ??
            getDetailedError(response.statusCode, response.body);
      } catch (e) {
        errorMessage = getDetailedError(response.statusCode, response.body);
      }
      throw Exception('FLUX.1 Kontext API error: $errorMessage');
    }
  }

  /// Poll for result completion
  Future<String> _pollForResult({
    required String requestId,
    required Duration maxWaitTime,
    required Duration pollInterval,
  }) async {
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse('$baseUrl/get_result?id=$requestId');
    final headers = {'Authorization': 'Bearer $apiKey'};

    while (stopwatch.elapsed < maxWaitTime) {
      try {
        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final result = FluxPollResponse.fromJson(jsonResponse);

          if (result.status == 'ready') {
            if (result.sampleUrl != null && result.sampleUrl!.isNotEmpty) {
              return result.sampleUrl!;
            } else {
              throw Exception('FLUX.1 returned no image URL');
            }
          } else if (result.status == 'failed') {
            throw Exception(
              'FLUX.1 generation failed: ${result.error ?? "Unknown error"}',
            );
          } else if (result.status == 'pending' ||
              result.status == 'processing') {
            // Continue polling
            await Future.delayed(pollInterval);
            continue;
          } else {
            throw Exception('Unexpected FLUX.1 status: ${result.status}');
          }
        } else {
          throw Exception(
            'Failed to poll FLUX.1 result: ${response.statusCode}',
          );
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('failed')) {
          // Don't retry on permanent failures
          rethrow;
        }
        // Retry on network errors
        await Future.delayed(pollInterval);
      }
    }

    throw Exception(
      'FLUX.1 generation timed out after ${maxWaitTime.inSeconds} seconds',
    );
  }

  /// Test connection to FLUX.1 API
  Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$baseUrl/flux-kontext-pro');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
      final body = {'prompt': 'test', 'aspect_ratio': '1:1'};

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Generate image with image-to-image capability
  Future<String> editImage({
    required String prompt,
    required String imageUrl,
    double? strength = 0.8,
    double? guidanceScale = 2.5,
    String? aspectRatio,
    Duration maxWaitTime = const Duration(seconds: 60),
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('FLUX.1 Kontext API key is required.');
    }
    if (prompt.isEmpty) {
      throw Exception('Prompt cannot be empty.');
    }
    if (imageUrl.isEmpty) {
      throw Exception('Image URL cannot be empty.');
    }

    try {
      final submitResponse = await _submitImageToImageRequest(
        prompt: prompt,
        imageUrl: imageUrl,
        strength: strength,
        guidanceScale: guidanceScale,
        aspectRatio: aspectRatio,
      );

      final imageUrlResult = await _pollForResult(
        requestId: submitResponse.id,
        maxWaitTime: maxWaitTime,
        pollInterval: pollInterval,
      );

      return imageUrlResult;
    } catch (e) {
      print('FLUX.1 Kontext image editing error: $e');
      rethrow;
    }
  }

  /// Submit image-to-image request
  Future<FluxSubmitResponse> _submitImageToImageRequest({
    required String prompt,
    required String imageUrl,
    double? strength,
    double? guidanceScale,
    String? aspectRatio,
  }) async {
    final url = Uri.parse('$baseUrl/flux-kontext-pro');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = {
      'prompt': prompt,
      'image': imageUrl,
      if (strength != null) 'strength': strength,
      if (guidanceScale != null) 'guidance_scale': guidanceScale,
      if (aspectRatio != null) 'aspect_ratio': aspectRatio,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return FluxSubmitResponse.fromJson(jsonResponse);
    } else {
      print('FLUX.1 API error: ${response.statusCode} - ${response.body}');
      String errorMessage;
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage =
            errorBody['error']?['message'] ??
            errorBody['message'] ??
            getDetailedError(response.statusCode, response.body);
      } catch (e) {
        errorMessage = getDetailedError(response.statusCode, response.body);
      }
      throw Exception('FLUX.1 Kontext API error: $errorMessage');
    }
  }

  /// Get detailed error information
  String getDetailedError(int statusCode, String responseBody) {
    switch (statusCode) {
      case 401:
        return 'Authentication failed. Please check your API key is correct and active.';
      case 403:
        return 'Access forbidden. Your API key may not have permission to use FLUX.1 models.';
      case 429:
        return 'Rate limit exceeded. Please wait before making more requests.';
      case 400:
        return 'Bad request. The prompt or parameters may be invalid.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'HTTP $statusCode error. Response: $responseBody';
    }
  }
}

class FluxSubmitResponse {
  final String id;
  final String status;
  final String pollingUrl;

  FluxSubmitResponse({
    required this.id,
    required this.status,
    required this.pollingUrl,
  });

  factory FluxSubmitResponse.fromJson(Map<String, dynamic> json) {
    return FluxSubmitResponse(
      id: json['id'] ?? '',
      status: json['status'] ?? 'pending',
      pollingUrl: json['polling_url'] ?? '',
    );
  }
}

class FluxPollResponse {
  final String status;
  final String? sampleUrl;
  final String? error;

  FluxPollResponse({required this.status, this.sampleUrl, this.error});

  factory FluxPollResponse.fromJson(Map<String, dynamic> json) {
    return FluxPollResponse(
      status: json['status'] ?? 'pending',
      sampleUrl: json['result']?['sample'],
      error: json['error']?['message'],
    );
  }
}
