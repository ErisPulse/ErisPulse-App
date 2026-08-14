/// Dashboard 日志条目 DTO。
///
/// 对应 Dashboard 后端 deque 中的日志记录，或 `/api/logs` 响应。
library;

/// 日志级别（与 Python logging 对齐，含 SDK 自定义级别）。
///
/// 数值与后端 `_resolve_level` / `level_num` 一致：
/// TRACE=5 / DEBUG=10 / INFO=20 / EVENT=21 / WARNING=30 / ERROR=40 / CRITICAL=50。
enum LogLevel {
  trace(5, 'TRACE'),
  debug(10, 'DEBUG'),
  info(20, 'INFO'),
  event(21, 'EVENT'),
  warning(30, 'WARNING'),
  error(40, 'ERROR'),
  critical(50, 'CRITICAL');

  /// Python logging levelno
  final int num;

  /// 等级名（英文代码值，与后端/前端一致，不参与翻译）
  final String label;

  const LogLevel(this.num, this.label);

  static LogLevel fromString(String s) {
    final up = s.trim().toUpperCase();
    for (final v in values) {
      if (v.label == up) return v;
    }
    return switch (up) {
      'WARN' => LogLevel.warning,
      'ERR' => LogLevel.error,
      'FATAL' => LogLevel.critical,
      _ => LogLevel.info,
    };
  }

  /// 从 Python logging levelno 数字映射（含自定义 TRACE=5 / EVENT=21）
  static LogLevel fromLevelNum(int n) {
    if (n <= 5) return LogLevel.trace;
    if (n < 20) return LogLevel.debug;
    if (n < 21) return LogLevel.info;
    if (n < 30) return LogLevel.event;
    if (n < 40) return LogLevel.warning;
    if (n < 50) return LogLevel.error;
    return LogLevel.critical;
  }

  /// 是否 >= 此级别（按 levelno 数值比较，与后端过滤语义一致）
  bool operator >=(LogLevel other) => num >= other.num;
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;

  /// 原始 levelno（后端推送的 level_num，保留用于调试/展示）
  final int levelNum;
  final String logger;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    this.levelNum = 0,
    required this.logger,
    required this.message,
  });

  /// 从 Dashboard WS 推送 / `/api/logs` 的日志 JSON 解析。
  ///
  /// 后端字段为 `module`（记录器名）；兼容 `logger` 旧字段。
  /// `level` 可能缺失（旧格式），用 `level_num`（Python levelno）兜底。
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    final levelStr = json['level'] as String?;
    final levelNum = json['level_num'];
    final numValue = levelNum is num ? levelNum.toInt() : 0;
    return LogEntry(
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      level: (levelStr != null && levelStr.isNotEmpty)
          ? LogLevel.fromString(levelStr)
          : LogLevel.fromLevelNum(numValue),
      levelNum: numValue,
      logger: (json['logger'] as String? ?? json['module'] as String?) ?? '',
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
