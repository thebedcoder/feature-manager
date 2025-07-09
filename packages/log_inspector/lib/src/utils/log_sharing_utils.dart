import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Utility class providing common sharing implementations for UniversalLoggerOutput
class LogSharingUtils {
  LogSharingUtils._();

  /// Copy content to clipboard
  static Future<void> copyToClipboard(String content, String fileName) async {
    await Clipboard.setData(ClipboardData(text: content));
    debugPrint('Logs copied to clipboard: $fileName');
  }

  /// Save content to a temporary file and return the file path
  /// Useful for sharing with external apps
  static Future<String> saveToTempFile(String content, String fileName) async {
    if (kIsWeb) {
      throw UnsupportedError('File operations not supported on web');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, fileName));
    await file.writeAsString(content);
    debugPrint('Logs saved to temporary file: ${file.path}');
    return file.path;
  }

  /// Save content to app documents directory
  static Future<String> saveToDocuments(String content, String fileName) async {
    if (kIsWeb) {
      throw UnsupportedError('File operations not supported on web');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory(path.join(docsDir.path, 'shared_logs'));
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    
    final file = File(path.join(logsDir.path, fileName));
    await file.writeAsString(content);
    debugPrint('Logs saved to documents: ${file.path}');
    return file.path;
  }

  /// Example implementation using share_plus package
  /// Uncomment and use when share_plus is added to dependencies
  /*
  static Future<void> shareWithSharePlus(String content, String fileName) async {
    try {
      if (kIsWeb) {
        // On web, just share the text content
        await Share.share(content, subject: 'App Logs - $fileName');
      } else {
        // On mobile/desktop, save to temp file and share
        final filePath = await saveToTempFile(content, fileName);
        await Share.shareXFiles([XFile(filePath)], text: 'App Logs');
      }
    } catch (e) {
      debugPrint('Error sharing with share_plus: $e');
      // Fallback to clipboard
      await copyToClipboard(content, fileName);
    }
  }
  */

  /// Create a callback that copies content to clipboard
  static Future<void> Function(String content, String fileName) get clipboardCallback {
    return copyToClipboard;
  }

  /// Create a callback that saves to documents directory
  static Future<void> Function(String content, String fileName) get documentsCallback {
    return (content, fileName) async {
      await saveToDocuments(content, fileName);
    };
  }

  /// Create a callback that saves to temp file for sharing
  static Future<void> Function(String content, String fileName) get tempFileCallback {
    return (content, fileName) async {
      await saveToTempFile(content, fileName);
    };
  }
}
