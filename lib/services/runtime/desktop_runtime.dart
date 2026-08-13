// 桌面运行时（Windows / Linux）：直接管理 ErisPulse 实例进程。
//
// 与 Android 不同，桌面无 proot / rootfs / 前台服务：
//   - 包体捆绑完整的便携 Python（CI 打包时置于包体 python/ 目录）
//   - 实例直接 `python -c "...sdk.run()"` 启动，工作目录为用户配置区
//   - 实例进程由本类管理，App 退出时随进程终止
//   - ErisPulse SDK 由用户从 PyPI 选择安装（见 desktop_sdk.dart）

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'assets.dart';
import 'proot_manager.dart' show InstanceData, ProcessEvent, ProcessLogEvent;

/// 桌面平台环境工具
class DesktopEnv {
  /// 捆绑 Python 可执行文件路径。
  ///
  /// CI 打包时把便携 Python 放入包体 `python/` 目录：
  ///   Windows: `<exeDir>/python/python.exe`
  ///   Linux:   `<exeDir>/python/bin/python3`
  static Future<String> pythonPath() async {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    if (Platform.isWindows) {
      return '$exeDir\\python\\python.exe';
    }
    return '$exeDir/python/bin/python3';
  }

  /// 用户数据根目录（实例工作目录 / 配置存放处）
  static Future<Directory> dataDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/instances');
    await dir.create(recursive: true);
    return dir;
  }

  /// 单个实例的工作目录（宿主绝对路径）
  static Future<Directory> instanceDir(String id) async {
    final root = await dataDir();
    final dir = Directory('${root.path}/$id');
    await dir.create(recursive: true);
    return dir;
  }
}

/// 桌面实例进程管理器（运行在 UI isolate，随 App 生命周期）
class DesktopRuntime {
  DesktopRuntime({required this.onEvent});

  /// 事件上报（instanceStatus / instanceLog，payload 与 FGS 通道一致）
  final void Function(Map<String, dynamic> event) onEvent;

  /// id → 运行中进程
  final Map<String, _DesktopProc> _procs = {};

  /// 崩溃后自动重启
  bool autoRestart = true;

  /// 是否已停止（避免崩溃退出误报）
  final Set<String> _manuallyStopped = {};

  static const _readyTimeout = Duration(seconds: 90);
  static const _pollInterval = Duration(milliseconds: 1200);
  static const _restartCooldown = Duration(seconds: 3);

  Map<String, Map<String, dynamic>> get statusSnapshot => {
        for (final e in _procs.entries)
          e.key: {
            'status': e.value.status.name,
            'pid': e.value.process.pid,
          },
      };

  /// 启动实例
  Future<bool> startInstance(InstanceData data) async {
    if (_procs.containsKey(data.id)) return true;
    final python = await DesktopEnv.pythonPath();
    if (!File(python).existsSync()) {
      onEvent(
        ProcessEvent(
          id: data.id,
          status: 'error',
          error: '捆绑 Python 缺失，请重新安装',
        ).toJson(),
      );
      return false;
    }

    _manuallyStopped.remove(data.id);

    try {
      // 实例工作目录 + 配置
      final instDir = await DesktopEnv.instanceDir(data.id);
      await _writeConfig(data, instDir);

      final proc = await Process.start(
        python,
        _runArgs(),
        workingDirectory: instDir.path,
      );
      final tracker = _DesktopProc(data, proc);
      _procs[data.id] = tracker;

      unawaited(proc.exitCode.then((code) => _handleExit(tracker, code)));
      onEvent(
        ProcessEvent(id: data.id, status: 'starting', pid: proc.pid).toJson(),
      );
      _streamLines(proc, data.id);
      tracker.status = _RunStatus.starting;
      unawaited(_waitReady(tracker, data));
      return true;
    } catch (e) {
      onEvent(
        ProcessEvent(id: data.id, status: 'error', error: '启动异常: $e').toJson(),
      );
      return false;
    }
  }

  /// 停止实例
  Future<void> stopInstance(String id) async {
    _manuallyStopped.add(id);
    final tracker = _procs.remove(id);
    if (tracker == null) {
      onEvent(
        ProcessEvent(
          id: id,
          status: 'stopped',
          clearPid: true,
          clearError: true,
        ).toJson(),
      );
      return;
    }
    _kill(tracker.process);
    onEvent(
      ProcessEvent(
        id: id,
        status: 'stopped',
        clearPid: true,
        clearError: true,
      ).toJson(),
    );
  }

  /// 重启实例
  Future<bool> restartInstance(InstanceData data) async {
    await stopInstance(data.id);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return startInstance(data);
  }

  /// 停止全部
  Future<void> stopAll() async {
    for (final id in _procs.keys.toList()) {
      await stopInstance(id);
    }
  }

  /// App 退出时调用：终止全部实例进程
  Future<void> dispose() async {
    for (final t in _procs.values.toList()) {
      _kill(t.process);
    }
    _procs.clear();
  }

  List<String> _runArgs() => [
        '-c',
        'import asyncio; from ErisPulse import sdk; asyncio.run(sdk.run())',
      ];

  /// 为实例写入 config.toml（复用 SDK 配置模板）
  Future<void> _writeConfig(InstanceData data, Directory instDir) async {
    final configDir = Directory('${instDir.path}/config');
    await configDir.create(recursive: true);
    final toml = buildInstanceConfigToml(port: data.port, token: data.token);
    await File('${configDir.path}/config.toml')
        .writeAsString(toml, flush: true);
  }

  void _streamLines(Process proc, String id) {
    proc.stdout
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen((line) => onEvent(ProcessLogEvent(id, line).toJson()));
    proc.stderr
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen((line) => onEvent(ProcessLogEvent(id, line).toJson()));
  }

  Future<void> _waitReady(_DesktopProc tracker, InstanceData data) async {
    final deadline = DateTime.now().add(_readyTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (!_procs.containsKey(data.id)) return;
      try {
        final resp = await http
            .get(
              Uri.parse(
                'http://127.0.0.1:${data.port}/Dashboard/api/auth/status',
              ),
            )
            .timeout(_pollInterval);
        if (resp.statusCode == 200 || resp.statusCode == 401) {
          tracker.status = _RunStatus.running;
          onEvent(
            ProcessEvent(
              id: data.id,
              status: 'running',
              pid: tracker.process.pid,
            ).toJson(),
          );
          return;
        }
      } catch (_) {}
      await Future<void>.delayed(_pollInterval);
    }
    if (_procs.containsKey(data.id)) {
      onEvent(
        ProcessEvent(
          id: data.id,
          status: 'running',
          pid: tracker.process.pid,
          error: 'Dashboard 就绪超时，但进程仍在运行',
        ).toJson(),
      );
    }
  }

  void _handleExit(_DesktopProc tracker, int code) {
    final id = tracker.data.id;
    final wasRunning = _procs.remove(id) != null;
    if (!wasRunning) return;
    if (_manuallyStopped.contains(id)) return;

    onEvent(
      ProcessEvent(
        id: id,
        status: 'error',
        error: '进程退出 (code=$code)',
        clearPid: true,
      ).toJson(),
    );

    if (autoRestart) {
      unawaited(_restartAfterExit(tracker));
    }
  }

  Future<void> _restartAfterExit(_DesktopProc tracker) async {
    await Future<void>.delayed(_restartCooldown);
    if (_manuallyStopped.contains(tracker.data.id)) return;
    await startInstance(tracker.data);
  }

  void _kill(Process p) {
    try {
      p.kill(ProcessSignal.sigterm);
      Timer(const Duration(seconds: 2), () {
        try {
          p.kill(ProcessSignal.sigkill);
        } catch (_) {}
      });
    } catch (_) {}
  }
}

enum _RunStatus { starting, running }

class _DesktopProc {
  final InstanceData data;
  final Process process;
  _RunStatus status;

  _DesktopProc(this.data, this.process) : status = _RunStatus.starting;
}
