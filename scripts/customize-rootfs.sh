#!/usr/bin/env bash
# 在 rootfs 镜像内应用 custom/rootfs 定制（需 root + qemu-user-static + binfmt）。
#
# 用法: customize-rootfs.sh <rootfs.tar.gz> <out.tar.gz>
# 输入: custom/rootfs/packages.list      额外 apt 包（可空）
#       custom/rootfs/requirements.txt   额外 pip 包（可空）
#       custom/rootfs/setup.sh           任意烘焙脚本（chroot 内执行，可空）
# 环境变量:
#       PYPI_INDEX   pip 索引地址（缺省官方源）
set -euo pipefail

SRC="${1:?usage: customize-rootfs.sh <rootfs.tar.gz> <out.tar.gz>}"
OUT="${2:?usage: customize-rootfs.sh <rootfs.tar.gz> <out.tar.gz>}"
CUSTOM_DIR="custom/rootfs"
PYPI_INDEX="${PYPI_INDEX:-https://pypi.org/simple}"

[ -d "$CUSTOM_DIR" ] || { echo "no $CUSTOM_DIR — copy input as-is"; cp "$SRC" "$OUT"; exit 0; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "extracting rootfs..."
tar -xzf "$SRC" -C "$WORK"

# arm64 rootfs 在 x64 宿主机 chroot 需要 qemu 模拟
if [ "$(uname -m)" != "aarch64" ]; then
  command -v qemu-aarch64-static >/dev/null || {
    apt-get update -qq && apt-get install -y -qq qemu-user-static binfmt-support
  }
  cp /usr/bin/qemu-aarch64-static "$WORK/usr/bin/"
fi
cp /etc/resolv.conf "$WORK/etc/resolv.conf" 2>/dev/null || true

# 定制文件送入 chroot
mkdir -p "$WORK/tmp"
for f in packages.list requirements.txt setup.sh; do
  [ -f "$CUSTOM_DIR/$f" ] && cp "$CUSTOM_DIR/$f" "$WORK/tmp/$f"
done

mount -t proc proc "$WORK/proc" 2>/dev/null || true
mount --rbind /dev "$WORK/dev" 2>/dev/null || true
mount --rbind /sys "$WORK/sys" 2>/dev/null || true
trap 'umount -R "$WORK/dev" "$WORK/proc" "$WORK/sys" 2>/dev/null; rm -rf "$WORK"' EXIT

chroot "$WORK" /bin/bash -e <<EOF
export DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8
if [ -f /tmp/packages.list ]; then
  apt-get update -qq
  xargs -a /tmp/packages.list apt-get install -y -qq --no-install-recommends
fi
if [ -f /tmp/requirements.txt ]; then
  pip install -r /tmp/requirements.txt -i "$PYPI_INDEX"
fi
if [ -f /tmp/setup.sh ]; then
  bash /tmp/setup.sh
fi
rm -f /tmp/packages.list /tmp/requirements.txt /tmp/setup.sh
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache
EOF

echo "repacking rootfs..."
tar -cf - -C "$WORK" . | gzip -9 > "$OUT"
echo "done: $OUT ($(du -h "$OUT" | cut -f1))"
