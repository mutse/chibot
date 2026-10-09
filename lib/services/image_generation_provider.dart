/// 图像生成提供商的公共接口
///
/// 由 [ImageGenerationServiceFactory] 创建的所有图像生成服务都实现此接口，
/// 调用方可以依赖该接口而不是 `dynamic`。
///
/// 需要提供商特有能力（如 Google 的 openAISize 映射）时，调用方可将接口
/// 向下转型为具体服务类；通用调用直接使用本接口即可。
abstract class ImageGenerationProvider {
  /// 生成图像
  ///
  /// [prompt] 图像描述；[aspectRatio] 可选的宽高比。
  /// 成功返回图片 URL，失败时返回 null 或由实现抛异常。
  Future<String?> generateImage({
    required String prompt,
    String? aspectRatio,
  });
}
