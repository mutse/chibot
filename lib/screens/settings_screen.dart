import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/chat_model_provider.dart';
import 'package:chibot/providers/image_model_provider.dart';
import 'package:chibot/providers/video_model_provider.dart';
import 'package:chibot/providers/search_provider.dart';
import 'package:chibot/providers/settings_models_provider.dart';
import 'package:chibot/providers/unified_settings_provider.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:chibot/models/available_model.dart' as available_model;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _PlatformDirectoryInfo {
  final Directory directory;
  final String platformName;
  final String displayPath;

  const _PlatformDirectoryInfo({
    required this.directory,
    required this.platformName,
    required this.displayPath,
  });
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const TextStyle _sectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  late AppLocalizations l10n;
  late TextEditingController _apiKeyController;

  // 玻璃态UI辅助方法
  Widget _buildGlassCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double borderRadius = 16.0,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                suffixIcon:
                    onClear != null
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          onPressed: onClear,
                        )
                        : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color:
              selected
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color:
                  selected
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black87 : Colors.black54,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: selected,
              onSelected: onSelected,
              backgroundColor: Colors.transparent,
              selectedColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              hint: hintText != null ? Text(hintText) : null,
              isExpanded: true,
              underline: Container(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.black.withValues(alpha: 0.6),
              ),
              style: const TextStyle(color: Colors.black87),
              dropdownColor: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    backgroundColor != null
                        ? [
                          backgroundColor.withValues(alpha: 0.8),
                          backgroundColor.withValues(alpha: 0.6),
                        ]
                        : [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.15),
                        ],
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.black87),
              label: Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: _sectionTitleStyle);
  }

  Widget _buildSimpleFieldSection({
    required String title,
    required Widget field,
    String? helperText,
    double spacingBeforeField = 12,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
        SizedBox(height: spacingBeforeField),
        field,
      ],
    );
  }

  late TextEditingController _providerUrlController;
  late TextEditingController _imageProviderUrlController;
  late TextEditingController _customModelController;
  late TextEditingController _tavilyApiKeyController;
  late TextEditingController _googleSearchApiKeyController;
  late TextEditingController _googleSearchEngineIdController;

  @override
  void initState() {
    super.initState();
    final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);
    final chatModel = Provider.of<ChatModelProvider>(context, listen: false);
    final imageModel = Provider.of<ImageModelProvider>(context, listen: false);
    final search = Provider.of<SearchProvider>(context, listen: false);

    _apiKeyController = TextEditingController(
      text: _getProviderApiKey(apiKeys, chatModel),
    );
    _providerUrlController = TextEditingController(
      text: chatModel.rawProviderUrl,
    );
    _imageProviderUrlController = TextEditingController(
      text: imageModel.rawImageProviderUrl,
    );
    _customModelController = TextEditingController();
    _tavilyApiKeyController = TextEditingController(
      text: search.tavilyApiKey ?? '',
    );
    _googleSearchApiKeyController = TextEditingController(
      text: search.googleSearchApiKey ?? '',
    );
    _googleSearchEngineIdController = TextEditingController(
      text: search.googleSearchEngineId ?? '',
    );
  }

  String _getProviderApiKey(
    ApiKeyProvider apiKeys,
    ChatModelProvider chatModel,
  ) {
    switch (chatModel.selectedProvider) {
      case 'OpenAI':
        return apiKeys.apiKey ?? '';
      case 'Anthropic':
        return apiKeys.claudeApiKey ?? '';
      case 'Google':
        return apiKeys.apiKey ?? ''; // Using OpenAI key for Google for now
      default:
        return apiKeys.apiKey ?? '';
    }
  }

  String _getApiKeyLabel(
    ChatModelProvider chatModel,
    ImageModelProvider imageModel,
    bool isImageMode,
  ) {
    if (isImageMode) {
      return l10n.apiKey(imageModel.selectedImageProvider);
    }

    switch (chatModel.selectedProvider) {
      case 'OpenAI':
        return 'OpenAI API Key';
      case 'Anthropic':
        return 'Claude API Key (Anthropic)';
      case 'Google':
        return 'Google API Key';
      default:
        return l10n.apiKey(chatModel.selectedProvider);
    }
  }

  String _getApiKeyHint(ChatModelProvider chatModel, bool isImageMode) {
    if (isImageMode) {
      return l10n.enterYourAPIKey;
    }

    switch (chatModel.selectedProvider) {
      case 'OpenAI':
        return 'Enter your OpenAI API Key';
      case 'Anthropic':
        return 'Enter your Claude API Key';
      case 'Google':
        return 'Enter your Google API Key';
      default:
        return l10n.enterYourAPIKey;
    }
  }

  Future<void> _saveProviderApiKey(
    ApiKeyProvider apiKeys,
    ChatModelProvider chatModel,
    String apiKey,
  ) async {
    switch (chatModel.selectedProvider) {
      case 'OpenAI':
        await apiKeys.setOpenaiApiKey(apiKey);
        break;
      case 'Anthropic':
        await apiKeys.setClaudeApiKey(apiKey);
        break;
      case 'Google':
        await apiKeys.setGoogleApiKey(apiKey);
        break;
      default:
        await apiKeys.setOpenaiApiKey(apiKey);
        break;
    }
  }

  Future<void> _saveImageProviderApiKey(
    ApiKeyProvider apiKeys,
    ImageModelProvider imageModel,
    String apiKey,
  ) async {
    switch (imageModel.selectedImageProvider) {
      case 'OpenAI':
        await apiKeys.setOpenaiApiKey(apiKey);
        break;
      case 'Google':
        await apiKeys.setGoogleApiKey(apiKey);
        break;
      case 'Black Forest Labs':
        await apiKeys.setFluxKontextApiKey(apiKey);
        break;
      default:
        await apiKeys.setOpenaiApiKey(apiKey);
        break;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _providerUrlController.dispose();
    _imageProviderUrlController.dispose();
    _customModelController.dispose();
    _tavilyApiKeyController.dispose();
    _googleSearchApiKeyController.dispose();
    _googleSearchEngineIdController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  void _updateControllerText(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.value = controller.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  void _syncApiKeyController({
    required UnifiedSettingsProvider unifiedSettings,
    required ApiKeyProvider apiKeys,
    required ChatModelProvider chatModel,
    required ImageModelProvider imageModel,
  }) {
    String expectedApiKey;
    if (unifiedSettings.selectedModelType == available_model.ModelType.text) {
      expectedApiKey = _getProviderApiKey(apiKeys, chatModel);
    } else if (unifiedSettings.selectedModelType ==
        available_model.ModelType.image) {
      expectedApiKey =
          apiKeys.getImageApiKeyForProvider(imageModel.selectedImageProvider) ??
          '';
    } else if (unifiedSettings.selectedModelType ==
        available_model.ModelType.video) {
      expectedApiKey = apiKeys.googleApiKey ?? '';
    } else {
      expectedApiKey = _getProviderApiKey(apiKeys, chatModel);
    }

    _updateControllerText(_apiKeyController, expectedApiKey);
  }

  void _syncSearchControllers(SearchProvider search) {
    _updateControllerText(_tavilyApiKeyController, search.tavilyApiKey ?? '');
    _updateControllerText(
      _googleSearchApiKeyController,
      search.googleSearchApiKey ?? '',
    );
    _updateControllerText(
      _googleSearchEngineIdController,
      search.googleSearchEngineId ?? '',
    );
  }

  Future<void> _saveSearchSettings(SearchProvider search) async {
    await search.setTavilyApiKey(
      search.tavilySearchEnabled ? _tavilyApiKeyController.text.trim() : '',
    );
    await search.setGoogleSearchApiKey(
      _googleSearchApiKeyController.text.trim(),
    );
    await search.setGoogleSearchEngineId(
      _googleSearchEngineIdController.text.trim(),
    );
  }

  Future<void> _saveTextSettings({
    required ApiKeyProvider apiKeys,
    required ChatModelProvider chatModel,
    required SearchProvider search,
    required String apiKeyText,
  }) async {
    await _saveProviderApiKey(apiKeys, chatModel, apiKeyText);
    await chatModel.setProviderUrl(_providerUrlController.text.trim());
    await _saveSearchSettings(search);
  }

  Future<void> _saveImageSettings({
    required ApiKeyProvider apiKeys,
    required ImageModelProvider imageModel,
    required String apiKeyText,
  }) async {
    await _saveImageProviderApiKey(apiKeys, imageModel, apiKeyText);
    await imageModel.setImageProviderUrl(
      _imageProviderUrlController.text.trim(),
    );
  }

  Future<void> _saveVideoSettings({
    required ApiKeyProvider apiKeys,
    required String apiKeyText,
  }) async {
    await apiKeys.setGoogleApiKey(apiKeyText);
  }

  Future<void> _saveSettingsForSelectedMode({
    required ApiKeyProvider apiKeys,
    required ChatModelProvider chatModel,
    required ImageModelProvider imageModel,
    required SearchProvider search,
    required UnifiedSettingsProvider unifiedSettings,
  }) async {
    final apiKeyText = _apiKeyController.text.trim();

    if (unifiedSettings.selectedModelType == available_model.ModelType.text) {
      await _saveTextSettings(
        apiKeys: apiKeys,
        chatModel: chatModel,
        search: search,
        apiKeyText: apiKeyText,
      );
      return;
    }

    if (unifiedSettings.selectedModelType == available_model.ModelType.image) {
      await _saveImageSettings(
        apiKeys: apiKeys,
        imageModel: imageModel,
        apiKeyText: apiKeyText,
      );
      return;
    }

    if (unifiedSettings.selectedModelType == available_model.ModelType.video) {
      await _saveVideoSettings(apiKeys: apiKeys, apiKeyText: apiKeyText);
    }
  }

  void _showSettingsSavedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsSaved),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _addTextProviderAndModel({
    required BuildContext context,
    required String providerName,
    required String modelName,
    required String providerUrl,
    required String apiKey,
  }) async {
    final chatModel = Provider.of<ChatModelProvider>(context, listen: false);
    final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);

    await chatModel.addCustomProvider(providerName, [modelName]);
    await chatModel.setSelectedProvider(providerName);
    await chatModel.setSelectedModel(modelName);

    if (providerUrl.isNotEmpty) {
      await chatModel.setProviderUrl(providerUrl);
    }
    if (apiKey.isNotEmpty) {
      await _saveProviderApiKey(apiKeys, chatModel, apiKey);
    }

    _providerUrlController.text = chatModel.rawProviderUrl ?? '';
    _apiKeyController.text = _getProviderApiKey(apiKeys, chatModel);
  }

  Future<void> _addImageProviderAndModel({
    required BuildContext context,
    required String providerName,
    required String modelName,
    required String providerUrl,
    required String apiKey,
  }) async {
    final imageModel = Provider.of<ImageModelProvider>(context, listen: false);
    final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);
    final settingsModels = Provider.of<SettingsModelsProvider>(
      context,
      listen: false,
    );

    if (providerUrl.isNotEmpty) {
      await imageModel.setImageProviderUrl(providerUrl);
    }

    await imageModel.addCustomImageProvider(providerName, [modelName]);
    await imageModel.setSelectedImageProvider(providerName);
    await imageModel.setSelectedImageModel(modelName);

    if (apiKey.isNotEmpty) {
      await _saveImageProviderApiKey(apiKeys, imageModel, apiKey);
    }

    settingsModels.refreshModels();
    _imageProviderUrlController.text = imageModel.rawImageProviderUrl ?? '';
    _apiKeyController.text =
        apiKeys.getImageApiKeyForProvider(imageModel.selectedImageProvider) ??
        '';
  }

  Future<void> _handleAddProviderAndModel({
    required BuildContext context,
    required available_model.ModelType modelType,
    required String providerName,
    required String modelName,
    required String providerUrl,
    required String apiKey,
  }) async {
    if (modelType == available_model.ModelType.text) {
      await _addTextProviderAndModel(
        context: context,
        providerName: providerName,
        modelName: modelName,
        providerUrl: providerUrl,
        apiKey: apiKey,
      );
      return;
    }

    if (modelType == available_model.ModelType.image) {
      await _addImageProviderAndModel(
        context: context,
        providerName: providerName,
        modelName: modelName,
        providerUrl: providerUrl,
        apiKey: apiKey,
      );
    }
  }

  void _showStatusSnackBar(
    BuildContext context, {
    required Widget content,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  void _showSimpleStatusMessage(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showStatusSnackBar(
      context,
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
    );
  }

  Widget _buildStatusDetails({
    required String title,
    required List<Widget> details,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        if (details.isNotEmpty) const SizedBox(height: 4),
        ...details,
      ],
    );
  }

  Widget _buildImportFileInfoCard({
    required String fileName,
    required String directoryPath,
    required double fileSizeKb,
    String? sourceLabel,
    String? platformLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            directoryPath,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '文件大小: ${fileSizeKb.toStringAsFixed(1)} KB',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (sourceLabel != null)
            Text(
              '来源: $sourceLabel',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (platformLabel != null)
            Text(
              '平台: $platformLabel',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Future<_PlatformDirectoryInfo> _getChibotDirectory() async {
    if (Platform.isMacOS) {
      final documentsDir = await getApplicationDocumentsDirectory();
      return _PlatformDirectoryInfo(
        directory: Directory('${documentsDir.path}/Chibot'),
        platformName: 'macOS',
        displayPath: '~/Documents/Chibot (macOS)',
      );
    } else if (Platform.isWindows) {
      final documentsDir = await getApplicationDocumentsDirectory();
      return _PlatformDirectoryInfo(
        directory: Directory('${documentsDir.path}/Chibot'),
        platformName: 'Windows',
        displayPath: '%USERPROFILE%/Documents/Chibot (Windows)',
      );
    } else if (Platform.isLinux) {
      final documentsDir = await getApplicationDocumentsDirectory();
      return _PlatformDirectoryInfo(
        directory: Directory('${documentsDir.path}/Chibot'),
        platformName: 'Linux',
        displayPath: '~/Documents/Chibot (Linux)',
      );
    } else if (Platform.isAndroid) {
      return _PlatformDirectoryInfo(
        directory: Directory('/storage/emulated/0/Download/Chibot'),
        platformName: 'Android',
        displayPath: '/storage/emulated/0/Download/Chibot (Android)',
      );
    } else if (Platform.isIOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      return _PlatformDirectoryInfo(
        directory: Directory('${appDocDir.path}/Chibot'),
        platformName: 'iOS',
        displayPath: 'App Documents/Chibot (iOS)',
      );
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    return _PlatformDirectoryInfo(
      directory: Directory('${documentsDir.path}/Chibot'),
      platformName: 'Unknown',
      displayPath: '~/Documents/Chibot',
    );
  }

  bool _isValidSettingsXml(String xmlContent) {
    return xmlContent.trim().isNotEmpty &&
        (xmlContent.contains('<settings') ||
            xmlContent.contains('</settings>'));
  }

  String _buildImportErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('version')) {
      return '导入失败: 配置版本不兼容。此文件来自较新的应用版本。';
    }
    if (message.contains('Invalid')) {
      return '导入失败: 无效的配置文件。文件可能已损坏。';
    }
    return '导入失败: 配置格式错误或不兼容';
  }

  Future<bool> _confirmImportFile(
    BuildContext context, {
    required String fileName,
    required String directoryPath,
    required double fileSizeKb,
    String? sourceLabel,
    String? platformLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('导入配置'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('即将导入配置文件，这将覆盖您当前的所有设置。'),
              const SizedBox(height: 16),
              _buildImportFileInfoCard(
                fileName: fileName,
                directoryPath: directoryPath,
                fileSizeKb: fileSizeKb,
                sourceLabel: sourceLabel,
                platformLabel: platformLabel,
              ),
              const SizedBox(height: 16),
              const Text(
                '确定要继续吗？此操作无法撤销。',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('导入'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _applyImportedSettings(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings, {
    required String xmlContent,
    required List<Widget> successDetails,
  }) async {
    try {
      await unifiedSettings.importSettingsFromXml(xmlContent);
      setState(() {});

      if (!context.mounted) return;
      _showStatusSnackBar(
        context,
        content: _buildStatusDetails(
          title: '✅ 配置导入成功！',
          details: successDetails,
        ),
        backgroundColor: Colors.green,
      );
    } catch (error) {
      debugPrint('Import validation error: $error');
      if (!context.mounted) return;
      _showStatusSnackBar(
        context,
        content: _buildStatusDetails(
          title: '❌ 导入失败',
          details: [
            Text(
              _buildImportErrorMessage(error),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Widget _buildModelTypeCard(UnifiedSettingsProvider unifiedSettings) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.selectModelType),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGlassChip(
                label: l10n.textModel,
                selected:
                    unifiedSettings.selectedModelType ==
                    available_model.ModelType.text,
                onSelected: (selected) {
                  if (selected) {
                    unifiedSettings.setSelectedModelType(
                      available_model.ModelType.text,
                    );
                  }
                },
              ),
              _buildGlassChip(
                label: l10n.imageModel,
                selected:
                    unifiedSettings.selectedModelType ==
                    available_model.ModelType.image,
                onSelected: (selected) {
                  if (selected) {
                    unifiedSettings.setSelectedModelType(
                      available_model.ModelType.image,
                    );
                  }
                },
              ),
              _buildGlassChip(
                label: '视频模型',
                selected:
                    unifiedSettings.selectedModelType ==
                    available_model.ModelType.video,
                onSelected: (selected) {
                  if (selected) {
                    unifiedSettings.setSelectedModelType(
                      available_model.ModelType.video,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddProviderCard(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
  ) {
    return _buildGlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSectionTitle(l10n.selectModelProvider),
          _buildGlassButton(
            label: l10n.add,
            icon: Icons.add,
            onPressed: () {
              _showAddProviderAndModelDialog(
                context,
                unifiedSettings,
                unifiedSettings.selectedModelType,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSettingsSection(SearchProvider search) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Tavily Web 搜索功能'),
            const Spacer(),
            Switch(
              value: search.tavilySearchEnabled,
              onChanged: (value) {
                search.setTavilySearchEnabled(value);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (search.tavilySearchEnabled) ...[
          _buildSectionTitle('Tavily Web 搜索 API Key'),
          TextField(
            controller: _tavilyApiKeyController,
            obscureText: true,
            decoration: const InputDecoration(hintText: '输入 Tavily API Key'),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            _buildSectionTitle('Google 搜索功能'),
            const Spacer(),
            Switch(
              value: search.googleSearchEnabled,
              onChanged: (value) {
                search.setGoogleSearchEnabled(value);
              },
            ),
          ],
        ),
        if (search.googleSearchEnabled) ...[
          const Text('Google Search API Key', style: TextStyle(fontSize: 14)),
          TextField(
            controller: _googleSearchApiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: '输入 Google Custom Search API Key',
            ),
          ),
          const SizedBox(height: 10),
          const Text('Google Search Engine ID', style: TextStyle(fontSize: 14)),
          TextField(
            controller: _googleSearchEngineIdController,
            decoration: const InputDecoration(
              hintText: '输入 Custom Search Engine ID',
            ),
          ),
          const SizedBox(height: 10),
          const Text('搜索结果数量', style: TextStyle(fontSize: 14)),
          Slider(
            value: search.googleSearchResultCount.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: search.googleSearchResultCount.toString(),
            onChanged: (value) {
              search.setGoogleSearchResultCount(value.toInt());
            },
          ),
          const SizedBox(height: 10),
          const Text('搜索提供商', style: TextStyle(fontSize: 14)),
          DropdownButton<String>(
            value: search.googleSearchProvider,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: 'googleCustomSearch',
                child: Text('Google Custom Search API'),
              ),
              DropdownMenuItem(
                value: 'programmableSearch',
                child: Text('Programmable Search Engine'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                search.setGoogleSearchProvider(value);
              }
            },
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTextSettingsSection({
    required ApiKeyProvider apiKeys,
    required ChatModelProvider chatModel,
    required ImageModelProvider imageModel,
    required SearchProvider search,
    required SettingsModelsProvider settingsModels,
    required UnifiedSettingsProvider unifiedSettings,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectModelProvider,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildGlassDropdown<String>(
                value:
                    chatModel.allProviderNames.contains(
                          chatModel.selectedProvider,
                        )
                        ? chatModel.selectedProvider
                        : (chatModel.allProviderNames.isNotEmpty
                            ? chatModel.allProviderNames.first
                            : null),
                items:
                    chatModel.allProviderNames.map((String provider) {
                      final isCustom =
                          !ChatModelProvider.defaultBaseUrls.keys.contains(
                            provider,
                          );
                      return DropdownMenuItem<String>(
                        value: provider,
                        child: Text(
                          isCustom
                              ? ' $provider (OpenAI Compatible)'
                              : provider,
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    await chatModel.setSelectedProvider(newValue);
                    _providerUrlController.text =
                        chatModel.rawProviderUrl ?? '';
                    _apiKeyController.text = _getProviderApiKey(
                      apiKeys,
                      chatModel,
                    );
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ),
        _buildGlassCard(
          child: _buildSimpleFieldSection(
            title: l10n.modelProviderURLOptional,
            helperText: l10n.defaultUrl(
              ChatModelProvider.defaultBaseUrls['OpenAI'] ?? '',
            ),
            field: _buildGlassTextField(
              controller: _providerUrlController,
              hintText: 'e.g., http://localhost:11434/v1',
              keyboardType: TextInputType.url,
            ),
          ),
        ),
        _buildGlassCard(
          child: _buildSimpleFieldSection(
            title: _getApiKeyLabel(
              chatModel,
              imageModel,
              unifiedSettings.selectedModelType ==
                  available_model.ModelType.image,
            ),
            field: _buildGlassTextField(
              controller: _apiKeyController,
              hintText: _getApiKeyHint(
                chatModel,
                unifiedSettings.selectedModelType ==
                    available_model.ModelType.image,
              ),
              obscureText: true,
              onClear: () async {
                setState(() {
                  _apiKeyController.clear();
                });
                await _saveProviderApiKey(apiKeys, chatModel, '');
              },
            ),
          ),
        ),
        _buildGlassCard(
          child: _buildSimpleFieldSection(
            title: l10n.selectModel,
            field: _buildGlassDropdown<String>(
              value:
                  settingsModels.textModels
                          .where(
                            (m) => m.provider == chatModel.selectedProvider,
                          )
                          .any((m) => m.id == chatModel.selectedModel)
                      ? chatModel.selectedModel
                      : (settingsModels.textModels
                              .where(
                                (m) => m.provider == chatModel.selectedProvider,
                              )
                              .isNotEmpty
                          ? settingsModels.textModels
                              .where(
                                (m) => m.provider == chatModel.selectedProvider,
                              )
                              .first
                              .id
                          : null),
              items:
                  settingsModels.textModels
                      .where(
                        (model) => model.provider == chatModel.selectedProvider,
                      )
                      .map((model) {
                        return DropdownMenuItem<String>(
                          value: model.id,
                          child: Text(model.name),
                        );
                      })
                      .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  chatModel.setSelectedModel(newValue);
                }
              },
              hintText:
                  settingsModels.textModels
                          .where(
                            (m) => m.provider == chatModel.selectedProvider,
                          )
                          .isEmpty
                      ? l10n.noModelsAvailable
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle(l10n.customModels),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customModelController,
                decoration: InputDecoration(
                  hintText: l10n.enterCustomModelName,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                final modelName = _customModelController.text.trim();
                if (modelName.isNotEmpty) {
                  chatModel.addCustomModel(modelName);
                  chatModel.setSelectedModel(modelName);
                  _customModelController.clear();
                }
              },
            ),
          ],
        ),
        _buildSearchSettingsSection(search),
        if (chatModel.customModels.isNotEmpty)
          Text(
            l10n.yourCustomModels,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chatModel.customModels.length,
          itemBuilder: (context, index) {
            final model = chatModel.customModels[index];
            return ListTile(
              title: Text(model),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  chatModel.removeCustomModel(model);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImageSettingsSection({
    required ApiKeyProvider apiKeys,
    required ImageModelProvider imageModel,
    required SettingsModelsProvider settingsModels,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value:
              imageModel.allImageProviderNames.contains(
                    imageModel.selectedImageProvider,
                  )
                  ? imageModel.selectedImageProvider
                  : (imageModel.allImageProviderNames.isNotEmpty
                      ? imageModel.allImageProviderNames.first
                      : null),
          isExpanded: true,
          items:
              imageModel.allImageProviderNames.map((String provider) {
                return DropdownMenuItem<String>(
                  value: provider,
                  child: Text(provider),
                );
              }).toList(),
          onChanged: (String? newValue) async {
            if (newValue != null) {
              await imageModel.setSelectedImageProvider(newValue);
              _imageProviderUrlController.text =
                  imageModel.rawImageProviderUrl ?? '';
              _apiKeyController.text =
                  apiKeys.getImageApiKeyForProvider(newValue) ?? '';
              if (imageModel.availableImageModels.isNotEmpty) {
                await imageModel.setSelectedImageModel(
                  imageModel.availableImageModels.first,
                );
              } else {
                await imageModel.setSelectedImageModel('');
              }
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 20),
        Text(l10n.modelProviderURLOptional, style: _sectionTitleStyle),
        Text(
          l10n.defaultUrl(
            ImageModelProvider.defaultImageBaseUrls['OpenAI'] ?? '',
          ),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        TextField(
          controller: _imageProviderUrlController,
          decoration: const InputDecoration(
            hintText: 'e.g., https://api.stability.ai',
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 20),
        _buildSectionTitle(l10n.apiKey(imageModel.selectedImageProvider)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: InputDecoration(hintText: l10n.enterYourAPIKey),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: '清除',
              onPressed: () async {
                setState(() {
                  _apiKeyController.clear();
                });
                await _saveImageProviderApiKey(apiKeys, imageModel, '');
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSectionTitle(l10n.selectModel),
        DropdownButton<String>(
          value:
              settingsModels.imageModels
                      .where(
                        (m) => m.provider == imageModel.selectedImageProvider,
                      )
                      .any((m) => m.id == imageModel.selectedImageModel)
                  ? imageModel.selectedImageModel
                  : (settingsModels.imageModels
                          .where(
                            (m) =>
                                m.provider == imageModel.selectedImageProvider,
                          )
                          .isNotEmpty
                      ? settingsModels.imageModels
                          .where(
                            (m) =>
                                m.provider == imageModel.selectedImageProvider,
                          )
                          .first
                          .id
                      : null),
          isExpanded: true,
          items:
              settingsModels.imageModels
                  .where(
                    (model) =>
                        model.provider == imageModel.selectedImageProvider,
                  )
                  .map((model) {
                    return DropdownMenuItem<String>(
                      value: model.id,
                      child: Text(model.name),
                    );
                  })
                  .toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              imageModel.setSelectedImageModel(newValue);
            }
          },
          hint:
              settingsModels.imageModels
                      .where(
                        (m) => m.provider == imageModel.selectedImageProvider,
                      )
                      .isEmpty
                  ? Text(l10n.noModelsAvailable)
                  : null,
        ),
        if (imageModel.selectedImageProvider == 'Black Forest Labs') ...[
          const SizedBox(height: 20),
          _buildSectionTitle(l10n.aspectRatio),
          DropdownButton<String>(
            value: imageModel.bflAspectRatio ?? '1:1',
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: '1:1', child: Text('1:1 (正方形)')),
              DropdownMenuItem(value: '16:9', child: Text('16:9 (横屏)')),
              DropdownMenuItem(value: '9:16', child: Text('9:16 (竖屏)')),
              DropdownMenuItem(value: '4:3', child: Text('4:3')),
              DropdownMenuItem(value: '3:2', child: Text('3:2')),
            ],
            onChanged: (value) async {
              await imageModel.setBflAspectRatio(value);
            },
          ),
        ],
        const SizedBox(height: 20),
        _buildSectionTitle(l10n.customModels),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customModelController,
                decoration: InputDecoration(
                  hintText: l10n.enterCustomModelName,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                final modelName = _customModelController.text.trim();
                if (modelName.isNotEmpty) {
                  imageModel.addCustomImageModel(modelName);
                  imageModel.setSelectedImageModel(modelName);
                  _customModelController.clear();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (imageModel.customImageModels.isNotEmpty)
          Text(
            l10n.yourCustomModels,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: imageModel.customImageModels.length,
          itemBuilder: (context, index) {
            final model = imageModel.customImageModels[index];
            return ListTile(
              title: Text(model),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  imageModel.removeCustomImageModel(model);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVideoSettingsSection({
    required ApiKeyProvider apiKeys,
    required VideoModelProvider videoModel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: videoModel.selectedVideoProvider,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'Google Veo3', child: Text('Google Veo3')),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              videoModel.setSelectedVideoProvider(newValue);
            }
          },
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Google Veo3 API Key'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your Google Veo3 API Key',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: '清除',
              onPressed: () async {
                setState(() {
                  _apiKeyController.clear();
                });
                await apiKeys.setGoogleApiKey('');
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Video Resolution'),
        DropdownButton<String>(
          value: videoModel.videoResolution,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: '480p', child: Text('480p (854×480)')),
            DropdownMenuItem(value: '720p', child: Text('720p HD (1280×720)')),
            DropdownMenuItem(
              value: '1080p',
              child: Text('1080p Full HD (1920×1080)'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              videoModel.setVideoResolution(value);
            }
          },
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Video Duration'),
        DropdownButton<String>(
          value: videoModel.videoDuration,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: '5s', child: Text('5 seconds')),
            DropdownMenuItem(value: '10s', child: Text('10 seconds')),
            DropdownMenuItem(value: '30s', child: Text('30 seconds')),
          ],
          onChanged: (value) {
            if (value != null) {
              videoModel.setVideoDuration(value);
            }
          },
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Video Quality'),
        DropdownButton<String>(
          value: videoModel.videoQuality,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: 'standard',
              child: Text('Standard Quality'),
            ),
            DropdownMenuItem(value: 'high', child: Text('High Quality')),
          ],
          onChanged: (value) {
            if (value != null) {
              videoModel.setVideoQuality(value);
            }
          },
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Video Aspect Ratio'),
        DropdownButton<String>(
          value: videoModel.videoAspectRatio,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: '16:9', child: Text('16:9 (Landscape)')),
            DropdownMenuItem(value: '9:16', child: Text('9:16 (Portrait)')),
            DropdownMenuItem(value: '1:1', child: Text('1:1 (Square)')),
            DropdownMenuItem(value: '4:3', child: Text('4:3 (Traditional)')),
          ],
          onChanged: (value) {
            if (value != null) {
              videoModel.setVideoAspectRatio(value);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final unifiedSettings = Provider.of<UnifiedSettingsProvider>(context);
    final settingsModels = Provider.of<SettingsModelsProvider>(context);
    final apiKeys = Provider.of<ApiKeyProvider>(context);
    final chatModel = Provider.of<ChatModelProvider>(context);
    final imageModel = Provider.of<ImageModelProvider>(context);
    final videoModel = Provider.of<VideoModelProvider>(context);
    final search = Provider.of<SearchProvider>(context);

    _syncApiKeyController(
      unifiedSettings: unifiedSettings,
      apiKeys: apiKeys,
      chatModel: chatModel,
      imageModel: imageModel,
    );
    _syncSearchControllers(search);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withValues(alpha: 0.05),
              Colors.purple.withValues(alpha: 0.05),
              Colors.pink.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildModelTypeCard(unifiedSettings),
                _buildAddProviderCard(context, unifiedSettings),
                if (unifiedSettings.selectedModelType ==
                    available_model.ModelType.text) ...[
                  _buildTextSettingsSection(
                    apiKeys: apiKeys,
                    chatModel: chatModel,
                    imageModel: imageModel,
                    search: search,
                    settingsModels: settingsModels,
                    unifiedSettings: unifiedSettings,
                  ),
                ] else if (unifiedSettings.selectedModelType ==
                    available_model.ModelType.image) ...[
                  _buildImageSettingsSection(
                    apiKeys: apiKeys,
                    imageModel: imageModel,
                    settingsModels: settingsModels,
                  ),
                ] else if (unifiedSettings.selectedModelType ==
                    available_model.ModelType.video) ...[
                  _buildVideoSettingsSection(
                    apiKeys: apiKeys,
                    videoModel: videoModel,
                  ),
                ],
                const SizedBox(height: 30),
                // Export/Import Settings Section
                _buildGlassCard(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildGlassButton(
                          label: l10n.exportConfig,
                          icon: Icons.file_upload,
                          backgroundColor: Colors.blue,
                          onPressed:
                              () => _exportSettings(context, unifiedSettings),
                        ),
                        _buildGlassButton(
                          label: l10n.importConfig,
                          icon: Icons.file_download,
                          backgroundColor: Colors.green,
                          onPressed:
                              () =>
                                  _showImportOptions(context, unifiedSettings),
                        ),
                        _buildGlassButton(
                          label: l10n.saveSettings,
                          icon: Icons.save,
                          backgroundColor: Colors.purple,
                          onPressed: () async {
                            await _saveSettingsForSelectedMode(
                              apiKeys: apiKeys,
                              chatModel: chatModel,
                              imageModel: imageModel,
                              search: search,
                              unifiedSettings: unifiedSettings,
                            );

                            // 保存后同步模型到内存注册表
                            chatModel.syncModelsToRegistry();

                            _showSettingsSavedSnackBar(context);
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddProviderAndModelDialog(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
    available_model.ModelType modelType,
  ) {
    final TextEditingController providerNameController =
        TextEditingController();
    final TextEditingController modelNameController = TextEditingController();
    final TextEditingController providerUrlController = TextEditingController();
    final TextEditingController apiKeyController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.addModelProvider),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: providerNameController,
                  decoration: InputDecoration(hintText: l10n.providerNameHint),
                ),
                TextField(
                  controller: modelNameController,
                  decoration: InputDecoration(hintText: l10n.modelsHint),
                ),
                TextField(
                  controller: providerUrlController,
                  decoration: InputDecoration(
                    hintText: l10n.modelProviderURLOptional,
                  ),
                ),
                TextField(
                  controller: apiKeyController,
                  decoration: InputDecoration(hintText: 'API Key (可选)'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.add),
              onPressed: () async {
                final String providerName = providerNameController.text.trim();
                final String modelName = modelNameController.text.trim();
                final String providerUrl = providerUrlController.text.trim();
                final String apiKey = apiKeyController.text.trim();

                if (providerName.isNotEmpty && modelName.isNotEmpty) {
                  await _handleAddProviderAndModel(
                    context: context,
                    modelType: modelType,
                    providerName: providerName,
                    modelName: modelName,
                    providerUrl: providerUrl,
                    apiKey: apiKey,
                  );
                  if (!context.mounted) return;
                  _showSimpleStatusMessage(
                    context,
                    message: l10n.providerAndModelAdded,
                    backgroundColor: Colors.green,
                  );
                  Navigator.of(context).pop();
                  setState(() {}); // 刷新 UI
                } else {
                  _showSimpleStatusMessage(
                    context,
                    message: l10n.providerAndModelNameCannotBeEmpty,
                    backgroundColor: Colors.red,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportSettings(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
  ) async {
    try {
      // 强制同步最新模型到 ModelRegistry
      await unifiedSettings.syncModelsToRegistry();
      debugPrint('Starting export process...');
      final xmlContent = await unifiedSettings.exportSettingsToXml();
      debugPrint('XML content generated: ${xmlContent.length} characters');
      final directoryInfo = await _getChibotDirectory();
      final exportDir = directoryInfo.directory;

      // Create directory if it doesn't exist
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
        debugPrint('Created directory: ${exportDir.path}');
      }

      // Generate filename with timestamp
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'chibot_config_$timestamp.xml';
      final filePath = '${exportDir.path}/$fileName';

      debugPrint('Saving to: $filePath');

      // Write the file
      final file = File(filePath);
      await file.writeAsString(xmlContent);
      debugPrint('File written successfully');

      if (context.mounted) {
        _showStatusSnackBar(
          context,
          content: _buildStatusDetails(
            title: '✅ 配置导出成功！',
            details: [
              Text('文件: $fileName', style: const TextStyle(fontSize: 12)),
              Text(
                '位置: ${exportDir.path}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '平台: ${directoryInfo.platformName}',
                style: const TextStyle(fontSize: 10, color: Colors.white60),
              ),
              Text(
                '文件大小: ${(xmlContent.length / 1024).toStringAsFixed(2)} KB',
                style: const TextStyle(fontSize: 10, color: Colors.white60),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6),
        );
        // 导出后刷新模型数据
        setState(() {});
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (context.mounted) {
        String errorTitle = '导出失败';
        String errorMessage = e.toString();

        // Provide more helpful error messages
        if (e is FileSystemException) {
          errorTitle = '文件系统错误';
          if (e.message.contains('Permission denied')) {
            errorMessage = '权限不足: 无法写入该目录。请检查存储权限。';
          } else if (e.message.contains('No space')) {
            errorMessage = '磁盘空间不足。请清理存储空间。';
          } else {
            errorMessage = '文件操作失败: ${e.message}';
          }
        }

        _showStatusSnackBar(
          context,
          content: _buildStatusDetails(
            title: '❌ $errorTitle',
            details: [Text(errorMessage, style: const TextStyle(fontSize: 12))],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        );
      }
    }
  }

  void _showImportOptions(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.file_download, color: Colors.green),
              SizedBox(width: 8),
              Text('导入配置选项'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('请选择导入配置的方式：'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.folder, color: Colors.blue),
                title: const Text('从平台目录导入'),
                subtitle: FutureBuilder<_PlatformDirectoryInfo>(
                  future: _getChibotDirectory(),
                  builder: (context, snapshot) {
                    return Text(snapshot.data?.displayPath ?? '加载中...');
                  },
                ),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _importSettings(context, unifiedSettings);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.file_open, color: Colors.orange),
                title: const Text('手动选择文件'),
                subtitle: const Text('浏览文件系统选择配置文件'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _importSettingsFromFilePicker(context, unifiedSettings);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importSettingsFromFilePicker(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
  ) async {
    try {
      debugPrint('Starting file picker import...');

      // Use file picker to select XML config file
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Chibot配置文件',
        extensions: <String>['xml'],
        mimeTypes: <String>['text/xml', 'application/xml'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
        initialDirectory: await _getInitialDirectory(),
      );

      if (file == null) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '未选择文件',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }

      // Validate file name pattern
      final fileName = path.basename(file.path);
      if (!fileName.contains('chibot_config_') || !fileName.endsWith('.xml')) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '文件名格式不正确。期望: chibot_config_*.xml，实际: $fileName',
            backgroundColor: Colors.red,
          );
        }
        return;
      }

      // Read and validate the file content
      final xmlContent = await file.readAsString();
      debugPrint('XML content read: ${xmlContent.length} characters from $fileName');

      if (!_isValidSettingsXml(xmlContent)) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '无效的配置文件格式',
            backgroundColor: Colors.red,
          );
        }
        return;
      }

      // Show confirmation dialog
      if (!context.mounted) return;
      final confirmed = await _confirmImportFile(
        context,
        fileName: fileName,
        directoryPath: path.dirname(file.path),
        fileSizeKb: xmlContent.length / 1024,
        sourceLabel: '文件选择器',
      );

      if (confirmed) {
        debugPrint('User confirmed file picker import');
        await _applyImportedSettings(
          context,
          unifiedSettings,
          xmlContent: xmlContent,
          successDetails: [
            Text('来源: $fileName', style: const TextStyle(fontSize: 12)),
            const Text(
              '方式: 文件选择器',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        );
      } else {
        debugPrint('User cancelled file picker import');
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '导入已取消',
            backgroundColor: Colors.orange,
          );
        }
      }
    } catch (e) {
      debugPrint('File picker import error: $e');
      if (context.mounted) {
        _showStatusSnackBar(
          context,
          content: _buildStatusDetails(
            title: '❌ 导入失败',
            details: [
              Text(
                e is FileSystemException
                    ? '文件操作失败: ${e.message}'
                    : '导入失败: ${e.toString()}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        );
      }
    }
  }

  Future<String?> _getInitialDirectory() async {
    try {
      final directoryInfo = await _getChibotDirectory();
      if (await directoryInfo.directory.exists()) {
        return directoryInfo.directory.path;
      }
      if (Platform.isAndroid) {
        return '/storage/emulated/0/Download';
      }
      final documentsDir = await getApplicationDocumentsDirectory();
      return documentsDir.path;
    } catch (e) {
      debugPrint('Error getting initial directory: $e');
    }
    return null;
  }

  Future<void> _importSettings(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
  ) async {
    try {
      debugPrint('Starting import process...');
      final directoryInfo = await _getChibotDirectory();
      final importDir = directoryInfo.directory;

      // Check if directory exists
      if (!await importDir.exists()) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '未找到配置目录: ${importDir.path}',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }

      // Find all chibot_config_*.xml files
      final List<FileSystemEntity> files = await importDir.list().toList();
      final List<File> configFiles = [];

      for (final entity in files) {
        if (entity is File &&
            entity.path.contains('chibot_config_') &&
            entity.path.endsWith('.xml')) {
          configFiles.add(entity);
        }
      }

      // Sort files by modification time (newest first)
      configFiles.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      if (configFiles.isEmpty) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '在 ${importDir.path} 中未找到配置文件',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }

      // If multiple files found, show selection dialog
      File selectedFile;
      if (configFiles.length == 1) {
        selectedFile = configFiles.first;
      } else {
        // Show file selection dialog
        if (!context.mounted) return;
        final selectedIndex = await showDialog<int>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.folder_open, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('选择配置文件'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('找到 ${configFiles.length} 个配置文件:'),
                    const SizedBox(height: 12),
                    ...configFiles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      final fileName = path.basename(file.path);
                      final fileSize = (file.lengthSync() / 1024)
                          .toStringAsFixed(1);
                      final modifiedTime = DateTime.fromMillisecondsSinceEpoch(
                        file.lastModifiedSync().millisecondsSinceEpoch,
                      );
                      final timeString =
                          '${modifiedTime.year}-${modifiedTime.month.toString().padLeft(2, '0')}-${modifiedTime.day.toString().padLeft(2, '0')} ${modifiedTime.hour.toString().padLeft(2, '0')}:${modifiedTime.minute.toString().padLeft(2, '0')}';

                      return ListTile(
                        leading: const Icon(Icons.description),
                        title: Text(fileName),
                        subtitle: Text('大小: $fileSize KB | 修改时间: $timeString'),
                        onTap: () => Navigator.of(dialogContext).pop(index),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(-1),
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );

        if (selectedIndex == null || selectedIndex == -1) {
          if (context.mounted) {
            _showSimpleStatusMessage(
              context,
              message: '导入已取消',
              backgroundColor: Colors.orange,
            );
          }
          return;
        }
        selectedFile = configFiles[selectedIndex];
      }

      // Read and validate the selected file
      final xmlContent = await selectedFile.readAsString();
      debugPrint(
        'XML content read: ${xmlContent.length} characters from ${path.basename(selectedFile.path)}',
      );

      // Validate XML content
      if (!_isValidSettingsXml(xmlContent)) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '无效的配置文件格式',
            backgroundColor: Colors.red,
          );
        }
        return;
      }

      // Show confirmation dialog with file info
      if (!context.mounted) return;
      final confirmed = await _confirmImportFile(
        context,
        fileName: path.basename(selectedFile.path),
        directoryPath: path.dirname(selectedFile.path),
        fileSizeKb: xmlContent.length / 1024,
        platformLabel: directoryInfo.platformName,
      );

      if (confirmed) {
        debugPrint('User confirmed import');
        await _applyImportedSettings(
          context,
          unifiedSettings,
          xmlContent: xmlContent,
          successDetails: [
            Text(
              '来源: ${path.basename(selectedFile.path)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '位置: ${path.dirname(selectedFile.path)}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      } else {
        debugPrint('User cancelled import');
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '导入已取消',
            backgroundColor: Colors.orange,
          );
        }
      }
    } catch (e) {
      debugPrint('Import error: $e');
      if (context.mounted) {
        _showStatusSnackBar(
          context,
          content: _buildStatusDetails(
            title: '❌ 导入失败',
            details: [
              Text(
                e is FileSystemException
                    ? '文件操作失败: ${e.message}'
                    : '导入失败: ${e.toString()}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        );
      }
    }
  }
}
