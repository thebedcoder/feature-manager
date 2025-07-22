import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class UniversalDownload {
  static Future<void> downloadLogs(String content, [String logFileName = 'app_logs']) async {
    try {
      // Get the temporary directory
      final tempDir = await getTemporaryDirectory();

      // Sanitize the filename by removing invalid characters
      final sanitizedFileName = _sanitizeFileName(logFileName);

      // Create the log file with .txt extension
      final logFile = File('${tempDir.path}/$sanitizedFileName.txt');

      // Write the content to the file
      await logFile.writeAsString(content);

      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(logFile.path)],
          subject: 'Log File: $sanitizedFileName',
          sharePositionOrigin: Rect.fromLTWH(0, 0, 100, 100), // Required for iPad
        ),
      );
    } catch (e) {
      // Handle any errors during file creation or sharing
      debugPrint('Error creating or sharing log file: $e');
      rethrow;
    }
  }

  static String _sanitizeFileName(String fileName) {
    // Replace invalid characters with underscores or dashes
    return fileName
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_') // Replace invalid chars
        .replaceAll(' ', '_') // Replace spaces with underscores
        .trim(); // Remove leading/trailing whitespace
  }
}
