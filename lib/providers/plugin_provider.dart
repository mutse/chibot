import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PluginProvider extends ChangeNotifier {
  static const _key = 'github_plugin_enabled';
  bool _githubEnabled = false;
  bool get githubEnabled => _githubEnabled;
  late final Future<void> ready;
  PluginProvider() {
    ready = _load();
  }
  Future<void> _load() async {
    _githubEnabled =
        (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> setGitHubEnabled(bool enabled) async {
    await ready;
    await (await SharedPreferences.getInstance()).setBool(_key, enabled);
    _githubEnabled = enabled;
    notifyListeners();
  }
}
