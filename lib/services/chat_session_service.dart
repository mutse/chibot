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
  // All instances share a write queue: background tool results and foreground
  // session edits must not overwrite each other or resurrect deleted sessions.
  static Future<void> _writes = Future<void>.value();
  Future<void> _write(Future<void> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.catchError((Object _) {});
    return next;
  }

  Future<List<ChatSession>> loadSessions() async {
    await _writes;
    return _store.loadSessions();
  }

  Future<void> saveSession(ChatSession session) =>
      _write(() => _store.saveSession(session));
  Future<void> deleteSession(String sessionId) =>
      _write(() => _store.deleteSession(sessionId));
  Future<void> clearAllSessions() => _write(_store.clearAllSessions);

  Future<void> updateToolMetadata(
    String sessionId,
    String messageId,
    Map<String, dynamic> metadata,
  ) => _write(() async {
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
  });
}
