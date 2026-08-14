// 实例事件流视图（详情页"事件流"注册视图）。
//
// 原生替代 Dashboard 前端 event-stream 页：轮询 Dashboard `/api/events`
// 实时展示事件，支持按事件类型过滤、自动刷新、清空。
// 事件字段解析与概览页事件卡一致（time / type / message 及平台/账号组合）。

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

/// 事件流视图
class InstanceEventsView extends StatefulWidget {
  final Instance instance;
  const InstanceEventsView({super.key, required this.instance});

  @override
  State<InstanceEventsView> createState() => _InstanceEventsViewState();
}

class _InstanceEventsViewState extends State<InstanceEventsView>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;

  /// 已出现的事件类型（下拉过滤）
  final List<String> _types = [];

  /// 类型过滤（null = 全部）
  String? _typeFilter;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    // 事件流自动刷新（对齐前端 event-stream 轮询）
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final api = DashboardApi(widget.instance);
    try {
      final events = await api.getEvents(limit: 200);
      if (!mounted) return;
      final types = <String>[];
      for (final e in events) {
        final t = _type(e);
        if (t.isNotEmpty && !types.contains(t)) types.add(t);
      }
      setState(() {
        _events = events;
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
      await DashboardApi(widget.instance).clearEvents();
      await _load();
    } catch (_) {}
  }

  static String _time(Map<String, dynamic> e) {
    final t = e['time'] ?? e['timestamp'] ?? e['created_at'];
    if (t is num) {
      final dt =
          DateTime.fromMillisecondsSinceEpoch(t.toInt() * 1000).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
    }
    final s = t?.toString() ?? '';
    if (s.length >= 19) {
      final sub = s.substring(11, 19);
      if (sub.contains(':')) return sub;
    }
    return s;
  }

  static String _type(Map<String, dynamic> e) =>
      (e['type'] ?? e['event'] ?? 'event').toString();

  static String _message(Map<String, dynamic> e) {
    final m = e['message'] ?? e['detail'] ?? e['data'];
    if (m is String && m.isNotEmpty) return m;
    final parts = <String>[
      if (e['platform'] != null) e['platform'].toString(),
      if (e['detail_type'] != null) e['detail_type'].toString(),
      if (e['sub_type'] != null) e['sub_type'].toString(),
      if (e['self_id'] != null) e['self_id'].toString(),
      if (e['user_id'] != null) 'user=${e['user_id']}',
      if (e['group_id'] != null) 'group=${e['group_id']}',
    ];
    final alt = e['alt_message']?.toString();
    if (alt != null && alt.isNotEmpty) return alt;
    final joined = parts.where((p) => p.isNotEmpty).join(' · ');
    if (joined.isNotEmpty) return joined;
    if (m is Map || m is List) return m.toString();
    return e['type']?.toString() ?? 'event';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final visible = _typeFilter == null
        ? _events
        : _events.where((e) => _type(e) == _typeFilter).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // 类型过滤
              DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _typeFilter,
                  hint: Text(
                    l10n.eventsFilterType,
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
                  onChanged: (v) => setState(() => _typeFilter = v),
                ),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
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
        Expanded(
          child: _buildBody(visible, l10n),
        ),
      ],
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> events, AppLocalizations l10n) {
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (events.isEmpty) {
      return EmptyState(
        icon: Icons.event_note_outlined,
        title: _loading ? l10n.commonLoading : l10n.detailNoEvents,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: events.length,
      itemBuilder: (context, i) => _EventRow(event: events[i]),
    );
  }
}

/// 单条事件行
class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});
  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              _InstanceEventsViewState._time(event),
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
              _InstanceEventsViewState._type(event),
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _InstanceEventsViewState._message(event),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
