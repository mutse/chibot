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
  String get selectModelType => '选择模型类型:';

  @override
  String get textModel => '文本模型';

  @override
  String get imageModel => '图像模型';

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
  String get chatGPTTitle => 'Chibot 标题';

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

  @override
  String get noResponseFromAI => 'AI 未返回响应。';

  @override
  String get pleaseEnterPromptAfterImagine => '请在 /imagine 后输入提示。';

  @override
  String get failedToGenerateImageNoUrl =>
      'Failed to generate image: No image URL returned.';

  @override
  String get errorLoadingImage => 'Error loading image.';

  @override
  String get noImageGenerated => 'No image generated.';

  @override
  String errorGeneratingImage(Object error) {
    return 'Error generating image: $error';
  }

  @override
  String get saveImage => '保存图片';

  @override
  String get imageGenerationSettings => 'Image Generation Settings';

  @override
  String get selectImageProvider => 'Select Image Provider:';

  @override
  String get imageProviderURLOptional => 'Image Provider URL (Optional):';

  @override
  String get enterImageProviderURL => 'Enter image provider URL';

  @override
  String get selectImageModel => 'Select Image Model:';

  @override
  String get customImageModels => 'Custom Image Models:';

  @override
  String get enterCustomImageModelName => 'Enter custom image model name';

  @override
  String get providerAndModelAdded => 'Provider and model added!';

  @override
  String get providerAndModelNameCannotBeEmpty =>
      'Provider name and model name cannot be empty.';

  @override
  String get newChat => 'New Chat';

  @override
  String get imageGeneratedSuccessfully => '图片生成成功！';

  @override
  String get newImageSession => '新图片会话';

  @override
  String get appName => 'Chibot AI';

  @override
  String get appDesc => '智能聊天助手';

  @override
  String get version => '版本 v0.1.3';

  @override
  String get releaseDate => '2025年7月';

  @override
  String get featureSmartChat => '智能聊天';

  @override
  String get featureSmartDesc => '支持多种AI模型，提供自然流畅的对话体验。';

  @override
  String get features => '功能特色';

  @override
  String get featureImageGen => '文生图';

  @override
  String get featureImageGenDesc => '将文字描述转换为精美图片。';

  @override
  String get featureFlexible => '灵活配置';

  @override
  String get featureFlexibleDesc => '支持多种模型提供商和自定义配置。';

  @override
  String get textChat => '文字对话';

  @override
  String get textImage => '文生图';

  @override
  String get supportModels => '支持的模型';

  @override
  String get usageHelp => '使用帮助';

  @override
  String get userManual => '用户手册';

  @override
  String get problemFeedback => '问题反馈';

  @override
  String get contact => '联系我们';

  @override
  String get helpSupport => '帮助支持';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsService => '服务条款';

  @override
  String get disclaimer => '免责申明';

  @override
  String get legalInfo => '法律信息';

  @override
  String get copyright => '© 2025 Chibot AI. 版权所有';

  @override
  String get vision => '用 ❤️ 打造更佳 AI 体验';

  @override
  String get tavilyApiKeyNotSet => 'Tavily API Key 未设置，请前往设置页面填写后再使用 Web 搜索功能。';

  @override
  String webSearchPrompt(Object userQuestion, Object webResult) {
    return '请结合以下网络搜索结果回答问题：\n$webResult\n用户提问：$userQuestion';
  }

  @override
  String webSearchFailed(Object error) {
    return 'Web 搜索失败：$error';
  }

  @override
  String get trayShowHide => '显示/隐藏';

  @override
  String get trayExit => '退出';

  @override
  String get saveToDirectory => '保存至目录';

  @override
  String get exportConfig => '导出';

  @override
  String get importConfig => '导入';

  @override
  String get exportToMarkdown => '导出为 Markdown';

  @override
  String get exportAllChats => '导出所有聊天记录';

  @override
  String get exportSingleChat => '导出聊天记录';

  @override
  String get noChatSessionsToExport => '没有聊天记录可导出';

  @override
  String get chatExportedSuccessfully => '聊天记录导出成功';

  @override
  String get exportCancelled => '取消导出';

  @override
  String get exportFailed => '导出失败';
}
