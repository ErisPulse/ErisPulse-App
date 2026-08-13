// proot 进程管理器（运行在 Foreground Service isolate）。
// 负责实例启停、健康轮询与崩溃监督，状态通过 onEvent 上报。

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'assets.dart';

/// 跨 isolate 传递的实例快照（UI 侧从 Instance 构造）
class InstanceData {
  final String id;
  final String name;
  final int port;
  final String token;
  final String workingDir;

  /// 桌面端：实例 venv 中安装的 ErisPulse SDK 版本（仅记录；启动使用
  /// 实例自己的 venv）。Android 端忽略（共用 rootfs）。
  final String? runtimeVersion;

  InstanceData({
    required this.id,
    required this.name,
    required this.port,
    required this.token,
    required this.workingDir,
    this.runtimeVersion,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'port': port,
        'token': token,
        'workingDir': workingDir,
        if (runtimeVersion != null) 'runtimeVersion': runtimeVersion,
      };

  factory InstanceData.fromJson(Map<String, dynamic> json) => InstanceData(
        id: json['id'] as String,
        name: json['name'] as String,
        port: (json['port'] as num).toInt(),
        token: json['token'] as String,
        workingDir: json['workingDir'] as String,
        runtimeVersion: json['runtimeVersion'] as String?,
      );
}

/// 实例运行状态（与 models/enums 的 InstanceStatus 对应，避免跨文件耦合）
enum _RunStatus { starting, running }

/// 状态事件：id → {status, pid, error}
class ProcessEvent {
  final String id;
  final String status; // InstanceStatus.name
  final int? pid;
  final String? error;
  final bool clearError;
  final bool clearPid;

  ProcessEvent({
    required this.id,
    required this.status,
    this.pid,
    this.error,
    this.clearError = false,
    this.clearPid = false,
  });

  Map<String, dynamic> toJson() => {
        'type': 'instanceStatus',
        'id': id,
        'status': status,
        if (pid != null) 'pid': pid,
        if (error != null) 'error': error,
        'clearError': clearError,
        'clearPid': clearPid,
      };
}

/// 进程日志事件
class ProcessLogEvent {
  final String id;
  final String line;
  ProcessLogEvent(this.id, this.line);

  Map<String, dynamic> toJson() =>
      {'type': 'instanceLog', 'id': id, 'line': line};
}

class ProotManager {
  ProotManager({
    required Directory appDir,
    required String nativeLibDir,
    required this.onEvent,
  })  : _rootfsDir = Directory('${appDir.path}/rootfs'),
        _nativeLibDir = nativeLibDir;

  final Directory _rootfsDir;
  final String _nativeLibDir;
  final void Function(Map<String, dynamic> event) onEvent;

  /// id → 运行中进程
  final Map<String, _InstanceProcess> _procs = {};

  /// 启动健康检测超时
  static const _readyTimeout = Duration(seconds: 90);

  /// 健康轮询间隔
  static const _pollInterval = Duration(milliseconds: 1200);

  /// 是否已停止（避免崩溃退出误报）
  final Set<String> _manuallyStopped = {};

  /// 崩溃后自动重启
  bool autoRestart = true;

  /// 重启冷却
  static const _restartCooldown = Duration(seconds: 3);

  /// 当前全部运行状态快照（供 UI 查询）
  Map<String, Map<String, dynamic>> get statusSnapshot {
    return {
      for (final e in _procs.entries)
        e.key: {
          'status': e.value.status.name,
          'pid': e.value.process.pid,
        },
    };
  }

  // proot 以 native lib 打包（jniLibs/libproot.so），系统提取到 native lib 目录。
  // 只有该目录（apk_data_file）允许 untrusted_app 执行（execute_no_trans）。
  File get _prootPath => File('$_nativeLibDir/libproot.so');

  bool get isRootfsReady =>
      File('${_rootfsDir.path}/usr/bin/python3').existsSync();

  /// 启动实例
  Future<bool> startInstance(InstanceData data) async {
    if (_procs.containsKey(data.id)) return true; // 已在运行
    if (!isRootfsReady) {
      onEvent(
        ProcessEvent(
          id: data.id,
          status: 'error',
          error: 'rootfs 未就绪，请先完成初始化',
        ).toJson(),
      );
      return false;
    }

    _manuallyStopped.remove(data.id);

    try {
      await _writeConfig(data);

      final proc = await _spawnProot(data);
      final tracker = _InstanceProcess(data, proc);
      _procs[data.id] = tracker;

      // 挂进程退出处理
      unawaited(proc.exitCode.then((code) => _handleExit(tracker, code)));

      // 立即上报启动中
      onEvent(
        ProcessEvent(
          id: data.id,
          status: 'starting',
          pid: proc.pid,
        ).toJson(),
      );

      // 转发 stdout/stderr 到 UI 日志
      _streamLines(proc, data.id);

      // 等待就绪
      tracker.status = _RunStatus.starting;
      unawaited(_waitReady(tracker, data));

      return true;
    } catch (e) {
      onEvent(
        ProcessEvent(
          id: data.id,
          status: 'error',
          error: '启动异常: $e',
        ).toJson(),
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

  /// 为实例写入 config.toml
  Future<void> _writeConfig(InstanceData data) async {
    final instDir = Directory('${_rootfsDir.path}/${data.workingDir}');
    final configDir = Directory('${instDir.path}/config');
    await configDir.create(recursive: true);

    final toml = buildInstanceConfigToml(
      port: data.port,
      token: data.token,
    );
    await File('${configDir.path}/config.toml')
        .writeAsString(toml, flush: true);
  }

  /// 建立 termux proot 的动态库符号链接目录。
  ///
  /// termux proot 为动态链接构建，依赖 libtalloc.so.2 与 libandroid-shmem.so，
  /// 以及 loader。二者以 jniLibs native lib 打包（liblibtalloc.so.2.so /
  /// libandroid-shmem.so），native lib 目录只读，无法直接放 libtalloc.so.2，
  /// 因此在 app 私有目录建软链接指向 native lib（SELinux 跟随 symlink 使用
  /// 目标 context，可正常读取/执行）。
  ///
  /// 注意：APK 升级（`-r`）后 native lib 目录路径会变化，旧链接会失效，
  /// 因此每次启动都删除并重建。
  Future<void> _setupBin(String id) async {
    final binDir = Directory('${_rootfsDir.parent.path}/bin');
    await binDir.create(recursive: true);
    // jniLibs 中 libtalloc 打包为 liblibtalloc.so.2.so，linker 名不匹配，必须软链
    await _ensureLink(
      binDir,
      'libtalloc.so.2',
      '$_nativeLibDir/liblibtalloc.so.2.so',
      id,
    );
    // libandroid-shmem 在 jniLibs 中为同名，native lib 目录可解析；再放入
    // LD_LIBRARY_PATH 目录兜底
    await _ensureLink(
      binDir,
      'libandroid-shmem.so',
      '$_nativeLibDir/libandroid-shmem.so',
      id,
    );
  }

  Future<void> _ensureLink(
    Directory binDir,
    String name,
    String target,
    String id,
  ) async {
    final linkPath = '${binDir.path}/$name';
    try {
      final old = Link(linkPath);
      if (old.existsSync()) {
        await old.delete();
      }
      await Link(linkPath).create(target);
    } catch (e) {
      _debug(id, '$name 软链创建失败: $e');
    }
    _debug(id, '$name: $linkPath -> $target');
  }

  /// 确保 rootfs 内基础运行时文件就绪（DNS + pip 配置）。
  ///
  /// 从 Docker 导出的容器 rootfs 不含可用 resolv.conf（Docker 挂载不随导出
  /// 保留），导致 proot 内 DNS 解析失败（模块商店 / pip 拉取不到信息）；
  /// 且 Ubuntu 24.04 默认 PEP 668 拒绝系统级 pip 安装（Dashboard 装包报
  /// externally-managed-environment）。这里在每次启动前写入兜底配置：
  ///   - /etc/resolv.conf：国内可用的公共 DNS
  ///   - /etc/pip.conf：break-system-packages = true
  Future<void> _ensureRuntimeFiles(String id) async {
    try {
      final resolv = File('${_rootfsDir.path}/etc/resolv.conf');
      await resolv.writeAsString(
        'nameserver 223.5.5.5\nnameserver 8.8.8.8\n',
        flush: true,
      );
    } catch (e) {
      _debug(id, 'resolv.conf 写入失败: $e');
    }
    try {
      final pip = File('${_rootfsDir.path}/etc/pip.conf');
      await pip.writeAsString(
        '[global]\nbreak-system-packages = true\n',
        flush: true,
      );
    } catch (e) {
      _debug(id, 'pip.conf 写入失败: $e');
    }
  }

  /// 构造 proot 启动命令并拉起进程（实例独立 venv 优先，旧实例回退系统 Python）
  Future<Process> _spawnProot(InstanceData data) async {
    const pythonCode = 'import asyncio; from ErisPulse import sdk; '
        'asyncio.run(sdk.run())';

    final useVenv = _hasVenv(data);
    final python =
        useVenv ? '${data.workingDir}/.venv/bin/python' : '/usr/bin/python3';

    final proc = await _runProot(
      data,
      [python, '-c', pythonCode],
      extraEnv: useVenv ? {'VIRTUAL_ENV': '${data.workingDir}/.venv'} : null,
    );
    _debug(data.id, 'python=$python venv=$useVenv');
    return proc;
  }

  /// proot 固定参数（不含实际执行的 guest 命令）
  List<String> _baseProotArgs(InstanceData data) {
    return [
      '-0', // 伪 root（无需真 root）
      '--rootfs=${_rootfsDir.path}',
      // 硬链接转软链接：app 沙箱文件系统不支持硬链接
      '--link2symlink',
      '--bind=/proc',
      '--bind=/dev',
      '--bind=/sys',
      '--bind=/dev/pts',
      '--bind=/proc/self/fd:/dev/fd',
      '--bind=/proc/self/fd/0:/dev/stdin',
      '--bind=/proc/self/fd/1:/dev/stdout',
      '--bind=/proc/self/fd/2:/dev/stderr',
      '--cwd=${data.workingDir}', // guest 内路径
      '--kill-on-exit',
    ];
  }

  /// 实例是否已有独立 venv（guest 路径 `{workingDir}/.venv`）
  bool _hasVenv(InstanceData data) {
    final p = File('${_rootfsDir.path}/${data.workingDir}/.venv/bin/python');
    return p.existsSync();
  }

  /// 在 rootfs 内执行一条 guest 命令（proot 包装），返回进程。
  ///
  /// 确保 DNS / pip 配置与 proot 动态库环境就绪；供实例启动与
  /// 环境准备（venv / pip / 复制）共用。
  Future<Process> _runProot(
    InstanceData data,
    List<String> guestCmd, {
    Map<String, String>? extraEnv,
  }) async {
    // 确保 rootfs 内 DNS 与 pip 配置可用
    await _ensureRuntimeFiles(data.id);
    // proot 的 loader 注入需要可写临时目录；app 沙箱没有全局 /tmp，必须显式指定
    final tmpDir = '${_rootfsDir.parent.path}/tmp';
    await Directory(tmpDir).create(recursive: true);
    // termux proot 动态依赖（libtalloc.so.2）所在的宿主目录
    await _setupBin(data.id);
    final binDir = '${_rootfsDir.parent.path}/bin';

    final args = [..._baseProotArgs(data), ...guestCmd];

    final env = <String, String>{
      'HOME': data.workingDir,
      'PATH': '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      'LANG': 'C.UTF-8',
      'PYTHONUNBUFFERED': '1',
      // loader 注入所需：app 沙箱没有全局 /tmp，必须显式指定可写目录
      'PROOT_TMP_DIR': tmpDir,
      // termux proot：ptrace 注入用 loader + 动态链接依赖 libtalloc.so.2
      'PROOT_LOADER': '$_nativeLibDir/libloader.so',
      'LD_LIBRARY_PATH': binDir,
      // process_vm_readv 加速在 app 沙箱可能受限，回退纯 ptrace 更稳。
      // 注意：不能设 PROOT_NO_SECCOMP —— proot 需安装 seccomp filter 以
      // TRACE 并翻译 tracee 的 clone3（rootfs 内 glibc 2.39 的 fork 走 clone3，
      // Android untrusted_app seccomp 禁 clone3，裸奔会 SIGSYS -31）。
      'PROOT_NO_PROCESS_VM': '1',
      // 输出 ptrace 诊断到 stderr（经日志页显示），定位问题卡点
      'PROOT_VERBOSE': '1',
      ...?extraEnv,
    };

    _debug(data.id, 'proot exec: ${args.join(' ')}');

    try {
      final proc = await Process.start(_prootPath.path, args, environment: env);
      _debug(data.id, 'Process.start OK pid=${proc.pid}');
      return proc;
    } on ProcessException catch (e) {
      _debug(data.id, 'Process.start 异常: $e');
      onEvent(
        ProcessEvent(
          id: data.id,
          status: 'error',
          error: 'exec 失败: $e',
        ).toJson(),
      );
      rethrow;
    }
  }

  /// 为实例准备独立 venv（移动端实例分离）。
  ///
  /// - `fresh`：`python3 -m venv --system-site-packages`（离线继承 rootfs 预烘焙
  ///   ErisPulse），可选按 [sdkVersion] 安装 ErisPulse / [installDashboard] 安装
  ///   ErisPulse-Dashboard（走 [indexUrl] 镜像）
  /// - `clone`：复制源实例（[sourceWorkingDir]）的 venv，继承其 SDK 版本与已装包
  Future<bool> prepareInstanceEnvironment(
    InstanceData data, {
    required String mode,
    String? sourceWorkingDir,
    String? sdkVersion,
    bool installDashboard = false,
    String? indexUrl,
  }) async {
    if (!isRootfsReady) {
      _debug(data.id, 'rootfs 未就绪，无法准备环境');
      return false;
    }
    try {
      final wd = data.workingDir;
      final venv = '$wd/.venv';

      if (mode == 'clone') {
        final src = sourceWorkingDir;
        if (src == null || src.isEmpty) {
          _debug(data.id, '克隆环境缺少源实例工作目录');
          return false;
        }
        _debug(data.id, '基于 $src/.venv 复制环境…');
        final proc = await _runProot(data, ['cp', '-r', '$src/.venv', venv]);
        final exit = await proc.exitCode;
        if (exit != 0) {
          _debug(data.id, '复制 venv 失败 exit=$exit');
          return false;
        }
        _debug(data.id, '环境准备完成（基于已有实例）');
        return true;
      }

      // fresh：独立 venv（system-site-packages 提供离线兜底）
      _debug(data.id, '创建独立 venv（system-site-packages）…');
      var proc = await _runProot(data, [
        '/usr/bin/python3',
        '-m',
        'venv',
        '--system-site-packages',
        venv,
      ]);
      var exit = await proc.exitCode;
      if (exit != 0) {
        _debug(data.id, '创建 venv 失败 exit=$exit');
        return false;
      }

      if ((sdkVersion != null && sdkVersion.isNotEmpty) || installDashboard) {
        final args = <String>['$venv/bin/pip', 'install'];
        if (indexUrl != null && indexUrl.isNotEmpty) {
          args.addAll(['--index-url', indexUrl]);
        }
        if (sdkVersion != null && sdkVersion.isNotEmpty) {
          args.add('ErisPulse==$sdkVersion');
        }
        if (installDashboard) args.add('ErisPulse-Dashboard');
        _debug(data.id, 'pip install ${args.sublist(2).join(' ')} …');
        proc = await _runProot(data, args);
        exit = await proc.exitCode;
        if (exit != 0) {
          _debug(data.id, 'pip 安装失败 exit=$exit');
          return false;
        }
      }
      _debug(data.id, '环境准备完成');
      return true;
    } catch (e) {
      _debug(data.id, '环境准备异常: $e');
      return false;
    }
  }

  /// 转发 stdout/stderr 为日志事件
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

  /// 轮询健康直到就绪或超时
  Future<void> _waitReady(_InstanceProcess tracker, InstanceData data) async {
    final deadline = DateTime.now().add(_readyTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (!_procs.containsKey(data.id)) return; // 被停止

      try {
        final resp = await http
            .get(
              Uri.parse(
                'http://127.0.0.1:${data.port}/Dashboard/api/auth/status',
              ),
            )
            .timeout(_pollInterval);
        if (resp.statusCode == 200 || resp.statusCode == 401) {
          // 服务器已响应即可视为就绪（401 表示 token 校验失败但服务活着）
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
      } catch (_) {
        // 未就绪，继续轮询
      }
      await Future<void>.delayed(_pollInterval);
    }
    // 超时：服务未就绪，但进程仍在 —— 报 warning 状态（不杀进程）
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

  /// 进程异常退出 → 上报 + 可选自动重启
  void _handleExit(_InstanceProcess tracker, int code) {
    final id = tracker.data.id;
    final wasRunning = _procs.remove(id) != null;
    if (!wasRunning) return;

    if (_manuallyStopped.contains(id)) return; // 手动停止，不处理

    _debug(id, '进程退出: code=$code ${_signalName(code)}');
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

  /// debug 断点日志（经 instanceLog 通道转发到 UI）
  void _debug(String id, String line) {
    onEvent(ProcessLogEvent(id, line).toJson());
  }

  /// 退出码 → 信号名（负数退出码表示进程被信号杀死）
  static String _signalName(int code) {
    if (code >= 0) return '';
    const signals = {
      1: 'SIGHUP',
      2: 'SIGINT',
      3: 'SIGQUIT',
      4: 'SIGILL',
      5: 'SIGTRAP',
      6: 'SIGABRT',
      7: 'SIGBUS',
      8: 'SIGFPE',
      9: 'SIGKILL',
      10: 'SIGUSR1',
      11: 'SIGSEGV',
      12: 'SIGUSR2',
      13: 'SIGPIPE',
      14: 'SIGALRM',
      15: 'SIGTERM',
      16: 'SIGSTKFLT',
      17: 'SIGCHLD',
      18: 'SIGCONT',
      19: 'SIGSTOP',
      20: 'SIGTSTP',
      21: 'SIGTTIN',
      22: 'SIGTTOU',
      23: 'SIGURG',
      24: 'SIGXCPU',
      25: 'SIGXFSZ',
      26: 'SIGVTALRM',
      27: 'SIGPROF',
      28: 'SIGWINCH',
      29: 'SIGIO',
      30: 'SIGPWR',
      31: 'SIGSYS',
    };
    return signals[-code] ?? '(signal ${-code})';
  }

  /// 崩溃后延迟重启
  Future<void> _restartAfterExit(_InstanceProcess tracker) async {
    await Future<void>.delayed(_restartCooldown);
    if (_manuallyStopped.contains(tracker.data.id)) return;
    await startInstance(tracker.data);
  }

  void _kill(Process p) {
    try {
      p.kill(ProcessSignal.sigterm);
      // 宽限 2s，再 SIGKILL
      Timer(const Duration(seconds: 2), () {
        try {
          p.kill(ProcessSignal.sigkill);
        } catch (_) {}
      });
    } catch (_) {}
  }
}

/// 单个实例的运行中进程跟踪
class _InstanceProcess {
  final InstanceData data;
  final Process process;
  _RunStatus status;

  _InstanceProcess(this.data, this.process) : status = _RunStatus.starting;
}
