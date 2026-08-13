# ErisPulse-App 开发者手册

> 本文档由开发会话整理，记录项目的完整背景、架构、构建流程、CI/CD 与关键技术难点，供后续开发者快速接手。

---

## 1. 项目是什么

**ErisPulse-App** 是一个 Android 应用，把 [ErisPulse](https://github.com/ErisPulse/ErisPulse)（Python 异步机器人框架）装进手机：
- 一个 App 创建、运行、管理**多个**本地 ErisPulse 实例
- 全原生 UI（不依赖 WebView），直接调用 Dashboard REST/WebSocket API
- proot + Ubuntu rootfs + Python + ErisPulse 运行时内嵌，离线可用
- Android Foreground Service 后台保活 + 崩溃自动重启

仓库：`https://github.com/ErisPulse/ErisPulse-App`（分支 `main`）

---

## 2. 架构总览

```
┌──────────────────────────────────────────────────────┐
│ Flutter 主 isolate（UI）                              │
│   HomePage / InstanceDetail / Logs / DebugPage       │
│   InstanceManager（实例元数据 CRUD + 持久化）         │
│   RuntimeController（与 FGS 通信桥）                 │
│         ↓  flutter_background_service invoke/on      │
│ ┌──────────────────────────────────────────────────┐ │
│ │ FGS isolate（flutter_background_service）        │ │
│ │   RootfsProvisioner（rootfs 解压供给）            │ │
│ │   ProotManager（proot 子进程管理）                │ │
│ └──────────────────────────────────────────────────┘ │
│         ↓ Process.start                             │
│   proot（native lib）→ Ubuntu rootfs → python3 → SDK │
└──────────────────────────────────────────────────────┘
```

### 目录结构

```
lib/
├── main.dart                     入口 + Provider + SplashGate
├── models/                       Instance / LogEntry / SystemInfo / AdapterInfo / ModuleInfo
├── pages/                        home / instance_detail / overview / logs / adapters /
│                                 modules / config / onboarding / debug_page / settings
├── services/
│   ├── instance_manager.dart     实例 CRUD + 端口分配 + token 安全存储
│   ├── dashboard_api.dart        Dashboard REST 客户端
│   ├── log_stream.dart           WebSocket 日志流
│   └── runtime/
│       ├── assets.dart           路径/发布常量
│       ├── native_lib.dart       native lib 路径获取 + SharedPreferences 缓存
│       ├── rootfs_provisioner.dart  rootfs 解压
│       ├── proot_manager.dart    proot 子进程管理（核心）
│       ├── background_service.dart FGS 入口
│       └── runtime_controller.dart UI 通信桥
└── widgets/                      状态指示 / 空状态
```

### 关键目录（Android 原生）

```
android/app/src/main/
├── jniLibs/arm64-v8a/
│   ├── libproot.so        静态 proot（重要：可执行二进制必须放这里）
│   └── libbusybox.so      静态 busybox
└── kotlin/.../MainActivity.kt  method channel：nativeLibraryDir
```

---

## 3. 运行时架构（proot 方案）

每个实例 = rootfs 内一个工作目录 + 独立端口 + 独立 token 的 ErisPulse 进程。

**三样运行时资产**（全部内置 APK）：
1. `proot` — 用户态 chroot（静态编译）
2. `busybox` — tar/gzip 解压 rootfs
3. `rootfs.tar.gz` — Ubuntu arm64 + Python 3.12 + ErisPulse + ErisPulse-Dashboard 预烘焙

**实例启动流程**（`proot_manager._spawnProot`）：
```
proot -0 --rootfs=<appDir>/rootfs \
      --bind=/proc --bind=/dev --bind=/sys \
      --cwd=/home/ep/instances/<name> --kill-on-exit \
      /usr/bin/python3 -c "import asyncio; from ErisPulse import sdk; asyncio.run(sdk.run())"
```

**关键环境变量**（必须在 proot 进程设置）：
| 变量 | 值 | 原因 |
|------|-----|------|
| `PROOT_TMP_DIR` | `<appDir>/tmp` | proot loader 注入需要可写临时目录，app 沙箱无全局 /tmp |
| `PROOT_NO_SECCOMP` | `1` | Android app 沙箱 seccomp 与 proot 过滤器冲突 → SIGSYS |
| `PROOT_NO_PROCESS_VM` | `1` | 同上，禁用 process_vm 加速 |
| `ERISPULSE_PLATFORM` | `android-proot` | SDK 移动端配置分支 |
| `HOME` | `/home/ep/instances/<name>` | guest 内路径 |
| `PATH` | rootfs 内标准路径 | — |

---

## 4. 关键技术难点（血泪史）

### 4.1 proot 必须静态编译
Termux 的 proot .deb 是**动态链接** `libtalloc.so.2`，App 沙箱没有该库 → `CANNOT LINK EXECUTABLE`。
**解决**：在 CI 的 arm64 Docker 里从源码编译，`LDFLAGS="-static"`（见 `scripts/Dockerfile.rootfs`）。

### 4.2 rootfs 用 tar.gz 而非 tar.xz
busybox 部分构建不支持 xz；toybox tar 的 xz 解压需外部 `xz` 程序（沙箱没有）。改用 **gzip**（toybox/busybox 原生支持）。

### 4.3 `PROOT_TMP_DIR` 缺失 → Permission denied
proot 的 loader 注入需要写临时文件。App 沙箱无 `/tmp` → `can't create temporary file`。
**解决**：设 `PROOT_TMP_DIR` 指向 app 私有可写目录（`<appDir>/tmp`）。

### 4.4 SELinux `execute_no_trans` → exec Permission denied（核心难点）
Android 10+ 的 SELinux：`untrusted_app` 对 `app_data_file`（app 私有目录 `/data/data/<pkg>/files`）**没有 `execute_no_trans`**——app 不能直接 exec 自己 data 目录的 ELF。
- `run-as`（`runas_app` domain）有该权限 → 手动测试成功但 App 失败
- avc 日志：`denied { execute_no_trans } for .../files/runtime/proot`

**解决**：把 proot/busybox 作为 **native lib** 打包进 `android/app/src/main/jniLibs/arm64-v8a/`（命名为 `.so`）。
- 系统提取到 `/data/app/<hash>/<pkg>/lib/arm64/`，SELinux context 为 `apk_data_file`
- `untrusted_app` 对 `apk_data_file` 有 `execute_no_trans`（Android 允许 app 运行自己的原生库）
- **必须**设置 `extractNativeLibs=true`：
  - manifest：`<application android:extractNativeLibs="true">`
  - 或 `build.gradle.kts`：`packaging { jniLibs { useLegacyPackaging = true } }`
  - 否则 Android 10+ 默认 `extractNativeLibs=false`，native lib 不提取、无法 exec

### 4.5 seccomp SIGSYS（退出码 -31）→ proot 被信号杀死
即使禁用 proot 的 seccomp，在 `untrusted_app` 下仍可能 SIGSYS（`-31`）。
当前状态：`PROOT_NO_SECCOMP=1` + `PROOT_NO_PROCESS_VM=1` 后，**run-as 测试完整 SDK 启动成功**（Dashboard 路由 HTTP=82 就绪）。但在 App（untrusted_app domain）下仍偶发 `-31`——**这是待解决的遗留问题**，需用 `PROOT_VERBOSE=1` 输出的诊断日志定位（见第 8 节）。

### 4.6 method channel 只在主 isolate
`MainActivity.configureFlutterEngine` 注册的 method channel handler 只对**主 isolate** 生效。FGS 后台 isolate 是独立 engine，调用 `nativeLibraryDir` 返回空。
**解决**：主 isolate 获取后写入 **SharedPreferences**，FGS isolate 读取（见 `native_lib.dart`）。

### 4.7 双 flavor 构建缓存串味
同一 job 顺序构建 online/offline 时，Flutter 的 asset 缓存会让两个包内容串味（大小一致）。
**解决**：release.yml 用**矩阵 job**（online/offline 各自独立 job，干净环境），或构建前 `flutter clean`。

### 4.8 git 不能提交大文件
rootfs（~169MB）/ proot / busybox 二进制**绝不能提交**。`.gitignore` 已排除：
```
assets/rootfs/*.tar.gz
assets/rootfs/*.tar.xz
assets/runtime/proot
assets/runtime/busybox
assets/runtime/busybox-aarch64
assets/runtime/proot-aarch64
```
CI 在构建时从 rootfs release 下载注入。若误提交，用 `git rm --cached` + force push。

---

## 5. 本地开发环境（Windows）

```powershell
# 环境变量（已持久化）
FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
PUB_HOSTED_URL=https://pub.flutter-io.cn
FLUTTER_GIT_URL=https://gitee.com/mirrors/Flutter.git
ANDROID_HOME=D:\devs\Android\Sdk
JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot
```

| 组件 | 位置 | 说明 |
|------|------|------|
| Flutter | `C:\dev\flutter` | 3.44.8 stable，**必须与 CI 版本一致**（格式器差异会挂 format 检查） |
| OpenJDK | `C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot` | winget 安装 |
| Android SDK | `D:\devs\Android\Sdk` | API 36，cmdline-tools + platform-tools + build-tools |
| Gradle | 项目自带 wrapper | 腾讯云镜像下载：`gradle-9.1.0-bin.zip` |
| Aliyun Maven | 项目 gradle 文件 | 解决 maven.google.com 超时 |

### 构建 APK

```powershell
# 准备运行时二进制（放 jniLibs + assets/runtime）
# proot/busybox 从 rootfs release 下载：https://github.com/ErisPulse/ErisPulse-App/releases
# 放到 android/app/src/main/jniLibs/arm64-v8a/libproot.so（命名 .so 必须！）
# rootfs 放 assets/rootfs/erispulse-rootfs-aarch64.tar.gz（offline 需要）

flutter pub get
flutter build apk --debug --dart-define=FLAVOR=offline
# 或 online（不含 rootfs）
flutter build apk --debug --dart-define=FLAVOR=online
```

### 验证命令

```powershell
dart format --output=none --set-exit-if-changed lib/ test/   # 格式检查（CI 必须过）
flutter analyze                                            # 静态检查（0 issues）
flutter test                                               # 单测
```

---

## 6. 安装与调试（adb）

```powershell
# 安装（签名冲突时先卸载：不同 keystore 的包不能直接覆盖）
adb uninstall com.erispulse.erispulse_app
adb install -r app-debug.apk

# 启动
adb shell am start -n com.erispulse.erispulse_app/.MainActivity

# 查看 app 私有目录（debug 包可用 run-as）
adb shell run-as com.erispulse.erispulse_app ls files/
adb shell run-as com.erispulse.erispulse_app cat shared_prefs/FlutterSharedPreferences.xml

# 抓 SELinux 拒绝（execute_no_trans 等）
adb logcat -d | findstr avc

# 抓崩溃 / seccomp
adb logcat -b crash -d
adb logcat -d | findstr "SIGSYS seccomp 1326"

# 实时监听（debug 时）
adb logcat -b all -v time | findstr "erispulse proot seccomp SIGSYS avc"
```

### 传输二进制到 app 目录（调试用）
`adb shell` 的 stdin 二进制会截断；用 base64 文本传输：
```bash
base64 -w 76 file > file.b64
adb shell "run-as PKG sh -c 'base64 -d > files/target'" < file.b64
adb shell "run-as PKG chmod 755 files/target"
```

---

## 7. CI/CD

### 7.1 工作流文件

| 文件 | 触发 | 作用 |
|------|------|------|
| `.github/workflows/ci.yml` | push main / PR | `flutter pub get` + format + analyze + test |
| `.github/workflows/release.yml` | push `v*` tag / workflow_dispatch | 完整发布 |

### 7.2 release.yml 流程（版本驱动，单 release 全产物）

```
v0.2.0 tag / workflow_dispatch
  ↓
job verify      → pub get + format + analyze + test
  ↓
job build-rootfs→ 检查 v{version} release 是否已有 rootfs
                 ├─ 无 → QEMU + buildx 构建（含静态 proot + busybox + tar.gz）
                 └─ 有 → 从 release 下载复用（幂等跳过）
                 → upload artifact（runtime-assets）
  ↓
job build-apk   → 矩阵 [online, offline]（各自独立 job，可单独重试）
                 → 下载 runtime-assets
                 → online: 不含 rootfs；offline: 内置 rootfs
                 → flutter build apk --split-per-abi + universal
                 → 重命名 + upload artifact
  ↓
job release     → 收集全部产物（8 APK + rootfs + proot + busybox）
                 → 创建/更新 v{version} release（notes 从 CHANGELOG.md 提取）
```

### 7.3 产物命名（官方 ABI 名）

```
ErisPulse-App-0.2.0-online-arm64-v8a.apk
ErisPulse-App-0.2.0-online-armeabi-v7a.apk
ErisPulse-App-0.2.0-online-x86_64.apk
ErisPulse-App-0.2.0-online-universal.apk
ErisPulse-App-0.2.0-offline-arm64-v8a.apk      （offline 内置 rootfs，更大）
...
ErisPulse-App-0.2.0-rootfs-aarch64.tar.gz
ErisPulse-App-0.2.0-proot-aarch64
ErisPulse-App-0.2.0-busybox-aarch64
```

### 7.4 触发发布

```bash
# 版本滚动发行（推荐）：打 tag
git tag v0.2.0 && git push origin v0.2.0

# 或手动指定版本
gh workflow run release.yml --field version=0.2.0
```

### 7.5 rootfs 跳过逻辑
`build-rootfs` job 检查 `gh release view v{version}` 是否已有 `rootfs-aarch64.tar.gz`：
- 有 → 直接下载复用（不重复编译，幂等）
- 无 → QEMU 构建（约 15-20 分钟，含静态 proot 编译）

### 7.6 版本来源
`pubspec.yaml` 的 `version: 0.2.0+1` → tag = `v0.2.0`。发布后版本号需手动 bump。

---

## 8. 当前状态与遗留问题

### ✅ 已完成
- 全原生 UI（实例管理 / 系统监控 / 流式日志 / 适配器 / 模块 / 配置）
- proot + rootfs 运行时（native lib 方案解决 exec）
- Foreground Service 保活
- 双 flavor 构建 + 版本驱动 release
- 蓝白图标（adaptive icon #E3F2FD）

### 🔧 进行中 / 待解决
1. **proot 在 untrusted_app 下 `-31`（SIGSYS）**：run-as 测试 SDK 完整启动成功，但 App 内仍偶发。
   - 已加 `PROOT_VERBOSE=1`，启动实例后到 **调试日志页**（DebugPage）看 proot 诊断输出
   - 关注：哪个 syscall 触发 seccomp；可能需要禁用 proot 更多特性或调整 loader
2. **DebugPage 未完成**：`home_page.dart` 引用 `DebugPage` 但缺 import；`DebugLogBuffer`/`DebugLogEntry` 类型可能未定义；`main.dart` 未注册 `/debug` 路由。修复后即可查看 proot 断点日志。
3. **psutil 警告**：rootfs 内 `swap_memory` 读 `/proc/vmstat` 被拒（非致命，仅 Dashboard 系统监控接口部分受限）。

### 📝 下一步建议
1. 完成 DebugPage（补 import + 类型 + 路由）
2. 用 DebugPage 的 proot 诊断定位 `-31`
3. 测试通过后重新构建 + 打 `v0.2.0` tag 发正式版
4. iOS / 桌面端（Phase 3/4，见 `docs/ROADMAP.md`）

---

## 9. 常用脚本/工具

| 路径 | 作用 |
|------|------|
| `scripts/Dockerfile.rootfs` | arm64 环境：编译静态 proot + 装 Python/ErisPulse + 获取 busybox |
| `scripts/build-rootfs.sh` | rootfs 内安装脚本（apt + pip） |
| `.github/workflows/release.yml` | 完整发布流水线 |

---

## 10. 参考

- [ErisPulse SDK](https://github.com/ErisPulse/ErisPulse)（含 `runtime/platform.py` 移动端检测）
- [ErisPulse-Dashboard](https://github.com/ErisPulse/ErisPulse-Dashboard)（本 App 的 REST/WS API 来源）
- [proot](https://github.com/proot-me/proot)（用户态 chroot）
- [flutter_background_service](https://pub.dev/packages/flutter_background_service)
