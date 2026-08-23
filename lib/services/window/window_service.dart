// 桌面窗口服务：统一封装 `window_manager` 与 `tray_manager`。
//
// 替代原先自研的 Windows 无边框实现（win32_window.cpp / flutter_window.cpp 的
// WM_NCHITTEST / 自绘通道）。所有桌面平台（Windows / macOS / Linux）共用：
//   - 无边框窗口（自绘顶栏承担标题 / 拖拽 / 最小化 / 最大化 / 关闭）
//   - 窗口控制（最小化 / 最大化还原 / 拖动 / 关闭）
//   - 系统托盘（左键恢复 / 右键菜单退出）
//
// 移动端（Android / iOS）不初始化窗口服务，相关调用为 no-op。

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// 无边框窗口控制服务（单例）
class WindowService with WindowListener {
  WindowService._();
  static final WindowService instance = WindowService._();

  bool _initialized = false;

  /// 是否桌面平台（无边框 + 托盘）
  bool get _isDesktop => !Platform.isAndroid && !Platform.isIOS;

  /// 窗口是否最大化（顶栏切换图标）
  final ValueNotifier<bool> isMaximized = ValueNotifier(false);

  /// 用户点击托盘「显示主界面」
  VoidCallback? onTrayShow;

  /// 用户点击托盘「退出」，或系统关闭确认后选择退出
  VoidCallback? onTrayExit;

  /// 窗口关闭前（系统 X / Alt+F4 / 自绘关闭按钮）触发。
  VoidCallback? onCloseRequest;

  bool get initialized => _initialized;

  /// 初始化无边框窗口（桌面平台）。需在 runApp 之前调用。
  ///
  /// 必须完整 await：若不等待而在平台线程上与引擎启动/首帧交错执行，
  /// 会引入窗口样式竞争（FlutterView 子窗口几何与父窗口客户区错位，
  /// 点击落在子窗口外被吞 → 概率性「页面加载但完全无法点击」）。
  ///
  /// 只保留一种样式机制（setAsFrameless）：window_manager 的
  /// setTitleBarStyle(hidden) 会重置 is_frameless_ 并走 Win10 兼容分支
  /// （客户区四周缩 8px），与 frameless 混用是竞争根源，禁止混用。
  Future<void> ensureInitialized() async {
    if (!_isDesktop || _initialized) return;
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1100, 720),
      minimumSize: Size(720, 520),
      center: true,
      backgroundColor: Colors.transparent,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setAsFrameless();
      await windowManager.show();
      await windowManager.focus();
      windowManager.addListener(this);
    });
    _initialized = true;
  }

  @override
  void onWindowMaximize() => isMaximized.value = true;

  @override
  void onWindowUnmaximize() => isMaximized.value = false;

  /// 系统关闭信号被拦截（setPreventClose(true)）后，window_manager 回调本
  /// 方法。转发给关闭确认处理（ask / tray / exit）。
  @override
  void onWindowClose() {
    onCloseRequest?.call();
  }

  /// 设置窗口关闭拦截：true 时系统关闭信号先进入 [onWindowClose]。
  Future<void> setPreventClose(bool prevent) async {
    if (!_isDesktop || !_initialized) return;
    await windowManager.setPreventClose(prevent);
  }

  /// 初始化系统托盘（桌面平台）。
  Future<void> initTray() async {
    if (!_isDesktop) return;
    await ensureInitialized();
    trayManager.addListener(_TrayListener(this));
    // Windows 托盘需 ICO 图标（LoadImage(IMAGE_ICON)）；路径基于 flutter_assets
    await trayManager.setIcon('assets/images/app_icon.ico');
    await trayManager.setToolTip('ErisPulse');
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show', label: '显示主界面'),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: '退出'),
        ],
      ),
    );
  }

  // ── 窗口控制 ──

  Future<void> minimize() => _call(() => windowManager.minimize());
  Future<void> toggleMaximize() => _call(
        () => windowManager.isMaximized().then(
              (m) => m ? windowManager.unmaximize() : windowManager.maximize(),
            ),
      );
  Future<void> startDragging() => _call(() => windowManager.startDragging());
  Future<void> hide() => _call(() => windowManager.hide());
  Future<void> show() => _call(() => windowManager.show());

  /// 请求关闭：触发原生关闭流程（进而进入 onWindowClose 关闭确认）。
  Future<void> close() => _call(() => windowManager.close());

  Future<void> _call(Future<void> Function() fn) async {
    if (!_isDesktop || !_initialized) return;
    try {
      await fn();
    } catch (_) {
      // 平台通道不可用或尚未初始化：忽略
    }
  }
}

/// 托盘事件监听（内部，负责菜单 / 点击分发）
class _TrayListener with TrayListener {
  _TrayListener(this.service);
  final WindowService service;

  @override
  void onTrayIconMouseDown() {
    service.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        service.show();
      case 'exit':
        service.onTrayExit?.call();
    }
  }
}
