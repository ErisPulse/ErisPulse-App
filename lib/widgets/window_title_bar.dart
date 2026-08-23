// 无边框窗口自绘顶栏（桌面）。
//
// 统一用于所有页面：承载标题 / 左侧返回等导航 / 右侧功能按钮，以及窗口
// 控制（最小化 / 最大化 / 关闭）。空白区按住拖动窗口、双击最大化 / 还原。
// 窗口能力统一走 [WindowService]（window_manager），跨平台一致。

import 'package:flutter/material.dart';

import '../services/window/window_service.dart';

/// 无边框窗口顶栏
class WindowTitleBar extends StatefulWidget {
  const WindowTitleBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
  });

  final String title;
  final Widget? leading;

  /// 顶栏右侧的功能按钮（刷新 / 设置 / 调试等）
  final List<Widget> actions;

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> {
  final _service = WindowService.instance;

  @override
  void initState() {
    super.initState();
    _service.isMaximized.addListener(_onMaxChanged);
  }

  @override
  void dispose() {
    _service.isMaximized.removeListener(_onMaxChanged);
    super.dispose();
  }

  void _onMaxChanged() {
    if (mounted) setState(() {});
  }

  void _toggleMaximize() {
    _service.toggleMaximize();
  }

  void _close() {
    // 触发原生关闭流程 → WindowService.onWindowClose 关闭确认
    _service.close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (widget.leading != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: widget.leading!,
            ),
          ],
          // 拖拽区：按住移动窗口（WindowService.startDragging），双击最大化/还原
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: _toggleMaximize,
              onPanStart: (_) => _service.startDragging(),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          ...widget.actions,
          const SizedBox(width: 4),
          _WindowControlButton(
            icon: Icons.minimize,
            onTap: () => _service.minimize(),
          ),
          _WindowControlButton(
            icon: _service.isMaximized.value
                ? Icons.filter_none
                : Icons.crop_square,
            onTap: _toggleMaximize,
          ),
          _WindowControlButton(
            icon: Icons.close,
            hoverColor: scheme.error,
            activeColor: scheme.onError,
            onTap: _close,
          ),
        ],
      ),
    );
  }
}

/// 顶栏窗口控制按钮（最小化 / 最大化 / 关闭）
class _WindowControlButton extends StatefulWidget {
  const _WindowControlButton({
    required this.icon,
    required this.onTap,
    this.hoverColor,
    this.activeColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;
  final Color? activeColor;

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.hoverColor;
    final effectiveBg = _hover ? (bg ?? scheme.surfaceContainerHigh) : null;
    final fg = effectiveBg != null && bg != null
        ? (widget.activeColor ?? scheme.onError)
        : scheme.onSurfaceVariant;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 48,
          color: effectiveBg ?? Colors.transparent,
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 18, color: fg),
        ),
      ),
    );
  }
}
