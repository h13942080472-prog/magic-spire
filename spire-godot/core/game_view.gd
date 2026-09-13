extends RefCounted

static func battle_rewards(g, actions: Array) -> Array:
 if g.state.phase!="reward": return []
 var rows=[]
 if g.Events.active_item_rewards(g):
  for reward in g.Events.item_reward_rows(g):
   var type=reward.type
   var spec=g.Tools.TYPES[type]
   var category={"potion":"药剂","scroll":"卷轴"}.get(spec.get("category",""),"工具")
   var detail=g.Consumables.description(g,type) if g.Tools.operation(type)=="buff" else "%s · 可使用%d次" % [spec.name,spec.uses]
   var matches=actions.filter(func(candidate):return candidate.payload.get("kind","")=="reward" and candidate.payload.get("reward_id","")==reward.id)
   var reason="" if reward.claimed or matches.is_empty() or matches[0].valid else matches[0].reason
   rows.append({"id":reward.id,"category":"item","symbol":type,"name":spec.name,"subtitle":category+" · 领取后收入道具栏","detail":detail,"claimed":reward.claimed,"available":reason=="","reason":reason})
  return rows
 var claimed=g.state.reward_claimed
 if not g.state.reward_options.is_empty():
  rows.append({"id":"","category":"card","symbol":"card","name":"选择一张卡牌","subtitle":"加入你的卡组","detail":"从本次奖励中选择一张卡牌。","claimed":claimed.has("card"),"available":true,"reason":""})
  if claimed.has("card"): rows.back().subtitle="已跳过" if claimed.card=="skip" else "已获得「"+g.B.CARD_NAMES[claimed.card]+"」"
 if g.state.battle_item_drop!="":
  var type=g.state.battle_item_drop
  var spec=g.Tools.TYPES[type]
  var category={"potion":"药剂","scroll":"卷轴"}.get(spec.get("category",""),"道具")
  var detail=g.Consumables.description(g,type) if g.Tools.operation(type)=="buff" else "%s · 可使用%d次" % [spec.name,spec.uses]
  rows.append({"id":"","category":"item","symbol":type,"name":spec.name,"subtitle":category+" · 领取后收入道具栏","detail":detail,"claimed":claimed.has("item"),"available":true,"reason":""})
 if g.state.battle_relic_drop!="":
  var type=g.state.battle_relic_drop
  var spec=g.Relics.TYPES[type]
  rows.append({"id":"","category":"relic","symbol":type,"name":spec.name,"subtitle":g.Relics.RARITIES[spec.rarity]+"遗物","detail":spec.detail,"claimed":claimed.has("relic"),"available":true,"reason":""})
 if not g.state.boss_relic_options.is_empty():
  rows.append({"id":"","category":"relic","symbol":g.state.boss_relic_options[0],"name":"选择一件Boss遗物","subtitle":"三选一","detail":"从本次Boss遗物奖励中选择一件。","claimed":claimed.has("relic"),"available":true,"reason":"","choices":g.Relics.view(g.state.boss_relic_options)})
  if claimed.has("relic"): rows.back().subtitle="已跳过" if claimed.relic=="skip" else "已获得「"+g.Relics.TYPES[claimed.relic].name+"」"
 return rows

static func reward_panel(g, actions: Array) -> Dictionary:
 if not g.state.relic_bundle.is_empty(): return g.RelicBundle.panel(g,actions)
 if g.state.phase=="departure": return g.Departure.panel(g,actions)
 var panel={"active":false,"title":"战 斗 奖 励","destination":"","continue_id":"","continue_label":"继续  ›","extra_ids":[],"rows":[]}
 var choices=[];var exits=[]
 match g.state.phase:
  "reward":
   panel.active=true;panel.rows=battle_rewards(g,actions)
   var event_items=g.Events.active_item_rewards(g)
   panel.title="找到的道具" if event_items else "战 斗 奖 励"
   panel.destination="继续后返回塔路。" if event_items or g.Prison.is_exit_battle(g) else "继续后进入%d回合整备。" % g.preparation_turns()
   choices=actions.filter(func(c):return c.payload.kind=="reward" and c.payload.type!="skip")
   exits=actions.filter(func(c):return c.payload.kind=="reward" and c.payload.type=="skip")
  "rest_choice":
   panel.active=true;panel.title="休息奖励"
   panel.destination="任选一项 · 当前可休息%d回合" % g.state.rest_left
   panel.continue_label="跳过 · 休息%d回合  ›" % g.state.rest_left
   choices=actions.filter(func(c):return c.payload.kind in ["rest_card","rest_rare","rest_flask"])
   exits=actions.filter(func(c):return c.payload.kind=="rest_begin")
   var row=reward_card_row(g.Cards.Rules.RARITIES.uncommon+"卡%d选1" % g.state.rest_cards.size(),"花费%d回合 · 选择1张加入卡组" % g.B.REST_CARD_TURNS.uncommon)
   row.id="uncommon";row.action_kind="rest_card";row.hide_skip=true
   panel.rows.append(row)
   var rare=reward_card_row("随机获得1张稀有卡","花费%d回合 · 随机加入卡组" % g.B.REST_CARD_TURNS.rare)
   rare.id="rare";rare.action_kind="rest_rare";rare.direct=true;rare.hide_skip=true
   rare.detail="随机获得1张稀有卡，花费%d回合休息时间。" % g.B.REST_CARD_TURNS.rare
   panel.rows.append(rare)
   panel.rows.append({"id":"flask","category":"item","symbol":"mana_potion","name":"魔瓶补充%d魔力" % g.B.REST_FLASK_MANA,"subtitle":"花费%d回合 · 存入贴身魔瓶" % g.B.REST_FLASK_TURNS,"detail":"补充%d魔瓶魔力，花费%d回合休息时间。" % [g.B.REST_FLASK_MANA,g.B.REST_FLASK_TURNS],"claimed":false,"available":true,"reason":"","action_kind":"rest_flask","direct":true,"hide_skip":true,"action_label":"补充  ›"})
  "event":
   if g.state.room_event.get("stage","")!="reward": return panel
   panel.active=true;panel.title="事件奖励";panel.destination="选取一张卡牌，或跳过本次奖励。";panel.continue_label="跳过奖励  ›"
   choices=actions.filter(func(c):return c.payload.kind=="event" and c.payload.action=="reward" and c.payload.type!="skip")
   exits=actions.filter(func(c):return c.payload.kind=="event" and c.payload.action=="reward" and c.payload.type=="skip")
   panel.rows=[reward_card_row("选择一张卡牌","加入你的卡组")]
  "treasure":
   panel.active=true;panel.title="宝箱奖励";panel.destination="未领取的奖励可以直接跳过。";panel.continue_label="继续  ›"
   choices=actions.filter(func(c):return c.payload.kind=="service" and c.payload.op=="take")
   exits=actions.filter(func(c):return c.payload.kind=="service" and c.payload.op=="leave")
   var stock=g.room_data(g.state.room).stock
   for index in range(stock.size()):
    var offer=stock[index];var category="item" if offer.kind=="tool" else offer.kind
    panel.rows.append({"id":str(index),"category":category,"symbol":offer.type,"name":g.Services.name(g,offer),"subtitle":"已领取" if offer.taken else "收入收藏","detail":g.Services.detail(g,offer),"claimed":offer.taken,"available":true,"reason":""})
 if not panel.active: return panel
 if not exits.is_empty(): panel.continue_id=exits[0].id
 for row in panel.rows:
  var matching=choices
  if g.state.phase=="reward":
   matching=choices.filter(func(c):return c.payload.get("category","")==row.category and (row.id=="" or c.payload.get("reward_id","")==row.id))
  elif g.state.phase=="treasure": matching=choices.filter(func(c):return str(c.payload.index)==row.id)
  elif g.state.phase=="rest_choice": matching=choices.filter(func(c):return c.payload.kind==row.action_kind)
  row.action_ids=matching.map(func(c):return c.id)
  row.skipped=g.state.phase=="reward" and g.state.reward_claimed.get(row.category,"")=="skip"
  var skips=actions.filter(func(c):return c.payload.kind=="reward_skip" and c.payload.category==row.category)
  row.skip_id=skips[0].id if not skips.is_empty() else (panel.continue_id if g.state.phase!="reward" and not row.claimed else "")
  if row.skipped: row.subtitle="已跳过"
  if not row.claimed and not matching.is_empty() and not matching.any(func(c):return c.valid):
   row.available=false;row.reason=matching[0].reason
 return panel

static func reward_card_row(title: String, subtitle: String) -> Dictionary:
 return {"id":"","category":"card","symbol":"card","name":title,"subtitle":subtitle,"detail":"选择一张卡牌加入卡组，也可以跳过。","claimed":false,"available":true,"reason":""}

const B = preload("res://data/balance.gd")
const Tools = preload("res://data/field_tools.gd")
const Equipment = preload("res://data/equipment.gd")
const Tower = preload("res://data/tower.gd")

static func equipment_entry(g, e: Dictionary, slot: String) -> Dictionary:
 var linked=e.template=="link_rope"
 var current_tier=g.tier(g._effective_ratio(e),1.0) if e.has("parent_id") else g.tier(e.durability,e.maximum)
 var card_status=[]
 var shoulder_text=g.Shoulders.text(g,e)
 if shoulder_text!="": card_status.append(shoulder_text)
 if e.has("shoulder_host"): card_status.append("连接至"+g._equipment_name(g._equipment(e.shoulder_host))+"。")
 var binding_text=g.Binding.text(g,e)
 if binding_text!="": card_status.append(binding_text)
 if e.has("parent_id"): card_status.append("依附于"+g._equipment_name(g._equipment(e.parent_id))+"。独立连接耐久；挣扎不受堆叠影响，滑脱仍受影响。")
 var description="%s · %s\n耐久度：%s/%s · 紧度：%s档" % [Equipment.GRADES[e.grade],Equipment.material_name(e),g.number(e.durability),g.number(e.maximum),current_tier]
 description="位置："+Equipment.position_text(e)+"\n"+description
 if e.get("root_id","")!="" and not g.Composites.active(g._composite(e.root_id)):
  description+="\n遗留外带 · 套体已解除，这条外带仍然固定。"
  card_status.append("遗留外带")
 var summary=description
 if g.SpecialEquipment.is_special(e):
  description+="\n"+g.SpecialEquipment.description(e,g.Pressure.gain_multiplier(g),g.tier(e.durability,e.maximum),g.cursed_plate(e))
  if g.SpecialEquipment.is_chastity(e):
   var lock_state="已上锁" if e.locked else "锁已打开"
   card_status.append(lock_state)
   description+="\n状态："+lock_state
  if g.Links.is_crotch_anchor(e): description+="\n可连接手腕或大腿根装备：对手腕算下端，对大腿根算上端。"
  var spec=g.SpecialEquipment.TYPES[e.type]
  if spec.turn_gain>0: card_status.append(("电量剩余%d回合" % e.remaining) if spec.duration>0 and e.remaining>0 else ("电量耗尽" if spec.duration>0 else "持续生效"))
  if spec.energy_gain>0 and (spec.duration==0 or e.remaining>0): card_status.append("消耗能量时，快感＋%s" % g.number(g.SpecialEquipment.gain(e,"energy")*g.Pressure.gain_multiplier(g)))
 if "eyes" in Equipment.coverage(e):
  description+="\n视觉受阻 · 意图不可见"
  summary+="\n视觉受阻 · 无法观察敌人意图。"
 if linked:
  var ends: Array[String]=[]
  var blocked: Array[String]=[]
  for id in e.ends: ends.append(g._equipment_name(g._equipment(id)))
  for id in e.blocked_slip: blocked.append(g._equipment_name(g._equipment(id)))
  description+="\n连接："+" ↔ ".join(ends)
  if not blocked.is_empty(): description+="\n阻止滑脱："+"、".join(blocked)
  summary+="\n同一条绳，两处共享耐久；不占部位容量。"
 else:
  var reason=g._slip_reason(e)
  if reason!="": description+="\n"+reason
 if e.template in ["glove_body","leg_body","jacket_body","hand_wrap"]:
  summary+="\n各部位共享这一条套体耐久。"
  description+="\n覆盖："+"、".join(Equipment.coverage(e).map(func(s):return B.SLOT_NAMES[s]))
  if not g._strain_release_root(e).is_empty(): description+="\n再次挣扎可直接脱下整件。"
 elif e.template=="glove_strap":
  summary+="\n自身滑脱计算紧度：%s%%。" % g.number(g._effective_ratio(e)*100)
  description+="\n计算紧度：%s%%" % g.number(g._effective_ratio(e)*100)
 return {"id":e.id,"name":g._equipment_name(e),"image":preload("res://data/equipment_images.gd").path(e),"card_status":"\n".join(card_status),"lockable":Equipment.allows(e,"lock") or g.SpecialEquipment.is_chastity(e),"slot":slot,"tier":current_tier,"durability":e.durability,"maximum":e.maximum,"ratio":e.durability/e.maximum,"locked":e.locked,"linked":linked,
  "root_id":e.get("root_id",""),"part":e.get("part",""),"position_text":Equipment.position_text(e),"sort_order":Equipment.anatomical_order(e),"material_name":Equipment.material_name(e),"methods":Equipment.method_text(e),"description":description,"summary":summary}

# Read-only projection. All gameplay changes remain in game.gd.
static func build(g) -> Dictionary:
 var state=g.state
 var actions=g.candidates()
 for action in actions:
  if action.payload.kind=="attack" and g.Cards.Rules.FIXED_MAGIC.has(action.payload.type):
   action.casting=g.cast_view(g.Cards.cast_profile(g,action.payload.type,action.mana>0))
 var body_coverage={"points":[]}
 for e in g.physical_pieces():
  for point in Equipment.physical_points(e):
   if not point in body_coverage.points: body_coverage.points.append(point)
 var bodies: Array=[]
 for slot in B.SLOTS:
  var projected={}
  var ordered=g.targets_at(slot)
  ordered.sort_custom(func(a,b):return Equipment.anatomical_order(a)<Equipment.anatomical_order(b) if Equipment.anatomical_order(a)!=Equipment.anatomical_order(b) else a.id.naturalnocasecmp_to(b.id)<0)
  for e in ordered: projected[e.id]=equipment_entry(g,e,slot)
  var entries: Array=[]
  for e in g.equipment_at(slot):
   entries.append(projected[e.id])
  var links: Array=[]
  for e in g.links_at(slot): links.append(projected[e.id])
  var groups: Array=[]
  var grouped={}
  for e in projected.values():
   var key=e.root_id if e.root_id!="" else e.id
   if not grouped.has(key):
    var group={"name":(g._composite(e.root_id).name+(" · 遗留外带" if not g.Composites.active(g._composite(e.root_id)) else "")) if e.root_id!="" else ("链接绳 · 不占部位容量" if e.linked else ""),"components":[]}
    groups.append(group); grouped[key]=group
   grouped[key].components.append(e)
  bodies.append({"id":slot,"name":B.SLOT_NAMES[slot],"occupied":not entries.is_empty(),"count":entries.size(),"capacity":g._capacity(slot),"capacity_used":g.capacity_used(slot),"equipment":entries,"links":links,"targets":projected,"groups":groups})
 var hand: Array=[]
 for card in state.hand:
  var info=B.card_info(card.type)
  info[1]=g.Cards.face_text(g,card.type,false,card.uid)
  info[2]=g.Cards.face_text(g,card.type,true,card.uid)
  var bound=info[1]
  hand.append({"uid":card.uid,"type":card.type,"name":B.CARD_NAMES[card.type],"cost":"—" if B.CARD_TRAITS.get(card.type,{}).get("unplayable",false) else str(g.Cards.Rules.SPECS[card.type].cost),"tag":info[0],"bound":bound,"free":info[2],"note":info[3],"retained":B.CARD_TRAITS.get(card.type,{}).get("retain",false) or card.retain_until>state.tick,"single_face":g.Cards.Rules.single_face(card.type)})
  hand.back().merge(g.Cards.Rules.classification(card.type))
  hand.back().merge(g.Cards.metadata(g,card.type,card.uid))
  var choices=actions.filter(func(c):return c.payload.get("uid","")==card.uid and c.payload.kind in ["card","prison"])
  hand.back().unplayable=B.CARD_TRAITS.get(card.type,{}).get("unplayable",false)
  hand.back().availability={"free":g.Cards.availability(g,card,true,choices),"bound":g.Cards.availability(g,card,false,choices)}
  hand.back().magic=hand.back().cast_faces.bound or hand.back().cast_faces.free
  if hand.back().magic: hand.back().casting=g.cast_view(g.Cards.cast_profile(g,card.type))
  hand.back().draw_serial=card.get("draw_serial",0)
  hand.back().draw_free=card.draw_free if card.has("draw_free") else not g.Cards.has_escape_target(g,card.type)
 var enemies: Array=[]
 var intent_visible=g.can_observe_intents()
 for e in state.enemies:
  enemies.append({"id":e.id,"type":g.Enemies.TYPES[e.type].visual,"visual_variant":e.get("visual_variant",""),"template":e.type,"name":e.name,"hp":e.hp,"maximum":e.max_hp,"gone":e.gone,"stage":e.stage if intent_visible else 0,"intent_visible":intent_visible,"intent_icons":preload("res://core/intent_view.gd").build(g,e,intent_visible)})
 var wall_position=g.wall_view()
 var special_regions=g.SpecialEquipment.view(g)
 var pressure=g.Pressure.view(g,special_regions)
 var guard_bind=g.CaptureBind.view(g)
 var statuses=preload("res://core/status_view.gd").build(g,special_regions,pressure)
 var capacity=g.item_capacity()
 var items: Array=[]
 for item in state.items:
  items.append({"id":item.id,"name":Tools.TYPES[item.type].name,"uses":item.uses,"damage":Tools.TYPES[item.type].damage,"mount":Tools.mount_name(g,item),"installed":Tools.is_fixed(g,item),"contact_text":Tools.contact_text(g,item.mount) if Tools.is_fixed(g,item) else ""})
  var environment_class=Tools.TYPES[item.type].get("environment_class","")
  items.back().fixed_label="触手固定" if item.mount=="carry" and Tools.is_fixed(g,item) else "已安装"
  items.back().environment_class=environment_class
  items.back().type=item.type
  items.back().direct_use=Tools.operation(item.type) in ["buff","escape"]
  items.back().summary=preload("res://core/item_presentation.gd").summary(g,item.type)
  items.back().usage_note=preload("res://core/item_presentation.gd").note(g,item.type)
  items.back().inactive_reason=Tools.escape_reason(g) if Tools.operation(item.type)=="escape" else "进入战斗、整备、休息或牢房的可行动回合后，可操作道具。"
  items.back().target_scope=Tools.TYPES[item.type].get("target_scope","")
  items.back().description=Tools.description(g,item.type)
  items.back().category={"potion":"药剂","scroll":"卷轴"}.get(Tools.TYPES[item.type].get("category",""),"工具")
  items.back().environment_name=Tools.Environments.NAMES.get(environment_class,"")
  items.back().passive_text=g.InstalledTools.description(g,item) if not Tools.TYPES[item.type].get("trigger_damage_types",[]).is_empty() else ""
  var groups=[];var unavailable=[]
  for c in actions:
   if c.payload.kind!="item_use" or c.payload.item!=item.id: continue
   if not c.valid:
    if c.reason not in unavailable: unavailable.append(c.reason)
    continue
   if items.back().target_scope=="body_group":
    var group=g.Equipment.panel_groups().filter(func(p):return p.id==c.payload.target)[0]
    groups.append({"id":group.id,"name":group.name,"candidates":[c.id]})
    continue
   var target=g._equipment(c.payload.target)
   var slots=[c.payload.target] if target.is_empty() else ([target.slot] if g.SpecialEquipment.is_special(target) else Tools.target_contact(g,target,Tools.operation(item.type)).slots)
   for slot in slots:
    var matches=groups.filter(func(group):return group.id==slot)
    if matches.is_empty():
     groups.append({"id":slot,"name":g.SpecialEquipment.slot_name(slot) if slot in g.SpecialEquipment.slots() else B.SLOT_NAMES.get(slot,{"prison_door":"牢门","hero":"自身"}.get(slot,"肩部")),"candidates":[]})
     matches=[groups.back()]
    if c.id not in matches[0].candidates: matches[0].candidates.append(c.id)
  items.back().target_groups=groups
  items.back().unavailable_reasons=unavailable
 var deck_list: Array=[]
 var practice_options: Array=[]
 var practice_table=Tower.all_practices()
 for kind in practice_table:
  var entry=practice_table[kind]
  practice_options.append({"id":kind,"label":entry.label,"node":entry.node})
 var counts={}
 for card in state.deck: counts[card.type]=counts.get(card.type,0)+1
 for type in counts:
  deck_list.append({"type":type,"name":B.CARD_NAMES[type],"count":counts[type],"bound":g.Cards.face_text(g,type,false),"free":g.Cards.face_text(g,type,true)})
 var costs={}
 var card_texts={}
 var card_instances={}
 for zone in g.Cards.ZONES:
  for card in state[zone]:
   if g.Cards.Rules.SPECS[card.type].has("damage_growth") or g.Cards.Rules.SPECS[card.type].has("hannya_stage"):
    card_instances[card.uid]={"bound":g.Cards.face_text(g,card.type,false,card.uid),"free":g.Cards.face_text(g,card.type,true,card.uid)}
    card_instances[card.uid].merge(g.Cards.metadata(g,card.type,card.uid))
 for type in g.Cards.Rules.SPECS: costs[type]=str(g.Cards.Rules.SPECS[type].cost)
 for type in g.Cards.Rules.SPECS:
  card_texts[type]={"bound":g.Cards.face_text(g,type,false),"free":g.Cards.face_text(g,type,true),"face_costs":{"bound":"—" if B.CARD_TRAITS.get(type,{}).get("unplayable",false) else str(g.Cards.energy_cost(g,type,false)),"free":"—" if B.CARD_TRAITS.get(type,{}).get("unplayable",false) else str(g.Cards.energy_cost(g,type,true))}}
  card_texts[type].merge(g.Cards.metadata(g,type))
  if not g.Cards.Rules.cast_profile(type).is_empty(): card_texts[type].casting=g.cast_view(g.Cards.cast_profile(g,type))
 var chain={} if state.card_chain.is_empty() else {"name":B.CARD_NAMES[state.card_chain.type],"remaining":state.card_chain.remaining}
 var copy=g.ActionCopy.view(state.logs,pressure.overloaded)
 var grouped_bodies=body_groups(g,bodies,special_regions)
 var arms_level=g.level("arms")
 var legs_level=g.level("legs")
 for body in grouped_bodies:
  body.can_release=body.occupied and actions.any(func(c):return c.payload.kind=="manual" and c.valid and c.payload.after==0.0 and body.targets.has(c.payload.target))
 var reward=reward_panel(g,actions)
 return {"run_header":run_header(g),"demo_cycle":state.demo_cycle,"demo_finished":state.demo_finished,"demo_exit":g.DemoExit.at_exit(g),"battle_rewards":reward.rows,"reward_panel":reward,"reward_title":reward.title,"reward_destination":reward.destination,"content_status":g.Content.report.duplicate(true),"card_chain":chain,"retain_left":state.retain_left,"card_costs":costs,"card_texts":card_texts,"card_instances":card_instances,"version":state.version,"seed":state.seed,"phase":state.phase,"phase_caption":preload("res://data/phases.gd").caption(state),"encounter":state.encounter,"round":state.round,"order":state.order,
  "powers":state.powers.map(func(card):return {"uid":card.uid,"type":card.type,"power_face":card.power_face}),"casting":g.cast_view(),"speech":copy.speech,"climax":copy.climax,"action_log":copy.actions,"travel_log":travel_log(state.logs),"pressure":pressure,"room_event":g.Events.view(g),"shop":g.Services.view(g),"relics":g.RelicEffects.view(g),
  "battle_relic_drop":g.Relics.TYPES[state.battle_relic_drop].name if state.battle_relic_drop!="" else "",
  "battle_item_drop":Tools.TYPES[state.battle_item_drop].name if state.battle_item_drop!="" else "",
  "capture":state.capture.duplicate(true),"guard_bind":guard_bind,"security":state.security,"prison":g.Prison.view(g),
  "posture":state.posture,"pose_name":B.POSE_NAMES[state.posture],"energy":state.energy,"energy_max":g.max_energy(),"mana":state.mana,"temporary_mana":state.temporary_mana,"mana_max":state.mana_max,"mana_flask":g.ManaFlask.view(g),
  "arms":arms_level,"legs":legs_level,"has_restraint_level":arms_level>0 or legs_level>0,"equipment_portrait_layers":g.SpecialEquipment.portrait_layers(state.special_equipment),"capacity":capacity,"bodies":bodies,"body_groups":grouped_bodies,"body_coverage":body_coverage,"hand":hand,"enemies":enemies,"statuses":statuses,
  "rest_left":state.rest_left,"hook_uses":state.hook_uses,"hook_location":"墙边挂钩","hook_environment_name":Tools.Environments.NAMES[Tools.Environments.HOOK_CLASS],"hook_contact":Tools.contact_text(g,Tools.HOOK_MOUNT,false),"items":items,"carried_items":g.carried_items(),
  "wall":state.wall,"wall_position":wall_position,"wall_text":wall_position.name+" · "+wall_position.status,
  "practice":state.practice,"practice_kind":state.practice_kind,"practice_description":practice_table.get(state.practice_kind,Tower.PRACTICES.equipment).spec.description,"practice_hint":practice_table.get(state.practice_kind,Tower.PRACTICES.equipment).spec.hint,"practice_options":practice_options,"practice_focus":practice_table.get(state.practice_kind,Tower.PRACTICES.equipment).focus,
  "map_name":"监狱" if state.map_region=="prison" else "塔路","map_region":state.map_region,"room_name":g.room_data(state.room).name if state.room=="prison" else (Tower.practice_spec(state.practice_kind).name if state.practice else g.room_data(state.room).name),"route":[] if state.practice or state.room=="prison" else g.route_view(actions),"movement":g.movement_profile(),"journey":state.journey.duplicate(true),"travel_turns":state.travel_turns,"rooms_completed":state.completed_rooms.size(),"reward_count":state.reward_count,
  "candidates":actions,"logs":state.logs.duplicate(true),"summary":state.summary,"prepare_left":state.prepare_left,"preparation_turns":g.preparation_turns(),"draw_count":state.draw.size(),"discard_count":state.discard.size(),"draw_cards":state.draw.map(func(card):return {"uid":card.uid,"type":card.type}),"discard_cards":state.discard.map(func(card):return {"uid":card.uid,"type":card.type}),"deck_count":state.deck.size(),"deck_cards":state.deck.map(func(card):return {"uid":card.uid,"type":card.type}),"deck_list":deck_list,"pending_retain":state.pending_retain}

static func travel_log(logs: Array) -> Array:
 var result=[]
 for entry in logs:
  if entry.data.has("travel"):
   result.append({"turn":entry.data.travel.turn,"text":entry.text})
 return result

# Display groups aggregate physical slots without changing their action candidates.
static func body_groups(g, bodies: Array, special_regions: Array) -> Array:
 var result=[]
 for panel in g.Equipment.panel_groups():
  var definition=panel.slots
  if panel.special:
   var region=special_regions.filter(func(r):return r.id==panel.id)[0]
   var count=0
   var capacity=0
   var targets={}
   for item in region.items:
    capacity+=item.capacity
    for e in item.equipment: targets[e.id]=e
   count=targets.size()
   var equipment=targets.values()
   var links=[]
   for slot in region.slots:
    for link in g.links_at(slot):
     if targets.has(link.id): continue
     var projected=equipment_entry(g,link,slot)
     links.append(projected);targets[link.id]=projected
   var entry={"id":region.id,"name":region.name,"slots":region.slots,"special":true,"items":region.items,"count":count,"capacity":capacity,"occupied":count>0,"links":links,"targets":targets,"groups":[],"equipment":equipment}
   entry.sections=body_sections(g,entry)
   result.append(entry)
   continue
  if definition==['neck','shoulder']:
   var targets={}
   for e in g.equipment_targets():
    if Equipment.display_points(e).any(func(p):return p in definition): targets[e.id]=equipment_entry(g,e,Equipment.contact_slots(e)[0])
   var neck={"id":"neck","name":panel.name,"slots":definition,"special":false,"count":targets.size(),"occupied":not targets.is_empty(),"targets":targets,"equipment":targets.values(),"links":[],"groups":[]}
   neck.sections=body_sections(g,neck)
   result.append(neck)
   continue
  var members=bodies.filter(func(b):return b.id in definition)
  var entry=members[0].duplicate(true)
  entry.slots=definition.duplicate();entry.special=false
  if definition.size()>1:
   entry.id="hands" if 'palm' in definition else "feet"
   entry.name="手部" if entry.id=="hands" else "足部"
   entry.targets={};entry.equipment=[];entry.links=[];entry.groups=[]
   var grouped={}
   for member in members:
    for id in member.targets: entry.targets[id]=member.targets[id]
    for field in ['equipment','links']:
     for item in member[field]:
      if not entry[field].any(func(e):return e.id==item.id): entry[field].append(item)
    for group in member.groups:
     if not grouped.has(group.name):
      grouped[group.name]={"name":group.name,"components":[]};entry.groups.append(grouped[group.name])
     for item in group.components:
      if not grouped[group.name].components.any(func(e):return e.id==item.id): grouped[group.name].components.append(item)
   entry.count=entry.equipment.size();entry.occupied=entry.count>0
  entry.sections=body_sections(g,entry)
  result.append(entry)
 return result

static func body_sections(g, body: Dictionary) -> Array:
 var sections=[]
 for slot in body.slots:
  for point in Equipment.points(slot):
   var entries=[]
   for item in body.targets.values():
    if point in Equipment.display_points(g._equipment(item.id)): entries.append(item)
   sections.append({"id":point,"name":Equipment.point_name(point),"equipment":entries})
 return sections



static func run_header(g) -> Dictionary:
 var state=g.state
 var floor=int(g.room_data(state.room).get("floor",-1))
 var location="牢房" if state.room=="prison" else ("监狱" if state.map_region=="prison" else ("第0层" if floor<0 else "第%d层" % (floor+1)))
 var turn=g.display_round()
 var active=state.phase in ["battle","prison","inspection","rest","prepare"]
 return {"location":location,"turn":"第%d回合" % turn if active else "回合 —","order":("先手" if state.order=="first" else "后手") if state.phase=="battle" else "非战斗","last":state.phase=="battle" and state.order=="last"}
