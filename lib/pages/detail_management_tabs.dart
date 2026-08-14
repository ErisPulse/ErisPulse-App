// 实例详情页的 Dashboard API 管理 Tab。
//
// 通过 DashboardApi 原生操作实例，端点/请求体与 Dashboard 后端逐项对齐：
//   - 模块：/modules 混排拆分 + modules/action（enable/disable/load/unload/reload）
//   - 适配器：modules/action（type=adapter）+ bot 展示 + schema 配置表单
//   - 配置：渲染（/config JSON 树 + 单键编辑 PUT /config {key,value}）
//   - 包/框架：已装 pip 包列表 + 安装/卸载 + 框架版本/更新 + SDK 重启
// 鉴权失败（401/403）统一显示"访问令牌无效"引导。

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/adapter_info.dart';
import '../models/instance.dart';
import '../models/module_info.dart';
import '../services/dashboard_api.dart';
import '../services/instance_manager.dart';
import 'adapter_config_page.dart';
import 'schema_config_page.dart';

/// 模块管理 Tab
class ModulesTab extends StatefulWidget {
  final Instance instance;
  const ModulesTab({super.key, required this.instance});

  @override
  State<ModulesTab> createState() => _ModulesTabState();
}

class _ModulesTabState extends State<ModulesTab> {
  late Future<List<ModuleInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardApi(widget.instance).getModules();
  }

  Future<void> _reload() async {
    setState(() => _future = DashboardApi(widget.instance).getModules());
  }

  Future<void> _toggle(ModuleInfo m, bool enabled) async {
    await DashboardApi(widget.instance).setModuleEnabled(m.name, enabled);
    await _reload();
  }

  Future<void> _reloadModule(ModuleInfo m) async {
    await DashboardApi(widget.instance).setModuleAction(m.name, 'reload');
    await _reload();
  }

  void _openConfig(ModuleInfo m) {
    final api = DashboardApi(widget.instance);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SchemaConfigPage(
          title: m.name,
          load: () => api.getModuleConfig(m.name),
          save: (values) => api.saveModuleConfig(m.name, values),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<ModuleInfo>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorView(onRetry: _reload, error: snap.error);
        }
        final modules = (snap.data ?? []).where((m) => m.isModule).toList();
        if (modules.isEmpty) return _EmptyView(l10n.detailTabEmpty);
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            children: [
              for (final m in modules)
                _ModuleTile(
                  module: m,
                  onToggle: (v) => _toggle(m, v),
                  onReload: m.loaded ? () => _reloadModule(m) : null,
                  onConfig: m.hasConfig ? () => _openConfig(m) : null,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final ModuleInfo module;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onReload;
  final VoidCallback? onConfig;

  const _ModuleTile({
    required this.module,
    required this.onToggle,
    this.onReload,
    this.onConfig,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Switch(
        value: module.enabled,
        onChanged: onToggle,
      ),
      title: Text(module.name),
      subtitle: Text(
        [
          if (module.version != null) module.version!,
          if (module.description != null) module.description!,
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onConfig != null)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Config',
              onPressed: onConfig,
            ),
          if (onReload != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload',
              onPressed: onReload,
            ),
          Icon(
            module.loaded ? Icons.check_circle : Icons.pause_circle_outline,
            color: module.loaded ? Colors.green : null,
            size: 18,
          ),
        ],
      ),
    );
  }
}

/// 适配器管理 Tab
class AdaptersTab extends StatefulWidget {
  final Instance instance;
  const AdaptersTab({super.key, required this.instance});

  @override
  State<AdaptersTab> createState() => _AdaptersTabState();
}

class _AdaptersTabState extends State<AdaptersTab> {
  late Future<List<AdapterInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardApi(widget.instance).getAdapters();
  }

  Future<void> _reload() async {
    setState(() => _future = DashboardApi(widget.instance).getAdapters());
  }

  Future<void> _toggle(AdapterInfo a, bool enabled) async {
    await DashboardApi(widget.instance).setAdapterEnabled(a.platform, enabled);
    await _reload();
  }

  Future<void> _startStop(AdapterInfo a) async {
    if (a.running) {
      await DashboardApi(widget.instance).stopAdapter(a.platform);
    } else {
      await DashboardApi(widget.instance).startAdapter(a.platform);
    }
    await _reload();
  }

  Future<void> _restart(AdapterInfo a) async {
    await DashboardApi(widget.instance).restartAdapter(a.platform);
    await _reload();
  }

  void _openConfig(AdapterInfo a) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdapterConfigPage(
          instance: widget.instance,
          platform: a.platform,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<AdapterInfo>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorView(onRetry: _reload, error: snap.error);
        }
        final adapters = snap.data ?? [];
        if (adapters.isEmpty) return _EmptyView(l10n.detailTabEmpty);
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            children: [
              for (final a in adapters)
                _AdapterTile(
                  adapter: a,
                  onToggle: (v) => _toggle(a, v),
                  onStartStop: () => _startStop(a),
                  onRestart: () => _restart(a),
                  onConfig: (a.hasConfig || a.hasAccounts)
                      ? () => _openConfig(a)
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AdapterTile extends StatelessWidget {
  final AdapterInfo adapter;
  final ValueChanged<bool> onToggle;
  final VoidCallback onStartStop;
  final VoidCallback onRestart;
  final VoidCallback? onConfig;

  const _AdapterTile({
    required this.adapter,
    required this.onToggle,
    required this.onStartStop,
    required this.onRestart,
    this.onConfig,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: Switch(
        value: adapter.enabled,
        onChanged: onToggle,
      ),
      title: Text(adapter.platform),
      subtitle: Text(
        [
          if (adapter.version != null) adapter.version!,
          if (adapter.statusMessage != null) adapter.statusMessage!,
          for (final b in adapter.bots) b.nickname ?? b.selfId,
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onConfig != null)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Config',
              onPressed: onConfig,
            ),
          IconButton(
            icon: Icon(
              adapter.running
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
            ),
            tooltip: adapter.running ? l10n.commonStop : l10n.commonStart,
            onPressed: onStartStop,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: l10n.commonRestart,
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

/// 配置 Tab：渲染模式（/config JSON 树 + 单键编辑 PUT /config {key,value}）
class ConfigTab extends StatefulWidget {
  final Instance instance;
  const ConfigTab({super.key, required this.instance});

  @override
  State<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<ConfigTab> {
  late Future<Map<String, dynamic>> _configFuture;

  @override
  void initState() {
    super.initState();
    _configFuture = DashboardApi(widget.instance).getConfig();
  }

  Future<void> _reloadConfig() async {
    setState(() => _configFuture = DashboardApi(widget.instance).getConfig());
  }

  Future<void> _editLeaf(_ConfigLeaf leaf) async {
    final result = await showDialog<({dynamic value, bool changed})>(
      context: context,
      builder: (_) => _ConfigValueDialog(
        configKey: leaf.key,
        value: leaf.value,
      ),
    );
    if (result != null && result.changed && mounted) {
      try {
        await DashboardApi(widget.instance).setConfig(leaf.key, result.value);
        await _reloadConfig();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')),
          );
        }
      }
    }
  }

  Future<void> _toggleBool(_ConfigLeaf leaf, bool v) async {
    try {
      await DashboardApi(widget.instance).setConfig(leaf.key, v);
      await _reloadConfig();
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return _buildRender(theme, l10n);
  }

  Widget _buildRender(ThemeData theme, AppLocalizations l10n) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _configFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorView(onRetry: _reloadConfig, error: snap.error);
        }
        final config = snap.data ?? {};
        final leaves = _flatten(config);
        if (leaves.isEmpty) return _EmptyView(l10n.detailTabEmpty);
        // 按首段分组
        final sections = <String, List<_ConfigLeaf>>{};
        for (final l in leaves) {
          sections.putIfAbsent(l.section, () => []).add(l);
        }
        final keys = sections.keys.toList()..sort();
        return ListView(
          children: [
            for (final section in keys) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  section,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              for (final leaf in sections[section]!)
                ListTile(
                  dense: true,
                  title: Text(
                    leaf.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  subtitle: Text(
                    _valueText(leaf.value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: leaf.value is bool
                      ? Switch(
                          value: leaf.value as bool,
                          onChanged: (v) => _toggleBool(leaf, v),
                        )
                      : const Icon(Icons.edit_outlined, size: 18),
                  onTap: leaf.value is bool ? null : () => _editLeaf(leaf),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// 渲染模式配置叶子（flatten 后的点分 key）
class _ConfigLeaf {
  final String key;
  final dynamic value;
  const _ConfigLeaf(this.key, this.value);

  String get section => key.split('.').first;
  String get label {
    final idx = key.indexOf('.');
    return idx < 0 ? key : key.substring(idx + 1);
  }
}

List<_ConfigLeaf> _flatten(Map<String, dynamic> config) {
  final leaves = <_ConfigLeaf>[];
  void walk(String prefix, dynamic v) {
    if (v is Map) {
      v.forEach((k, val) => walk('$prefix.$k', val));
    } else if (v is List) {
      leaves.add(_ConfigLeaf(prefix.substring(1), v));
    } else {
      leaves.add(_ConfigLeaf(prefix.substring(1), v));
    }
  }

  config.forEach((k, v) => walk('.$k', v));
  return leaves;
}

String _valueText(dynamic v) {
  if (v == null) return 'null';
  if (v is bool) return v ? 'true' : 'false';
  if (v is String) return v;
  return v.toString();
}

/// 配置值编辑对话框（按当前值类型渲染控件）
class _ConfigValueDialog extends StatefulWidget {
  final String configKey;
  final dynamic value;
  const _ConfigValueDialog({required this.configKey, required this.value});

  @override
  State<_ConfigValueDialog> createState() => _ConfigValueDialogState();
}

class _ConfigValueDialogState extends State<_ConfigValueDialog> {
  late final TextEditingController _ctrl;
  bool _switchValue = false;

  bool get _isBool => widget.value is bool;
  bool get _isNum => widget.value is num;
  bool get _isList => widget.value is List || widget.value is Map;
  bool get _isString => widget.value is String;

  @override
  void initState() {
    super.initState();
    _switchValue = widget.value == true;
    _ctrl = TextEditingController(text: _initialText());
  }

  String _initialText() {
    if (_isNum) return widget.value.toString();
    if (_isList) return const JsonEncoder.withIndent(' ').convert(widget.value);
    if (_isString) return widget.value as String;
    return widget.value?.toString() ?? '';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  dynamic _parsed() {
    if (_isBool) return _switchValue;
    if (_isNum) {
      return int.tryParse(_ctrl.text) ??
          double.tryParse(_ctrl.text) ??
          widget.value;
    }
    if (_isList) {
      try {
        return jsonDecode(_ctrl.text);
      } catch (_) {
        return _ctrl.text;
      }
    }
    return _ctrl.text;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.configKey),
      content: SizedBox(
        width: 400,
        child: _isBool
            ? SwitchListTile(
                title: Text(_switchValue ? 'true' : 'false'),
                value: _switchValue,
                onChanged: (v) => setState(() => _switchValue = v),
              )
            : TextField(
                controller: _ctrl,
                maxLines: _isList ? 8 : 1,
                keyboardType: _isNum
                    ? const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      )
                    : TextInputType.text,
                style: _isList
                    ? const TextStyle(fontFamily: 'monospace', fontSize: 12)
                    : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            (value: _parsed(), changed: true),
          ),
          child: Text(l10n.schemaConfigSave),
        ),
      ],
    );
  }
}

/// 包 / 框架 Tab
class PackagesTab extends StatefulWidget {
  final Instance instance;
  const PackagesTab({super.key, required this.instance});

  @override
  State<PackagesTab> createState() => _PackagesTabState();
}

class _PackagesTabState extends State<PackagesTab> {
  final _nameCtrl = TextEditingController();
  bool _busy = false;
  List<Map<String, dynamic>>? _packages;
  Map<String, dynamic>? _framework;
  bool _loading = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = DashboardApi(widget.instance);
      final packages = await api.getPackages();
      Map<String, dynamic>? fw;
      try {
        fw = await api.getFrameworkStatus();
      } catch (_) {
        fw = null;
      }
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _framework = fw;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ApiException('$e');
      });
    }
  }

  Future<void> _install() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await _run(() => DashboardApi(widget.instance).installPackages([name]));
    _nameCtrl.clear();
    await _load();
  }

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
              foregroundColor:
                  WidgetStateProperty.all(Theme.of(context).colorScheme.error),
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(
        () => DashboardApi(widget.instance).uninstallPackage(name),
      );
      await _load();
    }
  }

  Future<void> _updateFramework() async {
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
    if (ok == true) {
      await _run(
        () => DashboardApi(widget.instance).updateFramework(version: latest),
      );
      // 框架更新不绑定实例版本；更新后重新拉取状态，并同步实例记录的 SDK 版本
      await _load();
      if (!mounted) return;
      final fw = _framework;
      final current = fw?['current']?.toString();
      if (current != null && current.isNotEmpty) {
        await context
            .read<InstanceManager>()
            .setInstanceRuntime(widget.instance.id, current);
      }
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

  String _frameworkStatusText(AppLocalizations l10n) {
    final fw = _framework;
    if (fw == null) return l10n.detailTabEmpty;
    final current = fw['current']?.toString() ?? '?';
    final latest = _latestAvailable();
    if (latest == null) return 'v$current · ${l10n.detailFrameworkLatest}';
    return 'v$current → v$latest';
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
    if (ok == true) {
      await _run(() => DashboardApi(widget.instance).restartSdk());
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(onRetry: _load, error: _error);
    return AbsorbPointer(
      absorbing: _busy,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 安装
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.detailPackageName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
              onSubmitted: (_) => _install(),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _install,
              icon: const Icon(Icons.download),
              label: Text(l10n.detailPackageInstall),
            ),
            const Divider(height: 24),
            // 已装包
            Text(
              l10n.detailPackageInstalled,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            if (_packages == null || _packages!.isEmpty)
              ListTile(
                dense: true,
                title: Text(
                  l10n.detailTabEmpty,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              for (final p in _packages!)
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.detailPackageUninstall,
                    onPressed: () => _uninstall(p['name']?.toString() ?? ''),
                  ),
                ),
            const Divider(height: 24),
            // 框架：版本 + 更新 / 重启并列
            Text(l10n.detailFrameworkUpdate, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.system_update_alt),
              title: Text(_frameworkStatusText(l10n)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed:
                        _latestAvailable() == null ? null : _updateFramework,
                    icon: const Icon(Icons.system_update_alt),
                    label: Text(l10n.detailFrameworkUpdate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _restartSdk,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(l10n.detailSdkRestart),
                  ),
                ),
              ],
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, this.error});
  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAuth = error is ApiException && (error as ApiException).isAuth;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAuth ? Icons.lock_outline : Icons.cloud_off_outlined,
            size: 40,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              isAuth
                  ? l10n.detailAuthInvalid
                  : '${error ?? l10n.detailUnreachableError}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}
