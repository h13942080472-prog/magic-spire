extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Real=preload("res://core/game.gd")
const Prison=preload("res://tests/prison_cases.gd")
const Rewards=preload("res://tests/reward_cases.gd")

static func exercise(t,g,label: String,mounted: bool=false) -> void:
 g._gain_tool("saw");var item=g.state.items.back()
 if mounted:
  item.mount="hand_wall"
  if g.state.room=="prison": item.prison_position=g.Prison.Space.attachment_position(g)
 g._gain_tool("mana_potion");var other=g.state.items.back().duplicate(true)
 var before=g.export_snapshot()
 var choices=g.command_facts().filter(func(c):return c.payload.kind=="item_discard" and c.payload.item==item.id)
 t.check(choices.size()==1 and choices[0].valid and choices[0].cost==0 and choices[0].mana==0,"DISCARD one free candidate in "+label)
 if choices.is_empty(): return
 var choice=choices[0]
 g.get_view()
 t.check(g.state==before,"DISCARD queries preserve state in "+label)
 t.check(not g.dispatch(g.command(choice.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"DISCARD stale request is atomic in "+label)
 var result=g.dispatch(g.command(choice.payload,g.state.version),g.state.version)
 t.check(result.ok and g._item(item.id).is_empty() and g._item(other.id)==other,"DISCARD only chosen physical item removed in "+label+str(result.get("error","")))
 for key in ["phase","room","energy","mana","temporary_mana","flask_mana","flask_deposits","pressure","tick","round","rng","combat","prison","card_chain","room_event"]:
  t.check(g.state[key]==before[key],"DISCARD preserves "+key+" in "+label)
 var after=g.export_snapshot()
 t.check(not g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and g.state==after,"DISCARD repeated request cannot remove another item in "+label)

static func run(t) -> void:
 var g=Real.new(42)
 t.check(t.action(g,"departure",{"op":"skip"}).ok and g.state.phase=="map","DISCARD enter real map after the opening choice")
 exercise(t,g,"map")
 var destinations=g.command_facts().filter(func(c):return c.payload.kind=="depart" and c.valid)
 t.check(not destinations.is_empty(),"DISCARD map offers a real travel destination")
 if destinations.is_empty(): return
 var destination=destinations[0]
 t.check(g.dispatch(g.command(destination.payload,g.state.version),g.state.version).ok,"DISCARD setup real travel")
 exercise(t,g,"travel")
 g=Game.new(42);exercise(t,g,"battle",true)
 g=Rewards.setup();exercise(t,g,"preparation")
 g=Real.new(42);g.state.room="rest";g._start_rest()
 exercise(t,g,"rest choice")
 t.check(t.action(g,"rest_begin").ok,"DISCARD setup real rest")
 exercise(t,g,"rest")
 for kind in ["shop","treasure"]:
  g=Real.new(42);g.state.room=g.state.rooms.filter(func(room):return room.kind==kind)[0].id
  g.Services.start(g);exercise(t,g,kind)
 g=Game.new(42);preload("res://tests/event_cases.gd").arrive(g,"binding_cleric")
 exercise(t,g,"event")
 g=Game.new(42)
 for enemy in g.state.enemies: enemy.gone=true
 g._finish_battle();exercise(t,g,"reward")
 g=Prison.intake(t);Prison.clear_fixture(g)
 exercise(t,g,"prison",true)
 g.state.prison.left=1;t.check(t.action(g,"end").ok,"DISCARD setup actual inspection")
 exercise(t,g,"inspection")
 g=Game.new(42);g.Pressure.gain(g,100,"test")
 exercise(t,g,"forced turn")
 g=Rewards.setup()
 var targets=[]
 for i in range(3): targets.append(g.add_fixture("wrist",6,10,true))
 var card=Rewards.give(t,g,"double_unlock")
 t.check(Rewards.play(t,g,card,"wrist",targets[0].id).ok and not g.state.card_chain.is_empty(),"DISCARD setup pending multi-hit choice")
 exercise(t,g,"multi-hit choice")
 var next=g.command_facts().filter(func(c):return c.payload.kind=="chain" and c.valid)[0]
 t.check(g.dispatch(g.command(next.payload,g.state.version),g.state.version).ok and g.state.card_chain.is_empty(),"DISCARD original multi-hit action still completes")
