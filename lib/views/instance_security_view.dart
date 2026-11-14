// API 密钥管理视图（详情页"security"注册视图）：/api/security/*。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

class InstanceSecurityView extends StatefulWidget {
  final Instance instance;
  const InstanceSecurityView({super.key, required this.instance});

  @override
  State<InstanceSecurityView> createState() => _InstanceSecurityViewState();
}

class _InstanceSecurityViewState extends State<InstanceSecurityView>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _keys = [];
  Map<String, dynamic> _pages = {};
  bool _unsupported = false;

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
      final keys = await api.securityKeys();
      Map<String, dynamic> pages = {};
      try {
        pages = (await api.securityPages())['pages'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(
                (await api.securityPages())['pages'] as Map,
              )
            : {};
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _keys = keys;
        _pages = pages;
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
                l10n.securityTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.key_off, size: 18),
                label: Text(l10n.securityRegenToken),
                onPressed: _regenPrimaryToken,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
                onPressed: _load,
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.securityCreate),
                onPressed: _showCreateDialog,
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
    if (_keys.isEmpty) {
      return EmptyState(icon: Icons.key_outlined, title: l10n.securityEmpty);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _keys.length,
      itemBuilder: (context, i) => _tile(_keys[i], l10n),
    );
  }

  Widget _tile(Map<String, dynamic> k, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final id = k['id']?.toString() ?? '';
    final role = k['role']?.toString() ?? 'viewer';
    final enabled = k['enabled'] == true;
    final pages =
        (k['pages'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final prefix = k['key_prefix']?.toString() ?? '';
    final lastUsed = k['last_used']?.toString() ?? '';
    return ListTile(
      dense: true,
      leading: Icon(
        role == 'admin'
            ? Icons.admin_panel_settings_outlined
            : Icons.visibility_outlined,
        color: enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              k['name']?.toString() ?? id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: enabled
                  ? null
                  : TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              role == 'admin'
                  ? l10n.securityRoleAdmin
                  : l10n.securityRoleViewer,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        [
          '$prefix…',
          pages.isEmpty ? l10n.securityPagesAll : pages.join(', '),
          if (lastUsed.isNotEmpty) '${l10n.securityLastUsed}: $lastUsed',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: enabled,
            onChanged: (v) async {
              try {
                await DashboardApi(
                  widget.instance,
                ).updateSecurityKey(id, enabled: v);
                await _load();
              } catch (_) {}
            },
          ),
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'regen',
                child: Text(l10n.securityRegen),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(l10n.commonDelete),
              ),
            ],
            onSelected: (action) async {
              final api = DashboardApi(widget.instance);
              try {
                if (action == 'regen') {
                  final result = await api.regenerateSecurityKey(id);
                  if (mounted) {
                    _showPlaintext(result['key']?.toString() ?? '');
                  }
                } else if (action == 'delete') {
                  final ok = await _confirm(l10n.securityDeleteConfirm);
                  if (ok) await api.deleteSecurityKey(id);
                }
                await _load();
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String message) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(message),
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
    return ok == true;
  }

  void _showPlaintext(String plaintext) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.securityKeyCreated),
        content: SelectableText(plaintext),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  Future<void> _regenPrimaryToken() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.securityRegenToken),
        content: Text(l10n.securityRegenTokenConfirm),
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
    try {
      await DashboardApi(widget.instance).regeneratePrimaryToken();
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.securityRegenToken)),
      );
    }
  }

  Future<void> _showCreateDialog() async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    var role = 'viewer';
    final selectedPages = <String>{};
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.securityCreate),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.securityName),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(l10n.securityRole),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'viewer',
                            label: Text(l10n.securityRoleViewer),
                          ),
                          ButtonSegment(
                            value: 'admin',
                            label: Text(l10n.securityRoleAdmin),
                          ),
                        ],
                        selected: {role},
                        onSelectionChanged: (sel) =>
                            setDialogState(() => role = sel.first),
                      ),
                    ),
                  ],
                ),
                if (role == 'viewer' && _pages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(l10n.securityPages),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final page in _pages.keys)
                            CheckboxListTile(
                              dense: true,
                              title: Text(page),
                              value: selectedPages.contains(page),
                              onChanged: (v) => setDialogState(() {
                                v == true
                                    ? selectedPages.add(page)
                                    : selectedPages.remove(page);
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                try {
                  final result = await DashboardApi(
                    widget.instance,
                  ).createSecurityKey(
                    name: name,
                    role: role,
                    pages: selectedPages.toList(),
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  await _load();
                  if (mounted) {
                    _showPlaintext(result['key']?.toString() ?? '');
                  }
                } catch (_) {}
              },
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );
  }
}
