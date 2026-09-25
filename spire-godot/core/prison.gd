extends RefCounted

const B=preload("res://data/balance.gd")
const Space=preload("res://core/prison_space.gd")
const ACTIVE_DISCOVERIES=["shard","saw","vent"]
const PATROL_GUARD="guard_purple"
const SENIOR_GUARD="guard_brown"

static func has_flat_lock(g) -> bool:
 return g.state.special_equipment.any(func(item):return item.get("durability",0)>0 and g.SpecialEquipment.is_chastity(item))

static func inspection_climax(g, temporary: bool=false) -> Dictionary:
 var mana_before=float(g.state.mana)
 var flat=has_flat_lock(g)
 var low=mana_before<B.OVERLOAD_MANA
 var suffix="flat_low" if flat and low else ("flat" if flat else ("low" if low else "normal"))
 var narration_cue="prison.inspection.milk."+suffix
 var dialogue_cue="prison.guard.milk."+suffix
 var visual=SENIOR_GUARD if temporary else PATROL_GUARD
 var resolved=g.Pressure.scripted_climax(g,"出狱前巡视的手部榨精" if temporary else "例行巡视的手部榨精")
 var narrative=g.ActionCopy.line(narration_cue,{},true)
 var record={"temporary":temporary,"method":"hand","flat_lock":flat,"low_semen":low,"count":resolved.count,"mana_before":resolved.mana_before,"mana_lost":resolved.mana_lost,"mana_after":resolved.mana_after,"narration_cue":narration_cue,"dialogue_cue":dialogue_cue,"visual":visual}
 g._emit("event",narrative,{"prison_inspection_climax":record})
 return record

static func intake_climax(g) -> Dictionary:
 var mana_before=float(g.state.mana)
 var flat=has_flat_lock(g)
 var low=mana_before<B.OVERLOAD_MANA
 var suffix="flat_low" if flat and low else ("flat" if flat else ("low" if low else "normal"))
 var resolved=g.Pressure.scripted_climax(g,"收押时的手部榨精")
 return {"method":"hand","flat_lock":flat,"low_semen":low,"count":resolved.count,"mana_before":resolved.mana_before,"mana_lost":resolved.mana_lost,"mana_after":resolved.mana_after,"narration_cue":"prison.intake.milk."+suffix}

static func intake_scene(g, intake: Dictionary, links: Array, climax: Dictionary) -> Dictionary:
 var restraints: Array[String]=[]
 for item in intake.get("installed",[]):
  if item.has("components"): restraints.append(g.Composites.wear_text(item))
  else: restraints.append(g.Equipment.wear_text(item.name,item.slot))
 var collar=intake.get("collar",{})
 if not collar.is_empty(): restraints.append(g.Equipment.wear_text(collar.name,collar.slot))
 var toys: Array[String]=[]
 for item in intake.get("special",[]):
  var wear=g.SpecialEquipment.wear_text(item.type)
  if wear!="": toys.append(wear)
 var link_lines: Array[String]=[]
 for link in links: link_lines.append(g.Links.wear_text(link.name))
 return {
  "opening":g.ActionCopy.line("prison.intake.opening",{},true),
  "guard_intro":g.ActionCopy.line("prison.guard.intake",{},true),
  "restraints":restraints,
  "links":link_lines,
  "toys":toys,
  "milking":g.ActionCopy.line(climax.narration_cue,{},true),
  "closing":g.ActionCopy.line("prison.intake.closing",{},true),
  "guard_done":g.ActionCopy.line("prison.guard.intake_done",{},true),
  "climax":climax.duplicate(true)
 }

static func latest_inspection_scene(g) -> Dictionary:
 for index in range(g.state.logs.size()-1,-1,-1):
  var record=g.state.logs[index].data.get("prison_inspection_climax",{})
  if record is Dictionary and not record.is_empty(): return record
 return {}

static func latest_inspection_result(g) -> Dictionary:
 for index in range(g.state.logs.size()-1,-1,-1):
  var record=g.state.logs[index].data.get("inspection",{})
  if record is Dictionary and not record.is_empty(): return record
 return {}

static func intake_equipment(g) -> Dictionary:
 var rule=B.PRISON_INTAKE.get(g.state.security,{})
 var count=g.Cards.worn_count(g,false)
 var enough=not rule.is_empty() and count>=rule.floor
 var quota=0 if enough else (rule.floor-count+rule.extra if not rule.is_empty() else B.CAPTURE_EXTRA_BASE+g.state.security)
 var spec=equipment_spec(g,quota)
 # Intake links have their own quota and must not consume ordinary/root slots.
 spec.allow_links=false
 if not rule.is_empty(): spec.tier=2
 var installed=g.Application.execute(g,spec,"prison","prison").installed
 if not rule.is_empty():
  # Components change tightness, but only whole roots consume intake slots.
  for piece in g.physical_pieces():
   if g.Equipment.lock_only(piece): continue
   var current=g.tier(piece.durability,piece.maximum)
   var desired=mini(3,current+1) if enough else maxi(2,current)
   if desired>current:
    piece.durability=piece.maximum*[0.0,0.4,0.8,1.0][desired]
    g._refresh_equipment(piece)
  # Tightening a host can create fresh straps; they share the intake minimum.
  for piece in g.physical_pieces():
   if not g.Equipment.lock_only(piece) and g.tier(piece.durability,piece.maximum)<2:
    piece.durability=piece.maximum*0.8
    g._refresh_equipment(piece)
 var collar={}
 if g.state.security>=B.PRISON_COLLAR_LEVEL:
  var existing=g.state.equipment.filter(func(e):return g.Equipment.lock_only(e))
  if existing.is_empty(): collar=g._install_template("restriction_collar","neck",1.0,1.0,true,"prison",3)
  else: existing[0].locked=true
 var toys=toy_spec(g,rule.get("special",2),false)
 if not rule.is_empty(): toys.tier=2
 var special=g.Application.execute(g,toys,"prison","prison").installed
 return {"added":installed.map(func(e):return e.id),"special_added":special.map(func(e):return e.id),"collar_added":not collar.is_empty(),"before":count,"floor":rule.get("floor",0),"quota":quota,"enough":enough,"installed":installed.duplicate(true),"special":special.duplicate(true),"collar":collar.duplicate(true)}

static func intake_label(g) -> String:
 var rule=B.PRISON_INTAKE.get(g.state.security,{})
 # Security five has no intake row: PRISON_SECURITY[5] alone drives the highest-grade quota.
 if rule.is_empty(): return "五级进入规格最高的普通牢房：追加高级3档普通／复合拘束具与特殊装备，巡视间隔最短、不自动出狱。"
 return "拘束具保底%d件，不足时补齐并额外增加%d件、全部至少2档；已达保底则不补装，全部收紧1档，最多3档。另加%d件2档特殊装备，空位不足不替换。" % [rule.floor,rule.extra,rule.special]

# Intake and inspection share this source declaration; Application owns selection,
# batch counting and legal replacement. Special equipment remains a separate source.
static func equipment_spec(g, count: int, replace: bool=false) -> Dictionary:
 var rule=B.PRISON_SECURITY[g.state.security]
 return {"pool":"ordinary","templates":g.Equipment.TEMPLATES.keys().filter(func(id):return not g.Equipment.TEMPLATES[id].slots.is_empty()),"composites":g.EquipmentOffers.assembly_specs() if rule.composites else [],"grade":rule.grade,"tier":rule.tier,"count":count,"replace":replace}

static func equipment_label(g) -> String:
 var rule=B.PRISON_SECURITY[g.state.security]
 return "%s%s档%s拘束具" % [g.Equipment.GRADES[rule.grade],["","一","二","三"][rule.tier],"普通或复合" if rule.composites else "普通"]

static func toy_spec(g, count: int, replace: bool=false) -> Dictionary:
 var rule=B.PRISON_SECURITY[g.state.security]
 return {"pool":"special","templates":g.SpecialEquipment.prison_pool(rule.grade,g.state.security>=3,g.state.get("chastity_locks_enabled",false)),"grade":rule.grade,"tier":rule.tier,"count":count,"replace":replace}

static func toy_label(g) -> String:
 var rule=B.PRISON_SECURITY[g.state.security]
 return "%s性玩具%s" % [g.Equipment.GRADES[rule.grade],"（含飞机杯）" if g.state.security>=3 else ""]

static func refill_batteries(g) -> Array:
 var charged=[]
 for item in g.state.special_equipment:
  var maximum=int(g.SpecialEquipment.TYPES[item.type].duration)
  if maximum<=0: continue
  item.remaining=maximum
  charged.append(item.id)
 return charged

static func initial(g) -> Dictionary:
 var pool=ACTIVE_DISCOVERIES.duplicate()
 for i in range(pool.size()-1,0,-1):
  var j=g._random_index("prison",i+1)
  var swap=pool[i]; pool[i]=pool[j]; pool[j]=swap
 return {"served_turns":0,"sentence_extra":0,"active":true,"left":B.PRISON_INTERVALS[mini(B.PRISON_INTERVALS.size()-1,g.state.security-1)],"turn":0,"stage":"","missing":[],"baseline":g.state.capture.baseline.duplicate(),"special_missing":[],"special_baseline":g.state.capture.special_baseline.duplicate(),"discovery_pool":ACTIVE_DISCOVERIES.duplicate(),"discoveries":pool,"found":[],"vent_hits":0,"vent_tick":-1,"door_open":false,"key":false,"resisting":false,"checks":0,"report":""}

static func discoverable(p: Dictionary) -> Array:
 return p.discoveries.duplicate()

# Scenario initialization only; all subsequent actions use the ordinary prison pipeline.
static func start_practice(g) -> void:
 g.state.security=1;g._apply_transition("prison_cell_init",{"room":"prison"});g.state.wall="rough";g.state.wall_distance=0
 g.state.posture="lie"
 g.state.rooms.append({"id":"prison","name":"牢房","kind":"prison","wall":"rough","next":[],"floor":-1,"lane":0.5})
 var baseline=g.equipment_targets().map(func(e):return e.id)
 g.state.capture={"by":"牢房练习","security":1,"retained":baseline.duplicate(),"added":[],"links":[],"retained_special":[],"special_added":[],"special_baseline":[],"confiscated":0,"baseline":baseline}
 enter(g)
 g.RelicEffects._mana_hook(g,"prison_entry_mana","进入监狱")
 g._emit("event","你躺在墙边，手腕与大腿各有一件装备。先检查身上的装备，也可以开始探索牢房。")

# Security five is only the strongest ordinary cell: capture already applied PRISON_SECURITY[5],
# and entry follows the same path as one to four instead of a separate terminal scene.
static func enter(g) -> String:
 g.RelicEffects.begin_combat(g,"prison")
 g.state.prison=initial(g)
 g.state.prison.space=Space.initial(g)
 g.state.posture="lie";g.state.wall_distance=0
 # A new imprisonment restores the permanent deck; inspection itself only restores exhaust.
 g._reset_piles()
 g.state.enemies=[]
 g.room_data("prison").name="牢房"
 begin_turn(g)
 return ""

static func begin_turn(g) -> void:
 g._apply_transition("prison_cell_enter",{"phase":"prison"})
 g.state.prison.turn+=1
 g.state.heavy_used=false
 g._begin_player_turn()
 g._emit("event","牢房第%d回合，距离巡视还有%d回合。可挣脱、探索或处理出口。" % [g.state.prison.turn,g.state.prison.left])

static func end_turn(g) -> void:
 if g.state.prison.key:
  begin_turn(g)
  return
 g.state.prison.left-=1
 if g.state.prison.left>0:
  begin_turn(g)
  return
 g._apply_transition("inspection_start",{"phase":"inspection"}); g.state.prison.stage="arrival"
 # Keep the next-turn penalty while the non-turn inspection is on screen.
 g.state.overloaded=false; g.state.overload_count=0; g.state.energy=0
 g._emit("event","紫发狱警打开牢门，例行巡视开始。可以接受检查，或立即反抗。")

# 监狱显示点的事实构造（批 R5：行生产转发改显示事实构建）：形状恒为 prison＋action，extra 只带显示所需的
# 非提交字段（site／direction／steps／wall_warning 等），提交身份由 command_params 投影。
static func add(out: Array, g, action: String, label: String, copy, cost: int=0, reason: String="", extra: Dictionary={}) -> void:
 var payload={"kind":"prison","action":action}
 payload.merge(extra)
 out.append(g._fact(payload,label,copy,cost,0.0,reason,"","prison"))

# R3（docs/ondemand-copy.md §11.5）：Prison.add 各站点文案的 builder，正文留在本模块，路由只做分派。
static func enter_detail(_g, _args: Dictionary) -> String:
 return "牢门会在你身后锁上。"

static func inspection_detail(_g, args: Dictionary) -> String:
 return {"arrival":"让她核对你身上的装备。","result":"处理这次检查的结果。","done":"继续服刑。"}.get(String(args.get("stage","")),"")

static func resist_detail(_g, _args: Dictionary) -> String:
 return "与她战斗。胜利可取得牢门钥匙。"

static func vent_kick_detail(_g, _args: Dictionary) -> String:
 return "合法坐姿踢击一次推进1次，共需%d次；每回合一次。" % B.PRISON_VENT_HITS

static func vent_exit_detail(_g, _args: Dictionary) -> String:
 return "格栅开启后即可离开；不检查站姿移动速度。"

static func key_detail(_g, _args: Dictionary) -> String:
 return "钥匙不占道具容量；开门后可直接逃离，不检查行动速度。"

static func door_exit_detail(_g, _args: Dictionary) -> String:
 return "自行开锁后速度须至少1；狱警钥匙路线不检查速度。点击离开时重新判定。"

# 监狱显示事实（批 R5：行生产转发改显示事实构建，docs/spec/candidate-removal.md §2.1 T5／T8）。
static func facts(g) -> Array:
 var out=[]
 if g.state.phase=="captured":
  var enter_args={"security":g.state.security}
  add(out,g,"enter","进入牢房",{"kind":"prison.enter","args":enter_args,"fallback":enter_detail(g,enter_args)})
  return out
 if g.state.phase=="inspection":
  var stage=g.state.prison.stage
  var text={"arrival":["inspect","接受检查"],"result":["accept","让她继续"],"done":["resume","返回牢房"]}[stage]
  var stage_args={"stage":stage}
  add(out,g,text[0],text[1],{"kind":"prison.inspection","args":stage_args,"fallback":inspection_detail(g,stage_args)})
  add(out,g,"resist","反抗狱警",{"kind":"prison.resist","args":{},"fallback":resist_detail(g,{})})
  return out
 if g.state.phase!="prison": return out
 var p=g.state.prison
 out.append_array(Space.facts(g))
 var kick=g.kick_profile()
 var reason=""
 if "vent" not in p.found: reason="先探索找到通风口。"
 elif p.vent_hits>=B.PRISON_VENT_HITS: reason="格栅已经打开。"
 elif not Space.at(g,"vent"): reason="需要先到通风口前。"
 elif g.state.posture!="sit": reason="需要坐姿才能踢到墙脚的格栅。"
 elif kick.reason!="": reason=kick.reason
 elif p.vent_tick==g.state.tick: reason="本回合已经踢过格栅。"
 add(out,g,"vent_kick","踢击通风口",{"kind":"prison.vent_kick","args":{},"fallback":vent_kick_detail(g,{})},1,reason)
 add(out,g,"vent_exit","从通风口逃离",{"kind":"prison.vent_exit","args":{},"fallback":vent_exit_detail(g,{})},0,"先发现并踢开通风口格栅。" if p.vent_hits<B.PRISON_VENT_HITS else ("需要先到通风口前。" if not Space.at(g,"vent") else capacity_reason(g)))
 add(out,g,"key","使用牢门钥匙",{"kind":"prison.key","args":{},"fallback":key_detail(g,{})},0,"需要先击败巡视狱警，取得专用钥匙。" if not p.key else ("需要先到牢门前。" if not Space.at(g,"door") else ("牢门已经打开。" if p.door_open else "")))
 reason="牢门仍然上锁；可用手中的术式解锁牌，或击败狱警取得钥匙。" if not p.door_open else ""
 if reason=="" and not Space.at(g,"door"): reason="需要先到牢门前。"
 if reason=="" and not p.key and g.movement_profile().speed<1: reason="自行开锁逃离需要行动速度至少1；请先站起。"
 if reason=="": reason=capacity_reason(g)
 add(out,g,"door_exit","离开牢门",{"kind":"prison.door_exit","args":{},"fallback":door_exit_detail(g,{})},0,reason)
 out.append_array(unlock_facts(g))
 return out

# 牢门解锁事实（手牌域的手牌可用性输入，docs/spec/candidate-removal.md §2.1 T5／T8；批 R3）：
# 手牌上屏的术式解锁牌可用性与牢门显示点共用同一份事实。
static func unlock_facts(g) -> Array:
 var facts=[]
 if g.state.phase!="prison": return facts
 var p=g.state.prison
 for card in g.state.hand:
  if g.Cards.Rules.SPECS[card.type].mode!="unlock": continue
  var reason="牢门已经打开。" if p.door_open else ("需要先到牢门前。" if not Space.at(g,"door") else g.Cards.body_reason(g,card.type))
  var payload={"kind":"prison","action":"unlock","uid":card.uid,"type":card.type,"target":"prison_door","slot":"wrist","mode":"unlock","free":false}
  var door_args={"type":card.type}
  facts.append(g._fact(payload,g.B.CARD_NAMES[card.type]+" · 牢门",{"kind":"prison.unlock_door","args":door_args,"fallback":unlock_door_detail(g,door_args)},g.Cards.energy_cost(g,card.type,false),g.Cards.face_mana(g,card.type,false),reason,"","prison"))
 return facts

static func capacity_reason(g) -> String:
 return "随身道具超出容量，请在道具栏使用或放弃多出的工具。" if g.carried_items()>g.item_capacity() else ""

# R4（docs/ondemand-copy.md §11.5）：牢门解锁牌候选文案改走路由，正文留在本模块。
static func unlock_door_detail(g, args: Dictionary) -> String:
 var type=String(args.get("type",""))
 return "打出这张牌打开牢门；临时魔力优先抵扣耗魔。"+("随后可选择另一把外露锁。" if g.Cards.Rules.SPECS[type].get("hits",1)>1 else "")

static func execute(g, c: Dictionary) -> String:
 var action=c.payload.action
 if action=="enter": return enter(g)
 var p=g.state.prison
 match action:
  "explore":
   return Space.execute(g,c.payload)
  "vent_kick":
   p.vent_hits+=1; p.vent_tick=g.state.tick
   g._consume_charge()
   g._emit("event","你坐着踢向通风口格栅，进度%d/%d。%s" % [p.vent_hits,B.PRISON_VENT_HITS,"格栅已打开，可以逃离。" if p.vent_hits>=B.PRISON_VENT_HITS else "格栅尚未打开，下回合可再踢一次。"])
  "unlock": g.Cards.play(g,c)
  "key":
   p.door_open=true
   g._emit("event","你用狱警留下的钥匙打开牢门，可以直接逃离。")
  "vent_exit","door_exit": escape(g,action)
  "inspect":
   var current=g.equipment_targets().map(func(e):return e.id)
   p.missing=p.baseline.filter(func(id):return id not in current)
   var current_special=g.state.special_equipment.map(func(e):return e.id)
   p.special_missing=p.special_baseline.filter(func(id):return id not in current_special)
   p.stage="result"
   var findings=[]
   if not p.missing.is_empty(): findings.append("少了%d件拘束具。她准备再给你加上%d件%s。" % [p.missing.size(),p.missing.size()+B.PRISON_VIOLATION_EXTRA,equipment_label(g)])
   if not p.special_missing.is_empty(): findings.append("少了%d件性玩具。她又拿来了%d件%s。" % [p.special_missing.size(),p.special_missing.size()+1,toy_label(g)])
   if findings.is_empty(): findings.append("一件也没少。")
   var exposed_tools=g.state.items.filter(func(item):return item.mount!="carry").size()
   if exposed_tools>0: findings.append("牢房里的%d件工具也被她找到了。" % exposed_tools)
   p.report="".join(findings)
   g._emit("event",p.report)
  "accept":
   var equipment_violation=not p.missing.is_empty()
   var toy_violation=not p.special_missing.is_empty()
   var violation=equipment_violation or toy_violation
   var outcome={"count":0,"installed":[],"removed":[],"lost_links":[]}
   var requested=p.missing.size()+B.PRISON_VIOLATION_EXTRA if equipment_violation else 0
   if equipment_violation:
    var original_ids=g.equipment_targets().map(func(e):return e.id)
    outcome=g.Application.execute(g,equipment_spec(g,requested,true),"prison","prison")
    # Compare actual worn strength first. Only then tighten the surviving old
    # pieces; fresh roots keep their security profile and factory attachments.
    for id in original_ids:
     var e=g._equipment(id)
     if e.is_empty(): continue
     e.durability=e.maximum
     g._refresh_equipment(e)
   var toy_outcome={"count":0,"installed":[],"removed":[],"lost_links":[]}
   var toy_requested=p.special_missing.size()+1 if toy_violation else 0
   if toy_violation: toy_outcome=g.Application.execute(g,toy_spec(g,toy_requested,true),"prison","prison")
   var confiscated=0
   for item in g.state.items.duplicate():
    if violation or item.mount!="carry": g.state.items.erase(item); confiscated+=1
   p.baseline=g.equipment_targets().map(func(e):return e.id)
   p.special_baseline=g.state.special_equipment.map(func(e):return e.id)
   var restored=g.state.exhaust.size()
   for card in g.state.exhaust: card.retain_until=-1
   g.state.discard.append_array(g.state.exhaust); g.state.exhaust=[]
   var recharged=refill_batteries(g)
   var climax=inspection_climax(g,c.payload.get("temporary",false))
   var extension=B.PRISON_SENTENCE_PENALTY if violation or confiscated>0 else 0
   p.sentence_extra+=extension
   p.checks+=1; p.stage="done"
   var results=[]
   if equipment_violation:
    results.append("拘束具补回%d/%d件。" % [outcome.count,requested])
   if toy_violation:
    results.append("性玩具补回%d/%d件。" % [toy_outcome.count,toy_requested])
   if confiscated>0: results.append("没收工具%d件。" % confiscated)
   if recharged.size()>0: results.append("%d件性玩具已经充好电。" % recharged.size())
   if extension>0: results.append("刑期＋%d回合。" % extension)
   if results.is_empty(): results.append("检查结束。")
   p.report=" ".join(results)
   g._emit("event",p.report,{"inspection":{"temporary":c.payload.get("temporary",false),"sentence_extension":extension,"missing":p.missing.duplicate(),"requested":requested,"installed":outcome.installed.map(func(e):return e.id),"removed":outcome.removed.duplicate(),"lost_links":outcome.lost_links.duplicate(),"registered":p.baseline.size(),"special_missing":p.special_missing.duplicate(),"special_requested":toy_requested,"special_installed":toy_outcome.installed.map(func(e):return e.id),"special_removed":toy_outcome.removed.duplicate(),"special_registered":p.special_baseline.size(),"recharged":recharged,"confiscated":confiscated,"restored":restored,"climax":climax}})
  "resume":
   p.left=B.PRISON_INTERVALS[g.state.security-1]; p.stage=""; p.missing=[];p.special_missing=[]
   begin_turn(g)
  "resist":
   g.RelicEffects.end_combat(g)
   g.RelicEffects.begin_combat(g,"battle")
   p.resisting=true
   p.reinforcements=0
   # The battle keeps the cell position: state.wall_distance stays as the exploration
   # step left it, and after_preparation recomputes it from prison.space.position.
   g._apply_transition("prison_exit_battle_start",{"phase":"battle"}); g.state.round=0; g.state.encounter+=1
   g.state.kick_last=-10; g.state.heavy_used=false
   g.RelicEffects.clear_temporary(g)
   g.Pressure.clear_penalties(g)
   g._spawn_enemies("guard_solo")
   g._emit("event","你反抗巡视狱警，战斗开始。巡视暂停，消耗牌不会因反抗自动恢复。")
   g._emit("event","援军将在4回合后抵达，之后每4回合召来1名警卫；本场最多%d名。" % (1+g.state.security))
   g._start_round()
 return ""

static func won(g) -> void:
 if not g.state.prison.get("resisting",false): return
 g.state.prison.erase("reinforcements")
 g.state.prison.resisting=false; g.state.prison.key=true
 g._emit("event","击败巡视狱警，获得牢门钥匙；不占道具容量。奖励与整备后返回牢房，巡视继续暂停。")

static func reinforcements_active(g) -> bool:
 return g.state.phase=="battle" and g.state.room=="prison" and g.state.prison.get("active",false) and g.state.prison.get("resisting",false) and not is_exit_battle(g)

static func reinforcements_left(g) -> int:
 return maxi(0,4*(g.state.prison.get("reinforcements",0)+1)-(g.state.round-1))

static func tick_reinforcements(g) -> void:
 if not reinforcements_active(g) or g._all_gone(): return
 var count=g.state.prison.reinforcements
 if count>=1+g.state.security or g.state.round<4*(count+1): return
 var guard=g._append_enemies([{"type":"guard","grade":2}])[0]
 guard.reinforcement_round=g.state.round
 guard.acted_round=g.state.round;guard.intent=g._plan(guard)
 g.state.prison.reinforcements=count+1
 g._emit("event","援军抵达：%s加入战斗，从下一回合开始行动。已召来%d / %d名警卫。" % [guard.name,count+1,1+g.state.security],{"prison_reinforcements":{"enemy":guard.id,"count":count+1,"limit":1+g.state.security}})

static func reinforcement_issue(s: Dictionary) -> String:
 var p=s.prison
 if not p.has("reinforcements"):
  return "反抗战斗缺少援军进度，请重新开始此局。" if p.get("resisting",false) else ""
 if not p.reinforcements is int or p.reinforcements<0 or p.reinforcements>1+s.security: return "援军数量不正确。"
 if s.phase!="battle" or s.room!="prison" or not p.get("active",false) or not p.get("resisting",false): return "援军只能出现在牢房内的反抗战斗。"
 if p.reinforcements>int(maxi(0,s.round-1)/4): return "援军尚未到达对应回合。"
 return ""

static func after_preparation(g) -> bool:
 if is_exit_battle(g):
  return_to_tower(g)
  return true
 if not g.state.prison.get("active",false) or not g.state.prison.get("key",false): return false
 g.RelicEffects.begin_combat(g,"prison")
 g.state.prepare_left=0; g.state.rest_left=0
 g.state.enemies=[]
 g.state.wall_distance=Space.wall_distance(g.state.prison.space.position)
 begin_turn(g)
 return true

static func escape(g, route: String) -> void:
 g.RelicEffects.end_combat(g)
 g._leave_mounted_tools()
 g.Pressure.clear_penalties(g)
 g.state.prison={};g.state.capture={}
 g.state.practice=false
 g.state.map_region="prison"
 g.state.pressure_sources=g.state.pressure_sources.filter(func(s):return s.room=="")
 g.state.rooms=g.Tower.prison_route(g.state.security)
 # Keep the frozen tower encounter while its rooms are replaced by the escape route.
 var summit=g.state.room_encounters.get("summit","")
 g.state.room_encounters={"prison_gate":"guard_solo"}
 if summit!="": g.state.room_encounters.summit=summit
 g._apply_transition("prison_escape",{"room":"prison_start"});g.state.wall="normal";g.state.wall_distance=1
 g.state.room_event={};g.state.completed_rooms=[];g.state.traversed_edges=[];g.state.journey={}
 g.state.enemies=[];g._apply_transition("prison_escape",{"phase":"map"});g.state.energy=0
 g._emit("event",("传送符将你带离牢房。" if route=="return_seal" else ("你爬出通风口，离开牢房。" if route=="vent_exit" else "你穿过牢门，离开牢房。"))+"来到监狱出发点。前方是休息点和出口精英战，出口由%d名魅魔警卫把守。" % g.state.security)

static func is_exit_battle(g) -> bool:
 return g.state.map_region=="prison" and g.state.room=="prison_gate"

static func return_to_tower(g) -> void:
 g._restart_tower()

static func validate(g) -> String:
 var reinforcement_error=reinforcement_issue(g.state)
 if reinforcement_error!="": return reinforcement_error
 var p=g.state.prison
 if g.state.phase in ["prison","inspection"] and not p.get("active",false): return "牢房流程缺少入狱记录。"
 if p.is_empty(): return ""
 if p.served_turns<0 or p.sentence_extra<0 or p.sentence_extra%B.PRISON_SENTENCE_PENALTY!=0 or p.sentence_extra>p.checks*B.PRISON_SENTENCE_PENALTY: return "出狱期限记录不正确。"
 var space_issue=Space.validate(g)
 if space_issue!="": return space_issue
 if p.left<0 or p.left>B.PRISON_INTERVALS[mini(B.PRISON_INTERVALS.size()-1,g.state.security-1)] or p.vent_hits<0 or p.vent_hits>B.PRISON_VENT_HITS: return "巡视或通风口进度不合法。"
 var discovery_ids=p.discoveries+p.found
 var expected=p.get("discovery_pool",[])
 if expected!=ACTIVE_DISCOVERIES: return "牢房发现池与当前版本不符。"
 if discovery_ids.size()!=expected.size() or not expected.all(func(id):return discovery_ids.count(id)==1): return "牢房发现重复或缺失。"
 if p.vent_hits>0 and "vent" not in p.found: return "尚未发现通风口，不能有踢击进度。"
 if g.state.phase=="inspection" and (p.stage not in ["arrival","result","done"] or g.state.energy!=0): return "巡视阶段不合法。"
 if p.resisting and g.state.phase!="battle": return "反抗必须处于战斗阶段。"
 return ""

static func view(g) -> Dictionary:
 # prison_end survives only for saves written before security five became an ordinary cell.
 if g.state.phase=="prison_end": return {"terminal_text":"本局已经结束，可以查看最终装备或重新开始。"}
 var p=g.state.prison
 if p.is_empty(): return {"intake_rule":intake_label(g),"equipment_rule":equipment_label(g),"toy_rule":toy_label(g)} if g.state.phase=="captured" else {}
 var narrative=""
 var dialogue=""
 var visual=PATROL_GUARD
 var result_status="neutral"
 if g.state.phase=="inspection":
  if p.stage=="arrival":
   narrative=g.ActionCopy.line("prison.inspection.arrival",{},true)
   dialogue=g.ActionCopy.line("prison.guard.arrival",{},true)
  elif p.stage=="result":
   var exposed_tools=g.state.items.any(func(item):return item.mount!="carry")
   var violation=not p.missing.is_empty() or not p.special_missing.is_empty()
   narrative=g.ActionCopy.line("prison.inspection.result.violation" if violation else "prison.inspection.result.clean",{},true)
   dialogue=g.ActionCopy.line("prison.guard.result.violation" if violation else ("prison.guard.result.tools" if exposed_tools else "prison.guard.result.clean"),{},true)
   result_status="failure" if violation or exposed_tools else "success"
  elif p.stage=="done":
   var scene=latest_inspection_scene(g)
   narrative=g.ActionCopy.line(scene.get("narration_cue",""),{},true)
   dialogue=g.ActionCopy.line(scene.get("dialogue_cue",""),{},true)
   visual=scene.get("visual",PATROL_GUARD)
   result_status="failure" if int(latest_inspection_result(g).get("sentence_extension",0))>0 else "success"
 return {"sentence":sentence_label(g),"served_turns":p.served_turns,"sentence_limit":sentence_limit(g),"space":Space.view(g),"active":p.active,"left":p.left,"turn":p.turn,"stage":p.stage,"remaining":discoverable(p).size(),"found":p.found.duplicate(),"vent_hits":p.vent_hits,"vent_total":B.PRISON_VENT_HITS,"door_open":p.door_open,"key":p.key,"report":p.report,"checks":p.checks,"paused":p.key or p.resisting,"equipment_rule":equipment_label(g),"toy_rule":toy_label(g),"guard_visual":visual,"narrative":narrative,"guard_dialogue":dialogue,"result_status":result_status}

static func sentence_limit(g) -> int:
 var base=B.PRISON_SENTENCE[clampi(g.state.security-1,0,3)]
 return base+int(g.state.prison.get("sentence_extra",0)) if base>0 else 0

static func sentence_label(g) -> String:
 var served=int(g.state.prison.get("served_turns",0))
 var limit=sentence_limit(g)
 return "已服刑%d回合 · 不自动出狱" % served if limit==0 else "已服刑%d／%d回合 · 出狱剩余%d回合" % [served,limit,maxi(0,limit-served)]

static func completed_turn(g) -> bool:
 if not g.state.prison.get("active",false): return false
 # Only a completed cell turn advances the sentence or runs its due inspection.
 # Battle and post-battle preparation keep both clocks frozen, including on return.
 if g.state.phase!="prison": return false
 g.state.prison.served_turns+=1
 var limit=sentence_limit(g)
 if limit==0 or g.state.prison.served_turns<limit: return false
 if not release_inspection(g): return false
 var outcome=intake_equipment(g)
 g._emit("event","出狱检查通过。狱警按当前安全等级施加出狱装备后，你可以选择新塔路第10—11层的起点。",{"sentence_release":{"served":g.state.prison.served_turns,"limit":limit,"equipment":outcome},"npc_copy":{"cue":"prison.guard.release_pass","visual":SENIOR_GUARD}})
 g.RelicEffects.end_combat(g)
 g.Pressure.clear_penalties(g)
 g.CaptureBind.clear_bind(g)
 g.state.weakness_turns=0
 g.state.practice=false
 g._restart_tower()
 return true

static func release_inspection(g) -> bool:
 # Runs inside the completed-turn transaction. Do not enter the periodic
 # inspection phase or reset its countdown; a failed release resumes that turn.
 var p=g.state.prison
 var stage=p.stage
 var missing=p.missing.duplicate()
 var special_missing=p.special_missing.duplicate()
 var extra=p.sentence_extra
 g._emit("event","刑期已满，资深狱警前来进行出狱检查。",{"npc_copy":{"cue":"prison.guard.release_check","visual":SENIOR_GUARD}})
 execute(g,{"payload":{"action":"inspect","temporary":true}})
 execute(g,{"payload":{"action":"accept","temporary":true}})
 p.stage=stage;p.missing=missing;p.special_missing=special_missing
 if p.sentence_extra==extra: return true
 g._emit("event","出狱检查未通过，刑期延长8回合。",{"sentence_delayed":{"limit":sentence_limit(g),"extension":p.sentence_extra-extra},"npc_copy":{"cue":"prison.guard.release_fail","visual":SENIOR_GUARD}})
 return false

static func start_room(room: Dictionary) -> bool:
 var displayed_floor=int(room.get("floor",-2))+1
 return displayed_floor in [10,11] and room.get("kind","") in ["battle","event","shop"]

static func health_bonus(g, s: Dictionary) -> float:
 if s.get("map_region","")!="tower" or s.get("room","")=="prison": return 0.0
 var level=maxi(0,int(s.get("security",0))-1)
 var rooms=s.rooms.filter(func(room):return room.id==s.room)
 if rooms.is_empty(): return 0.0
 var room=rooms[0]
 var rank=g.Enemies.ENCOUNTERS.get(s.room_encounters.get(s.room,""),{}).get("rank","")
 return float(level*(30 if room.get("boss",false) or rank=="boss" else (20 if rank=="elite" else 10)))

static func exit_practice(g, kind: String) -> void:
 # Practice starts with the real intake result, including both equipment manifests.
 # The player enters the cell normally; neither the sentence nor patrol is skipped.
 g.Guard.capture(g,g.Enemies.TYPES.guard)
 if kind in ["prison_release","prison_release_violation"]: return
 enter(g)
 escape(g,"door_exit")
 g._apply_transition("prison_gate_init",{"room":"prison_gate"})
 g.state.completed_rooms=["prison_start","prison_rest"]
 g._start_battle()
