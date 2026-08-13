#!/usr/bin/env bash
# 在 arm64 容器内执行：安装 Python + ErisPulse 全家桶（预烘焙）。
# 由 .github/workflows/build-rootfs.yml 通过 buildx 构建阶段调用。
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

apt-get update
apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  python3-venv \
  ca-certificates \
  curl \
  && rm -rf /var/lib/apt/lists/*

# 安装 ErisPulse 与 Dashboard（含依赖，全部预烘焙进镜像）
pip3 install --break-system-packages --no-cache-dir \
  ErisPulse \
  ErisPulse-Dashboard

# 允许运行时系统级 pip 安装（PEP 668）：Dashboard 的包管理功能装包时不报错
printf '[global]\nbreak-system-packages = true\n' > /etc/pip.conf

# 预热：确认 SDK 可导入；失败即中断构建
python3 -c "from ErisPulse import sdk; print('ErisPulse OK', getattr(sdk, 'VERSION', ''))"

# 清理 pip 缓存
rm -rf /root/.cache

echo "=== rootfs 构建完成 ==="
