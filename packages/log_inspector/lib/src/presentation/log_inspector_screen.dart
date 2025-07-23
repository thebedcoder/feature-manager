import 'package:flutter/material.dart';
import 'package:log_inspector/src/services/logger_service/logger_service.dart';
import 'package:log_inspector/src/services/logger_service/logger_service_impl.dart';
import 'package:log_inspector/src/models/session.dart';
import 'package:log_inspector/src/presentation/detailed_logs_screen.dart';
import 'package:log_inspector/src/utils/extensions/date_time_extension.dart';

class LogInspectorScreen extends StatefulWidget {
  const LogInspectorScreen({super.key});

  @override
  State<LogInspectorScreen> createState() => _LogInspectorScreenState();
}

class _LogInspectorScreenState extends State<LogInspectorScreen> {
  bool _isLoading = false;
  late LoggerService _loggerService;

  int _currentPage = 0;
  int _totalPages = 0;

  List<LogSession> _allLoadedSessions = [];
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loggerService = LoggerServiceImpl();
    _loadSessionsInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionsInfo() async {
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
      // Get paginated sessions using the logger service
      final paginatedResult = await _loggerService.getSessionsPaginated(_currentPage);

      setState(() {
        if (append) {
          // Append new sessions to existing list for infinite scroll
          _allLoadedSessions.addAll(paginatedResult.sessions);
        } else {
          // Reset list for initial load or manual page navigation
          _allLoadedSessions = List.from(paginatedResult.sessions);
        }
        _totalPages = paginatedResult.totalPages;
      });
    } catch (e) {
      setState(() {
        if (!append) {
          _allLoadedSessions = [];
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

  Future<void> _deleteSession(LogSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete this session and all its logs?\n\n'
          'Session: ${session.id}\n'
          'Created: ${session.createdAt.formatDateTime()}\n'
          'Logs: ${session.logCount}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
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
      await _loggerService.deleteSession(session.id);
      await _loadSessionsInfo(); // Reload to update UI

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting session: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadSessionLogs(LogSession session) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loggerService.downloadLogsForSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session logs download triggered.')),
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

  void _viewSessionLogs(LogSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailedLogsScreen(sessionId: session.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Inspector'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSessionsInfo,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allLoadedSessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No sessions found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    // Auto-load next page when close to bottom (within 200 pixels)
                    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
                        _currentPage < _totalPages - 1 &&
                        !_isLoading &&
                        !_isLoadingMore) {
                      _loadNextPageInfinite();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _allLoadedSessions.length + (_currentPage < _totalPages - 1 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _allLoadedSessions.length) {
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
                                    ? 'Loading more sessions...'
                                    : 'Loading next page...'),
                              ],
                            ),
                          ),
                        );
                      }

                      final session = _allLoadedSessions[index];
                      final isCurrentSession = session.id == _loggerService.currentSessionId;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCurrentSession ? Colors.green : Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isCurrentSession ? Icons.play_circle : Icons.folder,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    session.id,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                                if (isCurrentSession)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${session.logCount} logs',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Created: ${session.createdAt.formatDateTime()}',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.update, size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Last: ${session.lastActivityAt.formatDateTime()}',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'view':
                                    _viewSessionLogs(session);
                                    break;
                                  case 'download':
                                    _downloadSessionLogs(session);
                                    break;
                                  case 'delete':
                                    if (!isCurrentSession) {
                                      _deleteSession(session);
                                    }
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility, size: 16),
                                      SizedBox(width: 8),
                                      Text('View Logs'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'download',
                                  child: Row(
                                    children: [
                                      Icon(Icons.download, size: 16),
                                      SizedBox(width: 8),
                                      Text('Download'),
                                    ],
                                  ),
                                ),
                                if (!isCurrentSession)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => _viewSessionLogs(session),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
