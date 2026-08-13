/// Dashboard REST API 客户端。
///
/// 与 Dashboard 后端路由一一对应，按 UI 用途分组组织。
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
      throw ApiException(
        'HTTP ${resp.statusCode}: ${resp.body.substring(0, resp.body.length.clamp(0, 200))}',
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

  // 适配器 / Bot

  /// 适配器列表
  Future<List<AdapterInfo>> getAdapters() async {
    final json = await _getJson('/adapters');
    final list = json['adapters'] as List? ?? json['data'] as List? ?? [];
    return AdapterInfo.fromList(list);
  }

  /// 启用 / 禁用适配器
  Future<void> setAdapterEnabled(String platform, bool enabled) async {
    await _postJson('/adapter/$platform/config', body: {'enabled': enabled});
  }

  /// 重启适配器
  Future<void> restartAdapter(String platform) async {
    await _postJson('/adapter/$platform/restart');
  }

  /// 适配器配置（platform-specific）
  Future<Map<String, dynamic>> getAdapterConfig(String platform) =>
      _getJson('/adapter/$platform/config');

  Future<void> setAdapterConfig(
    String platform,
    Map<String, dynamic> config,
  ) =>
      _postJson('/adapter/$platform/config', body: config);

  // 模块

  /// 模块列表
  Future<List<ModuleInfo>> getModules() async {
    final json = await _getJson('/modules');
    final list = json['modules'] as List? ?? json['data'] as List? ?? [];
    return ModuleInfo.fromList(list);
  }

  /// 启用 / 禁用模块
  Future<void> setModuleEnabled(String name, bool enabled) async {
    await _postJson(
      '/modules/action',
      body: {
        'name': name,
        'action': enabled ? 'enable' : 'disable',
      },
    );
  }

  /// 模块配置
  Future<Map<String, dynamic>> getModuleConfig(String name) =>
      _getJson('/module/$name/config');

  Future<void> setModuleConfig(String name, Map<String, dynamic> config) =>
      _postJson('/module/$name/config', body: config);

  // 日志

  /// 拉取历史日志（用于初始化日志页）
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

  // 配置

  /// 完整 ErisPulse 配置树（JSON）
  Future<Map<String, dynamic>> getConfig() => _getJson('/config');

  /// TOML 源码（用于配置页代码视图）
  Future<String> getConfigSource() async {
    final resp = await http
        .get(instance.apiUri('/config/source'), headers: _headers)
        .timeout(_timeout);
    if (resp.statusCode != 200) {
      throw ApiException(
        '获取 TOML 源码失败',
        statusCode: resp.statusCode,
        endpoint: '/config/source',
      );
    }
    return resp.body;
  }

  /// 设置配置项（点分路径 + 值）
  Future<void> setConfig(String dotPath, dynamic value) async {
    await _postJson('/config', body: {'path': dotPath, 'value': value});
  }

  // 存储 KV

  Future<Map<String, dynamic>> getStorage() => _getJson('/storage');

  Future<void> setStorageKey(String key, dynamic value) async {
    await _postJson('/storage', body: {'key': key, 'value': value});
  }

  Future<void> deleteStorageKey(String key) async {
    await _postJson('/storage/delete', body: {'key': key});
  }

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

  // 包管理（pip / uv）

  Future<List<Map<String, dynamic>>> getPackages() async {
    final json = await _getJson('/packages');
    final list = json['packages'] as List? ?? [];
    return list
        .map((e) => e is Map<String, dynamic> ? e : null)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> installPackage(String name) async {
    await _postJson('/packages/install', body: {'name': name});
  }

  Future<void> uninstallPackage(String name) async {
    await _postJson('/packages/uninstall', body: {'name': name});
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

  Future<void> updateFramework({String? version}) async {
    await _postJson('/framework/update', body: {'version': version});
  }

  /// 软重启 SDK（保留进程）
  Future<void> restartSdk() => _postJson('/restart');

  // 文件管理

  /// 列目录
  Future<List<Map<String, dynamic>>> listFiles({String? path}) async {
    final json = await _getJson('/files?path=${path ?? '/'}');
    final list = json['files'] as List? ?? [];
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
}
