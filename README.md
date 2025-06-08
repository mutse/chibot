# Chi Chatbot

<img src=./assets/images/logo.png width=40% height=40%/>
  
Chi Chatbot AI is a Flutter-based cross-platform application that provides an intuitive chat interface for interacting with AI language models. It currently supports integration with both OpenAI models (like GPT-4) and Google's Gemini models through a unified interface.  

## Screenshots

![](./images/chibot-mac.jpg)

## Features  
  
- **Multi-provider Support**: Interact with both OpenAI and Google Gemini AI models
- **Streaming Output**: Real-time responses from AI models
- **Text to Image**: Generate images based on text prompts
- **Clean Chat Interface**: User-friendly interface for sending messages and viewing AI responses  
- **Customizable Settings**: Configure API keys, model selection, and provider URLs  
- **Cross-platform**: Built with Flutter for compatibility across multiple platforms  
  
## Architecture  
  
Chi AI Chatbot follows a clean architecture with clear separation between presentation, state management, and service layers:  
  
- **Presentation Layer**: UI components for chat and settings screens  
- **State Management**: Provider pattern for managing application state  
- **Service Layer**: Abstraction for communicating with different AI providers  
  
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
    ├── main.dart # Application entry point
    ├── models/
    │ └── chat_message.dart # Data model for chat messages
    ├── providers/
    │ └── settings_provider.dart # State management for app settings
    ├── screens/
    │ ├── chat_screen.dart # Main chat interface
    │ └── settings_screen.dart # Settings configuration
    └── services/
    └── openai_service.dart # Service for AI provider communication
    ```

## Supported Platforms  
  
- macOS
- iOS 
- Android
- Web (possible)  
- Windows 
- Linux
  
## Technology Stack  
  
- **Flutter**: Cross-platform UI framework  
- **Dart**: Programming language  
- **Provider**: State management solution  
- **HTTP client**: For API communications with AI providers  
  
## License  
  
This project is licensed under the MIT [License](./LICENSE) - see the LICENSE file for details.  
  
## Author  
  
Mutse Young © 2025