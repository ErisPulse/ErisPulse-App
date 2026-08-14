// 实例日志页（Dashboard 日志流）。
//
// 通过 Dashboard WebSocket（/Dashboard/ws）实时接收日志（log_entry），
// 打开时先用 /api/logs 拉取历史填充；桌面/移动端统一。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../models/log_entry.dart';
import '../services/dashboard_api.dart';
import '../services/instance_manager.dart';
import '../services/log_stream.dart';
import '../widgets/states.dart';

class LogsPage extends StatefulWidget {
  final String instanceId;
  const LogsPage({super.key, required this.instanceId});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final ScrollController _scroll = ScrollController();
  bool _autoScroll = true;
  bool _paused = false;
  LogStream? _stream;

  /// 等级过滤（勾选集合，精确级别匹配）。默认仅 INFO 及以上
  /// （含自定义 EVENT=21），TRACE / DEBUG 默认隐藏。
  final Set<LogLevel> _selectedLevels = {
    LogLevel.info,
    LogLevel.event,
    LogLevel.warning,
    LogLevel.error,
    LogLevel.critical,
  };

  @override
  void initState() {
    super.initState();
    final inst = context.read<InstanceManager>().findById(widget.instanceId);
    if (inst != null) {
      _stream = LogStream(inst);
      _stream!.start();
      _loadHistory(inst);
    }
  }

  Future<void> _loadHistory(Instance inst) async {
    try {
      final logs = await DashboardApi(inst).getLogs(limit: 200);
      if (mounted && _stream != null) _stream!.seed(logs);
    } catch (_) {
      // 历史加载失败不影响实时流
    }
  }

  @override
  void dispose() {
    _stream?.stop();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _copyAll(List<LogEntry> entries) async {
    final text = entries
        .map(
          (e) => '${e.timestamp.toLocal().toString().substring(11, 19)} '
              '[${e.level.label}] ${e.logger} ${e.message}',
        )
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).logsCopiedLines(entries.length),
          ),
        ),
      );
    }
  }

  /// 导出日志到系统下载目录（桌面 / Android）或 app 文档目录（iOS 回退）
  Future<void> _download(List<LogEntry> entries) async {
    final text = entries
        .map(
          (e) => '${e.timestamp.toLocal().toString().substring(11, 19)} '
              '[${e.level.label}] ${e.logger} ${e.message}',
        )
        .join('\n');
    final name =
        context.read<InstanceManager>().findById(widget.instanceId)?.name ??
            'instance';
    try {
      final dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/erispulse-$name-'
        '${DateTime.now().millisecondsSinceEpoch}.log',
      );
      await file.writeAsString(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).logsDownloaded(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name =
        context.read<InstanceManager>().findById(widget.instanceId)?.name;
    final stream = _stream;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(title: Text(name ?? l10n.commonViewLogs)),
      body: stream == null
          ? EmptyState(
              icon: Icons.terminal,
              title: l10n.logsEmptyTitle,
              subtitle: l10n.logsEmptySubtitle,
            )
          : ListenableBuilder(
              listenable: stream,
              builder: (context, _) {
                final entries = stream.entries;
                final visible = entries
                    .where((e) => _selectedLevels.contains(e.level))
                    .toList();
                if (_autoScroll && !_paused) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scroll.hasClients) {
                      _scroll.jumpTo(_scroll.position.maxScrollExtent);
                    }
                  });
                }
                return Column(
                  children: [
                    _buildToolbar(context, visible),
                    const Divider(height: 1),
                    Expanded(child: _buildBody(visible)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    List<LogEntry> entries,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                tooltip: _paused ? l10n.logsResume : l10n.logsPause,
                onPressed: () => setState(() => _paused = !_paused),
              ),
              IconButton(
                icon: const Icon(Icons.vertical_align_bottom),
                tooltip: l10n.logsAutoScroll,
                onPressed: () => setState(() => _autoScroll = !_autoScroll),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: l10n.commonClear,
                onPressed: () => _stream?.clear(),
              ),
              IconButton(
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: l10n.commonCopyAll,
                onPressed: () => _copyAll(entries),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: l10n.logsDownload,
                onPressed: () => _download(entries),
              ),
              const Spacer(),
              Text(
                l10n.logsLineCount(entries.length),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // 等级过滤（勾选，精确级别集合）
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final lv in LogLevel.values)
                FilterChip(
                  label: Text(lv.label, style: theme.textTheme.labelSmall),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  selected: _selectedLevels.contains(lv),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _selectedLevels.add(lv);
                    } else {
                      _selectedLevels.remove(lv);
                    }
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<LogEntry> entries) {
    if (entries.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return EmptyState(
        icon: Icons.terminal,
        title: l10n.logsEmptyTitle,
        subtitle: _selectedLevels.length != LogLevel.values.length
            ? l10n.logsFilteredEmpty
            : l10n.logsEmptySubtitle,
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: entries.length,
      itemBuilder: (context, i) => _LogLine(entry: entries[i]),
    );
  }
}

/// 单条日志
class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry});
  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = entry.timestamp.toLocal();
    final hhmmss = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
    final levelColor = switch (entry.level) {
      LogLevel.trace => const Color(0xFFB0BEC5),
      LogLevel.debug => const Color(0xFF90A4AE),
      LogLevel.info => const Color(0xFF9E9E9E),
      LogLevel.event => const Color(0xFF4DB6AC),
      LogLevel.warning => const Color(0xFFFFB74D),
      LogLevel.error || LogLevel.critical => const Color(0xFFF06292),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            child: Text(
              hhmmss,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 52,
            child: Text(
              entry.level.label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: levelColor,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              entry.message,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
