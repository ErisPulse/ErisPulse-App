// UI 侧运行时控制器。
//
// Android：与 Foreground Service isolate 通信（proot/rootfs 由 FGS 管理）。
// 桌面（Windows/Linux）：直接管理本地实例进程（捆绑 Python），无 FGS。
// 对外暴露统一的环境状态（rootfsReady 等）与实例启停命令。

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../models/enums.dart';
import '../instance_manager.dart';
import 'debug_log.dart';
import 'desktop_runtime.dart';
import 'desktop_sdk.dart';
import 'proot_manager.dart';

class RuntimeController extends ChangeNotifier {
  RuntimeController({required this.instanceManager});

  final InstanceManager instanceManager;
  final FlutterBackgroundService _service = FlutterBackgroundService();

  /// 是否桌面平台（Windows/Linux/macOS）：本地进程管理，无 FGS
  final bool _isDesktop = !Platform.isAndroid && !Platform.isIOS;

  /// 桌面运行时（仅桌面平台）
  DesktopRuntime? _desktop;

  /// 运行时调试日志（proot / 实例进程 启动/退出/输出）
  final DebugLogBuffer debugLog = DebugLogBuffer();

  // 环境状态（Android = rootfs；桌面 = 捆绑 Python + SDK 就绪）
  bool rootfsReady = false;
  bool rootfsStatusLoaded = false;
  double? rootfsProgress;
  String? rootfsMessage;
  String? rootfsError;

  /// 桌面已安装的 ErisPulse 版本（未安装为 null）
  String? sdkInstalledVersion;

  /// 桌面是否正在安装 / 升级 SDK
  bool sdkInstalling = false;

  /// 崩溃自动重启（UI 状态，默认开启）
  bool autoRestart = true;

  final List<StreamSubscription<Map<String, dynamic>?>> _subs = [];

  /// 初始化：Android 订阅 FGS；桌面初始化本地运行时并检查环境
  Future<void> init() async {
    if (_isDesktop) {
      _desktop = DesktopRuntime(onEvent: _handleBackendEvent);
      _desktop!.autoRestart = autoRestart;
      await _refreshEnvironment();
      return;
    }

    _subs
      ..add(_service.on('rootfsProgress').listen(_handleRootfsProgress))
      ..add(_service.on('rootfsReady').listen(_handleRootfsReady))
      ..add(_service.on('instanceStatus').listen(_handleInstanceStatus))
      ..add(_service.on('instanceStates').listen(_handleInstanceStates))
      ..add(_service.on('instanceLog').listen(_handleInstanceLog));

    _service.invoke('getRootfsReady');
    _service.invoke('getState');
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

  /// 桌面：重新检查捆绑 Python 与 SDK 安装情况
  Future<void> _refreshEnvironment() async {
    final python = await DesktopEnv.pythonPath();
    final hasPython = File(python).existsSync();
    final sdkVer = await DesktopSdk.installedVersion();
    sdkInstalledVersion = sdkVer;
    rootfsReady = hasPython && sdkVer != null;
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

  // ── 对外操作 ──────────────────────────────────────────────

  /// 准备环境（Android 下载/解压 rootfs；桌面刷新环境检查）
  void ensureRootfs() {
    if (_isDesktop) {
      unawaited(_refreshEnvironment());
      return;
    }
    _service.invoke('ensureRootfs');
  }

  /// 重新查询环境状态
  void refreshRootfs() {
    if (_isDesktop) {
      unawaited(_refreshEnvironment());
      return;
    }
    _service.invoke('getRootfsReady');
  }

  /// 启动实例
  void startInstance(InstanceData data) {
    if (_isDesktop) {
      _desktop?.startInstance(data);
      return;
    }
    _service.invoke('startInstance', data.toJson());
  }

  /// 停止实例
  void stopInstance(String id) {
    if (_isDesktop) {
      _desktop?.stopInstance(id);
      return;
    }
    _service.invoke('stopInstance', {'id': id});
  }

  /// 重启实例
  void restartInstance(InstanceData data) {
    if (_isDesktop) {
      _desktop?.restartInstance(data);
      return;
    }
    _service.invoke('restartInstance', data.toJson());
  }

  /// 停止全部
  void stopAll() {
    if (_isDesktop) {
      _desktop?.stopAll();
      return;
    }
    _service.invoke('stopAll');
  }

  /// 设置崩溃自动重启
  void setAutoRestart(bool enabled) {
    autoRestart = enabled;
    if (_isDesktop) {
      _desktop?.autoRestart = enabled;
    } else {
      _service.invoke('setAutoRestart', {'enabled': enabled});
    }
    notifyListeners();
  }

  /// 桌面：安装 / 升级 SDK 到指定版本（日志逐行回调）
  Future<void> installSdk(
    String version, {
    required void Function(String line) onLog,
  }) async {
    if (!_isDesktop || sdkInstalling) return;
    sdkInstalling = true;
    notifyListeners();
    try {
      await DesktopSdk.install(version, onLog: onLog);
    } finally {
      sdkInstalling = false;
      await _refreshEnvironment();
    }
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
