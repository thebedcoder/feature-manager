# Changelog

## [1.0.2] - 2025-07-24

### Fixed

- Remove redundant logs

## [1.0.1] - 2025-07-23

### Fixed

- Fixed pagination on LogInspectorScreen
- Fixed formatting of updated logs date time
- Fixed an infinity loading on LogInspectorScreen
- Updated session ID formatting

## [1.0.0] - 2025-07-23

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
