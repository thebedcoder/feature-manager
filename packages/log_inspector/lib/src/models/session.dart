/// Represents a logging session
class LogSession {
  const LogSession({
    required this.id,
    required this.createdAt,
    required this.lastActivityAt,
    required this.logCount,
  });

  /// Unique identifier for the session
  final String id;

  /// When the session was created
  final DateTime createdAt;

  /// When the last log was added to this session
  final DateTime lastActivityAt;

  /// Number of logs in this session
  final int logCount;

  /// Create a LogSession from a Map (for storage/retrieval)
  factory LogSession.fromMap(Map<String, dynamic> map) {
    return LogSession(
      id: map['id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastActivityAt: DateTime.fromMillisecondsSinceEpoch(map['lastActivityAt'] as int),
      logCount: map['logCount'] as int,
    );
  }

  /// Convert LogSession to a Map (for storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastActivityAt': lastActivityAt.millisecondsSinceEpoch,
      'logCount': logCount,
    };
  }

  /// Create a copy of this session with updated values
  LogSession copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    int? logCount,
  }) {
    return LogSession(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      logCount: logCount ?? this.logCount,
    );
  }

  @override
  String toString() {
    return 'LogSession(id: $id, createdAt: $createdAt, lastActivityAt: $lastActivityAt, logCount: $logCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents a paginated result of sessions
class PaginatedSessions {
  const PaginatedSessions({
    required this.sessions,
    required this.currentPage,
    required this.pageSize,
    required this.totalSessions,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  /// The sessions for the current page
  final List<LogSession> sessions;

  /// The current page number (0-based)
  final int currentPage;

  /// The size of each page
  final int pageSize;

  /// Total number of sessions across all pages
  final int totalSessions;

  /// Total number of pages
  final int totalPages;

  /// Whether there is a next page available
  final bool hasNextPage;

  /// Whether there is a previous page available
  final bool hasPreviousPage;
}
