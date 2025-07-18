# Chi Chatbot

<img src=./assets/images/logo.png width=40% height=40%/>
  
Chi Chatbot AI is a Flutter-based cross-platform application that provides an intuitive chat interface for interacting with AI language models. It currently supports integration with both OpenAI models (like GPT-4) and Google's Gemini models through a unified interface.  

## Screenshots

![](./images/chibot-mac.jpg)

## Features  
  
- **Multi-provider Support**: Interact with OpenAI, Google Gemini, Anthropic Claude, and custom AI models
- **Streaming Output**: Real-time responses from AI models with server-sent events
- **Text to Image**: Generate images using DALL-E, Gemini, or other image generation models
- **Web Search**: Integrated web search capabilities using Tavily or Google Search APIs
- **Session Management**: Persistent chat sessions with conversation history
- **Desktop Integration**: System tray support, window management, and context menus
- **Multi-language Support**: English and Chinese localization
- **Clean Chat Interface**: Modern, user-friendly interface with sidebar navigation
- **Customizable Settings**: Configure API keys, model selection, provider URLs, and system prompts
- **Cross-platform**: Built with Flutter for compatibility across mobile and desktop platforms  
  
## Getting Started  
  
### Prerequisites  
  
- Flutter SDK  
- Dart  
- API keys for OpenAI or Google Gemini  
  
### Installation  
  
1. Clone the repository:

    ```zsh
    $ git clone https://github.com/mutse/chibot.git
    ```

2. Navigate to the project directory:  

    ```zsh
    $ cd chibot
    ```

3. Install dependencies:  

    ```zsh
    $ flutter pub get
    ```

4. Run the application:  

    ```zsh
    $ flutter run
    ```

### Configuration  

1. Launch the application  
2. Navigate to Settings  
3. Enter your API key for OpenAI or Google Gemini  
4. Select your preferred AI model  
5. (Optional) Configure custom provider URL if needed  

## Project Structure  

    ```zsh
    lib/
    ├── main.dart                 # Application entry point
    ├── models/
    │   ├── chat_message.dart     # Data model for chat messages
    │   ├── chat_session.dart     # Session management for conversations
    │   ├── image_session.dart    # Session management for image generation
    │   └── image_message.dart    # Specialized message type for image content
    ├── providers/
    │   ├── settings_provider.dart # State management for app settings
    │   └── chat_provider.dart    # State management for chat sessions
    ├── screens/
    │   ├── chat_screen.dart      # Main chat interface with sidebar
    │   ├── settings_screen.dart  # Settings configuration
    │   └── about_screen.dart     # App information and credits
    ├── services/
    │   ├── base_api_service.dart  # Abstract base service with common functionality
    │   ├── openai_service.dart    # OpenAI GPT service implementation
    │   ├── gemini_service.dart    # Google Gemini service implementation
    │   ├── claude_service.dart    # Anthropic Claude service implementation
    │   ├── chat_service_factory.dart # Factory for service creation
    │   ├── service_manager.dart   # Helper for service management
    │   ├── image_generation_service.dart # Image generation functionality
    │   ├── chat_session_service.dart     # Chat session persistence
    │   ├── image_session_service.dart    # Image session persistence
    │   ├── web_search_service.dart       # Web search integration
    │   └── image_save_service.dart       # Image saving to device storage
    ├── l10n/
    │   ├── app_en.arb           # English localization
    │   └── app_zh.arb           # Chinese localization
    └── utils/
        ├── constants.dart       # App constants and configuration
        └── validators.dart      # Input validation utilities
    ```

## Supported Platforms  
  
- **Desktop**: macOS, Windows, Linux (with window management)
- **Mobile**: iOS, Android
  
## Technology Stack  
  
- **Flutter**: Cross-platform UI framework  
- **Dart**: Programming language  
- **Provider**: State management solution  
- **HTTP client**: For API communications with AI providers
- **SharedPreferences**: Persistent settings storage
- **Window Manager**: Desktop window management
- **System Tray**: Desktop system tray integration
- **Localization**: Multi-language support  
  
## License  
  
This project is licensed under the MIT [License](./LICENSE) - see the LICENSE file for details.  
  
## Author  

Mutse Young © 2025