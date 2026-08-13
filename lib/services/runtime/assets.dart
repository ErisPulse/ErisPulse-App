// 运行时发布资产常量。
//
// App 运行 ErisPulse 实例需要 proot / busybox / rootfs 三样资产，
// 获取优先级：app 私有目录 → APK assets → Releases 下载。
// 在线 / 离线两个 flavor 的区别只在 assets 是否内置这些文件。

/// App 构建 flavor。
enum AppFlavor { online, offline }

/// 当前 flavor（由 `--dart-define=FLAVOR=online|offline` 注入）
const String _flavorDefine =
    String.fromEnvironment('FLAVOR', defaultValue: 'online');

const AppFlavor kFlavor =
    _flavorDefine == 'offline' ? AppFlavor.offline : AppFlavor.online;

/// GitHub Releases 下载基址。
///
/// 可通过 `--dart-define=ERISPULSE_RELEASE_BASE=https://...` 覆盖
/// （例如自建镜像 / 测试服）。
const String kReleaseBase = String.fromEnvironment(
  'ERISPULSE_RELEASE_BASE',
  defaultValue:
      'https://github.com/ErisPulse/ErisPulse-App/releases/latest/download',
);

/// GitHub Releases 下载源标识（持久化于 AppSettings，仅用于移动端 rootfs/proot/busybox 下载）：
/// - `github`：GitHub 官方直连
/// - `ghfast`：ghfast.top 加速镜像
/// - `ghproxy`：gh-proxy.com 加速镜像
const String kDownloadSourceGithub = 'github';
const String kDownloadSourceGhfast = 'ghfast';
const String kDownloadSourceGhproxy = 'ghproxy';

/// PyPI 镜像源标识（桌面端 pip 安装 ErisPulse 使用）
const String kPypiSourceOfficial = 'pypi';
const String kPypiSourceTsinghua = 'tsinghua';
const String kPypiSourceAliyun = 'aliyun';

/// PyPI 镜像源 → 索引 URL
const Map<String, String> kPypiIndexUrl = {
  kPypiSourceOfficial: 'https://pypi.org/simple',
  kPypiSourceTsinghua: 'https://pypi.tuna.tsinghua.edu.cn/simple',
  kPypiSourceAliyun: 'https://mirrors.aliyun.com/pypi/simple',
};

/// 解析 PyPI 镜像源为索引 URL（未知源回退官方）
String pypiIndexUrl(String source) =>
    kPypiIndexUrl[source] ?? kPypiIndexUrl[kPypiSourceOfficial]!;

/// 对任意 GitHub 下载 URL 应用下载源镜像前缀（rootfs / 二进制下载）。
String mirrorUrl(String source, String url) {
  return switch (source) {
    kDownloadSourceGhfast => 'https://ghfast.top/$url',
    kDownloadSourceGhproxy => 'https://gh-proxy.com/$url',
    _ => url,
  };
}

/// 根据下载源解析最终 Releases 基址（镜像 = 前缀 + GitHub 官方地址）。
String resolveReleaseBase(String source) => mirrorUrl(source, kReleaseBase);

/// rootfs 发行版本（与 CI 构建产物对应）。
const String kRootfsVersion = '1.0.0';

/// 项目开源地址（设置页"开源地址"）。
const String kOpenSourceUrl = 'https://github.com/ErisPulse/ErisPulse-App';

// 资产 / 文件名常量

/// assets 中运行时二进制目录（CI 注入 proot / busybox）
const String kAssetRuntimeDir = 'assets/runtime';

/// assets 中 rootfs 目录（offline flavor CI 注入 tar.xz）
const String kAssetRootfsDir = 'assets/rootfs';

/// assets 中内置 Python 目录（CI 注入 python-build-standalone 的 tar.gz）
const String kAssetPythonDir = 'assets/python';

/// assets 中内置 Python 压缩包名模板（`python-{platform}-{arch}.tar.gz`，
/// 内容为 python-build-standalone 的 install_only 发布产物）
String bundledPythonAssetName(String platformArch) =>
    'python-$platformArch.tar.gz';

/// app 私有目录中的文件名
const String kProotFileName = 'proot';
const String kBusyboxFileName = 'busybox';
const String kRootfsFileName = 'erispulse-rootfs-aarch64.tar.gz';

/// Releases 中 rootfs 资产名
String get rootfsReleaseAsset => kRootfsFileName;

/// Releases 中 proot / busybox 资产名（与 assets 同名）
const String prootReleaseAsset = 'proot-aarch64';
const String busyboxReleaseAsset = 'busybox-aarch64';

// 实例配置模板

/// 生成一个实例的 config.toml 内容。
///
/// 结构基于 SDK `frame_config.DEFAULT_ERISPULSE_CONFIG`；
/// 缺失的键由 SDK 在 `get_erispulse_config()` 自动补全。
/// Dashboard token 预写入 `[Dashboard]`，避免首次启动自动生成导致 App 未知。
String buildInstanceConfigToml({
  required int port,
  required String token,
  String logLevel = 'INFO',
}) {
  return '''
# 由 ErisPulse-App 生成，请勿手动编辑
[ErisPulse.server]
host = "127.0.0.1"
port = $port
auto_start = true

[ErisPulse.logger]
level = "$logLevel"

[ErisPulse.modules.status]
Dashboard = true

[Dashboard]
token = "$token"
''';
}
