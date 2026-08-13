// 首启向导：准备运行时环境。
//
// Android：rootfs 下载 / 解压进度（由 FGS 转发）。
// 桌面（Windows/Linux/macOS）：App 构建内置对应平台 Python，
// 释放（含 pip 引导）后进入主界面。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
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

  // ── 桌面：内置 Python 释放 ──
  bool _pythonStarted = false;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      return; // 桌面：由 build 根据 RuntimeController 状态渲染
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

  // ── 桌面 ──

  /// 释放内置 Python 环境（含 pip 引导）
  void _releasePython() {
    final runtime = context.read<RuntimeController>();
    if (runtime.bundledPythonBusy) return;
    setState(() {
      _pythonStarted = true;
      _busy = true;
    });
    runtime.ensureBundledPython(onLog: _appendLog);
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

  // ── 桌面 UI：运行时版本选择 ──

  Widget _buildDesktop(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingSdkTitle)),
      body: Stack(
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
      ),
    );
  }

  Widget _buildDesktopBody(ThemeData theme, AppLocalizations l10n) {
    final runtime = context.watch<RuntimeController>();
    // 已就绪：进入主界面
    if (runtime.rootfsReady) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          Text(
            'Python ${runtime.bundledPythonVersion ?? '?'} ${l10n.onboardingPythonReady}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: widget.onDone,
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.onboardingSdkContinue),
          ),
        ],
      );
    }
    // 释放中：进度 + 日志
    if (runtime.bundledPythonBusy) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(minHeight: 6),
          ),
          const SizedBox(height: 12),
          Text(
            runtime.bundledPythonMessage ?? l10n.onboardingPythonReleasing,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_log.isNotEmpty)
            SizedBox(
              height: 160,
              width: 480,
              child: Container(
                color: const Color(0xFF0D1117),
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  controller: _logScroll,
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
      );
    }
    // 释放失败：提示 + 重试
    if (_pythonStarted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingPythonFailed,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _releasePython,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.commonRetry),
          ),
        ],
      );
    }
    // 未开始：释放按钮
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.onboardingPythonIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _releasePython,
          icon: const Icon(Icons.bolt),
          label: Text(l10n.onboardingPythonRelease),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.read<RuntimeController>().refreshRootfs(),
          child: Text(l10n.onboardingSdkRefresh),
        ),
      ],
    );
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
