extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Enemies=preload("res://tests/enemy_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func linked_battle():
 var g=Enemies.encounter("rope_solo")
 g._install_template("rope","forearm",8,10,false,"fixture",1,-1,0,"mid_forearm")
 g.add_fixture("wrist",8)
 g.add_fixture("palm",8,10,false,0,"cord")
 return g

static func run(t) -> void:
 var g=Game.new(42)
 var before=g.state.duplicate(true)
 var pool=["rope","cord","mouth_tape","link_rope"]
 var choices=g.EquipmentOffers.preferred(g,g.EquipmentOffers.for_pool(g,1,pool))
 t.check(not choices.is_empty() and choices.all(func(o):return o.kind=="install" and o.slot=="wrist"),"PRIORITY empty wrist exclusively first")
 t.check(g.state==before and g.EquipmentOffers.for_pool(g,1,[]).is_empty(),"PRIORITY candidate lookup readonly; empty source never widens")
 g.add_fixture("wrist",8)
 choices=g.EquipmentOffers.preferred(g,g.EquipmentOffers.for_pool(g,1,pool))
 t.check(choices.any(func(o):return o.slot=="mouth") and choices.any(func(o):return o.slot=="fingers") and choices.all(func(o):return o.slot in ["mouth","fingers"]),"PRIORITY empty mouth and fingers share second band")
 g.add_fixture("mouth",8);g.add_fixture("fingers",8,10,false,0,"cord");g._install_template("rope","forearm",8,10,false,"fixture",1,-1,0,"mid_forearm")
 # Once every physical point is covered, additions and links retain the old shared band.
 for slot in g.B.ARM_SLOTS+g.B.LEG_SLOTS:
  for point in g.Equipment.points(slot):
   if g.physical_pieces().any(func(e):return point in g.Equipment.physical_points(e)): continue
   g._install_template(g.Equipment.default_template(slot),slot,8,10,false,"fixture",1,-1,0,point if g.Equipment.SEGMENTS.has(slot) else "")
 g.add_fixture("eyes",8)
 choices=g.EquipmentOffers.preferred(g,g.EquipmentOffers.for_pool(g,1,pool))
 for slot in ["wrist","fingers","foot","toes","thigh"]:
  t.check(choices.any(func(o):return o.kind=="install" and o.slot==slot),"PRIORITY third band includes "+slot)
 t.check(choices.any(func(o):return o.kind=="link") and choices.all(func(o):return o.rank==1),"PRIORITY legal links share third band, never inherit endpoint rank")
 # Audit real general-purpose enemy sources, not just a synthetic link whitelist.
 for type in ["small_circle","ominous_circle","trader","guard"]:
  var source={"type":type,"id":"pool_audit"}
  var plans=g.EnemyPlans.installation_intents(g,source).filter(func(p):return p.get("pool","")=="ordinary" and "rope" in p.get("templates",[]))
  t.check(not plans.is_empty(),"PRIORITY general source has a path to ordinary links: "+type)
  if plans.is_empty(): continue
  var legal=g.Application._choice_bands(g,plans[0],source.id)
  t.check(legal.any(func(band):return band.any(func(p):return p.kind=="link")) and legal.all(func(band):return band.all(func(p):return p.rank==1)),"PRIORITY real source admits legal links in the shared third band: "+type)
  var actual=plans[0].duplicate(true);actual.templates=["link_rope"];actual.count=1
  var old_equipment=g.state.equipment.duplicate(true)
  var result=g.Application.execute(g,actual,source.id)
  t.check(result.ok and result.installed[0].template=="link_rope" and g.state.equipment==old_equipment,"PRIORITY real source can commit a link without inventing endpoints: "+type)
  g.state.links.clear()
 t.check(g.EquipmentOffers.for_pool(g,1,["belt"]).any(func(o):return o.kind=="link") and g.EquipmentOffers.for_pool(g,1,["tape"]).all(func(o):return o.kind=="install" and o.template=="tape"),"PRIORITY belt sources inherit links, tape-only sources do not")
 g=Game.new(42)
 t.check(g.Application.choose(g,{"templates":["cord"],"grade":1},"test").slot=="fingers","PRIORITY missing wrist-capable template skips first band")
 t.check(g.Application.choose(g,{"templates":["eye_leather"],"grade":1},"test").is_empty(),"PRIORITY grade restriction precedes priority")
 var plain=g.Application.choose(g,{"templates":["rope"],"grade":1},"test")
 g.add_fixture("wrist",8)
 var committed=g.Application.execute_concrete(g,plain,"test")
 t.check(committed.ok and committed.installed[0].slot==plain.slot,"PRIORITY frozen concrete request retains its legal location when priority changes")
 g.state.room_event={"refs":{}}
 var effects=g.Events.freeze_effects(g,[{"op":"install_random","templates":["rope","cord"],"count":2,"grade":1,"tier":2,"locked":false}])
 t.check(effects.issue=="" and effects.effects[0].slot=="fingers" and effects.effects[1].slot!="mouth","PRIORITY event batch updates occupancy between source-limited additions")

 g=linked_battle()
 var enemy=g.state.enemies[0];var id=enemy.id
 var plan=g.EnemyPlans.application(["link_rope"])
 var anchors=g.link_anchors().map(func(anchor):return anchor.id)
 t.check(plan.kind=="apply" and plan.templates==["link_rope"] and plan.grade==1 and plan.tier==2,"LINK enemy plan uses real link template")
 enemy.intent=plan
 var icon=g.get_view().enemies[0].intent_icons[0]
 t.check(icon.kind=="bind" and icon.detail=="敌人准备对你施加拘束","LINK intent shares concise restraint icon")
 before=g.state.duplicate(true)
 g.get_view();g.command_facts()
 t.check(g.state==before,"LINK preview does not install or advance RNG")
 var h=Save.roundtrip(t,g,"pending enemy link")
 Save.step_both(t,g,h,"end")
 var link=g.state.links[0]
 t.check(g.state.links.size()==1 and link.ends.all(func(end):return end in anchors) and g.tier(link.durability,10)==2 and g.state.equipment.size()==3,"LINK actual enemy operation installs one link without extra endpoints")
 t.check(g.get_view().action_log.any(func(l):return l.text.contains("链接绳")) and g.state.logs.any(func(l):return l.data.get("enemy_action",{}).get("slots",[])==link.slots),"LINK result and both affected body locations recorded")
 t.check(g.EquipmentOffers.links(g,1).all(func(o):return o.ends!=link.ends),"LINK existing pair excluded from later additions")
 var malformed=h.export_snapshot();malformed.links[0].ends=[link.ends[0],link.ends[0]]
 before=h.state.duplicate(true)
 t.check(not h.restore_snapshot(malformed).ok and h.state==before,"LINK corrupted physical pair rejected atomically")

 g=linked_battle();enemy=g.state.enemies[0];id=enemy.id
 enemy.stage=4;enemy.intent=g.EnemyPlans.application(["link_rope"],2,2,1,true)
 g.state.round=2
 g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.check(t.action(g,"attack",{"type":"kick","form":2,"enemy":id}).ok,"LINK prepared final attachment can be interrupted")
 h=Save.roundtrip(t,g,"interrupted final link")
 Save.step_both(t,g,h,"end")
 t.check(g.state.links.is_empty() and g._enemy(id).stage==4,"LINK interrupt delays application without choosing endpoints")
 Save.step_both(t,g,h,"end")
 t.check(g.state.links.size()==1 and g.state.links[0].grade==2 and g._enemy(id).gone and g.state.reward_count==1,"LINK final medium attachment leaves and rewards once")

 g=linked_battle();enemy=g.state.enemies[0];plan=g.EnemyPlans.application(["link_rope"])
 enemy.intent=plan
 # Remove an extreme anchor after announcing a link-only application.
 var remove_id=g.equipment_at("forearm")[0].id
 g._equipment(remove_id).durability=0;g._cleanup()
 var resolved=g.EnemyPlans.resolve(g,enemy,plan)
 t.check(resolved==plan and not resolved.has("ends"),"LINK generic declaration still defers concrete endpoints to execution")
 t.action(g,"end")
 t.check(g.state.links.size()==1 and remove_id not in g.state.links[0].ends,"LINK retarget commits through formal enemy turn")
 g=linked_battle();enemy=g.state.enemies[0];enemy.stage=4;enemy.intent=g.EnemyPlans.application(["link_rope"],2,2,1,true)
 g.state.equipment.clear()
 t.check(t.action(g,"end").ok and g.physical_pieces().is_empty() and g._enemy(enemy.id).gone,"LINK no pair leaves without invented endpoints or widened installation")
 empty_point_priority(t)

static func empty_point_priority(t) -> void:
 var g=Game.new(42)
 var pool=["rope","cord","mouth_tape"]
 g._install_template("rope","upper_arm",8,10,false,"fixture",1,-1,0,"upper_arm_top")
 var choices=g.EquipmentOffers.preferred(g,g.EquipmentOffers.for_pool(g,1,pool))
 t.check(choices.all(func(o):return o.slot=="wrist"),"EMPTY PRIORITY empty wrists remain first despite other empty points")
 g.add_fixture("wrist",8)
 choices=g.EquipmentOffers.preferred(g,g.EquipmentOffers.for_pool(g,1,pool))
 t.check(choices.any(func(o):return o.slot=="mouth") and choices.any(func(o):return o.slot=="fingers") and choices.all(func(o):return o.slot in ["mouth","fingers"]),"EMPTY PRIORITY mouth and fingers retain equal second rank")
 g.add_fixture("mouth",8);g.add_fixture("fingers",8)
 var before=g.state.duplicate(true)
 var feedback={"sentinel":[]};g._resource_feedback=feedback
 choices=g.EquipmentOffers.preferred(g,g.EquipmentOffers.for_pool(g,1,pool))
 t.check(choices.any(func(o):return o.get("point")=="above_elbow") and choices.any(func(o):return o.get("slot")=="ankle"),"EMPTY PRIORITY empty elbow subpoint stays equal to ankle despite different region gains")
 t.check(choices.all(func(o):return o.kind=="install" and o.get("point")!="upper_arm_top" and o.slot not in ["wrist","fingers","mouth"]),"EMPTY PRIORITY uncovered points precede stacking and existing-endpoint links")
 t.check(g.state==before and g._resource_feedback==feedback,"EMPTY PRIORITY lookup preserves state RNG logs resources counters and feedback")
 g._resource_feedback=null
 var spec={"templates":["rope"],"slot":"upper_arm","grade":1,"tier":2,"count":2}
 var result=g.Application.execute(g,spec,"fixture")
 t.check(result.ok and result.installed.size()==2 and result.installed[0].points==["above_elbow"],"EMPTY PRIORITY batch first fills the vacant subpoint of an occupied large part")
 t.check(result.installed[1].points[0] in ["upper_arm_top","above_elbow"],"EMPTY PRIORITY batch may stack after its source has no empty point")
 var forced=g.Application.choose(g,{"templates":["rope"],"grade":1,"preferred_slots":["wrist"]},"fixture")
 t.check(forced.get("slot")=="wrist","EMPTY PRIORITY explicit source preference stays above general empty-point preference")
 forced=g.Application.choose(g,{"templates":["rope"],"slot":"upper_arm","point":"upper_arm_top","grade":1},"fixture")
 t.check(forced.get("point")=="upper_arm_top","EMPTY PRIORITY explicit physical target is never widened to an empty location")
 var options=g.EquipmentOffers.for_pool(g,1,["rope"]).filter(func(o):return o.kind=="install" and o.slot=="upper_arm")
 t.check(g.EquipmentOffers.preferred(g,options)==options,"EMPTY PRIORITY all occupied facts keep the original tie")
 # Whole-slot regional level can already be four while a precise segment is still empty.
 for slot in ["forearm","palm","thigh","calf","ankle","foot","toes"]: g.add_fixture(slot,8)
 t.check(g.level("arms")==4 and g.level("legs")==4,"EMPTY PRIORITY fixture has full regional degrees")
 var scoped=g.Events.ordinary(g,1,false,["rope"]).filter(func(o):return o.get("slot")=="forearm")
 var effect=g.Events.pick(g,scoped)
 t.check(effect.get("op")=="install" and effect.get("point")=="mid_forearm","EMPTY PRIORITY event fills the empty subpoint even when its region is already four")
 var used=[]
 for slot in g.B.ARM_SLOTS+g.B.LEG_SLOTS:
  for point in g.Equipment.points(slot):
   if point!="mid_forearm": used.append(point)
 var enemy=g.EnemyPlans.batch_choice(g,{"id":"fixture"},1,2,false,["rope"],used)
 t.check(enemy.get("point")=="mid_forearm","EMPTY PRIORITY enemy batch uses the shared physical-point preference")
 used.append("mid_forearm")
 t.check(g.EnemyPlans.batch_choice(g,{"id":"fixture"},1,2,false,["rope"],used).is_empty(),"EMPTY PRIORITY batch exclusion never reopens used points")
 # Composite bodies really cover their small parts, even if they cost no ordinary capacity.
 g=Game.new(43)
 for slot in ["mouth","wrist","fingers"]: g.add_fixture(slot,8)
 var leg=g._install_assembly("leg","upper","fixture",2,2)
 var raw=g.EquipmentOffers.for_pool(g,2,["rope"]).filter(func(o):return o.kind=="install" and o.slot in ["thigh","calf"])
 choices=g.EquipmentOffers.preferred(g,raw)
 t.check(not leg.is_empty() and choices.all(func(o):return o.slot=="calf"),"EMPTY PRIORITY a leg sleeve covers thigh subpoints despite its zero ordinary capacity cost")
 var composite_options=g.EquipmentOffers.assemblies(g,2,[{"family":"leg","variant":"lower"},{"family":"leg","variant":"ankle"}])
 t.check(g.EquipmentOffers.preferred(g,composite_options)==composite_options and composite_options.size()==2,"EMPTY PRIORITY composite options with new points stay equal without counting coverage as extra votes")
 g=Game.new(44)
 for slot in ["upper_arm","forearm","wrist","mouth"]: g.add_fixture(slot,8)
 var left=g._install_assembly("wrap","left","fixture",2,2)
 var occupied={}
 for e in g.physical_pieces():
  for point in g.Equipment.physical_points(e): occupied[point]=true
 var wraps=g.EquipmentOffers.assemblies(g,2,["wrap"])
 t.check(not left.is_empty() and wraps.size()==1 and wraps[0].variant=="right" and g.EquipmentOffers._fills_empty(g,wraps[0],occupied),"EMPTY PRIORITY hand occupancy respects the actual left and right components")
 # A full-slot replacement remains available after empty choices are exhausted.
 for i in range(g._capacity("wrist")-g.equipment_at("wrist").size()): g.add_fixture("wrist",4)
 spec={"templates":["tape"],"slot":"wrist","grade":2,"tier":3,"replace":true,"allow_links":false}
 before=g.state.duplicate(true)
 choices=g.Application._choices(g,spec,"fixture")
 t.check(not choices.is_empty() and g.state==before,"EMPTY PRIORITY authorized replacement remains read-only and available without empty points")
 var protected=spec.duplicate(true);protected.protected_ids=g.equipment_at("wrist").map(func(e):return e.id)
 t.check(g.Application._choices(g,protected,"fixture").is_empty() and g.state==before,"EMPTY PRIORITY replacement protections and atomic refusal remain intact")
 result=g.Application.execute(g,spec,"fixture")
 t.check(result.ok and not result.removed.is_empty(),"EMPTY PRIORITY exhausted source can still commit its authorized replacement")
