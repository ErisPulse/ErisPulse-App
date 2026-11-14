// 全局应用设置（主题 / 语言等）：持久化到 SharedPreferences。
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'distribution.dart';

class AppSettings extends ChangeNotifier {
  static const _kThemeMode = 'erispulse.theme_mode';
  static const _kLocale = 'erispulse.locale';
  static const _kDownloadSource = 'erispulse.download_source';
  static const _kPypiSource = 'erispulse.pypi_source';
  static const _kCloseAction = 'erispulse.close_action';
  static const _kRefreshSeconds = 'erispulse.refresh_seconds';
  static const _kDynamicColor = 'erispulse.dynamic_color';
  static const _kPrivacyMode = 'erispulse.privacy_mode';
  static const _kEventLimit = 'erispulse.event_limit';
  static const _kNotifyOnCrash = 'erispulse.notify_on_crash';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  String _downloadSource = 'github';
  String _pypiSource = 'pypi';
  String _closeAction = 'ask';
  int _refreshSeconds = 8;
  bool _dynamicColor = true;
  bool _privacyMode = false;
  int _eventLimit = 200;
  bool _notifyOnCrash = false;

  /// 发行版清单提供的默认源（官方构建回退 github / pypi）
  static String get manifestDownloadSource =>
      Distribution.instance.defaultDownloadSource ?? 'github';
  static String get manifestPypiSource =>
      Distribution.instance.defaultPypiSource ?? 'pypi';

  ThemeMode get themeMode => _themeMode;

  /// 界面语言；null 表示跟随系统
  Locale? get locale => _locale;

  /// GitHub 资产下载源（github / ghfast / ghproxy，移动端 rootfs 用）
  String get downloadSource => _downloadSource;

  /// PyPI 镜像源（pypi / tsinghua / aliyun / custom，桌面端 pip 用）
  String get pypiSource => _pypiSource;

  /// 窗口关闭行为（Windows 托盘）：ask 每次询问 / tray 最小化到托盘 /
  /// exit 停止全部实例并退出
  String get closeAction => _closeAction;

  int get refreshSeconds => _refreshSeconds;
  bool get dynamicColor => _dynamicColor;
  bool get privacyMode => _privacyMode;
  int get eventLimit => _eventLimit;
  bool get notifyOnCrash => _notifyOnCrash;

  /// 从本地存储加载
  Future<void> load() async {
    _downloadSource = manifestDownloadSource;
    _pypiSource = manifestPypiSource;
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_kThemeMode);
      _themeMode = switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      _locale = _localeFromCode(prefs.getString(_kLocale));
      _downloadSource =
          prefs.getString(_kDownloadSource) ?? manifestDownloadSource;
      _pypiSource = prefs.getString(_kPypiSource) ?? manifestPypiSource;
      final close = prefs.getString(_kCloseAction);
      _closeAction = switch (close) {
        'tray' || 'exit' => close!,
        _ => 'ask',
      };
      _refreshSeconds = prefs.getInt(_kRefreshSeconds) ?? _refreshSeconds;
      _dynamicColor = prefs.getBool(_kDynamicColor) ?? _dynamicColor;
      _privacyMode = prefs.getBool(_kPrivacyMode) ?? _privacyMode;
      _eventLimit = prefs.getInt(_kEventLimit) ?? _eventLimit;
      _notifyOnCrash = prefs.getBool(_kNotifyOnCrash) ?? _notifyOnCrash;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setRefreshSeconds(int v) => _set(
      _kRefreshSeconds, v, (x) => _refreshSeconds = x, () => _refreshSeconds,);
  Future<void> setDynamicColor(bool v) =>
      _set(_kDynamicColor, v, (x) => _dynamicColor = x, () => _dynamicColor);
  Future<void> setPrivacyMode(bool v) =>
      _set(_kPrivacyMode, v, (x) => _privacyMode = x, () => _privacyMode);
  Future<void> setEventLimit(int v) =>
      _set(_kEventLimit, v, (x) => _eventLimit = x, () => _eventLimit);
  Future<void> setNotifyOnCrash(bool v) =>
      _set(_kNotifyOnCrash, v, (x) => _notifyOnCrash = x, () => _notifyOnCrash);

  Future<void> _set<T>(
      String key, T value, void Function(T) assign, T Function() read,) async {
    if (read() == value) return;
    assign(value);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (_) {}
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

  /// 切换下载源（github 直连 / 国内加速镜像，用于移动端 rootfs 下载）
  Future<void> setDownloadSource(String source) async {
    if (_downloadSource == source) return;
    _downloadSource = source;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDownloadSource, source);
    } catch (_) {}
  }

  /// 切换 PyPI 镜像源（pypi 官方 / 清华 / 阿里，桌面端 pip 安装用）
  Future<void> setPypiSource(String source) async {
    if (_pypiSource == source) return;
    _pypiSource = source;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPypiSource, source);
    } catch (_) {}
  }

  /// 设置窗口关闭行为（ask / tray / exit，Windows 托盘关闭确认用）
  Future<void> setCloseAction(String action) async {
    if (_closeAction == action) return;
    _closeAction = action;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCloseAction, action);
    } catch (_) {}
  }
}
