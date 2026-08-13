// Dashboard WebView 页：全屏内嵌实例的 Dashboard 管理界面。
//
// 本地实例加载 http://127.0.0.1:<port>/Dashboard，远程实例加载其
// remoteUrl/Dashboard。Dashboard 自带全部管理能力（适配器/模块/配置/
// 日志/文件/包管理），App 只需把它套进 WebView 即可。
//
// 认证：Dashboard 首次打开需要输入访问令牌（token）。AppBar 提供
// "复制令牌"按钮，用户粘贴一次后 Dashboard 会在 WebView 的 localStorage
// 中记住，后续自动登录。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';

class DashboardPage extends StatefulWidget {
  final Instance instance;
  const DashboardPage({super.key, required this.instance});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.grey.shade900)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            if (!mounted) return;
            setState(() {
              _error = err.description.isEmpty
                  ? AppLocalizations.of(context)
                      .dashboardLoadFailed(err.errorCode)
                  : err.description;
            });
          },
        ),
      )
      ..loadRequest(widget.instance.dashboardUri);
  }

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
            onPressed: () => _controller.reload(),
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
                WebViewWidget(controller: _controller),
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
                _controller.reload();
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
