extends RefCounted
const CaptureBind=preload("res://core/capture_bind.gd")
const Game=preload("res://tests/game_fixture.gd")
const Guard=preload("res://core/guard.gd")

static func bind(g, enemy: Dictionary, progress: float=50.0) -> void:
 g.state.guard_bind={"progress":progress,"sources":{"guard":{"enemy":enemy.id,"energy":0}}}
 enemy.guard.bind_ready=false

static func ready(g) -> void:
 var enemy=g.state.enemies.filter(func(e):return g.Enemies.behavior(e.type)=="guard")[0]
 bind(g,enemy,100.0)
 enemy.stage=4
 enemy.intent=Guard.build(g,enemy)

# docs/spec/transition-pipeline.md「证据入口」：收押经主路径——迁移日志含 `battle_end_captured`，阶段／房间
# 与今天逐字节相同（oracle 冻结），收押副作用（能量归零、无力化、牢房初始化）顺序不变。
static func capture_routes_through_the_main_path(t) -> void:
 var arch=preload("res://tests/architecture_cases.gd")
 for route in ["surrender","announced"]:
  var g=Game.new(42) if route=="surrender" else Game.new(42,true,"guard")
  if route=="announced":
   var enemy=g.state.enemies[0]
   bind(g,enemy,100.0)
   enemy.stage=4
   enemy.intent={"kind":"bind_gain","text":"捕缚进度＋10","delayed":false}
   t.check(t.action(g,"end").ok and g.state.phase=="battle","TRANSITION CAPTURE the guard really announces arrest")
  var before=arch.transition_log(g)
  var outcome=t.action(g,"surrender") if route=="surrender" else t.action(g,"end")
  t.check(outcome.ok,"TRANSITION CAPTURE capture commits "+route)
  var delta=arch.transition_delta(g,before)
  t.check(delta==["battle_end_captured"],"TRANSITION CAPTURE exactly one declared capture kind "+route+": "+str(delta))
  t.check(String(g.state.phase)=="captured" and String(g.state.room)=="prison","TRANSITION CAPTURE phase and room unchanged "+route+": "+String(g.state.phase)+"/"+String(g.state.room))
  t.check(g.state.energy==0 and g.state.weakness_turns==0 and g.state.prepare_left==0 and g.state.rest_left==0,"TRANSITION CAPTURE resource side effects unchanged "+route)
  t.check(not g.state.capture.is_empty() and g.state.capture.security==g.state.security and g.state.capture.by!="","TRANSITION CAPTURE intake record written after the transition "+route)
  t.check(g.state.capture.baseline==g.equipment_targets().map(func(e):return e.id) and g.state.capture.special_baseline==g.state.special_equipment.map(func(e):return e.id),"TRANSITION CAPTURE intake snapshot taken after the phase and room write "+route)
  t.check(not g.room_data("prison").is_empty() and g.state.wall=="rough","TRANSITION CAPTURE cell exists and the wall is rough "+route)
  t.check(g.validate()=="","TRANSITION CAPTURE captured state validates "+route+": "+g.validate())
static func run(t) -> void:
 lower_and_charge(t)
 opening_fallback(t)
 capture_routes_through_the_main_path(t)

 var g=Game.new(42,true,"guard")
 var e=g.state.enemies[0]
 var pool=g.Enemies.TYPES.guard.visual_pool
 t.check(e.visual_variant in pool and g.get_view().enemies[0].visual_variant==e.visual_variant,"GUARD generated portrait variant is projected from stable enemy state")
 var duplicate_found=false
 for seed in range(12):
  var sample=Game.new(seed,true,"double_guard")
  var variants=sample.state.enemies.map(func(enemy):return enemy.visual_variant)
  t.check(variants.size()==2 and variants.all(func(variant):return variant in pool),"GUARD each paired guard independently draws a registered portrait "+str(seed))
  if variants[0]==variants[1]: duplicate_found=true
 t.check(duplicate_found,"GUARD independent portrait draws explicitly allow duplicate results")
 var fixed_variant=e.visual_variant
 t.check(e.type=="guard" and e.hp==90 and e.intent.kind=="guard_sequence" and e.intent.operations.size()==3,"GUARD opening publishes three fixed applications")
 t.check(e.intent.operations.map(func(op):return op.required_slots[0])==["wrist","mouth","ankle"] and e.intent.operations.all(func(op):return op.grade==2 and op.tier==2 and op.replace and op.tighten_missing),"GUARD opening fixes wrist mouth ankle at medium tier two with replacement and reinforcement fallback")
 t.check(t.action(g,"end").ok and g.occupied("wrist") and g.occupied("mouth") and g.occupied("ankle") and g._enemy(e.id).intent.kind=="bind_prepare" and g._enemy(e.id).visual_variant==fixed_variant,"GUARD opening uses real application factory and keeps its generated portrait")
 t.check(t.action(g,"end").ok and g._enemy(e.id).guard.bind_ready and g._enemy(e.id).intent.kind=="bind_apply" and g.state.guard_bind.is_empty(),"GUARD preparation consumes one full enemy action")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==50.0 and g.level("arms")>=1 and g._enemy(e.id).intent.kind=="apply" and g._enemy(e.id).intent.count==2,"GUARD bind starts at fifty and enters two-restraint cycle")

 e=g._enemy(e.id)
 e.guard.cycle_step=1;e.intent=Guard.build(g,e)
 t.check(e.intent.kind=="bind_gain","GUARD second cycle step publishes bind gain")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==60.0 and g._enemy(e.id).guard.cycle_step==2,"GUARD bind gain advances the cycle")
 e=g._enemy(e.id)
 e.intent=Guard.build(g,e)
 t.check((e.intent.kind=="apply" and e.intent.pool=="composite") or (e.intent.kind=="equipment_batch" and e.intent.tighten and e.intent.count==2 and e.intent.tier==3),"GUARD third cycle step chooses composite or total-six reinforcement fallback")
 var fallback=Guard.reinforcement(g,e)
 t.check(fallback.kind=="equipment_batch" and fallback.tighten and fallback.count==2 and fallback.tier==3,"GUARD unavailable composite fallback represents two tier-three reinforcements totaling six")

 g=Game.new(7,true,"guard")
 e=g.state.enemies[0]
 bind(g,e,100.0)
 e.stage=4;e.intent={"kind":"bind_gain","text":"捕缚进度＋10","delayed":false}
 t.check(t.action(g,"end").ok and g._enemy(e.id).intent.kind=="capture" and g.state.phase=="battle","GUARD full bind schedules capture for the next enemy action")
 var mana=g.state.mana
 var ordinary_tools=g.state.items.size()
 g._gain_tool("return_seal")
 var retained_seal=g.state.items.filter(func(item):return item.type=="return_seal")[0].duplicate(true)
 var capture_result=t.action(g,"end")
 t.check(capture_result.ok and g.state.phase=="captured" and g.state.security==1 and g.state.mana==maxf(0.0,mana-20.0) and g.state.guard_bind.is_empty() and g.state.reward_count==0,"GUARD capture clears bind, performs one intake milking and enters prison without battle reward: "+str(capture_result)+" phase="+g.state.phase)
 t.check(g.state.items==[retained_seal] and g.state.capture.confiscated==ordinary_tools,"GUARD formal capture preserves seal identity and uses while confiscating ordinary tools")
 var intake_scene=g.state.capture.intake_scene
 t.check(intake_scene.climax.count==1 and intake_scene.climax.mana_lost==20.0 and intake_scene.restraints.size()>=g.state.capture.added.size() and intake_scene.links.size()==g.state.capture.links.size() and intake_scene.toys.size()==g.state.capture.special_added.size(),"GUARD intake page stores one climax and reusable prose for every newly installed restraint, link and sex toy")
 var captured_snapshot=g.export_snapshot()
 var restored_capture=Game.new(77)
 t.check(restored_capture.restore_snapshot(captured_snapshot).ok and restored_capture.state.items==[retained_seal],"GUARD captured snapshot accepts the retained seal")
 var restored_before=restored_capture.export_snapshot()
 var invalid_capture=captured_snapshot.duplicate(true)
 invalid_capture.items.append({"id":"item_%d" % invalid_capture.next_item,"type":"shard","uses":3,"mount":"carry"});invalid_capture.next_item+=1
 t.check(not restored_capture.restore_snapshot(invalid_capture).ok and restored_capture.export_snapshot()==restored_before,"GUARD captured snapshot still rejects unconfiscated ordinary tools atomically")

 var locked=Game.new(107,true,"guard")
 var locked_plate=locked._install_special("negative_plate_lock_catheter_medium","special_2_a",2)
 locked.state.mana=0
 Guard.capture(locked,locked.state.enemies[0])
 intake_scene=locked.state.capture.intake_scene
 t.check(not locked_plate.is_empty() and intake_scene.climax.mana_after==0.0 and intake_scene.climax.flat_lock and intake_scene.climax.low_semen and intake_scene.climax.mana_lost==10.0 and intake_scene.milking.contains("平板锁") and intake_scene.milking.contains("乳房和小穴"),"GUARD intake milking uses the flat-lock low-mana differential and drains the remaining mana once after combat cleanup")

 g=Game.new(9,true,"guard")
 e=g.state.enemies[0]
 g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
 bind(g,e)
 var strain=t.hand_card(g,"strain")
 var candidate=t.find_action(g,"card",{"uid":strain.uid,"target":CaptureBind.BIND_TARGET})
 t.check(not candidate.is_empty() and candidate.valid and candidate.payload.preview.damage==12.0 and candidate.payload.preview.environment_true==0.0,"GUARD bind takes doubled full card damage with no non-head restraint and no wall bonus")
 t.check(t.action(g,"card",{"uid":strain.uid,"target":CaptureBind.BIND_TARGET}).ok and g.state.guard_bind.progress==38.0 and g.state.pressure in [6.0,10.0,15.0],"GUARD paid bind attack also stimulates one random special position with sensitivity")

 g=Game.new(10,true,"guard")
 e=g.state.enemies[0]
 bind(g,e)
 g._install_template("rope","wrist",8,10,false,"fixture")
 strain=t.hand_card(g,"strain")
 candidate=t.find_action(g,"card",{"uid":strain.uid,"target":CaptureBind.BIND_TARGET})
 t.check(candidate.payload.preview.damage==6.0,"GUARD any non-head restraint removes the damage doubling")
 e.stage=4
 CaptureBind.damage_bind(g,50.0,"测试")
 t.check(g.state.guard_bind.is_empty() and not CaptureBind.has_bind(g) and e.intent.kind=="bind_prepare","GUARD zero progress immediately replaces the old cycle intent with preparation")

 g=Game.new(14,true,"guard")
 e=g.state.enemies[0]
 bind(g,e,95.0);e.stage=4;e.intent=Guard.application(Guard.ordinary_templates(),2)
 CaptureBind.gain_bind(g,10.0,"测试推进")
 CaptureBind.observe(g)
 t.check(g.state.guard_bind.progress==100.0 and e.intent.kind=="capture","GUARD reaching full progress replaces the pending cycle with the next capture action")

 g=Game.new(11,true,"guard")
 e=g.state.enemies[0]
 bind(g,e)
 g.state.posture="stand"
 var down=t.find_action(g,"posture",{"dest":"sit","wall":false})
 t.check(not down.valid and down.reason.contains("不能反向切换"),"GUARD bind blocks standing to sitting")
 g.state.posture="lie"
 var up=t.find_action(g,"posture",{"dest":"sit","wall":false})
 var before=g.state.guard_bind.progress
 t.check(up.valid and g.dispatch(g.command(up.payload,g.state.version),g.state.version).ok and g.state.posture=="sit" and g.state.guard_bind.progress==before+10.0,"GUARD bind permits lie to sit and adds ten progress")

 g=Game.new(12,true,"double_guard")
 var first=g.state.enemies[0]
 var second=g.state.enemies[1]
 bind(g,first)
 CaptureBind.apply_bind(g,second)
 t.check(g.state.guard_bind.progress==50.0 and g.state.guard_bind.sources.guard.enemy==first.id,"GUARD bind is nonstacking across two guards")
 first.hp=1;second.hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":first.id}).ok and g.state.phase=="battle","GUARD defeating one of two guards does not end battle")
 t.check(t.action(g,"attack",{"type":"strike","enemy":second.id}).ok and g.state.phase=="reward" and g.state.guard_bind.is_empty(),"GUARD battle victory clears bind and grants one reward")

 g=Game.new(13,true,"guard")
 e=g.state.enemies[0]
 bind(g,e,95.0)
 g.state.pressure=95.0
 g.Pressure.gain(g,10.0,"测试刺激")
 t.check(g.state.guard_bind.progress==100.0 and g.state.overload_count==1 and e.intent.kind=="capture","GUARD each climax adds ten bind progress and schedules capture")
 t.check(g.validate()=="","GUARD new state and cycle remain valid")

static func lower_and_charge(t) -> void:
 for covered in [false,true]:
  var g=Game.new(42,true,"guard")
  g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
  bind(g,g.state.enemies[0],80.0)
  if covered: g._install_template("rope","wrist",8,10,false,"fixture")
  g.state.charge=3;g.state.charge_all=true;g.state.turn_strength=9
  g.Cards.grant_buff(g,"henshin_free")
  var card=t.grant_fixture_card(g,"ease")
  var choice=t.find_action(g,"card",{"uid":card.uid,"target":CaptureBind.BIND_TARGET,"free":false})
  t.check(choice.valid and choice.payload.preview.damage==8.0 and choice.payload.preview.charge==0.0 and choice.payload.preview.multiplier==1.0,"BIND LOWER fixed eight ignores charge, attributes and both damage multipliers")
  t.check(g.Cards.has_escape_target(g,"ease"),"BIND LOWER capture counts as a real bound-face target")
  var before=g.export_snapshot()
  t.check(not g.dispatch(g.command(choice.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==before,"BIND LOWER stale submission leaves all resources and capture unchanged")
  t.check(g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and g.state.guard_bind.progress==72 and g.state.charge==3 and g.state.charge_all,"BIND LOWER committed single step deals eight without consuming any charge")
  t.check(g.state.energy==before.energy-choice.cost and g.state.mana==before.mana-choice.mana_payment.mana,"BIND LOWER formal energy and mana costs are paid once")
 for progress in [8.0,10.0,40.0]:
  var g=Game.new(43,true,"guard")
  g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
  bind(g,g.state.enemies[0],progress);g.state.charge=2
  var card=t.grant_fixture_card(g,"magic_hand")
  var choice=t.find_action(g,"card",{"uid":card.uid,"target":CaptureBind.BIND_TARGET,"free":false})
  t.check(choice.valid,"BIND LOWER body-restricted multi-step lowering can target capture")
  var before=g.export_snapshot()
  var outcome=g.dispatch(g.command(choice.payload,g.state.version),g.state.version)
  t.check(outcome.ok and g.state.card_chain.is_empty() and g.state.play.is_empty(),"BIND LOWER multi-step resolves through the complete card pipeline: "+str(outcome))
  t.check((g.state.guard_bind.is_empty() if progress<=24 else g.state.guard_bind.progress==progress-24) and g.state.charge==2,"BIND LOWER each step deals eight and stops when capture reaches zero")
  var hits=g.state.logs.slice(before.logs.size()).filter(func(row):return row.data.get("guard_bind",{}).get("action","")=="damage")
  t.check(hits.size()==mini(3,ceili(progress/8.0)) and g.state.energy==before.energy-choice.cost,"BIND LOWER uses only required hits and pays once for the whole card")
  t.check(g.validate()=="","BIND LOWER completed or cleared capture leaves a valid state")
 for type in ["strain","slip"]:
  for all_charge in [false,true]:
   var g=Game.new(44,true,"guard")
   g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
   bind(g,g.state.enemies[0],80.0);g.state.charge=2;g.state.charge_all=all_charge
   var card=t.grant_fixture_card(g,type)
   var choice=t.find_action(g,"card",{"uid":card.uid,"target":CaptureBind.BIND_TARGET,"free":false})
   var charge=6.0 if all_charge else 3.0
   t.check(choice.valid and choice.payload.preview.charge==charge and choice.payload.preview.damage==(6.0+charge)*2,"BIND CHARGE ordinary escape keeps normal charge scaling: "+type)
   t.check(g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and g.state.guard_bind.progress==80.0-choice.payload.preview.damage and g.state.charge==(0 if all_charge else 1),"BIND CHARGE ordinary escape consumes the normal number of charge layers: "+type)

static func opening_fallback(t) -> void:
 var R=preload("res://tests/replacement_cases.gd")
 for grade in [1,3]:
  var g=Game.new(42,true,"guard")
  g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
  var original={}
  for slot in ["wrist","mouth","ankle"]:
   original[slot]=R.fill(g,slot,grade,1 if grade==1 else 2)
   t.check(original[slot].all(func(item):return not item.is_empty()),"GUARD full opening-slot fixture is legal")
  var outside=R.install(g,R.request("upper_arm",1,1,"upper_arm_top"))
  var saved_outside=outside.duplicate(true)
  var before=g.export_snapshot()
  g.get_view();g.command_facts()
  var end=t.find_action(g,"end")
  t.check(g.export_snapshot()==before and not g.dispatch(g.command(end.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==before,"GUARD opening preview and stale submission leave all equipment and random state unchanged")
  t.check(t.action(g,"end").ok,"GUARD full-slot opening uses the formal enemy turn")
  for slot in original:
   if grade==1:
    t.check(original[slot].any(func(item):return g._equipment(item.id).is_empty()) and g.equipment_at(slot).any(func(item):return item.grade==2 and g.tier(item.durability,item.maximum)==2),"GUARD opening upgrades weaker full-slot equipment through replacement: "+slot)
   else:
    t.check(original[slot].all(func(item):return not g._equipment(item.id).is_empty()) and original[slot].filter(func(item):return g.tier(g._equipment(item.id).durability,item.maximum)==3).size()==1,"GUARD impossible replacement reinforces exactly one existing piece in its declared slot: "+slot)
  t.check(g._equipment(outside.id)==saved_outside and g.state.enemies[0].intent.kind=="bind_prepare","GUARD scoped fallback leaves other slots unchanged and advances once to preparation")
  var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"guard opening fallback")
  t.check(restored!=null,"GUARD opening fallback remains saveable")
 var g=Game.new(42,true,"guard")
 g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
 var wrists=[]
 for i in range(g._capacity("wrist")):
  var request=R.request("wrist",3,3);request.template="belt"
  var item=R.install(g,request);item.durability=item.maximum*0.9;g._refresh_equipment(item);wrists.append(item)
 for operation in g.state.enemies[0].intent.operations: operation.erase("tighten_missing")
 var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"guard legacy opening")
 t.check(restored!=null,"GUARD older announced opening remains loadable without the new fallback flag")
 if restored!=null: g=restored
 t.check(t.action(g,"end").ok and wrists.filter(func(item):return not g._equipment(item.id).is_empty() and g._equipment(item.id).locked and g._equipment(item.id).durability==item.maximum).size()==1,"GUARD full tier-three opening slot locks once and restores durability, including a restored old opening")
 g=Game.new(42,true,"guard")
 g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
 for slot in ["wrist","mouth","ankle"]: R.fill(g,slot,3,3)
 var outside=R.install(g,R.request("upper_arm",1,1,"upper_arm_top"))
 var before=outside.duplicate(true)
 t.check(t.action(g,"end").ok and g._equipment(outside.id)==before and g.state.enemies[0].intent.kind=="bind_prepare","GUARD fully saturated declared slots never redirect reinforcement to another body part")
