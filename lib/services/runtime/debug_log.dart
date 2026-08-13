import 'package:flutter/foundation.dart';

class DebugLogEntry {
  final DateTime time;
  final String instanceId;
  final String line;
  DebugLogEntry(this.time, this.instanceId, this.line);
}

/// 运行时调试日志缓冲（proot 启动/退出关键信息 + stdout/stderr）。
///
/// 由 RuntimeController 接收 FGS 的 instanceLog 事件填充，DebugPage 展示。
class DebugLogBuffer extends ChangeNotifier {
  final List<DebugLogEntry> _entries = [];
  static const int _max = 3000;

  List<DebugLogEntry> get entries => List.unmodifiable(_entries);

  void add(String instanceId, String line) {
    _entries.add(DebugLogEntry(DateTime.now(), instanceId, line));
    while (_entries.length > _max) {
      _entries.removeAt(0);
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
