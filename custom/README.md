# custom/ — 自定义发行版目录

官方构建忽略本目录内容（仓库内无 config.json 时保持默认清单）。

结构示例见 `docs/CUSTOM-DISTRIBUTION.md`：

```
custom/
  config.json            # 发行版清单
  rootfs/
    packages.list        # 额外 apt 包
    requirements.txt     # 额外 pip 包
    setup.sh             # 自定义烘焙脚本
```
