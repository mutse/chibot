# API Documentation

This document provides comprehensive API documentation for the Chi Chatbot Flutter application, including service interfaces, data models, and integration patterns.

## 📋 Table of Contents

- [Service Architecture](#service-architecture)
- [Core Services](#core-services)
- [Data Models](#data-models)
- [Provider Interfaces](#provider-interfaces)
- [API Integration Patterns](#api-integration-patterns)
- [Error Handling](#error-handling)
- [Streaming Support](#streaming-support)

## 🏗️ Service Architecture

The application uses a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────┐
│               UI Layer               │
│         (Screens/Widgets)           │
├─────────────────────────────────────┤
│            Provider Layer            │
│        (State Management)           │
├─────────────────────────────────────┤
│            Service Layer             │
│        (Business Logic)             │
├─────────────────────────────────────┤
│            Model Layer               │
│        (Data Structures)            │
└─────────────────────────────────────┘
```

## 🔧 Core Services

### BaseApiService

**File**: `lib/services/base_api_service.dart`

The abstract base class for all AI service implementations.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `apiKey` | `String` | API key for authentication |
| `baseUrl` | `String` | Base URL for API endpoints |
| `model` | `String` | AI model identifier |
| `maxRetries` | `int` | Maximum retry attempts for failed requests |

#### Methods

```dart
abstract class BaseApiService {
  // Send message and get response
  Future<String> sendMessage(String message);
  
  // Send message with streaming response
  Stream<String> sendMessageStream(String message);
  
  // Validate API configuration
  Future<bool> validateConfig();
  
  // Get available models
  Future<List<String>> getAvailableModels();
}
```

### OpenAIService

**File**: `lib/services/openai_service.dart`

Implements OpenAI GPT API integration with streaming support.

#### Configuration

```dart
final openAIService = OpenAIService(
  apiKey: 'your-openai-api-key',
  model: 'gpt-4',
  baseUrl: 'https://api.openai.com/v1',
);
```

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `sendMessage` | `String message` | `Future<String>` | Send message and get complete response |
| `sendMessageStream` | `String message` | `Stream<String>` | Send message with streaming response |
| `generateImage` | `String prompt` | `Future<String>` | Generate image using DALL-E |
| `validateConfig` | - | `Future<bool>` | Validate API key and configuration |

#### Example Usage

```dart
// Streaming response
final stream = openAIService.sendMessageStream('Hello, how are you?');
await for (final chunk in stream) {
  print(chunk);
}

// Complete response
final response = await openAIService.sendMessage('What is Flutter?');
print(response);
```

### GeminiService

**File**: `lib/services/gemini_service.dart`

Implements Google Gemini API integration.

#### Configuration

```dart
final geminiService = GeminiService(
  apiKey: 'your-gemini-api-key',
  model: 'gemini-2.0-flash-exp',
);
```

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `sendMessage` | `String message` | `Future<String>` | Send message and get response |
| `sendMessageStream` | `String message` | `Stream<String>` | Send message with streaming |
| `generateImage` | `String prompt` | `Future<String>` | Generate image using Gemini |

### ClaudeService

**File**: `lib/services/claude_service.dart`

Implements Anthropic Claude API integration.

#### Configuration

```dart
final claudeService = ClaudeService(
  apiKey: 'your-claude-api-key',
  model: 'claude-3-5-sonnet-20241022',
);
```

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `sendMessage` | `String message` | `Future<String>` | Send message and get response |
| `sendMessageStream` | `String message` | `Stream<String>` | Send message with streaming |

## 📊 Data Models

### ChatMessage

**File**: `lib/models/chat_message.dart`

Represents a single chat message in a conversation.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique message identifier |
| `content` | `String` | Message content |
| `isUser` | `bool` | Whether message is from user |
| `timestamp` | `DateTime` | Message creation time |
| `isLoading` | `bool` | Loading state indicator |
| `error` | `String?` | Error message if any |

#### JSON Serialization

```dart
{
  "id": "msg_123",
  "content": "Hello, how can I help you?",
  "isUser": false,
  "timestamp": "2024-01-15T10:30:00Z",
  "isLoading": false,
  "error": null
}
```

### ChatSession

**File**: `lib/models/chat_session.dart`

Represents a complete chat conversation session.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique session identifier |
| `title` | `String` | Session title |
| `messages` | `List<ChatMessage>` | Conversation messages |
| `model` | `String` | AI model used |
| `provider` | `String` | AI provider name |
| `createdAt` | `DateTime` | Session creation time |
| `updatedAt` | `DateTime` | Last update time |

### ImageMessage

**File**: `lib/models/image_message.dart`

Represents an image generation message.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique message identifier |
| `prompt` | `String` | Image generation prompt |
| `imageUrl` | `String` | Generated image URL |
| `isLoading` | `bool` | Generation state |
| `error` | `String?` | Error message if any |

## 🎛️ Provider Interfaces

### SettingsProvider

**File**: `lib/providers/settings_provider.dart`

Manages application settings and configuration.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `openaiApiKey` | `String` | OpenAI API key |
| `geminiApiKey` | `String` | Google Gemini API key |
| `claudeApiKey` | `String` | Anthropic Claude API key |
| `selectedModel` | `String` | Currently selected AI model |
| `selectedProvider` | `String` | Currently selected provider |
| `customBaseUrl` | `String?` | Custom API base URL |
| `systemPrompt` | `String` | System prompt for AI |

#### Methods

```dart
// Save settings
await settingsProvider.saveSettings();

// Load settings
await settingsProvider.loadSettings();

// Validate API configuration
bool isValid = settingsProvider.validateConfiguration();

// Get available models for provider
List<String> models = settingsProvider.getModelsForProvider('openai');
```

### ChatProvider

**File**: `lib/providers/chat_provider.dart`

Manages chat sessions and conversations.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `currentSession` | `ChatSession?` | Currently active session |
| `sessions` | `List<ChatSession>` | All saved sessions |
| `isLoading` | `bool` | Loading state |

#### Methods

```dart
// Create new session
await chatProvider.createNewSession();

// Send message
await chatProvider.sendMessage('Hello, how are you?');

// Load existing session
await chatProvider.loadSession('session_id');

// Delete session
await chatProvider.deleteSession('session_id');

// Export session
String json = chatProvider.exportSession('session_id');
```

## 🔗 API Integration Patterns

### Service Factory Pattern

**File**: `lib/services/chat_service_factory.dart`

Creates appropriate AI service instances based on configuration.

```dart
final service = ChatServiceFactory.create(
  provider: 'openai',
  apiKey: 'your-api-key',
  model: 'gpt-4',
);
```

### Service Manager

**File**: `lib/services/service_manager.dart`

Helper class for integrated service creation with settings.

```dart
final service = await ServiceManager.createChatService(settingsProvider);
```

### Error Handling Pattern

All services implement consistent error handling:

```dart
try {
  final response = await service.sendMessage('Hello');
} on ApiException catch (e) {
  // Handle API-specific errors
  print('API Error: ${e.message}');
} on NetworkException catch (e) {
  // Handle network errors
  print('Network Error: ${e.message}');
} catch (e) {
  // Handle other errors
  print('Unexpected Error: $e');
}
```

## ⚡ Streaming Support

### Server-Sent Events (SSE)

OpenAI and Claude services support real-time streaming via Server-Sent Events:

```dart
// OpenAI streaming
final stream = openAIService.sendMessageStream('Tell me a story');

// Claude streaming  
final stream = claudeService.sendMessageStream('Explain quantum physics');

// Handle streaming response
await for (final chunk in stream) {
  // Update UI with new content
  setState(() {
    currentMessage += chunk;
  });
}
```

### Stream Management

#### Creating Custom Streams

```dart
Stream<String> createCustomStream(String message) async* {
  final request = http.Request('POST', Uri.parse(apiUrl));
  request.headers.addAll({
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  });
  
  final response = await request.send();
  
  await for (final chunk in response.stream.transform(utf8.decoder)) {
    yield chunk;
  }
}
```

## 📱 Platform-Specific APIs

### Desktop Integration

**File**: `lib/services/window_service.dart`

Manages desktop window state and system tray integration.

```dart
// Window management
await windowService.showWindow();
await windowService.hideWindow();
await windowService.setWindowSize(Size(800, 600));

// System tray
await trayService.showTray();
await trayService.setTrayIcon('assets/icon.png');
```

### Image Generation

**File**: `lib/services/image_generation_service.dart`

Unified interface for image generation across providers.

```dart
final imageService = ImageGenerationService(
  openaiKey: 'your-openai-key',
  geminiKey: 'your-gemini-key',
);

// Generate image
final imageUrl = await imageService.generateImage(
  prompt: 'A serene landscape with mountains',
  provider: 'openai',
  size: '1024x1024',
);
```

## 🔍 Web Search Integration

**File**: `lib/services/web_search_service.dart`

Provides web search capabilities using various providers.

```dart
final searchService = WebSearchService(
  tavilyApiKey: 'your-tavily-key',
  bingApiKey: 'your-bing-key',
);

// Search the web
final results = await searchService.search(
  query: 'latest Flutter updates',
  provider: 'tavily',
  maxResults: 5,
);
```

## 📊 Session Management

### Chat Session Service

**File**: `lib/services/chat_session_service.dart`

Handles persistence of chat sessions.

```dart
// Save session
await ChatSessionService.saveSession(session);

// Load sessions
final sessions = await ChatSessionService.loadSessions();

// Delete session
await ChatSessionService.deleteSession('session_id');
```

### Image Session Service

**File**: `lib/services/image_session_service.dart`

Manages image generation history.

```dart
// Save image session
await ImageSessionService.saveSession(imageSession);

// Load image history
final history = await ImageSessionService.loadSessions();
```

## 🛡️ Security Considerations

### API Key Management

- API keys are stored securely using SharedPreferences
- Keys are never logged or exposed in error messages
- Keys are validated before use

### Network Security

- All API calls use HTTPS
- Certificate validation is enforced
- Timeout configurations prevent hanging requests

### Data Privacy

- Conversation data is stored locally only
- No data is sent to external servers except AI providers
- Users can delete all data at any time

## 🔧 Development Utilities

### Logging

All services include comprehensive logging:

```dart
// Enable debug logging
Logger.level = Level.debug;

// Log API calls
logger.d('Sending request to OpenAI: $message');

// Log errors
logger.e('API error: ${e.message}', e);
```

### Testing Utilities

```dart
// Mock services for testing
class MockOpenAIService extends BaseApiService {
  @override
  Future<String> sendMessage(String message) async {
    return 'Mock response for: $message';
  }
}

// Test configuration
final mockSettings = SettingsProvider()
  ..openaiApiKey = 'test-key'
  ..selectedModel = 'gpt-4';
```

## 📈 Performance Optimization

### Request Caching

```dart
// Cache responses for common queries
final cache = ResponseCache();

if (cache.hasResponse(message)) {
  return cache.getResponse(message);
}

final response = await service.sendMessage(message);
cache.storeResponse(message, response);
```

### Connection Pooling

```dart
// Reuse HTTP connections
final client = http.Client();

// Make multiple requests with same client
final response1 = await client.post(url1, body: body1);
final response2 = await client.post(url2, body: body2);

// Close when done
client.close();
```

This API documentation provides a comprehensive guide for developers working with the Chi Chatbot application. For specific implementation details, refer to the source code and inline documentation.