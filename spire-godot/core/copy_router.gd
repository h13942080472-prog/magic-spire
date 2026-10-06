extends RefCounted
# 文案路由（docs/ondemand-copy.md「文案路由（收口阶段）」）：生产者提交「类别 + 参数」，路由按 kind 分派到已登记的 builder。
# 全 static；builder 本体留在各自模块（本文件不搬中文），路由只做分派与共享片段。
# 消费者侧不直连本模块：UI 只经 Game 的只读入口（live_card_text／candidate_detail）再由 docs/ondemand-copy.md「显示侧取用 helper」取用。
# 失败三态（必须区分）：① 字符串直传原样返回，行为与迁移前逐字节相同；② descriptor 命中 builder 返回
# 其结果；③ 未知 kind／无效 builder／结果类型不符 → 在游戏实例上记一条 copy_router_failures（含 kind、
# 入口、失败点与涉事 descriptor；不进 state、不进 View、不进存档、不渲染、不做成计数器），并返回
# descriptor 自带的 fallback；没有 fallback 时返回空值并记录，绝不"空白且无记录"。
# 语言限制：GDScript 无异常捕获，builder 内部的引擎错误由套件当作失败处理（不再是静默空值）。
const Cards=preload("res://core/card_effects.gd")
const Catalog=preload("res://data/encyclopedia.gd")
const ManaFlask=preload("res://core/mana_flask.gd")
const DemoExit=preload("res://core/demo_exit.gd")
const RoomServices=preload("res://core/room_services.gd")
const Prison=preload("res://core/prison.gd")
const PrisonSpace=preload("res://core/prison_space.gd")
const Departure=preload("res://core/departure.gd")
const RoomEvents=preload("res://core/room_events.gd")
const RelicBundle=preload("res://core/relic_bundle.gd")
const Consumables=preload("res://core/consumables.gd")
const WitchCharacter=preload("res://core/witch_character.gd")
# game.gd 反向引用本模块（_fact_core 经 CopyRouter.text 路由 copy），循环 preload 只在函数体内使用，引擎允许。
const Game=preload("res://core/game.gd")
const WitchExpansion=preload("res://core/witch_expansion.gd")

static var _table: Dictionary={}

# 类别 → builder(g, args)。卡面实时与静态两条实现、各模块的文案构建函数都在原地保留（docs/ondemand-copy.md「descriptor 与类别」不合并两份实现）。
static func _builders() -> Dictionary:
 if _table.is_empty():
  _table["card.face"]=func(g,args): return Cards.text_entry(g,String(args.get("type","")),String(args.get("uid","")))
  _table["card.catalog"]=func(g,args): return Catalog.card(String(args.get("type","")))
  _table["card.target"]=Callable(Cards,"target_detail")
  _table["card.two_face"]=func(g,args): return two_face(g,String(args.get("type","")))
  _table["card.face_text"]=Callable(Cards,"face_text_detail")
  _table["mana_flask.deposit"]=Callable(ManaFlask,"deposit_detail")
  _table["mana_flask.withdraw"]=Callable(ManaFlask,"withdraw_detail")
  _table["demo_exit.end"]=Callable(DemoExit,"end_detail")
  _table["demo_exit.continue"]=Callable(DemoExit,"continue_detail")
  _table["service.offer"]=Callable(RoomServices,"offer_detail")
  _table["service.release_job"]=Callable(RoomServices,"release_job_detail")
  _table["service.remove_card"]=Callable(RoomServices,"remove_card_detail")
  _table["service.refresh"]=Callable(RoomServices,"refresh_detail")
  _table["prison.enter"]=Callable(Prison,"enter_detail")
  _table["prison.inspection"]=Callable(Prison,"inspection_detail")
  _table["prison.resist"]=Callable(Prison,"resist_detail")
  _table["prison.vent_kick"]=Callable(Prison,"vent_kick_detail")
  _table["prison.vent_exit"]=Callable(Prison,"vent_exit_detail")
  _table["prison.key"]=Callable(Prison,"key_detail")
  _table["prison.door_exit"]=Callable(Prison,"door_exit_detail")
  _table["prison_space.explore_blind"]=Callable(PrisonSpace,"explore_blind_detail")
  _table["prison_space.explore_site"]=Callable(PrisonSpace,"explore_site_detail")
  _table["prison.unlock_door"]=Callable(Prison,"unlock_door_detail")
  _table["departure.description"]=Callable(Departure,"description_detail")
  _table["departure.skip"]=Callable(Departure,"skip_detail")
  _table["departure.finish"]=Callable(Departure,"finish_detail")
  _table["event.choice"]=Callable(RoomEvents,"choice_detail")
  _table["event.reward_skip"]=Callable(RoomEvents,"reward_skip_detail")
  _table["event.prepare"]=Callable(RoomEvents,"prepare_detail")
  _table["relic_bundle.claim"]=Callable(RelicBundle,"claim_detail")
  _table["relic.discharge"]=func(g,args): return g.RelicEffects.definition(g,args.id).detail
  _table["relic.control_toggle"]=func(g,_args): return g.FirstTurnControl.mode(g).detail
  _table["relic.control_done"]=func(_g,_args): return "当前无法结束回合，接管结束后由你处理；不会绕过卡牌的结束回合限制。"
  _table["relic_bundle.skip"]=Callable(RelicBundle,"skip_detail")
  _table["relic_bundle.finish"]=Callable(RelicBundle,"finish_detail")
  _table["service.leave"]=Callable(RoomServices,"leave_detail")
  _table["consumables.description"]=Callable(Consumables,"description_detail")
  _table["witch.attack"]=Callable(WitchCharacter,"attack_detail")
  _table["witch.card_log"]=Callable(WitchExpansion,"card_log_detail")
  _table["game.surrender"]=Callable(Game,"copy_surrender")
  _table["game.item_discard"]=Callable(Game,"copy_item_discard")
  _table["game.status_toggle"]=Callable(Game,"copy_status_toggle")
  _table["game.rest_rare"]=Callable(Game,"copy_rest_rare")
  _table["game.rest_card"]=Callable(Game,"copy_rest_card")
  _table["game.rest_flask"]=Callable(Game,"copy_rest_flask")
  _table["game.rest_begin"]=Callable(Game,"copy_rest_begin")
  _table["game.end_climax"]=Callable(Game,"copy_end_climax")
  _table["game.retain"]=Callable(Game,"copy_retain")
  _table["game.retain_skip"]=Callable(Game,"copy_retain_skip")
  _table["game.reward_item"]=Callable(Game,"copy_reward_item")
  _table["game.reward_item_skip"]=Callable(Game,"copy_reward_item_skip")
  _table["game.reward_flask"]=Callable(Game,"copy_reward_flask")
  _table["game.reward_other"]=Callable(Game,"copy_reward_other")
  _table["game.reward_relic"]=Callable(Game,"copy_reward_relic")
  _table["game.reward_skip_category"]=Callable(Game,"copy_reward_skip_category")
  _table["game.reward_skip"]=Callable(Game,"copy_reward_skip")
  _table["game.travel_step"]=Callable(Game,"copy_travel_step")
  _table["game.finish_pack"]=Callable(Game,"copy_finish_pack")
  _table["game.calm"]=Callable(Game,"copy_calm")
  _table["game.end_turn"]=Callable(Game,"copy_end_turn")
  _table["game.finish_prepare"]=Callable(Game,"copy_finish_prepare")
  _table["game.finish_rest"]=Callable(Game,"copy_finish_rest")
  _table["game.wall_move"]=Callable(Game,"copy_wall_move")
  _table["game.posture"]=Callable(Game,"copy_posture")
  _table["game.posture_wall"]=Callable(Game,"copy_posture_wall")
  _table["game.attack"]=Callable(Game,"copy_attack")
  _table["game.attack_release"]=Callable(Game,"copy_attack_release")
  _table["game.manual_collar"]=Callable(Game,"copy_manual_collar")
  _table["game.manual_release"]=Callable(Game,"copy_manual_release")
  _table["game.manual_retrieve"]=Callable(Game,"copy_manual_retrieve")
  _table["game.hook"]=Callable(Game,"copy_hook")
  _table["game.item_escape"]=Callable(Game,"copy_item_escape")
  _table["game.item_unlock"]=Callable(Game,"copy_item_unlock")
  _table["game.item_door_lock"]=Callable(Game,"copy_item_door_lock")
  _table["game.item_cut"]=Callable(Game,"copy_item_cut")
  _table["game.item_install"]=Callable(Game,"copy_item_install")
  _table["game.item_retrieve"]=Callable(Game,"copy_item_retrieve")
  _table["game.depart"]=Callable(Game,"copy_depart")
 return _table

# 可枚举的类别清单；未迁移的生产者走字符串直传通道，不在此列（docs/ondemand-copy.md「文案路由（收口阶段）」的 categories() 据此核对已收口范围）。
static func categories() -> Array:
 var names=_builders().keys()
 names.sort()
 return names

# 字符串类文案的唯一分派入口。
static func text(g, copy) -> String:
 var built=_render(g,copy,false)
 return built if built is String else ""

# 字典类文案（卡面条目）的唯一分派入口；与 text() 同一三态。
static func entry(g, copy) -> Dictionary:
 var built=_render(g,copy,true)
 return built if built is Dictionary else {}

# 共享片段：两面拼接（docs/ondemand-copy.md「文案路由（收口阶段）」实测的三处同一流程，只此一处实现）。
static func two_face(g, type: String) -> String:
 return Cards.face_text(g,type,false)+"\n"+Cards.face_text(g,type,true)

# 只读取用：该实例的失败记录（不渲染、不进存档、不做成计数器）。
static func failures(g) -> Array:
 return g.copy_router_failures

static func _render(g, copy, dictionary: bool) -> Variant:
 if copy is String: return copy
 var described=copy is Dictionary
 var kind=String(copy.get("kind","")) if described else ""
 var fallback=copy.get("fallback",{} if dictionary else "") if described else ({} if dictionary else "")
 var builder=_builders().get(kind,null)
 if builder is Callable and builder.is_valid():
  var result=builder.call(g,copy.get("args",{}) if described else {})
  var typed=result is Dictionary if dictionary else result is String
  if typed: return result
  _record(g,kind,"text" if not dictionary else "entry","result",copy)
  return fallback
 _record(g,kind,"text" if not dictionary else "entry","kind" if kind!="" else "shape",copy)
 return fallback

static func _record(g, kind: String, entry: String, stage: String, copy) -> void:
 if not (g is Object) or not ("copy_router_failures" in g): return
 g.copy_router_failures.append({"kind":kind,"entry":entry,"stage":stage,"copy":copy})
