// Foreground Service 后台 isolate 入口。
//
// 所有 ErisPulse 实例的 proot 子进程由本 isolate 拥有，从而：
//   - 用户关闭 UI 后实例继续运行
//   - 崩溃自动重启
//   - 系统回收时被前台服务保活
//
// UI 通过 flutter_background_service 的 invoke / onData 与本层通信。

import 'dart:async';
import 'dart:io';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show DartPluginRegistrant;

import 'assets.dart';
import 'native_lib.dart';
import 'proot_manager.dart';
import 'rootfs_provisioner.dart';

/// 后台服务入口（@pragma 必需：作为 entry-point 供平台调用）
@pragma('vm:entry-point')
Future<void> onBackgroundStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    unawaited(service.setAsForegroundService());
  }

  // 初始化运行时（app 私有目录 + native lib 目录）
  final appDir = await _appSupportDir();
  // method channel handler 只注册在主 isolate，这里从缓存读取
  final nativeLibDir = await readNativeLibraryDir();
  final provisioner = RootfsProvisioner(
    appDir: appDir,
    nativeLibDir: nativeLibDir,
  );

  // proot 状态 / 日志事件 → UI（按 type 路由到对应 channel）
  final proot = ProotManager(
    appDir: appDir,
    nativeLibDir: nativeLibDir,
    onEvent: (event) {
      final type = event['type'] as String? ?? 'instanceEvent';
      service.invoke(type, event);
    },
  );

  // rootfs 供给进度 → UI
  provisioner.onEvent = (event) {
    service.invoke('rootfsProgress', _provisionToJson(event));
  };

  service.on('ensureRootfs').listen((_) async {
    // 应用用户选择的下载源（GitHub 直连 / 国内加速镜像）
    provisioner.releaseBase = resolveReleaseBase(await _downloadSource());
    final ok = await provisioner.ensure();
    service.invoke('rootfsReady', {'ready': ok});
  });

  service.on('getRootfsReady').listen((_) {
    provisioner.isReady.then((ready) {
      service.invoke('rootfsReady', {'ready': ready});
    });
  });

  service.on('startInstance').listen((data) async {
    if (data == null) return;
    await proot.startInstance(InstanceData.fromJson(data));
  });

  service.on('stopInstance').listen((data) async {
    final id = data?['id'] as String?;
    if (id == null) return;
    await proot.stopInstance(id);
  });

  service.on('restartInstance').listen((data) async {
    if (data == null) return;
    await proot.restartInstance(InstanceData.fromJson(data));
  });

  service.on('stopAll').listen((_) async {
    await proot.stopAll();
  });

  service.on('setAutoRestart').listen((data) async {
    proot.autoRestart = data?['enabled'] as bool? ?? true;
  });

  // 移动端实例环境准备（独立 venv：fresh 新建 / clone 复制源实例 venv）
  service.on('prepareInstance').listen((data) async {
    if (data == null) return;
    final inst = InstanceData.fromJson(
      data['data'] as Map<String, dynamic>,
    );
    final ok = await proot.prepareInstanceEnvironment(
      inst,
      mode: data['mode'] as String? ?? 'fresh',
      sourceWorkingDir: data['sourceWorkingDir'] as String?,
      sdkVersion: data['sdkVersion'] as String?,
      indexUrl: data['indexUrl'] as String?,
    );
    service.invoke('instanceEnv', {'id': inst.id, 'ready': ok});
  });

  service.on('getState').listen((_) {
    service.invoke('instanceStates', {'states': proot.statusSnapshot});
  });

  // 进程启动时同步一次当前状态
  service.invoke('instanceStates', {'states': proot.statusSnapshot});
}

/// 供给事件 → channel payload JSON
Map<String, dynamic> _provisionToJson(ProvisionEvent e) {
  return switch (e) {
    ProvisionProgress(:final percent, :final message) => {
        'percent': percent,
        'message': message,
      },
    ProvisionDone() => {'percent': 100.0, 'message': '完成'},
    ProvisionFailed(:final message) => {'error': message},
  };
}

/// 读取用户配置的下载源（与 AppSettings 共享同一 prefs key）
Future<String> _downloadSource() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('erispulse.download_source') ??
        kDownloadSourceGithub;
  } catch (_) {
    return kDownloadSourceGithub;
  }
}

/// app 私有目录（runtime / rootfs 存放处）
Future<Directory> _appSupportDir() async {
  final dir = await getApplicationSupportDirectory();
  return Directory(dir.path);
}

/// 启动后台服务（UI 侧调用）
Future<void> configureBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: false,
      notificationChannelId: 'erispulse_runtime',
      initialNotificationTitle: 'ErisPulse 运行中',
      initialNotificationContent: '机器人实例保持后台运行',
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: (_) async {},
      onBackground: (_) async => true,
    ),
  );
  await service.startService();
}
