// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'ErisPulse';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonStart => 'Запуск';

  @override
  String get commonStop => 'Остановить';

  @override
  String get commonRestart => 'Перезапуск';

  @override
  String get commonCreate => 'Создать';

  @override
  String get commonRefresh => 'Обновить';

  @override
  String get commonSettings => 'Настройки';

  @override
  String get commonCopy => 'Копировать';

  @override
  String get commonCopyAll => 'Копировать всё';

  @override
  String get commonClear => 'Очистить';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonInitialize => 'Инициализировать';

  @override
  String get commonRemote => 'Удалённый';

  @override
  String get commonLocal => 'Локальный';

  @override
  String get commonCreateInstance => 'Создать экземпляр';

  @override
  String get commonDeleteInstance => 'Удалить экземпляр';

  @override
  String get commonRename => 'Переименовать';

  @override
  String get commonViewLogs => 'Просмотр журнала';

  @override
  String get statusStopped => 'Остановлен';

  @override
  String get statusStarting => 'Запуск';

  @override
  String get statusRunning => 'Работает';

  @override
  String get statusError => 'Ошибка';

  @override
  String get statusDestroying => 'Уничтожение';

  @override
  String get statusHealthy => 'Здоров';

  @override
  String get statusBooting => 'Запуск';

  @override
  String get statusTokenInvalid => 'Недействительный токен';

  @override
  String get statusOffline => 'Офлайн';

  @override
  String get statusUnknown => 'Не проверено';

  @override
  String get statusOnline => 'Онлайн';

  @override
  String get statusConnecting => 'Подключение';

  @override
  String get statusRemoteUnknown => 'Неизвестно';

  @override
  String get homeDebugTooltip => 'Журнал отладки';

  @override
  String get homeEmptyTitle => 'Пока нет экземпляров';

  @override
  String get homeEmptySubtitle =>
      'Создайте свой первый экземпляр ErisPulse\nКаждый экземпляр — это независимый бот';

  @override
  String homeDeleteConfirmContent(Object name) {
    return 'Удалить \"$name\"?\nРабочий каталог экземпляра будет сохранён; удаляются только метаданные.';
  }

  @override
  String get homeBannerTitle => 'Среда выполнения не готова';

  @override
  String get homeBannerInitializing => 'Инициализация…';

  @override
  String get homeBannerNeedDownload =>
      'Необходимо загрузить и распаковать образ среды выполнения';

  @override
  String get onboardingTitle => 'Подготовка среды';

  @override
  String get onboardingDescription =>
      'При первом запуске необходимо подготовить образ среды\n(Ubuntu + Python + ErisPulse)';

  @override
  String get onboardingStartButton => 'Начать инициализацию';

  @override
  String get onboardingTapHint =>
      'Нажмите в любом месте, чтобы переключить вид Прогресс / Журнал';

  @override
  String get onboardingProcessing => 'Обработка…';

  @override
  String get onboardingLogTitle => 'Журнал инициализации';

  @override
  String get onboardingStartingLog => 'Запуск инициализации среды…';

  @override
  String get onboardingReadyLog => 'Среда готова ✓';

  @override
  String onboardingErrorLog(Object msg) {
    return 'Ошибка: $msg';
  }

  @override
  String get onboardingSdkTitle => 'Установить ErisPulse SDK';

  @override
  String onboardingSdkPythonMissing(Object path) {
    return 'Встроенный Python не найден: $path';
  }

  @override
  String onboardingSdkInstalled(Object version) {
    return 'ErisPulse $version установлен';
  }

  @override
  String get onboardingSdkChooseVersion => 'Выберите версию для установки';

  @override
  String get onboardingSdkInstall => 'Установить';

  @override
  String get onboardingSdkInstalling => 'Установка…';

  @override
  String get onboardingSdkVersionFailed =>
      'Не удалось получить версии, проверьте сеть';

  @override
  String get onboardingSdkRefresh => 'Обновить';

  @override
  String get onboardingSdkContinue => 'Продолжить';

  @override
  String get homeBannerNeedSdk => 'Требуется установить ErisPulse SDK';

  @override
  String get createTitle => 'Создание экземпляра ErisPulse';

  @override
  String get createSubtitle =>
      'Локальный экземпляр работает независимо на этом телефоне;\nудалённый экземпляр подключается к экземпляру, развёрнутому на другом хосте.';

  @override
  String get createNameLabel => 'Имя экземпляра *';

  @override
  String get createNameHint => 'например: Мой бот';

  @override
  String get createNameHelper =>
      'Используется для различения экземпляров в списке';

  @override
  String get createNameRequired => 'Имя обязательно';

  @override
  String get createNameTooLong => 'Слишком длинное имя (макс. 24 символа)';

  @override
  String get createUrlLabel => 'URL Dashboard *';

  @override
  String get createUrlHelper => 'Базовый URL Dashboard удалённого экземпляра';

  @override
  String get createUrlRequired => 'URL обязателен';

  @override
  String get createUrlScheme => 'Должен начинаться с http:// или https://';

  @override
  String get createTokenLabel => 'Токен доступа (необязательно)';

  @override
  String get createTokenHelper =>
      'Токен удалённого Dashboard, используется для проверки и входа';

  @override
  String get createPortLabel => 'Порт прослушивания *';

  @override
  String get createPortHelper =>
      'У каждого экземпляра свой порт; по умолчанию назначается автоматически';

  @override
  String get createPortRequired => 'Порт обязателен';

  @override
  String get createPortRange => 'Порт должен быть в диапазоне 1024-65535';

  @override
  String get createRemoteNote =>
      'Удалённый экземпляр работает на другом хосте; приложение просматривает и управляет им через его Dashboard.';

  @override
  String get createLocalNote =>
      'Экземпляр создаётся в состоянии \"Остановлен\"; его можно запустить на странице сведений.';

  @override
  String createCreated(Object name) {
    return 'Экземпляр \"$name\" создан';
  }

  @override
  String get createFailed => 'Не удалось создать';

  @override
  String get createFailedRetry => 'Не удалось создать, повторите попытку';

  @override
  String get detailSystemResource => 'Системные ресурсы';

  @override
  String get detailResourceHint =>
      'Ресурсы Dashboard отображаются после запуска экземпляра';

  @override
  String get detailMemory => 'Память';

  @override
  String get detailUptime => 'Время работы';

  @override
  String get detailThreads => 'Потоки';

  @override
  String get detailCores => 'Ядра';

  @override
  String get detailAddress => 'Адрес';

  @override
  String get detailPort => 'Порт';

  @override
  String get detailTapToReveal => 'Нажмите, чтобы показать и скопировать';

  @override
  String get detailTokenCopied => 'Токен скопирован';

  @override
  String get detailRefreshState => 'Обновить статус';

  @override
  String get detailNotFound => 'Экземпляр не найден';

  @override
  String get detailRecentEvents => 'Последние события';

  @override
  String get detailNoEvents =>
      'Событий пока нет; события фреймворка/адаптеров будут записаны после запуска экземпляра';

  @override
  String get detailOpenDashboard => 'Открыть Dashboard';

  @override
  String get detailStartingToast => 'Запуск…';

  @override
  String get detailStoppedToast => 'Запрошена остановка';

  @override
  String get detailRestartingToast => 'Перезапуск…';

  @override
  String get detailUnreachableError =>
      'Экземпляр не запущен или Dashboard недоступен';

  @override
  String get detailOverview => 'Обзор';

  @override
  String get detailModules => 'Модули';

  @override
  String get detailAdapters => 'Адаптеры';

  @override
  String detailEnabledCount(Object count) {
    return 'включено: $count';
  }

  @override
  String detailRunningCount(Object count) {
    return 'работает: $count';
  }

  @override
  String dashboardLoadFailed(Object code) {
    return 'Не удалось загрузить ($code)';
  }

  @override
  String get dashboardTokenCopied =>
      'Токен доступа скопирован; вставьте его на страницу входа';

  @override
  String get dashboardExternalFailed => 'Не удалось открыть внешний браузер';

  @override
  String get dashboardCopyTokenTooltip => 'Скопировать токен доступа';

  @override
  String get dashboardExternalOpen => 'Открыть во внешнем браузере';

  @override
  String get dashboardCheckHint =>
      'Убедитесь, что экземпляр запущен и этот адрес доступен';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsThemeSystem => 'Как в системе';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLangSystem => 'Как в системе';

  @override
  String get settingsLangZh => '简体中文';

  @override
  String get settingsLangZhHant => '繁體中文';

  @override
  String get settingsLangEn => 'English';

  @override
  String get settingsLangJa => '日本語';

  @override
  String get settingsLangRu => 'Русский';

  @override
  String get settingsDownloadSource => 'Источник загрузки';

  @override
  String get settingsDownloadGithub => 'Официальный GitHub';

  @override
  String get settingsDownloadGhfast => 'Зеркало GitHub (ghfast.top)';

  @override
  String get settingsDownloadGhproxy => 'Зеркало GitHub (gh-proxy.com)';

  @override
  String get settingsRuntime => 'Среда выполнения';

  @override
  String get settingsRootfsTitle => 'Среда выполнения (rootfs)';

  @override
  String settingsRuntimeReady(Object version) {
    return 'Встроенный Python + ErisPulse $version';
  }

  @override
  String get settingsRootfsReady => 'Готово';

  @override
  String get settingsRootfsNotReady => 'Не готово';

  @override
  String get settingsAutoRestart => 'Автозапуск после сбоя';

  @override
  String get settingsAutoRestartDesc =>
      'Автоматически перезапускать экземпляр после аварийного завершения';

  @override
  String get settingsStopAll => 'Остановить все экземпляры';

  @override
  String get settingsStopAllDesc =>
      'Завершить все процессы локальных экземпляров';

  @override
  String get settingsStopAllConfirm =>
      'Остановить все работающие локальные экземпляры?';

  @override
  String get settingsStopAllAction => 'Остановить все';

  @override
  String get settingsData => 'Данные';

  @override
  String get settingsClearLogs => 'Очистить журнал отладки';

  @override
  String get settingsClearLogsDesc => 'Очистить буфер журнала процесса proot';

  @override
  String get settingsAbout => 'О программе';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsAboutApp => 'О ErisPulse-App';

  @override
  String get settingsAboutSubtitle =>
      'Клиент управления несколькими устройствами (лаунчер + Dashboard)';

  @override
  String get settingsAboutDialog =>
      'Клиент управления ErisPulse.\nЛокальные экземпляры работают на proot + Ubuntu; интерфейс управления предоставляет Dashboard.\n\nMIT License';

  @override
  String get debugTitle => 'Отладочная информация';

  @override
  String get debugCopyAllTooltip => 'Копировать всё';

  @override
  String get debugClearLogsTooltip => 'Очистить журнал';

  @override
  String get debugCopiedAll => 'Полная отладочная информация скопирована';

  @override
  String get debugCopiedLogs => 'Журнал скопирован';

  @override
  String get debugAppVersion => 'Версия приложения';

  @override
  String get debugPackageName => 'Пакет';

  @override
  String get debugDeviceModel => 'Модель устройства';

  @override
  String get debugBrand => 'Бренд';

  @override
  String get debugAndroid => 'Android';

  @override
  String get debugAbi => 'ABI';

  @override
  String get debugNativeLib => 'native lib';

  @override
  String get debugRootfs => 'rootfs';

  @override
  String get debugRootfsError => 'ошибка rootfs';

  @override
  String get debugInstanceCount => 'Количество экземпляров';

  @override
  String get debugInfoHeader => '== Отладочная информация ErisPulse-App ==';

  @override
  String get debugReady => 'Готово';

  @override
  String get debugNotReady => 'Не готово';

  @override
  String get debugRootfsMessage => 'сообщение rootfs';

  @override
  String get debugLogHeader => '== Журнал ==';

  @override
  String get debugNoLogs =>
      'Журнал пуст\nПосле запуска экземпляра вывод процесса proot будет отображаться здесь в реальном времени';

  @override
  String get debugProcessLogs => 'Журнал процесса';

  @override
  String logsCopiedLines(Object count) {
    return 'Скопировано строк журнала: $count';
  }

  @override
  String get logsResume => 'Продолжить';

  @override
  String get logsPause => 'Пауза';

  @override
  String get logsAutoScroll => 'Автопрокрутка';

  @override
  String logsLineCount(Object count) {
    return '$count строк';
  }

  @override
  String get logsEmptyTitle => 'Журнал пуст';

  @override
  String get logsEmptySubtitle =>
      'После запуска экземпляра здесь в реальном времени будет отображаться исходный вывод процесса';
}
