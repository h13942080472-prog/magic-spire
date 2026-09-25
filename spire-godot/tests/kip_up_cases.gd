extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Basic=preload("res://tests/basic_attack_cases.gd")

static func fresh():
 var g=Game.new(42);g._discard_end();g.state.energy=30
 return g

static func run(t) -> void:
 capture_priority(t)
 var g=fresh()
 t.check("kip_up" in g.Cards.Rules.COMMON and g.Cards.Rules.SPECS.kip_up.rarity=="common" and g.B.CARD_TRAITS.kip_up.retain,"KIP common retained skill is in the reward pool")
 var card=Cards.give(g,"kip_up")
 for strength in [0,3,4,5]:
  g.state.strength=strength;g.state.posture="lie"
  for free in [false,true]:
   var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
   t.check(c.valid and c.cost==(0 if strength>=4 else 1),"KIP both faces use the live four-strength threshold: "+str(strength))
 g.state.strength=3;g.state.turn_strength=1
 t.check(t.find_action(g,"card",{"uid":card.uid,"free":false}).cost==0,"KIP temporary strength contributes to discount")
 g.state.turn_strength=0;g.state.relics.append("martial_book")
 t.check(g.Cards.energy_cost(g,"kip_up")==0,"KIP relic strength contributes to discount")
 g.state.relics.erase("martial_book")
 g._discard_end()
 t.check(g.state.hand.any(func(c):return c.uid==card.uid),"KIP inherent retain survives normal end-of-turn discard")
 g=fresh();card=Cards.give(g,"kip_up")
 for pose in ["stand","sit"]:
  g.state.posture=pose
  var before=g.export_snapshot()
  t.check(not t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state==before,"KIP bound face rejects non-lying pose atomically: "+pose)
 g.state.posture="lie";g.state.strength=4;g.state.energy=0
 var c=t.find_action(g,"card",{"uid":card.uid,"free":false});var before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"KIP stale stand-up does not change pose or consume card")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.posture=="stand" and g.state.energy==0 and g.state.discard.any(func(x):return x.uid==card.uid),"KIP zero-energy bound play stands up and normally discards")
 g=fresh();g.state.posture="lie";g.state.pressure_sources=[preload("res://tests/pressure_cases.gd").source("kip_posture","posture",5)]
 card=Cards.give(g,"kip_up");c=t.find_action(g,"card",{"uid":card.uid,"free":false})
 t.check(c.risk.contains("5") and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.pressure==5,"KIP stance action previews and applies the existing posture trigger once")
 for pose in ["sit","lie"]:
  for move in [["heavy",0],["heavy",1],["kick",0],["kick",1],["kick",2]]:
   g=fresh();g.state.posture=pose
   t.check(Cards.play(t,g,"kip_up",true).ok,"KIP free face can activate from either low posture")
   var attack=Basic.attack(t,g,move[0],move[1])
   t.check(attack.valid and g.state.posture==pose,"KIP next leg move ignores pose without moving the player: "+str(move))
   t.check(not Basic.attack(t,g,"strike",0).valid,"KIP does not relax arm-only posture requirement")
   before=g.export_snapshot();g.get_view();g.command_facts()
   t.check(g.state==before,"KIP previews cannot consume the next-attack effect")
   t.check(g.dispatch(g.command(attack.payload,g.state.version),g.state.version).ok and "kip_up_free" not in g.state.card_buffs and g.state.posture==pose,"KIP full multi-hit or all-target action consumes effect once without standing")
   if g.state.phase=="battle": t.check(not Basic.attack(t,g,"heavy",0).valid,"KIP posture requirement returns after the attack")
 g=fresh();Cards.play(t,g,"kip_up",true)
 t.check(t.action(g,"attack",{"type":"strike","form":0}).ok and "kip_up_free" in g.state.card_buffs,"KIP arm attack does not consume leg buff")
 t.check(t.action(g,"attack",{"type":"fireball","form":0}).ok and "kip_up_free" in g.state.card_buffs,"KIP spell does not consume leg buff")
 before=g.export_snapshot()
 var duplicate=Cards.give(g,"kip_up");before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":duplicate.uid,"free":true}).ok and g.state==before,"KIP repeated active effect is refused without payment")
 g=fresh();g.state.posture="lie";Cards.play(t,g,"kip_up",true);g.add_fixture("ankle",8)
 t.check(not Basic.attack(t,g,"heavy",0).valid and not Basic.attack(t,g,"kick",2).valid,"KIP keeps body restrictions despite posture waiver")
 g.state.kick_last=g.state.round
 t.check(not Basic.attack(t,g,"kick",0).valid and Basic.attack(t,g,"kick",0).reason.contains("冷却"),"KIP does not bypass bound-kick cooldown")
 g=fresh();g.state.posture="sit";g.add_fixture("ankle",4);Cards.play(t,g,"kip_up",true)
 c=Basic.attack(t,g,"kick",0)
 t.check(c.valid and c.payload.fall and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.posture=="lie" and "kip_up_free" not in g.state.card_buffs,"KIP bound-feet kick keeps its normal after-attack fall and consumes the effect")
 g=Game.new(42,true,"binding_box_solo");g.CaptureBind.apply_bind(g,g.state.enemies[0])
 card=Cards.give(g,"kip_up");before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state==before,"KIP standing cannot override capture-imposed posture")
 g=fresh();g.state.posture="lie";Cards.play(t,g,"kip_up",true);g.state.energy=0;before=g.export_snapshot()
 t.check(not t.action(g,"attack",{"type":"kick","form":1}).ok and g.state==before,"KIP insufficient energy cannot consume pending effect")
 g.state.energy=30;g.state.heavy_used=true
 t.check(not Basic.attack(t,g,"heavy",0).valid,"KIP retains per-turn close-strike limit")
 var restored=fresh()
 t.check(restored.restore_snapshot(g.export_snapshot()).ok and "kip_up_free" in restored.state.card_buffs,"KIP current snapshot restores pending next-leg effect")
 g.Cards.expire_turn_buffs(g)
 t.check("kip_up_free" in g.state.card_buffs,"KIP unused next-attack buff survives turn end")
 g.RelicEffects.end_combat(g)
 t.check("kip_up_free" in g.state.card_buffs,"KIP unused buff follows existing next-attack retention across combat cleanup")

static func capture_priority(t) -> void:
 for bind_first in [true,false]:
  var g=Game.new(42,true,"binding_box_solo");g._discard_end();g.state.energy=30
  if bind_first: g.CaptureBind.apply_bind(g,g.state.enemies[0])
  t.check(Cards.play(t,g,"kip_up",true).ok,"KIP CAPTURE free buff can be played before or after capture")
  if not bind_first: g.CaptureBind.apply_bind(g,g.state.enemies[0])
  t.check(g.state.posture=="sit" and g.validate()=="","KIP CAPTURE fixture uses the real forced seated posture")
  var before=g.export_snapshot()
  for move in [["heavy",0],["heavy",1],["kick",1]]:
   var attack=Basic.attack(t,g,move[0],move[1])
   t.check(not attack.valid and not g.dispatch(g.command(attack.payload,g.state.version),g.state.version).ok and g.state==before,"KIP CAPTURE forced seated posture rejects standing moves without consuming resources or buff: "+str(move))
  var seated=Basic.attack(t,g,"kick",2)
  t.check(seated.valid and seated.label.contains("坐着踢") and g.state==before,"KIP CAPTURE preview uses the seated move and remains read-only")
  var restored=fresh()
  t.check(restored.restore_snapshot(before).ok and not Basic.attack(t,restored,"heavy",0).valid,"KIP CAPTURE restored pending buff still respects forced posture")
  if bind_first:
   t.check(g.dispatch(g.command(seated.payload,g.state.version),g.state.version).ok and g.state.posture=="sit" and "kip_up_free" not in g.state.card_buffs,"KIP CAPTURE legal seated attack keeps the forced posture and consumes the next-attack buff normally")
  else:
   g.CaptureBind.damage_bind(g,100.0,"test")
   var attack=Basic.attack(t,g,"heavy",0)
   t.check(attack.valid and g.dispatch(g.command(attack.payload,g.state.version),g.state.version).ok and g.state.posture=="sit","KIP CAPTURE unused posture waiver works again after actual capture removal")
 var g=Game.new(42,true,"guard");g.state.posture="lie";g.CaptureBind.apply_bind(g,g.state.enemies[0])
 var card=Cards.give(g,"kip_up");var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state==before,"KIP CAPTURE bound face cannot skip the guard's lying-to-seated-to-standing sequence")
 g=Game.new(42,true,"drone_solo");g.state.energy=30;g._discard_end();g.CaptureBind.apply_bind(g,g.state.enemies[0])
 t.check(Cards.play(t,g,"kip_up",true).ok and Basic.attack(t,g,"heavy",0).valid,"KIP CAPTURE compatible forced standing posture still allows standing moves")
 g.add_fixture("ankle",4)
 var kick=Basic.attack(t,g,"kick",0);before=g.export_snapshot()
 t.check(not kick.valid and kick.reason.contains("无法在踢击后躺下") and not g.dispatch(g.command(kick.payload,g.state.version),g.state.version).ok and g.state==before,"KIP CAPTURE cannot override the drone's prohibition on falling after a bound-feet kick")
