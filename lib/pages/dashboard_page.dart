// Dashboard WebView 页：全屏内嵌实例的 Dashboard 管理界面。
//
// 使用 flutter_inappwebview 实现跨平台内嵌（Android/iOS/macOS WKWebView、
// Windows WebView2、Linux WebKitGTK）。本地实例加载
// http://127.0.0.1:<port>/Dashboard，远程实例加载其 remoteUrl/Dashboard。
// AppBar 提供"复制令牌 / 刷新 / 在外部浏览器打开"。

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
  String? _error;

  Future<void> _copyToken() async {
    await Clipboard.setData(ClipboardData(text: widget.instance.token));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).dashboardTokenCopied),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.instance.name} · Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: l10n.dashboardCopyTokenTooltip,
            onPressed: _copyToken,
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
                    transparentBackground: true,
                  ),
                  onWebViewCreated: (controller) => _controller = controller,
                  onLoadStart: (controller, url) {
                    if (mounted) setState(() => _loading = true);
                  },
                  onLoadStop: (controller, url) {
                    if (mounted) setState(() => _loading = false);
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
