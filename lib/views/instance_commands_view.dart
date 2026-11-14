// 实例命令管理视图（详情页"命令"注册视图）。
//
// 原生替代 Dashboard 前端 commands 页：展示 `/api/commands` 返回的命令规则
// （别名 / 启用 / 平台限制 / transform_to）与全局设置（前缀 / 大小写 / 空格
// 前缀 / @Bot 必带），支持编辑与保存。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

/// 命令管理视图
class InstanceCommandsView extends StatefulWidget {
  final Instance instance;
  const InstanceCommandsView({super.key, required this.instance});

  @override
  State<InstanceCommandsView> createState() => _InstanceCommandsViewState();
}

class _InstanceCommandsViewState extends State<InstanceCommandsView>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _commands = [];
  Map<String, dynamic>? _settings;
  bool _loading = true;
  String? _error;

  final TextEditingController _prefix = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _prefix.dispose();
    super.dispose();
  }

  /// 平台候选（/commands 响应的 platforms；编辑对话框 chips 数据源）
  List<String> _platforms = [];

  Future<void> _load() async {
    try {
      final data = await DashboardApi(widget.instance).getCommands();
      if (!mounted) return;
      setState(() {
        _commands = (data['commands'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _settings = (data['global_settings'] as Map?)?.cast<String, dynamic>();
        _platforms = [
          for (final p in (data['platforms'] as List? ?? [])) p.toString(),
        ];
        // 多前缀兼容：prefixes 数组优先于 prefix 字符串
        _prefix.text = _settings?['prefixes'] is List
            ? (_settings?['prefixes'] as List).join(', ')
            : _settings?['prefix']?.toString() ?? '/';
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

  bool _settingBool(String key, bool def) {
    final v = _settings?[key];
    if (v is bool) return v;
    return def;
  }

  Future<void> _saveGlobal() async {
    final api = DashboardApi(widget.instance);
    try {
      await api.saveCommandSettings({
        'prefix': _prefix.text.trim().isEmpty ? '/' : _prefix.text.trim(),
        'case_sensitive': _settingBool('case_sensitive', true),
        'allow_space_prefix': _settingBool('allow_space_prefix', false),
        'must_at_bot': _settingBool('must_at_bot', false),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).commandsSaved)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggleEnabled(Map<String, dynamic> cmd, bool enabled) async {
    final name = cmd['name']?.toString() ?? '';
    if (name.isEmpty) return;
    try {
      await DashboardApi(widget.instance)
          .updateCommand(name, {'enabled': enabled});
      if (!mounted) return;
      setState(() {
        cmd['enabled'] = enabled;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _edit(Map<String, dynamic> cmd) async {
    final name = cmd['name']?.toString() ?? '';
    if (name.isEmpty) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CommandEditDialog(
        command: {...cmd, '_platforms': _platforms},
        instance: widget.instance,
      ),
    );
    if (saved == true && mounted) {
      await _load();
    }
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
                l10n.commandsTitle,
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
        Expanded(
          child: _buildBody(l10n),
        ),
      ],
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_loading) {
      return const LoadingView();
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 全局设置
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.commandsGlobalSettings,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _prefix,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.commandsPrefix,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saveGlobal,
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: Text(l10n.commandsSave),
                    ),
                  ],
                ),
                _SwitchRow(
                  label: l10n.commandsCaseSensitive,
                  value: _settingBool('case_sensitive', true),
                  onChanged: (v) => setState(() {
                    _settings?['case_sensitive'] = v;
                  }),
                ),
                _SwitchRow(
                  label: l10n.commandsAllowSpacePrefix,
                  value: _settingBool('allow_space_prefix', false),
                  onChanged: (v) => setState(() {
                    _settings?['allow_space_prefix'] = v;
                  }),
                ),
                _SwitchRow(
                  label: l10n.commandsMustAtBot,
                  value: _settingBool('must_at_bot', false),
                  onChanged: (v) => setState(() {
                    _settings?['must_at_bot'] = v;
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_commands.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.terminal_outlined,
              title: l10n.commandsEmpty,
            ),
          )
        else
          for (final cmd in _commands)
            _CommandRow(
              command: cmd,
              onToggle: (v) => _toggleEnabled(cmd, v),
              onEdit: () => _edit(cmd),
            ),
      ],
    );
  }
}

/// 设置开关行
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// 单条命令行
class _CommandRow extends StatelessWidget {
  const _CommandRow({
    required this.command,
    required this.onToggle,
    required this.onEdit,
  });
  final Map<String, dynamic> command;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = command['name']?.toString() ?? '';
    final group = command['group']?.toString() ?? '';
    final help = command['help']?.toString() ?? '';
    final enabled = command['enabled'] != false;
    return ListTile(
      dense: true,
      leading: Icon(
        enabled ? Icons.terminal : Icons.terminal_outlined,
        size: 20,
        color: enabled ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      title: Text(name, style: theme.textTheme.bodyMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.isNotEmpty)
            Text(
              group,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (help.isNotEmpty)
            Text(
              help,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: AppLocalizations.of(context).commandsEdit,
            onPressed: onEdit,
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
          ),
        ],
      ),
      onTap: onEdit,
    );
  }
}

/// 编辑命令规则对话框
class _CommandEditDialog extends StatefulWidget {
  final Map<String, dynamic> command;
  final Instance instance;
  const _CommandEditDialog({required this.command, required this.instance});

  @override
  State<_CommandEditDialog> createState() => _CommandEditDialogState();
}

class _CommandEditDialogState extends State<_CommandEditDialog> {
  late final TextEditingController _aliases;
  late final TextEditingController _transform;
  late bool _enabled;
  late bool _paramMaster;
  late bool _paramHidden;

  /// 平台允许/阻止（chips 数据源：/commands 返回的 platforms + 已配置值）
  List<String> _allowedPlatforms = [];
  List<String> _blockedPlatforms = [];
  List<String> _allPlatforms = [];

  /// ACL 用户名单（platform:uid）
  List<String> _aclAllow = [];
  List<String> _aclDeny = [];
  final _aclPlatformCtrl = TextEditingController();
  final _aclUidCtrl = TextEditingController();
  String _aclTarget = 'allow';

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cmd = widget.command;
    _enabled = cmd['enabled'] != false;
    _aliases = TextEditingController(
      text: _join(cmd['custom_aliases'] as List?),
    );
    _allowedPlatforms = [
      for (final p in (cmd['allowed_platforms'] as List? ?? [])) p.toString(),
    ];
    _blockedPlatforms = [
      for (final p in (cmd['blocked_platforms'] as List? ?? [])) p.toString(),
    ];
    final acl = cmd['acl'] is Map<String, dynamic>
        ? cmd['acl'] as Map<String, dynamic>
        : const <String, dynamic>{};
    _aclAllow = [
      for (final a in (acl['allow'] as List? ?? [])) a.toString(),
    ];
    _aclDeny = [
      for (final a in (acl['deny'] as List? ?? [])) a.toString(),
    ];
    final params = cmd['params'] is Map<String, dynamic>
        ? cmd['params'] as Map<String, dynamic>
        : const <String, dynamic>{};
    _paramMaster = params['master'] == true;
    _paramHidden = params['hidden'] == true;
    _transform =
        TextEditingController(text: cmd['transform_to']?.toString() ?? '');
    // 平台候选：命令列表接口返回的 platforms 由打开方注入
    _allPlatforms = [
      for (final p in (cmd['_platforms'] as List? ?? [])) p.toString(),
      ..._allowedPlatforms,
      ..._blockedPlatforms,
    ]..sort();
  }

  @override
  void dispose() {
    _aliases.dispose();
    _transform.dispose();
    _aclPlatformCtrl.dispose();
    _aclUidCtrl.dispose();
    super.dispose();
  }

  static String _join(List<dynamic>? list) {
    if (list == null) return '';
    return list.map((e) => e.toString()).where((e) => e.isNotEmpty).join(', ');
  }

  static List<String> _splitCmd(String s) =>
      s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  void _togglePlatform(List<String> list, String platform) {
    setState(() {
      list.contains(platform) ? list.remove(platform) : list.add(platform);
      list.remove('*');
      list.insert(0, '*');
    });
  }

  void _addAcl(List<String> list) {
    final p = _aclPlatformCtrl.text.trim();
    final u = _aclUidCtrl.text.trim();
    if (u.isEmpty) return;
    final tag = p.isEmpty || p == '*' ? u : '$p:$u';
    setState(() {
      if (!list.contains(tag)) list.add(tag);
      _aclPlatformCtrl.clear();
      _aclUidCtrl.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DashboardApi(widget.instance).updateCommand(
        widget.command['name']?.toString() ?? '',
        {
          'enabled': _enabled,
          'aliases': _splitCmd(_aliases.text),
          'allowed_platforms': _allowedPlatforms,
          'blocked_platforms': _blockedPlatforms,
          'transform_to':
              _transform.text.trim().isEmpty ? null : _transform.text.trim(),
          'acl': {'allow': _aclAllow, 'deny': _aclDeny},
          'params': {'master': _paramMaster, 'hidden': _paramHidden},
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _platformChips(String label, List<String> list) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final p in _allPlatforms)
              FilterChip(
                visualDensity: VisualDensity.compact,
                label: Text(p),
                selected: list.contains(p),
                onSelected: (_) => _togglePlatform(list, p),
              ),
          ],
        ),
      ],
    );
  }

  Widget _aclGroup(String label, List<String> list) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final tag in list)
              InputChip(
                visualDensity: VisualDensity.compact,
                label: Text(tag),
                onDeleted: () => setState(() => list.remove(tag)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _aclPlatformCtrl,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Platform (* = all)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _aclUidCtrl,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'UID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        '${l10n.commandsEditTitle}: ${widget.command['name'] ?? ''}',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.commandsEnabled),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              TextField(
                controller: _aliases,
                decoration: InputDecoration(
                  labelText: l10n.commandsAliases,
                  hintText: 'alias1, alias2',
                ),
              ),
              const SizedBox(height: 14),
              _platformChips(l10n.commandsAllowedPlatforms, _allowedPlatforms),
              const SizedBox(height: 14),
              _platformChips(l10n.commandsBlockedPlatforms, _blockedPlatforms),
              const SizedBox(height: 14),
              TextField(
                controller: _transform,
                decoration: InputDecoration(
                  labelText: l10n.commandsTransformTo,
                  hintText: '/other_command',
                ),
              ),
              const Divider(height: 24),
              Text('ACL', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'allow', label: Text('Allow')),
                  ButtonSegment(value: 'deny', label: Text('Deny')),
                ],
                selected: {_aclTarget},
                onSelectionChanged: (s) => setState(() => _aclTarget = s.first),
              ),
              const SizedBox(height: 8),
              _aclGroup(
                _aclTarget == 'allow' ? 'Allow' : 'Deny',
                _aclTarget == 'allow' ? _aclAllow : _aclDeny,
              ),
              const SizedBox(height: 4),
              FilledButton.tonal(
                onPressed: () => _addAcl(
                  _aclTarget == 'allow' ? _aclAllow : _aclDeny,
                ),
                child: const Text('Add'),
              ),
              const Divider(height: 24),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('params.master'),
                subtitle: const Text('Only bot master can use'),
                value: _paramMaster,
                onChanged: (v) => setState(() => _paramMaster = v),
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('params.hidden'),
                subtitle: const Text('Hide from help listing'),
                value: _paramHidden,
                onChanged: (v) => setState(() => _paramHidden = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.commandsSave),
        ),
      ],
    );
  }
}
