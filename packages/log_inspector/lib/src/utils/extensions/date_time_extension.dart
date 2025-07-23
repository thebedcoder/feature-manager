extension DateTimeExtension on DateTime {
  /// Formats the DateTime to a string in the format 'yyyy-MM-dd HH:mm:ss'
  String formatDateTime() {
    return '$year.${month.toString().padLeft(2, '0')}.${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  String toSessionId() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}_${hour.toString().padLeft(2, '0')}-${minute.toString().padLeft(2, '0')}-${second.toString().padLeft(2, '0')}';
  }

  String toFileName([String prefix = '']) =>
      '${prefix}_$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}_${hour.toString().padLeft(2, '0')}-${minute.toString().padLeft(2, '0')}-${second.toString().padLeft(2, '0')}'
          .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
          .replaceAll(' ', '_')
          .trim();
}
