import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/video_model_provider.dart';

class VideoGenerationSettingsScreen extends StatefulWidget {
  const VideoGenerationSettingsScreen({super.key});

  @override
  State<VideoGenerationSettingsScreen> createState() =>
      _VideoGenerationSettingsScreenState();
}

class _VideoGenerationSettingsScreenState
    extends State<VideoGenerationSettingsScreen> {
  late TextEditingController _veo3ApiKeyController;

  @override
  void initState() {
    super.initState();
    final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);
    _veo3ApiKeyController = TextEditingController(
      text: apiKeys.googleApiKey ?? '',
    );
  }

  @override
  void dispose() {
    _veo3ApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiKeys = Provider.of<ApiKeyProvider>(context);
    final videoModel = Provider.of<VideoModelProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('视频生成设置'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header
              Row(
                children: [
                  const Icon(Icons.videocam, size: 24, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '配置视频生成',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '为 Google Veo3 API 配置视频生成参数',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Veo3 API Key Section
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.key, size: 18, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            'Google Veo3 API Key',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _veo3ApiKeyController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: '输入 Google Veo3 API Key',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.vpn_key),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: '清空',
                            onPressed: () {
                              setState(() {
                                _veo3ApiKeyController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Video Resolution Section
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.aspect_ratio,
                            size: 18,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '视频分辨率',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButton<String>(
                        value: videoModel.videoResolution,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: '480p',
                            child: Text('480p (854×480)'),
                          ),
                          DropdownMenuItem(
                            value: '720p',
                            child: Text('720p 高清 (1280×720)'),
                          ),
                          DropdownMenuItem(
                            value: '1080p',
                            child: Text('1080p 全高清 (1920×1080)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            videoModel.setVideoResolution(value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '分辨率越高，画质越好，但生成时间也会更长',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Video Duration Section
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            '视频时长',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButton<String>(
                        value: videoModel.videoDuration,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: '5s', child: Text('5 秒')),
                          DropdownMenuItem(value: '10s', child: Text('10 秒')),
                          DropdownMenuItem(value: '15s', child: Text('15 秒')),
                          DropdownMenuItem(value: '30s', child: Text('30 秒')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            videoModel.setVideoDuration(value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '视频越长，生成耗时越久',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Video Quality Section
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.high_quality,
                            size: 18,
                            color: Colors.purple,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '视频质量',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButton<String>(
                        value: videoModel.videoQuality,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'standard',
                            child: Text('标准质量'),
                          ),
                          DropdownMenuItem(value: 'high', child: Text('高质量')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            videoModel.setVideoQuality(value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '高质量模式可获得更好的画面表现',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Video Aspect Ratio Section
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.crop, size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            '视频比例',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButton<String>(
                        value: videoModel.videoAspectRatio,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: '16:9',
                            child: Text('16:9（横屏）'),
                          ),
                          DropdownMenuItem(
                            value: '9:16',
                            child: Text('9:16（竖屏）'),
                          ),
                          DropdownMenuItem(
                            value: '1:1',
                            child: Text('1:1（方形）'),
                          ),
                          DropdownMenuItem(
                            value: '4:3',
                            child: Text('4:3（传统）'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            videoModel.setVideoAspectRatio(value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '根据你的使用场景选择合适的画面比例',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Save and Cancel buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('取消'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Save API key
                      await apiKeys.setGoogleApiKey(
                        _veo3ApiKeyController.text.trim(),
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('视频设置已保存'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('保存'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
