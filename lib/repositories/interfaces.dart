import '../models/chat_session.dart';
import '../models/image_session.dart';
import '../models/chat_message.dart';
import '../models/image_message.dart';

// Base repository interface
abstract class Repository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> save(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
  Future<void> deleteAll();
}

// Session repository interfaces
abstract class SessionRepository<T> extends Repository<T> {
  Future<List<T>> getRecentSessions({int limit = 10});
  Future<void> updateLastAccessed(String id);
}

// Chat repository interface
abstract class ChatRepository extends SessionRepository<ChatSession> {
  Future<void> addMessageToSession(String sessionId, ChatMessage message);
  Future<void> updateMessageInSession(String sessionId, ChatMessage message);
  Future<void> removeMessageFromSession(String sessionId, String messageId);
  Future<void> clearSessionMessages(String sessionId);
}

// Image repository interface
abstract class ImageRepository extends SessionRepository<ImageSession> {
  Future<void> addMessageToSession(String sessionId, ImageMessage message);
  Future<void> updateMessageInSession(String sessionId, ImageMessage message);
  Future<void> removeMessageFromSession(String sessionId, String messageId);
  Future<void> clearSessionMessages(String sessionId);
  Future<List<ImageMessage>> getGeneratedImages({int limit = 50});
}

// AI service interfaces
abstract class AIService {
  Future<void> validateConfiguration();
  Future<bool> isConfigured();
  String get providerName;
  List<String> get supportedModels;
}

abstract class ChatService extends AIService {
  Stream<String> generateResponse({
    required String prompt,
    required List<ChatMessage> context,
    required String model,
    Map<String, dynamic>? parameters,
  });
  
  Future<String> generateTitle(List<ChatMessage> messages);
}

abstract class ImageGenerationService extends AIService {
  Future<String> generateImage({
    required String prompt,
    required String model,
    Map<String, dynamic>? parameters,
  });
  
  Future<List<String>> generateImages({
    required String prompt,
    required String model,
    required int count,
    Map<String, dynamic>? parameters,
  });
}

abstract class WebSearchService extends AIService {
  Future<List<SearchResult>> search({
    required String query,
    int maxResults = 10,
    Map<String, dynamic>? parameters,
  });
}

// Search result model
class SearchResult {
  final String title;
  final String url;
  final String snippet;
  final DateTime? publishedDate;
  final Map<String, dynamic>? metadata;

  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.publishedDate,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'snippet': snippet,
        'publishedDate': publishedDate?.toIso8601String(),
        'metadata': metadata,
      };

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        title: json['title'] as String,
        url: json['url'] as String,
        snippet: json['snippet'] as String,
        publishedDate: json['publishedDate'] != null
            ? DateTime.parse(json['publishedDate'] as String)
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

// Settings repository interface
abstract class SettingsRepository {
  Future<T?> getValue<T>(String key);
  Future<void> setValue<T>(String key, T value);
  Future<void> removeValue(String key);
  Future<bool> containsKey(String key);
  Future<void> clear();
  
  // Typed getters for common settings
  Future<String?> getApiKey(String provider);
  Future<void> setApiKey(String provider, String key);
  Future<String?> getSelectedModel(String provider);
  Future<void> setSelectedModel(String provider, String model);
}