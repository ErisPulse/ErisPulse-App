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
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/instance.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/dashboard_api.dart';
import '../services/instance_manager.dart';
import '../services/runtime/proot_manager.dart';
import '../services/runtime/runtime_controller.dart';
import '../widgets/states.dart';
import '../widgets/status_indicators.dart';
import 'instance_create_page.dart';
import 'instance_detail_page.dart';
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
      body: Consumer<InstanceManager>(
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: mgr.count,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) =>
                        _InstanceTile(instance: mgr.instances[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: Text(l10n.commonCreateInstance),
      ),
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

/// 单实例列表项
class _InstanceTile extends StatelessWidget {
  const _InstanceTile({required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: StatusDot(
        status: instance.status,
        health: instance.isRemote ? instance.health : null,
      ),
      title: Row(
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            instance.isRemote
                ? instance.remoteUrl ?? l10n.commonRemote
                : ':${instance.port}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
      subtitle: Text(
        instance.isRemote
            ? _remoteLabel(l10n, instance.health)
            : instance.status == InstanceStatus.error
                ? (instance.errorMessage ?? l10n.statusError)
                : '${_statusLabel(l10n, instance.status)} · '
                    '${_healthLabel(l10n, instance.health)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => InstanceDetailPage(instanceId: instance.id),
        ),
      ),
      onLongPress: () => _showActionMenu(context),
    );
  }

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

  void _start(BuildContext context) {
    final runtime = context.read<RuntimeController>();
    final mgr = context.read<InstanceManager>();
    mgr.setRuntimeState(
      instance.id,
      status: InstanceStatus.starting,
      clearError: true,
    );
    runtime.startInstance(_toData(instance));
  }

  void _stop(BuildContext context) {
    context.read<RuntimeController>().stopInstance(instance.id);
  }

  static InstanceData _toData(Instance inst) => InstanceData(
        id: inst.id,
        name: inst.name,
        port: inst.port,
        token: inst.token,
        workingDir: inst.workingDir,
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

/// rootfs 未就绪横幅（引导进入首启向导）
class _RootfsBanner extends StatelessWidget {
  const _RootfsBanner();

  @override
  Widget build(BuildContext context) {
    return Consumer<RuntimeController>(
      builder: (context, runtime, _) {
        final l10n = AppLocalizations.of(context);
        final isDesktop = !Platform.isAndroid && !Platform.isIOS;
        if (runtime.rootfsReady) return const SizedBox.shrink();
        return Material(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            title: Text(
              l10n.homeBannerTitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            subtitle: Text(
              isDesktop
                  ? l10n.homeBannerNeedSdk
                  : (runtime.rootfsProgress != null
                      ? (runtime.rootfsMessage ?? l10n.homeBannerInitializing)
                      : l10n.homeBannerNeedDownload),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            trailing: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OnboardingPage(
                    onDone: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              child: Text(l10n.commonInitialize),
            ),
          ),
        );
      },
    );
  }
}
