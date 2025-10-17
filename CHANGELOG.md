# Changelog

All notable changes to FlowFlutter will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-16

### Added
- 🎉 Initial release of FlowFlutter
- 🔄 Real-time streaming chat with Server-Sent Events (SSE)
- 💾 Persistent chat history with secure storage
- ⚙️ Flexible configuration screen for API host and chatflow ID
- 🎨 Beautiful dark theme with navy blue and vibrant blue accents
- 📄 Source documents display in expandable panels
- 🛠️ Tool usage visualization with chips
- ⏱️ Smart timestamp formatting (relative and absolute)
- 🚨 Intelligent error handling with user-friendly messages
- 🔄 Automatic retry with exponential backoff for rate limiting (429 errors)
- 💬 Welcome empty state with suggestion chips
- 🎯 Non-streaming fallback mode
- 🌐 Cross-platform support (iOS, Android, Web, Windows, macOS, Linux)

### Technical Features
- Material Design 3 theming
- Custom SSE event parsing
- Roboto font family with light weight (300)
- Gradient message bubbles for user messages
- Settings screen with validation
- New chat functionality
- ChatId continuity between sessions
- Metadata event handling from Flowise API

### Security
- No hardcoded API keys
- Secure storage for chat history
- Best practices for API key handling documented

## [Unreleased]

### Planned Features
- File uploads (images, audio, documents)
- RAG document upsert workflow
- Multi-chat management
- Voice input (speech-to-text)
- Message search functionality
- Export conversations
- Dark/Light theme toggle
- Custom theme support
- Markdown rendering in messages
- Code syntax highlighting
- Unit and widget tests
- Integration tests

---

## Version History

### [1.0.0] - 2025-10-16
First public release with core chat functionality, streaming support, and beautiful UI.
