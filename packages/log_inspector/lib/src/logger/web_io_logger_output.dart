import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class WebIOLoggerOutput extends LogOutput {
  WebIOLoggerOutput({
    this.shouldLog = true,
    this.localStorageKey = 'log_inspector_logs',
  });

  final bool shouldLog;
  final String localStorageKey;

  List<String> _logs = [];

  @override
  Future<void> init() async {
    if (!shouldLog) return;
    _logs = [];
    html.window.localStorage.remove(localStorageKey);
  }

  @override
  void output(OutputEvent event) {
    if (!shouldLog) return;
    event.lines.forEach(debugPrint);
    _logs.addAll(event.lines);
    html.window.localStorage[localStorageKey] = jsonEncode(_logs);
  }

  @override
  Future<void> destroy() async {
    // No-op for web
  }

  @override
  Future<void> downloadLogs() async {
    final logs = html.window.localStorage[localStorageKey];
    if (logs == null) return;
    final blob = html.Blob([jsonDecode(logs).join('\n')], 'text/plain', 'native');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'logs.txt')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Future<void> clean() {
    // TODO: implement clean
    throw UnimplementedError();
  }

  @override
  Future<String> read() {
    // TODO: implement read
    throw UnimplementedError();
  }
}
