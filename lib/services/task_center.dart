// 全局任务中心：登记实例端后台任务（安装/升级/卸载/框架更新），
// 供任意页面查看进度与输出，关闭对话框后任务不丢。
//
// 任务由实例端托管（pip 子进程），本中心只做本地登记与轮询展示。

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/instance.dart';
import 'dashboard_api.dart';

/// 单条任务
class AppTask {
  AppTask({
    required this.id,
    required this.instanceId,
    required this.label,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String instanceId;
  final String label;
  String status; // running / success / error / timeout
  final DateTime createdAt;
  List<String> output = const [];
  String? message;

  bool get active => status == 'running';
}

/// 全局任务中心（应用级单例）
class TaskCenter extends ChangeNotifier {
  TaskCenter._();

  static final TaskCenter instance = TaskCenter._();

  final List<AppTask> _tasks = [];

  /// 最近任务在前
  List<AppTask> get tasks => List.unmodifiable(_tasks.reversed);

  int get activeCount => _tasks.where((t) => t.active).length;

  /// 登记并开始轮询实例端任务状态
  AppTask track({
    required Instance instance,
    required String taskId,
    required String label,
  }) {
    final existing = _tasks.where((t) => t.id == taskId).firstOrNull;
    if (existing != null) return existing;
    final task = AppTask(
      id: taskId,
      instanceId: instance.id,
      label: label,
      status: 'running',
      createdAt: DateTime.now(),
    );
    _tasks.add(task);
    notifyListeners();
    unawaited(_poll(instance, task));
    return task;
  }

  Future<void> _poll(Instance instance, AppTask task) async {
    final api = DashboardApi(instance);
    for (var i = 0; i < 200; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      try {
        final st = await api.getInstallStatus(task.id);
        final status = st['status']?.toString() ?? 'running';
        final output = st['output'];
        task
          ..status = status
          ..output = output is List
              ? [for (final l in output) l.toString()]
              : task.output
          ..message = st['message']?.toString();
        notifyListeners();
        if (status != 'running') return;
      } catch (e) {
        task
          ..status = 'error'
          ..message = '$e';
        notifyListeners();
        return;
      }
    }
    task
      ..status = 'timeout'
      ..message = 'polling timed out';
    notifyListeners();
  }

  void clearFinished() {
    _tasks.removeWhere((t) => !t.active);
    notifyListeners();
  }

  void remove(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
