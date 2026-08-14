# 更新日志

版本遵循 [语义化版本控制](https://semver.org/lang/zh-CN/)。

## [0.2.2] - 2026/08/15

### 新增

- 模块动态视窗入口（对齐 Dashboard `/api/views`）：
  - 详情页轮询同步模块注册的视窗，按分组自动插入导航（内置组复用同名
    分组，system / tools / 自定义分组追加末尾），装卸模块后入口实时增减
  - 视窗内容不在 App 内渲染：点击入口直接跳转 Dashboard 对应页面
    （WebView 登录后以 `go()` 定位，模块页面异步渲染自动重试）
  - 视窗图标（icon_svg）以 flutter_svg 原样渲染；标题 / 分组标题按
    App 语言解析 titles / group_titles 五语言字典
- 概览页对齐 Dashboard 仪表盘：
  - 大数字统计 4 格（适配器 / 模块 / 在线机器人 / 事件总数），点击
    跳转对应视图
  - CPU / 内存告警变色（>60% 橙 / >85% 红）
  - 版本行（ErisPulse vX · Python Y，来自 /api/status）
- 商店标签筛选折叠：默认折叠为一行（已选标签以可删除 chips 展示 +
  一键清除），点击展开完整多选列表

### 修复

- 桌面端左侧导航出现两个"概览"分组标题（固定概览项与机器人视图
  同组但重复渲染标题）

### 变更

- 创建实例页 PC 布局重构：宽屏两栏铺满（左：引导 / 类型 / 名称；
  右：端口或远程地址 / 环境来源 + 创建），移动端保持单列
- 创建实例副标题按平台区分文案（桌面=本机运行，手机=手机内独立运行）
- SDK 版本下拉限制菜单高度（360），不再占满全屏

## [0.2.1] - 2026/08/15

### 新增

- 详情页导航对齐 Dashboard 侧边栏颗粒度：
  - 视图按 5 个分组组织（概览 / 事件 / 扩展 / 管理 / 运维），桌面端左侧
    导航显示分组标题，移动端 TabBar 保持同一顺序平铺
  - 顺序：概览（机器人）→ 事件（事件流、命令）→ 扩展（模块、商店）→
    管理（适配器、配置）→ 运维（监控、文件）
- 新增「监控」视图：日志 / 生命周期 / 审计三合一子 tab（对齐 Dashboard
  monitor 页结构，替代原先 3 个独立视图）
- 新增「商店」视图（对齐 Dashboard store 页）：
  - 商店浏览：搜索（防抖）/ 类型过滤（模块 / 适配器）/ 标签多选筛选 /
    强制刷新；卡片含类型徽章、官方标识、安装状态（未安装 / 有更新 /
    已安装带版本），一键安装或升级
  - 包详情对话框：描述 / 作者 / 许可证 / 主页 / 依赖 / 历史版本列表，
    点击任意版本安装指定版本
  - 包管理：已安装（升级 / 卸载 + 框架更新卡）、可更新（单包 / 全部
    升级）、安装新包（`pkg==1.0` 与 `git+` URL）、Git 包列表与升级
  - 安装 / 升级为后台 pip 任务：确认框可选 pip 镜像源与强制重装，
    进度对话框轮询 task 实时状态与输出（running / success / error）
- `DashboardApi` 新增商店端点：`getStoreRemote` / `storeInstall` /
  `getInstallStatus` / `getPackageDetail` / `getPackageUpdates` /
  `upgradePackages` / `getGitPackages` / `upgradeGitPackage`；
  `installPackages` 改为返回 task_id 支持进度跟踪

### 变更

- 「包」视图（PackagesTab）并入商店「包管理」tab，框架更新 / SDK 重启
  随之迁移；详情页视图 11 → 10（概览 + 9 个注册视图）

## [0.2.0] - 2026/08/15

### 新增

- 详情页视图 8 → 11：新增「生命周期」「命令」「机器人」三个原生视图
- 新增「生命周期」原生视图（`/api/lifecycle`，事件时间轴列表：类型过滤 +
  清空 + 刷新，时间 / 类型 / 来源 / 摘要），替代 Dashboard 前端 lifecycle 页
- 新增「命令」原生视图（`/api/commands`）：
  - 全局设置卡：指令前缀 + 前缀区分大小写 / 允许空格前缀 / 必须 @机器人 开关，
    一键保存（`PUT /commands/settings`）
  - 命令列表：每个命令的启用开关即时保存（`PUT /commands/{name}`）+ 编辑对话框
    （别名 / 允许平台 / 禁止平台 / 转发为，逗号分隔）
- 新增「机器人」原生视图（`/api/bots`）：机器人卡片列表，在线状态指示点 +
  能力 chips + 最后活跃相对时间（从未活跃 / 刚刚 / 分钟 / 小时 / 天前）
- 概览页新增「消息统计」卡片（`/api/message-stats`）：总事件数 + 按类型 /
  按平台分布 + 近 24 小时趋势柱状图（与概览数据同轮询周期刷新）
- 事件流页新增「构建器」模式（SegmentedButton 查看 / 构建器切换）：
  - 事件类型（message / notice / request / meta）+ 子类型下拉 + 平台
    （内置列表或自定义）+ 机器人选择 + 会话类型 / ID
  - 消息分段编辑器（多段，字段名自动缓存）、可选字段 key/value 注入、
    JSON 实时预览（可复制）、提交校验（`/api/builder/segments` +
    `/api/builder/submit`），提交后自动回切查看模式并刷新
### 文档

- README（全部 5 语言）：桌面端（Windows / Linux / macOS）构建已发布，
  移除"开发中"表述，安装说明改为按平台从 Releases 选择下载

### 修复

- 无

## [0.1.2] - 2026/08/14

### 新增

- 详情页视图注册机制（`DetailViewRegistry` + `InstanceView`）：内置视图统一由
  注册表驱动，PC 宽屏改为左侧竖向导航 + 内容区（`IndexedStack` 保留各视图状态），
  移动端保持顶部 TabBar（视图自带 keep-alive）；未来 SDK 动态注册视图经
  `register()` 加入后自动出现在导航，无需改动详情页布局
- 新增「事件流」原生视图（轮询 `/api/events`，类型过滤 + 自动刷新 + 清空），
  替代 Dashboard 前端 event-stream 页
- 新增「审计」原生视图（`/api/audit`，时间 / action / 详情 / IP + 清空），
  替代 Dashboard 前端 audit-log 页
- 日志 Tab 完整版：
  - 软日志 / 进程日志双数据源切换（SegmentedButton）
  - 软日志工具栏对齐 Dashboard 前端日志页：模块过滤、等级过滤、搜索（防抖）、
    最新在底/顶排序、暂停滚动、自动滚动、行数计数、复制 / 导出 / 清空
  - 进程日志为实例实时 stdout/stderr（`DebugLogBuffer` 按实例缓冲，实时非持久化）
- Dashboard 内嵌页改为 App 侧 reload 完成 token 注入，避免前端
  `location.reload()` 的 onLoadStop 事件链不一致

### 修复

- PC 详情页滚轮不再切到相邻 Tab：桌面端走左侧导航（TabBarView 仅移动端）
- Dashboard 在 App 内一直转圈：token 注入后的刷新不置 loading 态 + 8s 加载超时兜底
- 首页长按 / 右键菜单停止 / 重启后主动探活回写，列表状态不再滞后
- 桌面停止实例改进程树终止（Windows `taskkill /F /T`、POSIX SIGTERM→SIGKILL），
  避免子进程残留导致端口仍健康、"停止无效"
- 全屏日志页等级过滤"无效果"：`level_num` 兜底解析缺失的 `level` 字段 +
  工具栏显示当前过滤级别 chip + 过滤空态提示
- 日志等级体系完整：SDK 自定义级别 `TRACE=5` / `EVENT=21` 正确解析并显示
  （原先被误解析为 INFO，导致日志页"只有 INFO"）；等级过滤改**勾选**
  （FilterChip 精确级别集合，含 TRACE/DEBUG/INFO/EVENT/WARNING/ERROR/CRITICAL），
  默认仅显示 INFO 及以上
- 概览页移除「查看日志」按钮（日志已是原生 Tab，与 Dashboard 入口保留）
- PC 概览页启停 / 软重启 / 硬重启按钮直接可见（移动端仍走右上角菜单）
- 概览卡片宽屏两列布局（资源+连接 / 事件），不再单列长条
- 调试页不再显示 Android 设备行：按平台取设备信息（Android 走 device_info，
  桌面显示操作系统版本）
- 基于已有实例创建时不再"卡死"：venv 复制改异步 IO（原同步递归复制会冻结
  UI），进度对话框显示确定性进度条 + 已复制文件数 + "请勿关闭窗口"提示

### 内部

- `DashboardApi` 新增 `getAuditLog` / `clearAuditLog`，`getEvents` 支持
  `limit` / `type` 服务端过滤参数
- i18n：新增事件流 / 审计 / 日志完整版相关键，同步 zh-CN / zh-TW / en / ja / ru

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
- Dashboard 访问密钥自动注入：打开内嵌 Dashboard 时自动把实例 token
  写入前端 localStorage（`__ep_tk__`）实现免手动登录；AppBar 复制按钮
  改为可见的「访问密钥」文字按钮（带钥匙图标），用户不再找不到密钥

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
- 修复桌面端"内置 Python 释放失败"：内置 Python 资产命名不一致（CI 打
  `python-windows-x64.tar.gz`，App 按 `python-windows-amd64` 加载），
  统一为 `x64`，Windows / Linux 首次启动可正常释放 Python
- 桌面端产物：Windows / Linux 为 x64，macOS 为 arm64
  （Windows on ARM 用户可直接用 windows-x64 产物，x64 模拟层可运行）
- Windows 新增 Inno Setup 安装器（x64，产 `*-setup.exe`），与 zip 一起发布
- 内置 Python 由 3.15 降为 3.13：3.15 过新，pydantic-core 等核心包尚无
  cp315 预编译 wheel，实例安装会触发源码编译（需 Rust）而失败；
  CI 下载改为精确匹配标准（非 free-threaded）构建
- Android CI 跳过阿里云 Maven 镜像（海外 runner 走官方仓库，规避 502）
- 桌面端图标改用透明背景 logo（无底色）；Android 维持自适应图标
  （系统要求背景层，完全透明会显示黑底）

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
