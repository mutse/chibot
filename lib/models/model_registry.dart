import 'available_model.dart';

class ModelRegistry {
  final Map<ModelType, List<AvailableModel>> _models = {
    ModelType.text: [],
    ModelType.image: [],
    ModelType.customOpenAI: [],
  };

  // 缓存验证时间
  final Map<String, DateTime> _lastValidated = {};
  final Duration cacheTtl = const Duration(minutes: 5);

  List<AvailableModel> getModels({required ModelType type}) =>
      List.unmodifiable(_models[type] ?? []);

  void registerModel(AvailableModel model) {
    _models[model.type]?.removeWhere(
      (m) => m.id == model.id && m.provider == model.provider,
    );
    _models[model.type]?.add(model);
    _lastValidated[_buildValidationKey(model.id, model.provider)] =
        DateTime.now();
  }

  bool shouldRefresh(String modelId, {String? provider}) {
    final cacheKey =
        provider == null ? modelId : _buildValidationKey(modelId, provider);
    final lastValidated = _lastValidated[cacheKey];
    return lastValidated == null ||
        DateTime.now().difference(lastValidated) > cacheTtl;
  }

  void clearType(ModelType type) {
    _models[type]?.clear();
  }

  void clear() {
    for (var type in _models.keys) {
      _models[type]?.clear();
    }
    _lastValidated.clear();
  }

  String _buildValidationKey(String modelId, String provider) {
    return '$provider::$modelId';
  }
}
