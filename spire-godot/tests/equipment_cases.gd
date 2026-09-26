extends RefCounted

const Game=preload("res://tests/game_fixture.gd")
const E=preload("res://data/equipment.gd")
# Living index-off reference for the B1 parity checks (single definition in the architecture suite).
const Arch=preload("res://tests/architecture_cases.gd")

static func eye_capacity(t) -> void:
 var g=Game.new(42,true,"head_harness")
 var eyes=g.get_view().bodies.filter(func(b):return b.id=="eyes")[0]
 t.check(eyes.capacity==2 and eyes.capacity_used==2 and eyes.equipment.size()==2,"EYES real mixed masks share two projected positions")
 var before=g.export_snapshot()
 t.check(g._install_template("eye_leather","eyes",6.4,16,false,"fixture",2).is_empty() and g.export_snapshot()==before,"EYES third material cannot bypass capacity")
 var broken=before.duplicate(true)
 var extra=g.equipment_at("eyes")[0].duplicate(true)
 extra.id="equipment_"+str(broken.next_equipment);broken.next_equipment+=1
 broken.equipment.append(extra)
 t.check(not g.restore_snapshot(broken).ok and g.export_snapshot()==before,"EYES over-capacity saved masks are rejected atomically")
 var old_ids=g.equipment_at("eyes").map(func(e):return e.id)
 var result=g.Application.execute(g,{"pool":"ordinary","templates":["eye_tape"],"count":1,"grade":2,"tier":3,"replace":true},"event:capacity")
 t.check(result.ok and result.removed.size()==1 and g.equipment_at("eyes").size()==2 and g.equipment_at("eyes").any(func(e):return e.id not in old_ids) and g.validate()=="","EYES authorized replacement swaps one at the two-slot limit without creating a third")

static func run(t) -> void:
 mouth_stacking(t)
 release_projection(t)
 precise_positions(t)
 eye_capacity(t)
 index_slot_edge_parity(t)
 index_targets_edge_parity(t)
 index_predicate_parity(t)
 var wear_slots=["eyes","mouth","neck","upper_arm","forearm","wrist","palm","fingers","thigh","calf","ankle","foot","toes"]
 t.check(E.WEAR_TEXTS.keys().all(func(slot):return slot in wear_slots) and wear_slots.all(func(slot):return E.WEAR_TEXTS.has(slot)),"WEAR ordinary single restraint prose covers every approved body location")
 t.check(E.ANIMATED_WEAR_TEXTS.keys().all(func(slot):return slot in wear_slots) and wear_slots.all(func(slot):return E.ANIMATED_WEAR_TEXTS.has(slot)),"WEAR animated restraint prose covers every approved body location")
 for slot in wear_slots:
  var wear=E.wear_text("测试拘束具",slot)
  t.check(wear.count("测试拘束具")==1 and not wear.contains("{name}") and not wear.contains("固定"),"WEAR reusable exact-name prose for "+slot)
  var animated=E.wear_text("测试拘束具",slot,"animated")
  t.check(animated.count("测试拘束具")==1 and not animated.contains("{name}") and not animated.contains("她"),"WEAR animated prose keeps an autonomous subject for "+slot)
 t.check(E.wear_text("测试拘束具","foot").contains("脚掌") and not E.wear_text("测试拘束具","foot").contains("足部"),"WEAR foot copy uses the visible body name 脚掌")
 for template in ["rope","belt","tape","cable_tie"]:
  var g=Game.new(42)
  var target=g.add_fixture("thigh",4,10,false,0,template)
  t.check(not target.is_empty() and g.validate()=="","TEMPLATE valid instance "+template)
  var entry=g.get_view().bodies.filter(func(b):return b.id=="thigh")[0].equipment[0]
  t.check(entry.name==E.name_for(template,"thigh") and entry.material_name==E.material_name(target),"TEMPLATE visible name and material "+template)
  t.check(g.escape_preview(target,"strain",5).reason=="" and g.escape_preview(target,"slip",5).reason=="","TEMPLATE both damage routes "+template)
  var manual=t.find_action(g,"manual",{"target":target.id})
  if template in ["rope","belt"]:
   t.check(manual.valid and t.action(g,"manual",{"target":target.id}).ok and g._equipment(target.id).is_empty(),"TEMPLATE actual quick release "+template)
  else:
   var before=JSON.stringify(g.state)
   t.check(not manual.valid and manual.reason.contains("不能徒手"),"TEMPLATE structural manual rejection "+template)
   t.check(not g.dispatch(g.command(manual.payload,g.state.version),g.state.version).ok and JSON.stringify(g.state)==before,"TEMPLATE blocked manual is atomic "+template)
   var card=t.hand_card(g,"slip")
   t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and g._equipment(target.id).is_empty(),"TEMPLATE actual slip still works "+template)

 var g=Game.new(4)
 for args in [["rope","fingers",false],["belt","toes",false],["tape","eyes",false],["cable_tie","mouth",false],["rope","thigh",true],["tape","thigh",true],["cable_tie","thigh",true],["missing","thigh",false]]:
  var before=JSON.stringify(g.state)
  t.check(g._install_template(args[0],args[1],4,10,args[2],"fixture").is_empty() and JSON.stringify(g.state)==before,"TEMPLATE invalid installation has no id/resource effects "+str(args))
 t.check(not g.add_fixture("fingers",4,10,false,0,"cord").is_empty(),"TEMPLATE fine cord supports fingers")
 t.check(not g.add_fixture("toes",4,10,true,0,"fine_belt").is_empty(),"TEMPLATE fine leather supports locked toes")
 var before=JSON.stringify(g.state)
 t.check(g._install_template("rope","thigh",4,10,false,"fixture",4).is_empty() and JSON.stringify(g.state)==before,"TEMPLATE undefined grade not generated")
 for bad in [NAN,INF,-1.0,11.0]:
  t.check(g._install_template("rope","thigh",bad,10,false,"fixture").is_empty() and JSON.stringify(g.state)==before,"TEMPLATE invalid durability rejected")
 t.check(g._install_template("rope","thigh",4,10,false,"fixture",1,-1,99).is_empty() and JSON.stringify(g.state)==before,"TEMPLATE invalid material version rejected")

 # Different materials share capacity, order and the same damage pipeline.
 g=Game.new(3)
 var inner=g.add_fixture("ankle",8,10,false,0,"rope")
 var outer=g.add_fixture("ankle",4,10,false,2,"belt")
 var tape=g._install_template("tape","ankle",4,10,false,"fixture")
 t.check(tape.layer==2 and g.escape_preview(inner,"slip",5).reason!="","TEMPLATE normal addition joins current outer layer")
 t.check(g.escape_preview(inner,"strain",5).reason=="" and g.escape_preview(outer,"strain",5).reason!="","TEMPLATE mixed materials force highest strain target")
 before=JSON.stringify(g.state)
 t.check(g._install_template("cable_tie","ankle",4,10,false,"fixture").is_empty() and JSON.stringify(g.state)==before,"TEMPLATE mixed materials do not increase capacity")
 g=Game.new(3)
 tape=g.add_fixture("thigh",10,10,false,0,"tape")
 t.check(g.escape_preview(tape,"slip",5).immune,"TEMPLATE tight tape uses common tier-three immunity")
 tape.durability=4
 t.check(g.escape_preview(tape,"slip",5).damage>0,"TEMPLATE loose tape has no legacy dry-adhesion block")

 # Declared enemy pools select concrete equipment only on the real enemy turn.
 for template in ["rope","belt","tape","cable_tie"]:
  for final in [false,true]:
   g=preload("res://tests/enemy_cases.gd").encounter(template+"_solo",51)
   var enemy=g.state.enemies[0]
   var deck_rng=g.state.rng.deck
   var equipment_rng=g.state.rng.equipment
   var plan=g.EnemyPlans.application([template],2 if final else 1,2,1,final)
   enemy.intent=plan
   t.check(plan.kind=="apply" and plan.templates==[template],"POOL actual source declares allowed equipment "+template)
   t.check(plan.grade==(2 if final else 1) and plan.tier==(3 if final else 2),"POOL normal application retains requested tier; departure uses declared middle-grade tier three "+template)
   t.check(g.state.rng.deck==deck_rng and g.state.rng.equipment==equipment_rng,"POOL declaration does not draw card or material randomness")
   before=JSON.stringify(g.state)
   g.get_view();g.command_facts()
   t.check(JSON.stringify(g.state)==before,"POOL preview does not choose equipment or material")
   t.check(t.action(g,"end").ok,"POOL declared installation commits through real enemy turn "+template)
   var installed=g.state.equipment.filter(func(item):return item.source==enemy.id)[0]
   t.check(installed.template==template and installed.slot in E.TEMPLATES[template].slots and installed.grade==plan.grade and installed.maximum==E.maximum(plan.grade),"POOL committed instance matches declared source and grade "+template)
   t.check(g.tier(installed.durability,installed.maximum)==plan.tier,"POOL initial durability follows declared tier")

 g=preload("res://tests/enemy_cases.gd").encounter("rope_solo")
 for i in range(g._capacity("wrist")): g._install_template("rope","wrist",4,10,false,"fixture",1)
 var next_id=g.state.next_equipment
 t.check(t.action(g,"end").ok and g.state.next_equipment==next_id+1,"POOL full wrist leaves one installation at another legal position")
 t.check(g.state.equipment.back().slot!="wrist" and g.state.equipment.back().source==g.state.enemies[0].id,"POOL actual placement observes current capacity and preserves source identity")
 g=preload("res://tests/enemy_cases.gd").encounter("rope_solo")
 var plan=g.state.enemies[0].intent.duplicate(true)
 var material_rng=g.state.rng.equipment
 g.state.round=2
 g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.action(g,"attack",{"type":"kick","form":2,"enemy":g.state.enemies[0].id});t.action(g,"end")
 t.check(g.state.enemies[0].intent==plan and g.state.rng.equipment==material_rng,"POOL interrupt preserves declared source and does not select material early")

 # Locks select and recheck template capability, not just a target id.
 g=Game.new(42,true,"guard")
 var rope=g.add_fixture("thigh",4,10,false,0,"rope")
 var belt=g.add_fixture("calf",8)
 var lock=g.state.enemies[0]
 lock.stage=2
 t.check(g.EnemyPlans.targets(g,lock,"lock").map(func(e):return e.id)==[belt.id],"LOCK pool excludes non-lockable material")
 lock.intent={"kind":"guard_sequence","priority":false,"delayed":false,"text":"上锁","operations":[{"kind":"lock","target":rope.id,"text":"上锁","delayed":false}]}
 t.check(t.action(g,"end").ok and not rope.locked and not g._equipment(rope.id).locked,"LOCK commit rechecks non-lockable target")

 # Tool compatibility affects actual payment, durability and use counts.
 g=Game.new(42,true)
 var plastic=g.state.equipment.filter(func(e):return e.template=="cable_tie")[0]
 var shard=g.state.items[0]
 var saw=g.state.items[1]
 var cut=t.find_action(g,"item_use",{"item":shard.id,"target":plastic.id})
 before=JSON.stringify(g.state)
 t.check(not cut.valid and cut.reason.contains("塑料"),"TOOL stone explicitly cannot cut plastic")
 t.check(not g.dispatch(g.command(cut.payload,g.state.version),g.state.version).ok and JSON.stringify(g.state)==before,"TOOL incompatible attempt consumes no uses")
 t.check(t.action(g,"item_use",{"item":saw.id,"target":plastic.id}).ok and g._equipment(plastic.id).durability==1 and g._item(saw.id).uses==1 and g.state.energy==3,"TOOL saw cuts plastic through shared zero-energy action")
 t.check(g.state.encounter==0 and g.state.reward_count==0 and g.state.rest_left==6 and g.get_view().route.is_empty(),"PRACTICE no fake battle, rewards or route")
 for i in range(6): t.action(g,"end")
 t.check(g.state.phase=="cleared" and g.state.completed_rooms.is_empty() and g.command_facts().all(func(c):return c.payload.kind=="item_discard"),"PRACTICE ends after six real rounds without tower progress; only universal item discard remains")
 t.check(g.validate()=="","PRACTICE final state valid")

# docs/spec/equipment-query-seam.md「证据入口」: presence and count predicates over ordinary equipment in precise
# positions answer exactly like the live path, and agree with the slot and point edges.
static func index_predicate_parity(t) -> void:
 var g=Game.new(42)
 g.state.equipment.clear()
 for slot in ["thigh","calf","ankle","foot","wrist","palm","eyes","fingers"]: g.add_fixture(slot,7,10)
 g._install_template("belt","calf",4,10,false,"fixture",1,0,0,"below_knee")
 g._install_template("rope","thigh",4,10,false,"fixture",1,0,0,"mid_thigh")
 var reference=Arch.UncachedGame.new(42);reference.state=g.state.duplicate(true)
 var before=g.export_snapshot()
 var previous=g._begin_equipment_read()
 var parity=true
 for slot in g.B.SLOTS:
  parity=parity and g.occupied(slot)==reference.occupied(slot) and g.capacity_used(slot)==reference.capacity_used(slot)
  for side in ["left","right"]: parity=parity and g.hand_blocked(slot,side)==reference.hand_blocked(slot,side)
 for point in g.Equipment.ANATOMY+["missing_point"]: parity=parity and g._point_count(point)==reference._point_count(point)
 parity=parity and g._capacity_issue(g.physical_pieces())==reference._capacity_issue(reference.physical_pieces())
 parity=parity and g._capacity_issue(g.physical_pieces()+g.state.equipment.duplicate())==reference._capacity_issue(reference.physical_pieces()+reference.state.equipment.duplicate())
 parity=parity and g.occupied("calf")==(not g.equipment_at("calf").is_empty()) and g.hand_blocked("palm","left")==g.equipment_at("palm").any(func(e):return e.get("side","") in ["","left"])
 parity=parity and g._point_count("below_knee")==g.physical_pieces().filter(func(e):return "below_knee" in g.Equipment.capacity_points(e)).size() and g._point_count("missing_point")==0
 g._equipment_read=previous
 t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX predicate parity with the live path over precise positions")
 t.check(g.occupied("calf")==reference.occupied("calf") and g.capacity_used("calf")==reference.capacity_used("calf") and g._point_count("below_knee")==reference._point_count("below_knee"),"INDEX predicates outside a scope stay live")

static func index_fixture(kind: String):
 if kind=="component": return Game.new(42,true,"component_links")
 if kind=="shoulder": return Game.new(42,true,"shoulder_links")
 var g=Game.new(42)
 g.state.equipment.clear()
 g.add_fixture("thigh",7,10,false,0,"rope")
 g.add_fixture("thigh",7,10,false,0,"rope")
 g.add_fixture("calf",7,10,true)
 g._install_template("rope","upper_arm",10,10,false,"fixture",2)
 return g

# docs/spec/equipment-query-seam.md「证据入口」: the materialized slot edge and piece set answer exactly like the live
# path, in piece order, including the order that powers the "第 N 条" names.
static func index_slot_edge_parity(t) -> void:
 for kind in ["plain","component","shoulder"]:
  var g=index_fixture(kind)
  var reference=Arch.UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var previous=g._begin_equipment_read()
  var pieces=g.physical_pieces()
  var live=reference.physical_pieces()
  var parity=pieces==live and pieces.map(func(e):return e.id)==live.map(func(e):return e.id)
  for slot in g.B.SLOTS+["shoulder","special_2_d"]:
   var here=g.equipment_at(slot)
   var expected=reference.equipment_at(slot)
   parity=parity and here==expected and here.map(func(e):return e.id)==expected.map(func(e):return e.id)
  for e in pieces:
   parity=parity and is_same(e,g._equipment(e.id)) and g._equipment_name(e)==reference._equipment_name(reference._equipment(e.id))
  t.check(parity,"INDEX slot edge parity with the live path "+kind)
  t.check(g._equipment_index_issues.is_empty() and g.export_snapshot()==before,"INDEX slot edge read records no self-check issue and changes no state "+kind)
  g._equipment_read=previous
  t.check(g._equipment_read.is_empty(),"INDEX slot edge read releases its materialized index "+kind)
 var plain=index_fixture("plain")
 var plain_scope=plain._begin_equipment_read()
 var thigh=plain.equipment_at("thigh")
 var labels=thigh.map(func(e):return plain._equipment_name(e))
 t.check(thigh.size()==2 and labels[0]!=labels[1] and labels.all(func(label):return label.begins_with("第")),"INDEX slot edge keeps 第 N 条 order for repeated templates "+str(labels))
 var hosts=plain.state.equipment.filter(func(e):return e.has("shoulders"))
 t.check(hosts.size()==1 and plain.physical_pieces().size()==plain.state.equipment.size()+hosts[0].shoulders.pieces.size(),"INDEX piece set is equipment plus host shoulder pieces")
 plain._equipment_read=plain_scope

# docs/spec/equipment-query-seam.md「证据入口」: the materialized slot-target edge answers exactly like the live
# path, including shoulder pieces that stay off the slot edge and zero-durability specials.
static func index_targets_edge_parity(t) -> void:
 var cases=[]
 for kind in ["plain","component","shoulder"]: cases.append({"label":kind,"game":index_fixture(kind)})
 for kind in ["component_links","shoulder_links","special_equipment","torso_binding"]: cases.append({"label":kind,"game":Game.new(42,true,kind)})
 for entry in cases:
  var g=entry.game
  if entry.label=="special_equipment":
   t.check(not g.state.special_equipment.is_empty(),"INDEX special fixture has a special piece "+entry.label)
   if not g.state.special_equipment.is_empty(): g.state.special_equipment[0].durability=0
  var reference=Arch.UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var previous=g._begin_equipment_read()
  var slots=Arch.index_target_slots(g)
  var parity=true
  for slot in slots:
   var here=g.targets_at(slot)
   var expected=reference.targets_at(slot)
   parity=parity and here==expected and here.map(func(e):return e.id)==expected.map(func(e):return e.id)
   parity=parity and g.equipment_at(slot)==reference.equipment_at(slot) and g.occupied(slot)==reference.occupied(slot)
  var straps=g.physical_pieces().filter(func(e):return g.Equipment.is_shoulder(e) and e.durability>0)
  if not straps.is_empty():
   parity=parity and not g.targets_at("shoulder").is_empty() and g.equipment_at("shoulder").is_empty()
  for e in g.physical_pieces().filter(func(e):return g.Equipment.is_shoulder(e)):
   parity=parity and (e.durability<=0 or g.targets_at("shoulder").has(e))
   for slot in slots:
    if slot=="shoulder": continue
    parity=parity and not g.targets_at(slot).has(e)
  if entry.label=="special_equipment" and not g.state.special_equipment.is_empty():
   var dead=g.state.special_equipment[0]
   for slot in g.SpecialEquipment.occupied_slots(dead): parity=parity and g.targets_at(slot).has(dead)
  t.check(parity,"INDEX targets edge parity with the live path "+entry.label)
  t.check(g.export_snapshot()==before,"INDEX targets edge read changes no state "+entry.label)
  g._equipment_read=previous
  t.check(g._equipment_read.is_empty(),"INDEX targets edge read releases its materialized index "+entry.label)
  var live=true
  for slot in slots:
   live=live and g.targets_at(slot)==reference.targets_at(slot) and g.targets_at(slot).map(func(e):return e.id)==reference.targets_at(slot).map(func(e):return e.id)
  t.check(live,"INDEX targets_at outside a scope stays live "+entry.label)

static func release_projection(t) -> void:
 var g=Game.new(42);g.state.equipment.clear();g._discard_end();g.state.wall="normal"
 var target=g.add_fixture("ankle",10,10)
 var slip=preload("res://tests/curse_cases.gd").give(g,"slip")
 var before=g.export_snapshot()
 var c=g.get_view().display_facts.filter(func(action):return action.payload.kind=="card" and action.payload.uid==slip.uid and action.payload.get("target","")==target.id and not action.payload.free)[0]
 t.check(c.valid and c.release_preview.before==c.release_preview.after and not c.release_preview.modifiers.is_empty(),"RELEASE immune slip is an explicit zero-change preview, not a blocked method")
 t.check(g.export_snapshot()==before,"RELEASE projection changes no state, payment, logs or RNG")
 g.state.equipment.clear();g._discard_end()
 var collar=g._install_template("restriction_collar","neck",1,1,true,"fixture",3)
 var card=preload("res://tests/curse_cases.gd").give(g,"unlock")
 g.state.sure_cast=true
 c=g.get_view().display_facts.filter(func(action):return action.payload.kind=="card" and action.payload.uid==card.uid and action.payload.get("target","")==collar.id and not action.payload.free)[0]
 t.check(c.valid and c.release_preview.headline=="已上锁 → 已开锁" and not c.release_preview.headline.contains("耐久"),"RELEASE lock-only equipment shows lock outcome without fake durability")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and not g._equipment(collar.id).locked,"RELEASE original unlock transaction still commits")
 c=g.get_view().display_facts.filter(func(action):return action.payload.kind=="manual" and action.payload.target==collar.id)[0]
 t.check(c.valid and c.release_preview.headline=="整件取下","RELEASE unlocked collar uses categorical removal preview")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._equipment(collar.id).is_empty(),"RELEASE categorical removal matches the actual lifecycle")

static func precise_positions(t) -> void:
 var g=Game.new(42)
 var low=g._install_template("rope","calf",4,10,false,"fixture",1,0,0,"mid_calf")
 var high=g._install_template("belt","calf",10,10,false,"fixture",1,2,0,"below_knee")
 t.check(g.escape_preview(low,"slip",5).reason=="" and not g.escape_preview(low,"slip",5).immune and g.escape_preview(low,"strain",5).divisor==1,"POSITION separate calf segments do not share outer blocking, tightness or stack penalty")
 var view=g.get_view();var body=view.bodies.filter(func(b):return b.id=="calf")[0]
 t.check(body.targets.values()[0].id==high.id and body.targets[low.id].position_text=="小腿中间","POSITION target boxes sort anatomically despite reverse creation order")
 t.check(view.body_coverage.points==["mid_calf","below_knee"],"POSITION ordinary piece covers exactly one physical segment")
 var saved=g.export_snapshot();var restored=Game.new(0,false,"equipment",false)
 t.check(restored.restore_snapshot(saved).ok and restored.get_view().body_coverage==view.body_coverage,"POSITION save/load preserves exact occupied locations")
 var before=JSON.stringify(g.state)
 t.check(g._install_template("rope","calf",4,10,false,"fixture",1,0,0,"thigh_root").is_empty() and JSON.stringify(g.state)==before,"POSITION foreign body position is rejected atomically")
 var cover=g._install_template("tape","calf",4,10,false,"fixture",1,3,0,"mid_calf")
 t.check(not cover.is_empty() and g.escape_preview(low,"slip",5).reason!="" and g.escape_preview(high,"strain",5).divisor==1,"POSITION same-segment outer cover blocks only that segment")
 g=Game.new(42,true,"glove_long")
 body=g.get_view().bodies.filter(func(b):return b.id=="forearm")[0]
 t.check(body.targets.size()==1 and g.get_view().body_groups.filter(func(b):return b.id=="neck")[0].targets.values().all(func(e):return e.position_text in ["左肩","右肩"]),"POSITION shoulders have own neck location instead of forearm targets")

static func mouth_stacking(t) -> void:
 var g=Game.new(42);g.state.energy=30
 var gag=g.add_fixture("mouth",8,10,false,1,"mouth_band")
 var before=g.export_snapshot()
 t.check(g._capacity("mouth")==2 and g._install_template("mouth_band","mouth",4,10,false,"fixture").is_empty() and g.state==before,"MOUTH STACK two positions do not allow a second non-tape restraint")
 var options=g.EquipmentOffers.ordinary(g,1,false,["mouth_band","mouth_tape"])
 t.check(options.size()==1 and options[0].template=="mouth_tape" and g.state==before,"MOUTH STACK real offer generator only allows tape over an occupied mouth without writes")
 var result=g.Application.execute(g,{"pool":"ordinary","templates":["mouth_tape"],"count":1,"grade":1,"tier":1},"event:mouth_stack")
 var tape=g.equipment_at("mouth").filter(func(e):return e.material=="tape")[0]
 t.check(result.ok and tape.layer>gag.layer and not g._outer(gag) and g._outer(tape) and g.validate()=="","MOUTH STACK real application installs mixed-material tape in the outer layer")
 var mouth=g.get_view().body_groups.filter(func(b):return b.id=="mouth")[0]
 t.check(mouth.capacity==2 and mouth.capacity_used==2 and mouth.sections[0].equipment[0].id==tape.id,"MOUTH STACK projection shows two positions and outer tape first")
 t.check(g.escape_preview(gag,"slip",5).reason!="" and not t.find_action(g,"manual",{"target":gag.id}).valid,"MOUTH STACK inner gag cannot be slipped or manually removed through tape")
 before=g.export_snapshot()
 t.check(g._install_template("mouth_tape","mouth",4,10,false,"fixture").is_empty() and g.state==before,"MOUTH STACK third item is rejected without consuming IDs or resources")
 var restored=Game.new(42)
 t.check(restored.restore_snapshot(before).ok and not restored._outer(restored._equipment(gag.id)),"MOUTH STACK two-piece save restores the real cover relationship")
 var broken=before.duplicate(true);var third=tape.duplicate(true)
 third.id="equipment_"+str(broken.next_equipment);broken.next_equipment+=1;broken.equipment.append(third)
 t.check(not g.restore_snapshot(broken).ok and g.state==before,"MOUTH STACK existing capacity validator rejects three saved pieces atomically")
 for layer in [gag.layer,maxi(0,gag.layer-1)]:
  broken=before.duplicate(true)
  broken.equipment.filter(func(e):return e.id==tape.id)[0].layer=layer
  t.check(not g.restore_snapshot(broken).ok and g.state==before,"MOUTH STACK aggregate validation rejects mixed tape at or below the gag layer atomically")
 broken=before.duplicate(true)
 var duplicate=gag.duplicate(true);duplicate.id=tape.id
 broken.equipment[broken.equipment.find(broken.equipment.filter(func(e):return e.id==tape.id)[0])]=duplicate
 t.check(not g.restore_snapshot(broken).ok and g.state==before,"MOUTH STACK aggregate validation rejects two non-tape mouth pieces atomically")
 var slip=t.hand_card(g,"slip")
 t.check(t.action(g,"card",{"uid":slip.uid,"target":tape.id}).ok and g._equipment(tape.id).is_empty() and g._outer(gag),"MOUTH STACK real card removes outer tape and exposes the original gag")
 t.check(t.action(g,"manual",{"target":gag.id}).ok and g.equipment_at("mouth").is_empty(),"MOUTH STACK exposed gag becomes removable through the existing action")
 g=Game.new(42)
 tape=g.add_fixture("mouth",4,10,false,0,"mouth_tape");before=g.export_snapshot()
 t.check(g._install_template("mouth_band","mouth",4,10,false,"fixture").is_empty() and g.state==before,"MOUTH STACK gag cannot be inserted under existing tape")
 var second=g.add_fixture("mouth",4,10,false,0,"mouth_tape")
 t.check(not second.is_empty() and second.layer==tape.layer and g.validate()=="","MOUTH STACK two tape pieces preserve normal same-material stacking")
 before=g.export_snapshot()
 t.check(g._install_template("mouth_tape","mouth",4,10,false,"fixture").is_empty() and g.state==before,"MOUTH STACK same-material stack also stops at two")
 g=Game.new(42);gag=g.add_fixture("mouth",4,10,false,5,"mouth_band")
 tape=g.add_fixture("mouth",4,10,false,0,"mouth_tape")
 t.check(tape.layer>gag.layer and g.validate()=="","MOUTH STACK explicit fixture layer cannot place mixed tape inside the gag")
