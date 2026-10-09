import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';

/// 通用的会话存储工具：把会话列表序列化后存入 SharedPreferences 的 `setStringList`。
///
/// 用作 [ChatSessionService] 和 [ImageSessionService] 的共享实现，
/// 保持 SharedPreferences 存储格式不变（每个会话一个 JSON 字符串）。
class PreferencesSessionStore<T> {
  PreferencesSessionStore({
    required this.storageKey,
    required this.toJson,
    required this.fromJson,
    required this.idOf,
    required this.debugLabel,
  });

  final String storageKey;
  final Map<String, dynamic> Function(T session) toJson;
  final T Function(Map<String, dynamic> json) fromJson;
  final String Function(T session) idOf;
  final String debugLabel;

  // All instances sharing the same storageKey serialize writes through one
  // queue: background tool results and foreground session edits must not
  // overwrite each other or resurrect deleted sessions.
  static final Map<String, Future<void>> _writeQueues = {};

  Future<void> _write(Future<void> Function() action) {
    final current = _writeQueues[storageKey] ?? Future<void>.value();
    final next = current.then((_) => action());
    _writeQueues[storageKey] = next.catchError((Object _) {});
    return next;
  }

  Future<List<T>> loadSessions() async {
    // Wait for pending writes so reads see a consistent snapshot.
    await (_writeQueues[storageKey] ?? Future<void>.value());
    return _loadSessionsUnsafe();
  }

  Future<void> saveSession(T session) => _write(() async {
        final sessions = await _loadSessionsUnsafe();
        final sessionId = idOf(session);
        sessions.removeWhere((existing) => idOf(existing) == sessionId);
        sessions.add(session);
        await _persist(sessions);
      });

  Future<void> deleteSession(String sessionId) => _write(() async {
        final sessions = await _loadSessionsUnsafe();
        sessions.removeWhere((session) => idOf(session) == sessionId);
        await _persist(sessions);
      });

  Future<void> clearAllSessions() => _write(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(storageKey);
      });

  /// Load without going through the write queue; only call from within [_write].
  Future<List<T>> _loadSessionsUnsafe() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(storageKey) ?? const <String>[];
    return sessionsJson
        .map((jsonString) {
          try {
            return fromJson(json.decode(jsonString) as Map<String, dynamic>);
          } catch (e, stackTrace) {
            AppLogger.warning(
              'Error decoding $debugLabel',
              error: e,
              stackTrace: stackTrace,
            );
            return null;
          }
        })
        .whereType<T>()
        .toList();
  }

  Future<void> _persist(List<T> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson =
        sessions.map((session) => json.encode(toJson(session))).toList();
    await prefs.setStringList(storageKey, sessionsJson);
  }
}
