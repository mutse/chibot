// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settings => 'Einstellungen';

  @override
  String get selectModelProvider => 'Modellanbieter auswählen:';

  @override
  String get add => 'Hinzufügen';

  @override
  String get modelProviderURLOptional => 'Modellanbieter-URL (optional):';

  @override
  String defaultUrl(Object url) {
    return 'Standard: $url';
  }

  @override
  String apiKey(Object provider) {
    return '$provider API-Schlüssel:';
  }

  @override
  String get enterYourAPIKey => 'Geben Sie Ihren API-Schlüssel ein';

  @override
  String get selectModel => 'Modell auswählen:';

  @override
  String get noModelsAvailable => 'Keine Modelle für diesen Anbieter verfügbar';

  @override
  String get customModels => 'Benutzerdefinierte Modelle:';

  @override
  String get enterCustomModelName => 'Benutzerdefinierten Modellnamen eingeben';

  @override
  String get yourCustomModels => 'Ihre benutzerdefinierten Modelle:';

  @override
  String get saveSettings => 'Einstellungen speichern';

  @override
  String get settingsSaved => 'Einstellungen gespeichert!';

  @override
  String get selectModelType => 'Modelltyp auswählen:';

  @override
  String get textModel => 'Textmodell';

  @override
  String get imageModel => 'Bildmodell';

  @override
  String get addNewModelConfiguration => 'Neue Modellkonfiguration hinzufügen';

  @override
  String get modelProvider => 'Modellanbieter';

  @override
  String get enterProviderName => 'Anbietername eingeben';

  @override
  String get enterModelNames => 'Modellnamen eingeben (durch Kommas getrennt)';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get chatWithAI => 'Mit KI chatten';

  @override
  String get typeYourMessage => 'Geben Sie Ihre Nachricht ein...';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get apiKeyNotSetError =>
      'API-Schlüssel nicht gesetzt. Bitte in den Einstellungen festlegen.';

  @override
  String get search => 'Suchen';

  @override
  String get about => 'Über';

  @override
  String get chatGPTTitle => 'Chibot Titel';

  @override
  String get aiIsThinking => 'KI denkt nach';

  @override
  String get askAnyQuestion => 'Stellen Sie eine beliebige Frage';

  @override
  String get addModelProvider => 'Modellanbieter hinzufügen';

  @override
  String get providerNameHint => 'Anbieter-Name-Hinweis';

  @override
  String get modelsHint => 'Modell-Hinweis';

  @override
  String get appTitle => 'Chi AI Chatbot';

  @override
  String get noResponseFromAI => 'KI hat keine Antwort zurückgegeben.';

  @override
  String get pleaseEnterPromptAfterImagine =>
      'Bitte geben Sie eine Eingabe nach /imagine ein.';

  @override
  String get failedToGenerateImageNoUrl =>
      'Fehler beim Generieren des Bildes: Keine Bild-URL zurückgegeben.';

  @override
  String get errorLoadingImage => 'Fehler beim Laden des Bildes.';

  @override
  String get noImageGenerated => 'Kein Bild generiert.';

  @override
  String errorGeneratingImage(Object error) {
    return 'Fehler beim Generieren des Bildes: $error';
  }

  @override
  String get saveImage => 'Bild speichern';

  @override
  String get imageGenerationSettings => 'Bildgenerierungseinstellungen';

  @override
  String get selectImageProvider => 'Bildanbieter auswählen:';

  @override
  String get imageProviderURLOptional => 'Bildanbieter-URL (optional):';

  @override
  String get enterImageProviderURL => 'Bildanbieter-URL eingeben';

  @override
  String get selectImageModel => 'Bildmodell auswählen:';

  @override
  String get customImageModels => 'Benutzerdefinierte Bildmodelle:';

  @override
  String get enterCustomImageModelName =>
      'Benutzerdefinierten Bildmodellnamen eingeben';

  @override
  String get providerAndModelAdded => 'Anbieter und Modell hinzugefügt!';

  @override
  String get providerAndModelNameCannotBeEmpty =>
      'Anbietername und Modellname dürfen nicht leer sein.';

  @override
  String get newChat => 'Neuer Chat';

  @override
  String get imageGeneratedSuccessfully => 'Bild erfolgreich generiert!';

  @override
  String get newImageSession => 'Neue Bildsitzung';

  @override
  String get appName => 'Chibot AI';

  @override
  String get appDesc => 'Intelligenter Chat-Assistent';

  @override
  String get version => 'Version v0.1.3';

  @override
  String get releaseDate => 'Juli 2025';

  @override
  String get featureSmartChat => 'Intelligenter Chat';

  @override
  String get featureSmartDesc =>
      'Unterstützt mehrere KI-Modelle für natürliche Gespräche.';

  @override
  String get features => 'Funktionen';

  @override
  String get featureImageGen => 'Text zu Bild';

  @override
  String get featureImageGenDesc =>
      'Generieren Sie schöne Bilder aus Texteingaben.';

  @override
  String get featureFlexible => 'Flexible Konfiguration';

  @override
  String get featureFlexibleDesc =>
      'Unterstützt mehrere Modellanbieter und benutzerdefinierte Einstellungen.';

  @override
  String get textChat => 'Text-Chat';

  @override
  String get textImage => 'Text zu Bild';

  @override
  String get supportModels => 'Unterstützte Modelle';

  @override
  String get usageHelp => 'Nutzungshilfe';

  @override
  String get userManual => 'Benutzerhandbuch';

  @override
  String get problemFeedback => 'Problem-Feedback';

  @override
  String get contact => 'Kontakt';

  @override
  String get helpSupport => 'Hilfe & Support';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get termsService => 'Nutzungsbedingungen';

  @override
  String get disclaimer => 'Haftungsausschluss';

  @override
  String get legalInfo => 'Rechtliche Informationen';

  @override
  String get copyright => '© 2025 Chibot AI. Alle Rechte vorbehalten.';

  @override
  String get vision => 'Mit ❤️ für eine bessere KI-Erfahrung gemacht';

  @override
  String get tavilyApiKeyNotSet =>
      'Tavily API-Schlüssel ist nicht gesetzt. Bitte gehen Sie zur Einstellungsseite, um ihn auszufüllen, bevor Sie die Web-Suche-Funktion verwenden.';

  @override
  String webSearchPrompt(Object userQuestion, Object webResult) {
    return 'Bitte beantworten Sie die Frage mit den folgenden Web-Suchergebnissen:\n$webResult\nBenutzerfrage: $userQuestion';
  }

  @override
  String webSearchFailed(Object error) {
    return 'Web-Suche fehlgeschlagen: $error';
  }

  @override
  String get trayShowHide => 'Anzeigen/Ausblenden';

  @override
  String get trayExit => 'Beenden';

  @override
  String get saveToDirectory => 'In Verzeichnis speichern';

  @override
  String get exportConfig => 'Exportieren';

  @override
  String get importConfig => 'Importieren';

  @override
  String get exportToMarkdown => 'Nach Markdown exportieren';

  @override
  String get exportAllChats => 'Alle Chats exportieren';

  @override
  String get exportSingleChat => 'Chat exportieren';

  @override
  String get noChatSessionsToExport => 'Keine Chat-Sitzungen zum Exportieren';

  @override
  String get chatExportedSuccessfully => 'Chat erfolgreich exportiert';

  @override
  String get exportCancelled => 'Export abgebrochen';

  @override
  String get exportFailed => 'Export fehlgeschlagen';
}
