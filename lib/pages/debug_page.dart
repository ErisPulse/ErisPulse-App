// 调试页：完整的应用 / 设备 / 运行时信息 + 全量进程日志。
//
// 信息区展示：
//   - 应用：包名、版本
//   - 设备：型号、Android 版本、SDK、ABI
//   - 运行时：rootfs 状态 / 进度 / 错误、native lib 目录、实例数量
// 日志区展示 proot 进程的完整 stdout/stderr（来自 RuntimeController.debugLog）。
//
// 复制：AppBar "复制全部" 一次性输出 信息 + 日志；日志区可单独复制。

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/instance_manager.dart';
import '../services/runtime/debug_log.dart';
import '../services/runtime/native_lib.dart';
import '../services/runtime/runtime_controller.dart';

class DebugPage extends StatefulWidget {
  static const routeName = '/debug';
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  String _appVersion = '…';
  String _appBuild = '';

  /// Android 设备信息（仅 Android 平台）
  AndroidDeviceInfo? _device;

  /// 桌面 / iOS 系统版本（PC 不再显示 Android 设备行）
  String _osVersion = '';
  String _nativeLibDir = '';

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _appBuild = info.buildNumber;
    } catch (_) {}
    try {
      if (Platform.isAndroid) {
        _device = await DeviceInfoPlugin().androidInfo;
      } else if (Platform.isIOS) {
        _osVersion = 'iOS ${Platform.operatingSystemVersion}';
      } else {
        // 桌面（Windows / Linux / macOS）：显示操作系统版本
        _osVersion =
            '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      }
    } catch (_) {}
    _nativeLibDir = await readNativeLibraryDir();
    if (mounted) setState(() {});
  }

  String _infoText(RuntimeController runtime) {
    final l10n = AppLocalizations.of(context);
    final d = _device;
    final buf = StringBuffer()
      ..writeln(l10n.debugInfoHeader)
      ..writeln('${l10n.debugAppVersion}: $_appVersion (build $_appBuild)')
      ..writeln('${l10n.debugPackageName}: com.erispulse.erispulse_app');
    if (d != null) {
      buf
        ..writeln('${l10n.debugDeviceModel}: ${d.model}')
        ..writeln('${l10n.debugBrand}: ${d.brand}')
        ..writeln(
          '${l10n.debugAndroid}: ${d.version.release} (SDK ${d.version.sdkInt})',
        )
        ..writeln('${l10n.debugAbi}: ${d.supportedAbis.join(', ')}');
    } else {
      buf.writeln(
        '${l10n.debugSystem}: ${_osVersion.isEmpty ? '-' : _osVersion}',
      );
    }
    buf
      ..writeln('${l10n.debugNativeLib}: $_nativeLibDir')
      ..writeln(
        '${l10n.debugRootfs}: ${runtime.rootfsReady ? l10n.debugReady : l10n.debugNotReady}'
        '${runtime.rootfsProgress != null ? ' (${runtime.rootfsProgress!.round()}%)' : ''}',
      )
      ..writeln('${l10n.debugRootfsMessage}: ${runtime.rootfsMessage ?? '-'}')
      ..writeln(
        '${l10n.debugInstanceCount}: ${context.read<InstanceManager>().count}',
      )
      ..writeln('');
    return buf.toString();
  }

  List<String> _logLines(RuntimeController runtime) => [
        for (final e in runtime.debugLog.entries)
          '${e.time.toLocal().toString().substring(11, 19)} '
              '[${e.instanceId}] ${e.line}',
      ];

  Future<void> _copyAll(RuntimeController runtime) async {
    final text =
        '${_infoText(runtime)}== ${AppLocalizations.of(context).debugLogHeader} ==\n'
        '${_logLines(runtime).join('\n')}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).debugCopiedAll)),
      );
    }
  }

  Future<void> _copyLogs(RuntimeController runtime) async {
    final text = _logLines(runtime).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).debugCopiedLogs)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debugTitle),
        actions: [
          Consumer<RuntimeController>(
            builder: (context, runtime, _) => IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: l10n.debugCopyAllTooltip,
              onPressed: () => _copyAll(runtime),
            ),
          ),
          Consumer<RuntimeController>(
            builder: (context, runtime, _) => IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l10n.debugClearLogsTooltip,
              onPressed: runtime.debugLog.clear,
            ),
          ),
        ],
      ),
      body: Consumer<RuntimeController>(
        builder: (context, runtime, _) {
          final l10n = AppLocalizations.of(context);
          return Column(
            children: [
              SizedBox(
                height: 210,
                child: _InfoSection(
                  rows: [
                    (l10n.debugAppVersion, '$_appVersion (build $_appBuild)'),
                    if (_device != null)
                      (l10n.debugDeviceModel, _device!.model),
                    if (_device != null)
                      (
                        l10n.debugAndroid,
                        '${_device!.version.release} (SDK ${_device!.version.sdkInt})'
                      ),
                    if (_device != null)
                      (l10n.debugAbi, _device!.supportedAbis.join(', ')),
                    if (_device == null)
                      (l10n.debugSystem, _osVersion.isEmpty ? '…' : _osVersion),
                    (
                      l10n.debugNativeLib,
                      _nativeLibDir.isEmpty ? '…' : _nativeLibDir
                    ),
                    (
                      l10n.debugRootfs,
                      runtime.rootfsReady
                          ? l10n.debugReady
                          : '${l10n.debugNotReady}${runtime.rootfsProgress != null ? ' (${runtime.rootfsProgress!.round()}%)' : ''}'
                    ),
                    if (runtime.rootfsError != null)
                      (l10n.debugRootfsError, runtime.rootfsError!),
                    (
                      l10n.debugInstanceCount,
                      '${context.read<InstanceManager>().count}'
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.terminal, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.debugProcessLogs,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Spacer(),
                    Consumer<RuntimeController>(
                      builder: (context, runtime, _) => TextButton.icon(
                        onPressed: () => _copyLogs(runtime),
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text(l10n.commonCopy),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListenableBuilder(
                  listenable: runtime.debugLog,
                  builder: (context, _) {
                    final entries = runtime.debugLog.entries;
                    if (entries.isEmpty) {
                      return Center(child: Text(l10n.debugNoLogs));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: entries.length,
                      itemBuilder: (context, i) =>
                          _DebugLogLine(entry: entries[i]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 信息行区（key: value）
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (final (k, v) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    k,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    v,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 单条日志行
class _DebugLogLine extends StatelessWidget {
  const _DebugLogLine({required this.entry});
  final DebugLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = entry.time.toLocal();
    final hhmmss = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            child: Text(
              hhmmss,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              '[${entry.instanceId}] ${entry.line}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
