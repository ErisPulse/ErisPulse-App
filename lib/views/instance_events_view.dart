// 实例事件流视图（详情页"事件流"注册视图）。
//
// 原生替代 Dashboard 前端 event-stream 页：轮询 Dashboard `/api/events`
// 实时展示事件，支持按事件类型过滤、自动刷新、清空。
// 事件字段解析与概览页事件卡一致（time / type / message 及平台/账号组合）。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/adapter_info.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

/// 事件流视图模式：查看 / 构建
enum _EventsMode { view, builder }

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

  /// 当前模式（构建器模式暂停自动轮询）
  _EventsMode _mode = _EventsMode.view;

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
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_mode == _EventsMode.view) _load();
    });
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: SegmentedButton<_EventsMode>(
            segments: [
              ButtonSegment(
                value: _EventsMode.view,
                label: Text(l10n.eventsBuilderView),
                icon: const Icon(Icons.list_outlined, size: 16),
              ),
              ButtonSegment(
                value: _EventsMode.builder,
                label: Text(l10n.eventsBuilderTab),
                icon: const Icon(Icons.build_outlined, size: 16),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _mode == _EventsMode.view
              ? _buildView(context, l10n)
              : _EventBuilder(instance: widget.instance),
        ),
      ],
    );
  }

  /// 查看模式：工具栏 + 事件列表
  Widget _buildView(BuildContext context, AppLocalizations l10n) {
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

/// 事件构建器：可视化构造事件 JSON 并提交（对齐后端 builder/validate + submit）。
/// 事件类型 / 详情类型表与后端 `_api_builder_validate` 的 EVENT_TYPES 一致。
const Map<String, Map<String, dynamic>> _eventTypes = {
  'message': {
    'detail_types': ['private', 'group', 'channel', 'guild', 'thread', 'user'],
  },
  'notice': {
    'detail_types': [
      'friend_increase',
      'friend_decrease',
      'group_member_increase',
      'group_member_decrease',
    ],
  },
  'request': {
    'detail_types': ['friend', 'group'],
  },
  'meta': {
    'detail_types': ['connect', 'disconnect', 'heartbeat'],
  },
};

/// 单个消息分段（type + 字段值）
class _Segment {
  String type;
  final Map<String, String> data = {};
  _Segment(this.type);
}

/// 附加字段（key/value）
class _OptionalField {
  String key = '';
  String value = '';
}

/// 事件构建器
class _EventBuilder extends StatefulWidget {
  final Instance instance;
  const _EventBuilder({required this.instance});

  @override
  State<_EventBuilder> createState() => _EventBuilderState();
}

class _EventBuilderState extends State<_EventBuilder> {
  String _type = 'message';
  String? _detailType;
  String? _platform;
  bool _useCustomPlatform = false;
  final TextEditingController _customPlatform = TextEditingController();
  String? _botId;
  String _sessionType = 'private';
  final TextEditingController _sessionId = TextEditingController();
  final List<_Segment> _segments = [_Segment('text')];
  final List<_OptionalField> _optional = [];

  List<String> _platforms = [];
  List<String> _bots = [];
  List<Map<String, dynamic>> _segmentTypes = [];
  bool _loadingMeta = true;
  String? _metaError;
  bool _submitting = false;
  String? _submitResult;
  bool _submitOk = false;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _customPlatform.dispose();
    _sessionId.dispose();
    super.dispose();
  }

  List<String> get _detailTypes =>
      (_eventTypes[_type]?['detail_types'] as List?)?.cast<String>() ?? [];

  Future<void> _loadMeta() async {
    final api = DashboardApi(widget.instance);
    try {
      final results = await Future.wait<Object?>([
        api.getAdapters(),
        api.getBots(),
        api.getBuilderSegments(),
      ]);
      final adapters = results[0] as List<AdapterInfo>;
      final bots = results[1] as List<Map<String, dynamic>>;
      final segs = results[2] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _platforms = [for (final a in adapters) a.platform];
        _bots = [
          for (final b in bots)
            if ((b['bot_id']?.toString() ?? '').isNotEmpty)
              b['bot_id']!.toString(),
        ];
        _segmentTypes = (segs['standard_segments'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        if (_platforms.isNotEmpty && _platform == null) {
          _platform = _platforms.first;
        }
        _loadingMeta = false;
        _metaError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMeta = false;
        _metaError = '$e';
      });
    }
  }

  /// 构建事件（对齐前端 buildEventData）
  Map<String, dynamic> _buildEvent() {
    final platform =
        _useCustomPlatform ? _customPlatform.text.trim() : (_platform ?? '');
    final botId = _botId ?? '';
    final event = <String, dynamic>{
      'id': 'builder_${DateTime.now().millisecondsSinceEpoch}',
      'time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'type': _type,
      'detail_type': _detailType ?? '',
      'platform': platform,
      'self': {'platform': platform, 'user_id': botId},
    };
    if (_type == 'message') {
      event['message'] = [
        for (final s in _segments)
          {'type': s.type, 'data': Map<String, dynamic>.from(s.data)},
      ];
    }
    for (final f in _optional) {
      final k = f.key.trim();
      final v = f.value.trim();
      if (k.isNotEmpty && v.isNotEmpty) event[k] = v;
    }
    final sessionId = _sessionId.text.trim();
    if (_sessionType == 'group') {
      if (sessionId.isNotEmpty) event['group_id'] = sessionId;
    } else if (_sessionType == 'channel') {
      if (sessionId.isNotEmpty) event['channel_id'] = sessionId;
    } else {
      event['user_id'] = sessionId.isNotEmpty
          ? sessionId
          : (botId.isNotEmpty ? botId : 'test_user');
    }
    if (_type == 'message') {
      final alt = (event['message'] as List)
          .map((s) => s as Map<String, dynamic>)
          .where(
            (s) =>
                s['type'] == 'text' &&
                s['data'] is Map &&
                (s['data'] as Map<String, dynamic>)['text'] is String,
          )
          .map(
            (s) => (s['data'] as Map<String, dynamic>)['text'] as String,
          )
          .join();
      event['alt_message'] = alt.isNotEmpty ? alt : '[test message]';
    }
    return event;
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _submitResult = null;
    });
    try {
      final result =
          await DashboardApi(widget.instance).submitBuilderEvent(_buildEvent());
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final ok = result['success'] == true;
      final msg = ok
          ? l10n.eventsBuilderSubmitted
          : (result['error']?.toString() ??
              ((result['errors'] as List?)?.join('\n') ??
                  l10n.eventsBuilderFailed));
      setState(() {
        _submitting = false;
        _submitResult = msg;
        _submitOk = ok;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitResult = '$e';
        _submitOk = false;
      });
    }
  }

  Future<void> _copyJson() async {
    await Clipboard.setData(ClipboardData(text: jsonEncode(_buildEvent())));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).eventsBuilderCopied),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final detailTypes = _detailTypes;
    final effectiveDetail =
        detailTypes.contains(_detailType) ? _detailType : null;
    final preview = const JsonEncoder.withIndent('  ').convert(_buildEvent());
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_metaError != null)
          ErrorView(message: _metaError!, onRetry: _loadMeta)
        else if (_loadingMeta)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else ...[
          _FieldLabel(l10n.eventsBuilderType),
          Wrap(
            spacing: 6,
            children: [
              for (final t in _eventTypes.keys)
                ChoiceChip(
                  label: Text(t),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  selected: _type == t,
                  onSelected: (_) => setState(() {
                    _type = t;
                    _detailType = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (detailTypes.isNotEmpty) ...[
            _FieldLabel(l10n.eventsBuilderDetailType),
            DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: effectiveDetail,
                isExpanded: true,
                hint: Text(l10n.eventsBuilderDetailType),
                items: [
                  for (final d in detailTypes)
                    DropdownMenuItem(value: d, child: Text(d)),
                ],
                onChanged: (v) => setState(() => _detailType = v),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _FieldLabel(l10n.eventsBuilderPlatform),
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _useCustomPlatform ? null : _platform,
                    isExpanded: true,
                    hint: Text(
                      _useCustomPlatform
                          ? l10n.eventsBuilderCustom
                          : l10n.eventsBuilderPlatform,
                    ),
                    items: [
                      for (final p in _platforms)
                        DropdownMenuItem(value: p, child: Text(p)),
                    ],
                    onChanged: _useCustomPlatform
                        ? null
                        : (v) => setState(() => _platform = v),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.eventsBuilderCustom,
                icon: Icon(
                  _useCustomPlatform
                      ? Icons.edit_off_outlined
                      : Icons.edit_outlined,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _useCustomPlatform = !_useCustomPlatform),
              ),
            ],
          ),
          if (_useCustomPlatform)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextField(
                controller: _customPlatform,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.eventsBuilderCustom,
                ),
              ),
            ),
          const SizedBox(height: 12),
          _FieldLabel(l10n.eventsBuilderBot),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _botId,
              isExpanded: true,
              hint: Text(l10n.eventsBuilderBot),
              items: [
                for (final b in _bots)
                  DropdownMenuItem(
                    value: b,
                    child: Text(b, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _botId = v),
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel(l10n.eventsBuilderSessionType),
          Row(
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sessionType,
                  items: const [
                    DropdownMenuItem(value: 'private', child: Text('private')),
                    DropdownMenuItem(value: 'group', child: Text('group')),
                    DropdownMenuItem(value: 'channel', child: Text('channel')),
                  ],
                  onChanged: (v) => setState(() => _sessionType = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _sessionId,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.eventsBuilderSessionId,
                  ),
                ),
              ),
            ],
          ),
          if (_type == 'message') ...[
            const SizedBox(height: 12),
            _FieldLabel(l10n.eventsBuilderSegments),
            for (var i = 0; i < _segments.length; i++)
              _SegmentEditor(
                key: ObjectKey(_segments[i]),
                segment: _segments[i],
                types: _segmentTypes,
                onRemove: _segments.length > 1
                    ? () => setState(() => _segments.removeAt(i))
                    : null,
              ),
            TextButton.icon(
              onPressed: () => setState(() => _segments.add(_Segment('text'))),
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.eventsBuilderAddSegment),
            ),
          ],
          const SizedBox(height: 12),
          _FieldLabel(l10n.eventsBuilderOptional),
          for (var i = 0; i < _optional.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => _optional[i].key = v,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'key',
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => _optional[i].value = v,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'value',
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _optional.removeAt(i)),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: () => setState(() => _optional.add(_OptionalField())),
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.eventsBuilderAddField),
          ),
          const Divider(height: 24),
          _FieldLabel(l10n.eventsBuilderPreview),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              preview,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _copyJson,
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: Text(l10n.eventsBuilderCopyJson),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined, size: 16),
                label: Text(l10n.eventsBuilderSubmit),
              ),
            ],
          ),
          if (_submitResult != null) ...[
            const SizedBox(height: 10),
            Text(
              _submitResult!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _submitOk ? Colors.green : theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// 构建器字段标签
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 单个消息分段编辑器（类型下拉 + 该类型字段输入）
class _SegmentEditor extends StatefulWidget {
  final _Segment segment;
  final List<Map<String, dynamic>> types;
  final VoidCallback? onRemove;
  const _SegmentEditor({
    super.key,
    required this.segment,
    required this.types,
    this.onRemove,
  });

  @override
  State<_SegmentEditor> createState() => _SegmentEditorState();
}

class _SegmentEditorState extends State<_SegmentEditor> {
  final Map<String, TextEditingController> _controllers = {};

  List<Map<String, dynamic>> _fieldsFor(String type) {
    for (final t in widget.types) {
      if (t['type'] == type) {
        return (t['fields'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    }
    return const [];
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fields = _fieldsFor(widget.segment.type);
    for (final f in fields) {
      final name = f['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      if (!_controllers.containsKey(name)) {
        final c = TextEditingController(text: widget.segment.data[name] ?? '');
        c.addListener(() => widget.segment.data[name] = c.text);
        _controllers[name] = c;
      }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.segment.type,
                      isExpanded: true,
                      items: [
                        for (final t in widget.types)
                          DropdownMenuItem(
                            value: t['type'] as String,
                            child: Text(
                              t['name']?.toString() ?? (t['type'] as String),
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        for (final c in _controllers.values) {
                          c.dispose();
                        }
                        _controllers.clear();
                        widget.segment.data.clear();
                        setState(() => widget.segment.type = v);
                      },
                    ),
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            if (fields.isNotEmpty) ...[
              const SizedBox(height: 6),
              for (final f in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextField(
                    controller: _controllers[f['name']?.toString()],
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: f['name']?.toString(),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
