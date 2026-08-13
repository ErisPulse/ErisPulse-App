// 首启向导：准备运行时环境。
//
// Android：rootfs 下载 / 解压进度（由 FGS 转发）。
// 桌面（Windows/Linux）：检查捆绑 Python 与 ErisPulse SDK，
// 未安装时让用户从 PyPI 选择版本安装（默认最新），完成后进入主界面。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/runtime/desktop_runtime.dart';
import '../services/runtime/desktop_sdk.dart';
import '../services/runtime/runtime_controller.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final bool _isDesktop = !Platform.isAndroid && !Platform.isIOS;

  // ── Android：rootfs 下载 ──
  bool _started = false;
  bool _showLog = false;
  bool _busy = false;
  final List<String> _log = [];
  final ScrollController _logScroll = ScrollController();

  // ── 桌面：SDK 环境准备 ──
  bool _sdkLoaded = false;
  bool _sdkInstalling = false;
  String? _sdkVersion;
  String? _selectedVersion;
  String? _pythonMissing;
  List<SdkVersion> _versions = [];

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      _loadDesktopEnv();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<RuntimeController>();
      if (ctrl.rootfsReady) {
        widget.onDone();
        return;
      }
      // 从主页横幅进入：若下载已在进行，直接显示进度，不重复触发
      if (ctrl.rootfsProgress != null || ctrl.rootfsMessage != null) {
        _started = true;
        _busy = true;
      }
    });
  }

  @override
  void dispose() {
    _logScroll.dispose();
    super.dispose();
  }

  Future<void> _loadDesktopEnv() async {
    final python = await DesktopEnv.pythonPath();
    if (!File(python).existsSync()) {
      setState(() => _pythonMissing = python);
      return;
    }
    final sdk = await DesktopSdk.installedVersion();
    if (!mounted) return;
    setState(() => _sdkVersion = sdk);
    if (sdk != null) {
      widget.onDone();
      return;
    }
    final versions = await DesktopSdk.availableVersions();
    if (!mounted) return;
    setState(() {
      _versions = versions;
      _sdkLoaded = true;
      if (_selectedVersion == null && versions.isNotEmpty) {
        _selectedVersion = versions.first.version;
      }
    });
  }

  Future<void> _installSdk() async {
    final version = _selectedVersion ?? _versions.first.version;
    setState(() => _sdkInstalling = true);
    await context.read<RuntimeController>().installSdk(
          version,
          onLog: _appendLog,
        );
    if (!mounted) return;
    setState(() => _sdkInstalling = false);
    if (context.read<RuntimeController>().rootfsReady) {
      widget.onDone();
    }
  }

  // ── Android ──

  void _start() {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _started = true;
      _busy = true;
    });
    _appendLog(l10n.onboardingStartingLog);
    context.read<RuntimeController>().ensureRootfs();
  }

  void _appendLog(String line) {
    if (!mounted) return;
    setState(
      () => _log.add(
        '[${DateTime.now().toLocal().toString().substring(11, 19)}] $line',
      ),
    );
    // 日志跟随滚动：新日志追加后自动滚到最底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_logScroll.hasClients) return;
      _logScroll.jumpTo(_logScroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return Scaffold(body: _buildDesktop(context));
    }
    return _buildAndroid(context);
  }

  // ── 桌面 UI：SDK 版本选择与安装 ──

  Widget _buildDesktop(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: theme.colorScheme.surface),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 72),
                const SizedBox(height: 16),
                Text(
                  l10n.onboardingSdkTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                _buildDesktopBody(theme, l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopBody(ThemeData theme, AppLocalizations l10n) {
    if (_pythonMissing != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingSdkPythonMissing(_pythonMissing!),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _loadDesktopEnv,
            child: Text(l10n.onboardingSdkRefresh),
          ),
        ],
      );
    }
    if (_sdkInstalling) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.onboardingSdkInstalling),
        ],
      );
    }
    if (_sdkVersion != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
          const SizedBox(height: 12),
          Text(l10n.onboardingSdkInstalled(_sdkVersion!)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.onDone,
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.onboardingSdkContinue),
          ),
        ],
      );
    }
    if (_versions.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.onboardingSdkChooseVersion,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            value: _selectedVersion,
            items: [
              for (final v in _versions)
                DropdownMenuItem(
                  value: v.version,
                  child: Text(v.version),
                ),
            ],
            onChanged: (v) => setState(() => _selectedVersion = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _installSdk,
            icon: const Icon(Icons.download),
            label: Text(l10n.onboardingSdkInstall),
          ),
          TextButton(
            onPressed: _loadDesktopEnv,
            child: Text(l10n.onboardingSdkRefresh),
          ),
        ],
      );
    }
    if (_sdkLoaded && _versions.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingSdkVersionFailed,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _loadDesktopEnv,
            child: Text(l10n.onboardingSdkRefresh),
          ),
        ],
      );
    }
    return const CircularProgressIndicator();
  }

  // ── Android UI：rootfs 进度 ──

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      body: Consumer<RuntimeController>(
        builder: (context, ctrl, _) {
          final l10n = AppLocalizations.of(context);
          // 完成检测
          if (ctrl.rootfsReady && _busy) {
            _busy = false;
            _appendLog(l10n.onboardingReadyLog);
            WidgetsBinding.instance
                .addPostFrameCallback((_) => widget.onDone());
          }

          // 错误注入日志
          if (ctrl.rootfsError != null && ctrl.rootfsError!.isNotEmpty) {
            final msg = ctrl.rootfsError!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _appendLog(l10n.onboardingErrorLog(msg));
            });
            ctrl.rootfsError = null;
          }

          // 进度消息注入日志
          final msg = ctrl.rootfsMessage;
          if (msg != null && _started) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _appendLog(msg);
            });
            ctrl.rootfsMessage = null;
          }

          return GestureDetector(
            onTap: () => setState(() => _showLog = !_showLog),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                if (!_showLog)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt, size: 72),
                          const SizedBox(height: 16),
                          Text(
                            l10n.onboardingTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.onboardingDescription,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 32),
                          if (_started)
                            _buildProgress(ctrl, l10n)
                          else
                            FilledButton.icon(
                              onPressed: _start,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(l10n.onboardingStartButton),
                            ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.onboardingTapHint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildLogView(context, l10n),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgress(RuntimeController ctrl, AppLocalizations l10n) {
    final percent = ctrl.rootfsProgress;
    return Column(
      children: [
        if (percent != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 100) / 100,
              minHeight: 8,
            ),
          )
        else
          const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          ctrl.rootfsMessage ?? l10n.onboardingProcessing,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLogView(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: const Color(0xFF0D1117),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.onboardingLogTitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _logScroll,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
          ],
        ),
      ),
    );
  }
}
