// InstanceManager 单元测试：token 持久化、损坏数据容错、同名重建与端口探测。
//
// 覆盖：
//   1. createInstance / updateToken 必须把 token 写入 secure storage
//      （回归：曾因与替换后的新值比较，条件恒 false 导致 token 永不落盘）
//   2. load() 遇到单条损坏记录只跳过该条，其余实例保留，
//      且原始数据先备份（后续 _persist 会覆盖原 key）
//   3. 同名重建：删除实例后用同名新建，工作目录不复用（不再继承残留数据）
//   4. 端口分配探测系统真实占用，跳过已被监听的端口

import 'dart:convert';
import 'dart:io' show InternetAddress, ServerSocket;

import 'package:erispulse_app/services/instance_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _kInstancesKey = 'erispulse.instances.v2';
const _kInstancesBackupKey = 'erispulse.instances.v2.corrupt-backup';
const _kTokenKeyPrefix = 'erispulse.instance.token.';

/// 内存版 secure storage：只实现测试用到的 read / write / delete
class _InMemorySecureStorage implements FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('createInstance 写入 token，updateToken 更新并重新写入 secure storage', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final storage = _InMemorySecureStorage();
    final mgr = InstanceManager(secureStorage: storage);

    final inst = await mgr.createInstance(name: 'bot', workingDir: '/w/bot');
    expect(
      storage.values['$_kTokenKeyPrefix${inst.id}'],
      isNotEmpty,
      reason: '创建实例时 token 应写入 secure storage',
    );

    // 回归：更新 token 必须重新落盘（曾因与替换后的新值比较恒为 false）
    await mgr.updateToken(inst.id, 'rotated-token');
    expect(storage.values['$_kTokenKeyPrefix${inst.id}'], 'rotated-token');
    expect(mgr.findById(inst.id)!.token, 'rotated-token');
  });

  test('load()：单条损坏只跳过该条，其余保留，原始数据先备份', () async {
    // 先通过真实 createInstance 生成一份合法的持久化 JSON
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final storage = _InMemorySecureStorage();
    final setup = InstanceManager(secureStorage: storage);
    await setup.createInstance(name: 'keep', workingDir: '/w/keep');
    final validRaw = await SharedPreferencesAsync().getString(_kInstancesKey);
    expect(validRaw, isNotNull);

    // 注入一条损坏记录（非 Map 元素）
    final list = jsonDecode(validRaw!) as List<dynamic>;
    list.add('corrupted-entry');
    final corruptedRaw = jsonEncode(list);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
      _kInstancesKey: corruptedRaw,
    });

    final mgr = InstanceManager(secureStorage: storage);
    await mgr.load();

    expect(mgr.count, 1, reason: '损坏条目应被跳过，有效实例保留');
    expect(mgr.instances.first.name, 'keep');
    expect(
      await SharedPreferencesAsync().getString(_kInstancesBackupKey),
      corruptedRaw,
      reason: '损坏时原始数据应先备份，避免被下次 _persist 覆盖丢失',
    );
  });

  test('同名重建：删除后新建同名实例，工作目录不复用', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final mgr = InstanceManager(secureStorage: _InMemorySecureStorage());

    final first = await mgr.createInstance(name: 'bot');
    final firstDir = first.workingDir;
    await mgr.removeInstance(first.id);

    final second = await mgr.createInstance(name: 'bot');
    expect(
      second.workingDir,
      isNot(firstDir),
      reason: '同名重建不得继承已删除实例的工作目录（残留数据）',
    );
    expect(second.id, isNot(first.id));
  });

  test('端口分配跳过已被监听的端口', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    // 占住默认起始端口 8000
    final blocker = await ServerSocket.bind(InternetAddress.loopbackIPv4, 8000);
    try {
      final mgr = InstanceManager(secureStorage: _InMemorySecureStorage());
      final inst = await mgr.createInstance(name: 'probe');
      expect(inst.port, isNot(8000), reason: '被监听的端口应被跳过');
    } finally {
      await blocker.close();
    }
  });

  test('显式指定被占用端口时创建失败并给出明确错误', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final blocker = await ServerSocket.bind(InternetAddress.loopbackIPv4, 8010);
    try {
      final mgr = InstanceManager(secureStorage: _InMemorySecureStorage());
      await expectLater(
        mgr.createInstance(name: 'x', preferredPort: 8010),
        throwsArgumentError,
      );
      expect(mgr.count, 0, reason: '创建失败不应留下半成品实例');
    } finally {
      await blocker.close();
    }
  });
}
