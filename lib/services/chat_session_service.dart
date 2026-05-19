import 'package:chibot/models/chat_session.dart';
import 'package:chibot/services/preferences_session_store.dart';

class ChatSessionService {
  ChatSessionService()
      : _store = PreferencesSessionStore<ChatSession>(
          storageKey: 'chat_sessions',
          toJson: (session) => session.toJson(),
          fromJson: ChatSession.fromJson,
          idOf: (session) => session.id,
          debugLabel: 'chat session',
        );

  final PreferencesSessionStore<ChatSession> _store;

  Future<List<ChatSession>> loadSessions() => _store.loadSessions();

  Future<void> saveSession(ChatSession session) => _store.saveSession(session);

  Future<void> deleteSession(String sessionId) =>
      _store.deleteSession(sessionId);

  Future<void> clearAllSessions() => _store.clearAllSessions();
}
