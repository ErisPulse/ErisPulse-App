// 实例文件浏览 Tab。
//
// 桌面 / 移动端统一走 Dashboard API（与 Web 端一致）：
//   GET  /files/browse?path=  列目录（entries）
//   GET  /files/read?path=    读文件
//   PUT  /files/write         写文件
//   POST /files/delete        删除
// 路径为 rootfs 相对路径；实例未运行 / API 不可达时显示错误并可重试。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import 'package:file_picker/file_picker.dart';

class FilesTab extends StatefulWidget {
  final Instance instance;
  const FilesTab({super.key, required this.instance});

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> {
  /// 当前 rootfs 相对路径（空 = 根）
  String _path = '';
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  ApiException? _error;

  /// 多选删除集合（entry path）
  final Set<String> _selection = <String>{};

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
      final files = await DashboardApi(widget.instance)
          .listFiles(path: _path.isEmpty ? '.' : _path);
      if (!mounted) return;
      setState(() {
        _entries = files;
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

  void _goUp() {
    final idx = _path.lastIndexOf('/');
    setState(() => _path = idx < 0 ? '' : _path.substring(0, idx));
    _load();
  }

  void _open(Map<String, dynamic> e) {
    final name = (e['name'] ?? '').toString();
    final path = (e['path'] ?? name).toString();
    if ((e['type'] ?? '') == 'directory') {
      setState(() => _path = path);
      _load();
      return;
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => _FileEditPage(
              instance: widget.instance,
              path: path,
              name: name,
            ),
          ),
        )
        .then((_) => _load());
  }

  Future<void> _mkdir(String name, {bool asFile = false}) async {
    final api = DashboardApi(widget.instance);
    final base = _path.isEmpty ? '' : '$_path/';
    final path = '$base$name';
    try {
      if (asFile) {
        await api.writeFile(path, '');
      } else {
        await api.mkdir(path);
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _renameEntry(Map<String, dynamic> e) async {
    final l10n = AppLocalizations.of(context);
    final name = (e['name'] ?? '').toString();
    final path = (e['path'] ?? name).toString();
    final ctrl = TextEditingController(text: name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonRename),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == name) return;
    try {
      await DashboardApi(widget.instance).renameFile(path, newName);
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _deleteSelected() async {
    final l10n = AppLocalizations.of(context);
    if (_selection.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text('${_selection.length} items'),
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
    if (ok != true) return;
    try {
      await DashboardApi(widget.instance).deleteFiles(_selection.toList());
      setState(() => _selection.clear());
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _uploadFiles() async {
    final picked = await FilePicker.platform.pickFiles(allowMultiple: true);
    final paths = picked == null
        ? <String>[]
        : [
            for (final f in picked.files)
              if (f.path != null) f.path!,
          ];
    if (paths.isEmpty) return;
    try {
      await DashboardApi(
        widget.instance,
      ).uploadFiles(_path.isEmpty ? '.' : _path, paths);
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _showCreateMenu() async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final mode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonCreate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.folder_outlined, size: 18),
                    label: const Text('Folder'),
                    onPressed: () => Navigator.pop(ctx, 'folder'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 18,
                    ),
                    label: const Text('File'),
                    onPressed: () => Navigator.pop(ctx, 'file'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    );
    final name = ctrl.text.trim();
    if (mode == null || name.isEmpty) return;
    await _mkdir(name, asFile: mode == 'file');
  }

  Future<void> _delete(Map<String, dynamic> e) async {
    final l10n = AppLocalizations.of(context);
    final name = (e['name'] ?? '').toString();
    final path = (e['path'] ?? name).toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text(l10n.detailFileDeleteConfirm(name)),
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
    if (ok != true) return;
    try {
      await DashboardApi(widget.instance).deleteFiles([path]);
      await _load();
    } on ApiException catch (e) {
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
    final sorted = List<Map<String, dynamic>>.of(_entries)
      ..sort((a, b) {
        final da = (a['type'] ?? '') == 'directory';
        final db = (b['type'] ?? '') == 'directory';
        if (da != db) return da ? -1 : 1;
        return (a['name'] ?? '').toString().toLowerCase().compareTo(
              (b['name'] ?? '').toString().toLowerCase(),
            );
      });
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _path.isEmpty ? null : _goUp,
              ),
              Expanded(
                child: Text(
                  _path.isEmpty ? '/' : '/$_path',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.upload_outlined),
                tooltip: l10n.filesUpload,
                onPressed: _uploadFiles,
              ),
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: l10n.commonCreate,
                onPressed: _showCreateMenu,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
                onPressed: _load,
              ),
            ],
          ),
        ),
        if (_selection.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_selection.length} selected',
                  style: theme.textTheme.labelSmall,
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.commonDelete),
                  onPressed: _deleteSelected,
                ),
                TextButton(
                  onPressed: () => setState(() => _selection.clear()),
                  child: Text(l10n.commonCancel),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _error!.isAuth
                                ? Icons.lock_outline
                                : Icons.cloud_off_outlined,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _error!.isAuth
                                  ? l10n.detailAuthInvalid
                                  : '${_error!}',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: _load,
                            child: Text(l10n.commonRetry),
                          ),
                        ],
                      ),
                    )
                  : sorted.isEmpty
                      ? Center(
                          child: Text(
                            l10n.detailTabEmpty,
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final e = sorted[i];
                            final isDir = (e['type'] ?? '') == 'directory';
                            final path =
                                (e['path'] ?? e['name'] ?? '').toString();
                            return ListTile(
                              leading: Icon(
                                isDir
                                    ? Icons.folder_outlined
                                    : Icons.insert_drive_file_outlined,
                                color: isDir ? theme.colorScheme.primary : null,
                              ),
                              title: Text((e['name'] ?? '').toString()),
                              subtitle: isDir
                                  ? null
                                  : Text(
                                      _formatSize(
                                        (e['size'] as num?)?.toInt() ?? 0,
                                      ),
                                    ),
                              selected: _selection.contains(path),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'rename',
                                    child: Text(l10n.commonRename),
                                  ),
                                  PopupMenuItem(
                                    value: 'select',
                                    child: Text(l10n.batchMode),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(l10n.commonDelete),
                                  ),
                                ],
                                onSelected: (action) {
                                  switch (action) {
                                    case 'rename':
                                      _renameEntry(e);
                                    case 'select':
                                      setState(() => _selection.add(path));
                                    case 'delete':
                                      _delete(e);
                                  }
                                },
                              ),
                              onTap: () {
                                if (_selection.isNotEmpty) {
                                  setState(() {
                                    _selection.contains(path)
                                        ? _selection.remove(path)
                                        : _selection.add(path);
                                  });
                                  return;
                                }
                                _open(e);
                              },
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

String _formatSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '$bytes B';
}

/// 文件查看 / 编辑 / 保存 / 删除页（统一走 API）
class _FileEditPage extends StatefulWidget {
  final Instance instance;
  final String path;
  final String name;

  const _FileEditPage({
    required this.instance,
    required this.path,
    required this.name,
  });

  @override
  State<_FileEditPage> createState() => _FileEditPageState();
}

class _FileEditPageState extends State<_FileEditPage> {
  late final TextEditingController _ctrl;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = await DashboardApi(widget.instance).readFile(widget.path);
      if (!mounted) return;
      setState(() {
        _ctrl.text = content;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DashboardApi(widget.instance).writeFile(widget.path, _ctrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).detailFileSaved),
        ),
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

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _ctrl.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).detailConfigCopied),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text(l10n.detailFileDeleteConfirm(widget.name)),
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
      try {
        await DashboardApi(widget.instance).deleteFiles([widget.path]);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: l10n.dashboardCopyTokenTooltip,
            onPressed: _copy,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.commonDelete,
            onPressed: _delete,
          ),
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            tooltip: l10n.detailFileSave,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: _load,
                          child: Text(l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _ctrl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
    );
  }
}
