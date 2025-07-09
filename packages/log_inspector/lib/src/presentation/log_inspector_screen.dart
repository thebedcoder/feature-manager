import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:log_inspector/src/logger/logger_service.dart';

class LogInspectorScreen extends StatefulWidget {
  const LogInspectorScreen({super.key});

  @override
  State<LogInspectorScreen> createState() => _LogInspectorScreenState();
}

class _LogInspectorScreenState extends State<LogInspectorScreen> {
  bool _isLoading = false;
  String? _error;
  String _logsContent = '';
  int _logFilesCount = 0;
  int _logsSizeBytes = 0;
  late LoggerService _loggerService;

  @override
  void initState() {
    super.initState();
    _loggerService = LoggerServiceImpl();
    _loadLogsInfo();
  }

  Future<void> _loadLogsInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final filesCount = await _loggerService.getLogFilesCount();
      final sizeBytes = await _loggerService.getLogsSizeInBytes();
      final content = await _loggerService.readLogs();

      setState(() {
        _logFilesCount = filesCount;
        _logsSizeBytes = sizeBytes;
        _logsContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadLogs() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loggerService.downloadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs download triggered.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text(
          'Are you sure you want to clear all log files? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loggerService.cleanLogs();
      await _loadLogsInfo(); // Reload to update UI

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing logs: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs Inspector '),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _isLoading ? null : _downloadLogs,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _isLoading ? null : _clearLogs,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLogsInfo,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Logs Information',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kIsWeb ? Colors.blue.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kIsWeb ? Colors.blue.shade300 : Colors.green.shade300,
                              ),
                            ),
                            child: Text(
                              kIsWeb ? 'WEB' : 'MOBILE/DESKTOP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kIsWeb ? Colors.blue.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Files: $_logFilesCount'),
                          Text('Size: ${_formatFileSize(_logsSizeBytes)}'),
                        ],
                      ),
                      if (kIsWeb && _logFilesCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Source: localStorage',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
                // Logs content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [],
                    ),
                    child: _logsContent.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No logs found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  kIsWeb
                                      ? 'Start adding logs to see them here'
                                      : 'File system logging not implemented yet',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Log header with metadata
                              if (_logFilesCount > 0) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Showing ${_logsContent.split('\n').where((line) => line.trim().isNotEmpty).length} log entries',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Last updated: ${DateTime.now().toString().substring(0, 19)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              // Log content
                              Expanded(
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    _logsContent,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
