import 'package:chibot/models/image_session.dart';
import 'package:chibot/services/preferences_session_store.dart';

class ImageSessionService {
  ImageSessionService()
      : _store = PreferencesSessionStore<ImageSession>(
          storageKey: 'image_sessions',
          toJson: (session) => session.toJson(),
          fromJson: ImageSession.fromJson,
          idOf: (session) => session.id,
          debugLabel: 'image session',
        );

  final PreferencesSessionStore<ImageSession> _store;

  Future<List<ImageSession>> loadSessions() => _store.loadSessions();

  Future<void> saveSession(ImageSession session) =>
      _store.saveSession(session);

  Future<void> deleteSession(String sessionId) =>
      _store.deleteSession(sessionId);

  Future<void> clearAllSessions() => _store.clearAllSessions();
}
