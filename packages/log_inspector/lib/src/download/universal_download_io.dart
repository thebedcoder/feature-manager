import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:log_inspector/src/utils/extensions/date_time_extension.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class UniversalDownload {
  static Future<void> downloadLogs(String content, [String logFileName = 'app_logs']) async {
    try {
      // Get the temporary directory
      final tempDir = await getTemporaryDirectory();

      // Sanitize the filename by removing invalid characters
      final fileName = DateTime.now().toFileName(logFileName);

      // Create the log file with .txt extension
      final logFile = File('${tempDir.path}/$fileName.txt');

      // Write the content to the file
      await logFile.writeAsString(content);

      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(logFile.path)],
          subject: 'Log File: $fileName',
          sharePositionOrigin: const Rect.fromLTWH(300, 0, 100, 100), // Top-right corner for iPad
        ),
      );
    } catch (e) {
      // Handle any errors during file creation or sharing
      debugPrint('Error creating or sharing log file: $e');
      rethrow;
    }
  }
}
