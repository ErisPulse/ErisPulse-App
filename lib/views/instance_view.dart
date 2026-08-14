// 实例详情页视图注册机制。
//
// 详情页的"管理型"视图（模块 / 适配器 / 配置 / 文件 / 日志 / 包…）统一由
// 注册表驱动：PC 宽屏左侧导航与移动端 TabBar 都由同一份视图列表生成。
//
// 未来 SDK 模块可通过 [DetailViewRegistry.register] 动态注册自定义视图
// （对齐 Dashboard 后端 register_view / `/api/views` 机制），注册后详情页
// 导航自动刷新，无需改动详情页布局代码。
library;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';

/// 视图构建器：给定实例返回该视图的内容。
typedef InstanceViewBuilder = Widget Function(
  BuildContext context,
  Instance instance,
);

/// 详情页视图描述。
class InstanceView {
  /// 唯一标识（与后端注册 view 的 id 对齐时保持稳定）
  final String id;

  /// 导航图标
  final IconData icon;

  /// 标题（按当前语言解析，支持多语言）
  final String Function(AppLocalizations l10n) title;

  /// 视图内容构建器
  final InstanceViewBuilder builder;

  /// 导航分组标题（对齐 Dashboard 侧边栏分组颗粒度）。
  ///
  /// 仅在该视图开启一个新分组时提供（连续同组的后续视图留空），
  /// 桌面端左侧导航会渲染小节标题；为 null 时沿用上一个分组。
  final String Function(AppLocalizations l10n)? group;

  const InstanceView({
    required this.id,
    required this.icon,
    required this.title,
    required this.builder,
    this.group,
  });
}

/// 详情页视图注册表（全局单例，由 Provider 注入）。
///
/// - 内置视图在应用启动时注册（见 builtin_views.dart）
/// - 动态视图运行时通过 [register] / [unregister] 增删，详情页自动刷新
class DetailViewRegistry extends ChangeNotifier {
  final List<InstanceView> _views = [];

  /// 已注册视图（按注册顺序）
  List<InstanceView> get views => List.unmodifiable(_views);

  /// 按 id 查找
  InstanceView? find(String id) {
    for (final v in _views) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// 注册视图（同 id 覆盖，保持原位置）
  void register(InstanceView view) {
    final idx = _views.indexWhere((v) => v.id == view.id);
    if (idx >= 0) {
      _views[idx] = view;
    } else {
      _views.add(view);
    }
    notifyListeners();
  }

  /// 注销视图
  void unregister(String id) {
    final idx = _views.indexWhere((v) => v.id == id);
    if (idx >= 0) {
      _views.removeAt(idx);
      notifyListeners();
    }
  }

  /// 当前在导航中的索引（未注册返回 -1）
  int indexOf(String id) => _views.indexWhere((v) => v.id == id);
}
