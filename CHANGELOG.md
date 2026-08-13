# 更新日志

版本遵循 [语义化版本控制](https://semver.org/lang/zh-CN/)。

## [0.2.0] - 2026/08/12

### 新增

- 多实例管理：一个 App 创建、运行、管理多个 ErisPulse 实例（独立端口 / 工作目录 / token）
- 原生 UI（不依赖 WebView），基于 Dashboard REST/WebSocket API：
  - 实例列表与详情页
  - 系统监控（CPU / 内存实时图表）
  - 流式日志（级别过滤 / 暂停 / 复制）
  - 适配器与模块管理
  - 配置 TOML 视图
- Android 嵌入运行时：proot + Ubuntu rootfs + Python + ErisPulse 全部内置，离线可用
- 后台保活：Foreground Service 常驻 + 崩溃自动重启
- 首启向导：运行时解压进度与日志视图

## 说明

- 移动端配置由 SDK 自动识别（`ERISPULSE_PLATFORM=android-proot`），见 ErisPulse 仓库的 CHANGELOG 与 `docs/zh-CN/user-guide/mobile-deploy.md`。
