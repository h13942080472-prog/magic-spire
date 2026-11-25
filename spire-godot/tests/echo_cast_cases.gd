extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func game():
 var g=Game.new(42);g._discard_end();g.state.energy=30;g.state.relics=[]
 return g

static func fire(t,g) -> Dictionary:
 return t.find_action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})

static func run(t) -> void:
 var g=game();g.state.enemies[0].hp=200;g.state.enemies[0].max_hp=200
 t.check(g.Cards.Rules.SPECS.echo_cast.rarity=="uncommon" and "echo_cast" in g.Cards.Rules.UNCOMMON and g.Cards.Rules.SPECS.fire_control.rarity=="uncommon" and not g.B.CARD_TRAITS.has("echo_cast"),"ECHO Echo Cast and Fire Control are uncommon, with no native Exhaust on Echo Cast")
 var defn=g.Cards.Rules.SPECS.echo_cast.duplicate(true)
 defn.self_faces.free.erase("cast")
 t.check(g.Cards.Rules.definition_reason(defn)!="","ECHO a casting skill must declare its casting face")
 defn=g.Cards.Rules.SPECS.echo_cast.duplicate(true);defn.self_faces.bound.when_spell_empty="unknown"
 t.check(g.Cards.Rules.definition_reason(defn)!="","ECHO rejects an unknown conditional spell")
 var card=Cards.give(g,"echo_cast")
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var before=g.export_snapshot()
 t.check(c.valid and c.cost==1 and c.mana==0 and g.Cards.Rules.face_casts("echo_cast",true) and not g.Cards.Rules.face_casts("echo_cast",false) and g.Cards.cast_profile(g,"echo_cast").parts==["mouth"],"ECHO only the free face casts through the mouth without mana")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and before==g.state,"ECHO stale activation is atomic")
 var original_damage=g.BasicAttacks.fireball_damage(g)
 t.check(Cards.play(t,g,"echo_cast",false).ok and g.BasicAttacks.fireball_damage(g)==original_damage,"ECHO remaining uses prevent the damage bonus")
 t.check(t.action(g,"attack",{"type":"fireball"}).ok,"ECHO spend the first Fireball use")
 t.check(g.dispatch(g.command(c.payload),g.state.version).ok and Cards.play(t,g,"echo_cast",true).ok and g.BasicAttacks.usage(g,"fireball").remaining==1 and g.Cards.Rules.type_tags("echo_cast",true)==["skill"],"ECHO two free-face skills stack without activating each other")
 t.check(t.action(g,"attack",{"type":"fireball"}).ok,"ECHO spend the remaining Fireball use")
 t.check(Cards.play(t,g,"echo_cast",false).ok and Cards.play(t,g,"echo_cast",false).ok and g.BasicAttacks.fireball_damage(g)==original_damage+10,"ECHO zero uses grants stacking battle damage")
 t.check(g.BasicAttacks.usage(g,"fireball").remaining==0,"ECHO Fireball and skill cards do not recover a use")
 g.state.pressure=99
 var failed=Cards.give(g,"mana_conversion")
 var chance=g.cast_view(g.Cards.cast_profile(g,failed.type)).winning_rolls
 var rng=g.state.rng.magic
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<chance: rng=g.state.rng.magic
 g.state.rng.magic=rng
 t.check(t.action(g,"card",{"uid":failed.uid,"free":false}).ok and g._magic_failed and g.BasicAttacks.usage(g,"fireball").remaining==0,"ECHO failed magic does not recharge")
 g.state.pressure=0
 t.check(t.action(g,"card",{"uid":failed.uid,"free":false}).ok and g.BasicAttacks.usage(g,"fireball").remaining==2,"ECHO successful magic restores two uses from two layers")
 t.check(Cards.play(t,g,"mana_invocation",false).ok and g.BasicAttacks.usage(g,"fireball").remaining==2 and fire(t,g).cost==0,"ECHO full recharge preserves cap and first-use payment history")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and "echo_recharge" not in g.state.card_buffs and g.BasicAttacks.fireball_damage(g)==original_damage+10,"ECHO recharge expires on turn end while damage remains")
 g._finish_battle()
 t.check("echo_firepower" not in g.state.card_buffs and g.BasicAttacks.fireball_damage(g)==original_damage,"ECHO damage expires at combat end")
 # Previously armed replays in older saves still resolve using their original rules.
 g=game()
 g.state.enemies[0].hp=100;g.state.enemies[0].max_hp=100
 g.Cards.grant_buff(g,"echo_cast_free");g.Cards.grant_buff(g,"echo_cast_free")
 before=g.export_snapshot();c=fire(t,g);var result=g.dispatch(g.command(c.payload),g.state.version)
 t.check(result.ok and g.state.combat.attack_uses.fireball==1 and "echo_cast_free" not in g.state.card_buffs,"ECHO legacy free stacks consume one use and resolve")
 t.check(g.BasicAttacks.successful_fireballs(g)==3 and g.live_card_text("boar_emperor_blaze").free=="蓄力3。","BLAZE successful replayed Fireballs count separately from turn uses")
 # Lethal casts never retarget the survivor or a new split child.
 g=game();g.Cards.grant_buff(g,"echo_cast_free");g.state.enemies[0].hp=1
 before=g.export_snapshot();result=g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.enemies[0].gone and g.state.enemies[1].hp==before.enemies[1].hp and g.state.logs.any(func(log):return log.data.get("replay",{}).get("skipped",false)),"ECHO lethal original skips repeat, survivor untouched")
 t.check(g.BasicAttacks.successful_fireballs(g)==1,"BLAZE a skipped replay adds no successful Fireball")
 # On-use powers see both actual casts; the turn bonus also applies to the replay.
 g=game();Cards.play(t,g,"wildfire_descent",false);g.Cards.grant_buff(g,"echo_cast_free")
 g.state.enemies[0].hp=100;g.state.enemies[0].max_hp=100
 g.state.card_buffs.append("embers_free");before=g.export_snapshot();c=fire(t,g)
 result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.hand.size()==before.hand.size()+2 and is_equal_approx(g.state.enemies[0].hp,before.enemies[0].hp-2*c.payload.damage) and "embers_free" in g.state.card_buffs,"ECHO both actual casts draw and keep the turn-wide embers bonus")
 g=game();Cards.play(t,g,"fire_dynamics",true);g.Cards.grant_buff(g,"echo_cast_free")
 before=g.export_snapshot();c=fire(t,g);result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 t.check(result.ok and range(g.state.enemies.size()).all(func(i):return is_equal_approx(g.state.enemies[i].hp,before.enemies[i].hp-2*c.payload.damage)),"ECHO area spell repeats once on each original enemy")
 # Excluded equal faces and free faces leave the next-bound-card effect intact.
 g=game();g.Cards.grant_buff(g,"echo_cast_bound")
 for type in ["mana_invocation","rekindle","wildfire_descent"]:
  t.check(not g.Cards.Rules.distinct_faces(type),"ECHO equal mechanical faces excluded: "+type)
 t.check(g.Cards.Rules.distinct_faces("pleasure_conversion"),"ECHO energy and temporary-mana conversion are distinct faces")
 t.check(Cards.play(t,g,"mana_invocation",false).ok and g.state.charge==0 and "echo_cast_bound" in g.state.card_buffs,"ECHO same-face spell neither repeats nor consumes")
 t.check(Cards.play(t,g,"strain",true).ok and "echo_cast_bound" in g.state.card_buffs,"ECHO free face does not consume bound replay")
 g.state.temporary_mana=0
 t.check(Cards.play(t,g,"fire_control",false).ok and g.state.temporary_mana==20 and "echo_cast_bound" not in g.state.card_buffs and g.state.discard.filter(func(v):return v.type=="fire_control").size()==1 and not g.state.exhaust.any(func(v):return v.type=="fire_control"),"ECHO bound control grants twice and discards physical card once")
 # Single-target damage and re-evaluated integer tightness; original UID only.
 g=game();var target=g.add_fixture("ankle",30,30);g.Cards.grant_buff(g,"echo_cast_bound")
 var uid=target.id;before=g.export_snapshot()
 t.check(Cards.play(t,g,"strain",false,{"target":uid}).ok,"ECHO bound targeted skill plays")
 var hits=g.state.logs.filter(func(log):return log.kind=="mechanical" and log.text.begins_with("「用力！」"))
 t.check(hits.size()==2 and g._equipment(uid).durability<30,"ECHO target hit resolves twice")
 # A persistent power is one real card with two applications of its numeric effect.
 g=game();g.Cards.grant_buff(g,"echo_cast_bound")
 t.check(Cards.play(t,g,"sympathetic_form",false).ok and g.state.powers.size()==1 and g.state.powers[0].power_stacks==2,"ECHO ability repeats without duplicating physical card")
 t.check(t.action(g,"end").ok and g.state.temporary_mana==20,"ECHO repeated turn-start ability really grants twice")
 var restored=Save.roundtrip(t,g,"ECHO repeated power current snapshot")
 t.check(restored!=null and restored.Cards.buff_stacks(restored,"sympathetic_form_bound")==2,"ECHO power repetition survives current snapshot")
 # Multiple original targets remain frozen across a real continuation and restore.
 g=game();var a=g.add_fixture("ankle",30,30,true);var b=g.add_fixture("ankle",30,30,true)
 g.Cards.grant_buff(g,"echo_cast_bound");t.check(Cards.play(t,g,"double_unlock",false,{"target":a.id}).ok,"ECHO multi-hit starts")
 t.check(not g.state.card_chain.is_empty() and g.state.card_chain.replay_targets.size()==1,"ECHO continuation stores first actual target")
 restored=Save.roundtrip(t,g,"ECHO pending multi-hit snapshot")
 if restored!=null:
  Save.step_both(t,g,restored,"chain",{"target":b.id})
 t.check(g.state.card_chain.is_empty() and g.validate()=="","ECHO original and replay complete without extra chain or card")
 # Failed card keeps the effect and original card; retry is the consuming play.
 g=game();g.Cards.grant_buff(g,"echo_cast_bound");g.state.pressure=99
 card=Cards.give(g,"mana_conversion");c=t.find_action(g,"card",{"uid":card.uid,"free":false});before=g.export_snapshot()
 result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 t.check(result.ok and g._magic_failed and "echo_cast_bound" in g.state.card_buffs and g.state.hand==before.hand,"ECHO failed casting leaves card and replay pending")
 # Pending effects persist across turns, but never across battle boundaries.
 g=game();g.Cards.grant_buff(g,"echo_cast_free");g.Cards.grant_buff(g,"echo_cast_bound")
 t.check(t.action(g,"end").ok and "echo_cast_free" in g.state.card_buffs and "echo_cast_bound" in g.state.card_buffs,"ECHO two faces coexist across turns")
 g.Cards.end_powers(g)
 t.check(g.state.card_buffs.is_empty(),"ECHO battle cleanup removes both pending effects")
 boundaries(t)

static func boundaries(t) -> void:
 var g=game();Cards.play(t,g,"flame_flourish",false);g.Cards.grant_buff(g,"echo_cast_free")
 var target=g.add_fixture("ankle",100,100)
 var c=t.find_action(g,"attack",{"type":"fireball","target":target.id})
 var before=g.export_snapshot();var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 t.check(result.ok and g._equipment(target.id).durability==100-2*c.payload.damage and g.state.combat.attack_uses.fireball==1 and g.state.mana==before.mana-c.mana,"ECHO equipment fireball repeats on same piece and pays once")
 g=game();Cards.play(t,g,"wildfire_descent",false);g.Cards.grant_buff(g,"echo_cast_free");g.state.pressure=99
 before=g.export_snapshot();c=fire(t,g);result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 var casts=g.state.logs.slice(before.logs.size()).filter(func(log):return log.data.get("spell",{}).get("type","")=="fireball")
 var successful_casts=casts.filter(func(log):return log.data.spell.success).size()
 t.check(result.ok and casts.size()==2 and successful_casts<2 and casts[0].data.spell.roll!=casts[1].data.spell.roll and g.state.hand.size()==before.hand.size()+successful_casts and is_equal_approx(g.state.mana,before.mana-c.mana*0.5),"ECHO two independent cast rolls, draw only on successful attempts, one payment")
 # Replaying the cut spends one use of the physical tool card.
 g=game();Cards.play(t,g,"practiced",true);g.Cards.grant_buff(g,"echo_cast_bound")
 target=g.add_fixture("thigh",100,100)
 var knife=t.take_item_card(g,"shard")
 var cut=t.action(g,"card",{"uid":knife,"target":target.id,"free":true})
 t.check(cut.ok and g.Cards.instance(g,knife).remove_left==2 and g.state.powers[0].power_cast_count==1 and is_equal_approx(g._equipment(target.id).durability,100.0-2*g.Tools.TYPES.shard.damage),"ECHO two cuts spend one tool use and count one physical play")
 # Destroyed outer target does not redirect to the newly exposed inner layer.
 g=game();var inner=g._install_template("belt","calf",30,30,false,"fixture",1,0,0,"mid_calf");var outer=g._install_template("belt","calf",0.1,10,false,"fixture",1,1,0,"mid_calf")
 g.Cards.grant_buff(g,"echo_cast_bound")
 t.check(Cards.play(t,g,"slip",false,{"target":outer.id}).ok and g._equipment(outer.id).is_empty() and g._equipment(inner.id).durability==30,"ECHO destroyed outer skips instead of hitting inner")
 # All original follow-through hits finish before replay; no new follow-through selection.
 g=game();target=g.add_fixture("ankle",1000,1000);g.Cards.grant_buff(g,"echo_cast_bound")
 var expected_hits=floori(g.BasicAttacks.fireball_damage(g))
 t.check(Cards.play(t,g,"boar_emperor_blaze",false,{"target":target.id}).ok and g.state.card_chain.is_empty(),"ECHO follow-through resolves both sequences atomically")
 t.check(g.state.logs.filter(func(log):return log.data.has("follow_through_hit")).size()==2*expected_hits,"ECHO original plus repeated Fireball-scaled hits on surviving original target")
 # A malformed new field cannot enter a live game through restore.
 g=game();g.Cards.grant_buff(g,"echo_cast_bound");Cards.play(t,g,"sympathetic_form",false);before=g.export_snapshot()
 var bad=before.duplicate(true);bad.powers[0].power_stacks="2"
 t.check(not g.restore_snapshot(bad).ok and g.state==before,"ECHO corrupt power repetition rejected atomically")
