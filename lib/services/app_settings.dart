// 全局应用设置（主题 / 语言等）：持久化到 SharedPreferences。
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const _kThemeMode = 'erispulse.theme_mode';
  static const _kLocale = 'erispulse.locale';
  static const _kDownloadSource = 'erispulse.download_source';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  String _downloadSource = 'github';

  ThemeMode get themeMode => _themeMode;

  /// 界面语言；null 表示跟随系统
  Locale? get locale => _locale;

  /// 运行时资产下载源（github / ghfast / ghproxy）
  String get downloadSource => _downloadSource;

  /// 从本地存储加载
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_kThemeMode);
      _themeMode = switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      _locale = _localeFromCode(prefs.getString(_kLocale));
      _downloadSource = prefs.getString(_kDownloadSource) ?? 'github';
    } catch (_) {}
    notifyListeners();
  }

  /// 切换主题（跟随系统 / 浅色 / 深色）
  Future<void> setThemeMode(ThemeMode m) async {
    if (_themeMode == m) return;
    _themeMode = m;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kThemeMode,
        switch (m) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          _ => 'system',
        },
      );
    } catch (_) {}
  }

  /// 切换界面语言；[code] 为 `system`（跟随系统）/ `zh` / `zh_Hant` / `en` / `ja` / `ru`
  Future<void> setLocale(String code) async {
    final loc = _localeFromCode(code);
    if (_locale == loc) return;
    _locale = loc;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocale, code);
    } catch (_) {}
  }

  static Locale? _localeFromCode(String? code) => switch (code) {
        'zh' => const Locale('zh'),
        'zh_Hant' => const Locale('zh', 'Hant'),
        'en' => const Locale('en'),
        'ja' => const Locale('ja'),
        'ru' => const Locale('ru'),
        _ => null,
      };

  /// 切换下载源（github 直连 / 国内加速镜像）
  Future<void> setDownloadSource(String source) async {
    if (_downloadSource == source) return;
    _downloadSource = source;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDownloadSource, source);
    } catch (_) {}
  }
}
