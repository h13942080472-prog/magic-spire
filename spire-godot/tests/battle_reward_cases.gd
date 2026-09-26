extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const CoreGame=preload("res://core/game.gd")
const Arch=preload("res://tests/architecture_cases.gd")

# 测试侧计数器（生产源码不带计数器）：数一次提交里 `_finish_battle` 被执行几次。
class BattleEndCountingGame extends "res://tests/game_fixture.gd":
 var finish_calls=0
 func _finish_battle(end_kind: String="victory") -> void:
  finish_calls+=1
  super._finish_battle(end_kind)

# docs/spec/transition-pipeline.md「证据入口」：八类战斗结束入口（＋警卫宣告收押）逐个走真实公开命令，
# 每次迁移日志恰有一条 `battle_end_*`、目标阶段与今天相同、`_finish_battle` 只被调用一次；
# 收押也走同一路径（迁移日志同为 `battle_end_captured`，执行体不经过 `_finish_battle`）。
static func battle_end_single_path_for_all_entry_points(t) -> void:
 var entries=[
  {"name":"normal_last_hit","kind":"battle_end_victory","phase":"reward","finish":1},
  {"name":"end_turn_all_gone","kind":"battle_end_victory","phase":"reward","finish":1},
  {"name":"saturation","kind":"battle_end_saturated","phase":"reward","finish":1},
  {"name":"event_battle","kind":"battle_end_victory","phase":"event","finish":1},
  {"name":"prison_exit_battle","kind":"battle_end_victory","phase":"reward","finish":1},
  {"name":"dispatch_all_gone","kind":"battle_end_victory","phase":"reward","finish":1},
  {"name":"enemy_phase_all_gone","kind":"battle_end_victory","phase":"reward","finish":1},
  {"name":"capture_surrender","kind":"battle_end_captured","phase":"captured","finish":0},
  {"name":"capture_guard_intent","kind":"battle_end_captured","phase":"captured","finish":0},
 ]
 for entry in entries:
  var g=battle_end_fixture(t,entry.name)
  var before=Arch.transition_log(g)
  battle_end_command(t,g,entry.name)
  var delta=Arch.transition_delta(g,before)
  t.check(Arch.transition_kinds(delta,"battle_end_")==[entry.kind],"TRANSITION ENTRY exactly one battle-end kind "+entry.name+": "+str(delta))
  t.check(String(g.state.phase)==entry.phase,"TRANSITION ENTRY target phase unchanged "+entry.name+": "+String(g.state.phase))
  t.check(g.finish_calls==int(entry.finish),"TRANSITION ENTRY executor call count "+entry.name+": "+str(g.finish_calls))

static func last_enemy(g) -> int:
 return g.state.enemies.size()-1

static func keep_last(g):
 for index in range(g.state.enemies.size()-1):
  g.state.enemies[index].gone=true;g.state.enemies[index].hp=0.0
 g.state.enemies[last_enemy(g)]["hp"]=1.0
 return g

static func drop_last(g):
 for enemy in g.state.enemies: enemy.gone=true;enemy.hp=0.0;enemy.intent={}
 return g

# 每个入口的真实可构造夹具；它们与迁移 oracle 的场景一一对应。
static func battle_end_fixture(t, name: String):
 match name:
  "normal_last_hit":
   return keep_last(BattleEndCountingGame.new(42))
  "end_turn_all_gone":
   return drop_last(BattleEndCountingGame.new(42))
  "saturation":
   var g=BattleEndCountingGame.new(42)
   g.state.enemies.clear()
   g._spawn_enemies("rope_solo")
   var enemy=g.state.enemies[0]
   var spec=g.EnemyPlans.application(g.Enemies.TYPES.rope.install_pool,2,3)
   for i in range(200):
    if not g.Application.execute(g,spec,enemy.id).ok: break
   for i in range(200):
    var targets=g.EnemyPlans.targets(g,enemy,"tighten")
    if targets.is_empty(): break
    g._enemy_operation(enemy,{"kind":"tighten","target":targets[0].id,"tier":3,"text":"加固"})
   return g
  "event_battle":
   var g=BattleEndCountingGame.new(42,true,"floating_belt_cluster")
   t.check(t.action(g,"event",{"action":"choose","choice":"fight"}).ok and g.state.phase=="battle","TRANSITION ENTRY event battle really starts: "+String(g.state.phase))
   return keep_last(g)
  "prison_exit_battle":
   # The intake leaves every striking limb restrained, so the exit battle is finished by the
   # guaranteed spell (定咒), which is a real legal attack candidate in this state.
   var exit_battle=keep_last(BattleEndCountingGame.new(42,true,"prison_gate_exit"))
   exit_battle.state.sure_cast=true
   return exit_battle
  "dispatch_all_gone":
   var g=drop_last(BattleEndCountingGame.new(42))
   g.add_fixture("thigh",8,10)
   return g
  "enemy_phase_all_gone":
   var g=drop_last(BattleEndCountingGame.new(42))
   # A leaving enemy is the real enemy-phase departure; the trailing check finishes the battle.
   g.state.enemies[0].gone=false;g.state.enemies[0].hp=1.0;g.state.enemies[0].intent={"kind":"leave","text":"离场","delayed":false}
   return g
  "capture_surrender":
   return BattleEndCountingGame.new(42)
  "capture_guard_intent":
   var g=BattleEndCountingGame.new(42,true,"guard")
   var enemy=g.state.enemies[0]
   g.state.guard_bind={"progress":100.0,"sources":{"guard":{"enemy":enemy.id,"energy":0}}}
   enemy.guard.bind_ready=false
   enemy.stage=4
   enemy.intent={"kind":"bind_gain","text":"捕缚进度＋10","delayed":false}
   t.check(t.action(g,"end").ok,"TRANSITION ENTRY announced capture is scheduled")
   return g
 return BattleEndCountingGame.new(42)

static func battle_end_command(t, g, name: String) -> void:
 match name:
  "normal_last_hit","event_battle":
   t.check(t.action(g,"attack",{"type":"strike"}).ok,"TRANSITION ENTRY strike commits "+name)
  "prison_exit_battle":
   t.check(t.action(g,"attack",{"type":"fireball"}).ok,"TRANSITION ENTRY exit battle spell commits "+name)
  "end_turn_all_gone","saturation","enemy_phase_all_gone":
   t.check(t.action(g,"end").ok,"TRANSITION ENTRY turn boundary commits "+name)
  "dispatch_all_gone":
   var card=t.hand_card(g,"strain")
   t.check(not card.is_empty() and t.action(g,"card",{"uid":card.uid,"target":g.equipment_at("thigh")[0].id}).ok,"TRANSITION ENTRY card command commits "+name)
  "capture_surrender":
   t.check(t.action(g,"surrender").ok,"TRANSITION ENTRY surrender commits "+name)
  "capture_guard_intent":
   t.check(t.action(g,"end").ok,"TRANSITION ENTRY announced capture commits "+name)

# docs/spec/transition-pipeline.md「证据入口」：整备结束三条分支都记 `prepare_end`（同一 kind），
# 目标阶段分别 pack／map／cleared。
static func prepare_end_three_branches_one_kind(t) -> void:
 var cases=[
  {"name":"map","phase":"map","command":"finish_prepare","packed":false,"practice":false},
  {"name":"pack","phase":"pack","command":"finish_prepare","packed":true,"practice":false},
  {"name":"cleared","phase":"cleared","command":"finish_rest","packed":false,"practice":true},
 ]
 for entry in cases:
  var g=prepare_end_fixture(t,entry)
  var before=Arch.transition_log(g)
  t.check(t.action(g,entry.command).ok,"TRANSITION PREPARE branch commits "+entry.name)
  var delta=Arch.transition_delta(g,before)
  t.check(not delta.is_empty() and Arch.transition_kinds(delta,"prepare_end").size()==delta.size(),"TRANSITION PREPARE every entry is the declared kind "+entry.name+": "+str(delta))
  t.check(String(g.state.phase)==entry.phase,"TRANSITION PREPARE target phase "+entry.name+": "+String(g.state.phase))

static func prepare_end_fixture(t, entry: Dictionary):
 if entry.practice:
  var practice=CoreGame.new(42,true,"equipment")
  t.check(practice.state.phase=="rest","TRANSITION PREPARE practice room is real: "+String(practice.state.phase))
  return practice
 var g=Game.new(42)
 g._finish_battle()
 for candidate in g.command_facts():
  if candidate.payload.kind=="reward" and candidate.payload.get("type","")=="skip":
   g.dispatch(g.command(candidate.payload,g.state.version),g.state.version)
   break
 t.check(g.state.phase=="prepare","TRANSITION PREPARE reward skip entered preparation: "+String(g.state.phase))
 if entry.packed:
  for i in range(6): g._gain_tool("shard")
 return g

static func run(t) -> void:
 battle_end_single_path_for_all_entry_points(t)
 prepare_end_three_branches_one_kind(t)
 boss_flask(t)
 magnifying_glass(t)
 skip_rewards(t)
 for order in [["card","item","relic"],["relic","card","item"],["item","relic","card"]]:
  var g=Game.new(78)
  g.state.room_encounters[g.state.room]="guard_solo"
  g.state.item_drop_chance=100
  var deck=g.state.deck.size();var items=g.state.items.size();var relics=g.state.relics.size()
  g._finish_battle()
  var offered=g.state.reward_options.duplicate();var rng=g.state.rng.duplicate()
  t.check(g.state.phase=="reward" and g.state.deck.size()==deck and g.state.items.size()==items and g.state.relics.size()==relics,"LOOT battle freezes rewards without granting them")
  var pending_save=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"pending battle relic reward")
  t.check(pending_save!=null and pending_save.state.battle_relic_drop==g.state.battle_relic_drop,"LOOT pending unclaimed relic survives save validation")
  t.check(g.get_view().battle_rewards.size()==3 and g.get_view().battle_rewards.all(func(row):return not row.claimed),"LOOT all pending categories have a real reward projection")
  for category in order:
   var pick=t.find_action(g,"reward",{"category":category})
   var version=g.state.version
   t.check(g.dispatch(g.command(pick.payload,version),version).ok and g.state.phase=="reward" and g.state.reward_claimed[category]==pick.payload.type,"LOOT independent pickup stays on reward screen "+category)
   var after=g.export_snapshot()
   t.check(not g.dispatch(g.command(pick.payload,version),version).ok and not t.action(g,"reward",{"category":category}).ok and g.state==after,"LOOT stale and duplicate pickup cannot grant another reward "+category)
   t.check(g.get_view().battle_rewards.filter(func(row):return row.category==category)[0].claimed and g.state.rng==rng and g.state.reward_options==offered,"LOOT claimed projection and frozen random result "+category)
  t.check(g.state.deck.size()==deck+1 and g.state.items.size()==items+1 and g.state.relics.size()==relics+1,"LOOT all categories grant exactly once in either order")
  t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare" and g.get_view().battle_rewards.is_empty(),"LOOT continue enters preparation only after acknowledgement")
  g.state.phase="battle";g._finish_battle()
  t.check(g.state.reward_claimed.is_empty() and g.get_view().battle_rewards.all(func(row):return not row.claimed),"LOOT next battle resets claim state")
 var g=Game.new(78);g.state.item_drop_chance=100;g.state.room_encounters[g.state.room]="guard_solo"
 var deck=g.state.deck.size();var items=g.state.items.duplicate(true);var relics=g.state.relics.duplicate()
 g._finish_battle()
 var dropped=g.state.battle_item_drop;var relic=g.state.battle_relic_drop
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.deck.size()==deck and g.state.items==items and g.state.relics==relics,"LOOT continue forfeits every unclaimed reward")
 t.check(not t.action(g,"reward",{"category":"item","type":dropped}).ok and not t.action(g,"reward",{"category":"relic","type":relic}).ok,"LOOT cannot collect a reward after leaving")

static func boss_flask(t) -> void:
 var Save=preload("res://tests/persistence_cases.gd")
 for result in ["victory","ordinary","saturated","departure"]:
  var g=Game.new(78)
  if result!="ordinary": g.state.room="summit";g._start_battle()
  g.state.item_drop_chance=100;g.state.flask_mana=137.5
  for enemy in g.state.enemies:
   if result in ["victory","ordinary"]: g._damage_enemy(enemy,1000,"physical","测试")
   else: enemy.gone=true;enemy.intent={}
  g._finish_battle("saturated" if result=="saturated" else "victory")
  var choices=g.get_view().display_facts.filter(func(c):return c.payload.kind=="reward" and c.payload.get("category","")=="flask")
  if result!="victory":
   t.check(choices.is_empty() and g.state.flask_mana==137.5,"BOSS FLASK no bonus for "+result)
   continue
  t.check(g.state.flask_mana==137.5 and choices.size()==1 and g.get_view().battle_rewards.size()==4,"BOSS FLASK freezes extra eighty alongside card item relic without automatic credit")
  Save.roundtrip(t,g,"pending Boss flask reward")
  var before=g.export_snapshot();var pick=choices[0]
  for amount in [-1,79,81]:
   var bad=before.duplicate(true);bad.battle_flask_drop=amount
   t.check(not g.restore_snapshot(bad).ok and g.state==before,"BOSS FLASK invalid saved amount rejects without mutation")
  t.check(g.dispatch(g.command(pick.payload,before.version),before.version).ok and g.state.flask_mana==217.5,"BOSS FLASK claim adds full eighty above player mana maximum")
  t.check(g.state.mana==before.mana and g.state.temporary_mana==before.temporary_mana and g.state.flask_deposits==before.flask_deposits and g.state.tick==before.tick and g.state.energy==before.energy and g.state.rng==before.rng and g.state.deck==before.deck and g.state.relics==before.relics,"BOSS FLASK claim only changes flask and reward receipt, costs no resources or turn")
  var after=g.export_snapshot()
  t.check(not g.dispatch(g.command(pick.payload,before.version),before.version).ok and not t.action(g,"reward",{"category":"flask"}).ok and g.state==after,"BOSS FLASK duplicate and stale claims roll back")
  var restored=Save.roundtrip(t,g,"claimed Boss flask reward")
  t.check(restored!=null and not t.action(restored,"reward",{"category":"flask"}).ok,"BOSS FLASK save preserves claimed receipt")
  t.check(g.restore_snapshot(before).ok,"BOSS FLASK pending reward restores")
  t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.flask_mana==137.5 and not t.action(g,"reward",{"category":"flask"}).ok,"BOSS FLASK continue forfeits unclaimed reward")

static func skip_rewards(t) -> void:
 for boss in [false,true]:
  var g=Game.new(78)
  if boss:
   g.state.room="summit";g._start_battle();g._finish_battle()
  else:
   g.state.room_encounters[g.state.room]="guard_solo";g.state.item_drop_chance=100;g._finish_battle()
  var before=g.export_snapshot()
  for category in ["card","relic"]:
   var skip=t.find_action(g,"reward_skip",{"category":category})
   var preview=g.export_snapshot();var panel=g.get_view().reward_panel
   t.check(panel.active and panel.rows.any(func(row):return row.category==category and row.skip_key==String(skip.get("key",""))) and g.state==preview,"SKIP reward projection exposes the formal per-category skip without mutation")
   t.check(g.dispatch(g.command(skip.payload,g.state.version),g.state.version).ok and g.state.phase=="reward" and g.state.reward_claimed[category]=="skip","SKIP settles one category without leaving the reward screen")
   var settled=g.export_snapshot()
   t.check(not g.dispatch(g.command(skip.payload,g.state.version-1),g.state.version-1).ok and not t.action(g,"reward_skip",{"category":category}).ok and not t.action(g,"reward",{"category":category}).ok and g.state==settled,"SKIP stale, repeated and later claims reject atomically")
   var restored=Game.new(2)
   t.check(restored.restore_snapshot(settled).ok and restored.state.reward_claimed==g.state.reward_claimed and restored.get_view().battle_rewards.any(func(row):return row.category==category and row.skipped),"SKIP current snapshots preserve skipped cards and normal or Boss relics")
  t.check(g.state.deck==before.deck and g.state.relics==before.relics and g.state.items==before.items and g.state.mana==before.mana and g.state.flask_mana==before.flask_mana and g.state.rng==before.rng and g.state.tick==before.tick,"SKIP no cards, relic effects, costs, random draws or turns are granted")
  if not boss: t.check(t.action(g,"reward",{"category":"item"}).ok,"SKIP remaining item reward can still be claimed")
  t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare","SKIP continue still enters ordinary preparation")
 var rest=Game.new(42);rest.state.room="rest";rest._start_rest()
 var panel=rest.get_view().reward_panel;var deck=rest.state.deck.duplicate(true)
 t.check(panel.active and panel.rows.size()==3 and panel.rows[0].action_keys.size()==3 and panel.rows.slice(1).all(func(row):return row.action_keys.size()==1 and row.direct) and panel.extra_keys.is_empty() and t.action(rest,"rest_begin").ok and rest.state.rest_left==rest.B.REST_TURNS and rest.state.deck==deck,"SKIP rest uses three common reward rows and keeps all rest turns when declining")

static func magnifying_glass(t) -> void:
 var Save=preload("res://tests/persistence_cases.gd")
 var g=Game.new(78)
 g.state.room_encounters[g.state.room]="guard_solo";g._finish_battle()
 g.state.battle_relic_drop="magnifying_glass"
 if "magnifying_glass" not in g.state.relic_seen: g.state.relic_seen.append("magnifying_glass")
 var offered=g.state.reward_options.duplicate();var random=g.state.rng.duplicate(true)
 var pickup=t.find_action(g,"reward",{"category":"relic"})
 var version=g.state.version
 t.check(g.dispatch(g.command(pickup.payload,version),version).ok and "magnifying_glass" in g.state.relics,"LENS formal rare relic pickup succeeds")
 t.check(offered.size()==3 and g.state.reward_options==offered and g.state.rng==random,"LENS same window keeps its three frozen cards without drawing random numbers")
 var snapshot=g.export_snapshot()
 t.check(not g.dispatch(g.command(pickup.payload,version),version).ok and g.state==snapshot,"LENS stale pickup rejects without changing rewards")
 Save.roundtrip(t,g,"lens acquired after three-card reward froze")
 var count=g.state.deck.size()
 t.check(t.action(g,"reward",{"category":"card","type":offered[-1]}).ok and g.state.deck.size()==count+1 and g.state.deck[-1].type==offered[-1],"LENS original choices still grant exactly the selected card")
 for source in ["normal","elite","boss"]:
  for seed_value in range(32):
   var a=Game.new(seed_value);var b=Game.new(seed_value)
   a.RelicEffects.gain(a,"magnifying_glass");b.RelicEffects.gain(b,"magnifying_glass")
   var before=a.state.rng.duplicate(true)
   var choices=a.reward_offer(a.Cards.Rules.REWARDS,source)
   t.check(choices.size()==4 and choices.all(func(id):return choices.count(id)==1) and choices==b.reward_offer(b.Cards.Rules.REWARDS,source),"LENS four unique reproducible choices: "+source)
   t.check(a.state.rng.deck==before.deck and a.state.rng.enemy==before.enemy and a.state.rng.relic==before.relic,"LENS extra choice only uses reward random domain")
   if source=="boss": t.check(choices.all(func(id):return a.Cards.Rules.SPECS[id].rarity=="rare"),"LENS Boss fourth card stays rare")
 g=Game.new(42);g.RelicEffects.gain(g,"magnifying_glass");g._finish_battle()
 t.check(g.state.reward_options.size()==4 and g.get_view().reward_panel.rows.filter(func(row):return row.category=="card")[0].action_keys.size()==4,"LENS actual battle finish exposes four formal facts")
 Save.roundtrip(t,g,"lens four-card battle reward")
 for rarity in ["uncommon"]:
  g=Game.new(42);g.RelicEffects.gain(g,"magnifying_glass");g.state.room="rest";g._start_rest()
  var cards=g.state.rest_cards.filter(func(id):return g.Cards.Rules.SPECS[id].rarity==rarity)
  t.check(g.state.rest_cards.size()==4 and cards.size()==4 and g.get_view().reward_panel.rows.filter(func(row):return row.id=="uncommon")[0].action_keys.size()==4,"LENS rest freezes four uncommon choices")
  Save.roundtrip(t,g,"lens rest "+rarity)
  random=g.state.rng.duplicate(true);count=g.state.deck.size()
  t.check(t.action(g,"rest_card",{"type":cards[-1]}).ok and g.state.deck.size()==count+1 and g.state.deck[-1].type==cards[-1] and g.state.rest_left==g.B.REST_TURNS-g.B.REST_CARD_TURNS[rarity] and g.state.rng==random,"LENS fourth rest choice preserves original fee and does not reroll")
 g=Game.new(42);g.RelicEffects.gain(g,"magnifying_glass");g.state.room="rest";g._start_rest()
 count=g.state.deck.size()
 t.check(t.action(g,"rest_rare").ok and g.state.deck.size()==count+1 and g.Cards.Rules.SPECS[g.state.deck[-1].type].rarity=="rare" and g.state.rest_left==3,"LENS random rare still grants exactly one card for three turns")
 g=Game.new(42);g.RelicEffects.gain(g,"magnifying_glass")
 preload("res://tests/event_cases.gd").arrive(g,"succubus_magic_pawnshop")
 t.check(t.action(g,"event",{"action":"choose","choice":"small_trade"}).ok and g.state.room_event.stage=="reward" and g.state.room_event.reward.size()==4,"LENS actual event choice generates four reward cards")
 var fourth=g.state.room_event.reward[-1];count=g.state.deck.size()
 t.check(t.action(g,"event",{"action":"reward","type":fourth}).ok and g.state.deck.size()==count+1 and g.state.deck[-1].type==fourth,"LENS fourth event card uses original claim transaction")
 var shop=Game.new(42);var baseline=Game.new(42)
 shop.RelicEffects.gain(shop,"magnifying_glass")
 for game in [shop,baseline]:
  game.state.room=game.state.rooms.filter(func(room):return room.kind=="shop")[0].id
  game.Services.start(game)
 var stock=shop.room_data(shop.state.room).stock.filter(func(row):return row.kind=="card")
 t.check(stock.size()==5 and stock==baseline.room_data(baseline.state.room).stock.filter(func(row):return row.kind=="card"),"LENS shop explicit 2/2/1 card stock is unchanged")
 t.check("magnifying_glass" in g.Relics.REWARDS and "magnifying_glass" in g.Relics.shop_pool() and g.Relics.TYPES.magnifying_glass.rarity=="rare","LENS participates in rare reward and shop pools")
