extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Bind=preload("res://core/capture_bind.gd")
const Save=preload("res://tests/persistence_cases.gd")
const ReplacementCases=preload("res://tests/replacement_cases.gd")

static func run(t) -> void:
 var g=Game.new(42,true,"binding_box_solo")
 var e=g.state.enemies[0]
 t.check(g.state.enemies.size()==1 and e.type=="binding_box" and e.hp==64 and e.carried_indices==[0,1,2] and e.intent.kind=="bind_apply","BOX practice starts with one mechanical enemy and three carried pieces")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==40 and g.state.posture=="sit" and g.level("arms")>=1,"BOX opening adds forty and fixes sitting without the first upkeep gain")
 t.check(g.state.equipment.is_empty(),"BOX newly applied capture skips the first upkeep installation")
 t.check(not t.find_action(g,"posture",{"dest":"stand","wall":false}).valid,"BOX fixed sitting blocks standing")
 t.check(t.action(g,"end").ok and g._enemy(e.id).intent.kind=="charge" and g.state.guard_bind.progress==50,"BOX first cycle action advances to preparation and triggers one passive")
 t.check(g.state.equipment.size()==3 and (g.Equipment.is_shackle(g.state.equipment[-1]) and preload("res://core/equipment_replacement.gd").replacement_value(g,g.state.equipment[-1])==4 or g.state.equipment[-1].grade+g.equipment_tier(g.state.equipment[-1])==4 and g.state.equipment[-1].material=="leather"),"BOX following upkeep installs value-four leather or the permitted fixed-value shackle after two cycle pieces")
 t.check(t.action(g,"end").ok and g._enemy(e.id).intent.kind=="carried_apply" and g._enemy(e.id).carried_indices.size()==3,"BOX preparation preserves stock and announces composite installation")
 var h=Save.roundtrip(t,g,"box prepared stock and sitting capture")
 Save.step_both(t,g,h,"end")
 e=g._enemy(e.id)
 t.check(e.carried_indices.size()==2 and g.state.composites.size()==1 and g.state.guard_bind.progress==70,"BOX successful announced installation consumes exactly one stock entry")
 var clean=g.export_snapshot()
 var bad=clean.duplicate(true);bad.enemies[0].carried_indices=[0,0]
 t.check(not g.restore_snapshot(bad).ok and g.state==clean,"BOX duplicate stock rejected atomically on restore")
 Bind.damage_bind(g,100,"测试")
 t.check(g._enemy(e.id).intent.kind=="bind_prepare","BOX escaped capture requires a preparation turn")
 t.check(t.action(g,"end").ok and not Bind.has_bind(g) and g._enemy(e.id).carried_indices.size()==2,"BOX preparation neither ticks absent capture nor restores stock")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==40 and g._enemy(e.id).carried_indices.size()==2,"BOX recapture retains consumed stock and skips its first upkeep again")

 # All three inventory pieces are selected through the same legal replacement path.
 g=Game.new(21,true,"binding_box_solo");e=g.state.enemies[0]
 Bind.apply_bind(g,e);e.stage=4;e.guard.cycle_step=2
 var seen={}
 for seed_value in t.seed_values("enemy_cycle"):
  g.state.rng.enemy=seed_value
  var choice=g.EnemyPlans.carried_application(g,e)
  if not choice.is_empty(): seen[choice.carried_index]=true
 if t.exhaustive: t.check(seen.size()==3,"BOX each legal carried piece can be selected first")
 for count in range(3):
  var plan=g.EnemyPlans.carried_application(g,e)
  t.check(not plan.is_empty(),"BOX remaining stock has a legal actual equipment target")
  if plan.is_empty(): break
  g._enemy_operation(e,plan)
 t.check(e.carried_indices.is_empty() and g.state.composites.size()==3 and g.state.composites.all(func(root):return root.components.all(func(piece):return piece.grade==2 and g.tier(piece.durability,piece.maximum)==2)),"BOX three medium tier-two pieces are consumed once each")
 t.check(g.EnemyPlans.build(g,e).kind=="bind_gain","BOX exhausted inventory changes its final cycle action to capture gain")

 g=Game.new(27,true,"binding_box_solo");e=g.state.enemies[0]
 e.carried_indices=[2]
 for point in ["upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist"]:
  ReplacementCases.fill(g,point)
 var count=g.state.equipment.size()
 var plan=g.EnemyPlans.carried_application(g,e)
 var spec=g.EnemyPlans.application_spec(g,e,plan)
 var ordinary=g.EnemyPlans.application_spec(g,e,g.EnemyPlans.application(["belt"],2,2))
 var forbidden=spec.duplicate(true);forbidden.replace=false
 t.check(spec.replace and not ordinary.replace and not g.Application.can_apply(g,forbidden,e.id),"BOX composite can replace full coverage while ordinary mechanical applications receive no replacement permission")
 g._enemy_operation(e,plan)
 t.check(g.state.equipment.size()<count and g.state.composites.size()==1 and e.carried_indices.is_empty(),"BOX composite replaces weaker outer equipment using the real replacement transaction")

 g=Game.new(28,true,"binding_box_solo");e=g.state.enemies[0];e.carried_indices=[2]
 for point in ["upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist"]:
  ReplacementCases.fill(g,point,3,3)
 var before=g.state.equipment.duplicate(true)
 g._enemy_operation(e,{"kind":"carried_apply","text":"施加备用装备","delayed":false})
 t.check(e.carried_indices==[2] and g.state.equipment==before and g.state.composites.is_empty(),"BOX blocked replacement leaves both stock and existing equipment intact")

 g=Game.new(29,true,"binding_box_solo");e=g.state.enemies[0]
 Bind.apply_bind(g,e);e.stage=4
 t.check(g.EnemyPlans.build(g,e).kind=="apply","BOX no leather reinforcement target selects installation")
 var pieces=[]
 for slot in ["wrist","ankle"]: pieces.append(g._install_template("belt",slot,4,10,false,"fixture"))
 var rope=g._install_template("rope","thigh",4,10,false,"fixture")
 var rope_before=rope.duplicate(true)
 g._enemy_operation(e,{"kind":"tighten_budget","budget":4,"text":"加固皮革","delayed":false})
 t.check(pieces.all(func(piece):return g.tier(piece.durability,piece.maximum)==3) and rope==rope_before,"BOX four tightening tiers affect only leather and stop at tier three")
 var guard=g._append_enemies([{"type":"guard","grade":2}])[0]
 Bind.apply_bind(g,guard)
 t.check(g.state.guard_bind.progress==65 and g.state.posture=="sit","BOX fixed sitting overrides guard posture route and new guard contributes twenty-five")
 e.hp=0;g._defeat_enemy(e)
 var progress=g.state.guard_bind.progress;count=g.physical_pieces().size()
 Bind.turn_start(g)
 t.check(not Bind.has_bind(g,"binding_box") and Bind.has_bind(g,"guard") and g.state.guard_bind.progress==progress and g.physical_pieces().size()==count,"BOX defeat stops only its source and its turn-start passive")
 first_enemy_turn(t)

static func first_enemy_turn(t) -> void:
 var g=Game.new(33,true,"binding_box_solo")
 g.state.relics.append("masochist_mark")
 g._start_battle()
 t.check(g.state.order=="last" and g.state.guard_bind.progress==40 and g.state.equipment.is_empty(),"BOX enemy-first opening has forty capture and no same-round upkeep")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==50 and not g.state.equipment.is_empty(),"BOX enemy-first next round resumes upkeep without an extra skipped turn")
 Bind.damage_bind(g,100,"测试重新捕缚")
 t.check(t.action(g,"end").ok and not Bind.has_bind(g),"BOX enemy-first escape prepares a fresh capture")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==40,"BOX enemy-first reapplication retains its initial progress")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==50,"BOX enemy-first reapplication resumes upkeep on the next round")
