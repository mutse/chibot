import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/logger.dart';
import 'flux/flux_base_service.dart';
import 'flux/flux_dtos.dart';

// 旧的类型名以 typedef 形式重新导出。
typedef FluxKreaRequest = FluxGenerationRequest;
typedef FluxKreaResponse = FluxSubmitResponse;
typedef FluxKreaResult = FluxPollResult;

class FluxKreaService extends FluxBaseService {
  FluxKreaService({required super.apiKey}) : super(baseUrl: 'https://api.bfl.ai');

  @override
  String get submitPath => 'v1/flux-krea-dev';

  @override
  String get apiKeyHeader => 'X-Key';

  @override
  String get fluxLabel => 'FLUX.1 Krea';

  static const String _pollPath = 'v1/get_result';

  /// 与 Kontext 不同：Krea 在提交时若立刻返回失败，需要立即抛出。
  @override
  void validateSubmitResponse(Map<String, dynamic> body) {
    final id = body['id'];
    if (id == null || (id is String && id.isEmpty)) {
      throw Exception('Invalid response: Missing or empty request ID');
    }

    final status = body['status'];
    if (status == 'error' || status == 'failed') {
      final details = body['details'];
      final detailMessage = details is Map<String, dynamic>
          ? details['error']?.toString()
          : null;
      throw Exception(
        'Request failed immediately: ${detailMessage ?? 'Request failed'}',
      );
    }
  }

  /// Krea 通过 `?id=requestId` 轮询。[idOrUrl] 应该是 request id。
  @override
  Future<FluxPollResult> poll(String idOrUrl) async {
    final url = Uri.parse('$baseUrl/$_pollPath')
        .replace(queryParameters: {'id': idOrUrl});

    final response = await http.get(url, headers: getHeaders());

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (json['status'] as String?) ?? '';

      if (status == 'Task not found') {
        throw Exception(
          'Task not found: Request ID $idOrUrl may be invalid or expired',
        );
      }
      if (status == 'Error') {
        final details = json['details'];
        final errorMsg = details is Map<String, dynamic>
            ? details['error']?.toString()
            : null;
        throw Exception('Task failed: ${errorMsg ?? 'Unknown error'}');
      }

      return FluxPollResult.fromJson(json);
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Task not found (404): Request ID $idOrUrl may be invalid or expired',
      );
    }

    throw Exception(
      'Failed to poll result: ${enrichHttpError(response.statusCode, response.body)}',
    );
  }

  /// 兼容旧调用方暴露的公共方法名。
  Future<FluxPollResult> pollResult(String requestId) => poll(requestId);

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
    return waitForResult(response.id, maxWaitTime, pollInterval);
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
    return waitForResult(response.id, maxWaitTime, pollInterval);
  }

  Future<bool> testConnection() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/flux-dev'),
        headers: getHeaders(),
        body: jsonEncode(const {
          'prompt': 'a simple test image',
          'aspect_ratio': '1:1',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.warning('[FLUX.1 Krea] connection test failed: $e');
      return false;
    }
  }
}
