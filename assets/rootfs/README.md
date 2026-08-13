# rootfs 镜像

此目录在 CI 打包 **offline flavor** 时注入 `erispulse-rootfs-aarch64.tar.xz`
（Ubuntu arm64 + Python + ErisPulse 预烘焙，约 80-100MB）。

- **offline flavor**：内置此文件，首次启动离线解压
- **online flavor**：不内置，首次启动从 GitHub Releases 下载

本地开发构建时此目录为空。
