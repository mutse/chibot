# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

### Development Commands
- `flutter pub get` - Install dependencies
- `flutter run` - Run the app on connected device/emulator
- `flutter run -d macos` - Run specifically on macOS
- `flutter run -d chrome` - Run on web browser
- `flutter build apk` - Build Android APK
- `flutter build ipa` - Build iOS app bundle
- `flutter build macos` - Build macOS app
- `flutter build web` - Build web version

### Code Quality
- `flutter analyze` - Run static analysis using flutter_lints
- `flutter test` - Run unit and widget tests
- `flutter pub deps` - Show dependency tree
- `flutter clean` - Clean build artifacts

### Build Tools
- `flutter pub run build_runner build` - Generate code (if using code generation)
- `flutter pub run flutter_launcher_icons` - Generate app icons

## Architecture Overview

This is a **cross-platform AI chatbot application** built with Flutter that supports multiple AI providers (OpenAI, Google Gemini) with both text and image generation capabilities.

### Core Architecture Pattern
- **State Management**: Provider pattern for centralized state management
- **Service Layer**: Clean separation between UI and business logic
- **Repository Pattern**: Services handle data persistence and API communications
- **Model Layer**: Plain Dart classes for data structures with JSON serialization

### Key Components

#### State Management (`lib/providers/`)
The app uses a specialized provider architecture with both legacy and new providers:

**Specialized Providers (Phase 1+ Refactoring)**:
- `ApiKeyProvider`: Centralized management of API keys for all providers
- `ChatModelProvider`: Manages chat model selection and configuration with ModelRegistry
- `ImageModelProvider`: Handles image generation model selection and settings
- `VideoModelProvider`: Manages video generation model selection
- `SearchProvider`: Manages search configuration and settings
- `UnifiedSettingsProvider`: Bridge provider combining all specialized providers for backward compatibility

**Legacy Providers**:
- `SettingsProvider`: Original monolithic settings provider (maintained for backward compatibility)
- `SettingsModelsProvider`: Provides access to ModelRegistry

All settings persist across app restarts using SharedPreferences.

#### Services (`lib/services/`)
**Chat Services**:
- `BaseApiService`: Abstract base class with retry logic, error handling, and streaming
- `OpenAIService`: Handles OpenAI GPT models with streaming responses
- `GeminiService`: Manages Google Gemini API calls
- `ClaudeService`: Integrates Anthropic Claude models with streaming support
- `ChatServiceFactory`: Factory for creating appropriate chat services

**Image Generation Services**:
- `ImageGenerationService`: Main image generation orchestrator with provider switching
- `ImageGenerationServiceManager`: Manages image service creation and configuration
- `FluxImageService`: FLUX.1 image generation via Black Forest Labs
- `FluxKreaService`: FLUX.1 generation via Krea platform
- `FluxKontextService`: FLUX.1 generation via Kontext platform
- `GoogleImageService`: Google's image generation models
- `Veo3Service`: Google Veo3 video-to-image model

**Video Generation Services**:
- `VideoGenerationService`: Main video generation service
- `VideoGenerationServiceManager`: Manages video service configuration and creation

**Session & Data Services**:
- `ChatSessionService`: Manages chat session persistence and history
- `ImageSessionService`: Manages image session persistence
- `VideoSessionService`: Manages video session persistence
- `ImageSaveService`: Handles image saving to device storage

**Search Services**:
- `WebSearchService`: Base web search interface
- `GoogleSearchService`: Google Search integration
- `SearchServiceManager`: Legacy search service manager
- `SearchServiceManagerV2`: Enhanced search service management
- `SearchCommandHandler`: Processes search commands in chat

**Utility Services**:
- `ServiceManager`: Helper for managing service creation with settings
- `MarkdownExportService`: Exports chat sessions to Markdown format
- `UpdateService`: Handles app update checking

#### Models (`lib/models/`)
- `ChatMessage`: Core message structure with sender, timestamp, loading states
- `ChatSession` & `ImageSession`: Session management for conversation history
- `ImageMessage`: Specialized message type for image content

#### Screens (`lib/screens/`)
- `ChatScreen`: Main chat interface with sidebar for session management
- `SettingsScreen`: Configuration UI for API keys, models, and providers
- `VideoGenerationScreen`: Video generation interface with model selection
- `VideoGenerationSettingsScreen`: Settings for video generation parameters
- `AboutScreen`: App information and credits
- `UpdateDialog`: Dialog for app update notifications

### Multi-Provider Support
The app supports multiple AI providers through unified interfaces:

**Chat Models**:
- **OpenAI**: GPT-4, GPT-4o, GPT-4-turbo models with streaming responses
- **Google Gemini**: Gemini 2.0 Flash, Gemini 2.5 Pro with API compatibility
- **Anthropic Claude**: Claude 3.5 Sonnet, Claude 3.5 Haiku, Claude 3 Opus with streaming support
- **Custom Providers**: Configurable base URLs for additional providers

**Image Generation Models**:
- **FLUX.1**: Via Black Forest Labs (FluxImageService), Krea (FluxKreaService), and Kontext (FluxKontextService) platforms
- **Google Gemini**: Image generation via Google's models
- **Veo3**: Google's advanced video-to-image model

**Video Generation Models**:
- Support for multiple video generation backends with model-specific settings

**Web Search**:
- **Google Search**: Primary web search integration
- **Fallback Support**: Additional search backends for redundancy

### Desktop Integration
- **Window Management**: Custom window sizing and positioning for desktop platforms
- **System Tray**: Tray icon with show/hide functionality
- **Context Menus**: Right-click context menus for enhanced UX

### Localization
- Full internationalization support using `flutter_localizations`
- Currently supports English and Chinese locales
- Localization files in `lib/l10n/`

## Development Guidelines

### Code Style
- Follow existing patterns in the codebase
- Use Provider for state management - don't introduce new state management solutions
- Maintain clean separation between UI and business logic
- Use proper error handling with user-friendly messages

### API Integration
- All API calls go through the service layer with proper abstraction
- Use streaming responses where supported (OpenAI, Claude)
- Implement proper error handling for network failures
- Store API keys securely using SharedPreferences
- Support for multiple API keys (OpenAI, Claude, Gemini, etc.)

### Testing
- Write unit tests for business logic in services
- Test state management providers
- Widget tests for UI components
- Integration tests for complete user flows

### Platform Considerations
- **Mobile**: Handle keyboard visibility, safe areas, and mobile-specific UI patterns
- **Desktop**: Implement window management, system tray, and desktop context menus
- **Web**: Ensure web compatibility for supported features

## Important Implementation Details

### Refactored Provider Architecture
The app has been migrated from a monolithic `SettingsProvider` to specialized providers:

- **Phase 1**: Decomposed into `ApiKeyProvider`, `ChatModelProvider`, `ImageModelProvider`, `VideoModelProvider`, `SearchProvider`
- **Phase 2**: Services updated to use specialized providers instead of monolithic `SettingsProvider`
- **Phase 3**: UI screens (VideoGenerationScreen, ChatScreen) migrated to specialized providers
- **Phase 4**: Search services migrated to specialized providers
- **Current**: SettingsScreen and remaining components using unified approach

The `UnifiedSettingsProvider` bridges old and new code for gradual migration.

### Settings Management
- API keys stored per provider via `ApiKeyProvider` with SharedPreferences
- Model selection per category (Chat, Image, Video) using specialized providers
- Custom providers and models supported with ModelRegistry
- Settings validated before API calls
- All settings persist across app restarts

### Chat Session Management
- Automatic session persistence with conversation history
- Support for text chat, image generation, and video generation sessions
- Session metadata includes timestamps, model information, and provider details
- `ChatSessionService`, `ImageSessionService`, `VideoSessionService` handle persistence
- Sessions can be exported to Markdown format via `MarkdownExportService`

### Image Generation Management
- Multiple image providers (FLUX.1 via BFL/Krea/Kontext, Google Gemini, Veo3)
- `ImageGenerationService` orchestrates provider selection based on model
- `ImageGenerationServiceManager` creates and configures image services
- Streaming responses for supported providers
- Image saving with metadata via `ImageSaveService`

### Video Generation Management
- Dedicated `VideoGenerationService` and `VideoGenerationServiceManager`
- Model-specific settings and parameters
- Session persistence for video generation history
- Integration with video playback via `VideoPlayerWidget`

### Streaming Implementation
- OpenAI-compatible APIs use server-sent events for streaming
- Claude API supports streaming with proper event handling
- Gemini API responses delivered as complete messages
- Real-time UI updates as responses are received
- Fallback to non-streaming when needed

### Error Handling
- Network errors caught and displayed with user-friendly messages
- API key validation before service creation via `MissingApiKeyException`
- Graceful fallbacks for unsupported features
- Comprehensive error logging for debugging
- Retry logic in `BaseApiService`

### Search Integration
- Web search via `GoogleSearchService` for enhanced chat capabilities
- `SearchProvider` manages search settings and preferences
- `SearchCommandHandler` processes search commands in chat messages
- `SearchServiceManagerV2` creates appropriate search service based on configuration

### ModelRegistry
- Centralized model definitions for all providers
- Type-safe model selection with validation
- Support for custom models and providers
- Used by `ChatModelProvider`, `ImageModelProvider`, and `VideoModelProvider`

## Development Environment Setup

1. Ensure Flutter SDK is installed and configured
2. Run `flutter doctor` to verify setup
3. Install platform-specific tools for target platforms
4. Configure API keys through the settings screen
5. Test on multiple platforms to ensure cross-platform compatibility

## Dependencies Notes

- Uses `provider` for state management (don't change this)
- `http` package for API communications
- `shared_preferences` for settings persistence
- `flutter_spinkit` for loading animations
- Platform-specific packages: `window_manager`, `tray_manager` for desktop
- `flutter_context_menu` for right-click context menus

## Common Tasks

### Using Specialized Providers
The refactored architecture uses specialized providers for better separation of concerns:

1. **Accessing Chat Models**: Use `ChatModelProvider` instead of `SettingsProvider.selectedChatModel`
2. **Managing API Keys**: Use `ApiKeyProvider` for centralized API key management
3. **Image Generation Settings**: Use `ImageModelProvider` for image model configuration
4. **Video Generation**: Use `VideoModelProvider` for video settings
5. **Search Configuration**: Use `SearchProvider` for search-related settings

### Adding New Providers
- Create service class extending `BaseApiService` (for chat services)
- Implement appropriate service interface
- Add to relevant service factory or manager
- Update specialized providers with new settings
- Add configuration UI in SettingsScreen

### Adding Image Generation Provider
1. Create service class (e.g., `NewImageService`) extending `BaseApiService`
2. Add model list to `ImageModelProvider`
3. Update `ImageGenerationService` to include the new provider
4. Add API key field in `ApiKeyProvider`
5. Update settings UI for configuration

### Adding Video Generation Provider
1. Create service class extending `BaseApiService`
2. Add to `VideoGenerationServiceManager`
3. Update `VideoModelProvider` with new models
4. Add API key and configuration in settings

### Session Management
- Use `ChatSessionService` for text chat persistence
- Use `ImageSessionService` for image generation history
- Use `VideoSessionService` for video generation history
- Repository pattern handles all data persistence

### Search Integration
- Use `SearchProvider` to manage search settings
- `SearchServiceManagerV2` handles service creation
- `SearchCommandHandler` processes search commands in chat
- Configure search API keys in settings