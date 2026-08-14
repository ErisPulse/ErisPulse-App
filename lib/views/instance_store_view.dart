// 模块商店视图（详情页"商店"注册视图）。
//
// 对齐 Dashboard 前端 store 页结构：
// - Tab 1 商店浏览：搜索（防抖）/ 类型过滤 / 标签多选筛选 / 强制刷新 /
//   安装 / 升级 / 包详情（PyPI 元信息 + 指定版本安装）
// - Tab 2 包管理：已安装（升级 / 卸载 / 框架更新）、可更新（单包 / 全部升级）、
//   安装新包（支持 `pkg==1.0` 与 `git+` URL）、Git 包列表与升级
// 安装 / 升级为后台 pip 任务：提交后拿 task_id 轮询
// `/store/install/status`，在进度对话框中展示输出（running/success/error/timeout）。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../services/instance_manager.dart';
import '../widgets/states.dart';

/// 商店视图：商店浏览 + 包管理
class InstanceStoreView extends StatelessWidget {
  final Instance instance;
  const InstanceStoreView({super.key, required this.instance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.storeBrowseTab),
              Tab(text: l10n.storePackagesTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _StoreBrowseTab(instance: instance),
                _StorePackagesTab(instance: instance),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 通用：任务选项 / 确认框 / 进度对话框
// ---------------------------------------------------------------------------

/// 安装/升级任务选项（确认框返回值）
class _TaskOptions {
  const _TaskOptions({this.indexUrl, this.force = false});
  final String? indexUrl;
  final bool force;
}

/// 安装/升级确认框：可选 pip 镜像源 + 强制重装（升级任务无 force）
class _OptionsDialog extends StatefulWidget {
  const _OptionsDialog({
    required this.title,
    required this.packages,
    required this.upgrade,
  });

  final String title;
  final List<String> packages;
  final bool upgrade;

  @override
  State<_OptionsDialog> createState() => _OptionsDialogState();
}

class _OptionsDialogState extends State<_OptionsDialog> {
  final _mirrorCtrl = TextEditingController();
  bool _force = false;

  @override
  void dispose() {
    _mirrorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.packages.join(', '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mirrorCtrl,
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.storeMirror,
              hintText: 'https://pypi.tuna.tsinghua.edu.cn/simple',
              border: const OutlineInputBorder(),
            ),
          ),
          if (!widget.upgrade)
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.storeForce),
              value: _force,
              onChanged: (v) => setState(() => _force = v),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _TaskOptions(indexUrl: _mirrorCtrl.text.trim(), force: _force),
          ),
          child: Text(
            widget.upgrade ? l10n.storeUpgrade : l10n.detailPackageInstall,
          ),
        ),
      ],
    );
  }
}

/// 后台任务进度对话框：轮询 `/store/install/status` 展示状态与 pip 输出。
///
/// 关闭对话框不会终止服务端任务（pip 进程由 Dashboard 托管）。
class _TaskProgressDialog extends StatefulWidget {
  const _TaskProgressDialog({required this.api, required this.taskId});

  final DashboardApi api;
  final String taskId;

  @override
  State<_TaskProgressDialog> createState() => _TaskProgressDialogState();
}

class _TaskProgressDialogState extends State<_TaskProgressDialog> {
  Timer? _timer;
  String _status = 'running';
  List<String> _lines = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final info = await widget.api.getInstallStatus(widget.taskId);
      if (!mounted) return;
      final status = info['status']?.toString() ?? 'running';
      final output =
          (info['output'] as List?)?.map((l) => l.toString()).toList() ??
              const <String>[];
      setState(() {
        _status = status;
        _lines = output;
        _error = info['error']?.toString();
      });
      if (status != 'running') {
        _timer?.cancel();
      }
    } catch (_) {
      // 轮询失败保持当前状态，下个周期重试
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final done = _status != 'running';
    final ok = _status == 'success';
    final raw = (_error != null && _error!.isNotEmpty && _lines.isEmpty)
        ? _error!.split('\n')
        : _lines;
    final shown = raw.length > 15 ? raw.sublist(raw.length - 15) : raw;
    return AlertDialog(
      title: Row(
        children: [
          if (!done)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              ok ? Icons.check_circle : Icons.error,
              size: 20,
              color: ok ? Colors.green : theme.colorScheme.error,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ok
                  ? l10n.storeTaskSuccess
                  : done
                      ? l10n.storeTaskFailed
                      : l10n.storeTaskRunning,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.taskId,
              style:
                  theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            if (shown.isEmpty)
              Text(l10n.storeTaskRunning, style: theme.textTheme.bodySmall)
            else
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    shown.join('\n'),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (done)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonConfirm),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
      ],
    );
  }
}

/// 安装/升级执行流：确认（镜像/force）→ 提交任务 → 进度对话框 → 完成回调
Future<void> _runTaskFlow(
  BuildContext context, {
  required DashboardApi api,
  required String title,
  required List<String> packages,
  required bool upgrade,
  required Future<String> Function(_TaskOptions opts) submit,
  required VoidCallback onDone,
}) async {
  final opts = await showDialog<_TaskOptions>(
    context: context,
    builder: (ctx) =>
        _OptionsDialog(title: title, packages: packages, upgrade: upgrade),
  );
  if (opts == null) return;
  try {
    final taskId = await submit(opts);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TaskProgressDialog(api: api, taskId: taskId),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  } finally {
    if (context.mounted) onDone();
  }
}

// ---------------------------------------------------------------------------
// Tab 1：商店浏览
// ---------------------------------------------------------------------------

/// 商店条目（注册表 modules/adapters 拍平后的统一结构）
class _StorePkg {
  _StorePkg({
    required this.name,
    required this.type,
    this.package = '',
    this.version = '',
    this.description = '',
    this.tags = const [],
    this.official = false,
  });

  final String name;
  final String type; // module | adapter
  final String package;
  final String version;
  final String description;
  final List<String> tags;
  final bool official;
}

class _StoreBrowseTab extends StatefulWidget {
  const _StoreBrowseTab({required this.instance});

  final Instance instance;

  @override
  State<_StoreBrowseTab> createState() => _StoreBrowseTabState();
}

class _StoreBrowseTabState extends State<_StoreBrowseTab>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<_StorePkg> _items = [];
  Map<String, String> _installed = {};
  List<String> _allTags = [];
  bool _loading = true;
  String? _error;

  String _query = '';
  String _type = 'all';
  final Set<String> _selectedTags = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  DashboardApi get _api => DashboardApi(widget.instance);

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await _api.getStoreRemote(force: force);
      final packages =
          (json['packages'] as Map?)?.cast<String, dynamic>() ?? {};
      final modules =
          (packages['modules'] as Map?)?.cast<String, dynamic>() ?? {};
      final adapters =
          (packages['adapters'] as Map?)?.cast<String, dynamic>() ?? {};
      final items = <_StorePkg>[
        for (final e in modules.entries) _pkg(e.key, 'module', e.value),
        for (final e in adapters.entries) _pkg(e.key, 'adapter', e.value),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final installed = <String, String>{};
      (json['installed_versions'] as Map?)?.forEach((k, v) {
        installed[k.toString().toLowerCase()] = v?.toString() ?? '';
      });
      final tags = <String>[];
      for (final i in items) {
        for (final t in i.tags) {
          if (t.isNotEmpty && !tags.contains(t)) tags.add(t);
        }
      }
      tags.sort();
      if (!mounted) return;
      setState(() {
        _items = items;
        _installed = installed;
        _allTags = tags;
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

  static _StorePkg _pkg(String name, String type, dynamic raw) {
    final m = raw is Map ? raw : const <String, dynamic>{};
    final tags = (m['tags'] as List?)
            ?.map((t) => t.toString())
            .where((t) => t.isNotEmpty)
            .toList() ??
        const <String>[];
    return _StorePkg(
      name: name,
      type: type,
      package: m['package']?.toString() ?? '',
      version: m['version']?.toString() ?? '',
      description: m['description']?.toString() ?? '',
      tags: tags,
      official: m['official'] == true,
    );
  }

  bool get _filterActive =>
      _query.trim().isNotEmpty || _type != 'all' || _selectedTags.isNotEmpty;

  List<_StorePkg> get _visible {
    final q = _query.trim().toLowerCase();
    return _items.where((p) {
      if (_type != 'all' && p.type != _type) return false;
      if (_selectedTags.isNotEmpty && !_selectedTags.every(p.tags.contains)) {
        return false;
      }
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.package.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = v);
    });
  }

  Future<void> _install(_StorePkg p) => _runTaskFlow(
        context,
        api: _api,
        title: p.name,
        packages: [p.package],
        upgrade: false,
        submit: (opts) => _api.storeInstall(
          [p.package],
          force: opts.force,
          indexUrl: opts.indexUrl,
        ),
        onDone: () => _load(force: true),
      );

  Future<void> _upgrade(_StorePkg p) => _runTaskFlow(
        context,
        api: _api,
        title: p.name,
        packages: [p.package],
        upgrade: true,
        submit: (opts) =>
            _api.upgradePackages([p.package], indexUrl: opts.indexUrl),
        onDone: () => _load(force: true),
      );

  Future<void> _openDetail(_StorePkg p) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _PkgDetailDialog(instance: widget.instance, pkg: p),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final visible = _visible;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.storeSearch,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _type,
                  borderRadius: BorderRadius.circular(8),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(l10n.storeTypeAll),
                    ),
                    DropdownMenuItem(
                      value: 'module',
                      child: Text(l10n.storeTypeModule),
                    ),
                    DropdownMenuItem(
                      value: 'adapter',
                      child: Text(l10n.storeTypeAdapter),
                    ),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'all'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.storeForceRefresh,
                onPressed: () => _load(force: true),
              ),
            ],
          ),
        ),
        if (_allTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Wrap(
              spacing: 6,
              children: [
                for (final t in _allTags)
                  FilterChip(
                    label: Text(t, style: theme.textTheme.labelSmall),
                    selected: _selectedTags.contains(t),
                    onSelected: (sel) => setState(() {
                      sel ? _selectedTags.add(t) : _selectedTags.remove(t);
                    }),
                  ),
              ],
            ),
          ),
        const Divider(height: 10),
        Expanded(
          child: _loading
              ? const LoadingView()
              : visible.isEmpty
                  ? EmptyState(
                      icon: Icons.storefront_outlined,
                      title: _filterActive
                          ? l10n.storeFilteredEmpty
                          : l10n.storeEmpty,
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(force: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: visible.length,
                        itemBuilder: (context, i) => _card(visible[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _card(_StorePkg p) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final instVer = _installed[p.package.toLowerCase()];
    final installed = instVer != null && instVer.isNotEmpty;
    final hasUpdate = installed && instVer != p.version;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _TypeChip(type: p.type),
                if (p.official) ...[
                  const SizedBox(width: 4),
                  Chip(
                    label: Text(
                      l10n.storeOfficial,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ],
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.info_outline, size: 20),
                  tooltip: l10n.storeDetail,
                  onPressed: () => _openDetail(p),
                ),
              ],
            ),
            if (p.package.isNotEmpty)
              Text(
                p.package,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (p.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                p.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (p.tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final t in p.tags)
                    Chip(
                      label: Text(
                        t,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: hasUpdate
                      ? Text(
                          '${l10n.storeUpdateAvailable}: '
                          'v$instVer → v${p.version}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                        )
                      : installed
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${l10n.storeInstalled} v$instVer',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'v${p.version}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                ),
                if (!installed)
                  FilledButton.tonalIcon(
                    onPressed: () => _install(p),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(l10n.detailPackageInstall),
                  )
                else if (hasUpdate)
                  FilledButton.tonalIcon(
                    onPressed: () => _upgrade(p),
                    icon: const Icon(Icons.upgrade, size: 18),
                    label: Text(l10n.storeUpgrade),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// module / adapter 类型小徽章
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final module = type == 'module';
    return Chip(
      label: Text(
        module ? l10n.storeTypeModule : l10n.storeTypeAdapter,
        style: theme.textTheme.labelSmall?.copyWith(
          color:
              module ? theme.colorScheme.primary : theme.colorScheme.tertiary,
        ),
      ),
      visualDensity: VisualDensity.compact,
      backgroundColor:
          (module ? theme.colorScheme.primary : theme.colorScheme.tertiary)
              .withValues(alpha: 0.1),
    );
  }
}

// ---------------------------------------------------------------------------
// 包详情对话框
// ---------------------------------------------------------------------------

class _PkgDetailDialog extends StatefulWidget {
  const _PkgDetailDialog({required this.instance, required this.pkg});

  final Instance instance;
  final _StorePkg pkg;

  @override
  State<_PkgDetailDialog> createState() => _PkgDetailDialogState();
}

class _PkgDetailDialogState extends State<_PkgDetailDialog> {
  Map<String, dynamic>? _detail;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DashboardApi get _api => DashboardApi(widget.instance);

  Future<void> _load() async {
    try {
      final d = await _api.getPackageDetail(widget.pkg.package);
      if (mounted) setState(() => _detail = d);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _installVersion(String version) async {
    final l10n = AppLocalizations.of(context);
    final spec = '${widget.pkg.package}==$version';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.storeVersionInstall),
        content: Text(spec),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.detailPackageInstall),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final taskId = await _api.storeInstall([spec]);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TaskProgressDialog(api: _api, taskId: taskId),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _str(Map<String, dynamic> m, String key) =>
      m[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = _detail;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(widget.pkg.name)),
          _TypeChip(type: widget.pkg.type),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: _error != null
            ? ErrorView(message: _error!, onRetry: _load)
            : d == null
                ? const LoadingView()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                '${l10n.storeCurrent}: '
                                'v${_str(d, 'installed_version')}',
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 6),
                            Chip(
                              label: Text(
                                '${l10n.storeLatest}: '
                                'v${_str(d, 'latest_version')}',
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_str(d, 'summary').isNotEmpty) ...[
                          Text(
                            _str(d, 'summary'),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_str(d, 'description').isNotEmpty) ...[
                          Text(
                            _str(d, 'description'),
                            style: theme.textTheme.bodySmall,
                            maxLines: 12,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                        ],
                        _row(l10n.storeAuthor, _str(d, 'author')),
                        _row(l10n.storeLicense, _str(d, 'license')),
                        _row(l10n.storeHomepage, _str(d, 'home_page')),
                        if ((d['requires_dist'] as List?)?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.storeRequires,
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (d['requires_dist'] as List)
                                .map((r) => r.toString())
                                .join('\n'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                        if ((d['versions'] as List?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.storeVersions,
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          if (_busy)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final v in (d['versions'] as List))
                                  ActionChip(
                                    label: Text(v.toString()),
                                    onPressed: () =>
                                        _installVersion(v.toString()),
                                  ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonConfirm),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2：包管理（已安装 / 可更新 / 安装新包 / Git）
// ---------------------------------------------------------------------------

class _StorePackagesTab extends StatefulWidget {
  const _StorePackagesTab({required this.instance});

  final Instance instance;

  @override
  State<_StorePackagesTab> createState() => _StorePackagesTabState();
}

class _StorePackagesTabState extends State<_StorePackagesTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _updates = [];
  Map<String, dynamic>? _git;
  bool _gitLoading = false;
  bool _loading = true;
  String? _error;
  bool _busy = false;

  final _newPkgCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newPkgCtrl.dispose();
    super.dispose();
  }

  DashboardApi get _api => DashboardApi(widget.instance);

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final packages = await _api.getPackages();
      List<Map<String, dynamic>> updates = [];
      try {
        updates = await _api.getPackageUpdates(force: force);
      } catch (_) {
        // 更新检查失败不阻塞已装列表
      }
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _updates = updates;
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

  Future<void> _loadGit() async {
    setState(() => _gitLoading = true);
    try {
      final git = await _api.getGitPackages();
      if (!mounted) return;
      setState(() {
        _git = git;
        _gitLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _gitLoading = false);
    }
  }

  Map<String, dynamic>? _updateFor(String name) {
    for (final u in _updates) {
      if (u['name']?.toString().toLowerCase() == name.toLowerCase()) return u;
    }
    return null;
  }

  List<Map<String, dynamic>> _mapList(Map<String, dynamic>? m, String key) =>
      (m?[key] as List?)
          ?.map((e) => e is Map<String, dynamic> ? e : null)
          .whereType<Map<String, dynamic>>()
          .toList() ??
      const <Map<String, dynamic>>[];

  // ---- 操作 ----

  Future<void> _upgradeOne(String name, {String? gitUrl}) => _runTaskFlow(
        context,
        api: _api,
        title: name,
        packages: gitUrl != null ? [gitUrl] : [name],
        upgrade: true,
        submit: (_) => gitUrl != null
            ? _api.upgradeGitPackage(gitUrl)
            : _api.upgradePackages([name]),
        onDone: () {
          _load(force: true);
          if (gitUrl != null) _loadGit();
        },
      );

  Future<void> _upgradeAll() => _runTaskFlow(
        context,
        api: _api,
        title: AppLocalizations.of(context).pkgUpgradeAll,
        packages: [for (final u in _updates) u['name']?.toString() ?? ''],
        upgrade: true,
        submit: (opts) => _api.upgradePackages(
          [for (final u in _updates) u['name']?.toString() ?? ''],
          indexUrl: opts.indexUrl,
        ),
        onDone: () => _load(force: true),
      );

  Future<void> _uninstall(String name) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.detailPackageUninstall),
        content: Text(l10n.detailPackageUninstallConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.error,
              ),
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _api.uninstallPackage(name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) await _load(force: true);
  }

  Future<void> _installNew() async {
    final spec = _newPkgCtrl.text.trim();
    if (spec.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    await _runTaskFlow(
      context,
      api: _api,
      title: l10n.pkgInstallNewTab,
      packages: [spec],
      upgrade: false,
      submit: (opts) => spec.startsWith('git+')
          ? _api.installPackages(
              [spec],
              force: opts.force,
              indexUrl: opts.indexUrl,
            )
          : _api.storeInstall(
              [spec],
              force: opts.force,
              indexUrl: opts.indexUrl,
            ),
      onDone: () {
        _newPkgCtrl.clear();
        _load(force: true);
        _loadGit();
      },
    );
  }

  // ---- 构建 ----

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_loading) return const LoadingView();
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.pkgInstalledTab),
              Tab(text: l10n.pkgUpdatesTab),
              Tab(text: l10n.pkgInstallNewTab),
              Tab(text: l10n.pkgGitTab),
            ],
          ),
          Expanded(
            child: AbsorbPointer(
              absorbing: _busy,
              child: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: () => _load(force: true),
                    child: _buildInstalled(l10n),
                  ),
                  RefreshIndicator(
                    onRefresh: () => _load(force: true),
                    child: _buildUpdates(l10n),
                  ),
                  _buildInstallNew(l10n),
                  RefreshIndicator(
                    onRefresh: _loadGit,
                    child: _buildGit(l10n),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstalled(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final p in _packages)
          ListTile(
            dense: true,
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(p['name']?.toString() ?? '?'),
            subtitle: Text(
              [
                if (p['version'] != null) 'v${p['version']}',
                if (p['summary'] != null) p['summary'].toString(),
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_updateFor(p['name']?.toString() ?? '') != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: OutlinedButton(
                      onPressed: () => _upgradeOne(p['name']?.toString() ?? ''),
                      child: Text(l10n.storeUpgrade),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.detailPackageUninstall,
                  onPressed: () => _uninstall(p['name']?.toString() ?? ''),
                ),
              ],
            ),
          ),
        const Divider(height: 24),
        Text(l10n.detailFrameworkUpdate, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        _FrameworkCard(instance: widget.instance),
      ],
    );
  }

  Widget _buildUpdates(AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (_updates.isEmpty) {
      return ListView(
        children: [
          EmptyState(
            icon: Icons.system_update_alt,
            title: l10n.pkgNoUpdates,
          ),
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _upgradeAll,
              icon: const Icon(Icons.upgrade),
              label: Text(l10n.pkgUpgradeAll),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _updates.length,
            itemBuilder: (context, i) {
              final u = _updates[i];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.system_update),
                title: Text(u['name']?.toString() ?? '?'),
                subtitle: Text(
                  'v${u['current']} → v${u['latest']}'
                  '${u['source'] != null ? ' · ${u['source']}' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: OutlinedButton(
                  onPressed: () => _upgradeOne(u['name']?.toString() ?? ''),
                  child: Text(l10n.storeUpgrade),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInstallNew(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _newPkgCtrl,
          decoration: InputDecoration(
            labelText: l10n.detailPackageName,
            hintText: 'ErisPulse-XXX · pkg==1.0.0 · git+https://…',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.inventory_2_outlined),
          ),
          onSubmitted: (_) => _installNew(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: _installNew,
            icon: const Icon(Icons.download),
            label: Text(l10n.detailPackageInstall),
          ),
        ),
      ],
    );
  }

  Widget _buildGit(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final pkgs = _mapList(_git, 'packages');
    final ups = _mapList(_git, 'updates');
    if (_gitLoading && pkgs.isEmpty && ups.isEmpty) {
      return const LoadingView();
    }
    if (pkgs.isEmpty && ups.isEmpty) {
      return ListView(
        children: [
          EmptyState(icon: Icons.call_split_outlined, title: l10n.pkgNoGit),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (ups.isNotEmpty) ...[
          Text(l10n.pkgUpdatesTab, style: theme.textTheme.titleSmall),
          for (final u in ups)
            ListTile(
              dense: true,
              leading: const Icon(Icons.system_update),
              title: Text(u['name']?.toString() ?? '?'),
              subtitle: Text(
                'v${u['current']} → v${u['latest']}',
                style: theme.textTheme.bodySmall,
              ),
              trailing: OutlinedButton(
                onPressed: () => _upgradeOne(
                  u['name']?.toString() ?? '',
                  gitUrl: u['git_url']?.toString(),
                ),
                child: Text(l10n.storeUpgrade),
              ),
            ),
          const Divider(height: 24),
        ],
        Text(l10n.pkgGitTab, style: theme.textTheme.titleSmall),
        for (final g in pkgs)
          ListTile(
            dense: true,
            leading: const Icon(Icons.call_split_outlined),
            title: Text(g['name']?.toString() ?? '?'),
            subtitle: Text(
              [
                g['git_url']?.toString(),
                if (g['installed_version'] != null)
                  'v${g['installed_version']}',
              ].whereType<String>().join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 框架更新卡（原 PackagesTab 逻辑迁移）
// ---------------------------------------------------------------------------

class _FrameworkCard extends StatefulWidget {
  const _FrameworkCard({required this.instance});

  final Instance instance;

  @override
  State<_FrameworkCard> createState() => _FrameworkCardState();
}

class _FrameworkCardState extends State<_FrameworkCard> {
  Map<String, dynamic>? _framework;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DashboardApi get _api => DashboardApi(widget.instance);

  Future<void> _load() async {
    try {
      final fw = await _api.getFrameworkStatus();
      if (mounted) setState(() => _framework = fw);
    } catch (_) {
      if (mounted) setState(() => _framework = null);
    }
  }

  /// 后端 `/framework/versions` 无 `latest` 字段：
  /// 最新可用版本为 `versions` 首个（仅当 `can_update` 为真）。
  String? _latestAvailable() {
    final fw = _framework;
    if (fw?['can_update'] != true) return null;
    final versions = (fw?['versions'] as List?)?.cast<String>();
    if (versions == null || versions.isEmpty) return null;
    return versions.first;
  }

  String _statusText(AppLocalizations l10n) {
    final fw = _framework;
    if (fw == null) return l10n.detailTabEmpty;
    final current = fw['current']?.toString() ?? '?';
    final latest = _latestAvailable();
    if (latest == null) return 'v$current · ${l10n.detailFrameworkLatest}';
    return 'v$current → v$latest';
  }

  Future<void> _update() async {
    final latest = _latestAvailable();
    if (latest == null) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.detailFrameworkUpdate),
        content: Text(l10n.detailFrameworkUpdateConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _api.updateFramework(version: latest);
      await _load();
      if (!mounted) return;
      final current = _framework?['current']?.toString();
      if (current != null && current.isNotEmpty) {
        await context
            .read<InstanceManager>()
            .setInstanceRuntime(widget.instance.id, current);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restartSdk() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.detailSdkRestart),
        content: Text(l10n.detailSdkRestartConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _api.restartSdk();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.system_update_alt),
          title: Text(_statusText(l10n)),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _latestAvailable() == null || _busy ? null : _update,
                icon: const Icon(Icons.system_update_alt),
                label: Text(l10n.detailFrameworkUpdate),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _restartSdk,
                icon: const Icon(Icons.restart_alt),
                label: Text(l10n.detailSdkRestart),
              ),
            ),
          ],
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
