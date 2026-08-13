// 设置页。
//
// 运行时管理：
//   - 运行环境（Android: rootfs；桌面: Python + ErisPulse SDK）状态 / 初始化
//   - 崩溃自动重启开关
//   - 停止所有实例
// 数据：
//   - 清空调试日志
// 关于：
//   - 版本信息 / 关于弹窗

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/runtime/assets.dart';
import '../services/runtime/runtime_controller.dart';
import 'onboarding_page.dart';

class SettingsPage extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '…';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _confirmStopAll(RuntimeController runtime) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).settingsStopAll),
        content: Text(AppLocalizations.of(ctx).settingsStopAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(ctx).settingsStopAllAction),
          ),
        ],
      ),
    );
    if (ok == true) runtime.stopAll();
  }

  static String _localeCode(Locale? loc) {
    if (loc == null) return 'system';
    if (loc.languageCode == 'zh' && loc.scriptCode == 'Hant') {
      return 'zh_Hant';
    }
    return loc.languageCode;
  }

  static List<(String, String)> _localeOptions(AppLocalizations l10n) => [
        ('system', l10n.settingsLangSystem),
        ('zh', l10n.settingsLangZh),
        ('zh_Hant', l10n.settingsLangZhHant),
        ('en', l10n.settingsLangEn),
        ('ja', l10n.settingsLangJa),
        ('ru', l10n.settingsLangRu),
      ];

  static List<(String, String)> _downloadSourceOptions(AppLocalizations l10n) =>
      [
        (kDownloadSourceGithub, l10n.settingsDownloadGithub),
        (kDownloadSourceGhfast, l10n.settingsDownloadGhfast),
        (kDownloadSourceGhproxy, l10n.settingsDownloadGhproxy),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.commonSettings)),
      body: Consumer<RuntimeController>(
        builder: (context, runtime, _) => Consumer<AppSettings>(
          builder: (context, settings, _) {
            final isDesktop = !Platform.isAndroid && !Platform.isIOS;
            return ListView(
              children: [
                // Logo（横版按比例完整展示）
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 176,
                      height: 99,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.bolt, size: 64),
                    ),
                  ),
                ),
                _SectionHeader(
                  title: l10n.settingsAppearance,
                  icon: Icons.palette_outlined,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.settingsThemeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.settingsThemeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.settingsThemeDark),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (sel) =>
                        settings.setThemeMode(sel.first),
                    showSelectedIcon: false,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(l10n.settingsLanguage),
                  trailing: DropdownButton<String>(
                    value: _localeCode(settings.locale),
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final (code, label) in _localeOptions(l10n))
                        DropdownMenuItem(value: code, child: Text(label)),
                    ],
                    onChanged: (v) {
                      if (v != null) settings.setLocale(v);
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: Text(l10n.settingsDownloadSource),
                  trailing: DropdownButton<String>(
                    value: settings.downloadSource,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final (code, label) in _downloadSourceOptions(l10n))
                        DropdownMenuItem(value: code, child: Text(label)),
                    ],
                    onChanged: (v) {
                      if (v != null) settings.setDownloadSource(v);
                    },
                  ),
                ),
                _SectionHeader(
                  title: l10n.settingsRuntime,
                  icon: Icons.settings_suggest_outlined,
                ),
                ListTile(
                  leading: Icon(
                    runtime.rootfsReady
                        ? Icons.folder_zip_outlined
                        : Icons.download_outlined,
                  ),
                  title: Text(
                    isDesktop ? l10n.settingsRuntime : l10n.settingsRootfsTitle,
                  ),
                  subtitle: Text(
                    isDesktop
                        ? (runtime.rootfsReady
                            ? l10n.settingsRuntimeReady(
                                runtime.sdkInstalledVersion ?? '?',
                              )
                            : l10n.homeBannerNeedSdk)
                        : (runtime.rootfsError ??
                            runtime.rootfsMessage ??
                            (runtime.rootfsReady
                                ? l10n.settingsRootfsReady
                                : l10n.settingsRootfsNotReady)),
                  ),
                  trailing: runtime.rootfsReady
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : TextButton(
                          onPressed: isDesktop
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => OnboardingPage(
                                        onDone: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ),
                                  )
                              : runtime.ensureRootfs,
                          child: Text(
                            isDesktop
                                ? l10n.onboardingSdkInstall
                                : l10n.commonInitialize,
                          ),
                        ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.autorenew),
                  title: Text(l10n.settingsAutoRestart),
                  subtitle: Text(l10n.settingsAutoRestartDesc),
                  value: runtime.autoRestart,
                  onChanged: runtime.setAutoRestart,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: Text(l10n.settingsStopAll),
                  subtitle: Text(l10n.settingsStopAllDesc),
                  onTap: () => _confirmStopAll(runtime),
                ),
                _SectionHeader(
                  title: l10n.settingsData,
                  icon: Icons.storage_outlined,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: Text(l10n.settingsClearLogs),
                  subtitle: Text(l10n.settingsClearLogsDesc),
                  onTap: runtime.debugLog.clear,
                ),
                _SectionHeader(
                  title: l10n.settingsAbout,
                  icon: Icons.info_outline,
                ),
                ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text(l10n.settingsVersion),
                  subtitle: Text('ErisPulse-App $_appVersion'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.settingsAboutApp),
                  subtitle: Text(l10n.settingsAboutSubtitle),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'ErisPulse-App',
                    applicationVersion: _appVersion,
                    applicationIcon: const Icon(Icons.bolt, size: 48),
                    children: [
                      Text(
                        l10n.settingsAboutDialog,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 分组标题
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
