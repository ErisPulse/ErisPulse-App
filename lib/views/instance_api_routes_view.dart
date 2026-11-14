// API 路由清单视图（详情页"api-routes"注册视图）：/api/routes。
// 按模块分组展示 HTTP / WS / SSE 路由（方法徽章 + 路径）。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

class InstanceApiRoutesView extends StatefulWidget {
  final Instance instance;
  const InstanceApiRoutesView({super.key, required this.instance});

  @override
  State<InstanceApiRoutesView> createState() => _InstanceApiRoutesViewState();
}

class _InstanceApiRoutesViewState extends State<InstanceApiRoutesView>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _http = [];
  List<Map<String, dynamic>> _ws = [];
  bool _loading = true;
  bool _unsupported = false;
  String? _error;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await DashboardApi(widget.instance).getRoutes();
      if (!mounted) return;
      setState(() {
        _http = [
          for (final r in (json['http_routes'] as List? ?? []))
            if (r is Map<String, dynamic>) r,
        ];
        _ws = [
          for (final r in (json['ws_routes'] as List? ?? []))
            if (r is Map<String, dynamic>) r,
        ];
        _unsupported = false;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _unsupported = e is ApiException && e.statusCode == 404;
        _error = _unsupported ? null : '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Text(
                l10n.apiRoutesTitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
                onPressed: _load,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildBody(l10n)),
      ],
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_unsupported) return UnsupportedView(onRetry: _load);
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_loading) return const LoadingView();

    final q = _query.trim().toLowerCase();
    final http = q.isEmpty
        ? _http
        : _http
            .where(
              (r) => '${r['path']}${r['module']}'.toLowerCase().contains(q),
            )
            .toList();
    final ws = q.isEmpty
        ? _ws
        : _ws
            .where(
              (r) => '${r['path']}${r['module']}'.toLowerCase().contains(q),
            )
            .toList();

    final byModule = <String, List<Map<String, dynamic>>>{};
    for (final r in http) {
      byModule.putIfAbsent(r['module']?.toString() ?? '-', () => []).add(r);
    }
    final modules = byModule.keys.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.logsSearch,
              prefixIcon: const Icon(Icons.search, size: 18),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            children: [
              for (final m in modules)
                ExpansionTile(
                  dense: true,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text('$m (${byModule[m]!.length})'),
                  children: [
                    for (final r in byModule[m]!)
                      ListTile(
                        dense: true,
                        leading: _methodBadge(r['method']?.toString() ?? 'GET'),
                        title: Text(
                          r['full_path']?.toString() ??
                              r['path']?.toString() ??
                              '',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                  ],
                ),
              if (ws.isNotEmpty)
                ExpansionTile(
                  dense: true,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text('WebSocket (${ws.length})'),
                  children: [
                    for (final r in ws)
                      ListTile(
                        dense: true,
                        leading: const _MethodBadge('WS'),
                        title: Text(
                          r['full_path']?.toString() ?? '',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                  ],
                ),
              if (modules.isEmpty && ws.isEmpty)
                EmptyState(
                  icon: Icons.route_outlined,
                  title: l10n.detailNoEvents,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _methodBadge(String method) => _MethodBadge(method);
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge(this.method);

  final String method;

  @override
  Widget build(BuildContext context) {
    final color = switch (method.toUpperCase()) {
      'GET' => Colors.green,
      'POST' => Colors.orange,
      'PUT' => Colors.blue,
      'DELETE' => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
