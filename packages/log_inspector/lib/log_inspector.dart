/// Log Inspector Package
/// 
/// Provides logging inspection capabilities for Flutter applications with
/// support for both web and mobile/desktop platforms.
/// 
/// ## Basic Usage
/// 
/// ```dart
/// // 1. Create and register a logger output
/// final logOutput = UniversalLoggerOutput(
///   shouldLog: true,
///   localStorageKey: 'my_app_logs',
/// );
/// logOutput.register();
/// 
/// // 2. Create a logger
/// final logger = Logger(output: logOutput);
/// 
/// // 3. Add logs
/// logger.i('This is an info message');
/// logger.e('This is an error message');
/// 
/// // 4. Show the log inspector
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => LogInspectorScreen()),
/// );
/// ```
/// 
/// ## Custom File Sharing
/// 
/// You can provide a custom sharing callback to handle log file sharing:
/// 
/// ```dart
/// final logOutput = UniversalLoggerOutput(
///   onShareFile: (content, fileName) async {
///     // Your custom sharing logic here
///     await Share.share(content, subject: 'App Logs');
///   },
/// );
/// ```
/// 
/// ## Pre-built Sharing Utilities
/// 
/// ```dart
/// // Copy to clipboard
/// final logOutput = UniversalLoggerOutput(
///   onShareFile: LogSharingUtils.clipboardCallback,
/// );
/// 
/// // Save to documents folder
/// final logOutput = UniversalLoggerOutput(
///   onShareFile: LogSharingUtils.documentsCallback,
/// );
/// 
/// // Save to temporary file for sharing
/// final logOutput = UniversalLoggerOutput(
///   onShareFile: LogSharingUtils.tempFileCallback,
/// );
/// ```
library;

export 'src/presentation/log_inspector_screen.dart';
export 'src/logger/logger.dart';
export 'src/utils/log_sharing_utils.dart';
