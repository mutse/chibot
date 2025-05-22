import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppLocalizations l10n;
  String? _selectedProviderValue; // To manage radio button state locally if needed, or drive from provider
  late TextEditingController _apiKeyController;
  late TextEditingController _providerUrlController; // 新增 Controller
  late TextEditingController _customModelController; // 新增 Controller for custom model input

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _providerUrlController = TextEditingController(text: settings.rawProviderUrl); // 使用 rawProviderUrl
    _customModelController = TextEditingController(); // 初始化 custom model controller
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _providerUrlController.dispose(); // 释放 Controller
    _customModelController.dispose(); // 释放 custom model controller
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize _selectedProviderValue when the widget is first built or dependencies change
    // This ensures the radio buttons reflect the provider's state correctly.
    _selectedProviderValue = Provider.of<SettingsProvider>(context, listen: false).selectedProvider;
    l10n = AppLocalizations.of(context)!;
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // 使用 SingleChildScrollView 防止内容溢出
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.selectModelProvider, style: const TextStyle(fontSize: 16)),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.add),
                    onPressed: () {
                      _showAddModelDialog(context, settings);
                    },
                  ),
                ],
              ),
              DropdownButton<String>(
                value: settings.allProviderNames.contains(settings.selectedProvider) ? settings.selectedProvider : (settings.allProviderNames.isNotEmpty ? settings.allProviderNames.first : null),
                isExpanded: true,
                items: settings.allProviderNames.map((String provider) { // Use allProviderNames here
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
              Text(l10n.modelProviderURLOptional, style: const TextStyle(fontSize: 16)),
              Text(
                l10n.defaultUrl(SettingsProvider.defaultBaseUrls['OpenAI'] ?? ''),
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

              Text(l10n.apiKey(settings.selectedProvider), style: const TextStyle(fontSize: 16)),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: l10n.enterYourAPIKey,
                ),
              ),
              const SizedBox(height: 20),

              Text(l10n.selectModel, style: const TextStyle(fontSize: 16)),
              DropdownButton<String>(
                value: settings.availableModels.contains(settings.selectedModel) ? settings.selectedModel : (settings.availableModels.isNotEmpty ? settings.availableModels.first : null),
                isExpanded: true,
                items: settings.availableModels.map((String model) {
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
                hint: settings.availableModels.isEmpty ? Text(l10n.noModelsAvailable) : null,
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
                Text(l10n.yourCustomModels, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // to disable ListView's own scrolling
                itemCount: settings.customModels.length,
                itemBuilder: (context, index) {
                  final model = settings.customModels[index];
                  return ListTile(
                    title: Text(model),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        settings.removeCustomModel(model);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              Center( // Wrap ElevatedButton with Center widget
                child: ElevatedButton(
                  onPressed: () {
                    settings.setApiKey(_apiKeyController.text.trim());
                    settings.setProviderUrl(_providerUrlController.text.trim()); // 保存 Provider URL
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsSaved)),
                    );
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

  void _showAddModelDialog(BuildContext context, SettingsProvider settings) {
    final TextEditingController providerController = TextEditingController();
    final TextEditingController modelsController = TextEditingController();
    String selectedProvider = 'OpenAI'; // Default provider

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.addModelProvider),
          content: StatefulBuilder( // Wrap with StatefulBuilder
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: l10n.modelProvider),
                      value: selectedProvider,
                      items: ['OpenAI', 'Google', l10n.custom].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() { // Use the setState from StatefulBuilder
                          selectedProvider = newValue!;
                        });
                      },
                    ),
                    if (selectedProvider == l10n.custom)
                      TextFormField(
                        controller: providerController,
                        decoration: InputDecoration(
                          hintText: l10n.providerNameHint,
                        ),
                      ),
                    TextFormField(
                      controller: modelsController,
                      decoration: InputDecoration(
                        hintText: l10n.modelsHint,
                      ),
                    ),
                  ],
                ),
              );
            },
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
                final provider = selectedProvider == 'Custom' ? providerController.text.trim() : selectedProvider;
                final models = modelsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                if (provider.isNotEmpty && models.isNotEmpty) {
                  // Logic to add provider and models to settings
                  // This part needs to be implemented in SettingsProvider
                  // For example: settings.addCustomProviderModels(provider, models);
                    // print('Provider: $provider, Models: $models'); // Placeholder
                    if (selectedProvider == 'Custom') {
                      settings.addCustomProviderWithModels(providerController.text.trim(), models);
                    } else {
                      // For existing providers, add models to their custom list or general custom list
                      for (final model in models) {
                        settings.addCustomModel(model); // Add to general custom models
                      }
                      // Optionally, set the provider if it's different and refresh
                      if (settings.selectedProvider != provider) {
                        settings.setSelectedProvider(provider);
                      }
                    }
                    Navigator.of(context).pop();
                  }
                }
            ),
          ],
        );
      },
    );
  }
}
