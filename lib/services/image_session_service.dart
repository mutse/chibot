import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:chibot/models/image_session.dart';

class ImageSessionService {
  static const String _sessionsKey = 'image_sessions';

  Future<List<ImageSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_sessionsKey) ?? [];
    return sessionsJson
        .map((jsonString) {
          try {
            return ImageSession.fromJson(json.decode(jsonString));
          } catch (e) {
            print('Error decoding image session: $e');
            return null;
          }
        })
        .where((session) => session != null)
        .cast<ImageSession>()
        .toList();
  }

  Future<void> saveSession(ImageSession session) async {
    final prefs = await SharedPreferences.getInstance();
    List<ImageSession> sessions = await loadSessions();
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    final sessionsJson = sessions.map((s) => json.encode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, sessionsJson);
  }

  Future<void> deleteSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    List<ImageSession> sessions = await loadSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    final sessionsJson = sessions.map((s) => json.encode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, sessionsJson);
  }

  Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }
}
