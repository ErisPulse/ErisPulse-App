# 自定义发行版（Custom Distribution）

通过 `custom/` 目录 + CI，你可以发布自己的 ErisPulse-App 发行版：预装指定模块、
自定义首启欢迎语、创建实例页说明、默认镜像源，甚至自建下载镜像。
**零代码改动**——只改配置与脚本，构建产物发布到你自己的 GitHub Releases。

## 目录结构

```
custom/
  config.json            # 发行版清单（可选）
  rootfs/                # rootfs 定制（可选，仅影响 Android offline flavor）
    packages.list        #   额外 apt 包，每行一个
    requirements.txt     #   额外 pip 包（ErisPulse 模块 / 适配器）
    setup.sh             #   任意烘焙脚本（rootfs 内以 root 执行）
  assets/                #（规划中）图标 / 启动图替换
```

## config.json 字段

```jsonc
{
  "distribution": {
    "name": "My ErisPulse",              // 发行版名称（首启弹窗 / 关于页 / 窗口标题）
    "vendor": "Your Org",                // 发行者
    "homepage": "https://example.com",   // 主页（可空）
    "contact": "mailto:you@example.com"  // 联系方式（可空）
  },
  "preinstalled": [                      // 预装组件清单（展示用）
    { "name": "ErisPulse-DashChat", "type": "module", "version": "1.2.0",
      "description": "跨平台统一收件箱" }
  ],
  "notices": {
    "firstLaunch": "首次启动欢迎文案…",    // 首启弹窗正文（可空；多行 \n）
    "createInstance": "创建实例页说明…"    // 创建实例页顶部说明卡（可空）
  },
  "defaults": {
    "downloadSource": "ghfast",          // 默认 GitHub 下载源 github/ghfast/ghproxy
    "pypiSource": "tsinghua",            // 默认 PyPI 源 pypi/tsinghua/aliyun/custom
    "pypiIndexUrl": "https://…/simple",  // pypiSource=custom 时的索引地址
    "pypiLabel": "我的镜像"              // custom 源显示名
  },
  "download": {
    "releaseBase": "https://dl.example.com/erispulse"  // 自建 Releases 镜像基址
  }
}
```

所有字段可省略；只写需要的 section，其余保持官方默认。`releaseBase` 指向的
地址需提供与官方 Releases 相同的资产文件名（`erispulse-rootfs-aarch64.tar.gz`、
`proot-aarch64` 等）。

## CI 用法

### 方式一：fork 官方仓库

1. Fork `ErisPulse/ErisPulse-App`
2. 添加 `custom/` 目录
3. 推送 `v*` 标签或手动触发官方 `release` workflow
4. 产物发布到 fork 的 Releases

官方 `release.yml` 已内置两步定制逻辑：
- `gen-manifest.sh`：`custom/config.json` 存在时合并进 `assets/custom/manifest.json`
- `customize-rootfs.sh`：`custom/rootfs/` 存在时在 rootfs 内执行 apt/pip/setup.sh

### 方式二：独立仓库 + 模板

1. 在你自己的仓库创建 `custom/` 目录
2. 复制 `templates/custom-release.yml` 到 `.github/workflows/custom-release.yml`
3. 推送 `v*` 标签或手动触发

模板会拉取官方源码与预构建产物，叠加 `custom/` 定制后构建发布。构建签名使用
你自己仓库的 secrets（`ANDROID_KEYSTORE_BASE64` 等，不配置则以 debug 签名构建）。

`rebuild_rootfs` 输入置 true 时从源码重建底层 rootfs（默认直接用官方预构建，
只叠加你的 `custom/rootfs` 层，速度快得多）。

## rootfs 定制说明

- `customize-rootfs.sh` 在 x64 runner 上通过 `qemu-user-static` chroot 进 arm64
  rootfs 执行，宿主与目标架构不同不影响使用。
- `requirements.txt` 通过 manifest 的 `pypiIndexUrl` 安装（未配置时官方源），
  与发行版保持一致的镜像源。
- `setup.sh` 幂等性由发行者自行保证（rootfs 可能被多次定制）。

## App 侧行为

| 清单字段 | App 行为 |
|---|---|
| `preinstalled` + `notices.firstLaunch` | 首次启动弹「欢迎使用 {name}」+ 预装清单，只弹一次 |
| `notices.createInstance` | 创建实例页顶部说明卡 |
| `defaults.downloadSource` | 用户未手动选过下载源时的默认值 |
| `defaults.pypiSource` / `pypiIndexUrl` / `pypiLabel` | 默认 PyPI 源；`custom` 选项出现在设置页 |
| `download.releaseBase` | rootfs / 运行时二进制下载地址覆盖 |
| `distribution.name` | 窗口标题 / 关于弹窗 / 设置页版本行 |
