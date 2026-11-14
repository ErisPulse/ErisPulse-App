// 管理员配置视图（详情页"master"注册视图）：/api/master*。
// 保存形态对齐 Dashboard：纯全局 → list；含平台绑定且框架支持 global 键 →
// {platform: [...], global: [...]}；否则退化为展开写入。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

class InstanceMasterView extends StatefulWidget {
  final Instance instance;
  const InstanceMasterView({super.key, required this.instance});

  @override
  State<InstanceMasterView> createState() => _InstanceMasterViewState();
}

class _InstanceMasterViewState extends State<InstanceMasterView>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  bool _unsupported = false;
  String? _error;

  /// 服务端返回的原始形态（list 或 dict），用于合成保存载荷
  dynamic _rawUsers;
  List<String> _platformOptions = [];
  bool _globalKeySupported = false;
  List<Map<String, dynamic>> _providers = [];

  /// 编辑模型
  List<String> _globalUsers = [];
  Map<String, List<String>> _platformUsers = {};
  List<Map<String, dynamic>> _candidates = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = DashboardApi(widget.instance);
      final json = await api.masterConfig();
      List<Map<String, dynamic>> candidates = [];
      try {
        candidates = await api.masterCandidates();
      } catch (_) {}
      if (!mounted) return;

      final master = json['master'] is Map<String, dynamic>
          ? json['master'] as Map<String, dynamic>
          : const <String, dynamic>{};
      final rawUsers = master['users'];
      final platforms = [
        for (final p in (json['platforms'] as List? ?? [])) p.toString(),
      ];
      final providers = [
        for (final p in (json['providers'] as List? ?? []))
          if (p is Map<String, dynamic>) p,
      ];

      final globals = <String>[];
      final byPlatform = <String, List<String>>{};
      if (rawUsers is List) {
        globals.addAll(rawUsers.map((e) => e.toString()));
      } else if (rawUsers is Map) {
        for (final entry in rawUsers.entries) {
          final key = entry.key.toString();
          final list = [
            for (final u in (entry.value as List? ?? [])) u.toString(),
          ];
          if (key == 'global') {
            globals.addAll(list);
          } else if (list.isNotEmpty) {
            byPlatform[key] = list;
          }
        }
      }

      setState(() {
        _rawUsers = rawUsers;
        _platformOptions = platforms;
        _globalKeySupported = json['global_key_supported'] == true;
        _providers = providers;
        _candidates = candidates;
        _globalUsers = globals;
        _platformUsers = byPlatform;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _unsupported = e is ApiException && e.statusCode == 404;
        _error = _unsupported ? null : '$e';
      });
    }
  }

  Future<void> _save() async {
    final hasPlatform = _platformUsers.values.any((l) => l.isNotEmpty);
    dynamic payload;
    if (_globalUsers.isEmpty && !hasPlatform) {
      payload = _rawUsers is Map ? <String, dynamic>{} : <String>[];
    } else if (!hasPlatform) {
      payload = [..._globalUsers];
    } else if (_globalKeySupported) {
      payload = <String, dynamic>{
        for (final e in _platformUsers.entries)
          if (e.value.isNotEmpty) e.key: e.value,
        if (_globalUsers.isNotEmpty) 'global': _globalUsers,
      };
    } else {
      // 旧框架不支持 global 键：退化为展开写入
      payload = [
        ..._globalUsers,
        for (final e in _platformUsers.entries)
          for (final u in e.value) '${e.key}:$u',
      ];
    }
    try {
      await DashboardApi(widget.instance).saveMasterUsers(payload);
    } catch (_) {}
    await _load();
  }

  void _addGlobal(String uid) {
    setState(() {
      if (!_globalUsers.contains(uid)) _globalUsers.add(uid);
    });
    _save();
  }

  void _addPlatformUser(String platform, String uid) {
    setState(() {
      final list = _platformUsers.putIfAbsent(platform, () => []);
      if (!list.contains(uid)) list.add(uid);
    });
    _save();
  }

  void _removeEntry(String? platform, String uid) {
    setState(() {
      if (platform == null) {
        _globalUsers.remove(uid);
      } else {
        _platformUsers[platform]?.remove(uid);
      }
    });
    _save();
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
                l10n.masterTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.person_add_alt),
                tooltip: l10n.masterAdd,
                onPressed: _showAddDialog,
              ),
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
    if (_unsupported) return UnsupportedView(onRetry: _load);
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_loading) return const LoadingView();

    final theme = Theme.of(context);
    final platformCount =
        _platformUsers.values.fold(0, (sum, l) => sum + l.length);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 统计行
        Row(
          children: [
            _statChip(
              theme,
              l10n.masterTitle,
              '${_globalUsers.length + platformCount}',
            ),
            const SizedBox(width: 8),
            _statChip(theme, 'Global', '${_globalUsers.length}'),
            const SizedBox(width: 8),
            _statChip(theme, l10n.securityRoleAdmin, '$platformCount'),
          ],
        ),
        const SizedBox(height: 12),

        // 全局管理员
        if (_globalUsers.isNotEmpty) ...[
          Text('Global', style: theme.textTheme.titleSmall),
          for (final u in _globalUsers)
            ListTile(
              dense: true,
              leading: Icon(
                Icons.public,
                color: theme.colorScheme.primary,
              ),
              title: Text(u),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _removeEntry(null, u),
              ),
            ),
          const SizedBox(height: 8),
        ],

        // 平台分组
        for (final entry
            in _platformUsers.entries.where((e) => e.value.isNotEmpty)) ...[
          Text(entry.key, style: theme.textTheme.titleSmall),
          for (final u in entry.value)
            ListTile(
              dense: true,
              leading: Icon(
                Icons.smart_toy_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(u),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _removeEntry(entry.key, u),
              ),
            ),
          const SizedBox(height: 8),
        ],

        if (_globalUsers.isEmpty && platformCount == 0)
          EmptyState(icon: Icons.person_off_outlined, title: l10n.masterEmpty),

        // 提供者清单
        if (_providers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Providers', style: theme.textTheme.titleSmall),
          for (final p in _providers)
            ListTile(
              dense: true,
              leading: const Icon(Icons.extension_outlined),
              title: Text(p['name']?.toString() ?? ''),
              subtitle: p['owner'] == null ? null : Text(p['owner'].toString()),
            ),
        ],
      ],
    );
  }

  Widget _statChip(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  /// 添加对话框：平台下拉（含自定义）+ UID 输入
  Future<void> _showAddDialog() async {
    final l10n = AppLocalizations.of(context);
    final uidCtrl = TextEditingController();
    String? platform =
        _platformOptions.isNotEmpty ? _platformOptions.first : null;
    var custom = platform == null;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.masterAdd),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: custom ? '__custom__' : platform,
                        decoration:
                            const InputDecoration(labelText: 'Platform'),
                        items: [
                          for (final p in _platformOptions)
                            DropdownMenuItem(value: p, child: Text(p)),
                          const DropdownMenuItem(
                            value: '__custom__',
                            child: Text('Custom'),
                          ),
                        ],
                        onChanged: (v) => setDialogState(() {
                          if (v == '__custom__') {
                            custom = true;
                            platform = null;
                          } else {
                            custom = false;
                            platform = v;
                          }
                        }),
                      ),
                    ),
                  ],
                ),
                if (custom)
                  TextField(
                    decoration: const InputDecoration(labelText: 'Platform'),
                    onChanged: (v) => platform = v.trim(),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: uidCtrl,
                  decoration: const InputDecoration(labelText: 'User ID'),
                  autofocus: custom,
                ),
                const SizedBox(height: 12),
                // 从最近消息选择
                TextButton.icon(
                  icon: const Icon(Icons.history, size: 18),
                  label: Text(l10n.masterCandidates),
                  onPressed: () async {
                    final picked = await _pickCandidate(dialogCtx);
                    if (picked != null) {
                      setDialogState(() {
                        custom = false;
                        platform = picked['platform']?.toString();
                        uidCtrl.text = picked['user_id']?.toString() ?? '';
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final uid = uidCtrl.text.trim();
                final plat = platform?.trim();
                if (uid.isEmpty) return;
                if (plat == null || plat.isEmpty) {
                  _addGlobal(uid);
                } else {
                  _addPlatformUser(plat, uid);
                }
                Navigator.pop(dialogCtx);
              },
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );
  }

  /// 候选人选择浮层（全量，昵称优先）
  Future<Map<String, dynamic>?> _pickCandidate(
    BuildContext dialogCtx,
  ) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: dialogCtx,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in _candidates)
              ListTile(
                dense: true,
                leading: const Icon(Icons.person_search_outlined),
                title: Text(
                  (c['nickname']?.toString().isNotEmpty ?? false)
                      ? c['nickname'].toString()
                      : c['user_id']?.toString() ?? '',
                ),
                subtitle: Text(
                  '${c['platform'] ?? ''} · ${c['user_id'] ?? ''}',
                ),
                onTap: () => Navigator.pop(sheetCtx, c),
              ),
            if (_candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('-')),
              ),
          ],
        ),
      ),
    );
    return result;
  }
}
