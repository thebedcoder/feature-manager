// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

class UniversalDownload {
  static Future<void> downloadLogs(String content, [String logFileName = 'app_logs']) async {
    try {
      final currentTime = DateTime.now();
      final fileName =
          '${logFileName}_${currentTime.year}_${currentTime.month}_${currentTime.day}_${currentTime.hour}_${currentTime.minute}.txt';

      // Use html APIs for web download
      final blob = html.Blob([content], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);

      (html.AnchorElement(href: url)..setAttribute('download', fileName)).click();

      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Error downloading web logs: $e');
    }
  }
}
