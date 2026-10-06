import 'package:flutter/material.dart';
import 'package:log_inspector/src/services/logger_service/logger_service.dart';
import 'package:log_inspector/src/services/logger_service/logger_service_impl.dart';
import 'package:log_inspector/src/models/session.dart';
import 'package:log_inspector/src/presentation/detailed_logs_screen.dart';
import 'package:log_inspector/src/presentation/widgets/log_session_tile.dart';
import 'package:log_inspector/src/utils/extensions/date_time_extension.dart';

class LogInspectorScreen extends StatefulWidget {
  const LogInspectorScreen({super.key, this.loggerService});

  final LoggerService? loggerService;

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
    _loggerService = widget.loggerService ?? LoggerServiceImpl();
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

  Future<void> _deleteSession(LogSession session, BuildContext dialogContext) async {
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Session'),
            content: Text(
              'Are you sure you want to delete this session and all its logs?\n\n'
              'Session: ${session.id}\n'
              'Created: ${session.createdAt.formatDateTime()}\n'
              'Entries: ${session.logCount}',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Session deleted successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting session: ${e.toString()}')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Session logs download triggered.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
        builder:
            (context) => DetailedLogsScreen(sessionId: session.id, loggerService: _loggerService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentTheme = Theme.of(context);
    final colors = ColorScheme.fromSeed(
      seedColor: parentTheme.colorScheme.primary,
      surface: Colors.white,
    );
    final theme = ThemeData.from(
      colorScheme: colors,
      textTheme: parentTheme.textTheme.apply(
        bodyColor: colors.onSurface,
        displayColor: colors.onSurface,
      ),
      useMaterial3: parentTheme.useMaterial3,
    );

    return Theme(
      data: theme,
      child: Builder(
        builder:
            (context) => Scaffold(
              backgroundColor: colors.surface,
              appBar: AppBar(
                backgroundColor: colors.surface,
                surfaceTintColor: colors.surface,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: const Text('Log Inspector'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isLoading ? null : _loadSessionsInfo,
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
                ),
              ),
              body: SafeArea(
                top: false,
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _allLoadedSessions.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('No sessions yet', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(
                                'New logging sessions will appear here.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                        : _buildSessionList(context),
              ),
            ),
      ),
    );
  }

  Widget _buildSessionList(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
            _currentPage < _totalPages - 1 &&
            !_isLoading &&
            !_isLoadingMore) {
          _loadNextPageInfinite();
        }
        return false;
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _allLoadedSessions.length + (_currentPage < _totalPages - 1 ? 1 : 0),
        separatorBuilder:
            (context, index) => Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
        itemBuilder: (context, index) {
          if (index >= _allLoadedSessions.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child:
                    _isLoadingMore
                        ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : TextButton(
                          onPressed: _loadNextPageInfinite,
                          child: const Text('Load more'),
                        ),
              ),
            );
          }

          final session = _allLoadedSessions[index];
          final isCurrentSession = session.id == _loggerService.currentSessionId;
          return LogSessionTile(
            session: session,
            isCurrentSession: isCurrentSession,
            onView: () => _viewSessionLogs(session),
            onDownload: () => _downloadSessionLogs(session),
            onDelete: isCurrentSession ? null : () => _deleteSession(session, context),
          );
        },
      ),
    );
  }
}
