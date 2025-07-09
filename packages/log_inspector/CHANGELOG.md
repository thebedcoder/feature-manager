# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-07-08

### Added
- Initial release of Log Inspector package
- Cross-platform logging support (Web, Mobile, Desktop)
- `UniversalLoggerOutput` with automatic platform detection
- `LogInspectorScreen` with Material Design UI
- `LoggerService` for programmatic log access
- `LogSharingUtils` with pre-built sharing utilities
- Persistent storage:
  - Web: localStorage with JSON encoding
  - Mobile/Desktop: File system storage with timestamps
- Real-time log viewing and statistics
- Log management features (clear, download, share)
- Custom sharing callback support
- Platform indicators and storage information
- Error handling and graceful fallbacks
- Comprehensive documentation and examples

### Features
- 📱 Cross-platform support (Web, iOS, Android, macOS, Windows, Linux)
- 💾 Persistent log storage with automatic platform detection
- 🔍 Real-time log viewing with searchable content
- 📊 Log statistics (count, size, storage type)
- 🗑️ Log management with confirmation dialogs
- 📤 Flexible sharing options with custom callbacks
- 🎨 Clean Material Design interface
- 🔧 Simple integration with existing logger setup
- 📋 Pre-built sharing utilities (clipboard, documents, temp files)

### Dependencies
- flutter: SDK
- logger: ^2.5.0
- path_provider: ^2.1.5
- path: ^1.9.0

### Supported Platforms
- ✅ Web (localStorage)
- ✅ iOS (file system)
- ✅ Android (file system)
- ✅ macOS (file system)
- ✅ Windows (file system)
- ✅ Linux (file system)