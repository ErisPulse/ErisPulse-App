[English](README.md) | **简体中文** | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [Русский](README.ru.md)

<div align="center">

<img src="https://raw.githubusercontent.com/ErisPulse/ErisPulse/main/.github/assets/ErisPulseLogo.png" width="180" alt="ErisPulse-App" />

# ErisPulse-App

**在 Android、Windows、Linux、macOS 上运行 ErisPulse。多实例、原生界面、后台常驻。**

[ErisPulse](https://github.com/ErisPulse/ErisPulse)（事件驱动的多平台机器人框架）的官方多平台客户端。使用纯原生界面创建、运行、管理机器人实例，无需电脑、无需终端、无需配置步骤。

<p>
  <a href="https://github.com/ErisPulse/ErisPulse-App/releases"><img src="https://img.shields.io/github/v/release/ErisPulse/ErisPulse-App?style=for-the-badge&logo=github&color=brightgreen" alt="Release"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://github.com/ErisPulse/ErisPulse"><img src="https://img.shields.io/badge/Powered_by-ErisPulse-FF6B9D?style=for-the-badge&logo=bookstack&logoColor=white" alt="ErisPulse"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/discussions"><img src="https://img.shields.io/badge/Discussions-181717?style=for-the-badge&logo=github" alt="Discussions"></a>
</p>

</div>

---

## 核心特性

<table>
<tr>
<td width="33%" align="center" valign="top">

### 多平台

Android、Windows、Linux、macOS 全平台安装包均已在 [Releases](https://github.com/ErisPulse/ErisPulse-App/releases) 发布。所有平台共享同一套 Flutter 代码库。

</td>
<td width="33%" align="center" valign="top">

### 多实例

每个实例都是独立的机器人，拥有自己的端口、工作目录与 token——按需创建、启动、停止、删除。

</td>
<td width="33%" align="center" valign="top">

### 原生界面

基于 Dashboard REST/WebSocket API 构建的纯原生界面——实时监控、流式日志、适配器与模块管理。

</td>
</tr>
<tr>
<td width="33%" align="center" valign="top">

### 后台常驻

Android 上前台服务让每个实例在后台持续运行，崩溃自动检测并重启；桌面端实例作为受 App 管理的直接进程运行。

</td>
<td width="33%" align="center" valign="top">

### 内置运行时

Android 上 proot、busybox 与含 Python + ErisPulse 的 Ubuntu 镜像内置（offline 版）或首启下载（online 版）。桌面端捆绑便携 Python，ErisPulse SDK 从 PyPI 安装，版本可选、默认最新。

</td>
<td width="33%" align="center" valign="top">

### 下载镜像

GitHub Releases 在部分网络环境缓慢或不可达——在设置页一键切换下载源为国内镜像（ghfast / gh-proxy）。

</td>
</tr>
</table>

---

## 工作原理

### Android

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

### 桌面端（Windows / Linux / macOS）

```
┌────────────────────────────────────────────────────┐
│  ErisPulse-App (Flutter)                            │
│                                                    │
│  原生 UI ── Dashboard REST / WS API                 │
│       │                                            │
│       ▼                                            │
│  捆绑 Python ── ErisPulse 实例（进程）              │
└────────────────────────────────────────────────────┘
```

- App 捆绑便携 Python。首次启动时选择要安装的 ErisPulse SDK 版本（默认最新）。
- 实例作为 App 的子进程运行，App 退出即停止。

内部设计见 [架构文档](docs/ARCHITECTURE.md)。

---

## 快速开始

### Android

[Releases](https://github.com/ErisPulse/ErisPulse-App/releases) 发布两种构建：

| 构建 | 运行时镜像 |
|------|-----------|
| `erispulse-app-online-*.apk` | 首次启动时下载 |
| `erispulse-app-offline-*.apk` | 内置在 APK 中 |

两种安装方式相同：

1. 安装并启动。允许通知权限——它保证后台服务存活。
2. 主页在运行时就绪前显示横幅，点击进入首启初始化（含进度与日志视图）。
3. 创建一个实例并启动。
4. 在应用内配置适配器与大模型 API Key。

> offline 版完全自包含，安装后无需联网。若首次启动下载缓慢或不稳定，可在设置页将**下载源**切换为镜像。

### 桌面端

> 从 [Releases](https://github.com/ErisPulse/ErisPulse-App/releases) 按平台选择下载：Windows `setup.exe`（或免安装 `zip`）、Linux `tar.gz`、macOS `zip`。

1. 安装并启动。
2. 在欢迎页选择要安装的 ErisPulse SDK 版本（默认选中最新）并安装。
3. 创建一个实例并启动。

---

## 开发者指南

### 环境要求

- Flutter ≥ 3.22（stable channel）
- Android SDK（API 36+，构建 Android 时）

### 构建

```bash
flutter pub get

# Android
# online：运行时首次启动下载
flutter build apk --release --dart-define=FLAVOR=online
# offline：rootfs 内置进 APK（需要 assets/rootfs 存在）
flutter build apk --release --dart-define=FLAVOR=offline

# Desktop
flutter build windows
flutter build linux
```

Android 的 rootfs 由独立 workflow（`.github/workflows/build-rootfs.yml`）构建，把 Ubuntu arm64 + Python + ErisPulse 烘焙进去，再由 Android 构建嵌入。详见 `scripts/`。

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
│   └── runtime/                 proot / rootfs / 前台服务（Android）
│                               桌面运行时 / SDK 管理器（Windows/Linux）
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

Android 容器方案基于用户态 chroot（proot）与静态 busybox，沿用 [Termux](https://github.com/termux/termux-app) 生态的成熟实践。产品形态与移动端部署思路参考 [AstrBot-Android-App](https://github.com/zz6zz666/AstrBot-Android-App)。
