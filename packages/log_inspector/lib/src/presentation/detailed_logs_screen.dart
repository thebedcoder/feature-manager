import 'package:flutter/material.dart';
import 'package:log_inspector/src/services/logger_service/logger_service.dart';
import 'package:log_inspector/src/services/logger_service/logger_service_impl.dart';

class DetailedLogsScreen extends StatefulWidget {
  const DetailedLogsScreen({super.key, this.sessionId});

  /// Optional session ID to view logs for a specific session
  /// If null, defaults to the current session
  final String? sessionId;

  @override
  State<DetailedLogsScreen> createState() => _DetailedLogsScreenState();
}

class _DetailedLogsScreenState extends State<DetailedLogsScreen> {
  bool _isLoading = false;
  late LoggerService _loggerService;

  int _currentPage = 0;
  int _totalPages = 0;

  List<String> _allLoadedLogs = [];
  bool _isLoadingMore = false;

  // Scroll controller to maintain position
  final ScrollController _scrollController = ScrollController();

  /// Whether this screen is viewing a specific session or the current session
  bool get _isViewingSpecificSession => widget.sessionId != null;

  /// The session ID being viewed (or current session if none specified)
  String get _targetSessionId => widget.sessionId ?? _loggerService.currentSessionId;

  String _getSessionDisplayName(String sessionId) {
    try {
      final parts = sessionId.split('_');
      if (parts.isNotEmpty) {
        final lastPart = parts.last;
        if (lastPart.length > 8) {
          return '${lastPart.substring(0, 8)}...';
        } else {
          return lastPart;
        }
      }
      return sessionId;
    } catch (e) {
      // Fallback to first 8 characters of the full ID if parsing fails
      return sessionId.length > 8 ? '${sessionId.substring(0, 8)}...' : sessionId;
    }
  }

  @override
  void initState() {
    super.initState();
    _loggerService = LoggerServiceImpl();
    _loadLogsInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogsInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadPaginatedData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPaginatedData({bool append = false}) async {
    try {
      // Get paginated logs using the logger service for the target session
      final paginatedResult = _isViewingSpecificSession
          ? await _loggerService.readLogsPaginatedForSession(_targetSessionId, _currentPage)
          : await _loggerService.readLogsPaginated(_currentPage);

      setState(() {
        if (append) {
          // Append new logs to existing list for infinite scroll
          _allLoadedLogs.addAll(paginatedResult.logs);
        } else {
          // Reset list for initial load or manual page navigation
          _allLoadedLogs = List.from(paginatedResult.logs);
        }
        _totalPages = paginatedResult.totalPages;
      });
    } catch (e) {
      setState(() {
        if (!append) {
          _allLoadedLogs = [];
        }
      });
    }
  }

  Future<void> _loadNextPageInfinite() async {
    if (_currentPage >= _totalPages - 1 || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadPaginatedData(append: true);

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _downloadLogs() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isViewingSpecificSession) {
        await _loggerService.downloadLogsForSession(_targetSessionId);
      } else {
        await _loggerService.downloadLogs();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs download triggered.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearLogs() async {
    final sessionText = _isViewingSpecificSession ? 'this session\'s logs' : 'all log files';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: Text(
          'Are you sure you want to clear $sessionText? This action cannot be undone.',
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
    });

    try {
      if (_isViewingSpecificSession) {
        await _loggerService.clearLogsForSession(_targetSessionId);
      } else {
        await _loggerService.cleanLogs();
      }

      await _loadLogsInfo(); // Reload to update UI

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isViewingSpecificSession
            ? 'Session Logs (${_getSessionDisplayName(_targetSessionId)})'
            : 'Logs Inspector'),
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
          : _allLoadedLogs.isEmpty
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
                        'No logs on this page',
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
                    Expanded(
                      child: FutureBuilder<List<String>>(
                        future: Future.value(_allLoadedLogs),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading logs: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          final logs = snapshot.data ?? [];
                          if (logs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No logs available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              // Auto-load next page when close to bottom (within 200 pixels)
                              if (scrollInfo.metrics.pixels >=
                                      scrollInfo.metrics.maxScrollExtent - 200 &&
                                  _currentPage < _totalPages - 1 &&
                                  !_isLoading &&
                                  !_isLoadingMore) {
                                _loadNextPageInfinite();
                              }
                              return false;
                            },
                            child: ListView.separated(
                              controller: _scrollController,
                              itemCount:
                                  _allLoadedLogs.length + (_currentPage < _totalPages - 1 ? 1 : 0),
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                color: Colors.grey,
                                thickness: 0.1,
                              ),
                              itemBuilder: (context, index) {
                                // Show loading indicator for next page
                                if (index >= _allLoadedLogs.length) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_isLoadingMore
                                              ? 'Loading more logs...'
                                              : 'Loading next page...'),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final logEntry = _allLoadedLogs[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          logEntry,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
