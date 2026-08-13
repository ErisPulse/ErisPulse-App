/// Dashboard REST API 客户端。
///
/// 端点/请求体与 Dashboard 后端（Core.py 路由）逐项对齐：
///   - 所有端点前缀 `/Dashboard/api`（由 [Instance.apiUri] 拼接）
///   - 无统一响应信封：成功直接业务 JSON，失败 `{"error": ...}` + HTTP 状态码
///   - 鉴权统一 `Authorization: Bearer <token>`；401/403 抛 [ApiException]
///   - 模块/适配器启停统一走 `POST /modules/action {name, action, type}`
///   - 配置双模式：渲染走 `GET /config`（JSON 树）+ `PUT /config {key, value}`，
///     源码走 `GET/POST /config/source`（TOML 原文）
///   - 文件走 `/files/browse|read|write|delete`
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/adapter_info.dart';
import '../models/enums.dart';
import '../models/instance.dart';
import '../models/log_entry.dart';
import '../models/module_info.dart';
import '../models/system_info.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? endpoint;

  ApiException(this.message, {this.statusCode, this.endpoint});

  /// 是否为鉴权失败（token 无效/过期）
  bool get isAuth => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'ApiException($statusCode, $endpoint): $message';
}

class DashboardApi {
  /// 默认超时（手机本地回环，给短一点）
  static const _timeout = Duration(seconds: 5);

  final Instance instance;

  DashboardApi(this.instance);

  // 内部请求工具

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${instance.token}',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> _getJson(String path) async {
    final resp = await http
        .get(instance.apiUri(path), headers: _headers)
        .timeout(_timeout);
    return _parseJson(resp, path);
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final resp = await http
        .post(
          instance.apiUri(path),
          headers: {
            ..._headers,
            'Content-Type': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return _parseJson(resp, path);
  }

  Future<Map<String, dynamic>> _putJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final resp = await http
        .put(
          instance.apiUri(path),
          headers: {
            ..._headers,
            'Content-Type': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return _parseJson(resp, path);
  }

  Future<Map<String, dynamic>> _parseJson(
    http.Response resp,
    String path,
  ) async {
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw ApiException(
        'Token 无效或已过期',
        statusCode: resp.statusCode,
        endpoint: path,
      );
    }
    if (resp.statusCode >= 400) {
      var detail = resp.body.substring(0, resp.body.length.clamp(0, 200));
      try {
        final json = jsonDecode(resp.body);
        if (json is Map) {
          final msg = json['message'] ?? json['error'];
          if (msg is String && msg.isNotEmpty) detail = msg;
        }
      } catch (_) {}
      throw ApiException(
        'HTTP ${resp.statusCode}: $detail',
        statusCode: resp.statusCode,
        endpoint: path,
      );
    }
    try {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException('响应不是合法 JSON', endpoint: path);
    }
  }

  // 鉴权 / 探活

  /// 探活：返回 [InstanceHealth]
  static Future<InstanceHealth> ping(Instance instance) async {
    try {
      final resp = await http.get(
        instance.apiUri('/auth/status'),
        // 必须带 token：auth/status 无 token 返回 401
        headers: {'Authorization': 'Bearer ${instance.token}'},
      ).timeout(_timeout);
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        return InstanceHealth.unauthorized;
      }
      if (resp.statusCode == 200) {
        return InstanceHealth.healthy;
      }
      return InstanceHealth.unreachable;
    } on SocketException {
      return InstanceHealth.unreachable;
    } on http.ClientException {
      return InstanceHealth.unreachable;
    } on FormatException {
      return InstanceHealth.unreachable;
    } on Exception {
      return InstanceHealth.unreachable;
    }
  }

  // 系统 / 性能

  /// 系统占用快照（CPU/内存/运行时长）
  Future<SystemInfo> getSystemInfo() async {
    final json = await _getJson('/system');
    return SystemInfo.fromJson(json);
  }

  /// 更详细的性能（含历史均值等）
  Future<Map<String, dynamic>> getPerformance() => _getJson('/performance');

  /// 简要状态（用于卡片）
  Future<Map<String, dynamic>> getStatus() => _getJson('/status');

  // 生命周期 / 事件

  /// 最近事件列表
  Future<List<Map<String, dynamic>>> getEvents({
    int limit = 100,
  }) async {
    final json = await _getJson('/events');
    final list = json['events'] as List? ?? [];
    return list
        .map((e) => e is Map<String, dynamic> ? e : null)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> clearEvents() => _postJson('/events/clear');

  // 模块

  /// 模块列表（后端 /modules 混排返回 module + adapter 条目）
  Future<List<ModuleInfo>> getModules() async {
    final json = await _getJson('/modules');
    final list = json['modules'] as List? ?? json['data'] as List? ?? [];
    return ModuleInfo.fromList(list);
  }

  /// 执行模块/适配器动作（enable/disable/load/unload/reload）
  Future<void> setModuleAction(
    String name,
    String action, {
    String type = 'module',
    String? package,
  }) async {
    await _postJson(
      '/modules/action',
      body: {
        'name': name,
        'action': action,
        'type': type,
        if (package != null) 'package': package,
      },
    );
  }

  /// 启用 / 禁用模块
  Future<void> setModuleEnabled(String name, bool enabled) async {
    await setModuleAction(name, enabled ? 'enable' : 'disable');
  }

  /// 模块配置（schema 驱动表单数据源）
  Future<Map<String, dynamic>> getModuleConfig(String name) =>
      _getJson('/module/$name/config');

  /// 整组保存模块配置（浅合并）
  Future<void> saveModuleConfig(String name, Map<String, dynamic> values) =>
      _putJson('/module/$name/config', body: {'values': values});

  // 适配器

  /// 适配器列表（复用 /modules 混排，过滤 type=adapter）
  Future<List<AdapterInfo>> getAdapters() async {
    final json = await _getJson('/modules');
    final list = json['modules'] as List? ?? json['data'] as List? ?? [];
    return AdapterInfo.fromList(list);
  }

  /// 执行适配器动作（enable/disable/load/unload/reload）
  Future<void> setAdapterAction(String platform, String action) async {
    await setModuleAction(platform, action, type: 'adapter');
  }

  /// 启用 / 禁用适配器（disable 同时 shutdown）
  Future<void> setAdapterEnabled(String platform, bool enabled) async {
    await setAdapterAction(platform, enabled ? 'enable' : 'disable');
  }

  /// 启动适配器
  Future<void> startAdapter(String platform) =>
      setAdapterAction(platform, 'load');

  /// 停止适配器
  Future<void> stopAdapter(String platform) =>
      setAdapterAction(platform, 'unload');

  /// 重启适配器
  Future<void> restartAdapter(String platform) =>
      setAdapterAction(platform, 'reload');

  /// 适配器配置（schema 驱动表单数据源）
  Future<Map<String, dynamic>> getAdapterConfig(String platform) =>
      _getJson('/adapter/$platform/config');

  /// 整组保存适配器配置（浅合并）
  Future<void> saveAdapterConfig(
    String platform,
    Map<String, dynamic> values,
  ) =>
      _putJson('/adapter/$platform/config', body: {'values': values});

  // 配置

  /// 完整配置树（JSON，渲染模式；token 已被后端脱敏）
  Future<Map<String, dynamic>> getConfig() async {
    final json = await _getJson('/config');
    return json['config'] as Map<String, dynamic>? ?? {};
  }

  /// 设置配置项（点分 key + 值）
  Future<void> setConfig(String dotKey, dynamic value) async {
    await _putJson('/config', body: {'key': dotKey, 'value': value});
  }

  /// TOML 源码正文（源码模式；返回 content 而非 JSON 外壳）
  Future<String> getConfigSource() async {
    final json = await _getJson('/config/source');
    return json['content'] as String? ?? '';
  }

  /// 整文件保存 TOML 源码（写文件并 reload 配置）
  Future<void> saveConfigSource(String content) async {
    await _postJson('/config/source', body: {'content': content});
  }

  // 存储 KV

  Future<Map<String, dynamic>> getStorage() => _getJson('/storage');

  Future<void> setStorageKey(String key, dynamic value) async {
    await _postJson('/storage', body: {'key': key, 'value': value});
  }

  Future<void> deleteStorageKey(String key) async {
    await _postJson('/storage/delete', body: {'key': key});
  }

  // 日志

  /// 拉取历史日志
  Future<List<LogEntry>> getLogs({LogLevel? minLevel, int limit = 200}) async {
    final json = await _getJson('/logs');
    final list = json['logs'] as List? ?? [];
    var entries = LogEntry.fromList(list);
    if (minLevel != null) {
      entries = entries.where((e) => e.level.index >= minLevel.index).toList();
    }
    if (entries.length > limit) {
      entries = entries.sublist(entries.length - limit);
    }
    return entries;
  }

  Future<void> clearLogs() async => _postJson('/logs/clear');

  // 包管理（pip / uv）

  /// 已安装 pip 包列表
  Future<List<Map<String, dynamic>>> getPackages() async {
    final json = await _getJson('/packages');
    final list = json['packages'] as List? ?? [];
    return list
        .map((e) => e is Map<String, dynamic> ? e : null)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// 安装包（可多个，支持 `pkg==1.0` / `git+...`）
  Future<void> installPackages(List<String> names, {bool force = false}) async {
    await _postJson(
      '/packages/install',
      body: {
        'packages': names,
        'force': force,
      },
    );
  }

  Future<void> uninstallPackage(String name) async {
    await _postJson('/packages/uninstall', body: {'package': name});
  }

  // 框架自更新 / 重启

  Future<List<Map<String, dynamic>>> getFrameworkVersions() async {
    final json = await _getJson('/framework/versions');
    final list = json['versions'] as List? ?? [];
    return list
        .map((e) => e is Map<String, dynamic> ? e : null)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// 框架状态（current/latest/versions 完整响应）
  Future<Map<String, dynamic>> getFrameworkStatus() =>
      _getJson('/framework/versions');

  Future<void> updateFramework({String? version, String lang = 'zh'}) async {
    await _postJson(
      '/framework/update',
      body: {
        'version': version,
        'lang': lang,
      },
    );
  }

  /// 软重启 SDK（保留进程）
  Future<void> restartSdk() => _postJson('/restart');

  // 文件管理（rootfs 相对路径）

  /// 列目录（browse 端点，解析 entries）
  Future<List<Map<String, dynamic>>> listFiles({String? path}) async {
    final p = (path == null || path.isEmpty) ? '.' : path;
    final json = await _getJson('/files/browse?path=$p');
    final list = json['entries'] as List? ?? [];
    return list
        .map((e) => e is Map<String, dynamic> ? e : null)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// 读文件文本
  Future<String> readFile(String path) async {
    final json = await _getJson('/files/read?path=$path');
    return json['content'] as String? ?? '';
  }

  /// 写文件
  Future<void> writeFile(String path, String content) async {
    await _postJson('/files/write', body: {'path': path, 'content': content});
  }

  /// 删除文件 / 目录（批量）
  Future<void> deleteFiles(List<String> paths) async {
    await _postJson('/files/delete', body: {'paths': paths});
  }
}
