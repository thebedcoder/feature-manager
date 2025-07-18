# Log Inspector

A Flutter package that provides a comprehensive logging inspection interface for debugging and monitoring your Flutter applications. Works seamlessly across web, mobile, and desktop platforms with persistent storage and customizable sharing options.

## Features

- 📱 **Cross-platform support**: Works on web, mobile, and desktop
- 💾 **Persistent storage**: Web uses localStorage, mobile/desktop uses file system
- 🔍 **Real-time log viewing**: See logs as they're generated
- 📊 **Log statistics**: View log count, file size, and storage information
- 🗑️ **Log management**: Clear logs with confirmation
- 📤 **Flexible sharing**: Download logs or use custom sharing callbacks
- 🎨 **Beautiful UI**: Clean, Material Design interface with platform indicators
- 🔧 **Easy integration**: Simple setup with your existing logger
- 📋 **Pre-built utilities**: Clipboard, file saving, and sharing helpers

## Screenshots

| Web Interface | Mobile Interface |
|---------------|------------------|
| Clean web interface with localStorage | Mobile interface with file-based storage |

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  log_inspector: ^1.0.0
  logger: ^2.5.0  # Required peer dependency
```

Run:
```bash
flutter pub get
```

### Basic Usage

1. **Set up the logger output**:

```dart
import 'package:log_inspector/log_inspector.dart';
import 'package:logger/logger.dart';

// Create and register the logger output
final logOutput = UniversalLoggerOutput(
  shouldLog: true,
  localStorageKey: 'my_app_logs',
  logFileName: 'app_logs',
);
logOutput.register(); // Register as global instance

// Create your logger
final logger = Logger(
  output: logOutput,
  level: Level.all,
);
```

2. **Add logs throughout your app**:

```dart
logger.i('User logged in successfully');
logger.w('API rate limit approaching');
logger.e('Failed to sync data', error: exception);
logger.d('Debug: Processing ${items.length} items');
```

3. **Show the log inspector**:

```dart
// Add a button or menu item to open the inspector
ElevatedButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LogInspectorScreen(),
      ),
    );
  },
  child: const Text('Open Log Inspector'),
)
```

## Advanced Usage

### Custom File Sharing

Provide custom sharing functionality using the `onShareFile` callback:

```dart
// Using share_plus package
final logOutput = UniversalLoggerOutput(
  onShareFile: (content, fileName) async {
    await Share.share(content, subject: 'App Logs - $fileName');
  },
);

// Custom sharing implementation
final logOutput = UniversalLoggerOutput(
  onShareFile: (content, fileName) async {
    // Save to a specific location
    final file = File('/path/to/logs/$fileName');
    await file.writeAsString(content);
    
    // Trigger your custom sharing logic
    await MyCustomSharing.shareFile(file.path);
  },
);
```

### Pre-built Sharing Utilities

The package includes convenient sharing utilities:

```dart
// Copy logs to clipboard
final logOutput = UniversalLoggerOutput(
  onShareFile: LogSharingUtils.clipboardCallback,
);

// Save to app documents directory
final logOutput = UniversalLoggerOutput(
  onShareFile: LogSharingUtils.documentsCallback,
);

// Save to temporary file for sharing
final logOutput = UniversalLoggerOutput(
  onShareFile: LogSharingUtils.tempFileCallback,
);
```

### Multiple Logger Outputs

Combine with other logger outputs:

```dart
final logger = Logger(
  output: MultiOutput([
    ConsoleOutput(),           // Console output for development
    UniversalLoggerOutput(),   // Log inspector storage
    FileOutput(file: myFile),  // Additional file logging
  ]),
);
```

### Integration with LoggerService

Use the LoggerService for programmatic access:

```dart
final loggerService = LoggerServiceImpl();

// Read current logs
final logs = await loggerService.readLogs();

// Get log statistics
final count = await loggerService.getLogFilesCount();
final size = await loggerService.getLogsSizeInBytes();

// Clear logs programmatically
await loggerService.cleanLogs();

// Trigger download/sharing
await loggerService.downloadLogs();
```

## Platform-Specific Behavior

### Web
- Uses browser localStorage for persistence
- Downloads logs as `.txt` files
- Automatically handles JSON encoding/decoding
- Shows "WEB" platform indicator

### Mobile & Desktop
- Uses file system storage via `path_provider`
- Stores logs in app documents directory with timestamps
- Supports file-based sharing and export
- Shows "MOBILE/DESKTOP" platform indicator
- Graceful fallback to in-memory storage if file operations fail

## Configuration Options

### UniversalLoggerOutput Parameters

```dart
UniversalLoggerOutput({
  bool shouldLog = true,                    // Enable/disable logging
  String localStorageKey = 'log_inspector_logs',  // Storage key
  String logFileName = 'app_logs',          // Base filename for logs
  Future<void> Function(String, String)? onShareFile,  // Custom sharing
})
```

### LogInspectorScreen

The screen automatically adapts to the platform and shows:
- Log count and total size
- Platform indicator (Web/Mobile/Desktop)
- Storage type information
- Real-time log content with timestamps
- Action buttons for refresh, download, and clear

## Error Handling

The package includes robust error handling:

- Graceful fallback to in-memory storage if file operations fail
- Error messages displayed in the UI
- Console warnings for configuration issues
- Safe handling of malformed log data

## Development & Testing

### Running the Example

```bash
cd example
flutter run
```

The example app demonstrates:
- Logger setup and registration
- Adding various types of log entries
- Opening the log inspector
- Custom sharing implementation

### Testing Different Platforms

```bash
# Web
flutter run -d chrome

# Desktop
flutter run -d macos
flutter run -d windows
flutter run -d linux

# Mobile
flutter run -d ios
flutter run -d android
```

## Dependencies

- `flutter`: SDK
- `logger`: ^2.5.0 (peer dependency)
- `path_provider`: ^2.1.5 (for mobile/desktop file storage)
- `path`: ^1.9.0 (for path operations)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Areas for Contribution

- Additional sharing integrations
- UI improvements and themes
- Performance optimizations
- Additional logger output formats
- Enhanced filtering and search

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

## Additional Information

- **Issues**: Report bugs and request features on [GitHub Issues](https://github.com/your-repo/log_inspector/issues)
- **Documentation**: Full API documentation available on [pub.dev](https://pub.dev/packages/log_inspector)
- **Examples**: More examples available in the `/example` directory
