import 'package:flutter/cupertino.dart';
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
    final theme = Theme.of(context); // Ensure theme is available

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings, style: theme.appBarTheme.titleTextStyle), // Use themed textStyle
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
                  Text(l10n.selectModelProvider, style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.add_circled, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(l10n.add, style: TextStyle(color: theme.colorScheme.primary, fontSize: 16)),
                      ],
                    ),
                    onPressed: () {
                      _showAddModelDialog(context, settings);
                    },
                  ),
                ],
              ),
              _buildCupertinoPickerButton(
                context: context,
                value: settings.allProviderNames.contains(settings.selectedProvider) ? settings.selectedProvider : (settings.allProviderNames.isNotEmpty ? settings.allProviderNames.first : null),
                items: settings.allProviderNames,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    settings.setSelectedProvider(newValue);
                  }
                },
              ),
              const SizedBox(height: 20),
              Text(l10n.modelProviderURLOptional, style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
              Text(
                l10n.defaultUrl(SettingsProvider.defaultBaseUrls['OpenAI'] ?? ''),
                style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
              ),
              TextField( // Will verify styling from inputDecorationTheme
                controller: _providerUrlController,
                decoration: InputDecoration( // Keep this to allow inputDecorationTheme to apply
                  hintText: 'e.g., http://localhost:11434/v1',
                ),
                keyboardType: TextInputType.url,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 20),

              Text(l10n.apiKey(settings.selectedProvider), style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
              TextField( // Will verify styling from inputDecorationTheme
                controller: _apiKeyController,
                obscureText: true,
                decoration: InputDecoration( // Keep this to allow inputDecorationTheme to apply
                  hintText: l10n.enterYourAPIKey,
                ),
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 20),

              Text(l10n.selectModel, style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
              _buildCupertinoPickerButton(
                context: context,
                value: settings.availableModels.contains(settings.selectedModel) ? settings.selectedModel : (settings.availableModels.isNotEmpty ? settings.availableModels.first : null),
                items: settings.availableModels,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    settings.setSelectedModel(newValue);
                  }
                },
                hintText: settings.availableModels.isEmpty ? l10n.noModelsAvailable : null,
              ),
              const SizedBox(height: 20),
              Text(l10n.customModels, style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
              Row(
                children: [
                  Expanded(
                    child: TextField( // Will verify styling from inputDecorationTheme
                      controller: _customModelController,
                      decoration: InputDecoration( // Keep this to allow inputDecorationTheme to apply
                        hintText: l10n.enterCustomModelName,
                      ),
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.add_circled_solid, color: theme.colorScheme.primary, size: 28),
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
                Text(l10n.yourCustomModels, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: settings.customModels.length,
                itemBuilder: (context, index) {
                  final model = settings.customModels[index];
                  return CupertinoListTile( // Using a conceptual CupertinoListTile, or style Container + Row
                    title: Text(model, style: theme.textTheme.bodyMedium),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
                      onPressed: () {
                        settings.removeCustomModel(model);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: CupertinoButton.filled(
                  child: Text(l10n.saveSettings),
                  onPressed: () {
                    settings.setApiKey(_apiKeyController.text.trim());
                    settings.setProviderUrl(_providerUrlController.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(l10n.settingsSaved), backgroundColor: CupertinoColors.activeGreen.resolveFrom(context)),
                    );
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a button that shows a CupertinoPicker
  Widget _buildCupertinoPickerButton({
    required BuildContext context,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hintText,
  }) {
    final theme = Theme.of(context);
    final bool isEmpty = items.isEmpty;

    return GestureDetector(
      onTap: isEmpty ? null : () {
        if (items.isEmpty) return;
        int initialItem = value != null ? items.indexOf(value) : 0;
        if (initialItem < 0) initialItem = 0;

        showCupertinoModalPopup<void>(
          context: context,
          builder: (BuildContext context) => Container(
            height: 216,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: CupertinoPicker(
                magnification: 1.22,
                squeeze: 1.2,
                useMagnifier: true,
                itemExtent: 32.0, // Standard iOS picker item height
                scrollController: FixedExtentScrollController(initialItem: initialItem),
                onSelectedItemChanged: (int selectedIndex) {
                  onChanged(items[selectedIndex]);
                },
                children: List<Widget>.generate(items.length, (int index) {
                  return Center(child: Text(items[index], style: TextStyle(color: theme.textTheme.bodyLarge?.color)));
                }),
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemFill.resolveFrom(context), // iOS-like field background
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: CupertinoColors.systemGrey4.resolveFrom(context), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              isEmpty ? (hintText ?? l10n.noItemsAvailable) : (value ?? hintText ?? l10n.pleaseSelect),
              style: TextStyle(
                color: isEmpty || value == null ? CupertinoColors.placeholderText.resolveFrom(context) : theme.textTheme.bodyMedium?.color,
                fontSize: 15,
              ),
            ),
            if (!isEmpty)
              Icon(CupertinoIcons.chevron_down, color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 20),
          ],
        ),
      ),
    );
  }

  // Placeholder for CupertinoListTile if not directly available or for custom styling
  Widget CupertinoListTile({required Widget title, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Typical iOS list tile padding
      // decoration: const BoxDecoration(
      //   border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      // ), // Border removed for now
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: title),
          if (trailing != null) trailing,
        ],
      ),
    );
  }


  void _showAddModelDialog(BuildContext context, SettingsProvider settings) {
    final TextEditingController providerController = TextEditingController();
    final TextEditingController modelsController = TextEditingController();
    String selectedProvider = 'OpenAI'; // Default provider
    final theme = Theme.of(context); // Get theme for dialog styling

    showCupertinoDialog( // Changed to showCupertinoDialog
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog( // Changed to CupertinoAlertDialog
          title: Text(l10n.addModelProvider),
          content: StatefulBuilder( 
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    // Simplified Dropdown for dialog, full CupertinoPicker might be too much here
                    // For a more Cupertino feel, this could be a tappable row that pushes a selection list
                    // or uses CupertinoSegmentedControl if options are few.
                    // Keeping DropdownButtonFormField for simplicity in dialog, but styled minimally.
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.modelProvider, style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                          _buildCupertinoPickerButton(
                            context: context,
                            value: selectedProvider,
                            items: ['OpenAI', 'Google', l10n.custom],
                            onChanged: (String? newValue) {
                                setState(() {
                                  selectedProvider = newValue!;
                                });
                            }
                          )
                        ],
                      )
                    ),
                    if (selectedProvider == l10n.custom)
                      CupertinoTextField( // Changed to CupertinoTextField
                        controller: providerController,
                        placeholder: l10n.providerNameHint,
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                      ),
                    const SizedBox(height: 8),
                    CupertinoTextField( // Changed to CupertinoTextField
                      controller: modelsController,
                      placeholder: l10n.modelsHint,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            CupertinoDialogAction( // Changed to CupertinoDialogAction
              child: Text(l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction( // Changed to CupertinoDialogAction
              isDefaultAction: true,
              child: Text(l10n.add),
              onPressed: () {
                final providerName = selectedProvider == l10n.custom ? providerController.text.trim() : selectedProvider;
                final models = modelsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                if (providerName.isNotEmpty && models.isNotEmpty) {
                    if (selectedProvider == l10n.custom) {
                      // For a new custom provider
                      settings.addCustomProviderWithModels(providerName, models);
                    } else {
                      // For existing, predefined providers (OpenAI, Google), add models to their general custom list
                      // The SettingsProvider needs a way to associate custom models with a specific predefined provider,
                      // or models added here are considered general custom models.
                      // Assuming general custom models for now if not a 'custom' provider type.
                      for (final model in models) {
                        settings.addCustomModel(model); // Add to general custom models list
                      }
                      // If the user selected 'OpenAI' or 'Google' and added models,
                      // they might expect these models to be available when that provider is selected.
                      // The current SettingsProvider.addCustomModel adds to a general list.
                      // This behavior is kept as per current provider capabilities.
                    }
                    // Optionally, select the provider if it's different, especially if it was a new custom provider
                    if (settings.selectedProvider != providerName && selectedProvider == l10n.custom) {
                       settings.setSelectedProvider(providerName);
                    } else if (settings.selectedProvider != providerName && (providerName == 'OpenAI' || providerName == 'Google')) {
                       // If they were adding models to an existing provider and it wasn't selected, select it.
                       settings.setSelectedProvider(providerName);
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
