// 桌面运行时（Windows / Linux / macOS）：直接管理 ErisPulse 实例进程。
//
// App 构建时内置对应平台 Python（python-build-standalone），实例通过
// 内置 Python 创建独立虚拟环境（~/.erispulse/instances/{id}/.venv）并
// pip 安装 ErisPulse；启动时使用该 venv 的 python，VIRTUAL_ENV 指向
// 实例 venv，保证后端包管理（uv）命中本实例环境。

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'assets.dart';
import 'proot_manager.dart' show InstanceData, ProcessEvent, ProcessLogEvent;

/// 桌面平台环境工具
class DesktopEnv {
  /// 用户主目录（Windows: %USERPROFILE%；Unix: $HOME）
  static Directory homeDir() {
    final env = Platform.environment;
    final home = Platform.isWindows ? env['USERPROFILE'] : env['HOME'];
    return Directory(home ?? Directory.current.path);
  }

  /// ErisPulse 用户数据根目录（~/.erispulse）
  static Future<Directory> erispulseDir() async {
    final d = Directory('${homeDir().path}/.erispulse');
    await d.create(recursive: true);
    return d;
  }

  /// 实例工作目录根（~/.erispulse/instances）
  static Future<Directory> dataDir() async {
    final d = Directory('${(await erispulseDir()).path}/instances');
    await d.create(recursive: true);
    return d;
  }

  /// 单个实例的工作目录（宿主绝对路径）
  static Future<Directory> instanceDir(String id) async {
    final d = Directory('${(await dataDir()).path}/$id');
    await d.create(recursive: true);
    return d;
  }

  /// 实例日志文件（进程输出落盘）
  static Future<File> instanceLogFile(String id) async {
    final dir = await instanceDir(id);
    return File('${dir.path}/logs/erispulse.log');
  }

  /// 内置 Python 释放目录（~/.erispulse/python）
  static Future<Directory> bundledPythonDir() async {
    final d = Directory('${(await erispulseDir()).path}/python');
    await d.create(recursive: true);
    return d;
  }

  /// 内置 Python 可执行文件路径。
  ///
  /// python-build-standalone 结构：Windows 顶层 `python.exe`，
  /// Unix 为 `bin/python3`。
  static Future<String> bundledPythonPath() async {
    final base = (await bundledPythonDir()).path;
    if (Platform.isWindows) return '$base\\python.exe';
    return '$base/bin/python3';
  }

  /// 实例虚拟环境目录（~/.erispulse/instances/{id}/.venv）。
  /// 不预创建，由 `python -m venv` 创建。
  static Future<Directory> instanceVenvDir(String id) async {
    return Directory('${(await instanceDir(id)).path}/.venv');
  }

  /// 实例 venv 的 Python 可执行文件路径。
  ///
  /// Windows 为 `.venv/Scripts/python.exe`，Unix 为 `.venv/bin/python`。
  static Future<String> instanceVenvPython(String id) async {
    final base = (await instanceVenvDir(id)).path;
    if (Platform.isWindows) return '$base\\Scripts\\python.exe';
    return '$base/bin/python';
  }

  /// 当前平台-架构标识（内置 Python 资产命名：windows/linux/macos × x64/arm64）
  static String hostPlatformArch() {
    final os =
        Platform.isWindows ? 'windows' : (Platform.isMacOS ? 'macos' : 'linux');
    return '$os-${_hostArchSuffix()}';
  }

  /// 主机架构后缀（x64 / arm64）。dart:io Platform 无 arch 属性，
  /// 从系统查询：Windows 用 PROCESSOR_ARCHITECTURE，Unix 用 uname -m。
  static String _hostArchSuffix() {
    String raw;
    if (Platform.isWindows) {
      raw = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'AMD64';
    } else {
      try {
        final r = Process.runSync('uname', ['-m']);
        raw = (r.exitCode == 0 ? r.stdout.toString() : '').trim();
      } catch (_) {
        raw = '';
      }
    }
    final lower = raw.toLowerCase();
    return (lower.contains('aarch64') || lower.contains('arm64'))
        ? 'arm64'
        : 'x64';
  }
}

/// 桌面实例进程管理器（运行在 UI isolate，随 App 生命周期）
class DesktopRuntime {
  DesktopRuntime({required this.onEvent});

  /// 事件上报（instanceStatus / instanceLog，payload 与 FGS 通道一致）
  final void Function(Map<String, dynamic> event) onEvent;

  /// id → 运行中进程
  final Map<String, _DesktopProc> _procs = {};

  /// id → 实例日志文件（追加写入，进程输出落盘）
  final Map<String, IOSink> _logFiles = {};

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
    // 每个实例使用自己的虚拟环境（创建实例时通过 pip 安装 ErisPulse）
    final python = await DesktopEnv.instanceVenvPython(data.id);
    if (!File(python).existsSync()) {
      onEvent(
        ProcessEvent(
          id: data.id,
          status: 'error',
          error: '实例环境未就绪，请先创建实例（安装 ErisPulse）',
        ).toJson(),
      );
      return false;
    }

    _manuallyStopped.remove(data.id);

    try {
      // 实例工作目录 + 配置
      final instDir = await DesktopEnv.instanceDir(data.id);
      await _writeConfig(data, instDir);
      await _openLogFile(data.id, instDir);
      final venvDir = await DesktopEnv.instanceVenvDir(data.id);

      final proc = await Process.start(
        python,
        _runArgs(),
        workingDirectory: instDir.path,
        environment: {
          // 让后端 PackageManager 的 uv 命中本实例 venv，装包不会回落系统环境
          'VIRTUAL_ENV': venvDir.path,
        },
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
    await _kill(tracker.process);
    await _closeLogFile(id);
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
      await _kill(t.process);
    }
    _procs.clear();
    for (final s in _logFiles.values) {
      unawaited(s.close());
    }
    _logFiles.clear();
  }

  List<String> _runArgs() => [
        '-c',
        'import asyncio; from ErisPulse import sdk; asyncio.run(sdk.run())',
      ];

  /// 打开实例日志文件（追加写入，进程输出落盘）
  Future<void> _openLogFile(String id, Directory instDir) async {
    final logsDir = Directory('${instDir.path}/logs');
    await logsDir.create(recursive: true);
    final sink =
        File('${logsDir.path}/erispulse.log').openWrite(mode: FileMode.append);
    _logFiles[id] = sink;
  }

  Future<void> _closeLogFile(String id) async {
    final sink = _logFiles.remove(id);
    if (sink == null) return;
    try {
      await sink.close();
    } catch (_) {}
  }

  /// 为实例写入 config.toml（复用 SDK 配置模板）
  Future<void> _writeConfig(InstanceData data, Directory instDir) async {
    final configDir = Directory('${instDir.path}/config');
    await configDir.create(recursive: true);
    final toml = buildInstanceConfigToml(port: data.port, token: data.token);
    await File('${configDir.path}/config.toml')
        .writeAsString(toml, flush: true);
  }

  void _streamLines(Process proc, String id) {
    void onLine(String line) {
      onEvent(ProcessLogEvent(id, line).toJson());
      _logFiles[id]?.writeln(line);
    }

    proc.stdout
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(onLine);
    proc.stderr
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(onLine);
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

  /// 终止进程树：Windows 用 taskkill /F /T（连子进程一起清，避免端口残留
  /// 导致"停止无效"）；POSIX 先 SIGTERM 再 SIGKILL 兜底。
  Future<void> _kill(Process p) async {
    try {
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/F', '/T', '/PID', '${p.pid}']);
        return;
      }
      p.kill(ProcessSignal.sigterm);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      p.kill(ProcessSignal.sigkill);
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
