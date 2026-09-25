extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const IntentView=preload("res://core/intent_view.gd")

static func timing_battle(stage: int, seed_value: int=42, encounter: String="rope_solo"):
 var g=Game.new(seed_value)
 g.state.room_encounters.entrance=encounter
 g._start_battle()
 g.state.enemies[0].stage=stage
 return g

static func timing_cases(t) -> void:
 var Save=preload("res://tests/persistence_cases.gd")
 var chosen={}
 for seed_value in t.seed_values("enemy_cycle"):
  var trial=timing_battle(2,seed_value)
  var actor=trial.state.enemies[0]
  actor.intent=trial._plan(actor)
  var declared=trial.EnemyPlans.installation_intents(trial,actor)
  t.check(actor.intent in declared,"TIMING missing generation target selects an existing application declaration")
  chosen[actor.intent.grade]=true
  var before=trial.state.duplicate(true)
  trial.get_view();trial.command_facts()
  t.check(trial.state==before,"TIMING preview cannot redraw fallback intent or spend randomness")
  t.check(t.action(trial,"end").ok and trial._enemy(actor.id).stage==3,"TIMING replacement action advances the original stage")
  t.check(trial.physical_pieces().size()==1,"TIMING chosen application executes once through the normal factory")
 t.check(chosen.size()==2,"TIMING fallback random samples cover both existing application actions")

 var g=timing_battle(2)
 var e=g.state.enemies[0]
 var piece=g._install_template("rope","wrist",4,10,false,e.id)
 e.intent=g._plan(e)
 t.check(e.intent.kind=="tighten" and not e.intent.has("target"),"TIMING reinforcement publishes no physical target")
 var slip=t.hand_card(g,"slip")
 t.check(t.action(g,"card",{"uid":slip.uid,"slot":piece.slot,"target":piece.id}).ok and g._equipment(piece.id).is_empty(),"TIMING player removes the final target with a formal action")
 var h=Save.roundtrip(t,g,"targetless published reinforcement")
 Save.step_both(t,g,h,"end")
 t.check(g.physical_pieces().is_empty() and g._enemy(e.id).stage==3 and not g._enemy(e.id).gone,"TIMING execution whiffs without application and still advances")
 t.check(g.state.logs.any(func(l):return l.text.contains("这次动作落空")),"TIMING whiff has an actual result message")

 g=timing_battle(2);e=g.state.enemies[0]
 piece=g._install_template("rope","wrist",4,10,false,e.id)
 var other=g._install_template("rope","ankle",4,10,false,e.id)
 e.intent=g._plan(e)
 slip=t.hand_card(g,"slip")
 t.check(t.action(g,"card",{"uid":slip.uid,"slot":piece.slot,"target":piece.id}).ok,"TIMING player removes one of several targets")
 t.check(t.action(g,"end").ok and g._equipment(other.id).durability==8 and g.physical_pieces().size()==1,"TIMING live execution reinforces the remaining target without adding equipment")

 g=timing_battle(2);e=g.state.enemies[0]
 piece=g._install_template("rope","ankle",10,10,false,e.id)
 e.intent=g._plan(e)
 t.check(e.intent.kind=="apply","TIMING maximum equipment without another tightening effect does not count as a legal target")

 for remove_count in [1,2]:
  g=timing_battle(4,42,"rope_heap_solo");e=g.state.enemies[0]
  piece=g._install_template("rope","wrist",4,10,false,e.id)
  other=g._install_template("rope","ankle",4,10,false,e.id)
  e.intent=g._plan(e)
  t.check(e.intent.kind=="equipment_batch" and e.intent.tighten and e.intent.operations.is_empty(),"TIMING batch announces count without frozen targets")
  slip=t.hand_card(g,"slip")
  t.check(t.action(g,"card",{"uid":slip.uid,"slot":piece.slot,"target":piece.id}).ok,"TIMING first batch target removed by player")
  if remove_count==2:
   slip=t.hand_card(g,"slip")
   t.check(t.action(g,"card",{"uid":slip.uid,"slot":other.slot,"target":other.id}).ok,"TIMING second batch target removed by player")
  t.check(t.action(g,"end").ok and g._enemy(e.id).stage==5 and g.physical_pieces().size()==2-remove_count,"TIMING missing batch operations whiff without replacement installation")
  if remove_count==1: t.check(g._equipment(other.id).durability==10,"TIMING remaining batch target still receives its declared tier")

 g=Game.new(42,true,"guard");e=g.state.enemies[0]
 g.state.guard_bind={"progress":50.0,"sources":{"guard":{"enemy":e.id,"energy":0}}};e.stage=4;e.guard.cycle_step=0
 e.intent=g.Guard.build(g,e)
 t.check(e.intent.kind=="apply" and not e.intent.has("target") and e.intent.count==2,"TIMING guard publishes scope while choosing actual application targets only on execution")

static func run(t) -> void:
 timing_cases(t)
 var completed=[];IntentView.operation(completed,{})
 var idle=[];IntentView.operation(idle,{"kind":"idle"})
 t.check(completed[0].detail=="敌人本回合已行动，下一回合重新显示意图" and idle[0].detail=="敌人暂不行动","INTENT completed enemy turn and actual idle have distinct explanations")
 var newborn=timing_battle(1)
 var child=newborn.state.enemies[0];child.spawned_round=newborn.state.round;child.intent={"kind":"charge"}
 t.check(IntentView.build(newborn,child,true)[0].detail!=completed[0].detail,"INTENT newly spawned enemy is not falsely described as having acted")
 var interrupted=Game.new(42)
 interrupted.state.equipment.clear()
 var actor=interrupted.state.enemies[0];var original=actor.intent.duplicate(true)
 var original_icons=IntentView.build(interrupted,actor,true)
 interrupted.state.round=2
 interrupted.state.card_buffs.append("infusion_bound")
 t.check(t.action(interrupted,"attack",{"type":"kick","form":2,"enemy":actor.id}).ok,"INTENT infused kick interrupts published action")
 actor=interrupted._enemy(actor.id)
 var frozen=interrupted.export_snapshot()
 var shown=IntentView.build(interrupted,actor,true)
 t.check(shown.size()==1 and shown[0].kind=="delayed" and interrupted.export_snapshot()==frozen,"INTENT interrupted action exposes only interrupt marker without changing frozen plan")
 t.check(IntentView.build(interrupted,actor,false).map(func(icon):return icon.kind)==["hidden"],"INTENT blindness remains authoritative for interrupted enemies")
 t.check(t.action(interrupted,"end").ok and IntentView.build(interrupted,interrupted._enemy(actor.id),true)==original_icons and interrupted._enemy(actor.id).intent==original,"INTENT skipped turn restores unchanged original intent")
 var composite=[]
 IntentView.operation(composite,{"kind":"guard_sequence","operations":[{"kind":"apply"},{"kind":"debuff"}],"tighten_after":true,"pressure":7,"delayed":true})
 t.check(composite.map(func(icon):return icon.kind)==["delayed"],"INTENT interruption replaces all combined action and auxiliary icons")
 for term in IntentView.ICON_TYPES:
  var projected=[]
  IntentView.operation(projected,{"kind":term,"text":"PRIVATE_DETAIL","target":"PRIVATE_TARGET"})
  t.check(projected.size()==1 and projected[0].label=="" and not projected[0].detail.contains("\n") and not JSON.stringify(projected).contains("PRIVATE_"),"INTENT direct plan projection has one public sentence: "+term)
 var grouped=[]
 IntentView.operation(grouped,{"kind":"guard_sequence","operations":[{"kind":"charge"},{"kind":"pause"},{"kind":"idle"}]})
 t.check(grouped.size()==1 and grouped[0].kind=="wait","INTENT stationary actions share one icon")
 grouped=[]
 IntentView.operation(grouped,{"kind":"equipment_batch","tighten":false,"operations":[]})
 t.check(grouped.size()==1 and grouped[0].kind=="bind","INTENT equipment forms share one icon")
 var g=Game.new(42,true,"guard")
 var before=g.export_snapshot()
 var e=g.state.enemies[0]
 var rows=g.get_view().enemies[0].intent_icons
 t.check(rows.any(func(r):return r.kind=="bind") and not rows.any(func(r):return r.kind=="deadline") and g.export_snapshot()==before,"INTENT guard opening shows its actual application without the removed deadline")
 g.add_fixture("eyes",4)
 var hidden=g.get_view().enemies[0].intent_icons
 e.intent={"kind":"capture","text":"执行收押","delayed":false}
 t.check(hidden.size()==1 and hidden[0].kind=="hidden" and g.get_view().enemies[0].intent_icons==hidden,"INTENT blindness hides changed capture plan")
 e.gone=true
 t.check(g.get_view().enemies[0].intent_icons.is_empty(),"INTENT departed enemy has no icons")
 # Debuff intent is a generic cue; no amount, duration or raw preview leaks.
 g=Game.new(42)
 e=g.state.enemies[0]
 e.intent.pressure=7
 e.intent.text="PRIVATE_DEBUFF_DETAIL"
 before=g.export_snapshot()
 var view=g.get_view().enemies[0]
 var debuffs=view.intent_icons.filter(func(r):return r.kind=="debuff")
 t.check(debuffs.size()==1 and debuffs[0].detail==IntentView.DEBUFF_MESSAGE and debuffs[0].caption=="","INTENT debuff uses one generic message")
 t.check(not JSON.stringify(view).contains("PRIVATE_DEBUFF_DETAIL") and g.state==before,"INTENT generic preview does not leak or mutate plan")
 g=Game.new(42,true,"guard")
 g.state.enemies[0].intent.operations[0].pressure=7
 t.check(g.get_view().enemies[0].intent_icons.filter(func(r):return r.kind=="debuff").size()==1,"INTENT nested action projects one debuff icon")
 g.add_fixture("eyes",4)
 t.check(g.get_view().enemies[0].intent_icons.all(func(r):return r.kind=="hidden"),"INTENT blindness hides generic debuff cue too")
 for encounter in ["rope_heap_solo","belt_heap_solo"]:
  g=Game.new(42,true,encounter)
  before=g.export_snapshot()
  view=g.get_view().enemies[0]
  t.check(view.intent_icons.filter(func(r):return r.kind=="debuff" and r.detail==IntentView.DEBUFF_MESSAGE).size()==1 and not JSON.stringify(view).contains("增生"),"INTENT heap persistent debuff has generic preview")
  t.check(g.state==before and g.get_view().statuses.filter(func(s):return s.id.begins_with("turn_install_")).is_empty(),"INTENT heap preview does not apply status")
  t.action(g,"end")
  t.check(g.get_view().statuses.any(func(s):return s.id.begins_with("turn_install_") and s.detail.contains("初级2档")),"INTENT applied heap debuff keeps detailed status")

