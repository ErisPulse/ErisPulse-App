// 桌面右键上下文菜单。
//
// 桌面端（Windows/Linux/macOS）鼠标右键无系统默认菜单，这里提供统一的
// 右键弹出菜单：[showContextMenu] 在全局坐标处弹出，[ContextMenuRegion]
// 包装可交互项以响应右键（并可选提供移动端长按入口）。

import 'package:flutter/material.dart';

/// 桌面右键上下文菜单项
class ContextMenuItem {
  const ContextMenuItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;

  /// 危险操作（删除等），图标与文字用错误色
  final bool destructive;
}

/// 在给定全局坐标处弹出桌面上下文菜单。
Future<void> showContextMenu({
  required BuildContext context,
  required Offset anchor,
  required List<ContextMenuItem> items,
}) {
  final theme = Theme.of(context);
  return showMenu<void>(
    context: context,
    position: RelativeRect.fromLTRB(
      anchor.dx,
      anchor.dy,
      anchor.dx,
      anchor.dy,
    ),
    items: [
      for (final item in items)
        if (item.enabled)
          PopupMenuItem<void>(
            height: 44,
            onTap: item.onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: 18,
                    color: item.destructive ? theme.colorScheme.error : null,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  item.label,
                  style: item.destructive
                      ? TextStyle(color: theme.colorScheme.error)
                      : null,
                ),
              ],
            ),
          ),
    ],
  );
}

/// 桌面鼠标右键包装：包裹可交互项，右键弹出上下文菜单。
///
/// 鼠标右键（secondaryTap）与左键点击 / 长按互不干扰；
/// 移动端无鼠标，可额外提供 [onLongPress] 作为长按入口。
class ContextMenuRegion extends StatelessWidget {
  const ContextMenuRegion({
    super.key,
    required this.onContextMenu,
    required this.child,
    this.onLongPress,
  });

  /// 右键触发（anchor 为全局坐标）
  final ValueChanged<Offset> onContextMenu;
  final Widget child;

  /// 移动端长按回调（可选）
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (d) => onContextMenu(d.globalPosition),
        onLongPress: onLongPress,
        child: child,
      ),
    );
  }
}
