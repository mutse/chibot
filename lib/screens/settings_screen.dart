import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chibot/providers/settings_provider.dart';
import 'package:chibot/l10n/app_localizations.dart';

enum ModelType { text, image }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppLocalizations l10n;
  String? _selectedProviderValue;
  late TextEditingController _apiKeyController;
  late TextEditingController _providerUrlController;
  late TextEditingController _imageProviderUrlController;
  late TextEditingController _customModelController;
  late TextEditingController _tavilyApiKeyController;
  late TextEditingController _bingApiKeyController;

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
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedProviderValue =
        Provider.of<SettingsProvider>(context, listen: false).selectedProvider;
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
                        return DropdownMenuItem<String>(
                          value: provider,
                          child: Text(provider),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settings.setSelectedProvider(newValue);
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
                Text('Bing Web 搜索 API Key', style: TextStyle(fontSize: 16)),
                TextField(
                  controller: _bingApiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(hintText: '输入 Bing API Key'),
                ),
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
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    final apiKeyText = _apiKeyController.text.trim();
                    
                    if (settings.selectedModelType == ModelType.text) {
                      // Save API key to the correct provider
                      _saveProviderApiKey(settings, apiKeyText);
                      
                      settings.setProviderUrl(
                        _providerUrlController.text.trim(),
                      );
                      settings.setTavilyApiKey(
                        _tavilyApiKeyController.text.trim(),
                      );
                      settings.setBingApiKey(_bingApiKeyController.text.trim());
                    } else {
                      settings.setImageApiKey(apiKeyText);
                      settings.setImageProviderUrl(
                        _imageProviderUrlController.text.trim(),
                      );
                    }
                    
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.settingsSaved)));
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(l10n.saveSettings),
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
                    if (providerUrl.isNotEmpty) {
                      if (settings.selectedProvider == providerName) {
                        settings.setProviderUrl(providerUrl);
                      }
                    }
                  } else if (modelType == ModelType.image) {
                    settings.addCustomImageProviderWithModels(providerName, [
                      modelName,
                    ]);
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
}
