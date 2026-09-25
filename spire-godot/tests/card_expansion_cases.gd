extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Rewards=preload("res://core/card_rewards.gd")

static func give(t,g,type: String) -> Dictionary:
 g._gain_card(type)
 return t.hand_card(g,type)

static func cast(t,g,type: String,free: bool) -> Dictionary:
 var card=give(t,g,type)
 return t.action(g,"card",{"uid":card.uid,"free":free})

static func run(t) -> void:
 preload("res://tests/lewd_magic_cases.gd").run(t)
 preload("res://tests/supple_flesh_cases.gd").run(t)
 preload("res://tests/binding_power_cases.gd").run(t)
 preload("res://tests/mana_attachment_cases.gd").run(t)
 preload("res://tests/binding_search_cases.gd").run(t)
 preload("res://tests/kip_up_cases.gd").run(t)
 preload("res://tests/endless_war_goddess_cases.gd").run(t)
 preload("res://tests/confluence_cases.gd").run(t)
 preload("res://tests/hannya_cases.gd").run(t)
 preload("res://tests/siphon_strength_cases.gd").run(t)
 preload("res://tests/shared_fate_cases.gd").run(t)
 preload("res://tests/magic_hand_cases.gd").run(t)
 preload("res://tests/leverage_cases.gd").run(t)
 preload("res://tests/light_as_swallow_cases.gd").run(t)
 preload("res://tests/breath_control_cases.gd").run(t)
 preload("res://tests/infusion_cases.gd").run(t)
 preload("res://tests/siphon_cases.gd").run(t)
 preload("res://tests/mana_circuit_cases.gd").run(t)
 preload("res://tests/ready_to_strike_cases.gd").run(t)
 preload("res://tests/crossed_legs_cases.gd").run(t)
 pot_of_greed(t)
 preload("res://tests/embers_cases.gd").run(t)
 preload("res://tests/follow_through_cases.gd").run(t)
 preload("res://tests/rekindle_cases.gd").run(t)
 preload("res://tests/fire_control_cases.gd").run(t)
 mana_invocation(t)
 var g=Game.new(42)
 g.state.energy=10
 t.check(cast(t,g,"fire_mastery",false).ok and cast(t,g,"fire_mastery",true).ok,"DUAL both power faces can coexist")
 t.check(cast(t,g,"henshin",true).ok and g.Cards.damage_multiplier(g,"fireball")==4 and g.Cards.damage_multiplier(g,"strike")==2,"BUFF distinct sources multiply by four, other damage only by two")
 var c=t.find_action(g,"attack",{"type":"fireball"})
 t.check(c.payload.damage==g.B.FIREBALL*4 and g.get_view().statuses.filter(func(e):return e.id.begins_with("power_")).size()==3,"BUFF damage preview and separate status entries reflect all sources")
 var copy=give(t,g,"henshin");var before=g.export_snapshot()
 t.check(t.find_action(g,"card",{"uid":copy.uid,"free":true}).reason=="唯一：henshin已生效，不能重复叠加。" and g.B.card_info("henshin")[3].contains("同源不叠加"),"HENSHIN face and duplicate reason clearly explain single effect")
 t.check(not t.action(g,"card",{"uid":copy.uid,"free":true}).ok and g.state==before,"BUFF duplicate source rejects before payment")
 var restored=Save.roundtrip(t,g,"dual powers and damage source")
 if restored!=null: t.check(restored.Cards.damage_multiplier(restored,"fireball")==4,"BUFF restored effects derive from their original sources")
 var target=g.add_fixture("wrist",8)
 var enhanced=g.escape_preview(target,"slip",5)
 g.state.card_buffs.erase("henshin_free")
 var plain=g.escape_preview(target,"slip",5)
 t.check(is_equal_approx(enhanced.damage,plain.damage*2) and enhanced.damage_buff_multiplier==2,"BUFF equipment damage includes wall contribution once")
 g.state.card_buffs.append("henshin_free")
 g.Cards.end_powers(g)
 t.check(g.Cards.active_buffs(g).is_empty() and g.Cards.damage_multiplier(g,"fireball")==1,"BUFF battle cleanup removes all battle sources")

 g=Game.new(42);g.state.energy=10;cast(t,g,"henshin",true)
 target=preload("res://tests/link_cases.gd").at(g,"mid_thigh")
 var passive=g.escape_preview(target,"slip",g.SlipMotion.factor("mid_thigh",g.state.posture),[],true)
 var old=target.durability
 c=t.find_action(g,"wall_move",{"direction":"away"})
 t.check(passive.damage_buff_multiplier==2 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(target.id).durability,old-passive.damage),"BUFF formal movement applies doubled passive damage once")
 target=g._equipment(target.id);g._gain_tool("shard")
 c=t.find_action(g,"item_use",{"item":g.state.items.back().id,"target":target.id})
 t.check(g.candidate_detail(c).contains("10") and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._equipment(target.id).is_empty(),"BUFF fixed tool preview and actual cutting both double")

 g=Game.new(42);g.state.energy=10
 t.check(cast(t,g,"strong_elbow",true).ok and cast(t,g,"henshin",true).ok,"BUFF arm preparation combines with battle damage")
 var kick=t.find_action(g,"attack",{"type":"kick","form":1})
 t.check(g.dispatch(g.command(kick.payload,g.state.version),g.state.version).ok and "strong_elbow_free" in g.state.card_buffs,"BUFF unrelated attack leaves next-elbow effect intact")
 c=t.find_action(g,"attack",{"type":"strike","form":1})
 var hp=g._enemy(c.payload.enemy).hp
 t.check(c.payload.hits==2 and c.payload.damage==16 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"BUFF complete multi-hit elbow receives both multipliers")
 t.check(g._enemy(c.payload.enemy).hp==maxf(0,hp-32) and "strong_elbow_free" not in g.state.card_buffs and "henshin_free" in g.state.card_buffs,"BUFF next attack consumed once after all hits; battle buff retained")

 g=Game.new(42);target=g.add_fixture("upper_arm",8);g.add_fixture("wrist",8)
 copy=give(t,g,"strong_elbow")
 var choices=g.command_facts().filter(func(a):return a.payload.get("uid","")==copy.uid and not a.payload.free)
 t.check(not choices.is_empty() and choices.all(func(a):return a.payload.slot in ["upper_arm","forearm"]),"ELBOW bound target scope is upper arm and forearm only")
 var hand_size=g.state.hand.size()
 c=t.find_action(g,"card",{"uid":copy.uid,"target":target.id})
 t.check(c.payload.preview.base==8 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.hand.size()==hand_size,"ELBOW legal damage draws one after using one card")

 for free in [false,true]:
  g=Game.new(42);g.state.mana=60;g.state.energy=3;g.state.pressure=60;g.state.temporary_mana=5
  g.state.sure_cast=true
  var magic=g.state.rng.magic
  t.check(cast(t,g,"mana_conversion",free).ok and g.state.mana==(70 if free else 45) and g.state.energy==(2 if free else 5),"CONVERSION bound pays twenty mana for two energy; free restores ten mana")
  t.check(g.state.temporary_mana==(5 if free else 0) and g.state.rng.magic==magic and not g.state.sure_cast,"CONVERSION guaranteed spell keeps fixed cost with temporary mana payment, consumes guarantee")
  g=Game.new(42);g.state.mana=60;g.state.energy=3;g.state.pressure=99;g.state.temporary_mana=5
  copy=give(t,g,"mana_conversion");c=t.find_action(g,"card",{"uid":copy.uid,"free":free})
  before=g.export_snapshot()
  t.check(c.valid and c.mana==(0 if free else 20) and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"CONVERSION either face uses normal probabilistic spell submission with fixed payment")
  t.check(g.state.mana==before.mana-c.mana_payment.mana*0.5 and g.state.energy==before.energy-c.cost and g.state.temporary_mana==before.temporary_mana-c.mana_payment.temporary_mana*0.5 and g.state.hand.any(func(x):return x.uid==copy.uid),"CONVERSION failed exchange spends cost without gain, uses temporary mana and keeps card")
  t.check(g.state.rng.magic==before.rng.magic+1 and not g.state.logs.filter(func(x):return x.data.has("spell")).back().data.spell.success,"CONVERSION failure uses the shared casting random domain")
 g=Game.new(42);g.state.energy=0;copy=give(t,g,"mana_conversion");before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":copy.uid,"free":true}).ok and g.state==before,"CONVERSION printed zero still requires actual one energy")
 g=Game.new(42);g.state.pressure=59
 t.check(cast(t,g,"pleasure_conversion",false).ok and g.state.energy==5 and g.state.pressure==59,"CONVERSION floor of current resource is gained without spending it")

 for free in [false,true]:
  g=Game.new(42)
  if free: g.state.mana=0
  t.check(cast(t,g,"mana_surge",free).ok and g.state.mana==(0 if free else 95) and g.state.charge==(0 if free else 2) and g.state.temporary_mana==(10 if free else 0) and g.state.exhaust.back().type=="mana_surge","SURGE bound pays five for charges; free works with zero mana for ten temporary mana; both exhaust")
 g=Game.new(42);g.state.pressure=99;copy=give(t,g,"mana_surge")
 c=t.find_action(g,"card",{"uid":copy.uid,"free":true})
 var mana=g.state.mana
 t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.charge==0 and is_equal_approx(g.state.mana,mana-c.mana*0.5) and g.state.hand.any(func(x):return x.uid==copy.uid) and g.state.exhaust.is_empty(),"SURGE failed cast pays and keeps exhaust card without granting charges")

 g=Game.new(42);preload("res://tests/link_cases.gd").precise_tool_fixture(g);g.add_fixture("wrist",8,10,true)
 var tools=g.state.items.duplicate(true)
 t.check(cast(t,g,"henshin",false).ok and g.action_targets().is_empty() and g.state.composites.is_empty() and g.state.links.is_empty() and g.state.mana==60 and g.state.items==tools,"HENSHIN releases locked pieces, composite components and links, preserves ordinary tools")
 reward_rules(t)
 henshin_capture(t)

static func henshin_capture(t) -> void:
 for free in [false,true]:
  var g=Game.new(42,true,"guard")
  var enemy=g.state.enemies[0]
  enemy.stage=4
  preload("res://tests/guard_cases.gd").bind(g,enemy)
  g.state.energy=g.Cards.Rules.energy_cost("henshin",free)
  t.check(cast(t,g,"henshin",free).ok,"HENSHIN casts with capture active")
  t.check(g.state.guard_bind.is_empty()==not free,"HENSHIN only release face clears capture")
  if not free:
   t.check(g.get_view().guard_bind.is_empty() and g._enemy(enemy.id).intent.kind=="bind_prepare","HENSHIN clears capture UI and makes guard prepare again")
 t.check(preload("res://data/balance.gd").card_info("henshin")[1].contains("拘束具与捕缚"),"HENSHIN printed release includes capture")


static func mana_invocation(t) -> void:
 for free in [false,true]:
  for initial_mana in [0.0,60.0,80.0,95.0,100.0]:
   var g=Game.new(42);g.state.mana=initial_mana
   var card=give(t,g,"mana_invocation")
   var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
   var before=g.export_snapshot()
   t.check(c.valid and c.cost==1 and c.mana==0 and g.Cards.uses_magic(c.payload),"INVOCATION either face is a one-energy zero-mana spell")
   t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"INVOCATION stale play changes no resources or card zones")
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==minf(g.state.mana_max,initial_mana+20) and g.state.energy==2,"INVOCATION restores twenty including at zero mana and respects the cap")
   t.check(g.state.exhaust.any(func(e):return e.uid==card.uid) and not g.state.hand.any(func(e):return e.uid==card.uid) and g.validate()=="","INVOCATION exhausts the actual card and preserves valid state")
 var g=Game.new(42);g.state.energy=0
 var card=give(t,g,"mana_invocation");var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"INVOCATION insufficient energy refuses atomically")
 g=Game.new(42);g.state.pressure=99;g.state.mana=40
 card=give(t,g,"mana_invocation")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.mana==40 and g.state.energy==2 and g.state.hand.any(func(x):return x.uid==card.uid) and g.state.exhaust.is_empty(),"INVOCATION failed spell keeps card and pays without restoring mana")

static func reward_rules(t) -> void:
 # Exhaust every percentile once, rather than a noisy frequency test.
 for sample in [["normal",-5,0,35,65],["normal",0,3,37,60],["elite",0,10,40,50],["boss",-5,100,0,0]]:
  var counts={"rare":0,"uncommon":0,"common":0}
  for roll in range(100): counts[Rewards.rarity(sample[0],sample[1],roll)]+=1
  t.check(counts.rare==sample[2] and counts.uncommon==sample[3] and counts.common==sample[4],"RARITY exact bands "+str(sample.slice(0,2)))
 t.check(Rewards.next_offset(-5,"common")==-4 and Rewards.next_offset(3,"uncommon")==3 and Rewards.next_offset(40,"common")==40 and Rewards.next_offset(20,"rare")==-5,"RARITY sequential correction, cap and rare reset")
 var g=Game.new(42);var twin=Game.new(42)
 var first=g.reward_offer(g.Cards.Rules.REWARDS,"normal")
 t.check(first==twin.reward_offer(twin.Cards.Rules.REWARDS,"normal") and g.state.rare_offset==twin.state.rare_offset,"RARITY actual offer and correction reproduce by seed")
 var expected=-5
 for type in first: expected=Rewards.next_offset(expected,g.Cards.Rules.SPECS[type].rarity)
 t.check(g.state.rare_offset==expected and first.size()==3 and first.all(func(id):return first.count(id)==1),"RARITY updates on each generated card with unique choices")
 var snapshot=g.export_snapshot();var restored=Save.roundtrip(t,g,"rarity offset")
 if restored!=null: t.check(g.reward_offer(g.Cards.Rules.REWARDS,"normal")==restored.reward_offer(restored.Cards.Rules.REWARDS,"normal"),"RARITY next offer survives save/load")
 var offset=g.state.rare_offset
 g.reward_offer(g.Cards.Rules.COMMON)
 t.check(g.state.rare_offset==offset,"RARITY explicit event pools do not change correction")
 var boss=g.reward_offer(g.Cards.Rules.REWARDS,"boss")
 t.check(boss.size()==3 and boss.all(func(id):return g.Cards.Rules.SPECS[id].rarity=="rare") and g.state.rare_offset==-5,"RARITY boss gives three distinct rare cards and resets offset")
 snapshot.rare_offset=41;var before=g.export_snapshot()
 t.check(not g.restore_snapshot(snapshot).ok and g.state==before,"RARITY malformed correction rejected atomically")

static func pot_of_greed(t) -> void:
 var type="pot_of_greed"
 for free in [false,true]:
  var g=Game.new(42);g._discard_end();g.state.mana=0;g.state.pressure=99
  g.add_fixture("mouth",10);g.add_fixture("palm",10);g.add_fixture("fingers",10)
  var card=preload("res://tests/curse_cases.gd").give(g,type)
  var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
  var before=g.export_snapshot()
  t.check(c.valid and c.cost==0 and c.mana==0 and g.Cards.Rules.SPECS[type].rarity=="uncommon" and type in g.Cards.Rules.UNCOMMON and type not in g.Cards.Rules.COMMON,"POT either zero-cost uncommon skill face works without mana or usable hands and mouth")
  t.check(not g.Cards.Rules.distinct_faces(type) and g.B.card_info(type)[1].contains("抽牌2。") and g.B.card_info(type)[2].contains("抽牌2。") and g.B.card_info(type)[1].contains("消耗") and g.B.card_info(type)[2].contains("消耗"),"POT identical faces share draw and exhaust text and do not qualify for distinct-face replay")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"POT stale card request preserves state and deck order")
  var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
  t.check(result.ok and g.state.hand.size()==2 and g.state.draw.size()==before.draw.size()-2 and g.state.energy==before.energy,"POT either face preserves energy and draws exactly two actual cards")
  t.check(g.state.mana==0 and g.state.rng.magic==before.rng.magic and g.state.equipment==before.equipment and not g.state.discard.any(func(x):return x.uid==card.uid) and g.state.exhaust.any(func(x):return x.uid==card.uid),"POT exhausts the used card without spell roll or equipment change")
  var transfers=result.card_feedback.map(func(event):return event.kind)
  t.check(transfers.size()==3 and transfers.slice(0,2)==["draw","draw"] and transfers[2]=="play_exhaust","POT resolves both draws before moving the used card to exhaust")
 var g=Game.new(42);g._discard_end()
 for i in range(9): preload("res://tests/curse_cases.gd").give(g,"slip")
 var card=preload("res://tests/curse_cases.gd").give(g,type)
 var before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.hand.size()==10 and g.state.draw.size()==before.draw.size()-1,"POT playing from full hand opens one slot and only draws to ten")
 g=Game.new(42);g._discard_end();card=preload("res://tests/curse_cases.gd").give(g,type);g.state.energy=0
 before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.energy==0 and g.state.hand.size()==2 and g.state.exhaust.any(func(x):return x.uid==card.uid),"POT remains playable at zero energy and exhausts after drawing")
