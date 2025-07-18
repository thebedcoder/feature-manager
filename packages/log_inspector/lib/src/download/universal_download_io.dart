import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class UniversalDownload {
  static Future<void> downloadLogs(String content, [String logFileName = 'app_logs']) async {
    try {
      // Get the temporary directory
      final tempDir = await getTemporaryDirectory();

      // Create the log file with .txt extension
      final logFile = File('${tempDir.path}/$logFileName.txt');

      // Write the content to the file
      await logFile.writeAsString(content);

      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(logFile.path)],
          subject: 'Log File: $logFileName',
        ),
      );
    } catch (e) {
      // Handle any errors during file creation or sharing
      debugPrint('Error creating or sharing log file: $e');
      rethrow;
    }
  }
}
