// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settings => '设置';

  @override
  String get selectModelProvider => '选择模型提供商：';

  @override
  String get add => '添加';

  @override
  String get modelProviderURLOptional => '模型提供商 URL (可选)：';

  @override
  String defaultUrl(Object url) {
    return '默认：$url';
  }

  @override
  String apiKey(Object provider) {
    return '$provider API 密钥：';
  }

  @override
  String get enterYourAPIKey => '输入您的 API 密钥';

  @override
  String get selectModel => '选择模型：';

  @override
  String get noModelsAvailable => '此提供商无可用模型';

  @override
  String get customModels => '自定义模型：';

  @override
  String get enterCustomModelName => '输入自定义模型名称';

  @override
  String get yourCustomModels => '您的自定义模型：';

  @override
  String get saveSettings => '保存设置';

  @override
  String get settingsSaved => '设置已保存！';

  @override
  String get addNewModelConfiguration => '添加新的模型配置';

  @override
  String get modelProvider => '模型提供商';

  @override
  String get enterProviderName => '输入提供商名称';

  @override
  String get enterModelNames => '输入模型名称 (逗号分隔)';

  @override
  String get cancel => '取消';

  @override
  String get chatWithAI => '与 AI 聊天';

  @override
  String get typeYourMessage => '输入您的消息...';

  @override
  String get custom => '自定义';

  @override
  String get apiKeyNotSetError => 'API 密钥未设置。请在设置中进行设置。';

  @override
  String get search => '搜索';

  @override
  String get about => '关于';

  @override
  String get chatGPTTitle => 'ChatGPT 标题';

  @override
  String get aiIsThinking => 'AI 正在思考中';

  @override
  String get askAnyQuestion => '提问任一问题';

  @override
  String get addModelProvider => '添加模型提供商';

  @override
  String get providerNameHint => '提供商名称提示';

  @override
  String get modelsHint => '模型提示';

  @override
  String get appTitle => 'Chi AI Chatbot';
}
