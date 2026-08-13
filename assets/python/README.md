# 内置 Python 环境

此目录在 CI 打包时注入对应平台的独立 Python 压缩包（来自
[python-build-standalone](https://github.com/astral-sh/python-build-standalone)，
即 uv 下载 managed Python 的来源），供桌面端（Windows / Linux / macOS）使用。

文件名格式：`python-{platform}-{arch}.tar.gz`，如 `python-windows-x64.tar.gz`，
内容为 python-build-standalone 的 `install_only` 发布产物（顶层带一个目录）。

- App 首次使用时会从 assets 释放到 `~/.erispulse/python/` 并引导 pip。
- 每个本地实例会用它创建独立虚拟环境（`~/.erispulse/instances/{id}/.venv`），
  再 `pip install ErisPulse==<版本> [ErisPulse-Dashboard]`。
- 本地开发构建时此目录为空：App 会提示缺少内置 Python 环境（不再支持 pybuild 下载兜底）。

打包脚本见 `.github/workflows/release.yml`（`Fetch bundled Python` 步骤）。
