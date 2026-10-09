import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_session.dart';
import '../models/video_message.dart';
import '../core/logger.dart';
import 'preferences_session_store.dart';

class VideoSessionService {
  static const String _sessionsKey = 'video_sessions';
  static const String _currentSessionKey = 'current_video_session';

  VideoSessionService()
      : _store = PreferencesSessionStore<VideoSession>(
          storageKey: _sessionsKey,
          toJson: (session) => session.toJson(),
          fromJson: (json) => VideoSession.fromJson(json),
          idOf: (session) => session.id,
          debugLabel: 'video session',
        );

  final PreferencesSessionStore<VideoSession> _store;

  bool _migrationDone = false;

  /// One-time migration from the legacy whole-list JSON string format to the
  /// per-item StringList format used by [PreferencesSessionStore].
  ///
  /// The migration is atomic (single write) and never deletes data before the
  /// new format is safely persisted. Corrupted legacy data is backed up to a
  /// separate key instead of being silently dropped.
  Future<void> _ensureMigrated() async {
    if (_migrationDone) return;
    _migrationDone = true;

    final prefs = await SharedPreferences.getInstance();
    // New format already present (StringList) — nothing to do.
    if (prefs.getStringList(_sessionsKey) != null) return;
    // Old format: single JSON string of the whole list.
    final legacyJson = prefs.getString(_sessionsKey);
    if (legacyJson == null || legacyJson.isEmpty) return;

    try {
      final List<dynamic> list = jsonDecode(legacyJson);
      final sessions = <VideoSession>[];
      for (final item in list) {
        try {
          sessions.add(VideoSession.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          // Skip individual corrupted sessions instead of dropping everything.
          AppLogger.warning(
            'Skipping corrupted video session during migration',
            error: e,
          );
        }
      }
      // Atomic write of the new format.
      final sessionsJson =
          sessions.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_sessionsKey, sessionsJson);
      AppLogger.info(
        'Migrated ${sessions.length} video sessions to per-item storage',
      );
    } catch (e) {
      // Whole-list JSON is corrupted: back it up for manual recovery instead
      // of silently dropping it.
      AppLogger.error(
        'Video sessions data corrupted, backing up raw JSON',
        error: e,
      );
      final backupKey =
          '${_sessionsKey}_corrupted_backup_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(backupKey, legacyJson);
    }
  }

  void _sortSessions(List<VideoSession> sessions) {
    sessions.sort(
      (a, b) =>
          b.updatedAt?.compareTo(a.updatedAt ?? a.createdAt) ??
          b.createdAt.compareTo(a.createdAt),
    );
  }

  Future<List<VideoSession>> getAllSessions() async {
    await _ensureMigrated();
    final sessions = await _store.loadSessions();
    _sortSessions(sessions);
    return sessions;
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
    await _ensureMigrated();
    final sessions = await getAllSessions();
    final newSession = VideoSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.isEmpty ? 'Video Session ${sessions.length + 1}' : title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      videos: [],
      settings: settings ?? VideoSettings(),
    );

    await _store.saveSession(newSession);
    await setCurrentSessionId(newSession.id);

    return newSession;
  }

  Future<VideoSession> updateSession(VideoSession session) async {
    await _ensureMigrated();
    final updated = session.copyWith(updatedAt: DateTime.now());
    await _store.saveSession(updated);
    return updated;
  }

  Future<void> deleteSession(String id) async {
    await _ensureMigrated();
    await _store.deleteSession(id);

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

    await _store.clearAllSessions();
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
      AppLogger.error('Error deleting session videos', error: e);
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
    final totalVideos =
        sessions.fold(0, (sum, session) => sum + session.videoCount);
    final totalDuration =
        sessions.fold(0, (sum, session) => sum + session.totalDuration);

    return {
      'totalSessions': totalSessions,
      'totalVideos': totalVideos,
      'totalDuration': totalDuration,
      'averageVideosPerSession': totalSessions > 0
          ? (totalVideos / totalSessions).toStringAsFixed(1)
          : '0',
      'averageDuration': totalVideos > 0
          ? (totalDuration / totalVideos).toStringAsFixed(1)
          : '0',
    };
  }
}
