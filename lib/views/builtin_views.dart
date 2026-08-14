// 详情页内置视图注册。
//
// 应用启动时调用 [registerBuiltinViews] 把内置管理视图注册进
// [DetailViewRegistry]。概览视图固定为详情页第一个视图，不在此注册。
// 后续新增原生页面只需在此追加一项，导航自动生成。

import 'package:flutter/material.dart';

import '../pages/detail_management_tabs.dart';
import '../pages/files_tab.dart';
import 'instance_audit_view.dart';
import 'instance_events_view.dart';
import 'instance_log_view.dart';
import 'instance_view.dart';

/// 注册全部内置视图
void registerBuiltinViews(DetailViewRegistry registry) {
  registry
    ..register(
      InstanceView(
        id: 'modules',
        icon: Icons.extension_outlined,
        title: (l) => l.detailTabModules,
        builder: (_, inst) => ModulesTab(instance: inst),
      ),
    )
    ..register(
      InstanceView(
        id: 'adapters',
        icon: Icons.devices_outlined,
        title: (l) => l.detailTabAdapters,
        builder: (_, inst) => AdaptersTab(instance: inst),
      ),
    )
    ..register(
      InstanceView(
        id: 'config',
        icon: Icons.tune_outlined,
        title: (l) => l.detailTabConfig,
        builder: (_, inst) => ConfigTab(instance: inst),
      ),
    )
    ..register(
      InstanceView(
        id: 'files',
        icon: Icons.folder_outlined,
        title: (l) => l.detailTabFiles,
        builder: (_, inst) => FilesTab(instance: inst),
      ),
    )
    ..register(
      InstanceView(
        id: 'logs',
        icon: Icons.terminal_outlined,
        title: (l) => l.detailTabLogs,
        builder: (_, inst) => InstanceLogView(instanceId: inst.id),
      ),
    )
    ..register(
      InstanceView(
        id: 'packages',
        icon: Icons.inventory_2_outlined,
        title: (l) => l.detailTabPackages,
        builder: (_, inst) => PackagesTab(instance: inst),
      ),
    )
    ..register(
      InstanceView(
        id: 'events',
        icon: Icons.event_note_outlined,
        title: (l) => l.detailTabEvents,
        builder: (_, inst) => InstanceEventsView(instance: inst),
      ),
    )
    ..register(
      InstanceView(
        id: 'audit',
        icon: Icons.fact_check_outlined,
        title: (l) => l.detailTabAudit,
        builder: (_, inst) => InstanceAuditView(instance: inst),
      ),
    );
}
