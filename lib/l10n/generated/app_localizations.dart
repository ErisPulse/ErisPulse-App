import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ru'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ErisPulse'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonSoftRestart.
  ///
  /// In en, this message translates to:
  /// **'Soft restart'**
  String get commonSoftRestart;

  /// No description provided for @commonHardRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart process'**
  String get commonHardRestart;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get commonStart;

  /// No description provided for @commonStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get commonStop;

  /// No description provided for @commonRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get commonRestart;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonCopyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get commonCopyAll;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonInitialize.
  ///
  /// In en, this message translates to:
  /// **'Initialize'**
  String get commonInitialize;

  /// No description provided for @commonInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get commonInstalled;

  /// No description provided for @commonPreRelease.
  ///
  /// In en, this message translates to:
  /// **'Pre-release'**
  String get commonPreRelease;

  /// No description provided for @railInstances.
  ///
  /// In en, this message translates to:
  /// **'Instances'**
  String get railInstances;

  /// No description provided for @commonRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get commonRemote;

  /// No description provided for @commonLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get commonLocal;

  /// No description provided for @commonCreateInstance.
  ///
  /// In en, this message translates to:
  /// **'Create instance'**
  String get commonCreateInstance;

  /// No description provided for @commonDeleteInstance.
  ///
  /// In en, this message translates to:
  /// **'Delete instance'**
  String get commonDeleteInstance;

  /// No description provided for @commonRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get commonRename;

  /// No description provided for @commonViewLogs.
  ///
  /// In en, this message translates to:
  /// **'View logs'**
  String get commonViewLogs;

  /// No description provided for @statusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusStopped;

  /// No description provided for @statusStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get statusStarting;

  /// No description provided for @statusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// No description provided for @statusDestroying.
  ///
  /// In en, this message translates to:
  /// **'Destroying'**
  String get statusDestroying;

  /// No description provided for @statusHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get statusHealthy;

  /// No description provided for @statusBooting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get statusBooting;

  /// No description provided for @statusTokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid token'**
  String get statusTokenInvalid;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not checked'**
  String get statusUnknown;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get statusConnecting;

  /// No description provided for @statusRemoteUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusRemoteUnknown;

  /// No description provided for @homeDebugTooltip.
  ///
  /// In en, this message translates to:
  /// **'Debug log'**
  String get homeDebugTooltip;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No instances yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first ErisPulse instance\nEach instance is an independent bot'**
  String get homeEmptySubtitle;

  /// No description provided for @homeDeleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?\nThe instance working directory will be kept; only metadata is removed.'**
  String homeDeleteConfirmContent(Object name);

  /// No description provided for @homeBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime not ready'**
  String get homeBannerTitle;

  /// No description provided for @homeBannerInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing…'**
  String get homeBannerInitializing;

  /// No description provided for @homeBannerNeedDownload.
  ///
  /// In en, this message translates to:
  /// **'A runtime image needs to be downloaded and extracted'**
  String get homeBannerNeedDownload;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare runtime'**
  String get onboardingTitle;

  /// No description provided for @onboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'The first launch needs to prepare the runtime environment\n(Python + ErisPulse)'**
  String get onboardingDescription;

  /// No description provided for @onboardingStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start initialization'**
  String get onboardingStartButton;

  /// No description provided for @onboardingTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to switch between Progress / Log views'**
  String get onboardingTapHint;

  /// No description provided for @onboardingProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get onboardingProcessing;

  /// No description provided for @onboardingLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Initialization log'**
  String get onboardingLogTitle;

  /// No description provided for @onboardingStartingLog.
  ///
  /// In en, this message translates to:
  /// **'Starting runtime initialization…'**
  String get onboardingStartingLog;

  /// No description provided for @onboardingReadyLog.
  ///
  /// In en, this message translates to:
  /// **'Runtime ready ✓'**
  String get onboardingReadyLog;

  /// No description provided for @onboardingErrorLog.
  ///
  /// In en, this message translates to:
  /// **'Error: {msg}'**
  String onboardingErrorLog(Object msg);

  /// No description provided for @onboardingSdkTitle.
  ///
  /// In en, this message translates to:
  /// **'Install ErisPulse SDK'**
  String get onboardingSdkTitle;

  /// No description provided for @onboardingSdkPythonMissing.
  ///
  /// In en, this message translates to:
  /// **'Bundled Python not found: {path}'**
  String onboardingSdkPythonMissing(Object path);

  /// No description provided for @onboardingSdkInstalled.
  ///
  /// In en, this message translates to:
  /// **'ErisPulse {version} installed'**
  String onboardingSdkInstalled(Object version);

  /// No description provided for @onboardingSdkChooseVersion.
  ///
  /// In en, this message translates to:
  /// **'Choose version to install'**
  String get onboardingSdkChooseVersion;

  /// No description provided for @onboardingSdkInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get onboardingSdkInstall;

  /// No description provided for @onboardingSdkUseInstalled.
  ///
  /// In en, this message translates to:
  /// **'Use installed version'**
  String get onboardingSdkUseInstalled;

  /// No description provided for @onboardingSdkInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get onboardingSdkInstalling;

  /// No description provided for @onboardingSdkVersionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch versions, check network'**
  String get onboardingSdkVersionFailed;

  /// No description provided for @onboardingSdkRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get onboardingSdkRefresh;

  /// No description provided for @onboardingSdkContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingSdkContinue;

  /// No description provided for @onboardingPythonRelease.
  ///
  /// In en, this message translates to:
  /// **'Release bundled Python'**
  String get onboardingPythonRelease;

  /// No description provided for @onboardingPythonReleasing.
  ///
  /// In en, this message translates to:
  /// **'Releasing Python environment…'**
  String get onboardingPythonReleasing;

  /// No description provided for @onboardingPythonReady.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get onboardingPythonReady;

  /// No description provided for @onboardingPythonIntro.
  ///
  /// In en, this message translates to:
  /// **'The app bundles a Python environment. Release it to start.'**
  String get onboardingPythonIntro;

  /// No description provided for @onboardingPythonFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to release the bundled Python. Please retry.'**
  String get onboardingPythonFailed;

  /// No description provided for @homeBannerNeedSdk.
  ///
  /// In en, this message translates to:
  /// **'ErisPulse SDK needs to be installed'**
  String get homeBannerNeedSdk;

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an ErisPulse instance'**
  String get createTitle;

  /// No description provided for @createSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A local instance runs independently on this phone;\na remote instance connects to an instance deployed on another host.'**
  String get createSubtitle;

  /// No description provided for @createNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Instance name *'**
  String get createNameLabel;

  /// No description provided for @createNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My bot'**
  String get createNameHint;

  /// No description provided for @createNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Used to distinguish instances in the list'**
  String get createNameHelper;

  /// No description provided for @createNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get createNameRequired;

  /// No description provided for @createNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name too long (max 24 chars)'**
  String get createNameTooLong;

  /// No description provided for @createUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard URL *'**
  String get createUrlLabel;

  /// No description provided for @createUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Base URL of the remote Dashboard'**
  String get createUrlHelper;

  /// No description provided for @createUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'URL is required'**
  String get createUrlRequired;

  /// No description provided for @createUrlScheme.
  ///
  /// In en, this message translates to:
  /// **'Must start with http:// or https://'**
  String get createUrlScheme;

  /// No description provided for @createTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Access token (optional)'**
  String get createTokenLabel;

  /// No description provided for @createTokenHelper.
  ///
  /// In en, this message translates to:
  /// **'Token of the remote Dashboard, used for health check and login'**
  String get createTokenHelper;

  /// No description provided for @createRuntimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Runtime version'**
  String get createRuntimeLabel;

  /// No description provided for @createRuntimeDefault.
  ///
  /// In en, this message translates to:
  /// **'Global default'**
  String get createRuntimeDefault;

  /// No description provided for @createSdkVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'ErisPulse SDK version'**
  String get createSdkVersionLabel;

  /// No description provided for @createSdkVersionHelper.
  ///
  /// In en, this message translates to:
  /// **'Installed into this instance\'s own virtual environment'**
  String get createSdkVersionHelper;

  /// No description provided for @createEnvTitle.
  ///
  /// In en, this message translates to:
  /// **'Environment source'**
  String get createEnvTitle;

  /// No description provided for @createEnvFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh environment'**
  String get createEnvFresh;

  /// No description provided for @createEnvFreshDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new venv with the selected SDK version'**
  String get createEnvFreshDesc;

  /// No description provided for @createEnvClone.
  ///
  /// In en, this message translates to:
  /// **'Based on existing instance'**
  String get createEnvClone;

  /// No description provided for @createEnvCloneDesc.
  ///
  /// In en, this message translates to:
  /// **'Copy an existing instance\'s venv (SDK version + installed packages)'**
  String get createEnvCloneDesc;

  /// No description provided for @createEnvCloneSource.
  ///
  /// In en, this message translates to:
  /// **'Source instance'**
  String get createEnvCloneSource;

  /// No description provided for @createEnvCloneNeedSource.
  ///
  /// In en, this message translates to:
  /// **'Please select a source instance'**
  String get createEnvCloneNeedSource;

  /// No description provided for @createPreparingEnv.
  ///
  /// In en, this message translates to:
  /// **'Preparing environment'**
  String get createPreparingEnv;

  /// No description provided for @createEnvReady.
  ///
  /// In en, this message translates to:
  /// **'Environment ready'**
  String get createEnvReady;

  /// No description provided for @createEnvFailed.
  ///
  /// In en, this message translates to:
  /// **'Environment preparation failed'**
  String get createEnvFailed;

  /// No description provided for @createEnvCopying.
  ///
  /// In en, this message translates to:
  /// **'Copying source instance environment (venv)…'**
  String get createEnvCopying;

  /// No description provided for @createEnvCopyProgress.
  ///
  /// In en, this message translates to:
  /// **'Copied {done} / {total} files'**
  String createEnvCopyProgress(Object done, Object total);

  /// No description provided for @createEnvPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Preparing environment. This may take a moment. Please do not close the window.'**
  String get createEnvPleaseWait;

  /// No description provided for @createPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Listen port *'**
  String get createPortLabel;

  /// No description provided for @createPortHelper.
  ///
  /// In en, this message translates to:
  /// **'Each instance uses its own port; auto-assigned by default'**
  String get createPortHelper;

  /// No description provided for @createPortRequired.
  ///
  /// In en, this message translates to:
  /// **'Port is required'**
  String get createPortRequired;

  /// No description provided for @createPortRange.
  ///
  /// In en, this message translates to:
  /// **'Port must be 1024-65535'**
  String get createPortRange;

  /// No description provided for @createRemoteNote.
  ///
  /// In en, this message translates to:
  /// **'The remote instance runs on the remote host; the app views and manages it through its Dashboard.'**
  String get createRemoteNote;

  /// No description provided for @createLocalNote.
  ///
  /// In en, this message translates to:
  /// **'The instance is created in the \"Stopped\" state; you can start it on the detail page.'**
  String get createLocalNote;

  /// No description provided for @createCreated.
  ///
  /// In en, this message translates to:
  /// **'Instance \"{name}\" created'**
  String createCreated(Object name);

  /// No description provided for @createFailed.
  ///
  /// In en, this message translates to:
  /// **'Creation failed'**
  String get createFailed;

  /// No description provided for @createFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Creation failed, please retry'**
  String get createFailedRetry;

  /// No description provided for @detailSystemResource.
  ///
  /// In en, this message translates to:
  /// **'System resource'**
  String get detailSystemResource;

  /// No description provided for @detailResourceHint.
  ///
  /// In en, this message translates to:
  /// **'Dashboard system resource shown after the instance starts'**
  String get detailResourceHint;

  /// No description provided for @detailMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get detailMemory;

  /// No description provided for @detailUptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get detailUptime;

  /// No description provided for @detailThreads.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get detailThreads;

  /// No description provided for @detailCores.
  ///
  /// In en, this message translates to:
  /// **'Cores'**
  String get detailCores;

  /// No description provided for @detailAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get detailAddress;

  /// No description provided for @detailPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get detailPort;

  /// No description provided for @detailRuntimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get detailRuntimeLabel;

  /// No description provided for @detailTapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal and copy'**
  String get detailTapToReveal;

  /// No description provided for @detailTokenCopied.
  ///
  /// In en, this message translates to:
  /// **'Access token copied'**
  String get detailTokenCopied;

  /// No description provided for @detailRefreshState.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get detailRefreshState;

  /// No description provided for @detailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Instance not found'**
  String get detailNotFound;

  /// No description provided for @detailRecentEvents.
  ///
  /// In en, this message translates to:
  /// **'Recent events'**
  String get detailRecentEvents;

  /// No description provided for @detailNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events yet; framework/adapter events will be recorded after the instance starts'**
  String get detailNoEvents;

  /// No description provided for @detailOpenDashboard.
  ///
  /// In en, this message translates to:
  /// **'Open Dashboard'**
  String get detailOpenDashboard;

  /// No description provided for @detailTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get detailTabOverview;

  /// No description provided for @detailTabModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get detailTabModules;

  /// No description provided for @detailTabAdapters.
  ///
  /// In en, this message translates to:
  /// **'Adapters'**
  String get detailTabAdapters;

  /// No description provided for @detailTabConfig.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get detailTabConfig;

  /// No description provided for @detailTabFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get detailTabFiles;

  /// No description provided for @detailTabLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get detailTabLogs;

  /// No description provided for @detailTabPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get detailTabPackages;

  /// No description provided for @detailTabEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get detailTabEvents;

  /// No description provided for @detailTabAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get detailTabAudit;

  /// No description provided for @eventsFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get eventsFilterType;

  /// No description provided for @auditTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get auditTitle;

  /// No description provided for @auditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No audit logs'**
  String get auditEmpty;

  /// No description provided for @detailTabEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get detailTabEmpty;

  /// No description provided for @detailClearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get detailClearLogs;

  /// No description provided for @detailAuthInvalid.
  ///
  /// In en, this message translates to:
  /// **'Access token invalid or expired. Check the instance token.'**
  String get detailAuthInvalid;

  /// No description provided for @detailConfigSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get detailConfigSource;

  /// No description provided for @detailConfigEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get detailConfigEdit;

  /// No description provided for @detailConfigSaved.
  ///
  /// In en, this message translates to:
  /// **'Config saved'**
  String get detailConfigSaved;

  /// No description provided for @detailPackageInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed packages'**
  String get detailPackageInstalled;

  /// No description provided for @schemaConfigSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get schemaConfigSave;

  /// No description provided for @schemaConfigSaved.
  ///
  /// In en, this message translates to:
  /// **'Config saved'**
  String get schemaConfigSaved;

  /// No description provided for @schemaConfigNoSchema.
  ///
  /// In en, this message translates to:
  /// **'No config schema'**
  String get schemaConfigNoSchema;

  /// No description provided for @adapterConfigGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global Settings'**
  String get adapterConfigGlobal;

  /// No description provided for @adapterConfigAccounts.
  ///
  /// In en, this message translates to:
  /// **'Bot Accounts'**
  String get adapterConfigAccounts;

  /// No description provided for @adapterConfigAccountAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get adapterConfigAccountAdd;

  /// No description provided for @adapterConfigAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get adapterConfigAccountName;

  /// No description provided for @adapterConfigAccountNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an account name'**
  String get adapterConfigAccountNameRequired;

  /// No description provided for @adapterConfigAccountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get adapterConfigAccountDelete;

  /// Confirm deleting a bot account
  ///
  /// In en, this message translates to:
  /// **'Delete account {name}? This cannot be undone.'**
  String adapterConfigAccountDeleteConfirm(String name);

  /// No description provided for @adapterConfigAccountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bot accounts'**
  String get adapterConfigAccountsEmpty;

  /// No description provided for @adapterConfigAccountSaved.
  ///
  /// In en, this message translates to:
  /// **'Account saved'**
  String get adapterConfigAccountSaved;

  /// No description provided for @adapterConfigAccountAdded.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get adapterConfigAccountAdded;

  /// No description provided for @adapterConfigAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get adapterConfigAccountDeleted;

  /// No description provided for @adapterConfigEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get adapterConfigEnabled;

  /// No description provided for @detailConfigCopied.
  ///
  /// In en, this message translates to:
  /// **'Config copied'**
  String get detailConfigCopied;

  /// No description provided for @detailPackageName.
  ///
  /// In en, this message translates to:
  /// **'Package name'**
  String get detailPackageName;

  /// No description provided for @detailPackageInstall.
  ///
  /// In en, this message translates to:
  /// **'Install package'**
  String get detailPackageInstall;

  /// No description provided for @detailPackageUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall package'**
  String get detailPackageUninstall;

  /// No description provided for @detailPackageUninstallConfirm.
  ///
  /// In en, this message translates to:
  /// **'Uninstall {name}?'**
  String detailPackageUninstallConfirm(Object name);

  /// No description provided for @detailFrameworkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update framework'**
  String get detailFrameworkUpdate;

  /// No description provided for @detailFrameworkUpdateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Update framework to the latest version?'**
  String get detailFrameworkUpdateConfirm;

  /// No description provided for @detailFrameworkLatest.
  ///
  /// In en, this message translates to:
  /// **'up to date'**
  String get detailFrameworkLatest;

  /// No description provided for @detailSdkRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart SDK'**
  String get detailSdkRestart;

  /// No description provided for @detailSdkRestartConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restart SDK now? All connections will be interrupted.'**
  String get detailSdkRestartConfirm;

  /// No description provided for @detailFileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get detailFileSave;

  /// No description provided for @detailFileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get detailFileSaved;

  /// No description provided for @detailFileDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String detailFileDeleteConfirm(Object name);

  /// No description provided for @detailStartingToast.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get detailStartingToast;

  /// No description provided for @detailStoppedToast.
  ///
  /// In en, this message translates to:
  /// **'Stop requested'**
  String get detailStoppedToast;

  /// No description provided for @detailRestartingToast.
  ///
  /// In en, this message translates to:
  /// **'Restarting…'**
  String get detailRestartingToast;

  /// No description provided for @detailUnreachableError.
  ///
  /// In en, this message translates to:
  /// **'Instance not running or Dashboard unreachable'**
  String get detailUnreachableError;

  /// No description provided for @detailOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get detailOverview;

  /// No description provided for @detailModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get detailModules;

  /// No description provided for @detailAdapters.
  ///
  /// In en, this message translates to:
  /// **'Adapters'**
  String get detailAdapters;

  /// No description provided for @detailEnabledCount.
  ///
  /// In en, this message translates to:
  /// **'{count} enabled'**
  String detailEnabledCount(Object count);

  /// No description provided for @detailRunningCount.
  ///
  /// In en, this message translates to:
  /// **'{count} running'**
  String detailRunningCount(Object count);

  /// No description provided for @dashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed ({code})'**
  String dashboardLoadFailed(Object code);

  /// No description provided for @dashboardAccessKey.
  ///
  /// In en, this message translates to:
  /// **'Access Key'**
  String get dashboardAccessKey;

  /// No description provided for @dashboardAccessKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Access key copied'**
  String get dashboardAccessKeyCopied;

  /// No description provided for @dashboardTokenCopied.
  ///
  /// In en, this message translates to:
  /// **'Access token copied; paste it into the login page'**
  String get dashboardTokenCopied;

  /// No description provided for @dashboardExternalFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot open external browser'**
  String get dashboardExternalFailed;

  /// No description provided for @dashboardCopyTokenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy access token'**
  String get dashboardCopyTokenTooltip;

  /// No description provided for @dashboardExternalOpen.
  ///
  /// In en, this message translates to:
  /// **'Open in external browser'**
  String get dashboardExternalOpen;

  /// No description provided for @dashboardCheckHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure the instance is running and this address is reachable'**
  String get dashboardCheckHint;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLangSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsLangSystem;

  /// No description provided for @settingsLangZh.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get settingsLangZh;

  /// No description provided for @settingsLangZhHant.
  ///
  /// In en, this message translates to:
  /// **'繁體中文'**
  String get settingsLangZhHant;

  /// No description provided for @settingsLangEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLangEn;

  /// No description provided for @settingsLangJa.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get settingsLangJa;

  /// No description provided for @settingsLangRu.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get settingsLangRu;

  /// No description provided for @settingsDownloadSource.
  ///
  /// In en, this message translates to:
  /// **'Download source'**
  String get settingsDownloadSource;

  /// No description provided for @settingsDownloadGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub official'**
  String get settingsDownloadGithub;

  /// No description provided for @settingsDownloadGhfast.
  ///
  /// In en, this message translates to:
  /// **'GitHub mirror (ghfast.top)'**
  String get settingsDownloadGhfast;

  /// No description provided for @settingsDownloadGhproxy.
  ///
  /// In en, this message translates to:
  /// **'GitHub mirror (gh-proxy.com)'**
  String get settingsDownloadGhproxy;

  /// No description provided for @settingsPypiSource.
  ///
  /// In en, this message translates to:
  /// **'PyPI mirror'**
  String get settingsPypiSource;

  /// No description provided for @settingsPypiOfficial.
  ///
  /// In en, this message translates to:
  /// **'PyPI official'**
  String get settingsPypiOfficial;

  /// No description provided for @settingsPypiTsinghua.
  ///
  /// In en, this message translates to:
  /// **'Tsinghua mirror'**
  String get settingsPypiTsinghua;

  /// No description provided for @settingsPypiAliyun.
  ///
  /// In en, this message translates to:
  /// **'Aliyun mirror'**
  String get settingsPypiAliyun;

  /// No description provided for @settingsRuntime.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get settingsRuntime;

  /// No description provided for @settingsRootfsTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime environment (rootfs)'**
  String get settingsRootfsTitle;

  /// No description provided for @settingsRuntimeReady.
  ///
  /// In en, this message translates to:
  /// **'Bundled Python + ErisPulse {version}'**
  String settingsRuntimeReady(Object version);

  /// No description provided for @settingsRuntimeVersion.
  ///
  /// In en, this message translates to:
  /// **'Runtime version'**
  String get settingsRuntimeVersion;

  /// No description provided for @settingsRuntimeDownload.
  ///
  /// In en, this message translates to:
  /// **'Download runtime'**
  String get settingsRuntimeDownload;

  /// No description provided for @runtimeManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime Manager'**
  String get runtimeManagerTitle;

  /// No description provided for @runtimeManagerInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed runtimes'**
  String get runtimeManagerInstalled;

  /// No description provided for @runtimeManagerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available versions'**
  String get runtimeManagerAvailable;

  /// No description provided for @runtimeManagerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No runtimes installed'**
  String get runtimeManagerEmpty;

  /// No description provided for @runtimeManagerLoading.
  ///
  /// In en, this message translates to:
  /// **'Fetching versions…'**
  String get runtimeManagerLoading;

  /// No description provided for @runtimeManagerActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get runtimeManagerActivate;

  /// No description provided for @runtimeManagerActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get runtimeManagerActive;

  /// No description provided for @runtimeManagerPath.
  ///
  /// In en, this message translates to:
  /// **'Runtime directory'**
  String get runtimeManagerPath;

  /// No description provided for @runtimeManagerDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete runtime v{version}? This cannot be undone.'**
  String runtimeManagerDeleteConfirm(Object version);

  /// No description provided for @runtimeManagerDesc.
  ///
  /// In en, this message translates to:
  /// **'Bundled Python & per-instance environments'**
  String get runtimeManagerDesc;

  /// No description provided for @runtimeManagerInstances.
  ///
  /// In en, this message translates to:
  /// **'Instance environments'**
  String get runtimeManagerInstances;

  /// No description provided for @runtimeManagerPythonMissing.
  ///
  /// In en, this message translates to:
  /// **'Bundled Python not ready'**
  String get runtimeManagerPythonMissing;

  /// No description provided for @settingsOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get settingsOpenSource;

  /// No description provided for @settingsRootfsReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get settingsRootfsReady;

  /// No description provided for @settingsRootfsNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get settingsRootfsNotReady;

  /// No description provided for @settingsAutoRestart.
  ///
  /// In en, this message translates to:
  /// **'Auto-restart on crash'**
  String get settingsAutoRestart;

  /// No description provided for @settingsAutoRestartDesc.
  ///
  /// In en, this message translates to:
  /// **'Restart the instance automatically after abnormal exit'**
  String get settingsAutoRestartDesc;

  /// No description provided for @settingsStopAll.
  ///
  /// In en, this message translates to:
  /// **'Stop all instances'**
  String get settingsStopAll;

  /// No description provided for @settingsStopAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Shut down all local instance processes'**
  String get settingsStopAllDesc;

  /// No description provided for @settingsStopAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop all running local instances?'**
  String get settingsStopAllConfirm;

  /// No description provided for @settingsStopAllAction.
  ///
  /// In en, this message translates to:
  /// **'Stop all'**
  String get settingsStopAllAction;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsClearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear debug log'**
  String get settingsClearLogs;

  /// No description provided for @settingsClearLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear runtime debug logs'**
  String get settingsClearLogsDesc;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About ErisPulse-App'**
  String get settingsAboutApp;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Multi-device management client (launcher + Dashboard)'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsAboutDialog.
  ///
  /// In en, this message translates to:
  /// **'ErisPulse multi-device management client.\nLocal instances run in their own isolated environment; the management UI is provided by Dashboard.\n\nMIT License'**
  String get settingsAboutDialog;

  /// No description provided for @debugTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug info'**
  String get debugTitle;

  /// No description provided for @debugCopyAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get debugCopyAllTooltip;

  /// No description provided for @debugClearLogsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear log'**
  String get debugClearLogsTooltip;

  /// No description provided for @debugCopiedAll.
  ///
  /// In en, this message translates to:
  /// **'Full debug info copied'**
  String get debugCopiedAll;

  /// No description provided for @debugCopiedLogs.
  ///
  /// In en, this message translates to:
  /// **'Log copied'**
  String get debugCopiedLogs;

  /// No description provided for @debugAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get debugAppVersion;

  /// No description provided for @debugPackageName.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get debugPackageName;

  /// No description provided for @debugDeviceModel.
  ///
  /// In en, this message translates to:
  /// **'Device model'**
  String get debugDeviceModel;

  /// No description provided for @debugBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get debugBrand;

  /// No description provided for @debugAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get debugAndroid;

  /// No description provided for @debugAbi.
  ///
  /// In en, this message translates to:
  /// **'ABI'**
  String get debugAbi;

  /// No description provided for @debugSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get debugSystem;

  /// No description provided for @debugNativeLib.
  ///
  /// In en, this message translates to:
  /// **'native lib'**
  String get debugNativeLib;

  /// No description provided for @debugRootfs.
  ///
  /// In en, this message translates to:
  /// **'rootfs'**
  String get debugRootfs;

  /// No description provided for @debugRootfsError.
  ///
  /// In en, this message translates to:
  /// **'rootfs error'**
  String get debugRootfsError;

  /// No description provided for @debugInstanceCount.
  ///
  /// In en, this message translates to:
  /// **'Instance count'**
  String get debugInstanceCount;

  /// No description provided for @debugInfoHeader.
  ///
  /// In en, this message translates to:
  /// **'== ErisPulse-App Debug Info =='**
  String get debugInfoHeader;

  /// No description provided for @debugReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get debugReady;

  /// No description provided for @debugNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get debugNotReady;

  /// No description provided for @debugRootfsMessage.
  ///
  /// In en, this message translates to:
  /// **'rootfs message'**
  String get debugRootfsMessage;

  /// No description provided for @debugLogHeader.
  ///
  /// In en, this message translates to:
  /// **'== Log =='**
  String get debugLogHeader;

  /// No description provided for @debugNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No log yet\nOnce an instance is started, proot process output will appear here in real time'**
  String get debugNoLogs;

  /// No description provided for @debugProcessLogs.
  ///
  /// In en, this message translates to:
  /// **'Process log'**
  String get debugProcessLogs;

  /// No description provided for @logsSoft.
  ///
  /// In en, this message translates to:
  /// **'App logs'**
  String get logsSoft;

  /// No description provided for @logsProcess.
  ///
  /// In en, this message translates to:
  /// **'Process logs'**
  String get logsProcess;

  /// No description provided for @logsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get logsSearch;

  /// No description provided for @logsFilterModule.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get logsFilterModule;

  /// No description provided for @logsFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logs match the current filters'**
  String get logsFilteredEmpty;

  /// No description provided for @logsProcessEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No process logs yet'**
  String get logsProcessEmptyTitle;

  /// No description provided for @logsProcessEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Raw process output (stdout/stderr) will appear here in real time'**
  String get logsProcessEmptySubtitle;

  /// No description provided for @logsSortNewestTop.
  ///
  /// In en, this message translates to:
  /// **'Newest on top'**
  String get logsSortNewestTop;

  /// No description provided for @logsSortNewestBottom.
  ///
  /// In en, this message translates to:
  /// **'Newest on bottom'**
  String get logsSortNewestBottom;

  /// No description provided for @logsCopiedLines.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} lines of log'**
  String logsCopiedLines(Object count);

  /// No description provided for @logsFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter by level'**
  String get logsFilter;

  /// No description provided for @logsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get logsFilterAll;

  /// No description provided for @logsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download log'**
  String get logsDownload;

  /// No description provided for @logsDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String logsDownloaded(Object path);

  /// No description provided for @logsResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get logsResume;

  /// No description provided for @logsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get logsPause;

  /// No description provided for @logsAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Auto scroll'**
  String get logsAutoScroll;

  /// No description provided for @logsLineCount.
  ///
  /// In en, this message translates to:
  /// **'{count} lines'**
  String logsLineCount(Object count);

  /// No description provided for @logsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No log'**
  String get logsEmptyTitle;

  /// No description provided for @logsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Once an instance is started, raw process output will appear here in real time'**
  String get logsEmptySubtitle;

  /// No description provided for @detailTabLifecycle.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle'**
  String get detailTabLifecycle;

  /// No description provided for @detailTabCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get detailTabCommands;

  /// No description provided for @detailTabBots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get detailTabBots;

  /// No description provided for @botsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get botsTitle;

  /// No description provided for @botsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bots'**
  String get botsEmpty;

  /// No description provided for @botsNeverActive.
  ///
  /// In en, this message translates to:
  /// **'Never active'**
  String get botsNeverActive;

  /// No description provided for @botsJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get botsJustNow;

  /// No description provided for @botsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'min ago'**
  String get botsMinutesAgo;

  /// No description provided for @botsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'h ago'**
  String get botsHoursAgo;

  /// No description provided for @botsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'d ago'**
  String get botsDaysAgo;

  /// No description provided for @lifecycleFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get lifecycleFilterType;

  /// No description provided for @lifecycleFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events match the filter'**
  String get lifecycleFilteredEmpty;

  /// No description provided for @lifecycleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No lifecycle events'**
  String get lifecycleEmpty;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Message stats'**
  String get statsTitle;

  /// No description provided for @statsTotalEvents.
  ///
  /// In en, this message translates to:
  /// **'Total events'**
  String get statsTotalEvents;

  /// No description provided for @statsByType.
  ///
  /// In en, this message translates to:
  /// **'By type'**
  String get statsByType;

  /// No description provided for @statsByPlatform.
  ///
  /// In en, this message translates to:
  /// **'By platform'**
  String get statsByPlatform;

  /// No description provided for @statsTrend.
  ///
  /// In en, this message translates to:
  /// **'Last 24h trend'**
  String get statsTrend;

  /// No description provided for @commandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get commandsTitle;

  /// No description provided for @commandsGlobalSettings.
  ///
  /// In en, this message translates to:
  /// **'Global settings'**
  String get commandsGlobalSettings;

  /// No description provided for @commandsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Command prefix'**
  String get commandsPrefix;

  /// No description provided for @commandsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commandsSave;

  /// No description provided for @commandsCaseSensitive.
  ///
  /// In en, this message translates to:
  /// **'Case-sensitive prefix'**
  String get commandsCaseSensitive;

  /// No description provided for @commandsAllowSpacePrefix.
  ///
  /// In en, this message translates to:
  /// **'Allow space prefix'**
  String get commandsAllowSpacePrefix;

  /// No description provided for @commandsMustAtBot.
  ///
  /// In en, this message translates to:
  /// **'Must mention bot'**
  String get commandsMustAtBot;

  /// No description provided for @commandsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No commands'**
  String get commandsEmpty;

  /// No description provided for @commandsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit command'**
  String get commandsEditTitle;

  /// No description provided for @commandsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get commandsEnabled;

  /// No description provided for @commandsAliases.
  ///
  /// In en, this message translates to:
  /// **'Aliases (comma separated)'**
  String get commandsAliases;

  /// No description provided for @commandsAllowedPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Allowed platforms (comma separated)'**
  String get commandsAllowedPlatforms;

  /// No description provided for @commandsBlockedPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Blocked platforms (comma separated)'**
  String get commandsBlockedPlatforms;

  /// No description provided for @commandsTransformTo.
  ///
  /// In en, this message translates to:
  /// **'Transform to (empty = none)'**
  String get commandsTransformTo;

  /// No description provided for @commandsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commandsSaved;

  /// No description provided for @commandsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commandsEdit;

  /// No description provided for @eventsBuilderView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get eventsBuilderView;

  /// No description provided for @eventsBuilderTab.
  ///
  /// In en, this message translates to:
  /// **'Builder'**
  String get eventsBuilderTab;

  /// No description provided for @eventsBuilderSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Event submitted'**
  String get eventsBuilderSubmitted;

  /// No description provided for @eventsBuilderFailed.
  ///
  /// In en, this message translates to:
  /// **'Submit failed'**
  String get eventsBuilderFailed;

  /// No description provided for @eventsBuilderType.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get eventsBuilderType;

  /// No description provided for @eventsBuilderDetailType.
  ///
  /// In en, this message translates to:
  /// **'Detail type'**
  String get eventsBuilderDetailType;

  /// No description provided for @eventsBuilderPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get eventsBuilderPlatform;

  /// No description provided for @eventsBuilderCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get eventsBuilderCustom;

  /// No description provided for @eventsBuilderBot.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get eventsBuilderBot;

  /// No description provided for @eventsBuilderSessionType.
  ///
  /// In en, this message translates to:
  /// **'Session type'**
  String get eventsBuilderSessionType;

  /// No description provided for @eventsBuilderSessionId.
  ///
  /// In en, this message translates to:
  /// **'Session ID'**
  String get eventsBuilderSessionId;

  /// No description provided for @eventsBuilderSegments.
  ///
  /// In en, this message translates to:
  /// **'Message segments'**
  String get eventsBuilderSegments;

  /// No description provided for @eventsBuilderAddSegment.
  ///
  /// In en, this message translates to:
  /// **'Add segment'**
  String get eventsBuilderAddSegment;

  /// No description provided for @eventsBuilderOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional fields'**
  String get eventsBuilderOptional;

  /// No description provided for @eventsBuilderAddField.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get eventsBuilderAddField;

  /// No description provided for @eventsBuilderPreview.
  ///
  /// In en, this message translates to:
  /// **'JSON preview'**
  String get eventsBuilderPreview;

  /// No description provided for @eventsBuilderCopyJson.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get eventsBuilderCopyJson;

  /// No description provided for @eventsBuilderCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get eventsBuilderCopied;

  /// No description provided for @eventsBuilderSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit event'**
  String get eventsBuilderSubmit;

  /// No description provided for @navGroupOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navGroupOverview;

  /// No description provided for @navGroupEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navGroupEvents;

  /// No description provided for @navGroupExtensions.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get navGroupExtensions;

  /// No description provided for @navGroupManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get navGroupManagement;

  /// No description provided for @navGroupOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get navGroupOperations;

  /// No description provided for @detailTabStore.
  ///
  /// In en, this message translates to:
  /// **'Module Store'**
  String get detailTabStore;

  /// No description provided for @detailTabMonitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get detailTabMonitor;

  /// No description provided for @storeBrowseTab.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get storeBrowseTab;

  /// No description provided for @storePackagesTab.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get storePackagesTab;

  /// No description provided for @storeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search modules, adapters…'**
  String get storeSearch;

  /// No description provided for @storeTypeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get storeTypeAll;

  /// No description provided for @storeTypeModule.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get storeTypeModule;

  /// No description provided for @storeTypeAdapter.
  ///
  /// In en, this message translates to:
  /// **'Adapter'**
  String get storeTypeAdapter;

  /// No description provided for @storeForceRefresh.
  ///
  /// In en, this message translates to:
  /// **'Force refresh'**
  String get storeForceRefresh;

  /// No description provided for @storeInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get storeInstalled;

  /// No description provided for @storeUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get storeUpdateAvailable;

  /// No description provided for @storeUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get storeUpgrade;

  /// No description provided for @storeOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get storeOfficial;

  /// No description provided for @storeDetail.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get storeDetail;

  /// No description provided for @storeAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get storeAuthor;

  /// No description provided for @storeLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get storeLicense;

  /// No description provided for @storeHomepage.
  ///
  /// In en, this message translates to:
  /// **'Homepage'**
  String get storeHomepage;

  /// No description provided for @storeRequires.
  ///
  /// In en, this message translates to:
  /// **'Dependencies'**
  String get storeRequires;

  /// No description provided for @storeVersions.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get storeVersions;

  /// No description provided for @storeVersionInstall.
  ///
  /// In en, this message translates to:
  /// **'Install this version'**
  String get storeVersionInstall;

  /// No description provided for @storeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Store is empty'**
  String get storeEmpty;

  /// No description provided for @storeFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching packages'**
  String get storeFilteredEmpty;

  /// No description provided for @storeMirror.
  ///
  /// In en, this message translates to:
  /// **'pip index mirror (optional)'**
  String get storeMirror;

  /// No description provided for @storeForce.
  ///
  /// In en, this message translates to:
  /// **'Force reinstall'**
  String get storeForce;

  /// No description provided for @storeTaskRunning.
  ///
  /// In en, this message translates to:
  /// **'Task running…'**
  String get storeTaskRunning;

  /// No description provided for @storeTaskSuccess.
  ///
  /// In en, this message translates to:
  /// **'Task finished'**
  String get storeTaskSuccess;

  /// No description provided for @storeTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Task failed'**
  String get storeTaskFailed;

  /// No description provided for @storeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get storeCurrent;

  /// No description provided for @storeLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get storeLatest;

  /// No description provided for @pkgInstalledTab.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get pkgInstalledTab;

  /// No description provided for @pkgUpdatesTab.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get pkgUpdatesTab;

  /// No description provided for @pkgInstallNewTab.
  ///
  /// In en, this message translates to:
  /// **'Install new'**
  String get pkgInstallNewTab;

  /// No description provided for @pkgGitTab.
  ///
  /// In en, this message translates to:
  /// **'Git'**
  String get pkgGitTab;

  /// No description provided for @pkgUpgradeAll.
  ///
  /// In en, this message translates to:
  /// **'Upgrade all'**
  String get pkgUpgradeAll;

  /// No description provided for @pkgNoUpdates.
  ///
  /// In en, this message translates to:
  /// **'No updates available'**
  String get pkgNoUpdates;

  /// No description provided for @pkgNoGit.
  ///
  /// In en, this message translates to:
  /// **'No Git packages'**
  String get pkgNoGit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
