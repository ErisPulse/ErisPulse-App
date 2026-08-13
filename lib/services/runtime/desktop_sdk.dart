// 桌面 SDK 管理：检查捆绑 Python 中 ErisPulse 的安装情况，
// 从 PyPI 拉取可用版本，并提供选择安装（pip）。
//
// 参考 Dashboard 的 /framework/versions + /framework/update 逻辑：
//   - 版本列表来自官方 PyPI JSON API（https://pypi.org/pypi/ErisPulse/json）
//   - 安装用 pip（捆绑 Python 自带），默认最新稳定版

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'desktop_runtime.dart' show DesktopEnv;

/// 一个可用的 SDK 版本
class SdkVersion {
  final String version;
  final bool preRelease;
  const SdkVersion({required this.version, required this.preRelease});
}

class DesktopSdk {
  static const _timeout = Duration(seconds: 15);
  static const _package = 'ErisPulse';

  /// 捆绑 Python 中 ErisPulse 的当前版本；未安装返回 null
  static Future<String?> installedVersion() async {
    final python = await DesktopEnv.pythonPath();
    if (!File(python).existsSync()) return null;
    try {
      final proc = await Process.run(
        python,
        [
          '-c',
          'import importlib.metadata;'
              'print(importlib.metadata.version("$_package"))',
        ],
      );
      final out = proc.stdout.toString().trim();
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  /// 从 PyPI 拉取可用版本列表（降序，默认过滤预发布；[pre] 为 true 时包含）
  static Future<List<SdkVersion>> availableVersions({bool pre = false}) async {
    try {
      final resp = await http
          .get(Uri.parse('https://pypi.org/pypi/$_package/json'))
          .timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final releases = data['releases'] as Map<String, dynamic>? ?? {};
      final versions = <SdkVersion>[];
      for (final entry in releases.entries) {
        final files = entry.value as List? ?? [];
        if (files.isEmpty) continue;
        final ver = entry.key;
        final isPre =
            RegExp(r'(a|alpha|b|beta|rc|dev|preview)', caseSensitive: false)
                .hasMatch(ver);
        if (!pre && isPre) continue;
        versions.add(SdkVersion(version: ver, preRelease: isPre));
      }
      versions.sort((a, b) => _compareVersions(b.version, a.version));
      if (versions.length > 50) versions.removeRange(50, versions.length);
      return versions;
    } catch (_) {
      return [];
    }
  }

  /// 安装 / 升级 SDK。进度与日志逐行回调，返回退出码。
  static Future<int> install(
    String version, {
    required void Function(String line) onLog,
  }) async {
    final python = await DesktopEnv.pythonPath();
    final proc = await Process.start(
      python,
      ['-m', 'pip', 'install', '--force-reinstall', '$_package==$version'],
    );
    proc.stdout
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(onLog);
    proc.stderr
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(onLog);
    return proc.exitCode;
  }

  /// 简易版本号比较（按 . 分段，数字优先）。
  /// 返回 >0 表示 a 新于 b。
  static int _compareVersions(String a, String b) {
    final as = a.split(RegExp(r'[\.\-+]'));
    final bs = b.split(RegExp(r'[\.\-+]'));
    final len = as.length > bs.length ? as.length : bs.length;
    for (var i = 0; i < len; i++) {
      final av = as.length > i ? as[i] : '';
      final bv = bs.length > i ? bs[i] : '';
      final an = int.tryParse(av);
      final bn = int.tryParse(bv);
      if (an != null && bn != null) {
        if (an != bn) return an - bn;
      } else {
        final cmp = av.compareTo(bv);
        if (cmp != 0) return cmp;
      }
    }
    return 0;
  }
}
