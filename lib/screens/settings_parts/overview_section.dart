part of '../settings_screen.dart';

/// overview_section.dart - _SettingsScreenState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _OverviewSectionExt on _SettingsScreenState {
  bool _isTextLikeModelType(available_model.ModelType type) {
    return type == available_model.ModelType.text ||
        type == available_model.ModelType.customOpenAI;
  }

  String _pageTitle() {
    switch (widget.section) {
      case SettingsScreenSection.plugins:
        return l10n.plugins;
      case SettingsScreenSection.models:
        return '模型';
      case SettingsScreenSection.search:
        return '搜索';
      case SettingsScreenSection.data:
        return '配置';
      case SettingsScreenSection.overview:
        return l10n.settings;
    }
  }

  String _pageSubtitle() {
    switch (widget.section) {
      case SettingsScreenSection.plugins:
        return l10n.plugins;
      case SettingsScreenSection.models:
        return '管理提供商、模型和 API Key';
      case SettingsScreenSection.search:
        return '管理网页搜索引擎及相关密钥';
      case SettingsScreenSection.data:
        return '导入或导出应用配置';
      case SettingsScreenSection.overview:
        return _isMobileSettingsHub
            ? '模型、搜索、备份、应用信息与服务状态'
            : 'API Key、模型、提供商与搜索设置';
    }
  }

  void _openSection(SettingsScreenSection section) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SettingsScreen(section: section)));
  }

  void _openAbout() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
  }

  Future<void> _checkForUpdates() async {
    final release = await UpdateService.fetchLatestRelease();
    if (!mounted) return;

    if (release == null) {
      _showSimpleStatusMessage(
        context,
        message: '检查更新失败，请稍后重试',
        backgroundColor: Colors.red,
      );
      return;
    }

    final latestVersion = release['tag_name'] ?? '';
    final downloadUrl = UpdateService.getDownloadUrl(release);
    if (downloadUrl == null) {
      _showSimpleStatusMessage(
        context,
        message: '未找到适用于当前平台的安装包',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final fileName = downloadUrl.split('/').last;
    final releaseNotes = release['body'] ?? '';
    showDialog(
      context: context,
      builder:
          (_) => UpdateDialog(
            latestVersion: latestVersion,
            releaseNotes: releaseNotes,
            downloadUrl: downloadUrl,
            fileName: fileName,
          ),
    );
  }

  String _modelTypeLabel(available_model.ModelType type) {
    switch (type) {
      case available_model.ModelType.text:
        return l10n.textModel;
      case available_model.ModelType.image:
        return l10n.imageModel;
      case available_model.ModelType.video:
        return '视频模型';
      case available_model.ModelType.customOpenAI:
        return '自定义 OpenAI';
    }
  }

  String _searchStatusLabel(SearchProvider search) {
    final active = <String>[];
    if (search.tavilySearchEnabled) {
      active.add('Tavily');
    }
    if (search.googleSearchEnabled) {
      active.add('Google');
    }
    if (active.isEmpty) {
      return '未启用搜索引擎';
    }

    final suffix =
        search.googleSearchEnabled
            ? ' • ${search.googleSearchResultCount} 条结果'
            : '';
    return '${active.join(' + ')}$suffix';
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MobilePalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (accentColor ?? MobilePalette.primary).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: accentColor ?? MobilePalette.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: MobilePalette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: MobilePalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewLinkCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String detail,
    required VoidCallback onTap,
    Color accentColor = MobilePalette.primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: MobilePalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: MobilePalette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: MobilePalette.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              detail,
              style: const TextStyle(
                color: MobilePalette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewHeroCard({
    required UnifiedSettingsProvider unifiedSettings,
    required ChatModelProvider chatModel,
    required ImageModelProvider imageModel,
    required VideoModelProvider videoModel,
    required SearchProvider search,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MobileSectionLabel(title: '快速总览'),
          const SizedBox(height: 6),
          Text(
            '把模型配置、搜索能力和配置备份集中到一个入口里。',
            style: const TextStyle(
              color: MobilePalette.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GlassChip(
                label: _modelTypeLabel(available_model.ModelType.text),
                selected: _isTextLikeModelType(
                  unifiedSettings.selectedModelType,
                ),
                onSelected: (selected) {
                  if (selected) {
                    unifiedSettings.setSelectedModelType(
                      available_model.ModelType.text,
                    );
                  }
                },
              ),
              GlassChip(
                label: _modelTypeLabel(available_model.ModelType.image),
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
              GlassChip(
                label: _modelTypeLabel(available_model.ModelType.video),
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
          _buildSummaryRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: '聊天',
            value: '${chatModel.selectedProvider} • ${chatModel.selectedModel}',
          ),
          _buildSummaryRow(
            icon: Icons.image_outlined,
            label: '图片',
            value:
                '${imageModel.selectedImageProvider} • ${imageModel.selectedImageModel}',
            accentColor: MobilePalette.secondary,
          ),
          _buildSummaryRow(
            icon: Icons.smart_display_outlined,
            label: '视频',
            value:
                '${videoModel.selectedVideoProvider} • ${videoModel.videoResolution} • ${videoModel.videoAspectRatio}',
            accentColor: MobilePalette.textPrimary,
          ),
          _buildSummaryRow(
            icon: Icons.travel_explore_rounded,
            label: '搜索',
            value: _searchStatusLabel(search),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderHealthRow({
    required String title,
    required bool connected,
    required String usageLabel,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MobilePalette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                connected
                    ? MobilePalette.primarySoft
                    : MobilePalette.surfaceStrong,
            child: Icon(
              connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              size: 16,
              color:
                  connected
                      ? MobilePalette.primary
                      : MobilePalette.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: MobilePalette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            usageLabel,
            style: TextStyle(
              color:
                  connected
                      ? MobilePalette.primary
                      : MobilePalette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderHealthCard({
    required ApiKeyProvider apiKeys,
    required ChatModelProvider chatModel,
    required ImageModelProvider imageModel,
  }) {
    bool hasKey(String? key) => key != null && key.trim().isNotEmpty;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MobileSectionLabel(title: '服务状态'),
          const SizedBox(height: 6),
          const Text(
            '快速查看当前常用服务是否已经完成连接。',
            style: TextStyle(color: MobilePalette.textSecondary, fontSize: 12),
          ),
          _buildProviderHealthRow(
            title: 'OpenAI',
            connected: hasKey(apiKeys.openaiApiKey),
            usageLabel:
                chatModel.selectedProvider == 'OpenAI'
                    ? '聊天中'
                    : imageModel.selectedImageProvider == 'OpenAI'
                    ? '图片中'
                    : '就绪',
          ),
          _buildProviderHealthRow(
            title: 'Google',
            connected: hasKey(apiKeys.googleApiKey),
            usageLabel:
                chatModel.selectedProvider == 'Google'
                    ? '聊天中'
                    : imageModel.selectedImageProvider == 'Google'
                    ? '图片中'
                    : '视频中',
          ),
          _buildProviderHealthRow(
            title: 'Anthropic',
            connected: hasKey(apiKeys.claudeApiKey),
            usageLabel:
                chatModel.selectedProvider == 'Anthropic' ? '聊天中' : '就绪',
          ),
          _buildProviderHealthRow(
            title: 'Black Forest Labs',
            connected: hasKey(apiKeys.fluxKontextApiKey),
            usageLabel:
                imageModel.selectedImageProvider == 'Black Forest Labs'
                    ? '图片中'
                    : '就绪',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewBody({
    required UnifiedSettingsProvider unifiedSettings,
    required ApiKeyProvider apiKeys,
    required ChatModelProvider chatModel,
    required ImageModelProvider imageModel,
    required VideoModelProvider videoModel,
    required SearchProvider search,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: [
        _buildOverviewHeroCard(
          unifiedSettings: unifiedSettings,
          chatModel: chatModel,
          imageModel: imageModel,
          videoModel: videoModel,
          search: search,
        ),
        _buildOverviewLinkCard(
          icon: Icons.extension_outlined,
          title: l10n.plugins,
          subtitle: l10n.githubPluginDescription,
          detail: 'GitHub',
          onTap: () => _openSection(SettingsScreenSection.plugins),
        ),
        _buildOverviewLinkCard(
          icon: Icons.layers_outlined,
          title: '模型',
          subtitle: '提供商、模型选择、API Key 与自定义模型',
          detail: '当前模式：${_modelTypeLabel(unifiedSettings.selectedModelType)}',
          onTap: () => _openSection(SettingsScreenSection.models),
        ),
        _buildOverviewLinkCard(
          icon: Icons.travel_explore_rounded,
          title: '搜索',
          subtitle: 'Tavily、Google 自定义搜索与结果控制',
          detail: _searchStatusLabel(search),
          accentColor: MobilePalette.secondary,
          onTap: () => _openSection(SettingsScreenSection.search),
        ),
        _buildOverviewLinkCard(
          icon: Icons.import_export_rounded,
          title: '配置与备份',
          subtitle: '导入和导出 XML 配置文件',
          detail: '在不改变功能的前提下迁移或恢复设置',
          accentColor: MobilePalette.textPrimary,
          onTap: () => _openSection(SettingsScreenSection.data),
        ),
        _buildOverviewLinkCard(
          icon: Icons.info_outline_rounded,
          title: '关于',
          subtitle: '版本信息、功能特性与支持说明',
          detail: '查看当前版本与应用能力',
          accentColor: const Color(0xFF31586E),
          onTap: _openAbout,
        ),
        _buildOverviewLinkCard(
          icon: Icons.system_update_alt_rounded,
          title: '检查更新',
          subtitle: '查找当前平台可用的最新安装包',
          detail: '有新版本时可直接下载更新',
          accentColor: MobilePalette.secondary,
          onTap: _checkForUpdates,
        ),
        _buildProviderHealthCard(
          apiKeys: apiKeys,
          chatModel: chatModel,
          imageModel: imageModel,
        ),
      ],
    );
  }
}
