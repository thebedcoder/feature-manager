import 'package:js_interop_utils/js_interop_utils.dart';
import 'package:web/web.dart' as web;

import 'package:flutter/foundation.dart';
import 'package:log_inspector/src/utils/extensions/date_time_extension.dart';

class UniversalDownload {
  static Future<void> downloadLogs(String content, [String logFileName = 'app_logs']) async {
    try {
      final fileName = DateTime.now().toFileName(logFileName);

      // Use html APIs for web download
      final blobContent = [content].toJS;

      final blob = web.Blob(blobContent, web.BlobPropertyBag(type: 'text/plain'));
      final url = web.URL.createObjectURL(blob);

      (web.HTMLAnchorElement()
            ..setAttribute('href', url)
            ..setAttribute('download', "$fileName.txt"))
          .click();

      web.URL.revokeObjectURL(url);
    } catch (e) {
      debugPrint('Error downloading web logs: $e');
    }
  }
}
