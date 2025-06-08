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
  String get pleaseEnterPromptAfterImagine => 'Please enter a prompt after /imagine.';

  @override
  String get failedToGenerateImageNoUrl => 'Failed to generate image: No image URL returned.';

  @override
  String get errorLoadingImage => 'Error loading image.';

  @override
  String get noImageGenerated => 'No image generated.';

  @override
  String errorGeneratingImage(Object error) {
    return 'Error generating image: $error';
  }

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
  String get providerAndModelNameCannotBeEmpty => 'Provider name and model name cannot be empty.';
}
