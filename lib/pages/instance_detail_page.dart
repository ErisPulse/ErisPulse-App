// 实例详情页：信息卡 + 操作 + Dashboard 入口。
//
// 原生层只做"查看信息"与启停：
//   - 头部：Logo + 名称 + 状态 / 类型 / 健康
//   - 信息卡：地址（本机 v4/v6 IP 可复制）、PID、访问令牌（可复制）
//   - 事件卡：最近事件（轮询 Dashboard /api/events）
//   - 操作：打开 Dashboard（WebView，包含全部管理能力）、启停
// 状态与健康每 3s 自动刷新，无需手动点击。
// 其余管理（适配器/模块/配置/文件/日志/事件流/审计）由 DetailViewRegistry
// 注册的原生视图承载：PC 宽屏左侧导航 + 内容区，移动端顶部 TabBar。

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/adapter_info.dart';
import '../models/enums.dart';
import '../models/instance.dart';
import '../models/module_info.dart';
import '../models/system_info.dart';
import '../services/dashboard_api.dart';
import '../services/instance_manager.dart';
import '../services/runtime/proot_manager.dart';
import '../services/runtime/runtime_controller.dart';
import '../views/instance_view.dart';
import '../widgets/status_indicators.dart';
import 'dashboard_page.dart';

/// 宽屏阈值：超过则使用 PC 左侧导航布局
const double _wideBreakpoint = 900;

class InstanceDetailPage extends StatefulWidget {
  final String instanceId;
  const InstanceDetailPage({super.key, required this.instanceId});

  @override
  State<InstanceDetailPage> createState() => _InstanceDetailPageState();
}

class _InstanceDetailPageState extends State<InstanceDetailPage> {
  Timer? _timer;
  SystemInfo? _sys;
  List<ModuleInfo> _modules = [];
  List<AdapterInfo> _adapters = [];
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String? _error;

  /// 消息统计（/api/message-stats）
  Map<String, dynamic>? _stats;

  /// 事件总数（进程启动以来，/api/events 的 total_count）
  int _totalEvents = 0;

  /// 在线机器人数量（/api/bots）
  int _onlineBots = 0;

  /// 框架信息（/api/status framework：version / python_version / platform）
  Map<String, dynamic>? _frameworkInfo;

  /// 本机可达地址（v4 / v6）
  List<InternetAddress> _localAddrs = [];

  /// 当前选中视图索引（0 = 概览，1..n = 注册视图）
  int _tabIndex = 0;

  /// 宽屏（PC）已访问过的视图索引集合，用于 IndexedStack 懒实例化
  final Set<int> _visited = {0};

  Instance? _lookup() =>
      context.read<InstanceManager>().findById(widget.instanceId);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    _loadLocalAddrs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 枚举本机非回环地址（每个类型只保留最相关的一个，排除虚拟/链路本地）
  Future<void> _loadLocalAddrs() async {
    try {
      final ifaces = await NetworkInterface.list(includeLoopback: false);
      final addrs = <InternetAddress>[];
      for (final ni in ifaces) {
        for (final a in ni.addresses) {
          if (a.isLoopback || a.isLinkLocal) continue;
          if (a.type == InternetAddressType.IPv4 ||
              a.type == InternetAddressType.IPv6) {
            // 每个类型只取第一个（通常为 Wi-Fi / 以太网接口）
            if (addrs.any((x) => x.type == a.type)) continue;
            addrs.add(a);
          }
        }
      }
      if (!mounted) return;
      setState(() => _localAddrs = addrs);
    } catch (_) {
      // 枚举失败（无权限等）则静默跳过
    }
  }

  /// 每 3s：并行拉取模块/适配器/系统资源/最近事件 + 自动探活
  Future<void> _poll() async {
    final inst = _lookup();
    if (inst == null) return;
    final api = DashboardApi(inst);
    try {
      final results = await Future.wait<Object?>([
        api.getModules(),
        api.getAdapters(),
        api.getSystemInfo(),
        api.getEvents(limit: 10),
        api.getMessageStats(),
      ]);
      // 在线机器人 / 框架版本（失败不阻塞主概览，如旧版本无端点）
      int onlineBots = 0;
      Map<String, dynamic>? fwInfo;
      try {
        final bots = await api.getBots();
        onlineBots =
            bots.where((b) => b['status']?.toString() == 'online').length;
      } catch (_) {}
      try {
        final st = await api.getStatus();
        final fw = st['framework'];
        if (fw is Map) fwInfo = Map<String, dynamic>.from(fw);
      } catch (_) {}
      if (!mounted) return;
      final evt =
          results[3] as ({List<Map<String, dynamic>> events, int totalCount});
      setState(() {
        _modules = (results[0] as List<ModuleInfo>);
        _adapters = (results[1] as List<AdapterInfo>);
        _sys = results[2] as SystemInfo;
        _events = evt.events;
        _totalEvents = evt.totalCount;
        _stats = results[4] as Map<String, dynamic>?;
        _onlineBots = onlineBots;
        _frameworkInfo = fwInfo;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).detailUnreachableError;
      });
    }
    final health = await DashboardApi.ping(inst);
    if (!mounted) return;
    context.read<InstanceManager>().setRuntimeState(inst.id, health: health);
    // 模块动态视窗同步（装卸模块后导航自动增减入口）
    await _syncModuleViews(api);
  }

  // 模块动态视窗（/api/views → ext-<id> 导航入口）
  //
  // 视窗内容不在 App 内渲染：入口点击直接跳转 Dashboard 对应页面
  // （前端全局 go('ext-<id>')，其内部按 p-ext-<id> 查找页面），
  // 对齐 Dashboard 的页面切换行为。

  /// 与后端 /api/views 对齐注册 ext- 视图；集合变化时回概览防索引错位。
  Future<void> _syncModuleViews(DashboardApi api) async {
    List<Map<String, dynamic>> views;
    try {
      views = await api.getViews();
    } catch (_) {
      return; // 端点不存在（旧版本）等，静默
    }
    if (!mounted) return;
    final registry = context.read<DetailViewRegistry>();
    final fresh = <String>{};
    for (final v in views) {
      final id = v['id']?.toString() ?? '';
      if (id.isNotEmpty) fresh.add(id);
    }
    final existing = registry.views
        .map((v) => v.id)
        .where((id) => id.startsWith('ext-'))
        .map((id) => id.substring(4))
        .toSet();
    if (fresh.length == existing.length && fresh.containsAll(existing)) {
      return; // 无变化，避免每轮 poll 触发重建
    }
    for (final id in existing.difference(fresh)) {
      registry.unregister('ext-$id');
    }
    for (final v in views) {
      final id = v['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      registry.insertBefore(
        _anchorFor(v['group']?.toString() ?? ''),
        _buildExtView(Map<String, dynamic>.from(v)),
      );
    }
    // 视图集合变化：回概览并清空懒加载索引
    setState(() {
      _tabIndex = 0;
      _visited
        ..clear()
        ..add(0);
    });
  }

  /// 动态视窗插入锚点：内置分组复用同名组（插到下一组首项之前），
  /// system / tools / 自定义分组追加到导航末尾（空 anchor = 末尾）。
  static String _anchorFor(String group) => switch (group) {
        'group_overview' => 'events',
        'group_events' => 'modules',
        'group_extensions' => 'adapters',
        'group_management' => 'monitor',
        'group_operations' => 'files',
        _ => '',
      };

  InstanceView _buildExtView(Map<String, dynamic> v) {
    final id = v['id']!.toString();
    return InstanceView(
      id: 'ext-$id',
      icon: Icons.extension_outlined,
      iconSvg: v['icon_svg']?.toString(),
      title: (l10n) => _extTitle(l10n, v),
      group: (l10n) => _extGroup(l10n, v),
      builder: (_, inst) =>
          _ModuleViewEntry(instance: inst, page: 'ext-$id', data: v),
    );
  }

  /// App localeName（zh / zh_Hant / …）→ Dashboard titles 字典键（zh-TW）
  static String? _extLocaleKey(String localeName) => switch (localeName) {
        'zh' => 'zh',
        'zh_Hant' => 'zh-TW',
        'en' => 'en',
        'ja' => 'ja',
        'ru' => 'ru',
        _ => null,
      };

  static String _extTitle(AppLocalizations l10n, Map<String, dynamic> v) {
    final titles = (v['titles'] as Map?)?.cast<String, dynamic>();
    final key = _extLocaleKey(l10n.localeName);
    final byLocale = key == null ? null : titles?[key]?.toString();
    return byLocale ??
        v['title']?.toString() ??
        v['title_en']?.toString() ??
        v['id'].toString();
  }

  /// 分组标题：内置组用本地文案；自定义组优先 group_titles[lang]，
  /// 回退 group_title_en / group_title。
  static String _extGroup(AppLocalizations l10n, Map<String, dynamic> v) {
    switch (v['group']?.toString() ?? '') {
      case 'group_overview':
        return l10n.navGroupOverview;
      case 'group_events':
        return l10n.navGroupEvents;
      case 'group_extensions':
        return l10n.navGroupExtensions;
      case 'group_management':
        return l10n.navGroupManagement;
      case 'group_operations':
        return l10n.navGroupOperations;
      case 'group_system':
        return l10n.navGroupSystem;
      case 'group_tools':
        return l10n.navGroupTools;
    }
    final titles = (v['group_titles'] as Map?)?.cast<String, dynamic>();
    final key = _extLocaleKey(l10n.localeName);
    final byLocale = key == null ? null : titles?[key]?.toString();
    if (byLocale != null && byLocale.isNotEmpty) return byLocale;
    final en = v['group_title_en']?.toString() ?? '';
    if (en.isNotEmpty) return en;
    return v['group_title']?.toString() ?? v['id'].toString();
  }

  /// 跳转 Dashboard 指定页面（go() 定位）
  void _openDashboardPage(Instance inst, String page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DashboardPage(instance: inst, initialPage: page),
      ),
    );
  }

  /// 概览大数字卡跳转到对应注册视图
  void _gotoView(String viewId) {
    final idx = context.read<DetailViewRegistry>().indexOf(viewId);
    if (idx < 0) return;
    setState(() {
      _tabIndex = idx + 1;
      _visited.add(idx + 1);
    });
  }

  Future<void> _refreshHealth() async {
    final inst = _lookup();
    if (inst == null) return;
    final health = await DashboardApi.ping(inst);
    if (!mounted) return;
    context.read<InstanceManager>().setRuntimeState(inst.id, health: health);
  }

  void _start() {
    final inst = _lookup();
    if (inst == null || inst.isRemote) return;
    final mgr = context.read<InstanceManager>();
    mgr.setRuntimeState(
      inst.id,
      status: InstanceStatus.starting,
      clearError: true,
    );
    context.read<RuntimeController>().startInstance(_toData(inst));
    _toast(AppLocalizations.of(context).detailStartingToast);
  }

  void _stop() {
    final inst = _lookup();
    if (inst == null || inst.isRemote) return;
    context.read<RuntimeController>().stopInstance(inst.id);
    _toast(AppLocalizations.of(context).detailStoppedToast);
  }

  void _restart() {
    final inst = _lookup();
    if (inst == null || inst.isRemote) return;
    context.read<RuntimeController>().restartInstance(_toData(inst));
    _toast(AppLocalizations.of(context).detailRestartingToast);
  }

  /// 软重启：调用 Dashboard API restartSdk（保留进程）
  Future<void> _softRestart() async {
    final inst = _lookup();
    if (inst == null) return;
    final msg = AppLocalizations.of(context).detailRestartingToast;
    try {
      await DashboardApi(inst).restartSdk();
      if (mounted) _toast(msg);
    } catch (e) {
      if (mounted) _toast('$e');
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

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openDashboard() {
    final inst = _lookup();
    if (inst == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DashboardPage(instance: inst),
      ),
    );
  }

  Future<void> _copyToken() async {
    final inst = _lookup();
    if (inst == null) return;
    await Clipboard.setData(ClipboardData(text: inst.token));
    if (mounted) _toast(AppLocalizations.of(context).detailTokenCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<InstanceManager>(
      builder: (context, mgr, _) {
        final inst = mgr.findById(widget.instanceId);
        return Scaffold(
          appBar: AppBar(
            title: Text(inst?.name ?? l10n.detailNotFound),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: l10n.dashboardCopyTokenTooltip,
                onPressed: _copyToken,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.detailRefreshState,
                onPressed: _refreshHealth,
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'start') _start();
                  if (v == 'stop') _stop();
                  if (v == 'softRestart') _softRestart();
                  if (v == 'restart') _restart();
                },
                itemBuilder: (_) {
                  final running = inst != null &&
                      (inst.status == InstanceStatus.running ||
                          inst.status == InstanceStatus.starting);
                  final startable = inst != null &&
                      !inst.isRemote &&
                      (inst.status == InstanceStatus.stopped ||
                          inst.status == InstanceStatus.error);
                  return [
                    if (startable)
                      PopupMenuItem(
                        value: 'start',
                        child: Text(l10n.commonStart),
                      ),
                    if (inst != null && !inst.isRemote && running) ...[
                      PopupMenuItem(
                        value: 'stop',
                        child: Text(l10n.commonStop),
                      ),
                    ],
                    if (running) ...[
                      PopupMenuItem(
                        value: 'softRestart',
                        child: Text(l10n.commonSoftRestart),
                      ),
                    ],
                    if (inst != null && !inst.isRemote && running) ...[
                      PopupMenuItem(
                        value: 'restart',
                        child: Text(l10n.commonHardRestart),
                      ),
                    ],
                  ];
                },
              ),
            ],
          ),
          body: inst == null
              ? Center(child: Text(l10n.detailNotFound))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= _wideBreakpoint;
                    return _buildBody(context, l10n, inst, isWide);
                  },
                ),
        );
      },
    );
  }

  /// 布局：PC 宽屏左侧导航 + 内容区（IndexedStack 保留状态），
  /// 移动端顶部 TabBar + TabBarView。视图列表来自 DetailViewRegistry。
  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    Instance inst,
    bool isWide,
  ) {
    return Consumer<DetailViewRegistry>(
      builder: (context, registry, _) {
        final views = registry.views;
        if (isWide) {
          return Row(
            children: [
              _NavRail(
                views: views,
                selectedIndex: _tabIndex,
                onSelect: (i) {
                  // 模块动态视窗：点击直接跳 Dashboard 对应页面
                  if (i > 0 && views[i - 1].id.startsWith('ext-')) {
                    _openDashboardPage(
                      inst,
                      'ext-${views[i - 1].id.substring(4)}',
                    );
                    return;
                  }
                  setState(() {
                    _tabIndex = i;
                    _visited.add(i);
                  });
                },
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    _buildOverview(inst, l10n, isWide),
                    // 懒实例化：未访问过的视图暂不构建，避免启动即拉全部数据
                    for (var i = 0; i < views.length; i++)
                      _visited.contains(i + 1)
                          ? views[i].builder(context, inst)
                          : const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          );
        }
        // 移动端：顶部 TabBar（视图自带 keep-alive，切换保留状态）
        return DefaultTabController(
          length: views.length + 1,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: l10n.detailTabOverview),
                  for (final v in views) Tab(text: v.title(l10n)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildOverview(inst, l10n, false),
                    for (final v in views) v.builder(context, inst),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 概览 Tab：头部 + 系统资源 + 事件 + 连接信息 + 操作。
  /// 宽屏下资源 / 连接与事件卡片并排两列，避免单列长条。
  Widget _buildOverview(
    Instance inst,
    AppLocalizations l10n,
    bool isWide,
  ) {
    final running = inst.status == InstanceStatus.running ||
        inst.status == InstanceStatus.starting;
    final startable = !inst.isRemote &&
        (inst.status == InstanceStatus.stopped ||
            inst.status == InstanceStatus.error);
    final overview = _OverviewCard(
      loading: _loading,
      modules: _modules,
      adapters: _adapters,
      sys: _sys,
      error: _error,
      onlineBots: _onlineBots,
      totalEvents: _totalEvents,
      frameworkInfo: _frameworkInfo,
      onTileTap: _gotoView,
    );
    final stats = _MessageStatsCard(
      loading: _loading,
      stats: _stats,
      error: _error,
    );
    final events = _EventCard(
      loading: _loading,
      events: _events,
      error: _error,
    );
    final connect = _ConnectCard(instance: inst, localAddrs: _localAddrs);
    return RefreshIndicator(
      onRefresh: _refreshHealth,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(instance: inst),
          const SizedBox(height: 12),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      overview,
                      const SizedBox(height: 12),
                      stats,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      events,
                      const SizedBox(height: 12),
                      connect,
                    ],
                  ),
                ),
              ],
            )
          else ...[
            overview,
            const SizedBox(height: 12),
            stats,
            const SizedBox(height: 12),
            events,
            const SizedBox(height: 12),
            connect,
          ],
          const SizedBox(height: 16),
          _ActionSection(
            isWide: isWide,
            onOpenDashboard: _openDashboard,
            onStart: startable ? _start : null,
            onStop: !inst.isRemote && running ? _stop : null,
            onSoftRestart: running ? _softRestart : null,
            onRestart: !inst.isRemote && running ? _restart : null,
          ),
        ],
      ),
    );
  }
}

/// 头部：Logo + 名称 + 状态 / 类型 / 健康
class _Header extends StatelessWidget {
  const _Header({required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        // Logo 为横版图（1672x941），按原始比例完整展示
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/logo.png',
            width: 96,
            height: 54,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 96,
              height: 54,
              color: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.bolt,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      instance.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  StatusDot(
                    status: instance.status,
                    health: instance.isRemote ? instance.health : null,
                    size: 11,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Tag(
                    icon: instance.isRemote
                        ? Icons.cloud_outlined
                        : Icons.phone_android,
                    label: instance.isRemote
                        ? l10n.commonRemote
                        : l10n.commonLocal,
                  ),
                  _Tag(
                    icon: Icons.circle,
                    label: instance.isRemote
                        ? _remoteLabel(l10n, instance.health)
                        : _statusLabel(l10n, instance.status),
                    color: instance.isRemote
                        ? _healthColor(instance.health)
                        : _statusColor(instance.status),
                  ),
                  _Tag(
                    icon: Icons.health_and_safety_outlined,
                    label: _healthLabel(l10n, instance.health),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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

  /// 远程实例的状态标签：由健康度表达（在线/连接中/离线/…）
  static String _remoteLabel(AppLocalizations l10n, InstanceHealth h) =>
      switch (h) {
        InstanceHealth.healthy => l10n.statusOnline,
        InstanceHealth.booting => l10n.statusConnecting,
        InstanceHealth.unauthorized => l10n.statusTokenInvalid,
        InstanceHealth.unreachable => l10n.statusOffline,
        InstanceHealth.unknown => l10n.statusRemoteUnknown,
      };

  static Color _healthColor(InstanceHealth h) => switch (h) {
        InstanceHealth.healthy => Colors.green,
        InstanceHealth.booting => Colors.blue,
        InstanceHealth.unauthorized => Colors.orange,
        InstanceHealth.unreachable => Colors.red,
        InstanceHealth.unknown => Colors.grey,
      };

  static Color _statusColor(InstanceStatus s) => switch (s) {
        InstanceStatus.running => Colors.green,
        InstanceStatus.starting => Colors.blue,
        InstanceStatus.error => Colors.red,
        InstanceStatus.destroying => Colors.orange,
        InstanceStatus.stopped => Colors.grey,
      };
}

/// 小标签
class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: c),
          ),
        ],
      ),
    );
  }
}

/// Dashboard 运行概览卡：
/// 顶部大数字统计 4 格（适配器 / 模块 / 在线机器人 / 事件总数，可点击跳转）
/// + 版本行（ErisPulse · Python）+ 系统资源（CPU/内存告警变色 + 运行时长）
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.loading,
    required this.modules,
    required this.adapters,
    required this.sys,
    required this.error,
    required this.onlineBots,
    required this.totalEvents,
    required this.frameworkInfo,
    required this.onTileTap,
  });

  final bool loading;
  final List<ModuleInfo> modules;
  final List<AdapterInfo> adapters;
  final SystemInfo? sys;
  final String? error;
  final int onlineBots;
  final int totalEvents;
  final Map<String, dynamic>? frameworkInfo;
  final ValueChanged<String> onTileTap;

  /// CPU / 内存告警变色（对齐 Dashboard：>60% 橙 / >85% 红）
  static Color _levelColor(int percent, Color base) {
    if (percent > 85) return Colors.red;
    if (percent > 60) return Colors.orange;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final enabledModules = modules.where((m) => m.enabled).length;
    final runningAdapters = adapters.where((a) => a.running).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.query_stats,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(l10n.detailOverview, style: theme.textTheme.titleSmall),
                const Spacer(),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(
                error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            else if (modules.isEmpty && adapters.isEmpty && sys == null)
              Text(
                l10n.detailResourceHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              // 大数字统计 4 格（宽屏 1 行，窄屏 2x2），点击跳转对应视图
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 420;
                  final tiles = <Widget>[
                    _StatTile(
                      icon: Icons.devices_outlined,
                      value: '${adapters.length}',
                      label: l10n.detailAdapters,
                      subtitle: l10n.detailRunningCount(runningAdapters),
                      onTap: () => onTileTap('adapters'),
                    ),
                    _StatTile(
                      icon: Icons.extension_outlined,
                      value: '${modules.length}',
                      label: l10n.detailModules,
                      subtitle: l10n.detailEnabledCount(enabledModules),
                      onTap: () => onTileTap('modules'),
                    ),
                    _StatTile(
                      icon: Icons.smart_toy_outlined,
                      value: '$onlineBots',
                      label: l10n.detailOnlineBots,
                      onTap: () => onTileTap('bots'),
                    ),
                    _StatTile(
                      icon: Icons.event_note_outlined,
                      value: '$totalEvents',
                      label: l10n.detailTotalEvents,
                      onTap: () => onTileTap('events'),
                    ),
                  ];
                  if (wide) {
                    return Row(
                      children: [
                        for (var i = 0; i < tiles.length; i++) ...[
                          Expanded(child: tiles[i]),
                          if (i < tiles.length - 1) const SizedBox(width: 8),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Row(children: [tiles[0], tiles[1]]),
                      const SizedBox(height: 4),
                      Row(children: [tiles[2], tiles[3]]),
                    ],
                  );
                },
              ),
              if (frameworkInfo != null) ...[
                const Divider(height: 16),
                Text(
                  'ErisPulse v${frameworkInfo!['version'] ?? '?'}'
                  ' · Python ${frameworkInfo!['python_version'] ?? '?'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              if (sys != null) ...[
                const SizedBox(height: 12),
                _ResourceBar(
                  label: 'CPU',
                  percent: sys!.cpuPercentInt,
                  color: _levelColor(sys!.cpuPercentInt, Colors.blue),
                ),
                const SizedBox(height: 10),
                _ResourceBar(
                  label:
                      '${l10n.detailMemory} (${sys!.memoryOfSystemReadable})',
                  percent: sys!.memoryPercentInt,
                  color: _levelColor(sys!.memoryPercentInt, Colors.green),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _ResourceValue(
                      label: l10n.detailUptime,
                      value: sys!.uptimeReadable,
                    ),
                    _ResourceValue(
                      label: 'PID',
                      value: '${sys!.pid ?? '-'}',
                    ),
                    _ResourceValue(
                      label: l10n.detailThreads,
                      value: '${sys!.threadCount ?? '-'}',
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// 大数字统计格（对齐 Dashboard statCard：图标 + 大数字 + 标签 + 副文本）
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: c.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: c.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 资源进度条
class _ResourceBar extends StatelessWidget {
  const _ResourceBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // label 占整行（左侧名称/右侧百分比），进度条独占下一整行：
    // 内存 label 较长（如 `内存 (85.5 MB / 15 GB)`），窄列布局会换行
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$percent%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

/// 资源文本值
class _ResourceValue extends StatelessWidget {
  const _ResourceValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ConnectCard extends StatelessWidget {
  const _ConnectCard({
    required this.instance,
    required this.localAddrs,
  });

  final Instance instance;
  final List<InternetAddress> localAddrs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final mono = theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    final v4 =
        localAddrs.where((a) => a.type == InternetAddressType.IPv4).toList();
    final v6 =
        localAddrs.where((a) => a.type == InternetAddressType.IPv6).toList();

    final rows = <Widget>[
      _Row(
        label: l10n.detailAddress,
        child: Text(
          instance.displayAddress,
          style: mono,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];
    if (!instance.isRemote) {
      rows.add(
        _Row(
          label: l10n.detailPort,
          child: Text(
            '${instance.port}',
            style: mono,
          ),
        ),
      );
      if (v4.isNotEmpty) {
        rows.add(
          _Row(
            label: 'IPv4',
            child: _MaskedValue(text: v4.first.address),
          ),
        );
      }
      if (v6.isNotEmpty) {
        rows.add(
          _Row(
            label: 'IPv6',
            child: _MaskedValue(text: v6.first.address),
          ),
        );
      }
      // 桌面：实例绑定的 SDK 版本（创建时设置，只读）
      if (!Platform.isAndroid && !Platform.isIOS) {
        rows.add(
          _Row(
            label: l10n.detailRuntimeLabel,
            child: Text(
              instance.runtimeVersion ?? l10n.createRuntimeDefault,
              style: mono,
            ),
          ),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: rows),
      ),
    );
  }
}

/// 信息行
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 掩码值：默认显示圆点，点击后完整显示 3 秒并复制到剪贴板。
class _MaskedValue extends StatefulWidget {
  const _MaskedValue({required this.text});
  final String text;

  @override
  State<_MaskedValue> createState() => _MaskedValueState();
}

class _MaskedValueState extends State<_MaskedValue> {
  bool _revealed = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTap() {
    setState(() => _revealed = true);
    Clipboard.setData(ClipboardData(text: widget.text));
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _revealed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: AppLocalizations.of(context).detailTapToReveal,
      child: InkWell(
        onTap: _onTap,
        borderRadius: BorderRadius.circular(4),
        child: Text(
          _revealed ? widget.text : '••••••••',
          style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// 最近事件卡（轮询 Dashboard /api/events）
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.loading,
    required this.events,
    required this.error,
  });

  final bool loading;
  final List<Map<String, dynamic>> events;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_note_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.detailRecentEvents,
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (error != null)
              Text(
                error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            else if (events.isEmpty)
              Text(
                l10n.detailNoEvents,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              // 概览最多 10 条、每条至多 2 行，控制卡片高度
              for (final e in events.take(10))
                _EventLine(event: e, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

/// 消息统计卡（/api/message-stats：总事件 / 按类型 / 按平台 / 24h 趋势）
class _MessageStatsCard extends StatelessWidget {
  const _MessageStatsCard({
    required this.loading,
    required this.stats,
    required this.error,
  });

  final bool loading;
  final Map<String, dynamic>? stats;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final byType = (stats?['by_type'] as Map?)?.cast<String, dynamic>() ?? {};
    final byPlatform =
        (stats?['by_platform'] as Map?)?.cast<String, dynamic>() ?? {};
    final hourly = (stats?['hourly'] as Map?)?.cast<String, dynamic>() ?? {};
    final total = stats?['total_events'];
    final hasData =
        byType.isNotEmpty || byPlatform.isNotEmpty || hourly.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(l10n.statsTitle, style: theme.textTheme.titleSmall),
                const Spacer(),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(
                error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            else if (!hasData)
              Text(
                l10n.detailNoEvents,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              _TrendBars(hourly: hourly, label: l10n.statsTrend),
              if (total != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      l10n.statsTotalEvents,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$total',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              if (byType.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.statsByType,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                _StatChips(map: byType),
              ],
              if (byPlatform.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.statsByPlatform,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                _StatChips(map: byPlatform),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// 24h 消息趋势柱状图（hourly：{整点unix秒: 计数}）
class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.hourly, required this.label});
  final Map<String, dynamic> hourly;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final bars = <(int, int)>[]; // (count, hourLabel)
    for (var h = 23; h >= 0; h--) {
      final t = now.subtract(Duration(hours: h));
      final key = (t.millisecondsSinceEpoch ~/ 1000 ~/ 3600) * 3600;
      final v = hourly[key.toString()];
      final count = v is num ? v.toInt() : 0;
      bars.add((count, t.hour));
    }
    final maxCount = bars.map((b) => b.$1).fold(1, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final b in bars)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      height: math.max(2, 52.0 * b.$1 / maxCount),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: b.$1 == 0 ? 0.15 : 0.6),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 计数 chips（type/platform -> count）
class _StatChips extends StatelessWidget {
  const _StatChips({required this.map});
  final Map<String, dynamic> map;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final e in map.entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${e.key} · ${e.value}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// 单条事件
class _EventLine extends StatelessWidget {
  const _EventLine({required this.event, required this.maxLines});
  final Map<String, dynamic> event;
  final int maxLines;

  /// 后端事件 time 为 Unix 秒（float），转本地 HH:mm:ss
  static String _time(Map<String, dynamic> e) {
    final t = e['time'] ?? e['timestamp'] ?? e['created_at'];
    if (t is num) {
      final sec = t.toInt();
      final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final ss = dt.second.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
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
    // 优先显式 message 字段（旧结构）
    final m = e['message'] ?? e['detail'] ?? e['data'];
    if (m is String && m.isNotEmpty) return m;
    // 后端事件无 message：组合 platform/detail_type/sub_type/账号 生成可读描述
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
    final theme = Theme.of(context);
    final time = _time(event);
    final type = _type(event);
    final message = _message(event);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              type,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// 操作区：打开 Dashboard 主按钮；PC 宽屏额外显示启停 / 重启按钮组
/// （移动端启停走右上角菜单）。
class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.isWide,
    required this.onOpenDashboard,
    this.onStart,
    this.onStop,
    this.onSoftRestart,
    this.onRestart,
  });

  final bool isWide;
  final VoidCallback onOpenDashboard;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onSoftRestart;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showActions = isWide &&
        (onStart != null ||
            onStop != null ||
            onSoftRestart != null ||
            onRestart != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onOpenDashboard,
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              l10n.detailOpenDashboard,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        if (showActions) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onStart != null)
                FilledButton.tonalIcon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.commonStart),
                ),
              if (onStop != null)
                OutlinedButton.icon(
                  onPressed: onStop,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.stop),
                  label: Text(l10n.commonStop),
                ),
              if (onSoftRestart != null)
                OutlinedButton.icon(
                  onPressed: onSoftRestart,
                  icon: const Icon(Icons.autorenew),
                  label: Text(l10n.commonSoftRestart),
                ),
              if (onRestart != null)
                OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.commonHardRestart),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// PC 宽屏左侧导航：概览 + 注册视图列表
class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.views,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<InstanceView> views;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 分组去重：仅当视图声明的分组与当前分组不同才渲染新标题，
    // 避免固定概览项与 bots 视图（同属概览组）出现两个"概览"
    String? currentGroup = l10n.navGroupOverview;
    final navItems = <Widget>[
      _NavGroupHeader(currentGroup),
      _NavItem(
        icon: Icons.space_dashboard_outlined,
        title: l10n.detailTabOverview,
        selected: selectedIndex == 0,
        onTap: () => onSelect(0),
      ),
    ];
    for (var i = 0; i < views.length; i++) {
      final g = views[i].group?.call(l10n);
      if (g != null && g != currentGroup) {
        navItems.add(_NavGroupHeader(g));
        currentGroup = g;
      }
      navItems.add(
        _NavItem(
          icon: views[i].icon,
          iconSvg: views[i].iconSvg,
          title: views[i].title(l10n),
          selected: selectedIndex == i + 1,
          onTap: () => onSelect(i + 1),
        ),
      );
    }
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: 208,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: navItems,
        ),
      ),
    );
  }
}

/// 导航分组标题（对齐 Dashboard 侧边栏的分组颗粒度）
class _NavGroupHeader extends StatelessWidget {
  const _NavGroupHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

/// 单个导航项
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.iconSvg,
  });

  final IconData icon;

  /// 模块视窗注册的 SVG 图标（非空时优先渲染）
  final String? iconSvg;

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (iconSvg != null && iconSvg!.isNotEmpty)
              SvgPicture.string(
                iconSvg!,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              )
            else
              Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 模块动态视窗入口（移动端 TabBar 内容）。
///
/// 桌面端点击导航项已直接跳转 Dashboard；移动端 Tab 无法拦截点击，
/// 显示中转页由用户点按钮打开（视窗内容由 Dashboard 渲染）。
class _ModuleViewEntry extends StatelessWidget {
  const _ModuleViewEntry({
    required this.instance,
    required this.page,
    required this.data,
  });

  final Instance instance;
  final String page;
  final Map<String, dynamic> data;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DashboardPage(instance: instance, initialPage: page),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              data['title']?.toString() ?? data['id'].toString(),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.moduleViewOpenHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _open(context),
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.moduleViewOpenButton),
            ),
          ],
        ),
      ),
    );
  }
}
