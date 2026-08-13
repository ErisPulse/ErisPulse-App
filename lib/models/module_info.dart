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

  ModuleInfo({
    required this.name,
    this.type = 'module',
    required this.enabled,
    required this.loaded,
    this.version,
    this.description,
    this.author,
  });

  factory ModuleInfo.fromJson(Map<String, dynamic> json) {
    return ModuleInfo(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'module',
      enabled: json['enabled'] as bool? ?? false,
      loaded: json['loaded'] as bool? ?? false,
      version: json['version'] as String?,
      description: json['description'] as String?,
      author: json['author'] as String?,
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
