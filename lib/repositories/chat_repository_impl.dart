import '../core/exceptions.dart';
import '../core/logger.dart';
import '../core/shared_preferences_manager.dart';
import '../constants/shared_preferences_keys.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import '../repositories/interfaces.dart';

class ChatRepositoryImpl extends ChatRepository {
  ChatRepositoryImpl();
  
  @override
  Future<List<ChatSession>> getAll() async {
    try {
      logInfo('Loading all chat sessions');
      
      final sessions = await SharedPreferencesManager.getObjectList(
        SharedPreferencesKeys.chatSessions,
        ChatSession.fromJson,
      );
      
      logInfo('Loaded ${sessions.length} chat sessions');
      return sessions;
      
    } catch (e, stackTrace) {
      logError('Failed to load chat sessions', error: e, stackTrace: stackTrace);
      throw StorageException(
        'Failed to load chat sessions',
        code: 'LOAD_SESSIONS_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<ChatSession?> getById(String id) async {
    try {
      logInfo('Loading chat session: $id');
      
      final sessions = await getAll();
      final session = sessions.cast<ChatSession?>().firstWhere(
        (session) => session?.id == id,
        orElse: () => null,
      );
      
      if (session != null) {
        logInfo('Found chat session: $id');
      } else {
        logWarning('Chat session not found: $id');
      }
      
      return session;
      
    } catch (e, stackTrace) {
      logError('Failed to load chat session: $id', error: e, stackTrace: stackTrace);
      throw StorageException(
        'Failed to load chat session',
        code: 'LOAD_SESSION_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<void> save(ChatSession session) async {
    try {
      logInfo('Saving chat session: ${session.id}');
      
      final sessions = await getAll();
      final existingIndex = sessions.indexWhere((s) => s.id == session.id);
      
      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
        logInfo('Updated existing chat session: ${session.id}');
      } else {
        sessions.add(session);
        logInfo('Added new chat session: ${session.id}');
      }
      
      await SharedPreferencesManager.setObjectList(
        SharedPreferencesKeys.chatSessions,
        sessions,
        (session) => session.toJson(),
      );
      
    } catch (e, stackTrace) {
      logError('Failed to save chat session: ${session.id}', error: e, stackTrace: stackTrace);
      throw StorageException(
        'Failed to save chat session',
        code: 'SAVE_SESSION_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<void> update(ChatSession session) async {
    await save(session); // Same implementation as save
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      logInfo('Deleting chat session: $id');
      
      final sessions = await getAll();
      final initialLength = sessions.length;
      sessions.removeWhere((session) => session.id == id);
      
      if (sessions.length < initialLength) {
        await SharedPreferencesManager.setObjectList(
          SharedPreferencesKeys.chatSessions,
          sessions,
          (session) => session.toJson(),
        );
        logInfo('Deleted chat session: $id');
      } else {
        logWarning('Chat session not found for deletion: $id');
      }
      
    } catch (e, stackTrace) {
      logError('Failed to delete chat session: $id', error: e, stackTrace: stackTrace);
      throw StorageException(
        'Failed to delete chat session',
        code: 'DELETE_SESSION_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<void> deleteAll() async {
    try {
      logInfo('Deleting all chat sessions');
      
      await SharedPreferencesManager.remove(SharedPreferencesKeys.chatSessions);
      
      logInfo('Deleted all chat sessions');
      
    } catch (e, stackTrace) {
      logError('Failed to delete all chat sessions', error: e, stackTrace: stackTrace);
      throw StorageException(
        'Failed to delete all chat sessions',
        code: 'DELETE_ALL_SESSIONS_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<List<ChatSession>> getRecentSessions({int limit = 10}) async {
    try {
      logInfo('Loading recent chat sessions (limit: $limit)');
      
      final sessions = await getAll();
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      final recentSessions = sessions.take(limit).toList();
      logInfo('Loaded ${recentSessions.length} recent chat sessions');
      
      return recentSessions;
      
    } catch (e, stackTrace) {
      logError('Failed to load recent chat sessions', error: e, stackTrace: stackTrace);
      throw StorageException(
        'Failed to load recent chat sessions',
        code: 'LOAD_RECENT_SESSIONS_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<void> updateLastAccessed(String id) async {
    try {
      logInfo('Updating last accessed time for session: $id');
      
      final session = await getById(id);
      if (session != null) {
        final updatedSession = session.copyWith(updatedAt: DateTime.now());
        await save(updatedSession);
        logInfo('Updated last accessed time for session: $id');
      } else {
        logWarning('Session not found for last accessed update: $id');
      }
      
    } catch (e, stackTrace) {
      logError('Failed to update last accessed time for session: $id', error: e, stackTrace: stackTrace);
      throw StorageException(
        'Failed to update last accessed time',
        code: 'UPDATE_LAST_ACCESSED_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<void> addMessageToSession(String sessionId, ChatMessage message) async {
    try {
      logInfo('Adding message to session: $sessionId');
      
      final session = await getById(sessionId);
      if (session != null) {
        final updatedSession = session.addMessage(message);
        await save(updatedSession);
        logInfo('Added message to session: $sessionId');
      } else {
        throw StorageException(
          'Session not found: $sessionId',
          code: 'SESSION_NOT_FOUND',
        );
      }
      
    } catch (e, stackTrace) {
      logError('Failed to add message to session: $sessionId', error: e, stackTrace: stackTrace);
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to add message to session',
        code: 'ADD_MESSAGE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<void> updateMessageInSession(String sessionId, ChatMessage message) async {
    try {
      logInfo('Updating message in session: $sessionId');
      
      final session = await getById(sessionId);
      if (session != null) {
        final updatedSession = session.updateLastMessage(message);
        await save(updatedSession);
        logInfo('Updated message in session: $sessionId');
      } else {
        throw StorageException(
          'Session not found: $sessionId',
          code: 'SESSION_NOT_FOUND',
        );
      }
      
    } catch (e, stackTrace) {
      logError('Failed to update message in session: $sessionId', error: e, stackTrace: stackTrace);
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to update message in session',
        code: 'UPDATE_MESSAGE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<void> removeMessageFromSession(String sessionId, String messageId) async {
    try {
      logInfo('Removing message from session: $sessionId');
      
      final session = await getById(sessionId);
      if (session != null) {
        final updatedSession = session.removeMessage(messageId);
        await save(updatedSession);
        logInfo('Removed message from session: $sessionId');
      } else {
        throw StorageException(
          'Session not found: $sessionId',
          code: 'SESSION_NOT_FOUND',
        );
      }
      
    } catch (e, stackTrace) {
      logError('Failed to remove message from session: $sessionId', error: e, stackTrace: stackTrace);
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to remove message from session',
        code: 'REMOVE_MESSAGE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<void> clearSessionMessages(String sessionId) async {
    try {
      logInfo('Clearing messages from session: $sessionId');
      
      final session = await getById(sessionId);
      if (session != null) {
        final updatedSession = session.clearMessages();
        await save(updatedSession);
        logInfo('Cleared messages from session: $sessionId');
      } else {
        throw StorageException(
          'Session not found: $sessionId',
          code: 'SESSION_NOT_FOUND',
        );
      }
      
    } catch (e, stackTrace) {
      logError('Failed to clear messages from session: $sessionId', error: e, stackTrace: stackTrace);
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to clear messages from session',
        code: 'CLEAR_MESSAGES_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}