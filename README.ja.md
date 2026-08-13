[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | **日本語** | [Русский](README.ru.md)

<div align="center">

<img src="https://raw.githubusercontent.com/ErisPulse/ErisPulse/main/.github/assets/ErisPulseLogo.png" width="180" alt="ErisPulse-App" />

# ErisPulse-App

**Android、Windows、Linux で ErisPulse を実行。マルチインスタンス、ネイティブ UI、常時稼働。**

[ErisPulse](https://github.com/ErisPulse/ErisPulse)（イベント駆動型マルチプラットフォーム bot フレームワーク）の公式マルチプラットフォームクライアント。完全なネイティブ UI で bot インスタンスを作成・実行・管理できます。PC もターミナルも設定手順も不要です。

<p>
  <a href="https://github.com/ErisPulse/ErisPulse-App/releases"><img src="https://img.shields.io/github/v/release/ErisPulse/ErisPulse-App?style=for-the-badge&logo=github&color=brightgreen" alt="Release"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://github.com/ErisPulse/ErisPulse"><img src="https://img.shields.io/badge/Powered_by-ErisPulse-FF6B9D?style=for-the-badge&logo=bookstack&logoColor=white" alt="ErisPulse"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/discussions"><img src="https://img.shields.io/badge/Discussions-181717?style=for-the-badge&logo=github" alt="Discussions"></a>
</p>

</div>

---

## 主な機能

<table>
<tr>
<td width="33%" align="center" valign="top">

### マルチプラットフォーム

Android はリリース済み。Windows / Linux デスクトップ版は開発中。全プラットフォームで共通の Flutter コードベース。

</td>
<td width="33%" align="center" valign="top">

### マルチインスタンス

各インスタンスは独立した bot で、独自のポート・作業ディレクトリ・トークンを持ちます。作成・起動・停止・削除はお好きなだけ。

</td>
<td width="33%" align="center" valign="top">

### ネイティブ UI

Dashboard の REST/WebSocket API 上に構築された完全ネイティブ UI。リアルタイム監視、ストリーミングログ、アダプター・モジュール管理。

</td>
</tr>
<tr>
<td width="33%" align="center" valign="top">

### 常時稼働

Android ではフォアグラウンドサービスが全インスタンスをバックグラウンドで維持し、クラッシュは自動検出・再起動。デスクトップではインスタンスはアプリが管理する直接プロセスとして実行されます。

</td>
<td width="33%" align="center" valign="top">

### 組み込みランタイム

Android では proot・busybox と Python + ErisPulse を含む Ubuntu イメージを内蔵（offline 版）するか、初回起動時にダウンロードします（online 版）。デスクトップではポータブル Python を同梱し、ErisPulse SDK は PyPI からバージョンを選んでインストール（デフォルトは最新）。

</td>
<td width="33%" align="center" valign="top">

### ダウンロードミラー

GitHub Releases は地域によって遅い・到達不能なことがあります。設定ページからダウンロードソースをミラー（ghfast / gh-proxy）にワンタッチで切り替えられます。

</td>
</tr>
</table>

---

## 仕組み

### Android

```
┌────────────────────────────────────────────────────┐
│  ErisPulse-App (Flutter)                            │
│                                                    │
│  ネイティブ UI ── Dashboard REST / WS API           │
│       │                                            │
│       └── Foreground Service（バックグラウンド isolate）
│                │                                   │
│                ▼                                   │
│  proot（ユーザー空間 chroot）                       │
│       │                                            │
│       ▼                                            │
│  Ubuntu rootfs + Python + ErisPulse インスタンス    │
└────────────────────────────────────────────────────┘
```

- **フォアグラウンドサービス**がすべてのインスタンスプロセスを保持するため、UI を閉じても bot は動き続けます。
- UI は `127.0.0.1:<port>/Dashboard/*` を通じて各インスタンスと通信します。Web Dashboard と同じ REST / WebSocket API です。
- 各インスタンスは共有 rootfs 配下の作業ディレクトリで SDK を実行し、独自のポートとトークンを持ちます。

### デスクトップ（Windows / Linux）

```
┌────────────────────────────────────────────────────┐
│  ErisPulse-App (Flutter)                            │
│                                                    │
│  ネイティブ UI ── Dashboard REST / WS API           │
│       │                                            │
│       ▼                                            │
│  同梱 Python ── ErisPulse インスタンス（プロセス）  │
└────────────────────────────────────────────────────┘
```

- アプリにはポータブル Python が同梱されています。初回起動時にインストールする ErisPulse SDK のバージョンを選択します（デフォルトは最新）。
- インスタンスはアプリの子プロセスとして実行され、アプリを終了すると停止します。

内部設計は [アーキテクチャ](docs/ARCHITECTURE.md) をご覧ください。

---

## クイックスタート

### Android

[Releases](https://github.com/ErisPulse/ErisPulse-App/releases) から 2 種類のビルドを公開しています：

| ビルド | ランタイムイメージ |
|-------|-------------------|
| `erispulse-app-online-*.apk` | 初回起動時にダウンロード |
| `erispulse-app-offline-*.apk` | APK 内に同梱 |

どちらもインストール方法は同じです：

1. インストールして起動します。通知権限を許可してください——バックグラウンドサービスを維持します。
2. ランタイムが準備できるまでホーム画面にバナーが表示されます。タップして初回初期化を実行します（進捗とログ表示付き）。
3. インスタンスを作成して起動します。
4. アプリ内ダッシュボードでアダプターとモデル API キーを設定します。

> offline 版は完全自己完結で、インストール後にネットワークは不要です。初回ダウンロードが遅い・不安定な場合は、設定の**ダウンロードソース**をミラーに切り替えてください。

### デスクトップ

> Windows / Linux デスクトップ版は開発中です。

1. インストールして起動します。
2. ようこそ画面でインストールする ErisPulse SDK のバージョンを選択し（デフォルトで最新が選択済み）、インストールします。
3. インスタンスを作成して起動します。

---

## 開発者ガイド

### 要件

- Flutter ≥ 3.22（stable channel）
- Android ビルドには Android SDK（API 36+）

### ビルド

```bash
flutter pub get

# Android
# online：ランタイムは初回起動時にダウンロード
flutter build apk --release --dart-define=FLAVOR=online
# offline：rootfs を APK に同梱（assets/rootfs が必要）
flutter build apk --release --dart-define=FLAVOR=offline

# Desktop
flutter build windows
flutter build linux
```

Android の rootfs は別の workflow（`.github/workflows/build-rootfs.yml`）が Ubuntu arm64 + Python + ErisPulse を焼き込んで作ります。詳細は `scripts/` をご覧ください。

### プロジェクト構成

```
lib/
├── main.dart                    エントリーポイント + Provider 配線
├── models/                      インスタンス / ログ / システム / アダプター DTO
├── pages/                       ネイティブ UI ページ
│   ├── home_page.dart           インスタンス一覧
│   ├── instance_detail_page.dart 概要 / ログ / アダプター / モジュール / 設定
│   ├── onboarding_page.dart     初回ランタイムプロビジョニング
│   └── ...
├── services/
│   ├── instance_manager.dart    インスタンスメタデータ CRUD + 永続化
│   ├── dashboard_api.dart       Dashboard REST クライアント
│   └── runtime/                 proot / rootfs / フォアグラウンドサービス（Android）
│                               デスクトップランタイム / SDK マネージャー（Windows/Linux）
└── widgets/
```

---

## 関連プロジェクト

| プロジェクト | 説明 |
|------------|------|
| [ErisPulse](https://github.com/ErisPulse/ErisPulse) | 本アプリが組み込む非同期マルチプラットフォーム bot フレームワーク |
| [ErisPulse-Dashboard](https://github.com/ErisPulse/ErisPulse-Dashboard) | Web 管理パネル。本アプリのネイティブ UI が基づく API |

---

## ライセンス

[MIT](LICENSE)

---

## 謝辞

Android コンテナ方式はユーザー空間 chroot（proot）と静的 busybox に基づき、[Termux](https://github.com/termux/termux-app) エコシステムの実践を踏襲しています。製品形態とモバイル展開のアプローチは [AstrBot-Android-App](https://github.com/zz6zz666/AstrBot-Android-App) を参考にしています。
