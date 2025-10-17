# FlowFlutter 🤖💬

A modern, beautiful Flutter mobile chat client for [Flowise](https://flowiseai.com/) - your AI chatflow platform. Built with Material Design 3 and featuring a stunning dark theme.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?style=flat&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat&logo=dart)
![Material Design 3](https://img.shields.io/badge/Material_Design-3-757575?style=flat&logo=material-design)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

## ✨ Features

### Core Functionality
- 🔄 **Real-time Streaming** - Live token-by-token responses via Server-Sent Events (SSE)
- 💾 **Persistent History** - Secure local storage of conversations with chatId continuity
- ⚙️ **Flexible Configuration** - Easy setup with API host and chatflow ID
- 🎨 **Beautiful Dark Theme** - Modern UI inspired by premium AI chat apps
- 📱 **Cross-Platform** - iOS, Android, Web, Windows, macOS, Linux support

### Advanced Features
- 📄 **Source Documents** - Expandable panels showing RAG document sources
- 🛠️ **Tool Usage Display** - Visual chips showing which tools the AI used
- ⏱️ **Smart Timestamps** - Relative time formatting (e.g., "2m ago", "Today at 14:30")
- 🚨 **Intelligent Error Handling** - User-friendly error messages with specific guidance
- 🔄 **Automatic Retry** - Exponential backoff for rate limiting (429 errors)
- 💬 **Empty State** - Welcoming screen with suggestion chips
- 🎯 **Non-streaming Fallback** - Seamless switch between streaming and non-streaming modes

## 🎨 Design

FlowFlutter features a premium dark theme with:
- **Navy Blue Background** (`#1A2332`) - Easy on the eyes
- **Vibrant Blue Accents** (`#4169FF`) - Modern and professional
- **Cyan Highlights** (`#00D4FF`) - For AI assistant elements
- **Gradient Message Bubbles** - Beautiful visual hierarchy
- **Roboto Font Family** - Clean, readable typography

## 📸 Screenshots

> Coming soon - Add your screenshots here!

## 🛠️ Tech Stack

- **Framework**: Flutter 3.9.2+
- **Language**: Dart 3.0+
- **State Management**: StatefulWidget with ChangeNotifier patterns (KISS approach)
- **Storage**:
  - `flutter_secure_storage` - Encrypted chatId and message storage
  - `shared_preferences` - App configuration
- **HTTP Client**: `http` package with custom SSE parsing
- **UI**: Material Design 3 with custom theming
- **Formatting**: `intl` for timestamps

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK 3.0 or higher
- A running [Flowise](https://github.com/FlowiseAI/Flowise) instance
- Chatflow ID from your Flowise setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/flowflutter.git
   cd flowflutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For web
   flutter run -d chrome

   # For mobile (with device/emulator connected)
   flutter run

   # For desktop
   flutter run -d windows  # or macos, linux
   ```

## ⚙️ Configuration

### First Launch

1. Launch the app - you'll see the chat screen with an empty state
2. Tap the **Settings icon (⚙️)** in the top-right corner
3. Configure:
   - **API Host**: Your Flowise server URL (e.g., `https://your-flowise.com`)
   - **Chatflow ID**: Your chatflow identifier
   - **Use Streaming**: Toggle for real-time vs batch responses
4. Tap **"Save Settings"**
5. Start chatting!

### API Key Security

⚠️ **Important**: Never hardcode API keys in your app!

For production:
- Use a **backend proxy** that adds the `Authorization: Bearer <key>` header
- Update `apiHost` to point to your proxy endpoint
- Let the proxy handle authentication with Flowise

For development:
- Flowise chatflows can be made public (no API key required)
- Or use environment-specific configuration

## 📱 Usage

### Chat Features

- **Send Messages**: Type and press Enter or tap the send button
- **Streaming Responses**: Watch AI responses appear in real-time
- **View Sources**: Tap to expand source documents in RAG responses
- **Tool Information**: See which tools the AI used (displayed as chips)
- **New Chat**: Tap the "+" icon to start fresh
- **Settings**: Tap the gear icon to update configuration

### Error Handling

The app provides helpful error messages:
- `"No internet connection"` - Check your network
- `"Invalid API key"` - Verify credentials in settings
- `"Chatflow not found"` - Check your Chatflow ID
- `"Too many requests"` - Automatic retry with countdown
- `"Server error"` - Flowise may be down, try later

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry point with theme configuration
├── models/
│   ├── app_config.dart       # Configuration model
│   ├── chat_message.dart     # Message and SourceDocument models
│   └── sse_event.dart        # Server-Sent Events parsing
├── screens/
│   ├── chat_screen.dart      # Main chat interface
│   └── settings_screen.dart  # Configuration screen
├── services/
│   ├── config_store.dart     # SharedPreferences wrapper
│   ├── history_store.dart    # Secure storage for messages
│   └── prediction_service.dart # Flowise API client (streaming/non-streaming)
└── widgets/
    └── message_bubble.dart   # Chat message UI component
```

### Key Design Principles

- **KISS (Keep It Simple, Stupid)**: Minimal abstractions, clear code
- **YOLO (You Only Live Once)**: Fast MVP, iterate based on feedback
- **Separation of Concerns**: Clear distinction between UI, business logic, and data
- **Stateful Simplicity**: Using built-in Flutter state management (no complex state libraries)

## 🔄 Development

### Running Tests

```bash
flutter test
```

### Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows --release  # or macos, linux
```

### Docker Deployment

FlowFlutter can be deployed as a web application using Docker:

#### Using Pre-built Image

```bash
# Pull from GitHub Container Registry
docker pull ghcr.io/xhorizont/flowflutter:latest

# Run the container
docker run -d \
  --name flowflutter \
  -p 8080:80 \
  ghcr.io/xhorizont/flowflutter:latest

# Access at http://localhost:8080
```

#### Building Locally

```bash
# Build the image
docker build -t flowflutter:local .

# Run the container
docker run -d \
  --name flowflutter \
  -p 8080:80 \
  flowflutter:local
```

#### Available Tags

- `latest` - Latest stable release
- `1.0.x` - Specific version
- `1.0` - Latest 1.0.x version
- `1` - Latest 1.x.x version

The Docker image:
- Multi-stage build for optimal size (~50MB)
- Nginx serving Flutter web build
- Health check included
- Multi-architecture support (linux/amd64, linux/arm64)

### Hot Reload

While developing:
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

## 🐛 Troubleshooting

### CORS Issues (Web)

If running on web and getting CORS errors:

1. Configure Flowise with:
   ```bash
   CORS_ORIGINS=http://localhost:8080
   IFRAME_ORIGINS=http://localhost:8080
   ```

2. Or use a proxy server to bypass CORS

### Streaming Not Working

- Ensure Flowise version is 2.1.0+ for reliable SSE support
- Check `useStreaming` toggle in settings
- Verify network allows SSE connections

### Messages Not Persisting

- `flutter_secure_storage` may have issues on some platforms
- Check app permissions for storage access
- Try clearing app data and reconfiguring

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📋 Roadmap

- [ ] File uploads (images, audio, documents)
- [ ] RAG document upsert workflow
- [ ] Multi-chat management
- [ ] Voice input (speech-to-text)
- [ ] Message search
- [ ] Export conversations
- [ ] Dark/Light theme toggle
- [ ] Custom themes
- [ ] Markdown rendering in messages
- [ ] Code syntax highlighting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flowise](https://flowiseai.com/) - The amazing AI chatflow platform
- [Flutter](https://flutter.dev/) - Beautiful native apps framework
- [Material Design 3](https://m3.material.io/) - Design system

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/flowflutter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/flowflutter/discussions)
- **Flowise Docs**: [docs.flowiseai.com](https://docs.flowiseai.com/)

## 🌟 Star History

If you find this project useful, please consider giving it a star! ⭐

---

**Built with ❤️ using Flutter and Flowise**
