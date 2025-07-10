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
- `SettingsProvider`: Manages app configuration, API keys, model selection, and provider settings
- Supports multiple AI providers with customizable base URLs
- Persistent settings storage using SharedPreferences

#### Services (`lib/services/`)
- `BaseApiService`: Abstract base class with retry logic, error handling, and streaming
- `OpenAIService`: Handles OpenAI GPT models with streaming responses
- `GeminiService`: Manages Google Gemini API calls
- `ClaudeService`: Integrates Anthropic Claude models with streaming support
- `ChatServiceFactory`: Factory for creating appropriate chat services
- `ServiceManager`: Helper for managing service creation with settings
- `ImageGenerationService`: Manages image generation requests
- `ChatSessionService` & `ImageSessionService`: Handle session persistence
- `WebSearchService`: Integrates web search capabilities (Tavily/Bing)
- `ImageSaveService`: Handles image saving to device storage

#### Models (`lib/models/`)
- `ChatMessage`: Core message structure with sender, timestamp, loading states
- `ChatSession` & `ImageSession`: Session management for conversation history
- `ImageMessage`: Specialized message type for image content

#### Screens (`lib/screens/`)
- `ChatScreen`: Main chat interface with sidebar for session management
- `SettingsScreen`: Configuration UI for API keys, models, and providers
- `AboutScreen`: App information and credits

### Multi-Provider Support
The app supports multiple AI providers through a unified interface:
- **OpenAI**: GPT-4, GPT-4o, GPT-4-turbo models with streaming responses
- **Google Gemini**: Gemini 2.0 Flash, Gemini 2.5 Pro with API compatibility
- **Anthropic Claude**: Claude 3.5 Sonnet, Claude 3.5 Haiku, Claude 3 Opus with streaming support
- **Custom Providers**: Configurable base URLs for additional providers

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

### Settings Management
- API keys are stored per provider (OpenAI, Claude, Gemini, Image generation, etc.)
- Model selection validates against provider capabilities
- Custom providers and models can be added through the UI
- Settings persist across app restarts

### Chat Session Management
- Sessions are automatically saved with conversation history
- Support for both text and image generation sessions
- Session metadata includes timestamps and model information

### Streaming Implementation
- OpenAI-compatible APIs use server-sent events for streaming
- Claude API supports streaming with proper event handling
- Gemini API responses are delivered as complete messages
- UI updates in real-time as responses are received

### Error Handling
- Network errors are caught and displayed to users
- API key validation occurs before requests
- Graceful fallbacks for unsupported features

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

- **Adding new AI provider**: Extend `ChatServiceFactory` and create new service class extending `BaseApiService`
- **New message types**: Create models and update chat UI components
- **Session management**: Work with existing repository pattern
- **UI customization**: Modify theme in `main.dart` and component styling
- **Localization**: Add new strings to `lib/l10n/app_*.arb` files

### Using the New Architecture

The refactored architecture provides:
- `ChatServiceFactory.create()` for service instantiation
- `ServiceManager.createChatService()` for integrated service creation
- Repository pattern for data persistence
- Proper error handling with custom exceptions
- Comprehensive logging system

### Example: Adding a New Provider

1. Create service class extending `BaseApiService`
2. Implement `ChatService` interface
3. Add to `ChatServiceFactory`
4. Update `SettingsProvider` with new models
5. Add API key support in settings