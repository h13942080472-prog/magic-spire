extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Copy=preload("res://core/action_copy.gd")

static func prepare_failure(g) -> void:
 g.state.pressure=73.12345
 var chance=g.cast_view(g.Cards.cast_profile(g,"fireball"))
 for attempt in range(100):
  var index=g.state.rng.magic
  if g._random_index("magic",g.B.CAST_ROLL_STEPS)>=chance.winning_rolls:
   g.state.rng.magic=index
   return

static func run(t) -> void:
 shared_rounds(t)
 var g=Game.new(42)
 prepare_failure(g)
 var card=preload("res://tests/curse_cases.gd").give(g,"ease")
 var target=g.add_fixture("wrist",8.0)
 # Both mouth spells have the same profile. Select a real failure roll for this card.
 var profile=g.cast_view(g.Cards.cast_profile(g,"ease"))
 for attempt in range(100):
  var index=g.state.rng.magic
  if g._random_index("magic",g.B.CAST_ROLL_STEPS)>=profile.winning_rolls:
   g.state.rng.magic=index
   break
 var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id},true)
 var before=g.export_snapshot()
 t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed,"LOG real failed spell commits its cost")
 var text=g.get_view().action_log.map(func(row):return row.text).reduce(func(a,b):return a+"\n"+b,"")
 t.check(text.contains("魔力撑隙") and text.contains("施法失败") and text.contains("卡牌留在手中") and text.contains("成功率%s%%" % Copy.number(profile.chance*100)),"LOG failure names the spell, chance and actual card destination")
 t.check(text.contains("消耗1能量、%s魔力" % Copy.number(c.mana_payment.mana)) and text.find("施法失败")<text.find("消耗") and text.count("消耗")==1,"LOG outcome precedes one accurately rounded payment")
 t.check(not text.contains("未产生法术效果") and not text.contains("不退回") and g.state.hand==before.hand and is_equal_approx(g.state.mana,before.mana-c.mana_payment.mana*0.5) and g.state.equipment==before.equipment,"LOG concise failure preserves half refund, cards and equipment")
 before=g.export_snapshot();g.get_view();g.get_view()
 t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"LOG viewing and stale requests do not add text or change state")

 var raw=[{"round":1,"text":"购买完成。","data":{"player_action":{"mana":10.03625,"temporary_mana":2.500001,"mana_source":"flask","cost":1}}}]
 var raw_before=raw.duplicate(true)
 text=Copy.view(raw).actions[0].text
 t.check(text=="购买完成。\n消耗1能量、2.5临时魔力、10.04魔瓶魔力。" and raw==raw_before,"LOG all payment pools use compact numbers without rounding the source")
 t.check(Copy.number(0)=="0" and Copy.number(12.5)=="12.5" and Copy.number(0.004)=="不足0.01","LOG zero, trailing decimals and tiny nonzero costs remain truthful")

 g=Game.new(42);g.state.wall="rough";g.state.wall_distance=0
 target=g.add_fixture("ankle",40.0,100.0)
 card=preload("res://tests/curse_cases.gd").give(g,"strain")
 c=t.find_action(g,"card",{"uid":card.uid,"target":target.id},true)
 var old=target.durability
 t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"LOG real equipment strike produces calculation and summary")
 var record=g.state.logs.filter(func(row):return row.data.has("action_result"))[0]
 text=g.get_view().action_log.filter(func(row):return row.id==g.state.logs.find(record))[0].text
 t.check(text.contains("点挣扎伤害") and text.contains("耐久%s → %s" % [Copy.number(old),Copy.number(g._equipment(target.id).durability)]) and not text.contains("×") and record.text.contains(g._formula(c.payload.preview)),"LOG sidebar shows actual typed damage while full record retains the exact formula")
 before=g.export_snapshot();var restored=Game.new(7)
 t.check(restored.restore_snapshot(before).ok and restored.get_view().action_log==g.get_view().action_log,"LOG restored history preserves summaries without recomputing old damage")

 g=Game.new(42);g.RelicEffects.gain(g,"ember_crystal")
 t.check(t.action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id}).ok,"LOG real casting guarantee relic triggers")
 var relic_rows=g.get_view().action_log.filter(func(row):return row.actor==g.Relics.TYPES.ember_crystal.name)
 t.check(relic_rows.size()==1 and relic_rows[0].text.contains("必定成功") and not relic_rows[0].text.contains("不再触发"),"LOG relic result uses its own name without repeating its cooldown rule")

 g=Game.new(42);target=preload("res://tests/slip_motion_cases.gd").piece(g,"thigh_root");g.state.wall_distance=2
 t.check(t.action(g,"wall_move",{"direction":"toward"}).ok,"LOG actual movement produces passive equipment results")
 var motion=g.state.logs.filter(func(row):return row.data.has("passive_slip"))
 t.check(not motion.is_empty() and Copy.result(motion[0])==motion[0].data.passive_slip.summary and motion[0].text.length()>Copy.result(motion[0]).length(),"LOG passive movement keeps per-target formulas in the full record")

static func shared_rounds(t) -> void:
 var g=Game.new(42)
 for phase in ["battle","prepare","rest","prison","inspection"]:
  g.state.phase=phase;g.state.round=9;g.state.combat.turn=4;g.state.prison={"turn":7}
  var expected=7 if phase in ["prison","inspection"] else (4 if phase in ["prepare","rest"] else 9)
  g._emit("event","测试行动。",{"player_action":{"cost":1}})
  var saved=g.export_snapshot();var shown=g.View.run_header(g);var log=g.ActionCopy.view(g.state.logs).actions.back()
  t.check(shown.turn=="第%d回合" % expected and log.round==expected and g.state==saved,"ROUND header and recorded action agree without mutating phase clocks: "+phase)
 g=Game.new(42);g.state.round=3;g.state.combat.turn=3
 g._emit("event","战斗行动。",{"player_action":{"cost":1}})
 var past=g.state.logs.duplicate(true)
 g._finish_battle()
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare" and g.display_round()==4,"ROUND preparation continues the session on the next player turn")
 t.check(g.get_view().run_header.turn=="第4回合" and g.get_view().action_log.back().round==4 and g.state.logs.slice(0,past.size())==past,"ROUND preparation entry logs current turn and preserves battle history")
 past=g.state.logs.duplicate(true)
 t.check(t.action(g,"end").ok and g.display_round()==5 and g.get_view().action_log.back().round==5 and g.state.logs.slice(0,past.size())==past,"ROUND next preparation turn advances header and new log only")
 var before=g.export_snapshot()
 t.check(not g.dispatch(g.command({"kind":"card","uid":"missing"},g.state.version),g.state.version).ok and g.state==before,"ROUND rejected action cannot rewrite historical round labels")
 g=Game.new(42);g.state.round=9;g.state.room="rest";g._start_rest()
 t.check(t.action(g,"rest_begin").ok and g.display_round()==1 and g.get_view().action_log.back().round==1,"ROUND rest starts its own turn one instead of retaining battle round nine")
 t.check(t.action(g,"end").ok and g.display_round()==2 and g.get_view().action_log.back().round==2,"ROUND second rest turn advances new log consistently")
