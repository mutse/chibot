/// 共享的 FLUX 请求/响应 DTO，用作 flux_kontext / flux_krea / flux_image
/// 服务的公共数据模型，避免在每个 service 文件中重新定义相同字段。
library;

/// 通用的 FLUX 图像生成请求体。
///
/// 三个 service（Kontext、Krea、Kontext-via-flux_image）都使用相同字段集合，
/// 只在 endpoint 和 header 上有差异。
class FluxGenerationRequest {
  const FluxGenerationRequest({
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

  final String prompt;
  final String? aspectRatio;
  final int? seed;
  final bool? promptUpsampling;
  final int? safetyTolerance;
  final String? outputFormat;
  final String? image;
  final double? strength;
  final double? guidanceScale;

  Map<String, dynamic> toJson() => {
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
}

/// FLUX 提交请求后返回的响应体（包含 polling URL）。
class FluxSubmitResponse {
  const FluxSubmitResponse({
    required this.id,
    required this.status,
    required this.pollingUrl,
  });

  final String id;
  final String status;
  final String pollingUrl;

  factory FluxSubmitResponse.fromJson(Map<String, dynamic> json) {
    return FluxSubmitResponse(
      id: (json['id'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      pollingUrl: (json['polling_url'] as String?) ?? '',
    );
  }
}

/// FLUX 轮询结果，包含生成完毕的图片 URL 或错误信息。
class FluxPollResult {
  const FluxPollResult({
    required this.status,
    this.sampleUrl,
    this.prompt,
    this.metadata,
    this.error,
  });

  final String status;
  final String? sampleUrl;
  final String? prompt;
  final Map<String, dynamic>? metadata;
  final String? error;

  factory FluxPollResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    final errorBlock = json['error'];
    return FluxPollResult(
      status: (json['status'] as String?) ?? 'pending',
      sampleUrl: result is Map<String, dynamic>
          ? result['sample'] as String?
          : null,
      prompt: result is Map<String, dynamic>
          ? result['prompt'] as String?
          : null,
      metadata: result is Map<String, dynamic>
          ? result['metadata'] as Map<String, dynamic>?
          : null,
      error: errorBlock is Map<String, dynamic>
          ? errorBlock['message'] as String?
          : null,
    );
  }
}
