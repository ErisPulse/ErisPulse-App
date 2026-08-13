// schema 驱动配置表单页（模块 / 适配器配置）。
//
// 数据源 `GET /api/module/{name}/config`（或 adapter）：
//   {schema: {fields: {字段: {type, widget, description, secret, group,
//      order, options, default}}}, values: {...}, config_key, has_config}
// 渲染对齐 Dashboard 前端 `renderAdapterConfigField`：
//   switch/boolean → Switch；password/secret → 密码框；
//   select/options → 下拉；number/integer/float → 数字框；
//   array/textarea → 多行（JSON 文本）；其余 → 文本输入。
// 保存整组 `PUT .../config {values: {...}}`（后端浅合并）。

import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/dashboard_api.dart';

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
  final List<_Field> _fields = [];
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _saving = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final data = await widget.load();
      final schemaFields = ((data['schema'] as Map?)?['fields'] as Map? ?? {})
          .cast<String, dynamic>();
      final values = (data['values'] as Map? ?? {}).cast<String, dynamic>();
      _fields.clear();
      _controllers.clear();
      for (final e in schemaFields.entries) {
        final sd = (e.value as Map).cast<String, dynamic>();
        final v = values.containsKey(e.key) ? values[e.key] : sd['default'];
        _values[e.key] = v;
        _fields.add(_Field(e.key, sd, v));
      }
      _fields.sort((a, b) {
        final ga = a.group ?? '_';
        final gb = b.group ?? '_';
        if (ga != gb) return ga.compareTo(gb);
        return (a.order ?? 100).compareTo(b.order ?? 100);
      });
      for (final f in _fields) {
        if (!f.isBool && !f.isSelect) {
          _controllers[f.name] =
              TextEditingController(text: _textOf(f.initialValue));
        }
      }
      if (!mounted) return;
      setState(() => _loading = false);
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

  static String _textOf(dynamic v) {
    if (v == null) return '';
    if (v is List || v is Map) {
      try {
        return const JsonEncoder.withIndent(' ').convert(v);
      } catch (_) {
        return v.toString();
      }
    }
    return v.toString();
  }

  Future<void> _save() async {
    for (final f in _fields) {
      final c = _controllers[f.name];
      if (c != null) {
        _values[f.name] = _parseTyped(f, c.text);
      }
    }
    setState(() => _saving = true);
    try {
      await widget.save(Map.of(_values));
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

  /// 按字段类型把文本转成保存值
  static dynamic _parseTyped(_Field f, String text) {
    final type = f.type;
    if (type == 'integer' || type == 'int') {
      return int.tryParse(text) ?? text;
    }
    if (type == 'float' || type == 'double' || type == 'number') {
      return double.tryParse(text) ?? text;
    }
    if (type == 'array' || f.widget == 'textarea' || f.initialValue is List) {
      try {
        return jsonDecode(text);
      } catch (_) {
        return text;
      }
    }
    if (type == 'boolean' || f.widget == 'switch') {
      return f.initialValue;
    }
    return text;
  }

  Widget _buildField(BuildContext context, _Field f) {
    final theme = Theme.of(context);
    final desc = f.description;

    if (f.isBool) {
      return SwitchListTile(
        title: Text(f.name),
        subtitle: desc == null ? null : Text(desc),
        value: _values[f.name] == true || _values[f.name] == 'true',
        onChanged: (v) => setState(() => _values[f.name] = v),
      );
    }
    if (f.isSelect) {
      final options = (f.schema['options'] as List?) ?? const [];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.name, style: theme.textTheme.titleSmall),
            if (desc != null) ...[
              const SizedBox(height: 2),
              Text(desc, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 6),
            DropdownButtonFormField<dynamic>(
              initialValue: _values[f.name],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: [
                for (final o in options)
                  DropdownMenuItem<dynamic>(
                    value: o is Map ? o['value'] : o,
                    child: Text(
                      o is Map
                          ? (o['label'] ?? o['value']).toString()
                          : o.toString(),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _values[f.name] = v),
            ),
          ],
        ),
      );
    }

    final ctrl = _controllers[f.name]!;
    final isSecret = f.widget == 'password' || f.secret == true;
    final isNumber =
        f.type == 'integer' || f.type == 'float' || f.type == 'number';
    final isMultiline =
        f.type == 'array' || f.widget == 'textarea' || f.initialValue is List;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f.name, style: theme.textTheme.titleSmall),
          if (desc != null) ...[
            const SizedBox(height: 2),
            Text(desc, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            obscureText: isSecret,
            maxLines: isMultiline ? 6 : 1,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  )
                : TextInputType.text,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        for (final f in _fields) _buildField(context, f),
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

/// 解析后的 schema 字段
class _Field {
  final String name;
  final Map<String, dynamic> schema;
  final dynamic initialValue;

  _Field(this.name, this.schema, this.initialValue);

  String get type => (schema['type'] ?? 'string').toString();
  String get widget => (schema['widget'] ?? '').toString();
  bool? get secret => schema['secret'] as bool?;
  String? get group => schema['group'] as String?;
  int? get order => schema['order'] as int?;
  String? get description => schema['description'] as String?;

  bool get isBool => widget == 'switch' || type == 'boolean';
  bool get isSelect =>
      widget == 'select' || (schema['options'] as List?)?.isNotEmpty == true;
}
