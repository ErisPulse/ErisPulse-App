// 统一编排：跨实例批量操作（启停 / 升级包 / 框架更新），并发受限执行。

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/instance.dart';
import 'dashboard_api.dart';
import 'runtime/proot_manager.dart';
import 'runtime/runtime_controller.dart';

/// 批量操作类型
enum BatchOp { start, stop, restart, upgradePackages, updateFramework }

/// 单实例执行结果
class BatchItemResult {
  const BatchItemResult({
    required this.instance,
    required this.ok,
    this.message,
  });

  final Instance instance;
  final bool ok;
  final String? message;

  String get errorText => message ?? '';
}

/// 批量任务（进度可监听）
class BatchTask extends ChangeNotifier {
  BatchTask(this.op, this.instances);

  final BatchOp op;
  final List<Instance> instances;

  final Queue<Instance> _pending = Queue.of([]);
  final List<BatchItemResult> _done = [];
  int _total = 0;
  bool _running = false;
  bool _cancelled = false;

  int get total => _total;
  int get finished => _done.length;
  bool get running => _running;
  bool get cancelled => _cancelled;
  List<BatchItemResult> get results => List.unmodifiable(_done);
  bool get allDone => _done.length >= _total;

  static const int _concurrency = 3;

  /// 执行并等待完成
  Future<List<BatchItemResult>> run({
    RuntimeController? runtime,
    int concurrency = _concurrency,
  }) async {
    if (_running) return const [];
    _running = true;
    _cancelled = false;
    _done.clear();
    _total = instances.length;
    _pending
      ..clear()
      ..addAll(instances);
    notifyListeners();

    Future<void> worker() async {
      while (_pending.isNotEmpty && !_cancelled) {
        final inst = _pending.removeFirst();
        final res = await _runOne(inst, runtime);
        _done.add(res);
        notifyListeners();
      }
    }

    await Future.wait([
      for (var i = 0; i < concurrency.clamp(1, 8); i++) worker(),
    ]);
    _running = false;
    notifyListeners();
    return results;
  }

  void cancel() {
    _cancelled = true;
    notifyListeners();
  }

  Future<BatchItemResult> _runOne(
    Instance inst,
    RuntimeController? runtime,
  ) async {
    try {
      switch (op) {
        case BatchOp.start:
        case BatchOp.stop:
        case BatchOp.restart:
          if (inst.isRemote) {
            return BatchItemResult(
              instance: inst,
              ok: false,
              message: '远程实例跳过',
            );
          }
          if (runtime == null) {
            return BatchItemResult(
              instance: inst,
              ok: false,
              message: '运行时不可用',
            );
          }
          final data = InstanceData(
            id: inst.id,
            name: inst.name,
            port: inst.port,
            token: inst.token,
            workingDir: inst.workingDir,
            runtimeVersion: inst.runtimeVersion,
          );
          switch (op) {
            case BatchOp.start:
              runtime.startInstance(data);
            case BatchOp.stop:
              await runtime.stopInstanceAndWait(inst.id);
            case BatchOp.restart:
              runtime.restartInstance(data);
            case BatchOp.upgradePackages || BatchOp.updateFramework:
              break;
          }
          return BatchItemResult(instance: inst, ok: true);
        case BatchOp.upgradePackages:
          final api = DashboardApi(inst);
          final updates = await api.getPackageUpdates();
          final names = [
            for (final p in updates)
              if (p['name'] != null) p['name'].toString(),
          ];
          if (names.isEmpty) {
            return BatchItemResult(instance: inst, ok: true, message: '无可用更新');
          }
          final taskId = await api.upgradePackages(names);
          if (taskId.isEmpty) {
            return BatchItemResult(
              instance: inst,
              ok: false,
              message: '升级任务未创建',
            );
          }
          final ok = await _pollTask(api, taskId);
          if (!ok) {
            return BatchItemResult(
              instance: inst,
              ok: false,
              message: '${names.length} 个包升级失败',
            );
          }
          return BatchItemResult(
            instance: inst,
            ok: true,
            message: '已升级 ${names.length} 个包',
          );
        case BatchOp.updateFramework:
          final api = DashboardApi(inst);
          await api.updateFramework();
          return BatchItemResult(instance: inst, ok: true);
      }
    } catch (e) {
      return BatchItemResult(instance: inst, ok: false, message: '$e');
    }
  }

  /// 轮询异步任务直至完成（最长 3 分钟）
  Future<bool> _pollTask(DashboardApi api, String taskId) async {
    for (var i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        final st = await api.getInstallStatus(taskId);
        final status = st['status']?.toString();
        if (status == 'success') return true;
        if (status == 'error' || status == 'timeout') return false;
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}
