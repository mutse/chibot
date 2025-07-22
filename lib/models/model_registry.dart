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
    _models[model.type]?.removeWhere((m) => m.id == model.id);
    _models[model.type]?.add(model);
    _lastValidated[model.id] = DateTime.now();
  }

  bool shouldRefresh(String modelId) {
    final lastValidated = _lastValidated[modelId];
    return lastValidated == null ||
        DateTime.now().difference(lastValidated) > cacheTtl;
  }

  void clear() {
    for (var type in _models.keys) {
      _models[type]?.clear();
    }
    _lastValidated.clear();
  }
}
