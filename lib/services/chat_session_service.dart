import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chibot/models/chat_session.dart';

class ChatSessionService {
  static const String _sessionsKey = 'chat_sessions';

  Future<List<ChatSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_sessionsKey) ?? [];
    return sessionsJson
        .map((jsonString) {
          try {
            return ChatSession.fromJson(json.decode(jsonString));
          } catch (e) {
            print('Error decoding session: $e');
            return null;
          }
        })
        .where((session) => session != null)
        .cast<ChatSession>()
        .toList();
  }

  Future<void> saveSession(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();
    List<ChatSession> sessions = await loadSessions();
    // Remove existing session if it has the same ID
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    final sessionsJson = sessions.map((s) => json.encode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, sessionsJson);
  }

  Future<void> deleteSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    List<ChatSession> sessions = await loadSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    final sessionsJson = sessions.map((s) => json.encode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, sessionsJson);
  }

  Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }
}
