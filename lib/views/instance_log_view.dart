// 实例日志视图（详情页"日志"注册视图）。
//
// 两种数据源，SegmentedButton 切换：
//   - 软日志：Dashboard WebSocket 实时推送的结构化日志（/api/logs 历史 +
//     /Dashboard/ws 流），含时间 / 级别 / 模块 / 消息；
//     工具栏对齐 Dashboard 前端日志页：模块过滤、等级过滤、搜索、排序
//     （最新在底/顶）、暂停滚动、自动滚动、行数计数、复制、导出、清空。
//   - 进程日志：本地进程 stdout/stderr 原始输出（RuntimeController.debugLog，
//     按实例缓冲，实时、非持久化），含进程启停关键信息。
//
// 供 DetailViewRegistry 注册使用。

import 'dart:async';
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
import '../services/runtime/debug_log.dart';
import '../services/runtime/runtime_controller.dart';
import '../widgets/states.dart';

/// 日志数据源
enum LogSource { soft, process }

/// 日志视图
class InstanceLogView extends StatefulWidget {
  final String instanceId;
  const InstanceLogView({super.key, required this.instanceId});

  @override
  State<InstanceLogView> createState() => _InstanceLogViewState();
}

class _InstanceLogViewState extends State<InstanceLogView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scroll = ScrollController();

  /// 数据源切换（默认软日志）
  LogSource _source = LogSource.soft;

  // ── 软日志 ──
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

  /// 模块过滤（null = 全部）
  String? _moduleFilter;

  /// 可用模块列表（从历史日志收集）
  final List<String> _modules = [];

  /// 搜索关键词（message 包含，忽略大小写）
  String _search = '';
  Timer? _searchDebounce;
  String _searchInput = '';

  /// 排序：true = 最新在底（默认，自动滚到底）；false = 最新在顶
  bool _newestBottom = true;

  bool _paused = false;
  bool _autoScroll = true;

  @override
  bool get wantKeepAlive => true;

  Instance? _lookup() =>
      context.read<InstanceManager>().findById(widget.instanceId);

  @override
  void initState() {
    super.initState();
    final inst = _lookup();
    if (inst != null) {
      _stream = LogStream(inst);
      _stream!.start();
      _loadHistory(inst);
    }
  }

  @override
  void dispose() {
    _stream?.stop();
    _scroll.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// 打开时拉取历史日志，并收集可用模块列表
  Future<void> _loadHistory(Instance inst) async {
    try {
      final logs = await DashboardApi(inst).getLogs(limit: 200);
      for (final e in logs) {
        if (e.logger.isNotEmpty && !_modules.contains(e.logger)) {
          _modules.add(e.logger);
        }
      }
      _modules.sort();
      if (mounted) setState(() {});
      if (mounted && _stream != null) _stream!.seed(logs);
    } catch (_) {
      // 历史加载失败不影响实时流
    }
  }

  Future<void> _clearSoft() async {
    final inst = _lookup();
    if (inst != null) {
      try {
        await DashboardApi(inst).clearLogs();
      } catch (_) {}
    }
    _stream?.clear();
  }

  void _clearProcess() {
    context.read<RuntimeController>().debugLog.clearFor(widget.instanceId);
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
      _toast(AppLocalizations.of(context).logsCopiedLines(entries.length));
    }
  }

  Future<void> _copyProcess() async {
    final runtime = context.read<RuntimeController>();
    final lines = runtime.debugLog.entries
        .where((e) => e.instanceId == widget.instanceId)
        .map(
          (e) => '${e.time.toLocal().toString().substring(11, 19)} ${e.line}',
        )
        .join('\n');
    await Clipboard.setData(ClipboardData(text: lines));
    if (mounted) _toast(AppLocalizations.of(context).debugCopiedLogs);
  }

  /// 导出软日志到系统下载目录（桌面 / Android）或文档目录（iOS 回退）
  Future<void> _downloadSoft(List<LogEntry> entries) async {
    final text = entries
        .map(
          (e) => '${e.timestamp.toLocal().toString().substring(11, 19)} '
              '[${e.level.label}] ${e.logger} ${e.message}',
        )
        .join('\n');
    final name = _lookup()?.name ?? 'instance';
    try {
      final dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/erispulse-$name-'
        '${DateTime.now().millisecondsSinceEpoch}.log',
      );
      await file.writeAsString(text);
      if (mounted) {
        _toast(AppLocalizations.of(context).logsDownloaded(file.path));
      }
    } catch (e) {
      if (mounted) _toast('$e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onSearchChanged(String v) {
    _searchInput = v;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _search != _searchInput) {
        setState(() => _search = _searchInput);
      }
    });
  }

  /// 软日志可见列表（应用模块 / 等级 / 搜索过滤）
  List<LogEntry> _visibleSoft(List<LogEntry> entries) {
    return entries.where((e) {
      if (_moduleFilter != null && e.logger != _moduleFilter) return false;
      if (!_selectedLevels.contains(e.level)) return false;
      if (_search.isNotEmpty &&
          !e.message.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  /// 自动滚动到底 / 顶
  void _maybeAutoScroll() {
    if (!_autoScroll || _paused) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_newestBottom) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        _scroll.jumpTo(_scroll.position.minScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _buildSourceSwitcher(l10n),
        const Divider(height: 1),
        Expanded(
          child: _source == LogSource.soft
              ? _buildSoft(context, l10n)
              : _buildProcess(context, l10n),
        ),
      ],
    );
  }

  Widget _buildSourceSwitcher(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          SegmentedButton<LogSource>(
            segments: [
              ButtonSegment(
                value: LogSource.soft,
                label: Text(l10n.logsSoft),
                icon: const Icon(Icons.terminal_outlined, size: 16),
              ),
              ButtonSegment(
                value: LogSource.process,
                label: Text(l10n.logsProcess),
                icon: const Icon(Icons.memory_outlined, size: 16),
              ),
            ],
            selected: {_source},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onSelectionChanged: (s) => setState(() => _source = s.first),
          ),
          const Spacer(),
          if (_source == LogSource.soft)
            Text(
              l10n.logsLineCount(_stream?.entries.length ?? 0),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }

  // ────────────────────────── 软日志 ──────────────────────────

  Widget _buildSoft(BuildContext context, AppLocalizations l10n) {
    final stream = _stream;
    if (stream == null) {
      return Center(child: Text(l10n.logsEmptyTitle));
    }
    return ListenableBuilder(
      listenable: stream,
      builder: (context, _) {
        final entries = stream.entries;
        final visible = _visibleSoft(entries);
        _maybeAutoScroll();
        return Column(
          children: [
            _buildSoftToolbar(context, l10n),
            const Divider(height: 1),
            Expanded(child: _buildLogList(visible, l10n)),
          ],
        );
      },
    );
  }

  Widget _buildSoftToolbar(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 模块过滤
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _moduleFilter,
              hint: Text(
                l10n.logsFilterModule,
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
                for (final m in _modules)
                  DropdownMenuItem<String?>(
                    value: m,
                    child: Text(m, style: theme.textTheme.labelSmall),
                  ),
              ],
              onChanged: (v) => setState(() => _moduleFilter = v),
            ),
          ),
          // 等级过滤（勾选，精确级别集合）
          for (final lv in LogLevel.values)
            FilterChip(
              label: Text(
                lv.label,
                style: theme.textTheme.labelSmall,
              ),
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
          // 搜索
          SizedBox(
            width: 160,
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.logsSearch,
                prefixIcon: const Icon(Icons.search, size: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 排序（最新在底/顶）
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: _newestBottom
                ? l10n.logsSortNewestTop
                : l10n.logsSortNewestBottom,
            icon: Icon(
              _newestBottom
                  ? Icons.vertical_align_bottom
                  : Icons.vertical_align_top,
            ),
            onPressed: () => setState(() => _newestBottom = !_newestBottom),
          ),
          // 暂停滚动
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
            tooltip: _paused ? l10n.logsResume : l10n.logsPause,
            onPressed: () => setState(() => _paused = !_paused),
          ),
          // 自动滚动
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.vertical_align_bottom),
            tooltip: l10n.logsAutoScroll,
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          // 清空
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: l10n.commonClear,
            onPressed: _clearSoft,
          ),
          // 复制
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: l10n.commonCopyAll,
            onPressed: () => _copyAll(_visibleSoft(_stream?.entries ?? [])),
          ),
          // 导出
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.download_outlined),
            tooltip: l10n.logsDownload,
            onPressed: () =>
                _downloadSoft(_visibleSoft(_stream?.entries ?? [])),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<LogEntry> entries, AppLocalizations l10n) {
    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.terminal,
        title: l10n.logsEmptyTitle,
        subtitle: (_selectedLevels.length != LogLevel.values.length ||
                _moduleFilter != null ||
                _search.isNotEmpty)
            ? l10n.logsFilteredEmpty
            : l10n.logsEmptySubtitle,
      );
    }
    final shown = _newestBottom ? entries : entries.reversed.toList();
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: shown.length,
      itemBuilder: (context, i) => _SoftLogLine(entry: shown[i]),
    );
  }

  // ────────────────────────── 进程日志 ──────────────────────────

  Widget _buildProcess(BuildContext context, AppLocalizations l10n) {
    final runtime = context.watch<RuntimeController>();
    final entries = runtime.debugLog.entries
        .where((e) => e.instanceId == widget.instanceId)
        .toList();
    _maybeAutoScroll();
    return Column(
      children: [
        _buildProcessToolbar(context, l10n),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? EmptyState(
                  icon: Icons.memory_outlined,
                  title: l10n.logsProcessEmptyTitle,
                  subtitle: l10n.logsProcessEmptySubtitle,
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: entries.length,
                  itemBuilder: (context, i) =>
                      _ProcessLogLine(entry: entries[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildProcessToolbar(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            l10n.logsProcess,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
            tooltip: _paused ? l10n.logsResume : l10n.logsPause,
            onPressed: () => setState(() => _paused = !_paused),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: l10n.commonCopyAll,
            onPressed: _copyProcess,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: l10n.commonClear,
            onPressed: _clearProcess,
          ),
        ],
      ),
    );
  }
}

/// 软日志行
class _SoftLogLine extends StatelessWidget {
  const _SoftLogLine({required this.entry});
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
              '${entry.logger.isEmpty ? '' : '[${entry.logger}] '}${entry.message}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// 进程日志行
class _ProcessLogLine extends StatelessWidget {
  const _ProcessLogLine({required this.entry});
  final DebugLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = entry.time.toLocal();
    final hhmmss = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
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
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              entry.line,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
