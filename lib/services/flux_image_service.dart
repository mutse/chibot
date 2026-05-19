import 'flux_kontext_service.dart';

// 旧的类型名以 typedef 形式重新导出，保留测试与外部引用。
typedef FluxSubmitResponse = FluxKontextResponse;
typedef FluxPollResponse = FluxKontextResult;

/// 历史保留的服务壳：内部委托给 [FluxKontextService]。
///
/// 测试和旧代码引用了这个类名 + 公共 [apiKey] getter，所以保留下来；
/// 实现已经合并到共享的 FLUX 基类中。
class FluxKontextImageService {
  FluxKontextImageService({required this.apiKey})
      : _delegate = FluxKontextService(apiKey: apiKey);

  final String apiKey;
  final FluxKontextService _delegate;

  Future<String> generateImage({
    required String prompt,
    String? aspectRatio = '1:1',
    int? seed,
    String? outputFormat = 'png',
    int? safetyTolerance,
    Duration maxWaitTime = const Duration(seconds: 60),
    Duration pollInterval = const Duration(seconds: 3),
  }) {
    if (apiKey.isEmpty) {
      throw Exception('FLUX.1 Kontext API key is required.');
    }
    if (prompt.isEmpty) {
      throw Exception('Prompt cannot be empty.');
    }
    return _delegate.generateImage(
      prompt: prompt,
      aspectRatio: aspectRatio,
      seed: seed,
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
    Duration pollInterval = const Duration(seconds: 3),
  }) {
    if (apiKey.isEmpty) {
      throw Exception('FLUX.1 Kontext API key is required.');
    }
    if (prompt.isEmpty) {
      throw Exception('Prompt cannot be empty.');
    }
    if (imageUrl.isEmpty) {
      throw Exception('Image URL cannot be empty.');
    }
    return _delegate.editImage(
      prompt: prompt,
      imageUrl: imageUrl,
      strength: strength,
      guidanceScale: guidanceScale,
      aspectRatio: aspectRatio,
      maxWaitTime: maxWaitTime,
      pollInterval: pollInterval,
    );
  }

  Future<bool> testConnection() => _delegate.testConnection();
}
