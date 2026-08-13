# rootfs 内引导脚本（由 CI 烘焙期调用，非 App 运行期）

此脚本在构建 rootfs 镜像时执行：安装 Python 与 ErisPulse 全家桶。
App 首次启动只需解压镜像即可运行，无需在手机上网安装依赖。

```bash
#!/usr/bin/env bash
# 供 CI build-rootfs.yml 内部使用
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  python3 python3-pip python3-venv \
  ca-certificates curl \
  && rm -rf /var/lib/apt/lists/*

# 安装 ErisPulse 与 Dashboard（预烘焙，含依赖）
pip3 install --break-system-packages --no-cache-dir \
  ErisPulse \
  ErisPulse-Dashboard

# 预热：生成一次 CLI 状态文件，避免首次 run 时写盘失败
python3 -c "import ErisPulse; print('ErisPulse OK')"
