import 'package:flutter/foundation.dart';

class DebugLogEntry {
  final DateTime time;
  final String instanceId;
  final String line;
  DebugLogEntry(this.time, this.instanceId, this.line);
}

/// 运行时调试日志缓冲（进程启动/退出关键信息 + stdout/stderr）。
///
/// 按实例分缓冲：每个实例独立上限，多实例同时刷屏时互不挤占，
/// 避免"日志显示不全"。由 RuntimeController 接收 instanceLog 事件填充。
class DebugLogBuffer extends ChangeNotifier {
  /// instanceId → 该实例的日志
  final Map<String, List<DebugLogEntry>> _byInstance = {};
  static const int _max = 3000;

  /// 合并全部实例的日志（按时间排序）
  List<DebugLogEntry> get entries {
    final all = <DebugLogEntry>[];
    for (final list in _byInstance.values) {
      all.addAll(list);
    }
    all.sort((a, b) => a.time.compareTo(b.time));
    return all;
  }

  int get count => _byInstance.values.fold(0, (sum, list) => sum + list.length);

  void add(String instanceId, String line) {
    final list = _byInstance.putIfAbsent(instanceId, () => []);
    list.add(DebugLogEntry(DateTime.now(), instanceId, line));
    while (list.length > _max) {
      list.removeAt(0);
    }
    notifyListeners();
  }

  void clear() {
    _byInstance.clear();
    notifyListeners();
  }

  /// 清除指定实例的缓冲（日志页加载历史前调用，避免重复）
  void clearFor(String instanceId) {
    _byInstance.remove(instanceId);
    notifyListeners();
  }
}
