extends RefCounted
const F=preload("res://tests/follow_through_cases.gd")
const Give=preload("res://tests/curse_cases.gd")
const Splash=preload("res://tests/card_splash_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 for type in ["strain","slip"]:
  ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.wall="normal"
  ui.game.state.strength=2;ui.game.state.dexterity=4;ui.game.state.charge=1
  var main=F.piece(ui.game,"thigh","above_knee",60,100)
  var peer=F.piece(ui.game,"thigh","above_knee" if type=="strain" else "thigh_root",40,100)
  var card=Give.give(ui.game,type);ui.card_faces[card.uid]=false
  ui.render();await t.frames()
  var value=11 if type=="strain" else 13
  t.check(t.visible_text(ui.card_buttons[card.uid]).contains(("挣扎" if type=="strain" else "滑脱")+str(value)),"SPLASH UI rendered card face shows current attribute and charge bonus "+type)
  var before=ui.game.export_snapshot()
  await t.start_drag(card.uid,"thigh")
  var choice=Queries.find(ui.view,"card",{"uid":card.uid,"target":main.id,"free":false})
  t.check(ui.game.candidate_detail(choice).contains("波及：") and ui.game.candidate_detail(choice).contains(peer.name) and ui.game.state==before,"SPLASH UI formal target preview includes collateral damage without state mutation "+type)
  await t.release_target(await t.reveal_drop_target(choice.key));await t.frames()
  t.check(Splash.events(ui.game).size()==1 and ui.game._equipment(peer.id).durability<40 and ui.game.state.energy==before.energy-1,"SPLASH UI native drop damages primary and collateral for one payment "+type)
  t.check(ui.view.logs.any(func(row):return row.text.contains("波及")),"SPLASH UI committed collateral appears in existing log projection "+type)
