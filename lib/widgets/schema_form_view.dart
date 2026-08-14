// schema 驱动的字段表单视图（模块 / 适配器全局 / 适配器账户共用）。
//
// 数据源 schema.fields（`GET /api/module/{name}/config` 等返回）：
//   {字段: {type, widget, description, secret, group, order, options, default}}
// 渲染对齐 Dashboard 前端 `renderAdapterConfigField`：
//   switch/boolean → Switch；password/secret → 密码框；
//   select/options → 下拉；number/integer/float → 数字框；
//   array/textarea → 多行（JSON 文本）；其余 → 文本输入。
// 保存时调用 [SchemaFormViewState.parseValues] 收集类型化值。

import 'dart:convert';

import 'package:flutter/material.dart';

/// schema 字段表单（无页面外壳，供配置页内嵌复用）
class SchemaFormView extends StatefulWidget {
  /// schema.fields：{字段名: 字段定义}
  final Map<String, dynamic> fields;

  /// 初始值（缺失字段回退到 schema default）
  final Map<String, dynamic> values;

  /// 任一字段变化回调（用于刷新保存按钮可用态）
  final VoidCallback? onChanged;

  const SchemaFormView({
    super.key,
    required this.fields,
    required this.values,
    this.onChanged,
  });

  @override
  State<SchemaFormView> createState() => SchemaFormViewState();
}

class SchemaFormViewState extends State<SchemaFormView> {
  final List<_SchemaField> _fields = [];
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _buildFields();
  }

  @override
  void didUpdateWidget(SchemaFormView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields != widget.fields ||
        oldWidget.values != widget.values) {
      for (final c in _controllers.values) {
        c.dispose();
      }
      _buildFields();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _buildFields() {
    _fields.clear();
    _controllers.clear();
    for (final e in widget.fields.entries) {
      final sd = (e.value as Map).cast<String, dynamic>();
      final v = widget.values.containsKey(e.key)
          ? widget.values[e.key]
          : sd['default'];
      _values[e.key] = v;
      _fields.add(_SchemaField(e.key, sd, v));
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
  }

  /// 收集当前表单值（文本 → 类型化值），供保存
  Map<String, dynamic> parseValues() {
    for (final f in _fields) {
      final c = _controllers[f.name];
      if (c != null) {
        _values[f.name] = _parseTyped(f, c.text);
      }
    }
    return Map.of(_values);
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

  /// 按字段类型把文本转成保存值
  static dynamic _parseTyped(_SchemaField f, String text) {
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

  Widget _buildField(BuildContext context, _SchemaField f) {
    final theme = Theme.of(context);
    final desc = f.description;

    if (f.isBool) {
      return SwitchListTile(
        title: Text(f.name),
        subtitle: desc == null ? null : Text(desc),
        value: _values[f.name] == true || _values[f.name] == 'true',
        onChanged: (v) {
          setState(() => _values[f.name] = v);
          widget.onChanged?.call();
        },
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
              onChanged: (v) {
                setState(() => _values[f.name] = v);
                widget.onChanged?.call();
              },
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
            onChanged: (_) => widget.onChanged?.call(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in _fields) _buildField(context, f),
      ],
    );
  }
}

/// 解析后的 schema 字段
class _SchemaField {
  final String name;
  final Map<String, dynamic> schema;
  final dynamic initialValue;

  _SchemaField(this.name, this.schema, this.initialValue);

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
