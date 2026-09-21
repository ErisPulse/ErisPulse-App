// 实例拓扑视图（详情页"拓扑"注册视图）。
//
// 消费 Dashboard `/api/topology`（SDK get_topology 聚合）：
//   - 模块归属资源：命令 / 服务 / 事件处理器 / 路由 / 生命周期钩子 / 依赖
//   - 适配器归属：运行状态、下属 Bot（状态 / 最近活跃）与作用域绑定
// 对齐 Dashboard 拓扑页的数据颗粒度；移动端以"归属树"呈现，
// 桌面端同样可用（不再另画 canvas 力导向图）。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/enums.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../theme/app_theme.dart';
import '../widgets/states.dart';
import '../widgets/status_indicators.dart';

/// 拓扑视图：适配器 → Bot、模块 → 归属资源
class InstanceTopologyView extends StatefulWidget {
  final Instance instance;
  const InstanceTopologyView({super.key, required this.instance});

  @override
  State<InstanceTopologyView> createState() => _InstanceTopologyViewState();
}

class _InstanceTopologyViewState extends State<InstanceTopologyView>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _topology;
  bool _supported = true;
  bool _loading = true;
  String? _error;

  /// 过滤开关（对齐 Dashboard 拓扑页：显示资源 / 显示依赖）
  bool _showResources = true;
  bool _showDepends = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await DashboardApi(widget.instance).getTopology();
      if (!mounted) return;
      setState(() {
        _topology = json;
        _supported = json['supported'] == true;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);

    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (!_supported) {
      return EmptyState(
        icon: Icons.hub_outlined,
        title: l10n.topoUnsupported,
        subtitle: l10n.topoUnsupportedHint,
      );
    }

    final topo = _topology?['topology'] as Map<String, dynamic>? ?? {};
    final modules =
        (topo['modules'] as Map?)?.cast<String, dynamic>() ?? const {};
    final adapters =
        (topo['adapters'] as Map?)?.cast<String, dynamic>() ?? const {};
    var botCount = 0;
    for (final a in adapters.values) {
      if (a is Map) {
        botCount += ((a['bots'] as Map?)?.length ?? 0);
      }
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 统计条：模块 / 适配器 / Bot
          Row(
            children: [
              _StatCard(
                label: l10n.topoStatModules,
                value: '${modules.length}',
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: l10n.topoStatAdapters,
                value: '${adapters.length}',
              ),
              const SizedBox(width: 10),
              _StatCard(label: l10n.topoStatBots, value: '$botCount'),
            ],
          ),
          const SizedBox(height: 8),
          // 过滤开关（对齐 Dashboard 拓扑页）
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: l10n.topoFilterResources,
                selected: _showResources,
                onSelected: (v) => setState(() => _showResources = v),
              ),
              _FilterChip(
                label: l10n.topoFilterDepends,
                selected: _showDepends,
                onSelected: (v) => setState(() => _showDepends = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 适配器 → Bot
          _SectionHeader(label: l10n.topoSectionAdapters),
          if (adapters.isEmpty)
            const _EmptyHint()
          else
            ...adapters.entries.map(
              (e) => _AdapterCard(
                platform: e.key,
                info: (e.value as Map?)?.cast<String, dynamic>() ?? const {},
              ),
            ),
          const SizedBox(height: 12),
          // 模块 → 归属资源
          _SectionHeader(label: l10n.topoSectionModules),
          if (modules.isEmpty)
            const _EmptyHint()
          else
            ...modules.entries.map(
              (e) => _ModuleCard(
                name: e.key,
                info: (e.value as Map?)?.cast<String, dynamic>() ?? const {},
                showResources: _showResources,
                showDepends: _showDepends,
              ),
            ),
        ],
      ),
    );
  }
}

// ── 统计条 ──

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(height: 1, color: scheme.outlineVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        '—',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ── 适配器 → Bot ──

class _AdapterCard extends StatelessWidget {
  const _AdapterCard({required this.platform, required this.info});
  final String platform;
  final Map<String, dynamic> info;

  Color _statusColor(BuildContext context, String status) {
    // 对齐 Dashboard 拓扑语义：started=ok / stopped=中性 / disabled=警告
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case 'started':
        return dark ? const Color(0xFF6FD6A1) : const Color(0xFF178A52);
      case 'disabled':
        return dark ? const Color(0xFFF5B95D) : const Color(0xFFC77F16);
      default:
        return dark ? const Color(0xFF5F6875) : const Color(0xFF9AA4B1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final status = '${info['status'] ?? 'stopped'}';
    final enabled = info['enabled'] == true;
    final bots = (info['bots'] as Map?)?.cast<String, dynamic>() ?? const {};
    final scope = (info['scope'] as Map?)?.cast<String, dynamic>() ?? const {};
    final scopeModules = (scope['modules'] as List?) ?? const [];
    final scopeBlocked = (scope['blocked'] as List?) ?? const [];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _statusColor(context, status),
            shape: BoxShape.circle,
          ),
        ),
        title:
            Text(platform, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$status · ${bots.length} bots'
          '${enabled ? '' : ' · ${l10n.topoAdapterDisabled}'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        children: [
          if (bots.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('—', style: Theme.of(context).textTheme.bodySmall),
            )
          else
            ...bots.entries.map((e) {
              final bot =
                  (e.value as Map?)?.cast<String, dynamic>() ?? const {};
              final botStatus = '${bot['status'] ?? 'unknown'}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: instanceStateColor(
                          context,
                          health: switch (botStatus) {
                            'online' => InstanceHealth.healthy,
                            'connecting' || 'booting' => InstanceHealth.booting,
                            'offline' => InstanceHealth.unreachable,
                            _ => InstanceHealth.unknown,
                          },
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      botStatus,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              );
            }),
          if (scopeModules.isNotEmpty || scopeBlocked.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...scopeModules.map(
                    (m) => _MiniTag(label: '+${_name(m)}', ok: true),
                  ),
                  ...scopeBlocked.map(
                    (m) => _MiniTag(label: '−${_name(m)}', ok: false),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _name(Object? v) {
    final s = '$v';
    // glob / 正则形（如 re:^Danger）原样展示
    return s.length > 24 ? '${s.substring(0, 24)}…' : s;
  }
}

// ── 模块 → 归属资源 ──

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.name,
    required this.info,
    required this.showResources,
    required this.showDepends,
  });

  final String name;
  final Map<String, dynamic> info;
  final bool showResources;
  final bool showDepends;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final loaded = info['loaded'] == true;
    final enabled = info['enabled'] == true;

    final commands =
        ((info['commands'] as List?) ?? const []).map((c) => '$c').toList();
    final services =
        ((info['services'] as List?) ?? const []).map((s) => '$s').toList();
    final handlers =
        ((info['handlers'] as Map?)?.cast<String, dynamic>()) ?? const {};
    final routes =
        ((info['routes'] as Map?)?.cast<String, dynamic>()) ?? const {};
    final depends =
        ((info['depends'] as List?) ?? const []).map((d) => '$d').toList();
    final lifecycleHooks = (info['lifecycle_hooks'] as num?)?.toInt() ?? 0;
    final scopeApplies = info['scope_applies'] == true;

    final summaryParts = <String>[
      if (loaded) l10n.topoModuleLoaded else l10n.topoModuleNotLoaded,
      if (commands.isNotEmpty) '${l10n.topoTypeCommands} ${commands.length}',
      if (services.isNotEmpty) '${l10n.topoTypeServices} ${services.length}',
      if (handlers.isNotEmpty) '${l10n.topoTypeHandlers} ${handlers.length}',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: loaded
                ? scheme.primary
                : scheme.onSurfaceVariant.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          summaryParts.join(' · '),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!enabled)
              Icon(
                Icons.pause_circle_outline,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            if (scopeApplies)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Tooltip(
                  message: l10n.topoScopeApplies,
                  child: Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: scheme.tertiary,
                  ),
                ),
              ),
          ],
        ),
        children: [
          if (showResources) ...[
            _ResourceRow(label: l10n.topoTypeCommands, items: commands),
            _ResourceRow(label: l10n.topoTypeServices, items: services),
            if (handlers.isNotEmpty)
              _KvRow(
                label: l10n.topoTypeHandlers,
                value: handlers.entries
                    .map((e) => '${e.key} ×${e.value}')
                    .join('  '),
              ),
            if (routes.isNotEmpty)
              _KvRow(
                label: l10n.topoTypeRoutes,
                value: routes.entries.map((e) {
                  final list = (e.value as List?) ?? const [];
                  return '${e.key} ×${list.length}';
                }).join('  '),
              ),
            _KvRow(
              label: l10n.topoTypeLifecycleHooks,
              value: '$lifecycleHooks',
            ),
          ],
          if (showDepends && depends.isNotEmpty)
            _ResourceRow(label: l10n.topoTypeDepends, items: depends),
        ],
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.label, required this.items});
  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (items.isEmpty)
            Text('—', style: Theme.of(context).textTheme.bodySmall)
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items.map((i) => _MiniTag(label: i, ok: true)).toList(),
            ),
        ],
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.ok});
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ok
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: ok ? scheme.primary : scheme.error,
            ),
      ),
    );
  }
}
