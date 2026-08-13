/// ErisPulse 实例相关枚举。
library;

/// 实例运行状态
enum InstanceStatus {
  /// 已停止
  stopped,

  /// 启动中（proot + Python 正在拉起）
  starting,

  /// 运行中（Dashboard 已就绪）
  running,

  /// 异常（启动失败 / 崩溃 / 端口占用）
  error,

  /// 销毁中
  destroying,
}

/// 实例健康度（基于 Dashboard 探活结果）
enum InstanceHealth {
  /// 未检测
  unknown,

  /// 健康：Dashboard 200 + token 有效
  healthy,

  /// 启动中：网络通但 Dashboard 未就绪
  booting,

  /// 端口不通
  unreachable,

  /// token 无效
  unauthorized,
}
