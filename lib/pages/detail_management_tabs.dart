// 实例详情页的 Dashboard API 管理 Tab。
//
// 通过 DashboardApi 原生操作实例，端点/请求体与 Dashboard 后端逐项对齐：
//   - 模块：/modules 混排拆分 + modules/action（enable/disable/load/unload/reload）
//   - 适配器：modules/action（type=adapter）+ bot 展示 + schema 配置表单
//   - 配置：渲染（/config JSON 树 + 单键编辑 PUT /config {key,value}）
// 包管理 / 框架更新已迁移至商店视图（views/instance_store_view.dart）。
// 鉴权失败（401/403）统一显示"访问令牌无效"引导。

import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/adapter_info.dart';
import '../models/instance.dart';
import '../models/module_info.dart';
import '../services/dashboard_api.dart';
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
