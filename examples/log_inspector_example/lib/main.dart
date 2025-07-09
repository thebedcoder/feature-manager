import 'package:flutter/material.dart';
import 'package:log_inspector/log_inspector.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Log Inspector Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Logger _logger;
  int _logCounter = 0;

  @override
  void initState() {
    super.initState();
    _initializeLogger();
  }

  void _initializeLogger() {
    // Create logger with UniversalLoggerOutput that works on all platforms
    final logOutput = UniversalLoggerOutput(
      shouldLog: true,
      localStorageKey: 'log_inspector_logs',
      onShareFile: LogSharingUtils.clipboardCallback, // Use clipboard sharing
      // Alternative options:
      // onShareFile: LogSharingUtils.documentsCallback, // Save to documents
      // onShareFile: LogSharingUtils.tempFileCallback,  // Save to temp file
      // onShareFile: _customShareFile,  // Custom implementation
    );
    
    // Register as global instance so LoggerService can access the same instance
    logOutput.register();

    _logger = Logger(
      output: logOutput,
      level: Level.all,
    );
  }

  void _addLogRecord() {
    _logCounter++;

    // Add various types of log records for testing
    final messages = [
      'This is info log #$_logCounter',
      'Debug message with timestamp: ${DateTime.now()}',
      'Warning: This is a sample warning log',
      'Error simulation for testing purposes',
      'Verbose log entry with detailed information',
    ];

    final levels = [Level.info, Level.debug, Level.warning, Level.error, Level.trace];
    final randomIndex = _logCounter % messages.length;

    switch (levels[randomIndex]) {
      case Level.info:
        _logger.i(messages[randomIndex]);
        break;
      case Level.debug:
        _logger.d(messages[randomIndex]);
        break;
      case Level.warning:
        _logger.w(messages[randomIndex]);
        break;
      case Level.error:
        _logger.e(messages[randomIndex]);
        break;
      case Level.trace:
        _logger.t(messages[randomIndex]);
        break;
      default:
        _logger.i(messages[randomIndex]);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added log record #$_logCounter'),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  void dispose() {
    _logger.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Inspector Demo Application'),
      ),
      body: Center(
        child: Column(
          spacing: 16,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _addLogRecord,
              child: const Text('Add Record to Log'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => LogInspectorScreen(),
                  ),
                );
              },
              child: const Text('Open Log Inspector'),
            ),
          ],
        ),
      ),
    );
  }
}
