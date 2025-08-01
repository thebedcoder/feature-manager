// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:log_inspector/src/utils/extensions/date_time_extension.dart';

class UniversalDownload {
  static Future<void> downloadLogs(String content, [String logFileName = 'app_logs']) async {
    try {
      final fileName = DateTime.now().toFileName(logFileName);

      // Use html APIs for web download
      final blob = html.Blob([content], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);

      (html.AnchorElement(href: url)..setAttribute('download', "$fileName.txt")).click();

      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Error downloading web logs: $e');
    }
  }
}
