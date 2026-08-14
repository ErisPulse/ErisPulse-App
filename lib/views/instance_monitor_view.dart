// 实例监控视图（详情页"监控"注册视图）。
//
// 对齐 Dashboard 前端 monitor 页的颗粒度：一个视图内含三个子 tab——
// 日志（软日志/进程日志）、生命周期、审计。三个子视图均自带 keep-alive，
// 切换子 tab 保留各自状态。

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import 'instance_audit_view.dart';
import 'instance_lifecycle_view.dart';
import 'instance_log_view.dart';

/// 监控视图：日志 / 生命周期 / 审计三合一
class InstanceMonitorView extends StatelessWidget {
  final Instance instance;
  const InstanceMonitorView({super.key, required this.instance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.detailTabLogs),
              Tab(text: l10n.detailTabLifecycle),
              Tab(text: l10n.detailTabAudit),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
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
