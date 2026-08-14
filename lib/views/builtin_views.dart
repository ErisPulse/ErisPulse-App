// 详情页内置视图注册。
//
// 应用启动时调用 [registerBuiltinViews] 把内置管理视图注册进
// [DetailViewRegistry]。概览视图固定为详情页第一个视图，不在此注册。
//
// 注册顺序与分组对齐 Dashboard 侧边栏颗粒度：
//   概览（机器人）/ 事件（事件流、命令）/ 扩展（模块、商店）/
//   管理（适配器、配置）/ 运维（监控、文件）
// 移动端顶部 TabBar 使用同一顺序；桌面端左侧导航按 group 渲染分组标题。
// 后续新增原生页面只需在此追加一项，导航自动生成。

import 'package:flutter/material.dart';

import '../pages/detail_management_tabs.dart';
import '../pages/files_tab.dart';
import 'instance_bots_view.dart';
import 'instance_commands_view.dart';
import 'instance_events_view.dart';
import 'instance_monitor_view.dart';
import 'instance_store_view.dart';
import 'instance_view.dart';

/// 注册全部内置视图（分组与顺序对齐 Dashboard 侧边栏）
void registerBuiltinViews(DetailViewRegistry registry) {
  registry
    // ── 概览 ──
    ..register(
      InstanceView(
        id: 'bots',
        group: (l) => l.navGroupOverview,
        icon: Icons.smart_toy_outlined,
        title: (l) => l.detailTabBots,
        builder: (_, inst) => InstanceBotsView(instance: inst),
      ),
    )
    // ── 事件 ──
    ..register(
      InstanceView(
        id: 'events',
        group: (l) => l.navGroupEvents,
        icon: Icons.event_note_outlined,
        title: (l) => l.detailTabEvents,
        builder: (_, inst) => InstanceEventsView(instance: inst),
      ),
    )
    ..register(
      InstanceView(
        id: 'commands',
        icon: Icons.terminal_outlined,
        title: (l) => l.detailTabCommands,
        builder: (_, inst) => InstanceCommandsView(instance: inst),
      ),
    )
    // ── 扩展 ──
    ..register(
      InstanceView(
        id: 'modules',
        group: (l) => l.navGroupExtensions,
        icon: Icons.extension_outlined,
        title: (l) => l.detailTabModules,
        builder: (_, inst) => ModulesTab(instance: inst),
      ),
    )
    ..register(
      InstanceView(
        id: 'store',
        icon: Icons.storefront_outlined,
        title: (l) => l.detailTabStore,
        builder: (_, inst) => InstanceStoreView(instance: inst),
      ),
    )
    // ── 管理 ──
    ..register(
      InstanceView(
        id: 'adapters',
        group: (l) => l.navGroupManagement,
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
    // ── 运维 ──
    ..register(
      InstanceView(
        id: 'monitor',
        group: (l) => l.navGroupOperations,
        icon: Icons.monitor_heart_outlined,
        title: (l) => l.detailTabMonitor,
        builder: (_, inst) => InstanceMonitorView(instance: inst),
      ),
    )
    ..register(
      InstanceView(
        id: 'files',
        icon: Icons.folder_outlined,
        title: (l) => l.detailTabFiles,
        builder: (_, inst) => FilesTab(instance: inst),
      ),
    );
}
