import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/video_message.dart';
import 'base_api_service.dart';
import 'video_generation_service.dart';

class Veo3Service extends BaseApiService implements VideoGenerationService {
  static const String _veo3BaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const Duration _pollInterval = Duration(seconds: 10);
  static const Duration _requestTimeout = Duration(minutes: 5);

  final Map<String, StreamController<VideoGenerationProgress>> _progressControllers = {};

  Veo3Service({required String apiKey}) : super(
    apiKey: apiKey,
    baseUrl: _veo3BaseUrl,
  );

  @override
  String get providerName => 'Google Veo3';

  @override
  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'x-goog-api-key': apiKey,
    };
  }

  @override
  void validateResponse(http.Response response) {
    if (response.statusCode >= 400) {
      final error = jsonDecode(response.body);
      throw Exception('Veo3 API Error: ${error['message'] ?? response.statusCode}');
    }
  }

  @override
  Future<VideoGenerationResponse> generateVideo(VideoGenerationRequest request) async {
    // Use the correct predictLongRunning endpoint for Veo API
    final url = Uri.parse('$_veo3BaseUrl/models/veo-3.1-generate-preview:predictLongRunning');

    try {
      // Build request body in correct format
      final requestBody = {
        'instances': [
          {
            'prompt': request.prompt,
          },
        ],
        'parameters': {
          'aspectRatio': request.aspectRatio,
          'resolution': request.resolution.label,
          'negativePrompt': '', // Optional negative prompt
        },
      };

      final response = await http.post(
        url,
        headers: getHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // The API returns an operation name
        final operationName = data['name'] as String?;

        if (operationName != null) {
          // Start progress tracking
          _startProgressTracking(operationName);
        }

        return VideoGenerationResponse(
          jobId: operationName,
          status: VideoStatus.pending,
          metadata: data,
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to generate video: ${error['error']?['message'] ?? error['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Video generation request timed out');
      }
      rethrow;
    }
  }

  @override
  Future<VideoGenerationResponse> checkGenerationStatus(String jobId) async {
    final url = Uri.parse('$_veo3BaseUrl/operations/$jobId');

    try {
      final response = await http.get(
        url,
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if operation is done
        final done = data['done'] as bool? ?? false;
        final metadata = data['metadata'] as Map<String, dynamic>?;
        final result = data['result'] as Map<String, dynamic>?;

        if (done && result != null) {
          // Video is ready - result contains the video output
          final output = result['predictions'] as List<dynamic>?;
          String? videoUrl;

          if (output != null && output.isNotEmpty) {
            final firstOutput = output[0] as Map<String, dynamic>?;
            videoUrl = firstOutput?['bytesBase64Encoded'] as String?;
          }

          return VideoGenerationResponse(
            jobId: jobId,
            videoUrl: videoUrl,
            status: VideoStatus.completed,
            progress: 1.0,
            metadata: result,
          );
        } else if (data['error'] != null) {
          // Error occurred
          final errorData = data['error'] as Map<String, dynamic>?;
          return VideoGenerationResponse(
            jobId: jobId,
            status: VideoStatus.failed,
            error: errorData?['message'] as String?,
            metadata: metadata,
          );
        } else {
          // Still processing
          return VideoGenerationResponse(
            jobId: jobId,
            status: VideoStatus.processing,
            progress: 0.5, // API doesn't provide granular progress
            metadata: metadata,
          );
        }
      } else {
        throw Exception('Failed to check status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking video generation status: $e');
    }
  }

  @override
  Stream<VideoGenerationProgress> getGenerationProgress(String jobId) {
    if (!_progressControllers.containsKey(jobId)) {
      _startProgressTracking(jobId);
    }
    return _progressControllers[jobId]!.stream;
  }

  void _startProgressTracking(String jobId) {
    final controller = StreamController<VideoGenerationProgress>.broadcast();
    _progressControllers[jobId] = controller;

    Timer.periodic(_pollInterval, (timer) async {
      try {
        final response = await checkGenerationStatus(jobId);

        final progress = VideoGenerationProgress(
          jobId: jobId,
          status: response.status,
          progress: response.progress ?? 0.0,
          message: _getProgressMessage(response.status, response.progress),
          currentStep: _getCurrentStep(response.progress ?? 0.0),
        );

        controller.add(progress);

        // Stop polling if completed or failed
        if (response.status == VideoStatus.completed ||
            response.status == VideoStatus.failed) {
          timer.cancel();
          await Future.delayed(const Duration(seconds: 1));
          await controller.close();
          _progressControllers.remove(jobId);
        }
      } catch (e) {
        controller.addError(e);
      }
    });
  }

  String _getProgressMessage(VideoStatus status, double? progress) {
    switch (status) {
      case VideoStatus.pending:
        return 'Preparing video generation...';
      case VideoStatus.processing:
        final percent = ((progress ?? 0) * 100).toInt();
        return 'Generating video: $percent%';
      case VideoStatus.completed:
        return 'Video generation completed!';
      case VideoStatus.failed:
        return 'Video generation failed';
      case VideoStatus.downloading:
        return 'Downloading video...';
    }
  }

  String _getCurrentStep(double progress) {
    if (progress < 0.1) return 'Initializing';
    if (progress < 0.3) return 'Processing prompt';
    if (progress < 0.5) return 'Generating frames';
    if (progress < 0.7) return 'Rendering video';
    if (progress < 0.9) return 'Finalizing';
    return 'Completing';
  }

  @override
  Future<void> cancelGeneration(String jobId) async {
    final url = Uri.parse('$_veo3BaseUrl/operations/$jobId:cancel');

    try {
      final response = await http.post(
        url,
        headers: getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel video generation: ${response.statusCode}');
      }

      // Clean up progress tracking
      if (_progressControllers.containsKey(jobId)) {
        await _progressControllers[jobId]!.close();
        _progressControllers.remove(jobId);
      }
    } catch (e) {
      throw Exception('Error cancelling video generation: $e');
    }
  }

  @override
  Future<String?> downloadVideo(String videoUrl, String localPath) async {
    try {
      final response = await http.get(Uri.parse(videoUrl));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final videoDir = Directory('${directory.path}/videos');
        if (!await videoDir.exists()) {
          await videoDir.create(recursive: true);
        }

        final fileName = path.basename(localPath);
        final file = File('${videoDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        return file.path;
      } else {
        throw Exception('Failed to download video: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading video: $e');
    }
  }

  // Helper method to validate API key
  @override
  Future<bool> validateApiKey() async {
    try {
      final url = Uri.parse('$_veo3BaseUrl/models?pageSize=1');
      final response = await http.get(url, headers: getHeaders());
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Helper method to get available models
  Future<List<String>> getAvailableModels() async {
    try {
      final url = Uri.parse('$_veo3BaseUrl/models?pageSize=10');
      final response = await http.get(url, headers: getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List<dynamic>?;

        return models
            ?.where((m) => m['name'].toString().contains('veo'))
            .map((m) => m['name'].toString())
            .toList() ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    // Clean up all progress controllers
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
  }
}