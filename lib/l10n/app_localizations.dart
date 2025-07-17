import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('ja'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @selectModelProvider.
  ///
  /// In en, this message translates to:
  /// **'Select Model Provider:'**
  String get selectModelProvider;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @modelProviderURLOptional.
  ///
  /// In en, this message translates to:
  /// **'Model Provider URL (Optional):'**
  String get modelProviderURLOptional;

  /// No description provided for @defaultUrl.
  ///
  /// In en, this message translates to:
  /// **'Default: {url}'**
  String defaultUrl(Object url);

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'{provider} API Key:'**
  String apiKey(Object provider);

  /// No description provided for @enterYourAPIKey.
  ///
  /// In en, this message translates to:
  /// **'Enter your API Key'**
  String get enterYourAPIKey;

  /// No description provided for @selectModel.
  ///
  /// In en, this message translates to:
  /// **'Select Model:'**
  String get selectModel;

  /// No description provided for @noModelsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No models available for this provider'**
  String get noModelsAvailable;

  /// No description provided for @customModels.
  ///
  /// In en, this message translates to:
  /// **'Custom Models:'**
  String get customModels;

  /// No description provided for @enterCustomModelName.
  ///
  /// In en, this message translates to:
  /// **'Enter custom model name'**
  String get enterCustomModelName;

  /// No description provided for @yourCustomModels.
  ///
  /// In en, this message translates to:
  /// **'Your Custom Models:'**
  String get yourCustomModels;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved!'**
  String get settingsSaved;

  /// No description provided for @selectModelType.
  ///
  /// In en, this message translates to:
  /// **'Select Model Type:'**
  String get selectModelType;

  /// No description provided for @textModel.
  ///
  /// In en, this message translates to:
  /// **'Text Model'**
  String get textModel;

  /// No description provided for @imageModel.
  ///
  /// In en, this message translates to:
  /// **'Image Model'**
  String get imageModel;

  /// No description provided for @addNewModelConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Add New Model Configuration'**
  String get addNewModelConfiguration;

  /// No description provided for @modelProvider.
  ///
  /// In en, this message translates to:
  /// **'Model Provider'**
  String get modelProvider;

  /// No description provided for @enterProviderName.
  ///
  /// In en, this message translates to:
  /// **'Enter Provider Name'**
  String get enterProviderName;

  /// No description provided for @enterModelNames.
  ///
  /// In en, this message translates to:
  /// **'Enter model names (comma-separated)'**
  String get enterModelNames;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @chatWithAI.
  ///
  /// In en, this message translates to:
  /// **'Chat with AI'**
  String get chatWithAI;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @apiKeyNotSetError.
  ///
  /// In en, this message translates to:
  /// **'API Key not set. Please set it in settings.'**
  String get apiKeyNotSetError;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @chatGPTTitle.
  ///
  /// In en, this message translates to:
  /// **'Chibot Title'**
  String get chatGPTTitle;

  /// No description provided for @aiIsThinking.
  ///
  /// In en, this message translates to:
  /// **'AI is Thinking'**
  String get aiIsThinking;

  /// No description provided for @askAnyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask Any Question'**
  String get askAnyQuestion;

  /// No description provided for @addModelProvider.
  ///
  /// In en, this message translates to:
  /// **'Add Model Provider'**
  String get addModelProvider;

  /// No description provided for @providerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Provider Name Hint'**
  String get providerNameHint;

  /// No description provided for @modelsHint.
  ///
  /// In en, this message translates to:
  /// **'Models Hint'**
  String get modelsHint;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Chi AI Chatbot'**
  String get appTitle;

  /// No description provided for @noResponseFromAI.
  ///
  /// In en, this message translates to:
  /// **'AI did not return a response.'**
  String get noResponseFromAI;

  /// No description provided for @pleaseEnterPromptAfterImagine.
  ///
  /// In en, this message translates to:
  /// **'Please enter a prompt after /imagine.'**
  String get pleaseEnterPromptAfterImagine;

  /// No description provided for @failedToGenerateImageNoUrl.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate image: No image URL returned.'**
  String get failedToGenerateImageNoUrl;

  /// No description provided for @errorLoadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error loading image.'**
  String get errorLoadingImage;

  /// No description provided for @noImageGenerated.
  ///
  /// In en, this message translates to:
  /// **'No image generated.'**
  String get noImageGenerated;

  /// No description provided for @errorGeneratingImage.
  ///
  /// In en, this message translates to:
  /// **'Error generating image: {error}'**
  String errorGeneratingImage(Object error);

  /// No description provided for @saveImage.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get saveImage;

  /// No description provided for @imageGenerationSettings.
  ///
  /// In en, this message translates to:
  /// **'Image Generation Settings'**
  String get imageGenerationSettings;

  /// No description provided for @selectImageProvider.
  ///
  /// In en, this message translates to:
  /// **'Select Image Provider:'**
  String get selectImageProvider;

  /// No description provided for @imageProviderURLOptional.
  ///
  /// In en, this message translates to:
  /// **'Image Provider URL (Optional):'**
  String get imageProviderURLOptional;

  /// No description provided for @enterImageProviderURL.
  ///
  /// In en, this message translates to:
  /// **'Enter image provider URL'**
  String get enterImageProviderURL;

  /// No description provided for @selectImageModel.
  ///
  /// In en, this message translates to:
  /// **'Select Image Model:'**
  String get selectImageModel;

  /// No description provided for @customImageModels.
  ///
  /// In en, this message translates to:
  /// **'Custom Image Models:'**
  String get customImageModels;

  /// No description provided for @enterCustomImageModelName.
  ///
  /// In en, this message translates to:
  /// **'Enter custom image model name'**
  String get enterCustomImageModelName;

  /// No description provided for @providerAndModelAdded.
  ///
  /// In en, this message translates to:
  /// **'Provider and model added!'**
  String get providerAndModelAdded;

  /// No description provided for @providerAndModelNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Provider name and model name cannot be empty.'**
  String get providerAndModelNameCannotBeEmpty;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @imageGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image generated successfully!'**
  String get imageGeneratedSuccessfully;

  /// No description provided for @newImageSession.
  ///
  /// In en, this message translates to:
  /// **'New Image Session'**
  String get newImageSession;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Chibot AI'**
  String get appName;

  /// No description provided for @appDesc.
  ///
  /// In en, this message translates to:
  /// **'Smart Chat Assistant'**
  String get appDesc;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version v0.1.3'**
  String get version;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'July 2025'**
  String get releaseDate;

  /// No description provided for @featureSmartChat.
  ///
  /// In en, this message translates to:
  /// **'Smart Chat'**
  String get featureSmartChat;

  /// No description provided for @featureSmartDesc.
  ///
  /// In en, this message translates to:
  /// **'Supports multiple AI models for natural conversations.'**
  String get featureSmartDesc;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @featureImageGen.
  ///
  /// In en, this message translates to:
  /// **'Text-to-Image'**
  String get featureImageGen;

  /// No description provided for @featureImageGenDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate beautiful images from text prompts.'**
  String get featureImageGenDesc;

  /// No description provided for @featureFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible Configuration'**
  String get featureFlexible;

  /// No description provided for @featureFlexibleDesc.
  ///
  /// In en, this message translates to:
  /// **'Supports multiple model providers and custom settings.'**
  String get featureFlexibleDesc;

  /// No description provided for @textChat.
  ///
  /// In en, this message translates to:
  /// **'Text chat'**
  String get textChat;

  /// No description provided for @textImage.
  ///
  /// In en, this message translates to:
  /// **'Text to image'**
  String get textImage;

  /// No description provided for @supportModels.
  ///
  /// In en, this message translates to:
  /// **'Support Models'**
  String get supportModels;

  /// No description provided for @usageHelp.
  ///
  /// In en, this message translates to:
  /// **'Usage Help'**
  String get usageHelp;

  /// No description provided for @userManual.
  ///
  /// In en, this message translates to:
  /// **'User Manual'**
  String get userManual;

  /// No description provided for @problemFeedback.
  ///
  /// In en, this message translates to:
  /// **'Problem Feedback'**
  String get problemFeedback;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsService;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get disclaimer;

  /// No description provided for @legalInfo.
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get legalInfo;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2025 Chibot AI. All rights reserved.'**
  String get copyright;

  /// No description provided for @vision.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ for better AI experience'**
  String get vision;

  /// No description provided for @tavilyApiKeyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Tavily API Key is not set. Please go to the settings page to fill it in before using the Web Search feature.'**
  String get tavilyApiKeyNotSet;

  /// No description provided for @webSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please answer the question using the following web search results:\n{webResult}\nUser question: {userQuestion}'**
  String webSearchPrompt(Object userQuestion, Object webResult);

  /// No description provided for @webSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Web search failed: {error}'**
  String webSearchFailed(Object error);

  /// No description provided for @trayShowHide.
  ///
  /// In en, this message translates to:
  /// **'Show/Hide'**
  String get trayShowHide;

  /// No description provided for @trayExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get trayExit;

  /// No description provided for @saveToDirectory.
  ///
  /// In en, this message translates to:
  /// **'Save to directory'**
  String get saveToDirectory;

  /// No description provided for @exportConfig.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportConfig;

  /// No description provided for @importConfig.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importConfig;

  /// No description provided for @exportToMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export to Markdown'**
  String get exportToMarkdown;

  /// No description provided for @exportAllChats.
  ///
  /// In en, this message translates to:
  /// **'Export All Chats'**
  String get exportAllChats;

  /// No description provided for @exportSingleChat.
  ///
  /// In en, this message translates to:
  /// **'Export Chat'**
  String get exportSingleChat;

  /// No description provided for @noChatSessionsToExport.
  ///
  /// In en, this message translates to:
  /// **'No chat sessions to export'**
  String get noChatSessionsToExport;

  /// No description provided for @chatExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Chat exported successfully'**
  String get chatExportedSuccessfully;

  /// No description provided for @exportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get exportCancelled;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @exportToImg.
  ///
  /// In en, this message translates to:
  /// **'Export to Image'**
  String get exportToImg;

  /// No description provided for @updateFound.
  ///
  /// In en, this message translates to:
  /// **'New version {version} found'**
  String updateFound(Object version);

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @promptCopied.
  ///
  /// In en, this message translates to:
  /// **'Copy Prompt'**
  String get promptCopied;

  /// No description provided for @savePrompt.
  ///
  /// In en, this message translates to:
  /// **'Save Prompt'**
  String get savePrompt;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
