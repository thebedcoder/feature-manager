# Changelog

## 1.0.3

- **Enhanced Database Interface**: Added `getPageByKeyRange` method for improved pagination support using KeyRange filters
- **Testability Improvements**: Added `createForTesting` static methods to `LogsService` and `SessionsService` for better unit testing
- **Web Dependencies**: Added `web: ^1.1.1` and `js_interop_utils: ^1.0.8` for improved web platform support
- **SDK**: Updated Dart SDK constraint from `^3.6.0` to `'>=3.7.0 <4.0.0'` for broader compatibility
- **Web Implementation**: Migrated from direct `dart:html` usage to `package:web` and `package:js_interop_utils` for better cross-platform compatibility
- **Service Architecture**: Refactored service constructors to support dependency injection for testing
- **Dependencies**: Removed unused `flutter_lints` dependency from dev_dependencies
- **Code Quality**: Improved code formatting and structure throughout the package

## 1.0.2

- **Bug Fixes**: Remove redundant logs

## 1.0.1

- **Bug Fixes**: Fixed pagination on LogInspectorScreen
- **Bug Fixes**: Fixed formatting of updated logs date time
- **Bug Fixes**: Fixed an infinity loading on LogInspectorScreen
- **Improvements**: Updated session ID formatting

## 1.0.0

- **Initial Release**: Initial release of Log Inspector package
- **Cross-Platform Support**: Cross-platform logging support (Web, Mobile, Desktop)
- **Core Features**: UniversalLoggerOutput with automatic platform detection
- **UI Components**: LogInspectorScreen with Material Design UI
- **Services**: LoggerService for programmatic log access
- **Utilities**: LogSharingUtils with pre-built sharing utilities
- **Storage**: Persistent storage with Web localStorage and Mobile/Desktop file system storage
- **Real-time Features**: Real-time log viewing and statistics
- **Management**: Log management features (clear, download, share)
- **Customization**: Custom sharing callback support
- **UI Enhancements**: Platform indicators and storage information
- **Reliability**: Error handling and graceful fallbacks
- **Documentation**: Comprehensive documentation and examples