/// 实例日志流（WebSocket 实时推送）。
///
/// Dashboard 在 `/Dashboard/ws?token=xxx` 暴露 WebSocket，推送：
///   - `{type: 'log_entry', data: {timestamp, level, level_num, module, message}}`
///   - `{type: 'log', ...}`（兼容旧格式）
///   - `{type: 'event', ...}`
///   - `{type: 'heartbeat'}`
///
/// 本服务仅关心日志消息，把它们转为 [LogEntry] 流。
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/instance.dart';
import '../models/log_entry.dart';

class LogStream extends ChangeNotifier {
  LogStream(this.instance);

  final Instance instance;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _manuallyStopped = false;

  /// 内存缓冲（环形）。UI 通过 notifyListeners 拉取。
  final List<LogEntry> _buffer = [];
  static const int _maxBuffer = 2000;

  /// 当前过滤级别（null = 不过滤）
  LogLevel? minLevel;

  /// 缓冲区只读视图
  List<LogEntry> get entries {
    if (minLevel == null) return List.unmodifiable(_buffer);
    return List.unmodifiable(
      _buffer.where((e) => e.level.num >= minLevel!.num),
    );
  }

  /// 是否已连接
  bool get isConnected => _channel != null && _reconnectTimer == null;

  /// 注入历史日志（首次打开时用 `/api/logs` 填充）
  void seed(Iterable<LogEntry> entries) {
    _buffer.addAll(entries);
    while (_buffer.length > _maxBuffer) {
      _buffer.removeAt(0);
    }
    notifyListeners();
  }

  /// 启动流（如果已运行则忽略）
  void start() {
    if (_channel != null) return;
    _manuallyStopped = false;
    _connect();
  }

  /// 停止流
  void stop() {
    _manuallyStopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// 清空缓冲
  void clear() {
    _buffer.clear();
    notifyListeners();
  }

  /// 设置过滤级别
  void setLevel(LogLevel? level) {
    minLevel = level;
    notifyListeners();
  }

  void _connect() {
    if (_disposed || _manuallyStopped) return;
    try {
      _channel = WebSocketChannel.connect(instance.wsUrl);
      _sub = _channel!.stream.listen(
        _onData,
        onError: (e) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final type = json['type'] as String?;
    if (type != 'log' && type != 'log_entry') return;

    // 后端 log_entry 消息把日志字段嵌在 `data` 里
    final payload =
        (json['data'] is Map) ? json['data'] as Map<String, dynamic> : json;
    final entry = LogEntry.fromJson(payload);
    _buffer.add(entry);
    while (_buffer.length > _maxBuffer) {
      _buffer.removeAt(0);
    }
    notifyListeners();
  }

  void _scheduleReconnect() {
    if (_disposed || _manuallyStopped) return;
    _sub?.cancel();
    _sub = null;
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), _connect);
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
