// 创建实例页（本地 / 远程）。
//
// 本地实例：名称 + 端口（自动分配，可调整）。桌面端另选 ErisPulse SDK
// 版本（PyPI），创建后自动准备环境（内置 Python → venv → pip 安装）。
// 远程实例：名称 + Dashboard 地址（http://host:port）+ 可选访问令牌，
// 运行在其它主机，App 仅负责查看与打开 Dashboard。

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/app_settings.dart';
import '../services/instance_manager.dart';
import '../services/runtime/assets.dart';
import '../services/runtime/desktop_sdk.dart';
import '../services/runtime/runtime_controller.dart';

enum _InstanceType { local, remote }

/// 环境来源：全新环境（选 SDK 版本） / 基于已有实例（复制其 venv）
enum _EnvMode { fresh, clone }

class InstanceCreatePage extends StatefulWidget {
  const InstanceCreatePage({super.key});

  @override
  State<InstanceCreatePage> createState() => _InstanceCreatePageState();
}

class _InstanceCreatePageState extends State<InstanceCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _tokenCtrl;
  _InstanceType _type = _InstanceType.local;
  bool _submitting = false;

  /// 可选的 SDK 版本（PyPI，异步加载）
  List<SdkVersion> _versions = [];
  bool _versionsLoading = true;

  /// 选中的 SDK 版本（全新环境）
  String? _sdkVersion;

  /// 环境来源：全新环境 / 基于已有实例
  _EnvMode _envMode = _EnvMode.fresh;

  /// 基于已有实例：源实例 id
  String? _sourceInstanceId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    // 默认端口：当前实例数 + 8000
    _portCtrl = TextEditingController(
      text: '${8000 + context.read<InstanceManager>().count}',
    );
    _urlCtrl = TextEditingController();
    _tokenCtrl = TextEditingController();
    // 异步加载 PyPI 版本列表（两端本地实例需要）
    unawaited(_loadVersions());
  }

  Future<void> _loadVersions() async {
    final v = await DesktopSdk.availableVersions();
    if (!mounted) return;
    setState(() {
      _versions = v;
      _versionsLoading = false;
      _sdkVersion ??= v.isEmpty ? DesktopSdk.kDefaultVersion : v.first.version;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _portCtrl.dispose();
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRemote = _type == _InstanceType.remote;
    final l10n = AppLocalizations.of(context);
    final localInstances = context
        .watch<InstanceManager>()
        .instances
        .where((i) => !i.isRemote)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.commonCreateInstance)),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _CreateHeader(),
                const SizedBox(height: 20),
                SegmentedButton<_InstanceType>(
                  segments: [
                    ButtonSegment(
                      value: _InstanceType.local,
                      label: Text(l10n.commonLocal),
                      icon: Icon(
                        !Platform.isAndroid && !Platform.isIOS
                            ? Icons.desktop_windows
                            : Icons.phone_android,
                      ),
                    ),
                    ButtonSegment(
                      value: _InstanceType.remote,
                      label: Text(l10n.commonRemote),
                      icon: const Icon(Icons.cloud_outlined),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (sel) =>
                      setState(() => _type = sel.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.createNameLabel,
                    hintText: l10n.createNameHint,
                    helperText: l10n.createNameHelper,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return l10n.createNameRequired;
                    if (s.length > 24) return l10n.createNameTooLong;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (isRemote) ...[
                  TextFormField(
                    controller: _urlCtrl,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: l10n.createUrlLabel,
                      hintText: 'http://192.168.1.10:8000',
                      helperText: l10n.createUrlHelper,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link),
                    ),
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return l10n.createUrlRequired;
                      if (!s.startsWith('http://') &&
                          !s.startsWith('https://')) {
                        return l10n.createUrlScheme;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tokenCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.createTokenLabel,
                      helperText: l10n.createTokenHelper,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key_outlined),
                    ),
                    obscureText: true,
                  ),
                ] else ...[
                  TextFormField(
                    controller: _portCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.createPortLabel,
                      helperText: l10n.createPortHelper,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.dns_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return l10n.createPortRequired;
                      final port = int.tryParse(s);
                      if (port == null || port < 1024 || port > 65535) {
                        return l10n.createPortRange;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.createEnvTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // 环境来源（本地实例，两端）
                  SegmentedButton<_EnvMode>(
                    segments: [
                      ButtonSegment(
                        value: _EnvMode.fresh,
                        label: Text(l10n.createEnvFresh),
                        icon: const Icon(Icons.add_box_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: _EnvMode.clone,
                        label: Text(l10n.createEnvClone),
                        icon: const Icon(Icons.copy_all_outlined, size: 18),
                      ),
                    ],
                    selected: {_envMode},
                    onSelectionChanged: (s) =>
                        setState(() => _envMode = s.first),
                    showSelectedIcon: false,
                  ),
                  if (_envMode == _EnvMode.fresh) ...[
                    const SizedBox(height: 4),
                    if (_versionsLoading)
                      const ListTile(
                        leading: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: Text('加载 SDK 版本…'),
                      )
                    else if (_versions.isEmpty)
                      const ListTile(
                        leading: Icon(Icons.cloud_off_outlined),
                        title: Text('无法获取版本列表，将使用默认版本'),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _sdkVersion ?? _versions.first.version,
                        decoration: InputDecoration(
                          labelText: l10n.createSdkVersionLabel,
                          helperText: l10n.createSdkVersionHelper,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                        ),
                        items: [
                          for (final v in _versions)
                            DropdownMenuItem(
                              value: v.version,
                              child: Text(
                                v.version +
                                    (v.preRelease
                                        ? ' (${l10n.commonPreRelease})'
                                        : ''),
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _sdkVersion = v),
                      ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                        l10n.createEnvCloneDesc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                    if (_envMode == _EnvMode.clone) ...[
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: _sourceInstanceId,
                        decoration: InputDecoration(
                          labelText: l10n.createEnvCloneSource,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.copy_all_outlined),
                        ),
                        items: [
                          for (final inst in localInstances)
                            DropdownMenuItem(
                              value: inst.id,
                              child: Text(
                                '${inst.name}'
                                '${inst.runtimeVersion != null ? ' · v${inst.runtimeVersion}' : ''}',
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _sourceInstanceId = v),
                      ),
                    ],
                  ],
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(l10n.commonCreate),
                ),
                const SizedBox(height: 12),
                Text(
                  isRemote ? l10n.createRemoteNote : l10n.createLocalNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final mgr = context.read<InstanceManager>();
    final isRemote = _type == _InstanceType.remote;
    final l10n = AppLocalizations.of(context);
    if (!isRemote && _envMode == _EnvMode.clone && _sourceInstanceId == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.createEnvCloneNeedSource)),
      );
      return;
    }
    try {
      final inst = await mgr.createInstance(
        name: _nameCtrl.text.trim(),
        isRemote: isRemote,
        remoteUrl: isRemote ? _urlCtrl.text.trim() : null,
        token: isRemote
            ? (_tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim())
            : null,
        preferredPort: isRemote ? null : int.tryParse(_portCtrl.text.trim()),
        runtimeVersion:
            isRemote ? null : (_envMode == _EnvMode.fresh ? _sdkVersion : null),
      );
      if (!mounted) return;
      // 本地实例：创建后准备环境（全新：venv + pip 安装；基于已有实例：复制）
      if (!isRemote) {
        final settings = context.read<AppSettings>();
        await _showEnvProgress(
          context,
          instance: inst,
          mode: _envMode,
          sdkVersion: _envMode == _EnvMode.fresh
              ? (_sdkVersion ?? DesktopSdk.kDefaultVersion)
              : null,
          indexUrl: pypiIndexUrl(settings.pypiSource),
          sourceInstanceId:
              _envMode == _EnvMode.clone ? _sourceInstanceId : null,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.createCreated(inst.name))),
      );
      Navigator.of(context).pop(true);
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message?.toString() ?? AppLocalizations.of(context).createFailed,
          ),
        ),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).createFailedRetry),
        ),
      );
    }
  }

  /// 弹出环境准备进度对话框（venv 新建 / 复制源实例环境）
  Future<void> _showEnvProgress(
    BuildContext context, {
    required Instance instance,
    required _EnvMode mode,
    String? sdkVersion,
    required String indexUrl,
    String? sourceInstanceId,
  }) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EnvProgressDialog(
        instance: instance,
        mode: mode,
        sdkVersion: sdkVersion,
        indexUrl: indexUrl,
        sourceInstanceId: sourceInstanceId,
      ),
    );
  }
}

/// 顶部引导图标区
class _CreateHeader extends StatelessWidget {
  const _CreateHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          Icons.add_circle_outline,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(l10n.createTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          l10n.createSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 创建实例后的环境准备进度对话框（两端：venv 新建 / 复制源实例环境）
class _EnvProgressDialog extends StatefulWidget {
  const _EnvProgressDialog({
    required this.instance,
    required this.mode,
    this.sdkVersion,
    required this.indexUrl,
    this.sourceInstanceId,
  });

  final Instance instance;
  final _EnvMode mode;
  final String? sdkVersion;
  final String indexUrl;
  final String? sourceInstanceId;

  @override
  State<_EnvProgressDialog> createState() => _EnvProgressDialogState();
}

class _EnvProgressDialogState extends State<_EnvProgressDialog> {
  final List<String> _log = [];
  final Set<String> _seen = {};
  bool _done = false;
  int _exit = -1;
  final ScrollController _scroll = ScrollController();

  /// 复制进度（0.0~1.0）；null = 无限进度（fresh 的 pip 阶段）
  double? _progress;
  int _progressDone = 0;
  int _progressTotal = 0;
  int _lastProgressTick = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _append(String line) {
    if (!mounted) return;
    if (!_seen.add(line)) return;
    setState(() => _log.add(line));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  /// 移动端日志经 FGS → debugLog 到达，轮询拉取到弹窗
  void _pullDebugLog() {
    if (!mounted) return;
    final entries = context
        .read<RuntimeController>()
        .debugLog
        .entries
        .where((e) => e.instanceId == widget.instance.id);
    for (final e in entries) {
      _append(e.line);
    }
  }

  /// 复制进度回调（节流：每 50 个文件或收尾才刷新，避免频繁重建）
  void _onProgress(int done, int total) {
    if (!mounted) return;
    if (total > 0 && (done - _lastProgressTick).abs() < 50 && done != total) {
      return;
    }
    _lastProgressTick = done;
    setState(() {
      _progressDone = done;
      _progressTotal = total;
      _progress = total <= 0 ? null : (done / total).clamp(0.0, 1.0);
    });
  }

  Future<void> _run() async {
    final runtime = context.read<RuntimeController>();
    final mgr = context.read<InstanceManager>();
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    runtime.debugLog.addListener(_pullDebugLog);
    int code = 0;
    try {
      // 桌面全新环境：先确保内置 Python 就绪（含 pip 引导）
      if (isDesktop && widget.mode == _EnvMode.fresh) {
        if (!await DesktopSdk.isBundledPythonReady()) {
          code = await DesktopSdk.ensureBundledPython(onLog: _append);
        }
      }
      if (code == 0) {
        code = await runtime.prepareInstanceEnvironment(
          instance: widget.instance,
          mode: widget.mode.name,
          sourceInstanceId: widget.sourceInstanceId,
          sdkVersion: widget.sdkVersion,
          indexUrl: widget.indexUrl,
          onLog: _append,
          onProgress: _onProgress,
        );
      }
      // 基于已有实例：继承源实例的 SDK 版本记录
      if (code == 0 && widget.mode == _EnvMode.clone) {
        final src = widget.sourceInstanceId == null
            ? null
            : mgr.findById(widget.sourceInstanceId!);
        if (src?.runtimeVersion != null) {
          await mgr.setInstanceRuntime(
            widget.instance.id,
            src!.runtimeVersion,
          );
        }
      }
    } finally {
      runtime.debugLog.removeListener(_pullDebugLog);
    }
    if (mounted) {
      setState(() {
        _exit = code;
        _done = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.createPreparingEnv),
      content: SizedBox(
        width: 420,
        height: 260,
        child: _done
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _exit == 0 ? Icons.check_circle : Icons.error_outline,
                    color: _exit == 0 ? Colors.green : theme.colorScheme.error,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _exit == 0 ? l10n.createEnvReady : l10n.createEnvFailed,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_progress != null)
                    LinearProgressIndicator(value: _progress)
                  else
                    const LinearProgressIndicator(),
                  // 基于已有实例：明确展示"正在复制环境 + 文件进度"，
                  // 避免同步复制（旧版）让用户误以为卡死
                  if (widget.mode == _EnvMode.clone && !_done) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.createEnvCopying,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (_progressTotal > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.createEnvCopyProgress(
                          _progressDone,
                          _progressTotal,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 6),
                  Text(
                    l10n.createEnvPleaseWait,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFF0D1117),
                      padding: const EdgeInsets.all(8),
                      child: ListView.builder(
                        controller: _scroll,
                        itemCount: _log.length,
                        itemBuilder: (context, i) => Text(
                          _log[i],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFFC9D1D9),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _done ? () => Navigator.pop(context, _exit == 0) : null,
          child: Text(l10n.commonConfirm),
        ),
      ],
    );
  }
}
