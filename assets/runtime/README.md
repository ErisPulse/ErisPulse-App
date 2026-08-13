# 运行时二进制

此目录在 CI 打包时注入 `proot` 与 `busybox`（aarch64 静态二进制）。

- `proot` — 用户态 chroot，运行 rootfs 内的 Python/ErisPulse
- `busybox` — 提供 tar/xz，用于解压 rootfs

本地开发构建时此目录为空，App 会回退到从 GitHub Releases 下载。
