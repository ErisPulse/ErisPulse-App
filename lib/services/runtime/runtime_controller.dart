// UI 侧运行时控制器。
//
// Android：与 Foreground Service isolate 通信（proot/rootfs 由 FGS 管理）。
// 桌面（Windows/Linux/macOS）：App 内置平台 Python（python-build-standalone），
// 每个实例使用独立 venv 并 pip 安装 ErisPulse；本地进程由 DesktopRuntime 管理。
// 对外暴露统一的环境状态（rootfsReady 等）与实例启停命令。

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../models/enums.dart';
import '../../models/instance.dart';
import '../instance_manager.dart';
import 'assets.dart';
import 'debug_log.dart';
import 'desktop_runtime.dart';
import 'desktop_sdk.dart';
import 'proot_manager.dart';

class RuntimeController extends ChangeNotifier {
  RuntimeController({required this.instanceManager});

  final InstanceManager instanceManager;

  /// 是否桌面平台：本地进程管理，无 FGS（仅 Android/iOS 使用 FGS）
  final bool _isDesktop = !Platform.isAndroid && !Platform.isIOS;

  /// FGS 服务（仅 Android/iOS 创建；懒初始化）
  FlutterBackgroundService? _service;

  /// 桌面运行时（仅桌面平台）
  DesktopRuntime? _desktop;

  /// 运行时调试日志（proot / 实例进程 启动/退出/输出）
  final DebugLogBuffer debugLog = DebugLogBuffer();

  // 环境状态（Android = rootfs 就绪；桌面 = 内置 Python 就绪）
  bool rootfsReady = false;
  bool rootfsStatusLoaded = false;
  double? rootfsProgress;
  String? rootfsMessage;
  String? rootfsError;

  /// 桌面：内置 Python 版本号（未释放为 null）
  String? bundledPythonVersion;

  /// 桌面：是否正在释放内置 Python
  bool bundledPythonBusy = false;

  /// 桌面：释放/引导进度消息
  String? bundledPythonMessage;

  /// 崩溃自动重启（UI 状态，默认开启）
  bool autoRestart = true;

  final List<StreamSubscription<Map<String, dynamic>?>> _subs = [];

  /// 初始化：Android 订阅 FGS；桌面初始化本地运行时并检查环境
  Future<void> init() async {
    if (_isDesktop) {
      _desktop = DesktopRuntime(onEvent: _handleBackendEvent);
      _desktop!.autoRestart = autoRestart;
      await _refreshBundledPython();
      return;
    }

    _service = FlutterBackgroundService();
    _subs
      ..add(_service!.on('rootfsProgress').listen(_handleRootfsProgress))
      ..add(_service!.on('rootfsReady').listen(_handleRootfsReady))
      ..add(_service!.on('instanceStatus').listen(_handleInstanceStatus))
      ..add(_service!.on('instanceStates').listen(_handleInstanceStates))
      ..add(_service!.on('instanceLog').listen(_handleInstanceLog));

    _invoke('getRootfsReady');
    _invoke('getState');
  }

  /// 桌面后端事件统一入口（DesktopRuntime 回调）
  void _handleBackendEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'instanceStatus':
        _handleInstanceStatus(event);
      case 'instanceLog':
        _handleInstanceLog(event);
    }
  }

  /// 桌面：刷新内置 Python 就绪状态
  Future<void> _refreshBundledPython() async {
    bundledPythonVersion = await DesktopSdk.bundledPythonVersion();
    rootfsReady = bundledPythonVersion != null;
    rootfsStatusLoaded = true;
    notifyListeners();
  }

  void _handleInstanceLog(Map<String, dynamic>? event) {
    if (event == null) return;
    final id = event['id'] as String? ?? '';
    final line = event['line'] as String? ?? '';
    if (line.isEmpty) return;
    debugLog.add(id, line);
  }

  void _handleRootfsProgress(Map<String, dynamic>? event) {
    if (event == null) return;
    if (event['error'] != null) {
      rootfsError = event['error'] as String?;
    } else {
      rootfsProgress = (event['percent'] as num?)?.toDouble();
      rootfsMessage = event['message'] as String?;
    }
    rootfsStatusLoaded = true;
    notifyListeners();
  }

  void _handleRootfsReady(Map<String, dynamic>? event) {
    if (event == null) return;
    rootfsReady = event['ready'] as bool? ?? false;
    rootfsStatusLoaded = true;
    notifyListeners();
  }

  void _handleInstanceStatus(Map<String, dynamic>? event) {
    if (event == null) return;
    _applyInstanceStatus(event);
  }

  void _handleInstanceStates(Map<String, dynamic>? event) {
    if (event == null) return;
    final states = event['states'] as Map<String, dynamic>? ?? {};
    states.forEach((id, state) {
      final s = state as Map<String, dynamic>;
      _applyInstanceStatus({
        'id': id,
        'status': s['status'],
        'pid': s['pid'],
      });
    });
  }

  void _applyInstanceStatus(Map<String, dynamic> event) {
    final id = event['id'] as String?;
    if (id == null) return;
    final inst = instanceManager.findById(id);
    if (inst == null) return;

    final statusName = event['status'] as String?;
    final pid = event['pid'] as int?;
    final error = event['error'] as String?;
    final clearPid = event['clearPid'] as bool? ?? false;
    final clearError = event['clearError'] as bool? ?? false;

    instanceManager.setRuntimeState(
      id,
      status: _mapStatus(statusName),
      pid: pid,
      errorMessage: error,
      clearPid: clearPid,
      clearError: clearError,
    );
  }

  static InstanceStatus? _mapStatus(String? s) {
    return switch (s) {
      'starting' => InstanceStatus.starting,
      'running' => InstanceStatus.running,
      'error' => InstanceStatus.error,
      'stopped' => InstanceStatus.stopped,
      'destroying' => InstanceStatus.destroying,
      _ => null,
    };
  }

  void _invoke(String method, [Map<String, dynamic>? args]) {
    _service?.invoke(method, args);
  }

  // ── 桌面：环境管理 ─────────────────────────────────

  /// 释放内置 Python（含 pip 引导）。日志经回调上报。
  Future<void> ensureBundledPython({void Function(String line)? onLog}) async {
    if (bundledPythonBusy) return;
    bundledPythonBusy = true;
    bundledPythonMessage = null;
    notifyListeners();
    void log(String line) {
      debugLog.add('python', line);
      onLog?.call(line);
      bundledPythonMessage = line;
      notifyListeners();
    }

    try {
      final code = await DesktopSdk.ensureBundledPython(onLog: log);
      if (code != 0) {
        bundledPythonMessage = '内置 Python 释放失败 (exit $code)';
        notifyListeners();
      }
      await _refreshBundledPython();
    } finally {
      bundledPythonBusy = false;
      notifyListeners();
    }
  }

  /// 桌面：实例环境是否就绪（venv 中已装 ErisPulse）
  Future<bool> isInstanceReady(String instanceId) =>
      DesktopSdk.isInstanceReady(instanceId);

  /// 桌面：查询实例 venv 中 ErisPulse 版本
  Future<String?> instanceSdkVersion(String instanceId) =>
      DesktopSdk.installedSdkVersion(instanceId);

  /// 为实例准备独立 venv（fresh 新建 / clone 复制源实例环境）。
  ///
  /// 桌面：内置 Python 建 venv + pip 安装（随装 Dashboard）；移动端经 FGS
  /// 在 rootfs 内执行，结果由 `instanceEnv` 事件异步回填。返回 0 表示成功。
  Future<int> prepareInstanceEnvironment({
    required Instance instance,
    required String mode, // 'fresh' | 'clone'
    String? sourceInstanceId,
    String? sdkVersion,
    String? indexUrl,
    void Function(String line)? onLog,
  }) {
    if (_isDesktop) {
      if (mode == 'clone') {
        return DesktopSdk.cloneInstanceEnv(
          sourceInstanceId: sourceInstanceId!,
          newInstanceId: instance.id,
          onLog: onLog ?? (_) {},
        );
      }
      return DesktopSdk.prepareInstance(
        instanceId: instance.id,
        version: sdkVersion ?? DesktopSdk.kDefaultVersion,
        indexUrl: indexUrl ?? pypiIndexUrl(kPypiSourceOfficial),
        onLog: (l) {
          debugLog.add(instance.id, l);
          onLog?.call(l);
        },
      );
    }

    final src = sourceInstanceId != null
        ? instanceManager.findById(sourceInstanceId)
        : null;
    _invoke('prepareInstance', {
      'data': InstanceData(
        id: instance.id,
        name: instance.name,
        port: instance.port,
        token: instance.token,
        workingDir: instance.workingDir,
      ).toJson(),
      'mode': mode,
      'sdkVersion': sdkVersion,
      'indexUrl': indexUrl,
      'sourceWorkingDir': src?.workingDir,
    });
    return _awaitInstanceEnv(instance.id);
  }

  /// 等待移动端环境准备完成（FGS `instanceEnv` 事件），超时 5 分钟
  Future<int> _awaitInstanceEnv(String instanceId) {
    final completer = Completer<int>();
    StreamSubscription<Map<String, dynamic>?>? sub;
    sub = _service!.on('instanceEnv').listen((e) {
      if (e?['id'] != instanceId) return;
      sub?.cancel();
      final ready = e?['ready'] == true;
      completer.complete(ready ? 0 : 1);
    });
    Timer(const Duration(minutes: 5), () {
      sub?.cancel();
      if (!completer.isCompleted) completer.complete(1);
    });
    return completer.future;
  }

  /// 桌面：删除实例 venv（删除实例时调用）
  Future<void> removeInstanceEnvironment(String instanceId) =>
      DesktopSdk.removeInstanceEnv(instanceId);

  // ── 对外操作 ──────────────────────────────────────

  /// 准备环境（Android 下载/解压 rootfs；桌面释放内置 Python）
  void ensureRootfs() {
    if (_isDesktop) {
      unawaited(ensureBundledPython());
      return;
    }
    _invoke('ensureRootfs');
  }

  /// 重新查询环境状态
  void refreshRootfs() {
    if (_isDesktop) {
      unawaited(_refreshBundledPython());
      return;
    }
    _invoke('getRootfsReady');
  }

  /// 启动实例
  void startInstance(InstanceData data) {
    if (_isDesktop) {
      _desktop?.startInstance(data);
      return;
    }
    _invoke('startInstance', data.toJson());
  }

  /// 停止实例
  void stopInstance(String id) {
    if (_isDesktop) {
      _desktop?.stopInstance(id);
      return;
    }
    _invoke('stopInstance', {'id': id});
  }

  /// 重启实例
  void restartInstance(InstanceData data) {
    if (_isDesktop) {
      _desktop?.restartInstance(data);
      return;
    }
    _invoke('restartInstance', data.toJson());
  }

  /// 停止全部实例（App 退出时调用，桌面终止全部进程）
  Future<void> stopAll() async {
    if (_isDesktop) {
      await _desktop?.stopAll();
      return;
    }
    _invoke('stopAll');
  }

  /// 设置崩溃自动重启
  void setAutoRestart(bool enabled) {
    autoRestart = enabled;
    if (_isDesktop) {
      _desktop?.autoRestart = enabled;
    } else {
      _invoke('setAutoRestart', {'enabled': enabled});
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _desktop?.dispose();
    super.dispose();
  }
}
