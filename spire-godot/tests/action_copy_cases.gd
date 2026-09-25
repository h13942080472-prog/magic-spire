extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Events=preload("res://tests/event_cases.gd")

static func run(t) -> void:
 preload("res://tests/action_log_cases.gd").run(t)
 var g=Game.new(42)
 t.check(g.get_view().speech.is_empty() and g.get_view().action_log.is_empty(),"COPY no invented opening actions or speech")
 var before=g.export_snapshot()
 t.check(not g.dispatch(g.command({"kind":"card","uid":"missing"},g.state.version),g.state.version).ok and g.export_snapshot()==before,"COPY rejected command leaves all text and mechanics unchanged")
 t.check(t.action(g,"attack",{"type":"strike","enemy":"enemy_1"}).ok and g.get_view().speech.cue=="hero.attack.upper.low.clear","COPY actual player action selects paid action and pleasure speech")
 var player_log=g.get_view().action_log
 t.check(player_log.size()==1 and player_log[0].actor=="魔法少女" and player_log[0].text.contains("造成") and player_log[0].text.contains("消耗1能量"),"COPY player attack records actual damage and paid resource once")
 var log_ids=player_log.map(func(row):return row.id)
 t.check(not g.dispatch(g.command({"kind":"card","uid":"missing"},g.state.version),g.state.version).ok and g.get_view().action_log.map(func(row):return row.id)==log_ids,"COPY rejected click adds no action row")
 before=g.export_snapshot()
 var speech=g.get_view().speech
 g.get_view();g.get_view()
 t.check(g.export_snapshot()==before and g.get_view().speech==speech,"COPY repeated rendering does not replay or draw random")
 t.check(t.action(g,"end").ok and not g.get_view().action_log.is_empty(),"COPY enemy phase records real completed operations")
 var mixed=g.get_view().action_log
 for i in range(1,mixed.size()): t.check(mixed[i].id>mixed[i-1].id,"COPY player/enemy/round results keep chronology without duplicates")
 var saved=g.export_snapshot();var restored=Game.new(0,false,"equipment",false)
 t.check(restored.restore_snapshot(saved).ok and restored.get_view().action_log==g.get_view().action_log and restored.get_view().speech==g.get_view().speech,"COPY restore preserves messages without triggering actions")
 g.add_fixture("mouth",4)
 var spoken_count=g.state.logs.filter(func(log):return log.data.has("hero_copy")).size()
 t.check(t.action(g,"end").ok and g.state.logs.filter(func(log):return log.data.has("hero_copy")).size()==spoken_count,"COPY zero-cost end action does not restore removed legacy dialogue")
 g.add_fixture("eyes",4)
 var enemy=g.state.enemies.filter(func(e):return not e.gone)[0]
 g._enemy_operation(enemy,{"kind":"charge","text":"准备下一次附着。","delayed":false})
 var hidden=g.get_view().action_log.back()
 t.check(hidden.cue=="enemy.unseen" and not hidden.text.contains("蓄力"),"COPY unseen preparation does not leak through custom copy cue")
 g=Game.new(42);Events.arrive(g,"binding_cleric")
 t.check(t.action(g,"event",{"action":"choose","choice":"leave_free"}).ok and g.get_view().action_log.back().cue=="event.binding_cleric.choose","COPY event result enters same sidebar stream")
 var copy=g.ActionCopy.texts.duplicate(true);before=g.export_snapshot()
 g.ActionCopy.texts["event.binding_cleric.choose"]="另一套测试描述。"
 t.check(g.get_view().action_log.back().text=="另一套测试描述。" and g.export_snapshot()==before,"COPY text replacement changes no gameplay or event records")
 g.ActionCopy.texts=copy
 t.check(g.ActionCopy.line("future.unknown",{"result":"原行动说明。"})=="原行动说明。","COPY unknown action has readable factual fallback")
 var clear_low={"cost":1,"pressure_before":0.0,"pressure_after":0.0,"mouth_before":"clear","mouth_after":"clear","uses_magic":false,"spell_failed":false}
 t.check(g.ActionCopy.hero_cue({"kind":"posture"},clear_low)=="hero.posture.low.clear","COPY posture uses actual command kind")
 g=Game.new(42)
 var target=g.add_fixture("eyes",4)
 t.check(t.action(g,"manual",{"target":target.id}).ok,"COPY real quick removal")
 t.check(g.get_view().action_log.any(func(row):return row.text.contains("剩余耐久0")) and g.get_view().action_log.any(func(row):return row.text.contains("已解除")),"COPY removal includes progress and resulting release")
 paid_dialogue_matrix(t)

static func paid_dialogue_matrix(t) -> void:
 var g=Game.new(42)
 var groups=["card.setup","card.magic","card.magic_failed","card.strain","card.slip","attack.upper","attack.kick","attack.fireball","attack.fireball_failed","move","posture","manual","toy.vaginal","toy.anal","item.install","calm","prison.vent"]
 var missing=[]
 g.ActionCopy.line("hero.default",{},true)
 for group in groups:
  for stage in ["low","mid","high"]:
   for voice in ["clear","partial"]:
    var cue="hero.%s.%s.%s" % [group,stage,voice]
    if not g.ActionCopy.texts.has(cue) or str(g.ActionCopy.texts[cue]).strip_edges()=="": missing.append(cue)
 t.check(missing.is_empty(),"COPY every paid action, pleasure and partial-mouth cue has authored dialogue: "+str(missing))

 var contexts=[
  [{"kind":"card","mode":"self","self_target":true,"free":false},false,false,"hero.card.setup.low.clear"],
  [{"kind":"card","mode":"self","self_target":true,"free":false},true,false,"hero.card.magic.low.clear"],
  [{"kind":"card","mode":"self","self_target":true,"free":false},true,true,"hero.card.magic_failed.low.clear"],
  [{"kind":"card","mode":"strain","free":false},false,false,"hero.card.strain.low.clear"],
  [{"kind":"card","mode":"slip","free":false},false,false,"hero.card.slip.low.clear"],
  [{"kind":"attack","type":"kick"},false,false,"hero.attack.kick.low.clear"],
  [{"kind":"attack","type":"fireball"},true,true,"hero.attack.fireball_failed.low.clear"],
  [{"kind":"prison","action":"explore"},false,false,"hero.move.low.clear"],
  [{"kind":"prison","action":"vent_kick"},false,false,"hero.prison.vent.low.clear"],
  [{"kind":"item_install"},false,false,"hero.item.install.low.clear"]
 ]
 for row in contexts:
  var context={"cost":1,"pressure_before":0.0,"pressure_after":0.0,"mouth_before":"clear","mouth_after":"clear","uses_magic":row[1],"spell_failed":row[2]}
  t.check(g.ActionCopy.hero_cue(row[0],context)==row[3],"COPY structured action selects "+row[3])
 var toy_context={"cost":1,"pressure_before":40.0,"pressure_after":40.0,"mouth_before":"clear","mouth_after":"clear","manual_family":"anal_egg"}
 t.check(g.ActionCopy.hero_cue({"kind":"manual"},toy_context)=="hero.toy.anal.mid.clear","COPY manual toy removal uses the actual occupied channel")

 var partial_game=Game.new(42)
 partial_game._install_template("mouth_band","mouth",4,10,false,"fixture",1,0)
 t.check(g.ActionCopy.mouth_mode(partial_game.equipment_at("mouth"))=="partial","COPY ordinary ball gag uses fragmented speech")
 var tape_game=Game.new(42)
 tape_game._install_template("mouth_tape","mouth",4,10,false,"fixture",1,0)
 t.check(g.ActionCopy.mouth_mode(tape_game.equipment_at("mouth"))=="full","COPY taped mouth uses shared complete-gag voice")
 var insert_game=Game.new(42)
 insert_game._install_template("mouth_band","mouth",8,16,false,"fixture",2,0,1)
 t.check(g.ActionCopy.mouth_mode(insert_game.equipment_at("mouth"))=="full","COPY insert gag uses shared complete-gag voice")
 var full_context={"pressure_before":80.0,"pressure_after":80.0,"mouth_before":"full","mouth_after":"full","uses_magic":true,"spell_failed":true}
 t.check(g.ActionCopy.hero_cue({"kind":"card","mode":"self","self_target":true},full_context)=="hero.muffled","COPY every fully gagged action shares one nonverbal cue")
 t.check(g.ActionCopy.hero_cue({"kind":"end"},{"cost":0,"mouth_before":"full","mouth_after":"full"})=="" and g.ActionCopy.line("hero.default",{},true)=="","COPY removed legacy cues neither regenerate nor fall back to placeholder speech")
 var climax_normal={"climax_count":1,"climax_turn_count":1,"mana_before":100.0,"mouth_before":"clear","mouth_after":"clear"}
 var climax_repeat={"climax_count":1,"climax_turn_count":2,"mana_before":80.0,"mouth_before":"partial","mouth_after":"partial"}
 var climax_low={"climax_count":1,"climax_turn_count":1,"mana_before":15.0,"mouth_before":"full","mouth_after":"full"}
 t.check(g.ActionCopy.climax_cues(climax_normal)=={"dialogue":"hero.climax.normal.clear","narration":"climax.narration.normal"},"COPY first climax selects normal spoken and second-person narration cues")
 t.check(g.ActionCopy.climax_cues(climax_repeat)=={"dialogue":"hero.climax.repeated.partial","narration":"climax.narration.repeated"},"COPY repeated climax keeps the partial-gag difference")
 t.check(g.ActionCopy.climax_cues(climax_low)=={"dialogue":"hero.climax.full","narration":"climax.narration.low"},"COPY low-mana climax uses the shared fully gagged voice and low-output narration")
 for cue in ["climax.narration.normal","climax.narration.repeated","climax.narration.low"]:
  var prose=g.ActionCopy.line(cue,{},true)
  t.check(prose.begins_with("你的") and not prose.contains("她的"),"COPY climax narration is second person: "+cue)
 var npc_logs=[{"kind":"event","text":"巡视完成。","round":1,"phase":"inspection","data":{"npc_copy":{"cue":"prison.guard.milk.normal","visual":"guard_purple"}}}]
 var npc_view=g.ActionCopy.view(npc_logs)
 t.check(npc_view.npc_speech.cue=="prison.guard.milk.normal" and npc_view.npc_speech.visual=="guard_purple" and npc_view.npc_speech.phase=="inspection" and not npc_view.npc_speech.has("name"),"COPY guard dialogue keeps cue, portrait and phase without a displayed name")

 var failure_seed=-1
 for seed_value in range(8):
  var probe=Game.new(seed_value);probe.state.pressure=75
  if probe._random_index("magic",probe.B.CAST_ROLL_STEPS)>=probe.cast_view().winning_rolls:
   failure_seed=seed_value
   break
 t.check(failure_seed>=0,"COPY deterministic spell-failure fixture exists")
 var failed=Game.new(failure_seed);failed.state.pressure=75
 var restraint=failed.add_fixture("wrist",8)
 var spell=t.hand_card(failed,"ease")
 t.check(t.action(failed,"card",{"uid":spell.uid,"target":restraint.id}).ok and failed._magic_failed and failed.get_view().speech.cue=="hero.card.magic_failed.high.clear","COPY failed card spell uses committed failure dialogue")
 failed=Game.new(failure_seed);failed.state.pressure=75
 t.check(t.action(failed,"attack",{"type":"fireball","enemy":failed.state.enemies[0].id}).ok and failed._magic_failed and failed.get_view().speech.cue=="hero.attack.fireball_failed.high.clear","COPY failed fixed spell uses committed failure dialogue")

 var partial=Game.new(42);partial.state.pressure=45
 partial._install_template("mouth_band","mouth",4,10,false,"fixture",1,0)
 t.check(t.action(partial,"attack",{"type":"strike","enemy":partial.state.enemies[0].id}).ok and partial.get_view().speech.cue=="hero.attack.upper.mid.partial","COPY real paid action combines current pleasure and partial gag")
