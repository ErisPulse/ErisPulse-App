// 适配器配置页（全局配置 + 多 bot 账户配置）。
//
// 数据源 `GET /api/adapter/{platform}/config` 一次拉全：
//   {schema, values, account_schema, accounts, has_config, has_accounts}
//   - 全局配置：schema + values（PUT /adapter/{platform}/config {values}）
//   - 账户（bot）：account_schema.fields + accounts（
//       PUT /adapter/{platform}/accounts {accounts: {...}} 整表合并，
//       POST .../accounts/add 新增，DELETE .../accounts/{name} 删除）
// 字段渲染复用 [SchemaFormView]。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/schema_form_view.dart';

class AdapterConfigPage extends StatefulWidget {
  /// 所属实例
  final Instance instance;

  /// 适配器平台标识（如 `onebot11`、`telegram`）
  final String platform;

  const AdapterConfigPage({
    super.key,
    required this.instance,
    required this.platform,
  });

  @override
  State<AdapterConfigPage> createState() => _AdapterConfigPageState();
}

class _AdapterConfigPageState extends State<AdapterConfigPage> {
  final _globalFormKey = GlobalKey<SchemaFormViewState>();
  final Map<String, GlobalKey<SchemaFormViewState>> _accountFormKeys = {};
  final Map<String, bool> _accountEnabled = {};

  DashboardApi get _api => DashboardApi(widget.instance);

  bool _loading = true;
  bool _saving = false;
  ApiException? _error;

  bool _hasConfig = false;
  bool _hasAccounts = false;
  Map<String, dynamic> _globalFields = {};
  Map<String, dynamic> _globalValues = {};
  Map<String, dynamic> _accountFields = {};
  Map<String, dynamic> _accounts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getAdapterConfig(widget.platform);
      final schemaFields = ((data['schema'] as Map?)?['fields'] as Map? ?? {})
          .cast<String, dynamic>();
      final accountSchemaFields =
          ((data['account_schema'] as Map?)?['fields'] as Map? ?? {})
              .cast<String, dynamic>();
      final accounts = (data['accounts'] as Map? ?? {}).cast<String, dynamic>();
      if (!mounted) return;
      setState(() {
        _hasConfig = data['has_config'] as bool? ?? schemaFields.isNotEmpty;
        _hasAccounts =
            data['has_accounts'] as bool? ?? accountSchemaFields.isNotEmpty;
        _globalFields = schemaFields;
        _globalValues = (data['values'] as Map? ?? {}).cast<String, dynamic>();
        _accountFields = accountSchemaFields;
        _accounts = accounts;
        _accountFormKeys.clear();
        _accountEnabled.clear();
        for (final name in _accounts.keys) {
          _accountFormKeys[name] = GlobalKey<SchemaFormViewState>();
          final acc = _accounts[name];
          _accountEnabled[name] = acc is Map && acc['enabled'] == true;
        }
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ApiException('加载适配器配置失败');
      });
    }
  }

  Future<void> _saveGlobal() async {
    final values = _globalFormKey.currentState!.parseValues();
    final ok = await _runSaving(
      () => _api.saveAdapterConfig(widget.platform, values),
    );
    if (ok && mounted) {
      _showSnack(AppLocalizations.of(context).schemaConfigSaved);
      await _load();
    }
  }

  Future<void> _saveAccount(String name) async {
    final formKey = _accountFormKeys[name];
    if (formKey == null) return;
    final parsed = formKey.currentState!.parseValues();
    final current = _accounts[name] is Map
        ? Map<String, dynamic>.from(_accounts[name] as Map)
        : <String, dynamic>{};
    final merged = {
      ...current,
      ...parsed,
      'enabled': _accountEnabled[name] ?? false,
    };
    final ok = await _runSaving(
      () => _api.saveAdapterAccounts(widget.platform, {name: merged}),
    );
    if (ok && mounted) {
      _showSnack(AppLocalizations.of(context).adapterConfigAccountSaved);
      await _load();
    }
  }

  Future<void> _addAccount() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddAccountDialog(),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    try {
      await _api.addAdapterAccount(widget.platform, trimmed);
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context).adapterConfigAccountAdded);
      await _load();
    } on ApiException catch (e) {
      _showError(e);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteAccount(String name) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adapterConfigAccountDelete),
        content: Text(l10n.adapterConfigAccountDeleteConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteAdapterAccount(widget.platform, name);
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context).adapterConfigAccountDeleted);
      await _load();
    } on ApiException catch (e) {
      _showError(e);
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> _runSaving(Future<void> Function() op) async {
    setState(() => _saving = true);
    try {
      await op();
      return true;
    } on ApiException catch (e) {
      _showError(e);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    return false;
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e')),
    );
  }

  Widget _buildAccountCard(BuildContext context, String name) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final acc = _accounts[name] is Map
        ? Map<String, dynamic>.from(_accounts[name] as Map)
        : <String, dynamic>{};
    // 账户编辑表单：跳过内建 name / enabled 字段（name 为卡片标题，enabled 为开关）
    final formFields = Map<String, dynamic>.from(_accountFields)
      ..remove('name')
      ..remove('enabled');
    final formValues = <String, dynamic>{
      for (final k in formFields.keys)
        if (acc.containsKey(k)) k: acc[k],
    };
    final enabled = _accountEnabled[name] ?? false;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: Switch(
          value: enabled,
          onChanged:
              _saving ? null : (v) => setState(() => _accountEnabled[name] = v),
        ),
        title: Text(name),
        subtitle: Text(
          '${l10n.adapterConfigEnabled}: ${enabled ? '✓' : '—'}',
        ),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          if (formFields.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.schemaConfigNoSchema,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            SchemaFormView(
              key: _accountFormKeys[name],
              fields: formFields,
              values: formValues,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _saving ? null : () => _deleteAccount(name),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.adapterConfigAccountDelete),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _saveAccount(name),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.commonSave),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.platform),
        actions: [
          if (!_loading && _error == null && _hasConfig)
            IconButton(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              tooltip: l10n.schemaConfigSave,
              onPressed: _saving ? null : _saveGlobal,
            ),
          if (!_loading && _error == null && _hasAccounts)
            IconButton(
              icon: const Icon(Icons.person_add_alt),
              tooltip: l10n.adapterConfigAccountAdd,
              onPressed: _saving ? null : _addAccount,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(error: _error!)
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (_hasConfig) ...[
                      _SectionHeader(l10n.adapterConfigGlobal),
                      SchemaFormView(
                        key: _globalFormKey,
                        fields: _globalFields,
                        values: _globalValues,
                      ),
                    ],
                    if (_hasAccounts) ...[
                      _SectionHeader(l10n.adapterConfigAccounts),
                      if (_accounts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.adapterConfigAccountsEmpty,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        for (final name in _accounts.keys)
                          _buildAccountCard(context, name),
                    ],
                  ],
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _AddAccountDialog extends StatefulWidget {
  const _AddAccountDialog();

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.adapterConfigAccountAdd),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.adapterConfigAccountName,
          hintText: l10n.adapterConfigAccountNameRequired,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l10n.commonConfirm),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final ApiException error;
  const _ErrorBody({required this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            error.isAuth ? Icons.lock_outline : Icons.cloud_off_outlined,
            size: 40,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error.isAuth ? l10n.detailAuthInvalid : error.message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
