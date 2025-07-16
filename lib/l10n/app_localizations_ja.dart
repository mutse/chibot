// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get settings => '設定';

  @override
  String get selectModelProvider => 'モデルプロバイダーを選択:';

  @override
  String get add => '追加';

  @override
  String get modelProviderURLOptional => 'モデルプロバイダーURL（オプション）:';

  @override
  String defaultUrl(Object url) {
    return 'デフォルト: $url';
  }

  @override
  String apiKey(Object provider) {
    return '$provider APIキー:';
  }

  @override
  String get enterYourAPIKey => 'APIキーを入力してください';

  @override
  String get selectModel => 'モデルを選択:';

  @override
  String get noModelsAvailable => 'このプロバイダーで利用可能なモデルがありません';

  @override
  String get customModels => 'カスタムモデル:';

  @override
  String get enterCustomModelName => 'カスタムモデル名を入力';

  @override
  String get yourCustomModels => 'あなたのカスタムモデル:';

  @override
  String get saveSettings => '設定を保存';

  @override
  String get settingsSaved => '設定が保存されました！';

  @override
  String get selectModelType => 'モデルタイプを選択:';

  @override
  String get textModel => 'テキストモデル';

  @override
  String get imageModel => '画像モデル';

  @override
  String get addNewModelConfiguration => '新しいモデル設定を追加';

  @override
  String get modelProvider => 'モデルプロバイダー';

  @override
  String get enterProviderName => 'プロバイダー名を入力';

  @override
  String get enterModelNames => 'モデル名を入力（カンマ区切り）';

  @override
  String get cancel => 'キャンセル';

  @override
  String get chatWithAI => 'AIとチャット';

  @override
  String get typeYourMessage => 'メッセージを入力...';

  @override
  String get custom => 'カスタム';

  @override
  String get apiKeyNotSetError => 'APIキーが設定されていません。設定で設定してください。';

  @override
  String get search => '検索';

  @override
  String get about => 'について';

  @override
  String get chatGPTTitle => 'Chibotタイトル';

  @override
  String get aiIsThinking => 'AIが考えています';

  @override
  String get askAnyQuestion => '何でも質問してください';

  @override
  String get addModelProvider => 'モデルプロバイダーを追加';

  @override
  String get providerNameHint => 'プロバイダー名ヒント';

  @override
  String get modelsHint => 'モデルヒント';

  @override
  String get appTitle => 'Chi AI チャットボット';

  @override
  String get noResponseFromAI => 'AIからの応答がありませんでした。';

  @override
  String get pleaseEnterPromptAfterImagine => '/imagineの後にプロンプトを入力してください。';

  @override
  String get failedToGenerateImageNoUrl => '画像の生成に失敗しました: 画像URLが返されませんでした。';

  @override
  String get errorLoadingImage => '画像の読み込みエラー。';

  @override
  String get noImageGenerated => '画像が生成されませんでした。';

  @override
  String errorGeneratingImage(Object error) {
    return '画像生成エラー: $error';
  }

  @override
  String get saveImage => '画像を保存';

  @override
  String get imageGenerationSettings => '画像生成設定';

  @override
  String get selectImageProvider => '画像プロバイダーを選択:';

  @override
  String get imageProviderURLOptional => '画像プロバイダーURL（オプション）:';

  @override
  String get enterImageProviderURL => '画像プロバイダーURLを入力';

  @override
  String get selectImageModel => '画像モデルを選択:';

  @override
  String get customImageModels => 'カスタム画像モデル:';

  @override
  String get enterCustomImageModelName => 'カスタム画像モデル名を入力';

  @override
  String get providerAndModelAdded => 'プロバイダーとモデルが追加されました！';

  @override
  String get providerAndModelNameCannotBeEmpty => 'プロバイダー名とモデル名は空にできません。';

  @override
  String get newChat => '新しいチャット';

  @override
  String get imageGeneratedSuccessfully => '画像が正常に生成されました！';

  @override
  String get newImageSession => '新しい画像セッション';

  @override
  String get appName => 'Chibot AI';

  @override
  String get appDesc => 'スマートチャットアシスタント';

  @override
  String get version => 'バージョン v0.1.3';

  @override
  String get releaseDate => '2025年7月';

  @override
  String get featureSmartChat => 'スマートチャット';

  @override
  String get featureSmartDesc => '自然な会話のための複数のAIモデルをサポート。';

  @override
  String get features => '機能';

  @override
  String get featureImageGen => 'テキストから画像';

  @override
  String get featureImageGenDesc => 'テキストプロンプトから美しい画像を生成。';

  @override
  String get featureFlexible => '柔軟な設定';

  @override
  String get featureFlexibleDesc => '複数のモデルプロバイダーとカスタム設定をサポート。';

  @override
  String get textChat => 'テキストチャット';

  @override
  String get textImage => 'テキストから画像';

  @override
  String get supportModels => 'サポートモデル';

  @override
  String get usageHelp => '使用ヘルプ';

  @override
  String get userManual => 'ユーザーマニュアル';

  @override
  String get problemFeedback => '問題フィードバック';

  @override
  String get contact => '連絡先';

  @override
  String get helpSupport => 'ヘルプ・サポート';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsService => '利用規約';

  @override
  String get disclaimer => '免責事項';

  @override
  String get legalInfo => '法的情報';

  @override
  String get copyright => '© 2025 Chibot AI. 全著作権所有。';

  @override
  String get vision => 'より良いAI体験のために❤️で作られました';

  @override
  String get tavilyApiKeyNotSet =>
      'Tavily APIキーが設定されていません。Web検索機能を使用する前に、設定ページで入力してください。';

  @override
  String webSearchPrompt(Object userQuestion, Object webResult) {
    return '以下のWeb検索結果を使用して質問に答えてください:\n$webResult\nユーザーの質問: $userQuestion';
  }

  @override
  String webSearchFailed(Object error) {
    return 'Web検索に失敗しました: $error';
  }

  @override
  String get trayShowHide => '表示/非表示';

  @override
  String get trayExit => '終了';

  @override
  String get saveToDirectory => 'ディレクトリに保存';

  @override
  String get exportConfig => 'エクスポート';

  @override
  String get importConfig => 'インポート';

  @override
  String get exportToMarkdown => 'Markdownにエクスポート';

  @override
  String get exportAllChats => 'すべてのチャットをエクスポート';

  @override
  String get exportSingleChat => 'チャットをエクスポート';

  @override
  String get noChatSessionsToExport => 'エクスポートするチャットセッションがありません';

  @override
  String get chatExportedSuccessfully => 'チャットが正常にエクスポートされました';

  @override
  String get exportCancelled => 'エクスポートがキャンセルされました';

  @override
  String get exportFailed => 'エクスポートに失敗しました';

  @override
  String get exportToImg => '画像としてエクスポート';

  @override
  String updateFound(Object version) {
    return '新しいバージョン $version が見つかりました';
  }

  @override
  String get updateNow => '今すぐ更新';
}
