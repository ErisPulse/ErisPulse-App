// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'ErisPulse';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '削除';

  @override
  String get commonStart => '起動';

  @override
  String get commonStop => '停止';

  @override
  String get commonRestart => '再起動';

  @override
  String get commonCreate => '作成';

  @override
  String get commonRefresh => '更新';

  @override
  String get commonSettings => '設定';

  @override
  String get commonCopy => 'コピー';

  @override
  String get commonCopyAll => 'すべてコピー';

  @override
  String get commonClear => 'クリア';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonInitialize => '初期化';

  @override
  String get commonRemote => 'リモート';

  @override
  String get commonLocal => 'ローカル';

  @override
  String get commonCreateInstance => 'インスタンスを作成';

  @override
  String get commonDeleteInstance => 'インスタンスを削除';

  @override
  String get commonRename => '名前を変更';

  @override
  String get commonViewLogs => 'ログを見る';

  @override
  String get statusStopped => '停止済み';

  @override
  String get statusStarting => '起動中';

  @override
  String get statusRunning => '実行中';

  @override
  String get statusError => 'エラー';

  @override
  String get statusDestroying => '破棄中';

  @override
  String get statusHealthy => '正常';

  @override
  String get statusBooting => '起動中';

  @override
  String get statusTokenInvalid => 'トークン無効';

  @override
  String get statusOffline => 'オフライン';

  @override
  String get statusUnknown => '未確認';

  @override
  String get statusOnline => 'オンライン';

  @override
  String get statusConnecting => '接続中';

  @override
  String get statusRemoteUnknown => '不明';

  @override
  String get homeDebugTooltip => 'デバッグログ';

  @override
  String get homeEmptyTitle => 'インスタンスがまだありません';

  @override
  String get homeEmptySubtitle => '最初の ErisPulse インスタンスを作成\n各インスタンスは独立したボットです';

  @override
  String homeDeleteConfirmContent(Object name) {
    return '「$name」を削除しますか？\nインスタンスの作業ディレクトリは保持され、メタデータのみ削除されます。';
  }

  @override
  String get homeBannerTitle => 'ランタイムが準備できていません';

  @override
  String get homeBannerInitializing => '初期化中…';

  @override
  String get homeBannerNeedDownload => 'ランタイムイメージのダウンロードと解凍が必要です';

  @override
  String get onboardingTitle => 'ランタイムを準備';

  @override
  String get onboardingDescription =>
      '初回起動にはランタイムイメージの準備が必要です\n（Ubuntu + Python + ErisPulse）';

  @override
  String get onboardingStartButton => '初期化を開始';

  @override
  String get onboardingTapHint => '画面のどこかをタップして 進捗 / ログ ビューを切り替え';

  @override
  String get onboardingProcessing => '処理中…';

  @override
  String get onboardingLogTitle => '初期化ログ';

  @override
  String get onboardingStartingLog => 'ランタイムの初期化を開始中…';

  @override
  String get onboardingReadyLog => 'ランタイム準備完了 ✓';

  @override
  String onboardingErrorLog(Object msg) {
    return 'エラー: $msg';
  }

  @override
  String get onboardingSdkTitle => 'ErisPulse SDK をインストール';

  @override
  String onboardingSdkPythonMissing(Object path) {
    return 'バンドルされた Python が見つかりません: $path';
  }

  @override
  String onboardingSdkInstalled(Object version) {
    return 'ErisPulse $version がインストールされています';
  }

  @override
  String get onboardingSdkChooseVersion => 'インストールするバージョンを選択';

  @override
  String get onboardingSdkInstall => 'インストール';

  @override
  String get onboardingSdkInstalling => 'インストール中…';

  @override
  String get onboardingSdkVersionFailed => 'バージョンの取得に失敗しました。ネットワークを確認してください';

  @override
  String get onboardingSdkRefresh => '更新';

  @override
  String get onboardingSdkContinue => '進む';

  @override
  String get homeBannerNeedSdk => 'ErisPulse SDK のインストールが必要です';

  @override
  String get createTitle => 'ErisPulse インスタンスを作成';

  @override
  String get createSubtitle =>
      'ローカルインスタンスはこの端末上で独立して動作します；\nリモートインスタンスは別ホストにデプロイしたインスタンスに接続します。';

  @override
  String get createNameLabel => 'インスタンス名 *';

  @override
  String get createNameHint => '例：マイボット';

  @override
  String get createNameHelper => '一覧でインスタンスを区別するために使用';

  @override
  String get createNameRequired => '名前は必須です';

  @override
  String get createNameTooLong => '名前が長すぎます（最大 24 文字）';

  @override
  String get createUrlLabel => 'Dashboard URL *';

  @override
  String get createUrlHelper => '相手インスタンスの Dashboard のベース URL';

  @override
  String get createUrlRequired => 'URL は必須です';

  @override
  String get createUrlScheme => 'http:// または https:// で始まる必要があります';

  @override
  String get createTokenLabel => 'アクセストークン（任意）';

  @override
  String get createTokenHelper => '相手 Dashboard のトークン。疎通確認とログインに使用';

  @override
  String get createPortLabel => '待受ポート *';

  @override
  String get createPortHelper => 'インスタンスごとに独立したポート。デフォルトで自動割り当て';

  @override
  String get createPortRequired => 'ポートは必須です';

  @override
  String get createPortRange => 'ポートは 1024-65535 の範囲で指定してください';

  @override
  String get createRemoteNote =>
      'リモートインスタンスは相手ホストで動作し、アプリは Dashboard 経由で表示・管理します。';

  @override
  String get createLocalNote => '作成後のインスタンスは「停止済み」状態です。詳細ページで起動できます。';

  @override
  String createCreated(Object name) {
    return 'インスタンス「$name」を作成しました';
  }

  @override
  String get createFailed => '作成に失敗しました';

  @override
  String get createFailedRetry => '作成に失敗しました。もう一度お試しください';

  @override
  String get detailSystemResource => 'システムリソース';

  @override
  String get detailResourceHint => 'インスタンス起動後に Dashboard のシステムリソースを表示';

  @override
  String get detailMemory => 'メモリ';

  @override
  String get detailUptime => '稼働時間';

  @override
  String get detailThreads => 'スレッド';

  @override
  String get detailCores => 'コア数';

  @override
  String get detailAddress => 'アドレス';

  @override
  String get detailPort => 'ポート';

  @override
  String get detailTapToReveal => 'タップして表示・コピー';

  @override
  String get detailTokenCopied => 'アクセストークンをコピーしました';

  @override
  String get detailRefreshState => 'ステータス更新';

  @override
  String get detailNotFound => 'インスタンスが存在しません';

  @override
  String get detailRecentEvents => '最近のイベント';

  @override
  String get detailNoEvents =>
      'イベントはまだありません。インスタンス起動後にフレームワーク/アダプタのイベントが記録されます';

  @override
  String get detailOpenDashboard => 'Dashboard を開く';

  @override
  String get detailStartingToast => '起動中…';

  @override
  String get detailStoppedToast => '停止を要求しました';

  @override
  String get detailRestartingToast => '再起動中…';

  @override
  String get detailUnreachableError => 'インスタンスが起動していないか、Dashboard に接続できません';

  @override
  String get detailOverview => '稼働概要';

  @override
  String get detailModules => 'モジュール';

  @override
  String get detailAdapters => 'アダプタ';

  @override
  String detailEnabledCount(Object count) {
    return '有効 $count';
  }

  @override
  String detailRunningCount(Object count) {
    return '稼働 $count';
  }

  @override
  String dashboardLoadFailed(Object code) {
    return '読み込みに失敗しました（$code）';
  }

  @override
  String get dashboardTokenCopied => 'アクセストークンをコピーしました。ログインページに貼り付けてください';

  @override
  String get dashboardExternalFailed => '外部ブラウザを開けません';

  @override
  String get dashboardCopyTokenTooltip => 'アクセストークンをコピー';

  @override
  String get dashboardExternalOpen => '外部ブラウザで開く';

  @override
  String get dashboardCheckHint => 'インスタンスが起動しており、このアドレスにアクセスできることを確認してください';

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsThemeSystem => 'システムに従う';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLangSystem => 'システムに従う';

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
  String get settingsDownloadSource => 'ダウンロード元';

  @override
  String get settingsDownloadGithub => 'GitHub 公式';

  @override
  String get settingsDownloadGhfast => 'GitHub ミラー (ghfast.top)';

  @override
  String get settingsDownloadGhproxy => 'GitHub ミラー (gh-proxy.com)';

  @override
  String get settingsRuntime => 'ランタイム';

  @override
  String get settingsRootfsTitle => '実行環境 (rootfs)';

  @override
  String settingsRuntimeReady(Object version) {
    return 'バンドル Python + ErisPulse $version';
  }

  @override
  String get settingsRootfsReady => '準備完了';

  @override
  String get settingsRootfsNotReady => '未準備';

  @override
  String get settingsAutoRestart => 'クラッシュ時に自動再起動';

  @override
  String get settingsAutoRestartDesc => 'インスタンスが異常終了したときに自動的に再起動';

  @override
  String get settingsStopAll => 'すべてのインスタンスを停止';

  @override
  String get settingsStopAllDesc => 'すべてのローカルインスタンスのプロセスを終了';

  @override
  String get settingsStopAllConfirm => '実行中のローカルインスタンスをすべて停止しますか？';

  @override
  String get settingsStopAllAction => 'すべて停止';

  @override
  String get settingsData => 'データ';

  @override
  String get settingsClearLogs => 'デバッグログをクリア';

  @override
  String get settingsClearLogsDesc => 'proot プロセスのログバッファをクリア';

  @override
  String get settingsAbout => '情報';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsAboutApp => 'ErisPulse-App について';

  @override
  String get settingsAboutSubtitle => 'マルチデバイス管理クライアント（ランチャー + Dashboard）';

  @override
  String get settingsAboutDialog =>
      'ErisPulse マルチデバイス管理クライアント。\nローカルインスタンスは proot + Ubuntu で動作し、管理 UI は Dashboard が提供します。\n\nMIT License';

  @override
  String get debugTitle => 'デバッグ情報';

  @override
  String get debugCopyAllTooltip => 'すべてコピー';

  @override
  String get debugClearLogsTooltip => 'ログをクリア';

  @override
  String get debugCopiedAll => '完全なデバッグ情報をコピーしました';

  @override
  String get debugCopiedLogs => 'ログをコピーしました';

  @override
  String get debugAppVersion => 'アプリバージョン';

  @override
  String get debugPackageName => 'パッケージ名';

  @override
  String get debugDeviceModel => '端末モデル';

  @override
  String get debugBrand => 'ブランド';

  @override
  String get debugAndroid => 'Android';

  @override
  String get debugAbi => 'ABI';

  @override
  String get debugNativeLib => 'native lib';

  @override
  String get debugRootfs => 'rootfs';

  @override
  String get debugRootfsError => 'rootfs エラー';

  @override
  String get debugInstanceCount => 'インスタンス数';

  @override
  String get debugInfoHeader => '== ErisPulse-App デバッグ情報 ==';

  @override
  String get debugReady => '準備完了';

  @override
  String get debugNotReady => '未準備';

  @override
  String get debugRootfsMessage => 'rootfs メッセージ';

  @override
  String get debugLogHeader => '== ログ ==';

  @override
  String get debugNoLogs =>
      'ログはまだありません\nインスタンスを起動すると、proot プロセスの出力がリアルタイムでここに表示されます';

  @override
  String get debugProcessLogs => 'プロセスログ';

  @override
  String logsCopiedLines(Object count) {
    return '$count 行のログをコピーしました';
  }

  @override
  String get logsResume => '再開';

  @override
  String get logsPause => '一時停止';

  @override
  String get logsAutoScroll => '自動スクロール';

  @override
  String logsLineCount(Object count) {
    return '$count 行';
  }

  @override
  String get logsEmptyTitle => 'ログなし';

  @override
  String get logsEmptySubtitle => 'インスタンスを起動すると、プロセスの生の出力がリアルタイムでここに表示されます';
}
