// 会话收件箱视图（详情页"transcript"注册视图）：/api/transcript/*。

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../utils/message_render.dart';
import '../widgets/states.dart';

class InstanceTranscriptView extends StatefulWidget {
  final Instance instance;
  const InstanceTranscriptView({super.key, required this.instance});

  @override
  State<InstanceTranscriptView> createState() => _InstanceTranscriptViewState();
}

class _InstanceTranscriptViewState extends State<InstanceTranscriptView>
    with AutomaticKeepAliveClientMixin {
  static const _hoursOptions = [24.0, 72.0, 168.0, 720.0];

  double _hours = 24;
  bool _supported = true;
  bool _loading = true;
  String? _error;
  bool _unsupported = false;
  List<Map<String, dynamic>> _sessions = [];

  String? _openSession;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await DashboardApi(widget.instance).transcriptInfo();
      if (!mounted) return;
      setState(() {
        _supported = info['supported'] == true;
        _unsupported = false;
        _loading = false;
      });
      if (_supported) unawaited(_loadSessions());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _unsupported = e is ApiException && e.statusCode == 404;
        _error = _unsupported ? null : '$e';
      });
    }
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await DashboardApi(
        widget.instance,
      ).transcriptSessions(_hours);
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
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
                l10n.transcriptTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final h in _hoursOptions)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(_hoursLabel(h)),
                            selected: _hours == h,
                            onSelected: (_) {
                              setState(() => _hours = h);
                              _loadSessions();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.tune),
                tooltip: l10n.transcriptRetention,
                onPressed: _showRetentionDialog,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
                onPressed: _loadSessions,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _openSession == null
              ? _buildSessions(l10n)
              : _SessionThread(
                  instance: widget.instance,
                  session: _openSession!,
                  onBack: () => setState(() => _openSession = null),
                ),
        ),
      ],
    );
  }

  static String _hoursLabel(double h) {
    if (h >= 168 && h % 168 == 0) return '${(h / 168).toInt()}d';
    if (h >= 24 && h % 24 == 0) return '${(h / 24).toInt()}d';
    return '${h.toInt()}h';
  }

  Widget _buildSessions(AppLocalizations l10n) {
    if (_unsupported) return UnsupportedView(onRetry: _loadInfo);
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadSessions);
    }
    if (_loading) return const LoadingView();
    if (!_supported) {
      return EmptyState(icon: Icons.inbox_outlined, title: l10n.commonLoading);
    }
    if (_sessions.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: l10n.transcriptEmpty,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _sessions.length,
      itemBuilder: (context, i) {
        final s = _sessions[i];
        return ListTile(
          dense: true,
          leading: Icon(
            _platformIcon(s['platform']?.toString()),
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            s['summary']?.toString() ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${s['platform'] ?? ''} · ${s['target_id'] ?? ''} · '
            '${s['count'] ?? 0} 条 · ${_sessionTime(s)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => setState(
            () => _openSession = s['session_key']?.toString(),
          ),
        );
      },
    );
  }

  static String _sessionTime(Map<String, dynamic> s) {
    final ts = s['last_ts'];
    if (ts is num) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        ts.toInt() * (ts < 1e12 ? 1000 : 1),
      ).toLocal();
      return '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    return ts?.toString() ?? '';
  }

  static IconData _platformIcon(String? platform) => switch (platform) {
        'qq' || 'onebot' => Icons.chat_bubble_outline,
        'telegram' => Icons.send_outlined,
        'discord' => Icons.forum_outlined,
        'kook' => Icons.graphic_eq,
        _ => Icons.device_hub,
      };

  Future<void> _showRetentionDialog() async {
    final l10n = AppLocalizations.of(context);
    final maxCtrl = TextEditingController();
    final ttlCtrl = TextEditingController();
    try {
      final ret = await DashboardApi(widget.instance).transcriptRetention();
      final data = ret['retention'];
      if (data is Map<String, dynamic>) {
        maxCtrl.text = '${data['max_per_session'] ?? ''}';
        ttlCtrl.text = '${data['ttl_hours'] ?? ''}';
      }
    } catch (_) {}
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.transcriptRetention),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: maxCtrl,
              decoration:
                  InputDecoration(labelText: l10n.transcriptMaxPerSession),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: ttlCtrl,
              decoration: InputDecoration(labelText: l10n.transcriptTtlHours),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final api = DashboardApi(widget.instance);
              try {
                await api.saveTranscriptRetention(
                  maxPerSession: int.tryParse(maxCtrl.text.trim()),
                  ttlHours: double.tryParse(ttlCtrl.text.trim()),
                );
              } catch (_) {}
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}

/// 单个会话的消息线程
class _SessionThread extends StatefulWidget {
  const _SessionThread({
    required this.instance,
    required this.session,
    required this.onBack,
  });

  final Instance instance;
  final String session;
  final VoidCallback onBack;

  @override
  State<_SessionThread> createState() => _SessionThreadState();
}

class _SessionThreadState extends State<_SessionThread> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await DashboardApi(
        widget.instance,
      ).transcriptMessages(widget.session, n: 200);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
            Expanded(
              child: Text(
                widget.session,
                style: theme.textTheme.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l10n.commonClear,
              onPressed: () async {
                try {
                  await DashboardApi(
                    widget.instance,
                  ).clearTranscript(widget.session);
                } catch (_) {}
                widget.onBack();
              },
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
              onPressed: _load,
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _messages.isEmpty
                      ? EmptyState(
                          icon: Icons.chat_outlined,
                          title: l10n.transcriptMsgEmpty,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) =>
                              _bubble(theme, _messages[i], l10n),
                        ),
        ),
      ],
    );
  }

  Widget _bubble(
    ThemeData theme,
    Map<String, dynamic> m,
    AppLocalizations l10n,
  ) {
    final role = m['role']?.toString() ?? '';
    final outbound = role == 'assistant' || role == 'bot' || role == 'out';
    final text = m['text']?.toString() ?? '';
    final parts = parseMessageParts(text);
    final sender = m['sender']?.toString() ?? '';
    final traceId =
        m['trace_id']?.toString() ?? m['event_id']?.toString() ?? '';
    return Align(
      alignment: outbound ? Alignment.centerRight : Alignment.centerLeft,
      child: InkWell(
        onTap: traceId.isEmpty ? null : () => _showDetail(m, traceId, l10n),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 460),
          decoration: BoxDecoration(
            color: outbound
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sender.isNotEmpty)
                Text(
                  sender,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (parts.isEmpty)
                Text('[media]', style: theme.textTheme.bodyMedium)
              else
                _PartsBody(parts: parts),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(
    Map<String, dynamic> m,
    String traceId,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(traceId),
        content: SingleChildScrollView(
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(m),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                final trace = await DashboardApi(
                  widget.instance,
                ).transcriptTrace(traceId);
                if (!mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (traceCtx) => AlertDialog(
                    title: Text(l10n.transcriptTitle),
                    content: SingleChildScrollView(
                      child: SelectableText(
                        const JsonEncoder.withIndent('  ').convert(trace),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(traceCtx),
                        child: Text(AppLocalizations.of(traceCtx).commonClose),
                      ),
                    ],
                  ),
                );
              } catch (_) {}
            },
            child: Text(l10n.transcriptTitle),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }
}

/// 消息部件序列渲染：文本行内混排 + 图片缩略图（点击大图）+ 占位徽章
class _PartsBody extends StatelessWidget {
  const _PartsBody({required this.parts});

  final List<MsgPart> parts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spans = <Widget>[];
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isNotEmpty) {
        spans.add(
          Text(buffer.toString(), style: theme.textTheme.bodyMedium),
        );
        buffer.clear();
      }
    }

    for (final part in parts) {
      switch (part) {
        case MsgText(:final text):
          buffer.write(text);
        case MsgAt(:final qq):
          buffer.write('@$qq ');
        case MsgPlaceholder(:final label):
          flush();
          spans.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '[$label]',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        case MsgLink(:final url, :final label):
          flush();
          spans.add(
            UrlText(url: url, label: label),
          );
        case MsgReply(:final quoted):
          flush();
          spans.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                quoted.isEmpty ? '回复' : '回复：$quoted',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        case MsgCard(:final title, :final desc):
          flush();
          spans.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                [if (title.isNotEmpty) title, if (desc.isNotEmpty) desc]
                    .join(' · '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          );
        case MsgImage():
          flush();
          spans.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _BubbleImage(part: part),
            ),
          );
      }
    }
    flush();

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: spans,
    );
  }
}

/// 图片部件：缩略图 + 点击查看大图
class _BubbleImage extends StatelessWidget {
  const _BubbleImage({required this.part});

  final MsgImage part;

  static Future<Uint8List> _decodeB64(String b64) async {
    try {
      return base64Decode(b64);
    } catch (_) {
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataUri = part.dataUri;
    final b64 = dataUri?.substring(dataUri.indexOf(',') + 1);
    Widget img;
    if (part.url != null) {
      img = Image.network(
        part.url!,
        width: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 180,
          height: 60,
          child: Center(child: Text('[图片]')),
        ),
      );
    } else {
      img = FutureBuilder<Uint8List>(
        future: () async {
          try {
            return base64Decode(b64 ?? '');
          } catch (_) {
            return Uint8List(0);
          }
        }(),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.isNotEmpty) {
            return Image.memory(
              snap.data!,
              width: 180,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 180,
                height: 60,
                child: Center(child: Text('[图片]')),
              ),
            );
          }
          if (snap.hasError || (snap.hasData && snap.data!.isEmpty)) {
            return const SizedBox(
              width: 180,
              height: 60,
              child: Center(child: Text('[图片]')),
            );
          }
          return const SizedBox(
            width: 180,
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
      );
    }
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog.fullscreen(
          child: InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: part.url != null
                  ? Image.network(part.url!)
                  : FutureBuilder<Uint8List>(
                      future: _decodeB64(b64 ?? ''),
                      builder: (context, snap) => snap.hasData
                          ? Image.memory(snap.data!)
                          : const CircularProgressIndicator(),
                    ),
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: img,
      ),
    );
  }
}

/// 可点链接文本（外部浏览器打开）
class UrlText extends StatelessWidget {
  const UrlText({super.key, required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
