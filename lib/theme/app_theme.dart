// 全局应用主题（Material 3，统一圆角与柔和阴影，无渐变）。
//
// 集中定义跨页面复用的组件主题，避免在各处零散内联：
//   - 卡片 / 按钮 / FAB / Chip 统一加大圆角
//   - AppBar 一体化顶栏（标题字重、背景、表面色调）
//   - 柔和低透明度阴影
// 颜色由 main.dart 的 dynamic_color + 跟随系统决定，本文件只导出
// 与配色无关但需要统一的组件样式（浅/深共用）。

import 'package:flutter/material.dart';

/// 统一的圆角词表
abstract final class AppRadius {
  /// 通用控件（按钮 / chip 内边距项 / 列表首尾）
  static const double s = 12;

  /// 中等（卡片 / 弹层 / 输入框）
  static const double m = 16;

  /// 大（大卡片 / 底部弹层）
  static const double l = 20;

  /// 胶囊（FAB / 标签）
  static const double pill = 999;

  static BorderRadius get card => BorderRadius.circular(l);
  static BorderRadius get dialog => BorderRadius.circular(l);
  static BorderRadius get button => BorderRadius.circular(m);
  static BorderRadius get fab => BorderRadius.circular(pill);
  static BorderRadius get input => BorderRadius.circular(m);
  static BorderRadius get sheet => BorderRadius.circular(l);
  static BorderRadius get chip => BorderRadius.circular(s);
}

/// ErisPulse 品牌色（对齐 Dashboard base.css 的 --accent：
/// 亮色 #4aa3dd / 暗色 #6a9df0）。
///
/// 仅作为 dynamic_color 取色失败时的回退 seed；
/// Android 12+ 仍优先跟随系统 Material You 动态取色。
abstract final class AppBrand {
  /// 浅色主题回退 seed
  static const Color seedLight = Color(0xFF4AA3DD);

  /// 深色主题回退 seed
  static const Color seedDark = Color(0xFF6A9DF0);
}

/// 应用主题构建器
class AppTheme {
  AppTheme._();

  /// 浅色主题（colorScheme 由调用方传入，如 dynamic_color 生成的结果）
  static ThemeData light(ColorScheme scheme) =>
      _build(scheme, Brightness.light);

  /// 深色主题（colorScheme 由调用方传入，如 dynamic_color 生成的结果）
  static ThemeData dark(ColorScheme scheme) => _build(scheme, Brightness.dark);

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    // 全局黑体（无衬线）：Android 下 Flutter 默认 Roboto 不含中文字形，
    // 中文会回落系统黑体。这里显式声明一摞黑体族名，确保各平台都走
    // 无衬线黑体（微软雅黑 / 苹方 / Noto Sans CJK），避免衬线（宋体）混入。
    const String kFontFamily = 'sans-serif';
    const List<String> kFontFallback = [
      'Microsoft YaHei',
      'PingFang SC',
      'Noto Sans CJK SC',
      'Noto Sans SC',
      'Roboto',
    ];
    final base = Typography.material2021().black;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: kFontFamily,
      fontFamilyFallback: kFontFallback,
      textTheme: base.apply(
        fontFamily: kFontFamily,
        fontFamilyFallback: kFontFallback,
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      // 统一圆角：卡片 / 按钮 / FAB / Chip
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fab),
        elevation: 2,
        highlightElevation: 3,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chip),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        titleTextStyle: TextStyle(
          fontFamily: kFontFamily,
          fontFamilyFallback: kFontFallback,
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialog),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
    );
  }
}
