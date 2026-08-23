// 实例列表主页。
//
// 显示所有 ErisPulse 实例：
//   - 每个卡片显示名称、端口、状态点、CPU/内存（如运行中）
//   - 点击进入详情页
//   - 长按弹菜单（启动/停止/重命名/删除）
//   - 右下角 FAB 创建新实例
//   - 每 8 秒自动刷新实例状态与健康

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/instance.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/dashboard_api.dart';
import '../services/instance_manager.dart';
import '../services/runtime/proot_manager.dart';
import '../services/runtime/runtime_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/context_menu.dart';
import '../widgets/states.dart';
import '../widgets/status_indicators.dart';
import '../widgets/window_title_bar.dart';
import 'dashboard_page.dart';
import 'instance_create_page.dart';
import 'instance_detail_page.dart';
import 'logs_page.dart';
import 'onboarding_page.dart';
import 'settings_page.dart';
import 'debug_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatus());
    // 每 8s 自动刷新一次实例状态/健康，无需手动点击
    _timer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshStatus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final mgr = context.read<InstanceManager>();
    for (final inst in mgr.instances) {
      // 远程实例始终探活；本地实例仅运行中探活
      if (inst.isRemote || inst.status == InstanceStatus.running) {
        final health = await DashboardApi.ping(inst);
        if (!mounted) return;
        mgr.setRuntimeState(inst.id, health: health);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _buildDesktop(context, l10n);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('ErisPulse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
            onPressed: _refreshStatus,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: l10n.homeDebugTooltip,
            onPressed: () =>
                Navigator.of(context).pushNamed(DebugPage.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.commonSettings,
            onPressed: () =>
                Navigator.of(context).pushNamed(SettingsPage.routeName),
          ),
        ],
      ),
      body: _buildContent(context, l10n),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: Text(l10n.commonCreateInstance),
      ),
    );
  }

  /// 桌面布局（WinUI3 风格）：顶部一体标题栏横贯 + 左侧导航列 + 右侧内容区
  Widget _buildDesktop(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      body: Column(
        children: [
          // 顶栏横贯全宽（含标题 + 拖拽区 + 窗口控制按钮），与标题栏同高
          WindowTitleBar(
            title: _paneTitle(l10n),
            leading: Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.bolt,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
                onPressed: _refreshStatus,
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 左侧导航列（WinUI3 风格导航项）
                _SideNav(
                  index: _navIndex,
                  onSelected: _onNavSelected,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                // 右侧主区域：实例 / 设置 / 调试 随导航切换（IndexedStack 保活）
                Expanded(
                  child: IndexedStack(
                    index: _navIndex,
                    children: [
                      _buildAdaptiveContent(context, l10n),
                      const SettingsPage(embedded: true),
                      const DebugPage(embedded: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: Text(l10n.commonCreateInstance),
      ),
    );
  }

  /// 桌面左侧导航选中（0 实例 / 1 设置 / 2 调试）
  /// 右侧主区域随导航切换（IndexedStack），不再 push 独立路由页
  int _navIndex = 0;

  void _onNavSelected(int index) {
    setState(() => _navIndex = index);
  }

  String _paneTitle(AppLocalizations l10n) => switch (_navIndex) {
        1 => l10n.commonSettings,
        2 => l10n.homeDebugTooltip,
        _ => 'ErisPulse',
      };

  /// 内容区：随窗口宽度自适应（宽屏实例卡片多列网格）
  Widget _buildAdaptiveContent(BuildContext context, AppLocalizations l10n) {
    return Consumer<InstanceManager>(
      builder: (context, mgr, _) {
        if (mgr.count == 0) {
          return Column(
            children: [
              const _RootfsBanner(),
              Expanded(
                child: EmptyState(
                  icon: Icons.dns_outlined,
                  title: l10n.homeEmptyTitle,
                  subtitle: l10n.homeEmptySubtitle,
                  actionLabel: l10n.commonCreateInstance,
                  onAction: () => _navigateToCreate(),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            const _RootfsBanner(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  // 宽屏自适应：≥1150 三列 / ≥760 两列 / 否则单列
                  final columns = width >= 1150
                      ? 3
                      : width >= 760
                          ? 2
                          : 1;
                  final items = mgr.instances;
                  return RefreshIndicator(
                    onRefresh: _refreshStatus,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 128,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) =>
                          _InstanceTile(instance: items[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// 内容区：实例横幅 + 列表（桌面与移动共用）
  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    return Consumer<InstanceManager>(
      builder: (context, mgr, _) {
        if (mgr.count == 0) {
          return Column(
            children: [
              const _RootfsBanner(),
              Expanded(
                child: EmptyState(
                  icon: Icons.dns_outlined,
                  title: l10n.homeEmptyTitle,
                  subtitle: l10n.homeEmptySubtitle,
                  actionLabel: l10n.commonCreateInstance,
                  onAction: () => _navigateToCreate(),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            const _RootfsBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshStatus,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: mgr.count,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _InstanceTile(instance: mgr.instances[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const InstanceCreatePage(),
      ),
    );
    if (created == true) {
      await _refreshStatus();
    }
  }
}

/// 左侧导航列（WinUI3 风格）：实例 / 设置 / 调试。
///
/// 受控组件：[index] 由外部（主页面 state）决定，点击回调 [onSelected]。
/// 项以"图标 + 标签"圆角高亮块呈现，选中项铺主题色浅底。
class _SideNav extends StatelessWidget {
  const _SideNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.dns_outlined, Icons.dns),
    (Icons.settings_outlined, Icons.settings),
    (Icons.bug_report_outlined, Icons.bug_report),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.railInstances,
      l10n.commonSettings,
      l10n.homeDebugTooltip,
    ];
    return SizedBox(
      width: 176,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          for (var i = 0; i < _items.length; i++)
            _SideNavItem(
              icon: _items[i].$1,
              selectedIcon: _items[i].$2,
              label: labels[i],
              selected: index == i,
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 20,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 圆角信息标签（端口 / 版本 / URL 等）
class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// 状态/健康徽章（带圆点着色，沿用 StatusDot 的配色语义）
class _HealthChip extends StatelessWidget {
  const _HealthChip({
    required this.text,
    this.status,
    this.health,
  });

  final String text;
  final InstanceStatus? status;
  final InstanceHealth? health;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h = health;
    final color = h != null
        ? switch (h) {
            InstanceHealth.healthy => Colors.green,
            InstanceHealth.booting => Colors.blue,
            InstanceHealth.unauthorized => Colors.orange,
            InstanceHealth.unreachable => Colors.red,
            InstanceHealth.unknown => Colors.grey,
          }
        : switch (status!) {
            InstanceStatus.running => Colors.green,
            InstanceStatus.starting => Colors.blue,
            InstanceStatus.error => Colors.red,
            InstanceStatus.destroying => Colors.orange,
            InstanceStatus.stopped => Colors.grey,
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// 单实例列表项
class _InstanceTile extends StatelessWidget {
  const _InstanceTile({required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    if (!isDesktop) {
      return ContextMenuRegion(
        onContextMenu: (pos) => _showContextMenu(context, pos),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => InstanceDetailPage(instanceId: instance.id),
              ),
            ),
            onLongPress: () => _showActionMenu(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  StatusDot(
                    status: instance.status,
                    health: instance.isRemote ? instance.health : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (instance.isRemote) ...[
                              Icon(
                                Icons.cloud_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                instance.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          instance.isRemote
                              ? _remoteLabel(l10n, instance.health)
                              : instance.status == InstanceStatus.error
                                  ? (instance.errorMessage ?? l10n.statusError)
                                  : '${_statusLabel(l10n, instance.status)} · '
                                      '${_healthLabel(l10n, instance.health)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _InfoPill(text: _portOrUrlText(l10n)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 桌面：饱满的网格卡片（信息密度更高）
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final running = instance.status == InstanceStatus.running ||
        instance.status == InstanceStatus.starting;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ContextMenuRegion(
        onContextMenu: (pos) => _showContextMenu(context, pos),
        child: InkWell(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => InstanceDetailPage(instanceId: instance.id),
            ),
          ),
          onLongPress: () => _showActionMenu(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusDot(
                      status: instance.status,
                      health: instance.isRemote ? instance.health : null,
                    ),
                    const SizedBox(width: 8),
                    if (instance.isRemote) ...[
                      Icon(
                        Icons.cloud_outlined,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        instance.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 端口/版本 + 健康徽章
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _InfoPill(
                      text: _portOrUrlText(l10n),
                      icon: Icons.link,
                    ),
                    if (instance.runtimeVersion != null)
                      _InfoPill(text: 'v${instance.runtimeVersion}'),
                    _HealthChip(
                      text: instance.isRemote
                          ? _remoteLabel(l10n, instance.health)
                          : _statusLabel(l10n, instance.status),
                      status: instance.status,
                      health: instance.isRemote ? instance.health : null,
                    ),
                  ],
                ),
                const Spacer(),
                // 操作按钮
                Row(
                  children: [
                    if (!instance.isRemote &&
                        (instance.status == InstanceStatus.stopped ||
                            instance.status == InstanceStatus.error))
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _start(context),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: Text(l10n.commonStart),
                        ),
                      )
                    else if (!instance.isRemote && running) ...[
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _stop(context),
                          icon: const Icon(Icons.stop, size: 16),
                          label: Text(l10n.commonStop),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: () => _openDashboard(context),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      tooltip: l10n.detailOpenDashboard,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 端口/URL + 版本的可读文本
  String _portOrUrlText(AppLocalizations l10n) => instance.isRemote
      ? (instance.remoteUrl ?? l10n.commonRemote)
      : ':${instance.port}';

  static String _statusLabel(AppLocalizations l10n, InstanceStatus s) =>
      switch (s) {
        InstanceStatus.stopped => l10n.statusStopped,
        InstanceStatus.starting => l10n.statusStarting,
        InstanceStatus.running => l10n.statusRunning,
        InstanceStatus.error => l10n.statusError,
        InstanceStatus.destroying => l10n.statusDestroying,
      };

  static String _healthLabel(AppLocalizations l10n, InstanceHealth h) =>
      switch (h) {
        InstanceHealth.healthy => l10n.statusHealthy,
        InstanceHealth.booting => l10n.statusBooting,
        InstanceHealth.unauthorized => l10n.statusTokenInvalid,
        InstanceHealth.unreachable => l10n.statusOffline,
        InstanceHealth.unknown => l10n.statusUnknown,
      };

  /// 远程实例状态标签：由健康度表达（在线/连接中/离线/…）
  static String _remoteLabel(AppLocalizations l10n, InstanceHealth h) =>
      switch (h) {
        InstanceHealth.healthy => l10n.statusOnline,
        InstanceHealth.booting => l10n.statusConnecting,
        InstanceHealth.unauthorized => l10n.statusTokenInvalid,
        InstanceHealth.unreachable => l10n.statusOffline,
        InstanceHealth.unknown => l10n.statusRemoteUnknown,
      };

  void _showActionMenu(BuildContext context) {
    final mgr = context.read<InstanceManager>();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 远程实例由对方主机运行，本地不提供启停
            if (!instance.isRemote &&
                (instance.status == InstanceStatus.stopped ||
                    instance.status == InstanceStatus.error))
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: Text(AppLocalizations.of(ctx).commonStart),
                onTap: () {
                  Navigator.pop(ctx);
                  _start(context);
                },
              ),
            if (!instance.isRemote &&
                (instance.status == InstanceStatus.running ||
                    instance.status == InstanceStatus.starting))
              ListTile(
                leading: const Icon(Icons.stop),
                title: Text(AppLocalizations.of(ctx).commonStop),
                onTap: () {
                  Navigator.pop(ctx);
                  _stop(context);
                },
              ),
            if (instance.status == InstanceStatus.running ||
                instance.status == InstanceStatus.starting)
              ListTile(
                leading: const Icon(Icons.autorenew),
                title: Text(AppLocalizations.of(ctx).commonSoftRestart),
                onTap: () {
                  Navigator.pop(ctx);
                  _softRestart(context);
                },
              ),
            if (!instance.isRemote &&
                (instance.status == InstanceStatus.running ||
                    instance.status == InstanceStatus.starting))
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: Text(AppLocalizations.of(ctx).commonHardRestart),
                onTap: () {
                  Navigator.pop(ctx);
                  _restart(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(AppLocalizations.of(ctx).commonDeleteInstance),
              onTap: () async {
                Navigator.pop(ctx);
                final runtime = context.read<RuntimeController>();
                final ok = await _confirmDelete(context);
                if (ok == true) {
                  runtime.stopInstance(instance.id);
                  await mgr.removeInstance(instance.id);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(AppLocalizations.of(ctx).commonRename),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 桌面右键菜单（鼠标右键，含完整操作）
  void _showContextMenu(BuildContext context, Offset anchor) {
    final l10n = AppLocalizations.of(context);
    final running = instance.status == InstanceStatus.running ||
        instance.status == InstanceStatus.starting;
    final startable = !instance.isRemote &&
        (instance.status == InstanceStatus.stopped ||
            instance.status == InstanceStatus.error);
    showContextMenu(
      context: context,
      anchor: anchor,
      items: [
        if (startable)
          ContextMenuItem(
            label: l10n.commonStart,
            icon: Icons.play_arrow,
            onTap: () => _start(context),
          ),
        if (!instance.isRemote && running)
          ContextMenuItem(
            label: l10n.commonStop,
            icon: Icons.stop,
            onTap: () => _stop(context),
          ),
        if (running)
          ContextMenuItem(
            label: l10n.commonSoftRestart,
            icon: Icons.autorenew,
            onTap: () => _softRestart(context),
          ),
        if (!instance.isRemote && running)
          ContextMenuItem(
            label: l10n.commonHardRestart,
            icon: Icons.restart_alt,
            onTap: () => _restart(context),
          ),
        ContextMenuItem(
          label: l10n.detailOpenDashboard,
          icon: Icons.open_in_new,
          onTap: () => _openDashboard(context),
        ),
        ContextMenuItem(
          label: l10n.commonViewLogs,
          icon: Icons.article_outlined,
          onTap: () => _openLogs(context),
        ),
        ContextMenuItem(
          label: l10n.dashboardCopyTokenTooltip,
          icon: Icons.copy_outlined,
          onTap: () => _copyToken(context),
        ),
        ContextMenuItem(
          label: l10n.commonRename,
          icon: Icons.edit_outlined,
          onTap: () => _showRenameDialog(context),
        ),
        ContextMenuItem(
          label: l10n.commonDeleteInstance,
          icon: Icons.delete_outline,
          destructive: true,
          onTap: () => _confirmDeleteAndStop(context),
        ),
      ],
    );
  }

  void _restart(BuildContext context) {
    context.read<RuntimeController>().restartInstance(_toData(instance));
    unawaited(_refreshHealth(context));
  }

  /// 软重启：调用 Dashboard API restartSdk（保留进程）
  Future<void> _softRestart(BuildContext context) async {
    try {
      await DashboardApi(instance).restartSdk();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).detailRestartingToast,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  void _openDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DashboardPage(instance: instance),
      ),
    );
  }

  void _openLogs(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LogsPage(instanceId: instance.id),
      ),
    );
  }

  Future<void> _copyToken(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: instance.token));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).detailTokenCopied),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAndStop(BuildContext context) async {
    final runtime = context.read<RuntimeController>();
    final mgr = context.read<InstanceManager>();
    final ok = await _confirmDelete(context);
    if (ok == true) {
      runtime.stopInstance(instance.id);
      await mgr.removeInstance(instance.id);
    }
  }

  void _start(BuildContext context) {
    final runtime = context.read<RuntimeController>();
    final mgr = context.read<InstanceManager>();
    mgr.setRuntimeState(
      instance.id,
      status: InstanceStatus.starting,
      clearError: true,
    );
    runtime.startInstance(_toData(instance));
    unawaited(_refreshHealth(context));
  }

  void _stop(BuildContext context) {
    context.read<RuntimeController>().stopInstance(instance.id);
    unawaited(_refreshHealth(context));
  }

  /// 操作后主动探活并回写实例健康，避免列表状态滞后
  Future<void> _refreshHealth(BuildContext context) async {
    final health = await DashboardApi.ping(instance);
    if (context.mounted) {
      context
          .read<InstanceManager>()
          .setRuntimeState(instance.id, health: health);
    }
  }

  static InstanceData _toData(Instance inst) => InstanceData(
        id: inst.id,
        name: inst.name,
        port: inst.port,
        token: inst.token,
        workingDir: inst.workingDir,
        runtimeVersion: inst.runtimeVersion,
      );

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).commonDeleteInstance),
        content: Text(
          AppLocalizations.of(ctx).homeDeleteConfirmContent(instance.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.error,
              ),
            ),
            child: Text(AppLocalizations.of(ctx).commonDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final mgr = context.read<InstanceManager>();
    final ctrl = TextEditingController(text: instance.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).commonRename),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(AppLocalizations.of(ctx).commonSave),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && name != instance.name) {
      await mgr.rename(instance.id, name);
    }
  }
}

/// rootfs 未就绪横幅（引导进入初始化页；显示进度，点击进入初始化页）
class _RootfsBanner extends StatelessWidget {
  const _RootfsBanner();

  @override
  Widget build(BuildContext context) {
    return Consumer<RuntimeController>(
      builder: (context, runtime, _) {
        final l10n = AppLocalizations.of(context);
        final isDesktop = !Platform.isAndroid && !Platform.isIOS;
        if (runtime.rootfsReady) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final progress = runtime.rootfsProgress;
        return Material(
          color: scheme.errorContainer,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OnboardingPage(
                  onDone: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: scheme.onErrorContainer,
                  ),
                  title: Text(
                    l10n.homeBannerTitle,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                  subtitle: Text(
                    isDesktop
                        ? l10n.homeBannerNeedSdk
                        : (progress != null
                            ? (runtime.rootfsMessage ??
                                l10n.homeBannerInitializing)
                            : l10n.homeBannerNeedDownload),
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: scheme.onErrorContainer,
                  ),
                ),
                if (progress != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 100) / 100,
                        minHeight: 6,
                        backgroundColor: scheme.surface,
                      ),
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
