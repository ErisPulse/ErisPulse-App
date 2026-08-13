/// Dashboard 日志条目 DTO。
///
/// 对应 Dashboard 后端 deque 中的日志记录，或 `/api/logs` 响应。
library;

/// 日志级别（与 Python logging 标准对齐）
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical;

  static LogLevel fromString(String s) {
    return switch (s.toLowerCase()) {
      'debug' => LogLevel.debug,
      'info' => LogLevel.info,
      'warn' || 'warning' => LogLevel.warning,
      'error' || 'err' => LogLevel.error,
      'critical' || 'fatal' => LogLevel.critical,
      _ => LogLevel.info,
    };
  }

  /// 是否 >= 此级别（用于过滤）
  bool operator >=(LogLevel other) => index >= other.index;
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String logger;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.logger,
    required this.message,
  });

  /// 从 Dashboard WS 推送的 log JSON 解析
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      level: LogLevel.fromString(json['level'] as String? ?? 'INFO'),
      logger: json['logger'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  /// 从 `/api/logs` 响应（可能是数组形式）解析
  static List<LogEntry> fromList(List<dynamic> list) {
    return list
        .map((e) => e is Map<String, dynamic> ? LogEntry.fromJson(e) : null)
        .whereType<LogEntry>()
        .toList();
  }
}
