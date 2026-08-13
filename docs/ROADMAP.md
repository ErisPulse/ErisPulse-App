# 路线图

## Phase 1 — 原生 UI 骨架

> 里程碑：Android APK 可创建并管理本地 ErisPulse 实例

- 数据模型：`Instance` / `LogEntry` / `SystemInfo` / `AdapterInfo` / `ModuleInfo`
- `InstanceManager`：实例元数据 CRUD + 持久化（shared_preferences + flutter_secure_storage）
- `DashboardApi`：Dashboard REST 客户端（探活 / 系统 / 适配器 / 模块 / 日志 / 配置）
- 实例列表页（状态 / 启停 / 重命名 / 删除）
- 实例详情页：概览（CPU/内存图表）、日志（WebSocket 流式）、适配器、模块、配置
- Material 3 主题 + 跟随系统

## Phase 2 — Android 嵌入运行时

> 里程碑：双 APK（online / offline），手机即主机

### 2.1 rootfs 构建 CI

- `build-rootfs.yml`：Ubuntu arm64 + Python + ErisPulse 预烘焙，压缩为 tar.xz
- `scripts/build-rootfs.sh`：容器内烘焙（apt + pip 安装全家桶）
- `scripts/fetch-runtime-binaries.sh`：获取 proot / busybox aarch64 静态二进制

### 2.2 proot 集成

- `rootfs_provisioner.dart`：二进制与 rootfs 获取（assets 内置优先，Releases 下载兜底）+ busybox 解压
- `proot_manager.dart`：proot 拉起 `sdk.run()`，健康轮询，崩溃自动重启
- 实例 token 预写入 config.toml，Dashboard 无需首启自签

### 2.3 首启向导

- `SplashGate` 门控：rootfs 未就绪时进入 `OnboardingPage`
- 进度条 / 日志视图切换（点击屏幕）

### 2.4 后台保活

- `flutter_background_service`：后台 isolate 持有全部 proot 进程
- 常驻通知（Android 13+ 首启申请权限）
- 息屏 / 切后台保持运行（FGS + dataSync）

## Phase 3 — 桌面端内置运行时

- Win / Mac / Linux：构建内置 python-build-standalone（Python 3.15），
  每个实例独立 venv（`python -m venv`）+ `pip install ErisPulse`，以子进程运行（无需 proot）
- 复用现有原生 UI（运行时抽象为接口，桌面用内置 Python 实现）

## Phase 4 — 增强

- iOS 远程客户端（iOS 无法嵌入 Python，仅作为 Dashboard 客户端）
- 联邦视图（`/api/cluster/proxy` 多实例统一入口）
- 系统通知集成（实例离线 / 崩溃告警）
- 深链（`erispulse://instance/{id}`）
- 多语言（zh-CN / zh-TW / en / ja / ru）

## 说明

- SDK 侧配套改动（`runtime/platform.py` 移动端检测、`mobile-deploy.md` 文档等）已完成，见 [ErisPulse](https://github.com/ErisPulse/ErisPulse) 仓库的 CHANGELOG。
- 运行时镜像与 App 的耦合版本对应关系见 `lib/services/runtime/assets.dart` 的 `kRootfsVersion`。
