# Log Inspector

A comprehensive Flutter package that provides an advanced logging inspection interface for debugging and monitoring Flutter applications. Features session-based log management, cross-platform persistence, and a beautiful Material Design interface.

## Features

- 📱 **Universal cross-platform support**: Web, iOS, Android, macOS, Windows, Linux
- 💾 **Session-based log storage**: Automatic session management with IndexedDB/file system persistence
- 🔍 **Advanced log viewing**: Real-time log inspection with infinite scroll pagination
- 📊 **Session analytics**: View session count, log statistics, and storage information
- 🗑️ **Smart log management**: Session-specific or global log clearing with confirmation
- 📤 **Universal download system**: Cross-platform log export and sharing
- 🎨 **Material Design UI**: Clean interface with session indicators and platform detection
- 🔧 **Zero-configuration setup**: Drop-in replacement for standard logger outputs
- 📋 **Session navigation**: Browse and manage multiple logging sessions
- ⚡ **Performance optimized**: Efficient pagination and lazy loading

## What's New in v1.0.0

- **Session Management**: Automatic session creation with unique identifiers
- **Advanced UI**: Two dedicated screens - Session Inspector and Detailed Log Viewer
- **Database Integration**: Uses IndexedDB for web and file system for native platforms
- **Infinite Scroll**: Paginated log loading for better performance with large datasets

## Interface Screenshots

| Session Inspector                                | Detailed Log Viewer                        |
| ------------------------------------------------ | ------------------------------------------ |
| ![Session Inspector](doc/session-inspector.png)  | ![Log Viewer](doc/log-viewer.png)          |
| Manage multiple logging sessions with statistics | View and analyze logs with infinite scroll |

_Screenshots show the clean Material Design interface with session management and detailed log inspection capabilities._

## Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  log_inspector: ^1.0.0
  logger: ^2.5.0 # Required peer dependency
```

```bash
flutter pub get
```

### Basic Setup

**1. Initialize the logger output:**

```dart
import 'package:log_inspector/log_inspector.dart';
import 'package:logger/logger.dart';

// Create the universal logger output
final logOutput = UniversalLoggerOutput();

// Create your logger
final logger = Logger(
  output: logOutput,
  level: Level.all,
);
```

**2. Log your events:**

```dart
logger.i('Application started successfully');
logger.w('Low memory warning detected');
logger.e('Network request failed', error: exception, stackTrace: stackTrace);
logger.d('User interaction: ${action.name}');
```

**3. Access the inspection interface:**

```dart
// Open the Session Inspector
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const LogInspectorScreen(),
  ),
);

// Or view current session logs directly
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DetailedLogsScreen(),
  ),
);
```
## Example Application

The package includes a comprehensive example demonstrating all features:

```dart
// example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:log_inspector/log_inspector.dart';
import 'package:logger/logger.dart';

void main() => runApp(const LogInspectorDemo());

class LogInspectorDemo extends StatefulWidget {
  @override
  State<LogInspectorDemo> createState() => _LogInspectorDemoState();
}

class _LogInspectorDemoState extends State<LogInspectorDemo> {
  late Logger _logger;

  @override
  void initState() {
    super.initState();

    // Initialize the logger with UniversalLoggerOutput
    final logOutput = UniversalLoggerOutput();
    _logger = Logger(output: logOutput, level: Level.all);
  }

  void _addTestLogs() {
    _logger.i('Info: Application event logged');
    _logger.w('Warning: Something needs attention');
    _logger.e('Error: Something went wrong');
    _logger.d('Debug: Detailed diagnostic information');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Log Inspector Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _addTestLogs,
                child: const Text('Add Test Logs'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogInspectorScreen(),
                  ),
                ),
                icon: const Icon(Icons.folder),
                label: const Text('Open Session Inspector'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetailedLogsScreen(),
                  ),
                ),
                icon: const Icon(Icons.description),
                label: const Text('View Current Session Logs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Performance Tips

- Use appropriate log levels in production (`Level.warning` or higher)
- Implement log rotation for long-running applications
- Consider using `shouldLog: false` in production builds

```dart
final logOutput = UniversalLoggerOutput(
  shouldLog: !kReleaseMode, // Only log in debug mode
);
```

## Contributing

We welcome contributions! Here's how you can help:

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
