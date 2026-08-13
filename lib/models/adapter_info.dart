/// 适配器信息 DTO。
library;

class AdapterInfo {
  /// 平台标识（如 `onebot11`、`telegram`、`yunhu`）
  final String platform;

  /// 是否启用
  final bool enabled;

  /// 是否在运行（已启动且未崩溃）
  final bool running;

  /// 模块/适配器类名
  final String? className;

  /// 版本号
  final String? version;

  /// 启动后 bot 账号列表（self_id 等）
  final List<BotAccount> bots;

  /// 简要状态描述
  final String? statusMessage;

  /// 是否声明了配置 schema
  final bool hasConfig;

  /// 能力列表
  final List<String> capabilities;

  AdapterInfo({
    required this.platform,
    required this.enabled,
    required this.running,
    this.className,
    this.version,
    this.bots = const [],
    this.statusMessage,
    this.hasConfig = false,
    this.capabilities = const [],
  });

  factory AdapterInfo.fromJson(Map<String, dynamic> json) {
    final botsRaw = json['bots'] as List? ?? [];
    return AdapterInfo(
      platform: json['platform']?.toString() ?? json['name']?.toString() ?? '',
      enabled: json['enabled'] as bool? ?? false,
      running: json['loaded'] as bool? ?? json['running'] as bool? ?? false,
      className: json['class']?.toString(),
      version: json['version']?.toString(),
      bots: botsRaw
          .map(
            (e) => e is Map<String, dynamic> ? BotAccount.fromJson(e) : null,
          )
          .whereType<BotAccount>()
          .toList(),
      statusMessage: json['status'] as String?,
      hasConfig: json['has_config'] as bool? ?? false,
      capabilities:
          (json['capabilities'] as List?)?.whereType<String>().toList() ??
              const [],
    );
  }

  static List<AdapterInfo> fromList(List<dynamic> list) {
    return list
        .map((e) => e is Map<String, dynamic> ? AdapterInfo.fromJson(e) : null)
        .whereType<AdapterInfo>()
        .toList();
  }
}

/// bot 账号信息（一个适配器可能登录多个账号）
class BotAccount {
  final String selfId;
  final String? nickname;
  final bool online;

  BotAccount({
    required this.selfId,
    this.nickname,
    required this.online,
  });

  factory BotAccount.fromJson(Map<String, dynamic> json) {
    // 后端字段：bot_id / status / last_active / info
    final info = json['info'] as Map?;
    return BotAccount(
      selfId: (json['bot_id'] ?? json['self_id'] ?? '').toString(),
      nickname: json['nickname'] as String? ?? (info?['nickname'] as String?),
      online:
          json['online'] as bool? ?? ((json['status'] as String?) == 'online'),
    );
  }
}
