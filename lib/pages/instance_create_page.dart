// 创建实例页（本地 / 远程）。
//
// 本地实例：名称 + 端口（自动分配，可调整），在手机 rootfs 内运行。
// 远程实例：名称 + Dashboard 地址（http://host:port）+ 可选访问令牌，
// 运行在其它主机，App 仅负责查看与打开 Dashboard。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/instance_manager.dart';

enum _InstanceType { local, remote }

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.commonCreateInstance)),
      body: Form(
        key: _formKey,
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
                  icon: const Icon(Icons.phone_android),
                ),
                ButtonSegment(
                  value: _InstanceType.remote,
                  label: Text(l10n.commonRemote),
                  icon: const Icon(Icons.cloud_outlined),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (sel) => setState(() => _type = sel.first),
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
                  if (!s.startsWith('http://') && !s.startsWith('https://')) {
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
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final mgr = context.read<InstanceManager>();
    final isRemote = _type == _InstanceType.remote;
    try {
      final inst = await mgr.createInstance(
        name: _nameCtrl.text.trim(),
        isRemote: isRemote,
        remoteUrl: isRemote ? _urlCtrl.text.trim() : null,
        token: isRemote
            ? (_tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim())
            : null,
        preferredPort: isRemote ? null : int.tryParse(_portCtrl.text.trim()),
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
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
