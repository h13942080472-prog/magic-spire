# 紧缚尖塔

当前发布版本：0.18。Godot 4.7.2 项目，支持 Windows 与 Android。

## 许可

Copyright (c) 2026 h13942080472-prog。

本项目自有程序源代码、测试与构建脚本采用 [GNU GPL 第 3 版](LICENSE)，且仅限此版本（SPDX：`GPL-3.0-only`），不采用“第 3 版或更高版本”。

此许可不包含图片、音乐、音效、字体、剧情文本及其他非代码内容素材；这些内容的权利范围见 [素材说明](ASSET_RIGHTS.md)。第三方代码与素材继续遵循各自原有许可证。

本次更新后的项目自有代码及后续基于该代码构建的发布包采用 GPL-3.0-only。已发布的历史版本以其随附许可证为准，此前已经授予的许可不追溯撤销。完整对应源码通过各版本发布页的 Source code 下载提供。

## 目录

- `spire-godot/`：游戏源码、素材、内容包、测试和打包工具。
- `docs/`：现行契约、玩法设计、操作指南、验证记录与历史归档。
- `版本更新内容.txt`：版本更新记录。

用 Godot 打开 `spire-godot/project.godot` 后运行项目。开发与检查命令见 [操作入口](skills/repo-ops/SKILL.md)，打包见 [打包契约](docs/spec/packaging.md)，进度见 [变更记录](docs/record/changelog.md)，协作规则见 [AGENTS.md](AGENTS.md)。

仓库不包含 Godot 缓存、本地构建工具、测试日志、个人设置、签名私钥及安装包。发布时需在本机配置 Godot 导出模板；安卓另需 SDK、JDK 和个人签名配置。素材及第三方许可说明位于 `spire-godot/assets/vendor/CREDITS.md` 与 `spire-godot/packaging/licenses/`。
