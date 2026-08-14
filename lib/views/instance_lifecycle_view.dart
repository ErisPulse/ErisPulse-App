// 实例生命周期时间轴视图（详情页"生命周期"注册视图）。
//
// 原生替代 Dashboard 前端 monitor 页的生命周期 tab：展示 `/api/lifecycle`
// 返回的生命周期事件（event / timestamp / data / source / msg），
// 支持按事件主类型过滤与清空。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

/// 生命周期时间轴视图
class InstanceLifecycleView extends StatefulWidget {
  final Instance instance;
  const InstanceLifecycleView({super.key, required this.instance});

  @override
  State<InstanceLifecycleView> createState() => _InstanceLifecycleViewState();
}

class _InstanceLifecycleViewState extends State<InstanceLifecycleView>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String? _error;

  /// 事件主类型过滤（null = 全部，取 `event` 第一段如 module / adapter）
  String? _filter;

  /// 已出现的事件主类型
  final List<String> _types = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final logs = await DashboardApi(widget.instance).getLifecycle();
      if (!mounted) return;
      final types = <String>[];
      for (final e in logs) {
        final t = _type(e);
        if (t.isNotEmpty && !types.contains(t)) types.add(t);
      }
      setState(() {
        _logs = logs;
        _types
          ..clear()
          ..addAll(types);
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
      await DashboardApi(widget.instance).clearLifecycle();
      await _load();
    } catch (_) {}
  }

  /// 事件主类型（event 字段第一段，如 module.load -> module）
  static String _type(Map<String, dynamic> e) {
    final s = e['event']?.toString() ?? '';
    final dot = s.indexOf('.');
    return dot > 0 ? s.substring(0, dot) : s;
  }

  static String _event(Map<String, dynamic> e) => e['event']?.toString() ?? '';
  static String _msg(Map<String, dynamic> e) => e['msg']?.toString() ?? '';
  static String _source(Map<String, dynamic> e) =>
      e['source']?.toString() ?? '';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final visible = _filter == null
        ? _logs
        : _logs.where((e) => _type(e) == _filter).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _filter,
                  hint: Text(
                    l10n.lifecycleFilterType,
                    style: theme.textTheme.labelSmall,
                  ),
                  isDense: true,
                  borderRadius: BorderRadius.circular(8),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        l10n.logsFilterAll,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    for (final t in _types)
                      DropdownMenuItem<String?>(
                        value: t,
                        child: Text(t, style: theme.textTheme.labelSmall),
                      ),
                  ],
                  onChanged: (v) => setState(() => _filter = v),
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
        Expanded(child: _buildBody(visible, l10n)),
      ],
    );
  }

  Widget _buildBody(
    List<Map<String, dynamic>> logs,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_loading) {
      return const LoadingView();
    }
    if (logs.isEmpty) {
      return EmptyState(
        icon: Icons.timeline_outlined,
        title:
            _filter != null ? l10n.lifecycleFilteredEmpty : l10n.lifecycleEmpty,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: logs.length,
      itemBuilder: (context, i) {
        final e = logs[i];
        final event = _event(e);
        final msg = _msg(e);
        final source = _source(e);
        final time = _time(e);
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
                  event,
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
                    if (msg.isNotEmpty)
                      Text(msg, style: theme.textTheme.bodySmall),
                    if (source.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        source,
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
