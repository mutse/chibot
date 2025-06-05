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
  String get chatGPTTitle => 'ChatGPT Title';

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
}
