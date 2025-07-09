import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class IOLoggerOutput extends LogOutput {
  IOLoggerOutput({
    required this.documentsDirectory,
    required this.fileSystem,
    this.overrideExisting = false,
    this.shouldLog = true,
    this.encoding = utf8,
  });

  final Directory documentsDirectory;
  final FileSystem fileSystem;
  final bool overrideExisting;
  final Encoding encoding;

  IOSink? _sink;

  bool shouldLog;

  @override
  Future<void> init() async {
    if (!shouldLog) {
      return;
    }

    final path = await _localPath;
    final now = DateTime.now();
    final startSessionTime = '${now.year}-${now.month}-${now.day}-'
        '-${now.hour}-${now.minute}-${now.second}';
    final file = fileSystem.file('$path/$startSessionTime.log');
    debugPrint('>>> Saving logs to ${file.path}');

    _sink = file.openWrite(
      mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
      encoding: encoding,
    );
  }

  Future<String> get _localPath async {
    final logsDirectory = fileSystem.directory(
      '${documentsDirectory.path}/logs',
    );
    if (!logsDirectory.existsSync()) {
      logsDirectory.createSync();
    }
    return logsDirectory.path;
  }

  @override
  void output(OutputEvent event) {
    if (!shouldLog) {
      return;
    }

    // console output
    event.lines.forEach(debugPrint);

    // file output
    _sink?.writeAll(event.lines, '\n');
    _sink?.writeln();
  }

  @override
  Future<void> destroy() async {
    await _sink?.flush();
    await _sink?.close();
  }
}
