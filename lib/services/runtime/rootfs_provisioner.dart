// rootfs 与运行时二进制供给：确保 app 私有目录中存在可用的
// proot / busybox 与 rootfs（含 python3），来源为私有目录 / assets / Releases。

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'assets.dart';

/// 供给过程事件
sealed class ProvisionEvent {
  const ProvisionEvent();
}

class ProvisionProgress extends ProvisionEvent {
  final double? percent; // 0-100，null 表示不确定（如解压）
  final String message;
  const ProvisionProgress(this.percent, this.message);
}

class ProvisionDone extends ProvisionEvent {
  const ProvisionDone();
}

class ProvisionFailed extends ProvisionEvent {
  final String message;
  const ProvisionFailed(this.message);
}

class RootfsProvisioner {
  RootfsProvisioner({
    required Directory appDir,
    required String nativeLibDir,
  })  : _appDir = appDir,
        _nativeLibDir = nativeLibDir;

  final Directory _appDir;
  final String _nativeLibDir;

  /// 可覆盖的 Releases 基址（国内镜像下载源）；null 时用默认 [kReleaseBase]
  String? releaseBase;

  /// 回调：上报事件（在调用者上下文执行）
  void Function(ProvisionEvent event)? onEvent;

  // busybox 以 native lib 打包（jniLibs/libbusybox.so），系统提取后可直接执行
  File get _busyboxFile => File('$_nativeLibDir/libbusybox.so');
  Directory get _rootfsDir => Directory('${_appDir.path}/rootfs');
  File get _rootfsTar => File('${_appDir.path}/$kRootfsFileName');

  /// 当前供给状态是否已就绪（rootfs + python3 存在）
  Future<bool> get isReady async {
    final py = _rootfsPythonPath();
    return await py.exists();
  }

  /// rootfs 内 python3 的可能路径
  File _rootfsPythonPath() {
    return File('${_rootfsDir.path}/usr/bin/python3');
  }

  /// 确保一切就绪。返回 true 表示可用。
  Future<bool> ensure() async {
    _emit(const ProvisionProgress(null, '准备运行时环境…'));

    // proot/busybox 作为 native lib 打包，确认存在
    if (!await _busyboxFile.exists()) {
      _emit(const ProvisionFailed('busybox native lib 缺失'));
      return false;
    }

    // rootfs 目录
    if (await isReady) {
      _emit(const ProvisionDone());
      return true;
    }

    // rootfs tar 来源
    if (!await _rootfsTar.exists()) {
      await _acquireRootfsTar();
    }

    // 解压
    final ok = await _extractRootfs();
    if (ok && await isReady) {
      _emit(const ProvisionDone());
      return true;
    }
    _emit(const ProvisionFailed('rootfs 解压后未找到 python3'));
    return false;
  }

  /// 获取 rootfs tar（assets 内置优先，其次下载兜底）
  Future<void> _acquireRootfsTar() async {
    // assets 内置（正式包）
    final bundled = await _readAssetBytes('$kAssetRootfsDir/$kRootfsFileName');
    if (bundled != null && bundled.isNotEmpty) {
      await _rootfsTar.writeAsBytes(bundled, flush: true);
      return;
    }
    // 下载（开发/兜底）
    final url = '${releaseBase ?? kReleaseBase}/$rootfsReleaseAsset';
    _emit(const ProvisionProgress(0, '开始下载运行时镜像…'));
    await _downloadFile(url, _rootfsTar);
  }

  /// 解压 rootfs 到 rootfs 目录。
  ///
  /// 优先用 Android 系统 tar（toybox，原生支持 gzip + 硬链接），
  /// 失败则回退 busybox tar（部分构建不支持硬链接）。
  Future<bool> _extractRootfs() async {
    await _rootfsDir.create(recursive: true);
    _emit(const ProvisionProgress(null, '解压运行时镜像（首次较慢）…'));

    // 方案 1：系统 tar（toybox）
    try {
      final result = await Process.run(
        '/system/bin/tar',
        ['-xf', _rootfsTar.path, '-C', _rootfsDir.path],
      );
      if (result.exitCode == 0) return true;
      // toybox 可能报 xz 错误但仍部分解压 —— 检查 python3 是否存在
      final pyCheck =
          await File('${_rootfsDir.path}/usr/bin/python3.12').exists();
      if (pyCheck) return true;
    } catch (_) {
      // 系统 tar 不可用，回退 busybox
    }

    // 方案 2：busybox tar
    try {
      final result = await Process.run(
        _busyboxFile.path,
        ['tar', '-xf', _rootfsTar.path, '-C', _rootfsDir.path],
      );
      if (result.exitCode == 0) return true;
      final pyCheck =
          await File('${_rootfsDir.path}/usr/bin/python3.12').exists();
      if (pyCheck) return true;
      _emit(ProvisionFailed('解压失败: ${result.stderr}'));
      return false;
    } catch (e) {
      _emit(ProvisionFailed('解压异常: $e'));
      return false;
    }
  }

  /// 读取 asset 字节；不存在或为空返回 null
  Future<List<int>?> _readAssetBytes(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      if (data.lengthInBytes == 0) return null;
      return data.buffer.asUint8List();
    } catch (_) {
      return null; // asset 不存在
    }
  }

  /// 带进度的文件下载（dio）
  Future<void> _downloadFile(String url, File target) async {
    final dio = Dio();
    try {
      await dio.download(
        url,
        target.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _emit(
              ProvisionProgress(
                (received / total * 100).clamp(0, 100),
                '下载中 ${(received / 1024 / 1024).toStringAsFixed(1)}MB / '
                '${(total / 1024 / 1024).toStringAsFixed(1)}MB',
              ),
            );
          }
        },
      );
      _emit(const ProvisionProgress(null, '下载完成'));
    } finally {
      dio.close();
    }
  }

  void _emit(ProvisionEvent e) {
    onEvent?.call(e);
  }
}
