// 应用冒烟测试：验证 App 能启动并渲染实例列表空状态。
//
// 由于 App 已接入 Foreground Service / rootfs 供给（依赖 Android 平台通道），
// 测试用无平台调用的 RuntimeController 子类替代。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:erispulse_app/main.dart';
import 'package:erispulse_app/services/app_settings.dart';
import 'package:erispulse_app/services/instance_manager.dart';
import 'package:erispulse_app/services/runtime/runtime_controller.dart';

/// 测试专用控制器：rootfs 视为已就绪，启停 / 查询为 no-op
class _TestRuntimeController extends RuntimeController {
  _TestRuntimeController(InstanceManager mgr) : super(instanceManager: mgr) {
    rootfsReady = true;
    rootfsStatusLoaded = true;
  }

  @override
  void refreshRootfs() {}

  @override
  void ensureRootfs() {}
}

void main() {
  testWidgets('App 启动渲染实例列表空状态', (WidgetTester tester) async {
    // InstanceManager 使用 SharedPreferencesAsync，需 mock 异步平台
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final mgr = InstanceManager();
    final RuntimeController runtime = _TestRuntimeController(mgr);
    final settings = AppSettings();

    // 指定中文环境（App 多语言跟随系统）
    tester.platformDispatcher.localesTestValue = const [Locale('zh')];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: mgr),
          ChangeNotifierProvider.value(value: runtime),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: const ErisPulseApp(),
      ),
    );

    // 手动 pump 等待异步 load 完成。
    // 不能用 pumpAndSettle：SplashGate 的 CircularProgressIndicator 无限动画会挂死。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ErisPulse'), findsOneWidget);
    expect(find.text('还没有实例'), findsOneWidget);
    expect(find.text('创建实例'), findsWidgets);
  });
}
