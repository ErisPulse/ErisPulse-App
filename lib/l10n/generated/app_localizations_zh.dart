// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'ErisPulse';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonSoftRestart => '软重启';

  @override
  String get commonHardRestart => '重启进程';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonStart => '启动';

  @override
  String get commonStop => '停止';

  @override
  String get commonRestart => '重启';

  @override
  String get commonCreate => '创建';

  @override
  String get commonRefresh => '刷新';

  @override
  String get commonLoading => '加载中';

  @override
  String get commonSettings => '设置';

  @override
  String get commonCopy => '复制';

  @override
  String get commonCopyAll => '复制全部';

  @override
  String get commonClear => '清空';

  @override
  String get commonRetry => '重试';

  @override
  String get commonInitialize => '初始化';

  @override
  String get commonInstalled => '已安装';

  @override
  String get commonPreRelease => '预发布';

  @override
  String get railInstances => '实例';

  @override
  String get commonRemote => '远程';

  @override
  String get commonLocal => '本地';

  @override
  String get commonCreateInstance => '创建实例';

  @override
  String get commonDeleteInstance => '删除实例';

  @override
  String get commonRename => '重命名';

  @override
  String get commonViewLogs => '查看日志';

  @override
  String get statusStopped => '已停止';

  @override
  String get statusStarting => '启动中';

  @override
  String get statusRunning => '运行中';

  @override
  String get statusError => '异常';

  @override
  String get statusDestroying => '销毁中';

  @override
  String get statusHealthy => '健康';

  @override
  String get statusBooting => '启动中';

  @override
  String get statusTokenInvalid => 'Token 无效';

  @override
  String get statusOffline => '离线';

  @override
  String get statusUnknown => '未检测';

  @override
  String get statusOnline => '在线';

  @override
  String get statusConnecting => '连接中';

  @override
  String get statusRemoteUnknown => '未知';

  @override
  String get homeDebugTooltip => '调试日志';

  @override
  String get homeEmptyTitle => '还没有实例';

  @override
  String get homeEmptySubtitle => '创建你的第一个 ErisPulse 实例\n每个实例是一个独立的机器人';

  @override
  String homeDeleteConfirmContent(Object name) {
    return '确认删除 \"$name\"？\n实例工作目录会保留，仅删除元数据。';
  }

  @override
  String get homeBannerTitle => '运行环境未就绪';

  @override
  String get homeBannerInitializing => '初始化中…';

  @override
  String get homeBannerNeedDownload => '需要下载并解压运行时镜像';

  @override
  String get onboardingTitle => '准备运行环境';

  @override
  String get onboardingDescription => '首次启动需要准备运行时环境\n（Python + ErisPulse）';

  @override
  String get onboardingStartButton => '开始初始化';

  @override
  String get onboardingTapHint => '点击屏幕任意位置切换 进度 / 日志 视图';

  @override
  String get onboardingProcessing => '处理中…';

  @override
  String get onboardingLogTitle => '初始化日志';

  @override
  String get onboardingStartingLog => '开始初始化运行时…';

  @override
  String get onboardingReadyLog => '运行时就绪 ✓';

  @override
  String onboardingErrorLog(Object msg) {
    return '错误: $msg';
  }

  @override
  String get onboardingSdkTitle => '安装 ErisPulse SDK';

  @override
  String onboardingSdkPythonMissing(Object path) {
    return '未找到捆绑的 Python: $path';
  }

  @override
  String onboardingSdkInstalled(Object version) {
    return 'ErisPulse $version 已安装';
  }

  @override
  String get onboardingSdkChooseVersion => '选择要安装的版本';

  @override
  String get onboardingSdkInstall => '安装';

  @override
  String get onboardingSdkUseInstalled => '使用已安装版本';

  @override
  String get onboardingSdkInstalling => '正在安装…';

  @override
  String get onboardingSdkVersionFailed => '获取版本失败，请检查网络';

  @override
  String get onboardingSdkRefresh => '刷新';

  @override
  String get onboardingSdkContinue => '进入';

  @override
  String get onboardingPythonRelease => '释放内置 Python';

  @override
  String get onboardingPythonReleasing => '正在释放 Python 环境…';

  @override
  String get onboardingPythonReady => '已就绪';

  @override
  String get onboardingPythonIntro => 'App 内置了 Python 环境，释放后即可开始使用。';

  @override
  String get onboardingPythonFailed => '内置 Python 释放失败，请重试。';

  @override
  String get homeBannerNeedSdk => '需要安装 ErisPulse SDK';

  @override
  String get createTitle => '创建一个 ErisPulse 实例';

  @override
  String get createSubtitle => '本地实例在手机内独立运行；\n远程实例连接到你部署在其它主机的实例。';

  @override
  String get createNameLabel => '实例名称 *';

  @override
  String get createNameHint => '例如：我的机器人';

  @override
  String get createNameHelper => '用于在列表中区分不同实例';

  @override
  String get createNameRequired => '名称不能为空';

  @override
  String get createNameTooLong => '名称过长（最多 24 字符）';

  @override
  String get createUrlLabel => 'Dashboard 地址 *';

  @override
  String get createUrlHelper => '对方实例的 Dashboard 基地址';

  @override
  String get createUrlRequired => '地址不能为空';

  @override
  String get createUrlScheme => '需以 http:// 或 https:// 开头';

  @override
  String get createTokenLabel => '访问令牌（可选）';

  @override
  String get createTokenHelper => '对方 Dashboard 的 token，用于探活与登录';

  @override
  String get createRuntimeLabel => '运行时版本';

  @override
  String get createRuntimeDefault => '使用全局默认';

  @override
  String get createSdkVersionLabel => 'ErisPulse SDK 版本';

  @override
  String get createSdkVersionHelper => '安装到该实例自己的虚拟环境中';

  @override
  String get createEnvTitle => '环境来源';

  @override
  String get createEnvFresh => '全新环境';

  @override
  String get createEnvFreshDesc => '用所选 SDK 版本新建独立环境';

  @override
  String get createEnvClone => '基于已有实例';

  @override
  String get createEnvCloneDesc => '复制某个已有实例的环境（SDK 版本与已装包）';

  @override
  String get createEnvCloneSource => '源实例';

  @override
  String get createEnvCloneNeedSource => '请选择源实例';

  @override
  String get createPreparingEnv => '正在准备环境';

  @override
  String get createEnvReady => '环境准备完成';

  @override
  String get createEnvFailed => '环境准备失败';

  @override
  String get createEnvCopying => '正在复制源实例环境（venv）…';

  @override
  String createEnvCopyProgress(Object done, Object total) {
    return '已复制 $done / $total 个文件';
  }

  @override
  String get createEnvPleaseWait => '环境准备中，可能需要一点时间，请勿关闭窗口';

  @override
  String get createPortLabel => '监听端口 *';

  @override
  String get createPortHelper => '每个实例独立端口，默认自动分配';

  @override
  String get createPortRequired => '端口不能为空';

  @override
  String get createPortRange => '端口需在 1024-65535 之间';

  @override
  String get createRemoteNote => '远程实例运行在对方主机，App 通过其 Dashboard 查看与管理。';

  @override
  String get createLocalNote => '创建后实例处于\"已停止\"状态，可在详情页启动。';

  @override
  String createCreated(Object name) {
    return '实例 \"$name\" 创建成功';
  }

  @override
  String get createFailed => '创建失败';

  @override
  String get createFailedRetry => '创建失败，请重试';

  @override
  String get detailSystemResource => '系统资源';

  @override
  String get detailResourceHint => '实例启动后显示 Dashboard 系统资源';

  @override
  String get detailMemory => '内存';

  @override
  String get detailUptime => '运行时长';

  @override
  String get detailThreads => '线程';

  @override
  String get detailCores => '核数';

  @override
  String get detailAddress => '地址';

  @override
  String get detailPort => '端口';

  @override
  String get detailRuntimeLabel => '运行时';

  @override
  String get detailTapToReveal => '点击查看并复制';

  @override
  String get detailTokenCopied => '访问令牌已复制';

  @override
  String get detailRefreshState => '刷新状态';

  @override
  String get detailNotFound => '实例不存在';

  @override
  String get detailRecentEvents => '最近事件';

  @override
  String get detailNoEvents => '暂无事件，实例启动后会记录框架/适配器事件';

  @override
  String get detailOpenDashboard => '打开 Dashboard';

  @override
  String get detailTabOverview => '概览';

  @override
  String get detailTabModules => '模块';

  @override
  String get detailTabAdapters => '适配器';

  @override
  String get detailTabConfig => '配置';

  @override
  String get detailTabFiles => '文件';

  @override
  String get detailTabLogs => '日志';

  @override
  String get detailTabPackages => '包';

  @override
  String get detailTabEvents => '事件流';

  @override
  String get detailTabAudit => '审计';

  @override
  String get eventsFilterType => '类型';

  @override
  String get auditTitle => '审计日志';

  @override
  String get auditEmpty => '暂无审计日志';

  @override
  String get detailTabEmpty => '暂无内容';

  @override
  String get detailClearLogs => '清空日志';

  @override
  String get detailAuthInvalid => '访问令牌无效或已过期，请检查实例令牌';

  @override
  String get detailConfigSource => '源码';

  @override
  String get detailConfigEdit => '编辑';

  @override
  String get detailConfigSaved => '配置已保存';

  @override
  String get detailPackageInstalled => '已安装的包';

  @override
  String get schemaConfigSave => '保存';

  @override
  String get schemaConfigSaved => '配置已保存';

  @override
  String get schemaConfigNoSchema => '无配置 schema';

  @override
  String get adapterConfigGlobal => '全局设置';

  @override
  String get adapterConfigAccounts => 'Bot 账户';

  @override
  String get adapterConfigAccountAdd => '新增账户';

  @override
  String get adapterConfigAccountName => '账户名称';

  @override
  String get adapterConfigAccountNameRequired => '请输入账户名称';

  @override
  String get adapterConfigAccountDelete => '删除账户';

  @override
  String adapterConfigAccountDeleteConfirm(String name) {
    return '删除账户 $name？删除后不可恢复。';
  }

  @override
  String get adapterConfigAccountsEmpty => '暂无 Bot 账户';

  @override
  String get adapterConfigAccountSaved => '账户已保存';

  @override
  String get adapterConfigAccountAdded => '账户已创建';

  @override
  String get adapterConfigAccountDeleted => '账户已删除';

  @override
  String get adapterConfigEnabled => '启用';

  @override
  String get detailConfigCopied => '配置已复制';

  @override
  String get detailPackageName => '包名';

  @override
  String get detailPackageInstall => '安装包';

  @override
  String get detailPackageUninstall => '卸载包';

  @override
  String detailPackageUninstallConfirm(Object name) {
    return '卸载 $name？';
  }

  @override
  String get detailFrameworkUpdate => '更新框架';

  @override
  String get detailFrameworkUpdateConfirm => '将框架更新到最新版本？';

  @override
  String get detailFrameworkLatest => '已是最新';

  @override
  String get detailSdkRestart => '重启 SDK';

  @override
  String get detailSdkRestartConfirm => '现在重启 SDK？将中断所有连接。';

  @override
  String get detailFileSave => '保存';

  @override
  String get detailFileSaved => '已保存';

  @override
  String detailFileDeleteConfirm(Object name) {
    return '删除 $name？';
  }

  @override
  String get detailStartingToast => '正在启动…';

  @override
  String get detailStoppedToast => '已请求停止';

  @override
  String get detailRestartingToast => '正在重启…';

  @override
  String get detailUnreachableError => '实例未运行或 Dashboard 不可达';

  @override
  String get detailOverview => '运行概览';

  @override
  String get detailModules => '模块';

  @override
  String get detailAdapters => '适配器';

  @override
  String detailEnabledCount(Object count) {
    return '已启用 $count';
  }

  @override
  String detailRunningCount(Object count) {
    return '运行 $count';
  }

  @override
  String dashboardLoadFailed(Object code) {
    return '加载失败（$code）';
  }

  @override
  String get dashboardAccessKey => '访问密钥';

  @override
  String get dashboardAccessKeyCopied => '访问密钥已复制';

  @override
  String get dashboardTokenCopied => '访问令牌已复制，可粘贴到登录页';

  @override
  String get dashboardExternalFailed => '无法打开外部浏览器';

  @override
  String get dashboardCopyTokenTooltip => '复制访问令牌';

  @override
  String get dashboardExternalOpen => '外部浏览器打开';

  @override
  String get dashboardCheckHint => '请确认实例已启动，且网络可访问该地址';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLangSystem => '跟随系统';

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
  String get settingsDownloadSource => '下载源';

  @override
  String get settingsDownloadGithub => 'GitHub 官方';

  @override
  String get settingsDownloadGhfast => 'GitHub 镜像 (ghfast.top)';

  @override
  String get settingsDownloadGhproxy => 'GitHub 镜像 (gh-proxy.com)';

  @override
  String get settingsPypiSource => 'PyPI 镜像源';

  @override
  String get settingsPypiOfficial => 'PyPI 官方';

  @override
  String get settingsPypiTsinghua => '清华镜像';

  @override
  String get settingsPypiAliyun => '阿里云镜像';

  @override
  String get settingsRuntime => '运行时';

  @override
  String get settingsRootfsTitle => '运行环境 (rootfs)';

  @override
  String settingsRuntimeReady(Object version) {
    return '捆绑 Python + ErisPulse $version';
  }

  @override
  String get settingsRuntimeVersion => '运行时版本';

  @override
  String get settingsRuntimeDownload => '下载运行时';

  @override
  String get runtimeManagerTitle => '运行时管理';

  @override
  String get runtimeManagerInstalled => '已安装的运行时';

  @override
  String get runtimeManagerAvailable => '可下载版本';

  @override
  String get runtimeManagerEmpty => '暂无已安装的运行时';

  @override
  String get runtimeManagerLoading => '正在获取版本…';

  @override
  String get runtimeManagerActivate => '激活';

  @override
  String get runtimeManagerActive => '已激活';

  @override
  String get runtimeManagerPath => '运行时目录';

  @override
  String runtimeManagerDeleteConfirm(Object version) {
    return '删除运行时 v$version？该操作不可恢复。';
  }

  @override
  String get runtimeManagerDesc => '内置 Python 与各实例环境管理';

  @override
  String get runtimeManagerInstances => '实例环境';

  @override
  String get runtimeManagerPythonMissing => '内置 Python 未就绪';

  @override
  String get settingsOpenSource => '开源地址';

  @override
  String get settingsRootfsReady => '已就绪';

  @override
  String get settingsRootfsNotReady => '未就绪';

  @override
  String get settingsAutoRestart => '崩溃自动重启';

  @override
  String get settingsAutoRestartDesc => '实例异常退出后自动重新启动';

  @override
  String get settingsStopAll => '停止所有实例';

  @override
  String get settingsStopAllDesc => '关闭全部本地实例进程';

  @override
  String get settingsStopAllConfirm => '确认停止全部正在运行的本地实例？';

  @override
  String get settingsStopAllAction => '全部停止';

  @override
  String get settingsData => '数据';

  @override
  String get settingsClearLogs => '清空调试日志';

  @override
  String get settingsClearLogsDesc => '清空运行调试日志';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsAboutApp => '关于 ErisPulse-App';

  @override
  String get settingsAboutSubtitle => '多端管理客户端（启动器 + Dashboard）';

  @override
  String get settingsAboutDialog =>
      'ErisPulse 多端管理客户端。\n本地实例使用独立的环境运行，管理界面由 Dashboard 提供。\n\nMIT License';

  @override
  String get debugTitle => '调试信息';

  @override
  String get debugCopyAllTooltip => '复制全部';

  @override
  String get debugClearLogsTooltip => '清空日志';

  @override
  String get debugCopiedAll => '已复制完整调试信息';

  @override
  String get debugCopiedLogs => '已复制日志';

  @override
  String get debugAppVersion => '应用版本';

  @override
  String get debugPackageName => '包名';

  @override
  String get debugDeviceModel => '设备型号';

  @override
  String get debugBrand => '品牌';

  @override
  String get debugAndroid => 'Android';

  @override
  String get debugAbi => 'ABI';

  @override
  String get debugSystem => '系统';

  @override
  String get debugNativeLib => 'native lib';

  @override
  String get debugRootfs => 'rootfs';

  @override
  String get debugRootfsError => 'rootfs 错误';

  @override
  String get debugInstanceCount => '实例数量';

  @override
  String get debugInfoHeader => '== ErisPulse-App 调试信息 ==';

  @override
  String get debugReady => '就绪';

  @override
  String get debugNotReady => '未就绪';

  @override
  String get debugRootfsMessage => 'rootfs 消息';

  @override
  String get debugLogHeader => '== 日志 ==';

  @override
  String get debugNoLogs => '暂无日志\n启动实例后，proot 进程输出将实时显示在这里';

  @override
  String get debugProcessLogs => '进程日志';

  @override
  String get logsSoft => '软日志';

  @override
  String get logsProcess => '进程日志';

  @override
  String get logsSearch => '搜索';

  @override
  String get logsFilterModule => '模块';

  @override
  String get logsFilteredEmpty => '没有符合当前过滤条件的日志';

  @override
  String get logsProcessEmptyTitle => '暂无进程日志';

  @override
  String get logsProcessEmptySubtitle => '实例运行时的原始输出（stdout/stderr）将实时显示在这里';

  @override
  String get logsSortNewestTop => '最新在顶';

  @override
  String get logsSortNewestBottom => '最新在底';

  @override
  String logsCopiedLines(Object count) {
    return '已复制 $count 行日志';
  }

  @override
  String get logsFilter => '等级过滤';

  @override
  String get logsFilterAll => '全部';

  @override
  String get logsDownload => '下载日志';

  @override
  String logsDownloaded(Object path) {
    return '已保存到 $path';
  }

  @override
  String get logsResume => '继续';

  @override
  String get logsPause => '暂停';

  @override
  String get logsAutoScroll => '自动滚动';

  @override
  String logsLineCount(Object count) {
    return '$count 行';
  }

  @override
  String get logsEmptyTitle => '暂无日志';

  @override
  String get logsEmptySubtitle => '启动实例后，进程原始输出将实时显示在这里';

  @override
  String get detailTabLifecycle => '生命周期';

  @override
  String get detailTabCommands => '命令';

  @override
  String get detailTabBots => '机器人';

  @override
  String get botsTitle => '机器人';

  @override
  String get botsEmpty => '暂无机器人';

  @override
  String get botsNeverActive => '从未活跃';

  @override
  String get botsJustNow => '刚刚活跃';

  @override
  String get botsMinutesAgo => '分钟前';

  @override
  String get botsHoursAgo => '小时前';

  @override
  String get botsDaysAgo => '天前';

  @override
  String get lifecycleFilterType => '类型';

  @override
  String get lifecycleFilteredEmpty => '没有符合筛选条件的事件';

  @override
  String get lifecycleEmpty => '暂无生命周期事件';

  @override
  String get statsTitle => '消息统计';

  @override
  String get statsTotalEvents => '总事件数';

  @override
  String get statsByType => '按类型';

  @override
  String get statsByPlatform => '按平台';

  @override
  String get statsTrend => '近24小时趋势';

  @override
  String get commandsTitle => '命令管理';

  @override
  String get commandsGlobalSettings => '全局设置';

  @override
  String get commandsPrefix => '指令前缀';

  @override
  String get commandsSave => '保存';

  @override
  String get commandsCaseSensitive => '前缀区分大小写';

  @override
  String get commandsAllowSpacePrefix => '允许空格前缀';

  @override
  String get commandsMustAtBot => '必须 @机器人';

  @override
  String get commandsEmpty => '暂无命令';

  @override
  String get commandsEditTitle => '编辑命令';

  @override
  String get commandsEnabled => '已启用';

  @override
  String get commandsAliases => '别名（逗号分隔）';

  @override
  String get commandsAllowedPlatforms => '允许的平台（逗号分隔）';

  @override
  String get commandsBlockedPlatforms => '禁止的平台（逗号分隔）';

  @override
  String get commandsTransformTo => '转发为（留空表示不转发）';

  @override
  String get commandsSaved => '已保存';

  @override
  String get commandsEdit => '编辑';

  @override
  String get eventsBuilderView => '查看';

  @override
  String get eventsBuilderTab => '构建器';

  @override
  String get eventsBuilderSubmitted => '事件已提交';

  @override
  String get eventsBuilderFailed => '提交失败';

  @override
  String get eventsBuilderType => '事件类型';

  @override
  String get eventsBuilderDetailType => '子类型';

  @override
  String get eventsBuilderPlatform => '平台';

  @override
  String get eventsBuilderCustom => '自定义';

  @override
  String get eventsBuilderBot => '机器人';

  @override
  String get eventsBuilderSessionType => '会话类型';

  @override
  String get eventsBuilderSessionId => '会话 ID';

  @override
  String get eventsBuilderSegments => '消息分段';

  @override
  String get eventsBuilderAddSegment => '添加分段';

  @override
  String get eventsBuilderOptional => '可选字段';

  @override
  String get eventsBuilderAddField => '添加字段';

  @override
  String get eventsBuilderPreview => 'JSON 预览';

  @override
  String get eventsBuilderCopyJson => '复制 JSON';

  @override
  String get eventsBuilderCopied => '已复制';

  @override
  String get eventsBuilderSubmit => '提交事件';

  @override
  String get navGroupOverview => '概览';

  @override
  String get navGroupEvents => '事件';

  @override
  String get navGroupExtensions => '扩展';

  @override
  String get navGroupManagement => '管理';

  @override
  String get navGroupOperations => '运维';

  @override
  String get detailTabStore => '模块商店';

  @override
  String get detailTabMonitor => '监控';

  @override
  String get storeBrowseTab => '商店';

  @override
  String get storePackagesTab => '包管理';

  @override
  String get storeSearch => '搜索模块、适配器…';

  @override
  String get storeTypeAll => '全部';

  @override
  String get storeTypeModule => '模块';

  @override
  String get storeTypeAdapter => '适配器';

  @override
  String get storeForceRefresh => '强制刷新';

  @override
  String get storeInstalled => '已安装';

  @override
  String get storeUpdateAvailable => '有更新';

  @override
  String get storeUpgrade => '升级';

  @override
  String get storeOfficial => '官方';

  @override
  String get storeDetail => '详情';

  @override
  String get storeAuthor => '作者';

  @override
  String get storeLicense => '许可证';

  @override
  String get storeHomepage => '主页';

  @override
  String get storeRequires => '依赖';

  @override
  String get storeVersions => '历史版本';

  @override
  String get storeVersionInstall => '安装此版本';

  @override
  String get storeEmpty => '商店为空';

  @override
  String get storeFilteredEmpty => '没有匹配的包';

  @override
  String get storeMirror => 'pip 镜像源（可选）';

  @override
  String get storeForce => '强制重装';

  @override
  String get storeTaskRunning => '任务执行中…';

  @override
  String get storeTaskSuccess => '任务完成';

  @override
  String get storeTaskFailed => '任务失败';

  @override
  String get storeCurrent => '当前';

  @override
  String get storeLatest => '最新';

  @override
  String get pkgInstalledTab => '已安装';

  @override
  String get pkgUpdatesTab => '可更新';

  @override
  String get pkgInstallNewTab => '安装新包';

  @override
  String get pkgGitTab => 'Git 安装';

  @override
  String get pkgUpgradeAll => '全部升级';

  @override
  String get pkgNoUpdates => '暂无可更新包';

  @override
  String get pkgNoGit => '暂无 Git 包';

  @override
  String get navGroupSystem => '系统';

  @override
  String get navGroupTools => '工具';

  @override
  String get moduleViewOpenHint => '该视窗由模块提供，在 Dashboard 中打开渲染。';

  @override
  String get moduleViewOpenButton => '打开模块视窗';

  @override
  String get storeTagFilter => '标签筛选';

  @override
  String storeTagFilterCount(Object n) {
    return '标签筛选 ($n)';
  }

  @override
  String get storeTagClear => '清除';

  @override
  String get createSubtitleDesktop => '本地实例在本机创建并独立运行；\n远程实例连接到你部署在其它主机的实例。';

  @override
  String get detailOnlineBots => '在线机器人';

  @override
  String get detailTotalEvents => '事件总数';

  @override
  String get dashboardLoadTimeout => '加载超时：页面未能完成加载，请重试或用浏览器打开';

  @override
  String get closePromptTitle => '关闭 ErisPulse';

  @override
  String get closePromptMessage =>
      '还有实例在运行时可以最小化到托盘让它们继续在后台运行；停止全部实例并退出会中断机器人服务。';

  @override
  String get closeMinimizeTray => '最小化到托盘';

  @override
  String get closeStopExit => '停止全部实例并退出';

  @override
  String get closeRemember => '记住我的选择';

  @override
  String get settingsCloseBehavior => '关闭窗口行为';

  @override
  String get closeActionAsk => '每次询问';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appName => 'ErisPulse';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonSoftRestart => '軟重啟';

  @override
  String get commonHardRestart => '重啟程序';

  @override
  String get commonSave => '儲存';

  @override
  String get commonDelete => '刪除';

  @override
  String get commonStart => '啟動';

  @override
  String get commonStop => '停止';

  @override
  String get commonRestart => '重新啟動';

  @override
  String get commonCreate => '建立';

  @override
  String get commonRefresh => '重新整理';

  @override
  String get commonLoading => '載入中';

  @override
  String get commonSettings => '設定';

  @override
  String get commonCopy => '複製';

  @override
  String get commonCopyAll => '複製全部';

  @override
  String get commonClear => '清除';

  @override
  String get commonRetry => '重試';

  @override
  String get commonInitialize => '初始化';

  @override
  String get commonInstalled => '已安裝';

  @override
  String get commonPreRelease => '預發布';

  @override
  String get railInstances => '實例';

  @override
  String get commonRemote => '遠端';

  @override
  String get commonLocal => '本機';

  @override
  String get commonCreateInstance => '建立實例';

  @override
  String get commonDeleteInstance => '刪除實例';

  @override
  String get commonRename => '重新命名';

  @override
  String get commonViewLogs => '檢視日誌';

  @override
  String get statusStopped => '已停止';

  @override
  String get statusStarting => '啟動中';

  @override
  String get statusRunning => '執行中';

  @override
  String get statusError => '異常';

  @override
  String get statusDestroying => '銷毀中';

  @override
  String get statusHealthy => '健康';

  @override
  String get statusBooting => '啟動中';

  @override
  String get statusTokenInvalid => 'Token 無效';

  @override
  String get statusOffline => '離線';

  @override
  String get statusUnknown => '未偵測';

  @override
  String get statusOnline => '線上';

  @override
  String get statusConnecting => '連線中';

  @override
  String get statusRemoteUnknown => '未知';

  @override
  String get homeDebugTooltip => '除錯日誌';

  @override
  String get homeEmptyTitle => '還沒有實例';

  @override
  String get homeEmptySubtitle => '建立你的第一個 ErisPulse 實例\n每個實例是一個獨立的機器人';

  @override
  String homeDeleteConfirmContent(Object name) {
    return '確認刪除「$name」？\n實例工作目錄會保留，僅刪除中繼資料。';
  }

  @override
  String get homeBannerTitle => '執行環境未就緒';

  @override
  String get homeBannerInitializing => '初始化中…';

  @override
  String get homeBannerNeedDownload => '需要下載並解壓執行時期映像';

  @override
  String get onboardingTitle => '準備執行環境';

  @override
  String get onboardingDescription => '首次啟動需要準備執行時期環境\n（Python + ErisPulse）';

  @override
  String get onboardingStartButton => '開始初始化';

  @override
  String get onboardingTapHint => '點擊螢幕任意位置切換 進度 / 日誌 檢視';

  @override
  String get onboardingProcessing => '處理中…';

  @override
  String get onboardingLogTitle => '初始化日誌';

  @override
  String get onboardingStartingLog => '開始初始化執行時期…';

  @override
  String get onboardingReadyLog => '執行時期就緒 ✓';

  @override
  String onboardingErrorLog(Object msg) {
    return '錯誤: $msg';
  }

  @override
  String get onboardingSdkTitle => '安裝 ErisPulse SDK';

  @override
  String onboardingSdkPythonMissing(Object path) {
    return '未找到捆綁的 Python: $path';
  }

  @override
  String onboardingSdkInstalled(Object version) {
    return 'ErisPulse $version 已安裝';
  }

  @override
  String get onboardingSdkChooseVersion => '選擇要安裝的版本';

  @override
  String get onboardingSdkInstall => '安裝';

  @override
  String get onboardingSdkUseInstalled => '使用已安裝版本';

  @override
  String get onboardingSdkInstalling => '正在安裝…';

  @override
  String get onboardingSdkVersionFailed => '取得版本失敗，請檢查網路';

  @override
  String get onboardingSdkRefresh => '重新整理';

  @override
  String get onboardingSdkContinue => '進入';

  @override
  String get onboardingPythonRelease => '釋放內建 Python';

  @override
  String get onboardingPythonReleasing => '正在釋放 Python 環境…';

  @override
  String get onboardingPythonReady => '已就緒';

  @override
  String get onboardingPythonIntro => 'App 內建了 Python 環境，釋放後即可開始使用。';

  @override
  String get onboardingPythonFailed => '內建 Python 釋放失敗，請重試。';

  @override
  String get homeBannerNeedSdk => '需要安裝 ErisPulse SDK';

  @override
  String get createTitle => '建立一個 ErisPulse 實例';

  @override
  String get createSubtitle => '本機實例在手機內獨立執行；\n遠端實例連線到你部署在其他主機的實例。';

  @override
  String get createNameLabel => '實例名稱 *';

  @override
  String get createNameHint => '例如：我的機器人';

  @override
  String get createNameHelper => '用於在清單中區分不同實例';

  @override
  String get createNameRequired => '名稱不能為空';

  @override
  String get createNameTooLong => '名稱過長（最多 24 字元）';

  @override
  String get createUrlLabel => 'Dashboard 位址 *';

  @override
  String get createUrlHelper => '對方實例的 Dashboard 基底位址';

  @override
  String get createUrlRequired => '位址不能為空';

  @override
  String get createUrlScheme => '需以 http:// 或 https:// 開頭';

  @override
  String get createTokenLabel => '存取權杖（選用）';

  @override
  String get createTokenHelper => '對方 Dashboard 的 token，用於探活與登入';

  @override
  String get createRuntimeLabel => '運行時版本';

  @override
  String get createRuntimeDefault => '使用全局預設';

  @override
  String get createSdkVersionLabel => 'ErisPulse SDK 版本';

  @override
  String get createSdkVersionHelper => '安裝到該實例自己的虛擬環境中';

  @override
  String get createEnvTitle => '環境來源';

  @override
  String get createEnvFresh => '全新環境';

  @override
  String get createEnvFreshDesc => '用所選 SDK 版本新建獨立環境';

  @override
  String get createEnvClone => '基於已有實例';

  @override
  String get createEnvCloneDesc => '複製某個已有實例的環境（SDK 版本與已裝包）';

  @override
  String get createEnvCloneSource => '源實例';

  @override
  String get createEnvCloneNeedSource => '請選擇源實例';

  @override
  String get createPreparingEnv => '正在準備環境';

  @override
  String get createEnvReady => '環境準備完成';

  @override
  String get createEnvFailed => '環境準備失敗';

  @override
  String get createEnvCopying => '正在複製來源實例環境（venv）…';

  @override
  String createEnvCopyProgress(Object done, Object total) {
    return '已複製 $done / $total 個檔案';
  }

  @override
  String get createEnvPleaseWait => '環境準備中，可能需要一點時間，請勿關閉視窗';

  @override
  String get createPortLabel => '監聽連接埠 *';

  @override
  String get createPortHelper => '每個實例獨立連接埠，預設自動分配';

  @override
  String get createPortRequired => '連接埠不能為空';

  @override
  String get createPortRange => '連接埠需在 1024-65535 之間';

  @override
  String get createRemoteNote => '遠端實例執行在對方主機，App 透過其 Dashboard 檢視與管理。';

  @override
  String get createLocalNote => '建立後實例處於「已停止」狀態，可在詳情頁啟動。';

  @override
  String createCreated(Object name) {
    return '實例「$name」建立成功';
  }

  @override
  String get createFailed => '建立失敗';

  @override
  String get createFailedRetry => '建立失敗，請重試';

  @override
  String get detailSystemResource => '系統資源';

  @override
  String get detailResourceHint => '實例啟動後顯示 Dashboard 系統資源';

  @override
  String get detailMemory => '記憶體';

  @override
  String get detailUptime => '執行時間';

  @override
  String get detailThreads => '執行緒';

  @override
  String get detailCores => '核心數';

  @override
  String get detailAddress => '位址';

  @override
  String get detailPort => '連接埠';

  @override
  String get detailRuntimeLabel => '執行環境';

  @override
  String get detailTapToReveal => '點擊檢視並複製';

  @override
  String get detailTokenCopied => '存取權杖已複製';

  @override
  String get detailRefreshState => '重新整理狀態';

  @override
  String get detailNotFound => '實例不存在';

  @override
  String get detailRecentEvents => '最近事件';

  @override
  String get detailNoEvents => '暫無事件，實例啟動後會記錄框架/轉接器事件';

  @override
  String get detailOpenDashboard => '開啟 Dashboard';

  @override
  String get detailTabOverview => '概覽';

  @override
  String get detailTabModules => '模組';

  @override
  String get detailTabAdapters => '配接器';

  @override
  String get detailTabConfig => '組態';

  @override
  String get detailTabFiles => '檔案';

  @override
  String get detailTabLogs => '日誌';

  @override
  String get detailTabPackages => '套件';

  @override
  String get detailTabEvents => '事件流';

  @override
  String get detailTabAudit => '稽核';

  @override
  String get eventsFilterType => '類型';

  @override
  String get auditTitle => '稽核日誌';

  @override
  String get auditEmpty => '暫無稽核日誌';

  @override
  String get detailTabEmpty => '暫無內容';

  @override
  String get detailClearLogs => '清空日誌';

  @override
  String get detailAuthInvalid => '存取權杖無效或已過期，請檢查實例權杖';

  @override
  String get detailConfigSource => '原始碼';

  @override
  String get detailConfigEdit => '編輯';

  @override
  String get detailConfigSaved => '組態已儲存';

  @override
  String get detailPackageInstalled => '已安裝的套件';

  @override
  String get schemaConfigSave => '儲存';

  @override
  String get schemaConfigSaved => '組態已儲存';

  @override
  String get schemaConfigNoSchema => '無設定 schema';

  @override
  String get adapterConfigGlobal => '全域設定';

  @override
  String get adapterConfigAccounts => 'Bot 帳戶';

  @override
  String get adapterConfigAccountAdd => '新增帳戶';

  @override
  String get adapterConfigAccountName => '帳戶名稱';

  @override
  String get adapterConfigAccountNameRequired => '請輸入帳戶名稱';

  @override
  String get adapterConfigAccountDelete => '刪除帳戶';

  @override
  String adapterConfigAccountDeleteConfirm(String name) {
    return '刪除帳戶 $name？刪除後無法復原。';
  }

  @override
  String get adapterConfigAccountsEmpty => '尚無 Bot 帳戶';

  @override
  String get adapterConfigAccountSaved => '帳戶已保存';

  @override
  String get adapterConfigAccountAdded => '帳戶已建立';

  @override
  String get adapterConfigAccountDeleted => '帳戶已刪除';

  @override
  String get adapterConfigEnabled => '啟用';

  @override
  String get detailConfigCopied => '組態已複製';

  @override
  String get detailPackageName => '套件名稱';

  @override
  String get detailPackageInstall => '安裝套件';

  @override
  String get detailPackageUninstall => '卸載套件';

  @override
  String detailPackageUninstallConfirm(Object name) {
    return '卸載 $name？';
  }

  @override
  String get detailFrameworkUpdate => '更新框架';

  @override
  String get detailFrameworkUpdateConfirm => '將框架更新至最新版本？';

  @override
  String get detailFrameworkLatest => '已是最新';

  @override
  String get detailSdkRestart => '重啟 SDK';

  @override
  String get detailSdkRestartConfirm => '現在重啟 SDK？將中斷所有連線。';

  @override
  String get detailFileSave => '儲存';

  @override
  String get detailFileSaved => '已儲存';

  @override
  String detailFileDeleteConfirm(Object name) {
    return '刪除 $name？';
  }

  @override
  String get detailStartingToast => '正在啟動…';

  @override
  String get detailStoppedToast => '已請求停止';

  @override
  String get detailRestartingToast => '正在重新啟動…';

  @override
  String get detailUnreachableError => '實例未執行或 Dashboard 無法連線';

  @override
  String get detailOverview => '執行概覽';

  @override
  String get detailModules => '模組';

  @override
  String get detailAdapters => '轉接器';

  @override
  String detailEnabledCount(Object count) {
    return '已啟用 $count';
  }

  @override
  String detailRunningCount(Object count) {
    return '執行 $count';
  }

  @override
  String dashboardLoadFailed(Object code) {
    return '載入失敗（$code）';
  }

  @override
  String get dashboardAccessKey => '存取金鑰';

  @override
  String get dashboardAccessKeyCopied => '存取金鑰已複製';

  @override
  String get dashboardTokenCopied => '存取權杖已複製，可貼上到登入頁';

  @override
  String get dashboardExternalFailed => '無法開啟外部瀏覽器';

  @override
  String get dashboardCopyTokenTooltip => '複製存取權杖';

  @override
  String get dashboardExternalOpen => '以外部瀏覽器開啟';

  @override
  String get dashboardCheckHint => '請確認實例已啟動，且網路可存取該位址';

  @override
  String get settingsAppearance => '外觀';

  @override
  String get settingsThemeSystem => '跟隨系統';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsLangSystem => '跟隨系統';

  @override
  String get settingsLangZh => '簡體中文';

  @override
  String get settingsLangZhHant => '繁體中文';

  @override
  String get settingsLangEn => 'English';

  @override
  String get settingsLangJa => '日本語';

  @override
  String get settingsLangRu => 'Русский';

  @override
  String get settingsDownloadSource => '下載源';

  @override
  String get settingsDownloadGithub => 'GitHub 官方';

  @override
  String get settingsDownloadGhfast => 'GitHub 鏡像 (ghfast.top)';

  @override
  String get settingsDownloadGhproxy => 'GitHub 鏡像 (gh-proxy.com)';

  @override
  String get settingsPypiSource => 'PyPI 鏡像源';

  @override
  String get settingsPypiOfficial => 'PyPI 官方';

  @override
  String get settingsPypiTsinghua => '清華鏡像';

  @override
  String get settingsPypiAliyun => '阿里雲鏡像';

  @override
  String get settingsRuntime => '執行時期';

  @override
  String get settingsRootfsTitle => '執行環境 (rootfs)';

  @override
  String settingsRuntimeReady(Object version) {
    return '捆綁 Python + ErisPulse $version';
  }

  @override
  String get settingsRuntimeVersion => '運行時版本';

  @override
  String get settingsRuntimeDownload => '下載執行環境';

  @override
  String get runtimeManagerTitle => '執行環境管理';

  @override
  String get runtimeManagerInstalled => '已安裝的執行環境';

  @override
  String get runtimeManagerAvailable => '可下載版本';

  @override
  String get runtimeManagerEmpty => '暫無已安裝的執行環境';

  @override
  String get runtimeManagerLoading => '正在取得版本…';

  @override
  String get runtimeManagerActivate => '啟動';

  @override
  String get runtimeManagerActive => '已啟動';

  @override
  String get runtimeManagerPath => '執行環境目錄';

  @override
  String runtimeManagerDeleteConfirm(Object version) {
    return '刪除執行環境 v$version？此操作無法復原。';
  }

  @override
  String get runtimeManagerDesc => '內建 Python 與各實例環境管理';

  @override
  String get runtimeManagerInstances => '實例環境';

  @override
  String get runtimeManagerPythonMissing => '內建 Python 未就緒';

  @override
  String get settingsOpenSource => '開源地址';

  @override
  String get settingsRootfsReady => '已就緒';

  @override
  String get settingsRootfsNotReady => '未就緒';

  @override
  String get settingsAutoRestart => '當機自動重啟';

  @override
  String get settingsAutoRestartDesc => '實例異常結束後自動重新啟動';

  @override
  String get settingsStopAll => '停止所有實例';

  @override
  String get settingsStopAllDesc => '關閉全部本機實例程序';

  @override
  String get settingsStopAllConfirm => '確認停止全部正在執行的本機實例？';

  @override
  String get settingsStopAllAction => '全部停止';

  @override
  String get settingsData => '資料';

  @override
  String get settingsClearLogs => '清除除錯日誌';

  @override
  String get settingsClearLogsDesc => '清空執行時期調試日誌';

  @override
  String get settingsAbout => '關於';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsAboutApp => '關於 ErisPulse-App';

  @override
  String get settingsAboutSubtitle => '多端管理用戶端（啟動器 + Dashboard）';

  @override
  String get settingsAboutDialog =>
      'ErisPulse 多端管理用戶端。\n本機實例使用獨立的環境執行，管理介面由 Dashboard 提供。\n\nMIT License';

  @override
  String get debugTitle => '除錯資訊';

  @override
  String get debugCopyAllTooltip => '複製全部';

  @override
  String get debugClearLogsTooltip => '清除日誌';

  @override
  String get debugCopiedAll => '已複製完整除錯資訊';

  @override
  String get debugCopiedLogs => '已複製日誌';

  @override
  String get debugAppVersion => '應用版本';

  @override
  String get debugPackageName => '套件名稱';

  @override
  String get debugDeviceModel => '裝置型號';

  @override
  String get debugBrand => '品牌';

  @override
  String get debugAndroid => 'Android';

  @override
  String get debugAbi => 'ABI';

  @override
  String get debugSystem => '系統';

  @override
  String get debugNativeLib => 'native lib';

  @override
  String get debugRootfs => 'rootfs';

  @override
  String get debugRootfsError => 'rootfs 錯誤';

  @override
  String get debugInstanceCount => '實例數量';

  @override
  String get debugInfoHeader => '== ErisPulse-App 除錯資訊 ==';

  @override
  String get debugReady => '就緒';

  @override
  String get debugNotReady => '未就緒';

  @override
  String get debugRootfsMessage => 'rootfs 訊息';

  @override
  String get debugLogHeader => '== 日誌 ==';

  @override
  String get debugNoLogs => '暫無日誌\n啟動實例後，proot 程序輸出將即時顯示在這裡';

  @override
  String get debugProcessLogs => '程序日誌';

  @override
  String get logsSoft => '軟日誌';

  @override
  String get logsProcess => '程序日誌';

  @override
  String get logsSearch => '搜尋';

  @override
  String get logsFilterModule => '模組';

  @override
  String get logsFilteredEmpty => '沒有符合目前篩選條件的日誌';

  @override
  String get logsProcessEmptyTitle => '暫無程序日誌';

  @override
  String get logsProcessEmptySubtitle => '實例執行時的原始輸出（stdout/stderr）將即時顯示在這裡';

  @override
  String get logsSortNewestTop => '最新在頂';

  @override
  String get logsSortNewestBottom => '最新在底';

  @override
  String logsCopiedLines(Object count) {
    return '已複製 $count 行日誌';
  }

  @override
  String get logsFilter => '等級過濾';

  @override
  String get logsFilterAll => '全部';

  @override
  String get logsDownload => '下載日誌';

  @override
  String logsDownloaded(Object path) {
    return '已保存到 $path';
  }

  @override
  String get logsResume => '繼續';

  @override
  String get logsPause => '暫停';

  @override
  String get logsAutoScroll => '自動捲動';

  @override
  String logsLineCount(Object count) {
    return '$count 行';
  }

  @override
  String get logsEmptyTitle => '暫無日誌';

  @override
  String get logsEmptySubtitle => '啟動實例後，程序原始輸出將即時顯示在這裡';

  @override
  String get detailTabLifecycle => '生命週期';

  @override
  String get detailTabCommands => '指令';

  @override
  String get detailTabBots => '機器人';

  @override
  String get botsTitle => '機器人';

  @override
  String get botsEmpty => '暫無機器人';

  @override
  String get botsNeverActive => '從未活躍';

  @override
  String get botsJustNow => '剛剛活躍';

  @override
  String get botsMinutesAgo => '分鐘前';

  @override
  String get botsHoursAgo => '小時前';

  @override
  String get botsDaysAgo => '天前';

  @override
  String get lifecycleFilterType => '類型';

  @override
  String get lifecycleFilteredEmpty => '沒有符合篩選條件的事件';

  @override
  String get lifecycleEmpty => '暫無生命週期事件';

  @override
  String get statsTitle => '訊息統計';

  @override
  String get statsTotalEvents => '總事件數';

  @override
  String get statsByType => '按類型';

  @override
  String get statsByPlatform => '按平台';

  @override
  String get statsTrend => '近 24 小時趨勢';

  @override
  String get commandsTitle => '指令管理';

  @override
  String get commandsGlobalSettings => '全域設定';

  @override
  String get commandsPrefix => '指令前綴';

  @override
  String get commandsSave => '儲存';

  @override
  String get commandsCaseSensitive => '前綴區分大小寫';

  @override
  String get commandsAllowSpacePrefix => '允許空格前綴';

  @override
  String get commandsMustAtBot => '必須 @機器人';

  @override
  String get commandsEmpty => '暫無指令';

  @override
  String get commandsEditTitle => '編輯指令';

  @override
  String get commandsEnabled => '已啟用';

  @override
  String get commandsAliases => '別名（逗號分隔）';

  @override
  String get commandsAllowedPlatforms => '允許的平台（逗號分隔）';

  @override
  String get commandsBlockedPlatforms => '禁止的平台（逗號分隔）';

  @override
  String get commandsTransformTo => '轉發為（留空表示不轉發）';

  @override
  String get commandsSaved => '已儲存';

  @override
  String get commandsEdit => '編輯';

  @override
  String get eventsBuilderView => '檢視';

  @override
  String get eventsBuilderTab => '建構器';

  @override
  String get eventsBuilderSubmitted => '事件已提交';

  @override
  String get eventsBuilderFailed => '提交失敗';

  @override
  String get eventsBuilderType => '事件類型';

  @override
  String get eventsBuilderDetailType => '子類型';

  @override
  String get eventsBuilderPlatform => '平台';

  @override
  String get eventsBuilderCustom => '自訂';

  @override
  String get eventsBuilderBot => '機器人';

  @override
  String get eventsBuilderSessionType => '工作階段類型';

  @override
  String get eventsBuilderSessionId => '工作階段 ID';

  @override
  String get eventsBuilderSegments => '訊息分段';

  @override
  String get eventsBuilderAddSegment => '新增分段';

  @override
  String get eventsBuilderOptional => '可選欄位';

  @override
  String get eventsBuilderAddField => '新增欄位';

  @override
  String get eventsBuilderPreview => 'JSON 預覽';

  @override
  String get eventsBuilderCopyJson => '複製 JSON';

  @override
  String get eventsBuilderCopied => '已複製';

  @override
  String get eventsBuilderSubmit => '提交事件';

  @override
  String get navGroupOverview => '概覽';

  @override
  String get navGroupEvents => '事件';

  @override
  String get navGroupExtensions => '擴充';

  @override
  String get navGroupManagement => '管理';

  @override
  String get navGroupOperations => '維運';

  @override
  String get detailTabStore => '模組商店';

  @override
  String get detailTabMonitor => '監控';

  @override
  String get storeBrowseTab => '商店';

  @override
  String get storePackagesTab => '套件管理';

  @override
  String get storeSearch => '搜尋模組、適配器…';

  @override
  String get storeTypeAll => '全部';

  @override
  String get storeTypeModule => '模組';

  @override
  String get storeTypeAdapter => '適配器';

  @override
  String get storeForceRefresh => '強制重新整理';

  @override
  String get storeInstalled => '已安裝';

  @override
  String get storeUpdateAvailable => '有更新';

  @override
  String get storeUpgrade => '升級';

  @override
  String get storeOfficial => '官方';

  @override
  String get storeDetail => '詳情';

  @override
  String get storeAuthor => '作者';

  @override
  String get storeLicense => '授權條款';

  @override
  String get storeHomepage => '首頁';

  @override
  String get storeRequires => '相依套件';

  @override
  String get storeVersions => '歷史版本';

  @override
  String get storeVersionInstall => '安裝此版本';

  @override
  String get storeEmpty => '商店為空';

  @override
  String get storeFilteredEmpty => '沒有符合的套件';

  @override
  String get storeMirror => 'pip 鏡像源（可選）';

  @override
  String get storeForce => '強制重裝';

  @override
  String get storeTaskRunning => '工作執行中…';

  @override
  String get storeTaskSuccess => '工作完成';

  @override
  String get storeTaskFailed => '工作失敗';

  @override
  String get storeCurrent => '目前';

  @override
  String get storeLatest => '最新';

  @override
  String get pkgInstalledTab => '已安裝';

  @override
  String get pkgUpdatesTab => '可更新';

  @override
  String get pkgInstallNewTab => '安裝新套件';

  @override
  String get pkgGitTab => 'Git 安裝';

  @override
  String get pkgUpgradeAll => '全部升級';

  @override
  String get pkgNoUpdates => '暫無可更新套件';

  @override
  String get pkgNoGit => '暫無 Git 套件';

  @override
  String get navGroupSystem => '系統';

  @override
  String get navGroupTools => '工具';

  @override
  String get moduleViewOpenHint => '該視窗由模組提供，在 Dashboard 中開啟渲染。';

  @override
  String get moduleViewOpenButton => '開啟模組視窗';

  @override
  String get storeTagFilter => '標籤篩選';

  @override
  String storeTagFilterCount(Object n) {
    return '標籤篩選 ($n)';
  }

  @override
  String get storeTagClear => '清除';

  @override
  String get createSubtitleDesktop => '本機實例在本機建立並獨立執行；\n遠端實例連線到你部署在其他主機的實例。';

  @override
  String get detailOnlineBots => '線上機器人';

  @override
  String get detailTotalEvents => '事件總數';

  @override
  String get dashboardLoadTimeout => '載入逾時：頁面未能完成載入，請重試或用瀏覽器開啟';

  @override
  String get closePromptTitle => '關閉 ErisPulse';

  @override
  String get closePromptMessage =>
      '還有實例在執行時可以最小化到系統匣讓它們繼續在背景執行；停止全部實例並退出會中斷機器人服務。';

  @override
  String get closeMinimizeTray => '最小化到系統匣';

  @override
  String get closeStopExit => '停止全部實例並退出';

  @override
  String get closeRemember => '記住我的選擇';

  @override
  String get settingsCloseBehavior => '關閉視窗行為';

  @override
  String get closeActionAsk => '每次詢問';
}
