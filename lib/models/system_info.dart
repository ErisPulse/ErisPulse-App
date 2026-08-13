/// Dashboard `/api/system` 响应 DTO。
///
/// 后端实际返回结构：
/// ```json
/// {
///   "uptime_seconds": 3600, "uptime_human": "1h 0m 0s",
///   "pid": 1234,
///   "memory": {"rss_mb": 120, "cpu_percent": 2.1,
///              "system_percent": 34.5, "system_total_gb": 8.0,
///              "system_available_gb": 5.2, "system_cpu_percent": 12.0},
///   "process": {"threads": 8, "open_files": 40, ...},
///   "total_events": 100
/// }
/// ```
library;

import 'dart:math' show max;

/// 系统资源占用（采样快照）
class SystemInfo {
  /// 进程 CPU 占用百分比（0-100）
  final double cpuPercent;

  /// 进程常驻内存（MB）
  final double memoryMb;

  /// 系统内存占用百分比（0-100）
  final double memoryPercent;

  /// CPU 核心数（后端未提供时默认 1）
  final int cpuCount;

  /// 运行时长
  final Duration uptime;

  /// 后端直接给出的可读运行时长（如 `1h 2m 3s`），可能为空
  final String? uptimeHuman;

  final int? pid;

  final int? threadCount;

  SystemInfo({
    required this.cpuPercent,
    required this.memoryMb,
    required this.memoryPercent,
    required this.cpuCount,
    required this.uptime,
    this.uptimeHuman,
    this.pid,
    this.threadCount,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    final memory =
        (json['memory'] as Map?)?.cast<String, dynamic>() ?? const {};
    final process =
        (json['process'] as Map?)?.cast<String, dynamic>() ?? const {};
    final cpuPercent = (memory['cpu_percent'] as num?)?.toDouble() ??
        (memory['system_cpu_percent'] as num?)?.toDouble() ??
        0;
    final memUsedMb = (memory['rss_mb'] as num?)?.toDouble() ?? 0;
    final memPercent = (memory['system_percent'] as num?)?.toDouble() ?? 0;
    final uptimeSec = (json['uptime_seconds'] as num?)?.toInt() ??
        (json['uptime'] as num?)?.toInt() ??
        0;
    return SystemInfo(
      cpuPercent: cpuPercent.clamp(0, 100).toDouble(),
      memoryMb: memUsedMb.clamp(0, double.infinity).toDouble(),
      memoryPercent: memPercent.clamp(0, 100).toDouble(),
      cpuCount: (json['cpu_count'] as num?)?.toInt() ?? 1,
      uptime: Duration(seconds: uptimeSec),
      uptimeHuman: json['uptime_human'] as String?,
      pid: json['pid'] as int?,
      threadCount: process['threads'] as int?,
    );
  }

  /// 内存占用的人类可读字符串
  String get memoryReadable {
    final mb = memoryMb;
    if (mb < 1) return '${(mb * 1024).toStringAsFixed(0)} KB';
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  /// 运行时长的人类可读字符串（优先后端提供的格式化串）
  String get uptimeReadable {
    final human = uptimeHuman;
    if (human != null && human.isNotEmpty) return human;
    final d = uptime;
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    if (d.inHours < 24) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inDays}d ${d.inHours % 24}h';
  }

  /// 0-100 整数百分比值（用于进度条）
  int get cpuPercentInt => max(0, cpuPercent.round()).clamp(0, 100);
  int get memoryPercentInt => max(0, memoryPercent.round()).clamp(0, 100);

  @override
  String toString() =>
      'SystemInfo(cpu=$cpuPercentInt%, mem=$memoryReadable, up=$uptimeReadable)';
}
