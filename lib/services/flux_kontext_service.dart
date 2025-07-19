import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'base_api_service.dart';

class FluxKontextRequest {
  final String prompt;
  final String? aspectRatio;
  final int? seed;
  final bool? promptUpsampling;
  final int? safetyTolerance;
  final String? outputFormat;
  final String? image;
  final double? strength;
  final double? guidanceScale;

  FluxKontextRequest({
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

class FluxKontextResponse {
  final String id;
  final String status;
  final String pollingUrl;

  FluxKontextResponse({
    required this.id,
    required this.status,
    required this.pollingUrl,
  });

  factory FluxKontextResponse.fromJson(Map<String, dynamic> json) {
    return FluxKontextResponse(
      id: json['id'] ?? '',
      status: json['status'] ?? 'pending',
      pollingUrl: json['polling_url'] ?? '',
    );
  }
}

class FluxKontextResult {
  final String sampleUrl;
  final String? prompt;
  final Map<String, dynamic>? metadata;

  FluxKontextResult({required this.sampleUrl, this.prompt, this.metadata});

  factory FluxKontextResult.fromJson(Map<String, dynamic> json) {
    return FluxKontextResult(
      sampleUrl: json['result']?['sample'] ?? '',
      prompt: json['result']?['prompt'],
      metadata: json['result']?['metadata'],
    );
  }
}

class FluxKontextService extends BaseApiService {
  FluxKontextService({required String apiKey})
    : super(baseUrl: 'https://api.bfl.ai/v1', apiKey: apiKey);

  @override
  String get providerName => 'Black Foreast Labs';

  @override
  Map<String, String> getHeaders() {
    return {'Content-Type': 'application/json', 'x-key': apiKey};
  }

  @override
  void validateResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage =
          'Request failed with status 27${response.statusCode}27';
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage =
            errorBody['error']?['message'] ??
            errorBody['message'] ??
            errorMessage;
      } catch (_) {}
      throw Exception('FLUX.1 Kontext API error: $errorMessage');
    }
  }

  Future<FluxKontextResponse> _submitRequest(FluxKontextRequest request) async {
    try {
      final url = Uri.parse('$baseUrl/flux-kontext-pro');
      final headers = <String, String>{
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'x-key': apiKey,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print(jsonEncode(request.toJson()));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return FluxKontextResponse.fromJson(jsonResponse);
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['error']?['message'] ??
            errorBody['message'] ??
            'Unknown error';
        throw Exception('FLUX.1 Kontext API error: $errorMessage');
      }
    } catch (e) {
      print('Error submitting FLUX.1 request: $e');
      rethrow;
    }
  }

  Future<FluxKontextResult> pollResult(String requestId) async {
    try {
      final url = Uri.parse('$baseUrl/get_result?id=$requestId');
      final headers = <String, String>{
        'accept': 'application/json',
        'x-key': apiKey,
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return FluxKontextResult.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to poll result: ${response.statusCode}');
      }
    } catch (e) {
      print('Error polling FLUX.1 result: $e');
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
    final request = FluxKontextRequest(
      prompt: prompt,
      aspectRatio: aspectRatio,
      seed: seed,
      outputFormat: outputFormat,
      safetyTolerance: safetyTolerance,
    );

    final response = await _submitRequest(request);
    return await _waitForResult(response.id, maxWaitTime, pollInterval);
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
    // Parse OpenAI-style size to aspect ratio for FLUX.1
    String? aspectRatio;
    if (openAISize == '1024x1024') {
      aspectRatio = '1:1';
    } else if (openAISize == '1792x1024') {
      aspectRatio = '16:9';
    } else if (openAISize == '1024x1792') {
      aspectRatio = '9:16';
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
    final request = FluxKontextRequest(
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

    while (stopwatch.elapsed < maxWaitTime) {
      try {
        final result = await pollResult(requestId);
        if (result.sampleUrl.isNotEmpty) {
          return result.sampleUrl;
        }
      } catch (e) {
        // Continue polling on transient errors
        print('Polling error, retrying: $e');
      }

      await Future.delayed(pollInterval);
    }

    throw Exception(
      'Image generation timed out after ${maxWaitTime.inSeconds} seconds',
    );
  }

  Future<bool> testConnection() async {
    try {
      final testPrompt = 'a simple test image';
      final url = Uri.parse('$baseUrl/flux-kontext-pro');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'x-key': apiKey,
      };
      final body = {'prompt': testPrompt, 'aspect_ratio': '1:1'};

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
