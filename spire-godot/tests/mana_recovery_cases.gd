extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func run(t) -> void:
 for bundle in [false,true]:
  var opening=preload("res://core/game.gd").new(42)
  if bundle: opening.RelicEffects.gain(opening,"nesting_doll")
  opening.state.mana=40;opening.state.flask_mana=20;opening.add_fixture("fingers",8)
  opening._gain_tool("mana_potion");var item_id=opening.state.items.back().id
  var frozen=opening.export_snapshot()
  t.check(opening.get_view().reward_panel.entries.size()==(3 if bundle else frozen.departure.options.size()+1),"RECOVERY item and flask actions are not displayed as opening reward choices")
  t.check(t.action(opening,"item_use",{"item":item_id}).ok and t.action(opening,"flask",{"op":"withdraw"}).ok and opening.state.mana==70,"RECOVERY works during opening or nested relic choices")
  t.check(["phase","departure","relic_bundle","rng","tick"].all(func(key):return opening.state[key]==frozen[key]),"RECOVERY cannot skip or reroll pending opening rewards")
 for phase in ["battle","reward","prepare","rest_choice","rest","map","shop","prison"]:
  var g=preload("res://tests/prison_cases.gd").intake(t) if phase=="prison" else Game.new(42)
  match phase:
   "reward": g._finish_battle()
   "prepare": g._finish_battle();t.action(g,"reward",{"type":"skip"})
   "rest_choice": g._start_rest()
   "rest": g._start_rest();t.action(g,"rest_begin")
   "map": g._finish_battle();t.action(g,"reward",{"type":"skip"});t.action(g,"finish_prepare")
   "shop": t.check(preload("res://tests/mana_flask_cases.gd").shop(g),"RECOVERY reaches actual shop")
  g.add_fixture("fingers",8);g.add_fixture("wrist",8)
  g._install_template("mouth_band","mouth",16,16,false,"fixture",2)
  g.state.posture="stand";g.state.mana=40;g.state.flask_mana=20
  g._gain_tool("mana_potion");var item=g.state.items.back().id
  var before=g.export_snapshot()
  var actions=g.command_facts().filter(func(c):return c.payload.kind=="item_use" and c.payload.get("item","")==item)
  t.check(actions.size()==1 and actions[0].valid==(phase!="battle"),"RECOVERY one potion candidate with correct phase restrictions: "+phase)
  var withdrawal=t.find_action(g,"flask",{"op":"withdraw"})
  t.check(withdrawal.valid==(phase!="battle"),"RECOVERY flask matches potion body exemption: "+phase)
  t.check(g.state==before,"RECOVERY projections do not mutate state: "+phase)
  if phase=="battle":
   t.check(not g.dispatch(g.command(actions[0].payload,g.state.version),g.state.version).ok and g.state==before,"RECOVERY combat rejection rolls back all state")
   continue
  t.check(t.action(g,"item_use",{"item":item}).ok and g.state.mana==50 and g._item(item).is_empty(),"RECOVERY potion works while bound and retains mouth half effect: "+phase)
  t.check(t.action(g,"flask",{"op":"withdraw"}).ok and g.state.mana==55 and g.state.flask_mana==10,"RECOVERY flask retains mouth loss and real withdrawn amount: "+phase)
  t.check(["phase","tick","round","energy","rng","posture","combat","prison"].all(func(key):return g.state[key]==before[key]),"RECOVERY consumes no turn and preserves pending stage: "+phase)
  var after=g.export_snapshot()
  t.check(not g.dispatch(g.command(actions[0].payload,before.version),before.version).ok and g.state==after,"RECOVERY stale or consumed potion cannot be reused: "+phase)
  g._gain_tool("mana_potion");item=g.state.items.back().id;g.state.mana=g.state.mana_max
  before=g.export_snapshot()
  t.check(not t.action(g,"item_use",{"item":item}).ok and g.state==before,"RECOVERY full mana still prevents wasting a potion: "+phase)
 var g=Game.new(42);g.state.phase="prepare";g.state.prepare_left=2;g.add_fixture("fingers",8)
 t.check(g.Consumables.reason(g,"mana_potion")=="魔力已经达到上限。" and g.Consumables.reason(g,"energy_potion").contains("坐下"),"RECOVERY exemption does not alter other potion rules")
 for phase in ["departure","travel","pack","event","inspection","captured"]:
  g.state.phase=phase;g.state.mana=40
  t.check(g.Consumables.reason(g,"mana_potion")=="","RECOVERY noncombat phase policy includes "+phase)
 t.check(g.Consumables.effect_description("mana_potion",20).contains("非战斗与探索") and g.Consumables.description(g,"mana_potion").contains("嘴部不自由时效果减半"),"RECOVERY public descriptions retain phase and mouth rules")
