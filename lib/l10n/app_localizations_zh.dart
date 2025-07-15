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

  @override
  String get exportToImg => '导出图片';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get settings => '設定';

  @override
  String get selectModelProvider => '選擇模型提供者：';

  @override
  String get add => '新增';

  @override
  String get modelProviderURLOptional => '模型提供者網址（可選）：';

  @override
  String defaultUrl(Object url) {
    return '預設：$url';
  }

  @override
  String apiKey(Object provider) {
    return '$provider API 金鑰：';
  }

  @override
  String get enterYourAPIKey => '請輸入您的 API 金鑰';

  @override
  String get selectModel => '選擇模型：';

  @override
  String get noModelsAvailable => '此提供者沒有可用模型';

  @override
  String get customModels => '自訂模型：';

  @override
  String get enterCustomModelName => '輸入自訂模型名稱';

  @override
  String get yourCustomModels => '您的自訂模型：';

  @override
  String get saveSettings => '儲存設定';

  @override
  String get settingsSaved => '設定已儲存！';

  @override
  String get selectModelType => '選擇模型類型：';

  @override
  String get textModel => '文字模型';

  @override
  String get imageModel => '圖像模型';

  @override
  String get addNewModelConfiguration => '新增模型配置';

  @override
  String get modelProvider => '模型提供者';

  @override
  String get enterProviderName => '輸入提供者名稱';

  @override
  String get enterModelNames => '輸入模型名稱（以逗號分隔）';

  @override
  String get cancel => '取消';

  @override
  String get chatWithAI => '與 AI 對話';

  @override
  String get typeYourMessage => '輸入您的訊息...';

  @override
  String get custom => '自訂';

  @override
  String get apiKeyNotSetError => '未設定 API 金鑰。請在設定中進行設定。';

  @override
  String get search => '搜尋';

  @override
  String get about => '關於';

  @override
  String get chatGPTTitle => 'Chibot 標題';

  @override
  String get aiIsThinking => 'AI 正在思考';

  @override
  String get askAnyQuestion => '詢問任何問題';

  @override
  String get addModelProvider => '新增模型提供者';

  @override
  String get providerNameHint => '提供者名稱提示';

  @override
  String get modelsHint => '模型提示';

  @override
  String get appTitle => 'Chi AI 聊天機器人';

  @override
  String get noResponseFromAI => 'AI 沒有回應。';

  @override
  String get pleaseEnterPromptAfterImagine => '請在 /imagine 後輸入提示詞。';

  @override
  String get failedToGenerateImageNoUrl => '圖像生成失敗：未返回圖像網址。';

  @override
  String get errorLoadingImage => '圖像載入錯誤。';

  @override
  String get noImageGenerated => '未生成圖像。';

  @override
  String errorGeneratingImage(Object error) {
    return '圖像生成錯誤：$error';
  }

  @override
  String get saveImage => '儲存圖像';

  @override
  String get imageGenerationSettings => '圖像生成設定';

  @override
  String get selectImageProvider => '選擇圖像提供者：';

  @override
  String get imageProviderURLOptional => '圖像提供者網址（可選）：';

  @override
  String get enterImageProviderURL => '輸入圖像提供者網址';

  @override
  String get selectImageModel => '選擇圖像模型：';

  @override
  String get customImageModels => '自訂圖像模型：';

  @override
  String get enterCustomImageModelName => '輸入自訂圖像模型名稱';

  @override
  String get providerAndModelAdded => '提供者和模型已新增！';

  @override
  String get providerAndModelNameCannotBeEmpty => '提供者名稱和模型名稱不能為空。';

  @override
  String get newChat => '新聊天';

  @override
  String get imageGeneratedSuccessfully => '圖像生成成功！';

  @override
  String get newImageSession => '新圖像工作階段';

  @override
  String get appName => 'Chibot AI';

  @override
  String get appDesc => '智能聊天助手';

  @override
  String get version => '版本 v0.1.3';

  @override
  String get releaseDate => '2025年7月';

  @override
  String get featureSmartChat => '智能對話';

  @override
  String get featureSmartDesc => '支援多種 AI 模型進行自然對話。';

  @override
  String get features => '功能';

  @override
  String get featureImageGen => '文字轉圖像';

  @override
  String get featureImageGenDesc => '從文字提示生成美麗的圖像。';

  @override
  String get featureFlexible => '彈性配置';

  @override
  String get featureFlexibleDesc => '支援多種模型提供者和自訂設定。';

  @override
  String get textChat => '文字聊天';

  @override
  String get textImage => '文字轉圖像';

  @override
  String get supportModels => '支援模型';

  @override
  String get usageHelp => '使用說明';

  @override
  String get userManual => '使用手冊';

  @override
  String get problemFeedback => '問題回饋';

  @override
  String get contact => '聯絡我們';

  @override
  String get helpSupport => '說明與支援';

  @override
  String get privacyPolicy => '隱私政策';

  @override
  String get termsService => '服務條款';

  @override
  String get disclaimer => '免責聲明';

  @override
  String get legalInfo => '法律資訊';

  @override
  String get copyright => '© 2025 Chibot AI. 版權所有。';

  @override
  String get vision => '用 ❤️ 打造更好的 AI 體驗';

  @override
  String get tavilyApiKeyNotSet => 'Tavily API 金鑰未設定。請前往設定頁面填寫後再使用網路搜尋功能。';

  @override
  String webSearchPrompt(Object userQuestion, Object webResult) {
    return '請使用以下網路搜尋結果回答問題：\n$webResult\n使用者問題：$userQuestion';
  }

  @override
  String webSearchFailed(Object error) {
    return '網路搜尋失敗：$error';
  }

  @override
  String get trayShowHide => '顯示/隱藏';

  @override
  String get trayExit => '退出';

  @override
  String get saveToDirectory => '儲存到目錄';

  @override
  String get exportConfig => '匯出';

  @override
  String get importConfig => '匯入';

  @override
  String get exportToMarkdown => '匯出為 Markdown';

  @override
  String get exportAllChats => '匯出所有聊天';

  @override
  String get exportSingleChat => '匯出聊天';

  @override
  String get noChatSessionsToExport => '沒有聊天工作階段可匯出';

  @override
  String get chatExportedSuccessfully => '聊天匯出成功';

  @override
  String get exportCancelled => '匯出已取消';

  @override
  String get exportFailed => '匯出失敗';
}
