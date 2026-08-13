/// 模块信息 DTO。
library;

class ModuleInfo {
  /// 模块名（如 `Dashboard`、`MyEcho`）
  final String name;

  /// 条目类型：`module` / `adapter`（后端 /modules 混排返回）
  final String type;

  /// 是否启用
  final bool enabled;

  /// 是否已加载（模块：实例化成功；适配器：正在运行）
  final bool loaded;

  /// 版本号
  final String? version;

  /// 简要描述
  final String? description;

  /// 作者
  final String? author;

  /// 来源包名
  final String? package;

  /// 加载策略（后端为 dict：{lazy_load, priority, depends}）
  final Map<String, dynamic>? loadStrategy;

  /// 注册路由数
  final int routesCount;

  /// 注册视图数
  final int viewsCount;

  /// 是否声明了配置 schema
  final bool hasConfig;

  /// 适配器条目：登录账号数
  final int botsCount;

  /// 适配器条目：能力列表
  final List<String> capabilities;

  ModuleInfo({
    required this.name,
    this.type = 'module',
    required this.enabled,
    required this.loaded,
    this.version,
    this.description,
    this.author,
    this.package,
    this.loadStrategy,
    this.routesCount = 0,
    this.viewsCount = 0,
    this.hasConfig = false,
    this.botsCount = 0,
    this.capabilities = const [],
  });

  factory ModuleInfo.fromJson(Map<String, dynamic> json) {
    return ModuleInfo(
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'module',
      enabled: json['enabled'] as bool? ?? false,
      loaded: json['loaded'] as bool? ?? false,
      version: json['version']?.toString(),
      description: json['description']?.toString(),
      author: json['author']?.toString(),
      package: json['package']?.toString(),
      loadStrategy: json['load_strategy'] is Map
          ? Map<String, dynamic>.from(json['load_strategy'] as Map)
          : null,
      routesCount: json['routes_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      hasConfig: json['has_config'] as bool? ?? false,
      botsCount: json['bots_count'] as int? ?? 0,
      capabilities:
          (json['capabilities'] as List?)?.whereType<String>().toList() ??
              const [],
    );
  }

  /// 是否为模块条目（而非混排进来的适配器）
  bool get isModule => type != 'adapter';

  static List<ModuleInfo> fromList(List<dynamic> list) {
    return list
        .map((e) => e is Map<String, dynamic> ? ModuleInfo.fromJson(e) : null)
        .whereType<ModuleInfo>()
        .toList();
  }
}
