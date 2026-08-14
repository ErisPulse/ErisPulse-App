# 更新日志

版本遵循 [语义化版本控制](https://semver.org/lang/zh-CN/)。

## [0.1.1] - 2026/08/14

### 新增

- 桌面运行时重构：完全移除 pybuild 便携运行时下载，改为构建时内置
  python-build-standalone（Python 3.15，即 uv managed Python 来源）到
  `assets/python/python-{platform}-{arch}.tar.gz`，首次使用释放到
  `~/.erispulse/python/` 并引导 pip
- 实例环境分离（PC + 移动端统一）：每个本地实例使用独立虚拟环境
  （PC `~/.erispulse/instances/{id}/.venv`；移动端 rootfs 内
  `{workingDir}/.venv`），启动用 venv python 并注入 `VIRTUAL_ENV`，
  后端包管理命中实例环境，不再回落系统 Python；旧实例无 venv 自动回退
- 创建实例可选环境来源：
  - 全新环境：选 ErisPulse SDK 版本（PyPI，可选随装 ErisPulse-Dashboard），
    `python -m venv` + `pip install` 准备；移动端 venv 带
    `--system-site-packages`（离线继承 rootfs 预烘焙版本）
  - 基于已有实例：复制某个已有实例的 venv（继承其 SDK 版本与已装包），
    即"在谁的 venv 基础上建立新实例"
- 实例不绑定 SDK 版本：首次安装版本记入实例记录，之后可随时通过
  Dashboard 包管理更新框架版本（更新后同步记录）
- 移动端：FGS 新增 `prepareInstance` 通道（fresh / clone 环境准备 +
  `instanceEnv` 完成回执），创建页两端均提供环境来源选择
- 下载源拆分：GitHub 镜像（移动端 rootfs 下载）+ 新增 PyPI 镜像源
  （官方 / 清华 / 阿里，桌面端 pip 安装使用）
- 创建实例页桌面版：SDK 版本选择（PyPI 列表，含预发布标注）+
  安装 Dashboard 开关 + 环境准备进度日志弹窗
- 运行时管理页改为 PC 环境概览：内置 Python 状态 / 各实例 venv /
  PyPI 镜像源
- 适配器多 bot（账户）配置：配置页分「全局设置」与「Bot 账户」两区，
  支持账户列表、启用开关、新建 / 编辑 / 删除账户（schema 驱动表单，
  保存后端校验并热重载）

### 修复

- 框架更新信息不显示：后端 `/framework/versions` 无 `latest` 字段，
  改为使用 `can_update` + `versions` 首个，无更新时禁用按钮并显示"已是最新"
- 日志改走 Dashboard WebSocket 日志流（`log_entry` + `data` 解包 +
  `module` 字段），桌面 / 移动端统一（历史用 `/api/logs` 填充 + WS 实时）
- 配置页删除源码模式，只保留渲染（JSON 树 + 单键编辑）
- 修复实例安装包被装到系统环境的问题（见上"每实例独立 venv"）
- 适配器 Tab 过滤混排的模块条目（只保留 `type=adapter`）
- 配置 Tab 删除顶部"渲染 / 复制"栏，只保留配置树
- 日志页新增等级过滤与导出下载（系统下载 / 文档目录）
- PyPI 版本排序修正：正式版排在预发布之前（`2.7.1` > `2.7.1.dev4` > … > `2.7.1.dev0`），
  预发布按后缀数字排序（PEP 440 语义）
- 桌面 App 关闭时终止全部实例进程（`AppLifecycleListener.onExitRequested`），
  不再残留 python 进程
- 创建实例页 PC 布局优化：表单限宽居中（560px），环境来源分组加标题，宽屏不再全宽拉伸
- 关于 / 首启 / 清空日志文案去掉 proot / Ubuntu 等实现细节，统一通用（实现细节见架构文档）
- 详情页操作按钮移入右上角菜单（停止 / 软重启 / 重启进程），概览页更简洁
- 开源地址与 rootfs 下载镜像更新为 `ErisPulse/ErisPulse-App`
- CI：修复 Windows 打包步骤 PowerShell 语法、macOS ditto 产物路径（`erispulse_app.app`）

### 变更

- Dashboard 随 SDK 一起安装（移除"安装 Dashboard 模块"开关，恒装 `ErisPulse-Dashboard`）

## [0.1.0] - 2026/08/13

### 新增

- 桌面平台支持（Windows / Linux / macOS，开发中）：
  - App 作启动器：不捆绑运行时，从官方 release 下载 pybuild 便携包（完整 Python + ErisPulse 全依赖），解压安装到 `~/.erispulse/runtimes/{version}`，可自由选择版本
  - 实例可绑定运行时版本（创建实例时选择 / 详情页切换），未绑定则使用全局默认版本
  - 运行时版本多源获取（GitHub API → PyPI → 内置兜底），下载源镜像同样生效，不再单点依赖
  - 桌面运行时：直接进程管理，无 proot / rootfs / 前台服务
  - RuntimeController 平台分支（Android FGS + 桌面直连）
  - 桌面 NavigationRail 侧边栏 + 宽屏自适应布局（内容区居中限宽）
  - Dashboard 统一 flutter_inappwebview（Windows WebView2 / Linux WebKitGTK / macOS WKWebView / 移动端一致）
  - 设置页新增开源地址入口
- 首屏横幅化：不再强制首启初始化页；主页横幅提示未初始化并显示进度，点击进入初始化页，可随时返回
- 初始化日志自动滚动跟随（默认定位底部）
- 设置页下载源去重（右侧下拉即显示当前值，删除重复的 subtitle）
- 详情页 Tab 式改造（概览 / 模块 / 适配器 / 配置 / 文件 / 日志 / 包），Dashboard API 原生管理：
  - 模块、适配器启停 / 重启，状态展示与 bot 列表
  - 模块 / 适配器 schema 驱动配置表单（switch / password / select / number / textarea）
  - 配置双模式：渲染（JSON 树，叶子可编辑）+ 源码（TOML 查看 / 编辑 / 整文件保存）
  - 已装 pip 包列表 + 安装 / 卸载 + 框架版本 / 更新 + SDK 重启
  - 文件浏览统一走 API（browse / read / write / delete，桌面与移动端一致）
  - 鉴权失败（401/403）统一提示访问令牌无效
- 运行时管理页（设置 → 运行时管理）：已装版本列表 / 激活切换 / 删除 / 下载新版本 / 目录展示
- 桌面实例列表右键菜单（启动 / 停止 / 重启 / 打开 Dashboard / 查看日志 / 复制令牌 / 重命名 / 删除）
- 日志按实例分缓冲（多实例互不挤占），进程输出落盘 `~/.erispulse/instances/{id}/logs/erispulse.log`
- 构建产物 Logo：Windows / macOS / Linux 应用图标
- Dashboard API 客户端全面对齐后端端点（modules/action、config key、files/browse、packages 等）
- 软 / 硬重启：软重启调用 Dashboard API `restartSdk`（保留进程），硬重启为原生重启进程（详情页 / 右键 / 长按菜单可选）
- 实例列表显示 SDK 版本，桌面实例列表卡片化
- 日志页 / 详情日志 Tab 加载历史（桌面读落盘 `erispulse.log` 尾部，移动端拉 Dashboard 日志）+ 实时流
- 包 Tab 框架区合并：版本 +「更新框架」「重启 SDK」两按钮并列
- 下载源改横向滚动选择，运行时管理页下载区可就地切换下载源
- 修复：文件浏览 404（`apiUri` 内嵌 query 被编码进 path）、模块列表类型错误（后端 `load_strategy` 为 dict）、配置源码模式不加载、错误信息展示后端 `message` 字段

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
