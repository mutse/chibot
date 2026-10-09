part of '../settings_screen.dart';

/// provider_model_sections.dart - _SettingsScreenState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _ProviderModelSectionsExt on _SettingsScreenState {
  String _getProviderApiKey(
    ApiKeyProvider apiKeys,
    ChatModelProvider chatModel,
  ) {
    return apiKeys.getApiKeyForProvider(chatModel.selectedProvider) ?? '';
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
        return 'Claude API Key（Anthropic）';
      case 'Google':
        return 'Google API Key';
      default:
        return '${chatModel.selectedProvider} API Key';
    }
  }

  String _getApiKeyHint(ChatModelProvider chatModel, bool isImageMode) {
    if (isImageMode) {
      return l10n.enterYourAPIKey;
    }

    switch (chatModel.selectedProvider) {
      case 'OpenAI':
        return '输入 OpenAI API Key';
      case 'Anthropic':
        return '输入 Claude API Key';
      case 'Google':
        return '输入 Google API Key';
      default:
        return '输入 ${chatModel.selectedProvider} 的 API Key';
    }
  }

  Future<void> _saveProviderApiKey(
    ApiKeyProvider apiKeys,
    ChatModelProvider chatModel,
    String apiKey,
  ) async {
    await apiKeys.setApiKeyForProvider(chatModel.selectedProvider, apiKey);
  }

  Future<void> _saveImageProviderApiKey(
    ApiKeyProvider apiKeys,
    ImageModelProvider imageModel,
    String apiKey,
  ) async {
    await apiKeys.setImageApiKeyForProvider(
      imageModel.selectedImageProvider,
      apiKey,
    );
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
    if (_isTextLikeModelType(unifiedSettings.selectedModelType)) {
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

    if (_isTextLikeModelType(unifiedSettings.selectedModelType)) {
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

  Widget _buildModelTypeCard(UnifiedSettingsProvider unifiedSettings) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MobileSectionLabel(title: '工作模式'),
          const SizedBox(height: 6),
          Text(
            l10n.selectModelType,
            style: const TextStyle(
              color: MobilePalette.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GlassChip(
                label: l10n.textModel,
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
              GlassChip(
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
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MobileSectionLabel(
            title: l10n.addModelProvider,
            actionLabel: l10n.add,
            onAction: () {
              _showAddProviderAndModelDialog(
                context,
                unifiedSettings,
                unifiedSettings.selectedModelType,
              );
            },
          ),
          const SizedBox(height: 6),
          const Text(
            '添加自定义厂商、模型、Base URL 和 API key。文本模型默认按 OpenAI 兼容接口接入。',
            style: TextStyle(color: MobilePalette.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSettingsSection(SearchProvider search) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MobileSectionLabel(title: '搜索'),
        const SizedBox(height: 12),
        SettingsSwitchRow(
          title: 'Tavily Web 搜索',
          subtitle: '为聊天启用增强型网页检索',
          value: search.tavilySearchEnabled,
          onChanged: (value) {
            search.setTavilySearchEnabled(value);
          },
        ),
        if (search.tavilySearchEnabled) ...[
          const SizedBox(height: 12),
          SimpleFieldSection(
            title: 'Tavily API Key',
            field: GlassTextField(
              controller: _tavilyApiKeyController,
              hintText: '输入 Tavily API Key',
              obscureText: true,
            ),
          ),
          const SizedBox(height: 14),
        ],
        SettingsSwitchRow(
          title: 'Google 搜索',
          subtitle: '使用自定义搜索返回网页结果',
          value: search.googleSearchEnabled,
          onChanged: (value) {
            search.setGoogleSearchEnabled(value);
          },
        ),
        if (search.googleSearchEnabled) ...[
          const SizedBox(height: 12),
          SimpleFieldSection(
            title: 'Google Search API Key',
            field: GlassTextField(
              controller: _googleSearchApiKeyController,
              hintText: '输入 Google 自定义搜索 API Key',
              obscureText: true,
            ),
          ),
          const SizedBox(height: 14),
          SimpleFieldSection(
            title: 'Google Search Engine ID',
            field: GlassTextField(
              controller: _googleSearchEngineIdController,
              hintText: '输入自定义搜索引擎 ID',
            ),
          ),
          const SizedBox(height: 14),
          SettingsSectionTitle('搜索结果数量'),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MobilePalette.primary,
              inactiveTrackColor: MobilePalette.border,
              thumbColor: MobilePalette.primary,
              overlayColor: MobilePalette.primary.withValues(alpha: 0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: search.googleSearchResultCount.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: search.googleSearchResultCount.toString(),
              onChanged: (value) {
                search.setGoogleSearchResultCount(value.toInt());
              },
            ),
          ),
          Text(
            '当前返回 ${search.googleSearchResultCount} 条结果',
            style: const TextStyle(
              color: MobilePalette.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          SimpleFieldSection(
            title: '搜索提供商',
            field: GlassDropdown<String>(
              value: search.googleSearchProvider,
              items: const [
                DropdownMenuItem(
                  value: 'googleCustomSearch',
                  child: Text('Google 自定义搜索 API'),
                ),
                DropdownMenuItem(
                  value: 'programmableSearch',
                  child: Text('可编程搜索引擎'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  search.setGoogleSearchProvider(value);
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextSettingsSection({
    required ApiKeyProvider apiKeys,
    required ChatModelProvider chatModel,
    required ImageModelProvider imageModel,
    required SettingsModelsProvider settingsModels,
    required UnifiedSettingsProvider unifiedSettings,
  }) {
    final availableTextModels =
        settingsModels.textModels
            .where((model) => model.provider == chatModel.selectedProvider)
            .toList();
    final selectedModel =
        availableTextModels.any((model) => model.id == chatModel.selectedModel)
            ? chatModel.selectedModel
            : (availableTextModels.isNotEmpty
                ? availableTextModels.first.id
                : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionTitle(l10n.selectModelProvider),
              const SizedBox(height: 12),
              GlassDropdown<String>(
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
                          isCustom ? '$provider（OpenAI 兼容）' : provider,
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
        GlassCard(
          child: SimpleFieldSection(
            title: l10n.modelProviderURLOptional,
            helperText:
                ChatModelProvider.defaultBaseUrls.containsKey(
                      chatModel.selectedProvider,
                    )
                    ? l10n.defaultUrl(
                      ChatModelProvider.defaultBaseUrls[chatModel
                              .selectedProvider] ??
                          '',
                    )
                    : '兼容 OpenAI 的 Base URL，例如 http://localhost:11434/v1',
            field: GlassTextField(
              controller: _providerUrlController,
              hintText: '例如：http://localhost:11434/v1',
              keyboardType: TextInputType.url,
            ),
          ),
        ),
        GlassCard(
          child: SimpleFieldSection(
            title: _getApiKeyLabel(
              chatModel,
              imageModel,
              unifiedSettings.selectedModelType ==
                  available_model.ModelType.image,
            ),
            field: GlassTextField(
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
        GlassCard(
          child: SimpleFieldSection(
            title: l10n.selectModel,
            field: GlassDropdown<String>(
              value: selectedModel,
              items:
                  availableTextModels.map((model) {
                    return DropdownMenuItem<String>(
                      value: model.id,
                      child: Text(model.name),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  chatModel.setSelectedModel(newValue);
                }
              },
              hintText:
                  availableTextModels.isEmpty ? l10n.noModelsAvailable : null,
            ),
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionTitle(l10n.customModels),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassTextField(
                      controller: _customModelController,
                      hintText: l10n.enterCustomModelName,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InlineActionButton(
                    icon: Icons.add_rounded,
                    tooltip: l10n.add,
                    onTap: () {
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
              if (chatModel.customModels.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.yourCustomModels,
                  style: const TextStyle(
                    color: MobilePalette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...chatModel.customModels.map(
                  (model) => ModelListTile(
                    title: model,
                    onDelete: () {
                      chatModel.removeCustomModel(model);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSettingsSection({
    required ApiKeyProvider apiKeys,
    required ImageModelProvider imageModel,
    required SettingsModelsProvider settingsModels,
  }) {
    final availableImageModels =
        settingsModels.imageModels
            .where(
              (model) => model.provider == imageModel.selectedImageProvider,
            )
            .toList();
    final selectedModel =
        availableImageModels.any(
              (model) => model.id == imageModel.selectedImageModel,
            )
            ? imageModel.selectedImageModel
            : (availableImageModels.isNotEmpty
                ? availableImageModels.first.id
                : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: SimpleFieldSection(
            title: l10n.selectModelProvider,
            field: GlassDropdown<String>(
              value:
                  imageModel.allImageProviderNames.contains(
                        imageModel.selectedImageProvider,
                      )
                      ? imageModel.selectedImageProvider
                      : (imageModel.allImageProviderNames.isNotEmpty
                          ? imageModel.allImageProviderNames.first
                          : null),
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
          ),
        ),
        GlassCard(
          child: SimpleFieldSection(
            title: l10n.modelProviderURLOptional,
            helperText: l10n.defaultUrl(
              ImageModelProvider.defaultImageBaseUrls['OpenAI'] ?? '',
            ),
            field: GlassTextField(
              controller: _imageProviderUrlController,
              hintText: '例如：https://api.stability.ai',
              keyboardType: TextInputType.url,
            ),
          ),
        ),
        GlassCard(
          child: SimpleFieldSection(
            title: l10n.apiKey(imageModel.selectedImageProvider),
            field: GlassTextField(
              controller: _apiKeyController,
              hintText: l10n.enterYourAPIKey,
              obscureText: true,
              onClear: () async {
                setState(() {
                  _apiKeyController.clear();
                });
                await _saveImageProviderApiKey(apiKeys, imageModel, '');
              },
            ),
          ),
        ),
        GlassCard(
          child: SimpleFieldSection(
            title: l10n.selectModel,
            field: GlassDropdown<String>(
              value: selectedModel,
              items:
                  availableImageModels.map((model) {
                    return DropdownMenuItem<String>(
                      value: model.id,
                      child: Text(model.name),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  imageModel.setSelectedImageModel(newValue);
                }
              },
              hintText:
                  availableImageModels.isEmpty ? l10n.noModelsAvailable : null,
            ),
          ),
        ),
        if (imageModel.selectedImageProvider == 'Black Forest Labs') ...[
          GlassCard(
            child: SimpleFieldSection(
              title: l10n.aspectRatio,
              field: GlassDropdown<String>(
                value: imageModel.bflAspectRatio ?? '1:1',
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
            ),
          ),
        ],
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionTitle(l10n.customModels),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassTextField(
                      controller: _customModelController,
                      hintText: l10n.enterCustomModelName,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InlineActionButton(
                    icon: Icons.add_rounded,
                    tooltip: l10n.add,
                    onTap: () {
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
              if (imageModel.customImageModels.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.yourCustomModels,
                  style: const TextStyle(
                    color: MobilePalette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...imageModel.customImageModels.map(
                  (model) => ModelListTile(
                    title: model,
                    onDelete: () {
                      imageModel.removeCustomImageModel(model);
                    },
                  ),
                ),
              ],
            ],
          ),
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
        GlassCard(
          child: SimpleFieldSection(
            title: l10n.selectModelProvider,
            field: GlassDropdown<String>(
              value: videoModel.selectedVideoProvider,
              items: const [
                DropdownMenuItem(
                  value: 'Google Veo3',
                  child: Text('Google Veo3'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  videoModel.setSelectedVideoProvider(newValue);
                }
              },
            ),
          ),
        ),
        GlassCard(
          child: SimpleFieldSection(
            title: 'Google Veo3 API Key',
            field: GlassTextField(
              controller: _apiKeyController,
              hintText: '输入 Google Veo3 API Key',
              obscureText: true,
              onClear: () async {
                setState(() {
                  _apiKeyController.clear();
                });
                await apiKeys.setGoogleApiKey('');
              },
            ),
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MobileSectionLabel(title: '视频输出'),
              const SizedBox(height: 12),
              SimpleFieldSection(
                title: '视频分辨率',
                field: GlassDropdown<String>(
                  value: videoModel.videoResolution,
                  items: const [
                    DropdownMenuItem(
                      value: '480p',
                      child: Text('480p (854×480)'),
                    ),
                    DropdownMenuItem(
                      value: '720p',
                      child: Text('720p 高清 (1280×720)'),
                    ),
                    DropdownMenuItem(
                      value: '1080p',
                      child: Text('1080p 全高清 (1920×1080)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      videoModel.setVideoResolution(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              SimpleFieldSection(
                title: '视频时长',
                field: GlassDropdown<String>(
                  value: videoModel.videoDuration,
                  items: const [
                    DropdownMenuItem(value: '5s', child: Text('5 秒')),
                    DropdownMenuItem(value: '10s', child: Text('10 秒')),
                    DropdownMenuItem(value: '30s', child: Text('30 秒')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      videoModel.setVideoDuration(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              SimpleFieldSection(
                title: '视频质量',
                field: GlassDropdown<String>(
                  value: videoModel.videoQuality,
                  items: const [
                    DropdownMenuItem(value: 'standard', child: Text('标准质量')),
                    DropdownMenuItem(value: 'high', child: Text('高质量')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      videoModel.setVideoQuality(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              SimpleFieldSection(
                title: '视频比例',
                field: GlassDropdown<String>(
                  value: videoModel.videoAspectRatio,
                  items: const [
                    DropdownMenuItem(value: '16:9', child: Text('16:9（横屏）')),
                    DropdownMenuItem(value: '9:16', child: Text('9:16（竖屏）')),
                    DropdownMenuItem(value: '1:1', child: Text('1:1（方形）')),
                    DropdownMenuItem(value: '4:3', child: Text('4:3（传统）')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      videoModel.setVideoAspectRatio(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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
}
