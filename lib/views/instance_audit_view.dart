// 实例审计日志视图（详情页"审计"注册视图）。
//
// 原生替代 Dashboard 前端 audit-log 页：展示 `/api/audit` 返回的审计记录
// （timestamp / action / detail / ip），支持清空。
// 审计记录由后端 `_add_audit_log` 写入，覆盖鉴权 / 配置 / 模块等关键操作。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

/// 审计日志视图
class InstanceAuditView extends StatefulWidget {
  final Instance instance;
  const InstanceAuditView({super.key, required this.instance});

  @override
  State<InstanceAuditView> createState() => _InstanceAuditViewState();
}

class _InstanceAuditViewState extends State<InstanceAuditView>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final logs = await DashboardApi(widget.instance).getAuditLog(limit: 200);
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _clear() async {
    try {
      await DashboardApi(widget.instance).clearAuditLog();
      await _load();
    } catch (_) {}
  }

  static String _time(Map<String, dynamic> e) {
    final t = e['timestamp'];
    if (t is num) {
      final dt =
          DateTime.fromMillisecondsSinceEpoch(t.toInt() * 1000).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
    }
    return t?.toString() ?? '';
  }

  static String _action(Map<String, dynamic> e) =>
      e['action']?.toString() ?? '';
  static String _detail(Map<String, dynamic> e) =>
      e['detail']?.toString() ?? '';
  static String _ip(Map<String, dynamic> e) => e['ip']?.toString() ?? '';

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
                l10n.auditTitle,
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
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: l10n.commonClear,
                onPressed: _clear,
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
    final theme = Theme.of(context);
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_loading) {
      return const LoadingView();
    }
    if (_logs.isEmpty) {
      return EmptyState(
        icon: Icons.fact_check_outlined,
        title: l10n.auditEmpty,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _logs.length,
      itemBuilder: (context, i) {
        final e = _logs[i];
        final time = _time(e);
        final action = _action(e);
        final detail = _detail(e);
        final ip = _ip(e);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 118,
                child: Text(
                  time,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  action,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (detail.isNotEmpty)
                      Text(detail, style: theme.textTheme.bodySmall),
                    if (ip.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        ip,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
