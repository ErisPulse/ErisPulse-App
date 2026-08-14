/// 实例管理服务：元数据 CRUD + 持久化 + 端口分配。
///
/// 进程启停由 runtime 层负责，本服务只管实例元数据。
library;

import 'dart:convert';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';
import '../models/instance.dart';

const _kInstancesKey = 'erispulse.instances.v2';
const _kTokenKeyPrefix = 'erispulse.instance.token.';

/// 默认起始端口（8000）；依次递增分配
const int kDefaultStartPort = 8000;

class InstanceManager extends ChangeNotifier {
  InstanceManager({
    SharedPreferencesAsync? prefs,
    FlutterSecureStorage? secureStorage,
  })  : _prefs = prefs ?? SharedPreferencesAsync(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final SharedPreferencesAsync _prefs;
  final FlutterSecureStorage _secureStorage;

  List<Instance> _instances = [];
  List<Instance> get instances => List.unmodifiable(_instances);

  /// 实例数量
  int get count => _instances.length;

  /// 异步初始化：加载持久化的实例元数据 + token
  Future<void> load() async {
    final raw = await _prefs.getString(_kInstancesKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final loaded = <Instance>[];
      for (final item in list) {
        final inst = Instance.fromJson(item as Map<String, dynamic>);
        final token =
            await _secureStorage.read(key: _kTokenKeyPrefix + inst.id);
        inst.token = token ?? '';
        loaded.add(inst);
      }
      _instances = loaded;
      notifyListeners();
    } catch (e) {
      debugPrint('InstanceManager.load failed: $e');
    }
  }

  /// 创建新实例。
  ///
  /// 本地实例：工作目录由调用方决定（通常基于 rootfs + 名字生成），
  /// 端口由本方法自动分配（避开已用）。
  /// 远程实例：仅记录 [remoteUrl]（Dashboard 基地址）与可选 token，
  /// 不分配端口、无工作目录、不参与本地启停。
  Future<Instance> createInstance({
    required String name,
    String? workingDir,
    String? token,
    int? preferredPort,
    bool isRemote = false,
    String? remoteUrl,
    String? runtimeVersion,
  }) async {
    if (_instances.any((n) => n.name.toLowerCase() == name.toLowerCase())) {
      throw ArgumentError('实例名称已存在: $name');
    }
    if (isRemote && (remoteUrl == null || remoteUrl.trim().isEmpty)) {
      throw ArgumentError('远程实例必须填写地址');
    }

    final port = isRemote ? 0 : (preferredPort ?? _allocatePort());
    final inst = Instance(
      id: _generateId(),
      name: name,
      port: port,
      workingDir: workingDir ?? (isRemote ? '' : '/home/ep/instances/$name'),
      token: token ?? _generateToken(),
      createdAt: DateTime.now().toUtc().toIso8601String(),
      isRemote: isRemote,
      remoteUrl: isRemote ? remoteUrl!.trim() : null,
      runtimeVersion: runtimeVersion,
    );

    _instances = [..._instances, inst];
    await _persist();
    await _secureStorage.write(
      key: _kTokenKeyPrefix + inst.id,
      value: inst.token,
    );
    notifyListeners();
    return inst;
  }

  /// 删除实例（仅删除元数据；停止进程由 RuntimeManager 处理）
  Future<void> removeInstance(String id) async {
    _instances = _instances.where((n) => n.id != id).toList();
    await _persist();
    await _secureStorage.delete(key: _kTokenKeyPrefix + id);
    notifyListeners();
  }

  /// 重命名
  Future<void> rename(String id, String newName) async {
    await _update(id, name: newName);
  }

  /// 记录实例 venv 中安装的 ErisPulse SDK 版本（创建时写入首次安装版本，
  /// 框架更新后由 PackagesTab 同步）
  Future<void> setInstanceRuntime(String id, String? version) async {
    await _update(
      id,
      runtimeVersion: version,
      clearRuntimeVersion: version == null,
    );
  }

  /// 更新实例字段
  Future<void> _update(
    String id, {
    String? name,
    int? port,
    String? workingDir,
    String? token,
    String? lastStartedAt,
    InstanceStatus? status,
    InstanceHealth? health,
    int? pid,
    String? errorMessage,
    String? runtimeVersion,
    bool clearPid = false,
    bool clearError = false,
    bool clearRuntimeVersion = false,
  }) async {
    final idx = _instances.indexWhere((n) => n.id == id);
    if (idx < 0) throw ArgumentError('实例不存在: $id');

    final next = _instances[idx].copyWith(
      name: name,
      port: port,
      workingDir: workingDir,
      token: token,
      lastStartedAt: lastStartedAt,
      status: status,
      health: health,
      pid: pid,
      errorMessage: errorMessage,
      runtimeVersion: runtimeVersion,
      clearPid: clearPid,
      clearError: clearError,
      clearRuntimeVersion: clearRuntimeVersion,
    );
    _instances = List.of(_instances)..[idx] = next;

    await _persist();
    if (token != null && token != _instances[idx].token) {
      await _secureStorage.write(key: _kTokenKeyPrefix + id, value: token);
    }
    notifyListeners();
  }

  /// 运行期状态更新（不持久化）
  ///
  /// status / health / pid / errorMessage 是运行期状态，
  /// 每次进程状态变化调用此方法，触发 UI 刷新但不写盘。
  void setRuntimeState(
    String id, {
    InstanceStatus? status,
    InstanceHealth? health,
    int? pid,
    String? errorMessage,
    bool clearPid = false,
    bool clearError = false,
  }) {
    final idx = _instances.indexWhere((n) => n.id == id);
    if (idx < 0) return;

    _instances[idx] = _instances[idx].copyWith(
      status: status,
      health: health,
      pid: pid,
      errorMessage: errorMessage,
      clearPid: clearPid,
      clearError: clearError,
    );
    notifyListeners();
  }

  /// 标记实例已启动（持久化 lastStartedAt 与 pid，桌面端重启后识别存活实例）
  Future<void> markStarted(String id, {required int pid}) async {
    await _update(
      id,
      lastStartedAt: DateTime.now().toUtc().toIso8601String(),
      pid: pid,
    );
  }

  /// 标记实例已不再运行（清除持久化 pid）
  Future<void> markNotRunning(String id) async {
    await _update(id, clearPid: true);
  }

  /// 通过 id 查询
  Instance? findById(String id) {
    for (final i in _instances) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// 通过端口查询（用于 RuntimeManager 回调找到对应实例）
  Instance? findByPort(int port) {
    for (final i in _instances) {
      if (i.port == port) return i;
    }
    return null;
  }

  Future<void> _persist() async {
    final raw = jsonEncode(_instances.map((i) => i.toJson()).toList());
    await _prefs.setString(_kInstancesKey, raw);
  }

  /// 分配下一个可用端口（从 8000 递增）
  int _allocatePort() {
    final used = _instances.map((i) => i.port).toSet();
    for (var p = kDefaultStartPort; p < 65535; p++) {
      if (!used.contains(p)) return p;
    }
    throw StateError('无可用端口');
  }

  static String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    return List.generate(32, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  static String _generateToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
    return List.generate(43, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
