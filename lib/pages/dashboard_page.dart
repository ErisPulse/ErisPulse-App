// Dashboard WebView 页：全屏内嵌实例的 Dashboard 管理界面。
//
// 使用 flutter_inappwebview 实现跨平台内嵌（Android/iOS/macOS WKWebView、
// Windows WebView2、Linux WebKitGTK）。本地实例加载
// http://127.0.0.1:<port>/Dashboard，远程实例加载其 remoteUrl/Dashboard。
//
// 访问密钥：进入页面后自动把实例 token 写入 Dashboard 前端的
// localStorage（key `__ep_tk__`，dash.js 启动时读取并 POST /api/auth 验证），
// 实现免手动登录；AppBar 提供可见的"访问密钥"复制按钮 / 刷新 / 外部浏览器。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';

class DashboardPage extends StatefulWidget {
  final Instance instance;
  const DashboardPage({super.key, required this.instance});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  InAppWebViewController? _controller;
  bool _loading = true;
  bool _tokenInjected = false;
  String? _error;
  Timer? _loadingTimer;

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

  /// 首次加载完成后把访问密钥写入 Dashboard 前端（localStorage `__ep_tk__`），
  /// 再由 App 侧 reload（避免 JS location.reload 的 onLoadStop 事件链不一致
  /// 导致 loading 卡住）。刷新后 dash.js 自动登录，免手动输入。
  void _maybeInjectToken(InAppWebViewController controller, WebUri? url) {
    if (_tokenInjected) return;
    final token = widget.instance.token;
    if (token.isEmpty) return;
    // 仅注入到本实例 Dashboard 页面（按 origin 匹配），避免向第三方页面写入凭据
    final page = Uri.tryParse(url?.toString() ?? '');
    final base = widget.instance.baseUrl;
    if (page == null || page.origin != base.origin) return;
    _tokenInjected = true;
    final jsToken = jsonEncode(token);
    controller.evaluateJavascript(
      source: '''
      (function() {
        try {
          if (localStorage.getItem("__ep_tk__") !== $jsToken) {
            localStorage.setItem("__ep_tk__", $jsToken);
          }
        } catch (e) {}
      })();
      ''',
    ).then((_) {
      // 注入完成后 App 侧 reload，页面带上 token 自动登录
      if (mounted) controller.reload();
    });
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
          : Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri.uri(widget.instance.dashboardUri),
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    transparentBackground: true,
                  ),
                  onWebViewCreated: (controller) => _controller = controller,
                  onLoadStart: (controller, url) {
                    if (!mounted) return;
                    // token 注入后的刷新不再显示转圈；首次加载显示并加超时兜底
                    if (!_tokenInjected) {
                      setState(() => _loading = true);
                      _loadingTimer?.cancel();
                      _loadingTimer = Timer(const Duration(seconds: 8), () {
                        if (mounted) setState(() => _loading = false);
                      });
                    }
                  },
                  onLoadStop: (controller, url) {
                    _loadingTimer?.cancel();
                    if (mounted) setState(() => _loading = false);
                    _maybeInjectToken(controller, url);
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
                if (_loading) const Center(child: CircularProgressIndicator()),
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
                setState(() => _error = null);
                _controller?.reload();
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
