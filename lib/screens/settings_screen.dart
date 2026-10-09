import '../widgets/github_plugin_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/chat_model_provider.dart';
import 'package:chibot/providers/image_model_provider.dart';
import 'package:chibot/providers/video_model_provider.dart';
import 'package:chibot/providers/search_provider.dart';
import 'package:chibot/providers/settings_models_provider.dart';
import 'package:chibot/providers/unified_settings_provider.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'package:chibot/screens/about_screen.dart';
import 'package:chibot/screens/update_dialog.dart';
import 'package:chibot/services/update_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:chibot/models/available_model.dart' as available_model;
import 'package:chibot/widgets/mobile_ui.dart';
part 'settings_parts/overview_section.dart';
part 'settings_parts/provider_model_sections.dart';
part 'settings_parts/hub_sections.dart';
part 'settings_parts/data_io.dart';

enum SettingsScreenSection { overview, models, search, data, plugins }

class SettingsScreen extends StatefulWidget {
  final SettingsScreenSection section;
  final VoidCallback? onOpenAppMenu;

  const SettingsScreen({
    super.key,
    this.section = SettingsScreenSection.overview,
    this.onOpenAppMenu,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  late AppLocalizations l10n;
  late TextEditingController _apiKeyController;

  bool get _isMobileSettingsHub =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isWindows ||
      Platform.isMacOS ||
      Platform.isLinux;

  bool get _showsOverviewHub =>
      _isMobileSettingsHub && widget.section == SettingsScreenSection.overview;

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

    late final Widget body;
    if (_showsOverviewHub) {
      body = _buildOverviewBody(
        unifiedSettings: unifiedSettings,
        apiKeys: apiKeys,
        chatModel: chatModel,
        imageModel: imageModel,
        videoModel: videoModel,
        search: search,
      );
    } else if (widget.section == SettingsScreenSection.plugins) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: const [GitHubPluginSettings()],
      );
    } else if (widget.section == SettingsScreenSection.models) {
      body = _buildModelsBody(
        context: context,
        unifiedSettings: unifiedSettings,
        settingsModels: settingsModels,
        apiKeys: apiKeys,
        chatModel: chatModel,
        imageModel: imageModel,
        videoModel: videoModel,
        search: search,
      );
    } else if (widget.section == SettingsScreenSection.search) {
      body = _buildSearchBody(context: context, search: search);
    } else if (widget.section == SettingsScreenSection.data) {
      body = _buildDataBody(context: context, unifiedSettings: unifiedSettings);
    } else {
      body = _buildLegacyFormBody(
        context: context,
        unifiedSettings: unifiedSettings,
        settingsModels: settingsModels,
        apiKeys: apiKeys,
        chatModel: chatModel,
        imageModel: imageModel,
        videoModel: videoModel,
        search: search,
      );
    }

    // Ask the enclosing route, not the navigator: when embedded in the home
    // shell this screen is on the root route even if other routes are pushed.
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final Widget leading;
    if (canPop) {
      leading = MobileIconCircleButton(
        icon: Icons.arrow_back_ios_new_rounded,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onTap: () => Navigator.maybePop(context),
      );
    } else if (widget.onOpenAppMenu != null) {
      leading = MobileIconCircleButton(
        icon: Icons.menu_rounded,
        tooltip: '打开菜单',
        onTap: widget.onOpenAppMenu,
      );
    } else {
      leading = const MobileIconCircleButton(icon: Icons.settings_outlined);
    }

    return Scaffold(
      backgroundColor: MobilePalette.background,
      body: DecoratedBox(
        decoration: buildMobileBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              MobileTopBar(
                leading: leading,
                title: _pageTitle(),
                subtitle: _pageSubtitle(),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

}
