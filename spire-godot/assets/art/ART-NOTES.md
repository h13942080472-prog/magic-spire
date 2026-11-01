# 本批美术提示词与来源

## 2026-10-31 强人锁女 SVG 卡图

- 用户要求简洁SVG卡面，直接绘制 `assets/ui/cards/art_submission.svg`（480×320）。以绳索绑合的牌片、黄铜锁扣与中断的攻击符号构图，沿用深紫、金色和青绿配色；无外部素材、位图嵌入、文字字体或脚本依赖。
- 接入 `ui/card_face.gd::ILLUSTRATIONS` 的 `art_submission`，手牌、悬停及图鉴复用同一纹理，卡牌规则保持原样。

## 2026-10-31 绳艺大师与助理 SVG

- 按用户要求直接绘制原创矢量角色，素材为 `assets/ui/enemies/rope_master.svg` 与 `assets/ui/enemies/rope_assistant.svg`，均为640×840透明画布；由路径、描边与渐变构成，无外部图片、字体或脚本依赖。
- 大师采用银发卷须、单片眼镜、深紫长衣和金色绳结，双手呈展示动作；成年助理采用铜色短发、青绿工作服、绳盘和工具包。沿用已有敌人图的深轮廓、金色与青绿色配色。
- 经 `data/enemies.gd` 的 `visual` 字段与 `ui/arena.gd::ILLUSTRATIONS` 接入既有战斗及图鉴显示通路，替换原借用的绳堆与绳索形象；战斗规则与站位保持原样。

## 2026-09-21 股绳差分运行时接入

- 后续接入覆盖普通受限站姿与平板锁受限站姿；所有包含单手套的组合（含单手套＋平板锁）按用户最终要求沿用原底图及原加强带，不应用本次差分。此前两节是素材准备记录。
- 数据流：真实特殊装备 family／正耐久 → `SpecialEquipment.portrait_layers` → 共享 `EquipmentPortrait.configure` 底图选择。普通与平板锁新增无股绳底图，有股绳时复用旧底图；加强带按同一股绳事实切换。固定、自由、坐／躺立绘沿原通道。
- 本地按源图差异替换 RGBA，而非把无绳贴片叠在旧轮廓上；覆盖源图变为透明的区域以消除旧轮廓细线，平板锁右边沿使用所供锁版源图校正。没有使用生成工具，原文件不变。
- 新运行素材为 `equipment-body-plain-no-crotch-rope-v1.png`、`equipment-body-flat-lock-no-crotch-rope-v1.png`（均740×2214）与 `equipment-overlay-flat-lock-reinforcement-no-crotch-rope-v1.png`（246×294），PNG只含IHDR／IDAT／IEND；来源及底图哈希见两份股绳清单。单手套适配试产物已撤除。

## 2026-09-21 平板锁版股绳局部差分

- 用户补充 `00170-135882225.png`（无股绳）与 `QQ图片20260911234734.png`（有股绳），采用这对1536×2304同坐标原图，保留其锁体与加固带像素。仅适配这组带加固带的平板锁图，不宣称适配其它未提供画面。
- 数据流：源图对 → 既有本地白底抠图／差分辅助函数 → `equipment-overlay-crotch-rope-flat-lock-v1.png` 与 `equipment-overlay-crotch-rope-flat-lock-free-v1.png`；均296×274，源坐标原点(670,851)，相对BOUND_CROP为(280,761)。变化区域(680,861,956,1113)，来源、哈希与组合约束见 `equipment-crotch-rope-flat-lock-layer.json`。
- 两个方向的局部alpha替换均完整还原目标抠图的alpha及可见像素；仅图像PNG块、不含文本元数据，原文件不变。这版无普通差分的尖细突起，不套用普通版裁尖线以免裁掉锁带。只准备素材，未接入运行时。

## 2026-09-21 股绳局部差分素材

- 采用用户最终确认的图1 `codex-clipboard-9359ef44-4306-445f-9943-ea570c3776f5.png`（无股绳）、图2 `codex-clipboard-0a5a87f5-9b19-469e-835a-05bce54cf054.png`（有股绳）；此前发错的图未使用。
- 数据流：两张1536×2304对齐源图 → 复用 `build_equipment_special_layers.py` 的本地白底抠图与差分辅助函数 → 同坐标透明替换贴片。仅差异区域及羽化边缘，保留周围皮肤轮廓；不调用生成工具，不改原图，不带PNG文本元数据。
- 有股绳 `equipment-overlay-crotch-rope-v1.png`，无股绳 `equipment-overlay-crotch-rope-free-v1.png`，均299×282，源坐标原点(665,848)。实际变化范围(675,858,954,1120)，相对既有BOUND_CROP原点为(275,758)。来源哈希及图层信息见 `equipment-crotch-rope-layer.json`。
- 两张为替换贴片；清除旧区域再绘制对应版本，不能仅在旧绳之上叠无股绳图。裁尖前双向alpha替换与对应抠图的透明度及可见像素完全一致；按用户指示削去贴片右下尖细突起（局部y≥238，x+y≥468，边缘1.5像素羽化），只改alpha不重画颜色。
- 本次只准备差分素材，未修改运行时装备映射；平板锁版本使用用户后续单独提供的图对，见上节。

## 2026-09-21 欲能转换正式卡图

- 用户提供 `00155-2092312727.png`，按约定接入 `card-pleasure-conversion-formal-v1.png`。
- 本地移除PNG文本元数据，保留1920×1920原始像素、比例与背景；逐块CRC及原始IDAT一致性检查通过，源文件不变。
- 数据流：清理后PNG → `DisplaySettings.FORMAL_ART.cards.pleasure_conversion` → 既有卡面／图鉴；双面共图，默认正式版并保留测试画风，不改规则与布局。

## 2026-09-21 交感形态正式卡图

- 用户提供 `00153-1864203336.png`，接入 `card-sympathetic-form-formal-v1.png`。
- 本地移除PNG文本元数据，保留1920×1920原始像素、比例与背景；CRC及原始IDAT一致性检查通过，源文件不变。
- 数据流：清理后PNG → `DisplaySettings.FORMAL_ART.cards.sympathetic_form` → 既有卡面／图鉴；双面共图，默认正式版并保留测试画风，不改规则与布局。

## 2026-09-21 用力与顾涌正式卡图

- 用户提供 `00145-3340865038.png` → 用力！`card-strain-formal-v1.png`；顾涌！采用用户最新提供的 `00152-3394080224.png` → `card-slip-formal-v1.png`。
- 本地移除PNG元数据，保留1920×1920原始像素、比例与背景，源文件不变；逐块CRC与原始IDAT一致性检查通过。
- 数据流：清理后PNG → `DisplaySettings.FORMAL_ART.cards.strain/slip` → 既有卡面／图鉴；双面共图，默认正式版，保留测试画风切换，不改规则与布局。

## 2026-09-21 命运同担正式卡图

- 用户提供 `codex-clipboard-16a2216e-9fa5-4909-a847-d17eec8aacd8.png`，按已确认工作流接入命运同担；项目文件 `card-shared-fate-formal-v1.png`。
- 本地过滤PNG元数据，仅保留图像必需块，逐块CRC与原始IDAT一致性检查通过；保留1920×1920像素、比例和背景，源文件不变。
- 数据流：清理后PNG → `DisplaySettings.FORMAL_ART.cards.shared_fate` → 既有卡面／图鉴；双面共图，默认正式版并保留测试SVG切换，不改布局与规则。

## 2026-09-21 紧缚爱好模式替换图

- 用户提供 `codex-clipboard-072b8bf6-4aad-446a-a327-9fc2fb9cde0b.png`，接入 `card-binding-enthusiast-fixed-formal-v1.png`；去除tEXt元数据后仅IHDR／IDAT／IEND，1920×1920，CRC与原始IDAT逐字节一致，保留原像素和源文件。
- `FORMAL_ART.cards.binding_enthusiast` 统一声明原图与替换图；`formal` 默认跟随 `fixed_hero_portrait`（扶她出去），图鉴可显式选原图或替换图，手动选择优先并沿已有美术偏好保存。测试版仍可选。
- 数据流：模式开关／图鉴 → DisplaySettings美术偏好 → `art_texture` → `art_changed`刷新既有卡面；双面共用所选图片，不改游戏快照或规则。其它单图、灌注双面与敌人继续使用同一接口。

## 2026-09-21 紧缚爱好正式卡图

- 用户提供 `00141-3931109664.png`，授权接入紧缚爱好；项目文件 `card-binding-enthusiast-formal-v1.png`。
- 本地移除PNG文本元数据，成品仅IHDR／IDAT／IEND，逐块CRC与原图IDAT一致性通过。保留1920×1920原始像素、比例与背景，不改源文件。
- 数据流：清理后PNG → `DisplaySettings.FORMAL_ART.cards.binding_enthusiast` → 既有卡面／图鉴；双面共图，默认正式版并保留测试SVG切换，不改原有布局或规则。

## 2026-09-21 般若汤系列与猪神之皇焚正式卡图

- 用户提供 `00140-3340243041.png` 作为般若汤系列共用图，接入 `card-hannya-formal-v1.png`，1920×1920；去除PNG文本元数据，逐块CRC与原始IDAT一致性检查通过。
- 用户指定 `b12bd754d9fac3f1ab10a764434018f7.jpg` 用于猪神之皇焚，接入 `card-boar-emperor-blaze-formal-v1.jpg`，1080×1092；移除JPEG的APP0元信息，保留压缩图像扫描数据及原有文字，不重新压缩、不裁切。
- 数据流：去元数据图片 → `DisplaySettings.FORMAL_ART` → 既有卡面／图鉴。`hannya_1`至`hannya_4`及`good_soup`共享同一图片；`boar_emperor_blaze`使用猪图。双面共图，保留测试版选择，源文件不变。

## 2026-09-21 熟练而已正式卡图

- 用户提供 `00139-1844109518.png`，按已确认工作流接入熟练而已；项目文件 `card-practiced-formal-v1.png`。
- 本地移除PNG文本元数据，成品仅IHDR／IDAT／IEND，逐块CRC及原图IDAT一致性通过。保留1920×1920原始像素与背景，源文件不变。
- 数据流：清理后PNG → `DisplaySettings.FORMAL_ART.cards.practiced` → 既有卡面／图鉴；双面共用此图，默认正式版并保留测试SVG切换，不改布局和规则。

## 2026-09-21 无尽魔法少女战神正式卡图

- 用户提供 `00138-2324526895.png`，按已确认工作流接入无尽魔法少女战神；项目文件 `card-endless-war-goddess-formal-v1.png`。
- 本地移除PNG文本元数据，成品仅IHDR／IDAT／IEND，逐块CRC及原图IDAT一致性通过。保留1920×1920原始像素与背景，不改源文件。
- 数据流：清理后PNG → `DisplaySettings.FORMAL_ART.cards.endless_war_goddess` → 既有卡面／图鉴；双面共用此图，默认正式版并保留测试SVG切换，不改布局和规则。

## 2026-09-21 灌注双面正式卡图

- 用户提供 `00135-3764119089.png`（手部）与 `00136-4112113424.png`（腿部），分别接入 `card-infusion-hand-formal-v1.png` 与 `card-infusion-leg-formal-v1.png`。
- 本地移除PNG文本元数据，仅保留IHDR／IDAT／IEND；逐块CRC与原图IDAT一致性检查通过，两图均1920×1920，保持像素、比例与暗色背景，源文件不变。
- 数据流：`CardFace.effect_free` → `DisplaySettings.art_texture` → `FORMAL_ART` 的双面映射 → 同一卡图控件。依据现行效果，自由面用手部图，拘束面用腿部图；普通灌注与般若汤赠送版共用此组资源。单图卡牌与敌人沿用原路径，测试版仍用原SVG。

## 2026-09-21 汲取力量正式卡图

- 用户提供 `codex-clipboard-c92b71c3-118c-48cd-81b1-068bb13dd5bd.png`，按已确认的卡图工作流接入汲取力量；项目文件 `card-siphon-strength-formal-v1.png`。
- 本地过滤PNG元数据，逐块CRC与原图IDAT一致性检查通过；保留1920×1920尺寸、原始像素和暗色背景，源文件不变。
- 数据流：清理后PNG → `DisplaySettings.FORMAL_ART.cards.siphon_strength` → 既有卡面／图鉴；默认正式图，原SVG仍可切换，不改规则与布局。

## 2026-09-20 火焰精通正式卡图

- 用户提供 `00133-803601954.png`，授权用作火焰精通正式卡图；项目文件 `card-fire-mastery-formal-v1.png`。
- 本地移除PNG元数据，成品仅含IHDR／IDAT／IEND；逐块CRC与原图IDAT一致性检查通过。保留1920×1920尺寸、原始像素和暗色背景，源文件不变。
- 数据流：清理后PNG → `DisplaySettings.FORMAL_ART.cards.fire_mastery` → 既有卡面／图鉴；默认正式图，原SVG仍可切换，不改规则与布局。

## 2026-09-20 魔力回路正式卡图

- 用户提供 `codex-clipboard-32230ebd-2737-4710-8555-489dbabd35cd.png`，授权用作魔力回路正式卡图；项目文件 `card-mana-circuit-formal-v1.png`。
- 元数据过滤后仅保留 PNG 图像必需块，逐块CRC和原图IDAT一致性检查通过；保留1920×1920尺寸、原始像素和暗色背景，原文件不变。
- 数据流：清理后PNG → `DisplaySettings.FORMAL_ART.cards.mana_circuit` → 现有卡面／图鉴；默认正式图，原SVG仍可切换，不改规则与布局。

## 2026-09-20 身轻如燕正式卡图

- 用户提供 `00130-3456336496.png`，授权接入身轻如燕正式版画风；项目文件 `card-light-as-swallow-formal-v1.png`。
- 本地清除元数据，保留1920×1920尺寸、原有暗色背景和像素；不裁切、拉伸或重绘，原下载文件保持不变。PNG逐块CRC及原图IDAT一致性检查通过。
- 数据流：清理后PNG → `DisplaySettings.FORMAL_ART.cards` 中 `light_as_swallow`／`hannya_swallow` → 既有卡面与图鉴。普通版和赠送版共用正式图，保留测试版切换，不改玩法。

## 2026-09-20 henshin 正式卡图

- 用户提供 `codex-clipboard-8a396aef-a837-46fe-b00a-ee0cf51635b2.png`，授权作为 henshin 正式卡图；项目文件 `card-henshin-formal-v1.png`。
- 原剪贴板 PNG 已仅含 IHDR／IDAT／IEND，无附加元数据；本地过滤后仍与原图逐字节一致，逐块 CRC 检查通过。保持1920×1920尺寸、暗色背景与像素，不裁切、不拉伸、不重绘；源文件保持不变。
- 在 `DisplaySettings.FORMAL_ART.cards` 中登记 `henshin` 与 `hannya_henshin`，普通与完美版本共用同一图片；默认正式版，测试版 SVG 仍可选。复用既有卡面与图鉴通道，不改玩法。

## 2026-09-20 火动力学正式卡图

- 用户提供 `00127-3676734309.png` 并授权用作火动力学正式版画风；接入文件为 `card-fire-dynamics-formal-v1.png`，1920×1920，保留原有暗色背景。
- 本地移除 PNG 文本元数据，成品仅含 IHDR／IDAT／IEND 块；IDAT 压缩像素数据与用户原图逐字节一致，无缩放、裁切或重绘。下载目录原图保持不变。
- 通过 `DisplaySettings.FORMAL_ART.cards.fire_dynamics` 复用现有卡面与图鉴通道，默认正式版，原 SVG 仍可选作测试版；不改规则与画框。
- 成品 SHA256：`3e129faf50479464b033353b27e85b0aba5949191849c3e7a686b3d57d51993b`。

## 2026-09-19 魅魔警卫恢复原版战斗立绘

按用户最新要求，魅魔警卫恢复为2026-09-09提供并在项目v0.15验收的两张原版制服魅魔透明图。成品从仓库历史对象逐字节取回到`enemy-succubus-guards-v1/`，没有重新抠图、生成或重绘；源图、处理参数、尺寸与SHA256见该目录`README.md`。

`guard.visual_pool`、`enemy_visual`随机域及`guard_purple`／`guard_brown`稳定变体ID保持不变。战场`guard`只在最终美术映射处读取`SUCCUBUS_GUARD_PORTRAITS`；监狱巡视、收押和出狱对白继续读取`GUARD_PORTRAITS`中的现有紫发／棕发狱警。旧存档不重抽，双魅魔仍允许有放回重复，监狱固定分工与随机游标不变。

## 2026-09-19 大魔棒遗物图标

`assets/ui/relics/great_wand.svg` 为本次原生 SVG 绘制的晶体魔杖图标，沿用青色晶体与金色轮廓；无外部素材或生成模型。动态点数仍由既有 RelicCounter 叠在图标上，不写入图片。

## 2026-09-19 布阵卡面图标

`assets/ui/cards/formation.svg` 为本次用原生 SVG 绘制的魔法阵图标：三处阵位与中央晶体，沿用现有卡面金色／青色线条。无外部素材、无生成模型调用，卡面与能力状态共用该资源。

## 2026-09-15 单手套拘束具差分

本批只使用用户提供的两张1536×2304同姿势PNG进行本地像素差分和白底抠图，没有调用生成工具，也没有修改原文件。单手套源图为`C:/Users/16563/Downloads/00105-3376505697.png`（SHA256 `075487EA317622794B8B956B8E7BC16F5BE26007A47B4952B027532CFDDCACD2`）；红绳参照图为`C:/Users/16563/Downloads/00077-1312644243.png`（`23E76BA8FA2E76B3F55B39B2010936C66A25F4CACC9369CC4A6AE2AAE5E1DEA5`）。

`tools/build_equipment_single_glove_layer.py`在原图坐标(450,420,1050,1230)内提取变化，实际非透明差分边界为(477,446,1030,1213)，输出检查用`equipment-overlay-single-glove-v1.png`。由于新套体会移除原图拳头和红绳，运行时使用差分生成的透明替换底图，而不在旧像素上直接覆盖；普通／平板锁底图及大腿根有拘束／无拘束切片均生成对应版本。完整路径、哈希、坐标和映射见`equipment-single-glove-layer.json`。

运行时只读取只读投影`composite_portrait_layers`：存在主体仍有效的真实`kind == "glove"`复合拘束具时，短型、长型和两种肩带共用单手套差分；套体解除后恢复原红绳分段立绘。左侧装备肖像与战斗受限站姿同步，平板锁可组合；自由站姿、坐姿、躺姿和固定立绘设置不变。该显示映射不参与装备生成、等级、覆盖、容量、耐久、锁、候选、事务或随机结算。

## 2026-09-13 自由站姿平板锁与加固带差分

本批只使用用户提供的三张1536×2304对齐PNG进行本地像素差分和白底抠图，不调用生成工具，不修改源文件。无平板锁源图为`C:/Users/16563/Downloads/hand0legs0.png`（SHA256 `2C28A89B08E7BEE0F4761445A615CCDF34FDA43427C0C7C7CC33D5A1785AA41B`）；平板锁源图为`C:/Users/16563/Downloads/QQ图片202609131041226.png`（`B176781AADDA42CFE15E2F90432E1EDC55E1072748BC9857D61C5F095BA82442`）；带加固带源图为`C:/Users/16563/Downloads/QQ图片20260913104126.png`（`BF5EA5A1FBDB8E80321DF085726B1479D687B0760C9E1A45D6A13449795EF544`）。

`tools/build_free_flat_lock_layers.py`先从图2相对图1的差异提取138×284的`hero-overlay-flat-lock-free-v1.png`，源坐标(774,894)；再从图3相对图2的差异提取390×180的`hero-overlay-flat-lock-reinforcement-free-v1.png`，源坐标(634,956)。差异遮罩只在已确认区域保留连通变化，轻微扩展并羽化后乘以目标图的本地抠图alpha。复现参数、源哈希和坐标保存于`hero-stand-special-layers.json`。

运行时只在站姿且双臂／双腿拘束等级均为0时使用本差分：存在真实平板锁显示锁体层，存在其真实加固带再显示加固带层；未佩戴平板锁继续直接使用原`hero-stand-cutout-v2.png`。受限站姿仍沿原装备栏组合器，坐姿、躺姿和固定立绘设置不变。

## 2026-09-09 拘束等级战斗立绘

本批按用户要求仅使用本地抠图，不调用生成工具，也不重绘人物。两张源图均保持原文件不变：

| 姿态 | 用户源文件 | 原始尺寸 | 正式透明PNG | 裁剪范围 / 输出尺寸 |
| --- | --- | --- | --- | --- |
| 坐 | `C:/Users/16563/Downloads/00016-707839426.png` | 1920×1920 | `hero-restrained-sit-v1.png` | (108,247,1886,1779) / 1778×1532 |
| 躺 | `C:/Users/16563/Downloads/00014-3134264137.png` | 2112×1728 | `hero-restrained-lie-v1.png` | (0,511,2112,1379) / 2112×868 |

两图复用`tools/extract_bedded_portrait.py`的固定种子GrabCut，只以原图RGB计算alpha。坐姿使用背景种子700,1740／1000,1720／1400,1700，并以`--clear-neutral-shadow`清除臀部轮廓下方与最低前景相连的低色度投影；该步骤不会清除封闭在人物内部的浅色皮肤或衣物。卧姿的白色床面与灰色投影由主人物连通区域排除。两张图都已在深蓝底检查透明边缘和完整肢体。

运行时以只读投影`has_restraint_level`为唯一切换事实：双臂或双腿任一整数拘束等级大于0时，坐／躺姿读取上述资源；站姿直接复用`equipment_portrait.gd`组合器，因此战场和左侧装备栏同步显示同一底图与真实覆盖层。单独的眼／口装备不产生肢体拘束等级，不会借此切换整套战斗姿态。

## 2026-09-14：魅魔警卫与监狱狱警双立绘

用户提供 `00014-3038311190.png` 与 `1212122.png`，分别作为紫发狱警和棕发资深狱警，并同步替换魅魔警卫战斗立绘池的两张角色图。使用项目现有本地脚本移除边缘连通白底，没有调用生成式图像工具；透明成品、裁框、哈希和运行时约定见 `enemy-guards-v1/README.md`。战斗仍按每只魅魔警卫独立有放回抽取并保存变体；监狱例行巡视固定使用紫发图，收押、出狱前额外巡视和正常出狱对白固定使用棕发图，不消耗战斗美术随机域。

## 2026-09-07 装备栏五档差分与口/眼覆盖

来源均为用户提供的1536×2304 PNG，位于`C:/Users/16563/Downloads/`：

| 用途 | 源文件 | 正式资源 |
| --- | --- | --- |
| 图1 / 腿0级 | `00068-4048214563 (1).png` | `equipment-bound-legs0-v1.png` |
| 图2 / 腿1级 | `handsanylegs1 (2).png` | `equipment-bound-legs1-v1.png` |
| 图3 / 腿2级 | `00071-1333714550.png` | `equipment-bound-legs2-v1.png` |
| 图4 / 腿3级 | `00073-1839265440.png` | `equipment-bound-legs3-v1.png` |
| 图5 / 腿4级 | `00075-1504326030 (1).png` | `equipment-bound-legs4-v1.png` |
| 图6 / 嘴部 | `00076-3734441362.png` | `equipment-overlay-mouth-v1.png` |
| 图7 / 眼部 | `00077-1312644243.png` | `equipment-overlay-eyes-v1.png` |

处理只使用原图像素进行本地去背景、裁剪、差异遮罩与显示对齐，没有生成或重绘。`tools/build_equipment_variants.py <源目录>`复用extract_portrait，统一源图裁剪(390,90,1130,2304)，五张正式图均740×2214；额外白底种子677,480用于封闭发丝/手臂间空隙。图6/7整图中间结果仅保存在build，不加入运行时。

嘴部从图6相对图5的差异提取，源区域(655,374,950,479)，输出295×105；眼部从图7相对图6提取，源区域(590,238,990,374)，输出400×136。差异遮罩小幅扩展并羽化，乘以原图抠图alpha，保留原脸部/发丝像素，仅覆盖对应变化，眼部贴片不携带嘴部装备。两层共享五张差分坐标；自由图使用原图眼部锚点(823,383)，相对差分眼部(895,329)缩放0.907、旋转-0.1035弧度，扣除原自由图裁剪偏移。

图1同时是用户指定的“手臂无等级但腿部受限”临时图。图片是区域等级示意，不等于逐件装备外观清单。战场站/坐/躺资源保持独立。

## 2026-09-06 战场三姿态原图替换

本批只做用户提供图片的本地背景移除、透明裁剪及摆放，不生成或重绘人物。三个源文件保持原样：

| 姿态 | 用户源文件 | 原始尺寸 | 正式透明PNG | 裁剪范围 / 输出尺寸 |
| --- | --- | --- | --- | --- |
| 站 | `C:/Users/16563/Downloads/hand0legs0.png` | 1536×2304 | `hero-stand-cutout-v2.png` | (349,60,1138,2268) / 789×2208 |
| 坐 | `C:/Users/16563/Downloads/00066-1380771150.png` | 1920×1920 | `hero-sit-cutout-v2.png` | (64,101,1375,1906) / 1311×1805 |
| 躺 | `C:/Users/16563/Downloads/00067-362755172.png` | 2240×1664 | `hero-lie-cutout-v2.png` | (29,11,2167,1497) / 2138×1486 |

站/坐使用`tools/extract_portrait.py`，保留衣物内部白色与人物不透明原像素。站姿白底种子为668,432 / 813,467 / 966,785 / 572,848；坐姿为444,540 / 367,932，白底下限239，并清理已确认全是背景的源图边缘孤立像素（`--clear-border`）。

躺姿使用`tools/extract_bedded_portrait.py`，以原图颜色作为GrabCut前后景种子，保留主连通人物并恢复封闭衣料高光；三处人工确认的床单空隙为600,1250 / 840,1380 / 1357,740，最后只在这些种子对应的小型中性颜色连通域清理床单。依赖Pillow/numpy/OpenCV，所需版本记录在`tools/cutout-requirements.txt`；本机`build/cutout-deps`是可重建缓存，需要重建时可运行`python -m pip install --target build/cutout-deps -r tools/cutout-requirements.txt`，并给脚本传`--opencv-path build/cutout-deps`。这些依赖不进入游戏运行时。此算法只决定原图像素的alpha，不添加人物内容。

三张图均已在深色背景与正式站/坐/躺窗口检查。战场与头像现在直接使用alpha和线性采样；旧绿底像素图保留为历史资源，不再被人物运行时代码引用。左侧装备栏仍用此前单独确认的立绘。

以下为此前素材记录，历史“正式/当前”指各批次当时版本。

## 2026-09-06 装备区人物本地抠图

用户原图：`C:/Users/16563/Downloads/00081-1922854840.png`，1536×2304。正式透明资源：`equipment-portrait-cutout-v1.png`，621×2098；裁剪范围为原图(463,164)至(1084,2262)，保留14像素边距。该资源直接处理原图，没有生成式重绘，原文件不修改。

`tools/extract_portrait.py`以Pillow/numpy识别边缘连通的近白背景，再清理经人工查看确认的三个封闭背景区域，原图种子坐标为(644,622)、(816,524)、(743,879)。只处理背景与相邻边缘的透明度/白底混色，人物内部白色衣料不作全局色键删除。输出695837个透明像素、保留21940个不透明近白像素；已在深色背景检查头发、手臂间隙与衣料。需要复现时向脚本传入原图、输出路径及三个`--background-seed x,y`参数。

装备栏使用真实alpha与等比完整缩放，战场继续使用原三姿态像素图。立绘不随装备改变，不冒充穿戴差分。

## 2026-09-06 界面与敌人美术升级

正式资源：`assets/art/enemies-atlas-v2.png`，1536×1024；使用内置 image_gen 生成及编辑。六个区域依次为浮游绳索、皮带、锁、眼罩、封口符板和穿完整制服的成年女性警卫。区域坐标由 `ui/pixel_art.gd` 统一登记，所有敌人共用 `ui/arena.gd`；卡牌插图复用图集。没有新增敌人机制。

生成器未产出真实透明通道：最初是暗底，第二稿是烘焙棋盘底，均未采用。最终采用纯绿底源图，当时通过 chroma_key 画材运行时透明合成（历史方案；2026-09-11确认已无运行时调用，删除其闲置接口与着色器，源PNG保留）；源PNG原样复制，没有手工绘改。最终生成原文件为 `G:/CodexData/generated_images/01a070f2-5b3a-7980-82c2-3816e7a504a1/exec-a3942014-f81b-4b17-9f59-0fe5b3594d89.png`。用户批准的人物图集保持原样。

初次生成提示词：
Use case: stylized-concept. Asset type: one production sprite atlas for a side-view anime pixel-art fantasy roguelike. Create a 1536 by 1024 transparent PNG sprite sheet, exactly THREE COLUMNS and TWO ROWS of equal 512x512 cells, no gridlines, no labels, no text. Each cell contains one complete isolated game enemy centered with generous transparent margins; nothing crosses cell borders. Consistent polished 32-bit JRPG pixel-art, crisp visible pixel clusters, dark navy outlines, 5-tone shaded materials, antique gold highlights, pale cyan magic. TOP LEFT: a floating living coil of thick pale hemp rope, asymmetrical S-shaped dynamic knot, loose ends, tiny cyan runic glints. TOP MIDDLE: a floating curled dark brown leather belt with a large ornate bronze rectangular buckle, supple curling strap and punched holes, elegant serpentine silhouette. TOP RIGHT: a floating imposing antique padlock, dark iron body, gold keyhole, arched brass shackle, a couple of cyan rune motes. BOTTOM LEFT: a floating opaque violet cloth eye mask, silver rim, long trailing ribbons curving upward, its oval mask clearly different from the belt. BOTTOM MIDDLE: a floating dark blue enchanted sealing plate, compact curved oval central plate with a bright cyan seal rune, small leather fastening straps flowing behind, no person and no anatomy. BOTTOM RIGHT: one adult woman palace guard age 30, full body 3/4 SIDE VIEW FACING LEFT in a confident grounded combat stance, mature face, long dark plum hair ponytail, peaked navy cap with bronze insignia, fully clothed high-collared tailored navy uniform jacket, fitted trousers, tall boots, gold shoulder trim, utility belt with a coil of rope and a ring of keys, one hand holding a short baton downward. Character realistic anime adult proportions about 6.5 heads tall, not chibi, no cleavage, no fetish styling. Guard sprite should fit entirely in its own cell and occupy 88% of cell height. Other objects occupy 65-75% of their cells. Truly transparent background and spaces between sprites; no scenic backgrounds, no drop shadows, no glow clouds, no gradient vignette, no typography, no watermark. High quality finished game sprites not flat icons.

最终编辑提示词：
Production sprite-sheet edit. Keep the exact six sprites, positions, proportions, pixel details and colors in this image. Replace EVERY white and grey checkerboard background square and ALL empty space between and inside the sprites with one perfectly flat chroma-key color RGB(0,255,0), hex #00FF00. This is a green-screen sprite atlas. Absolutely no checkerboard, no gradient, no texture, no shadows or lighting on the background. All background pixels must be pure bright green including openings inside rope and belt and padlock loop, between limbs and loose ribbons. Preserve dark navy sprite edges and crisp cyan magic marks. Keep layout dimensions unchanged. Do not add/remove/repose any sprites.

UI边框、地图图标、卡牌面、配色与伤害数字由Godot绘制；统一样式在 `ui/visual_theme.gd`，伤害表现只消费提交前后可见生命变化，不改规则与资源。

使用内置 image_gen 工具生成；2026-09-06。
用户最新选择：暂用本轮上传的三姿态像素图，不继续重画。已将附件原样收纳为正式人物图集，替换此前的严格侧视稿。

## 正式人物素材
`assets/art/hero-poses-selected-v1.png`，源为用户上传的 `codex-clipboard-154312eb-6ae2-4400-b7f8-0356593d60f6.png`（1774×887）。站姿保留用户选择的三分之四视角，坐/躺保留同图姿态；不再将该版本描述为严格正侧视。前置生成参考为旧项目 `game-demo/public/assets/character/source-pose-sheets-v1/hero-standing-three-view-v1.png`，仅参考画风与人物外形，不读取或复用旧规则代码。

初次像素姿态提示词：
Use case: stylized-concept. NEW original pixel-art character pose sheet. The attached reference is ONLY the intended identity, costume, and PIXEL ART drawing style. Closely match its beautiful detailed anime pixel sprite aesthetic: pink-haired green-eyed adult magical heroine, age 26, large white ribbon with pink edges, partial high ponytail, layered pink dress with white ruffle hems and small gold heart brooch, white gloves, white boots with pink accents. Keep the recognizable original heroine design. Clear clustered pixel shading, delicate pixel outlines, carefully placed hair highlights, vibrant yet soft pinks, sprite proportions similar to the reference (about 5.5 heads tall, unmistakably an adult fantasy heroine), NOT smooth vector art, NOT painterly illustration, NOT a portrait. Make a single WIDE landscape sprite sheet divided into three equal invisible columns with at least 50 pixels clear space between figures. Column LEFT: full-body standing, 3/4 view facing right, arms comfortably at sides, hands visible and free. Column CENTER: same character seated on invisible floor facing right, torso upright, hands relaxed beside hips, bent knees and boots extending right, dress worn normally covering upper thighs. Column RIGHT: same character resting lying on her back on invisible floor, head on left and feet on right within that column, hands resting on abdomen, both legs extended, dress worn normally. All three poses must fit completely inside their own column; no overlap between columns; keep costume, face and hair identical. Use readable crisp pixel sprites at a consistent pixel density. Background must be perfectly flat chroma green #00FF00 everywhere outside the sprites, for Godot real-time cutout; no shadows, no floor, no gradient, no checkerboard, no text, no labels, no frames, no watermarks. Nonsexual neutral combat/resting poses, fully clothed, no restraints. Only these three sprites.

先前侧视草稿提示词（当前停用，文件保留为`hero-side-poses-v1.png`）：
Use case: precise-object-edit. Revise this three-pose pink-haired magical heroine pixel-art sheet for a TRUE SIDE-SCROLLING 2D BATTLE GAME. Preserve the same adult character age 26, beautiful detailed anime pixel rendering, pink ponytail, green eyes, big white-and-pink bow, layered pink dress, long white gloves and white/pink boots. Change the camera to STRICT ORTHOGRAPHIC SIDE VIEW AT BODY HEIGHT: absolutely NO top-down view, NO three-quarter/front view, NO foreshortening. LEFT sprite: standing neutral READY pose facing exactly screen RIGHT in complete side profile, one visible profile eye and one nose silhouette, both hands relaxed and free, aligned with body; character head, torso, hips, knees, and boots all shown from the side. MIDDLE sprite: seated facing exactly screen RIGHT, same strict side camera, upright torso and relaxed bent knees, boots point right; hands resting beside hips, skirt normally covers upper thighs. RIGHT sprite: lying on her back with head LEFT and boots RIGHT, shown strictly from her body's SIDE as in a side-scroller resting animation, no overhead view; face profile looks upward naturally, hands on abdomen, legs straight. Each figure fully isolated with generous separation, one figure per zone, no overlap, same character design and pixel scale across poses. Three sprites placed left-to-right in a single wide sprite sheet. Keep entire background perfectly uniform chroma green #00FF00 for game-engine compositing, no shadows, no gradient, no checkerboard, no stage, no panels, no words, no watermark. Fully clothed, nonsexual poses, no restraints. Emphasize exact side profile silhouettes and crisp beautiful pixel clustering.

生成源文件带绿色底，游戏通过统一画材做实时透明合成；源PNG原样保存，未手工重画或后处理。原图集的三个姿态区域分别读取，按正式姿态切换。这里只表现基础姿态，并非装备差分图。

## 正式背景素材
`assets/art/moonlit-gallery-v1.png`。
Use case: stylized-concept. Production game asset: one empty illustrated 16:9 widescreen battle background for an original Japanese anime magical-heroine card battler. A beautiful moonlit tower interior, a broad lateral stone arcade, elegant pointed arches, slender carved columns, tall violet stained-glass windows high behind the scene, a few warm brass sconces, deep indigo night visible through an arch, subtle floating silver dust. Fine hand-drawn anime linework with clean gentle cel-painted shading and layered atmospheric depth, polished Japanese RPG background art. Cool dusty lavender and blue-gray stone, muted antique gold details, restrained soft rose reflections that will harmonize with a pink-haired green-eyed heroine in a pink-white magical dress. The central play area must be uncluttered: no figures, no enemies, no cages, no large props. A wide level stone floor spans the image, floor-wall boundary around 58% of height, camera mostly side-on at a slightly elevated battle-game angle; smooth perspective without an extreme vanishing point. Keep the lower quarter dark and quiet because cards will overlay it; leave the upper area readable for intent panels. Light falls softly from upper right, faint warm fill from left. Elegant and enchanting with a hint of mystery, not horror. No pixel art, no photorealism, no gritty texture noise, no UI, no text, no lettering, no watermark. Wide 1536x1024 or 16:9 composition suitable for a Godot background.

## 未采用草稿
银发人物、平滑赛璐璐粉发人物与严格侧视像素稿均未接入当前运行时。当前采用用户重新上传并指定的三姿态像素稿。

## 2026-09-07：腿部按实际部位整段替换

用户最后确认：裁下绳子及周围整段腿部，保留皮肤、袜子及受压轮廓，不仅提取红绳。源图是`C:/Users/16563/Downloads/00077-1312644243.png`，1536×2304；无拘束腿段来自用户原图1。七处分别为大腿根、大腿中部、膝上、膝下、小腿中间、脚踝、脚掌，脚趾暂无差分。

`tools/build_equipment_leg_layers.py`生成每处有拘束/无拘束两张v3 PNG与挖空对应腿段的`equipment-body-sliced-v3.png`；上下切边12像素过渡，中央完整保留源图腿段。无拘束七段可逐像素还原原底图，脚部外形不会被旧底图重叠覆盖。坐标、裁框、图片路径和显示映射统一记录在`equipment-leg-layers.json`。全部为本地裁切合成，无生成式重绘，原文件不变。

普通大腿控制前三段，小腿控制膝下和中段；独立外带只控制真实固定点。自由图、原图1的分段底图、嘴/眼图层保持原接口。旧legs1—4不再用于运行时；本次中间的v2纯绳贴片已清理；图像不决定或改变装备规则。

## 2026-09-07：地图独立素材正式接入

map-icons-v1 与 map-parts-v2 均为本任务内置 image_gen 生成，逐图原始提示词和来源记录保存在各目录。ui/route_map.gd 直接使用独立PNG，纸面只在绘制时以0.78调暗，未生成或修改原图。入口、当前位置、可前往及完成标记均按正式投影显示；侧边建筑不拦截输入。纸面按视口等比裁取，不使用未验证的无缝平铺。此前 map-assembly-v1 仍为历史静态示意，不参与游戏。

route窗口88项通过。实际截图与日志见 `docs/record/verification.md` 本批记录。

## 2026-09-07：商店代码绘景

ui/shop_scenery.gd 和 ui/shop_glyph.gd 使用 Godot 原生几何绘制棚檐、灯笼、商人、柜台、货架和商品符号；无外部图片、无生成式绘图。卡牌插图复用项目既有 pixel_art 图集。只参考摊位陈列这一界面组织方式，不复制其他游戏的商人或美术。灯光与商人轻微起伏只按显示时间变化，不使用游戏随机域。

## 2026-09-09：魅魔的三局赌牌立绘

用户指定原图 C:/Users/16563/Downloads/00013-3999890640.png 复制为 event-fortune-teller-v1.png（1536×2304）。源图与项目文件 SHA256 一致，未重绘、裁切或去背景。事件只读投影公开稳定 id，ui/event_screen.gd 按 succubus_three_games 选择图片，所有阶段及结果页沿用；其他事件保留占位。左侧300×450画框内等比完整显示，图片不接收鼠标输入。

## 2026-09-10：废弃储物室与漂浮皮带群插图

用户确认接入本对话内置 imagegen 生成的两张最终预览；复制原 PNG，源文件保留，SHA256 校验一致。共用 `ui/event_screen.gd::ARTWORK`，正式事件与练习均按稳定事件 ID 加载，沿原画框完整等比显示、线性采样且不接收鼠标输入。

- `event-abandoned-storeroom-v1.png`：来源 `G:/CodexData/generated_images/01a07aed-ccd8-70b2-bc98-da783f6cdbe3/exec-59f91b5d-ac5c-4b0f-9cac-28501fc015ee.png`；采用第二版日系二次元绘制，前景为药剂、卷轴与工具。
- `event-floating-belt-cluster-v1.png`：来源 `G:/CodexData/generated_images/01a07aed-ccd8-70b2-bc98-da783f6cdbe3/exec-a4d3480c-13b5-4652-b6a4-3e26d05b88ac.png`；采用减少到约七条皮带后的版本，保留粉色附魔纹路与高塔回廊。

原三局赌牌插图保留；本批没有重新生成、裁切、拉伸或修改事件规则与正文。

## 2026-09-10：迷宫测绘队插图

用户提供 `C:/Users/16563/Downloads/00084-4094280623.png`，原样复制为 `event-maze-survey-team-v1.png`。源图与项目文件 SHA256 均为 `BA3494EAEE489196447608F8F49D6413229A76C3559DCB42B8EEE2C6A3DDC23F`；未重绘、裁切或拉伸。`ui/event_screen.gd` 按 `maze_survey_team` 加载，正式事件与练习共用，沿原画框完整等比显示。

## 2026-09-10：偷渡商人的魔药箱插图

用户提供 `C:/Users/16563/Downloads/00085-558123539.png` 并指定接入偷渡商人的魔药箱，原样复制为 `event-smuggled-mana-potions-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `smuggled_mana_potions` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：魅纹师的空房插图

用户提供 `C:/Users/16563/Downloads/00086-4247279898.png` 并指定接入魅纹师的空房，原样复制为 `event-enchanters-empty-studio-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `enchanters_empty_studio` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：女药师的试饮摊插图

用户提供 `C:/Users/16563/Downloads/00087-1686288904.png`，原样复制为 `event-alchemist-tasting-stall-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `alchemist_tasting_stall` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：缚疗修女插图

用户提供 `C:/Users/16563/Downloads/00088-549235516.png`，原样复制为 `event-binding-cleric-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `binding_cleric` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：拘束具堆里的微光插图

用户提供 `C:/Users/16563/Downloads/00089-3699988499.png`，原样复制为 `event-bound-adventurer-relic-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `bound_adventurer_relic` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：缚梦客房插图

用户提供 `C:/Users/16563/Downloads/00090-3863653336.png`，原样复制为 `event-bound-dream-guest-room-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `bound_dream_guest_room` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：神秘女人的雕像插图

用户提供 `C:/Users/16563/Downloads/00091-1968829285.png`，原样复制为 `event-mysterious-woman-statue-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `mysterious_woman_statue` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：魅魔的魔力典当铺插图

用户提供 `C:/Users/16563/Downloads/00093-2888790767.png`，原样复制为 `event-succubus-magic-pawnshop-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `succubus_magic_pawnshop` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。


## 2026-09-10：翘腿无视正式卡牌立绘

用户原图`C:/Users/16563/Downloads/00094-2394729949.png`（1536×2304）通过`tools/prepare_crossed_legs_art.py`本地抠图，复用色彩播种GrabCut并按已核对区域保留饮料、玻璃杯与吸管；定向清除座面阴影和手臂／躯干／大腿之间的背景孔洞。原图保持不变，没有生成或重绘。输出`card-crossed-legs-formal-v1.png`为1536×2138透明RGBA，原图裁框(0,64,1536,2202)，不拉伸、不裁去人物。

正式图登记到DisplaySettings.FORMAL_ART.cards.crossed_legs，原SVG继续作为测试版。透明区直接显示CardFace原有双面暗色背景，不烘焙另一份背景，也不改牌面效果。

源图SHA-256：`1eb9ca45fbb08cadbb4d74117602b6fe478248f41ccc4884fc5022fc980cc4b2`。输出SHA-256：`e029664d70119e811aa5e71a304ec3c05a0ba08ef3f1c295011ac4e2ea4f4aca`。

## 2026-09-11：商店自身魔力付款演出

用户提供的图2—5原样复制到 `assets/art/`，未裁切、重绘或拉伸；Godot以完整等比方式显示。现有常驻店主图 `assets/characters/shopkeeper.png` 按用户要求保持不变，图1不重复接入。四张演出图只表现已经成功提交的自身魔力付款，不参与付款资格、上半身束缚等级或随机结算。

- `00012-659780370.png` → `shop-payment-self-v1.png`，SHA256 `B05EE7A57A71F208E592DE59D3DE56841AF00306722FE314D34EBE5A0C60CB39`。
- `00006-2887118337.png` → `shop-payment-sleeve-v1.png`，SHA256 `0136966BEEDF7A0DCE2DE017EC42BCB03C2F032074222D68992B0DDF6A416BC6`。
- `00007-4136421944.png` → `shop-payment-hand-v1.png`，SHA256 `73F008719326CE976AF65BD57171BF279DD714C4499ECAC4A6BEF1E53AE81CDD`。
- `00010-2041060406.png` → `shop-payment-foot-v1.png`，SHA256 `738BFC24E23103EEDF98B67A5357B532462CE839B60399FEC8E7D4E0925D8127`。

## 2026-09-13：平板锁、加固带与马眼棒拘束立绘差分

用户提供四张1536×2304对齐原图，由`tools/build_equipment_special_layers.py`在本地进行白底抠图与像素差分，没有调用生成式绘图。图1与图2形成平板锁替换；图3相对图2扣除已经处理的平板锁后形成加固带透明层；图4与图3形成马眼棒透明层。源图保持不变，完整路径、配对关系与SHA-256记录在`equipment-special-layers.json`。

平板锁会移除原底图对应区域，因此输出同尺寸`equipment-body-flat-lock-v1.png`，并为会覆盖其下缘的大腿根分段输出有拘束／无拘束两个对应版本。加固带与马眼棒分别输出`equipment-overlay-flat-lock-reinforcement-v1.png`、`equipment-overlay-urethral-rod-v1.png`。构建脚本在暗色背景上重组大腿分段并检查可见接缝。

这些差分只应用于拘束站姿：左侧身体与拘束具立绘，以及战斗中复用同一拘束站姿的角色立绘。自由立绘、“扶她出去”固定立绘、坐姿与躺姿均不显示。普通平板锁显示锁体；真实加固带存在时叠加加固带；只有存在任意平板锁，且该锁内置导尿管或同时佩戴独立马眼棒时，才叠加依附锁体绘制的马眼棒差分。单独佩戴马眼棒时不显示该差分。显示只读取`equipment_portrait_layers`投影，不参与装备规则、容量、耐久、锁、高潮或随机结算。

## 2026-09-15：小魔女站／坐／躺立绘

用户明确提供并授权以下本地原图作为小魔女三姿势素材；仅使用`tools/extract_portrait.py`在本地去除白底，没有生成、重绘、变形或改色。

- 站姿源`C:/Users/16563/Downloads/00000-3192334327.png`，1536×2304，SHA-256 `913D0560A27695BECB67BAAFAEB35A9C342122669B32EA1B8203691ADC52B1C0`。外部白底种子`(1200,1800)`，前景连通种子`(750,1050)`，输出`witch-stand-cutout-v1.png`为1536×2295，SHA-256 `48645E61E95C76F1ED52E73ED15917CCA9FE8441A16A47E13109DFC80F2214FD`。
- 坐姿源`C:/Users/16563/Downloads/00002-1650663794.png`，1856×2112，SHA-256 `DD2A2214CB44319E8759044949988CD0038D87537E2148F87A9A167591D50CEB`。外部白底之外，只清除用户指出的帽内`(592,323)`与脚／斗篷之间`(1231,1699)`两个封闭白底区域；没有使用会误伤大腿的`(1168,1670)`区域。裁框`(15,63,1848,2070)`，输出`witch-sit-cutout-v1.png`为1833×2007，SHA-256 `79000FA19A3B978A536DCE726EC048D8DAE0D403072A6BB9EBF16AABD4ABF2BE`。
- 躺姿源`C:/Users/16563/Downloads/00003-3976721801.png`，2112×1856，SHA-256 `96ED0524705CB2FFAB48E8A6508504842B2E0BE4D2F4F4740AEE01EEDAB74652`。封闭白底种子`(1726,1110)`用于清除用户指出的双腿间白底，裁框`(20,221,2112,1777)`，输出`witch-lie-cutout-v1.png`为2092×1556，SHA-256 `BCB18D7046AA0562953CAB31288C2A22564FAD6879B0D03AEEDF70D30DD5D045`。
- 左侧身体栏从站姿源按`(460,0,1380,2304)`裁成920×2304的`witch-sidebar-cutout-v1.png`，SHA-256 `2A39CA5647C8370507B60B49243C63ECA6BE700FA745659DA6CCC66E4DC78725`。相对首版裁框向右取景320像素，使人物身体在现有178×454画框内向左移动并居中，保持同一宽高比。

战场根据只读View中的`character_id`和真实姿势选择三张图；身体栏使用独立窄裁图。小魔女暂无拘束差分，因此拘束状态不叠加角色1的嘴、眼、腿、平板锁或复合拘束图层。该显示映射不改变装备、姿势、资源、卡牌、随机或存档。

## 2026-09-19：无尽魔法少女战神卡图

assets/ui/cards/endless_war_goddess.svg 为本次绘制的项目原生矢量插图，沿用既有卡图尺寸，以星形、羽翼与无限符号表现能力；不使用外部素材。


## 2026-09-19 交感形态卡图

`assets/ui/cards/sympathetic_form.svg`为本次原创矢量图：深色底、金色法环、冷青晶体与暗红心形，延续测试版简洁图标风格。由代码绘制，未调用imagegen、未使用外部素材。随卡面注册共用于手牌与图鉴。

2026-09-19 护腕与怨灵系带：assets/ui/relics/wrist_bracer.svg、wraith_ribbon.svg 为本次原创矢量图标，沿用金色描边与冷青配色，分别绘制护腕和幽灵结饰，无外部素材。图标通过 RelicIcon.ART 供正式遗物界面复用。

2026-09-19 空灵挂件与智力斗篷：assets/ui/relics/ethereal_pendant.svg、intellect_cloak.svg 为本次原创矢量图标，分别采用悬挂晶体和星纹斗篷造型，沿用现有64×64金色描边／冷青配色，无外部素材。

2026-09-19 日晷：assets/ui/relics/sundial.svg 为本次原创64×64矢量图标，金色晷针、青灰椭圆盘与刻度，沿用项目原生图标风格；未复用《杀戮尖塔》图像或外部素材。

## 2026-09-19：会员卡遗物图标

assets/ui/relics/membership_card.svg 为本次绘制的项目原生64×64矢量图标，使用金色卡框、青色横纹与星形，不使用外部素材。


## 2026-09-19｜扫描全能王

`assets/ui/relics/universal_scanner.svg` 为本项目手工编写矢量图，使用既有金边／青色物品图标风格，扫描仪与复制卡片图形，无外部图片来源。

- 2026-09-19：`assets/ui/relics/ditto.svg` 为本项目原创矢量百变怪图标；变形后显示目标遗物已有图标，保持独立百变怪来源。

## 2026-09-19｜抖M印记、豆包与DeepSeek

assets/ui/relics/masochist_mark.svg、doubao.svg、deepseek.svg 为本次手工编写的64×64项目原生矢量图标，分别采用心形印章、豆包和蓝色小鲸鱼造型。无外部图片素材。豆包与蓝鲸是同一遗物的两种显示模式。
## 2026-09-19 鲤鱼打挺卡图

`assets/ui/cards/kip_up.svg` 为原生SVG绘制的翻身跃起人形与方向弧线，使用既有青金卡图配色，无外部素材。

## 2026-09-19｜紧缚检索卡图

`assets/ui/cards/binding_search.svg` 为本项目原创SVG：以皮带束起的卡牌和检索放大镜为主体，沿用青金配色，无外部图片素材。

## 2026-09-19 破铜烂铁机器人遗物图标

`assets/ui/relics/scrap_robot.svg` 为原生SVG绘制的拼补金属机器人头像，使用现有遗物的青金配色与铜色补丁；没有外部素材。

## 2026-09-19｜豆包像素头像

- `assets/ui/relics/doubao.png`：使用用户上传的 `codex-clipboard-e486ad19-8428-4075-9f92-d619228ca6df.png` 作为形象参考，由内置 `image_gen.imagegen` 生成像素风成年女性头像；按本次用户要求接入豆包遗物。DeepSeek 沿用原创蓝鲸 SVG。运行时头像采用 nearest 过滤；原始输出保留在工作区外 generated_images，项目引用已复制的 PNG。
- 提示词：Create one square game relic icon using the supplied portrait as reference. Transform into deliberate hand-crafted retro pixel art: adult cartoon woman, short side-part dark brown bob haircut, large dark brown eyes, warm subtle smile, black shirt, shoulders and head centered, pale sky blue flat background. Recognizable likeness to reference. Compact readable 64x64 pixel-grid design upscaled with crisp nearest-neighbor square edges. Restrained palette, clean chunky outlines, no blur, no text, no extra objects, no UI frame. Single square icon fills canvas.
- 实际输出为透明背景像素头像，保留此结果以适配现有遗物栏；没有额外移除或重绘人物部分。游戏文案的两套台词是原创戏仿，不作为真实产品引语。
## 2026-09-19：魔力附着

新增 `assets/ui/cards/mana_attachment.svg`：项目原生矢量图标，手部轮廓、魔力闪电与环绕箭头表示附着与群体攻击，用于卡面及能力状态；未引入外部素材。

## 2026-09-20 拘束就是力量！卡图

`assets/ui/cards/binding_power.svg` 为原生SVG绘制的握拳、链节与蓄力闪电符号，沿现有卡图的青金配色；没有使用外部素材。

## 2026-09-20 活动媚肉卡图

`assets/ui/cards/supple_flesh.svg` 为原生SVG绘制的柔韧弧带、动作箭头与光芒符号，使用现有青金配色；没有外部素材。

## 2026-09-20｜DeepSeek铁盆帽像素形象

- 用户提供 `00B46E7B5012EBFBD6B4950671BDAA28.jpg` 作为本次替换形象参考；内置 `image_gen.imagegen` 生成透明像素图，保留蓝发、蓝眼、女仆装和倒扣铁盆。项目文件为 `assets/ui/relics/deepseek.png`，遗物栏与豆包图鉴内的DeepSeek通过 `RelicIcon.ART.deepseek` 共用同一纹理，nearest采样。旧SVG不再被该映射使用。
- 生成原文件：`G:/CodexData/generated_images/01a07a1d-4055-7863-9860-8f938ba62711/exec-e598ce2d-b5b0-483d-a151-a9f17d4f71d7.png`；原样复制生成PNG，保留透明通道。
# 2026-09-20 欲望魔方 Pro Max

`assets/ui/relics/desire_cube_pro_max.svg` 为本次代码绘制的原生矢量图标，沿用既有遗物的金色描边与紫色魔方元素，增加心形与星光；无外部图片或生成模型素材。侧栏与图鉴统一通过 `RelicIcon.ART` 引用。

- 2026-09-20：`assets/ui/relics/pleasure_extractor.svg` 为本项目手绘 SVG 图标，沿用金色描边与青色魔瓶，以心形和向内箭头表示汲取；无需第三方素材。

- 2026-09-20：`assets/ui/relics/edging_seal.svg` 为本项目原创矢量图标，以钢印、限位刻线和三道青色印痕表达寸止钢印；无外部素材。

## 2026-09-20｜铁男独立SVG立绘

- `assets/ui/enemies/iron_man.svg` 为本次手工编写的原创透明矢量立绘，720×780画布；深铁灰装甲、双锁扣胸舱、液压钳爪、肩背捕缚机械臂、青色扫描灯与琥珀警示条。没有使用外部图片或ImageGen。
- 作为铁男的测试版画风，通过 `Enemies.TYPES.iron_man.visual → Arena.ILLUSTRATIONS → Arena._refresh_enemy_art` 统一供战斗与图鉴读取；复用原有等比缩放、停机变暗与鼠标穿透。正式版立绘仍沿独立美术偏好选择。

## 2026-09-20｜淫魔法卡池图标

- `assets/ui/cards/pressure_heart.svg` 与 `desire_magic.svg` 为本次原创矢量图形，无外部素材；前者是快感费用角标，后者以爱心和法阵作为本批七张牌共用插图。
- 卡面与图鉴沿 `CardFace.ILLUSTRATIONS` 和 `CardText.mana_entries` 共用映射；同时存在魔力费用时保留蓝色魔力角标。

- 2026-09-20：`assets/ui/relics/lucidity_necklace.svg` 为本项目手绘 SVG 图标，以金色项链、浅青晶石与白色光芒表现清醒；无需第三方素材。

- 2026-09-20：原创矢量 `assets/ui/end-turn-locked.svg`（结束回合锁链／锁头纹样）与 `assets/ui/cards/witch_binding_lure.svg`（护弧与转向拘束环），无外部素材。


## 2026-09-20｜四件专用遗物图标

`assets/ui/relics/brainwash_earrings.svg`、`hypnosis_hairpin.svg`、`lewd_silk_bodysuit.svg`、`lewd_silk_gloves.svg` 为本次手写的原生 SVG，以耳环、发卡、连体衣及手套轮廓配合旋纹、金色描边与青紫色点缀。统一通过 `RelicIcon.ART` 显示；无第三方图片或生成模型素材。

## 2026-09-21｜单腿套装备差分

用户提供四张1536×2304对齐原图，由`tools/build_equipment_single_leg_layers.py`在本地对白底抠图并按连通像素差异提取腿部，没有调用生成式绘图。脚本只保留纵坐标1100以下的三个大面积腿部差异组件，明确排除四张图中同时变化的手臂装备。

- 基准`C:/Users/16563/Downloads/00077-1312644243.png`，SHA-256 `3EC1855B084FFD5902D4A7E283251EF35B6064CFAF27F75367B777F01FD05F0F`。
- 短上段`C:/Users/16563/Downloads/00158-520016716.png`，SHA-256 `766E3F4238602EDCB4C763B16D617F01434B5B79E6A179F6F484CF758D7DCCEC`；输出`equipment-overlay-single-leg-upper-v1.png`。
- 短上段＋短下段`C:/Users/16563/Downloads/00159-2677612210.png`，SHA-256 `4A766A4F8066473CB4FD50773627B9F77609554B9B7421B13CB55A6456E31CA8`；其中小腿组件独立输出`equipment-overlay-single-leg-lower-v1.png`，可单独显示或与短上段叠合还原原图。
- 长款`C:/Users/16563/Downloads/00160-4038985730.png`，SHA-256 `5E5E12727C1F55BB9F7A64B4B7B937A27E2B8E98400D0E591A229A67ADDECCF8`；输出`equipment-overlay-single-leg-long-v1.png`，用于长至脚踝与长至脚趾两种现有套体。

来源、裁框与成品哈希集中记录在`equipment-single-leg-layers.json`。运行时按活动复合装备的稳定`kind/variant`读取；短上段、短下段可以同时存在，长款生效时保留真实投影但隐藏两种短款连续层。脚本同时为三种腿套生成完整底图替换，并为覆盖到的每个横切片生成完整RGBA替换，包含套体、皮肤与透明轮廓；普通、皮革、平板锁、单手套及其组合分别保留对应上下文。运行时先以目标图透明区域清除底图和横切片中的旧轮廓，再把连续差分置于其它覆盖层之后；不会因隐藏整条横切片形成透明缺口，也不会让短款从长款透明边缘穿出。套体破坏后差分与替换切片同时消失，剩余独立外带恢复既有分段显示。

## 2026-09-21｜皮带与红绳材质差分

使用用户提供的两张1536×2304对齐原图，通过 `tools/build_equipment_material_layers.py` 本地像素差异、既有抠图与RGBA替换函数处理，没有生成新画面；32张PNG均无嵌入元数据。皮带源 `C:/Users/16563/Downloads/00169-825092941.png`，SHA-256 `b07a285599e8700b86cb097bc9e057d55c4f8a93980d07be4f80702dd03f8964`；红绳源 `C:/Users/16563/Downloads/00163-4122631836.png`，SHA-256 `056d6f16b6058560b24e6ef32b1a6e216bff3f9e7389e49e07a834602b28f2d6`。

成品来源、尺寸、坐标及哈希集中于 `equipment-material-layers.json`。普通／平板锁、股绳有无与上身两种材质共8张底图；七个腿锚点各有红绳／皮带／自由切片，大腿根另有平板锁版本，共24张。连续分界采用源图y=1180、1325、1480、1625、1800、1965、2135、2304。皮革版只从两张源图的差异中保留9个大面积深色皮带组件及窄抗锯齿边缘，再合成到自由切片的统一皮肤底图；皮带掩膜不得触及横切片分界。这样相邻部位混用红绳、皮带或自由状态时不会切换整段皮肤色调，也不会形成横向黑线。红绳与自由切片重建逐可见像素保持原有成品。单腿套生成器复用这些边界，单手套仍使用其专用旧切片，避免恢复旧手臂像素。显示选择契约见 `docs/spec/release-interface.md`。

## 2026-10-31｜魔法少女被捕过场插图

以下成人向插图均由用户直接提供。项目内PNG统一以 Pillow 重新编码，不保留源文件的 `parameters` 或其它附加元数据；没有使用生成式改图。

- `assets/art/prison-capture-intro-leather-v1.png`：皮革拘束分支；源文件 `codex-clipboard-d9d3fa4f-ed04-4009-bb03-0c0b7315d056.png`，1472×2432，源SHA-256 `4552CFAFBFCE29F41F72A11A868CACB3A1123AD718B9FC8D880DC9D68CE19A0D`；无元数据成品SHA-256 `83430FA3E3DC2D6E2B8DBC06A24EE6E73D2ABC8A214279848C1A62223022438A`。
- `assets/art/prison-capture-intro-rope-v1.png`：绳索拘束分支；替换源文件 `00014-1991231483.png`，1536×2304，源SHA-256 `F965871847E7BCFF6BA5B57AADA807928B5DBD8EA3B9D0C1236D4B61539B56B4`；无元数据成品SHA-256 `B6870F64469FB74FDE2579B4BC9F64FAFD2B7F7E2DE2C0F818D96712B63A2287`。
- `assets/art/prison-capture-intro-flat-lock-v1.png`：固定主角立绘／平板锁分支；源文件 `codex-clipboard-8f829d7c-c094-4258-8aca-1d26458c4155.png`，1536×2304，源SHA-256 `5A6D98B02F21797319AF9941ED43A49665BCA3EAB227EFC234BF41DA2290DA51`；无元数据成品SHA-256 `C07AD907E9ACE1BCD784894B4110E9B98E9D59277513E80AF2A5AF00AB89EA91`。
- `assets/art/hero-hogtie-pose-cutout-v1.png`：仅用于战斗中的驷马缚特殊姿势；源文件 `00003-71753615 (1).png`，1920×1920，源SHA-256 `3792F84EFE76618D7B18686B91539CCF90E9CC9EF3AD68E1D524CC73C6D50F3A`。使用本地 `isnet-anime` 模型移除白底并按非透明边界留24像素裁切，成品1892×1101、RGBA、SHA-256 `B2CF0136BB6D7C5C2CDACAC9AE9BAF24B57FD9D4DE5D4FA6B41107C224D0788D`，无附加元数据。
