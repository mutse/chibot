// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settings => 'Paramètres';

  @override
  String get selectModelProvider => 'Sélectionner le fournisseur de modèle :';

  @override
  String get add => 'Ajouter';

  @override
  String get modelProviderURLOptional =>
      'URL du fournisseur de modèle (optionnel) :';

  @override
  String defaultUrl(Object url) {
    return 'Par défaut : $url';
  }

  @override
  String apiKey(Object provider) {
    return 'Clé API $provider :';
  }

  @override
  String get enterYourAPIKey => 'Entrez votre clé API';

  @override
  String get selectModel => 'Sélectionner le modèle :';

  @override
  String get noModelsAvailable => 'Aucun modèle disponible pour ce fournisseur';

  @override
  String get customModels => 'Modèles personnalisés :';

  @override
  String get enterCustomModelName => 'Entrez le nom du modèle personnalisé';

  @override
  String get yourCustomModels => 'Vos modèles personnalisés :';

  @override
  String get saveSettings => 'Enregistrer les paramètres';

  @override
  String get settingsSaved => 'Paramètres enregistrés !';

  @override
  String get selectModelType => 'Sélectionner le type de modèle :';

  @override
  String get textModel => 'Modèle de texte';

  @override
  String get imageModel => 'Modèle d\'image';

  @override
  String get addNewModelConfiguration =>
      'Ajouter une nouvelle configuration de modèle';

  @override
  String get modelProvider => 'Fournisseur de modèle';

  @override
  String get enterProviderName => 'Entrez le nom du fournisseur';

  @override
  String get enterModelNames =>
      'Entrez les noms des modèles (séparés par des virgules)';

  @override
  String get cancel => 'Annuler';

  @override
  String get chatWithAI => 'Discuter avec l\'IA';

  @override
  String get typeYourMessage => 'Tapez votre message...';

  @override
  String get custom => 'Personnalisé';

  @override
  String get apiKeyNotSetError =>
      'Clé API non définie. Veuillez la définir dans les paramètres.';

  @override
  String get search => 'Rechercher';

  @override
  String get about => 'À propos';

  @override
  String get chatGPTTitle => 'Titre Chibot';

  @override
  String get aiIsThinking => 'L\'IA réfléchit';

  @override
  String get askAnyQuestion => 'Posez n\'importe quelle question';

  @override
  String get addModelProvider => 'Ajouter un fournisseur de modèle';

  @override
  String get providerNameHint => 'Indication du nom du fournisseur';

  @override
  String get modelsHint => 'Indication des modèles';

  @override
  String get appTitle => 'Chi AI Chatbot';

  @override
  String get noResponseFromAI => 'L\'IA n\'a pas retourné de réponse.';

  @override
  String get pleaseEnterPromptAfterImagine =>
      'Veuillez entrer une invite après /imagine.';

  @override
  String get failedToGenerateImageNoUrl =>
      'Échec de la génération d\'image : Aucune URL d\'image retournée.';

  @override
  String get errorLoadingImage => 'Erreur lors du chargement de l\'image.';

  @override
  String get noImageGenerated => 'Aucune image générée.';

  @override
  String errorGeneratingImage(Object error) {
    return 'Erreur lors de la génération d\'image : $error';
  }

  @override
  String get saveImage => 'Enregistrer l\'image';

  @override
  String get imageGenerationSettings => 'Paramètres de génération d\'image';

  @override
  String get selectImageProvider => 'Sélectionner le fournisseur d\'image :';

  @override
  String get imageProviderURLOptional =>
      'URL du fournisseur d\'image (optionnel) :';

  @override
  String get enterImageProviderURL => 'Entrez l\'URL du fournisseur d\'image';

  @override
  String get selectImageModel => 'Sélectionner le modèle d\'image :';

  @override
  String get customImageModels => 'Modèles d\'image personnalisés :';

  @override
  String get enterCustomImageModelName =>
      'Entrez le nom du modèle d\'image personnalisé';

  @override
  String get providerAndModelAdded => 'Fournisseur et modèle ajoutés !';

  @override
  String get providerAndModelNameCannotBeEmpty =>
      'Le nom du fournisseur et du modèle ne peuvent pas être vides.';

  @override
  String get newChat => 'Nouveau chat';

  @override
  String get imageGeneratedSuccessfully => 'Image générée avec succès !';

  @override
  String get newImageSession => 'Nouvelle session d\'image';

  @override
  String get appName => 'Chibot AI';

  @override
  String get appDesc => 'Assistant de chat intelligent';

  @override
  String get version => 'Version v0.1.3';

  @override
  String get releaseDate => 'Juillet 2025';

  @override
  String get featureSmartChat => 'Chat intelligent';

  @override
  String get featureSmartDesc =>
      'Prend en charge plusieurs modèles d\'IA pour des conversations naturelles.';

  @override
  String get features => 'Fonctionnalités';

  @override
  String get featureImageGen => 'Texte vers image';

  @override
  String get featureImageGenDesc =>
      'Générez de belles images à partir d\'invites textuelles.';

  @override
  String get featureFlexible => 'Configuration flexible';

  @override
  String get featureFlexibleDesc =>
      'Prend en charge plusieurs fournisseurs de modèles et paramètres personnalisés.';

  @override
  String get textChat => 'Chat textuel';

  @override
  String get textImage => 'Texte vers image';

  @override
  String get supportModels => 'Modèles pris en charge';

  @override
  String get usageHelp => 'Aide à l\'utilisation';

  @override
  String get userManual => 'Manuel utilisateur';

  @override
  String get problemFeedback => 'Commentaires sur les problèmes';

  @override
  String get contact => 'Contact';

  @override
  String get helpSupport => 'Aide et support';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsService => 'Conditions d\'utilisation';

  @override
  String get disclaimer => 'Avertissement';

  @override
  String get legalInfo => 'Informations légales';

  @override
  String get copyright => '© 2025 Chibot AI. Tous droits réservés.';

  @override
  String get vision => 'Créé avec ❤️ pour une meilleure expérience IA';

  @override
  String get tavilyApiKeyNotSet =>
      'La clé API Tavily n\'est pas définie. Veuillez aller à la page des paramètres pour la remplir avant d\'utiliser la fonction de recherche Web.';

  @override
  String webSearchPrompt(Object userQuestion, Object webResult) {
    return 'Veuillez répondre à la question en utilisant les résultats de recherche Web suivants :\n$webResult\nQuestion de l\'utilisateur : $userQuestion';
  }

  @override
  String webSearchFailed(Object error) {
    return 'La recherche Web a échoué : $error';
  }

  @override
  String get trayShowHide => 'Afficher/Masquer';

  @override
  String get trayExit => 'Quitter';

  @override
  String get saveToDirectory => 'Enregistrer dans le répertoire';

  @override
  String get exportConfig => 'Exporter';

  @override
  String get importConfig => 'Importer';

  @override
  String get exportToMarkdown => 'Exporter vers Markdown';

  @override
  String get exportAllChats => 'Exporter tous les chats';

  @override
  String get exportSingleChat => 'Exporter le chat';

  @override
  String get noChatSessionsToExport => 'Aucune session de chat à exporter';

  @override
  String get chatExportedSuccessfully => 'Chat exporté avec succès';

  @override
  String get exportCancelled => 'Exportation annulée';

  @override
  String get exportFailed => 'Échec de l\'exportation';
}
