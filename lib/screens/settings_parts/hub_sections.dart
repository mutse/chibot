part of '../settings_screen.dart';

/// hub_sections.dart - _SettingsScreenState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _HubSectionsExt on _SettingsScreenState {
  Widget _buildModelsBody({
    required BuildContext context,
    required UnifiedSettingsProvider unifiedSettings,
    required SettingsModelsProvider settingsModels,
    required ApiKeyProvider apiKeys,
    required ChatModelProvider chatModel,
    required ImageModelProvider imageModel,
    required VideoModelProvider videoModel,
    required SearchProvider search,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: <Widget>[
        _buildModelTypeCard(unifiedSettings),
        _buildAddProviderCard(context, unifiedSettings),
        if (_isTextLikeModelType(unifiedSettings.selectedModelType)) ...[
          _buildTextSettingsSection(
            apiKeys: apiKeys,
            chatModel: chatModel,
            imageModel: imageModel,
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
          _buildVideoSettingsSection(apiKeys: apiKeys, videoModel: videoModel),
        ],
        const SizedBox(height: 8),
        _buildActionPanel(
          context: context,
          unifiedSettings: unifiedSettings,
          apiKeys: apiKeys,
          chatModel: chatModel,
          imageModel: imageModel,
          search: search,
        ),
      ],
    );
  }

  Widget _buildSearchActionPanel({
    required BuildContext context,
    required SearchProvider search,
  }) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: GlassButton(
          label: l10n.saveSettings,
          icon: Icons.save_outlined,
          backgroundColor: MobilePalette.primary,
          onPressed: () async {
            await _saveSearchSettings(search);
            if (!mounted || !context.mounted) return;
            _showSettingsSavedSnackBar(context);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchBody({
    required BuildContext context,
    required SearchProvider search,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MobileSectionLabel(title: '搜索概览'),
              const SizedBox(height: 6),
              Text(
                _searchStatusLabel(search),
                style: const TextStyle(
                  color: MobilePalette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '在这里管理网页搜索引擎、相关 API key 和结果条数。',
                style: TextStyle(
                  color: MobilePalette.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        GlassCard(child: _buildSearchSettingsSection(search)),
        _buildSearchActionPanel(context: context, search: search),
      ],
    );
  }

  Widget _buildDataToolsPanel({
    required BuildContext context,
    required UnifiedSettingsProvider unifiedSettings,
  }) {
    final exportButton = GlassButton(
      label: l10n.exportConfig,
      icon: Icons.file_upload_outlined,
      backgroundColor: MobilePalette.textPrimary,
      onPressed: () => _exportSettings(context, unifiedSettings),
    );
    final importButton = GlassButton(
      label: l10n.importConfig,
      icon: Icons.file_download_outlined,
      backgroundColor: MobilePalette.secondary,
      onPressed: () => _showImportOptions(context, unifiedSettings),
    );

    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          if (isWide) {
            return Row(
              children: [
                Expanded(child: exportButton),
                const SizedBox(width: 12),
                Expanded(child: importButton),
              ],
            );
          }

          return Column(
            children: [
              SizedBox(width: double.infinity, child: exportButton),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: importButton),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDataBody({
    required BuildContext context,
    required UnifiedSettingsProvider unifiedSettings,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MobileSectionLabel(title: '配置文件'),
              const SizedBox(height: 6),
              const Text(
                '导出当前配置用于备份，或导入 XML 文件恢复现有设置。',
                style: TextStyle(
                  color: MobilePalette.textSecondary,
                  fontSize: 12,
                ),
              ),
              _buildSummaryRow(
                icon: Icons.file_upload_outlined,
                label: '导出',
                value: '备份当前模型、搜索、API key 和自定义配置',
              ),
              _buildSummaryRow(
                icon: Icons.file_download_outlined,
                label: '导入',
                value: '从已有 XML 配置恢复应用设置',
                accentColor: MobilePalette.secondary,
              ),
            ],
          ),
        ),
        _buildDataToolsPanel(
          context: context,
          unifiedSettings: unifiedSettings,
        ),
      ],
    );
  }

  Widget _buildLegacyFormBody({
    required BuildContext context,
    required UnifiedSettingsProvider unifiedSettings,
    required SettingsModelsProvider settingsModels,
    required ApiKeyProvider apiKeys,
    required ChatModelProvider chatModel,
    required ImageModelProvider imageModel,
    required VideoModelProvider videoModel,
    required SearchProvider search,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: <Widget>[
        const GitHubPluginSettings(),
        _buildModelTypeCard(unifiedSettings),
        _buildAddProviderCard(context, unifiedSettings),
        if (_isTextLikeModelType(unifiedSettings.selectedModelType)) ...[
          _buildTextSettingsSection(
            apiKeys: apiKeys,
            chatModel: chatModel,
            imageModel: imageModel,
            settingsModels: settingsModels,
            unifiedSettings: unifiedSettings,
          ),
          GlassCard(child: _buildSearchSettingsSection(search)),
        ] else if (unifiedSettings.selectedModelType ==
            available_model.ModelType.image) ...[
          _buildImageSettingsSection(
            apiKeys: apiKeys,
            imageModel: imageModel,
            settingsModels: settingsModels,
          ),
        ] else if (unifiedSettings.selectedModelType ==
            available_model.ModelType.video) ...[
          _buildVideoSettingsSection(apiKeys: apiKeys, videoModel: videoModel),
        ],
        const SizedBox(height: 8),
        _buildActionPanel(
          context: context,
          unifiedSettings: unifiedSettings,
          apiKeys: apiKeys,
          chatModel: chatModel,
          imageModel: imageModel,
          search: search,
        ),
      ],
    );
  }

  Widget _buildActionPanel({
    required BuildContext context,
    required UnifiedSettingsProvider unifiedSettings,
    required ApiKeyProvider apiKeys,
    required ChatModelProvider chatModel,
    required ImageModelProvider imageModel,
    required SearchProvider search,
  }) {
    final exportButton = GlassButton(
      label: l10n.exportConfig,
      icon: Icons.file_upload_outlined,
      backgroundColor: MobilePalette.textPrimary,
      onPressed: () => _exportSettings(context, unifiedSettings),
    );
    final importButton = GlassButton(
      label: l10n.importConfig,
      icon: Icons.file_download_outlined,
      backgroundColor: MobilePalette.secondary,
      onPressed: () => _showImportOptions(context, unifiedSettings),
    );
    final saveButton = GlassButton(
      label: l10n.saveSettings,
      icon: Icons.save_outlined,
      backgroundColor: MobilePalette.primary,
      onPressed: () async {
        await _saveSettingsForSelectedMode(
          apiKeys: apiKeys,
          chatModel: chatModel,
          imageModel: imageModel,
          search: search,
          unifiedSettings: unifiedSettings,
        );

        if (!mounted || !context.mounted) return;
        chatModel.syncModelsToRegistry();
        _showSettingsSavedSnackBar(context);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
    );

    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;

          if (isWide) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: exportButton),
                    const SizedBox(width: 12),
                    Expanded(child: importButton),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: saveButton),
              ],
            );
          }

          return Column(
            children: [
              SizedBox(width: double.infinity, child: exportButton),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: importButton),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: saveButton),
            ],
          );
        },
      ),
    );
  }
}
