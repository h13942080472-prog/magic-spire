extends RefCounted
const FirstTurnControl=preload("res://core/first_turn_control.gd")
var _resource_feedback
var _card_feedback: Array=[]
var _equipment_read: Dictionary={}
# Build-time self check records (§6): one entry per voided read batch, on this instance only.
var _equipment_index_issues: Array=[]
# 文案路由失败记录（docs/ondemand-copy.md §11.2）：未知 kind／无效 builder／结果类型不符时追加一条。
# 只读诊断：不进 state、不进 View、不进存档、不渲染、不做成计数器。
var copy_router_failures: Array=[]

# 指令形状的键面真源（docs/spec/candidate-removal.md §3.3；N3 指令形状＝{kind, params, expected_version}）。
# 显示事实（core/game.gd::display_fact 的输出）与该形状一一对应：同一 (kind, params) 只有一条事实。
# 值＝该 kind 的 params 键与默认值：键面只用稳定 ID（template／type／id／uid／slot／target…），
# 显示与派生字段（label／detail／brief／reason／risk／cost／mana／preview／after／hits／damage…）不进键面。
# 本表是闭集：新增 kind 必须先回填契约 §3.3 再实现；dispatch 的形状与参数合法性复核按本表判定。
const COMMAND_KEYS={
 "card":{"uid":"","type":"","slot":"","target":"","free":false,"mode":"","self_target":false,"x":0,"hand_uid":""},
 "chain":{"action":"","type":"","target":"","slot":"","free":false,"mode":"","selected_uid":""},
 "attack":{"type":"","form":0,"enemy":"","all":false,"target":"","x":0,"part":"","charge_action":false},
 "status_toggle":{"status":"","enabled":false,"uid":""},
 "posture":{"dest":"","wall":false},
 "wall_move":{"direction":""},
 "manual":{"target":""},
 "hook":{"target":""},
 "end":{},
 "calm":{},
 "surrender":{},
 "item_use":{"item":"","target":""},
 "item_install":{"item":"","mount":"","operator":""},
 "item_retrieve":{"item":"","mount":"","operator":""},
 "item_discard":{"item":""},
 "finish_prepare":{},
 "finish_rest":{},
 "finish_pack":{},
 "retain":{"uid":""},
 "retain_skip":{},
 "rest_rare":{},
 "rest_card":{"type":""},
 "rest_flask":{},
 "rest_begin":{},
 "service":{"op":"","index":0,"target":"","uid":"","payment":""},
 "event":{"action":"","choice":"","type":""},
 "prison":{"action":"","site":"","direction":"","steps":0,"uid":"","type":"","target":"","slot":"","mode":"","free":false},
 "depart":{"room":""},
 "travel_step":{},
 "reward":{"category":"","type":"","reward_id":""},
 "reward_skip":{"category":""},
 "relic_bundle":{"op":"","index":0,"uid":"","type":""},
 "departure":{"op":"","option":"","uid":"","type":""},
 "flask":{"op":""},
 "relic_toggle":{"relic":""},
 "relic_discharge":{"relic":""},
 "relic_control_done":{},
 "demo_end":{},
 "demo_continue":{},
}

# 指令装配的唯一投影（M-III 输入域）：把意图来源投影到该 kind 的声明键面并补齐默认值。
# 提交侧与显示侧都只经本函数取得 params，保证「同一形状 → 同一 params」只有一条路径。
func command_params(kind: String, source: Dictionary) -> Dictionary:
 var declared=COMMAND_KEYS.get(kind,{})
 var params={}
 for key in declared: params[key]=source.get(key,declared[key])
 return params

# 显示点的形状键（docs/spec/candidate-removal.md §2.1 T8 的显示点同一性）：kind＋声明 params 的稳定键。
# 提交身份 id 不参与；G2 已断言每个 (kind, params) 恰有一条候选行，故形状键与显示点一一对应。
# 行、显示事实与 UI 按钮注册键共用本函数（唯一实现）。
func shape_key(payload: Dictionary) -> String:
 var kind=String(payload.get("kind",""))
 return kind+"|"+JSON.stringify(command_params(kind,payload))

# 指令装箱（N3 的唯一构造点）：kind＋params＋expected_version。版本默认取提交时的当前版本（§3.3.4）。
func command(source: Dictionary, expected_version: int=-1) -> Dictionary:
 var kind=String(source.get("kind",""))
 return {"kind":kind,"params":command_params(kind,source),"expected_version":state.version if expected_version<0 else expected_version}

# 指令形状与参数合法性复核（T4 前半；不判定资格、不写 valid／reason）：形状或键面不合法即拒绝。
# 失败原因与按 id 取行复核（B2）时代的「该行动已经失效，请重新选择。」逐字相同。
func command_issue(cmd: Dictionary) -> String:
 var kind=String(cmd.get("kind",""))
 if not COMMAND_KEYS.has(kind): return "该行动已经失效，请重新选择。"
 var params=cmd.get("params")
 if not (params is Dictionary): return "该行动已经失效，请重新选择。"
 var declared=COMMAND_KEYS[kind]
 for key in params:
  if not declared.has(key) or typeof(params[key])!=typeof(declared[key]): return "该行动已经失效，请重新选择。"
 return ""

# 指令形状 → 当前状态下该显示点的投影事实（T4 后半：唯一判定经显示事实给出）。形状与 params 相等的
# 事实恰有一条；无命中即失效。按 kind 只调该生产者再 display_fact，不经 command_facts 全表（销 B2／DUP3）。
# 未接线 kind 仍走 _fact_source；禁止对子集跑 FirstTurnControl.select。
func command_fact(cmd: Dictionary) -> Dictionary:
 var kind=String(cmd.get("kind",""))
 var params=command_params(kind,cmd.get("params",{}))
 var previous=_begin_equipment_read()
 var found=_command_fact_row(kind,params)
 _equipment_read=previous
 return found

# select 只吃全表：接管期回全表查找；可行动期按 kind 调该生产者。不对子集再跑 select。
func _command_fact_row(kind: String, params: Dictionary) -> Dictionary:
 if FirstTurnControl.active(self):
  for f in command_facts():
   if String(f.payload.get("kind",""))!=kind: continue
   if command_params(kind,f.payload)==params: return f
  return {}
 var found={}
 for f in _kind_facts(kind,params):
  if String(f.payload.get("kind",""))!=kind: continue
  var row=display_fact(f)
  if command_params(kind,row.payload)==params:
   found=row;break
 return found

# T4 查找的运作层：已接线 kind 只跑 _fact_source／_phase_facts 里该生产者；kind 不在 COMMAND_KEYS → 空。
func _kind_facts(kind: String, params: Dictionary) -> Array:
 match kind:
  "flask": return _flask_kind_facts()
  "attack":
   if String(params.get("target",""))!="": return _fact_source()
   return attack_facts() if _phase_action_tail() else []
  "item_discard": return item_discard_facts() if _fact_source_domain() else []
  "item_use": return _item_use_kind_facts(params)
  "end","calm","finish_prepare","finish_rest","finish_pack": return _flow_kind_facts(kind)
  "posture": return posture_facts() if _phase_action_tail() else []
  "wall_move": return wall_move_facts() if _phase_action_tail() else []
  "status_toggle": return _status_toggle_facts() if _fact_source_domain() else []
  "relic_toggle","relic_discharge": return RelicEffects.facts(self) if _fact_source_domain() else []
  "surrender":
   if not _fact_source_domain(): return []
   var row=surrender_fact()
   return [] if row.is_empty() else [row]
  _: return _fact_source() if COMMAND_KEYS.has(kind) else []

func _fact_source_domain() -> bool:
 return state.relic_bundle.is_empty() and state.phase!="departure" and command_domain_ready()

# _phase_facts 默认行动尾（墙面／姿态／攻击／底栏）：域就绪且 command_tail（早退分支不跑这些生产者）。
func _phase_action_tail() -> bool:
 return _fact_source_domain() and command_tail()

func _flask_kind_facts() -> Array:
 if not state.relic_bundle.is_empty() or state.phase=="departure": return ManaFlask.facts(self,true)
 return ManaFlask.facts(self) if command_domain_ready() else []

func _flow_kind_facts(kind: String) -> Array:
 if not _fact_source_domain(): return []
 if state.overloaded and state.phase in RelicEffects.COMBAT_PHASES: return _phase_facts() if kind=="end" else []
 if state.phase=="pack" or _phase_action_tail(): return flow_facts()
 return []

func _item_use_kind_facts(params: Dictionary) -> Array:
 var item=_item(String(params.get("item","")))
 if item.is_empty(): return []
 var op=Tools.operation(item.type)
 if op not in ["buff","escape"]: return _fact_source()
 if not state.relic_bundle.is_empty() or state.phase=="departure":
  return Consumables.use_facts(self,item) if op=="buff" and Consumables.outside_battle(self,item.type) else []
 if not command_domain_ready(): return []
 if item_action_block(): return item_action_facts(item.id)
 return Consumables.use_facts(self,item) if op=="buff" and Consumables.outside_battle(self,item.type) else []

# A read batch owns its indexes; commands and subsequent views never reuse them.
# Speculative installation replaces state, so it must use live queries instead.
# Entry materializes the piece set and every edge derived from it once; a failed self check
# voids the batch instead of rebuilding it, and every later query in it answers from the
# live path.
func _begin_equipment_read() -> Dictionary:
 var previous=_equipment_read
 if not _equipment_read_active() and (previous.is_empty() or not is_same(previous.get("state",null),state)):
  _equipment_read={"state":state,"slots":{},"stacks":{},"escapes":{},"casts":[]}
  _build_equipment_read_index()
 return previous

func _equipment_read_active() -> bool:
 return not _equipment_read.is_empty() and not _equipment_read.get("invalid",false) and is_same(_equipment_read.state,state)

# Edges follow the verified build direction only: authoritative containers project forward into
# piece order. An inconsistent graph is neither repaired nor partly trusted (§6).
func _build_equipment_read_index() -> void:
 var pieces=_materialize_physical_pieces()
 var issue=_equipment_index_issue(pieces)
 if not issue.is_empty():
  _equipment_read.invalid=true
  _equipment_index_issues.append(issue)
  return
 _equipment_read.pieces=pieces
 _equipment_read.slots=_materialize_slot_edge(pieces)
 _equipment_read.roots=_materialize_root_edge()
 _equipment_read.links=_materialize_link_edge()
 _equipment_read.anchors=_materialize_anchor_list()
 _equipment_read.targets=_materialize_equipment_targets()
 _equipment_read.connections=_materialize_connection_edge()
 _equipment_read.actions=_materialize_action_targets()
 _equipment_read.ids=_materialize_id_edge()
 _equipment_read.capacity_points=_materialize_capacity_points(pieces)
 _equipment_read.physical_points=_materialize_physical_points(pieces)

# Slot to rope with the §1 durability filter. The list edges below keep the §1 concatenation
# order; the connection edge is the projection the action list and targets_at share.
func _materialize_link_edge() -> Dictionary:
 var links={}
 for link in state.links:
  if link.durability<=0: continue
  for slot in link.slots:
   if not links.has(slot): links[slot]=[]
   links[slot].append(link)
 return links

func _materialize_anchor_list() -> Array:
 return _equipment_read.pieces.duplicate()+state.special_equipment.filter(Links.is_crotch_anchor)

func _materialize_equipment_targets() -> Array:
 return _equipment_read.pieces.duplicate()+state.links

# The helper's own scan over state.equipment runs once per scope instead of once per list query.
func _materialize_connection_edge() -> Array:
 return Binding.connections(self)

func _materialize_action_targets() -> Array:
 return _equipment_read.targets.duplicate()+state.special_equipment+_equipment_read.connections.duplicate()

# Root id to root, in root order, so every component lookup reads one projection of
# state.composites instead of rescanning it; components stay reachable as root.components.
func _materialize_root_edge() -> Dictionary:
 var roots={}
 for root in state.composites:
  if not roots.has(root.id): roots[root.id]=root
 return roots

func _composite_roots() -> Array:
 if _equipment_read_active(): return _equipment_read.roots.values()
 return state.composites

# Built from the assembled action target list, so a later batch never re-runs its scans.
func _materialize_id_edge() -> Dictionary:
 var ids={}
 for target in action_targets():
  if not ids.has(target.id): ids[target.id]=target
 return ids

# Both point edges project the whole piece set, so neither carries a durability filter of its own:
# a caller that needs one iterates the durability-filtered slot edge (equipment_at) and uses the
# point edge only as a membership test.
func _materialize_capacity_points(pieces: Array) -> Dictionary:
 return _materialize_point_edge(pieces,Equipment.capacity_points)

func _materialize_physical_points(pieces: Array) -> Dictionary:
 return _materialize_point_edge(pieces,Equipment.physical_points)

func _materialize_point_edge(pieces: Array, points_of: Callable) -> Dictionary:
 var points={}
 for piece in pieces:
  for point in points_of.call(piece):
   if not points.has(point): points[point]=[]
   points[point].append(piece)
 return points

func _capacity_point_count(point: String) -> int:
 if _equipment_read_active(): return _equipment_read.capacity_points.get(point,[]).size()
 return physical_pieces().filter(func(e):return point in Equipment.capacity_points(e)).size()

func _piece_covers_point(point: String, e: Dictionary) -> bool:
 if _equipment_read_active(): return _equipment_read.physical_points.get(point,[]).has(e)
 return point in Equipment.physical_points(e)

func _materialize_physical_pieces() -> Array:
 var pieces=state.equipment.duplicate()
 for root in state.composites: pieces.append_array(root.components)
 for host in state.equipment:
  if host.has("shoulders"): pieces.append_array(host.shoulders.pieces)
 return pieces

func _materialize_slot_edge(pieces: Array) -> Dictionary:
 var slots={"shoulder":[]}
 for slot in SpecialEquipment.slots(): slots[slot]=[]
 for piece in pieces:
  if piece.durability<=0: continue
  for slot in Equipment.coverage(piece):
   if not slots.has(slot): slots[slot]=[]
   slots[slot].append(piece)
 return slots

func _equipment_index_issue(pieces: Array) -> Dictionary:
 var by_id={}
 for piece in pieces:
  var id=piece.get("id","")
  if by_id.has(id): return {"check":3,"edge":"pieces","id":id}
  by_id[id]=piece
 for root in state.composites:
  for component in root.components:
   if component.get("root_id","")!=root.id: return {"check":1,"edge":"components","id":component.get("id","")}
   if not is_same(by_id.get(component.get("id",""),null),component): return {"check":1,"edge":"components","id":component.get("id","")}
 for piece in pieces:
  if not piece.has("shoulder_host"): continue
  if not by_id.has(piece.shoulder_host): return {"check":2,"edge":"shoulders","id":piece.get("id","")}
  var host=by_id[piece.shoulder_host]
  if not host.get("shoulders",{}).get("pieces",[]).any(func(entry):return is_same(entry,piece)): return {"check":2,"edge":"shoulders","id":piece.get("id","")}
 return {}

func _card_motion(kind: String, card: Dictionary={}) -> void:
 if _resource_feedback!=null:
  _card_feedback.append({"kind":kind,"uid":card.get("uid",""),"type":card.get("type","")})

const Content=preload("res://core/content_catalog.gd")
const B = preload("res://data/balance.gd")
const BasicAttacks=preload("res://data/basic_attacks.gd")
const Tower = preload("res://data/tower.gd")
const Tools = preload("res://core/tool_rules.gd")
const Consumables=preload("res://core/consumables.gd")
const ManaFlask=preload("res://core/mana_flask.gd")
const RelicRewards=preload("res://core/relic_rewards.gd")
const RelicBundle=preload("res://core/relic_bundle.gd")
const Departure=preload("res://core/departure.gd")
const ItemRewards=preload("res://core/item_rewards.gd")
const View = preload("res://core/game_view.gd")
const Equipment = preload("res://data/equipment.gd")
const Links = preload("res://data/links.gd")
const Composites = preload("res://data/composites.gd")
const Enemies = preload("res://data/enemies.gd")
const EnemyPlans = preload("res://core/enemy_plans.gd")
const Puppets=preload("res://core/puppet_enemy.gd")
const IronMan=preload("res://core/iron_man.gd")
const DemoExit=preload("res://core/demo_exit.gd")
const SlipMotion=preload("res://core/slip_motion.gd")
const HandAssist=preload("res://core/hand_assist.gd")
const Contact=preload("res://core/contact.gd")
const InstalledTools=preload("res://core/installed_tools.gd")
const Replay=preload("res://core/action_replay.gd")
const Pressure = preload("res://core/pressure.gd")
const SpecialEquipment=preload("res://data/special_equipment.gd")
const Shoulders=preload("res://core/shoulder_links.gd")
const Binding=preload("res://core/torso_binding.gd")
const Guard = preload("res://core/guard.gd")
const CaptureBind=preload("res://core/capture_bind.gd")
const Application=preload("res://core/equipment_application.gd")
const EquipmentOffers=preload("res://core/equipment_offers.gd")
const Services=preload("res://core/room_services.gd")
const Events=preload("res://core/room_events.gd")
const Cards=preload("res://core/card_effects.gd")
const CopyRouter=preload("res://core/copy_router.gd")
const Character=preload("res://core/witch_character.gd")
const RelicEffects=preload("res://core/relic_effects.gd")
const Relics=preload("res://data/relics.gd")
const Prison = preload("res://core/prison.gd")
const Snapshot=preload("res://core/snapshot.gd")
const ActionCopy=preload("res://core/action_copy.gd")
var _copy_context: Dictionary={}
# docs/transition-pipeline.md §2.2：迁移日志（进程内、只读诊断）。元素＝已声明的 Transition kind。
# 不进 state、不进存档、不进 View；只为后续（固定点存档）留出挂点，本片不消费。
var _transition_log: Array[String]=[]
var _transition_written: Dictionary={}
var _energy_pressure_pending=false
var _card_energy_pressure_pending=0.0
var _capture_energy_pending={}
var _magic_failed=false
var state: Dictionary = {}
var _scene_start: Dictionary = {}

func _init(run_seed: int = 20260906, practice: bool=false, practice_kind: String="equipment", initialize: bool=true, chastity_locks_enabled: bool=false, chastity_lock_chance: int=25, cursed_plate_start: bool=false, cursed_plate_masochist_mode: bool=false, character_id: String="original") -> void:
 Character.register(self)
 SpecialEquipment.ensure_catalog()
 Content.ensure(self)
 # Run identity: `initial_seed` is written once here and never rewritten by _restart_tower,
 # which only advances `seed`; docs/spec/seed-identity.md.
 state = {"version":1, "seed":run_seed, "initial_seed":run_seed, "rng":{}, "phase":"battle", "encounter":0,
  "round":0, "tick":0, "weakness_turns":0, "order":"first", "posture":"stand", "energy":B.ENERGY, "mana":B.MANA_MAX,
  "calm_uses":0,"shop_removals":0,"shop_refreshes":0,
  "mana_max":B.MANA_MAX,"flask_mana":0.0,"flask_deposits":0,"combat":{"serial":0,"active":false,"first_turn":false,"turn":0,"energy":0,"mana_spent":0.0,"mana_used":false,"attack_uses":{},"attack_started":{},"successful_spells":[]},"relic_seen":[],"battle_relic_drop":"","boss_relic_options":[],
  "strength":0.0,"dexterity":0.0,"wall":"rough","wall_distance":0, "equipment":[], "next_equipment":1,"links":[],"next_link":1,"composites":[],"next_composite":1,"practice_kind":practice_kind,
  "special_equipment":[],"chastity_locks_enabled":chastity_locks_enabled,"chastity_lock_chance":clampi(chastity_lock_chance,0,100),"cursed_plate_masochist_mode":cursed_plate_masochist_mode and chastity_locks_enabled,"chastity_climax_factor":3,"slip_ejaculation_turns":0,"slip_ejaculation_force_last":false,"pressure":0.0,"pressure_sources":[],"overloaded":false,"overload_energy":0,"overload_count":0,"overload_total":0,
  "ditto_form":"","cursed_plate_released":false,"relic_bundle":{},"relics":["ember"],"relic_used":{},"relic_pending":{},"relic_counters":{},"ribbon_tick":-1,"card_chain":{},"retain_left":0,"retain_draw_after":0,"reward_options":[],"rest_cards":[],"room_event":{},"security":0,"capture":{},"guard_bind":{},"prison":{},"tower_generation":0,"tower_start_pending":false,
  "enemies":[], "deck":[], "draw":[], "hand":[], "play":[], "discard":[], "exhaust":[], "powers":[], "card_buffs":[], "card_buff_uses":{}, "evasion":0, "rare_offset":Cards.Rules.RARE_OFFSET_INITIAL, "next_card":1,"draw_serial":0,
  "turn_strength":0,"charge":0,"charge_all":false,"temporary_mana":0.0,"next_energy":0,"kick_last":-10,"heavy_used":false,"spell_base_bonuses":{},
  "sure_cast":false,"body_buffs":[],"item_drop_chance":Tools.DROP_INITIAL,"battle_item_drop":"",
  "prepare_left":0,"reward_count":0,"reward_claimed":{},"battle_flask_drop":0,"logs":[],"summary":"", "pending_retain":false,
  "room":"entrance","map_region":"tower","last_strong_group":"","completed_rooms":[],"journey":{},"travel_turns":0,"traversed_edges":[],
  "rest_left":0,"hook_uses":0,"items":[],"next_item":1,"practice":practice,"room_encounters":{},"next_enemy":1}
 state.departure={}
 state.demo_cycle=0;state.demo_finished=false
 state.event_seen=[]
 state.rooms=[]
 for domain in B.RNG_SALTS: state.rng[domain]=0
 state.save_revision=Snapshot.REVISION
 state.save_slot="practice" if practice else "tower"
 if character_id==Character.ID:
  Character.initialize(self)
  state.chastity_locks_enabled=false;state.cursed_plate_masochist_mode=false
 if not initialize: return
 _generate_tower()
 if Character.active(self):
  for type in Character.STARTER: state.deck.append(_make_card(type))
 else:
  for i in range(4):
   state.deck.append(_make_card("strain"))
   state.deck.append(_make_card("slip"))
  state.deck.append(_make_card("ease"))
  state.deck.append(_make_card("magic_slip"))
 if practice: _start_practice()
 elif room_data(state.room).kind=="entry":
  _gain_tool("return_seal")
  _apply_transition("setup_init",{"phase":"map"})
  state.energy=0;state.wall="normal";state.wall_distance=1;state.draw=state.deck.duplicate(true)
  Departure.start(self,cursed_plate_start and state.chastity_locks_enabled)
 else: _start_battle()
 _scene_start=export_snapshot()

func _restart_tower(from_exit: bool=false) -> void:
 # Derive a fresh seed within the committed random stream, so restoring the
 # reward screen reproduces the same new run. Live object ids remain monotonic.
 var previous_seed=int(state.seed)
 var retained_summit="" if from_exit else state.room_encounters.get("summit","")
 # Older escape-route saves discarded the tower row, but kept its generation seed.
 if not from_exit and retained_summit=="" and state.map_region=="prison":
  for room in Tower.generate(previous_seed):
   if room.id=="summit": retained_summit=room.encounter;break
 var next_seed=_random_index("prison",2147483647)
 if next_seed==previous_seed: next_seed=(next_seed+1)%2147483647
 _leave_mounted_tools()
 state.seed=next_seed
 state.rare_offset=Cards.Rules.RARE_OFFSET_INITIAL
 for domain in state.rng: state.rng[domain]=0
 state.tower_generation+=1
 state.slip_ejaculation_turns=0
 state.slip_ejaculation_force_last=false
 state.map_region="tower";state.last_strong_group=""
 state.event_seen=[]
 state.pressure_sources=state.pressure_sources.filter(func(s):return s.room=="")
 _generate_tower(retained_summit)
 if not from_exit:
  for room in state.rooms:
   if room.get("pool","")=="ordinary": room.pool="strong"
 var entry=room_data("entrance")
 if entry.kind=="entry": entry.id="tower_bottom"
 else: state.rooms.append({"id":"tower_bottom","name":"塔底入口","kind":"entry","wall":"normal","next":["entrance"],"floor":entry.floor-1,"lane":0.5})
 state.tower_start_pending=not from_exit
 _apply_transition("tower_restart",{"room":"tower_bottom"}); state.wall="normal"; state.wall_distance=1
 state.completed_rooms=[]; state.traversed_edges=[]; state.journey={}
 state.travel_turns=0;state.room_event={};state.prison={};state.capture={}
 state.prepare_left=0;state.rest_left=0;state.rest_cards=[];state.hook_uses=0
 state.reward_options=[];state.battle_item_drop=""
 state.battle_relic_drop="";state.boss_relic_options=[];state.battle_flask_drop=0;state.reward_claimed={}
 state.enemies=[]; _apply_transition("tower_restart",{"phase":"map"}); state.energy=0
 if not from_exit:
  _emit("event","已离开监狱。请选择新塔路第10—11层的任一非休息、非宝箱区域作为起点；保留当前装备、卡组、遗物与资源。新地图的普通战斗全部使用强怪池。",{"new_tower":{"previous_seed":previous_seed,"seed":next_seed}})

func _generate_tower(retained_summit: String="") -> void:
 state.room_encounters={}
 state.rooms=Tower.generate(int(state.seed),retained_summit)
 for room in state.rooms:
  if room.kind!="battle": continue
  if room.get("pool","")=="ordinary":
   room.encounter_choices={"weak":"weak_group","strong":""}
   state.room_encounters[room.id]=room.encounter_choices.weak
   continue
  var pool=Enemies.FirstFloor.choices(room.pool) if room.has("pool") else [room.encounter]
  state.room_encounters[room.id]=pool[_random_index("encounter",pool.size())]

func room_data(id: String) -> Dictionary:
 for room in state.rooms:
  if room.id==id: return room
 return {}

func _make_card(type: String) -> Dictionary:
 var card = {"uid": "card_%d" % state.next_card, "type":type, "retain_until":-1}
 state.next_card += 1
 return card

func reward_offer(pool: Array, source: String="fixed", rng=null, count: int=-1, reward_pool: String="") -> Array:
 # Explicit counts are stock samples; only newly generated reward choices expand.
 if count<0: count=3+int(relic_value("reward_card_options"))
 var available=Character.pool(self,pool)
 if reward_pool!="": available=available.filter(func(type):return Cards.Rules.SPECS[type].get("reward_pool","")==reward_pool)
 return preload("res://core/card_rewards.gd").offer(self,available,source,rng,count)

func can_offer_card(type: String) -> bool:
 return preload("res://core/card_rewards.gd").eligible(self,type)

func _gain_card(type: String, original: Dictionary={}, to_hand: bool=false) -> void:
 type=Character.card_id(self,type)
 if not Character.allowed_card(self,type): return
 var card=original.duplicate(true)
 card.merge(_make_card(type),true)
 state.deck.append(card.duplicate(true))
 if to_hand and state.phase=="reward": card.retain_until=state.tick+1
 if to_hand and _put_card_in_hand(card): return
 state.discard.append(card)
 if to_hand: _emit("event","手牌已满，「%s」加入弃牌堆。" % B.CARD_NAMES[type])

func _put_card_in_hand(card: Dictionary) -> bool:
 if state.hand.size()>=B.HAND_LIMIT: return false
 state.draw_serial+=1;card.draw_serial=state.draw_serial
 card.draw_free=not Cards.has_escape_target(self,card.type)
 state.hand.append(card);_card_motion("draw",card)
 return true

func _gain_temporary_card(type: String) -> Dictionary:
 if not B.CARD_TRAITS.get(type,{}).get("temporary",false): return {}
 var card=_make_card(type)
 state.deck.append(card.duplicate(true))
 state.discard.append(card)
 return card

func _gain_tool(type: String) -> void:
 state.items.append({"id":"item_%d" % state.next_item,"type":type,"uses":Tools.TYPES[type].uses,"mount":"carry"})
 state.next_item+=1

func _start_practice() -> void:
 _apply_transition("practice_init",{"room":"rest"})
 state.draw=state.deck.duplicate(true)
 _shuffle(state.draw)
 var spec=Tower.practice_spec(state.practice_kind)
 for id in spec.get("relics",[]): RelicEffects.gain(self,id)
 for entry in spec.equipment:
  _install_template(entry.template,entry.slot,entry.durability,Equipment.maximum(entry.get("grade",1)),entry.locked,"practice",entry.get("grade",1),-1,entry.get("material_variant",0),entry.get("point",""))
 for entry in spec.get("shoulders",[]):
  Shoulders.install(self,state.equipment[entry.host],entry.template,entry.grade,"practice")
 for entry in spec.get("links",[]):
  _install_link(state.equipment[entry.a].id,state.equipment[entry.b].id,entry.durability,"practice",1,[state.equipment[entry.blocked_end].id])
 for entry in spec.get("composites",[]):
  _install_assembly(entry.get("kind","glove"),entry.variant,"practice",entry.get("grade",2),entry.tier,entry.get("parts",{}),entry.get("straps","straight"),state.equipment[entry.attach].id if entry.has("attach") else "")
 for entry in spec.get("component_links",[]):
  var a=state.composites[entry.a_root].components.filter(func(e):return e.part==entry.a_part)[0]
  var b=state.composites[entry.b_root].components.filter(func(e):return e.part==entry.b_part)[0]
  _install_link(a.id,b.id,entry.durability,"practice",1,[a.id] if entry.get("blocks_a",false) else [],entry.slots)
 for type in spec.items: _gain_tool(type)
 for item in spec.get("special_equipment",[]): _install_special(item.type,item.slot,item.get("tier",0))
 state.pressure=spec.get("pressure",0.0)
 for source in spec.get("pressure_sources",[]):
  var s=source.duplicate(true)
  s.equipment=state.equipment[s.equipment_index].id if s.has("equipment_index") else ""
  s.erase("equipment_index")
  state.pressure_sources.append(s)
 if spec.get("start","")=="shop":
  _apply_transition("practice_init",{"room":state.rooms.filter(func(room):return room.kind=="shop")[0].id})
  Services.start(self)
 elif spec.get("start","") in ["prison_release","prison_release_violation","prison_gate_exit"]:
  Prison.exit_practice(self,spec.start)
 elif spec.get("start","")=="prison":
  Prison.start_practice(self)
 elif spec.get("start","")=="event":
  Events.start(self,spec.event)
 elif spec.has("encounter"):
  _apply_transition("practice_init",{"room":"entrance"})
  state.room_encounters.entrance=spec.encounter
  _start_battle()
 else: _start_rest()
 _gain_energy(int(spec.get("opening_energy",0)))
 # Practice-only setup supplies declared cards through the regular draw path.
 for type in spec.get("opening_cards",[]):
  var resolved="witch_key" if Character.active(self) and type=="unlock" else Character.card_id(self,type)
  if not Character.allowed_card(self,resolved): continue
  var card=_make_card(resolved)
  state.deck.append(card.duplicate(true))
  state.draw.append(card)
  _draw(1)
 _emit("event",spec.name+"："+spec.hint)

func _random_index(domain: String, size: int) -> int:
 if size <= 1:
  return 0
 var rng = RandomNumberGenerator.new()
 var salt = B.RNG_SALTS[domain]
 rng.seed = int(state.seed) + salt + int(state.rng[domain]) * 104729
 state.rng[domain] += 1
 return rng.randi_range(0,size-1)

func _shuffle(cards: Array, draw_cycle: bool=false) -> void:
 for i in range(cards.size()-1,0,-1):
  var j = _random_index("deck",i+1)
  var tmp = cards[i]
  cards[i] = cards[j]
  cards[j] = tmp
 if draw_cycle: RelicEffects.shuffled(self)

func display_round() -> int:
 if state.phase in ["prison","inspection"]: return int(state.prison.get("turn",0))
 if state.phase in ["rest","prepare"]: return int(state.combat.turn)
 return int(state.round)

func _emit(kind: String, message: String, data: Dictionary = {}) -> void:
 if _resource_feedback!=null:
  if data.has("relic_trigger"): _resource_feedback.relic(state,data.relic_trigger.name)
  else: _resource_feedback.capture(state)
 var recorded=data.duplicate(true)
 if not _copy_context.is_empty():
  recorded.action_copy={"cue":_copy_context.cue,"params":{"actor":_copy_context.actor,"result":message}}
  if _copy_context.has("enemy_id"):
   recorded.enemy_action={"enemy_id":_copy_context.enemy_id,"actor":_copy_context.actor,"kind":_copy_context.cue.trim_prefix("enemy."),"sequence":_copy_context.sequence,"slots":_copy_context.get("slots",[]).duplicate()}
   if recorded.enemy_action.kind in ["charge","bind_prepare"] and not can_observe_intents(): recorded.enemy_action.kind="unseen"
 state.logs.append({"kind":kind,"text":message,"round":display_round(),"phase":state.phase,"data":recorded})
 state.summary = recorded.get("passive_slip",{}).get("summary",message)

func _draw(amount: int, filter: Dictionary={}) -> void:
 for i in range(amount):
  if state.hand.size()>=B.HAND_LIMIT:
   _emit("event","手牌已满，停止抽牌。")
   break
  if state.draw.is_empty():
   # StS counts one final empty reshuffle after a partially fulfilled draw.
   # An initially empty pair of piles and a full hand never attempt a shuffle.
   if state.discard.is_empty() and i==0: break
   state.draw = state.discard.duplicate(true)
   state.discard.clear()
   _shuffle(state.draw,true)
   if state.draw.is_empty(): break
   _card_motion("shuffle")
  var index=state.draw.size()-1
  while index>=0 and not Cards.Rules.matches_draw_filter(state.draw[index].type,filter): index-=1
  if index<0: break
  var card=state.draw[index]
  state.draw.remove_at(index)
  _put_card_in_hand(card)

func _discard_end(end_session: bool=false) -> void:
 state.ribbon_tick=-1
 var kept: Array = []
 for card in state.hand:
  if B.CARD_TRAITS.get(card.type,{}).get("ethereal",false):
   card.retain_until=-1
   state.exhaust.append(card)
   _card_motion("exhaust",card)
  elif not end_session and (relic_value("keep_hand")>0 or B.CARD_TRAITS.get(card.type,{}).get("retain",false) or int(card.retain_until) > int(state.tick)):
   kept.append(card)
   _card_motion("retain",card)
  else:
   card.retain_until = -1
   state.discard.append(card)
   _card_motion("discard",card)
 state.hand = kept
 state.pending_retain = false
 state.retain_left=0;state.retain_draw_after=0

func _start_battle() -> void:
 state.battle_flask_drop=0
 state.sure_cast=false
 state.battle_item_drop=""
 state.battle_relic_drop=""
 state.boss_relic_options=[]
 RelicEffects.clear_temporary(self)
 Pressure.clear_penalties(self)
 state.guard_bind={}
 var room=room_data(state.room)
 state.wall=room.wall
 state.wall_distance=_initial_wall_distance(true)
 RelicEffects.begin_combat(self,"battle")
 state.encounter += 1
 _apply_transition("battle_start",{"phase":"battle"})
 state.weakness_turns=0
 state.round = 0
 state.kick_last = -10
 state.heavy_used = false
 state.pending_retain = false
 if room.has("encounter_choices") and not room.has("encounter_selected"):
  var fought=state.completed_rooms.filter(func(id):
   var previous=room_data(id)
   return previous.kind=="battle" and not previous.get("boss",false) and Enemies.ENCOUNTERS.get(state.room_encounters.get(id,""),{}).get("rank","")!="elite").size()
  var early_battle=room.get("pool","")!="strong" and fought<Tower.WEAK_ENCOUNTERS
  room.encounter_selected="weak" if early_battle or Enemies.FirstFloor.choices("strong").is_empty() else "strong"
  if room.encounter_selected=="strong":
   var pool=Enemies.FirstFloor.choices("strong")
   var choices=pool.filter(func(id):return id!=state.last_strong_group)
   if choices.is_empty(): choices=pool
   room.encounter_choices.strong=choices[_random_index("encounter",choices.size())]
   state.last_strong_group=room.encounter_choices.strong
  state.room_encounters[room.id]=room.encounter_choices[room.encounter_selected]
 var encounter=Enemies.ENCOUNTERS[state.room_encounters[room.id]]
 if encounter.has("weak_strength") and not room.has("enemy_members"):
  room.enemy_members=[]
  if encounter.has("family"):
   var variants=Enemies.ENCOUNTERS[encounter.family].variants
   var variant=variants[_random_index("encounter",variants.size())]
   room.enemy_members.append_array(Enemies.ENCOUNTERS[variant].members.duplicate(true))
  room.enemy_members.append_array(encounter.get("fixed_members",[]).duplicate(true))
  room.enemy_members.append_array(Enemies.FirstFloor.roll(self,encounter.weak_strength,encounter.get("max_weak_strength",0),encounter.get("unique_weak_types",false)))
 if encounter.has("variants"):
  state.room_encounters[room.id]=encounter.variants[_random_index("encounter",encounter.variants.size())]
 _spawn_enemies(state.room_encounters[room.id])
 _reset_piles()
 var names: Array[String]=[]
 for e in state.enemies: names.append(e.name)
 _emit("event","进入"+room.name+"。"+"、".join(names)+"出现在前方。")
 if room.get("boss",false): RelicEffects._mana_hook(self,"boss_entry_mana","进入Boss房")
 elif Enemies.ENCOUNTERS[state.room_encounters[room.id]].get("rank","")=="elite": RelicEffects._mana_hook(self,"elite_entry_mana","进入精英房")
 _start_round()

func _reset_piles() -> void:
 state.draw = state.deck.duplicate(true)
 for c in state.draw:
  c.retain_until = -1
 state.hand.clear()
 state.play.clear()
 state.discard.clear()
 state.exhaust.clear()
 state.powers.clear()
 _shuffle(state.draw)

func _spawn_enemies(encounter_id: String) -> void:
 var members=(room_data(state.room).get("enemy_members",[]) if Enemies.ENCOUNTERS[encounter_id].has("weak_strength") else Enemies.ENCOUNTERS[encounter_id].members).duplicate(true)
 var base_members=members.duplicate(true)
 for i in range(1,room_data(state.room).get("encounter_repeats",1)):
  members.append_array(base_members.duplicate(true))
 members.sort_custom(func(a,b):return Enemies.TYPES[a.type].order<Enemies.TYPES[b.type].order)
 state.enemies=[]
 _append_enemies(members)

# Both room entry and defeat-spawned members share identities and initial state.
func _append_enemies(members: Array, inherited_health: bool=false) -> Array:
 var counts={}
 for existing in state.enemies: counts[existing.type]=counts.get(existing.type,0)+1
 var added=[]
 for member in members:
  var type=member.type
  counts[type]=counts.get(type,0)+1
  var spec=Enemies.TYPES[type]
  var character_factor=1.3 if not inherited_health and state.room_encounters.get(state.room,"")=="iron_man_solo" and Character.active(self) else 1.0
  var hp=float(member.get("hp",spec.hp))*(1.0 if inherited_health else DemoExit.health_multiplier(state)*character_factor)
  if not inherited_health: hp+=Prison.health_bonus(self,state)
  var name=member.get("name",spec.name)+("（%d）" % counts[type] if counts[type]>1 or members.filter(func(m):return m.type==type).size()>1 else "")
  state.enemies.append({"id":"enemy_%d" % state.next_enemy,"type":type,"name":name,"grade":member.grade,"hp":hp,"max_hp":hp,"stage":1,"ready_layers":0,"intent":{},"gone":false,"defeated":false,"pressure_gain":member.get("pressure",0.0)})
  if spec.has("visual_pool"):
   state.enemies[-1].visual_variant=spec.visual_pool[_random_index("enemy_visual",spec.visual_pool.size())]
  state.next_enemy+=1
  if spec.has("capture_kind"): state.enemies[-1].guard=Guard.initial()
  if spec.has("carried_composites"): state.enemies[-1].carried_indices=range(spec.carried_composites.size())
  if spec.has("damage_cap"): state.enemies[-1].barrier_damage=0.0
  if spec.has("ritual_gain"):
   state.enemies[-1].ritual=0;state.enemies[-1].application_bonus=0
  if spec.has("quantity_gain"):
   state.enemies[-1].application_bonus=0;state.enemies[-1].last_move="";state.enemies[-1].move_streak=0
  if spec.behavior=="six_bind":
   state.enemies[-1].constriction=0
   state.enemies[-1].next_climax_capture=state.overload_total+spec.climax_capture_threshold
  if spec.behavior=="iron_man": IronMan.initialize(state.enemies[-1])
  added.append(state.enemies[-1])
 IronMan.link_supports(added)
 for enemy in added:
  if Enemies.TYPES[enemy.type].behavior=="puppeteer": Puppets.summon(self,enemy)
 return added

func _damage_enemy(e: Dictionary, amount: float, damage_type: String, label: String, details: Dictionary={}, damage_group: Variant=null) -> void:
 if e.is_empty() or e.gone: return
 if damage_group==null: damage_group={}
 var dealt=amount*Enemies.damage_multiplier(self,e.type,damage_type)*(1.0 if details.has("puppet_transfer") else Character.damage_multiplier(self))
 var health_scale=DemoExit.health_multiplier(state)
 var cap=Enemies.barrier_limit(e,health_scale)
 if is_finite(cap):
  var remaining=Enemies.barrier_remaining(e,health_scale)
  if dealt>remaining:
   Puppets.barrier_trigger(self,e,damage_group)
   _emit("mechanical","%s的护身屏障将本次伤害从%s限制为%s；每回合合计最多%s点。" % [e.name,number(dealt),number(remaining),number(cap)],{"enemy":e.id,"damage_barrier":{"before":dealt,"after":remaining,"limit":cap}})
   dealt=remaining
  e.barrier_damage+=dealt
 if Puppets.damage(self,e,dealt,damage_type,label,details,damage_group): return
 e.hp=maxf(0.0,e.hp-dealt)
 var record={"damage":dealt,"damage_type":damage_type,"enemy":e.id}
 record.merge(details)
 _emit("mechanical","%s对%s造成%s点%s伤害，剩余生命%s。" % [label,e.name,number(dealt),"魔法" if damage_type=="magic" else "",number(e.hp)],record)
 if e.hp<=0: _defeat_enemy(e)
 elif Enemies.TYPES[e.type].has("split_threshold") and e.hp<=e.max_hp*Enemies.TYPES[e.type].split_threshold: _split_enemy(e,e.hp)

func _defeat_enemy(e: Dictionary) -> void:
 if e.gone: return
 e.gone=true;e.defeated=true;e.intent={};e.erase("turn_install_layers")
 _emit("event",e.name+"被击倒。")
 Puppets.dismiss(self,e)
 IronMan.defeat_supports(self,e)
 CaptureBind.observe(self)
 var members=Enemies.TYPES[e.type].get("defeat_spawns",[])
 if members.is_empty(): return
 _spawn_children(e,members)

func _split_enemy(e: Dictionary, basis: float) -> void:
 if e.gone: return
 e.split_basis=basis
 e.gone=true;e.defeated=true;e.hp=0;e.intent={};e.erase("turn_install_layers")
 var members=Enemies.TYPES[e.type].split_spawns.duplicate(true)
 for member in members: member.hp=basis if member.hp_ratio==1.0 else ceilf(basis*member.hp_ratio)
 _spawn_children(e,members)

func _spawn_children(e: Dictionary, members: Array) -> void:
 var children=_append_enemies(members,e.has("split_basis"))
 for child in children:
  child.spawned_from=e.id;child.spawned_round=state.round
  child.acted_round=state.round # No action in the remainder of the birth round, regardless of order.
  child.intent=_plan(child)
 var previous=_copy_context
 _copy_context={"cue":"enemy.split","actor":e.name,"enemy_id":e.id,"sequence":state.logs.size()}
 _emit("event",e.name+"散开，分裂成"+"、".join(children.map(func(child):return child.name))+"。它们从下一回合开始行动。",{"spawned":children.map(func(child):return child.id)})
 _copy_context=previous

func _start_round() -> void:
 if _finish_if_saturated(): return
 state.round += 1
 for enemy in state.enemies:
  if Enemies.TYPES[enemy.type].has("damage_cap"): enemy.barrier_damage=0.0
 state.order = "last" if state.posture == "lie" or relic_value("battle_force_last")>0 else "first"
 if state.slip_ejaculation_force_last:
  state.order="last"
  state.slip_ejaculation_force_last=false
 state.heavy_used = false
 _begin_player_turn()
 if _finish_if_saturated(): return
 CaptureBind.observe(self)
 for e in state.enemies:
  if not e.gone and e.intent.is_empty():
   e.intent = _plan(e)
 _emit("event","第%d回合：%s，%s。" % [state.round,"你先行动" if state.order == "first" else "敌人先行动","意图已公开" if can_observe_intents() else "视线受阻，无法观察敌人意图"])
 if state.order == "last":
  _enemy_phase()

func preparation_turns() -> int:
 return B.PREPARATION_TURNS+int(relic_value("preparation_turns"))

func _start_preparation() -> void:
 _apply_transition("prepare_start",{"phase":"prepare"})
 if not state.combat.active: RelicEffects.begin_combat(self)
 # A fresh player turn, using the same session and live card piles.
 _discard_end()
 state.combat.energy=state.energy if relic_value("retain_energy")>0 else 0
 state.prepare_left = preparation_turns()
 _prepare_round()

func _begin_player_turn() -> void:
 state.ribbon_tick=-1
 state.calm_uses=0
 # Shared resource/draw boundary; each phase owns its timer and side effects.
 state.tick += 1
 # Capture pending draws before this turn can queue another climax reward.
 var relic_draw=RelicEffects.turn_draw(self)
 ManaFlask.reset_turn(self)
 state.overloaded=false
 state.overload_count=0
 var slip_penalty=1 if state.slip_ejaculation_turns>0 else 0
 state.energy = state.combat.energy+maxi(0,max_energy() + state.next_energy-state.overload_energy-slip_penalty)
 if state.slip_ejaculation_turns>0:
  var mana_before=state.mana
  var lost=minf(mana_before,B.SLIP_EJACULATION_MANA)
  state.mana-=lost
  state.slip_ejaculation_turns-=1
  _emit("event","滑精：损失%s魔力，剩余%d回合。" % [number(lost),state.slip_ejaculation_turns],{"slip_ejaculation_tick":true,"mana_before":mana_before,"mana_lost":lost,"mana_after":state.mana,"remaining":state.slip_ejaculation_turns})
 state.combat.energy=0
 state.overload_energy=0
 state.next_energy = 0
 RelicEffects.begin_turn(self)
 var innate=Cards.Hannya.prepare_innate(self)
 Cards.begin_turn(self)
 # Apply source-bound turn effects before drawing, so card faces see the new equipment.
 EnemyPlans.tick_install(self,"turn_start")
 CaptureBind.turn_start(self)
 RelicEffects.flush(self)
 _draw(maxi(innate,B.DRAW+RelicEffects.opening_draw(self)+relic_draw))
 Pressure.tick(self,"turn_start")
 _tick_special("turn_start")
 RelicEffects.flush(self)
 FirstTurnControl.begin_turn(self)

func _prepare_round() -> void:
 state.heavy_used = false
 _begin_player_turn()
 _emit("event","整备还有%d回合。" % state.prepare_left)

func _start_rest() -> void:
 _apply_transition("rest_start",{"phase":"rest_choice"})
 state.wall=room_data(state.room).wall
 state.wall_distance=0
 state.enemies=[]
 state.rest_left=B.REST_TURNS
 state.hook_uses=B.REST_HOOK_USES
 state.rest_cards=reward_offer(Cards.Rules.REWARDS.filter(func(id):return Cards.Rules.SPECS[id].rarity=="uncommon"))
 if state.practice: _begin_rest()

func _begin_rest() -> void:
 _apply_transition("rest_start",{"phase":"rest"})
 RelicEffects.begin_combat(self)
 _rest_round()

func _rest_round() -> void:
 state.pending_retain=false
 _begin_player_turn()
 _emit("event","休息还有%d回合；悬挂挂钩剩余%d次。" % [state.rest_left,state.hook_uses])

# docs/transition-pipeline.md §3：迁移声明表。每个 kind 声明它允许进入的阶段（空＝不写阶段）、
# 是否允许改当前房间（写值由调用点的 args.room 提供）、是否在已提交事务内（tx 列本片只登记事实，
# 供存档切片消费）、是否是一个进度固定点（checkpoint 列，缺省＝不是；见 docs/save-fixed-points.md §2），
# 以及谁负责触发它。
const TRANSITIONS={
 "setup_init":{"phases":["map"],"room":false,"tx":false,"owners":["_init"]},
 "tower_restart":{"phases":["map"],"room":true,"tx":true,"owners":["_restart_tower"]},
 "practice_init":{"phases":[],"room":true,"tx":false,"owners":["_start_practice"]},
 "prison_cell_init":{"phases":[],"room":true,"tx":false,"owners":["Prison.start_practice"]},
 "prison_gate_init":{"phases":[],"room":true,"tx":false,"owners":["Prison.exit_practice"]},
 "battle_start":{"phases":["battle"],"room":false,"tx":true,"owners":["_start_battle"]},
 "battle_end_victory":{"phases":["reward","event"],"room":false,"tx":true,"checkpoint":"battle_end","owners":["_finish_battle"]},
 "battle_end_saturated":{"phases":["reward","event"],"room":false,"tx":true,"checkpoint":"battle_end","owners":["_finish_battle"]},
 "battle_end_captured":{"phases":["captured"],"room":true,"tx":true,"checkpoint":"battle_end","owners":["Guard.capture"]},
 "prepare_start":{"phases":["prepare"],"room":false,"tx":true,"owners":["_start_preparation"]},
 "prepare_end":{"phases":["pack","map","cleared"],"room":false,"tx":true,"checkpoint":"prepare_end","owners":["_finish_preparation"]},
 "rest_start":{"phases":["rest_choice","rest"],"room":false,"tx":true,"owners":["_start_rest","_begin_rest"]},
 "room_enter":{"phases":["map","cleared"],"room":true,"tx":true,"owners":["_arrive_room"]},
 "floor_enter":{"phases":[],"room":true,"tx":true,"checkpoint":"floor","owners":["_depart","_advance_travel"]},
 "travel_start":{"phases":["travel"],"room":false,"tx":true,"owners":["_depart"]},
 "prison_cell_enter":{"phases":["prison"],"room":false,"tx":true,"owners":["Prison.begin_turn"]},
 "inspection_start":{"phases":["inspection"],"room":false,"tx":true,"owners":["Prison.end_turn"]},
 "prison_exit_battle_start":{"phases":["battle"],"room":false,"tx":true,"owners":["Prison.execute"]},
 "prison_escape":{"phases":["map"],"room":true,"tx":true,"owners":["Prison.escape"]},
 "event_enter":{"phases":["event"],"room":false,"tx":true,"owners":["Events.start"]},
 "event_leave_empty":{"phases":["map"],"room":false,"tx":false,"owners":["Events.start"]},
 "event_item_rewards":{"phases":["reward"],"room":false,"tx":true,"owners":["Events.begin_item_rewards"]},
 "shop_enter":{"phases":["shop","treasure"],"room":false,"tx":true,"owners":["Services.start"]},
 "departure_start":{"phases":["departure"],"room":false,"tx":false,"owners":["Departure.start"]},
 "departure_end":{"phases":["map"],"room":false,"tx":true,"owners":["Departure.execute"]},
 "demo_end":{"phases":[],"room":false,"tx":true,"owners":["_execute"]},
}

# 全仓唯一写 state.phase／state.room 的地方（docs/transition-pipeline.md §2.2）。
# 立即写入、单一写入者、不做事务末统一执行：位置与顺序由各调用点保持原样。
# 返回 ""＝成功，否则 issue（与既有失败字符串风格一致）。
func _apply_transition(kind: String, args: Dictionary = {}) -> String:
 var spec=TRANSITIONS.get(kind,{})
 if spec.is_empty():
  push_error("未声明的状态迁移："+kind)
  return "未声明的状态迁移："+kind
 var wrote=[]
 var phases=spec.get("phases",[])
 # 阶段只在调用点显式给出时写入，且必须落在声明表允许的集合内；只带 room 的续写调用不写阶段。
 if args.has("phase"):
  var target=String(args.phase)
  if not phases.has(target):
   push_error("迁移"+kind+"不接受阶段："+target)
   return "迁移"+kind+"不接受阶段："+target
  state.phase=target
  wrote.append("phase")
 if bool(spec.get("room",false)) and args.has("room"):
  state.room=String(args.room)
  wrote.append("room")
 # 迁移日志：一次迁移记一条。同一 kind 的 phase／room 由调用点分两次写入（写入位置不变），
 # 第二条若只写未写过的字段则不再记；重复写同一字段仍是新的一次迁移（例如牢房每回合）。
 var continuation=_transition_written.get("kind","")==kind and not wrote.is_empty() and wrote.all(func(field):return field not in _transition_written.get("fields",[]))
 if not continuation: _transition_log.append(kind)
 _transition_written={"kind":kind,"fields":wrote}
 return ""

# 进入某房间时使用的 kind（docs/transition-pipeline.md §3）：目标层高于当前层＝floor_enter，
# 否则＝room_enter。只用于真实移动与换塔的落点；构造期写入由各自的构造 kind 承担。
func _room_transition_kind(target: String) -> String:
 return "floor_enter" if int(room_data(target).get("floor",0))>int(room_data(state.room).get("floor",0)) else "room_enter"

# docs/save-fixed-points.md §2／§5.1：进度固定点只由本次提交实际产生的迁移条目命名——不看上下文差异。
# 同一次提交同时命中多类时按 battle_end ＞ prepare_end ＞ floor 取一个；没有命中返回 ""（UI 只在非空时写盘）。
const CHECKPOINT_PRIORITY=["battle_end","prepare_end","floor"]

func _checkpoint_kind(log_start: int) -> String:
 for point in CHECKPOINT_PRIORITY:
  for index in range(maxi(log_start,0),_transition_log.size()):
   if String(TRANSITIONS.get(_transition_log[index],{}).get("checkpoint",""))==point: return point
 return ""

func _finish_battle(end_kind: String="victory") -> void:
 if state.phase != "battle":
  return
 var saturated=end_kind=="saturated"
 # 事件战与普通战共用同一个已声明 kind，只是目标阶段不同（§3 表：事件战＝event）。
 var end_transition="battle_end_saturated" if saturated else "battle_end_victory"
 var event_battle=Events.active_battle(self)
 CaptureBind.clear_bind(self)
 Pressure.cleanup(self)
 if event_battle:
  _apply_transition(end_transition,{"phase":"event"})
  state.reward_count+=1
  var event_issue=Events.finish_battle(self,saturated)
  if event_issue!="": state.room_event.battle_issue=event_issue
  return
 ItemRewards.roll(self)
 RelicEffects.boss_key(self,saturated)
 RelicRewards.battle_drop(self)
 _apply_transition(end_transition,{"phase":"reward"})
 state.reward_claimed={}
 state.battle_flask_drop=B.BOSS_FLASK_MANA if not saturated and _all_gone() and room_data(state.room).get("boss",false) and not Prison.is_exit_battle(self) and state.enemies.any(func(enemy):return enemy.get("defeated",false)) else 0
 var reward_source="boss" if room_data(state.room).get("boss",false) else ("elite" if Enemies.ENCOUNTERS.get(state.room_encounters.get(state.room,""),{}).get("rank","")=="elite" else "normal")
 state.reward_options=reward_offer(Cards.Rules.RARE,"fixed",null,3) if Prison.is_exit_battle(self) else reward_offer(Cards.Rules.REWARDS,reward_source)
 if Prison.is_exit_battle(self): state.battle_flask_drop=B.PRISON_EXIT_FLASK_MANA
 Prison.won(self)
 state.reward_count += 1
 var ending="监狱出口的警卫已全部被击败。收取战利品后，选择新塔路第10—11层的非休息、非宝箱区域开始。" if Prison.is_exit_battle(self) else (("敌人已无法继续添加或加固装备，遭遇结束。" if saturated else ("塔顶首领已被击败，整备后可以前往出口。" if room_data(state.room).get("boss",false) else "遭遇结束。"))+"收取战利品后，点击继续进行整备。")
 _emit("event",ending,{"battle_end":"saturated" if saturated else "cleared"})

# docs/transition-pipeline.md §2.2: the single battle-end judgement every call site shares
# (the 13 reference points keep their own position in the control flow and only ask this).
# "" = the battle continues, "victory" = every enemy is gone, "captured" = a living enemy
# announces arrest through its next normal intent, "saturated" = no living enemy can add or
# reinforce equipment any more.
func _battle_end_reason() -> String:
 if state.phase!="battle": return ""
 if _all_gone(): return "victory"
 if room_data(state.room).get("requires_defeat",false) or Events.battle_requires_defeat(self): return ""
 # Human/mechanical enemies announce arrest through the next normal intent;
 # exhausting equipment options is never a victory against these sources.
 if state.enemies.any(func(enemy):return EnemyPlans.can_arrest(self,enemy)): return "captured"
 # Even a blocked departure attachment gets its normal action before leaving.
 if state.enemies.any(func(enemy):return EnemyPlans.lock_departure_pending(self,enemy)): return ""
 if EnemyPlans.has_equipment_space(self): return ""
 return "saturated"

# Existing settlement boundary: resolve long-battle departures/preparations, then ask
# the single battle-end judgement. Callers and their ordering remain unchanged.
func _finish_if_saturated() -> bool:
 if state.phase!="battle" or not state.card_chain.is_empty(): return false
 if EnemyPlans.long_battle_limit(self):
  for enemy in state.enemies:
   if enemy.gone: continue
   if not Enemies.TYPES[enemy.type].get("humanoid",false):
    enemy.gone=true;enemy.intent={};enemy.erase("turn_install_layers")
    _emit("event",enemy.name+"离开战场。",{"long_battle_departure":enemy.id})
   elif CaptureBind.kind(self,enemy)=="" and enemy.intent.get("kind","")!="capture":
    # Switching to arrest must not undo an interruption already paid for this turn.
    var delayed=enemy.intent.get("delayed",false)
    enemy.intent=_plan(enemy)
    enemy.intent.delayed=delayed
  CaptureBind.observe(self)
 var end_kind=_battle_end_reason()
 if end_kind=="victory":
  _finish_battle("victory")
  return true
 if end_kind!="saturated": return false
 for enemy in state.enemies:
  if enemy.gone: continue
  enemy.gone=true
  enemy.intent={}
  enemy.erase("turn_install_layers")
 _finish_battle("saturated")
 return true

func _all_gone() -> bool:
 for e in state.enemies:
  if not e.gone:
   return false
 return true

func _enemy(id: String) -> Dictionary:
 for e in state.enemies:
  if e.id == id:
   return e
 return {}

func _equipment(id: String) -> Dictionary:
 if _equipment_read_active(): return _equipment_read.ids.get(id,{})
 for e in action_targets():
  if e.id == id:
   return e
 return {}

func _card(uid: String) -> Dictionary:
 for c in state.hand:
  if c.uid == uid:
   return c
 return {}

func _equipment_name(target: Dictionary) -> String:
 if target.has("parent_id"): return target.name+"（"+Equipment.position_text(target)+"）"
 if SpecialEquipment.is_special(target):
  var items=_stack_items(target)
  return ("第%d件" % (items.find(target)+1) if items.size()>1 else "")+target.name+"（"+SpecialEquipment.location_name(target)+"）"
 if target.template=="link_rope" or target.has("root_id"): return target.name
 var items=equipment_at(target.slot)
 return "第%d条%s" % [items.find(target)+1,target.name] if items.size()>1 else target.name

func equipment_at(slot: String) -> Array:
 if _equipment_read_active():
  if _equipment_read.slots.has(slot): return _equipment_read.slots[slot].duplicate()
  return []
 return physical_pieces().filter(func(e): return slot in Equipment.coverage(e) and e.durability>0)

# One physical list powers targeting, contact, enemies and validation; roots carry no extra durability.
func physical_pieces() -> Array:
 if _equipment_read_active() and _equipment_read.has("pieces"): return _equipment_read.pieces.duplicate()
 var pieces=state.equipment.duplicate()
 for root in state.composites: pieces.append_array(root.components)
 pieces.append_array(Shoulders.pieces(self))
 return pieces

# Link eligibility is separate from ordinary coverage/capacity and special removal routes.
func link_anchors() -> Array:
 if _equipment_read_active(): return _equipment_read.anchors.duplicate()
 return physical_pieces()+state.special_equipment.filter(Links.is_crotch_anchor)

func equipment_targets() -> Array:
 if _equipment_read_active(): return _equipment_read.targets.duplicate()
 return physical_pieces()+state.links

# Player removal queries include the independent family, enemy application does not.
func action_targets() -> Array:
 if _equipment_read_active(): return _equipment_read.actions.duplicate()
 return equipment_targets()+state.special_equipment+Binding.connections(self)

func targets_at(slot: String) -> Array:
 var targets=[]
 _visit_targets_at(slot,targets,false)
 return targets

func has_targets_at(slot: String) -> bool:
 return _visit_targets_at(slot,[],true)

# Filters live only here. stop_on_first returns on the first hit and does not collect later sources.
func _visit_targets_at(slot: String, found: Array, stop_on_first: bool) -> bool:
 if slot=="shoulder":
  for e in physical_pieces():
   if Equipment.is_shoulder(e) and e.durability>0:
    if stop_on_first: return true
    found.append(e)
  return false
 if slot in SpecialEquipment.slots():
  for e in state.special_equipment:
   if SpecialEquipment.occupies(e,slot):
    if stop_on_first: return true
    found.append(e)
  for e in links_at(slot):
   if stop_on_first: return true
   found.append(e)
  return false
 for e in equipment_at(slot):
  if stop_on_first: return true
  found.append(e)
 for root in _composite_roots():
  if slot in Composites.definition(root).coverage and Composites.active(root):
   for e in root.components:
    if Equipment.is_shoulder(e) or found.has(e): continue
    if stop_on_first: return true
    found.append(e)
 for e in links_at(slot):
  if stop_on_first: return true
  found.append(e)
 var connections=_equipment_read.connections.duplicate() if _equipment_read_active() else Binding.connections(self)
 for e in connections:
  if e.slot==slot:
   if stop_on_first: return true
   found.append(e)
 return false

func _composite(id: String) -> Dictionary:
 if _equipment_read_active(): return _equipment_read.roots.get(id,{})
 for root in state.composites:
  if root.id==id: return root
 return {}

func _composite_body(root: Dictionary) -> Dictionary:
 for part in root.components:
  if part.part=="body": return part
 return {}

func _sealed_reason(slot: String) -> String:
 for root in state.composites:
  if Composites.active(root) and slot in Composites.definition(root).closed: return root.name+"封住了"+B.SLOT_NAMES[slot]+"，不能在该处追加装备或链接。"
 return ""

func _assembly_reason(layout: Dictionary, attached_to: String="") -> String:
 if layout.kind=="head":
  return "马具已经并入口球，不再单独安装。"
 for old in state.composites:
  if not Composites.active(old): continue
  if layout.kind in ["glove","jacket"] and old.kind in ["glove","jacket"]: return "单手套与拘束衣不能重复或互相覆盖。"
  if layout.kind=="head" and old.kind=="head": return "口部装备已经附有头部马具。"
  if layout.kind=="leg" and old.kind=="leg":
   if layout.variant==old.variant or old.variant in ["ankle","toes"]: return "已有同段单腿套，或外层长套不允许再补入短套。"
  if layout.kind=="wrap" and old.kind=="wrap" and layout.variant==old.variant: return "这一侧的手已经包裹。"
 for slot in layout.coverage:
  if layout.kind!="head" and _sealed_reason(slot)!="": return _sealed_reason(slot)
 if layout.kind=="wrap":
  for e in physical_pieces():
   if e.get("side","") not in ["",layout.variant]: continue
   if Equipment.coverage(e).any(func(slot):return slot in ["palm","fingers"]): return "包裹前该侧手掌与手指必须没有装备。"
 return ""

func _capacity_issue(pieces: Array) -> String:
 # The input is not guaranteed to be the authoritative piece set (validation and the replacement
 # tail pass their own arrays), so it always counts live; array values cannot declare authority,
 # so the batch capacity edge is never used here.
 var counts={}
 for e in pieces:
  for point in Equipment.capacity_points(e): counts[point]=counts.get(point,0)+1
 for slot in B.SLOTS:
  for point in Equipment.points(slot):
   if counts.get(point,0)>_capacity(slot): return B.SLOT_NAMES[slot]+"的固定位置已满，无法容纳这些装备。"
 if OS.is_debug_build():
  var mouth=pieces.filter(func(e):return "mouth" in Equipment.capacity_points(e))
  var inner=mouth.filter(func(e):return Equipment.capacity("mouth",e.template)<Equipment.capacity("mouth"))
  if inner.size()>1: return "嘴部不能叠加多件非胶带拘束具。"
  if not inner.is_empty() and mouth.any(func(e):return e.id!=inner[0].id and e.layer<=inner[0].layer): return "嘴部胶带必须位于其他材料拘束具的外层。"
 return ""

func capacity_used(slot: String) -> int:
 var amount=0
 for point in Equipment.points(slot):
  amount=maxi(amount,_capacity_point_count(point))
 return amount

# §3.1 item 10: the planning half reads through one scope; the write side stays in
# _install_assembly, which runs after the scope is released.
func _prepare_assembly(kind: String, variant: String, source: String, grade: int=2, tightness: int=2, overrides: Dictionary={}, straps: String="straight", attached_to: String="") -> Dictionary:
 var previous=_begin_equipment_read()
 var root=_plan_assembly(kind,variant,source,grade,tightness,overrides,straps,attached_to)
 _equipment_read=previous
 return root

func _plan_assembly(kind: String, variant: String, source: String, grade: int=2, tightness: int=2, overrides: Dictionary={}, straps: String="straight", attached_to: String="") -> Dictionary:
 var layout=Composites.spec(kind,variant,straps)
 if layout.is_empty() or not Equipment.GRADES.has(grade) or grade<layout.minimum or tightness not in [1,2,3]: return {}
 if _assembly_reason(layout,attached_to)!="": return {}
 for key in overrides:
  if key not in layout.parts: return {}
 var layer=0
 for slot in layout.coverage:
  for e in equipment_at(slot): layer=maxi(layer,e.layer+1)
 var root={"id":"composite_%d" % state.next_composite,"name":layout.name,"kind":kind,"variant":variant,"straps":straps,"layer":layer,"components":[],"attached_to":attached_to}
 for key in layout.parts:
  var definition=layout.parts[key]
  var settings=overrides.get(key,{})
  var part_tier=settings.get("tier",tightness)
  if part_tier not in [1,2,3]: return {}
  if definition.template=="glove_strap" and not settings.has("tier"): part_tier=grade
  var piece=_make_assembly_piece(root,definition,key,grade,part_tier,settings,source)
  root.components.append(piece)
 if Composites.validate(root)!="": return {}
 if _capacity_issue(physical_pieces()+root.components)!="": return {}
 return root

func _special_install_reason(type: String, slot: String) -> String:
 SpecialEquipment.ensure_catalog()
 if not SpecialEquipment.DESIGNS.has(type) or not SpecialEquipment.TYPES.has(type): return "这件装备尚未定义。"
 var design=SpecialEquipment.DESIGNS[type]
 if design.slots.any(func(point):return not Character.has_slot(self,point)): return "该角色没有此装备所需的身体部位。"
 if design.slots.is_empty() or slot!=design.slots[0]: return "该装备不能安装在这个位置。"
 if SpecialEquipment.TYPES[type].get("component_only",false): return "固定带只能随对应主体自动附加。"
 if SpecialEquipment.is_chastity_type(type):
  var old_locks=state.special_equipment.filter(SpecialEquipment.is_chastity)
  if old_locks.size()>1: return "当前平板锁状态不完整。"
  if old_locks.size()==1 and not SpecialEquipment.can_upgrade(old_locks[0].type,type): return "只能换成等级更高或功能更多的平板锁。"
  var retained=state.special_equipment.filter(func(e):return not _chastity_displaces(type,e))
  for covered in design.slots:
   if SpecialEquipment.used_capacity(retained,covered)+int(design.capacity_cost)>SpecialEquipment.capacity(covered): return "所需位置已满。"
  return ""
 var blocking_lock=state.special_equipment.filter(func(e):return SpecialEquipment.is_chastity(e) and SpecialEquipment.occupied_slots(e).any(func(covered):return covered in design.slots))
 if not blocking_lock.is_empty(): return blocking_lock[0].name+"封住了所需位置，其他性玩具不能替换它。"
 if state.special_equipment.any(func(e):return SpecialEquipment.exclusive_family(e.type)==SpecialEquipment.exclusive_family(type)): return "杯类特殊装备只能佩戴一件。" if SpecialEquipment.exclusive_family(type)=="cup" else "已佩戴同类装备。"
 for covered in design.slots:
  if SpecialEquipment.used_capacity(state.special_equipment,covered)+int(design.capacity_cost)>SpecialEquipment.capacity(covered): return "所需位置已满。"
 return ""

func _install_special(type: String, slot: String, tightness: int=0) -> Dictionary:
 if tightness not in [0,1,2,3]: return {}
 if _special_install_reason(type,slot)!="": return {}
 var design=SpecialEquipment.DESIGNS[type]
 if SpecialEquipment.is_chastity_type(type):
  # Resolve ownership before removing roots, so component removal is order-independent.
  var displaced=state.special_equipment.filter(func(old):return _chastity_displaces(type,old))
  for old in displaced:
   state.special_equipment.erase(old)
   _emit("event",old.name+"被新的平板锁替换并取下。")
 var item={"id":"special_%d" % state.next_equipment,"template":"special","type":type,"slot":design.slots[0],"coverage":design.slots.duplicate(),"contact_slots":design.slots.duplicate(),"remaining":SpecialEquipment.TYPES[type].duration,"name":SpecialEquipment.TYPES[type].name,"grade":design.grade,"maximum":design.maximum,"durability":design.maximum*design.ratio,"locked":SpecialEquipment.is_chastity_type(type),"layer":0,"material":design.material,"variant":0,"owner_id":""}
 if tightness>0: item.durability=design.maximum*[0.0,0.4,0.8,1.0][tightness]
 if SpecialEquipment.supports_reinforcement(item): item.reinforcement_state="none"
 state.next_equipment+=1
 state.special_equipment.append(item)
 if SpecialEquipment.supports_reinforcement(item) and tier(item.durability,item.maximum)==3: _attach_special_reinforcement(item)
 RelicEffects._mana_hook(self,"restraint_mana","佩戴"+item.name)
 Cards.restraint_changed(self,"worn")
 return item

func _chastity_displaces(incoming_type: String, item: Dictionary) -> bool:
 if SpecialEquipment.is_reinforcement(item):
  var owner=_equipment(item.owner_id)
  return not owner.is_empty() and _chastity_displaces(incoming_type,owner)
 if SpecialEquipment.is_chastity(item): return SpecialEquipment.can_upgrade(item.type,incoming_type)
 var incoming=SpecialEquipment.DESIGNS[incoming_type]
 return SpecialEquipment.occupied_slots(item).any(func(covered):return covered in incoming.slots and (covered!="special_2_d" or SpecialEquipment.catheter_type(incoming_type)))

func _attach_special_reinforcement(owner: Dictionary) -> Dictionary:
 var existing=state.special_equipment.filter(func(item):return SpecialEquipment.reinforcement_matches(item,owner))
 if not existing.is_empty(): return existing[0]
 var type=SpecialEquipment.reinforcement_type(owner)
 if type=="": return {}
 var design=SpecialEquipment.DESIGNS[type]
 owner.reinforcement_state="active"
 var strap={"id":"special_%d" % state.next_equipment,"template":"special","type":type,"slot":design.slots[0],"coverage":design.slots.duplicate(),"contact_slots":design.slots.duplicate(),"remaining":0,"name":SpecialEquipment.TYPES[type].name,"grade":design.grade,"maximum":design.maximum,"durability":design.maximum,"locked":false,"layer":0,"material":design.material,"variant":0,"owner_id":owner.id}
 state.next_equipment+=1;state.special_equipment.append(strap)
 _emit("event",owner.name+"达到紧度3档，自动扣上了"+strap.name+"。")
 return strap

func _tick_special(timing: String) -> void:
 for item in state.special_equipment.duplicate():
  if item.durability<=0.000001: continue
  var spec=SpecialEquipment.TYPES[item.type]
  var amount=SpecialEquipment.effective_gain(self,item,timing)
  if amount>0:
   var source_slots=spec.get("turn_stimulates",spec.stimulates) if timing=="turn_start" else spec.stimulates
   Pressure.gain(self,amount,spec.name+"（"+SpecialEquipment.location_name(item)+"）",false,source_slots)
  if timing=="turn_start" and spec.duration>0 and item.remaining>0:
   item.remaining-=1
   if item.remaining==0:
    _emit("event",spec.name+"的电量已经耗尽，自动刺激停止；装备仍留在"+SpecialEquipment.location_name(item)+"。")

func _remote_special(item: Dictionary, source: String, drain: bool) -> void:
 if item.is_empty() or item.durability<=0 or item.remaining<=0 or not state.special_equipment.has(item): return
 var spec=SpecialEquipment.TYPES[item.type]
 var timing="energy" if spec.energy_gain>0 else "turn_start"
 var amount=SpecialEquipment.effective_gain(self,item,timing)
 if amount>0:
  var slots=spec.get("turn_stimulates",spec.stimulates) if timing=="turn_start" else spec.stimulates
  Pressure.gain(self,amount,source+"·"+item.name,false,slots)
 if drain and spec.duration>0:
  item.remaining=maxi(0,item.remaining-1)
  _emit("event",source+"使"+item.name+"额外结算一次，电量－1，剩余%d。" % item.remaining)

func _climax_special_slip(count: int) -> bool:
 var released=false
 for climax in range(count):
  for item in state.special_equipment.duplicate():
   if item.durability<=0.000001 or SpecialEquipment.TYPES[item.type].get("climax_slip_base",0.0)<=0: continue
   var tightness=tier(item.durability,item.maximum)
   var damage=SpecialEquipment.climax_slip_damage(item,tightness)
   var before=item.durability
   _apply_equipment_damage(item,damage,"slip",true,false)
   var actual=before-item.durability
   _emit("mechanical","高潮牵动%s：%s－%d－%d＝%s点固定滑脱伤害；耐久%s→%s。" % [item.name,number(SpecialEquipment.TYPES[item.type].climax_slip_base),tightness,item.grade,number(damage),number(before),number(item.durability)],{"climax_slip":{"target":item.id,"climax":climax+1,"base":SpecialEquipment.TYPES[item.type].climax_slip_base,"tightness":tightness,"grade":item.grade,"damage":actual,"before":before,"after":item.durability}})
   released=released or (before>0 and item.durability<=0.000001)
 return released

func _install_assembly(kind: String, variant: String, source: String, grade: int=2, tightness: int=2, overrides: Dictionary={}, straps: String="straight", attached_to: String="") -> Dictionary:
 var root=_prepare_assembly(kind,variant,source,grade,tightness,overrides,straps,attached_to)
 if root.is_empty(): return {}
 Binding.cancel_for_assembly(self,root.components)
 state.composites.append(root)
 state.next_composite+=1
 RelicEffects._mana_hook(self,"restraint_mana","佩戴"+root.name)
 Cards.restraint_changed(self,"worn")
 return root

func _make_assembly_piece(root: Dictionary, definition: Dictionary, key: String, grade: int, part_tier: int, settings: Dictionary, source: String) -> Dictionary:
 var maximum=Composites.definition(root).get("maximum",Equipment.maximum(grade))
 var piece={"id":root.id+"_"+key,"root_id":root.id,"part":key,"name":root.name+" · "+definition.label,
  "template":definition.template,"slot":definition.contact[0],"coverage":definition.coverage.duplicate(),"contact_slots":definition.contact.duplicate(),"side":definition.side,"independent":definition.independent,
  "layer":root.layer+(1 if definition.independent else 0),"grade":grade,"variant":0,"material":Equipment.TEMPLATES[definition.template].material,"locked":settings.get("locked",false),"maximum":maximum,"durability":maximum*[0.0,0.4,0.8,1.0][part_tier],"source":source}
 if definition.has("points"): piece.points=definition.points.duplicate()
 if Equipment.is_shoulder(piece):
  piece.layer=0;piece.crossed=part_tier==3
 return piece

func _refresh_equipment(target: Dictionary) -> void:
 if target.template=="mouth_band":
  target.name=Equipment.name_for(target.template,target.slot,target.grade,target.variant)
  target.slip_allowed=not Equipment.has_mouth_harness(target)
 Binding.refresh(self,target)
 Shoulders.refresh(self,target)

func _can_tighten(target: Dictionary) -> bool:
 if Equipment.lock_only(target): return false
 if cursed_eyes(target): return false
 return _reinforcement_locks(target) or Binding.can_tighten(target) or Shoulders.missing(self,target)

func _reinforcement_locks(target: Dictionary) -> bool:
 return tier(target.durability,target.maximum)==3 and Equipment.allows(target,"lock") and not target.locked

func _reinforce_equipment(target: Dictionary, to_tier: int=0) -> String:
 if _reinforcement_locks(target):
  target.locked=true
  target.durability=target.maximum
  _refresh_equipment(target)
  return "加固并上锁，耐久恢复至满值"
 var current=tier(target.durability,target.maximum)
 target.durability=target.maximum*(1.0 if to_tier==3 else (0.8 if current==1 else 1.0))
 _refresh_equipment(target)
 return "收紧到%d档" % tier(target.durability,target.maximum)

func links_at(slot: String) -> Array:
 if _equipment_read_active(): return _equipment_read.links.get(slot,[]).duplicate()
 return state.links.filter(func(link):return link.durability>0 and slot in link.slots)

func _prepare_link(a: String, b: String, durability: float, source: String, grade: int=1, blocked_slip: Array=[], connection_slots: Array=[], connection_points: Array=[]) -> Dictionary:
 var ends=[_equipment(a),_equipment(b)]
 if a==b or ends.any(func(e):return e.is_empty() or e.template=="link_rope"): return {}
 var slots=connection_slots.duplicate()
 if slots.is_empty(): slots=[ends[0].slot,ends[1].slot]
 if slots.size()!=2: return {}
 for slot in slots:
  if _sealed_reason(slot)!="": return {}
 if connection_points.is_empty():
  for pa in Links.anchor_points(ends[0],slots[0]):
   for pb in Links.anchor_points(ends[1],slots[1]):
    var prepared=_prepare_link(a,b,durability,source,grade,blocked_slip,slots,[pa,pb])
    if not prepared.is_empty(): return prepared
  return {}
 var link={"id":"link_%d" % state.next_link,"template":"link_rope","material":"rope","variant":0,"grade":grade,"locked":false,
  "slot":slots[1] if slots[0]==Links.CROTCH_CONTACT else slots[0],"slots":slots,"contact_points":connection_points.duplicate(),"name":"","ends":[ends[0].id,ends[1].id],"blocked_slip":blocked_slip.duplicate(),"durability":durability,"maximum":Equipment.maximum(grade),"source":source}
 if Links.validate(link,link_anchors(),state.links)!="": return {}
 link.name="—".join(connection_points.map(func(point):return "股绳" if point==Links.CROTCH_CONTACT else Equipment.point_name(point)))+"链接绳"
 return link

func _install_link(a: String, b: String, durability: float, source: String, grade: int=1, blocked_slip: Array=[], connection_slots: Array=[], connection_points: Array=[]) -> Dictionary:
 var link=_prepare_link(a,b,durability,source,grade,blocked_slip,connection_slots,connection_points)
 if link.is_empty(): return {}
 state.links.append(link)
 state.next_link+=1
 RelicEffects._mana_hook(self,"restraint_mana","新增"+link.name)
 Cards.restraint_changed(self,"worn")
 return link

func _slip_block_reason(target: Dictionary) -> String:
 for link in state.links:
  if link.durability>0 and target.id in link.blocked_slip:
   return link.name+"牵住了这件装备，须先解除链接或它连接的另一件装备。"
 return ""

# §5: presence and side questions read the slot edge directly; the hand special case stays
# side-based and never degrades into a plain non-empty test.
func occupied(slot: String) -> bool:
 if slot in ["palm","fingers"]: return hand_blocked(slot,"left") and hand_blocked(slot,"right")
 if _equipment_read_active(): return not _equipment_read.slots.get(slot,[]).is_empty()
 return not equipment_at(slot).is_empty()

func hand_blocked(slot: String, side: String) -> bool:
 if _equipment_read_active(): return _equipment_read.slots.get(slot,[]).any(func(e):return e.get("side","") in ["",side])
 return equipment_at(slot).any(func(e):return e.get("side","") in ["",side])

func hands_can_hold() -> bool:
 return ["left","right"].any(func(side):return not hand_blocked("fingers",side))

func hand_cast_reason() -> String:
 if relic_value("toe_cast")>0 and not occupied("toes"): return ""
 var reason=physical_hand_cast_reason()
 if reason!="" and relic_value("toe_cast")>0: return reason+"秘密武器：脚趾也被拘束，不能代替手部施法。"
 return reason

func physical_hand_cast_reason() -> String:
 var free_hands=["left","right"].filter(func(side):return not hand_blocked("palm",side) and not hand_blocked("fingers",side)).size()
 var single=relic_value("single_hand_cast")>0
 if free_hands>=(1 if single else 2): return ""
 return "需要同一只手的手掌和手指都自由。" if single else "需要双手的手掌和手指都自由。"

func can_observe_intents() -> bool:
 return not occupied("eyes")

func _enemy_preparation(e: Dictionary, text: String) -> void:
 var previous=_copy_context
 if not can_observe_intents():
  _copy_context=previous.duplicate(true)
  _copy_context.cue="enemy.unseen";_copy_context.actor=e.name
 _emit("event",text if can_observe_intents() else "视线受阻，未能看清行动。")
 _copy_context=previous

func jointly_bound(slot: String) -> bool:
 return equipment_at(slot).any(func(e):return e.get("side","")=="")

func _capacity(slot: String) -> int:
 return Equipment.capacity(slot)

func _priority(slot: String) -> int:
 if slot=="toes" and not occupied(slot) and relic_value("toe_cast")>0: return Equipment.slot_priority("mouth")
 return Equipment.slot_priority(slot) if not occupied(slot) else 1

func _install_choice(choice: Dictionary, source: String, grade: int, tightness: int, final: bool=false) -> Dictionary:
 if choice.kind=="link":
  choice=choice.duplicate(true);choice.erase("rank")
  choice.grade=grade;choice.tier=tightness;choice.source=source;choice.final=final;choice.delayed=false
  choice.text="施加%s%s · %d档%s" % [Equipment.GRADES[grade],choice.name,tightness,"，随后离场" if final else ""]
  return choice
 var p=_equipment_intent(choice.template,grade,source,tightness)
 p.slot=choice.slot;p.point=choice.point;p.final=final
 p.text="%s%s · %d档 · %s%s" % [Equipment.GRADES[grade],Equipment.name_for(p.template,p.slot,grade,p.variant),tightness,Equipment.point_name(p.point) if p.point!="" else B.SLOT_NAMES[p.slot],"，随后离场" if final else ""]
 return p

func _equipment_intent(template: String, grade: int, source: String, tightness: int=-1) -> Dictionary:
 var material=Equipment.TEMPLATES[template].material
 var variant=_random_index("equipment",Equipment.MATERIALS[material][grade].size())
 var initial_tier=tightness if tightness>0 else [1,1,2][_random_index("enemy",3)]
 return {"kind":"install","tier":initial_tier,"grade":grade,"source":source,"template":template,"variant":variant,"final":true,"delayed":false,
  "text":"施加%s%s · %d档，随后离场" % [Equipment.GRADES[grade],Equipment.name_for(template,"mouth",grade,variant) if template=="mouth_band" else Equipment.TEMPLATES[template].name,initial_tier]}

func _plan(e: Dictionary) -> Dictionary:
 var intent=EnemyPlans.build(self,e)
 if e.get("pressure_gain",0)>0 and intent.kind not in ["idle","leave"]:
  intent.pressure=e.pressure_gain
  intent.text+=" · 贴身刺激＋"+number(intent.pressure)+"快感"
 return intent

func _enemy_phase() -> void:
 if _finish_if_saturated(): return
 var announced={}
 for enemy in state.enemies: announced[enemy.id]=enemy.intent.duplicate(true)
 for e in state.enemies:
  if state.phase!="battle": break
  if e.gone or e.get("acted_round",-1)==state.round or (Enemies.behavior(e.type)=="puppet" and announced[e.id].get("kind","")!="capture"): continue
  var intent=announced[e.id]
  e.acted_round=state.round
  IronMan.begin_enemy_turn(e)
  _copy_context={"cue":"enemy."+intent.kind,"actor":e.name,"enemy_id":e.id,"sequence":state.logs.size()}
  if intent.get("delayed",false):
   _copy_context.cue="enemy.delayed"
   if intent.get("cancel_on_interrupt",false):
    e.next_climax_capture=intent.climax_threshold+Enemies.TYPES[e.type].climax_capture_repeat
    e.intent=EnemyPlans.six_plan(self,e)
    _emit("event",e.name+"放弃了被打断的逮捕准备，恢复原定行动。")
   else:
    e.intent.delayed=false
    _emit("event",e.name+"被打断，本回合停顿；原定行动保留到下回合。")
   EnemyPlans.end_turn(self,e)
   RelicEffects.flush(self)
   _copy_context={}
   continue
  if Enemies.behavior(e.type)=="guard": Guard.execute(self,e,intent)
  else:
   _enemy_operation(e,intent)
   if CaptureBind.kind(self,e)!="" and intent.kind in ["apply","tighten_budget","bind_gain","idle","charge","carried_apply"]: e.guard.cycle_step=(e.guard.cycle_step+1)%3
  if state.phase!="battle":
   _copy_context={}
   break
  if intent.get("pressure",0)>0: Pressure.gain(self,intent.pressure,e.name+"的贴身摩擦")
  if intent.has("pressure_effect"): Pressure.attach(self,intent.pressure_effect,"",e.id)
  if e.gone and intent.kind!="leave": _emit("event",e.name+"离开战场。")
  EnemyPlans.end_turn(self,e)
  RelicEffects.flush(self)
  if intent.has("move"):
   e.move_streak=e.move_streak+1 if e.last_move==intent.move else 1
   e.last_move=intent.move
  if IronMan.finish_turn(e,intent): e.stage+=1
  e.last_intent=intent.text
  e.intent={}
  CaptureBind.observe(self)
  _copy_context={}
  if _finish_if_saturated(): break
 if _battle_end_reason()=="victory": _finish_battle("victory")

func _enemy_operation(e: Dictionary, intent: Dictionary) -> void:
 var previous=_copy_context
 var resolved=EnemyPlans.resolve(self,e,intent)
 var slots=[]
 if resolved.kind=="link": slots=resolved.slots.duplicate()
 elif resolved.has("slot"): slots=[resolved.slot]
 elif resolved.has("target"):
  var target=_equipment(resolved.target)
  if not target.is_empty(): slots=["shoulder"] if resolved.kind=="shoulder" or Equipment.is_shoulder(target) else Equipment.coverage(target)
 _copy_context={"cue":"enemy."+("install" if resolved.kind in ["shoulder","link"] else resolved.kind),"actor":e.name,"enemy_id":e.id,"sequence":state.logs.size(),"slots":slots}
 _execute_enemy_operation(e,resolved)
 _copy_context=previous

func _execute_enemy_operation(e: Dictionary, intent: Dictionary) -> void:
 var applied={}
 if intent.kind in ["install","assembly","special_install","link","shoulder"]:
  applied=Application.execute_concrete(self,intent,intent.get("source",e.id))
  if applied.get("evaded",0)>0:
   if intent.get("final",false): e.gone=true
   return
 match intent.kind:
  "iron_stunned","iron_bind_gain","iron_restraints","iron_composite","iron_recharge","iron_upgrade": IronMan.execute(self,e,intent)
  "puppet_awaken","puppet_mend","puppet_composite","puppet_special":
   Puppets.execute(self,e,intent)
  "apply":
   var spec=EnemyPlans.application_spec(self,e,intent)
   var result=Application.execute(self,spec,e.id)
   if result.count+result.evaded>0 and intent.has("carried_index"):
    e.carried_indices.erase(intent.carried_index)
    _emit("event",e.name+"取出了一件备用装备，盒内还剩%d件。" % e.carried_indices.size(),{"carried_equipment":{"enemy":e.id,"used":intent.carried_index,"remaining":e.carried_indices.duplicate()}})
   e.ready_layers=maxi(0,e.get("ready_layers",0)-int(result.get("ready_used",0)))+int(intent.get("ready_gain",0))
   for item in result.get("installed",[]):
    var slots=[]
    for piece in item.get("components",[item]):
     var affected=piece.slots if piece.get("template","")=="link_rope" else (SpecialEquipment.occupied_slots(piece) if SpecialEquipment.is_special(piece) else Equipment.coverage(piece))
     for slot in affected:
      if slot not in slots: slots.append(slot)
    _copy_context.slots=slots
    _emit("event",e.name+"施加了"+item.name+"。",{"equipment":item.id})
   if not result.get("removed",[]).is_empty():
    _emit("event",e.name+"替换了%d处原有装备。" % result.removed.size(),{"replaced":result.removed,"lost_links":result.get("lost_links",[])})
   var missing=spec.count-int(result.get("count",0))-int(result.get("evaded",0))
   if missing>0:
    if intent.get("tighten_missing",false):
     _emit("event",e.name+"施加了%d件拘束具，剩余%d次没有合法新增位置，改为加固。" % [result.count,missing])
     var completed=0
     var required_slots=intent.get("required_slots",[])
     while completed<missing and not EnemyPlans.targets(self,e,"tighten",required_slots).is_empty():
      _enemy_operation(e,{"kind":"tighten","text":"加固拘束具","delayed":false,"required_slots":required_slots})
      completed+=1
     if completed<missing: _emit("event",e.name+"完成%d次加固，其余%d次没有可加固的目标而落空。" % [completed,missing-completed])
    else: _emit("event",e.name+"本次仅施加%d件，其余没有合法位置。" % int(result.get("count",0)))
   if intent.get("ready_gain",0)>0: _emit("event",e.name+"获得「准备就绪」，现有%d层。" % e.ready_layers)
   if intent.get("tighten_after",false):
    _enemy_operation(e,{"kind":"tighten","tier":3,"random_target":true,"text":"翻卷收紧","delayed":false})
   if intent.get("final",false): e.gone=true
  "debuff":
   if intent.effect=="weakness":
    state.weakness_turns=maxi(state.weakness_turns,intent.turns)
    _emit("event",e.name+"对你施加了「无力化」。")
  "capture": Guard.capture(self,e)
  "bind_prepare":
   e.guard.bind_ready=true
   _enemy_preparation(e,"准备捕缚。")
  "bind_apply": CaptureBind.apply_bind(self,e)
  "bind_gain": CaptureBind.gain_bind(self,CaptureBind.gain_amount(self,e),e.name)
  "six_prepare": _enemy_preparation(e,"展开法阵。")
  "six_opening":
   _six_area_sweep(e,1,2)
   _enemy_operation(e,EnemyPlans.six_special(Enemies.TYPES[e.type],1,1,true))
  "six_tease":
   _enemy_operation(e,EnemyPlans.six_ordinary(Enemies.TYPES[e.type],2,2,1,true))
   _six_add_curses(e,"tease",1)
  "six_tune":
   _enemy_operation(e,EnemyPlans.six_special(Enemies.TYPES[e.type],intent.grade,intent.count,true))
   EnemyPlans.execute_tighten_budget(self,e,{"budget":intent.count})
   e.constriction+=1
   _emit("event",e.name+"获得1层「收束」，现有%d层。" % e.constriction,{"constriction":{"enemy":e.id,"layers":e.constriction}})
  "six_composite":
   var plan=EnemyPlans.six_composite(2,2,true)
   if Application.can_apply(self,EnemyPlans.application_spec(self,e,plan),e.id): _enemy_operation(e,plan)
   else: EnemyPlans.execute_tighten_budget(self,e,{"budget":3})
  "six_finale":
   _six_area_sweep(e,2,2)
   _six_add_curses(e,"tease_plus",3)
  "tighten_budget": EnemyPlans.execute_tighten_budget(self,e,intent)
  "carried_apply":
   var plan=EnemyPlans.carried_application(self,e)
   if plan.is_empty(): _emit("event",e.name+"的备用装备当前都无法佩戴，留在盒内。")
   else: _enemy_operation(e,plan)
  "turn_install":
   EnemyPlans.activate_install(self,e)
  "equipment_batch": EnemyPlans.execute_batch(self,e,intent)
  "split_burst":
   EnemyPlans.execute_batch(self,e,EnemyPlans.batch(self,e,0,2,3,false,Enemies.TYPES[e.type].final_pool))
   _split_enemy(e,e.max_hp*Enemies.TYPES[e.type].split_threshold)
  "link":
   var rope=applied.installed[0] if applied.ok else {}
   if not rope.is_empty(): _emit("event",e.name+"施加了"+rope.name+"，紧度%d档。" % intent.tier,{"equipment":rope.id,"template":rope.template})
   else: _emit("event",e.name+"未能施加链接绳，两处连接位置已不适用。")
   if intent.get("final",false): e.gone=true
  "shoulder":
   var target=_equipment(intent.target)
   if applied.ok: _emit("event",e.name+"给"+_equipment_name(target)+"连接了一对肩部拘束，左右分别固定。")
   else: _emit("event",e.name+"未能施加肩部拘束："+applied.reason)
  "assembly":
   var root=applied.installed[0] if applied.ok else {}
   if not root.is_empty(): _emit("event",e.name+"施加了中级"+root.name+"，各组件紧度%d档。" % intent.tier)
   else:
    _emit("event",e.name+"没有装上原定的"+intent.name+"："+applied.reason)
  "install":
   var installed=applied.installed[0] if applied.ok else {}
   if not installed.is_empty():
    _emit("event",e.name+"在"+Equipment.position_text(installed)+"施加了"+installed.name+"（"+Equipment.material_name(installed)+"），紧度"+str(intent.tier)+"档。",{"equipment":installed.id,"template":installed.template})
   else:
    _emit("event",e.name+"没有装上原定装备："+applied.reason)
   if intent.get("final",false): e.gone = true
  "tighten":
   var target = _equipment(intent.target)
   if not target.is_empty():
    var change=_reinforce_equipment(target,intent.get("tier",0))
    _emit("event",e.name+"将"+_equipment_name(target)+change+"。")
   else: _emit("event",e.name+"要加固的装备已经解除，这次动作落空。")
  "lock":
   var target = _equipment(intent.target)
   if not target.is_empty() and Equipment.allows(target,"lock") and not target.locked:
    target.locked = true
    _emit("event",e.name+"锁住了"+target.name+"。")
   else: _emit("event",e.name+"没有锁住原定目标。")
   if intent.get("final",false): e.gone = true
  "charge":
   if intent.get("quantity_gain",0)>0:
    e.application_bonus+=intent.quantity_gain
    _emit("event",e.name+"获得%d层「狂躁」，现有%d层。" % [intent.quantity_gain,e.application_bonus])
   if intent.get("ritual_gain",0)>0:
    e.ritual+=intent.ritual_gain
    _emit("event",e.name+"获得%d点「仪式」，现有%d点。" % [intent.ritual_gain,e.ritual])
   _enemy_preparation(e,"蓄力。")
  "special_install":
   var item=applied.installed[0] if applied.ok else {}
   if item.is_empty(): _emit("event",e.name+"本次未能佩戴装备："+applied.reason)
   else: _emit("event",e.name+"佩戴了"+item.name+"。",{"equipment":item.id,"type":item.type})
  "pause":
   _emit("event","停顿。")
  "leave":
   e.gone = true
   _emit("event",e.name+("未能在"+B.SLOT_NAMES[Enemies.TYPES[e.type].attachment_slot]+"施加原定装备，随后离场。" if Enemies.behavior(e.type)=="attachment" else "无处附着，散去并离场。"))
  "idle": _emit("event",intent.text)

func _six_area_sweep(e: Dictionary, grade: int, tightness: int) -> void:
 var definition=Enemies.TYPES[e.type]
 for area in EnemyPlans.six_areas():
  var plan=EnemyPlans.six_ordinary(definition,grade,tightness,1,true)
  plan.templates=(definition.opening_pool if grade==1 else definition.install_pool).duplicate()
  plan.required_slots=area.slots.duplicate()
  plan.text="束缚"+area.name
  if Application.can_apply(self,EnemyPlans.application_spec(self,e,plan),e.id):
   _enemy_operation(e,plan)
   continue
  var choices=EnemyPlans.six_area_targets(self,e,area.slots)
  if choices.is_empty():
   _emit("event",e.name+"扫过"+area.name+"，这里没有可以新增或加固的目标。")
  else:
   var target=choices[_random_index("enemy",choices.size())]
   _enemy_operation(e,{"kind":"tighten","target":target.id,"text":"加固"+area.name,"delayed":false})

func _six_add_curses(e: Dictionary, type: String, count: int) -> void:
 var added=0
 for i in range(count):
  if not _gain_temporary_card(type).is_empty(): added+=1
 if added>0: _emit("event",e.name+"将%d张「%s」混入弃牌堆。" % [added,B.CARD_NAMES[type]],{"temporary_curse":{"type":type,"count":added}})

func _installation_points(slot: String, point: String="") -> Array:
 if not Equipment.SEGMENTS.has(slot): return Equipment.points(slot) if point=="" or point==slot else []
 var options=Equipment.points(slot)
 if point!="": return [point] if point in options else []
 options.sort_custom(func(a,b):return _point_count(a)<_point_count(b) if _point_count(a)!=_point_count(b) else Equipment.ANATOMY.find(a)<Equipment.ANATOMY.find(b))
 return [options[0]]

func _point_count(point: String) -> int:
 return _capacity_point_count(point)

func _installation_reason(template: String, slot: String, grade: int, locked: bool=false, point: String="", layer: int=-1) -> String:
 return _prepare_installation(template,slot,grade,locked,point,layer).reason

# Resolve exact points and structural layer once for both queries and creation.
func _prepare_installation(template: String, slot: String, grade: int, locked: bool=false, point: String="", layer: int=-1) -> Dictionary:
 if Equipment.TEMPLATES.get(template,{}).get("lock_only",false) and state.equipment.any(func(e):return Equipment.lock_only(e)):
  return {"reason":"已经佩戴限制项圈。"}
 if cursed_eyes({"slot":slot}): return {"reason":"诅咒眼罩封闭了眼部装备操作。"}
 var reason=Equipment.definition_reason(template,slot,grade,locked)
 if reason!="": return {"reason":reason}
 reason=_sealed_reason(slot)
 if reason!="": return {"reason":reason}
 var locations=_installation_points(slot,point)
 if locations.is_empty(): return {"reason":"该具体位置不属于所选身体部位。"}
 var overlaps=equipment_at(slot).filter(func(e):return locations.any(func(p):return _piece_covers_point(p,e)))
 var proposed=layer
 if proposed<0:
  proposed=0
  for e in overlaps: proposed=maxi(proposed,e.layer+(1 if e.has("root_id") else 0))
 if slot=="mouth" and Equipment.TEMPLATES[template].material=="tape":
  for e in overlaps:
   if e.material!="tape": proposed=maxi(proposed,e.layer+1)
 if overlaps.any(func(e):return Binding.present(e) and proposed>e.layer): return {"reason":"此处已有躯干固缚，不能在它外面追加拘束具；可以在同层安装。"}
 if overlaps.any(func(e):return e.has("root_id") and proposed<=e.layer): return {"reason":"已有复合拘束具覆盖这里，只能安装在它外面。"}
 for location in locations:
  var limit=Equipment.capacity(slot,template)
  if _point_count(location)>=limit: return {"reason":("嘴部已有装备时只能追加胶带。" if limit<_capacity(slot) else Equipment.point_name(location)+"已有%d件装备，位置已满。" % limit),"capacity_full":true,"points":locations,"layer":proposed}
 return {"reason":"","points":locations,"layer":proposed}

func _install_template(template: String, slot: String, durability: float, maximum: float, locked: bool, source: String, grade: int=1, layer: int=-1, variant: int=0, point: String="") -> Dictionary:
 var placement=_prepare_installation(template,slot,grade,locked,point,layer)
 if placement.reason!="": return {}
 var spec=Equipment.TEMPLATES[template]
 var e = {"id":"equipment_%d" % state.next_equipment,"template":template,"variant":variant,"slot":slot,"name":Equipment.name_for(template,slot,grade,variant),
  "durability":durability,"maximum":maximum,"locked":locked,"material":spec.material,"source":source,"grade":grade,"layer":placement.layer,"slip_allowed":spec.slip,"points":placement.points}
 if Equipment.validate(e)!="": return {}
 state.next_equipment += 1
 state.equipment.append(e)
 _refresh_equipment(e)
 RelicEffects._mana_hook(self,"restraint_mana","佩戴"+e.name)
 if not Equipment.lock_only(e): Cards.restraint_changed(self,"worn")
 return e

# Only tests use fixture injection. The UI does not expose this method.
func add_fixture(slot: String, durability: float, maximum: float = 10.0, locked: bool = false, layer: int = 0, template: String="") -> Dictionary:
 return _install_template(Equipment.default_template(slot) if template=="" else template,slot,durability,maximum,locked,"fixture",1,layer)

func tier(durability: float, maximum: float) -> int:
 if durability <= 0.000001: return 0
 var p = durability/maximum
 if p <= 0.40000001: return 1
 if p <= 0.80000001: return 2
 return 3

func lower_durability(d: float, m: float) -> float:
 var p = d/m
 if tier(d,m) == 1: return 0.0
 if tier(d,m) == 2: return maxf(0.0,(p-0.4)*m)
 return (0.4+2.0*(p-0.8))*m

func _damage_multiplier(p: float) -> float:
 # Smooth ends around each interval; continuous at 40%. Tunable prototype curve.
 if p <= 0.4:
  var x = clampf(1.0-p/0.4,0.0,1.0)
  return 1.0+B.LOOSE_DAMAGE_BONUS*x*x*(3.0-2.0*x)
 var x = clampf((p-0.4)/0.6,0.0,1.0)
 return 1.0-B.DAMAGE_REDUCTION_MAX*x*x*(3.0-2.0*x)

func level(region: String) -> int:
 return ceili(restraint_degree(region))

func restraint_degree(region: String) -> float:
 var slots = B.ARM_SLOTS if region == "arms" else B.LEG_SLOTS
 var marks: Array = []
 for slot in slots:
  marks.append(not equipment_at(slot).is_empty() if region=="arms" and slot in ["palm","fingers"] else jointly_bound(slot))
 if not marks.has(false) and (region!="arms" or (occupied("palm") and occupied("fingers"))): return 4
 var value = (0.5 if marks[0] else 0.0)+(0.5 if marks[1] else 0.0)+(2.0 if marks[2] else 0.0)+(1.0 if marks[3] or marks[4] else 0.0)
 var result=0.0
 if value>0: result=value if value<1 else (1.0 if value<2 else (2.0 if value<3 else 3.0))
 if region=="arms" and CaptureBind.has_bind(self): result=maxf(1.0,result)
 return result

func _wall_bonus() -> float:
 return B.WALL_BONUS if at_wall() and state.wall == "rough" and state.posture != "lie" else 0.0

func _bound_feet() -> bool:
 return occupied("ankle") or occupied("foot") or occupied("toes") or occupied("calf")

func _outer(target: Dictionary) -> bool:
 if target.has("parent_id"): return _outer(_equipment(target.parent_id))
 if target.template=="link_rope":
  for i in range(2):
   if _outer_at(_equipment(target.ends[i]),target.slots[i],target.contact_points[i]): return true
  return false
 return Equipment.contact_slots(target).all(func(slot):return _outer_at(target,slot))

func _outer_at(target: Dictionary, slot: String, point: String="") -> bool:
 return _outer_cover_at(target,slot,point).is_empty()

# The same covering piece supplies both exposure eligibility and its explanation.
func _outer_cover_at(target: Dictionary, slot: String, point: String="") -> Dictionary:
 if Equipment.is_shoulder(target): return {}
 for e in equipment_at(slot):
  if point!="" and not _piece_covers_point(point,e): continue
  if target.get("side","")!="" and e.get("side","") not in ["",target.side]: continue
  if target.has("points") and not Equipment.overlaps(target,e): continue
  if e.get("root_id",e.id)!=target.get("root_id",target.id) and e.layer>target.layer: return e
 return {}

func _effective_ratio(target: Dictionary) -> float:
 if target.has("parent_id"): return _effective_ratio(_equipment(target.parent_id))
 var p=target.durability/target.maximum
 return p

func _stack_items(target: Dictionary) -> Array:
 if _equipment_read_active() and is_same(target,_equipment(target.get("id",""))):
  if not _equipment_read.stacks.has(target.id): _equipment_read.stacks[target.id]=_query_stack_items(target)
  return _equipment_read.stacks[target.id].duplicate()
 return _query_stack_items(target)

func _query_stack_items(target: Dictionary) -> Array:
 if target.has("parent_id"): return _stack_items(_equipment(target.parent_id))
 if SpecialEquipment.is_special(target):
  return state.special_equipment.filter(func(e):return SpecialEquipment.occupied_slots(e).any(func(slot):return slot in SpecialEquipment.occupied_slots(target)))
 if Equipment.coverage(target).is_empty() or target.template=="link_rope": return [target]
 return physical_pieces().filter(func(e):return Equipment.overlaps(target,e) and (not target.get("independent",false) or e.id==target.id or e.get("root_id","")!=target.get("root_id","")))

func _slip_reason(target: Dictionary, method: String="slip") -> String:
 if Equipment.lock_only(target): return Equipment.LOCK_ONLY_REASON
 if cursed_plate(target): return SpecialEquipment.CURSED_PLATE_REASON
 if cursed_eyes(target): return "诅咒眼罩封闭了眼部装备操作。"
 if Equipment.has_mouth_harness(target): return "马具固定着口球，不能通过滑脱取下；可以使用挣扎类卡牌，或满足条件后徒手解除。"
 if target.slot=="eyes":
  for mouth in equipment_at("mouth"):
   if Equipment.has_mouth_harness(mouth) and _effective_ratio(mouth)>_effective_ratio(target)+0.000001:
    return "口球的马具比这件眼罩更紧，当前不能滑脱眼罩。"
 if SpecialEquipment.is_special(target):
  var reinforcement=state.special_equipment.any(func(item):return SpecialEquipment.reinforcement_matches(item,target))
  if SpecialEquipment.is_chastity(target) and target.get("locked",false) and reinforcement:
   return target.name+"的加固带仍在，当前不能滑脱；可以先切断加固带或开锁。"
  if SpecialEquipment.is_reinforced_cup(target) and reinforcement and method in ["slip","magic_slip"]:
   return target.name+"的固定带仍在，当前不能滑脱；可以先切断固定带或改用挣扎。"
  return SpecialEquipment.method_reason(target,method)
 if not Equipment.allows(target,"slip"): return "这件装备的结构没有滑脱路线。"
 var shoulder_reason=Shoulders.slip_reason(self,target)
 if shoulder_reason!="": return shoulder_reason
 if not _outer(target):
  for contact in Contact.target_contacts(self,target):
   var cover=_outer_cover_at(contact.target,contact.slot,contact.get("point",""))
   if not cover.is_empty(): return "无法滑脱：%s处被%s覆盖，需先解除它。" % [Equipment.point_name(contact.point) if contact.has("point") else B.SLOT_NAMES[contact.slot],_equipment_name(cover)]
  return "外层拘束尚未解除，无法滑脱。"
 if target.template in ["leg_body","jacket_body"]:
  var root=_composite(target.root_id)
  if root.components.any(func(e):return e.part!="body"):
   return "需要先解除全部外带，才能滑脱套体。" if root.kind=="leg" else "需要先解除袖部连接和下摆固定，才能滑脱衣身。"
 for root in state.composites:
  if root.kind!="head": continue
  if root.attached_to==target.id: return "头部马具仍维持口部固定，需要先解除马具。"
  if target.slot=="eyes" and _effective_ratio(_composite_body(root))>target.durability/target.maximum+0.000001: return "头部马具比这件眼罩更紧，当前不能滑脱眼罩。"
 return _slip_block_reason(target)

func _strain_release_root(target: Dictionary) -> Dictionary:
 if not target.has("root_id"): return {}
 var root=_composite(target.root_id)
 if root.kind!="glove": return {}
 var body=_composite_body(root)
 if not Composites.has_open_strap(root) or tier(body.durability,body.maximum)==3 or not _outer(body): return {}
 if root.components.any(func(e):return _slip_block_reason(e)!=""): return {}
 return root

# Shared direct loosening effect; permission and cost belong to the caller's candidate.
func _apply_manual_release(target: Dictionary, after: float, release_lock_only: bool=false, absolute: bool=false) -> void:
 if Equipment.lock_only(target) and not release_lock_only: return
 if cursed_plate(target) and not absolute: return
 if cursed_eyes(target):
  if not absolute: return
  target.absolute_release=true
 target.durability=after

func relic_value(hook: String) -> float:
 return Relics.value(state.relics,hook,state.relic_counters,state.get("ditto_form",""))

func max_energy() -> int:
 return B.ENERGY+int(relic_value("max_energy"))

# Reactions still resolve during interruption, but cannot restore usable energy.
# All energy grants use this entry; payment and turn initialization remain separate.
func _gain_energy(amount: int) -> int:
 if state.overloaded: return 0
 state.energy+=amount
 return amount

func cursed_eyes(target: Dictionary) -> bool:
 return "cursed_blindfold" in state.relics and target.get("slot","")=="eyes"

func cursed_plate(target: Dictionary) -> bool:
 if SpecialEquipment.is_cursed_plate(target): return true
 return SpecialEquipment.is_reinforcement(target) and state.special_equipment.any(func(item):return SpecialEquipment.is_cursed_plate(item) and item.id==target.get("owner_id",""))

func _gain_charge(amount: int) -> void:
 state.charge+=amount

func charge_bonus(hit_index: int=0) -> float:
 var count=(state.charge if hit_index==0 else 0) if state.charge_all else mini(1,maxi(0,state.charge-hit_index))
 return B.CHARGE_BONUS*count

# Shared pre-target values for live card faces and actual escape damage.
# Future-hit queries project charge consumption without changing state.
func escape_values(mode: String, base: float, target: Dictionary={}, passive: bool=false, hit_index: int=0) -> Dictionary:
 var bonus=RelicEffects.attribute(self,"strength" if mode=="strain" else "dexterity",target,passive)
 var charge=0.0 if passive else charge_bonus(hit_index)
 return {"base":base,"bonus":bonus,"charge":charge,"raw":base+bonus+charge}

func _consume_charge() -> void:
 if state.charge<=0: return
 var consumed=state.charge if state.charge_all else 1
 state.charge-=consumed
 RelicEffects.trigger(self,"charge_spent",{"count":consumed})
 if state.charge_all or state.charge==0: state.charge_all=false

func retained_charge() -> int:
 return mini(state.charge,B.CHARGE_RETENTION+combat_retention_bonus())

func retained_energy() -> int:
 var unused=maxi(state.energy,state.combat.energy) if relic_value("retain_energy")>0 else 0
 return mini(state.next_energy+unused,B.ENERGY_RETENTION+combat_retention_bonus())

func retained_temporary_mana() -> float:
 return minf(state.temporary_mana,B.TEMPORARY_MANA_RETENTION+combat_retention_bonus()*5.0)

func combat_retention_bonus() -> int:
 return int(relic_value("combat_retention_layers"))

func _clear_charge(keep_retained: bool=false) -> void:
 state.charge=retained_charge() if keep_retained else 0
 if state.charge==0: state.charge_all=false

func _apply_equipment_damage(target: Dictionary, damage: float, kind: String, passive: bool=false, consume_charge: bool=true) -> void:
 if cursed_plate(target): return
 if cursed_eyes(target): return
 if SpecialEquipment.is_special(target):
  if SpecialEquipment.DESIGNS[target.type].get("damage_factor",1.0)==0.0: return
  if SpecialEquipment.is_chastity(target):
   if damage<=0 or (kind not in ["slip","magic_slip"] and not SpecialEquipment.unlocked_release(target,kind)): return
   if target.get("locked",false) and state.special_equipment.any(func(item):return SpecialEquipment.reinforcement_matches(item,target)): return
   if SpecialEquipment.unlocked_release(target,kind): damage=target.durability
  elif SpecialEquipment.is_reinforced_cup(target) and kind in ["slip","magic_slip"] and state.special_equipment.any(func(item):return SpecialEquipment.reinforcement_matches(item,target)): return
  elif SpecialEquipment.is_reinforcement(target) and kind!="cut": return
 elif Equipment.TEMPLATES[target.template].get("damage_factor",1.0)==0.0: return
 # Capture eligibility before this hit; breaking a first strap cannot trigger the same hit twice.
 var before=target.durability
 var release=_strain_release_root(target) if kind=="strain" and not passive else {}
 target.durability=maxf(0.0,target.durability-damage)
 if kind in ["strain","slip"] and not passive and consume_charge: _consume_charge()
 if not release.is_empty():
  _composite_body(release).durability=0.0
  _emit("event","这次挣扎直接脱下了"+release.name+"。")
 if kind=="strain" and before>0 and target.durability<=0: RelicEffects.strain_destroyed(self)

func escape_preview(target: Dictionary, mode: String, base: float, assist_profiles: Array=[], passive: bool=false, area_effect: bool=false, continuation: bool=false, splash: bool=false, ignore_tightness_reduction: bool=false) -> Dictionary:
 if not _equipment_read_active() or not is_same(target,_equipment(target.get("id",""))):
  return _build_escape_preview(target,mode,base,assist_profiles,passive,area_effect,continuation,splash,ignore_tightness_reduction)
 # Keep every argument, including full precision numbers and nested reach profiles.
 # Copies isolate callers which annotate previews or later reuse mutable profiles.
 var arguments=[mode,base,assist_profiles,passive,area_effect,continuation,splash,ignore_tightness_reduction]
 if not _equipment_read.escapes.has(target.id): _equipment_read.escapes[target.id]=[]
 var entries: Array=_equipment_read.escapes[target.id]
 for entry in entries:
  if entry.arguments==arguments: return entry.result.duplicate(true)
 var result=_build_escape_preview(target,mode,base,assist_profiles,passive,area_effect,continuation,splash,ignore_tightness_reduction)
 entries.append({"arguments":arguments.duplicate(true),"result":result.duplicate(true)})
 return result

func _build_escape_preview(target: Dictionary, mode: String, base: float, assist_profiles: Array=[], passive: bool=false, area_effect: bool=false, continuation: bool=false, splash: bool=false, ignore_tightness_reduction: bool=false) -> Dictionary:
 var items = _stack_items(target)
 if mode=="strain" and SpecialEquipment.unlocked_release(target,mode):
  items=items.filter(func(item):return not (SpecialEquipment.is_reinforcement(item) and item.get("owner_id","")==target.id))
 if target.has("parent_id") and mode=="strain": items=[target]
 var highest = 0.0
 var min_layer = 100000
 var max_layer = -1
 var layered = false
 for e in items:
  highest = maxf(highest,_effective_ratio(e))
  min_layer = mini(min_layer,e.get("layer",0))
  max_layer = maxi(max_layer,e.get("layer",0))
 layered = min_layer != max_layer
 var p = _effective_ratio(target)
 var reason = ""
 var ratio = p
 var divisor = 1.0
 var penalty = 1.0
 var lock_multiplier = 1.0
 var is_strain = mode == "strain"
 if is_strain:
  if not Equipment.allows(target,"strain"):
   reason=SpecialEquipment.method_reason(target,mode) if SpecialEquipment.is_special(target) else ("眼部装备没有力量挣扎路线。" if target.slot=="eyes" else "这件装备没有力量挣扎路线。")
  elif not continuation and p < highest-0.000001: reason = "必须先挣扎该部位紧度最高的装备。"
  elif not continuation and layered:
   for e in items:
    if is_equal_approx(_effective_ratio(e),highest) and e.layer < target.layer:
     reason = "最高紧度并列，必须先处理其中最内侧的一件。"
  if items.size() >= 2:
   var counts = [0,0,0,0]
   for e in items: counts[tier(e.durability,e.maximum)] += 1
   match tier(target.durability,target.maximum):
    3: divisor = counts[3]+0.5*counts[2]
    2: divisor = 0.75*counts[2]+0.25*counts[1]
    1: divisor = maxf(1.0,0.5*counts[1])
  lock_multiplier = (0.75 if relic_value("soften_locked_strain")>0 else 0.5) if target.locked else 1.0
 else:
  reason=_slip_reason(target,mode)
  if layered: ratio = highest
  elif p < highest-0.000001: penalty = 0.5
 var assist={"bonus":0.0,"hands":[],"detail":""} if passive or area_effect or splash else HandAssist.preview(self,target,assist_profiles)
 if target.has("parent_id") and not _outer(target): reason="连接式固缚被外层覆盖，当前不能处理。"
 if reason=="" and SpecialEquipment.is_special(target):
  var method_hands=HandAssist.preview(self,target,assist_profiles).hands if splash else assist.hands
  reason=SpecialEquipment.escape_reason(self,target,mode,method_hands)
 var values=escape_values(mode,base,target,passive)
 var bonus=values.bonus
 var charge=values.charge
 if splash: bonus=0.0;charge=0.0
 var slip_buff=1.0 if is_strain else Consumables.slip_multiplier(self,target)
 var immune = reason=="" and not is_strain and mode != "magic_slip" and ratio > 0.80000001 and slip_buff==1.0
 if area_effect:
  # The effect supplies its own outer-layer targets, not a manual escape route.
  reason="";bonus=0.0;charge=0.0;immune=false
 if cursed_eyes(target): reason="诅咒眼罩封闭了眼部装备操作。"
 if cursed_plate(target): reason=SpecialEquipment.CURSED_PLATE_REASON
 if Equipment.lock_only(target): reason=Equipment.LOCK_ONLY_REASON
 var mult = _damage_multiplier(ratio)
 if ignore_tightness_reduction: mult=maxf(1.0,mult)
 if not is_strain: penalty*=Shoulders.factor(self,target)
 var target_factor=SpecialEquipment.DESIGNS[target.type].damage_factor if SpecialEquipment.is_special(target) else Equipment.TEMPLATES[target.template].get("damage_factor",1.0)
 penalty*=target_factor
 var position=SlipMotion.profile(self,target) if not is_strain and not passive else {"point":"","factor":1.0}
 var link_factor=1.0 if is_strain else Links.slip_factor(self,target)
 var scaled_damage = 0.0 if immune or reason != "" else (base+bonus+charge+assist.bonus)*mult*penalty*lock_multiplier*position.factor*link_factor/divisor
 var environment_true=0.0 if passive or area_effect or splash or reason!="" or target_factor<=0 else _wall_bonus()
 var buff_multiplier=Cards.damage_multiplier(self,"equipment")*Character.damage_multiplier(self)
 scaled_damage*=buff_multiplier
 environment_true*=buff_multiplier
 scaled_damage*=slip_buff
 environment_true*=slip_buff
 var damage=scaled_damage+environment_true
 return {"ignore_tightness_reduction":ignore_tightness_reduction,"slip_buff_multiplier":slip_buff,"damage_buff_multiplier":buff_multiplier,"environment_true":environment_true,"scaled_damage":scaled_damage,"link_factor":link_factor,"passive":passive,"position":position,"assist":assist,"damage":damage,"reason":reason,"immune":immune,"ratio":ratio,"multiplier":mult,"divisor":divisor,"lock_multiplier":lock_multiplier,"penalty":penalty,"base":base,"bonus":bonus,"charge":charge,"release":reason=="" and is_strain and not _strain_release_root(target).is_empty()}

func _formula(p: Dictionary) -> String:
 if p.reason!="": return p.reason
 var buff_text="×%s伤害增益" % number(p.get("damage_buff_multiplier",1.0)) if p.get("damage_buff_multiplier",1.0)!=1.0 else ""
 var link_text="×%s仅向下链接" % number(p.get("link_factor",1.0)) if p.get("link_factor",1.0)!=1.0 else ""
 var slip_buff=p.get("slip_buff_multiplier",1.0)
 var slip_text="×%s部位滑脱增益" % number(slip_buff) if slip_buff!=1.0 else ""
 if p.get("passive",false):
  return "%s部位基础×%s紧度倍率×%s目标倍率×%s锁倍率%s÷%s堆叠%s = %s" % [number(p.base),number(p.multiplier),number(p.penalty),number(p.lock_multiplier),link_text+buff_text,number(p.divisor),slip_text,number(p.damage)]
 var expression="0（三档免疫普通滑脱）" if p.immune else "（%s基础＋%s属性＋%s蓄力＋%s手部辅助）×%s紧度倍率×%s目标倍率×%s锁倍率×%s部位倍率%s÷%s堆叠" % [number(p.base),number(p.bonus),number(p.charge),number(p.get("assist",{}).get("bonus",0.0)),number(p.multiplier),number(p.penalty),number(p.lock_multiplier),number(p.get("position",{}).get("factor",1.0)),link_text,number(p.divisor)]
 expression+=buff_text
 if p.get("environment_true",0)>0: expression+="＋%s粗糙墙面真实加成" % number(p.environment_true/slip_buff)
 if slip_text!="": expression="（"+expression+"）"+slip_text
 return expression+" = "+number(p.damage)

func _mana_cost(base: float) -> float:
 return maxf(0.0,base*Pressure.magic_multiplier(state.pressure,Pressure.maximum(self))*Cards.mana_cost_multiplier(self))

func _mana_payment(payload: Dictionary, mana: float) -> Dictionary:
 if payload.get("payment","")=="flask": return {"mana":0.0,"temporary_mana":0.0,"flask_mana":mana}
 var eligible=payload.kind=="card" or (payload.kind=="prison" and payload.has("uid")) or (payload.kind=="attack" and (Cards.Rules.FIXED_MAGIC.has(payload.type) or payload.get("mana_attachment",false)))
 var temporary=minf(state.temporary_mana,mana) if eligible else 0.0
 return {"mana":mana-temporary,"temporary_mana":temporary,"flask_mana":0.0}

func _pay_mana(payment: Dictionary) -> void:
 for field in payment: state[field]-=payment[field]
 RelicEffects.mana_lost(self,payment.mana,payment.temporary_mana)

# 唯一合法性判定（docs/spec/candidate-removal.md §2.1 N4；批 R1 落地，工作名 eligibility）。
# 全仓唯一产出 valid／reason 的位置：行工厂 _candidate 与接管路径都只消费本函数结果，不再自写判定字段。
# 输入＝指令形状 payload＋行参数（cost／mana／reason／risk）＋当前状态；分支顺序与文案与抽出前逐字相同。
# extra_traction 不是行字段，供 detail 组装复用同一次计算。
func eligibility(payload: Dictionary, cost: int, mana: float, reason: String, risk: String) -> Dictionary:
 if payload.kind=="end" and Character.Expansion.end_reason(self)!="": reason=Character.Expansion.end_reason(self)
 var lock_target=_equipment(payload.get("target",""))
 if Equipment.lock_only(lock_target):
  var unlock=payload.get("mode","")=="unlock" or (payload.kind=="item_use" and Tools.operation(_item(payload.item).get("type",""))=="unlock")
  if payload.kind!="manual" and not unlock: reason=Equipment.LOCK_ONLY_REASON
 if cursed_plate(lock_target): reason=SpecialEquipment.CURSED_PLATE_REASON
 if cursed_eyes(lock_target) or cursed_eyes({"slot":payload.get("slot","")}): reason="诅咒眼罩封闭了眼部装备操作。"
 var uses_magic=(payload.kind in ["card","prison"] and payload.has("uid") and Cards.uses_magic(payload)) or (payload.kind=="attack" and Cards.Rules.FIXED_MAGIC.has(payload.type))
 if reason=="" and uses_magic and cast_view(Cards.cast_profile(self,payload.type,mana>0,payload.get("free"))).chance<=0.0: reason="当前施法成功率为0%。"
 var pressure_risk=Pressure.action_risk(self,payload)
 var extra_traction=Cards.magic_card_traction(self,payload)
 if cost>0 or extra_traction>0:
  var toe_gain=RelicEffects.toe_traction(self).gain*(int(cost>0)+extra_traction)
  if toe_gain>0: pressure_risk+=("\n" if pressure_risk!="" else "")+"秘密武器：脚趾牵扯增加%s快感值。" % number(toe_gain)
 if cost>0:
  var gain=0.0
  for item in state.special_equipment: gain+=SpecialEquipment.gain(item,"energy")
  if gain>0: pressure_risk+=("\n" if pressure_risk!="" else "")+"牵扯：佩戴的性玩具合计增加%s快感值。" % number(gain*Pressure.gain_multiplier(self))
 if pressure_risk!="": risk+=("\n" if risk!="" else "")+pressure_risk
 if reason == "" and state.energy < cost: reason = "需要%d能量，当前只有%d。" % [cost,state.energy]
 var payment=_mana_payment(payload,mana)
 var flask=payload.get("payment","")=="flask"
 var balance=state.flask_mana if flask else state.mana
 var required=payment.flask_mana if flask else payment.mana
 if reason == "" and balance < required: reason = "需要%s%s，当前只有%s。" % [number(required),"魔瓶魔力" if flask else "魔力",number(balance)]
 return {"cost":cost,"mana":mana,"mana_payment":payment,"valid":reason=="","reason":reason,"risk":risk,"extra_traction":extra_traction}

# 接管锁定的资格结论（销 DUP2，docs/spec/candidate-removal.md §2.3）：判定内读接管状态，返回与旧实现
# 逐字相同的文案；未锁定时返回空字典（调用方 merge 后行不变）。接管路径只决定哪一条是本次步骤。
func eligibility_takeover() -> Dictionary:
 if not FirstTurnControl.active(self): return {}
 return {"valid":false,"reason":"豆包接管中"}

# 事实 → 判定结论：唯一判定（本文件 eligibility）＋事实可预置的同一结论。预置只用于「显示字段依赖本次判定
# 结果」的显示点（巫女攻击的 brief 读 mana_payment）：仍是同一实现、同一输入，不构成第二份判定。
func _fact_verdict(f: Dictionary) -> Dictionary:
 if f.has("verdict"): return f.verdict
 return eligibility(f.payload,f.get("cost",0),f.get("mana",0.0),String(f.get("source_reason","")),String(f.get("risk","")))

# 事实 → 判定＋detail 的唯一组装（行与投影显示事实共用；两处都不写 valid／reason，只 merge 判定结论）。
func _fact_core(f: Dictionary) -> Dictionary:
 var payload: Dictionary=f.payload
 # B3（docs/ondemand-copy.md §1.5）：card 目标显示点不再预生成 detail，显示时经 candidate_detail 现算。
 var on_demand=String(payload.get("kind",""))=="card"
 var verdict=_fact_verdict(f)
 var core={}
 core.payload=payload
 core.label=f.label
 if not on_demand: core.detail=_candidate_detail(CopyRouter.text(self,f.copy),payload,int(verdict.extra_traction),verdict.mana_payment)
 # 判定字段整体来自唯一判定（本文件不出现第二处 valid／reason 写点）；extra_traction 只是 detail 输入。
 core.merge(verdict)
 core.erase("extra_traction")
 # 接管步骤的唯一选择结果随事实投影（提交侧经 FirstTurnControl.commit 消费），不构成第二份结论。
 if f.has("control_next"): core.control_next=f.control_next
 return core

# 事实的唯一构造点：source_reason＝该显示点的结构原因（唯一判定的输入，不是资格结论）；判定结论 reason 由
# 唯一判定给出，事实本身不写 valid／reason（G4 的写点面因此不出现第二处结论）。
func _fact(payload: Dictionary, label: String, copy, cost, mana, reason: String, risk: String, group: String) -> Dictionary:
 var fact={"payload":payload,"label":label,"copy":copy,"cost":cost,"mana":mana,"risk":risk,"group":group}
 fact.source_reason=reason
 return fact

# 事实里带显示字段时（brief／brief_tags／casting／body_part 与 reason_scope／reason_surface／copy_context）
# 照抄：显示文本与显示侧元数据只有一份来源，投影不另算。
const FACT_DISPLAY_FIELDS=["brief","brief_tags","casting","body_part","reason_scope","reason_surface","copy_context"]

# 事实 → 投影显示事实（docs/spec/candidate-removal.md §2.1 T5／T8；显示侧的唯一取值入口）：
# 事实＋唯一判定＋detail 组装；不含提交身份 id；带该显示点的显示字段与显示点身份 key（形状键）。
func display_fact(f: Dictionary) -> Dictionary:
 var fact=_fact_core(f)
 # 结构原因（判定输入）：手牌可用性按「结构上可解」优先取资源短缺文案，语义与改动前一致。
 fact.source_reason=String(f.get("source_reason",""))
 for key in FACT_DISPLAY_FIELDS:
  if f.has(key): fact[key]=f[key]
 # 组名（显示侧按组取事实的键面）与显示点身份（形状键）都只在这里写一次。
 fact.group=String(f.get("group","action"))
 fact.key=shape_key(fact.payload)
 return fact

# 候选 detail 的唯一组装点（docs/ondemand-copy.md §1.5／§11.2）：eager 路径与候选只读入口共用，
# 追加顺序与原实现一致（锁定项圈改写 → 熟练牵扯 → 临时魔力抵扣）。
func _candidate_detail(base: String, payload: Dictionary, extra_traction: int, payment: Dictionary) -> String:
 var detail=base
 var lock_target=_equipment(payload.get("target",""))
 if Equipment.lock_only(lock_target):
  var unlock=payload.get("mode","")=="unlock" or (payload.kind=="item_use" and Tools.operation(_item(payload.item).get("type",""))=="unlock")
  if payload.kind!="manual" and not unlock: detail=Equipment.LOCK_ONLY_REASON
 if extra_traction>0: detail+="\n熟练而已：无论成败，额外牵扯%d次（每次按1能量，不扣能量）。" % extra_traction
 if payment.temporary_mana>0: detail+="\n临时魔力抵扣%s点，自身魔力支付%s点。" % [number(payment.temporary_mana),number(payment.mana)]
 return detail

# card 目标候选的基础文案（core/card_effects.gd 的 target_candidate／facts 原表达式），
# 供候选只读入口在 detail 缺失时按 payload 现算；其余组始终保持预生成 detail。
func _candidate_base_detail(payload: Dictionary) -> String:
 return Cards.target_detail(self,{"payload":payload})

# R5（docs/ondemand-copy.md §11.5）：本模块直呼点的文案 builder，正文留在本模块，路由只做分派。
static func copy_surrender(_g, _args: Dictionary) -> String:
 return "放弃战斗，被逮捕并进入收押处理。"

static func copy_item_discard(_g, _args: Dictionary) -> String:
 return "丢弃后无法取回。不消耗能量、魔力或回合。"

static func copy_status_toggle(_g, args: Dictionary) -> String:
 if args.has("power_name"): return ("开启" if args.enabled else "关闭")+args.power_name+"。不消耗能量或魔力。"
 return "每次触发消耗1层。" if bool(args.get("charge_all",false)) else "下一次触发使用全部蓄力。"

static func copy_rest_rare(_g, _args: Dictionary) -> String:
 return "剩余%d回合休息。" % (B.REST_TURNS-B.REST_CARD_TURNS.rare)

static func copy_rest_card(_g, args: Dictionary) -> String:
 return "从%d张%s卡中选一张，剩余%d回合休息。" % [int(args.get("count",0)),Cards.Rules.RARITIES[String(args.get("rarity","common"))],B.REST_TURNS-int(args.get("turns",0))]

static func copy_rest_flask(_g, _args: Dictionary) -> String:
 return "剩余%d回合用于休息，不改变自身魔力。" % (B.REST_TURNS-B.REST_FLASK_TURNS)

static func copy_rest_begin(_g, args: Dictionary) -> String:
 return "保留%d回合休息时间。" % int(args.get("left",0))

static func copy_end_climax(_g, args: Dictionary) -> String:
 return "身体暂时使不上力，剩余行动已跳过。"+("敌人仍按原定行动执行。" if bool(args.get("battle",false)) and bool(args.get("first",false)) else "")+"下一玩家回合按累计乏力恢复能量。"+("若持续无法行动，也可以投降进入牢房。" if bool(args.get("battle",false)) else "")

static func copy_retain(_g, _args: Dictionary) -> String:
 return "保留到下一玩家回合结束。"

static func copy_retain_skip(_g, args: Dictionary) -> String:
 return "保留已选手牌，不再选择。"+("随后抽1张。" if int(args.get("draw_after",0))>0 else "继续行动。")

static func copy_reward_item(_g, _args: Dictionary) -> String:
 return "收入道具栏；本事件不会进入整理道具。"

static func copy_reward_item_skip(_g, _args: Dictionary) -> String:
 return "未领取的道具将被放弃；直接返回塔路，不进入整备或整理道具。"

static func copy_reward_flask(_g, _args: Dictionary) -> String:
 return "全部存入贴身魔瓶，不占用存入次数。"

static func copy_reward_other(_g, args: Dictionary) -> String:
 return "收入道具栏。" if String(args.get("category",""))=="item" else Relics.TYPES[String(args.get("type",""))].detail

static func copy_reward_relic(_g, args: Dictionary) -> String:
 return Relics.TYPES[String(args.get("type",""))].detail

static func copy_reward_skip_category(_g, args: Dictionary) -> String:
 return "放弃本次"+("卡牌" if String(args.get("category",""))=="card" else "遗物")+"奖励，其他奖励仍可领取。"

static func copy_reward_skip(_g, _args: Dictionary) -> String:
 return "未领取的奖励将被放弃。"

static func copy_travel_step(_g, args: Dictionary) -> String:
 return "沿已选路线前进，不抽牌、不恢复资源；本段剩余%d回合。" % int(args.get("remaining",0))

static func copy_finish_pack(_g, _args: Dictionary) -> String:
 return "只携带容量允许的随身道具。"

static func copy_calm(g, args: Dictionary) -> String:
 return "快感－%s，下回合能量＋%d。本回合剩余%d／%d次。" % [g.number(float(args.get("reduction",0.0))),B.CALM_NEXT_ENERGY,int(args.get("remaining",0)),B.CALM_USES_PER_TURN]

static func copy_end_turn(g, args: Dictionary) -> String:
 return ("保留手牌。" if bool(args.get("keep_hand",false)) else "弃置未保留手牌。")+("敌人按原定行动执行。" if bool(args.get("battle",false)) and bool(args.get("first",false)) else "")

static func copy_finish_prepare(_g, _args: Dictionary) -> String:
 return "放弃剩余整备回合，不获得额外资源。"

static func copy_finish_rest(_g, _args: Dictionary) -> String:
 return "放弃剩余休息回合，固定工具留在房间。"

static func copy_wall_move(_g, args: Dictionary) -> String:
 return "移动%d格；%s。" % [int(args.get("distance",0)),String(args.get("result",""))]

static func copy_posture(g, args: Dictionary) -> String:
 return ("眼罩使站起额外消耗1能量。" if bool(args.get("blind_cost",false)) else "")+RelicEffects.posture_detail(g,String(args.get("dest","")))+String(args.get("bind_detail",""))

static func copy_posture_wall(g, args: Dictionary) -> String:
 return String(args.get("support",""))+"，额外减1能量；本回合仍可继续行动。"+("眼罩使站起额外消耗1能量。" if bool(args.get("blind_cost",false)) else "")+String(args.get("bind_detail",""))

# 攻击候选的正文：参数带完整 payload 与展示伤害，其余按当前 state 只读现算。
static func copy_attack(g, args: Dictionary) -> String:
 var payload=args.get("payload",{})
 var type=String(payload.get("type",""))
 var spec=BasicAttacks.forms(g,type)[int(payload.get("form",0))]
 var e=g._enemy(String(payload.get("enemy","")))
 var all_targets=bool(payload.get("all",false))
 var damage=float(payload.get("damage",0.0))
 var shown_damage=float(args.get("shown_damage",0.0))
 var damage_type=String(payload.get("damage_type",""))
 var interrupt=bool(payload.get("interrupt",false))
 var cooldown_turns=int(payload.get("cooldown_turns",0))
 var usage=BasicAttacks.usage(g,type)
 var detail="对%s造成%s点伤害%s。" % ["全部敌人" if all_targets else e.name,g.number(damage if all_targets else shown_damage),"，共%d次" % spec.hits if spec.hits>1 else ""]
 detail+=BasicAttacks.cost_description(type)
 if spec.get("x_cost",false): detail+="耗尽剩余能量X，X至少为1；连续踢X＋1次，X≥3时攻击后躺下。"
 if Cards.attack_ignores_restraints(g,type): detail+="本次体术按自由态发动，忽略拘束限制与减益。"
 var hard_targets=g.state.enemies.filter(func(enemy):return not enemy.gone and (all_targets or enemy.id==e.id) and Enemies.TYPES[enemy.type].get("mechanical",false))
 if damage_type not in ["magic","fixed"] and not hard_targets.is_empty(): detail+="坚硬：机械敌人受到的非魔法伤害减少%s%%。" % g.number((1.0-Enemies.damage_multiplier(g,hard_targets[0].type,damage_type))*100)
 if interrupt: detail+="将尚未执行的意图延后一回合。"
 if cooldown_turns>0: detail+="与坐姿踢击、并腿踢击共用%d回合冷却。" % (cooldown_turns+1)
 if usage.limit>0: detail+="本回合剩余%d／%d次。" % [usage.remaining,usage.limit]
 if type=="fireball":
  detail+=("无尽魔法少女战神：无视手部拘束，获得手势加成。" if Cards.basic_attack_freedom(g) else ("秘密武器：脚趾代替手部，获得手势加成。" if g.physical_hand_cast_reason()!="" else "满足手部条件，获得手势加成。")) if BasicAttacks.fireball_gesture(g) else ("火焰精通：无视身体施法限制，不获得手势加成。" if Cards.spell_power(g,type).get("disable_gesture",false) else g.hand_cast_reason()+"目前只使用咏唱威力。")
 return detail

static func copy_attack_release(g, args: Dictionary) -> String:
 var usage=BasicAttacks.usage(g,"fireball")
 return "对%s造成%s点魔法伤害。本回合剩余%d／%d次。" % [String(args.get("target_name","")),g.number(float(args.get("damage",0.0))),usage.remaining,usage.limit]+BasicAttacks.cost_description("fireball")

static func copy_manual_collar(_g, _args: Dictionary) -> String:
 return "取下已开锁的限制项圈，花费1能量。"

static func copy_manual_release(g, args: Dictionary) -> String:
 return "%s：耐久 %s → %s。" % [String(args.get("name","")),g.number(float(args.get("durability",0.0))),g.number(float(args.get("after",0.0)))]

static func copy_manual_retrieve(_g, args: Dictionary) -> String:
 return "取出"+String(args.get("name",""))+"；花费1能量，不使用挣扎或滑脱牌。"

static func copy_hook(g, args: Dictionary) -> String:
 return "耐久%s → %s；%s消耗1次挂钩，不耗能量。" % [g.number(float(args.get("durability",0.0))),g.number(float(args.get("after",0.0))),"仅削减连接耐久，原装备紧度不变；" if bool(args.get("parent",false)) else "降低一档；"]

static func copy_item_escape(_g, args: Dictionary) -> String:
 var grip="由触手朋友协助撕开。" if bool(args.get("assisted",false)) else "任意姿态可用，需要手指或脚趾任一部位自由。"
 return "消耗此符，不耗能量或魔力；"+grip+"进入监狱出发点，仍需通过出口警卫战；使用后剩余道具须符合容量。"

static func copy_item_unlock(_g, _args: Dictionary) -> String:
 return "解除一把锁，不改变耐久或紧度；消耗1次开锁针，不耗能量。"

static func copy_item_door_lock(_g, _args: Dictionary) -> String:
 return "消耗1次开锁针，不耗能量；离开牢房仍须满足行动速度。"

static func copy_item_cut(g, args: Dictionary) -> String:
 return "固定减少%s耐久，不受紧度和锁减伤影响；消耗1次工具。" % g.number(float(args.get("damage",0.0))*float(args.get("multiplier",1.0)))

static func copy_item_install(g, args: Dictionary) -> String:
 var operators=args.get("operators",[])
 return Tools.contact_text(g,String(args.get("mount","")))+("" if operators.is_empty() else "；可用部位："+"／".join(operators.map(func(op):return Tools.OPERATOR_NAMES[op])))

static func copy_item_retrieve(_g, args: Dictionary) -> String:
 var operators=args.get("operators",[])
 return "取回后保留剩余次数"+("" if operators.is_empty() else "；可用部位："+"／".join(operators.map(func(op):return Tools.OPERATOR_NAMES[op])))

static func copy_depart(g, args: Dictionary) -> String:
 var room=g.room_data(String(args.get("room_id","")))
 var detail="%s · 路程需要%d回合。\n%s" % [String(args.get("mode","")),int(args.get("turns",0)),g.room_description(room)]
 if String(args.get("phase","")) in ["prepare","rest"]: detail+="\n离开时结束剩余整备回合。" if String(args.get("phase",""))=="prepare" else "\n离开时结束剩余休息回合。"
 if bool(args.get("tower_start",false)): detail="选择此区域作为出狱起点，不消耗回合。\n"+g.room_description(room)
 return detail

# 候选 detail 的只读入口（docs/ondemand-copy.md §1.5／§2）：当前 View 的候选逐字节等于投影值。
# 陈旧候选允许按当前 state 重算（§2）；不写 state、不推进随机、不改 version、不产生日志与事件。
func candidate_detail(candidate: Dictionary) -> String:
 if candidate.has("detail"): return String(candidate.detail)
 var payload=candidate.get("payload",{})
 if payload.get("kind","")!="card": return ""
 return _candidate_detail(_candidate_base_detail(payload),payload,Cards.magic_card_traction(self,payload),_mana_payment(payload,float(candidate.get("mana",0.0))))

# 全部指令显示事实的唯一来源（docs/spec/candidate-removal.md §2.1 T5／T8；批 R5）：按阶段／域产出显示点事实。
# 投影与接管选择经 command_facts 取本列表；command_fact 已接线 kind 经 _kind_facts 调该生产者，未接线 kind 仍走本函数。行载体已删除，无第二份物化。
func _fact_source() -> Array:
 var facts: Array=[]
 if not state.relic_bundle.is_empty():
  facts.append_array(RelicBundle.facts(self))
  facts.append_array(Consumables.noncombat_facts(self,facts))
  facts.append_array(ManaFlask.facts(self,true))
  return facts
 if state.phase=="departure":
  facts.append_array(Departure.facts(self))
  facts.append_array(Consumables.noncombat_facts(self,facts))
  facts.append_array(ManaFlask.facts(self,true))
  return facts
 if not command_domain_ready(): return facts
 facts.append_array(_phase_facts())
 facts.append_array(Consumables.noncombat_facts(self,facts))
 facts.append_array(_route_facts(facts))
 var surrender=surrender_fact()
 if not surrender.is_empty(): facts.append(surrender)
 facts.append_array(item_discard_facts())
 facts.append_array(ManaFlask.facts(self))
 facts.append_array(RelicEffects.facts(self))
 facts.append_array(_status_toggle_facts())
 return facts

# 状态开关（蓄力切换＋可切换能力）：显示事实的唯一来源；_fact_source 与 command_fact 共用。
func _status_toggle_facts() -> Array:
 var facts=Cards.toggle_facts(self)
 if state.charge>0 and not state.overloaded and state.phase not in ["cleared","prison_end"]:
  var toggle_args={"charge_all":state.charge_all}
  facts.append(_fact({"kind":"status_toggle","status":"charge","enabled":not state.charge_all},"切换为普通蓄力" if state.charge_all else "切换为全量蓄力",{"kind":"game.status_toggle","args":toggle_args,"fallback":copy_status_toggle(self,toggle_args)},0,0.0,"","","status_toggle"))
 return facts

# 投影事实（唯一出口，T8）：事实源 → 唯一判定与 detail 组装（display_fact）→ 接管标注（唯一选择结果）。
# core/game_view.gd::build 的 view.display_facts 来自本列表；command_fact 经 kind 调该生产者，不经本列表。
func command_facts() -> Array:
 # 读取批次：事实源与投影只在一个批次内物化一次（与改动前的候选表读取同一批次语义）。
 var previous=_begin_equipment_read()
 var facts: Array=[]
 for f in _fact_source(): facts.append(display_fact(f))
 var result=FirstTurnControl.select(self,facts)
 _equipment_read=previous
 return result

# 全量卡面文案的只读入口（docs/ondemand-copy.md §1.3）：输入 [{type,uid}]，逐项按 §1.1 现算，容器全部新建。
func live_card_text_set(cards: Array) -> Dictionary:
 var texts={}
 var instances={}
 for row in cards:
  var type=String(row.get("type",""))
  if not Cards.Rules.SPECS.has(type): continue
  var uid=String(row.get("uid",""))
  if not texts.has(type): texts[type]=Cards.text_entry(self,type)
  if uid!="" and not instances.has(uid): instances[uid]=Cards.text_entry(self,type,uid)
 return {"texts":texts,"instances":instances}

# 单条卡面文案的只读入口（docs/ondemand-copy.md §1.4）：任意注册牌型现算一条，返回全新容器。
# 不写 state、不推进随机、不改 version、不产生日志与事件（§2 共同语义）。
func live_card_text(type: String, uid: String = "") -> Dictionary:
 return Cards.text_entry(self,type,uid)

# 阶段与行动显示事实（command_facts 的阶段分支）：早退分支与改动前的行路径逐条对应。
func _phase_facts() -> Array:
 var out: Array = []
 if state.phase=="rest_choice":
  out.append(_fact({"kind":"rest_rare"},"随机获得1张稀有卡 · 扣除%d回合" % B.REST_CARD_TURNS.rare,{"kind":"game.rest_rare","args":{},"fallback":copy_rest_rare(self,{})},0,0.0,"休息回合不足。" if state.rest_left<B.REST_CARD_TURNS.rare else "","","rest_service"))
  for type in state.rest_cards:
   var rarity=Cards.Rules.SPECS[type].rarity
   var turns=B.REST_CARD_TURNS[rarity]
   var rest_args={"count":state.rest_cards.size(),"rarity":rarity,"turns":turns}
   out.append(_fact({"kind":"rest_card","type":type},"领取「"+B.CARD_NAMES[type]+"」 · 扣除%d回合" % turns,{"kind":"game.rest_card","args":rest_args,"fallback":copy_rest_card(self,rest_args)},0,0.0,"休息回合不足。" if state.rest_left<turns else "","","rest_service"))
  out.append(_fact({"kind":"rest_flask"},"魔瓶补充%d魔力 · 扣除%d回合" % [B.REST_FLASK_MANA,B.REST_FLASK_TURNS],{"kind":"game.rest_flask","args":{},"fallback":copy_rest_flask(self,{})},0,0.0,"休息回合不足。" if state.rest_left<B.REST_FLASK_TURNS else "","","rest_service"))
  var begin_args={"left":state.rest_left}
  out.append(_fact({"kind":"rest_begin"},"跳过奖励，直接休息",{"kind":"game.rest_begin","args":begin_args,"fallback":copy_rest_begin(self,begin_args)},0,0.0,"","","rest_service"))
  return out
 if state.phase in ["shop","treasure"]:
  return Services.facts(self)
 if state.phase=="event":
  return Events.facts(self)
 if state.phase in ["captured","inspection"]:
  return Prison.facts(self)
 if state.phase=="prison_end": return out
 if state.overloaded and state.phase in RelicEffects.COMBAT_PHASES:
  var climax_args={"battle":state.phase=="battle","first":state.order=="first"}
  out.append(_fact({"kind":"end"},"继续 · 高潮后缓一缓",{"kind":"game.end_climax","args":climax_args,"fallback":copy_end_climax(self,climax_args)},0,0.0,"","","flow"))
  return out
 if not state.card_chain.is_empty():
  return Cards.chain_display_facts(self)
 if state.pending_retain:
  return retain_facts()
 if state.phase == "reward":
  if Events.active_item_rewards(self):
   for row in Events.item_reward_rows(self):
    if row.claimed: continue
    var full_reason="随身道具栏已满，无法拾取这件道具。" if carried_items()>=item_capacity() else ""
    out.append(_fact({"kind":"reward","category":"item","type":row.type,"reward_id":row.id},"领取「"+Tools.TYPES[row.type].name+"」",{"kind":"game.reward_item","args":{},"fallback":copy_reward_item(self,{})},0,0.0,full_reason,"","reward"))
   out.append(_fact({"kind":"reward","type":"skip"},"继续",{"kind":"game.reward_item_skip","args":{},"fallback":copy_reward_item_skip(self,{})},0,0.0,"","","reward"))
   return out
  if not state.reward_claimed.has("card"):
   for type in state.reward_options:
    out.append(_fact({"kind":"reward","category":"card","type":type},"选择「"+B.CARD_NAMES[type]+"」",{"kind":"card.two_face","args":{"type":type},"fallback":CopyRouter.two_face(self,type)},0,0.0,"","","reward"))
  if state.battle_flask_drop>0 and not state.reward_claimed.has("flask"):
   out.append(_fact({"kind":"reward","category":"flask","type":"boss_mana"},"领取%d魔瓶魔力" % state.battle_flask_drop,{"kind":"game.reward_flask","args":{},"fallback":copy_reward_flask(self,{})},0,0.0,"","","reward"))
  for category in ["item","relic"]:
   var type=state.battle_item_drop if category=="item" else state.battle_relic_drop
   if type=="" or state.reward_claimed.has(category): continue
   var title=Tools.TYPES[type].name if category=="item" else Relics.TYPES[type].name
   var other_args={"category":category,"type":type}
   out.append(_fact({"kind":"reward","category":category,"type":type},"领取「"+title+"」",{"kind":"game.reward_other","args":other_args,"fallback":copy_reward_other(self,other_args)},0,0.0,"","","reward"))
  if not state.reward_claimed.has("relic"):
   for type in state.boss_relic_options:
    out.append(_fact({"kind":"reward","category":"relic","type":type},"选择「"+Relics.TYPES[type].name+"」",{"kind":"game.reward_relic","args":{"type":type},"fallback":copy_reward_relic(self,{"type":type})},0,0.0,RelicEffects.gain_reason(self,type),"","reward"))
  for category in ["card","relic"]:
   var offered=not state.reward_options.is_empty() if category=="card" else (state.battle_relic_drop!="" or not state.boss_relic_options.is_empty())
   if offered and not state.reward_claimed.has(category):
    out.append(_fact({"kind":"reward_skip","category":category},"跳过",{"kind":"game.reward_skip_category","args":{"category":category},"fallback":copy_reward_skip_category(self,{"category":category})},0,0.0,"","","reward"))
  out.append(_fact({"kind":"reward","type":"skip"},"继续",{"kind":"game.reward_skip","args":{},"fallback":copy_reward_skip(self,{})},0,0.0,"","","reward"))
  return out
 if state.phase == "map": return out
 if state.phase == "travel":
  var step_args={"remaining":state.journey.remaining}
  out.append(_fact({"kind":"travel_step"},"继续前进 · 1回合",{"kind":"game.travel_step","args":step_args,"fallback":copy_travel_step(self,step_args)},0,0.0,travel_route_reason(),SlipMotion.hint(),"route"))
  return out
 if state.phase == "cleared":
  return DemoExit.facts(self)
 if state.phase == "pack":
  out.append_array(item_action_facts())
  out.append_array(flow_facts())
  return out
 out.append_array(wall_move_facts())
 out.append_array(posture_facts())
 out.append_array(attack_facts())
 out.append_array(equipment_spell_facts())
 for card in state.hand: out.append_array(Cards.card_facts(self,card))
 out.append_array(manual_facts())
 out.append_array(item_action_facts())
 if state.phase=="rest": out.append_array(hook_facts())
 if state.phase=="prison": out.append_array(Prison.facts(self))
 out.append_array(flow_facts())
 return out

# Position is saved once per encounter; previews only read it.
func _initial_wall_distance(battle: bool) -> int:
 return 1+_random_index("position",4) if battle and state.wall!="none" else 0

func at_wall() -> bool:
 return wall_contact() or relic_value("always_wall")>0

func wall_contact() -> bool:
 return state.wall!="none" and state.wall_distance==0

func wall_movement_profile() -> Dictionary:
 var turns=movement_profile().turns
 return {"distance":2 if turns<=2 else 1,"cost":1 if turns==1 else (2 if turns<=3 else 3)}

func wall_view() -> Dictionary:
 var profile=wall_movement_profile()
 var name={"rough":"粗糙墙面","normal":"普通墙面","none":"无可用墙面"}[state.wall]
 var status="已贴墙" if at_wall() else "距墙%d格" % state.wall_distance
 var detail="贴墙后才能借墙起身、安装、使用或取回墙上工具。"
 if at_wall(): detail="可借墙起身，少花1能量，仍可继续行动；墙上工具还需满足姿态和手足条件。"
 if state.wall=="rough": detail+="贴墙站／坐时，主动挣扎或滑脱额外造成%s点真实伤害；躺姿不生效。" % number(B.WALL_BONUS)
 if state.wall=="none": status="无墙";detail="途中没有可用墙面。"
 var sources=state.relics.filter(func(id):return RelicEffects.definition(self,id).modifiers.get("always_wall",0)>0)
 var source="当前位于墙边"
 var duration="离开墙边后解除"
 if not sources.is_empty():
  source="、".join(sources.map(func(id):return RelicEffects.definition(self,id).name));duration="持有遗物期间持续生效"
  status="视为贴墙"
  detail=source+"提供持续支撑：始终视为贴墙，可用贴墙起身并免于探索移动摔倒。实际距墙不变，墙上工具与挂钩仍需走到对应位置。"
  if state.wall=="rough": detail+="站／坐时，主动挣扎或滑脱额外造成%s点真实伤害；躺姿不生效。" % number(B.WALL_BONUS)
 var environment_class=Tools.Environments.WALLS.get(state.wall,"")
 return {"environment_class":environment_class,"environment_name":Tools.Environments.NAMES.get(environment_class,""),"at_wall":at_wall(),"distance":state.wall_distance,"stride":profile.distance,"cost":profile.cost,"status":status,"name":name,"detail":detail,"source":source,"duration":duration}

# ==== 显示事实的唯一来源（docs/spec/candidate-removal.md §2.1 T5／T8；批 R3）====
# 事实＝显示点的指令形状＋行参数（cost／mana／reason／risk）＋显示字段（brief／brief_tags／casting／body_part）。
# 投影显示事实（display_fact）是事实的唯一出口：同一份事实与同一判定，同一形状只有一条路径。
# 键面：payload／label／copy／cost／mana／reason／risk／group／brief／brief_tags／casting／body_part／verdict（可选）。

# 基础行动块（墙面／姿态／攻击／装备法术／底栏）的产出条件（唯一来源）：这些阶段或状态不产出基础行动行。
const BASE_ABSENT_PHASES=["rest_choice","shop","treasure","reward","map","travel","cleared","pack"]

func base_action_block() -> bool:
 if not state.relic_bundle.is_empty() or state.phase=="departure" or state.phase in BASE_ABSENT_PHASES: return false
 return Binding.state_issue(self)=="" and SpecialEquipment.validate(state.get("special_equipment"))==""

# 攻击事实的显示字段（原 core/game_view.gd::build 的投影表达式，批 R3 随事实来源迁移）：施法投影＋部位。
func _attack_fact_display(f: Dictionary) -> Dictionary:
 var type=String(f.payload.get("type",""))
 if Cards.Rules.FIXED_MAGIC.has(type): f["casting"]=cast_view(Cards.cast_profile(self,type,float(f.get("mana",0.0))>0))
 f["body_part"]={"strike":"双臂","heavy":"双臂／双腿","kick":"双腿"}.get(type,"")
 if f.has("casting"):
  var part=f.casting.get("source_part",f.casting.part)
  f["body_part"]="脚趾" if part=="toes" else Cards.Rules.CAST_PART_NAMES[part]
 return f

# 墙面移动（墙面域）：显示事实的唯一来源。
func wall_move_facts() -> Array:
 var facts=[]
 if not base_action_block(): return facts
 if state.wall=="none" or state.phase not in ["battle","prepare","rest","prison"]: return facts
 if state.phase=="prison" and occupied("eyes"): return facts
 var profile=wall_movement_profile()
 for direction in ["toward","away"]:
  var distance=mini(profile.distance,state.wall_distance if direction=="toward" else 4-state.wall_distance)
  if state.phase=="prison": distance=mini(profile.distance,Prison.Space.wall_path(self,direction=="toward").size())
  var reason="" if distance>0 else ("已经贴墙。" if direction=="toward" else "已到房间可移动的最远处。")
  if CaptureBind.has_bind(self): reason=CaptureBind.movement_reason(self)
  var after=state.wall_distance+distance*(-1 if direction=="toward" else 1)
  if state.phase=="prison" and distance>0: after=Prison.Space.wall_distance(Prison.Space.wall_path(self,direction=="toward")[distance-1])
  var label="靠近墙面" if direction=="toward" else "离开墙面"
  var result="到达墙边，获得贴墙" if after==0 else "距墙%d格，不能借用墙面" % after
  if after>0 and relic_value("always_wall")>0: result="距墙%d格，遗物仍提供贴墙效果" % after
  var move_args={"distance":distance,"result":result}
  facts.append(_fact({"kind":"wall_move","direction":direction,"distance":distance,"after":after},label,{"kind":"game.wall_move","args":move_args,"fallback":copy_wall_move(self,move_args)},profile.cost,0.0,reason,SlipMotion.hint(),"wall_move"))
 return facts

# 姿态（姿态域）：显示事实的唯一来源。
func posture_facts() -> Array:
 var facts=[]
 if not base_action_block(): return facts
 for dest in ["stand","sit","lie"]:
  var current_index = ["stand","sit","lie"].find(state.posture)
  var dest_index = ["stand","sit","lie"].find(dest)
  var reason = ""
  if current_index == dest_index: reason = "当前已经是"+B.POSE_NAMES[dest]+"。"
  elif absi(current_index-dest_index) != 1: reason = "姿态必须依次经过坐姿，不能直接跨越。"
  var key = str(state.posture)+">"+dest
  if reason=="": reason=CaptureBind.posture_reason(self,dest)
  var cost_index = {"stand>sit":0,"sit>stand":1,"sit>lie":2,"lie>sit":3}.get(key,0)
  var cost = maxi(0,B.POSTURE_COSTS[level("legs")][cost_index]-(1 if level("arms")<=1 else 0)-RelicEffects.posture_discount(self,dest))
  var blind_cost=1 if key=="sit>stand" and occupied("eyes") else 0
  cost+=blind_cost
  var bind_detail="捕缚进度＋10。" if reason=="" and CaptureBind.has_bind(self,"guard") else ""
  var posture_args={"dest":dest,"blind_cost":blind_cost,"bind_detail":bind_detail}
  facts.append(_fact({"kind":"posture","dest":dest,"wall":false,"adjacent":reason==""},"转为"+B.POSE_NAMES[dest],{"kind":"game.posture","args":posture_args,"fallback":copy_posture(self,posture_args)},cost,0.0,reason,"","posture"))
  if reason=="" and key in ["sit>stand","lie>sit"] and state.phase in ["battle","prepare","rest","prison"] and at_wall():
   var support="借墙起身" if wall_contact() else "借助遗物支撑起身"
   var wall_posture_args={"support":support,"blind_cost":blind_cost,"bind_detail":bind_detail}
   facts.append(_fact({"kind":"posture","dest":dest,"wall":true,"adjacent":true},"贴墙站起" if dest=="stand" else "贴墙坐起",{"kind":"game.posture_wall","args":wall_posture_args,"fallback":copy_posture_wall(self,wall_posture_args)},maxi(0,cost-blind_cost-1)+blind_cost,0.0,"","","posture"))
 return facts

# 底栏（flow 组）与深呼吸（pressure 组）：显示事实的唯一来源；产出顺序与改动前一致。
func flow_facts() -> Array:
 var facts=[]
 if state.phase=="pack":
  facts.append(_fact({"kind":"finish_pack"},"整理完成，离开房间",{"kind":"game.finish_pack","args":{},"fallback":copy_finish_pack(self,{})},0,0.0,"请使用或放下超出容量的道具。" if carried_items()>item_capacity() else "","","flow"))
  return facts
 if not base_action_block(): return facts
 var calm=Pressure.calm(self)
 var calm_args={"reduction":calm.reduction,"remaining":calm.remaining}
 var calm_fact=_fact({"kind":"calm"},"深呼吸",{"kind":"game.calm","args":calm_args,"fallback":copy_calm(self,calm_args)},B.CALM_COST,0.0,calm.reason if calm.reason!="" else ("当前快感已经降到最低。" if state.pressure<=0 else ""),"","pressure")
 calm_fact.body_part="嘴部"
 calm_fact.brief="快感－%s" % number(calm.reduction)
 calm_fact.brief_tags="下回合＋%d能量 · %d/%d次" % [B.CALM_NEXT_ENERGY,calm.remaining,B.CALM_USES_PER_TURN]
 facts.append(calm_fact)
 var turn_args={"keep_hand":relic_value("keep_hand")>0,"battle":state.phase=="battle","first":state.order=="first"}
 facts.append(_fact({"kind":"end"},"结束回合",{"kind":"game.end_turn","args":turn_args,"fallback":copy_end_turn(self,turn_args)},0,0.0,"","","flow"))
 if state.phase == "prepare":
  facts.append(_fact({"kind":"finish_prepare"},"提前结束整备",{"kind":"game.finish_prepare","args":{},"fallback":copy_finish_prepare(self,{})},0,0.0,"","","flow"))
 if state.phase=="rest":
  facts.append(_fact({"kind":"finish_rest"},"提前离开休息房",{"kind":"game.finish_rest","args":{},"fallback":copy_finish_rest(self,{})},0,0.0,"","","flow"))
 return facts

# 投降（底栏）：条件与文案的唯一来源（行与显示事实共用）。
func surrender_fact() -> Dictionary:
 if state.phase!="battle" or not state.enemies.any(func(enemy):return not enemy.gone): return {}
 return _fact({"kind":"surrender"},"投降",{"kind":"game.surrender","args":{},"fallback":copy_surrender(self,{})},0,0.0,"","","surrender")

func change_posture(destination: String, support: String="") -> void:
 state.posture=destination
 _emit("event",support+"你转为"+B.POSE_NAMES[destination]+"。")
 if CaptureBind.has_bind(self,"guard"): CaptureBind.gain_bind(self,CaptureBind.BIND_GAIN,"姿态切换")
 Pressure.tick(self,"posture")

func kick_profile(variant: Dictionary={}) -> Dictionary:
 var freedom=Cards.basic_attack_freedom(self)
 var posture=BasicAttacks.posture(self,"kick",variant)
 var bound=variant.get("kick_bound",false) if freedom else (_bound_feet() and not Cards.action_ignores_restraints(self))
 var leg_level=0 if freedom or Cards.action_ignores_restraints(self) else level("legs")
 var label=("并拢飞踢" if posture=="stand" else "并腿蹬击") if bound else (BasicAttacks.TYPES.kick[0].name if posture=="stand" else "坐姿踢击")
 var base_damage=(B.BOUND_KICK if posture=="stand" else B.BOUND_SEATED_KICK) if bound else (B.KICK if posture=="stand" else B.SEATED_KICK)
 var damage=BasicAttacks.physical_damage(self,base_damage,leg_level)
 var reason="躺姿没有体术攻击，请施法或起身。" if posture=="lie" else ("腿部活动受限达到三级，无法独立踢击。" if not bound and leg_level>=3 else "")
 var spec=BasicAttacks.TYPES.kick[0]
 var cost=spec.bound_cost if bound else (spec.cost if posture=="stand" else spec.seated_cost)
 var justice=not bound and posture=="stand"
 var infused_justice=justice and "hannya_justice" in state.card_buffs
 if infused_justice: cost+=1
 if justice and leg_level>BasicAttacks.TYPES.kick[2].postures.stand.max_level: reason="正义飞踢需要双腿活动自由。"
 return {"label":label,"cost":cost,"damage":damage,"reason":reason,"fall":bound,"interrupt":infused_justice or (not justice and (posture=="stand" or not bound)),"cooldown_turns":0 if justice and not infused_justice else spec.cooldown_turns}

# 基础攻击（行动域）：显示事实的唯一来源。角色2（巫女）的攻击事实由 core/witch_character.gd::attack_facts 给出。
func attack_facts() -> Array:
 var facts=[]
 if not base_action_block() or state.phase!="battle": return facts
 if Character.active(self): return Character.attack_facts(self)
 for e in state.enemies:
  if e.gone: continue
  for type in BasicAttacks.TYPES:
   for form in range(BasicAttacks.forms(self,type).size()):
    facts.append(_attack_offer_fact(e,type,form))
 return facts

func _attack_offer_fact(e: Dictionary, type: String, form: int) -> Dictionary:
 var spec=BasicAttacks.forms(self,type)[form]
 var freedom=Cards.basic_attack_freedom(self)
 var posture=BasicAttacks.posture(self,type,spec)
 var leg_level=0 if freedom or Cards.action_ignores_restraints(self) else level("legs")
 var cost=BasicAttacks.energy_cost(self,type,form)
 var reason=""
 var mana=0.0
 var damage=0.0
 var label=spec.name
 var risk=""
 var interrupt=false
 var fall=false
 var all_targets=spec.get("all",false)
 var cooldown_turns=0
 match type:
  "strike","heavy":
   var ignore_restraints=Cards.attack_ignores_restraints(self,type)
   var arm_level=0 if ignore_restraints else level("arms")
   damage=BasicAttacks.physical_damage(self,spec.damage+Cards.Hannya.heavy_bonus(self,type,form),arm_level)
   if posture!="stand": reason=label+"需要站姿。"
   elif arm_level>=3: reason="双臂活动受限达到三级，无法完成"+label+"。"
   elif type=="heavy" and not ignore_restraints and level("legs")!=0: reason="近身短打需要双腿活动自由。"
   elif type=="heavy" and state.heavy_used: reason="本回合已使用近身短打。"
  "kick":
   if spec.has("postures"):
    var posture_spec=spec.postures.get(posture,spec.postures.values()[0])
    label=posture_spec.name
    damage=BasicAttacks.physical_damage(self,posture_spec.damage,leg_level)
    if not spec.postures.has(posture): reason="踢击需要站姿或坐姿。" if spec.postures.size()>1 else "连续踢需要坐姿。"
    elif leg_level>posture_spec.max_level: reason="站着踢需要双腿活动自由。" if posture=="stand" else "腿部严密度达到4级，无法坐着踢。"
    if spec.get("x_cost",false):
     fall=cost>=spec.fall_energy
     if reason=="" and cost<1: reason="连续踢至少需要1点能量。"
   elif all_targets:
    damage=BasicAttacks.physical_damage(self,spec.damage,leg_level)
    if posture!="stand": reason="横扫需要站姿。"
    elif not freedom and not Cards.action_ignores_restraints(self) and (_bound_feet() or leg_level>=3): reason="双腿无法独立活动，不能横扫。"
   else:
    var kick=kick_profile(spec)
    label=kick.label;cost=kick.cost;damage=kick.damage;fall=kick.fall;interrupt=kick.interrupt;reason=kick.reason
    cooldown_turns=kick.cooldown_turns
    if reason=="" and cooldown_turns>0 and BasicAttacks.kick_cooldown(self)>0: reason="踢击冷却中，还需%d回合。" % BasicAttacks.kick_cooldown(self)
   if reason=="" and fall and not freedom and CaptureBind.fixed_posture(self)!="": reason="捕缚将你固定为%s，无法在踢击后躺下，先解除捕缚。" % B.POSE_NAMES[CaptureBind.fixed_posture(self)]
   if fall and CaptureBind.fixed_posture(self)=="": risk="攻击后立即躺下。"
  "fireball":
   damage=BasicAttacks.fireball_damage(self)
   mana=_mana_cost(B.SPELL_COST)
   all_targets=Cards.spell_power(self,type).get("all_enemies",false)
 if type!="fireball":
  damage*=Cards.damage_multiplier(self,type)
  interrupt=interrupt or Cards.attack_interrupt(self,type)
 var attachment=Cards.physical_attachment(self,type)
 if not attachment.is_empty():
  damage*=attachment.multiplier
  mana=attachment.mana
  all_targets=true
 var usage=BasicAttacks.usage(self,type)
 if reason=="" and usage.limit>0 and usage.remaining<=0: reason="本回合"+label+"次数已用完。"
 if type!="fireball" and state.weakness_turns>0: reason="无力化：本回合不能使用基础攻击。"
 var damage_type="magic" if type=="fireball" else "physical"
 if reason=="": reason=Puppets.taunt_reason(self,e,all_targets)
 var shown_damage=damage*Enemies.damage_multiplier(self,e.type,damage_type)
 var attack_payload={"kind":"attack","type":type,"form":form,"hits":spec.hits,"all":all_targets,"enemy":e.id,"damage":damage,"damage_type":damage_type,"interrupt":interrupt,"fall":fall,"cooldown_turns":cooldown_turns}
 if spec.get("x_cost",false): attack_payload.x=cost
 if not attachment.is_empty(): attack_payload.mana_attachment=true
 var attack_args={"payload":attack_payload,"shown_damage":shown_damage}
 # Compact display uses the same target-adjusted damage as the detailed preview.
 var brief_damage=number(damage if all_targets else shown_damage)
 if brief_damage.contains("."): brief_damage=brief_damage.rstrip("0").rstrip(".")
 var tags=[]
 if all_targets: tags.append("全体")
 if interrupt: tags.append("打断")
 if fall and CaptureBind.fixed_posture(self)=="": tags.append("击后躺下")
 if usage.limit>0: tags.append("%d/%d次" % [usage.remaining,usage.limit])
 var fact=_attack_fact_display(_fact(attack_payload,label,{"kind":"game.attack","args":attack_args,"fallback":copy_attack(self,attack_args)},cost if spec.get("x_cost",false) else Cards.attack_cost(self,type,cost),mana,reason,risk,"attack"))
 fact.brief=brief_damage+(" × %d" % spec.hits if spec.hits>1 else "")+" 伤害"
 fact.brief_tags=" · ".join(tags)
 return fact

# 装备自解火球（行动域，非战斗阶段）：显示事实的唯一来源。
func equipment_spell_facts() -> Array:
 var facts=[]
 if not base_action_block(): return facts
 if Character.active(self): return facts
 var factor=float(Cards.spell_power(self,"fireball").get("equipment_damage_factor",0.0))
 if factor<=0.0: return facts
 var usage=BasicAttacks.usage(self,"fireball")
 for target in action_targets():
  var reason=""
  var definition=SpecialEquipment.DESIGNS[target.type] if SpecialEquipment.is_special(target) else Equipment.TEMPLATES[target.template]
  if not _outer(target): reason="先解除遮挡它的外层拘束具。"
  elif definition.get("damage_factor",1.0)==0.0: reason=target.name+"无法受到伤害。"
  elif usage.remaining<=0: reason="本回合火球术次数已用完。"
  var damage=BasicAttacks.fireball_damage(self)*factor
  var release_args={"target_name":target.name,"damage":damage}
  var fact=_attack_fact_display(_fact({"kind":"attack","type":"fireball","form":0,"hits":1,"all":false,"enemy":"","target":target.id,"damage":damage,"damage_type":"magic","interrupt":false,"fall":false},"火球术 · 自解",{"kind":"game.attack_release","args":release_args,"fallback":copy_attack_release(self,release_args)},Cards.attack_cost(self,"fireball",BasicAttacks.energy_cost(self,"fireball")),_mana_cost(B.SPELL_COST),reason,"","attack"))
  fact.brief=number(damage)+" 伤害"
  fact.brief_tags="%d/%d次" % [usage.remaining,usage.limit]
  facts.append(fact)
 return facts

# Reachable only on the default tail of _phase_facts (after the early returns).
func command_tail() -> bool:
 if not command_domain_ready(): return false
 if state.phase in ITEM_ABSENT_PHASES or state.phase=="pack": return false
 if state.overloaded and state.phase in RelicEffects.COMBAT_PHASES: return false
 if not state.card_chain.is_empty() or state.pending_retain: return false
 return true

# Chain facts exist only when _phase_facts reaches the chain return, before reward and the action tail.
func chain_rows_active() -> bool:
 if not command_domain_ready() or state.card_chain.is_empty(): return false
 if state.phase in ["rest_choice","shop","treasure","event","captured","inspection","prison_end"]: return false
 return not (state.overloaded and state.phase in RelicEffects.COMBAT_PHASES)

# 装备操作（装备域，批 R4 起、R5 收口）：显示事实的唯一来源（docs/spec/candidate-removal.md §2.1 T5／T8）。
func manual_facts() -> Array:
 var facts=[]
 if not command_tail(): return facts
 for target in equipment_targets():
  var reason=""
  var full=level("arms")==0
  if Equipment.lock_only(target):
   reason="先用开锁术或开锁工具打开限制项圈的锁。" if target.locked else ("双臂需要完全自由才能取下限制项圈。" if not full else "")
   facts.append(_fact({"kind":"manual","target":target.id,"after":0.0},"取下限制项圈",{"kind":"game.manual_collar","args":{},"fallback":copy_manual_collar(self,{})},1,0.0,reason,"","manual"))
   continue
  if not Equipment.allows(target,"manual"): reason=Equipment.TEMPLATES[target.template].name+"不能徒手快速解开。"
  elif occupied("wrist") or occupied("fingers"): reason="手腕需要自由，并且手指能精细操作。"
  elif target.locked: reason="目标已上锁，先开锁才能徒手松解。"
  else:
   reason=Tools.Contact.reason(self,target,"manual")
  var after=0.0 if full else lower_durability(target.durability,target.maximum)
  var release_args={"name":target.name,"durability":target.durability,"after":after}
  facts.append(_fact({"kind":"manual","target":target.id,"after":after},"快速解开" if full else "手动松解",{"kind":"game.manual_release","args":release_args,"fallback":copy_manual_release(self,release_args)},1,0.0,reason,"","manual"))
 for target in state.special_equipment:
  if not SpecialEquipment.allows(target,"manual"): continue
  var special_reason=SpecialEquipment.manual_reason(self,target)
  facts.append(_fact({"kind":"manual","target":target.id,"after":0.0},"直接取出",{"kind":"game.manual_retrieve","args":{"name":target.name},"fallback":copy_manual_retrieve(self,{"name":target.name})},1,0.0,special_reason,"","manual"))
 return facts

# 挂钩（装备域，批 R4 起、R5 收口）：显示事实的唯一来源；只在休息阶段产出。
func hook_facts() -> Array:
 var facts=[]
 if state.phase!="rest" or not command_tail(): return facts
 for target in action_targets():
  if SpecialEquipment.is_special(target): continue
  var reason=""
  if not wall_contact(): reason="需要先靠到墙边，才能使用挂钩。"
  elif state.hook_uses<=0: reason="悬挂挂钩的3次使用机会已经耗尽。"
  else:
   var contact=Tools.Contact.evaluate(self,target,{"points":Tools.height_points(self,Tools.HOOK_MOUNT)})
   reason="当前姿势下，"+Tools.target_parts(self,target)+"碰不到挂钩。" if contact.code=="out_of_reach" else contact.reason
  if reason=="": reason=_slip_reason(target,"hook")
  var after=lower_durability(target.durability,target.maximum)
  var hook_args={"name":_equipment_name(target),"durability":target.durability,"after":after,"parent":target.has("parent_id")}
  facts.append(_fact({"kind":"hook","target":target.id,"after":after},"挂钩 · "+_equipment_name(target),{"kind":"game.hook","args":hook_args,"fallback":copy_hook(self,hook_args)},0,0.0,reason,"","hook"))
 return facts

func item_capacity() -> int:
 return 3+int(state.departure.get("capacity_bonus",0))+int(relic_value("capacity"))-(1 if level("arms")>=3 or occupied("fingers") else 0)-(1 if level("legs")>=3 else 0)

func carried_items() -> int:
 return state.items.filter(func(i):return i.mount=="carry").size()

func _item(id: String) -> Dictionary:
 for item in state.items:
  if item.id==id: return item
 return {}

# 道具域（批 R4 起、R5 收口）：显示事实的唯一来源；pack 与默认可行动分支由本函数派生。
# 每件道具的可用操作（与执行分支的可用性一一对应）。item_id 非空时只产该件。
func item_action_facts(item_id: String="") -> Array:
 var facts=[]
 for item in state.items:
  if item_id!="" and item.id!=item_id: continue
  var spec=Tools.TYPES[item.type]
  if Tools.operation(item.type)=="buff":
   facts.append_array(Consumables.use_facts(self,item))
   continue
  if Tools.operation(item.type)=="escape":
   var escape_args={"assisted":Tools.assisted(self)}
   facts.append(_fact({"kind":"item_use","item":item.id,"target":"hero"},"撕开传送符，离开牢房",{"kind":"game.item_escape","args":escape_args,"fallback":copy_item_escape(self,escape_args)},0,0.0,Tools.escape_reason(self),"","item"))
   continue
  if Tools.operation(item.type)=="unlock":
   for target in action_targets():
    facts.append(_fact({"kind":"item_use","item":item.id,"target":target.id},"开锁 · "+_equipment_name(target),{"kind":"game.item_unlock","args":{},"fallback":copy_item_unlock(self,{})},0,0.0,Tools.unlock_reason(self,target),"","item"))
   if state.phase=="prison":
    var reason="牢门已经打开。" if state.prison.door_open else ("需要先到牢门前。" if not Tools.assisted(self) and not Prison.Space.at(self,"door") else Tools.unlock_reason(self))
    facts.append(_fact({"kind":"item_use","item":item.id,"target":"prison_door"},"打开牢门锁",{"kind":"game.item_door_lock","args":{},"fallback":copy_item_door_lock(self,{})},0,0.0,reason,"","item"))
   continue
  if item.mount=="carry" and Tools.is_fixed(self,item):
   continue
  if item.mount=="carry":
   for target in action_targets():
    if SpecialEquipment.is_special(target): continue
    var cut_reason="手指被拘束，不能握持工具直接切割。" if not Tools.assisted(self) and occupied("fingers") else ""
    if cut_reason=="": cut_reason=Tools.contact_reason(self,target,item)
    if cut_reason=="" and not spec.materials.has(target.material): cut_reason=spec.name+"不能切割"+Equipment.MATERIAL_NAMES[target.material]+"；请换用兼容的工具。"
    var cut_args={"damage":spec.damage,"multiplier":Cards.damage_multiplier(self,"equipment")}
    facts.append(_fact({"kind":"item_use","item":item.id,"target":target.id},"切割 · "+_equipment_name(target),{"kind":"game.item_cut","args":cut_args,"fallback":copy_item_cut(self,cut_args)},0,0.0,cut_reason,"","item"))
  if item.mount=="carry":
   for mount in Tools.HEIGHTS:
    var operators=Tools.install_operators(self,mount,item.type)
    var install_args={"mount":mount,"operators":operators}
    facts.append(_fact({"kind":"item_install","item":item.id,"mount":mount,"operator":operators[0] if not operators.is_empty() else ""},"安装到"+Tools.mount_label(mount),{"kind":"game.item_install","args":install_args,"fallback":copy_item_install(self,install_args)},1,0.0,Tools.install_reason(self,mount,item.type),"","item"))
  else:
   var operators=Tools.install_operators(self,item.mount,item.type)
   var retrieve_args={"operators":operators}
   facts.append(_fact({"kind":"item_retrieve","item":item.id,"mount":"carry","operator":operators[0] if not operators.is_empty() else ""},"取回工具",{"kind":"game.item_retrieve","args":retrieve_args,"fallback":copy_item_retrieve(self,retrieve_args)},0,0.0,Tools.retrieve_reason(self,item),"","item"))
 return facts

# 丢弃（道具域）：每件道具一条；守卫与 command_facts 的守卫（departure／relic bundle 分支与两处校验）一致。
func item_discard_facts() -> Array:
 var facts=[]
 for item in state.items:
  facts.append(_fact({"kind":"item_discard","item":item.id},"丢弃"+Tools.TYPES[item.type].name,{"kind":"game.item_discard","args":{},"fallback":copy_item_discard(self,{})},0,0.0,"","","item"))
 return facts

# 指令域的公共前置（绑定状态与特殊装备校验，command_facts 的入口守卫）：显示事实的域构建器复用同一守卫，
# 不再各自重写条件。
func command_domain_ready() -> bool:
 return Binding.state_issue(self)=="" and SpecialEquipment.validate(state.get("special_equipment"))==""

# 道具操作块参与的阶段（＝_phase_facts 的非早退分支）：早退分支（休息选择／商店／宝箱／事件／捕获／
# 巡视／监狱结束／地图／旅途／通关／奖励）与高潮／连锁／保留期不产出道具操作事实，只留非战斗可用道具与丢弃行。
const ITEM_ABSENT_PHASES=["rest_choice","shop","treasure","event","captured","inspection","prison_end","map","travel","cleared","reward"]

func item_action_block() -> bool:
 if state.phase in ITEM_ABSENT_PHASES: return false
 if state.overloaded and state.phase in RelicEffects.COMBAT_PHASES: return false
 if not state.card_chain.is_empty(): return false
 return not state.pending_retain

# 道具域显示事实（批 R4 起、R5 收口；T5／T8）：同一批事实构建器 + 同一分支守卫（item_action_block 与
# command_facts 的入口守卫）。分支面：relic bundle／departure 分支只留非战斗道具；其余阶段先取操作事实，
# 再用非战斗块补齐，最后每件道具一条丢弃行。
func item_facts() -> Array:
 var facts: Array=[]
 if not state.relic_bundle.is_empty() or state.phase=="departure":
  facts.append_array(Consumables.noncombat_facts(self,facts))
  return facts
 if not command_domain_ready(): return facts
 if item_action_block(): facts.append_array(item_action_facts())
 facts.append_array(Consumables.noncombat_facts(self,facts))
 facts.append_array(item_discard_facts())
 return facts

# 保留选择（整备域）：显示事实的唯一来源；只在保留期产出。
func retain_facts() -> Array:
 var facts=[]
 if not command_domain_ready() or not state.pending_retain: return facts
 if state.phase in ["rest_choice","shop","treasure","event","captured","inspection","prison_end"]: return facts
 if state.overloaded and state.phase in RelicEffects.COMBAT_PHASES: return facts
 if not state.card_chain.is_empty(): return facts
 for card in state.hand:
  if not Cards.can_select_retain(self,card): continue
  facts.append(_fact({"kind":"retain","uid":card.uid},"保留「"+B.CARD_NAMES[card.type]+"」",{"kind":"game.retain","args":{},"fallback":copy_retain(self,{})},0,0.0,"","","retain"))
 var retain_args={"draw_after":state.retain_draw_after}
 facts.append(_fact({"kind":"retain_skip"},"跳过剩余选牌",{"kind":"game.retain_skip","args":retain_args,"fallback":copy_retain_skip(self,retain_args)},0,0.0,"","","retain"))
 return facts

func dispatch(cmd: Dictionary, expected_version: int) -> Dictionary:
 var buff_issue=Consumables.validate_buffs(self,state.get("body_buffs"))
 if buff_issue!="": return {"ok":false,"error":buff_issue}
 var binding_issue=Binding.state_issue(self)
 if binding_issue!="": return {"ok":false,"error":binding_issue}
 if expected_version!=state.version:
  return {"ok":false,"error":"状态已更新，请重新选择行动。"}
 var special_issue=SpecialEquipment.validate(state.get("special_equipment"))
 if special_issue!="": return {"ok":false,"error":special_issue}
 var pending_issue=Cards.validate(self)
 if pending_issue!="": return {"ok":false,"error":pending_issue}
 var relic_issue=RelicEffects.validate(self)
 if relic_issue!="": return {"ok":false,"error":relic_issue}
 # T4 复核：指令形状＋参数合法性（不判定资格），随后由形状取回该显示点的投影事实（唯一判定在事实出口内）。
 var shape_issue=command_issue(cmd)
 if shape_issue!="": return {"ok":false,"error":shape_issue}
 var chosen=command_fact(cmd)
 if chosen.is_empty(): return {"ok":false,"error":"该行动已经失效，请重新选择。"}
 if not chosen.valid: return {"ok":false,"error":chosen.reason}
 var extra_traction=Cards.magic_card_traction(self,chosen.payload)
 var traction_mark=Cards.hand_modifier(self,"energy_pressure")
 var traction_guard=CaptureBind.has_bind(self,"guard")
 # docs/save-fixed-points.md §5.1：本批提交新增的迁移日志条目决定 checkpoint 取值。
 var log_start=_transition_log.size()
 var original=state
 var hero_copy_context={
  "cost":chosen.cost,
  "pressure_before":state.pressure,
  "mouth_before":ActionCopy.mouth_mode(equipment_at("mouth")),
  "uses_magic":(chosen.payload.kind in ["card","prison"] and chosen.payload.has("uid") and Cards.uses_magic(chosen.payload)) or (chosen.payload.kind=="attack" and chosen.payload.type=="fireball")
 }
 if chosen.payload.kind=="manual":
  var copy_target=_equipment(chosen.payload.get("target",""))
  if not copy_target.is_empty() and SpecialEquipment.is_special(copy_target):
   hero_copy_context.manual_family=SpecialEquipment.TYPES[copy_target.type].family
 var action_buffs=Cards.action_buff_ids(self) if Cards.is_card_action(chosen.payload) or chosen.payload.kind=="attack" else []
 state=state.duplicate(true)
 FirstTurnControl.commit(self,chosen)
 _resource_feedback=preload("res://core/resource_feedback.gd").new()
 _card_feedback=[]
 _resource_feedback.capture(state)
 _energy_pressure_pending=chosen.cost>0
 _card_energy_pressure_pending=Cards.hand_modifier(self,"energy_pressure") if chosen.cost>0 else 0.0
 _capture_energy_pending={"amount":chosen.cost,"guard":CaptureBind.has_bind(self,"guard")} if chosen.cost>0 and CaptureBind.has_bind(self) else {}
 _magic_failed=false
 state.energy-=chosen.cost
 _pay_mana(chosen.mana_payment)
 _resource_feedback.capture(state)
 var execution_issue=""
 if chosen.payload.kind=="event":
  var cue="event."+state.room_event.id+"."+chosen.payload.action
  var actor=Events.Data.TYPES[state.room_event.id].name
  execution_issue=Events.execute(self,chosen)
  if execution_issue=="" and state.logs.size()>original.logs.size():
   state.logs.back().data.action_copy={"cue":cue,"params":{"actor":actor,"result":state.logs.back().text}}
 elif chosen.payload.kind=="departure": execution_issue=Departure.execute(self,chosen.payload)
 elif chosen.payload.kind=="service": execution_issue=Services.execute(self,chosen.payload)
 elif chosen.payload.kind=="depart": execution_issue=_depart(chosen)
 elif chosen.payload.kind=="surrender":
  Cards.cancel_chain(self);state.pending_retain=false;state.retain_left=0;state.retain_draw_after=0
  _emit("event","你放弃抵抗，向敌人投降。")
  Guard.capture(self,state.enemies.filter(func(enemy):return not enemy.gone)[0])
 elif chosen.payload.kind=="prison": execution_issue=Prison.execute(self,chosen)
 else: _execute(chosen)
 _copy_context={}
 if execution_issue!="":
  _card_feedback=[]
  _resource_feedback=null
  _energy_pressure_pending=false
  _card_energy_pressure_pending=0.0
  _capture_energy_pending={}
  state=original
  return {"ok":false,"error":"行动未提交："+execution_issue}
 if not action_buffs.is_empty():
  if state.card_chain.is_empty(): Cards.consume_action_buffs(self,action_buffs)
  else: state.card_chain.action_buffs=action_buffs
 _settle_energy_pressure()
 for pulse in range(extra_traction):
  _emit("event","熟练而已：额外牵扯1次。",{"traction":{"extra":true,"energy":1,"card_uid":chosen.payload.uid}})
  _apply_traction(1,traction_guard,traction_mark)
 if chosen.payload.kind=="card" and not _magic_failed: Cards.record_play(self,chosen.payload.type,chosen.payload.get("free",false),chosen.payload.get("uid",""))
 _cleanup()
 Cards.normalize(self)
 if state.card_chain.is_empty() and Cards.flush_powers(self):
  _cleanup()
  if _battle_end_reason()=="victory": _finish_battle("victory")
 if state.card_chain.is_empty(): RelicEffects.flush(self)
 # Only the completed action contributes; phase transitions own their start/end pulses.
 if state.card_chain.is_empty() and not _magic_failed: Pressure.tick(self,Pressure.escape_timing(chosen.payload))
 if state.card_chain.is_empty() and not state.relic_pending.is_empty(): RelicEffects.flush(self)
 CaptureBind.observe(self)
 _finish_if_saturated()
 var issue=validate()
 if issue!="":
  _resource_feedback=null
  _card_feedback=[]
  state=original
  return {"ok":false,"error":"行动未提交："+issue}
 state.version=int(original.version)+1
 if state.logs.size()==original.logs.size(): _emit("event",chosen.label+"。")
 # Mark committed results only. Existing enemy/event copy retains its own source.
 # Logs without a player action source must not invent one during projection.
 var payment_pending=true
 for i in range(original.logs.size(),state.logs.size()):
  var data=state.logs[i].data
  if chosen.payload.kind in ["depart","travel_step"]:
   data.travel={"turn":state.travel_turns,"from":original.room,"to":chosen.payload.get("room",original.journey.get("target",original.room)),"action":chosen.payload.kind}
  if data.has("action_copy"): continue
  data.player_action={"label":chosen.label,"actor":"回合" if chosen.payload.kind=="end" else "魔法少女","cost":chosen.cost if payment_pending else 0,"mana":chosen.mana_payment.mana+chosen.mana_payment.flask_mana if payment_pending else 0,"temporary_mana":chosen.mana_payment.temporary_mana if payment_pending else 0,"mana_source":chosen.payload.get("payment","self")}
  payment_pending=false
 hero_copy_context.pressure_after=state.pressure
 hero_copy_context.overloaded=state.overloaded
 hero_copy_context.mouth_after=ActionCopy.mouth_mode(equipment_at("mouth"))
 hero_copy_context.spell_failed=hero_copy_context.uses_magic and _magic_failed
 hero_copy_context.climax_count=state.overload_total-int(original.overload_total)
 hero_copy_context.climax_turn_count=state.overload_count
 var climax_log_index=-1
 if hero_copy_context.climax_count>0:
  for i in range(state.logs.size()-1,original.logs.size()-1,-1):
   if state.logs[i].data.has("overloads"):
    climax_log_index=i
    break
 if climax_log_index>=0:
  hero_copy_context.mana_before=float(state.logs[climax_log_index].data.get("mana_before",original.mana))
  var climax_cues=ActionCopy.climax_cues(hero_copy_context)
  state.logs[climax_log_index].data.climax_copy={"cue":climax_cues.narration}
  state.logs[climax_log_index].data.hero_copy={"cue":ActionCopy.hero_cue(chosen.payload,hero_copy_context)}
 else:
  var hero_cue=ActionCopy.hero_cue(chosen.payload,hero_copy_context)
  if hero_cue!="": state.logs.back().data.hero_copy={"cue":hero_cue}
 _resource_feedback.capture(state)
 var resource_events=_resource_feedback.events.duplicate(true)
 _resource_feedback=null
 var card_events=_card_feedback
 _card_feedback=[]
 _commit_scene_start(original)
 var checkpoint=_checkpoint_kind(log_start)
 var music_events=[]
 if chosen.payload.kind=="card" and not _magic_failed and original.phase in ["battle","prison"]:
  var track=Cards.Rules.SPECS[chosen.payload.type].get("play_music","")
  if track!="": music_events.append({"track":track,"phase":original.phase,"loop":original.phase=="battle"})
 return {"ok":true,"version":state.version,"resource_feedback":resource_events,"card_feedback":card_events,"music_feedback":music_events,"checkpoint":checkpoint,"spell_failed":_magic_failed}

func cast_view(profile: Dictionary={"parts":["mouth"],"multiplier":1.0}) -> Dictionary:
 if not _equipment_read_active(): return _build_cast_view(profile)
 for entry in _equipment_read.casts:
  if entry.profile==profile: return entry.result.duplicate(true)
 var result=_build_cast_view(profile)
 _equipment_read.casts.append({"profile":profile.duplicate(true),"result":result.duplicate(true)})
 return result

func _build_cast_view(profile: Dictionary) -> Dictionary:
 var best={}
 for part in profile.parts:
  var route=_cast_path(part,profile)
  if part=="hand" and not profile.get("body_free",false) and relic_value("toe_cast")>0:
   var toe_profile=profile.duplicate(true)
   toe_profile.toe_route=true
   var toe_route=_cast_path(part,toe_profile)
   var comparison="\n秘密武器：手部%s，脚趾%s，取较高成功率。" % [route.percent,toe_route.percent]
   if (route.reason!="" and toe_route.reason=="") or (toe_route.reason=="" and toe_route.chance>route.chance): route=toe_route
   route.formula+=comparison
   route.detail+=comparison
   if route.reason!="": route.reason=hand_cast_reason()
  if best.is_empty() or (best.reason!="" and route.reason=="") or (route.reason==best.reason and route.chance>best.chance): best=route
 return best

func _cast_path(part: String, profile: Dictionary) -> Dictionary:
 var unrestricted=profile.get("unrestricted_basic",false)
 var base=1.0 if unrestricted else Pressure.cast_chance(state.pressure,Pressure.maximum(self),profile.get("desire_curve",false) or relic_value("desire_cast_curve")>0)
 var multiplier=float(profile.get("multiplier",1.0))
 var factors=[]
 var toe_route=part=="hand" and profile.get("toe_route",false)
 var reason=physical_hand_cast_reason() if part=="hand" and not profile.get("body_free",false) else ""
 if toe_route: reason="秘密武器：脚趾被拘束，脚趾施法成功率×0%。" if occupied("toes") else ""
 var formula=("无需身体部位" if part=="none" else "施法部位："+("脚趾（代替手部）" if toe_route else Cards.Rules.CAST_PART_NAMES[part]))+"\n当前快感下的基础成功率：%s%%" % String.num(base*100,6)
 for e in (equipment_at("mouth") if part=="mouth" and not unrestricted and not profile.get("ignore_restraints",false) else []):
  var tightness=tier(e.durability,e.maximum)
  var grade_factor=B.MOUTH_CAST_GRADE[e.grade]
  var tightness_factor=B.MOUTH_CAST_TIGHTNESS[tightness]
  multiplier*=grade_factor*tightness_factor
  factors.append({"id":e.id,"grade":e.grade,"tier":tightness,"grade_factor":grade_factor,"tightness_factor":tightness_factor})
  formula+="\n%s：%s×%s，紧度%d档×%s" % [e.name,Equipment.GRADES[e.grade],number(grade_factor),tightness,number(tightness_factor)]
 if profile.get("multiplier",1.0)!=1.0: formula+="\n法术加成：×"+number(profile.multiplier)
 if unrestricted: formula+="\n无尽魔法少女战神：基础动作无视拘束与快感，施法成功率100%。"
 elif profile.get("ignore_restraints",false): formula+="\n心理暗示：本次忽略拘束具影响，快感判定照常。"
 elif profile.get("body_free",false): formula+="\n魔术手：本次手部基础动作忽略拘束条件。" if Character.active(self) and part=="hand" else "\n火焰精通：不受口部装备影响，不获得手势施法加成。"
 var modifiers=Cards.casting_modifiers(self,profile)
 var chance_bonus=float(profile.get("chance_bonus",0.0))+modifiers.bonus+relic_value("cast_chance_percent")/100.0
 if chance_bonus!=0.0: formula+="\n成功率额外加成：＋%s个百分点（倍率之后）。" % number(chance_bonus*100)
 if modifiers.minimum>0: formula+="\n"+"、".join(modifiers.minimum_sources)+("：施法成功率固定为100%。" if modifiers.minimum==1.0 else "：最终成功率最低%s%%。" % number(modifiers.minimum*100))
 var winning_rolls=roundi(clampf(maxf(base*multiplier+chance_bonus,modifiers.minimum),0.0,1.0)*B.CAST_ROLL_STEPS)
 var guarantee=RelicEffects.cast_guarantee(self) if profile.get("paid_cast",true) and reason=="" else ""
 if guarantee!="":
  winning_rolls=B.CAST_ROLL_STEPS
  formula+="\n"+RelicEffects.definition(self,guarantee).name+"：本次施法必定成功。"
 elif state.sure_cast and reason=="":
  winning_rolls=B.CAST_ROLL_STEPS
  formula+="\n定咒：本次合法施法必定成功。"
 if reason!="":
  winning_rolls=0
  formula+="\n"+reason
 var chance=float(winning_rolls)/B.CAST_ROLL_STEPS
 return {"part":part,"source_part":"toes" if toe_route else part,"reason":reason,"chance":chance,"winning_rolls":winning_rolls,"base":base,"factors":factors,"multiplier":multiplier,"chance_bonus":chance_bonus,"percent":number(chance*100)+"%","formula":formula,"detail":formula+"\n嘴部施法受口部装备影响；手部施法默认需要双手的手掌和手指均自由，施法动作教程可放宽为一只完整自由手。多种可用部位取最高成功率。"+Cards.failure_refund_detail(self)+"。"}

func _cast_magic(c: Dictionary) -> bool:
 var paid=not c.payload.get("replay",false) and c.mana>0
 var guarantee=RelicEffects.cast_guarantee(self) if paid else ""
 var profile=Cards.cast_profile(self,c.payload.type,paid,c.payload.get("free"))
 if c.payload.get("replay",false): profile.magic_card=false
 var casting=cast_view(profile)
 _pay_magic(c)
 if guarantee!="" and casting.reason=="": RelicEffects.trigger(self,"paid_cast")
 else: state.sure_cast=false
 var chance=casting.chance
 var roll=-1
 var success=chance>=1.0
 if chance>0.0 and chance<1.0:
  roll=_random_index("magic",B.CAST_ROLL_STEPS)
  success=roll<casting.winning_rolls
 _magic_failed=not success
 if not success: Character.lose_focus(self,1,"施法失败")
 var refund={"mana":0.0,"temporary_mana":0.0}
 var energy_refund=0
 if not success and not c.payload.get("replay",false):
  var outcome=Cards.failure_outcome(self,c)
  var refund_rates=outcome.rates
  Cards.commit_failure(self,outcome)
  energy_refund=outcome.energy
  for field in refund:
   refund[field]=float(c.mana_payment.get(field,0.0))*refund_rates[field]
   if field=="mana": refund[field]=minf(refund[field],maxf(0.0,state.mana_max-state.mana))
   state[field]+=refund[field]
 var name=B.CARD_NAMES[c.payload.type] if c.payload.has("uid") else c.label
 var result=("额外施放「%s」" if c.payload.get("replay",false) else "「%s」施法") % name
 result+=("成功" if success else "失败")+"（成功率%s%%）。" % ActionCopy.number(chance*100)
 if casting.source_part=="toes": result+="秘密武器：脚趾代替手部施法。"
 if energy_refund>0: result+="魔路精通：获得%d能量。" % energy_refund
 if refund.mana>0: result+="返还%s魔力。" % number(refund.mana)
 if refund.temporary_mana>0: result+="返还%s临时魔力。" % number(refund.temporary_mana)
 if not success and c.payload.type=="fireball" and not c.payload.get("replay",false): result+="火球术次数未消耗。"
 if not success and c.payload.has("uid") and not c.payload.get("replay",false): result+="卡牌留在手中。"
 _emit("event",result,{"spell":{"success":success,"chance":chance,"roll":roll,"pressure":state.pressure,"base":casting.base,"factors":casting.factors,"chance_bonus":casting.chance_bonus,"part":casting.part,"source_part":casting.source_part,"type":c.payload.type,"mana_refund":refund,"energy_refund":energy_refund}})
 if success: RelicEffects.trigger(self,"spell_succeeded")
 if success and c.payload.type in Cards.Rules.FIXED_MAGIC and c.payload.type not in state.combat.successful_spells: state.combat.successful_spells.append(c.payload.type)
 if success: Cards.spell_used(self,c.payload.type)
 return success

func _pay_magic(c: Dictionary) -> void:
 if c.payload.get("replay",false): return
 if Cards.Rules.SPECS.get(c.payload.get("type",""),{}).get("fixed_mana_cost",false): return
 RelicEffects.magic_paid(self,c.mana_payment.mana)

func _execute(c: Dictionary) -> void:
 var p=c.payload
 match p.kind:
  "status_toggle":
   if p.status=="charge": state.charge_all=p.enabled
   else: Cards.toggle_power(self,p)
  "relic_discharge": RelicEffects.discharge(self,p.relic)
  "relic_toggle": FirstTurnControl.toggle(self)
  "relic_control_done": _emit("event","接管结束；当前无法结束回合，请自行处理。")
  "demo_continue": DemoExit.continue_run(self)
  "demo_end":
   _apply_transition("demo_end")
   state.demo_finished=true
   _emit("event","感谢游玩这次demo。本次游玩已结束。")
  "attack":
   var replay=Replay.take(self,"attack",p.type)
   var targets=state.enemies.filter(func(enemy):return not enemy.gone).map(func(enemy):return enemy.id) if p.all else [p.enemy]
   _execute_attack(c,targets)
   if replay: Replay.spell(self,c,targets,replay)
   if _battle_end_reason()=="victory": _finish_battle("victory")
  "wall_move":
   if state.phase=="prison":
    Prison.Space.move(self,Prison.Space.wall_path(self,p.direction=="toward"),"wall_move")
    return
   state.wall_distance=p.after
   var result="已到墙边，可以借用墙面。" if wall_contact() else "距墙%d格，墙面效果未生效。" % state.wall_distance
   if not wall_contact() and at_wall(): result="距墙%d格，遗物仍提供贴墙效果。" % state.wall_distance
   _emit("event",("你向墙面靠近" if p.direction=="toward" else "你向远离墙面的方向移动")+"%d格。" % p.distance+result,{"wall_distance":state.wall_distance,"distance":p.distance,"against_wall":at_wall()})
   if c.cost>0 and p.distance>0: SlipMotion.apply(self,"wall_move")
  "posture":
   if RelicEffects.posture_discount(self,p.dest)>0: state.ribbon_tick=-1
   var support=("借墙支撑，" if wall_contact() else "借助遗物支撑，") if p.wall else ""
   change_posture(p.dest,support)
  "card": Cards.play(self,c)
  "chain": Cards.continue_card(self,p)
  "manual":
   var target=_equipment(p.target)
   _apply_manual_release(target,p.after,Equipment.lock_only(target) and not target.locked and level("arms")==0)
   if Equipment.lock_only(target): _emit("event","取下了已开锁的限制项圈。")
   elif SpecialEquipment.is_special(target): _emit("event","双臂和双手已经完全自由，你直接取出了"+target.name+"。")
   else: _emit("event",c.label+"："+target.name+"，剩余耐久"+number(p.after)+"。")
  "end": _end_turn()
  "calm":
   var reduced=minf(state.pressure,Pressure.calm(self).reduction)
   Pressure.lose(self,reduced)
   state.next_energy+=B.CALM_NEXT_ENERGY
   state.calm_uses+=1
   _emit("event","深呼吸：快感降低%s，当前%s；下回合能量＋%d。本回合剩余%d次。" % [number(reduced),number(state.pressure),B.CALM_NEXT_ENERGY,B.CALM_USES_PER_TURN-state.calm_uses],{"calm_uses":state.calm_uses,"calm_remaining":B.CALM_USES_PER_TURN-state.calm_uses,"pressure_loss":reduced})
  "finish_prepare", "finish_rest":
   _finish_preparation()
  "finish_pack": _finish_preparation()
  "hook":
   var target=_equipment(p.target)
   target.durability=p.after
   state.hook_uses-=1
   _emit("event","借悬挂挂钩松开"+target.name+"，耐久降至"+number(p.after)+"；剩余%d次。" % state.hook_uses)
  "rest_card","rest_rare":
   var type=reward_offer(Cards.Rules.RARE,"fixed",null,1)[0] if p.kind=="rest_rare" else p.type
   var turns=B.REST_CARD_TURNS[Cards.Rules.SPECS[type].rarity]
   state.rest_left-=turns
   _gain_card(type)
   _emit("event","领取「"+B.CARD_NAMES[type]+"」，扣除%d回合，剩余%d回合休息。" % [turns,state.rest_left])
   _begin_rest()
  "rest_flask":
   state.rest_left-=B.REST_FLASK_TURNS
   state.flask_mana+=B.REST_FLASK_MANA
   _emit("event","魔瓶补充%d魔力，扣除%d回合，剩余%d回合休息。" % [B.REST_FLASK_MANA,B.REST_FLASK_TURNS,state.rest_left])
   _begin_rest()
  "rest_begin": _begin_rest()
  "item_use":
   var item=_item(p.item)
   if Tools.operation(item.type)=="buff":
    Consumables.use(self,item,p.target)
    return
   if Tools.operation(item.type)=="escape":
    item.uses-=1
    Prison.escape(self,"return_seal")
    _emit("event","传送符已用完。")
    return
   var target=_equipment(p.target)
   if Tools.operation(item.type)=="unlock":
    if p.target=="prison_door": state.prison.door_open=true
    else: target.locked=false
    _emit("event","用开锁针打开了"+("牢门锁" if p.target=="prison_door" else target.name+"的锁")+"。")
   else:
    _apply_equipment_damage(target,Tools.TYPES[item.type].damage*Cards.damage_multiplier(self,"equipment"),"cut")
    _emit("event","用"+Tools.TYPES[item.type].name+"切割"+target.name+"，剩余耐久"+number(target.durability)+"。")
   item.uses-=1
   _emit("event",Tools.TYPES[item.type].name+"剩余%d次。" % item.uses)
  "item_install", "item_retrieve":
   var item=_item(p.item)
   item.mount=p.mount
   if p.kind=="item_retrieve": item.erase("prison_position")
   elif state.room=="prison" and state.prison.get("active",false): item.prison_position=Prison.Space.attachment_position(self)
   if p.kind=="item_install":
    _emit("event","用"+Tools.OPERATOR_NAMES[p.operator]+"把"+Tools.TYPES[item.type].name+"安装到"+Tools.mount_label(p.mount)+"。",{"installation":{"item":item.id,"mount":p.mount,"operator":p.operator}})
   else: _emit("event","用"+Tools.OPERATOR_NAMES[p.operator]+"取回"+Tools.TYPES[item.type].name+"。",{"retrieval":{"item":item.id,"operator":p.operator}})
  "item_discard":
   var item=_item(p.item)
   _emit("event","丢弃"+Tools.TYPES[item.type].name+"。")
   state.items.erase(item)
  "flask": ManaFlask.execute(self,p)
  "reward_skip":
   state.reward_claimed[p.category]="skip"
   _emit("event","跳过本次"+("卡牌" if p.category=="card" else "遗物")+"奖励。")
  "relic_bundle": RelicBundle.execute(self,p)
  "reward":
   if Events.active_item_rewards(self):
    if p.type=="skip":
     Events.finish_item_rewards(self)
     return
    Events.claim_item_reward(self,p.reward_id)
    _emit("event","领取"+Tools.TYPES[p.type].name+"，收入道具栏。")
    return
   if p.type!="skip":
    var category=p.category
    state.reward_claimed[category]=p.type
    match category:
     "card":
      _gain_card(p.type)
      _emit("event","获得「"+B.CARD_NAMES[p.type]+"」，加入卡组。")
     "item":
      _gain_tool(p.type)
      _emit("event","领取"+Tools.TYPES[p.type].name+"，收入道具栏。")
     "relic": RelicEffects.gain(self,p.type,"boss" if room_data(state.room).get("boss",false) else "")
     "flask":
      state.flask_mana+=state.battle_flask_drop
      _emit("event",("领取出口守卫奖励，贴身魔瓶获得%d魔力。" if Prison.is_exit_battle(self) else "领取Boss奖励，贴身魔瓶获得%d魔力。") % state.battle_flask_drop,{"boss_flask_reward":state.battle_flask_drop})
   else:
    state.battle_flask_drop=0
    state.battle_item_drop=""
    state.battle_relic_drop=""
    state.boss_relic_options=[]
    if Prison.is_exit_battle(self):
     state.reward_options=[]
     _finish_preparation()
    else: _start_preparation()
  "travel_step": _advance_travel()
  "retain": Cards.retain(self,p.uid)
  "retain_skip": Cards.finish_retain(self)

func _execute_attack(c: Dictionary, targets: Array) -> void:
 var damage_group={}
 if c.payload.get("witch_action",false):
  Character.execute(self,c,damage_group)
  return
 var p=c.payload
 if not p.get("replay",false) and BasicAttacks.TYPES[p.type][0].has("first_use_cost"): state.combat.attack_started[p.type]=true
 if p.type=="fireball":
  if not _cast_magic(c): return
 else: _consume_charge()
 if not p.get("replay",false) and BasicAttacks.TYPES[p.type][0].has("uses_per_turn"): state.combat.attack_uses[p.type]=int(state.combat.attack_uses.get(p.type,0))+1
 if p.get("target","")!="":
  var equipment=_equipment(p.target)
  var before=equipment.durability
  _apply_equipment_damage(equipment,p.damage,p.damage_type)
  _emit("mechanical","火球术对%s造成%s点魔法伤害，耐久%s→%s。" % [equipment.name,number(before-equipment.durability),number(before),number(equipment.durability)],{"equipment_spell":{"target":equipment.id,"damage_type":p.damage_type,"before":before,"after":equipment.durability,"damage":before-equipment.durability}})
  Cards.consume_attack_buffs(self,p.type)
  return
 if p.type=="heavy": state.heavy_used=true
 if p.get("cooldown_turns",0)>0: state.kick_last=state.round
 for id in targets:
  var target=_enemy(id)
  for hit in range(p.hits):
   if target.is_empty() or target.gone: break
   _damage_enemy(target,p.damage,p.damage_type,c.label+("第%d击" % (hit+1) if p.hits>1 else ""),{"hit":hit+1,"hits":p.hits,"attack":true},damage_group)
  if not target.is_empty() and not target.gone and p.interrupt and not target.intent.is_empty() and not target.intent.get("delayed",false):
   target.intent.delayed=true
   var cancelled=target.intent.get("cancel_on_interrupt",false)
   _emit("event",target.name+("的逮捕准备被打断。" if cancelled else "的意图延后一回合。"),{"interrupt":{"enemy":target.id,"cancelled":cancelled}})
 Cards.consume_attack_buffs(self,p.type)
 if p.fall and CaptureBind.fixed_posture(self)=="":
  state.posture="lie"
  RelicEffects.fell(self)
  _emit("event","攻击结束后，你转为躺姿。")

func _cleanup(released: bool=true) -> void:
 var roots=Cards.restraint_roots(self) if released and not state.powers.is_empty() else []
 Shoulders.cleanup(self)
 for item in state.special_equipment.duplicate():
  if item.durability<=0.000001:
   if SpecialEquipment.is_reinforcement(item):
    var owner=_equipment(item.owner_id)
    if not owner.is_empty() and SpecialEquipment.supports_reinforcement(owner): owner.reinforcement_state="removed"
   state.special_equipment.erase(item)
   if SpecialEquipment.supports_reinforcement(item):
    for strap in state.special_equipment.duplicate():
     if SpecialEquipment.reinforcement_matches(strap,item): state.special_equipment.erase(strap)
   _emit("event",item.name+"已解除。")
 for strap in state.special_equipment.duplicate():
  if SpecialEquipment.is_reinforcement(strap) and not state.special_equipment.any(func(owner):return SpecialEquipment.reinforcement_matches(strap,owner)):
   state.special_equipment.erase(strap)
 for item in state.items.duplicate():
  if item.uses<=0:
   _emit("event",Tools.TYPES[item.type].name+"已经耗尽次数。")
   state.items.erase(item)
 for i in range(state.equipment.size()-1,-1,-1):
  var e=state.equipment[i]
  if e.durability<=0.000001 and (not cursed_eyes(e) or e.get("absolute_release",false)):
   _emit("event",e.name+"已解除。")
   state.equipment.remove_at(i)
 for root in state.composites.duplicate():
  var body=_composite_body(root)
  if root.kind=="head" and _equipment(root.attached_to).is_empty():
   state.composites.erase(root)
   _emit("event","口部固定带已解除，依附其上的头部马具一并移除。")
   continue
  if not body.is_empty() and body.durability<=0.000001:
   root.components=root.components.filter(func(e):return e.get("independent",false) and e.durability>0.000001)
   if root.components.is_empty(): state.composites.erase(root)
   _emit("event",root.name+"的套体已解除。"+("附带部件一并解除。" if root.components.is_empty() else ""))
  else:
   var previous_count=root.components.size()
   for part in root.components.duplicate():
    if part.durability<=0.000001:
     root.components.erase(part)
     _emit("event",part.name+"已解除。")
   if root.components.is_empty(): state.composites.erase(root)
   elif not body.is_empty():
    var removed=root.components.size()<previous_count
    if removed and _slip_reason(body)=="": _emit("event","现在可以尝试滑脱"+root.name+"的套体。")
 for link in state.links.duplicate():
  if link.durability<=0.000001:
   state.links.erase(link)
   _emit("event",link.name+"已解除。")
  elif not link.ends.all(func(id):return link_anchors().any(func(e):return e.id==id)):
   state.links.erase(link)
   _emit("event",link.name+"连接的一件装备已解除，这条链接随之移除。")
 Pressure.cleanup(self)
 Pressure.settle_maximum(self,"平板锁解除后")

 if not roots.is_empty():
  var remaining=Cards.restraint_roots(self)
  Cards.restraint_changed(self,"released",roots.filter(func(id):return id not in remaining).size())

func _apply_traction(amount: int, guard_effect: bool, hand_pressure: float) -> void:
 _tick_special("energy")
 CaptureBind.energy_spent(self,amount,guard_effect)
 var toe=RelicEffects.toe_traction(self)
 if toe.base>0: Pressure.gain(self,toe.base,"秘密武器·脚趾牵扯",false,["toes"])
 if hand_pressure>0: Pressure.gain(self,hand_pressure,"小腹上的淫纹")

func _settle_energy_pressure() -> void:
 if not _energy_pressure_pending: return
 _energy_pressure_pending=false
 var spent=_capture_energy_pending
 _capture_energy_pending={}
 _apply_traction(int(spent.get("amount",0)),spent.get("guard",false),_card_energy_pressure_pending)
 _card_energy_pressure_pending=0.0

func _end_turn() -> void:
 if state.weakness_turns>0:
  state.weakness_turns-=1
  if state.weakness_turns==0: _emit("event","无力化结束。")
 _settle_energy_pressure()
 state.ribbon_tick=-1
 Cards.end_hand(self)
 Pressure.tick(self,"turn_end")
 _discard_end()
 EnemyPlans.tick_install(self,"turn_end")
 RelicEffects.end_turn(self)
 Cards.expire_turn_buffs(self)
 Pressure.relax(self)
 RelicEffects.flush(self)
 if Prison.completed_turn(self): return
 if _battle_end_reason()=="victory":
  _finish_battle("victory")
  return
 if state.phase=="prison":
  Prison.end_turn(self)
  return
 if state.phase=="rest":
  state.rest_left-=1
  if state.rest_left<=0: _finish_preparation()
  else: _rest_round()
  return
 if state.phase=="prepare":
  state.prepare_left-=1
  if state.prepare_left<=0:
   _finish_preparation()
  else: _prepare_round()
  return
 if state.order=="first": _enemy_phase()
 if state.phase=="battle":
  Prison.tick_reinforcements(self)
  _start_round()

func _finish_preparation() -> void:
 RelicEffects.end_combat(self)
 Pressure.clear_penalties(self)
 state.weakness_turns=0
 if carried_items()>item_capacity():
  _apply_transition("prepare_end",{"phase":"pack"})
  state.energy=0
  _emit("event","随身道具超出容量，请使用或放下多出的道具后离开。")
  return
 if Prison.after_preparation(self): return
 _apply_transition("prepare_end",{"phase":"map"})
 state.energy=0
 state.prepare_left=0
 state.rest_left=0
 if state.practice:
  _apply_transition("prepare_end",{"phase":"cleared"})
  _emit("event","本次装备练习结束。")
  return
 if not state.completed_rooms.has(state.room): state.completed_rooms.append(state.room)
 _emit("event","房间探索结束。" if room_data(state.room).kind in ["event","shop","treasure"] else "整备结束。")

func _leave_mounted_tools() -> void:
 for item in state.items.duplicate():
  if item.mount!="carry":
   _emit("event",Tools.TYPES[item.type].name+"留在原房间的"+Tools.mount_label(item.mount)+"。")
   state.items.erase(item)

func movement_profile() -> Dictionary:
 var speed=5.0
 var mode="正常步行"
 if state.posture!="stand":
  speed=0.5
  mode="坐姿挪动" if state.posture=="sit" else "躺姿挪动"
 elif occupied("ankle") or occupied("foot") or occupied("toes"):
  speed=1.0
  mode="并腿跳跃"
 elif occupied("calf"):
  speed=2.0
  mode="短步移动"
 elif occupied("thigh"):
  speed=3.0
  mode="小步移动"
 return {"speed":speed,"mode":mode,"turns":ceili(Tower.DISTANCE/speed)}

func room_description(room: Dictionary) -> String:
 if state.map_region=="prison":
  if room.kind=="entry": return "监狱出口。"
  if room.kind=="battle": return "魅魔警卫 × %d。" % room.encounter_repeats
 if room.kind=="shop": return "用魔力购买卡牌、道具和遗物，或移除一张牌。"
 if room.kind=="treasure": return "领取一件遗物。"
 if room.has("encounter_choices") and not room.has("encounter_selected"):
  return "普通战斗 · 强怪池。" if room.get("pool","")=="strong" else "普通战斗。"
 if room.kind=="event": return Events.Data.TYPES[room.event].name if room.get("event","")!="" else ("这里没有新的发现。" if room.has("event") else "抵达后发现事件。")
 if state.tower_start_pending and room.id==state.room: return "请选择第10—11层的非休息、非宝箱区域作为出狱起点。"
 if room.kind=="entry": return "塔底入口。"
 if room.kind=="prison": return "牢房内可以挣脱、探索、处理出口；巡视按倒计时到达。"
 if room.kind=="exit": return "塔顶出口。"
 if room.kind=="rest": return "最多%d回合；入场可扣%d回合随机获得1张稀有卡，或扣%d回合选择1张罕见卡，或扣%d回合补充%d魔瓶魔力；也可跳过奖励。挂钩%d次，禁用卡牌自由效果，不自动回魔。" % [B.REST_TURNS,B.REST_CARD_TURNS.rare,B.REST_CARD_TURNS.uncommon,B.REST_FLASK_TURNS,B.REST_FLASK_MANA,B.REST_HOOK_USES]
 var wall="粗糙墙面：贴墙站／坐时，主动挣扎或滑脱额外造成2点真实伤害" if room.wall=="rough" else "普通墙面：贴墙后可借墙起身，无属性加成"
 var encounter=state.room_encounters[room.id]
 var extra=""
 if room.get("boss",false): extra="塔顶关卡：必须击败首领才能前往出口；若首领完成收押，你会被送入监狱。"
 var description=Enemies.description(encounter)
 if room.has("enemy_members"): description="、".join(room.enemy_members.map(func(m):return Enemies.TYPES[m.type].name))
 return description+"；"+wall+"。"+extra

func route_connection_reason(source: Dictionary, target: Dictionary) -> String:
 if source.is_empty() or target.is_empty(): return "这条路线连接的房间已不存在。"
 if target.floor!=source.floor+1: return "只能沿地图连线前往相邻的上一层，不能跳层或回头。"
 if target.id not in source.next: return "当前房间与这里没有地图连线，不能跨到其他分支。"
 return ""

func travel_route_reason() -> String:
 if state.journey.is_empty() or state.journey.get("from","")!=state.room: return "当前行程的起点不符，不能继续前进。"
 return route_connection_reason(room_data(state.room),room_data(state.journey.target))

func _route_exit_candidate(choices: Array) -> Dictionary:
 if state.practice or state.room=="prison" or Prison.is_exit_battle(self): return {}
 if state.phase=="event" and state.room_event.get("prepare_pending",false): return {}
 for c in choices:
  var p=c.payload
  if p.kind in ["finish_prepare","finish_rest","finish_pack"] or (p.kind=="service" and p.op=="leave") or (p.kind=="event" and p.action=="leave"):
   # 出口事实按需投影（调用方可能传事实源）：判定结论与 detail 由唯一判定给出，行载体已删除。
   return c if c.has("valid") else display_fact(c)
 return {}

# 路线显示事实（路线域；批 R5）：exit_action＝本条指令域内已产出的出口事实（与改动前的行扫描同一输入）。
func _route_facts(choices: Array) -> Array:
 var out: Array=[]
 var exit_action=_route_exit_candidate(choices)
 if state.phase!="map" and exit_action.is_empty(): return out
 var profile=movement_profile()
 var destinations=state.rooms.filter(func(room):return Prison.start_room(room)).map(func(room):return room.id) if state.tower_start_pending else room_data(state.room).next
 for id in destinations:
  if state.completed_rooms.has(id): continue
  var room=room_data(id)
  var depart_args={"mode":profile.mode,"turns":profile.turns,"room_id":id,"phase":state.phase,"tower_start":state.tower_start_pending}
  out.append(_fact({"kind":"depart","room":id},("从这里开始 · " if state.tower_start_pending else "前往")+room.name,{"kind":"game.depart","args":depart_args,"fallback":copy_depart(self,depart_args)},0,0.0,room_entry_reason(room,exit_action),SlipMotion.hint(),"route"))
 return out

func room_entry_reason(room: Dictionary, exit_action: Variant=null) -> String:
 if state.tower_start_pending:
  return "" if state.phase=="map" and Prison.start_room(room) else "出狱起点只能选择第10—11层的非休息、非宝箱区域。"
 if room.is_empty(): return "这个房间不在当前塔图中。"
 if state.phase=="travel": return "正在前往已选房间，抵达后才能选择新路线。"
 if exit_action==null: exit_action=_route_exit_candidate(_phase_facts()) if state.phase!="map" else {}
 if state.phase in ["battle","reward","prepare","rest","rest_choice","pack","event","shop","treasure"] and exit_action.is_empty(): return "先完成当前房间的战斗、奖励或整备，再选择前进路线。"
 if not exit_action.is_empty():
  if not exit_action.valid: return exit_action.reason
  if carried_items()>item_capacity(): return "请先使用或放下超出容量的随身道具。"
 if state.phase=="cleared": return "当前阶段已完成。"
 if room.id==state.room: return "你当前就在这里，请选择相连的下一房间。"
 if state.completed_rooms.has(room.id): return "已经走过这个房间，不能返回。"
 if room.has("requires_clear") and not state.completed_rooms.has(room.requires_clear) and not (not exit_action.is_empty() and room.requires_clear==state.room): return "需要先击败塔顶首领并完成战后整备，出口才会开放。"
 var connection=route_connection_reason(room_data(state.room),room)
 if connection!="": return connection
 if state.phase!="map" and exit_action.is_empty(): return "当前不能离开房间选择路线。"
 return ""

func _depart(c: Dictionary) -> String:
 if state.phase!="map":
  var exit_action=_route_exit_candidate(_phase_facts())
  if exit_action.is_empty() or not exit_action.valid: return "当前房间还有未完成的事项，不能离开。"
  var issue=""
  match exit_action.payload.kind:
   "event": issue=Events.execute(self,exit_action)
   "service": issue=Services.execute(self,exit_action.payload)
   _: _execute(exit_action)
  if issue!="": return issue
  _cleanup();Cards.normalize(self)
  if state.phase=="pack": return "请先使用或放下超出容量的随身道具。"
  if state.phase!="map": return "当前房间还有未完成的事项，不能离开。"
 var reason=room_entry_reason(room_data(c.payload.room))
 if reason!="": return reason
 _leave_mounted_tools()
 if state.tower_start_pending:
  state.tower_start_pending=false
  _apply_transition(_room_transition_kind(c.payload.room),{"room":c.payload.room})
  _emit("event","选择"+room_data(state.room).name+"作为新塔路起点。")
  _arrive_room()
  return ""
 var profile=movement_profile()
 state.journey={"from":state.room,"target":c.payload.room,"total":profile.turns,"remaining":profile.turns,"speed":profile.speed,"mode":profile.mode}
 _apply_transition("travel_start",{"phase":"travel"});state.wall="none";state.wall_distance=0
 _emit("event","你离开"+room_data(state.room).name+"，以"+profile.mode+"前往"+room_data(c.payload.room).name+"，需要%d回合。" % profile.turns)
 return ""

func _advance_travel() -> void:
 if travel_route_reason()!="": return
 Pressure.tick(self,"travel")
 state.journey.remaining-=1
 state.travel_turns+=1
 ManaFlask.reset_turn(self)
 SlipMotion.apply(self,"travel")
 Pressure.relax(self)
 RelicEffects.flush(self)
 if state.journey.remaining>0:
  _emit("event","你继续"+state.journey.mode+"，距离"+room_data(state.journey.target).name+"还有%d回合。" % state.journey.remaining)
  return
 state.traversed_edges.append([state.room,state.journey.target])
 _apply_transition(_room_transition_kind(state.journey.target),{"room":state.journey.target})
 state.journey={}
 _arrive_room()

func _arrive_room() -> void:
 var room=room_data(state.room)
 if room.kind=="exit":
  _apply_transition("room_enter",{"phase":"cleared"})
  state.completed_rooms.append(state.room)
  _emit("event","感谢游玩这次demo。"+("你可以返回菜单，或保留当前成长继续攀塔。" if state.demo_cycle<2 else "三个阶段全部完成。"))
 elif room.kind=="entry":
  _apply_transition("room_enter",{"phase":"map"});state.energy=0;state.wall=room.wall
  state.wall_distance=1
  _emit("event","抵达塔底，选择第一层入口继续攀塔。")
 elif room.kind=="rest": _start_rest()
 elif room.kind=="event": Events.start(self)
 elif room.kind in ["shop","treasure"]: Services.start(self)
 else:
  _start_battle()

func route_view(choices: Variant=null) -> Array:
 var result: Array=[]
 var current=room_data(state.room)
 var exit_action=_route_exit_candidate(_phase_facts() if choices==null else choices)
 for room in state.rooms:
  var status="ahead"
  if state.completed_rooms.has(room.id): status="completed"
  elif room.id==state.room: status="current"
  elif room_entry_reason(room,exit_action)=="": status="available"
  elif not state.journey.is_empty() and state.journey.target==room.id: status="destination"
  elif room.floor<=current.floor: status="skipped"
  var paths: Array=[]
  for next in room.next:
   var path_status="ahead"
   if state.traversed_edges.has([room.id,next]): path_status="travelled"
   elif not state.journey.is_empty() and state.journey.from==room.id and state.journey.target==next: path_status="travelling"
   elif room.id==state.room and room_entry_reason(room_data(next),exit_action)=="": path_status="available"
   elif status in ["completed","skipped"]: path_status="skipped"
   paths.append({"to":next,"status":path_status})
  var reason=room_entry_reason(room,exit_action)
  var icon=room.kind
  if room.get("pool","") in ["ordinary","strong"]: icon="battle"
  elif room.kind=="battle": icon="boss" if room.get("boss",false) else Enemies.ENCOUNTERS[state.room_encounters[room.id]].rank
  result.append({"id":room.id,"name":room.name,"floor":room.floor,"lane":room.lane,"next":room.next.duplicate(),"paths":paths,"icon":icon,"current":room.id==state.room,"entry_reason":reason,"status":status})
 return result

func validate() -> String:
 var character_issue=Character.validate(self,state)
 if character_issue!="": return character_issue
 var departure_issue=Departure.validate(self,state)
 if departure_issue!="": return departure_issue
 var buff_issue=Consumables.validate_buffs(self,state.get("body_buffs"))
 if buff_issue!="": return buff_issue
 if not Snapshot.fields(state,"charge_all:b"): return "蓄力模式不正确。"
 if not Snapshot.fields(state,"chastity_locks_enabled:b chastity_lock_chance:i cursed_plate_masochist_mode:b chastity_climax_factor:i slip_ejaculation_turns:i slip_ejaculation_force_last:b") or state.chastity_lock_chance<0 or state.chastity_lock_chance>100 or state.chastity_lock_chance%5!=0 or state.chastity_climax_factor<3 or (not state.cursed_plate_masochist_mode and state.chastity_climax_factor>SpecialEquipment.CHASTITY_CLIMAX_FACTOR_LIMIT) or state.slip_ejaculation_turns<0 or state.slip_ejaculation_turns>2: return "平板锁生成、高潮保留或滑精状态不正确。"
 var demo_issue=DemoExit.validate(state)
 if demo_issue!="": return demo_issue
 if not Snapshot.fields(state,"temporary_mana:n") or state.temporary_mana<0: return "临时魔力记录不正确。"
 var flask_issue=ManaFlask.validate(self)
 if flask_issue!="": return flask_issue
 if not Snapshot.is_current(state): return Snapshot.INCOMPATIBLE
 if not Snapshot.fields(state,"sure_cast:b item_drop_chance:i battle_item_drop:s") or state.item_drop_chance<0 or state.item_drop_chance>100 or state.item_drop_chance%10!=0: return "道具掉落或定咒记录不正确。"
 if state.battle_item_drop!="" and state.battle_item_drop not in Tools.DROP_POOL: return "掉落道具不在当前道具池中。"
 if state.sure_cast and not RelicEffects.keeps_combat_state(self): return "定咒只能在本场战斗及整备中保留。"
 var shoulder_issue=Shoulders.validate(self)
 if state.equipment.filter(func(e):return Equipment.lock_only(e)).size()>1: return "不能重复佩戴限制项圈。"
 if shoulder_issue!="": return shoulder_issue
 for e in state.equipment:
  var binding_issue=Binding.validate(self,e)
  if binding_issue!="": return binding_issue
 if not state.wall_distance is int or state.wall_distance<0 or state.wall_distance>4: return "距墙距离必须是0至4的整数。"
 var service_issue=Services.validate(self)
 if service_issue!="": return service_issue
 if state.phase=="travel" and not state.journey.is_empty():
  var route_issue=travel_route_reason()
  if route_issue!="": return route_issue
 var card_issue=Cards.validate(self)
 if card_issue!="": return card_issue
 var relic_issue=RelicEffects.validate(self)
 if relic_issue!="": return relic_issue
 var event_issue=Events.validate(self)
 if event_issue!="": return event_issue
 var prison_issue=Prison.validate(self)
 if prison_issue!="": return prison_issue
 var guard_issue=Guard.validate(self)
 if guard_issue!="": return guard_issue
 var special_issue=SpecialEquipment.validate(state.get("special_equipment"))
 if special_issue!="": return special_issue
 var pressure_issue=Pressure.validate(self)
 if pressure_issue!="": return pressure_issue
 var enemy_ids: Array=[]
 for e in state.enemies:
  if not Enemies.TYPES.has(e.get("type","")) or enemy_ids.has(e.id): return "敌人种类或个体编号不合法"
  var carried_issue=EnemyPlans.carried_reason(self,e)
  if carried_issue!="": return carried_issue
  if not is_finite(e.hp) or e.hp<0 or e.hp>e.max_hp or e.stage<1: return "敌人生命或行动阶段不合法"
  if Enemies.TYPES[e.type].has("ritual_gain"):
   if not e.get("ritual") is int or not e.get("application_bonus") is int or e.ritual<0 or e.application_bonus<0: return "敌人仪式或施加数量加成不合法"
  if Enemies.TYPES[e.type].has("quantity_gain") and (not e.get("application_bonus") is int or e.application_bonus<0): return "敌人施加数量加成不合法"
  if e.has("turn_install_layers"):
   var effect=Enemies.TYPES[e.type].get("turn_install_effect",{})
   if not e.turn_install_layers is int or e.turn_install_layers<1 or effect.is_empty() or e.gone: return "持续施加来源不合法"
   if not effect.stack and e.turn_install_layers!=1: return "持续施加层数不合法"
  var iron_issue=IronMan.validate(self,e)
  if iron_issue!="": return iron_issue
  enemy_ids.append(e.id)
 var puppet_issue=Puppets.validate(self,state.enemies,DemoExit.health_multiplier(state))
 if puppet_issue!="": return puppet_issue
 for parent in state.enemies:
  var spec=Enemies.TYPES[parent.type]
  var expected=spec.get("defeat_spawns",[]) if parent.defeated else []
  if parent.has("split_basis"):
   if not spec.has("split_spawns") or not parent.gone or not parent.defeated or parent.split_basis<=0 or parent.split_basis>parent.max_hp*spec.split_threshold: return "分裂时的生命记录不合法"
   expected=spec.split_spawns
  var children=state.enemies.filter(func(child):return child.get("spawned_from","")==parent.id)
  if expected.size()!=children.size(): return "分裂敌人的数量与来源不符"
  for i in range(children.size()):
   if children[i].type!=expected[i].type or children[i].grade!=expected[i].grade or not parent.gone or parent.hp!=0: return "分裂敌人的类型或来源不符"
   if parent.has("split_basis"):
    var inherited=parent.split_basis if expected[i].hp_ratio==1.0 else ceilf(parent.split_basis*expected[i].hp_ratio)
    if children[i].max_hp!=inherited: return "分裂敌人的继承生命不符"
 for e in state.enemies:
  if e.has("spawned_from") and (e.spawned_from not in enemy_ids or e.spawned_from==e.id): return "分裂敌人的来源不存在"
 var mounts: Array=[]
 var item_ids: Array=[]
 for item in state.items:
  if Tools.TYPES.has(item.type) and Tools.operation(item.type)!="cut" and item.mount!="carry": return "这件道具不能安装在墙面。"
  if item_ids.has(item.id) or not Tools.TYPES.has(item.type) or item.uses<=0 or item.uses>Tools.TYPES[item.type].uses: return "道具数量或次数不合法"
  item_ids.append(item.id)
  if item.mount!="carry":
   var point=[item.mount,item.get("prison_position",[])]
   if point in mounts: return "同一位置的同一高度墙缝不能安装两件工具。"
   mounts.append(point)
 if room_data(state.room).is_empty(): return "房间不存在"
 var current_room=room_data(state.room)
 if current_room.has("requires_clear") and not state.completed_rooms.has(current_room.requires_clear): return "尚未击败塔顶守卫，不能抵达出口。"
 if state.phase=="travel" and (state.journey.is_empty() or state.journey.remaining<1 or state.journey.remaining>state.journey.total): return "移动进度不合法"
 if state.energy<0 or state.mana<0 or state.mana>state.mana_max or state.mana_max<B.MANA_MAX_FLOOR: return "资源超出合法范围"
 var ids: Array=[]
 for root in state.composites:
  var issue=Composites.validate(root)
  if issue!="": return issue
  if ids.has(root.id): return "复合装备重复"
  if root.kind=="head":
   var attached=_equipment(root.attached_to)
   if attached.is_empty() or attached.template!="mouth_band": return "头部马具缺少兼容口部固定带。"
  ids.append(root.id)
  for piece in root.components:
   if ids.has(piece.id): return "复合组件重复"
   ids.append(piece.id)
 for e in state.equipment:
  if ids.has(e.id): return "装备重复"
  ids.append(e.id)
  var issue=Equipment.validate(e)
  if issue!="": return issue
 var capacity_issue=_capacity_issue(physical_pieces())
 if capacity_issue!="": return capacity_issue
 for root in state.composites:
  if not Composites.active(root): continue
  var layout=Composites.definition(root)
  for e in state.equipment:
   if e.slot not in layout.coverage or root.kind=="head": continue
   if e.layer==root.layer: return "普通装备不能与复合主体共用结构层。"
   if e.slot in layout.closed and e.layer>root.layer: return "封闭区域不能新增外层普通装备。"
  for other in state.composites:
   if other.id==root.id or not Composites.active(other): continue
   if root.kind in ["glove","jacket"] and other.kind in ["glove","jacket"]: return "单手套与拘束衣不能重复或互相覆盖。"
   if root.kind==other.kind and root.variant==other.variant: return "同种复合装备重复。"
   if root.kind=="leg" and other.kind=="leg" and root.variant in ["ankle","toes"]:
    if other.variant in ["ankle","toes"] or other.layer>=root.layer: return "长短单腿套的层序不合法。"
 for link in state.links:
  if ids.has(link.id): return "链接装备重复"
  ids.append(link.id)
  var issue=Links.validate(link,link_anchors(),state.links)
  if issue!="": return issue
 return ""

func number(n: float) -> String:
 return str(int(n)) if is_equal_approx(n,roundf(n)) else "%.2f" % n

func get_view() -> Dictionary:
 var previous=_begin_equipment_read()
 var result=View.build(self)
 _equipment_read=previous
 return result

func export_snapshot() -> Dictionary:
 return state.duplicate(true)

func restore_snapshot(saved: Dictionary) -> Dictionary:
 var candidate=saved.duplicate(true)
 var saved_revision=candidate.get("save_revision")
 var migrate_drone=saved_revision is int and saved_revision in [Snapshot.REINFORCEMENT_STATE_REVISION,Snapshot.CUP_STACK_REVISION,Snapshot.IRON_DRONE_REVISION]
 if saved_revision is int and saved_revision==Snapshot.REINFORCEMENT_STATE_REVISION:
  var special_items=[]
  if candidate.get("special_equipment") is Array: special_items.append_array(candidate.special_equipment)
  var saved_event=candidate.get("room_event",{})
  if saved_event is Dictionary and saved_event.get("held") is Dictionary:
   for held_items in saved_event.held.values():
    if held_items is Array: special_items.append_array(held_items)
  SpecialEquipment.migrate_reinforcement_state(special_items)
 if saved_revision is int and saved_revision in [Snapshot.REINFORCEMENT_STATE_REVISION,Snapshot.CUP_STACK_REVISION]:
  var migration_issue=Snapshot.migrate_cup_stacks(candidate,self)
  if migration_issue!="": return {"ok":false,"error":"无法继续这份存档："+migration_issue}
 if migrate_drone:
  Snapshot.migrate_iron_drone(candidate,self)
  candidate.save_revision=Snapshot.REVISION
 elif not Snapshot.is_current(candidate): return {"ok":false,"code":"version","error":Snapshot.INCOMPATIBLE}
 # The only backfill point for the run identity: a save written before `initial_seed`
 # existed took its identity from the then current `seed`. Patched on the copy before the
 # shared field check, so the caller dictionary, the file and the live state stay untouched.
 if not candidate.has("initial_seed"): candidate.initial_seed=int(candidate.get("seed",0))
 var issue=Snapshot.check(candidate,self)
 if issue!="": return {"ok":false,"error":"无法继续这份存档："+issue}
 var previous=state
 state=candidate
 if migrate_drone:
  for enemy in state.enemies:
   var member=Enemies.encounter_member(state,enemy.type)
   if member.has("name"): enemy.name=member.name
   if enemy.type=="iron_drone" and not enemy.gone and state.phase=="battle":
    var delayed=enemy.intent.delayed
    enemy.intent=EnemyPlans.build(self,enemy)
    enemy.intent.delayed=delayed
 # Saves written before security five became an ordinary cell carry the removed
 # high-security manifest; drop the key so no second terminal path survives a load.
 var loaded_capture: Dictionary=state.get("capture",{})
 loaded_capture.erase("terminal_equipment")
 issue=validate()
 if issue=="" and not state.card_chain.is_empty() and Cards.chain_facts(self).is_empty(): issue="连续卡牌已没有可继续的目标。"
 if issue=="" and state.pending_retain and (state.overloaded or not state.hand.any(func(card):return Cards.can_select_retain(self,card))): issue="保留手牌选择已没有合法目标。"
 if issue!="":
  state=previous
  return {"ok":false,"error":"无法继续这份存档："+issue}
 state.version=maxi(int(previous.version),int(state.version))+1
 _scene_start=export_snapshot()
 return {"ok":true}


# Scene checkpoints are outside the live state: no nested snapshots or second rule state.
static func _scene_key(s: Dictionary) -> Array:
 var phase="prison" if s.phase=="inspection" else s.phase
 # Rest rewards and playable rest belong to one room entry, even though choosing
 # a reward starts a new combat lifecycle and increments its serial.
 if phase=="rest_choice": phase="rest"
 return [s.seed,s.tower_generation,s.map_region,s.room,phase,s.encounter if phase=="battle" else 0,s.combat.serial if phase in ["battle","prison","prepare"] else 0,s.demo_finished]

func _commit_scene_start(before: Dictionary) -> void:
 if _scene_key(state)!=_scene_key(before):
  _scene_start=export_snapshot()
 elif _scene_start.is_empty() or _scene_key(_scene_start)!=_scene_key(before):
  # Explicit test scenes may be injected before their first formal command.
  _scene_start=before.duplicate(true)

func restart_snapshot() -> Dictionary:
 if _scene_start.is_empty() or _scene_key(_scene_start)!=_scene_key(state): return export_snapshot()
 return _scene_start.duplicate(true)
