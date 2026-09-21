// 实例监控视图（详情页"监控"注册视图）。
//
// 一个视图内含四个子 tab——性能（CPU/内存折线）、日志（软日志/进程日志）、
// 生命周期、审计。各子视图均自带 keep-alive，切换子 tab 保留各自状态。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import 'instance_audit_view.dart';
import 'instance_lifecycle_view.dart';
import 'instance_log_view.dart';
import 'instance_performance_view.dart';

/// 监控视图：性能 / 日志 / 生命周期 / 审计
class InstanceMonitorView extends StatelessWidget {
  final Instance instance;
  const InstanceMonitorView({super.key, required this.instance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.detailTabPerformance),
              Tab(text: l10n.detailTabLogs),
              Tab(text: l10n.detailTabLifecycle),
              Tab(text: l10n.detailTabAudit),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                InstancePerformanceView(instance: instance),
                InstanceLogView(instanceId: instance.id),
                InstanceLifecycleView(instance: instance),
                InstanceAuditView(instance: instance),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
