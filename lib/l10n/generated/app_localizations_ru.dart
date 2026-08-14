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
  String get commonConfirm => 'Подтвердить';

  @override
  String get commonSoftRestart => 'Мягкий перезапуск';

  @override
  String get commonHardRestart => 'Перезапустить процесс';

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
  String get commonLoading => 'Загрузка';

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
  String get commonInstalled => 'Установлено';

  @override
  String get commonPreRelease => 'предв.';

  @override
  String get railInstances => 'Экземпляры';

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
      'При первом запуске необходимо подготовить среду выполнения\n(Python + ErisPulse)';

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
  String get onboardingSdkUseInstalled => 'Использовать установленную версию';

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
  String get onboardingPythonRelease => 'Развернуть встроенный Python';

  @override
  String get onboardingPythonReleasing => 'Развёртывание Python…';

  @override
  String get onboardingPythonReady => 'готов';

  @override
  String get onboardingPythonIntro =>
      'Приложение включает Python. Разверните его для начала работы.';

  @override
  String get onboardingPythonFailed =>
      'Не удалось развернуть встроенный Python. Повторите попытку.';

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
  String get createRuntimeLabel => 'Версия среды';

  @override
  String get createRuntimeDefault => 'Глобальная по умолчанию';

  @override
  String get createSdkVersionLabel => 'Версия ErisPulse SDK';

  @override
  String get createSdkVersionHelper =>
      'Устанавливается в собственное виртуальное окружение экземпляра';

  @override
  String get createEnvTitle => 'Источник окружения';

  @override
  String get createEnvFresh => 'Новое окружение';

  @override
  String get createEnvFreshDesc =>
      'Создать новое окружение с выбранной версией SDK';

  @override
  String get createEnvClone => 'На основе существующего экземпляра';

  @override
  String get createEnvCloneDesc =>
      'Скопировать окружение существующего экземпляра (версия SDK и установленные пакеты)';

  @override
  String get createEnvCloneSource => 'Исходный экземпляр';

  @override
  String get createEnvCloneNeedSource => 'Выберите исходный экземпляр';

  @override
  String get createPreparingEnv => 'Подготовка окружения';

  @override
  String get createEnvReady => 'Окружение готово';

  @override
  String get createEnvFailed => 'Не удалось подготовить окружение';

  @override
  String get createEnvCopying =>
      'Копирование окружения исходного экземпляра (venv)…';

  @override
  String createEnvCopyProgress(Object done, Object total) {
    return 'Скопировано файлов: $done / $total';
  }

  @override
  String get createEnvPleaseWait =>
      'Подготовка окружения. Это может занять некоторое время. Не закрывайте окно.';

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
  String get detailRuntimeLabel => 'Среда';

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
  String get detailTabOverview => 'Обзор';

  @override
  String get detailTabModules => 'Модули';

  @override
  String get detailTabAdapters => 'Адаптеры';

  @override
  String get detailTabConfig => 'Конфиг';

  @override
  String get detailTabFiles => 'Файлы';

  @override
  String get detailTabLogs => 'Журнал';

  @override
  String get detailTabPackages => 'Пакеты';

  @override
  String get detailTabEvents => 'События';

  @override
  String get detailTabAudit => 'Аудит';

  @override
  String get eventsFilterType => 'Тип';

  @override
  String get auditTitle => 'Журнал аудита';

  @override
  String get auditEmpty => 'Журнал аудита пуст';

  @override
  String get detailTabEmpty => 'Нет элементов';

  @override
  String get detailClearLogs => 'Очистить журнал';

  @override
  String get detailAuthInvalid =>
      'Недействительный или истёкший токен доступа. Проверьте токен экземпляра';

  @override
  String get detailConfigSource => 'Исходник';

  @override
  String get detailConfigEdit => 'Изменить';

  @override
  String get detailConfigSaved => 'Конфиг сохранён';

  @override
  String get detailPackageInstalled => 'Установленные пакеты';

  @override
  String get schemaConfigSave => 'Сохранить';

  @override
  String get schemaConfigSaved => 'Конфиг сохранён';

  @override
  String get schemaConfigNoSchema => 'Нет схемы конфигурации';

  @override
  String get adapterConfigGlobal => 'Глобальные настройки';

  @override
  String get adapterConfigAccounts => 'Аккаунты ботов';

  @override
  String get adapterConfigAccountAdd => 'Добавить аккаунт';

  @override
  String get adapterConfigAccountName => 'Имя аккаунта';

  @override
  String get adapterConfigAccountNameRequired => 'Введите имя аккаунта';

  @override
  String get adapterConfigAccountDelete => 'Удалить аккаунт';

  @override
  String adapterConfigAccountDeleteConfirm(String name) {
    return 'Удалить аккаунт $name? Это действие необратимо.';
  }

  @override
  String get adapterConfigAccountsEmpty => 'Нет аккаунтов ботов';

  @override
  String get adapterConfigAccountSaved => 'Аккаунт сохранён';

  @override
  String get adapterConfigAccountAdded => 'Аккаунт создан';

  @override
  String get adapterConfigAccountDeleted => 'Аккаунт удалён';

  @override
  String get adapterConfigEnabled => 'Включено';

  @override
  String get detailConfigCopied => 'Конфиг скопирован';

  @override
  String get detailPackageName => 'Имя пакета';

  @override
  String get detailPackageInstall => 'Установить пакет';

  @override
  String get detailPackageUninstall => 'Удалить пакет';

  @override
  String detailPackageUninstallConfirm(Object name) {
    return 'Удалить $name?';
  }

  @override
  String get detailFrameworkUpdate => 'Обновить фреймворк';

  @override
  String get detailFrameworkUpdateConfirm =>
      'Обновить фреймворк до последней версии?';

  @override
  String get detailFrameworkLatest => 'актуально';

  @override
  String get detailSdkRestart => 'Перезапустить SDK';

  @override
  String get detailSdkRestartConfirm =>
      'Перезапустить SDK? Все соединения будут прерваны.';

  @override
  String get detailFileSave => 'Сохранить';

  @override
  String get detailFileSaved => 'Сохранено';

  @override
  String detailFileDeleteConfirm(Object name) {
    return 'Удалить $name?';
  }

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
  String get dashboardAccessKey => 'Ключ доступа';

  @override
  String get dashboardAccessKeyCopied => 'Ключ доступа скопирован';

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
  String get settingsPypiSource => 'Зеркало PyPI';

  @override
  String get settingsPypiOfficial => 'PyPI официальный';

  @override
  String get settingsPypiTsinghua => 'Зеркало Tsinghua';

  @override
  String get settingsPypiAliyun => 'Зеркало Aliyun';

  @override
  String get settingsRuntime => 'Среда выполнения';

  @override
  String get settingsRootfsTitle => 'Среда выполнения (rootfs)';

  @override
  String settingsRuntimeReady(Object version) {
    return 'Встроенный Python + ErisPulse $version';
  }

  @override
  String get settingsRuntimeVersion => 'Версия среды выполнения';

  @override
  String get settingsRuntimeDownload => 'Скачать среду выполнения';

  @override
  String get runtimeManagerTitle => 'Управление средами';

  @override
  String get runtimeManagerInstalled => 'Установленные среды';

  @override
  String get runtimeManagerAvailable => 'Доступные версии';

  @override
  String get runtimeManagerEmpty => 'Установленных сред нет';

  @override
  String get runtimeManagerLoading => 'Получение версий…';

  @override
  String get runtimeManagerActivate => 'Активировать';

  @override
  String get runtimeManagerActive => 'Активна';

  @override
  String get runtimeManagerPath => 'Каталог сред';

  @override
  String runtimeManagerDeleteConfirm(Object version) {
    return 'Удалить среду v$version? Это действие необратимо.';
  }

  @override
  String get runtimeManagerDesc => 'Встроенный Python и окружения экземпляров';

  @override
  String get runtimeManagerInstances => 'Окружения экземпляров';

  @override
  String get runtimeManagerPythonMissing => 'Встроенный Python не готов';

  @override
  String get settingsOpenSource => 'Исходный код';

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
  String get settingsClearLogsDesc => 'Очистить журналы отладки';

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
      'Клиент управления ErisPulse.\nЛокальные экземпляры работают в изолированной среде; интерфейс управления предоставляет Dashboard.\n\nMIT License';

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
  String get debugSystem => 'Система';

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
  String get logsSoft => 'Логи приложения';

  @override
  String get logsProcess => 'Журнал процесса';

  @override
  String get logsSearch => 'Поиск';

  @override
  String get logsFilterModule => 'Модуль';

  @override
  String get logsFilteredEmpty =>
      'Нет журналов, соответствующих текущим фильтрам';

  @override
  String get logsProcessEmptyTitle => 'Журнал процесса пока пуст';

  @override
  String get logsProcessEmptySubtitle =>
      'Необработанный вывод процесса (stdout/stderr) появится здесь в реальном времени';

  @override
  String get logsSortNewestTop => 'Новые сверху';

  @override
  String get logsSortNewestBottom => 'Новые снизу';

  @override
  String logsCopiedLines(Object count) {
    return 'Скопировано строк журнала: $count';
  }

  @override
  String get logsFilter => 'Фильтр по уровню';

  @override
  String get logsFilterAll => 'Все';

  @override
  String get logsDownload => 'Скачать лог';

  @override
  String logsDownloaded(Object path) {
    return 'Сохранено в $path';
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

  @override
  String get detailTabLifecycle => 'Жизненный цикл';

  @override
  String get detailTabCommands => 'Команды';

  @override
  String get detailTabBots => 'Боты';

  @override
  String get botsTitle => 'Боты';

  @override
  String get botsEmpty => 'Нет ботов';

  @override
  String get botsNeverActive => 'Не активен';

  @override
  String get botsJustNow => 'Только что';

  @override
  String get botsMinutesAgo => 'мин назад';

  @override
  String get botsHoursAgo => 'ч назад';

  @override
  String get botsDaysAgo => 'дн. назад';

  @override
  String get lifecycleFilterType => 'Тип';

  @override
  String get lifecycleFilteredEmpty => 'Нет событий по фильтру';

  @override
  String get lifecycleEmpty => 'Нет событий жизненного цикла';

  @override
  String get statsTitle => 'Статистика сообщений';

  @override
  String get statsTotalEvents => 'Всего событий';

  @override
  String get statsByType => 'По типу';

  @override
  String get statsByPlatform => 'По платформе';

  @override
  String get statsTrend => 'Тренд за 24 часа';

  @override
  String get commandsTitle => 'Управление командами';

  @override
  String get commandsGlobalSettings => 'Глобальные настройки';

  @override
  String get commandsPrefix => 'Префикс команд';

  @override
  String get commandsSave => 'Сохранить';

  @override
  String get commandsCaseSensitive => 'Префикс чувствителен к регистру';

  @override
  String get commandsAllowSpacePrefix => 'Разрешить префикс с пробелом';

  @override
  String get commandsMustAtBot => 'Требовать упоминание бота';

  @override
  String get commandsEmpty => 'Нет команд';

  @override
  String get commandsEditTitle => 'Редактировать команду';

  @override
  String get commandsEnabled => 'Включена';

  @override
  String get commandsAliases => 'Псевдонимы (через запятую)';

  @override
  String get commandsAllowedPlatforms =>
      'Разрешённые платформы (через запятую)';

  @override
  String get commandsBlockedPlatforms =>
      'Запрещённые платформы (через запятую)';

  @override
  String get commandsTransformTo => 'Преобразовать в (пусто — нет)';

  @override
  String get commandsSaved => 'Сохранено';

  @override
  String get commandsEdit => 'Изменить';

  @override
  String get eventsBuilderView => 'Просмотр';

  @override
  String get eventsBuilderTab => 'Конструктор';

  @override
  String get eventsBuilderSubmitted => 'Событие отправлено';

  @override
  String get eventsBuilderFailed => 'Ошибка отправки';

  @override
  String get eventsBuilderType => 'Тип события';

  @override
  String get eventsBuilderDetailType => 'Подтип';

  @override
  String get eventsBuilderPlatform => 'Платформа';

  @override
  String get eventsBuilderCustom => 'Своя';

  @override
  String get eventsBuilderBot => 'Бот';

  @override
  String get eventsBuilderSessionType => 'Тип сессии';

  @override
  String get eventsBuilderSessionId => 'ID сессии';

  @override
  String get eventsBuilderSegments => 'Сегменты сообщения';

  @override
  String get eventsBuilderAddSegment => 'Добавить сегмент';

  @override
  String get eventsBuilderOptional => 'Необязательные поля';

  @override
  String get eventsBuilderAddField => 'Добавить поле';

  @override
  String get eventsBuilderPreview => 'Предпросмотр JSON';

  @override
  String get eventsBuilderCopyJson => 'Копировать JSON';

  @override
  String get eventsBuilderCopied => 'Скопировано';

  @override
  String get eventsBuilderSubmit => 'Отправить событие';
}
