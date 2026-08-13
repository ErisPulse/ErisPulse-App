[English](README.md) | [简体中文](README.zh-CN.md)

# ErisPulse-App

**在手机上运行 ErisPulse。多实例、原生界面、后台常驻。**

一个内嵌 [ErisPulse](https://github.com/ErisPulse/ErisPulse)（事件驱动的多平台机器人框架）的 Android 客户端，让你直接在手机上创建、运行、管理机器人实例，无需电脑、无需命令行。

<p>
  <a href="https://github.com/ErisPulse/ErisPulse-App/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/releases"><img src="https://img.shields.io/github/v/release/ErisPulse/ErisPulse-App?style=for-the-badge" alt="Release"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/discussions"><img src="https://img.shields.io/badge/Discussions-181717?style=for-the-badge&logo=github" alt="Discussions"></a>
</p>

---

<div align="center">

### 核心特性

</div>

<table>
<tr>
<td width="33%" align="center" valign="top">

### 内嵌运行时

完整的 ErisPulse 运行环境——proot、busybox 与预烘焙的 Ubuntu（含 Python 与 ErisPulse）随 App 提供。安装即用，无需任何配置步骤。

</td>
<td width="33%" align="center" valign="top">

### 多实例

每个实例都是独立的机器人，拥有自己的端口、工作目录与 token，全部在一个 App 里管理。按需创建、启动、停止、删除。

</td>
<td width="33%" align="center" valign="top">

### 原生界面

基于 Dashboard REST/WebSocket API 构建的纯原生界面，不依赖 WebView。实时系统监控、流式日志、适配器与模块管理。

</td>
</tr>
<tr>
<td width="33%" align="center" valign="top">

### 后台常驻

前台服务让每个实例在后台持续运行。息屏、切后台都不中断，崩溃自动检测并重启。

</td>
<td width="33%" align="center" valign="top">

### 零配置

首次启动解压内置运行时，带进度视图引导。不需要 shell、不需要包管理器、不需要终端。

</td>
<td width="33%" align="center" valign="top">

### 跨端代码库

单一 Flutter 代码库，当前发布 Android，Windows / macOS / Linux / iOS 跟进中。

</td>
</tr>
</table>

---

## 工作原理

```
┌────────────────────────────────────────────────────┐
│  ErisPulse-App (Flutter)                            │
│                                                    │
│  原生 UI ── Dashboard REST / WS API                 │
│       │                                            │
│       └── Foreground Service（后台 isolate）        │
│                │                                   │
│                ▼                                   │
│  proot（用户态 chroot）                             │
│       │                                            │
│       ▼                                            │
│  Ubuntu rootfs + Python + ErisPulse 实例            │
└────────────────────────────────────────────────────┘
```

- **前台服务**持有所有实例进程，关闭界面后机器人仍在运行。
- UI 通过 `127.0.0.1:<port>/Dashboard/*` 与每个实例通信——与 Web Dashboard 使用相同的 REST 与 WebSocket API。
- 每个实例在共享 rootfs 下自己的工作目录中运行 SDK，拥有独立的端口与 token。

内部设计见 [架构文档](docs/ARCHITECTURE.md)。

---

## 快速开始

[Releases](https://github.com/ErisPulse/ErisPulse-App/releases) 发布两种构建：

| 构建 | 运行时镜像 |
|------|-----------|
| `erispulse-app-online-*.apk` | 首次启动时下载 |
| `erispulse-app-offline-*.apk` | 内置在 APK 中 |

两种安装方式相同：

1. 安装并启动。允许通知权限——它保证后台服务存活。
2. 首次启动准备运行环境（含进度与日志视图）。
3. 创建一个实例并启动。
4. 在应用内配置适配器与大模型 API Key。

> offline 版完全自包含，安装后无需联网。若首次启动下载可能缓慢或不稳定，请选择它。

---

## 开发者指南

### 环境要求

- Flutter ≥ 3.22（stable channel）
- Android SDK（API 36+）

### 构建

```bash
flutter pub get

# 拉取 proot / busybox 到 assets/runtime（CI 自动执行）
bash scripts/fetch-runtime-binaries.sh

# 从最新的 build-rootfs release 拉取预烘焙 rootfs 到 assets/rootfs（CI 自动执行）

# online：运行时首次启动下载
flutter build apk --release --dart-define=FLAVOR=online

# offline：rootfs 内置进 APK（需要 assets/rootfs 存在）
flutter build apk --release --dart-define=FLAVOR=offline
```

rootfs 由独立 workflow（`.github/workflows/build-rootfs.yml`）构建，把 Ubuntu arm64 + Python + ErisPulse 烘焙进 `tar.xz`，再由 Android 构建嵌入。详见 `scripts/`。

### 代码结构

```
lib/
├── main.dart                    入口 + Provider 装配
├── models/                      实例 / 日志 / 系统 / 适配器 DTO
├── pages/                       原生界面
│   ├── home_page.dart           实例列表
│   ├── instance_detail_page.dart 概览 / 日志 / 适配器 / 模块 / 配置
│   ├── onboarding_page.dart     首启运行时供给
│   └── ...
├── services/
│   ├── instance_manager.dart    实例元数据 CRUD + 持久化
│   ├── dashboard_api.dart       Dashboard REST 客户端
│   └── runtime/                 proot / rootfs / 前台服务
└── widgets/
```

---

## 相关项目

| 项目 | 说明 |
|------|------|
| [ErisPulse](https://github.com/ErisPulse/ErisPulse) | 本 App 内嵌的异步多平台机器人框架 |
| [ErisPulse-Dashboard](https://github.com/ErisPulse/ErisPulse-Dashboard) | Web 管理面板；本 App 原生界面所基于的 API |

---

## 许可证

[MIT](LICENSE)

---

## 致谢

- [AstrBot-Android-App](https://github.com/zz6zz666/AstrBot-Android-App) 提供了产品形态与移动端部署思路。
- Android 容器方案基于用户态 chroot（proot）与静态 busybox，沿用 Termux 生态的成熟实践。
