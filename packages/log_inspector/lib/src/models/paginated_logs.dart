class PaginatedLogs {
  const PaginatedLogs({
    required this.logs,
    required this.currentPage,
    required this.pageSize,
    required this.totalLogs,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  /// The logs for the current page
  final List<String> logs;

  /// The current page number (0-based)
  final int currentPage;

  /// The size of each page
  final int pageSize;

  /// Total number of logs across all pages
  final int totalLogs;

  /// Total number of pages
  final int totalPages;

  /// Whether there is a next page available
  final bool hasNextPage;

  /// Whether there is a previous page available
  final bool hasPreviousPage;
}
