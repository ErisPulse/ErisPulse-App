# 更新日志

版本遵循 [语义化版本控制](https://semver.org/lang/zh-CN/)。

## [0.1.0] - 2026/08/13

### 新增

- 桌面平台支持（Windows / Linux，开发中）：
  - 捆绑便携 Python，ErisPulse SDK 从 PyPI 选择版本安装（默认最新）
  - 桌面运行时：直接进程管理，无 proot / rootfs / 前台服务
  - RuntimeController 平台分支（Android FGS + 桌面直连）
- 首屏横幅化：不再强制首启初始化页；主页横幅提示未初始化并显示进度，点击进入初始化页，可随时返回
- 初始化日志自动滚动跟随（默认定位底部）
- 设置页下载源去重（右侧下拉即显示当前值，删除重复的 subtitle）

### 修复

- proot 启动报 `libandroid-shmem.so not found`：termux 动态依赖补全打包进 jniLibs
- SplashGate 超时误踢初始化流程
- rootfs 下载 404：CI 资产名与 App 下载名不匹配

### 工程

- 正式签名（release keystore + CI secrets），online/offline 同签名可覆盖安装
- 下载源镜像：GitHub 直连 / ghfast / ghproxy
- README 重构为 5 语言分文件（en / zh-CN / zh-TW / ja / ru）

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
