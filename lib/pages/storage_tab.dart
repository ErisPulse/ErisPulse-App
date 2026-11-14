// 存储子页（配置 tab）：KV 键值 + 表浏览（分页）+ 清空表 + 备份导出/导入。
//
// 后端形状：
//   GET  /storage             → {keys, data: {k: v}, total}
//   GET  /storage/tables      → {backend, tables: [{name, rows, builtin}], total}
//   GET  /storage/table?name  → {columns, rows, total, page, size}
//   POST /storage/table/clear → {success}
//   GET  /backup/export       → {config, storage}
//   POST /backup/import       → {success}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

/// 存储子页
class StorageTab extends StatefulWidget {
  final Instance instance;
  const StorageTab({super.key, required this.instance});

  @override
  State<StorageTab> createState() => _StorageTabState();
}

class _StorageTabState extends State<StorageTab>
    with AutomaticKeepAliveClientMixin {
  static const _pageSize = 20;

  late final DashboardApi _api = DashboardApi(widget.instance);

  Map<String, dynamic> _kvData = {};
  List<Map<String, dynamic>> _tables = [];
  bool _loading = true;
  String? _error;

  /// 当前展开表的分页数据
  String? _openTable;
  List<Map<String, dynamic>> _rows = [];
  List<String> _columns = [];
  int _page = 1;
  int _totalRows = 0;
  bool _rowsLoading = false;
  String? _rowsError;

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
      final storage = await _api.getStorage();
      List<Map<String, dynamic>> tables = [];
      try {
        final t = await _api.getStorageTables();
        tables = [
          for (final e in (t['tables'] as List? ?? []))
            if (e is Map) Map<String, dynamic>.from(e),
        ];
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _kvData = (storage['data'] as Map?)?.cast<String, dynamic>() ?? {};
        _tables = tables;
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

  Future<void> _openRows(String name, {int page = 1}) async {
    setState(() {
      _openTable = name;
      _page = page;
      _rowsLoading = true;
      _rowsError = null;
    });
    try {
      final data =
          await _api.getStorageTable(name, page: page, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _rows = [
          for (final r in (data['rows'] as List? ?? []))
            if (r is Map) Map<String, dynamic>.from(r),
        ];
        _columns = [
          for (final c in (data['columns'] as List? ?? [])) c.toString(),
        ];
        _totalRows = (data['total'] as num?)?.toInt() ?? _rows.length;
        _rowsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rows = [];
        _rowsLoading = false;
        _rowsError = '$e';
      });
    }
  }

  Future<void> _clearTable(String name) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.storageClearTable),
        content: Text(name),
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
      await _api.clearStorageTable(name);
      if (name == _openTable) await _openRows(name, page: 1);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _exportBackup() async {
    final l10n = AppLocalizations.of(context);
    try {
      final data = await _api.exportBackup();
      if (!mounted) return;
      final text = const JsonEncoder.withIndent('  ').convert(data);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.backupExport),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 420),
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(ctx);
              },
              child: Text(l10n.commonCopyAll),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonClose),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _importBackup() async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupImport),
        content: SizedBox(
          width: 440,
          child: TextField(
            controller: ctrl,
            maxLines: 10,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '{"config": {...}, "storage": {...}}',
            ),
          ),
        ),
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
      final payload = jsonDecode(ctrl.text);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('backup payload must be a JSON object');
      }
      await _api.importBackup(payload);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.configSourceSaved)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final kvEntries = _kvData.entries.toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Text(
                l10n.storageTables,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.download_outlined, size: 18),
                label: Text(l10n.backupExport),
                onPressed: _exportBackup,
              ),
              TextButton.icon(
                icon: const Icon(Icons.upload_outlined, size: 18),
                label: Text(l10n.backupImport),
                onPressed: _importBackup,
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
        Expanded(
          child: ListView(
            children: [
              if (kvEntries.isNotEmpty)
                ExpansionTile(
                  dense: true,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text('KV (${kvEntries.length})'),
                  initiallyExpanded: _tables.isEmpty,
                  children: [
                    for (final e in kvEntries)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.vpn_key_outlined, size: 18),
                        title: Text(
                          e.key,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        subtitle: Text(
                          '${e.value}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              for (final t in _tables) _tableTile(t, l10n, theme),
              if (_tables.isEmpty && kvEntries.isEmpty)
                EmptyState(
                  icon: Icons.storage_outlined,
                  title: l10n.detailTabEmpty,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableTile(
    Map<String, dynamic> t,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final name = t['name']?.toString() ?? '';
    final rows = (t['rows'] as num?)?.toInt();
    final builtin = t['builtin'] == true;
    final pages = _totalRows == 0 ? 1 : ((_totalRows - 1) ~/ _pageSize) + 1;
    final expanded = _openTable == name;
    return ExpansionTile(
      dense: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(name),
      subtitle: Text(
        [
          if (rows != null) '$rows ${l10n.storageTableRows}',
          if (builtin) 'builtin',
        ].join(' · '),
      ),
      onExpansionChanged: (open) {
        if (open) {
          _openRows(name);
        } else if (_openTable == name) {
          setState(() => _openTable = null);
        }
      },
      children: [
        if (expanded) ...[
          if (_rowsLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_rowsError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    _rowsError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openRows(name, page: _page),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            )
          else if (_rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.detailTabEmpty,
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            // 表格：列名取首行键（后端 columns 可能为空）
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 44,
                columns: [
                  for (final c in (_columns.isNotEmpty
                      ? _columns
                      : _rows.first.keys.toList()))
                    DataColumn(
                      label: Text(
                        c,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
                rows: [
                  for (final r in _rows)
                    DataRow(
                      cells: [
                        for (final c in (_columns.isNotEmpty
                            ? _columns
                            : _rows.first.keys.toList()))
                          DataCell(
                            Text(
                              '${r[c] ?? ''}',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed:
                    _page > 1 ? () => _openRows(name, page: _page - 1) : null,
                child: const Icon(Icons.chevron_left, size: 18),
              ),
              Text(
                '$_page / $pages',
                style: theme.textTheme.labelSmall,
              ),
              TextButton(
                onPressed: _page < pages
                    ? () => _openRows(name, page: _page + 1)
                    : null,
                child: const Icon(Icons.chevron_right, size: 18),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => _clearTable(name),
                child: Text(
                  l10n.storageClearTable,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
