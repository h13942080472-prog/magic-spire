extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Receipt=preload("res://core/resource_feedback.gd")
const CUE="rope_leather_tension"

class RejectCommit extends Game:
 var reject=false
 func validate() -> String:
  return "audio rollback probe" if reject else super.validate()

static func recording(g):
 g._resource_feedback=Receipt.new()
 return g._resource_feedback

static func audible_enemies(g) -> void:
 # Explicit fixture: both actors install audible materials, two pieces per step.
 for enemy in g.state.enemies: enemy.intent=g.EnemyPlans.application(["rope"],1,1,2)

static func run(t) -> void:
 for entry in [["rope","ankle",true],["belt","ankle",true],["mouth_band","mouth",true],["tape","ankle",false],["cable_tie","ankle",false],["eye_cloth","eyes",false],["ankle_cuffs","ankle",false]]:
  var g=Game.new(42);var receipt=recording(g)
  var piece=g._install_template(entry[0],entry[1],8,10,false,"fixture")
  t.check(not piece.is_empty() and receipt.sounds.has(CUE)==entry[2],"AUDIO installation follows physical material: "+entry[0])
  receipt.sounds.clear()
  g._apply_equipment_damage(piece,0,"strain",true)
  t.check(receipt.sounds.is_empty(),"AUDIO zero damage is silent: "+entry[0])
  g._apply_equipment_damage(piece,1,"strain",true)
  t.check(receipt.sounds.has(CUE)==entry[2],"AUDIO passive damage follows physical material: "+entry[0])
  receipt.sounds.clear()
  g._apply_equipment_damage(piece,9999,"cut",true)
  t.check(receipt.sounds.has(CUE)==entry[2],"AUDIO destruction retains the material before cleanup: "+entry[0])
 var g=Game.new(42);var receipt=recording(g)
 var crotch=g._install_special("crotch_rope_low","special_3_a")
 t.check(not crotch.is_empty() and receipt.sounds.has(CUE),"AUDIO special crotch rope uses its actual rope material")
 receipt.sounds.clear();g._apply_equipment_damage(crotch,1,"strain",true)
 t.check(receipt.sounds.has(CUE),"AUDIO special crotch rope damage is audible")
 var wrist=g.add_fixture("wrist",4);receipt.sounds.clear()
 var link=g._install_link(crotch.id,wrist.id,4.8,"fixture")
 t.check(not link.is_empty() and receipt.sounds.has(CUE),"AUDIO link installation includes crotch connectors")
 receipt.sounds.clear();g._apply_equipment_damage(link,1,"strain",true)
 t.check(receipt.sounds.has(CUE),"AUDIO links use the shared damage receipt")
 g=Game.new(42);receipt=recording(g)
 var root=g._install_assembly("leg","upper","fixture",2,2)
 t.check(not root.is_empty() and receipt.sounds.keys()==[CUE],"AUDIO multi-component leather assembly collapses into one cue")
 receipt.sounds.clear();g._apply_equipment_damage(root.components[0],1,"cut",true)
 t.check(receipt.sounds.has(CUE),"AUDIO composite component damage is audible")
 g=Game.new(42);var host=g._install_template("rope","upper_arm",4,10,false,"fixture")
 receipt=recording(g)
 t.check(g.Shoulders.install(g,host,"belt",2,"fixture") and receipt.sounds.keys()==[CUE],"AUDIO newly attached leather shoulder pair produces one cue")
 receipt.sounds.clear();g.Shoulders.fill(g,host)
 t.check(receipt.sounds.is_empty(),"AUDIO refreshing existing shoulder pieces is silent")
 g=Game.new(42);receipt=recording(g)
 var before=g.export_snapshot()
 g._prepare_assembly("leg","upper","fixture",2,2)
 g.Application.can_apply(g,{"pool":"ordinary","templates":["rope"],"grade":1,"tier":2,"count":1},"fixture")
 t.check(receipt.sounds.is_empty() and g.export_snapshot()==before,"AUDIO planning never emits a cue or changes state")
 var piece=g.add_fixture("ankle",4);receipt.sounds.clear()
 g._apply_manual_release(piece,0)
 t.check(receipt.sounds.is_empty(),"AUDIO direct removal without damage does not masquerade as a hit")
 committed(t)

static func committed(t) -> void:
 var g=Game.new(42)
 var piece=g.add_fixture("ankle",8)
 var card=t.hand_card(g,"strain")
 var chosen=t.find_action(g,"card",{"uid":card.uid,"target":piece.id,"free":false},true)
 var before=g.export_snapshot()
 g.get_view();g.command_facts()
 t.check(g.export_snapshot()==before and g._resource_feedback==null,"AUDIO ordinary previews create no live sound receipt")
 t.check(chosen.valid,"AUDIO real damage candidate is usable")
 if not chosen.valid: return
 var result=g.dispatch(g.command(chosen.payload,g.state.version),g.state.version)
 t.check(result.ok and result.get("sound_feedback",[]).has(CUE),"AUDIO successful card damage exposes the committed material cue")
 var stale=g.dispatch(g.command(chosen.payload,0),0)
 t.check(not stale.ok and not stale.has("sound_feedback"),"AUDIO stale rejected action exposes no sound cue")
 var failed=RejectCommit.new(42)
 piece=failed.add_fixture("ankle",8);card=t.hand_card(failed,"strain")
 chosen=t.find_action(failed,"card",{"uid":card.uid,"target":piece.id,"free":false},true)
 before=failed.export_snapshot();failed.reject=true
 result=failed.dispatch(failed.command(chosen.payload,failed.state.version),failed.state.version)
 t.check(not result.ok and not result.has("sound_feedback") and failed._resource_feedback==null and failed.export_snapshot()==before,"AUDIO validation rollback discards payment, damage and pending sound")
 g=Game.new(42)
 audible_enemies(g)
 result=t.action(g,"end")
 var scoped=result.get("sound_feedback",[]).filter(func(cue):return cue is Dictionary)
 t.check(result.ok and scoped.size()>=2 and not result.sound_feedback.has(CUE),"AUDIO multiple enemy installations retain separate scoped receipts without an immediate duplicate")
 t.check(scoped[0].enemy_id!=scoped[-1].enemy_id and scoped.all(func(cue):return cue.cue==CUE and g.state.logs.any(func(log):return log.data.get("enemy_action",{}).get("enemy_id","")==cue.enemy_id and log.data.enemy_action.sequence==cue.sequence and log.data.enemy_action.kind==cue.kind)),"AUDIO scoped cues identify committed enemy instances and operations")
 g=Game.new(42);var silent_enemy=g.state.enemies[0].id
 g.state.enemies[0].intent.delayed=true
 result=t.action(g,"end")
 t.check(result.ok and not result.sound_feedback.any(func(cue):return cue is Dictionary and cue.enemy_id==silent_enemy),"AUDIO interrupted enemy contributes no material cue")
 failed=RejectCommit.new(42);before=failed.export_snapshot();failed.reject=true
 result=t.action(failed,"end")
 t.check(not result.ok and not result.has("sound_feedback") and failed._resource_feedback==null and failed.export_snapshot()==before,"AUDIO enemy-phase rollback discards every scoped receipt")
 var receipt=Receipt.new()
 var context={"enemy_id":"same_enemy","sequence":10,"cue":"enemy.apply"}
 for i in range(3): receipt.equipment({"material":"rope"},1,true,true,context)
 context.sequence=12;receipt.equipment({"material":"leather"},1,true,true,context)
 receipt.equipment({"material":"rope"},1)
 t.check(receipt.sound_events().size()==3 and receipt.sounds.keys()==[CUE],"AUDIO one operation coalesces its pieces while the next operation and player damage remain independent")
