import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _providerUrlController; // 新增 Controller

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _providerUrlController = TextEditingController(text: settings.rawProviderUrl); // 使用 rawProviderUrl
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _providerUrlController.dispose(); // 释放 Controller
    super.dispose();
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
              const Text('OpenAI API Key:', style: TextStyle(fontSize: 16)),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your API Key',
                ),
              ),
              const SizedBox(height: 20),

              const Text('Model Provider URL (Optional):', style: TextStyle(fontSize: 16)),
              Text(
                'Default: ${SettingsProvider.defaultOpenAIBaseUrl}',
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

              const Text('Select Model:', style: TextStyle(fontSize: 16)),
              DropdownButton<String>(
                value: settings.selectedModel,
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
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
