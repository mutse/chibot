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

class _SettingsScreenState extends State<SettingsScreen> {
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
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
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
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                suffixIcon: onClear != null
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.black.withOpacity(0.5),
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
          color: selected
              ? Colors.white.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withOpacity(0.35)
                  : Colors.white.withOpacity(0.15),
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
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
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
                color: Colors.black.withOpacity(0.6),
              ),
              style: const TextStyle(color: Colors.black87),
              dropdownColor: Colors.white.withOpacity(0.95),
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
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                colors: backgroundColor != null
                    ? [
                        backgroundColor.withOpacity(0.8),
                        backgroundColor.withOpacity(0.6),
                      ]
                    : [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
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
      text: apiKeys.tavilyApiKey ?? '',
    );
    _googleSearchApiKeyController = TextEditingController(
      text: apiKeys.googleSearchApiKey ?? '',
    );
    _googleSearchEngineIdController = TextEditingController(
      text: search.googleSearchEngineId ?? '',
    );
  }

  String _getProviderApiKey(ApiKeyProvider apiKeys, ChatModelProvider chatModel) {
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

  String _getApiKeyLabel(ChatModelProvider chatModel, ImageModelProvider imageModel, bool isImageMode) {
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

  Future<void> _saveProviderApiKey(ApiKeyProvider apiKeys, ChatModelProvider chatModel, String apiKey) async {
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

  Future<void> _saveImageProviderApiKey(ApiKeyProvider apiKeys, ImageModelProvider imageModel, String apiKey) async {
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

  @override
  Widget build(BuildContext context) {
    final unifiedSettings = Provider.of<UnifiedSettingsProvider>(context);
    final settingsModels = Provider.of<SettingsModelsProvider>(context);
    final apiKeys = Provider.of<ApiKeyProvider>(context);
    final chatModel = Provider.of<ChatModelProvider>(context);
    final imageModel = Provider.of<ImageModelProvider>(context);
    final videoModel = Provider.of<VideoModelProvider>(context);
    final search = Provider.of<SearchProvider>(context);

    // 动态切换 API Key Controller 内容 - now provider-aware
    String expectedApiKey;
    if (unifiedSettings.selectedModelType == available_model.ModelType.text) {
      expectedApiKey = _getProviderApiKey(apiKeys, chatModel);
    } else if (unifiedSettings.selectedModelType == available_model.ModelType.image) {
      expectedApiKey = apiKeys.getImageApiKeyForProvider(imageModel.selectedImageProvider) ?? '';
    } else if (unifiedSettings.selectedModelType == available_model.ModelType.video) {
      expectedApiKey = apiKeys.googleApiKey ?? '';
    } else {
      expectedApiKey = _getProviderApiKey(apiKeys, chatModel);
    }
    if (_apiKeyController.text != expectedApiKey) {
      _apiKeyController.text = expectedApiKey;
    }

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
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.15),
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
              Colors.blue.withOpacity(0.05),
              Colors.purple.withOpacity(0.05),
              Colors.pink.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectModelType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildGlassChip(
                          label: l10n.textModel,
                          selected: unifiedSettings.selectedModelType ==
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
                          selected: unifiedSettings.selectedModelType ==
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
                          label: '视频模型', // TODO: Use l10n.videoModel after localization regeneration
                          selected: unifiedSettings.selectedModelType ==
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
              ),
              _buildGlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.selectModelProvider,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
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
              ),
              if (unifiedSettings.selectedModelType ==
                  available_model.ModelType.text) ...[
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
                        value: chatModel.allProviderNames.contains(
                              chatModel.selectedProvider,
                            )
                            ? chatModel.selectedProvider
                            : (chatModel.allProviderNames.isNotEmpty
                                ? chatModel.allProviderNames.first
                                : null),
                        items: chatModel.allProviderNames.map((String provider) {
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
                            _apiKeyController.text = _getProviderApiKey(apiKeys, chatModel);
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ),
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.modelProviderURLOptional,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.defaultUrl(
                          ChatModelProvider.defaultBaseUrls['OpenAI'] ?? '',
                        ),
                        style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 12),
                      _buildGlassTextField(
                        controller: _providerUrlController,
                        hintText: 'e.g., http://localhost:11434/v1',
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getApiKeyLabel(chatModel, imageModel, unifiedSettings.selectedModelType == available_model.ModelType.image),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGlassTextField(
                        controller: _apiKeyController,
                        hintText: _getApiKeyHint(chatModel, unifiedSettings.selectedModelType == available_model.ModelType.image),
                        obscureText: true,
                        onClear: () async {
                          setState(() {
                            _apiKeyController.clear();
                          });
                          await _saveProviderApiKey(apiKeys, chatModel, '');
                        },
                      ),
                    ],
                  ),
                ),
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectModel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGlassDropdown<String>(
                        value: settingsModels.textModels
                                .where(
                                  (m) => m.provider == chatModel.selectedProvider,
                                )
                                .any((m) => m.id == chatModel.selectedModel)
                            ? chatModel.selectedModel
                            : (settingsModels.textModels
                                    .where(
                                      (m) =>
                                          m.provider == chatModel.selectedProvider,
                                    )
                                    .isNotEmpty
                                ? settingsModels.textModels
                                    .where(
                                      (m) =>
                                          m.provider == chatModel.selectedProvider,
                                    )
                                    .first
                                    .id
                                : null),
                        items: settingsModels.textModels
                            .where(
                              (model) =>
                                  model.provider == chatModel.selectedProvider,
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
                        hintText: settingsModels.textModels
                                .where(
                                  (m) => m.provider == chatModel.selectedProvider,
                                )
                                .isEmpty
                            ? l10n.noModelsAvailable
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(l10n.customModels, style: const TextStyle(fontSize: 16)),
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
                          chatModel.setSelectedModel(modelName); // 新增：自动选中
                          _customModelController.clear();
                        }
                      },
                    ),
                  ],
                ),
                // Tavily Web Search Settings
                Row(
                  children: [
                    Text('Tavily Web 搜索功能', style: TextStyle(fontSize: 16)),
                    Spacer(),
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
                  Text(
                    'Tavily Web 搜索 API Key',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextField(
                    controller: _tavilyApiKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: '输入 Tavily API Key',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                //const SizedBox(height: 5),
                // Google Search Settings
                Row(
                  children: [
                    Text('Google 搜索功能', style: TextStyle(fontSize: 16)),
                    Spacer(),
                    Switch(
                      value: search.googleSearchEnabled,
                      onChanged: (value) {
                        search.setGoogleSearchEnabled(value);
                      },
                    ),
                  ],
                ),
                if (search.googleSearchEnabled) ...[
                  Text('Google Search API Key', style: TextStyle(fontSize: 14)),
                  TextField(
                    controller: _googleSearchApiKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '输入 Google Custom Search API Key',
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Google Search Engine ID',
                    style: TextStyle(fontSize: 14),
                  ),
                  TextField(
                    controller: _googleSearchEngineIdController,
                    decoration: InputDecoration(
                      hintText: '输入 Custom Search Engine ID',
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('搜索结果数量', style: TextStyle(fontSize: 14)),
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

                  SizedBox(height: 10),
                  Text('搜索提供商', style: TextStyle(fontSize: 14)),
                  DropdownButton<String>(
                    value: search.googleSearchProvider,
                    isExpanded: true,
                    items: [
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
                SizedBox(height: 10),

                if (chatModel.customModels.isNotEmpty)
                  Text(
                    l10n.yourCustomModels,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          chatModel.removeCustomModel(model);
                        },
                      ),
                    );
                  },
                ),
              ] else if (unifiedSettings.selectedModelType ==
                  available_model.ModelType.image) ...[
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
                      _apiKeyController.text = apiKeys.getImageApiKeyForProvider(newValue) ?? '';
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
                Text(
                  l10n.modelProviderURLOptional,
                  style: const TextStyle(fontSize: 16),
                ),
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
                Text(
                  l10n.apiKey(imageModel.selectedImageProvider),
                  style: const TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: l10n.enterYourAPIKey,
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
                        // Clear image API key for the current image provider
                        await _saveImageProviderApiKey(apiKeys, imageModel, '');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(l10n.selectModel, style: const TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value:
                      settingsModels.imageModels
                              .where(
                                (m) =>
                                    m.provider ==
                                    imageModel.selectedImageProvider,
                              )
                              .any((m) => m.id == imageModel.selectedImageModel)
                          ? imageModel.selectedImageModel
                          : (settingsModels.imageModels
                                  .where(
                                    (m) =>
                                        m.provider ==
                                        imageModel.selectedImageProvider,
                                  )
                                  .isNotEmpty
                              ? settingsModels.imageModels
                                  .where(
                                    (m) =>
                                        m.provider ==
                                        imageModel.selectedImageProvider,
                                  )
                                  .first
                                  .id
                              : null),
                  isExpanded: true,
                  items:
                      settingsModels.imageModels
                          .where(
                            (model) =>
                                model.provider ==
                                imageModel.selectedImageProvider,
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
                                (m) =>
                                    m.provider ==
                                    imageModel.selectedImageProvider,
                              )
                              .isEmpty
                          ? Text(l10n.noModelsAvailable)
                          : null,
                ),
                // Aspect Ratio selector for Black Forest Labs
                if (imageModel.selectedImageProvider == 'Black Forest Labs') ...[
                  const SizedBox(height: 20),
                  Text(l10n.aspectRatio, style: TextStyle(fontSize: 16)),
                  DropdownButton<String>(
                    value: imageModel.bflAspectRatio ?? '1:1',
                    isExpanded: true,
                    items: [
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
                Text(l10n.customModels, style: const TextStyle(fontSize: 16)),
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
                          imageModel.setSelectedImageModel(modelName); // 新增：自动选中
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          imageModel.removeCustomImageModel(model);
                        },
                      ),
                    );
                  },
                ),
              ] else if (unifiedSettings.selectedModelType ==
                  available_model.ModelType.video) ...[
                // Video Provider Selection
                DropdownButton<String>(
                  value: videoModel.selectedVideoProvider,
                  isExpanded: true,
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
                const SizedBox(height: 20),
                
                // Google Veo3 API Key
                Text(
                  'Google Veo3 API Key',
                  style: const TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
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

                // Video Resolution
                Text('Video Resolution', style: const TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: videoModel.videoResolution,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: '480p',
                      child: Text('480p (854×480)'),
                    ),
                    DropdownMenuItem(
                      value: '720p',
                      child: Text('720p HD (1280×720)'),
                    ),
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

                // Video Duration
                Text('Video Duration', style: const TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: videoModel.videoDuration,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: '5s',
                      child: Text('5 seconds'),
                    ),
                    DropdownMenuItem(
                      value: '10s',
                      child: Text('10 seconds'),
                    ),
                    DropdownMenuItem(
                      value: '30s',
                      child: Text('30 seconds'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      videoModel.setVideoDuration(value);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Video Quality
                Text('Video Quality', style: const TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: videoModel.videoQuality,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'standard',
                      child: Text('Standard Quality'),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child: Text('High Quality'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      videoModel.setVideoQuality(value);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Video Aspect Ratio
                Text('Video Aspect Ratio', style: const TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: videoModel.videoAspectRatio,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: '16:9',
                      child: Text('16:9 (Landscape)'),
                    ),
                    DropdownMenuItem(
                      value: '9:16',
                      child: Text('9:16 (Portrait)'),
                    ),
                    DropdownMenuItem(
                      value: '1:1',
                      child: Text('1:1 (Square)'),
                    ),
                    DropdownMenuItem(
                      value: '4:3',
                      child: Text('4:3 (Traditional)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      videoModel.setVideoAspectRatio(value);
                    }
                  },
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
                        onPressed: () => _exportSettings(context, unifiedSettings),
                      ),
                      _buildGlassButton(
                        label: l10n.importConfig,
                        icon: Icons.file_download,
                        backgroundColor: Colors.green,
                        onPressed: () => _showImportOptions(context, unifiedSettings),
                      ),
                      _buildGlassButton(
                        label: l10n.saveSettings,
                        icon: Icons.save,
                        backgroundColor: Colors.purple,
                        onPressed: () async {
                        final apiKeyText = _apiKeyController.text.trim();

                        if (unifiedSettings.selectedModelType ==
                            available_model.ModelType.text) {
                          // Save API key to the correct provider
                          await _saveProviderApiKey(apiKeys, chatModel, apiKeyText);

                          chatModel.setProviderUrl(
                            _providerUrlController.text.trim(),
                          );
                          if (search.tavilySearchEnabled) {
                            await apiKeys.setTavilyApiKey(
                              _tavilyApiKeyController.text.trim(),
                            );
                          } else {
                            await apiKeys.setTavilyApiKey('');
                          }
                          await apiKeys.setGoogleSearchApiKey(
                            _googleSearchApiKeyController.text.trim(),
                          );
                          await search.setGoogleSearchEngineId(
                            _googleSearchEngineIdController.text.trim(),
                          );
                        } else if (unifiedSettings.selectedModelType ==
                            available_model.ModelType.image) {
                          // Save image API key based on selected image provider
                          await _saveImageProviderApiKey(apiKeys, imageModel, apiKeyText);
                          imageModel.setImageProviderUrl(
                            _imageProviderUrlController.text.trim(),
                          );
                        } else if (unifiedSettings.selectedModelType ==
                            available_model.ModelType.video) {
                          // Save video API key (Google Veo3 uses Google API key)
                          await apiKeys.setGoogleApiKey(apiKeyText);
                        }

                        // 保存后同步模型到内存注册表
                        chatModel.syncModelsToRegistry();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.settingsSaved),
                              backgroundColor: Colors.black.withOpacity(0.7),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
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
                  if (modelType == available_model.ModelType.text) {
                    // Add custom provider with the model to ChatModelProvider
                    final chatModel = Provider.of<ChatModelProvider>(context, listen: false);
                    final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);

                    await chatModel.addCustomProvider(providerName, [modelName]);
                    await chatModel.setSelectedProvider(providerName);
                    await chatModel.setSelectedModel(modelName);

                    if (providerUrl.isNotEmpty) {
                      await chatModel.setProviderUrl(providerUrl);
                    }
                    if (apiKey.isNotEmpty) {
                      // Save API key based on provider type
                      await _saveProviderApiKey(apiKeys, chatModel, apiKey);
                    }

                    // 更新文本模型对应的参数显示
                    _providerUrlController.text = chatModel.rawProviderUrl ?? '';
                    _apiKeyController.text = _getProviderApiKey(apiKeys, chatModel);
                  } else if (modelType == available_model.ModelType.image) {
                    // Add custom image provider with the model to ImageModelProvider
                    final imageModel = Provider.of<ImageModelProvider>(context, listen: false);
                    final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);

                    await imageModel.addCustomImageProvider(providerName, [modelName]);
                    await imageModel.setSelectedImageProvider(providerName);
                    await imageModel.setSelectedImageModel(modelName);

                    if (providerUrl.isNotEmpty) {
                      await imageModel.setImageProviderUrl(providerUrl);
                    }
                    if (apiKey.isNotEmpty) {
                      // Save image API key based on provider type
                      await _saveImageProviderApiKey(apiKeys, imageModel, apiKey);
                    }

                    // 更新图像模型对应的参数显示
                    _imageProviderUrlController.text = imageModel.rawImageProviderUrl ?? '';
                    _apiKeyController.text = apiKeys.getImageApiKeyForProvider(imageModel.selectedImageProvider) ?? '';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.providerAndModelAdded)),
                  );
                  Navigator.of(context).pop();
                  setState(() {}); // 刷新 UI
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.providerAndModelNameCannotBeEmpty),
                    ),
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
      unifiedSettings.syncModelsToRegistry();
      print('Starting export process...');
      final xmlContent = await unifiedSettings.exportSettingsToXml();
      print('XML content generated: ${xmlContent.length} characters');

      // Get the appropriate directory based on platform
      Directory exportDir;
      String platformName;

      if (Platform.isMacOS) {
        // macOS: ~/Documents/Chibot
        final documentsDir = await getApplicationDocumentsDirectory();
        exportDir = Directory('${documentsDir.path}/Chibot');
        platformName = 'macOS';
      } else if (Platform.isWindows) {
        // Windows: %USERPROFILE%/Documents/Chibot
        final documentsDir = await getApplicationDocumentsDirectory();
        exportDir = Directory('${documentsDir.path}/Chibot');
        platformName = 'Windows';
      } else if (Platform.isLinux) {
        // Linux: ~/Documents/Chibot
        final documentsDir = await getApplicationDocumentsDirectory();
        exportDir = Directory('${documentsDir.path}/Chibot');
        platformName = 'Linux';
      } else if (Platform.isAndroid) {
        // Android: /storage/emulated/0/Download/Chibot
        final downloadsDir = Directory('/storage/emulated/0/Download');
        exportDir = Directory('${downloadsDir.path}/Chibot');
        platformName = 'Android';
      } else if (Platform.isIOS) {
        // iOS: App Documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        exportDir = Directory('${appDocDir.path}/Chibot');
        platformName = 'iOS';
      } else {
        // Fallback for other platforms
        final documentsDir = await getApplicationDocumentsDirectory();
        exportDir = Directory('${documentsDir.path}/Chibot');
        platformName = 'Unknown';
      }

      // Create directory if it doesn't exist
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
        print('Created directory: ${exportDir.path}');
      }

      // Generate filename with timestamp
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'chibot_config_$timestamp.xml';
      final filePath = '${exportDir.path}/$fileName';

      print('Saving to: $filePath');

      // Write the file
      final file = File(filePath);
      await file.writeAsString(xmlContent);
      print('File written successfully');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ 配置导出成功！'),
                const SizedBox(height: 4),
                Text('文件: $fileName', style: const TextStyle(fontSize: 12)),
                Text(
                  '位置: ${exportDir.path}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '平台: $platformName',
                  style: const TextStyle(fontSize: 10, color: Colors.white60),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
          ),
        );
        // 导出后刷新模型数据
        setState(() {});
      }
    } catch (e) {
      print('Export error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showImportOptions(BuildContext context, UnifiedSettingsProvider unifiedSettings) {
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
                subtitle: Text(_getPlatformDirectory()),
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

  String _getPlatformDirectory() {
    if (Platform.isMacOS) {
      return '~/Documents/Chibot (macOS)';
    } else if (Platform.isWindows) {
      return '%USERPROFILE%/Documents/Chibot (Windows)';
    } else if (Platform.isLinux) {
      return '~/Documents/Chibot (Linux)';
    } else if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/Chibot (Android)';
    } else if (Platform.isIOS) {
      return 'App Documents/Chibot (iOS)';
    } else {
      return '~/Documents/Chibot';
    }
  }

  Future<void> _importSettingsFromFilePicker(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
  ) async {
    try {
      print('Starting file picker import...');

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未选择文件'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Validate file name pattern
      final fileName = path.basename(file.path);
      if (!fileName.contains('chibot_config_') || !fileName.endsWith('.xml')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('文件名格式不正确。期望: chibot_config_*.xml，实际: $fileName'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Read and validate the file content
      final xmlContent = await file.readAsString();
      print('XML content read: ${xmlContent.length} characters from $fileName');

      if (xmlContent.trim().isEmpty || !xmlContent.contains('<settings>')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无效的配置文件格式'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show confirmation dialog
      if (!context.mounted) return;
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
                Container(
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        path.dirname(file.path),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '文件大小: ${(xmlContent.length / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Text(
                        '来源: 文件选择器',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
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

      if (confirmed == true) {
        print('User confirmed file picker import');
        await unifiedSettings.importSettingsFromXml(xmlContent);
        // 导入后强制刷新 SettingsProvider 和 SettingsModelsProvider
        setState(() {});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ 配置导入成功！'),
                  const SizedBox(height: 4),
                  Text('来源: $fileName', style: const TextStyle(fontSize: 12)),
                  const Text(
                    '方式: 文件选择器',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        print('User cancelled file picker import');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('导入已取消'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('File picker import error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<String?> _getInitialDirectory() async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        final documentsDir = await getApplicationDocumentsDirectory();
        final chibotDir = Directory('${documentsDir.path}/Chibot');
        if (await chibotDir.exists()) {
          return chibotDir.path;
        }
        return documentsDir.path;
      } else if (Platform.isWindows) {
        final documentsDir = await getApplicationDocumentsDirectory();
        final chibotDir = Directory('${documentsDir.path}/Chibot');
        if (await chibotDir.exists()) {
          return chibotDir.path;
        }
        return documentsDir.path;
      } else if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        final chibotDir = Directory('${downloadsDir.path}/Chibot');
        if (await chibotDir.exists()) {
          return chibotDir.path;
        }
        return downloadsDir.path;
      }
    } catch (e) {
      print('Error getting initial directory: $e');
    }
    return null;
  }

  Future<void> _importSettings(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
  ) async {
    try {
      print('Starting import process...');

      // Get the appropriate directory based on platform
      Directory importDir;
      String platformName;

      if (Platform.isMacOS) {
        // macOS: ~/Documents/Chibot
        final documentsDir = await getApplicationDocumentsDirectory();
        importDir = Directory('${documentsDir.path}/Chibot');
        platformName = 'macOS';
      } else if (Platform.isWindows) {
        // Windows: %USERPROFILE%/Documents/Chibot
        final documentsDir = await getApplicationDocumentsDirectory();
        importDir = Directory('${documentsDir.path}/Chibot');
        platformName = 'Windows';
      } else if (Platform.isLinux) {
        // Linux: ~/Documents/Chibot
        final documentsDir = await getApplicationDocumentsDirectory();
        importDir = Directory('${documentsDir.path}/Chibot');
        platformName = 'Linux';
      } else if (Platform.isAndroid) {
        // Android: /storage/emulated/0/Download/Chibot
        final downloadsDir = Directory('/storage/emulated/0/Download');
        importDir = Directory('${downloadsDir.path}/Chibot');
        platformName = 'Android';
      } else if (Platform.isIOS) {
        // iOS: App Documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        importDir = Directory('${appDocDir.path}/Chibot');
        platformName = 'iOS';
      } else {
        // Fallback for other platforms
        final documentsDir = await getApplicationDocumentsDirectory();
        importDir = Directory('${documentsDir.path}/Chibot');
        platformName = 'Unknown';
      }

      // Check if directory exists
      if (!await importDir.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('未找到配置目录: ${importDir.path}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('在 ${importDir.path} 中未找到配置文件'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('导入已取消'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        selectedFile = configFiles[selectedIndex];
      }

      // Read and validate the selected file
      final xmlContent = await selectedFile.readAsString();
      print(
        'XML content read: ${xmlContent.length} characters from ${path.basename(selectedFile.path)}',
      );

      // Validate XML content
      if (xmlContent.trim().isEmpty || !xmlContent.contains('<settings>')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无效的配置文件格式'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show confirmation dialog with file info
      if (!context.mounted) return;
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
                Container(
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
                              path.basename(selectedFile.path),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        path.dirname(selectedFile.path),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '文件大小: ${(xmlContent.length / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '平台: $platformName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
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

      if (confirmed == true) {
        print('User confirmed import');
        await unifiedSettings.importSettingsFromXml(xmlContent);
        // 导入后强制刷新 SettingsProvider 和 SettingsModelsProvider
        setState(() {});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ 配置导入成功！'),
                  const SizedBox(height: 4),
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
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        print('User cancelled import');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('导入已取消'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Import error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
