extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Witch=preload("res://tests/witch_character_cases.gd")
const TYPE="endless_war_goddess"

static func fresh(witch: bool=false):
 var g=Witch.fresh() if witch else Game.new(42)
 g._discard_end()
 for enemy in g.state.enemies: enemy.hp=1000;enemy.max_hp=1000
 return g

static func activate(t,g,free: bool=true) -> Dictionary:
 var card=Cards.give(g,TYPE)
 g.state.energy=3;g.state.mana=35;g.state.temporary_mana=15;g.state.pressure=0
 var before=g.export_snapshot();var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
 t.check(c.valid and c.cost==3 and c.mana==50 and c.mana_payment.mana==35 and c.mana_payment.temporary_mana==15,"WAR GODDESS pays all personal and temporary mana at exactly fifty")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"WAR GODDESS stale payment rolls back both mana pools")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==0 and g.state.temporary_mana==0 and g.state.energy==0 and g.state.powers.any(func(v):return v.uid==card.uid),"WAR GODDESS successful cast consumes all mana and enters power zone")
 t.check(g.get_view().speech.text=="无尽战神,出来!","WAR GODDESS successful play uses dedicated spoken cue")
 return card

static func run(t) -> void:
 for witch in [false,true]:
  for free in [false,true]:
   var g=fresh(witch);var card=Cards.give(g,TYPE)
   t.check(TYPE in g.Character.pool(g,g.Cards.Rules.RARE),"WAR GODDESS rare card is available to both characters")
   g.state.mana=34.99;g.state.temporary_mana=15;g.state.flask_mana=999
   var before=g.export_snapshot()
   t.check(not t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.state==before,"WAR GODDESS less than fifty rejects without using bottle mana")
   g.state.mana=50;g.state.temporary_mana=30
   var mouth=g.add_fixture("mouth",1);g.state.sure_cast=true
   before=g.export_snapshot()
   t.check(not t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.state==before,"WAR GODDESS any mouth restraint blocks even guaranteed casting")
   mouth.durability=0;g._cleanup();g.state.sure_cast=false
   var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
   t.check(c.mana==80 and g.cast_view(g.Cards.cast_profile(g,TYPE)).part=="mouth","WAR GODDESS spends more than the minimum and casts through the mouth")
   g.state.relics.append("intellect_cloak")
   t.check(t.find_action(g,"card",{"uid":card.uid,"free":free}).mana==80,"WAR GODDESS all-mana payment cannot be reduced by a card mana discount relic")
   g=fresh(witch);activate(t,g,free)
   if witch: witch_attacks(t,g)
   else: original_attacks(t,g)
 var g=fresh();var card=Cards.give(g,TYPE)
 g.state.mana=50;g.state.temporary_mana=20;g.state.pressure=95
 var failed=t.find_action(g,"card",{"uid":card.uid,"free":true})
 t.check(failed.valid and g.cast_view(g.Cards.cast_profile(g,TYPE)).chance<1 and g.dispatch(g.command(failed.payload,g.state.version),g.state.version).ok and not g.Cards.basic_attack_freedom(g) and g.state.mana==25 and g.state.temporary_mana==10 and g.state.hand.any(func(v):return v.uid==card.uid),"WAR GODDESS failed activation retains card and follows normal half refund")
 t.check(g.get_view().speech.get("text","")!="无尽战神,出来!","WAR GODDESS failed activation does not announce successful transformation")
 var spec=g.Cards.Rules.SPECS[TYPE].duplicate(true);spec.all_mana_minimum=-1
 t.check(g.Cards.Rules.definition_reason(spec)!="","WAR GODDESS invalid all-mana threshold is rejected")
 var book=preload("res://data/encyclopedia.gd").card(TYPE)
 t.check(book.rarity=="rare" and book.cost=="3" and book.face_mana.free[0].text=="-X" and book.face_keywords.free.any(func(term):return term.name=="嘴部无拘束") and not book.face_keywords.free.any(func(term):return term.name=="各部位紧度＝0"),"WAR GODDESS catalog shows rare power, all-mana badge and exact mouth restriction")
 var locale=preload("res://ui/localization.gd").new();locale.set_locale("en_US")
 t.check(locale.display("无尽战神,出来!")=="Endless War Goddess, come forth!" and locale.display("自身与临时魔力合计至少需要50点。")=="Requires at least 50 combined personal and temporary mana.","WAR GODDESS localized cue and full dynamic payment requirement preserve meaning")

static func restrain(g) -> void:
 g.state.energy=100;g.state.mana=100;g.state.temporary_mana=0;g.state.pressure=g.Pressure.maximum(g)-5;g.state.posture="lie"
 for slot in ["mouth","upper_arm","forearm","wrist","palm","fingers","thigh","calf","ankle","foot"]: g.add_fixture(slot,16)

static func original_attacks(t,g) -> void:
 restrain(g)
 var before=g.export_snapshot();var choices=g.command_facts().filter(func(c):return c.payload.kind=="attack" and c.payload.get("enemy","")==g.state.enemies[0].id)
 t.check(choices.size()==13 and choices.all(func(c):return c.valid) and g.state==before,"WAR GODDESS all original forms remain usable lying and heavily restrained; preview is read only")
 var kicks=choices.filter(func(c):return c.payload.type=="kick")
 t.check(kicks.map(func(c):return c.label)==["正义飞踢","横扫","站着踢","连续踢！","并拢飞踢","并腿蹬击","坐姿踢击","坐着踢"],"WAR GODDESS right-click facts include every posture and bound kick form")
 var fire=t.find_action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})
 t.check(g.cast_view(g.Cards.cast_profile(g,"fireball")).chance==1 and fire.payload.damage==g.B.FIREBALL_ASSISTED,"WAR GODDESS fireball ignores mouth and hand restraints plus pressure")
 var normal=Cards.give(g,"mana_invocation")
 t.check(g.cast_view(g.Cards.cast_profile(g,normal.type)).chance<1,"WAR GODDESS does not guarantee ordinary spell cards")
 t.check(t.action(g,"attack",{"type":"kick","form":4}).ok and not t.find_action(g,"attack",{"type":"kick","form":5},false).valid,"WAR GODDESS bound forms retain shared kick cooldown")
 t.check(g.dispatch(g.command(fire.payload,g.state.version),g.state.version).ok and t.action(g,"attack",{"type":"fireball"}).ok and not t.find_action(g,"attack",{"type":"fireball"},false).valid,"WAR GODDESS fireball retains its per-turn limit")
 t.check(t.action(g,"attack",{"type":"heavy"}).ok and not t.find_action(g,"attack",{"type":"heavy","form":1},false).valid,"WAR GODDESS close-strike forms retain shared once-per-turn use")
 var restored=fresh()
 t.check(restored.restore_snapshot(g.export_snapshot()).ok and restored.Cards.basic_attack_freedom(restored),"WAR GODDESS active effect survives current-format snapshot")
 g._finish_battle()
 t.check(not g.Cards.basic_attack_freedom(g) and g.BasicAttacks.forms(g,"kick").size()==4,"WAR GODDESS freedom ends immediately when combat finishes")
 g.RelicEffects.end_combat(g);g._start_battle()
 t.check(not g.Cards.basic_attack_freedom(g),"WAR GODDESS does not leak into the next battle")

static func witch_attacks(t,g) -> void:
 restrain(g);g.state.witch_charges.legs=4
 var choices=g.command_facts().filter(func(c):return c.payload.kind=="attack" and c.payload.enemy==g.state.enemies[0].id)
 t.check(choices.size()==8 and choices.all(func(c):return c.valid and c.casting.chance==1),"WAR GODDESS all witch preparation and release actions ignore restraint and pressure")
 for part in ["hand","mouth","mind","legs"]:
  t.check(t.action(g,"attack",{"type":"witch_"+part,"form":1}).ok and not t.find_action(g,"attack",{"type":"witch_"+part,"form":1},false).valid,"WAR GODDESS witch release keeps once-per-part limit: "+part)
 t.check(t.action(g,"attack",{"type":"witch_hand","form":0}).ok,"WAR GODDESS witch preparation remains available after release")
