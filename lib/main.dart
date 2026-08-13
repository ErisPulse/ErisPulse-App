// ErisPulse App 入口。
//
// 启动流程：
//   1. 注册 Provider（InstanceManager / RuntimeController）
//   2. 请求通知权限（Android 13+）
//   3. 启动 Foreground Service（保活 + 后台运行实例）
//   4. 若 rootfs 未就绪 → 进入首启向导，否则进入主页
//
// 主题：Material 3 + 跟随系统（dynamic_color）。

import 'dart:async';
import 'dart:io' show Platform;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/debug_page.dart';
import 'services/app_settings.dart';
import 'services/instance_manager.dart';
import 'services/runtime/background_service.dart';
import 'services/runtime/native_lib.dart';
import 'services/runtime/runtime_controller.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Android 专用：通知权限 + 前台服务 + native lib 缓存 ──
  if (Platform.isAndroid) {
    // 通知权限（Android 13+）
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // 创建 FGS 通知渠道（必须与 configureBackgroundService 的
    // notificationChannelId 一致，且要在 startService 之前创建）
    const AndroidNotificationChannel runtimeChannel =
        AndroidNotificationChannel(
      'erispulse_runtime',
      'ErisPulse 运行中',
      description: 'ErisPulse 后台保活服务通知',
      importance: Importance.low,
    );
    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(runtimeChannel);

    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // 主 isolate 获取 native lib 目录并缓存。
    // method channel handler 只注册在主 isolate engine，FGS isolate 读缓存获取。
    final nativeLibDir = await getNativeLibraryDir();
    await cacheNativeLibraryDir(nativeLibDir);

    // 启动后台服务
    await configureBackgroundService();
  }

  final instanceManager = InstanceManager();
  await instanceManager.load();

  final appSettings = AppSettings();
  await appSettings.load();

  final runtime = RuntimeController(instanceManager: instanceManager);
  await runtime.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: instanceManager),
        ChangeNotifierProvider.value(value: runtime),
        ChangeNotifierProvider.value(value: appSettings),
      ],
      child: const ErisPulseApp(),
    ),
  );
}

class ErisPulseApp extends StatelessWidget {
  const ErisPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, _) => DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return MaterialApp(
            title: 'ErisPulse',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: lightDynamic ??
                  ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: darkDynamic ??
                  ColorScheme.fromSeed(
                    seedColor: const Color(0xFF6750A4),
                    brightness: Brightness.dark,
                  ),
              brightness: Brightness.dark,
            ),
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashGate(),
            routes: {
              SettingsPage.routeName: (_) => const SettingsPage(),
              DebugPage.routeName: (_) => const DebugPage(),
            },
          );
        },
      ),
    );
  }
}

/// 启动闸门：等 InstanceManager 就绪 + rootfs 就绪
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _loaded = false;

  /// 兜底：FGS 长时间未响应时强制进入主页，避免白屏
  bool _forceHome = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    // InstanceManager 已在 main() 中 load，这里只需等一帧
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _loaded = true);
    });
    // 查询 rootfs 状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RuntimeController>().refreshRootfs();
    });
    _timeout = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _forceHome = true);
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Consumer<RuntimeController>(
      builder: (context, runtime, _) {
        // 兜底：FGS 长时间未返回状态时进入主页，避免白屏
        if (_forceHome && !runtime.rootfsStatusLoaded) {
          return const HomePage();
        }
        // 等待 FGS 返回真实 rootfs 状态，避免误闪首启初始化页
        if (!runtime.rootfsStatusLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // 直接进入主页；rootfs/SDK 未就绪由主页横幅提示并引导初始化，
        // 不再强制首屏进入初始化页（用户可先去设置切换下载源等）
        return const HomePage();
      },
    );
  }
}
