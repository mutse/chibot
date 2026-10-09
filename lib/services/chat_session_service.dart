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
  // Write serialization is handled by PreferencesSessionStore (per storageKey).

  Future<List<ChatSession>> loadSessions() => _store.loadSessions();

  Future<void> saveSession(ChatSession session) => _store.saveSession(session);
  Future<void> deleteSession(String sessionId) =>
      _store.deleteSession(sessionId);
  Future<void> clearAllSessions() => _store.clearAllSessions();

  Future<void> updateToolMetadata(
    String sessionId,
    String messageId,
    Map<String, dynamic> metadata,
  ) async {
    // Write serialization is handled by PreferencesSessionStore.
    final sessions = await _store.loadSessions();
    final matches = sessions.where((s) => s.id == sessionId);
    if (matches.isEmpty) return;
    final session = matches.first;
    await _store.saveSession(
      session.copyWith(
        messages:
            session.messages
                .map(
                  (m) =>
                      m.id == messageId
                          ? m.copyWith(metadata: metadata, isLoading: false)
                          : m,
                )
                .toList(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
