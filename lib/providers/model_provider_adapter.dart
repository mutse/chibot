import '../models/available_model.dart';
import '../models/model_registry.dart';

class ModelProviderAdapter {
  final ModelRegistry registry;

  ModelProviderAdapter(this.registry);

  List<AvailableModel> getModelsForProvider(String provider) {
    return registry
        .getModels(type: ModelType.text)
        .where((m) => m.provider == provider)
        .toList();
  }

  List<AvailableModel> getTextModels() =>
      registry.getModels(type: ModelType.text);

  List<AvailableModel> getImageModels() =>
      registry.getModels(type: ModelType.image);

  List<AvailableModel> getCustomModels() =>
      registry.getModels(type: ModelType.customOpenAI);
}
