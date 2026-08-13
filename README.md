[English](README.md) | [简体中文](README.zh-CN.md)

# ErisPulse-App

**Run ErisPulse on your phone. Multiple instances, native UI, always-on.**

An Android client that embeds [ErisPulse](https://github.com/ErisPulse/ErisPulse) — the event-driven multi-platform bot framework — so you can create, run, and manage bot instances directly on your phone, with no PC or terminal required.

<p>
  <a href="https://github.com/ErisPulse/ErisPulse-App/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/releases"><img src="https://img.shields.io/github/v/release/ErisPulse/ErisPulse-App?style=for-the-badge" alt="Release"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/discussions"><img src="https://img.shields.io/badge/Discussions-181717?style=for-the-badge&logo=github" alt="Discussions"></a>
</p>

---

<div align="center">

### Core Features

</div>

<table>
<tr>
<td width="33%" align="center" valign="top">

### Embedded Runtime

The full ErisPulse runtime — proot, busybox and a pre-baked Ubuntu image with Python and ErisPulse — is bundled inside the APK. Install and go, fully offline, no setup steps.

</td>
<td width="33%" align="center" valign="top">

### Multi-instance

Each instance is an independent bot with its own port, working directory and token, all managed from one app. Create, start, stop and delete as many as you need.

</td>
<td width="33%" align="center" valign="top">

### Native UI

A fully native interface built on top of the Dashboard REST/WebSocket API — no WebView. Real-time system monitoring, streaming logs, adapter and module management.

</td>
</tr>
<tr>
<td width="33%" align="center" valign="top">

### Always-on

A foreground service keeps every instance alive in the background. The screen can be off, the app can be closed — bots keep running. Crashes are detected and restarted automatically.

</td>
<td width="33%" align="center" valign="top">

### Zero Configuration

First launch extracts the bundled runtime and walks you through it with a progress view. No shell, no package manager, no terminal.

</td>
<td width="33%" align="center" valign="top">

### Cross-platform Codebase

A single Flutter codebase targeting Android today, with Windows / macOS / Linux / iOS as a follow-up.

</td>
</tr>
</table>

---

## How It Works

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

For the internal design, see [Architecture](docs/ARCHITECTURE.md).

---

## Quick Start

Two builds are published on [Releases](https://github.com/ErisPulse/ErisPulse-App/releases):

| Build | Runtime image |
|-------|---------------|
| `erispulse-app-online-*.apk` | downloaded on first launch |
| `erispulse-app-offline-*.apk` | bundled inside the APK |

Both install the same way:

1. Install and launch. Allow the notification permission — it keeps the background service alive.
2. The first launch prepares the runtime (progress and log view included).
3. Create an instance and start it.
4. Configure adapters and your model API keys from the in-app dashboard.

> The offline build is self-contained — no network access needed after installation. Choose it if the first-launch download would be slow or unreliable.

---

## Developer Guide

### Requirements

- Flutter ≥ 3.22 (stable channel)
- Android SDK (API 36+)

### Build

```bash
flutter pub get

# Fetch proot / busybox into assets/runtime (CI does this automatically)
bash scripts/fetch-runtime-binaries.sh

# Fetch the pre-baked rootfs into assets/rootfs (CI does this automatically)
# from the latest build-rootfs release

# online: runtime downloaded on first launch
flutter build apk --release --dart-define=FLAVOR=online

# offline: rootfs bundled into the APK (needs assets/rootfs present)
flutter build apk --release --dart-define=FLAVOR=offline
```

The rootfs image is built by a separate workflow (`.github/workflows/build-rootfs.yml`) which bakes Ubuntu arm64 + Python + ErisPulse into a `tar.xz`; the Android build then embeds it. See `scripts/` for details.

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
│   └── runtime/                 # proot / rootfs / foreground service
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

- [AstrBot-Android-App](https://github.com/zz6zz666/AstrBot-Android-App) for the product shape and mobile deployment approach.
- The Android container approach builds on user-space chroot (proot) and static busybox, following the ecosystem established by Termux.
