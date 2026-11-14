// 统一动效常量与组件：入场、切换淡入、hover 上浮、按压缩放、路由转场。
// 全部尊重系统"减弱动效"设置。

import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration enter = Duration(milliseconds: 380);

  static const Curve curve = Curves.easeOutCubic;
}

/// 内容切换淡入：child 更新（key 变化）时旧内容淡出、新内容淡入上移。
class FadeThroughSwitcher extends StatelessWidget {
  const FadeThroughSwitcher({
    super.key,
    required this.childKey,
    required this.child,
  });

  /// 外部业务 key（如 tabIndex），变化时触发过渡
  final Object childKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.curve,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (widget, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(anim),
          child: widget,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(childKey), child: child),
    );
  }
}

/// 列表项入场：淡入上移，按 [index] 错开延迟。
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppMotion.enter,
  );
  late final Animation<double> _anim = CurvedAnimation(
    parent: _ctrl,
    curve: AppMotion.curve,
  );

  @override
  void initState() {
    super.initState();
    final delay = Duration(
      milliseconds: (widget.index.clamp(0, 8) * 45),
    );
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(_anim),
        child: widget.child,
      ),
    );
  }
}

/// 桌面 hover 上浮：容器阴影加深 + 轻微上移。
class HoverLift extends StatefulWidget {
  const HoverLift({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        child: widget.child,
      ),
    );
  }
}

/// 按压缩放反馈（0.98）。
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return GestureDetector(onTap: widget.onTap, child: widget.child);
    }
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}

/// 统一路由转场：淡入 + 轻微上移。
PageRouteBuilder<T> appRoute<T>({required WidgetBuilder builder}) {
  return PageRouteBuilder<T>(
    transitionDuration: AppMotion.normal,
    reverseTransitionDuration: AppMotion.fast,
    pageBuilder: (_, __, ___) => Builder(builder: builder),
    transitionsBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: AppMotion.curve);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
