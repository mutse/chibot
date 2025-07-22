import 'package:flutter/foundation.dart';
import '../models/model_registry.dart';
import '../models/available_model.dart';

class SettingsModelsProvider extends ChangeNotifier {
  final ModelRegistry _registry;

  SettingsModelsProvider(this._registry);

  List<AvailableModel> get textModels =>
      _registry.getModels(type: ModelType.text);

  List<AvailableModel> get imageModels =>
      _registry.getModels(type: ModelType.image);

  List<AvailableModel> get customModels =>
      _registry.getModels(type: ModelType.customOpenAI);

  // 可扩展：刷新、验证、通知等
  void refreshModels() {
    // TODO: 实现模型刷新逻辑
    notifyListeners();
  }
}
