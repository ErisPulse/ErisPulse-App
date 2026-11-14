// 集群管理视图（详情页"cluster"注册视图）：/api/cluster/nodes。
// 节点列表（在线/延迟/版本）+ ping + 删除 + 添加节点。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

class InstanceClusterView extends StatefulWidget {
  final Instance instance;
  const InstanceClusterView({super.key, required this.instance});

  @override
  State<InstanceClusterView> createState() => _InstanceClusterViewState();
}

class _InstanceClusterViewState extends State<InstanceClusterView>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _nodes = [];
  bool _loading = true;
  bool _unsupported = false;
  String? _error;
  final Set<String> _pinging = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await DashboardApi(widget.instance).clusterNodes();
      if (!mounted) return;
      setState(() {
        _nodes = [
          for (final n in (json['nodes'] as List? ?? []))
            if (n is Map<String, dynamic>) n,
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

  Future<void> _ping(String nodeId) async {
    setState(() => _pinging.add(nodeId));
    try {
      await DashboardApi(widget.instance).clusterPingNode(nodeId);
    } catch (_) {}
    if (mounted) {
      setState(() => _pinging.remove(nodeId));
      await _load();
    }
  }

  Future<void> _remove(String nodeId) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clusterRemove),
        content: Text(nodeId),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DashboardApi(widget.instance).clusterDeleteNode(nodeId);
    } catch (_) {}
    await _load();
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final tokenCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.clusterAddNode),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l10n.clusterName),
                autofocus: true,
              ),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  labelText: l10n.clusterUrl,
                  hintText: 'http://192.168.1.10:8000',
                ),
              ),
              TextField(
                controller: tokenCtrl,
                decoration: InputDecoration(labelText: l10n.clusterToken),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final url = urlCtrl.text.trim();
              final token = tokenCtrl.text.trim();
              if (name.isEmpty || url.isEmpty || token.isEmpty) return;
              try {
                await DashboardApi(widget.instance)
                    .clusterAddNode(name: name, url: url, token: token);
              } catch (_) {}
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              await _load();
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
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
                l10n.clusterTitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add),
                tooltip: l10n.clusterAddNode,
                onPressed: _add,
              ),
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
    if (_nodes.isEmpty) {
      return EmptyState(icon: Icons.hub_outlined, title: l10n.detailNoEvents);
    }
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _nodes.length,
      itemBuilder: (context, i) {
        final n = _nodes[i];
        final id = n['id']?.toString() ?? '';
        final online = n['online'] == true;
        final enabled = n['enabled'] != false;
        return ListTile(
          dense: true,
          leading: Icon(
            online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: online ? Colors.green : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(n['name']?.toString() ?? id),
          subtitle: Text(
            [
              n['url']?.toString() ?? '',
              if (n['latency_ms'] != null) '${n['latency_ms']}ms',
              if (n['dashboard_version'] != null) 'v${n['dashboard_version']}',
              if (!enabled) 'disabled',
            ].where((s) => s.isNotEmpty).join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pinging.contains(id)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.speed_outlined, size: 20),
                      tooltip: l10n.clusterPing,
                      onPressed: () => _ping(id),
                    ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: l10n.clusterRemove,
                onPressed: () => _remove(id),
              ),
            ],
          ),
        );
      },
    );
  }
}
