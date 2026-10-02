import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../providers/api_key_provider.dart';
import '../providers/plugin_provider.dart';
import '../services/tools/github_plugin.dart';

class GitHubPluginSettings extends StatefulWidget {
  final GitHubPlugin Function(String)? createPlugin;
  const GitHubPluginSettings({super.key, this.createPlugin});
  @override
  State<GitHubPluginSettings> createState() => _GitHubPluginSettingsState();
}

class _GitHubPluginSettingsState extends State<GitHubPluginSettings> {
  final _token = TextEditingController();
  bool _busy = false;
  String? _login;
  String? _error;
  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final keys = context.read<ApiKeyProvider>();
    final l = AppLocalizations.of(context)!;
    final token =
        _token.text.trim().isEmpty ? keys.githubToken : _token.text.trim();
    if (token == null) {
      setState(() => _error = l.githubMissingToken);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _login = null;
    });
    final plugin = widget.createPlugin?.call(token) ?? GitHubPlugin(token);
    try {
      await keys.setGitHubToken(token);
      final result = await plugin.testConnection();
      if (!mounted) return;
      final data = result.data['data'];
      setState(() {
        if (data is Map && data['login'] is String) {
          _login = data['login'];
        } else {
          _error = l.githubConnectionFailed;
        }
        _token.clear();
      });
    } catch (_) {
      if (mounted) setState(() => _error = l.githubConnectionFailed);
    } finally {
      plugin.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final plugins = context.watch<PluginProvider>();
    final keys = context.watch<ApiKeyProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GitHub', style: Theme.of(context).textTheme.titleLarge),
            Text(l.githubPluginDescription),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.githubEnable),
              value: plugins.githubEnabled,
              onChanged: _busy ? null : plugins.setGitHubEnabled,
            ),
            TextField(
              controller: _token,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: l.githubToken,
                hintText: keys.githubToken != null ? '••••••••' : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ??
                  _login ??
                  (keys.githubToken == null
                      ? l.githubNotConnected
                      : l.githubTokenSaved),
            ),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: _busy ? null : _connect,
                  child: Text(l.githubTestConnection),
                ),
                TextButton(
                  onPressed:
                      _busy
                          ? null
                          : () async {
                            await plugins.setGitHubEnabled(false);
                            await keys.setGitHubToken(null);
                            if (mounted) {
                              setState(() {
                                _token.clear();
                                _login = null;
                                _error = null;
                              });
                            }
                          },
                  child: Text(l.githubDisconnect),
                ),
                TextButton(
                  onPressed:
                      () => launchUrl(
                        Uri.parse(
                          'https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens',
                        ),
                      ),
                  child: Text(l.githubPermissions),
                ),
              ],
            ),
            Text(
              l.githubStorageNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
