import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/enums.dart';

/// 实例状态 / 健康度 → 语义色（全项目唯一来源）。
///
/// 配色对齐 Dashboard base.css 的语义芯片（--ok / --pr / --wr / --er），
/// 明暗主题分别取对应色值；未知/停止用中性灰。
Color instanceStateColor(
  BuildContext context, {
  InstanceStatus? status,
  InstanceHealth? health,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final (ok, pr, wr, er) = dark
      ? (
          const Color(0xFF6FD6A1),
          const Color(0xFF7FA8F0),
          const Color(0xFFF5B95D),
          const Color(0xFFFF8B95),
        )
      : (
          const Color(0xFF178A52),
          const Color(0xFF2E88C4),
          const Color(0xFFC77F16),
          const Color(0xFFD9404E),
        );
  final neutral = dark ? const Color(0xFF5F6875) : const Color(0xFF9AA4B1);

  final h = health;
  if (h != null) {
    return switch (h) {
      InstanceHealth.healthy => ok,
      InstanceHealth.booting => pr,
      InstanceHealth.unauthorized => wr,
      InstanceHealth.unreachable => er,
      InstanceHealth.unknown => neutral,
    };
  }
  return switch (status!) {
    InstanceStatus.running => ok,
    InstanceStatus.starting => pr,
    InstanceStatus.error => er,
    InstanceStatus.destroying => wr,
    InstanceStatus.stopped => neutral,
  };
}

/// 实例状态指示点。
///
/// 远程实例没有本地进程，[status] 固定为 stopped，此时传入 [health]
/// 以健康度决定颜色与提示（在线/连接中/离线等）。
class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    required this.status,
    this.health,
    this.size = 10,
  });

  final InstanceStatus status;
  final InstanceHealth? health;
  final double size;

  @override
  Widget build(BuildContext context) {
    final h = health;
    final l10n = AppLocalizations.of(context);
    final tooltip = h != null
        ? switch (h) {
            InstanceHealth.healthy => l10n.statusOnline,
            InstanceHealth.booting => l10n.statusConnecting,
            InstanceHealth.unauthorized => l10n.statusTokenInvalid,
            InstanceHealth.unreachable => l10n.statusOffline,
            InstanceHealth.unknown => l10n.statusUnknown,
          }
        : switch (status) {
            InstanceStatus.running => l10n.statusRunning,
            InstanceStatus.starting => l10n.statusStarting,
            InstanceStatus.error => l10n.statusError,
            InstanceStatus.destroying => l10n.statusDestroying,
            InstanceStatus.stopped => l10n.statusStopped,
          };
    final color = instanceStateColor(
      context,
      status: status,
      health: health,
    );
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: size * 0.6,
            ),
          ],
        ),
      ),
    );
  }
}

/// 健康度徽章
class HealthBadge extends StatelessWidget {
  const HealthBadge({super.key, required this.health});
  final InstanceHealth health;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (health) {
      InstanceHealth.healthy => l10n.statusHealthy,
      InstanceHealth.booting => l10n.statusConnecting,
      InstanceHealth.unauthorized => l10n.statusTokenInvalid,
      InstanceHealth.unreachable => l10n.statusOffline,
      InstanceHealth.unknown => l10n.statusRemoteUnknown,
    };
    return Chip(
      label: Text(label),
      avatar: Icon(
        Icons.circle,
        color: instanceStateColor(context, health: health),
        size: 10,
      ),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
