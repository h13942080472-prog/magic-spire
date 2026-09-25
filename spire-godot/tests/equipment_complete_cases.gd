extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const C=preload("res://data/composites.gd")
const E=preload("res://data/equipment.gd")
const Tower=preload("res://data/tower.gd")
# Living index-off reference for the B3 parity checks (single definition in the architecture suite).
const Arch=preload("res://tests/architecture_cases.gd")

static func piece(g, root_id: String, key: String) -> Dictionary:
 return g._composite(root_id).components.filter(func(e):return e.part==key)[0]

static func cover_id(g, target: Dictionary, slot: String, point: String="") -> String:
 return g._outer_cover_at(target,slot,point).get("id","")

# docs/spec/equipment-query-seam.md「证据入口」: the capacity and physical point edges, their counts and the coverage reason
# agree with the live path, including templates whose capacity_points is empty.
static func index_point_edge_parity(t) -> void:
 for kind in ["leg_layers","component_links","head_harness","plain"]:
  var g=Game.new(42,true,kind) if kind!="plain" else Game.new(42)
  if kind=="plain":
   g.add_fixture("thigh",7,10)
   g._install_template("belt","calf",4,10,false,"fixture",1,0,0,"below_knee")
   g.add_fixture("ankle",4)
  var reference=Arch.UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var previous=g._begin_equipment_read()
  var parity=true
  for slot in g.B.SLOTS: parity=parity and g.capacity_used(slot)==reference.capacity_used(slot)
  for point in E.ANATOMY+["missing_point"]: parity=parity and g._point_count(point)==reference._point_count(point)
  parity=parity and g._capacity_issue(g.physical_pieces())==reference._capacity_issue(reference.physical_pieces())
  for target in reference.physical_pieces():
   var here=g._equipment(target.id)
   for slot in E.coverage(target):
    parity=parity and cover_id(g,here,slot)==cover_id(reference,target,slot)
    for point in E.physical_points(target): parity=parity and cover_id(g,here,slot,point)==cover_id(reference,target,slot,point)
  for spec in [["rope","thigh",1],["belt","calf",1],["tape","ankle",2],["fine_belt","toes",1],["eye_cloth","eyes",1]]:
   parity=parity and g._prepare_installation(spec[0],spec[1],spec[2])==reference._prepare_installation(spec[0],spec[1],spec[2])
  g._equipment_read=previous
  t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX point edge parity with the live path "+kind)
 var leg=Game.new(42,true,"leg_layers")
 var body=piece(leg,leg.state.composites[0].id,"body")
 var point=E.physical_points(body)[0]
 var physical_members=leg.physical_pieces().filter(func(e):return point in E.physical_points(e)).size()
 var leg_scope=leg._begin_equipment_read()
 t.check(E.capacity_points(body).is_empty() and physical_members>leg._point_count(point),"INDEX capacity edge excludes the capacity-free body the physical edge still counts: "+point)
 leg._equipment_read=leg_scope

static func run(t) -> void:
 assembly_preparation(t)
 index_point_edge_parity(t)
 for config in [[1,0,"普通口球",false],[2,0,"马具口球",true],[2,1,"普通假阳具口球",false],[3,0,"马具假阳具口球",true]]:
  var gag_game=Game.new(42,true,"mouth_combination_%d_%d" % [config[0],config[1]])
  var gag=gag_game.equipment_at("mouth")[0]
  t.check(gag.name==config[2] and gag.grade==config[0] and gag.maximum==E.maximum(config[0]),"MOUTH combination determines name and grade")
  t.check(E.has_mouth_harness(gag)==config[3] and E.allows(gag,"slip")== (not config[3]) and gag_game.state.composites.is_empty(),"MOUTH reuse existing methods with one physical target")
  var saved=gag_game.export_snapshot()
  var restored=Game.new(42)
  t.check(restored.restore_snapshot(saved).ok and restored.equipment_at("mouth")[0].name==config[2],"MOUTH combination persists without reroll")
 # Every visible scenario must create every declared object, not silently skip illegal fixtures.
 for id in Tower.all_practices():
  var g=Game.new(42,true,id)
  var spec=Tower.practice_spec(id)
  var intake=spec.get("start","") in ["prison_release","prison_release_violation","prison_gate_exit"]
  var layout_matches=g.state.equipment.size()==spec.equipment.size() and g.state.composites.size()==spec.get("composites",[]).size()
  if intake: layout_matches=not g.state.capture.is_empty() and not g.state.capture.baseline.is_empty() and g.state.capture.baseline==g.equipment_targets().map(func(e):return e.id)
  if spec.get("start","")=="prison_gate_exit": layout_matches=g.Cards.worn_count(g,false)>=g.B.PRISON_INTAKE[1].floor+g.B.PRISON_INTAKE[1].extra and g.state.special_equipment.size()==g.B.PRISON_INTAKE[1].special
  t.check(g.validate()=="" and layout_matches,"CATALOG complete legal scenario "+id)
  var correct_phase=(g.state.phase=="battle" and g.state.encounter==1) if spec.has("encounter") else (g.state.phase=="rest" and g.state.rest_left==6)
  if spec.has("event"): correct_phase=g.state.phase=="event" and g.state.room_event.id==spec.event
  if spec.get("start","")=="prison": correct_phase=g.state.phase=="prison" and g.state.prison.left==g.B.PRISON_INTERVALS[0] and g.state.posture=="lie"
  if spec.get("start","")=="shop": correct_phase=g.state.phase=="shop" and g.state.energy==0 and not g.room_data(g.state.room).stock.is_empty()
  var links_match=g.state.links.size()==spec.get("links",[]).size()+spec.get("component_links",[]).size()
  if intake:
   correct_phase=g.state.phase=="battle" and g.Prison.is_exit_battle(g) if spec.start=="prison_gate_exit" else g.state.phase=="captured"
   links_match=not g.state.links.is_empty() if spec.start=="prison_gate_exit" else g.state.links.map(func(e):return e.id)==g.state.capture.links and g.state.special_equipment.map(func(e):return e.id)==g.state.capture.special_baseline
  t.check(links_match and correct_phase,"CATALOG links and entry phase match declared layout or formal intake "+id)
  var before=JSON.stringify(g.state)
  var view=g.get_view()
  t.check(JSON.stringify(g.state)==before and view.practice_kind==id and view.display_facts.size()>0,"CATALOG projection and actual actions "+id)
 for template in E.TEMPLATES:
  var definition=E.TEMPLATES[template]
  if definition.slots.is_empty(): continue
  for grade in [1,2,3]:
   var g=Game.new(42)
   var maximum=1.0 if definition.get("lock_only",false) else E.maximum(grade)
   var durability=1.0 if definition.get("lock_only",false) else maximum*0.4
   var e=g._install_template(template,definition.slots[0],durability,maximum,false,"fixture",grade)
   if grade<definition.get("min_grade",1):
    t.check(e.is_empty() and g.validate()=="","GRADE rejects below template minimum "+template+str(grade))
   else: t.check(not e.is_empty() and e.grade==grade and g.validate()=="","GRADE actual legal material/grade "+template+str(grade))

 for variant in C.LEGS:
  var g=Game.new(42,true,"leg_"+variant)
  var root=g.state.composites[0]
  var body=piece(g,root.id,"body")
  t.check(g.escape_preview(body,"slip",5).reason.contains("全部外带"),"LEG whole slip requires every band "+variant)
  t.check(not g.escape_preview(body,"strain",5).release,"LEG does not inherit glove shortcut")
  var bands=root.components.filter(func(e):return e.part!="body")
  var kept=JSON.stringify(bands)
  body.durability=1
  if variant=="lower": t.action(g,"posture",{"dest":"sit","wall":false})
  t.check(t.action(g,"item_use",{"item":g.state.items[0].id,"target":body.id}).ok,"LEG actual cutting destroys body "+variant)
  t.check(JSON.stringify(g._composite(root.id).components)==kept and not C.active(g._composite(root.id)),"LEG all independent bands retain exact identities and state "+variant)
  t.check(g.get_view().bodies.any(func(b):return b.groups.any(func(group):return group.name.contains("遗留外带"))),"LEG UI explains remaining independent bands")
  t.check(g.state.posture==("sit" if variant=="lower" else "stand") and g.validate()=="","LEG no forced posture and valid remaining capacity")
  if variant=="toes": t.check(not g.occupied("foot") and not g.occupied("toes") and g.occupied("ankle"),"LEG toes recover but surviving ankle band still restricts movement")

 var g=Game.new(42,true,"component_links")
 var root=g.state.composites[0]
 var body=piece(g,root.id,"body")
 var link=g.state.links[0].duplicate(true)
 var band=piece(g,root.id,"above_knee")
 band.locked=true
 body.durability=1
 t.check(t.action(g,"item_use",{"item":g.state.items[0].id,"target":body.id}).ok,"LINK cut linked assembly body through normal tool candidate")
 t.check(g._equipment(band.id).locked and JSON.stringify(g.state.links[0])==JSON.stringify(link),"LINK live independent band preserves lock and link after body removed")
 t.action(g,"posture",{"dest":"sit","wall":false})
 var other=link.ends[1]
 t.check(t.action(g,"manual",{"target":other}).ok and g.state.links.is_empty() and not g._equipment(band.id).is_empty(),"LINK removing the other endpoint cleans rope without deleting independent partner")

 g=Game.new(42,true,"leg_layers")
 t.check(g.state.composites.size()==3 and g.capacity_used("thigh")==2 and g.capacity_used("ankle")==2,"LEG shorts plus long reserve capacity per real band position")
 var upper=g.state.composites[0]
 var outer=g.state.composites[2]
 t.check(g.escape_preview(piece(g,upper.id,"body"),"slip",5).reason!="","LEG outer long sleeve blocks inner short")
 var before=JSON.stringify(g.state)
 t.check(g._install_assembly("leg","toes","fixture").is_empty() and JSON.stringify(g.state)==before,"LEG two long sleeves rejected atomically")
 t.check(g._install_assembly("leg","upper","fixture").is_empty(),"LEG cannot insert duplicate short beneath existing long")
 band=g._install_template("belt","thigh",4,10,false,"fixture")
 t.check(not band.is_empty() and band.points==["mid_thigh"] and g._point_count("mid_thigh")==1,"LEG ordinary band occupies only available middle point")
 while g._installation_reason("rope","thigh",1)=="":
  t.check(not g._install_template("rope","thigh",4,10,false,"fixture").is_empty(),"LEG fills each precise location through factory")
 before=JSON.stringify(g.state)
 t.check(g._install_template("rope","thigh",4,10,false,"fixture").is_empty() and JSON.stringify(g.state)==before,"LEG rejects only after every precise location is full")

 # Intact sleeves keep their own restrictions even after bands are removed.
 g=Game.new(42,true,"leg_upper")
 root=g.state.composites[0]
 for key in ["thigh_root","above_knee"]: t.check(t.action(g,"manual",{"target":piece(g,root.id,key).id}).ok,"LEG reachable bands can be unfastened independently")
 body=piece(g,root.id,"body")
 t.check(g.escape_preview(body,"slip",5).reason=="" and g.occupied("thigh") and g.capacity_used("thigh")==0,"LEG opened body remains restrictive but adds no reserved band capacity")
 g.state.posture="lie"
 t.check(not t.find_action(g,"hook",{"target":body.id}).valid,"LEG upper-only body is not a lying ankle hook target")

 g=Game.new(42,true,"jacket")
 root=g.state.composites[0]; body=piece(g,root.id,"body")
 var sleeves=piece(g,root.id,"sleeves")
 t.check(g.level("arms")==4 and not g.hands_can_hold(),"JACKET actual sleeve and finger restrictions")
 t.check(g.escape_preview(sleeves,"slip",5).reason!="" and g.escape_preview(sleeves,"strain",5).reason=="","JACKET connection can strain but never slip")
 t.check(not t.find_action(g,"hook",{"target":sleeves.id}).valid and not t.find_action(g,"hook",{"target":body.id}).valid,"JACKET hook cannot bypass either prerequisite")
 before=JSON.stringify(g.state)
 t.check(g._install_template("belt","upper_arm",4,10,false,"fixture").is_empty() and g._install_assembly("glove","short","fixture",2,2,{},"straight").is_empty() and JSON.stringify(g.state)==before,"JACKET sealed region and glove conflict rejected")
 g.state.items[0].mount="hand_wall"
 sleeves.durability=1
 t.check(g.InstalledTools.reason(g,g.state.items[0],sleeves)=="","JACKET installed tool contacts connection")
 g._apply_equipment_damage(sleeves,5,"cut");g._cleanup()
 t.check(g.escape_preview(piece(g,root.id,"body"),"slip",5).reason!="","JACKET hem still required after sleeve connection gone")
 var hem=piece(g,root.id,"hem"); hem.durability=1
 t.check(t.action(g,"hook",{"target":hem.id}).ok and g.escape_preview(piece(g,root.id,"body"),"slip",5).reason=="","JACKET both removed opens body slip")
 t.check(not g.escape_preview(piece(g,root.id,"body"),"strain",5).release,"JACKET never inherits glove automatic exit")
 piece(g,root.id,"body").durability=1
 g._apply_equipment_damage(piece(g,root.id,"body"),5,"cut");g._cleanup()
 t.check(g.state.composites.is_empty(),"JACKET body destruction clears attached structure")

 for side in ["left","right"]:
  g=Game.new(42)
  root=g._install_assembly("wrap",side,"fixture",1,1)
  body=piece(g,root.id,"body")
  t.check(g.hand_blocked("fingers",side) and not g.occupied("fingers") and g.level("arms")==1,"WRAP one side contributes one arm point without disabling both hands")
  var free=t.grant_fixture_card(g,"unlock")
  t.check(not t.find_action(g,"card",{"uid":free.uid,"slot":"fingers","free":true}).valid,"WRAP single free hand does not meet default spell condition")
  g.RelicEffects.gain(g,"casting_manual")
  t.check(t.find_action(g,"card",{"uid":free.uid,"slot":"fingers","free":true}).valid,"WRAP casting manual permits opposite intact hand for spell preparation")
  g._gain_tool("shard")
  t.check(t.action(g,"item_use",{"item":g.state.items[0].id,"target":body.id}).ok and g.state.composites.is_empty(),"WRAP free opposite hand cuts and restores both covered slots")
  t.check(g.restraint_degree("arms")==0,"WRAP removing last single-sided component restores zero arm score")
 g=Game.new(42,true,"wrap_both")
 t.check(g.level("arms")==1 and g.occupied("fingers") and g.item_capacity()==2 and not g.hands_can_hold(),"WRAP two independent wraps count hand region once and disable both grips")
 var left=g.state.composites[0]
 t.check(t.action(g,"hook",{"target":piece(g,left.id,"body").id}).ok and not g.occupied("fingers") and g.state.composites.size()==1,"WRAP releasing one hand immediately restores holding")
 for slot in ["upper_arm","forearm","wrist"]: g.add_fixture(slot,4)
 t.check(g.level("arms")==3,"WRAP all arm regions with only one wrapped hand are not fully restrained")
 g._install_assembly("wrap","left","fixture",1,1)
 t.check(g.level("arms")==4,"WRAP all arm regions and both separately wrapped hands reach full restraint")
 g=Game.new(42)
 g.add_fixture("fingers",4,10,false,0,"cord")
 before=JSON.stringify(g.state)
 t.check(g._install_assembly("wrap","left","fixture",1).is_empty() and JSON.stringify(g.state)==before,"WRAP cannot be inserted over already occupied hand at application")

 g=Game.new(42,true,"head_harness")
 var harness=g.equipment_at("mouth")[0]
 var cloth=g.equipment_at("eyes").filter(func(e):return e.template=="eye_cloth")[0]
 var tape=g.equipment_at("eyes").filter(func(e):return e.template=="eye_tape")[0]
 var mouth=g.equipment_at("mouth")[0]
 t.check(g.equipment_at("mouth").size()==1 and g.state.composites.is_empty() and not g.escape_preview(harness,"strain",5).reason.length(),"HEAD integrated harness uses one mouth target and durability")
 t.check(g.escape_preview(cloth,"slip",5).reason.contains("更紧") and g.escape_preview(tape,"slip",5).reason=="","HEAD compare each mask separately and allow equality")
 g.state.posture="sit"
 t.check(not t.find_action(g,"hook",{"target":cloth.id}).valid and t.find_action(g,"hook",{"target":tape.id}).valid,"HEAD hook respects unequal tightness structure comparison")
 t.check(g.escape_preview(mouth,"slip",5).reason.contains("马具") and g.escape_preview(harness,"slip",5).reason!="","HEAD mouth and harness structural slip rules differ")
 before=JSON.stringify(g.state)
 t.check(g._install_template("eye_cloth","eyes",8,10,false,"fixture").is_empty() and JSON.stringify(g.state)==before,"HEAD third mask is rejected without changing the two existing masks")
 cloth.durability=0;g._cleanup()
 var mask=g._install_template("eye_cloth","eyes",8,10,false,"fixture")
 t.check(not mask.is_empty() and g.escape_preview(mask,"slip",5).reason=="","HEAD mask may be installed beneath existing harness")
 before=JSON.stringify(g.state)
 t.check(g._install_template("eye_tape","eyes",4,10,false,"fixture").is_empty() and JSON.stringify(g.state)==before,"HEAD cloth/tape masks share capacity")
 t.check(not t.find_action(g,"item_use",{"item":g.state.items[0].id,"target":harness.id}).valid,"HEAD no tool expands to head or neck")
 t.check(t.action(g,"manual",{"target":mouth.id}).ok and g.state.composites.is_empty() and g.occupied("eyes"),"HEAD removing compatible mouth attachment cleans harness, keeps masks")
 g=Game.new(42)
 t.check(g._install_assembly("head","harness","fixture").is_empty(),"HEAD cannot generate free-standing harness without compatible prior mouth equipment")
 g=Game.new(42,true,"head_harness")
 harness=g.equipment_at("mouth")[0]
 mouth=g.equipment_at("mouth")[0]
 harness.locked=true
 var locked_damage=g.escape_preview(harness,"strain",5).damage
 harness.locked=false
 t.check(is_equal_approx(g.escape_preview(harness,"strain",5).damage,locked_damage*2),"HEAD own lock halves strain on actual harness target")
 t.check(t.action(g,"manual",{"target":harness.id}).ok and g._equipment(mouth.id).is_empty(),"HEAD manual release removes whole integrated gag")
 t.check(g.equipment_at("eyes").size()==2 and g.validate()=="","HEAD harness removal leaves two separate valid masks")

 # Failed commits roll back all resources and logs, including malformed component state.
 for scenario in ["leg_layers","wrap_both","jacket"]:
  g=Game.new(42,true,scenario)
  var pending=t.find_action(g,"end")
  g.state.composites[0].components[0].side="invalid"
  before=JSON.stringify(g.state)
  var rejected=g.dispatch(g.command(pending.payload,g.state.version),g.state.version)
  t.check(not rejected.ok and JSON.stringify(g.state)==before,"ASSEMBLY malformed structure rejects and rolls back full turn "+scenario)

 # High-tier assemblies use the same mechanics and constraints, no secret magical affixes.
 for args in [["glove","long"],["leg","toes"],["jacket","standard"],["wrap","left"]]:
  g=Game.new(42)
  root=g._install_assembly(args[0],args[1],"fixture",3,3)
  t.check(not root.is_empty() and root.components.all(func(e):return e.maximum==24 and e.grade==3) and g.state.mana==100,"GRADE high assembly uses registered temporary values only")

static func assembly_preparation(t) -> void:
 for occupied in [false,true]:
  var g=Game.new(42)
  if occupied: g._install_assembly("glove","long","fixture")
  var identity=g.state
  var before=g.export_snapshot()
  var offers=g.EquipmentOffers.options(g)
  t.check(is_same(identity,g.state) and g.state==before,"ASSEMBLY offers preserve original state identity, ids, logs and RNG")
  for config in C.GENERATION:
   var attached=config[3] if config.size()>3 else ""
   var prepared=g._prepare_assembly(config[0],config[1],"fixture",2,2,{},config[2],attached)
   t.check(g.state==before,"ASSEMBLY preflight is read-only even for blocked configurations")
   var trial=Game.new(42)
   t.check(trial.restore_snapshot(before).ok,"ASSEMBLY matching installation starts from the same snapshot")
   var trial_before=trial.export_snapshot()
   var installed=trial._install_assembly(config[0],config[1],"fixture",2,2,{},config[2],attached)
   t.check(prepared==installed,"ASSEMBLY probe and real factory agree for "+config[0]+"/"+config[1])
   if prepared.is_empty():
    t.check(trial.state==trial_before,"ASSEMBLY rejection leaves the whole state unchanged")
   else:
    prepared.components[0].durability=0
    t.check(trial.state.composites.back().components[0].durability>0 and g.state==before,"ASSEMBLY prepared data cannot mutate either live state")
  t.check(not offers.is_empty(),"ASSEMBLY blocked composite still leaves ordinary legal offers")
