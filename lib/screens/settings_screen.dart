import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chibot/providers/settings_provider.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

enum ModelType { text, image }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppLocalizations l10n;
  late TextEditingController _apiKeyController;
  late TextEditingController _providerUrlController;
  late TextEditingController _imageProviderUrlController;
  late TextEditingController _customModelController;
  late TextEditingController _tavilyApiKeyController;
  late TextEditingController _bingApiKeyController;
  late TextEditingController _googleSearchApiKeyController;
  late TextEditingController _googleSearchEngineIdController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _apiKeyController = TextEditingController(
      text: _getProviderApiKey(settings),
    );
    _providerUrlController = TextEditingController(
      text: settings.rawProviderUrl,
    );
    _imageProviderUrlController = TextEditingController(
      text: settings.rawImageProviderUrl,
    );
    _customModelController = TextEditingController();
    _tavilyApiKeyController = TextEditingController(
      text: settings.tavilyApiKey ?? '',
    );
    _bingApiKeyController = TextEditingController(
      text: settings.bingApiKey ?? '',
    );
    _googleSearchApiKeyController = TextEditingController(
      text: settings.googleSearchApiKey ?? '',
    );
    _googleSearchEngineIdController = TextEditingController(
      text: settings.googleSearchEngineId ?? '',
    );
  }

  String _getProviderApiKey(SettingsProvider settings) {
    if (settings.selectedModelType == ModelType.image) {
      return settings.imageApiKey ?? '';
    }

    switch (settings.selectedProvider) {
      case 'OpenAI':
        return settings.apiKey ?? '';
      case 'Anthropic':
        return settings.claudeApiKey ?? '';
      case 'Google':
        return settings.apiKey ?? ''; // Using OpenAI key for Google for now
      default:
        return settings.apiKey ?? '';
    }
  }

  String _getApiKeyLabel(SettingsProvider settings) {
    if (settings.selectedModelType == ModelType.image) {
      return l10n.apiKey(settings.selectedImageProvider);
    }

    switch (settings.selectedProvider) {
      case 'OpenAI':
        return 'OpenAI API Key';
      case 'Anthropic':
        return 'Claude API Key (Anthropic)';
      case 'Google':
        return 'Google API Key';
      default:
        return l10n.apiKey(settings.selectedProvider);
    }
  }

  String _getApiKeyHint(SettingsProvider settings) {
    if (settings.selectedModelType == ModelType.image) {
      return l10n.enterYourAPIKey;
    }

    switch (settings.selectedProvider) {
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

  void _saveProviderApiKey(SettingsProvider settings, String apiKey) {
    switch (settings.selectedProvider) {
      case 'OpenAI':
        settings.setApiKey(apiKey);
        break;
      case 'Anthropic':
        settings.setClaudeApiKey(apiKey);
        break;
      case 'Google':
        settings.setApiKey(apiKey); // Using OpenAI key for Google for now
        break;
      default:
        settings.setApiKey(apiKey);
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
    _bingApiKeyController.dispose();
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
    final settings = Provider.of<SettingsProvider>(context);

    // 动态切换 API Key Controller 内容 - now provider-aware
    final expectedApiKey = _getProviderApiKey(settings);
    if (_apiKeyController.text != expectedApiKey) {
      _apiKeyController.text = expectedApiKey;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Text(
                    l10n.selectModelType,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: Text(l10n.textModel),
                    selected: settings.selectedModelType == ModelType.text,
                    onSelected: (selected) {
                      if (selected) {
                        settings.setSelectedModelType(ModelType.text);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(l10n.imageModel),
                    selected: settings.selectedModelType == ModelType.image,
                    onSelected: (selected) {
                      if (selected) {
                        settings.setSelectedModelType(ModelType.image);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.selectModelProvider,
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.add),
                    onPressed: () {
                      _showAddProviderAndModelDialog(
                        context,
                        settings,
                        settings.selectedModelType,
                      );
                    },
                  ),
                ],
              ),
              if (settings.selectedModelType == ModelType.text) ...[
                DropdownButton<String>(
                  value:
                      settings.allProviderNames.contains(
                            settings.selectedProvider,
                          )
                          ? settings.selectedProvider
                          : (settings.allProviderNames.isNotEmpty
                              ? settings.allProviderNames.first
                              : null),
                  isExpanded: true,
                  items:
                      settings.allProviderNames.map((String provider) {
                        final isCustom =
                            !SettingsProvider.defaultBaseUrls.keys.contains(
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
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settings.setSelectedProvider(newValue);
                      // Pre-fill for custom providers
                      final isCustom =
                          !SettingsProvider.defaultBaseUrls.keys.contains(
                            newValue,
                          );
                      if (isCustom) {
                        if (_providerUrlController.text.isEmpty) {
                          setState(() {
                            _providerUrlController.text =
                                'http://localhost:8000/v1';
                          });
                        }
                        if (settings.availableModels.isEmpty) {
                          // Add a default model if none exists
                          settings.addCustomModel('gpt-3.5-turbo');
                          settings.setSelectedModel('gpt-3.5-turbo');
                        }
                      }
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
                    SettingsProvider.defaultBaseUrls['OpenAI'] ?? '',
                  ),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                TextField(
                  controller: _providerUrlController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., http://localhost:11434/v1',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 20),
                Text(
                  _getApiKeyLabel(settings),
                  style: const TextStyle(fontSize: 16),
                ),
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: _getApiKeyHint(settings),
                  ),
                ),
                const SizedBox(height: 20),
                // Tavily Web Search Settings
                Row(
                  children: [
                    Text('Tavily Web 搜索功能', style: TextStyle(fontSize: 16)),
                    Spacer(),
                    Switch(
                      value: settings.tavilySearchEnabled,
                      onChanged: (value) {
                        settings.setTavilySearchEnabled(value);
                      },
                    ),
                  ],
                ),
                if (settings.tavilySearchEnabled) ...[
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
                  const SizedBox(height: 20),
                ],
                Text('Bing Web 搜索 API Key', style: TextStyle(fontSize: 16)),
                TextField(
                  controller: _bingApiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(hintText: '输入 Bing API Key'),
                ),
                const SizedBox(height: 20),
                // Google Search Settings
                Row(
                  children: [
                    Text('Google 搜索功能', style: TextStyle(fontSize: 16)),
                    Spacer(),
                    Switch(
                      value: settings.googleSearchEnabled,
                      onChanged: (value) {
                        settings.setGoogleSearchEnabled(value);
                      },
                    ),
                  ],
                ),
                if (settings.googleSearchEnabled) ...[
                  Text('Google Search API Key', style: TextStyle(fontSize: 14)),
                  TextField(
                    controller: _googleSearchApiKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '输入 Google Custom Search API Key',
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('Google Search Engine ID', style: TextStyle(fontSize: 14)),
                  TextField(
                    controller: _googleSearchEngineIdController,
                    decoration: InputDecoration(
                      hintText: '输入 Custom Search Engine ID',
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('搜索结果数量', style: TextStyle(fontSize: 14)),
                  Slider(
                    value: settings.googleSearchResultCount.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: settings.googleSearchResultCount.toString(),
                    onChanged: (value) {
                      settings.setGoogleSearchResultCount(value.toInt());
                    },
                  ),
                  SizedBox(height: 10),
                  Text('搜索提供商', style: TextStyle(fontSize: 14)),
                  DropdownButton<String>(
                    value: settings.googleSearchProvider,
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
                        settings.setGoogleSearchProvider(value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 20),
                Text(l10n.selectModel, style: const TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value:
                      settings.availableModels.contains(settings.selectedModel)
                          ? settings.selectedModel
                          : (settings.availableModels.isNotEmpty
                              ? settings.availableModels.first
                              : null),
                  isExpanded: true,
                  items:
                      settings.availableModels.map((String model) {
                        return DropdownMenuItem<String>(
                          value: model,
                          child: Text(model),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settings.setSelectedModel(newValue);
                    }
                  },
                  hint:
                      settings.availableModels.isEmpty
                          ? Text(l10n.noModelsAvailable)
                          : null,
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
                          settings.addCustomModel(modelName);
                          settings.setSelectedModel(modelName); // 新增：自动选中
                          _customModelController.clear();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (settings.customModels.isNotEmpty)
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
                  itemCount: settings.customModels.length,
                  itemBuilder: (context, index) {
                    final model = settings.customModels[index];
                    return ListTile(
                      title: Text(model),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          settings.removeCustomModel(model);
                        },
                      ),
                    );
                  },
                ),
              ] else ...[
                DropdownButton<String>(
                  value:
                      settings.allImageProviderNames.contains(
                            settings.selectedImageProvider,
                          )
                          ? settings.selectedImageProvider
                          : (settings.allImageProviderNames.isNotEmpty
                              ? settings.allImageProviderNames.first
                              : null),
                  isExpanded: true,
                  items:
                      settings.allImageProviderNames.map((String provider) {
                        return DropdownMenuItem<String>(
                          value: provider,
                          child: Text(provider),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settings.setSelectedImageProvider(newValue);
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
                    SettingsProvider.defaultImageBaseUrls['OpenAI'] ?? '',
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
                  l10n.apiKey(settings.selectedImageProvider),
                  style: const TextStyle(fontSize: 16),
                ),
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(hintText: l10n.enterYourAPIKey),
                ),
                const SizedBox(height: 20),
                Text(l10n.selectModel, style: const TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value:
                      settings.availableImageModels.contains(
                            settings.selectedImageModel,
                          )
                          ? settings.selectedImageModel
                          : (settings.availableImageModels.isNotEmpty
                              ? settings.availableImageModels.first
                              : null),
                  isExpanded: true,
                  items:
                      settings.availableImageModels.map((String model) {
                        return DropdownMenuItem<String>(
                          value: model,
                          child: Text(model),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settings.setSelectedImageModel(newValue);
                    }
                  },
                  hint:
                      settings.availableImageModels.isEmpty
                          ? Text(l10n.noModelsAvailable)
                          : null,
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
                          settings.addCustomImageModel(modelName);
                          settings.setSelectedImageModel(modelName); // 新增：自动选中
                          _customModelController.clear();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (settings.customImageModels.isNotEmpty)
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
                  itemCount: settings.customImageModels.length,
                  itemBuilder: (context, index) {
                    final model = settings.customImageModels[index];
                    return ListTile(
                      title: Text(model),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          settings.removeCustomImageModel(model);
                        },
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 30),
              // Export/Import Settings Section
              const Divider(),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _exportSettings(context, settings),
                      icon: const Icon(Icons.file_upload),
                      label: Text(l10n.exportConfig),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showImportOptions(context, settings),
                      icon: const Icon(Icons.file_download),
                      label: Text(l10n.importConfig),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        final apiKeyText = _apiKeyController.text.trim();

                        if (settings.selectedModelType == ModelType.text) {
                          // Save API key to the correct provider
                          _saveProviderApiKey(settings, apiKeyText);

                          settings.setProviderUrl(
                            _providerUrlController.text.trim(),
                          );
                          if (settings.tavilySearchEnabled) {
                            settings.setTavilyApiKey(
                              _tavilyApiKeyController.text.trim(),
                            );
                          } else {
                            settings.setTavilyApiKey('');
                          }
                          settings.setBingApiKey(
                            _bingApiKeyController.text.trim(),
                          );
                          settings.setGoogleSearchApiKey(
                            _googleSearchApiKeyController.text.trim(),
                          );
                          settings.setGoogleSearchEngineId(
                            _googleSearchEngineIdController.text.trim(),
                          );
                        } else {
                          settings.setImageApiKey(apiKeyText);
                          settings.setImageProviderUrl(
                            _imageProviderUrlController.text.trim(),
                          );
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.settingsSaved)),
                        );
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(l10n.saveSettings),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProviderAndModelDialog(
    BuildContext context,
    SettingsProvider settings,
    ModelType modelType,
  ) {
    final TextEditingController providerNameController =
        TextEditingController();
    final TextEditingController modelNameController = TextEditingController();
    final TextEditingController providerUrlController = TextEditingController();

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
              onPressed: () {
                final String providerName = providerNameController.text.trim();
                final String modelName = modelNameController.text.trim();
                final String providerUrl = providerUrlController.text.trim();

                if (providerName.isNotEmpty && modelName.isNotEmpty) {
                  if (modelType == ModelType.text) {
                    settings.addCustomProviderWithModels(providerName, [
                      modelName,
                    ]);
                    settings.setSelectedProvider(
                      providerName,
                    ); // 新增：自动选中Provider
                    settings.setSelectedModel(modelName); // 新增：自动选中模型
                    if (providerUrl.isNotEmpty) {
                      if (settings.selectedProvider == providerName) {
                        settings.setProviderUrl(providerUrl);
                      }
                    }
                  } else if (modelType == ModelType.image) {
                    settings.addCustomImageProviderWithModels(providerName, [
                      modelName,
                    ]);
                    settings.setSelectedImageProvider(
                      providerName,
                    ); // 新增：自动选中Provider
                    settings.setSelectedImageModel(modelName); // 新增：自动选中模型
                    if (providerUrl.isNotEmpty) {
                      if (settings.selectedImageProvider == providerName) {
                        settings.setImageProviderUrl(providerUrl);
                      }
                    }
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.providerAndModelAdded)),
                  );
                  Navigator.of(context).pop();
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
    SettingsProvider settings,
  ) async {
    try {
      print('Starting export process...');
      final xmlContent = await settings.exportSettingsToXml();
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

  void _showImportOptions(BuildContext context, SettingsProvider settings) {
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
                  _importSettings(context, settings);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.file_open, color: Colors.orange),
                title: const Text('手动选择文件'),
                subtitle: const Text('浏览文件系统选择配置文件'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _importSettingsFromFilePicker(context, settings);
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
    SettingsProvider settings,
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
        await settings.importSettingsFromXml(xmlContent);
        print('Settings imported successfully from file picker');

        // Update controllers with new values
        setState(() {
          _apiKeyController.text = _getProviderApiKey(settings);
          _providerUrlController.text = settings.rawProviderUrl ?? '';
          _imageProviderUrlController.text = settings.rawImageProviderUrl ?? '';
          _tavilyApiKeyController.text = settings.tavilyApiKey ?? '';
          _bingApiKeyController.text = settings.bingApiKey ?? '';
          _googleSearchApiKeyController.text = settings.googleSearchApiKey ?? '';
          _googleSearchEngineIdController.text = settings.googleSearchEngineId ?? '';
        });

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
    SettingsProvider settings,
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
        await settings.importSettingsFromXml(xmlContent);
        print('Settings imported successfully');

        // Update controllers with new values
        setState(() {
          _apiKeyController.text = _getProviderApiKey(settings);
          _providerUrlController.text = settings.rawProviderUrl ?? '';
          _imageProviderUrlController.text = settings.rawImageProviderUrl ?? '';
          _tavilyApiKeyController.text = settings.tavilyApiKey ?? '';
          _bingApiKeyController.text = settings.bingApiKey ?? '';
          _googleSearchApiKeyController.text = settings.googleSearchApiKey ?? '';
          _googleSearchEngineIdController.text = settings.googleSearchEngineId ?? '';
        });

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
