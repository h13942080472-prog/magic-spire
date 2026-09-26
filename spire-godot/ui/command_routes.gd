extends RefCounted

# M-I 分类子路由（docs/spec/candidate-removal.md §3.1；N2）：每类指令一条装配路径。
# 装配＝把 UI 意图（点击／键盘／触屏／拖放／自动接管）落成类型化指令：取本地选中态、解析改道、
# 按 §3.3 键面装箱；不判定资格（资格只由 core 的唯一判定给出），不提交（提交执行段在 ui/main.gd::_submit）。
# 本文件与 command_router.gd 都不 preload core；形状装箱经 host.game.command（指令构造的唯一入口）。
#
# 意图来源两种形态（同一投影只认稳定 ID；其余键不进 params、不参与提交复核）：
#  ①显示行（含 payload／valid／automated）＝已解析的行，提交前只保留改动前的 A40 改道；
#  ②稳定 ID 意图（uid／free／target…，可带 "click" 标记点击链）＝待解析的点击／拖放意图。
# 装配返回三种结果：
#  {kind, params, expected_version}＝可提交指令；{"handled":true}＝已改道或已给提示（不再提交）；{}＝未解析。
const HANDLED={"handled":true}
const Queries=preload("res://ui/target_queries.gd")

# 分类子路由的装配入口（指令路由 ROUTES 的每个值都在此处有一条实现）。
static func assemble(route: String, host, source: Dictionary, expected_version: int) -> Dictionary:
 match route:
  "battle": return _battle(host,source,expected_version)
  "item","flow","rest","shop","event","prison","route","reward","departure","relic","demo":
   return _box(host,source,expected_version)
 return {}

# 意图来源的稳定 ID 字段：显示行取 payload，纯意图取自身（同一投影只认声明键面）。
static func _intent(source: Dictionary) -> Dictionary:
 return source.payload if source.has("payload") else source

# 装箱：意图来源 → 类型化指令（kind＋params＋expected_version）；键面与默认值由 core 的声明表给出。
static func _box(host, source: Dictionary, expected_version: int) -> Dictionary:
 var intent=_intent(source)
 if String(intent.get("kind",""))=="": return {}
 return host.game.command(intent,expected_version)

# 战斗／装备／道具类：card 的装配含 A40–A45 改道（原提交前改道链并入此处）；其余按形状装箱。
static func _battle(host, source: Dictionary, expected_version: int) -> Dictionary:
 if String(_intent(source).get("kind",""))!="card": return _box(host,source,expected_version)
 if source.has("payload"): return _resolved_card(host,source,expected_version)
 return _card_intent(host,source,expected_version)

# 已解析的显示行（原 A1–A39 的提交路径）：提交前只保留改动前的 A40 改道（见 _hand_or_box）。
# 行自身的判定结论（valid／automated）由调用方读出后作为来源事实传入，本文件不写该结论。
static func _resolved_card(host, source: Dictionary, expected_version: int) -> Dictionary:
 return _hand_or_box(host,source.payload,bool(source.get("valid",false)),bool(source.get("automated",false)),expected_version)

# 带 hand_uid 的卡牌行的唯一路径（原提交前改道链的 A40 项，R2 收敛时漏在意图链）：行有效、
# 非自动接管步骤、带 hand_uid 且非自身目标、且未在选择中时先选要消耗的手牌并返回 HANDLED；
# 其余按该行原样装箱（无效行由 dispatch 给出判定 reason）。条件只此一份。
# row_valid／row_automated 是行来源的事实，由调用方按来源给出（判定结论的读取，不是第二判定）：
# 显示行读行自身的结论；意图链的 seam 只在行有效时交出 payload（无效行已由 seam 提示），
# 且自动接管步骤只经已解析的显示行走本接口（automated 判定不丢失）。
static func _hand_or_box(host, payload: Dictionary, row_valid: bool, row_automated: bool, expected_version: int) -> Dictionary:
 if row_valid and not row_automated and payload.has("hand_uid") and not bool(payload.get("self_target",false)) and not host.selecting_hand():
  host.open_hand_selection(payload,expected_version)
  return HANDLED
 return _box(host,payload,expected_version)

# 意图链的已解析行（自由面／快捷解除／唯一装备）：seam 与行查询只在行有效时交出 payload
# （无效行已提示），故此处按「有效、非自动接管」的来源事实上转改道。
static func _seam_card(host, payload: Dictionary, expected_version: int) -> Dictionary:
 return _hand_or_box(host,payload,true,false,expected_version)

# 待解析的卡牌意图（原 A22／A24／A41–A45 的改道链并入此处）：与改动前的解析顺序逐条对齐
# （手牌选择 → 自身目标 → 单面提示 → 自由面 → 快捷解除 → 唯一装备）。
static func _card_intent(host, source: Dictionary, expected_version: int) -> Dictionary:
 var uid=String(source.get("uid",""))
 var free=bool(source.get("free",false))
 var clicked=bool(source.get("click",false))
 # 手牌选择中（原 A22）：提交选中的手牌消耗组合
 if host.selecting_hand() and source.has("hand_uid"):
  return _box(host,host.hand_selection_source(String(source.get("hand_uid",""))),expected_version)
 # 自身目标牌（原 A41／A42 改道）：带 hand_uid 时先选要消耗的手牌
 var self_card=Queries.find(host.view,"card",{"uid":uid,"self_target":true,"free":free})
 if not self_card.is_empty():
  if bool(self_card.valid) and String(self_card.payload.get("hand_uid",""))!="":
   host.open_hand_selection(self_card.payload,expected_version)
   return HANDLED
  return _box(host,self_card.payload,expected_version)
 # 单面卡面（点击链）：只有原文提示，没有可提交的形状
 if clicked and host.single_face_notice(uid): return HANDLED
 # 自由面（原 A43／A44 改道）：解析到具体自由部位；该 seam 只在行有效时返回 payload（无效时已提示）
 if host.card_is_free(uid,free):
  var free_card=host.free_card_source(source,expected_version)
  if free_card.is_empty(): return HANDLED
  return _seam_card(host,free_card,expected_version)
 # 快捷解除（原 A45 改道）：按选中的拘束具区域取行；该 seam 同理只在行有效时返回 payload
 if clicked and host.quick_release_open and host.quick_release_region!="":
  var quick=host.quick_release_source(source,expected_version)
  if quick.is_empty(): return HANDLED
  return _seam_card(host,quick,expected_version)
 # 唯一装备面（原 A24）：该牌只有一处可落点时直接落点（带 hand_uid 时先选要消耗的手牌）
 if clicked:
  var single=host.single_restraint_source(uid)
  if not single.is_empty():
   if bool(single.valid): return _seam_card(host,single.payload,expected_version)
   host.selected_slot=String(single.payload.get("slot",""))
 return {}
