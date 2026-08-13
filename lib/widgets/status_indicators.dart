import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/enums.dart';

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
    final (color, tooltip) = h != null
        ? switch (h) {
            InstanceHealth.healthy => (Colors.green, l10n.statusOnline),
            InstanceHealth.booting => (Colors.blue, l10n.statusConnecting),
            InstanceHealth.unauthorized => (
                Colors.orange,
                l10n.statusTokenInvalid,
              ),
            InstanceHealth.unreachable => (Colors.red, l10n.statusOffline),
            InstanceHealth.unknown => (Colors.grey, l10n.statusUnknown),
          }
        : switch (status) {
            InstanceStatus.running => (Colors.green, l10n.statusRunning),
            InstanceStatus.starting => (Colors.blue, l10n.statusStarting),
            InstanceStatus.error => (Colors.red, l10n.statusError),
            InstanceStatus.destroying => (Colors.orange, l10n.statusDestroying),
            InstanceStatus.stopped => (Colors.grey, l10n.statusStopped),
          };
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
    final (label, color) = switch (health) {
      InstanceHealth.healthy => (l10n.statusHealthy, Colors.green),
      InstanceHealth.booting => (l10n.statusConnecting, Colors.blue),
      InstanceHealth.unauthorized => (l10n.statusTokenInvalid, Colors.orange),
      InstanceHealth.unreachable => (l10n.statusOffline, Colors.red),
      InstanceHealth.unknown => (l10n.statusRemoteUnknown, Colors.grey),
    };
    return Chip(
      label: Text(label),
      avatar: Icon(Icons.circle, color: color, size: 10),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
