// 连接注册表视图（详情页"connections"注册视图）：/api/connections。
// 连接列表（类型/命名空间/地址）+ 概览统计 + 断开连接。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

class InstanceConnectionsView extends StatefulWidget {
  final Instance instance;
  const InstanceConnectionsView({super.key, required this.instance});

  @override
  State<InstanceConnectionsView> createState() =>
      _InstanceConnectionsViewState();
}

class _InstanceConnectionsViewState extends State<InstanceConnectionsView>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _unsupported = false;
  String? _error;
  String? _closingId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await DashboardApi(widget.instance).getConnections();
      if (!mounted) return;
      setState(() {
        _data = json;
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

  Future<void> _close(String id) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonConfirm),
        content: Text(id),
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
    setState(() => _closingId = id);
    try {
      await DashboardApi(widget.instance).closeConnection(id);
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _closingId = null);
  }

  List<Map<String, dynamic>> _connections() {
    final data = _data;
    if (data == null) return const [];
    final out = <Map<String, dynamic>>[];
    data.forEach((key, value) {
      if (value is List) {
        for (final c in value) {
          if (c is Map<String, dynamic>) {
            out.add({...c, 'group': key});
          }
        }
      }
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Text(
                'Connections',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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

    final conns = _connections();
    if (conns.isEmpty) {
      return EmptyState(
        icon: Icons.link_off_outlined,
        title: l10n.detailTabEmpty,
      );
    }
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: conns.length,
      itemBuilder: (context, i) {
        final c = conns[i];
        final id = (c['id'] ?? c['conn_id'] ?? '').toString();
        return ListTile(
          dense: true,
          leading: Icon(
            Icons.link_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            '${c['namespace'] ?? c['group'] ?? ''} · ${c['remote'] ?? c['addr'] ?? id}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          ),
          subtitle: Text(
            '${c['group'] ?? ''} · ${c['kind'] ?? c['type'] ?? ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: _closingId == id
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.link_off, size: 20),
                  tooltip: l10n.commonClose,
                  onPressed: id.isEmpty ? null : () => _close(id),
                ),
        );
      },
    );
  }
}
