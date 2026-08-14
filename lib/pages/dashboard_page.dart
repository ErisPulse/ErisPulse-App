// Dashboard WebView 页：全屏内嵌实例的 Dashboard 管理界面。
//
// 使用 flutter_inappwebview 实现跨平台内嵌（Android/iOS/macOS WKWebView、
// Windows WebView2、Linux WebKitGTK）。本地实例加载
// http://127.0.0.1:<port>/Dashboard，远程实例加载其 remoteUrl/Dashboard。
//
// 访问密钥：以 UserScript（AT_DOCUMENT_START，页面 JS 执行前）把实例
// token 写入 Dashboard 前端的 localStorage（key `__ep_tk__`，dash.js 启动
// 时读取并 POST /api/auth 验证），实现免手动登录；脚本内带 origin 校验，
// 避免向第三方页面写入凭据。AppBar 提供"访问密钥"复制 / 刷新 / 外部浏览器。
//
// Windows 注意：setup.exe 安装到 Program Files 后 exe 同目录只读，
// WebView2 默认 user data folder 会在该处创建失败（表现为永久转圈），
// 因此显式创建指向应用数据目录的共享 WebViewEnvironment。

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.instance, this.initialPage});

  final Instance instance;

  /// 登录后跳转的目标页面 id（**不带 `p-` 前缀**，如模块视窗 `ext-<id>`、
  /// 仪表盘 `dashboard`）。
  ///
  /// 由 Dashboard 前端全局 go(name) 完成（其内部按 `p-<name>` 查找页面）。
  /// 需等 dash.js 自动登录（authed）且模块视窗 DOM（登录后异步渲染）就绪，
  /// 脚本轮询等待后调用。
  final String? initialPage;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  InAppWebViewController? _controller;
  bool _loading = true;
  bool _pageJumped = false;
  String? _error;
  Timer? _loadingTimer;

  /// Windows 共享 WebView2 环境（多页面复用，进程级缓存）
  static WebViewEnvironment? _sharedEnv;

  /// 环境初始化已尝试（失败也继续，走默认路径 + 超时兜底）
  bool _envAttempted = false;

  /// 重试用：递增使 WebView 整体重建
  int _webKey = 0;

  /// token 预注入脚本：文档创建时（页面 JS 之前）写入 localStorage，
  /// dash.js 启动即可读到并自动登录（无需加载后注入 + reload）。
  UnmodifiableListView<UserScript> get _tokenScripts {
    final token = widget.instance.token;
    if (token.isEmpty) {
      return UnmodifiableListView(const <UserScript>[]);
    }
    return UnmodifiableListView([
      UserScript(
        source:
            'try{if(location.origin===${jsonEncode(widget.instance.baseUrl.origin)})'
            '{localStorage.setItem("__ep_tk__",${jsonEncode(token)});}}catch(e){}',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    ]);
  }

  @override
  void initState() {
    super.initState();
    // Windows：显式指定可写的 user data folder 后再创建 WebView，
    // 避免 setup.exe 安装到 Program Files（只读）导致环境创建失败
    if (Platform.isWindows) unawaited(_ensureWebViewEnv());
  }

  /// WebView2 默认把 user data folder 放在 exe 同目录；安装到
  /// Program Files 后该目录不可写，环境创建失败表现为页面永久转圈。
  /// 显式指定到应用数据目录（%APPDATA%）规避。
  Future<void> _ensureWebViewEnv() async {
    if (_sharedEnv != null) {
      if (mounted) setState(() => _envAttempted = true);
      return;
    }
    try {
      final dir = await getApplicationSupportDirectory();
      _sharedEnv = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(
          userDataFolder: '${dir.path}${Platform.pathSeparator}WebView2',
        ),
      );
    } catch (_) {
      // 创建失败保持 null：走默认路径，由加载超时兜底提示
    }
    if (mounted) setState(() => _envAttempted = true);
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyToken() async {
    await Clipboard.setData(ClipboardData(text: widget.instance.token));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).dashboardAccessKeyCopied),
        ),
      );
    }
  }

  Future<void> _openExternal() async {
    final ok = await launchUrl(
      widget.instance.dashboardUri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).dashboardExternalFailed),
        ),
      );
    }
  }

  /// 加载完成且来源为本实例时，跳转到 [DashboardPage.initialPage]。
  ///
  /// go(name) 要求：全局 `authed === true`（自动登录完成）且页面 DOM
  /// `p-<name>` 存在（模块视窗由 loadModuleViews 在登录后异步渲染）。
  /// 过早调用会被 authed 门槛拦下或激活不存在的页面导致空白，因此脚本
  /// 轮询两个条件都就绪再 go，最多重试 20 秒。
  void _maybeJumpToPage(InAppWebViewController controller, WebUri? url) {
    final page = widget.initialPage;
    if (_pageJumped || page == null) return;
    final origin = Uri.tryParse(url?.toString() ?? '');
    if (origin == null || origin.origin != widget.instance.baseUrl.origin) {
      return;
    }
    _pageJumped = true;
    final jsPage = jsonEncode(page);
    controller.evaluateJavascript(
      source: '''
      (function() {
        var target = $jsPage, n = 0;
        function t() {
          var ready = typeof go === 'function' &&
              typeof authed !== 'undefined' && authed &&
              document.getElementById('p-' + target);
          if (ready) {
            go(target);
          } else if (n++ < 80) {
            setTimeout(t, 250);
          }
        }
        t();
      })();
      ''',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.instance.name} · Dashboard',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton.icon(
            onPressed: _copyToken,
            icon: const Icon(Icons.key, size: 18),
            label: Text(l10n.dashboardAccessKey),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
            onPressed: () => _controller?.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: l10n.dashboardExternalOpen,
            onPressed: _openExternal,
          ),
        ],
      ),
      body: _error != null
          ? _buildError()
          // Windows：等待可写的 WebView2 环境就绪（避免默认只读目录卡死）
          : Platform.isWindows && !_envAttempted
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    InAppWebView(
                      key: ValueKey(_webKey),
                      webViewEnvironment: _sharedEnv,
                      initialUrlRequest: URLRequest(
                        url: WebUri.uri(widget.instance.dashboardUri),
                      ),
                      initialUserScripts: _tokenScripts,
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        transparentBackground: true,
                      ),
                      onWebViewCreated: (controller) =>
                          _controller = controller,
                      onLoadStart: (controller, url) {
                        if (!mounted) return;
                        setState(() => _loading = true);
                        _loadingTimer?.cancel();
                        _loadingTimer = Timer(const Duration(seconds: 8), () {
                          if (!mounted) return;
                          // 超时仍未完成加载：显式报错（含重试），
                          // 避免白屏/永久转圈无反馈
                          if (_loading) {
                            setState(() {
                              _loading = false;
                              _error = AppLocalizations.of(context)
                                  .dashboardLoadTimeout;
                            });
                          }
                        });
                      },
                      onLoadStop: (controller, url) {
                        _loadingTimer?.cancel();
                        if (mounted) setState(() => _loading = false);
                        _maybeJumpToPage(controller, url);
                      },
                      onReceivedError: (controller, request, error) {
                        if (!mounted) return;
                        setState(() {
                          _error = error.description.isNotEmpty
                              ? error.description
                              : 'Load error: ${error.type.toString()}';
                        });
                      },
                    ),
                    if (_loading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).dashboardCheckHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // 整体重建 WebView（环境此时已就绪），而非仅 reload
                setState(() {
                  _error = null;
                  _loading = true;
                  _pageJumped = false;
                  _webKey++;
                });
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
