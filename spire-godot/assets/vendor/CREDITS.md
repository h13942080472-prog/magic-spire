# 素材来源与授权

## 用户提供的音频

- `assets/audio/rope-leather-tension.mp3`：用户于2026-10-31提供本地文件 `oxidvideos-rope-amp-leather-tension-449628.mp3` 并指定用于绳索／皮革装备伤害与施加音效。直接复制，未剪辑、转码；播放不循环。SHA256：`DBDC331704548813EE29D98CF4EABE4E195D930258ADE6170B7FF39255E448DA`。来源标识沿用原文件名；未另行推定公开许可证。
- `assets/audio/girl-sound/profile-a/`：用户于2026-11-01提供本地音频包 `GirlSound/Profile A`，用于获得快感、佩戴拘束具、高潮及卡牌成功伤害拘束具时的角色声音。共186个OGG（12,353,823字节），按原包普通／堵嘴及四类目录直接复制，未剪辑、转码或改名文件；Godot导入均为不循环。以“小写文件名＋制表符＋文件SHA256”排序并以换行连接后的清单SHA256：`5A20DA8197161E3B0311F1587E75DE7DA00A5AAE006E88FB4A9100459D84CF13`。未另行推定公开许可证。

## 公开素材包

下载与核验日期：2026-09-06。仅从作者提供的公开下载入口取得文件，未使用《杀戮尖塔》原作美术。

| 作者与作品 | 来源 | 授权 | 本项目使用 |
|---|---|---|---|
| Robert / 0x72 — 16x16 DungeonTileset II v1.7 | https://0x72.itch.io/dungeontileset-ii | CC0 1.0 | `0x72/dungeon.png`：当前用于地图门与骷髅图标；先前墙面、地砖、石柱与旗帜背景已被绘制的月夜回廊替换。原始图集未修改，以区域读取和最近邻缩放显示。随附作者 README 与坐标表。 |
| Dennis960 — Female Character Portrait 64x64 | https://dennis960.itch.io/female-character-portrait | CC0 1.0 | `dennis960/portrait.png`：历史临时头像，现已停用。原文件与授权保留，不再由运行时加载。 |

授权原文核验：0x72 页面标明 “You can use this tileset for whatever you like (CC-0)”；Dennis960 页面标明 “Free to use character portrait, use however you want” 和 “CC0 1.0”。

CC0 正文：https://creativecommons.org/publicdomain/zero/1.0/legalcode

以上作者不参与或背书本游戏。项目绘制的敌人轮廓、篝火、卡框和路径不属于上述第三方素材。当前重新生成的人物和月夜回廊另见`assets/art/ART-NOTES.md`，不归入上述CC0素材包。

## 2026-11-01：交互音效第二版

`assets/audio/interaction/` 内 17 个 WAV 为本项目原创程序合成音效，采用 Python 标准库合成正弦音、滤波噪声和短包络，无第三方采样。格式为 48 kHz、双声道、16-bit PCM。按用户确认的第二版试听素材原样接入，包含低音量窗口开合与火球术；试听报幕语音未进入游戏。
