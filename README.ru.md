[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | **Русский**

<div align="center">

<img src="https://raw.githubusercontent.com/ErisPulse/ErisPulse/main/.github/assets/ErisPulseLogo.png" width="180" alt="ErisPulse-App" />

# ErisPulse-App

**Запускайте ErisPulse на Android, Windows, Linux и macOS — несколько экземпляров, нативный интерфейс, работа в фоне.**

Официальный многоплатформенный клиент для [ErisPulse](https://github.com/ErisPulse/ErisPulse) — событийно-ориентированного многоплатформенного фреймворка для ботов. Создавайте, запускайте и управляйте экземплярами ботов с полностью нативным интерфейсом. Не нужны ни ПК, ни терминал, ни шаги по настройке.

<p>
  <a href="https://github.com/ErisPulse/ErisPulse-App/releases"><img src="https://img.shields.io/github/v/release/ErisPulse/ErisPulse-App?style=for-the-badge&logo=github&color=brightgreen" alt="Release"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://github.com/ErisPulse/ErisPulse"><img src="https://img.shields.io/badge/Powered_by-ErisPulse-FF6B9D?style=for-the-badge&logo=bookstack&logoColor=white" alt="ErisPulse"></a>
  <a href="https://github.com/ErisPulse/ErisPulse-App/discussions"><img src="https://img.shields.io/badge/Discussions-181717?style=for-the-badge&logo=github" alt="Discussions"></a>
</p>

</div>

---

## Основные возможности

<table>
<tr>
<td width="33%" align="center" valign="top">

### Многоплатформенность

Сборки для Android, Windows, Linux и macOS уже опубликованы на [Releases](https://github.com/ErisPulse/ErisPulse-App/releases). Единая кодовая база Flutter для всех платформ.

</td>
<td width="33%" align="center" valign="top">

### Несколько экземпляров

Каждый экземпляр — независимый бот со своим портом, рабочей директорией и токеном. Создавайте, запускайте, останавливайте и удаляйте сколько угодно.

</td>
<td width="33%" align="center" valign="top">

### Нативный интерфейс

Полностью нативный интерфейс на основе REST/WebSocket API Dashboard — мониторинг в реальном времени, потоковые логи, управление адаптерами и модулями.

</td>
</tr>
<tr>
<td width="33%" align="center" valign="top">

### Работа в фоне

На Android фоновый сервис поддерживает работу всех экземпляров в фоне; сбои обнаруживаются и перезапускаются автоматически. На десктопе экземпляры запускаются как прямые процессы, управляемые приложением.

</td>
<td width="33%" align="center" valign="top">

### Встроенный рантайм

На Android proot, busybox и образ Ubuntu с Python + ErisPulse встроены (offline-сборка) или загружаются при первом запуске (online-сборка). На десктопе прилагается портативный Python, а SDK ErisPulse устанавливается из PyPI с выбором версии — по умолчанию последняя.

</td>
<td width="33%" align="center" valign="top">

### Зеркала загрузки

GitHub Releases может быть медленным или недоступным в некоторых регионах — переключите источник загрузки на зеркало (ghfast / gh-proxy) прямо на странице настроек.

</td>
</tr>
</table>

---

## Как это работает

### Android

```
┌────────────────────────────────────────────────────┐
│  ErisPulse-App (Flutter)                            │
│                                                    │
│  Нативный UI ── Dashboard REST / WS API             │
│       │                                            │
│       └── Foreground Service (фоновый isolate)      │
│                │                                   │
│                ▼                                   │
│  proot (chroot в пространстве пользователя)        │
│       │                                            │
│       ▼                                            │
│  Ubuntu rootfs + Python + экземпляры ErisPulse      │
└────────────────────────────────────────────────────┘
```

- **Фоновый сервис** владеет всеми процессами экземпляров, поэтому боты продолжают работать даже при закрытом интерфейсе.
- Интерфейс общается с каждым экземпляром через `127.0.0.1:<port>/Dashboard/*` — тот же REST и WebSocket API, что и у веб-Dashboard.
- Каждый экземпляр запускает SDK в своей рабочей директории внутри общего rootfs, со своим портом и токеном.

### Десктоп (Windows / Linux / macOS)

```
┌────────────────────────────────────────────────────┐
│  ErisPulse-App (Flutter)                            │
│                                                    │
│  Нативный UI ── Dashboard REST / WS API             │
│       │                                            │
│       ▼                                            │
│  встроенный Python ── экземпляры ErisPulse (процессы)
└────────────────────────────────────────────────────┘
```

- Приложение включает портативный Python. При первом запуске вы выбираете версию SDK ErisPulse для установки (по умолчанию последняя).
- Экземпляры запускаются как прямые дочерние процессы приложения и останавливаются при его закрытии.

Внутреннее устройство см. в [Архитектура](docs/ARCHITECTURE.md).

---

## Быстрый старт

### Android

На [Releases](https://github.com/ErisPulse/ErisPulse-App/releases) публикуются две сборки:

| Сборка | Образ рантайма |
|--------|----------------|
| `erispulse-app-online-*.apk` | загружается при первом запуске |
| `erispulse-app-offline-*.apk` | встроен в APK |

Установка одинакова для обеих:

1. Установите и запустите. Разрешите уведомления — они поддерживают фоновый сервис.
2. На главном экране до готовности рантайма отображается баннер. Нажмите его, чтобы запустить инициализацию (с индикатором прогресса и логами).
3. Создайте экземпляр и запустите его.
4. Настройте адаптеры и API-ключи моделей во встроенном Dashboard.

> offline-сборка полностью автономна — после установки сеть не нужна. Если первая загрузка медленная или нестабильная, переключите **источник загрузки** в настройках на зеркало.

### Десктоп

> Скачайте сборку для своей платформы со страницы [Releases](https://github.com/ErisPulse/ErisPulse-App/releases): Windows `setup.exe` (или портативный `zip`), Linux `tar.gz`, macOS `zip`.

1. Установите и запустите.
2. На экране приветствия выберите версию SDK ErisPulse для установки (по умолчанию выбрана последняя) и установите.
3. Создайте экземпляр и запустите его.

---

## Руководство разработчика

### Требования

- Flutter ≥ 3.22 (stable channel)
- Android SDK (API 36+) для сборок Android

### Сборка

```bash
flutter pub get

# Android
# online: рантайм загружается при первом запуске
flutter build apk --release --dart-define=FLAVOR=online
# offline: rootfs встроен в APK (нужен assets/rootfs)
flutter build apk --release --dart-define=FLAVOR=offline

# Desktop
flutter build windows
flutter build linux
```

Образ rootfs для Android собирается отдельным workflow (`.github/workflows/build-rootfs.yml`), который встраивает Ubuntu arm64 + Python + ErisPulse. Подробности — в `scripts/`.

### Структура проекта

```
lib/
├── main.dart                    Точка входа + подключение Provider
├── models/                      DTO для экземпляров / логов / системы / адаптеров
├── pages/                       Страницы нативного интерфейса
│   ├── home_page.dart           Список экземпляров
│   ├── instance_detail_page.dart Обзор / логи / адаптеры / модули / конфигурация
│   ├── onboarding_page.dart     Подготовка рантайма при первом запуске
│   └── ...
├── services/
│   ├── instance_manager.dart    CRUD метаданных экземпляров + персистентность
│   ├── dashboard_api.dart       REST-клиент Dashboard
│   └── runtime/                 proot / rootfs / фоновый сервис (Android)
│                               десктоп-рантайм / менеджер SDK (Windows/Linux)
└── widgets/
```

---

## Связанные проекты

| Проект | Описание |
|--------|----------|
| [ErisPulse](https://github.com/ErisPulse/ErisPulse) | Асинхронный многоплатформенный фреймворк для ботов, встроенный в это приложение |
| [ErisPulse-Dashboard](https://github.com/ErisPulse/ErisPulse-Dashboard) | Веб-панель управления; API, на котором построен нативный интерфейс приложения |

---

## Лицензия

[MIT](LICENSE)

---

## Благодарности

Подход к контейнеризации Android основан на chroot в пространстве пользователя (proot) и статическом busybox, следуя экосистеме [Termux](https://github.com/termux/termux-app). Форма продукта и подход к мобильному развёртыванию опираются на [AstrBot-Android-App](https://github.com/zz6zz666/AstrBot-Android-App).
