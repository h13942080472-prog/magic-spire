extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const ID="axe_amulet"

static func triggers(g) -> Array:
 return g.state.logs.filter(func(row):return row.data.get("relic_trigger",{}).get("id","")==ID and row.text.contains("进入"))

static func setup():
 var g=Game.new(42);g.state.relics=[ID];g.state.mana=40
 return g

static func run(t) -> void:
 var g=setup()
 t.check(g.Relics.TYPES[ID].name=="斧护符" and g.Relics.TYPES[ID].rarity=="uncommon" and ID in g.Relics.REWARDS and ID in g.Relics.shop_pool(),"AXE uncommon relic enters ordinary reward and shop pools")
 for scenario in [{"encounter":"rope_solo","boss":false,"gain":0},{"encounter":"rope_heap_solo","boss":false,"gain":20},{"encounter":"six_bind_solo","boss":true,"gain":20},{"encounter":"rope_heap_solo","boss":true,"gain":20},{"encounter":"heap_family","boss":false,"gain":20}]:
  g=setup();var room=g.room_data(g.state.room)
  room.boss=scenario.boss;g.state.room_encounters[room.id]=scenario.encounter
  var flask=g.state.flask_mana;var temporary=g.state.temporary_mana
  g._start_battle()
  t.check(g.state.mana==40+scenario.gain and triggers(g).size()==(1 if scenario.gain>0 else 0),"AXE entry uses final encounter rank and boss precedence: "+str(scenario))
  t.check(g.state.flask_mana==flask and g.state.temporary_mana==temporary,"AXE entry restores personal mana only")
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(g.state==before,"AXE read-only queries cannot retrigger recovery")
  g._start_round()
  t.check(triggers(g).size()==(1 if scenario.gain>0 else 0),"AXE later rounds do not count as room entry")
 g=setup();g.state.mana=95;g.state.room_encounters[g.state.room]="rope_heap_solo";g._start_battle()
 t.check(g.state.mana==100 and triggers(g).size()==1 and triggers(g)[0].text.contains("恢复5魔力"),"AXE recovery respects cap and logs actual amount")
 g=setup();g.state.relics=[];g.RelicEffects.gain(g,ID)
 t.check(g.state.mana==40 and triggers(g).is_empty(),"AXE pickup does not retroactively count current room")
 prison(t)

static func prison(t) -> void:
 var g=setup();var c=t.find_action(g,"surrender");var before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"AXE stale surrender cannot heal or enter prison")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.phase=="captured" and g.state.mana==40 and triggers(g).size()==1,"AXE formal surrender drains twenty during intake, then applies its one prison-entry recovery")
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==40,"AXE repeated surrender is rejected without recovery")
 t.check(t.action(g,"prison",{"action":"enter"}).ok and g.state.phase=="prison" and g.state.mana==40,"AXE intake confirmation does not repeat either milking or recovery")
 g.state.prison.left=1
 t.action(g,"end");t.action(g,"prison",{"action":"inspect"});t.action(g,"prison",{"action":"accept"});t.action(g,"prison",{"action":"resume"})
 t.check(g.state.phase=="prison" and triggers(g).size()==1,"AXE inspection and resumed exploration never repeat intake recovery")
 t.action(g,"end")
 g.state.prison.left=1;t.action(g,"end");t.action(g,"prison",{"action":"resist"})
 t.check(g.state.phase=="battle" and triggers(g).size()==1,"AXE resisting inside prison is not a new room entry")
 t.check(t.action(g,"surrender").ok and triggers(g).size()==2,"AXE actual recapture grants a new recovery")
 g=setup();g.state.security=4
 t.check(t.action(g,"surrender").ok and g.state.phase=="captured" and g.state.mana==40 and triggers(g).size()==1,"AXE security-five intake also drains and heals exactly once")
 t.check(t.action(g,"prison",{"action":"enter"}).ok and g.state.phase=="prison" and g.state.prison.left==g.B.PRISON_INTERVALS[4],"AXE security-five intake confirmation enters the ordinary top-spec cell")
