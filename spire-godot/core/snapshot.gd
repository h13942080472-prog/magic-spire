extends RefCounted

# Shape checks precede existing rule validators, so damaged nested data never reaches UI.
const Phases=preload("res://data/phases.gd")
const REVISION=55
const IRON_DRONE_REVISION=54
const REINFORCEMENT_STATE_REVISION=52
const CUP_STACK_REVISION=53
const INCOMPATIBLE="这份存档与当前版本不兼容，请从主界面开始新游戏。"
const SLOTS=["tower","practice"]
const PIECE="id:s name:s template:s material:s variant:i grade:i locked:b slot:s durability:n maximum:n source:s"

static func is_current(s: Dictionary) -> bool:
 return s.get("save_revision") is int and s.save_revision==REVISION

static func migrate_iron_drone(s: Dictionary, g) -> void:
 if not s.get("enemies") is Array: return
 for enemy in s.enemies:
  if enemy is Dictionary and enemy.get("type")=="iron_drone" and not enemy.has("guard"):
   enemy.guard=g.Guard.initial()

static func migrate_cup_stacks(s: Dictionary, g) -> String:
 if not s.get("special_equipment") is Array: return "性玩具列表不完整。"
 var containers=[s.special_equipment]
 var event=s.get("room_event",{})
 if event is Dictionary and event.get("held") is Dictionary:
  for held in event.held.values():
   if not held is Array: return "事件暂存装备记录损坏。"
   containers.append(held)
 var all_items=[]
 for items in containers: all_items.append_array(items)
 var issue=g.SpecialEquipment.validate(all_items,true)
 if issue!="": return issue
 var cups=all_items.filter(func(item):return g.SpecialEquipment.exclusive_family(item.type)=="cup")
 if cups.size()<2: return ""
 cups.sort_custom(func(a,b):return a.grade>b.grade if a.grade!=b.grade else int(a.id.trim_prefix("special_"))<int(b.id.trim_prefix("special_")))
 var removed=cups.slice(1).map(func(item):return item.id)
 for item in all_items:
  if item.owner_id in removed: removed.append(item.id)
 for items in containers:
  for item in items.duplicate():
   if item.id in removed: items.erase(item)
 # Migration is not a player removal; inspections must not punish repaired saves.
 for record in [s.get("capture",{}),s.get("prison",{})]:
  if not record is Dictionary: continue
  for key in ["retained_special","special_added","special_baseline","special_missing"]:
   if record.get(key) is Array: record[key]=record[key].filter(func(id):return id not in removed)
 if s.get("pressure_sources") is Array:
  s.pressure_sources=s.pressure_sources.filter(func(source):return not source is Dictionary or source.get("equipment","") not in removed)
 return ""

static func typed(value, kind: String) -> bool:
 match kind:
  "s": return value is String or value is StringName
  "i": return value is int
  "n": return (value is int or value is float) and is_finite(float(value))
  "b": return value is bool
  "d": return value is Dictionary
  "a": return value is Array
  "z": return value is Array and value.all(func(v):return v is String or v is StringName)
 return false

static func fields(value, specification: String) -> bool:
 if not value is Dictionary: return false
 for entry in specification.split(" ",false):
  var pair=entry.split(":")
  if not value.has(pair[0]) or not typed(value[pair[0]],pair[1]): return false
 return true

static func intent(p, g, depth: int=0) -> bool:
 if depth>1 or not fields(p,"kind:s text:s delayed:b"): return false
 if p.has("point") and (not p.point is String or (p.point!="" and (not p.has("slot") or p.point not in g.Equipment.points(p.slot)))): return false
 if p.has("pressure") and not typed(p.pressure,"n"): return false
 if p.has("random_target") and (p.kind not in ["tighten","lock"] or not p.random_target is bool): return false
 if p.has("quantity_gain") and (p.kind!="charge" or not p.quantity_gain is int or p.quantity_gain<1): return false
 if p.has("tighten_after") and (p.kind!="apply" or not p.tighten_after is bool): return false
 if p.has("tighten_missing") and (p.kind!="apply" or not p.tighten_missing is bool): return false
 if p.has("move") and not p.move is String: return false
 if p.has("ritual_gain") and (p.kind!="charge" or not p.ritual_gain is int or p.ritual_gain<=0): return false
 if p.has("pressure_effect") and (not p.pressure_effect is String or not g.Pressure.Data.TYPES.has(p.pressure_effect) or not g.Pressure.Data.TYPES[p.pressure_effect].has("duration")): return false
 if p.has("cancel_on_interrupt") and (p.kind!="capture" or not p.cancel_on_interrupt is bool or not p.cancel_on_interrupt): return false
 if p.has("climax_threshold") and (not p.get("cancel_on_interrupt",false) or not p.climax_threshold is int or p.climax_threshold<1): return false
 match p.kind:
  "apply":
   if p.has("profiles"):
    if not p.profiles is Array or p.profiles.is_empty(): return false
    if p.profiles.any(func(profile):return not fields(profile,"grade:i tier:i") or profile.size()!=2 or profile.grade not in [1,2,3] or profile.tier not in [1,2,3]): return false
   if not fields(p,"pool:s grade:i tier:i count:i") or p.pool not in ["ordinary","composite","special"] or p.grade not in [1,2,3] or p.tier not in [1,2,3] or p.count<1 or p.count>8: return false
   for key in ["replace","locked","final","shoulders"]:
    if p.has(key) and not p[key] is bool: return false
   if p.has("required_slots") and (not typed(p.required_slots,"z") or p.required_slots.is_empty() or p.required_slots.any(func(slot):return slot not in g.B.SLOTS)): return false
   for key in ["ready_gain","ready_layers"]:
    if p.has(key) and (not p[key] is int or p[key]<0): return false
   for key in ["templates","fallback_templates"]:
    if not p.has(key): continue
    if not p[key] is Array: return false
    for selector in p[key]:
     if p.pool=="composite":
      if g.EquipmentOffers.assembly_specs([selector]).is_empty(): return false
     elif not selector is String or not (g.SpecialEquipment.DESIGNS.has(selector) if p.pool=="special" else g.Equipment.TEMPLATES.has(selector)): return false
   if p.pool=="ordinary" and (not p.has("templates") or p.templates.is_empty()): return false
   if p.pool=="special" and (not fields(p,"templates:z") or p.templates.is_empty()): return false
   if p.has("preferred_slots") and (not typed(p.preferred_slots,"z") or p.preferred_slots.any(func(slot):return slot not in g.B.SLOTS)): return false
   if p.has("variants"):
    if not p.variants is Dictionary: return false
    for id in p.variants:
     if not g.Equipment.TEMPLATES.has(id) or not p.variants[id] is int or p.variants[id]<0 or p.variants[id]>=g.Equipment.MATERIALS[g.Equipment.TEMPLATES[id].material][p.grade].size(): return false
   return true
  "debuff": return fields(p,"effect:s turns:i") and p.effect=="weakness" and p.turns==1
  "tighten_budget": return fields(p,"budget:i") and p.budget in [2,4]
  "six_tune": return fields(p,"count:i grade:i") and p.count>=1 and p.count<=1024 and p.grade in [1,2]
  "six_prepare","six_opening","six_tease","six_composite","six_finale": return true
  "iron_restraints": return fields(p,"count:i grade:i tier:i reinforce:i") and p.count>=2 and p.count<=1024 and p.grade in [1,2,3] and p.tier in [1,2,3] and p.reinforce>=0 and p.reinforce<=4096
  "iron_composite": return fields(p,"grade:i tier:i special:i locks:i") and p.grade in [1,2,3] and p.tier in [1,2,3] and p.special>=0 and p.special<=1024 and p.locks>=0 and p.locks<=4096
  "iron_stunned","iron_bind_gain","iron_recharge","iron_upgrade": return true
  "carried_apply": return true
  "puppet_awaken","puppet_mend","puppet_composite","puppet_special": return p.size()==3
  "turn_install","split_burst": return true
  "equipment_batch": return fields(p,"count:i grade:i tier:i tighten:b templates:z operations:a") and p.count==2 and p.grade==2 and p.tier in [2,3] and p.operations.is_empty() and p.templates.all(func(id):return g.Equipment.TEMPLATES.has(id))
  "guard_sequence": return fields(p,"priority:b operations:a") and not p.priority and p.operations.size() in [1,2,3] and p.operations.all(func(op):return intent(op,g,depth+1) and op.kind in ["apply","install","assembly","shoulder","tighten","lock","idle"])
  "install": return fields(p,"template:s grade:i tier:i variant:i source:s final:b") and g.Equipment.TEMPLATES.has(p.template) and p.grade in [1,2,3] and p.tier in [1,2,3] and (not p.has("slot") or p.slot in g.B.SLOTS) and p.variant>=0 and p.variant<g.Equipment.MATERIALS[g.Equipment.TEMPLATES[p.template].material][p.grade].size()
  "special_install": return fields(p,"type:s slot:s") and g.SpecialEquipment.DESIGNS.has(p.type) and p.slot==g.SpecialEquipment.DESIGNS[p.type].slots[0]
  "link": return fields(p,"template:s ends:z slots:z contact_points:z name:s grade:i tier:i source:s final:b") and p.template=="link_rope" and p.grade in [1,2,3] and p.tier in [1,2,3] and p.ends.size()==2 and p.ends[0]!=p.ends[1] and p.slots.size()==2 and p.contact_points.size()==2 and g.Links.adjacent(p.contact_points[0],p.contact_points[1]) and p.slots==p.contact_points.map(g.Links.point_slot)
  "pause": return true
  "shoulder": return fields(p,"target:s template:s grade:i tier:i source:s") and g.Equipment.base_template(p.template) in g.Shoulders.BASES and p.grade in [1,2,3] and p.tier==p.grade
  "assembly": return fields(p,"family:s variant:s straps:s grade:i tier:i source:s") and not g.Composites.spec(p.family,p.variant,p.straps).is_empty() and p.grade in [1,2,3] and p.tier in [1,2,3]
  "lock","tighten": return (not p.has("target") or fields(p,"target:s")) and (not p.has("final") or p.final is bool) and (not p.has("tier") or (p.tier is int and p.tier==3))
  "charge","leave","idle","capture","bind_prepare","bind_apply","bind_gain": return not p.has("target") or p.target is String
 return false

static func effect(e, g) -> bool:
 if not fields(e,"op:s"): return false
 if e.has("replace") and not e.replace is bool: return false
 if e.has("wear_style") and (not e.wear_style is String or e.wear_style not in g.Equipment.WEAR_STYLES): return false
 if e.has("point") and (not fields(e,"point:s slot:s") or (e.point!="" and e.point not in g.Equipment.points(e.slot))): return false
 for key in ["ref","target","ref_target"]:
  if e.has(key) and not e[key] is String: return false
 match e.op:
  "link":
   var plan=e.duplicate(true)
   plan.kind="link";plan.text=e.get("name","链接绳");plan.delayed=false;plan.final=false;plan.source="event"
   return not e.get("locked",false) and intent(plan,g)
  "special_install": return fields(e,"type:s slot:s") and g.SpecialEquipment.TYPES.has(e.type) and e.slot in g.SpecialEquipment.DESIGNS[e.type].slots
  "install": return fields(e,"template:s slot:s grade:i tier:i locked:b") and g.Equipment.definition_reason(e.template,e.slot,e.grade,e.locked)=="" and e.tier in [1,2,3]
  "assembly": return fields(e,"family:s variant:s straps:s part:s") and not g.Composites.spec(e.family,e.variant,e.straps).is_empty()
  "tighten","unlock": return e.has("target") or e.has("ref_target")
  "tighten_to": return fields(e,"target:s tier:i") and e.tier in [1,2,3]
  "mana_loss","mana_gain","flask_mana_gain": return fields(e,"amount:n") and e.amount>=0
  "mana_restore_full": return e.size()==1
  "mana_max_loss": return fields(e,"amount:n") and e.amount>=1 and e.amount<=100
  "pressure": return fields(e,"amount:n") and e.amount>=0 and (not e.has("source") or e.source is String)
  "card": return fields(e,"type:s") and g.Cards.Rules.SPECS.has(e.type)
  "tool": return fields(e,"type:s") and g.Tools.TYPES.has(e.type)
  "relic": return fields(e,"type:s") and g.Relics.TYPES.has(e.type)
  "hold_special": return fields(e,"key:s slots:z") and e.slots.all(func(slot):return slot in g.SpecialEquipment.slots())
  "restore_held": return fields(e,"key:s")
  "transform_card": return fields(e,"target:s type:s") and g.Cards.Rules.SPECS.has(e.type)
  "remove_card": return fields(e,"target:s")
  "remove_restraints": return fields(e,"targets:z") and e.targets.size()>=1 and e.targets.size()<=4 and e.targets.all(func(id):return e.targets.count(id)==1)
  "ease_restraint": return fields(e,"target:s")
  "counter": return fields(e,"key:s amount:i") and e.amount!=0
 return false

static func selected_target(value) -> bool:
 var rows=value if value is Array else [value]
 if rows.is_empty() or rows.size()>4: return false
 var ids=[]
 for row in rows:
  if not fields(row,"id:s name:s type:s kind:s slot:s") or row.kind not in ["card","restraint"] or row.id in ids: return false
  ids.append(row.id)
 return true

static func selected_suffix(value) -> String:
 var rows=value if value is Array else [value]
 return "__"+"__".join(rows.map(func(row):return row.id))

static func check(s: Dictionary, g) -> String:
 var character_issue=g.Character.validate(g,s)
 if character_issue!="": return character_issue
 var demo_issue=g.DemoExit.validate(s)
 if demo_issue!="": return demo_issue
 for key in g.state:
  if key in ["character_id","witch_charges","witch_focus"]: continue
  if not s.has(key): return "缺少必要的进度记录。"
  var reference=g.state[key]
  if reference is int or reference is float:
   if not typed(s[key],"n") or (reference is int and not s[key] is int): return "基础数值类型不正确。"
  elif typeof(s[key])!=typeof(reference): return "进度记录类型不正确。"
 if not fields(s.combat,"serial:i active:b first_turn:b energy:i mana_spent:n mana_used:b successful_spells:z") or s.combat.serial<0 or s.combat.energy<0 or s.combat.mana_spent<0: return "战斗触发进度损坏。"
 if not fields(s,"relic_seen:z battle_relic_drop:s") or s.relic_seen.any(func(id):return not g.Relics.is_reward(id,"shop") or s.relic_seen.count(id)!=1): return "遗物抽取记录损坏。"
 if s.battle_relic_drop!="":
  var claimed_relic=s.reward_claimed.get("relic","")
  if not g.Relics.is_reward(s.battle_relic_drop) or s.battle_relic_drop not in s.relic_seen: return "战斗遗物领取记录损坏。"
  if claimed_relic==s.battle_relic_drop and s.battle_relic_drop not in s.relics: return "战斗遗物领取记录损坏。"
  if claimed_relic not in [s.battle_relic_drop,"skip"] and (claimed_relic!="" or not g.Relics.can_gain(s.relics,s.battle_relic_drop)): return "战斗遗物领取记录损坏。"
 if not typed(s.boss_relic_options,"z") or s.boss_relic_options.size()>3: return "Boss遗物选项损坏。"
 var prison_exit=s.map_region=="prison" and s.room=="prison_gate"
 if s.tower_start_pending and (s.phase!="map" or s.map_region!="tower" or s.room!="tower_bottom" or not s.prison.is_empty() or not s.journey.is_empty()): return "出狱起点选择阶段不正确。"
 if s.battle_flask_drop not in [0,g.B.PRISON_EXIT_FLASK_MANA if prison_exit else g.B.BOSS_FLASK_MANA]: return "Boss魔瓶奖励数值损坏。"
 if s.battle_flask_drop>0 and (s.phase!="reward" or (s.boss_relic_options.is_empty() and not prison_exit)): return "Boss魔瓶奖励阶段损坏。"
 if s.reward_claimed.has("flask") and s.reward_claimed.flask!="boss_mana": return "Boss魔瓶奖励领取记录损坏。"
 if s.phase=="reward" and s.reward_claimed.has("flask") and s.battle_flask_drop==0: return "Boss魔瓶奖励领取记录缺少对应奖励。"
 if not s.boss_relic_options.is_empty():
  if s.phase!="reward" or s.battle_relic_drop!="" or not s.rooms.any(func(room):return room is Dictionary and room.get("id","")==s.room and room.get("boss",false)==true): return "Boss遗物奖励阶段损坏。"
  for id in s.boss_relic_options:
   if (id not in g.Relics.BOSS_POOL and id!=g.Relics.FALLBACK) or s.boss_relic_options.count(id)!=1 or id not in s.relic_seen: return "Boss遗物候选记录损坏。"
   if id!=g.Relics.FALLBACK and id in s.relics and s.reward_claimed.get("relic","")!=id: return "Boss遗物重复领取。"
  if s.reward_claimed.has("relic") and s.reward_claimed.relic!="skip" and (s.reward_claimed.relic not in s.boss_relic_options or s.reward_claimed.relic not in s.relics): return "Boss遗物领取记录损坏。"
 if not typed(s.get("temporary_mana"),"n") or s.temporary_mana<0: return "临时魔力记录损坏。"
 if not typed(s.mana_max,"n") or s.mana_max<g.B.MANA_MAX_FLOOR: return "魔力上限损坏。"
 if s.map_region not in ["tower","prison"]: return "地图区域不存在。"
 if not s.weakness_turns is int or s.weakness_turns not in [0,1] or (not g.RelicEffects.keeps_combat_state(g) and s.weakness_turns!=0): return "无力化持续时间损坏。"
 if s.phase not in Phases.DEFINITIONS or s.posture not in g.B.POSE_NAMES or s.order not in ["first","last"] or s.wall not in ["rough","normal","none"]: return "当前阶段或姿态不存在。"
 if s.last_strong_group!="" and g.Enemies.ENCOUNTERS.get(s.last_strong_group,{}).get("rank","")!="strong": return "上一场强怪组合记录损坏。"
 if not s.wall_distance is int or s.wall_distance<0 or s.wall_distance>4: return "距墙距离损坏。"
 if s.save_slot not in SLOTS or (s.practice and s.save_slot!="practice"): return "存档所属模式不正确。"
 if s.security<0 or s.security>5 or s.version<1 or s.version>=9223372036854775807 or not g.Tower.all_practices().has(s.practice_kind): return "进度版本、练习或安全等级无效。"
 for key in ["round","tick","encounter","energy","charge","next_energy","prepare_left","rest_left","hook_uses","reward_count","tower_generation","travel_turns","draw_serial"]:
  if not s[key] is int or s[key]<0: return "回合、资源或次数记录不合法。"
 if not fields(s,"calm_uses:i") or s.calm_uses<0 or s.calm_uses>g.B.CALM_USES_PER_TURN: return "本回合深呼吸次数不正确。"
 if s.rng.size()!=g.B.RNG_SALTS.size() or g.B.RNG_SALTS.keys().any(func(domain):return not s.rng.get(domain) is int or s.rng[domain]<0): return "随机进度不完整。"
 if not s.guard_bind.is_empty():
  if not fields(s.guard_bind,"progress:n sources:d") or s.guard_bind.progress<=0 or s.guard_bind.progress>g.CaptureBind.BIND_MAXIMUM or s.phase!="battle": return "捕缚进度记录损坏。"
  if s.guard_bind.sources.is_empty(): return "捕缚缺少来源。"
  for source_kind in s.guard_bind.sources:
   var source=s.guard_bind.sources[source_kind]
   if not fields(source,"enemy:s energy:i") or source.energy<0 or source.energy>=g.CaptureBind.energy_threshold(g,source_kind): return "捕缚来源或能量计数损坏。"
   if source.has("skip_turn_start") and not source.skip_turn_start is bool: return "捕缚回合开始记录损坏。"
 if not fields(s,"completed_rooms:z relics:z reward_options:z rest_cards:z"): return "奖励或房间记录不完整。"
 var form_issue=g.Relics.form_issue(s)
 if form_issue!="": return form_issue
 if s.get("ditto_form","")!="" and not g.Character.relic_allowed(g,s.ditto_form,s.get("character_id","original")): return "百变怪形态来源不正确。"
 var bundle_issue=g.RelicBundle.validate(g,s)
 if bundle_issue!="": return bundle_issue
 var departure_issue=g.Departure.validate(g,s)
 if departure_issue!="": return departure_issue
 if not fields(s,"card_buffs:z card_buff_uses:d turn_strength:i evasion:i rare_offset:i") or s.rare_offset<g.Cards.Rules.RARE_OFFSET_INITIAL or s.rare_offset>g.Cards.Rules.RARE_OFFSET_MAX: return "卡牌增益或奖励修正记录不正确。"
 if not fields(s,"sure_cast:b item_drop_chance:i battle_item_drop:s"): return "道具掉落或定咒记录不完整。"
 var body_buff_issue=g.Consumables.validate_buffs(g,s.get("body_buffs"))
 if body_buff_issue!="": return body_buff_issue
 for id in s.relic_pending:
  var pending=s.relic_pending[id]
  if id not in s.relics or not g.Relics.TYPES.has(id) or not fields(pending,"op:s amount:n"): return "遗物待发放记录不正确。"
  if pending.op not in ["charge","draw","mana","pressure"] or pending.op!=g.Relics.trigger(id,s.get("ditto_form","")).get("op","") or pending.amount<0: return "遗物待发放效果不正确。"
  if pending.op!="mana" and not pending.amount is int: return "遗物待发放数量必须是整数。"
  if pending.op=="pressure" and pending.amount%g.Relics.trigger(id,s.get("ditto_form","")).amount!=0: return "遗物快感触发数量不正确。"
 if s.relic_used.values().any(func(v):return not v is int): return "临时增益记录不正确。"
 if not s.card_chain.is_empty() and not fields(s.card_chain,"type:s slot:s mode:s remaining:i"): return "连续卡牌记录不完整。"
 if s.card_chain.has("replay_count") and (not typed(s.card_chain.replay_count,"i") or s.card_chain.replay_count<1 or not s.card_chain.has("replay_targets")): return "连续卡牌的复放次数损坏。"
 if s.card_chain.has("replay_targets") and (not typed(s.card_chain.replay_targets,"a") or s.card_chain.replay_targets.any(func(p):return not fields(p,"slot:s target:s self_target:b"))): return "连续卡牌的复放目标记录损坏。"
 if s.pending_retain and (s.hand.is_empty() or not s.card_chain.is_empty()): return "保留手牌阶段不正确。"
 # Ownership may change after offers freeze (e.g. a relic claimed before cards).
 if s.relics.any(func(id):return not g.Relics.TYPES.has(id)): return "遗物定义不存在。"
 var reward_count=3+int(g.Relics.value(s.relics,"reward_card_options",s.relic_counters))
 var reward_counts=[3,reward_count]
 # Frozen offers outlive Ditto rerolls; accept counts from any eligible prior form.
 if "ditto" in s.relics:
  for id in g.Relics.TYPES:
   if g.Relics.transformable(id) and g.Character.relic_allowed(g,id,s.get("character_id","original")):
    var count=reward_count+int(g.Relics.TYPES[id].modifiers.get("reward_card_options",0))
    if count not in reward_counts: reward_counts.append(count)
 for pool in [s.reward_options,s.rest_cards]:
  if pool.size() not in [0]+reward_counts or pool.any(func(id):return not g.Character.reward_member(g,id,s.get("character_id","original")) or pool.count(id)!=1): return "奖励牌结果重复或不存在。"
 if s.phase=="rest_choice" and (s.rest_left!=g.B.REST_TURNS or s.rest_cards.size() not in reward_counts): return "休息前的回合数或卡牌选项不完整。"
 if not s.rest_cards.is_empty():
  if s.rest_cards.any(func(id):return g.Cards.Rules.SPECS[id].rarity!="uncommon"): return "休息选牌必须为罕见卡。"
 var event_item_reward=s.phase=="reward" and s.room_event.get("stage","")=="loot"
 if s.phase=="reward" and not event_item_reward and s.reward_options.size() not in reward_counts: return "缺少已确定的卡牌奖励。"
 if event_item_reward and (not s.reward_options.is_empty() or not s.boss_relic_options.is_empty() or s.battle_item_drop!="" or s.battle_relic_drop!="" or not s.reward_claimed.is_empty()): return "事件道具奖励混入了战斗奖励记录。"
 for zone in ["deck"]+g.Cards.ZONES:
  for c in s[zone]:
   if c.has("exhaust_after_play") and (zone!="play" or c.exhaust_after_play!=true): return "卡牌消耗记录不正确。"
   if not fields(c,"uid:s type:s retain_until:i") or not g.Cards.Rules.SPECS.has(c.type): return "卡牌记录损坏或类型不存在。"
   var practice_issue=g.Character.Expansion.validate_card(g,c)
   if practice_issue!="": return practice_issue
   if c.has("draw_serial") and (not c.draw_serial is int or c.draw_serial<0): return "卡牌的抽取记录损坏。"
   if c.has("draw_free") and not c.draw_free is bool: return "卡牌的抽取牌面损坏。"
   if c.has("power_failure_count") and (zone!="powers" or not typed(c.power_failure_count,"i") or c.power_failure_count<0 or c.power_failure_count>2): return "能力牌的本回合失败记录损坏。"
   if c.has("power_cast_count") and (zone!="powers" or not typed(c.power_cast_count,"i") or c.power_cast_count<0): return "能力牌的本回合出牌记录损坏。"
   if c.has("power_stacks") and (zone!="powers" or not c.power_stacks is int or c.power_stacks<2): return "能力牌的额外生效记录损坏。"
   if c.has("power_pressure_progress") and (zone!="powers" or not typed(c.power_pressure_progress,"n") or c.power_pressure_progress<0): return "能力牌的累计快感记录损坏。"
   if c.has("power_mana_progress") and (zone!="powers" or not typed(c.power_mana_progress,"n") or c.power_mana_progress<0): return "能力牌的累计耗魔记录损坏。"
   if c.has("power_next_draw") and (zone!="powers" or not c.power_next_draw is int or c.power_next_draw<0): return "能力牌的下回合抽牌记录损坏。"
 var room_ids=[]
 for r in s.rooms:
  if not fields(r,"id:s name:s kind:s wall:s next:z floor:i lane:n") or r.id in room_ids or r.kind not in ["battle","rest","event","exit","entry","prison","shop","treasure"] or r.wall not in ["rough","normal","none"]: return "地图房间记录不完整。"
  room_ids.append(r.id)
  if r.kind=="battle" and (not s.room_encounters.has(r.id) or s.room_encounters[r.id] not in g.Enemies.ENCOUNTERS): return "房间缺少已确定的敌人组合。"
  if r.has("encounter_repeats") and (r.kind!="battle" or not r.encounter_repeats is int or r.encounter_repeats<1 or r.encounter_repeats>5 or g.Enemies.ENCOUNTERS[s.room_encounters[r.id]].has("weak_strength")): return "房间敌人组数不正确。"
  if r.has("requires_defeat") and (r.kind!="battle" or not r.requires_defeat is bool): return "房间胜利要求不正确。"
  if r.has("enemy_members"):
   if not r.enemy_members is Array or r.enemy_members.is_empty() or not r.enemy_members.all(func(m):return fields(m,"type:s grade:i") and m.type in g.Enemies.TYPES and m.grade in [1,2,3] and g.Enemies.TYPES[m.type].get("strength",0)>0): return "房间敌人名单损坏。"
   var definition=g.Enemies.ENCOUNTERS.get(s.room_encounters.get(r.id,""),{})
   if not definition.has("weak_strength"): return "房间敌人组合不符合生成要求。"
   var remaining=r.enemy_members.duplicate(true)
   for member in definition.get("fixed_members",[]):
    if member not in remaining: return "房间缺少指定种类的敌人。"
    remaining.erase(member)
   if definition.has("family"):
    var variants=g.Enemies.ENCOUNTERS[definition.family].variants
    var matched=false
    for variant in variants:
     var required=g.Enemies.ENCOUNTERS[variant].members
     if required.all(func(m):return m in remaining):
      for member in required: remaining.erase(member)
      matched=true;break
    if not matched: return "房间缺少指定种类的敌人。"
   var weak_members=[]
   for id in g.Enemies.FirstFloor.choices("weak"): weak_members.append_array(g.Enemies.ENCOUNTERS[id].members)
   if definition.has("max_weak_strength") and remaining.any(func(m):return g.Enemies.TYPES[m.type].strength>definition.max_weak_strength): return "房间敌人强度不符合组合要求。"
   if definition.get("unique_weak_types",false) and remaining.any(func(m):return remaining.filter(func(other):return other.type==m.type).size()>1): return "房间的小怪种类不能重复。"
   if remaining.any(func(m):return m not in weak_members) or remaining.reduce(func(total,m):return total+int(g.Enemies.TYPES[m.type].strength),0)!=definition.weak_strength: return "房间敌人组合不符合生成要求。"
  if r.kind=="battle" and g.Enemies.ENCOUNTERS[s.room_encounters[r.id]].has("weak_strength") and r.has("encounter_selected") and not r.has("enemy_members"): return "缺少已确定的房间敌人名单。"
  if r.has("encounter_choices"):
   if not fields(r.encounter_choices,"weak:s strong:s"): return "房间敌人池损坏。"
   for rank in ["weak","strong"]:
    var id=r.encounter_choices[rank]
    if rank=="strong" and id=="": continue
    if id not in g.Enemies.ENCOUNTERS or g.Enemies.ENCOUNTERS[id].rank!=rank: return "房间敌人池损坏。"
   if r.get("encounter_selected","")=="strong" and r.encounter_choices.strong=="": return "房间尚未配置强怪遭遇。"
  if r.has("encounter_selected") and r.encounter_selected not in ["weak","strong"]: return "房间遭遇进度损坏。"
  if r.get("pool","")=="strong" and r.has("encounter_choices") and r.get("encounter_selected","strong")!="strong": return "房间遭遇进度损坏。"
  if r.kind=="event" and r.has("event") and (not r.event is String or (r.event!="" and r.event not in g.Events.Data.TYPES)): return "事件房类型不存在。"
 if s.room not in room_ids or s.completed_rooms.any(func(id):return id not in room_ids): return "当前房间或已完成房间不存在。"
 var history_issue=g.Events.history_issue(s)
 if history_issue!="": return history_issue
 if s.map_region=="prison" and s.room!="prison":
  var route=s.rooms.filter(func(room):return room.kind!="prison")
  var route_security=s.security
  var encounters=s.room_encounters.duplicate()
  if encounters.get("summit","") in g.Enemies.FirstFloor.SUMMIT_ENCOUNTERS: encounters.erase("summit")
  if route_security<1 or route!=g.Tower.prison_route(route_security) or encounters!={"prison_gate":"guard_solo"}: return "监狱路线或出口警卫数量不正确。"
 for r in s.rooms:
  if r.next.any(func(id):return id not in room_ids) or (r.has("requires_clear") and r.requires_clear not in room_ids): return "地图连接的房间不存在。"
 for edge in s.traversed_edges:
  if not typed(edge,"z") or edge.size()!=2 or edge.any(func(id):return id not in room_ids): return "已走路线记录损坏。"
 if not s.journey.is_empty():
  if not fields(s.journey,"from:s target:s total:i remaining:i speed:n mode:s") or s.journey.from!=s.room or s.journey.target not in room_ids or s.journey.speed<=0: return "移动进度损坏。"
  var room=s.rooms.filter(func(r):return r.id==s.room)[0]
  if s.journey.target not in room.next: return "移动目标不与当前房间相连。"
 var physical_ids=[]
 for e in s.equipment:
  if not fields(e,PIECE+" layer:i"): return "装备记录不完整。"
  var binding_issue=g.Binding.validate(g,e)
  if binding_issue!="": return binding_issue
  var shoulder_issue=g.Shoulders.validate_host(g,e)
  if shoulder_issue!="": return shoulder_issue
  for shoulder in e.get("shoulders",{}).get("pieces",[]): physical_ids.append(shoulder.id)
  physical_ids.append(e.id)
 for root in s.composites:
  if not fields(root,"id:s name:s kind:s variant:s straps:s layer:i components:a"): return "复合装备记录不完整。"
  if root.kind=="head" and not fields(root,"attached_to:s"): return "头部结构缺少连接记录。"
  for e in root.components:
   if e.has("binding"): return "复合组件不能附加普通单件的躯干固缚。"
   if not fields(e,PIECE+" layer:i part:s root_id:s coverage:z contact_slots:z") or e.coverage.any(func(slot):return slot not in g.B.SLOTS): return "装备组件记录不完整。"
   if e.template=="glove_strap":
    var shoulder_issue=g.Shoulders.crossed_issue(g,e)
    if shoulder_issue!="": return shoulder_issue
   physical_ids.append(e.id)
 for link in s.links:
  if link.has("binding"): return "连接绳不能附加普通单件的躯干固缚。"
  if not fields(link,PIECE+" ends:z slots:z contact_points:z blocked_slip:z") or link.contact_points.size()!=2: return "连接绳缺少完整的具体连接位置，请重新开始此局。"
  physical_ids.append(link.id)
 for e in s.equipment+s.links:
  if e.slot not in g.B.SLOTS and not (e.slot=="neck" and g.Equipment.lock_only(e)): return "装备部位不存在。"
 for e in s.equipment+s.links+s.composites.reduce(func(all,root):return all+root.components,[]):
  for definition in ["coverage:z","contact_slots:z","points:z","side:s","independent:b","slip_allowed:b"]:
   var key=definition.split(":")[0]
   if e.has(key) and not fields(e,definition): return "装备附属记录类型不正确。"
 for item in s.items:
  if not fields(item,"id:s type:s uses:i mount:s") or item.mount not in g.Tools.MOUNTS: return "道具记录不完整。"
 for e in s.enemies:
  if not fields(e,"id:s type:s name:s hp:n max_hp:n grade:i stage:i ready_layers:i gone:b defeated:b intent:d pressure_gain:n") or e.type not in g.Enemies.TYPES: return "敌人记录不完整。"
  var visual_pool=g.Enemies.TYPES[e.type].get("visual_pool",[])
  if visual_pool.is_empty() and e.has("visual_variant"): return "该敌人不应保存立绘变体。"
  if not visual_pool.is_empty() and (not fields(e,"visual_variant:s") or e.visual_variant not in visual_pool): return "敌人立绘变体不存在。"
  if e.ready_layers<0 or (e.ready_layers>0 and not g.Enemies.TYPES[e.type].get("humanoid",false)): return "敌人准备就绪层数损坏。"
  if g.Enemies.TYPES[e.type].has("ritual_gain"):
   if not fields(e,"ritual:i application_bonus:i") or e.ritual<0 or e.application_bonus<0: return "敌人仪式记录损坏。"
  elif g.Enemies.TYPES[e.type].has("quantity_gain"):
   if not fields(e,"application_bonus:i last_move:s move_streak:i") or e.application_bonus<0 or e.move_streak<0: return "敌人强化记录损坏。"
   var moves=g.Enemies.TYPES[e.type].weighted_moves
   if e.last_move=="" and e.move_streak!=0: return "敌人行动历史损坏。"
   if e.last_move!="" and (e.last_move not in moves or e.move_streak<1 or e.move_streak>moves[e.last_move].limit): return "敌人行动历史损坏。"
  elif e.has("ritual") or e.has("application_bonus"): return "该敌人没有施加数量加成。"
  if g.Enemies.behavior(e.type)=="six_bind":
   var capture_step=g.Enemies.TYPES[e.type].climax_capture_threshold
   if not fields(e,"constriction:i next_climax_capture:i") or e.constriction<0 or e.constriction>1023 or e.next_climax_capture<capture_step or e.next_climax_capture>s.overload_total+capture_step: return "六缚的收束或逮捕记录损坏。"
   if e.intent.get("kind","")=="six_tune" and (e.intent.count!=1+e.constriction or e.intent.grade!=(1 if e.stage<3+g.EnemyPlans.SIX_CYCLE_LENGTH else 2)): return "六缚的调教升温数量或品质不正确。"
   if e.intent.get("cancel_on_interrupt",false) and (s.overload_total<e.next_climax_capture or e.intent.get("climax_threshold",0)!=e.next_climax_capture): return "六缚的高潮逮捕意图与当前记录不一致。"
  elif e.has("constriction") or e.has("next_climax_capture") or e.intent.get("cancel_on_interrupt",false): return "该敌人不应具有六缚专属记录。"
  var iron_issue=g.IronMan.validate(g,e,s.enemies,s)
  if iron_issue!="": return iron_issue
  if not e.intent.is_empty() and not intent(e.intent,g): return "已公开的敌人行动记录损坏。"
  var carried_issue=g.EnemyPlans.carried_reason(g,e)
  if carried_issue!="": return carried_issue
  if e.intent.has("move") and e.intent.move not in g.Enemies.TYPES[e.type].get("weighted_moves",{}): return "敌人行动分支损坏。"
  if e.intent.has("quantity_gain") and e.intent.quantity_gain!=g.Enemies.TYPES[e.type].get("quantity_gain",0): return "敌人强化数值与来源不符。"
  if e.intent.has("ritual_gain") and e.intent.ritual_gain!=g.Enemies.TYPES[e.type].get("ritual_gain",0): return "敌人行动中的仪式数值与来源不符。"
  if not e.gone and e.intent.is_empty() and not (s.phase=="battle" and e.get("acted_round",-1)==s.round and fields(e,"last_intent:s")): return "敌人缺少已公开行动。"
  if e.has("prepared") or e.has("attachment") or e.has("final_target"): return "敌人行动记录仍为旧的目标格式。"
  if e.has("turn_install_active"): return "持续施加记录使用了旧版格式。"
  if e.intent.get("kind","")=="turn_install" and not g.Enemies.TYPES[e.type].has("turn_install_effect"): return "敌人没有这种持续施加效果。"
  if e.has("turn_install_layers"):
   var effect=g.Enemies.TYPES[e.type].get("turn_install_effect",{})
   if not e.turn_install_layers is int or e.turn_install_layers<1 or effect.is_empty() or e.gone: return "持续施加来源损坏。"
   if not effect.stack and e.turn_install_layers!=1: return "该持续施加效果不能叠层。"
  if e.has("split_basis") and not typed(e.split_basis,"n"): return "分裂时生命记录损坏。"
  if e.has("acted_round") and not e.acted_round is int: return "敌人行动次数损坏。"
  if e.has("reinforcement_round"):
   if e.type!="guard" or not fields(e,"reinforcement_round:i acted_round:i") or e.reinforcement_round<4 or e.reinforcement_round%4!=0 or e.reinforcement_round>s.round or e.acted_round<e.reinforcement_round: return "援军出场回合不正确。"
  if e.has("spawned_from") or e.has("spawned_round"):
   if not fields(e,"spawned_from:s spawned_round:i acted_round:i") or e.spawned_round<1 or e.spawned_round>s.round or e.acted_round<e.spawned_round: return "分裂敌人的出场回合损坏。"
  if g.Enemies.TYPES[e.type].has("capture_kind") and (not fields(e.get("guard"),"bind_ready:b cycle_step:i") or e.guard.cycle_step not in [0,1,2]): return "魅魔警卫进度不完整。"
 var puppet_issue=g.Puppets.validate(g,s.enemies,g.DemoExit.health_multiplier(s))
 if puppet_issue!="": return puppet_issue
 var special_issue=g.SpecialEquipment.validate(s.get("special_equipment"))
 if special_issue!="": return special_issue
 for item in s.special_equipment:
  var suffix=item.id.trim_prefix("special_")
  if not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=s.next_equipment: return "特殊装备编号或后续编号不正确。"
 for source in s.pressure_sources:
  if not fields(source,"id:s name:s timing:s amount:n equipment:s room:s"): return "刺激来源记录不完整。"
  for definition in ["definition:s","enemy:s","encounter:i","remaining:i"]:
   if source.has(definition.split(":")[0]) and not fields(source,definition): return "刺激来源的持续记录类型不正确。"
 for log in s.logs:
  if not fields(log,"kind:s text:s round:i phase:s data:d"): return "行动记录不完整。"
 if not s.prison.is_empty() and not fields(s.prison,"served_turns:i sentence_extra:i active:b left:i turn:i stage:s missing:z baseline:z special_missing:z special_baseline:z discovery_pool:z discoveries:z found:z vent_hits:i vent_tick:i door_open:b key:b resisting:b checks:i report:s"): return "牢房进度不完整。"
 var reinforcement_issue=g.Prison.reinforcement_issue(s)
 if reinforcement_issue!="": return reinforcement_issue
 if s.phase in ["captured","prison_end"] and s.capture.is_empty(): return "缺少收押记录。"
 if not s.capture.is_empty() and not fields(s.capture,"by:s security:i retained:z added:z links:z retained_special:z special_added:z special_baseline:z confiscated:i baseline:z"): return "收押记录不完整。"
 if s.capture.has("intake_scene"):
  var scene=s.capture.intake_scene
  if not fields(scene,"opening:s guard_intro:s restraints:a links:a toys:a milking:s closing:s guard_done:s climax:d"): return "收押演出记录不完整。"
  if not (scene.restraints+scene.links+scene.toys).all(func(line):return line is String): return "收押装备文案记录不完整。"
 if not s.room_event.is_empty():
  var event=s.room_event
  if not fields(event,"id:s stage:s options:a refs:d report:s reward:z winner:i relic:s") or event.id not in g.Events.Data.TYPES: return "事件进度不完整。"
  if event.get("result_status","neutral") not in g.Events.RESULT_STATUSES: return "事件结果标记损坏。"
  # docs/spec/event-pipeline.md「事件链」／「存档表示」: chain exists only after a real cross-event jump and lists the events already
  # left, each one registered and named once. No other key is added or dropped by the jump.
  if event.has("chain"):
   var chain=event.chain
   if not chain is Array or chain.is_empty(): return "事件链记录不完整。"
   var passed=[]
   for id in chain:
    if not id is String or not g.Events.Data.TYPES.has(id) or id in passed: return "事件链记录不完整。"
    passed.append(id)
  if event.has("prepare_pending") and not event.prepare_pending is bool: return "事件战后的整备进度损坏。"
  if event.refs.values().any(func(id):return not id is String) or event.reward.any(func(id):return not g.Character.reward_member(g,id,s.get("character_id","original"))): return "事件结果类型不存在。"
  for option in event.options:
   if not option is Dictionary or option.get("result_status","neutral") not in g.Events.RESULT_STATUSES: return "事件选项结果标记损坏。"
   # "advanced" is accepted only for an in-progress save created before rewards were split by rarity.
   if not fields(option,"id:s label:s detail:s reward:s effects:a") or option.reward not in ["common","uncommon","rare","advanced","relic","none"] or not option.effects.all(func(e):return effect(e,g)): return "事件选项或代价记录损坏。"
   # Canonical spelling: exact key set from the single declaration, plus its mode.
   if option.has("conditions"):
    if option.has("availability"): return "事件选项同时携带两种状态条件。"
    if not option.conditions is Array or option.conditions.is_empty() or option.conditions.size()>8: return "事件选项的状态条件损坏。"
    for entry in option.conditions:
     if not entry is Dictionary or not entry.get("kind") is String: return "事件选项的状态条件损坏。"
     var entry_fields=g.Events.condition_saved_fields(entry.kind)+["mode"]
     if entry.size()!=entry_fields.size() or not entry_fields.all(func(key):return entry.has(key)): return "事件选项的状态条件损坏。"
     if entry.mode not in ["optional","hidden"] or not entry.reason is String or entry.reason.strip_edges().is_empty(): return "事件选项的状态条件损坏。"
   if option.has("availability"):
    var availability=option.availability
    if not fields(availability,"kind:s reason:s") or availability.reason.strip_edges().is_empty(): return "事件选项的状态条件损坏。"
    # Each kind owns its key set; a new condition must extend this check with its shape.
    if availability.kind=="no_chastity_lock":
     if availability.size()!=2: return "事件选项的状态条件损坏。"
    elif availability.kind=="has_relic":
     if availability.size()!=3 or not availability.get("type") is String or not g.Relics.TYPES.has(availability.type): return "事件选项的状态条件损坏。"
    else: return "事件选项的状态条件损坏。"
   if option.has("encounter") and g.Events.battle_spec_issue(g,option.encounter)!="": return "事件选项的战斗记录损坏。"
   if option.has("item_rewards") and g.Events.item_rewards_issue(g,option.item_rewards)!="": return "事件选项的道具奖励记录损坏。"
   if option.has("selected"):
    var source_choice=option.get("source_choice",option.id)
    if not selected_target(option.selected) or option.id!=source_choice+selected_suffix(option.selected): return "事件选择目标记录损坏。"
  if event.stage=="battle":
   if s.phase!="battle" or not event.get("battle",{}).get("active",false) or g.Events.battle_spec_issue(g,event.battle)!="": return "事件战斗进度损坏。"
  elif event.has("battle"): return "非战斗阶段残留了事件战斗记录。"
  if event.stage=="loot":
   if s.phase!="reward" or g.Events.item_rewards_issue(g,event.get("loot",[]),true)!="": return "事件道具领取进度损坏。"
  elif event.has("loot"): return "非道具奖励阶段残留了事件奖励记录。"
  if event.get("flow",false):
   if not fields(event,"flow:b held:d values:d cleanup_effects:a next_stage:s") or not event.cleanup_effects.all(func(e):return effect(e,g)) or event.values.keys().any(func(key):return not key is String or not event.values[key] is int or event.values[key]<0): return "多阶段事件记录不完整。"
   var definition=g.Events.Data.TYPES[event.id]
   var stage_ids=g.Events.node_ids(definition)
   if stage_ids.size()<=1: return "多阶段事件定义不存在。"
   if event.stage not in ["reward","result"]:
    var current=stage_ids.find(event.stage)
    if current<0: return "多阶段事件当前阶段不存在。"
    var current_node=g.Events.node(definition,event.stage)
    var declared=current_node.choices.map(func(choice):return choice.id)+(["refuse"] if current_node.allow_refuse else [])
    for option in event.options:
     var source_choice=option.get("source_choice",option.id)
     if not fields(option,"report:s") or not option.has("next") or source_choice not in declared: return "多阶段事件冻结选项损坏。"
     if option.next is Dictionary:
      # docs/spec/event-pipeline.md「事件链」cross-event form: the frozen target stays a registered event node, never this event.
      if not fields(option.next,"event:s node:s") or not g.Events.Data.TYPES.has(option.next.event) or option.next.event==event.id: return "多阶段事件冻结选项损坏。"
      if option.next.node not in g.Events.node_ids(g.Events.Data.TYPES[option.next.event]): return "多阶段事件冻结选项损坏。"
     elif not option.next is String or (option.next!="result" and (option.next not in stage_ids or stage_ids.find(option.next)<=current)): return "多阶段事件冻结选项损坏。"
   var held=[]
   for key in event.held:
    if not key is String or not event.held[key] is Array: return "事件暂存装备记录损坏。"
    held.append_array(event.held[key])
   if g.SpecialEquipment.validate(s.special_equipment+held)!="": return "事件暂存装备记录损坏。"
   for item in held:
    var suffix=item.id.trim_prefix("special_")
    if not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=s.next_equipment: return "暂存装备编号不正确。"
 # Factories must not reuse ids after a resume.
 for pair in [["next_card","card_",s.deck.map(func(card):return card.uid)],["next_equipment","equipment_",physical_ids],["next_composite","composite_",s.composites.map(func(r):return r.id)],["next_link","link_",s.links.map(func(r):return r.id)],["next_item","item_",s.items.map(func(r):return r.id)],["next_enemy","enemy_",s.enemies.map(func(r):return r.id)]]:
  if not s[pair[0]] is int or s[pair[0]]<1: return "新对象编号不合法。"
  for id in pair[2]:
   if id.begins_with(pair[1]) and id.trim_prefix(pair[1]).is_valid_int() and id.trim_prefix(pair[1]).to_int()>=s[pair[0]]: return "新对象编号会重复。"
 return ""
