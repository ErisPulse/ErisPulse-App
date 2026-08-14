// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ErisPulse';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSoftRestart => 'Soft restart';

  @override
  String get commonHardRestart => 'Restart process';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonStart => 'Start';

  @override
  String get commonStop => 'Stop';

  @override
  String get commonRestart => 'Restart';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopyAll => 'Copy all';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonInitialize => 'Initialize';

  @override
  String get commonInstalled => 'Installed';

  @override
  String get commonPreRelease => 'Pre-release';

  @override
  String get railInstances => 'Instances';

  @override
  String get commonRemote => 'Remote';

  @override
  String get commonLocal => 'Local';

  @override
  String get commonCreateInstance => 'Create instance';

  @override
  String get commonDeleteInstance => 'Delete instance';

  @override
  String get commonRename => 'Rename';

  @override
  String get commonViewLogs => 'View logs';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get statusStarting => 'Starting';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusError => 'Error';

  @override
  String get statusDestroying => 'Destroying';

  @override
  String get statusHealthy => 'Healthy';

  @override
  String get statusBooting => 'Starting';

  @override
  String get statusTokenInvalid => 'Invalid token';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusUnknown => 'Not checked';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusConnecting => 'Connecting';

  @override
  String get statusRemoteUnknown => 'Unknown';

  @override
  String get homeDebugTooltip => 'Debug log';

  @override
  String get homeEmptyTitle => 'No instances yet';

  @override
  String get homeEmptySubtitle =>
      'Create your first ErisPulse instance\nEach instance is an independent bot';

  @override
  String homeDeleteConfirmContent(Object name) {
    return 'Delete \"$name\"?\nThe instance working directory will be kept; only metadata is removed.';
  }

  @override
  String get homeBannerTitle => 'Runtime not ready';

  @override
  String get homeBannerInitializing => 'Initializing…';

  @override
  String get homeBannerNeedDownload =>
      'A runtime image needs to be downloaded and extracted';

  @override
  String get onboardingTitle => 'Prepare runtime';

  @override
  String get onboardingDescription =>
      'The first launch needs to prepare the runtime environment\n(Python + ErisPulse)';

  @override
  String get onboardingStartButton => 'Start initialization';

  @override
  String get onboardingTapHint =>
      'Tap anywhere to switch between Progress / Log views';

  @override
  String get onboardingProcessing => 'Processing…';

  @override
  String get onboardingLogTitle => 'Initialization log';

  @override
  String get onboardingStartingLog => 'Starting runtime initialization…';

  @override
  String get onboardingReadyLog => 'Runtime ready ✓';

  @override
  String onboardingErrorLog(Object msg) {
    return 'Error: $msg';
  }

  @override
  String get onboardingSdkTitle => 'Install ErisPulse SDK';

  @override
  String onboardingSdkPythonMissing(Object path) {
    return 'Bundled Python not found: $path';
  }

  @override
  String onboardingSdkInstalled(Object version) {
    return 'ErisPulse $version installed';
  }

  @override
  String get onboardingSdkChooseVersion => 'Choose version to install';

  @override
  String get onboardingSdkInstall => 'Install';

  @override
  String get onboardingSdkUseInstalled => 'Use installed version';

  @override
  String get onboardingSdkInstalling => 'Installing…';

  @override
  String get onboardingSdkVersionFailed =>
      'Failed to fetch versions, check network';

  @override
  String get onboardingSdkRefresh => 'Refresh';

  @override
  String get onboardingSdkContinue => 'Continue';

  @override
  String get onboardingPythonRelease => 'Release bundled Python';

  @override
  String get onboardingPythonReleasing => 'Releasing Python environment…';

  @override
  String get onboardingPythonReady => 'ready';

  @override
  String get onboardingPythonIntro =>
      'The app bundles a Python environment. Release it to start.';

  @override
  String get onboardingPythonFailed =>
      'Failed to release the bundled Python. Please retry.';

  @override
  String get homeBannerNeedSdk => 'ErisPulse SDK needs to be installed';

  @override
  String get createTitle => 'Create an ErisPulse instance';

  @override
  String get createSubtitle =>
      'A local instance runs independently on this phone;\na remote instance connects to an instance deployed on another host.';

  @override
  String get createNameLabel => 'Instance name *';

  @override
  String get createNameHint => 'e.g. My bot';

  @override
  String get createNameHelper => 'Used to distinguish instances in the list';

  @override
  String get createNameRequired => 'Name is required';

  @override
  String get createNameTooLong => 'Name too long (max 24 chars)';

  @override
  String get createUrlLabel => 'Dashboard URL *';

  @override
  String get createUrlHelper => 'Base URL of the remote Dashboard';

  @override
  String get createUrlRequired => 'URL is required';

  @override
  String get createUrlScheme => 'Must start with http:// or https://';

  @override
  String get createTokenLabel => 'Access token (optional)';

  @override
  String get createTokenHelper =>
      'Token of the remote Dashboard, used for health check and login';

  @override
  String get createRuntimeLabel => 'Runtime version';

  @override
  String get createRuntimeDefault => 'Global default';

  @override
  String get createSdkVersionLabel => 'ErisPulse SDK version';

  @override
  String get createSdkVersionHelper =>
      'Installed into this instance\'s own virtual environment';

  @override
  String get createEnvTitle => 'Environment source';

  @override
  String get createEnvFresh => 'Fresh environment';

  @override
  String get createEnvFreshDesc =>
      'Create a new venv with the selected SDK version';

  @override
  String get createEnvClone => 'Based on existing instance';

  @override
  String get createEnvCloneDesc =>
      'Copy an existing instance\'s venv (SDK version + installed packages)';

  @override
  String get createEnvCloneSource => 'Source instance';

  @override
  String get createEnvCloneNeedSource => 'Please select a source instance';

  @override
  String get createPreparingEnv => 'Preparing environment';

  @override
  String get createEnvReady => 'Environment ready';

  @override
  String get createEnvFailed => 'Environment preparation failed';

  @override
  String get createEnvCopying => 'Copying source instance environment (venv)…';

  @override
  String createEnvCopyProgress(Object done, Object total) {
    return 'Copied $done / $total files';
  }

  @override
  String get createEnvPleaseWait =>
      'Preparing environment. This may take a moment. Please do not close the window.';

  @override
  String get createPortLabel => 'Listen port *';

  @override
  String get createPortHelper =>
      'Each instance uses its own port; auto-assigned by default';

  @override
  String get createPortRequired => 'Port is required';

  @override
  String get createPortRange => 'Port must be 1024-65535';

  @override
  String get createRemoteNote =>
      'The remote instance runs on the remote host; the app views and manages it through its Dashboard.';

  @override
  String get createLocalNote =>
      'The instance is created in the \"Stopped\" state; you can start it on the detail page.';

  @override
  String createCreated(Object name) {
    return 'Instance \"$name\" created';
  }

  @override
  String get createFailed => 'Creation failed';

  @override
  String get createFailedRetry => 'Creation failed, please retry';

  @override
  String get detailSystemResource => 'System resource';

  @override
  String get detailResourceHint =>
      'Dashboard system resource shown after the instance starts';

  @override
  String get detailMemory => 'Memory';

  @override
  String get detailUptime => 'Uptime';

  @override
  String get detailThreads => 'Threads';

  @override
  String get detailCores => 'Cores';

  @override
  String get detailAddress => 'Address';

  @override
  String get detailPort => 'Port';

  @override
  String get detailRuntimeLabel => 'Runtime';

  @override
  String get detailTapToReveal => 'Tap to reveal and copy';

  @override
  String get detailTokenCopied => 'Access token copied';

  @override
  String get detailRefreshState => 'Refresh status';

  @override
  String get detailNotFound => 'Instance not found';

  @override
  String get detailRecentEvents => 'Recent events';

  @override
  String get detailNoEvents =>
      'No events yet; framework/adapter events will be recorded after the instance starts';

  @override
  String get detailOpenDashboard => 'Open Dashboard';

  @override
  String get detailTabOverview => 'Overview';

  @override
  String get detailTabModules => 'Modules';

  @override
  String get detailTabAdapters => 'Adapters';

  @override
  String get detailTabConfig => 'Config';

  @override
  String get detailTabFiles => 'Files';

  @override
  String get detailTabLogs => 'Logs';

  @override
  String get detailTabPackages => 'Packages';

  @override
  String get detailTabEvents => 'Events';

  @override
  String get detailTabAudit => 'Audit';

  @override
  String get eventsFilterType => 'Type';

  @override
  String get auditTitle => 'Audit log';

  @override
  String get auditEmpty => 'No audit logs';

  @override
  String get detailTabEmpty => 'No items';

  @override
  String get detailClearLogs => 'Clear logs';

  @override
  String get detailAuthInvalid =>
      'Access token invalid or expired. Check the instance token.';

  @override
  String get detailConfigSource => 'Source';

  @override
  String get detailConfigEdit => 'Edit';

  @override
  String get detailConfigSaved => 'Config saved';

  @override
  String get detailPackageInstalled => 'Installed packages';

  @override
  String get schemaConfigSave => 'Save';

  @override
  String get schemaConfigSaved => 'Config saved';

  @override
  String get schemaConfigNoSchema => 'No config schema';

  @override
  String get adapterConfigGlobal => 'Global Settings';

  @override
  String get adapterConfigAccounts => 'Bot Accounts';

  @override
  String get adapterConfigAccountAdd => 'Add Account';

  @override
  String get adapterConfigAccountName => 'Account Name';

  @override
  String get adapterConfigAccountNameRequired => 'Enter an account name';

  @override
  String get adapterConfigAccountDelete => 'Delete Account';

  @override
  String adapterConfigAccountDeleteConfirm(String name) {
    return 'Delete account $name? This cannot be undone.';
  }

  @override
  String get adapterConfigAccountsEmpty => 'No bot accounts';

  @override
  String get adapterConfigAccountSaved => 'Account saved';

  @override
  String get adapterConfigAccountAdded => 'Account created';

  @override
  String get adapterConfigAccountDeleted => 'Account deleted';

  @override
  String get adapterConfigEnabled => 'Enabled';

  @override
  String get detailConfigCopied => 'Config copied';

  @override
  String get detailPackageName => 'Package name';

  @override
  String get detailPackageInstall => 'Install package';

  @override
  String get detailPackageUninstall => 'Uninstall package';

  @override
  String detailPackageUninstallConfirm(Object name) {
    return 'Uninstall $name?';
  }

  @override
  String get detailFrameworkUpdate => 'Update framework';

  @override
  String get detailFrameworkUpdateConfirm =>
      'Update framework to the latest version?';

  @override
  String get detailFrameworkLatest => 'up to date';

  @override
  String get detailSdkRestart => 'Restart SDK';

  @override
  String get detailSdkRestartConfirm =>
      'Restart SDK now? All connections will be interrupted.';

  @override
  String get detailFileSave => 'Save';

  @override
  String get detailFileSaved => 'Saved';

  @override
  String detailFileDeleteConfirm(Object name) {
    return 'Delete $name?';
  }

  @override
  String get detailStartingToast => 'Starting…';

  @override
  String get detailStoppedToast => 'Stop requested';

  @override
  String get detailRestartingToast => 'Restarting…';

  @override
  String get detailUnreachableError =>
      'Instance not running or Dashboard unreachable';

  @override
  String get detailOverview => 'Overview';

  @override
  String get detailModules => 'Modules';

  @override
  String get detailAdapters => 'Adapters';

  @override
  String detailEnabledCount(Object count) {
    return '$count enabled';
  }

  @override
  String detailRunningCount(Object count) {
    return '$count running';
  }

  @override
  String dashboardLoadFailed(Object code) {
    return 'Load failed ($code)';
  }

  @override
  String get dashboardAccessKey => 'Access Key';

  @override
  String get dashboardAccessKeyCopied => 'Access key copied';

  @override
  String get dashboardTokenCopied =>
      'Access token copied; paste it into the login page';

  @override
  String get dashboardExternalFailed => 'Cannot open external browser';

  @override
  String get dashboardCopyTokenTooltip => 'Copy access token';

  @override
  String get dashboardExternalOpen => 'Open in external browser';

  @override
  String get dashboardCheckHint =>
      'Make sure the instance is running and this address is reachable';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'Follow system';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLangSystem => 'Follow system';

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
  String get settingsDownloadSource => 'Download source';

  @override
  String get settingsDownloadGithub => 'GitHub official';

  @override
  String get settingsDownloadGhfast => 'GitHub mirror (ghfast.top)';

  @override
  String get settingsDownloadGhproxy => 'GitHub mirror (gh-proxy.com)';

  @override
  String get settingsPypiSource => 'PyPI mirror';

  @override
  String get settingsPypiOfficial => 'PyPI official';

  @override
  String get settingsPypiTsinghua => 'Tsinghua mirror';

  @override
  String get settingsPypiAliyun => 'Aliyun mirror';

  @override
  String get settingsRuntime => 'Runtime';

  @override
  String get settingsRootfsTitle => 'Runtime environment (rootfs)';

  @override
  String settingsRuntimeReady(Object version) {
    return 'Bundled Python + ErisPulse $version';
  }

  @override
  String get settingsRuntimeVersion => 'Runtime version';

  @override
  String get settingsRuntimeDownload => 'Download runtime';

  @override
  String get runtimeManagerTitle => 'Runtime Manager';

  @override
  String get runtimeManagerInstalled => 'Installed runtimes';

  @override
  String get runtimeManagerAvailable => 'Available versions';

  @override
  String get runtimeManagerEmpty => 'No runtimes installed';

  @override
  String get runtimeManagerLoading => 'Fetching versions…';

  @override
  String get runtimeManagerActivate => 'Activate';

  @override
  String get runtimeManagerActive => 'Active';

  @override
  String get runtimeManagerPath => 'Runtime directory';

  @override
  String runtimeManagerDeleteConfirm(Object version) {
    return 'Delete runtime v$version? This cannot be undone.';
  }

  @override
  String get runtimeManagerDesc => 'Bundled Python & per-instance environments';

  @override
  String get runtimeManagerInstances => 'Instance environments';

  @override
  String get runtimeManagerPythonMissing => 'Bundled Python not ready';

  @override
  String get settingsOpenSource => 'Open source';

  @override
  String get settingsRootfsReady => 'Ready';

  @override
  String get settingsRootfsNotReady => 'Not ready';

  @override
  String get settingsAutoRestart => 'Auto-restart on crash';

  @override
  String get settingsAutoRestartDesc =>
      'Restart the instance automatically after abnormal exit';

  @override
  String get settingsStopAll => 'Stop all instances';

  @override
  String get settingsStopAllDesc => 'Shut down all local instance processes';

  @override
  String get settingsStopAllConfirm => 'Stop all running local instances?';

  @override
  String get settingsStopAllAction => 'Stop all';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsClearLogs => 'Clear debug log';

  @override
  String get settingsClearLogsDesc => 'Clear runtime debug logs';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsAboutApp => 'About ErisPulse-App';

  @override
  String get settingsAboutSubtitle =>
      'Multi-device management client (launcher + Dashboard)';

  @override
  String get settingsAboutDialog =>
      'ErisPulse multi-device management client.\nLocal instances run in their own isolated environment; the management UI is provided by Dashboard.\n\nMIT License';

  @override
  String get debugTitle => 'Debug info';

  @override
  String get debugCopyAllTooltip => 'Copy all';

  @override
  String get debugClearLogsTooltip => 'Clear log';

  @override
  String get debugCopiedAll => 'Full debug info copied';

  @override
  String get debugCopiedLogs => 'Log copied';

  @override
  String get debugAppVersion => 'App version';

  @override
  String get debugPackageName => 'Package';

  @override
  String get debugDeviceModel => 'Device model';

  @override
  String get debugBrand => 'Brand';

  @override
  String get debugAndroid => 'Android';

  @override
  String get debugAbi => 'ABI';

  @override
  String get debugSystem => 'System';

  @override
  String get debugNativeLib => 'native lib';

  @override
  String get debugRootfs => 'rootfs';

  @override
  String get debugRootfsError => 'rootfs error';

  @override
  String get debugInstanceCount => 'Instance count';

  @override
  String get debugInfoHeader => '== ErisPulse-App Debug Info ==';

  @override
  String get debugReady => 'Ready';

  @override
  String get debugNotReady => 'Not ready';

  @override
  String get debugRootfsMessage => 'rootfs message';

  @override
  String get debugLogHeader => '== Log ==';

  @override
  String get debugNoLogs =>
      'No log yet\nOnce an instance is started, proot process output will appear here in real time';

  @override
  String get debugProcessLogs => 'Process log';

  @override
  String get logsSoft => 'App logs';

  @override
  String get logsProcess => 'Process logs';

  @override
  String get logsSearch => 'Search';

  @override
  String get logsFilterModule => 'Module';

  @override
  String get logsFilteredEmpty => 'No logs match the current filters';

  @override
  String get logsProcessEmptyTitle => 'No process logs yet';

  @override
  String get logsProcessEmptySubtitle =>
      'Raw process output (stdout/stderr) will appear here in real time';

  @override
  String get logsSortNewestTop => 'Newest on top';

  @override
  String get logsSortNewestBottom => 'Newest on bottom';

  @override
  String logsCopiedLines(Object count) {
    return 'Copied $count lines of log';
  }

  @override
  String get logsFilter => 'Filter by level';

  @override
  String get logsFilterAll => 'All';

  @override
  String get logsDownload => 'Download log';

  @override
  String logsDownloaded(Object path) {
    return 'Saved to $path';
  }

  @override
  String get logsResume => 'Resume';

  @override
  String get logsPause => 'Pause';

  @override
  String get logsAutoScroll => 'Auto scroll';

  @override
  String logsLineCount(Object count) {
    return '$count lines';
  }

  @override
  String get logsEmptyTitle => 'No log';

  @override
  String get logsEmptySubtitle =>
      'Once an instance is started, raw process output will appear here in real time';

  @override
  String get detailTabLifecycle => 'Lifecycle';

  @override
  String get detailTabCommands => 'Commands';

  @override
  String get detailTabBots => 'Bots';

  @override
  String get botsTitle => 'Bots';

  @override
  String get botsEmpty => 'No bots';

  @override
  String get botsNeverActive => 'Never active';

  @override
  String get botsJustNow => 'Just now';

  @override
  String get botsMinutesAgo => 'min ago';

  @override
  String get botsHoursAgo => 'h ago';

  @override
  String get botsDaysAgo => 'd ago';

  @override
  String get lifecycleFilterType => 'Type';

  @override
  String get lifecycleFilteredEmpty => 'No events match the filter';

  @override
  String get lifecycleEmpty => 'No lifecycle events';

  @override
  String get statsTitle => 'Message stats';

  @override
  String get statsTotalEvents => 'Total events';

  @override
  String get statsByType => 'By type';

  @override
  String get statsByPlatform => 'By platform';

  @override
  String get statsTrend => 'Last 24h trend';

  @override
  String get commandsTitle => 'Commands';

  @override
  String get commandsGlobalSettings => 'Global settings';

  @override
  String get commandsPrefix => 'Command prefix';

  @override
  String get commandsSave => 'Save';

  @override
  String get commandsCaseSensitive => 'Case-sensitive prefix';

  @override
  String get commandsAllowSpacePrefix => 'Allow space prefix';

  @override
  String get commandsMustAtBot => 'Must mention bot';

  @override
  String get commandsEmpty => 'No commands';

  @override
  String get commandsEditTitle => 'Edit command';

  @override
  String get commandsEnabled => 'Enabled';

  @override
  String get commandsAliases => 'Aliases (comma separated)';

  @override
  String get commandsAllowedPlatforms => 'Allowed platforms (comma separated)';

  @override
  String get commandsBlockedPlatforms => 'Blocked platforms (comma separated)';

  @override
  String get commandsTransformTo => 'Transform to (empty = none)';

  @override
  String get commandsSaved => 'Saved';

  @override
  String get commandsEdit => 'Edit';

  @override
  String get eventsBuilderView => 'View';

  @override
  String get eventsBuilderTab => 'Builder';

  @override
  String get eventsBuilderSubmitted => 'Event submitted';

  @override
  String get eventsBuilderFailed => 'Submit failed';

  @override
  String get eventsBuilderType => 'Event type';

  @override
  String get eventsBuilderDetailType => 'Detail type';

  @override
  String get eventsBuilderPlatform => 'Platform';

  @override
  String get eventsBuilderCustom => 'Custom';

  @override
  String get eventsBuilderBot => 'Bot';

  @override
  String get eventsBuilderSessionType => 'Session type';

  @override
  String get eventsBuilderSessionId => 'Session ID';

  @override
  String get eventsBuilderSegments => 'Message segments';

  @override
  String get eventsBuilderAddSegment => 'Add segment';

  @override
  String get eventsBuilderOptional => 'Optional fields';

  @override
  String get eventsBuilderAddField => 'Add field';

  @override
  String get eventsBuilderPreview => 'JSON preview';

  @override
  String get eventsBuilderCopyJson => 'Copy JSON';

  @override
  String get eventsBuilderCopied => 'Copied';

  @override
  String get eventsBuilderSubmit => 'Submit event';

  @override
  String get navGroupOverview => 'Overview';

  @override
  String get navGroupEvents => 'Events';

  @override
  String get navGroupExtensions => 'Extensions';

  @override
  String get navGroupManagement => 'Management';

  @override
  String get navGroupOperations => 'Operations';

  @override
  String get detailTabStore => 'Module Store';

  @override
  String get detailTabMonitor => 'Monitor';

  @override
  String get storeBrowseTab => 'Store';

  @override
  String get storePackagesTab => 'Packages';

  @override
  String get storeSearch => 'Search modules, adapters…';

  @override
  String get storeTypeAll => 'All';

  @override
  String get storeTypeModule => 'Module';

  @override
  String get storeTypeAdapter => 'Adapter';

  @override
  String get storeForceRefresh => 'Force refresh';

  @override
  String get storeInstalled => 'Installed';

  @override
  String get storeUpdateAvailable => 'Update available';

  @override
  String get storeUpgrade => 'Upgrade';

  @override
  String get storeOfficial => 'Official';

  @override
  String get storeDetail => 'Details';

  @override
  String get storeAuthor => 'Author';

  @override
  String get storeLicense => 'License';

  @override
  String get storeHomepage => 'Homepage';

  @override
  String get storeRequires => 'Dependencies';

  @override
  String get storeVersions => 'Versions';

  @override
  String get storeVersionInstall => 'Install this version';

  @override
  String get storeEmpty => 'Store is empty';

  @override
  String get storeFilteredEmpty => 'No matching packages';

  @override
  String get storeMirror => 'pip index mirror (optional)';

  @override
  String get storeForce => 'Force reinstall';

  @override
  String get storeTaskRunning => 'Task running…';

  @override
  String get storeTaskSuccess => 'Task finished';

  @override
  String get storeTaskFailed => 'Task failed';

  @override
  String get storeCurrent => 'Current';

  @override
  String get storeLatest => 'Latest';

  @override
  String get pkgInstalledTab => 'Installed';

  @override
  String get pkgUpdatesTab => 'Updates';

  @override
  String get pkgInstallNewTab => 'Install new';

  @override
  String get pkgGitTab => 'Git';

  @override
  String get pkgUpgradeAll => 'Upgrade all';

  @override
  String get pkgNoUpdates => 'No updates available';

  @override
  String get pkgNoGit => 'No Git packages';
}
