/// ErisPulse 实例数据模型。
///
/// 一个 Instance 表示一个 ErisPulse 运行单元：
/// - 本地实例（[isRemote] == false）：运行在手机 rootfs 内，独立端口与 token
/// - 远程实例（[isRemote] == true）：运行在其它主机，通过 [remoteUrl] 访问 Dashboard
///
/// 多个实例共享同一个 Ubuntu rootfs 与 Python 解释器，但运行时相互隔离
/// （不同进程 / 不同工作目录 / 不同端口）。
library;

import 'enums.dart';

class Instance {
  /// 唯一标识
  final String id;

  /// 用户可读名称（如"小机器人"）
  String name;

  /// 本地监听端口（如 8000、8001...）。远程实例此字段为 0。
  ///
  /// 由 InstanceManager 在创建时分配，避免冲突。
  int port;

  /// rootfs 内的工作目录绝对路径（如 `/home/ep/instances/bot1`）。
  /// 远程实例为空。
  String workingDir;

  /// Dashboard Bearer token
  ///
  /// 持久化时由 InstanceManager 通过 flutter_secure_storage 单独保管。
  String token;

  /// 是否为远程实例（不在本机运行）
  bool isRemote;

  /// 远程实例的 Dashboard 基地址（如 `http://192.168.1.10:8000`）
  String? remoteUrl;

  /// 创建时间（ISO 8601 UTC）
  final String createdAt;

  /// 最后一次启动时间（ISO 8601 UTC），可能为 null
  String? lastStartedAt;

  /// 运行状态（仅运行期维护）
  InstanceStatus status;

  /// 健康度（仅运行期维护，靠 DashboardApi.ping 更新）
  InstanceHealth health;

  /// 子进程 PID（仅运行期，Android 端通过 proot 启动后回填）
  int? pid;

  /// 错误信息（status == error 时填写）
  String? errorMessage;

  Instance({
    required this.id,
    required this.name,
    required this.port,
    required this.workingDir,
    required this.token,
    required this.createdAt,
    this.isRemote = false,
    this.remoteUrl,
    this.lastStartedAt,
    this.status = InstanceStatus.stopped,
    this.health = InstanceHealth.unknown,
    this.pid,
    this.errorMessage,
  });

  factory Instance.fromJson(Map<String, dynamic> json) {
    return Instance(
      id: json['id'] as String,
      name: json['name'] as String,
      port: (json['port'] as num).toInt(),
      workingDir: json['workingDir'] as String,
      token: '', // 由 InstanceManager 单独从 secure_storage 注入
      createdAt: json['createdAt'] as String,
      isRemote: json['isRemote'] as bool? ?? false,
      remoteUrl: json['remoteUrl'] as String?,
      lastStartedAt: json['lastStartedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'port': port,
        'workingDir': workingDir,
        'createdAt': createdAt,
        'isRemote': isRemote,
        if (remoteUrl != null) 'remoteUrl': remoteUrl,
        if (lastStartedAt != null) 'lastStartedAt': lastStartedAt,
      };

  /// Dashboard 基址（本地回环或远程地址）
  Uri get baseUrl => isRemote
      ? Uri.parse(remoteUrl ?? '')
      : Uri.parse('http://127.0.0.1:$port');

  /// Dashboard Web 界面地址（WebView 加载）
  Uri get dashboardUri => baseUrl.replace(path: '/Dashboard');

  /// API 完整 URL（拼接路径）
  Uri apiUri(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return baseUrl.replace(path: '/Dashboard/api$p');
  }

  /// Dashboard WebSocket URL（用于日志/事件流）
  Uri get wsUrl => baseUrl.replace(
        scheme: 'ws',
        path: '/Dashboard/ws',
        queryParameters: {'token': token},
      );

  /// 展示用地址
  String get displayAddress =>
      isRemote ? (remoteUrl ?? '远程') : '127.0.0.1:$port';

  /// 状态对应的简短中文标签
  String get statusLabel => switch (status) {
        InstanceStatus.stopped => '已停止',
        InstanceStatus.starting => '启动中',
        InstanceStatus.running => '运行中',
        InstanceStatus.error => '异常',
        InstanceStatus.destroying => '销毁中',
      };

  /// 展示用状态标签。
  ///
  /// 远程实例没有本地进程，状态由健康度表达（在线/离线/连接中）；
  /// 本地实例用进程状态。
  String get displayStatusLabel {
    if (isRemote) {
      return switch (health) {
        InstanceHealth.healthy => '在线',
        InstanceHealth.booting => '连接中',
        InstanceHealth.unreachable => '离线',
        InstanceHealth.unauthorized => 'Token 无效',
        InstanceHealth.unknown => '未知',
      };
    }
    return statusLabel;
  }

  Instance copyWith({
    String? name,
    int? port,
    String? workingDir,
    String? token,
    bool? isRemote,
    String? remoteUrl,
    String? lastStartedAt,
    InstanceStatus? status,
    InstanceHealth? health,
    int? pid,
    String? errorMessage,
    bool clearPid = false,
    bool clearError = false,
  }) {
    return Instance(
      id: id,
      name: name ?? this.name,
      port: port ?? this.port,
      workingDir: workingDir ?? this.workingDir,
      token: token ?? this.token,
      isRemote: isRemote ?? this.isRemote,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      createdAt: createdAt,
      lastStartedAt: lastStartedAt ?? this.lastStartedAt,
      status: status ?? this.status,
      health: health ?? this.health,
      pid: clearPid ? null : (pid ?? this.pid),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Instance && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Instance($name, port=$port, status=$status)';
}
