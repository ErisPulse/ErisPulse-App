/// 实例管理服务：元数据 CRUD + 持久化 + 端口分配。
///
/// 进程启停由 runtime 层负责，本服务只管实例元数据。
library;

import 'dart:convert';
import 'dart:io' show InternetAddress, ServerSocket;
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';
import '../models/instance.dart';

const _kInstancesKey = 'erispulse.instances.v2';
const _kInstancesBackupKey = 'erispulse.instances.v2.corrupt-backup';
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

  /// 异步初始化：加载持久化的实例元数据 + token。
  ///
  /// 单条记录损坏只跳过该条（原始数据先备份），不影响其余实例；
  /// 整体解析失败（非 JSON 等）保持空列表。
  Future<void> load() async {
    final raw = await _prefs.getString(_kInstancesKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final loaded = <Instance>[];
      var corrupted = 0;
      for (final item in list) {
        try {
          final inst = Instance.fromJson(item as Map<String, dynamic>);
          final token =
              await _secureStorage.read(key: _kTokenKeyPrefix + inst.id);
          inst.token = token ?? '';
          loaded.add(inst);
        } catch (e) {
          corrupted++;
          debugPrint('InstanceManager.load: 跳过损坏的实例记录: $e');
        }
      }
      // 有损坏记录时备份原始数据：后续 _persist 会覆盖原 key，
      // 没有备份的话损坏条目（可能只是个别字段异常）将无法找回
      if (corrupted > 0) {
        await _prefs.setString(_kInstancesBackupKey, raw);
        debugPrint(
          'InstanceManager.load: $corrupted 条记录损坏，'
          '原始数据已备份到 $_kInstancesBackupKey',
        );
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

    // 指定端口时先探测真实占用：避免与残留进程/其它程序撞车
    if (!isRemote && preferredPort != null) {
      if (await _portInUse(preferredPort)) {
        throw ArgumentError('端口已被占用: $preferredPort');
      }
    }

    final id = _generateId();
    final port = isRemote ? 0 : (preferredPort ?? await _allocatePort());
    // 工作目录带短 id：同名重建不再继承已删除实例的残留数据
    //（目录由创建时间唯一决定，与名字无关；桌面端实际使用按 id 的环境目录）
    final inst = Instance(
      id: id,
      name: name,
      port: port,
      workingDir: workingDir ??
          (isRemote ? '' : '/home/ep/instances/$name-${id.substring(0, 8)}'),
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

  /// 更新实例 token（如远程实例轮换凭据），并同步写入 secure storage
  Future<void> updateToken(String id, String token) =>
      _update(id, token: token);

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

    final prev = _instances[idx];
    final next = prev.copyWith(
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
    // 与更新前的旧值比较（_instances[idx] 已是替换后的新值，不能再用）
    if (token != null && token != prev.token) {
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

  /// 分配下一个可用端口（从 8000 递增）。
  ///
  /// 除避开 app 内已用端口外，还用 ServerSocket 试探系统真实占用：
  /// 被其它程序或已删除实例的残留进程占住的端口直接跳过，
  /// 避免新实例撞上旧进程（表现为"创建出来是之前的实例"）。
  Future<int> _allocatePort() async {
    final used = _instances.map((i) => i.port).toSet();
    for (var p = kDefaultStartPort; p < 65535; p++) {
      if (used.contains(p)) continue;
      if (!await _portInUse(p)) return p;
    }
    throw StateError('无可用端口');
  }

  /// 探测回环地址上 [port] 是否已被监听；探测失败（无权限等）按占用处理
  Future<bool> _portInUse(int port) async {
    try {
      final server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        port,
      );
      await server.close();
      return false;
    } catch (_) {
      return true;
    }
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
