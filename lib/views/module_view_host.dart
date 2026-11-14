// 模块视图兼容宿主：按 Dashboard 视窗契约在 App 内渲染模块视图。
//
// 宿主 = 实例的真实 Dashboard 页面（完整前端环境：localStorage / go() /
// i18n / WS / CSS 全部原生可用），onLoadStop 后注入聚焦脚本：隐藏侧栏与
// 顶栏、go() 导航到目标 ext-<id> 页。iframe_url 型原样 iframe + token。
//
// 兼容性说明：模块 JS 面向 Dashboard 全页编写，裸 loadData 文档是 opaque
// origin（localStorage 拒绝访问）且缺 Dashboard DOM，故必须加载真实页面。

import 'dart:async';
import 'dart:convert';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../models/instance.dart';
import '../services/webview_env.dart';

class ModuleViewHost extends StatefulWidget {
  const ModuleViewHost({super.key, required this.instance, required this.view});

  final Instance instance;
  final Map<String, dynamic> view;

  @override
  State<ModuleViewHost> createState() => _ModuleViewHostState();
}

class _ModuleViewHostState extends State<ModuleViewHost> {
  // 二分定位开关：--dart-define=EP_HOST_INJECT=false 可关闭聚焦注入
  static const bool _enableInject = bool.fromEnvironment(
    'EP_HOST_INJECT',
    defaultValue: true,
  );

  double _progress = 0;
  bool _focused = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Windows：等共享环境就绪后再建 WebView（userDataFolder 全局唯一）
    unawaited(
      WebViewEnv.ensure().then((_) {
        if (mounted) setState(() {});
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iframeUrl = widget.view['iframe_url']?.toString() ?? '';
    if (iframeUrl.isNotEmpty) {
      return _buildIframe(iframeUrl);
    }
    // Windows：环境未就绪时不建 WebView，避免使用默认（只读）userDataFolder
    if (defaultTargetPlatform == TargetPlatform.windows &&
        !WebViewEnv.attempted) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        _buildDashboardWeb(),
        if (_progress < 1)
          LinearProgressIndicator(value: _progress, minHeight: 2),
        if (_error != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(10),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDashboardWeb() {
    final instance = widget.instance;
    return InAppWebView(
      webViewEnvironment: defaultTargetPlatform == TargetPlatform.windows
          ? WebViewEnv.instance
          : null,
      initialUrlRequest: URLRequest(
        url: WebUri(instance.baseUrl.replace(path: '/Dashboard/').toString()),
      ),
      initialUserScripts: UnmodifiableListView([
        UserScript(
          source:
              'try{if(location.origin===${jsonEncode(instance.baseUrl.origin)}){'
              'localStorage.setItem("__ep_tk__",${jsonEncode(instance.token)});'
              "localStorage.setItem('ep_onboarding_done','1');"
              "localStorage.setItem('ep_setup_done','1');}}catch(e){}",
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ]),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        transparentBackground: true,
      ),
      onReceivedError: (controller, request, error) {
        if (mounted) {
          setState(() => _error = error.description);
        }
      },
      onLoadStop: (controller, url) => unawaited(_injectFocus(controller)),
      onProgressChanged: (_, p) => setState(() => _progress = p / 100),
    );
  }

  /// 注入聚焦脚本：等 Dashboard 前端完成 auth/DOM 渲染后隐藏侧栏/顶栏，
  /// go() 导航到目标 ext 页面。轮询上限 10s。
  Future<void> _injectFocus(InAppWebViewController controller) async {
    if (_focused || !_enableInject) return;
    final pageId = 'ext-${widget.view['id'] ?? ''}';
    final idJson = jsonEncode(pageId);
    await controller.evaluateJavascript(
      source: '''
(function(){
  if (window.__epHostFocus) return;
  window.__epHostFocus = true;
  var pid = $idJson;
  var tries = 0;
  var t = setInterval(function(){
    tries++;
    try {
      var page = document.getElementById('p-' + pid);
      if (typeof go !== 'function' || !page) return;
      // Dashboard 启动默认页可能晚于本脚本执行 go：跳转后需复核可见性
      var sb = document.querySelector('.sidebar');
      if (sb) sb.style.setProperty('display', 'none');
      var hd = document.querySelector('.header');
      if (hd) hd.style.setProperty('display', 'none');
      var hb = document.querySelector('.btn-hamburger');
      if (hb) hb.style.setProperty('display', 'none');
      document.querySelectorAll('.page').forEach(function(p){
        if (p.id !== 'p-' + pid) p.style.setProperty('display', 'none');
      });
      page.style.setProperty('display', 'block');
      go(pid);
      if (page.offsetParent !== null) clearInterval(t);
    } catch (e) {
      // 聚焦失败静默：不影响页面自身运行
    }
    if (tries > 60) {
      clearInterval(t);
    }
  }, 250);
})();
''',
    );
    if (mounted) setState(() => _focused = true);
  }

  Widget _buildIframe(String iframeUrl) {
    final base = widget.instance.baseUrl;
    final Uri target;
    if (iframeUrl.startsWith('http://') || iframeUrl.startsWith('https://')) {
      target = Uri.parse(iframeUrl);
    } else {
      final path = iframeUrl.startsWith('/') ? iframeUrl : '/$iframeUrl';
      target = base.replace(path: path);
    }
    final sep = target.query.isEmpty ? '?' : '&';
    return InAppWebView(
      webViewEnvironment: defaultTargetPlatform == TargetPlatform.windows
          ? WebViewEnv.instance
          : null,
      initialUrlRequest: URLRequest(
        url: WebUri(
          '$target${sep}token=${Uri.encodeComponent(widget.instance.token)}',
        ),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        supportZoom: true,
      ),
    );
  }
}
