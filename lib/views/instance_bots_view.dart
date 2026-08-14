// 实例机器人总览视图（详情页"机器人"注册视图）。
//
// 原生替代 Dashboard 前端 bots 页：展示各平台已发现的机器人
// （`/api/bots`：platform / bot_id / status / capabilities / last_active /
// 适配器运行状态），只读总览。bot 账户的增删改启停走适配器配置视图。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

/// 机器人总览视图
class InstanceBotsView extends StatefulWidget {
  final Instance instance;
  const InstanceBotsView({super.key, required this.instance});

  @override
  State<InstanceBotsView> createState() => _InstanceBotsViewState();
}

class _InstanceBotsViewState extends State<InstanceBotsView>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _bots = [];
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
      final bots = await DashboardApi(widget.instance).getBots();
      if (!mounted) return;
      setState(() {
        _bots = bots;
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

  static bool _online(Map<String, dynamic> b) {
    final status = b['status']?.toString().toLowerCase() ?? '';
    final adapterRunning = b['adapter_running'] == true;
    return adapterRunning && (status.isEmpty || status == 'online');
  }

  static String _lastActive(Map<String, dynamic> b, AppLocalizations l10n) {
    final t = b['last_active'];
    if (t is! num || t <= 0) return l10n.botsNeverActive;
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(t.toInt() * 1000));
    if (diff.inSeconds < 60) return l10n.botsJustNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${l10n.botsMinutesAgo}';
    if (diff.inHours < 24) return '${diff.inHours} ${l10n.botsHoursAgo}';
    return '${diff.inDays} ${l10n.botsDaysAgo}';
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
                l10n.botsTitle,
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
    final theme = Theme.of(context);
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_loading) {
      return const LoadingView();
    }
    if (_bots.isEmpty) {
      return EmptyState(icon: Icons.smart_toy_outlined, title: l10n.botsEmpty);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _bots.length,
      itemBuilder: (context, i) {
        final b = _bots[i];
        final platform = b['platform']?.toString() ?? 'unknown';
        final botId = b['bot_id']?.toString() ?? '-';
        final online = _online(b);
        final caps = (b['capabilities'] as List? ?? [])
            .map((c) => c.toString())
            .where((c) => c.isNotEmpty)
            .toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  platform.substring(0, platform.length.clamp(1, 2)),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          platform,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: online ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      botId,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (caps.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          for (final c in caps)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                c,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _lastActive(b, l10n),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
