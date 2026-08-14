// 桌面 SDK 环境管理器。
//
// App 构建时内置对应平台 Python（python-build-standalone，打包为
// assets/python/python-{platform}-{arch}.zip）。本服务负责：
//   - 释放内置 Python 到 ~/.erispulse/python/（含 pip 引导）
//   - 为每个实例创建独立虚拟环境（~/.erispulse/instances/{id}/.venv）
//    并 pip 安装 ErisPulse（可选 ErisPulse-Dashboard）
//   - PyPI 版本列表 / 实例 SDK 版本查询 / 框架升级
//
// 不再依赖 pybuild 便携运行时下载。

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'assets.dart';
import 'desktop_runtime.dart' show DesktopEnv;

/// 一个可用的 ErisPulse SDK 版本
class SdkVersion {
  final String version;
  final bool preRelease;
  const SdkVersion({required this.version, required this.preRelease});
}

class DesktopSdk {
  static const _timeout = Duration(seconds: 20);
  static const _package = 'ErisPulse';

  /// 默认推荐 SDK 版本（PyPI 查询失败时兜底）
  static const String kDefaultVersion = '2.7.1';

  /// 内置 Python 版本（python-build-standalone）。
  /// 选 3.13（较新但生态成熟）：3.15 太新，部分核心包（如 pydantic-core）
  /// 尚无 cp315 预编译 wheel，会触发源码编译（需 Rust）导致实例安装失败。
  static const String kBundledPython = '3.13';

  // ── 版本列表（PyPI）────────────────────────────────

  /// 可用版本（降序，仅稳定版）。来源：PyPI JSON；失败回退内置候选。
  static Future<List<SdkVersion>> availableVersions() async {
    final pypi = await _fromPyPI();
    if (pypi.isNotEmpty) return pypi;
    return const [
      SdkVersion(version: kDefaultVersion, preRelease: false),
    ];
  }

  static Future<List<SdkVersion>> _fromPyPI() async {
    try {
      final resp = await http
          .get(Uri.parse('https://pypi.org/pypi/ErisPulse/json'))
          .timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final root = jsonDecode(resp.body) as Map<String, dynamic>;
      final releases = root['releases'] as Map<String, dynamic>? ?? const {};
      final versions = <SdkVersion>[];
      for (final e in releases.entries) {
        final ver = e.key;
        final files = e.value as List? ?? [];
        if (files.isEmpty) continue;
        final pre =
            RegExp(r'(a|alpha|b|beta|rc|dev|preview)', caseSensitive: false)
                .hasMatch(ver);
        versions.add(SdkVersion(version: ver, preRelease: pre));
      }
      versions.sort((a, b) => _compareVersions(b.version, a.version));
      if (versions.length > 50) versions.removeRange(50, versions.length);
      return versions;
    } catch (_) {
      return [];
    }
  }

  // ── 内置 Python ─────────────────────────────────────

  /// 内置 Python 可执行文件路径；未就绪返回 null
  static Future<String?> bundledPythonPath() async {
    final p = await DesktopEnv.bundledPythonPath();
    return File(p).existsSync() ? p : null;
  }

  /// 内置 Python 是否就绪（python 存在即可）
  static Future<bool> isBundledPythonReady() async {
    return await bundledPythonPath() != null;
  }

  /// 内置 Python 版本号（如 `3.13.0`）；未就绪返回 null
  static Future<String?> bundledPythonVersion() async {
    final p = await bundledPythonPath();
    if (p == null) return null;
    try {
      final r = await Process.run(p, ['-V']);
      return r.exitCode == 0 ? r.stdout.toString().trim() : null;
    } catch (_) {
      return null;
    }
  }

  /// 内置 Python 是否有 pip
  static Future<bool> hasPip() async {
    final p = await bundledPythonPath();
    if (p == null) return false;
    try {
      final r = await Process.run(p, ['-m', 'pip', '--version']);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 确保内置 Python 可用：已存在则只引导 pip；否则从 assets 释放并解压。
  /// 返回 0 表示成功。
  static Future<int> ensureBundledPython({
    required void Function(String line) onLog,
  }) async {
    final existing = await bundledPythonPath();
    if (existing != null) {
      final code = await _ensurePip(existing, onLog);
      if (code == 0) onLog('内置 Python 就绪');
      return code;
    }

    final pa = DesktopEnv.hostPlatformArch();
    final assetName = bundledPythonAssetName(pa);
    onLog('释放内置 Python（$assetName）…');
    try {
      final data = await rootBundle.load('$kAssetPythonDir/$assetName');
      final targetDir = await DesktopEnv.bundledPythonDir();
      if (targetDir.existsSync()) targetDir.deleteSync(recursive: true);
      targetDir.createSync(recursive: true);
      // python-build-standalone 发布产物为 tar.gz，顶层带一个目录，解压时剥离
      final tar = TarDecoder().decodeBytes(
        const GZipDecoder().decodeBytes(data.buffer.asUint8List()),
      );
      for (final f in tar.files) {
        if (!f.isFile) continue;
        final rel = _stripTopLevel(f.name);
        if (rel.isEmpty) continue;
        final out = File('${targetDir.path}/$rel');
        out.createSync(recursive: true);
        out.writeAsBytesSync(f.content as List<int>);
      }
      // Unix 需要可执行位
      if (!Platform.isWindows) {
        final bin = '${targetDir.path}/bin/python3';
        if (File(bin).existsSync()) {
          Process.runSync('chmod', ['+x', bin]);
        }
      }
      final py = await bundledPythonPath();
      if (py == null) {
        onLog('释放后未找到 python 可执行文件');
        return 1;
      }
      final code = await _ensurePip(py, onLog);
      if (code == 0) onLog('内置 Python 就绪');
      return code;
    } catch (e) {
      onLog('释放异常: $e');
      return 1;
    }
  }

  /// 剥离 tar 条目首层目录（python-build-standalone 顶层为 `python/` 等）
  static String _stripTopLevel(String name) {
    final idx = name.indexOf('/');
    return idx < 0 ? '' : name.substring(idx + 1);
  }

  /// 确保指定 Python 有 pip（ensurepip 优先，get-pip.py 兜底）
  static Future<int> _ensurePip(
    String python,
    void Function(String line) onLog,
  ) async {
    final check = await Process.run(python, ['-m', 'pip', '--version']);
    if (check.exitCode == 0) return 0;

    onLog('引导 pip（ensurepip）…');
    var r = await Process.run(python, ['-m', 'ensurepip', '--upgrade']);
    if (r.exitCode == 0) return 0;

    onLog('ensurepip 不可用，尝试 get-pip.py…');
    try {
      final resp = await http
          .get(Uri.parse('https://bootstrap.pypa.io/get-pip.py'))
          .timeout(const Duration(minutes: 2));
      if (resp.statusCode == 200) {
        final script = File(
          '${Directory.systemTemp.path}/erispulse_get_pip.py',
        );
        await script.writeAsString(resp.body);
        r = await Process.run(python, [script.path]);
        script.deleteSync();
        if (r.exitCode == 0) return 0;
      }
    } catch (_) {}
    onLog('pip 引导失败:\n${r.stdout}\n${r.stderr}');
    return r.exitCode;
  }

  // ── 实例环境（每实例独立 venv）──────────────────────

  /// 为实例创建 venv 并安装 ErisPulse SDK（随装 ErisPulse-Dashboard）。
  /// 返回 0 表示成功。
  static Future<int> prepareInstance({
    required String instanceId,
    required String version,
    required String indexUrl,
    required void Function(String line) onLog,
  }) async {
    final py = await bundledPythonPath();
    if (py == null) {
      onLog('内置 Python 未就绪');
      return 1;
    }
    final venvDir = await DesktopEnv.instanceVenvDir(instanceId);

    onLog('创建虚拟环境…');
    var r = await Process.run(py, ['-m', 'venv', venvDir.path]);
    if (r.exitCode != 0) {
      onLog('创建 venv 失败:\n${r.stdout}\n${r.stderr}');
      return r.exitCode;
    }

    final venvPy = await DesktopEnv.instanceVenvPython(instanceId);
    final pkgSpec = '$_package==$version';
    final args = [
      '-m',
      'pip',
      'install',
      '--index-url',
      indexUrl,
      pkgSpec,
      'ErisPulse-Dashboard',
    ];
    onLog('安装 $pkgSpec + ErisPulse-Dashboard …');
    r = await Process.run(venvPy, args);
    if (r.exitCode != 0) {
      onLog('安装失败:\n${r.stdout}\n${r.stderr}');
      return r.exitCode;
    }
    onLog('环境准备完成');
    return 0;
  }

  /// 查询实例 venv 中已安装的 ErisPulse 版本；未就绪返回 null
  static Future<String?> installedSdkVersion(String instanceId) async {
    final venvPy = await DesktopEnv.instanceVenvPython(instanceId);
    if (!File(venvPy).existsSync()) return null;
    try {
      final r = await Process.run(venvPy, [
        '-c',
        'import importlib.metadata;print(importlib.metadata.version("$_package"))',
      ]);
      return r.exitCode == 0 ? r.stdout.toString().trim() : null;
    } catch (_) {
      return null;
    }
  }

  /// 实例环境是否就绪（venv 中已装 ErisPulse）
  static Future<bool> isInstanceReady(String instanceId) async {
    final v = await installedSdkVersion(instanceId);
    return v != null && v.isNotEmpty;
  }

  /// 升级实例 venv 中的 ErisPulse 到指定版本
  static Future<int> updateInstanceSdk({
    required String instanceId,
    required String version,
    required String indexUrl,
    required void Function(String line) onLog,
  }) async {
    final venvPy = await DesktopEnv.instanceVenvPython(instanceId);
    if (!File(venvPy).existsSync()) {
      onLog('实例环境未就绪');
      return 1;
    }
    onLog('更新 $_package==$version …');
    final r = await Process.run(venvPy, [
      '-m',
      'pip',
      'install',
      '--index-url',
      indexUrl,
      '$_package==$version',
    ]);
    if (r.exitCode != 0) onLog('${r.stdout}\n${r.stderr}');
    return r.exitCode;
  }

  /// 删除实例的 venv（删除实例时调用）
  static Future<void> removeInstanceEnv(String instanceId) async {
    final venvDir = await DesktopEnv.instanceVenvDir(instanceId);
    if (venvDir.existsSync()) venvDir.deleteSync(recursive: true);
  }

  /// 基于源实例复制 venv 到新实例（继承其 SDK 版本与已装包）。
  /// venv 可移动（site-packages 相对 venv 目录），直接复制目录即可。
  /// 返回 0 表示成功。
  static Future<int> cloneInstanceEnv({
    required String sourceInstanceId,
    required String newInstanceId,
    required void Function(String line) onLog,
  }) async {
    final src = await DesktopEnv.instanceVenvDir(sourceInstanceId);
    if (!src.existsSync()) {
      onLog('源实例环境未就绪');
      return 1;
    }
    final dst = await DesktopEnv.instanceVenvDir(newInstanceId);
    if (dst.existsSync()) dst.deleteSync(recursive: true);
    onLog('基于源实例环境复制 venv…');
    try {
      _copyDirectorySync(src, dst);
    } catch (e) {
      onLog('复制失败: $e');
      return 1;
    }
    onLog('环境准备完成（基于已有实例）');
    return 0;
  }

  /// 递归复制目录（保留符号链接，如 Unix venv 的 bin/python）
  static void _copyDirectorySync(Directory from, Directory to) {
    to.createSync(recursive: true);
    for (final e in from.listSync(followLinks: false)) {
      final name =
          e.path.substring(e.path.lastIndexOf(Platform.pathSeparator) + 1);
      if (e is Directory) {
        _copyDirectorySync(e, Directory('${to.path}/$name'));
      } else if (e is File) {
        final out = File('${to.path}/$name');
        out.createSync(recursive: true);
        out.writeAsBytesSync(e.readAsBytesSync());
      } else if (e is Link) {
        try {
          Link('${to.path}/$name').createSync(e.targetSync());
        } catch (_) {}
      }
    }
  }

  /// 版本比较（公开，供 UI 排序）。返回 >0 表示 a 新于 b。
  static int compareVersions(String a, String b) => _compareVersions(a, b);

  /// 版本号比较（PEP 440 语义）：先比基础数字段；基础段相同且一方为
  /// 预发布时，正式版排在预发布之前；同为预发布时按 pre 段数字比较
  /// （如 `2.7.1.dev4` > `2.7.1.dev3`）。
  static int _compareVersions(String a, String b) {
    final ab = _baseParts(a);
    final bb = _baseParts(b);
    final len = ab.length > bb.length ? ab.length : bb.length;
    for (var i = 0; i < len; i++) {
      final av = ab.length > i ? ab[i] : '';
      final bv = bb.length > i ? bb[i] : '';
      final an = int.tryParse(av);
      final bn = int.tryParse(bv);
      if (an != null && bn != null) {
        if (an != bn) return an - bn;
      } else {
        final cmp = av.compareTo(bv);
        if (cmp != 0) return cmp;
      }
    }
    final aPre = _hasPreRelease(a);
    final bPre = _hasPreRelease(b);
    if (aPre != bPre) return aPre ? -1 : 1; // 正式版在前
    if (aPre) return _comparePreParts(a, b);
    return 0;
  }

  /// 比较两个预发布版本的后缀段（如 `dev4` vs `dev3`），数字段优先
  static int _comparePreParts(String a, String b) {
    final ap = _preParts(a);
    final bp = _preParts(b);
    final len = ap.length > bp.length ? ap.length : bp.length;
    for (var i = 0; i < len; i++) {
      final av = ap.length > i ? ap[i] : '';
      final bv = bp.length > i ? bp[i] : '';
      final an = int.tryParse(av);
      final bn = int.tryParse(bv);
      if (an != null && bn != null) {
        if (an != bn) return an - bn;
      } else if (an == null && bn == null) {
        final cmp = av.compareTo(bv);
        if (cmp != 0) return cmp;
      } else {
        return an != null ? 1 : -1;
      }
    }
    return 0;
  }

  /// 版本的基础数字段（截掉预发布标识及之后，如 `2.7.1-dev.0` → `[2, 7, 1]`）
  static List<String> _baseParts(String v) {
    final parts = v.split(RegExp(r'[\.\-+]'));
    final out = <String>[];
    for (final p in parts) {
      if (int.tryParse(p) == null) break;
      out.add(p);
    }
    return out.isEmpty ? parts : out;
  }

  /// 预发布后缀段（第一个非数字段开始，如 `2.7.1-dev.0` → `[dev, 0]`）
  static List<String> _preParts(String v) {
    final parts = v.split(RegExp(r'[\.\-+]'));
    final idx = parts.indexWhere((p) => int.tryParse(p) == null);
    if (idx < 0) return const [];
    return parts.sublist(idx);
  }

  /// 是否为预发布版本（含 alpha/beta/rc/dev/preview 标识）
  static bool _hasPreRelease(String v) =>
      RegExp(r'(a|alpha|b|beta|rc|dev|preview)', caseSensitive: false)
          .hasMatch(v);
}
