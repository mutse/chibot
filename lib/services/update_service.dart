import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String githubApiUrl =
      'https://api.github.com/repos/mutse/chibot/releases/latest';

  static Future<Map<String, dynamic>?> fetchLatestRelease() async {
    try {
      final response = await http.get(Uri.parse(githubApiUrl));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('fetchLatestRelease error: $e');
    }
    return null;
  }

  static String? getDownloadUrl(Map<String, dynamic> release) {
    final assets = release['assets'] as List<dynamic>;
    if (Platform.isAndroid) {
      return assets.firstWhere(
        (a) => a['name'].toString().endsWith('.apk'),
        orElse: () => null,
      )?['browser_download_url'];
    } else if (Platform.isIOS) {
      return 'https://apps.apple.com/app/AppStoreID';
    } else if (Platform.isWindows) {
      return assets.firstWhere(
        (a) => a['name'].toString().endsWith('.exe'),
        orElse: () => null,
      )?['browser_download_url'];
    } else if (Platform.isMacOS) {
      return assets.firstWhere(
        (a) => a['name'].toString().endsWith('.dmg'),
        orElse: () => null,
      )?['browser_download_url'];
    } else if (Platform.isLinux) {
      return assets.firstWhere(
        (a) => a['name'].toString().endsWith('.AppImage'),
        orElse: () => null,
      )?['browser_download_url'];
    }
    return null;
  }

  static Future<void> downloadAndInstall(String url, String fileName) async {
    if (Platform.isAndroid) {
      await _downloadAndInstallApk(url);
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await _downloadAndOpenInstaller(url, fileName);
    } else if (Platform.isIOS) {
      await launchUrl(Uri.parse(url));
    }
  }

  static Future<void> _downloadAndInstallApk(String url) async {
    try {
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir!.path}/chibot_update.apk';
      await Dio().download(url, savePath);
      await OpenFile.open(savePath); // 用 open_file 直接打开 APK
    } catch (e) {
      debugPrint('downloadAndInstallApk error: $e');
    }
  }

  static Future<void> _downloadAndOpenInstaller(
    String url,
    String fileName,
  ) async {
    try {
      final dir = await getDownloadsDirectory();
      final savePath = '${dir!.path}/$fileName';
      await Dio().download(url, savePath);
      await OpenFile.open(savePath);
    } catch (e) {
      debugPrint('downloadAndOpenInstaller error: $e');
    }
  }
}
