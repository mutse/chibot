import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/logger.dart';
import '../base_api_service.dart';
import 'flux_dtos.dart';

/// FLUX 系列图像服务的共享基类。
///
/// 子类提供 endpoint、header、轮询地址等差异化配置；
/// 提交、轮询、错误处理、size 映射等逻辑都集中在这里。
abstract class FluxBaseService extends BaseApiService {
  FluxBaseService({required super.apiKey, required super.baseUrl});

  /// 提交请求时使用的相对路径，例如 `flux-kontext-pro`、`v1/flux-krea-dev`。
  String get submitPath;

  /// API Key 写入的 header 名（Kontext 用 `x-key`，Krea 用 `X-Key`）。
  String get apiKeyHeader;

  /// 在日志和异常文案中使用的可读 label，例如 `FLUX.1 Kontext`。
  String get fluxLabel;

  @override
  String get providerName => fluxLabel;

  @override
  Map<String, String> getHeaders() => {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        apiKeyHeader: apiKey,
      };

  @override
  void validateResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$fluxLabel API error: ${enrichHttpError(
        response.statusCode,
        response.body,
      )}');
    }
  }

  /// 由 `'1024x1024'` 形式的 OpenAI 尺寸推导出 FLUX aspect ratio。
  /// 未匹配时返回 null，由调用方决定默认值。
  static String? aspectRatioFromOpenAISize(String openAISize) {
    switch (openAISize) {
      case '1024x1024':
        return '1:1';
      case '1792x1024':
        return '16:9';
      case '1024x1792':
        return '9:16';
      default:
        return null;
    }
  }

  /// 把 HTTP 错误体加工成用户可读的文案。
  String enrichHttpError(int statusCode, String responseBody) {
    String detail = 'HTTP $statusCode';
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err is String) {
          detail = err;
        } else if (err is Map<String, dynamic>) {
          detail = (err['message'] as String?) ?? detail;
        } else if (decoded['message'] is String) {
          detail = decoded['message'] as String;
        } else if (decoded['errors'] != null) {
          detail = decoded['errors'].toString();
        }
      }
    } catch (_) {
      if (responseBody.isNotEmpty) detail = responseBody;
    }

    switch (statusCode) {
      case 400:
        return 'Bad request (400). Invalid prompt or parameters: $detail';
      case 401:
        return 'Authentication failed (401). Please verify your API key is valid and active.';
      case 403:
        return 'Access forbidden (403). Your API key may not have permission for FLUX.1 models.';
      case 429:
        return 'Rate limit exceeded (429). Please wait before making more requests.';
      case 500:
        return 'Server error (500). Please try again later.';
      default:
        return detail;
    }
  }

  /// 子类提交请求后可以重写此方法做额外校验（例如 Krea 检查 pending/processing）。
  void validateSubmitResponse(Map<String, dynamic> body) {}

  /// 提交一个生成请求并解析为 [FluxSubmitResponse]。
  Future<FluxSubmitResponse> submit(FluxGenerationRequest request) async {
    if (apiKey.isEmpty) {
      throw Exception(
        '$fluxLabel API key is empty. Please configure your API key in settings.',
      );
    }

    final url = Uri.parse('$baseUrl/$submitPath');
    final body = jsonEncode(request.toJson());
    AppLogger.debug('[$fluxLabel] POST $url body=$body');

    final response = await http.post(url, headers: getHeaders(), body: body);
    AppLogger.debug(
      '[$fluxLabel] submit status=${response.statusCode} body=${response.body}',
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      validateSubmitResponse(json);
      return FluxSubmitResponse.fromJson(json);
    }

    throw Exception('$fluxLabel API error: ${enrichHttpError(
      response.statusCode,
      response.body,
    )}');
  }

  /// 轮询单次结果。`idOrUrl` 可以是完整 polling URL，也可以是 request id（视子类而定）。
  Future<FluxPollResult> poll(String idOrUrl);

  /// 反复轮询直到结果就绪、失败或超时。返回成功生成的图像 URL。
  Future<String> waitForResult(
    String idOrUrl,
    Duration maxWaitTime,
    Duration pollInterval,
  ) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < maxWaitTime) {
      try {
        final result = await poll(idOrUrl);
        final status = result.status.toLowerCase();

        if (status == 'ready') {
          final url = result.sampleUrl;
          if (url != null && url.isNotEmpty) {
            return url;
          }
          throw Exception('$fluxLabel returned no image URL');
        }

        if (status == 'error' || status == 'failed') {
          throw Exception(
            '$fluxLabel generation failed: ${result.error ?? "Unknown error"}',
          );
        }
      } catch (e) {
        final errString = e.toString();
        if (errString.contains('Task not found') ||
            errString.contains('invalid or expired') ||
            errString.contains('generation failed') ||
            errString.contains('returned no image URL')) {
          rethrow;
        }
        AppLogger.warning('[$fluxLabel] transient polling error: $e');
      }

      await Future.delayed(pollInterval);
    }

    throw Exception(
      '$fluxLabel generation timed out after ${maxWaitTime.inSeconds} seconds',
    );
  }
}
