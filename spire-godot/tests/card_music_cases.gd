extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")

static func run(t) -> void:
 practice(t)
 mandarin_duck(t)
 for type in ["henshin","hannya_henshin"]:
  for free in [false,true]:
   var g=Game.new(42);g.state.energy=10
   var card=Give.give(g,type)
   var choice=t.find_action(g,"card",{"uid":card.uid,"free":free})
   var before=g.export_snapshot()
   t.check(not g.dispatch(g.command(choice.payload,g.state.version-1),g.state.version-1).get("music_feedback",[]).size() and g.state==before,"MUSIC stale submission has no cue or mutation")
   var result=g.dispatch(g.command(choice.payload,g.state.version),g.state.version)
   t.check(result.ok and result.music_feedback==[{"track":"rain_love","phase":"battle","loop":true}],"MUSIC both versions and faces emit one committed looping cue: "+type+str(free))
   for face in [1,2]: t.check(g.B.card_info(type)[face].contains("打出时播放dj版雨爱"),"MUSIC both printed faces explain playback")
 for phase in ["prison","rest","prepare"]:
  var g=preload("res://tests/prison_cases.gd").intake(t) if phase=="prison" else Game.new(42,true,"equipment")
  if phase=="prepare":
   g=Game.new(42)
   for enemy in g.state.enemies: enemy.gone=true;enemy.hp=0
   g._finish_battle();t.action(g,"reward",{"type":"skip"})
  g.state.energy=10;g.state.mana=100;g.state.pressure=0
  var result=Give.play(t,g,"henshin",false)
  t.check(result.ok and result.get("music_feedback",[])==([{"track":"rain_love","phase":"prison","loop":false}] if phase=="prison" else []),"MUSIC prison plays once and rest/preparation are silent: "+phase)
 var g=Game.new(42);g.state.energy=10;g.state.pressure=99;g.state.rng.magic=0
 var card=Give.give(g,"henshin")
 var result=t.action(g,"card",{"uid":card.uid,"free":false})
 t.check(result.ok and g.state.hand.any(func(c):return c.uid==card.uid) and result.music_feedback.is_empty(),"MUSIC paid failed cast does not play music")
 g=Game.new(42);g.state.energy=0;card=Give.give(g,"henshin")
 result=t.action(g,"card",{"uid":card.uid,"free":false})
 t.check(not result.ok and result.get("music_feedback",[]).is_empty(),"MUSIC rejected unaffordable card is silent")

static func practice(t) -> void:
 for type in ["henshin","hannya_henshin"]:
  for free in [false,true]:
   var g=Game.new(42,true,"henshin")
   t.check(g.validate()=="" and g.state.phase=="battle" and g.state.enemies.size()==2 and g.state.equipment.size()==2 and g.state.energy==4,"HENSHIN PRACTICE starts valid real battle with targets and enough first-turn energy")
   t.check(g.state.hand.size()==8 and g.state.deck.size()==13 and g.state.hand.slice(5).map(func(c):return c.type)==["henshin","hannya_henshin","hannya_2"],"HENSHIN PRACTICE all music cards drawn into opening hand")
   var card=t.hand_card(g,type);var before=g.export_snapshot()
   var choice=t.find_action(g,"card",{"uid":card.uid,"free":free})
   t.check(choice.valid and g.get_view().practice_options.any(func(row):return row.id=="henshin" and row.node=="Practice_henshin") and g.state==before,"HENSHIN PRACTICE real legal choices and readonly entry: %s %s %s" % [type,str(free),choice.reason])
   var result=g.dispatch(g.command(choice.payload,g.state.version),g.state.version)
   t.check(result.ok and result.music_feedback.size()==1 and g.state.energy==before.energy-choice.cost and g.state.mana==before.mana-choice.mana,"HENSHIN PRACTICE normal costs and committed music")
   t.check((g.state.equipment.is_empty() if not free else "henshin_free" in g.state.card_buffs) and g.state.exhaust.any(func(c):return c.uid==card.uid),"HENSHIN PRACTICE real release/buff and exhaust")
 var normal=Game.new(42)
 t.check(not normal.state.deck.any(func(c):return c.type in ["henshin","hannya_henshin"]),"HENSHIN PRACTICE gifts do not leak into normal runs")

static func mandarin_duck(t) -> void:
 for phase in ["battle","prison","rest","prepare"]:
  for free in [false,true]:
   var g=preload("res://tests/prison_cases.gd").intake(t) if phase=="prison" else Game.new(42)
   if phase=="rest": g=Game.new(42,true,"equipment")
   if phase=="prepare": g._finish_battle();t.action(g,"reward",{"type":"skip"})
   g.state.energy=10;g.state.pressure=0;g.state.posture="sit"
   var card=Give.give(g,"hannya_2")
   var choice=t.find_action(g,"card",{"uid":card.uid,"free":free})
   var before=g.export_snapshot()
   var stale=g.dispatch(g.command(choice.payload,g.state.version-1),g.state.version-1)
   t.check(not stale.ok and stale.get("music_feedback",[]).is_empty() and g.state==before,"DUCK MUSIC stale play is silent and atomic")
   var result=g.dispatch(g.command(choice.payload,g.state.version),g.state.version)
   var expected=[{"track":"mandarin_duck_play","phase":phase,"loop":phase=="battle"}] if phase in ["battle","prison"] else []
   if phase=="rest" and free:
    t.check(not result.ok and result.get("music_feedback",[]).is_empty(),"DUCK MUSIC forbidden rest free effect is silent")
   else:
    t.check(result.ok and result.music_feedback==expected,"DUCK MUSIC formal phase and face: "+phase+str(free))
   t.check(g.B.card_info("hannya_2")[2 if free else 1].contains("打出时自动播放鸳鸯戏") and g.Cards.face_text(g,"hannya_2",free,card.uid).contains("打出时自动播放鸳鸯戏"),"DUCK MUSIC static and dynamic card descriptions agree")
 var g=Game.new(42);g._install_template("mouth_band","mouth",24,24,false,"fixture",3,0)
 var card=Give.give(g,"hannya_2");var before=g.export_snapshot()
 var result=t.action(g,"card",{"uid":card.uid,"free":false})
 t.check(not result.ok and result.get("music_feedback",[]).is_empty() and g.state==before,"DUCK MUSIC blocked drinking cannot start song")
