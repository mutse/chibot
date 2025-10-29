import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_session.dart';
import '../models/video_message.dart';

class VideoSessionService {
  static const String _sessionsKey = 'video_sessions';
  static const String _currentSessionKey = 'current_video_session';

  Future<List<VideoSession>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString(_sessionsKey);

    if (sessionsJson == null) {
      return [];
    }

    try {
      final List<dynamic> sessionsList = jsonDecode(sessionsJson);
      return sessionsList
          .map((json) => VideoSession.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt?.compareTo(a.updatedAt ?? a.createdAt) ??
                         b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error loading video sessions: $e');
      return [];
    }
  }

  Future<void> saveSessions(List<VideoSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = jsonEncode(
      sessions.map((session) => session.toJson()).toList(),
    );
    await prefs.setString(_sessionsKey, sessionsJson);
  }

  Future<VideoSession?> getSession(String id) async {
    final sessions = await getAllSessions();
    try {
      return sessions.firstWhere((session) => session.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<VideoSession> createSession({
    required String title,
    VideoSettings? settings,
  }) async {
    final sessions = await getAllSessions();
    final newSession = VideoSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.isEmpty ? 'Video Session ${sessions.length + 1}' : title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      videos: [],
      settings: settings ?? VideoSettings(),
    );

    sessions.insert(0, newSession);
    await saveSessions(sessions);
    await setCurrentSessionId(newSession.id);

    return newSession;
  }

  Future<VideoSession> updateSession(VideoSession session) async {
    final sessions = await getAllSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);

    if (index != -1) {
      sessions[index] = session.copyWith(updatedAt: DateTime.now());
      await saveSessions(sessions);
      return sessions[index];
    }

    return session;
  }

  Future<void> deleteSession(String id) async {
    final sessions = await getAllSessions();
    sessions.removeWhere((session) => session.id == id);
    await saveSessions(sessions);

    // Delete associated video files if they exist
    await _deleteSessionVideos(id);

    // Clear current session if it was deleted
    final currentId = await getCurrentSessionId();
    if (currentId == id) {
      await clearCurrentSessionId();
    }
  }

  Future<void> deleteAllSessions() async {
    final sessions = await getAllSessions();

    // Delete all video files
    for (final session in sessions) {
      await _deleteSessionVideos(session.id);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
    await clearCurrentSessionId();
  }

  Future<VideoSession> addVideoToSession(
    String sessionId,
    VideoMessage video,
  ) async {
    final session = await getSession(sessionId);
    if (session != null) {
      final updatedSession = session.addVideo(video);
      return await updateSession(updatedSession);
    }
    throw Exception('Session not found');
  }

  Future<VideoSession> updateVideoInSession(
    String sessionId,
    int videoIndex,
    VideoMessage video,
  ) async {
    final session = await getSession(sessionId);
    if (session != null) {
      final updatedSession = session.updateVideo(videoIndex, video);
      return await updateSession(updatedSession);
    }
    throw Exception('Session not found');
  }

  Future<String?> getCurrentSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentSessionKey);
  }

  Future<void> setCurrentSessionId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSessionKey, id);
  }

  Future<void> clearCurrentSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSessionKey);
  }

  Future<VideoSession?> getCurrentSession() async {
    final id = await getCurrentSessionId();
    if (id != null) {
      return await getSession(id);
    }
    return null;
  }

  Future<void> _deleteSessionVideos(String sessionId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/videos/$sessionId');

      if (await videoDir.exists()) {
        await videoDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error deleting session videos: $e');
    }
  }

  Future<String> getVideoDirectory(String sessionId) async {
    final directory = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${directory.path}/videos/$sessionId');

    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }

    return videoDir.path;
  }

  Future<File> getVideoFile(String sessionId, String fileName) async {
    final dir = await getVideoDirectory(sessionId);
    return File('$dir/$fileName');
  }

  Future<bool> videoFileExists(String sessionId, String fileName) async {
    final file = await getVideoFile(sessionId, fileName);
    return await file.exists();
  }

  Future<int> getSessionCount() async {
    final sessions = await getAllSessions();
    return sessions.length;
  }

  Future<int> getTotalVideoCount() async {
    final sessions = await getAllSessions();
    int total = 0;
    for (final session in sessions) {
      total += session.videoCount;
    }
    return total;
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final sessions = await getAllSessions();
    final totalSessions = sessions.length;
    final totalVideos = sessions.fold(0, (sum, session) => sum + session.videoCount);
    final totalDuration = sessions.fold(0, (sum, session) => sum + session.totalDuration);

    return {
      'totalSessions': totalSessions,
      'totalVideos': totalVideos,
      'totalDuration': totalDuration,
      'averageVideosPerSession': totalSessions > 0 ? (totalVideos / totalSessions).toStringAsFixed(1) : '0',
      'averageDuration': totalVideos > 0 ? (totalDuration / totalVideos).toStringAsFixed(1) : '0',
    };
  }
}