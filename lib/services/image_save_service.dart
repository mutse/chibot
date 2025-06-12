import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageSaveService {
  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // 检查 Android 版本
      if (await Permission.storage.status.isDenied) {
        // Android 13 以下版本
        if (await Permission.storage.request().isGranted) {
          return true;
        }
      } else {
        // Android 13 及以上版本
        if (await Permission.photos.request().isGranted) {
          return true;
        }
      }
      return false;
    } else if (Platform.isIOS) {
      if (await Permission.photos.request().isGranted) {
        return true;
      }
      return false;
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
              content: Text('Permission denied. Please grant storage permission to save images.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 获取图片数据
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final Uint8List imageBytes = response.bodyBytes;

      if (kIsWeb) {
        // Web平台处理
        throw UnsupportedError('Web platform is not supported');
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 移动平台处理
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          quality: 100,
          name: "chibot_image_${DateTime.now().millisecondsSinceEpoch}",
        );
        
        if (result['isSuccess']) {
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
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          throw Exception('Could not access downloads directory');
        }

        final fileName = 'chibot_image_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(imageBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image saved to ${file.path}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 