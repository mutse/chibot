import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // 使用 SingleChildScrollView 防止内容溢出
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Select Model Provider:', style: TextStyle(fontSize: 16)),
              Row(
                children: <Widget>[
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('OpenAI'),
                      value: 'OpenAI',
                      groupValue: settings.selectedProvider, // Use provider's value directly
                      onChanged: (String? value) {
                        if (value != null) {
                          settings.setSelectedProvider(value);
                          // No need to call setState if UI updates are handled by Provider
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Google'),
                      value: 'Google',
                      groupValue: settings.selectedProvider, // Use provider's value directly
                      onChanged: (String? value) {
                        if (value != null) {
                          settings.setSelectedProvider(value);
                          // No need to call setState if UI updates are handled by Provider
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Model Provider URL (Optional):', style: TextStyle(fontSize: 16)),
              Text(
                'Default: ${SettingsProvider.defaultBaseUrls['OpenAI']}',
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

              const Text('OpenAI API Key:', style: TextStyle(fontSize: 16)),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your API Key',
                ),
              ),
              const SizedBox(height: 20),

              const Text('Select Model:', style: TextStyle(fontSize: 16)),
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
                hint: settings.availableModels.isEmpty ? const Text("No models available for this provider") : null,
              ),
              const SizedBox(height: 20),
              const Text('Custom Models:', style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customModelController,
                      decoration: const InputDecoration(
                        hintText: 'Enter custom model name',
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
                const Text('Your Custom Models:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
              ElevatedButton(
                onPressed: () {
                  settings.setApiKey(_apiKeyController.text.trim());
                  settings.setProviderUrl(_providerUrlController.text.trim()); // 保存 Provider URL
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved!')),
                  );
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                //icon: const Icon(Icons.info_outline),
                // onPressed: () {
                //   showDialog(
                //     context: context,
                //     builder: (BuildContext context) {
                //       return AlertDialog(
                //         title: const Text('About'),
                //         content: const Text('App 作者: Mutse Young\nApp 名称: Chibot\n版本号: 1.0.0\n版权: © 2023 Chibot\n联系邮箱: contact@chibot.com'),
                //         actions: <Widget>[
                //           TextButton(
                //             child: const Text('关闭'),
                //             onPressed: () {
                //               Navigator.of(context).pop();
                //             },
                //           ),
                //         ],
                //       );
                //     },
                //   );
                // },
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
