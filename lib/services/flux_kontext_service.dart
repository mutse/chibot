import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/logger.dart';
import 'flux/flux_base_service.dart';
import 'flux/flux_dtos.dart';

// 旧的类型名以 typedef 形式重新导出，保留所有外部引用。
typedef FluxKontextRequest = FluxGenerationRequest;
typedef FluxKontextResponse = FluxSubmitResponse;
typedef FluxKontextResult = FluxPollResult;

class FluxKontextService extends FluxBaseService {
  FluxKontextService({required super.apiKey})
      : super(baseUrl: 'https://api.bfl.ai/v1');

  @override
  String get submitPath => 'flux-kontext-pro';

  @override
  String get apiKeyHeader => 'x-key';

  @override
  String get fluxLabel => 'FLUX.1 Kontext';

  /// 轮询单次结果，参数为 [submit] 返回的完整 `polling_url`。
  @override
  Future<FluxPollResult> poll(String idOrUrl) async {
    final response = await http.get(
      Uri.parse(idOrUrl),
      headers: getHeaders(),
    );

    if (response.statusCode == 200) {
      return FluxPollResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception('Failed to poll result: ${response.statusCode}');
  }

  /// 兼容旧调用方暴露的公共方法名。
  Future<FluxPollResult> pollResult(String pollingUrl) => poll(pollingUrl);

  Future<String> generateImage({
    required String prompt,
    String? aspectRatio,
    int? seed,
    String? outputFormat = 'png',
    int? safetyTolerance,
    Duration maxWaitTime = const Duration(seconds: 60),
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    final request = FluxGenerationRequest(
      prompt: prompt,
      aspectRatio: aspectRatio,
      seed: seed,
      outputFormat: outputFormat,
      safetyTolerance: safetyTolerance,
    );
    final response = await submit(request);
    return waitForResult(response.pollingUrl, maxWaitTime, pollInterval);
  }

  Future<String> generateImageWithOpenAISize({
    required String prompt,
    required String openAISize,
    String? outputFormat = 'png',
    int? safetyTolerance,
    Duration maxWaitTime = const Duration(seconds: 120),
    Duration pollInterval = const Duration(seconds: 2),
  }) {
    return generateImage(
      prompt: prompt,
      aspectRatio:
          FluxBaseService.aspectRatioFromOpenAISize(openAISize) ?? '1:1',
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
    final request = FluxGenerationRequest(
      prompt: prompt,
      image: imageUrl,
      strength: strength,
      guidanceScale: guidanceScale,
      aspectRatio: aspectRatio,
    );
    final response = await submit(request);
    return waitForResult(response.pollingUrl, maxWaitTime, pollInterval);
  }

  Future<bool> testConnection() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$submitPath'),
        headers: getHeaders(),
        body: jsonEncode(const {
          'prompt': 'a simple test image',
          'aspect_ratio': '1:1',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.warning('[FLUX.1 Kontext] connection test failed: $e');
      return false;
    }
  }
}
