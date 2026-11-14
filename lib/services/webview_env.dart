// WebView2 共享环境（Windows）：全局单例。
//
// WebView2 限制：同一 userDataFolder 只能被一个 WebViewEnvironment 使用。
// 多个页面（Dashboard 页 / 模块视图宿主）必须共享同一实例，否则第二个
// 环境创建即崩溃。

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

/// 全局 WebView2 环境（仅 Windows 有意义；其它平台恒为 null）
class WebViewEnv {
  WebViewEnv._();

  static WebViewEnvironment? _instance;
  static Future<void>? _creating;
  static bool _attempted = false;

  /// 是否已尝试初始化（成功或失败）
  static bool get attempted => _attempted;

  /// 环境是否就绪
  static bool get ready => _instance != null;

  /// 确保环境已创建（幂等；并发调用合并为一次）
  static Future<void> ensure() async {
    if (defaultTargetPlatform != TargetPlatform.windows) return;
    if (_instance != null) return;
    if (_creating != null) return _creating;
    _creating = () async {
      try {
        final dir = await getApplicationSupportDirectory();
        _instance = await WebViewEnvironment.create(
          settings: WebViewEnvironmentSettings(
            userDataFolder: '${dir.path}${Platform.pathSeparator}WebView2',
          ),
        );
      } catch (_) {
        // 创建失败保持 null：调用方走默认路径
      }
      _attempted = true;
    }();
    return _creating;
  }

  static WebViewEnvironment? get instance => _instance;
}
