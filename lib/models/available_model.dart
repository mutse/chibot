enum ModelType { text, image, customOpenAI }

class AvailableModel {
  final String id;
  final String name;
  final String provider;
  final ModelType type;
  final bool supportsStreaming;
  final Map<String, dynamic> capabilities;
  final String? baseUrl;
  final String? apiVersion;

  AvailableModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.type,
    this.supportsStreaming = false,
    this.capabilities = const {},
    this.baseUrl,
    this.apiVersion,
  });
}
