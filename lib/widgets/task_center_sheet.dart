// 任务中心面板：底部弹层展示全局后台任务（运行中/完成/失败）+ 输出。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/task_center.dart';

/// 任务中心入口按钮（AppBar 用，运行中显示角标）
class TaskCenterButton extends StatelessWidget {
  const TaskCenterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TaskCenter.instance,
      builder: (context, _) {
        final active = TaskCenter.instance.activeCount;
        return IconButton(
          tooltip: AppLocalizations.of(context).batchResultTitle,
          icon: Badge(
            isLabelVisible: active > 0,
            label: Text('$active'),
            child: const Icon(Icons.task_alt_outlined),
          ),
          onPressed: () => showTaskCenter(context),
        );
      },
    );
  }
}

/// 打开任务中心面板
Future<void> showTaskCenter(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _TaskCenterSheet(),
  );
}

class _TaskCenterSheet extends StatelessWidget {
  const _TaskCenterSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: TaskCenter.instance,
      builder: (context, _) {
        final tasks = TaskCenter.instance.tasks;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        l10n.batchResultTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: TaskCenter.instance.clearFinished,
                        child: Text(l10n.commonClear),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            l10n.detailTabEmpty,
                            style: theme.textTheme.bodySmall,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: tasks.length,
                          itemBuilder: (context, i) =>
                              _TaskTile(task: tasks[i]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final AppTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (task.status) {
      'success' => (Icons.check_circle, Colors.green),
      'error' || 'timeout' => (Icons.error_outline, theme.colorScheme.error),
      _ => (Icons.sync, theme.colorScheme.primary),
    };
    return ExpansionTile(
      dense: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: color, size: 20),
      title: Text(task.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          task.status,
          if (task.message != null) task.message!,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      children: [
        if (task.output.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                task.output.take(40).join('\n'),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
