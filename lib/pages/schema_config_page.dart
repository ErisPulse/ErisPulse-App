// schema 驱动配置表单页（模块 / 适配器全局配置）。
//
// 数据源 `GET /api/module/{name}/config`（或 adapter）：
//   {schema: {fields: {字段: {type, widget, description, secret, group,
//      order, options, default}}}, values: {...}, config_key, has_config}
// 字段渲染与保存逻辑复用 [SchemaFormView]。
// 保存整组 `PUT .../config {values: {...}}`（后端浅合并）。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/dashboard_api.dart';
import '../widgets/schema_form_view.dart';

class SchemaConfigPage extends StatefulWidget {
  /// 页面标题（模块 / 适配器名）
  final String title;

  /// 拉取配置（GET schema+values）
  final Future<Map<String, dynamic>> Function() load;

  /// 整组保存（PUT values）
  final Future<void> Function(Map<String, dynamic> values) save;

  const SchemaConfigPage({
    super.key,
    required this.title,
    required this.load,
    required this.save,
  });

  @override
  State<SchemaConfigPage> createState() => _SchemaConfigPageState();
}

class _SchemaConfigPageState extends State<SchemaConfigPage> {
  final _formKey = GlobalKey<SchemaFormViewState>();

  Map<String, dynamic> _fields = {};
  Map<String, dynamic> _values = {};
  bool _loading = true;
  bool _saving = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final data = await widget.load();
      final schemaFields = ((data['schema'] as Map?)?['fields'] as Map? ?? {})
          .cast<String, dynamic>();
      final values = (data['values'] as Map? ?? {}).cast<String, dynamic>();
      if (!mounted) return;
      setState(() {
        _fields = schemaFields;
        _values = values;
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
        _error = ApiException('加载配置失败');
      });
    }
  }

  Future<void> _save() async {
    final values = _formKey.currentState!.parseValues();
    setState(() => _saving = true);
    try {
      await widget.save(values);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).schemaConfigSaved)),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_loading && _error == null && _fields.isNotEmpty)
            IconButton(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              tooltip: l10n.schemaConfigSave,
              onPressed: _saving ? null : _save,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(error: _error!)
              : _fields.isEmpty
                  ? Center(
                      child: Text(
                        l10n.schemaConfigNoSchema,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        SchemaFormView(
                          key: _formKey,
                          fields: _fields,
                          values: _values,
                        ),
                      ],
                    ),
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
          Text(
            error.isAuth ? l10n.detailAuthInvalid : error.message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
