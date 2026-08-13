[English](README.md) | [简体中文](README.zh-CN.md) | **繁體中文** | [日本語](README.ja.md) | [Русский](README.ru.md)

<div align="center">

<img src="https://raw.githubusercontent.com/ErisPulse/ErisPulse/main/.github/assets/ErisPulseLogo.png" width="180" alt="ErisPulse-App" />

# ErisPulse-App

**在 Android、Windows、Linux 上執行 ErisPulse。多實例、原生介面、背景常駐。**

[ErisPulse](https://github.com/ErisPulse/ErisPulse)（事件驅動的多平台機器人框架）的官方多平台客戶端。使用純原生介面建立、執行、管理機器人實例，無需電腦、無需終端、無需任何設定步驟。

<p>
  <a href="https://github.com/ErisPulse/ErisPulse-App/releases"><img src="https://img.shields.io/github/v/release/ErisPulse/ErisPulse-App?style=for-the-badge&logo=github&color=brightgreen" alt="Release"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://github.com/ErisPulse/ErisPulse"><img src="https://img.shields.io/badge/Powered_by-ErisPulse-FF6B9D?style=for-the-badge&logo=bookstack&logoColor=white" alt="ErisPulse"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/discussions"><img src="https://img.shields.io/badge/Discussions-181717?style=for-the-badge&logo=github" alt="Discussions"></a>
</p>

</div>

---

## 核心功能

<table>
<tr>
<td width="33%" align="center" valign="top">

### 多平台

Android 已發佈；Windows / Linux 桌面版開發中。所有平台共享同一套 Flutter 程式碼庫。

</td>
<td width="33%" align="center" valign="top">

### 多實例

每個實例都是獨立的機器人，擁有自己的連接埠、工作目錄與 token——依需求建立、啟動、停止、刪除。

</td>
<td width="33%" align="center" valign="top">

### 原生介面

基於 Dashboard REST/WebSocket API 建構的純原生介面——即時監控、串流日誌、介面卡與模組管理。

</td>
</tr>
<tr>
<td width="33%" align="center" valign="top">

### 背景常駐

Android 上前景服務讓每個實例在背景持續執行，崩潰自動偵測並重啟；桌面端實例作為受 App 管理的直接程序執行。

</td>
<td width="33%" align="center" valign="top">

### 內建執行環境

Android 上 proot、busybox 與含 Python + ErisPulse 的 Ubuntu 映像內建（offline 版）或首啟下載（online 版）。桌面端捆綁可攜式 Python，ErisPulse SDK 從 PyPI 安裝，版本可選、預設最新。

</td>
<td width="33%" align="center" valign="top">

### 下載鏡像

GitHub Releases 在部分網路環境緩慢或不可達——在設定頁一鍵切換下載源為鏡像（ghfast / gh-proxy）。

</td>
</tr>
</table>

---

## 運作原理

### Android

```
┌────────────────────────────────────────────────────┐
│  ErisPulse-App (Flutter)                            │
│                                                    │
│  原生 UI ── Dashboard REST / WS API                 │
│       │                                            │
│       └── Foreground Service（背景 isolate）        │
│                │                                   │
│                ▼                                   │
│  proot（使用者態 chroot）                           │
│       │                                            │
│       ▼                                            │
│  Ubuntu rootfs + Python + ErisPulse 實例            │
└────────────────────────────────────────────────────┘
```

- **前景服務**持有所有實例程序，關閉介面後機器人仍在執行。
- UI 透過 `127.0.0.1:<port>/Dashboard/*` 與每個實例通訊——與 Web Dashboard 使用相同的 REST 與 WebSocket API。
- 每個實例在共享 rootfs 下自己的工作目錄中執行 SDK，擁有獨立的連接埠與 token。

### 桌面端（Windows / Linux）

```
┌────────────────────────────────────────────────────┐
│  ErisPulse-App (Flutter)                            │
│                                                    │
│  原生 UI ── Dashboard REST / WS API                 │
│       │                                            │
│       ▼                                            │
│  捆綁 Python ── ErisPulse 實例（程序）              │
└────────────────────────────────────────────────────┘
```

- App 捆綁可攜式 Python。首次啟動時選擇要安裝的 ErisPulse SDK 版本（預設最新）。
- 實例作為 App 的子程序執行，App 退出即停止。

內部設計見 [架構文件](docs/ARCHITECTURE.md)。

---

## 快速開始

### Android

[Releases](https://github.com/ErisPulse/ErisPulse-App/releases) 發佈兩種建置：

| 建置 | 執行環境映像 |
|------|-----------|
| `erispulse-app-online-*.apk` | 首次啟動時下載 |
| `erispulse-app-offline-*.apk` | 內建在 APK 中 |

兩種安裝方式相同：

1. 安裝並啟動。允許通知權限——它保證背景服務存活。
2. 主頁在執行環境就緒前顯示橫幅，點擊進入首啟初始化（含進度與日誌檢視）。
3. 建立一個實例並啟動。
4. 在應用內設定介面卡與模型 API Key。

> offline 版完全自包含，安裝後無需聯網。若首次啟動下載緩慢或不穩定，可在設定頁將**下載源**切換為鏡像。

### 桌面端

> Windows / Linux 桌面版開發中。

1. 安裝並啟動。
2. 在歡迎頁選擇要安裝的 ErisPulse SDK 版本（預設選中最新）並安裝。
3. 建立一個實例並啟動。

---

## 開發者指南

### 環境需求

- Flutter ≥ 3.22（stable channel）
- Android SDK（API 36+，建置 Android 時）

### 建置

```bash
flutter pub get

# Android
# online：執行環境首次啟動下載
flutter build apk --release --dart-define=FLAVOR=online
# offline：rootfs 內建進 APK（需要 assets/rootfs 存在）
flutter build apk --release --dart-define=FLAVOR=offline

# Desktop
flutter build windows
flutter build linux
```

Android 的 rootfs 由獨立 workflow（`.github/workflows/build-rootfs.yml`）建置，把 Ubuntu arm64 + Python + ErisPulse 烘焙進去，再由 Android 建置嵌入。詳見 `scripts/`。

### 程式碼結構

```
lib/
├── main.dart                    入口 + Provider 裝配
├── models/                      實例 / 日誌 / 系統 / 介面卡 DTO
├── pages/                       原生介面
│   ├── home_page.dart           實例清單
│   ├── instance_detail_page.dart 概覽 / 日誌 / 介面卡 / 模組 / 設定
│   ├── onboarding_page.dart     首啟執行環境供給
│   └── ...
├── services/
│   ├── instance_manager.dart    實例中繼資料 CRUD + 持久化
│   ├── dashboard_api.dart       Dashboard REST 客戶端
│   └── runtime/                 proot / rootfs / 前景服務（Android）
│                               桌面執行環境 / SDK 管理器（Windows/Linux）
└── widgets/
```

---

## 相關專案

| 專案 | 說明 |
|------|------|
| [ErisPulse](https://github.com/ErisPulse/ErisPulse) | 本 App 內嵌的非同步多平台機器人框架 |
| [ErisPulse-Dashboard](https://github.com/ErisPulse/ErisPulse-Dashboard) | Web 管理面板；本 App 原生介面所基於的 API |

---

## 授權

[MIT](LICENSE)

---

## 致謝

Android 容器方案基於使用者態 chroot（proot）與靜態 busybox，沿用 [Termux](https://github.com/termux/termux-app) 生態的成熟實踐。產品形態與行動端部署思路參考 [AstrBot-Android-App](https://github.com/zz6zz666/AstrBot-Android-App)。
