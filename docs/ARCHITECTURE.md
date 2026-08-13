# 架构概览

## 总体架构

```
┌──────────────────────────────────────────────────────────┐
│  ErisPulse-App（Flutter）                                 │
│                                                          │
│  原生 UI（lib/pages/）                                    │
│    实例列表 / 实例详情（概览·日志·适配器·模块·配置）        │
│           ↓                                              │
│  服务层（lib/services/）                                  │
│    InstanceManager —— 实例元数据 CRUD + 持久化            │
│    DashboardApi    —— Dashboard REST 客户端              │
│    LogStream       —— 日志 WebSocket 流                  │
│    RuntimeController —— 与后台服务通信（Provider）        │
│           ↓                                              │
│  Foreground Service isolate（后台保活）                   │
│    RootfsProvisioner —— 二进制/rootfs 解压供给            │
│    ProotManager      —— proot 子进程管理                 │
│           ↓                                              │
│  proot（用户态 chroot）                                  │
│           ↓                                              │
│  Ubuntu rootfs + Python + ErisPulse 实例                 │
└──────────────────────────────────────────────────────────┘
```

每个实例是 rootfs 内一个独立工作目录 + 独立端口 + 独立 token 的 ErisPulse 进程。
UI 通过 `http://127.0.0.1:<port>/Dashboard/api/*` 与实例通信。

## 数据流

1. **启停**：UI 调 `RuntimeController.startInstance()` → invoke 后台 isolate → `ProotManager` 用 proot 拉起 `python -c "sdk.run()"` → 健康轮询就绪 → 状态回写 `InstanceManager`。
2. **监控**：UI 每 2s 轮询 `DashboardApi.getSystemInfo()`（CPU / 内存 / 运行时长）。
3. **日志**：`LogStream` 连 `ws://127.0.0.1:<port>/Dashboard/ws`，实时推送并缓冲。
4. **管理**：适配器 / 模块 / 配置页直接调 Dashboard REST 端点，全原生渲染。

## 后台保活

- `flutter_background_service` 的后台 isolate 持有所有 proot 进程，UI 关闭后实例继续运行。
- Android Foreground Service（`dataSync`）+ 常驻通知，息屏 / 切后台不被回收。
- `ProotManager` 监听进程退出，崩溃后自动重启（可关闭）。

## 运行时供给

proot / busybox / rootfs 三者内置进 APK assets（CI 打包时注入）：

- **offline flavor**：rootfs 也内置，首启离线解压。
- **online flavor**：仅内置 proot / busybox，rootfs 首启从 GitHub Releases 下载。

运行时通过 `RootfsProvisioner` 按「私有目录 → assets → Releases」顺序获取。

## 代码结构

```
lib/
├── main.dart                    入口 + Provider 注册 + 启动闸门
├── models/
│   ├── instance.dart           实例数据模型（端口 / 工作目录 / token）
│   ├── enums.dart              实例状态 / 健康度
│   ├── log_entry.dart          日志 DTO
│   ├── system_info.dart        系统监控 DTO
│   ├── adapter_info.dart       适配器 / bot DTO
│   └── module_info.dart        模块 DTO
├── pages/
│   ├── home_page.dart          实例列表
│   ├── instance_create_page.dart  创建向导
│   ├── instance_detail_page.dart  详情 Tab 容器
│   ├── overview_page.dart      系统监控（fl_chart 图表）
│   ├── logs_page.dart          流式日志
│   ├── adapters_page.dart      适配器管理
│   ├── modules_page.dart       模块管理
│   ├── config_page.dart        TOML 配置视图
│   ├── onboarding_page.dart    首启运行时供给向导
│   └── settings_page.dart      设置
├── services/
│   ├── instance_manager.dart   实例 CRUD + 持久化 + 端口分配
│   ├── dashboard_api.dart      Dashboard REST 客户端
│   ├── log_stream.dart         WebSocket 日志流
│   └── runtime/
│       ├── assets.dart         资产路径 / 发布常量
│       ├── rootfs_provisioner.dart  二进制与 rootfs 供给
│       ├── proot_manager.dart  proot 子进程管理
│       ├── background_service.dart  FGS 后台 isolate 入口
│       └── runtime_controller.dart  UI 侧通信桥
└── widgets/
    ├── status_indicators.dart  状态点 / 健康徽章
    └── states.dart             空状态 / 错误 / 加载视图
```

## 相关文档

- [路线图](ROADMAP.md)
- [ErisPulse](https://github.com/ErisPulse/ErisPulse) —— 框架本体
- [ErisPulse-Dashboard](https://github.com/ErisPulse/ErisPulse-Dashboard) —— 本 App 原生 UI 所基于的 REST/WS API
