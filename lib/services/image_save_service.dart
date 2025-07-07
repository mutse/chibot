import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'dart:async';
import 'package:file_selector/file_selector.dart';

class ImageSaveService {
  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      Permission permissionToRequest;
      if (androidInfo.version.sdkInt >= 33) {
        permissionToRequest = Permission.photos;
      } else {
        permissionToRequest = Permission.storage;
      }

      final status = await permissionToRequest.status;
      if (status.isGranted) {
        return true;
      }

      // If not granted, request it
      final requestStatus = await permissionToRequest.request();
      return requestStatus.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return true; // 桌面平台不需要权限
  }

  static Future<void> saveImage(String imageUrl, BuildContext context) async {
    try {
      // 检查权限
      if (!await _requestPermissions()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permission denied. Please grant storage permission to save images.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 获取图片数据
      Uint8List imageBytes;
      final base64RegExp = RegExp(r'^data:image/png;base64,');

      if (base64RegExp.hasMatch(imageUrl)) {
        // 如果是base64编码的图片数据
        final String base64String = imageUrl.replaceFirst(base64RegExp, '');
        imageBytes = base64Decode(base64String);
      } else {
        // 否则，按URL下载图片
        try {
          final client = http.Client();
          final response = await client
              .get(
                Uri.parse(imageUrl),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36',
                },
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw TimeoutException(
                    'The connection has timed out, Please try again!',
                  );
                },
              );

          if (response.statusCode != 200) {
            throw Exception('Failed to download image: ${response.statusCode}');
          }

          imageBytes = response.bodyBytes;
          client.close();
        } catch (e) {
          if (e is TimeoutException) {
            throw Exception(
              'Connection timed out. Please check your internet connection and try again.',
            );
          } else if (e is HandshakeException) {
            throw Exception(
              'SSL handshake failed. Please check your network connection and try again.',
            );
          } else {
            throw Exception('Failed to download image: $e');
          }
        }
      }

      if (kIsWeb) {
        // Web平台处理
        throw UnsupportedError('Web platform is not supported');
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 移动平台处理
        final fileName =
            'chibot_image_${DateTime.now().millisecondsSinceEpoch}.png';

        // 保存到相册
        final result = await SaverGallery.saveImage(
          Uint8List.fromList(imageBytes),
          quality: 80,

          androidRelativePath: "Pictures/chibot",

          fileName: fileName,
          skipIfExists: true,
        );

        if (result.isSuccess) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image saved to gallery'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Failed to save image to gallery');
        }
      } else {
        // 桌面平台处理
        final fileName =
            'chibot_image_${DateTime.now().millisecondsSinceEpoch}.png';
        final FileSaveLocation? result = await getSaveLocation(suggestedName: fileName);
        if (result == null) {
          throw Exception('Save cancelled by user');
        }
        final file = File(result.path);
        await file.writeAsBytes(imageBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image saved to $result'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Error saving image: $e');
    }
  }
}
