// 运行时管理页（桌面）。
//
// 展示 PC 端环境：
//   - 内置 Python（python-build-standalone）状态 / 释放
//   - 各本地实例的独立 venv 环境（ErisPulse 版本 / 就绪状态）
//   - PyPI 镜像源选择

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/app_settings.dart';
import '../services/instance_manager.dart';
import '../services/runtime/assets.dart';
import '../services/runtime/desktop_sdk.dart';
import '../services/runtime/runtime_controller.dart';

class RuntimeManagerPage extends StatefulWidget {
  const RuntimeManagerPage({super.key});

  static const routeName = '/runtime-manager';

  @override
  State<RuntimeManagerPage> createState() => _RuntimeManagerPageState();
}

class _RuntimeManagerPageState extends State<RuntimeManagerPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.runtimeManagerTitle)),
      body: Consumer<RuntimeController>(
        builder: (context, runtime, _) {
          final instances = context
              .watch<InstanceManager>()
              .instances
              .where((i) => !i.isRemote)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPythonCard(context, theme, l10n, runtime),
              const SizedBox(height: 16),
              Text(
                l10n.runtimeManagerInstances,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (instances.isEmpty)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.inbox_outlined),
                    title: Text(l10n.runtimeManagerEmpty),
                  ),
                )
              else
                for (final inst in instances) _InstanceEnvCard(instance: inst),
              const Divider(height: 24),
              _buildPypiSection(context, theme, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPythonCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    RuntimeController runtime,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          runtime.rootfsReady ? Icons.check_circle : Icons.bolt_outlined,
          color: runtime.rootfsReady ? Colors.green : null,
        ),
        title: Text(l10n.settingsRuntime),
        subtitle: Text(
          runtime.rootfsReady
              ? 'Python ${runtime.bundledPythonVersion ?? '?'}'
              : (runtime.bundledPythonBusy
                  ? (runtime.bundledPythonMessage ??
                      l10n.onboardingPythonReleasing)
                  : l10n.runtimeManagerPythonMissing),
        ),
        trailing: runtime.rootfsReady
            ? const Icon(Icons.check_circle, color: Colors.green)
            : runtime.bundledPythonBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: runtime.ensureRootfs,
                    child: Text(l10n.commonInitialize),
                  ),
      ),
    );
  }

  Widget _buildPypiSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final settings = context.watch<AppSettings>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsPypiSource, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final (code, label) in _pypiSourceOptions(l10n))
              ChoiceChip(
                label: Text(label),
                selected: settings.pypiSource == code,
                onSelected: (_) => settings.setPypiSource(code),
              ),
          ],
        ),
      ],
    );
  }

  static List<(String, String)> _pypiSourceOptions(AppLocalizations l10n) => [
        (kPypiSourceOfficial, l10n.settingsPypiOfficial),
        (kPypiSourceTsinghua, l10n.settingsPypiTsinghua),
        (kPypiSourceAliyun, l10n.settingsPypiAliyun),
      ];
}

/// 单个本地实例的 venv 环境卡片
class _InstanceEnvCard extends StatefulWidget {
  const _InstanceEnvCard({required this.instance});

  final Instance instance;

  @override
  State<_InstanceEnvCard> createState() => _InstanceEnvCardState();
}

class _InstanceEnvCardState extends State<_InstanceEnvCard> {
  String? _sdkVersion;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sdk = await DesktopSdk.installedSdkVersion(widget.instance.id);
    if (!mounted) return;
    setState(() {
      _sdkVersion = sdk;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = _sdkVersion != null && _sdkVersion!.isNotEmpty;
    return Card(
      child: ListTile(
        leading: Icon(
          ready ? Icons.check_circle : Icons.build_circle_outlined,
          color: ready ? Colors.green : null,
        ),
        title: Text(widget.instance.name),
        subtitle: Text(
          _loading
              ? '…'
              : ready
                  ? 'ErisPulse v$_sdkVersion'
                  : '环境未就绪',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
