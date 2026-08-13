// 实例原始日志页。
//
// 直接读取 proot 进程的 stdout/stderr（FGS 通过 instanceLog 事件写入
// RuntimeController.debugLog），不依赖 Dashboard WebSocket。
// 因此即使 Dashboard 未就绪也能看到进程输出。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/runtime/debug_log.dart';
import '../services/runtime/runtime_controller.dart';
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

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _copyAll(List<DebugLogEntry> entries) async {
    final text = entries
        .map(
          (e) => '${e.time.toLocal().toString().substring(11, 19)} ${e.line}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Consumer<RuntimeController>(
        builder: (context, runtime, _) => ListenableBuilder(
          listenable: runtime.debugLog,
          builder: (context, _) {
            final entries = runtime.debugLog.entries
                .where((e) => e.instanceId == widget.instanceId)
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
                _buildToolbar(context, entries),
                const Divider(height: 1),
                Expanded(child: _buildBody(entries)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    List<DebugLogEntry> entries,
  ) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
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
            onPressed: () => context.read<RuntimeController>().debugLog.clear(),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: l10n.commonCopyAll,
            onPressed: () => _copyAll(entries),
          ),
          const Spacer(),
          Text(
            l10n.logsLineCount(entries.length),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<DebugLogEntry> entries) {
    if (entries.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return EmptyState(
        icon: Icons.terminal,
        title: l10n.logsEmptyTitle,
        subtitle: l10n.logsEmptySubtitle,
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

/// 单条原始日志行
class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry});
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
