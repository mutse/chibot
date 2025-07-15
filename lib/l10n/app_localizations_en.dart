// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get selectModelProvider => 'Select Model Provider:';

  @override
  String get add => 'Add';

  @override
  String get modelProviderURLOptional => 'Model Provider URL (Optional):';

  @override
  String defaultUrl(Object url) {
    return 'Default: $url';
  }

  @override
  String apiKey(Object provider) {
    return '$provider API Key:';
  }

  @override
  String get enterYourAPIKey => 'Enter your API Key';

  @override
  String get selectModel => 'Select Model:';

  @override
  String get noModelsAvailable => 'No models available for this provider';

  @override
  String get customModels => 'Custom Models:';

  @override
  String get enterCustomModelName => 'Enter custom model name';

  @override
  String get yourCustomModels => 'Your Custom Models:';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get settingsSaved => 'Settings saved!';

  @override
  String get selectModelType => 'Select Model Type:';

  @override
  String get textModel => 'Text Model';

  @override
  String get imageModel => 'Image Model';

  @override
  String get addNewModelConfiguration => 'Add New Model Configuration';

  @override
  String get modelProvider => 'Model Provider';

  @override
  String get enterProviderName => 'Enter Provider Name';

  @override
  String get enterModelNames => 'Enter model names (comma-separated)';

  @override
  String get cancel => 'Cancel';

  @override
  String get chatWithAI => 'Chat with AI';

  @override
  String get typeYourMessage => 'Type your message...';

  @override
  String get custom => 'Custom';

  @override
  String get apiKeyNotSetError => 'API Key not set. Please set it in settings.';

  @override
  String get search => 'Search';

  @override
  String get about => 'About';

  @override
  String get chatGPTTitle => 'Chibot Title';

  @override
  String get aiIsThinking => 'AI is Thinking';

  @override
  String get askAnyQuestion => 'Ask Any Question';

  @override
  String get addModelProvider => 'Add Model Provider';

  @override
  String get providerNameHint => 'Provider Name Hint';

  @override
  String get modelsHint => 'Models Hint';

  @override
  String get appTitle => 'Chi AI Chatbot';

  @override
  String get noResponseFromAI => 'AI did not return a response.';

  @override
  String get pleaseEnterPromptAfterImagine =>
      'Please enter a prompt after /imagine.';

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
  String get saveImage => 'Save image';

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
  String get imageGeneratedSuccessfully => 'Image generated successfully!';

  @override
  String get newImageSession => 'New Image Session';

  @override
  String get appName => 'Chibot AI';

  @override
  String get appDesc => 'Smart Chat Assistant';

  @override
  String get version => 'Version v0.1.3';

  @override
  String get releaseDate => 'July 2025';

  @override
  String get featureSmartChat => 'Smart Chat';

  @override
  String get featureSmartDesc =>
      'Supports multiple AI models for natural conversations.';

  @override
  String get features => 'Features';

  @override
  String get featureImageGen => 'Text-to-Image';

  @override
  String get featureImageGenDesc =>
      'Generate beautiful images from text prompts.';

  @override
  String get featureFlexible => 'Flexible Configuration';

  @override
  String get featureFlexibleDesc =>
      'Supports multiple model providers and custom settings.';

  @override
  String get textChat => 'Text chat';

  @override
  String get textImage => 'Text to image';

  @override
  String get supportModels => 'Support Models';

  @override
  String get usageHelp => 'Usage Help';

  @override
  String get userManual => 'User Manual';

  @override
  String get problemFeedback => 'Problem Feedback';

  @override
  String get contact => 'Contact';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsService => 'Terms of Service';

  @override
  String get disclaimer => 'Disclaimer';

  @override
  String get legalInfo => 'Legal Information';

  @override
  String get copyright => '© 2025 Chibot AI. All rights reserved.';

  @override
  String get vision => 'Made with ❤️ for better AI experience';

  @override
  String get tavilyApiKeyNotSet =>
      'Tavily API Key is not set. Please go to the settings page to fill it in before using the Web Search feature.';

  @override
  String webSearchPrompt(Object userQuestion, Object webResult) {
    return 'Please answer the question using the following web search results:\n$webResult\nUser question: $userQuestion';
  }

  @override
  String webSearchFailed(Object error) {
    return 'Web search failed: $error';
  }

  @override
  String get trayShowHide => 'Show/Hide';

  @override
  String get trayExit => 'Exit';

  @override
  String get saveToDirectory => 'Save to directory';

  @override
  String get exportConfig => 'Export';

  @override
  String get importConfig => 'Import';

  @override
  String get exportToMarkdown => 'Export to Markdown';

  @override
  String get exportAllChats => 'Export All Chats';

  @override
  String get exportSingleChat => 'Export Chat';

  @override
  String get noChatSessionsToExport => 'No chat sessions to export';

  @override
  String get chatExportedSuccessfully => 'Chat exported successfully';

  @override
  String get exportCancelled => 'Export cancelled';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get exportToImg => 'Export to Image';
}
