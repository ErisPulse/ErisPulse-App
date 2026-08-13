**English** | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [Русский](README.ru.md)

<div align="center">

<img src="https://raw.githubusercontent.com/ErisPulse/ErisPulse/main/.github/assets/ErisPulseLogo.png" width="180" alt="ErisPulse-App" />

# ErisPulse-App

**Run ErisPulse on Android, Windows and Linux — multiple instances, native UI, always-on.**

An official multi-platform client for [ErisPulse](https://github.com/ErisPulse/ErisPulse) — the event-driven multi-platform bot framework. Create, run, and manage bot instances with a fully native UI. No PC, terminal, or setup steps required.

<p>
  <a href="https://github.com/ErisPulse/ErisPulse-App/releases"><img src="https://img.shields.io/github/v/release/ErisPulse/ErisPulse-App?style=for-the-badge&logo=github&color=brightgreen" alt="Release"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://github.com/ErisPulse/ErisPulse"><img src="https://img.shields.io/badge/Powered_by-ErisPulse-FF6B9D?style=for-the-badge&logo=bookstack&logoColor=white" alt="ErisPulse"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/discussions"><img src="https://img.shields.io/badge/Discussions-181717?style=for-the-badge&logo=github" alt="Discussions"></a>
</p>

</div>

---

## Core Features

<div align="center">

</div>

<table>
<tr>
<td width="33%" align="center" valign="top">

### Multi-platform

Android is released; Windows and Linux desktop builds are in progress. A single Flutter codebase across every platform.

</td>
<td width="33%" align="center" valign="top">

### Multi-instance

Each instance is an independent bot with its own port, working directory and token — create, start, stop and delete as many as you need.

</td>
<td width="33%" align="center" valign="top">

### Native UI

A fully native interface built on the Dashboard REST/WebSocket API — real-time monitoring, streaming logs, adapter and module management.

</td>
</tr>
<tr>
<td width="33%" align="center" valign="top">

### Always-on

On Android a foreground service keeps every instance alive in the background; crashes are detected and restarted automatically. On desktop, instances run as direct processes managed by the app.

</td>
<td width="33%" align="center" valign="top">

### Embedded Runtime

On Android, proot, busybox and an Ubuntu image with Python + ErisPulse are bundled (offline build) or downloaded on first launch (online build). On desktop, a portable Python is bundled and the ErisPulse SDK is installed from PyPI with your choice of version — latest by default.

</td>
<td width="33%" align="center" valign="top">

### Download Mirror

GitHub releases can be slow or unreachable in some regions — switch the download source to a mirror (ghfast / gh-proxy) right from the settings page.

</td>
</tr>
</table>

---

## How It Works

### Android

```
┌────────────────────────────────────────────────────┐
│  ErisPulse-App (Flutter)                            │
│                                                    │
│  Native UI ── Dashboard REST / WS API              │
│       │                                            │
│       └── Foreground Service (background isolate)  │
│                │                                   │
│                ▼                                   │
│  proot (user-space chroot)                         │
│       │                                            │
│       ▼                                            │
│  Ubuntu rootfs + Python + ErisPulse instances      │
└────────────────────────────────────────────────────┘
```

- The **Foreground Service** owns every instance process, so bots keep running even when the UI is closed.
- The UI talks to each instance through `127.0.0.1:<port>/Dashboard/*` — the same REST and WebSocket API the web Dashboard uses.
- Each instance runs the SDK in its own working directory under the shared rootfs, with its own port and token.

### Desktop (Windows / Linux)

```
┌────────────────────────────────────────────────────┐
│  ErisPulse-App (Flutter)                            │
│                                                    │
│  Native UI ── Dashboard REST / WS API              │
│       │                                            │
│       ▼                                            │
│  bundled Python ── ErisPulse instances (processes) │
└────────────────────────────────────────────────────┘
```

- The app bundles a portable Python. On first launch you pick an ErisPulse SDK version to install (latest by default).
- Instances run as direct child processes of the app and stop when the app exits.

For the internal design, see [Architecture](docs/ARCHITECTURE.md).

---

## Quick Start

### Android

Two builds are published on [Releases](https://github.com/ErisPulse/ErisPulse-App/releases):

| Build | Runtime image |
|-------|---------------|
| `erispulse-app-online-*.apk` | downloaded on first launch |
| `erispulse-app-offline-*.apk` | bundled inside the APK |

Both install the same way:

1. Install and launch. Allow the notification permission — it keeps the background service alive.
2. The home screen shows a banner until the runtime is ready. Tap it to run the first-launch initialization (progress and log view included).
3. Create an instance and start it.
4. Configure adapters and your model API keys from the in-app dashboard.

> The offline build is self-contained — no network access needed after installation. If the first-launch download is slow or unreliable, switch the **download source** in Settings to a mirror.

### Desktop

> Windows and Linux desktop builds are in progress.

1. Install and launch.
2. Choose an ErisPulse SDK version on the welcome screen (latest is preselected) and install it.
3. Create an instance and start it.

---

## Developer Guide

### Requirements

- Flutter ≥ 3.22 (stable channel)
- Android SDK (API 36+) for Android builds

### Build

```bash
flutter pub get

# Android
# online: runtime downloaded on first launch
flutter build apk --release --dart-define=FLAVOR=online
# offline: rootfs bundled into the APK (needs assets/rootfs present)
flutter build apk --release --dart-define=FLAVOR=offline

# Desktop
flutter build windows
flutter build linux
```

The Android rootfs image is built by a separate workflow (`.github/workflows/build-rootfs.yml`) which bakes Ubuntu arm64 + Python + ErisPulse; the Android build then embeds it. See `scripts/` for details.

### Project Layout

```
lib/
├── main.dart                    # Entry point + Provider wiring
├── models/                      # Instance / log / system / adapter DTOs
├── pages/                       # Native UI pages
│   ├── home_page.dart           # Instance list
│   ├── instance_detail_page.dart# Overview / logs / adapters / modules / config
│   ├── onboarding_page.dart     # First-launch runtime provisioning
│   └── ...
├── services/
│   ├── instance_manager.dart    # Instance metadata CRUD + persistence
│   ├── dashboard_api.dart       # Dashboard REST client
│   └── runtime/                 # proot / rootfs / foreground service (Android)
│                               # desktop runtime / SDK manager (Windows/Linux)
└── widgets/
```

---

## Related Projects

| Project | Description |
|---------|-------------|
| [ErisPulse](https://github.com/ErisPulse/ErisPulse) | The async multi-platform bot framework this app embeds |
| [ErisPulse-Dashboard](https://github.com/ErisPulse/ErisPulse-Dashboard) | Web management panel; the API this app's native UI is built on |

---

## License

[MIT](LICENSE)

---

## Acknowledgments

The Android container approach builds on user-space chroot (proot) and static busybox, following the ecosystem established by [Termux](https://github.com/termux/termux-app). The product shape and mobile deployment approach draw on [AstrBot-Android-App](https://github.com/zz6zz666/AstrBot-Android-App).
