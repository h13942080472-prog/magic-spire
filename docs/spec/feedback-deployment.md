# 游戏内反馈：Gmail 转发服务契约（部署与运维）

本文件是现行契约：登记游戏内反馈入口的客户端字段、服务端接口、限额与失败处理、验收边界。
本文件不写执行结果；通过／失败／未执行只登记在验证记录（`docs/record/verification.md`）。

路径约定：不带 `spire-godot/` 前缀的脚本与工程路径（`tools/feedback-service/`、`project.godot`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 玩家在游戏内向固定收件人递交反馈的端到端路径：客户端窗口 → Apps Script Web App → Gmail。
- 不含：游戏规则、存档格式本身（存档只作为附件转发既有固定点内容，格式契约见
  `docs/spec/save-fixed-points.md`）、版本发布（见 `docs/spec/packaging.md`）。
- 服务是**小规模匿名反馈入口**，不是带账号身份验证的反滥用系统；任何"防刷"表述不得超出此口径。

## 接口

客户端与服务的唯一接口是 `project.godot` 中 `[feedback]` 的 `endpoint="完整 /exec 地址"`。

| 调用 | 语义 |
| --- | --- |
| 浏览器 / 匿名 GET 部署地址 | 只返回服务版本（`service`／`schema`），**不发送邮件**；`schema>=2` 声明支持带存档提交（见「服务版本门控」） |
| 正式 POST 提交 | 才调用邮件服务；返回 `ok:true` 表示 `MailApp` 接受了该次邮件，**不保证**已出现在收件箱 |
| 回执补查（可选一次） | 对原 `exec` 地址追加 receipt 编号查询；只返回该随机编号的发送状态，不泄露正文、附件或收件人 |
| 管理入口 | [管理脚本](https://script.google.com/d/1-syp_ASOKIj4Qv1xv2O78RBr5E4cYMJW1rG_uiMAMmTAjbHi_u0aPiMf/edit)、[服务状态](https://script.google.com/macros/s/AKfycbw9SHt60mspbgTUvGsDpmV1ylFKXBJ76zupmjXben_3Sh_2yDA3G0eHmDdhdFlRUoeLMA/exec) |

- 脚本 ID：`1-syp_ASOKIj4Qv1xv2O78RBr5E4cYMJW1rG_uiMAMmTAjbHi_u0aPiMf`；部署 ID：`AKfycbw9SHt60mspbgTUvGsDpmV1ylFKXBJ76zupmjXben_3Sh_2yDA3G0eHmDdhdFlRUoeLMA`，版本 3。
- 收件邮箱**只在转发服务内固定**为 `towerlover7787@gmail.com`：玩家界面的编辑页与确认页都不展示地址，客户端也不保存该收件地址；服务端不接受客户端提供的收件人。
- 服务维护账号（部署账号）为 `h13942080472@gmail.com`；维护账号与固定收件人**不必相同**。
- 入口位置：场景右上角的「问题与建议」（商店位于左侧上方）。窗口布局：左侧填写／预览、右侧截图与存档附件、底部网络提示与提交按钮。
- 两个 schema 不可混用：GET 的 `schema` 是**服务能力版本**（支持存档附件时为 `>=2`）；
  POST 报告内的 `p.schema` 是**报告格式版本**（仍为 `1`，只多一个可选的 `save` 键）。

## 输入域

客户端可提交的字段与其上限：

| 字段 | 规则 |
| --- | --- |
| 类型 | Bug／修改建议 |
| 标题、正文 | 纯文本；提交前可预览 |
| 最近行动日志 | 最近 40 条，**默认不勾选** |
| 截图 | 最多 3 张；可截取游戏画面（自动隐藏反馈窗口）或选取本地 PNG／JPEG；统一压缩为最长 1600 像素的 JPEG，每张最多 2 MB；**不上传原始文件路径** |
| 当前进度存档 | 复选框「一并附带当前进度存档」，**默认勾选**，旁边常驻说明「反馈会连同当前进度存档一起发送；取消勾选则只发送上面的内容。」；勾选且服务端声明支持时附带本局固定点存档（`SaveStore.fixed_point_text`，文件名＝当前 `slot`＋`.json`，内容＝写入时刻的 `restart_snapshot()`＋当时线稿，含 `state.initial_seed` 与 `state.tower_generation`）；**不含 `.bak`**；解码后上限 2 MiB（base64 ≤2796204 字符） |

服务端校验：字段长度、附件数量、单张大小与 JPEG 签名；正文一律按纯文本处理。
草稿存于 `user://feedback-draft.json`，与正式存档／快速 SL 无关，包含玩家选择的截图；
点击「清空草稿」或成功提交会清空它。**存档附件不进草稿文件**（草稿体积与既有版本相同，
存档本体仍只在 `user://saves`）。
版本号沿 `ProjectSettings.application/config/version → _capture_context → draft.context → 预览／提交` 共用通道读取。重新打开跨版本草稿时更新版本号并清除旧提交编号、确认状态，保留正文、截图、原场次与日志；同版本重新打开保留重试编号。
隐私口径：**仅在你可见并同意时发送当前进度存档**——反馈页以默认勾选的复选框与常驻说明披露，
玩家可随时取消；除此之外不收集系统用户名、设备唯一标识、邮箱密码，也不上传原始文件路径或任意其他本地文件。
网络前提：客户端必须能访问 Google 服务；反馈页面明确显示「提交反馈需要开启梯子（能访问 Google 服务）」，
建议用全局／TUN 模式覆盖游戏程序（只有浏览器配置代理不保证游戏能联网）；普通游戏不需要此连接。
Android 侧已打开联网权限。

## 存档附件

- 客户端读入口：`SaveStore.fixed_point_text(game, map_drawings)`（只读、无文件访问；
  见 `docs/spec/save-fixed-points.md`）。附件＝该局**当前固定点**（写入时刻的 `restart_snapshot()`
  加当时线稿），与本局写盘内容同源同格式；**不读取、不上传 `.bak`**（上一个固定点）。
- 与种子标识的关系：附件内的快照携带 `state.initial_seed` 与 `state.tower_generation`，与地图角落
  可复制的四要素文本互为对照；标识本身不足以复现当前进度（见 `docs/spec/seed-identity.md`）。
- 上限：客户端 `MAX_SAVE_BYTES = 2*1024*1024`（解码后）；服务端原始 POST 上限由 9 MiB 提到
  12 MiB 字符。实测存档 26.5–27.2 KB（`build/next-perf/*` 六份），余量约 70 倍。
- 单封最大附件量＝3 张截图（各 ≤2 MB）＋存档（≤2 MB）≤ 8 MB，低于 Gmail／MailApp 约 25 MB 的
  单封上限；`MailApp` 每日额度按收件人计、不按体积计，附件只影响单封大小，不额外消耗额度。
- 捕获时机：按草稿身份捕获一次（`_capture_save_once()`）——新建草稿随 `draft.context` 一起捕获，
  从磁盘恢复的草稿（`context` 已存在）在首次使用时捕获，此时游戏是本局而非启动时的默认局；
  勾选复选框也会在未捕获时补捕一次。同一草稿的编辑与重试都不重捕，重试发送**逐字相同**的 POST body，
  失败重试沿用原编号与去重回执；`clear_draft()` 或成功提交后，下一个草稿重新捕获。
- 未勾选／没有可附带的存档／本次草稿未捕获／校验未通过／超限：**不带附件**，并在确认页的附件行
  显示各自的原因（如「未附带存档：存档过大（超过 2 MB），未附带。」「未附带存档：当前进度存档校验未通过，未附带。」），
  提交与游戏不受影响；文案走 `ui.feedback.save.*` 本地化 key，有存档时不得显示「没有可附带的存档」。

## 服务版本门控（上线顺序约束）

客户端一旦会在 payload 里带 `save`，而服务端可能仍是旧版；**旧服务对未知字段的行为未证**，
最坏情况是整条反馈被拒，而不只是附件缺席。因此：

- 提交前先按既有 GET 探测服务端（同一 `endpoint`，只回版本、不发信）：读取 `service` 与 `schema`，
  **只有 `schema>=2` 才把 `save` 放进 payload**。`schema<2`、字段缺失、非 200、超时或 JSON 解析失败
  一律按"不支持"处理。
- 不支持时按旧 schema 提交（不带 `save`），并在反馈页可见地说明
  **「当前反馈服务暂不支持附带存档。」**（确认页附件行位置）。
- **不允许**用"先带附件、失败再重发"兜底（会重复投递）；探测失败不得阻塞提交、不得改变草稿与编号。
- 服务端在支持该附件时才把 GET 的 `schema` 提高到 2；报告格式字段 `p.schema` 仍为 1。
  降级路径长期保留：客户端不得假定服务端已升级。

## 失败语义

- 客户端只在玩家确认后发送；提交期间重复点击被禁用；失败保留草稿与原反馈编号。
- 附件与探测失败只影响附件：探测按"不支持"降级、捕获失败或超限不带附件，**都不阻塞提交**，
  也不改变草稿、编号与去重语义。
- 去重摘要的哈希输入**不含 `save`**（同编号只改存档仍命中回执、不重发；同编号改标题仍 `invalid`）；
  理由：失败重试时存档可能已前移，不能因此把报告判为伪造。
- 上线顺序：先在服务维护账号部署声明 `schema>=2` 的新版本，再打包带 `save` 的客户端；反序时
  客户端只会走降级路径（邮件送达、无附件），不得对外宣称"支持附带存档"。
- HTTPS 校验保留；302／303 只向 `script.googleusercontent.com` 发起**不带正文**的 GET 读取回执，最多 4 次；
  不自动转发 POST（实测 Godot 自动跳转产生 400，因此由反馈请求入口显式处理）。
- 若提交／回执跳转未返回有效响应：对原 `exec` 地址追加 receipt 编号**最多补查一次**，不重发邮件正文；
  补查也失败时保留草稿并停止，等待玩家明确重试。
- 服务端去重：保留 48 小时内已发送编号的摘要，减少重试产生的重复邮件；
  **不保证严格一次送达**（服务在记录回执前异常退出时无法保证已发送）。
- 限流：全局每 10 秒最多一次新提交；串行锁防止同时重复发送。
- 一次发送尝试 = 一个收件人；个人 Gmail 的 Apps Script 额度为每日 100 个收件人，脚本再限制
  每 24 小时最多 80 次发送尝试以预留额度；不同账号／Google 策略可能变化，
  实际以官方额度与 `MailApp.getRemainingDailyQuota()` 为准。
- 首次验收必须检查垃圾邮件目录；只收到 `ok:true` 不等于已送达收件箱。

## 证据入口

- 离线：`node tools/feedback-service/test.cjs`——验证收件人固定、参数与附件校验、去重、限额、
  邮件失败与建议分类；不调用 Google、不发送邮件。存档附件同时覆盖：
  - 接受：带合法 `save` 的提交（`ok:true`；邮件附件 `mime=application/json`、`name=tower.json`、
    字节与提交文本相等；正文含存档行）；无 `save` 的提交行为与既有版本相同；GET 声明 `schema`。
  - 拒绝：非法 base64／解码超 2 MiB／`name` 不符（含 `../` 路径）／解码非 JSON／`format!=2`／
    `save` 非对象或含额外键／原始 POST 超 12 MiB 字符 → `invalid` 且不发信。
  - 回执：同编号改标题 → `invalid`；同编号只改 `save` → 命中回执且不重发。
- 公网验收：匿名 GET 返回 `service`／`schema`；正式客户端发送无效 POST 后收到 `invalid` 并保留草稿；
  再由用户确认提交一封实际邮件并按编号在收件账号 Gmail 全邮箱搜索，确认送达并完成收件验收。
  2026-09-13 的验收记录（编号、时间、跳转与重试过程）见 `docs/record/verification.md`。
- 界面案例归既有 `interface` 分类：检查入口相对日志的位置、必填、截图、附件上限、勾选日志、预览、
  关闭保留、不显示地址、超时重试、确认成功及游戏状态不变。存档附件同时覆盖具名 check：
  - `FEEDBACK attaches the current save by default`（默认勾选；`payload().save.name` 与当前 slot 一致；
    base64 解码后的信封 `format==2` 且校验和成立；确认页显示附件名与大小）。
  - `FEEDBACK unchecked save is omitted but submit still works`、`FEEDBACK oversized or missing save never blocks`
    （无 `save` 键、可见原因、提交照常走通且游戏状态不变）、`FEEDBACK every missing save names its own reason`
    （无来源／只读入口失败／超限各自显示自己的原因，且不得声称「没有可附带的存档」）。
  - `FEEDBACK restored draft captures at its first use`（载入的旧草稿保留原 `context`，首次使用时捕获本局
    固定点，且后续使用不重捕、附件字节不变）、`FEEDBACK restored draft checked later captures on the toggle`
    （未勾选的旧草稿在勾选时补捕）。
  - `FEEDBACK retry keeps identical save bytes`（沿用既有同一 body 判据）。
  - `FEEDBACK old service schema submits without the save`（探测 GET 返回 `schema:1` → payload 无 `save`
    且界面可见「当前反馈服务暂不支持附带存档。」）、`FEEDBACK new service schema includes the save`
    （`schema:2` → 含 `save`）、`FEEDBACK probe failure degrades without blocking`
    （超时／非 200／坏 JSON → 无 `save`、提交继续）。
  - 既有请求计数断言按"探测 GET＋POST"更新；判据本身不变（同一草稿重试的 POST body 逐字相同）。
- 边界：HTTP 传输使用测试替身，**不能代替**公网部署与真实收件验收；桌面探针不代表 Android 真机，
  Android 实机收件仍未验收。
- 官方依据：[Web App 部署](https://developers.google.com/apps-script/guides/web)、
  [MailApp 与附件](https://developers.google.com/apps-script/reference/mail/mail-app)、
  [每日额度](https://developers.google.com/apps-script/guides/services/quotas)、
  [ContentService 重定向](https://developers.google.com/apps-script/guides/content)。

## 首次部署或重建（由服务维护账号完成）

1. 用服务维护账号登录 [Google Apps Script](https://script.google.com/home/start)，新建项目，名称可填「紧缚尖塔反馈」；
   收件地址继续由 `Code.gs` 固定。
2. 把 `tools/feedback-service/Code.gs` 的全部内容复制到项目的 `Code.gs`。
3. 打开「在编辑器中显示 appsscript.json 清单文件」，把同目录 `appsscript.json` 的内容复制进去；
   脚本仅请求发送邮件权限，不读取收件箱。
4. 「部署 → 新部署」，类型选「网页应用」，执行身份选「我」，访问权限选「任何人」（包括未登录用户）；
   授权发送邮件时确认当前账号为服务维护账号，必要时在编辑器运行 `doGet` 完成授权。
5. 复制以 `https://script.google.com/macros/s/` 开头、以 `/exec` 结尾的地址；
   **不要**使用仅开发者可访问的 `/dev` 测试地址；把 `/exec` 地址交给维护者即可，无需提供邮箱密码或授权码。
6. 维护者在 `project.godot` 的 `[feedback]` 写入 `endpoint`，检查服务，再由用户确认进行一次实际邮件提交与收件验收，
   最后按发布要求打包。仅修改编辑器中的脚本**不会**更新已有部署；后续应「管理部署 → 编辑 → 新版本」。

- **上线顺序（存档附件的前置）**：支持存档附件的那次服务改动必须**先部署并验证**——按第 5 步取新
  `/exec` 地址，用匿名 GET 确认返回 `schema>=2`；之后才打包／发布会在 payload 里带 `save` 的客户端。
  反序时客户端走「服务版本门控」的降级路径（邮件照发、无附件），此时不得宣称已支持附带存档。
  部署动作本身不在本仓库的切片内，但缺这一步即视为该功能未上线。

OAuth 凭据仅保留在本机用户配置，不进入项目或游戏包；维护工作目录 `build/feedback-deploy` 不属于运行资源。
