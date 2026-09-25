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
 t.check(g.Cards.Rules.SPECS.echo_cast.rarity=="uncommon" and "echo_cast" in g.Cards.Rules.UNCOMMON and g.Cards.Rules.SPECS.fire_control.rarity=="uncommon" and not g.B.CARD_TRAITS.has("echo_cast"),"ECHO replay and control are uncommon with replay not exhausting")
 var card=Cards.give(g,"echo_cast");var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(c.valid and c.cost==1 and c.mana==0 and before==g.state,"ECHO one energy no casting preview is read only")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and before==g.state,"ECHO stale activation is atomic")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.discard.any(func(v):return v.uid==card.uid) and "echo_cast_free" in g.state.card_buffs,"ECHO free face arms and discards normally")
 t.check(Cards.play(t,g,"echo_cast",true).ok and g.state.card_buff_uses.echo_cast_free==2,"ECHO same pending face accumulates")
 before=g.export_snapshot();c=fire(t,g)
 var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.energy==before.energy-c.cost and g.state.mana==before.mana-c.mana and g.state.combat.attack_uses.fireball==1,"ECHO fireball repetition pays once and uses once")
 t.check(is_equal_approx(g.state.enemies[0].hp,before.enemies[0].hp-3*c.payload.damage) and g.state.enemies[1].hp==before.enemies[1].hp and "echo_cast_free" not in g.state.card_buffs,"ECHO triple damage to only original target and consumes buff")
 # Lethal casts never retarget the survivor or a new split child.
 g=game();Cards.play(t,g,"echo_cast",true);g.state.enemies[0].hp=1
 before=g.export_snapshot();result=g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.enemies[0].gone and g.state.enemies[1].hp==before.enemies[1].hp and g.state.logs.any(func(log):return log.data.get("replay",{}).get("skipped",false)),"ECHO lethal original skips repeat, survivor untouched")
 # On-use powers see both actual casts; the turn bonus also applies to the replay.
 g=game();Cards.play(t,g,"wildfire_descent",false);Cards.play(t,g,"echo_cast",true)
 g.state.enemies[0].hp=100;g.state.enemies[0].max_hp=100
 g.state.card_buffs.append("embers_free");before=g.export_snapshot();c=fire(t,g)
 result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.hand.size()==before.hand.size()+2 and is_equal_approx(g.state.enemies[0].hp,before.enemies[0].hp-2*c.payload.damage) and "embers_free" in g.state.card_buffs,"ECHO both actual casts draw and keep the turn-wide embers bonus")
 g=game();Cards.play(t,g,"fire_dynamics",true);Cards.play(t,g,"echo_cast",true)
 before=g.export_snapshot();c=fire(t,g);result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 t.check(result.ok and range(g.state.enemies.size()).all(func(i):return is_equal_approx(g.state.enemies[i].hp,before.enemies[i].hp-2*c.payload.damage)),"ECHO area spell repeats once on each original enemy")
 # Excluded equal faces and free faces leave the next-bound-card effect intact.
 g=game();Cards.play(t,g,"echo_cast",false)
 for type in ["mana_invocation","rekindle","wildfire_descent","pleasure_conversion"]:
  t.check(not g.Cards.Rules.distinct_faces(type),"ECHO equal mechanical faces excluded: "+type)
 t.check(Cards.play(t,g,"mana_invocation",false).ok and g.state.charge==0 and "echo_cast_bound" in g.state.card_buffs,"ECHO same-face spell neither repeats nor consumes")
 t.check(Cards.play(t,g,"strain",true).ok and "echo_cast_bound" in g.state.card_buffs,"ECHO free face does not consume bound replay")
 g.state.temporary_mana=0
 t.check(Cards.play(t,g,"fire_control",false).ok and g.state.temporary_mana==20 and "echo_cast_bound" not in g.state.card_buffs and g.state.discard.filter(func(v):return v.type=="fire_control").size()==1 and not g.state.exhaust.any(func(v):return v.type=="fire_control"),"ECHO bound control grants twice and discards physical card once")
 # Single-target damage and re-evaluated integer tightness; original UID only.
 g=game();var target=g.add_fixture("ankle",30,30);Cards.play(t,g,"echo_cast",false)
 var uid=target.id;before=g.export_snapshot()
 t.check(Cards.play(t,g,"strain",false,{"target":uid}).ok,"ECHO bound targeted skill plays")
 var hits=g.state.logs.filter(func(log):return log.kind=="mechanical" and log.text.begins_with("「用力！」"))
 t.check(hits.size()==2 and g._equipment(uid).durability<30,"ECHO target hit resolves twice")
 # A persistent power is one real card with two applications of its numeric effect.
 g=game();Cards.play(t,g,"echo_cast",false)
 t.check(Cards.play(t,g,"adaptability",false).ok and g.state.powers.size()==1 and g.state.powers[0].power_stacks==2,"ECHO ability repeats without duplicating physical card")
 t.check(t.action(g,"end").ok and g.state.charge==2,"ECHO repeated turn-start ability really grants twice")
 var restored=Save.roundtrip(t,g,"ECHO repeated power current snapshot")
 t.check(restored!=null and restored.Cards.buff_stacks(restored,"adaptability_bound")==2,"ECHO power repetition survives current snapshot")
 # Multiple original targets remain frozen across a real continuation and restore.
 g=game();var a=g.add_fixture("ankle",30,30,true);var b=g.add_fixture("ankle",30,30,true)
 Cards.play(t,g,"echo_cast",false);t.check(Cards.play(t,g,"double_unlock",false,{"target":a.id}).ok,"ECHO multi-hit starts")
 t.check(not g.state.card_chain.is_empty() and g.state.card_chain.replay_targets.size()==1,"ECHO continuation stores first actual target")
 restored=Save.roundtrip(t,g,"ECHO pending multi-hit snapshot")
 if restored!=null:
  Save.step_both(t,g,restored,"chain",{"target":b.id})
 t.check(g.state.card_chain.is_empty() and g.validate()=="","ECHO original and replay complete without extra chain or card")
 # Failed card keeps the effect and original card; retry is the consuming play.
 g=game();Cards.play(t,g,"echo_cast",false);g.state.pressure=99
 card=Cards.give(g,"mana_conversion");c=t.find_action(g,"card",{"uid":card.uid,"free":false});before=g.export_snapshot()
 result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 t.check(result.ok and g._magic_failed and "echo_cast_bound" in g.state.card_buffs and g.state.hand==before.hand,"ECHO failed casting leaves card and replay pending")
 # Pending effects persist across turns, but never across battle boundaries.
 g=game();Cards.play(t,g,"echo_cast",true);Cards.play(t,g,"echo_cast",false)
 t.check(t.action(g,"end").ok and "echo_cast_free" in g.state.card_buffs and "echo_cast_bound" in g.state.card_buffs,"ECHO two faces coexist across turns")
 g.Cards.end_powers(g)
 t.check(g.state.card_buffs.is_empty(),"ECHO battle cleanup removes both pending effects")
 boundaries(t)

static func boundaries(t) -> void:
 var g=game();Cards.play(t,g,"flame_flourish",false);Cards.play(t,g,"echo_cast",true)
 var target=g.add_fixture("ankle",100,100)
 var c=t.find_action(g,"attack",{"type":"fireball","target":target.id})
 var before=g.export_snapshot();var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 t.check(result.ok and g._equipment(target.id).durability==100-2*c.payload.damage and g.state.combat.attack_uses.fireball==1 and g.state.mana==before.mana-c.mana,"ECHO equipment fireball repeats on same piece and pays once")
 g=game();Cards.play(t,g,"wildfire_descent",false);Cards.play(t,g,"echo_cast",true);g.state.pressure=99
 before=g.export_snapshot();c=fire(t,g);result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 var casts=g.state.logs.slice(before.logs.size()).filter(func(log):return log.data.get("spell",{}).get("type","")=="fireball")
 var successful_casts=casts.filter(func(log):return log.data.spell.success).size()
 t.check(result.ok and casts.size()==2 and successful_casts<2 and casts[0].data.spell.roll!=casts[1].data.spell.roll and g.state.hand.size()==before.hand.size()+successful_casts and is_equal_approx(g.state.mana,before.mana-c.mana*0.5),"ECHO two independent cast rolls, draw only on successful attempts, one payment")
 # Extra resolution never counts as a second skill or consumes a cutter twice.
 g=game();Cards.play(t,g,"letter_opener",true);Cards.play(t,g,"echo_cast",false)
 g.state.wall="normal";target=g.add_fixture("wrist",100,100,true)
 g._gain_tool("shard");var tool=g.state.items.back();tool.mount="hand_wall"
 t.check(Cards.play(t,g,"strain",false,{"target":target.id}).ok and g._item(tool.id).uses==2 and g.state.powers[0].power_progress==2,"ECHO repeated damage keeps tool and skill count per physical card")
 # Destroyed outer target does not redirect to the newly exposed inner layer.
 g=game();var inner=g._install_template("belt","calf",30,30,false,"fixture",1,0,0,"mid_calf");var outer=g._install_template("belt","calf",0.1,10,false,"fixture",1,1,0,"mid_calf")
 Cards.play(t,g,"echo_cast",false)
 t.check(Cards.play(t,g,"slip",false,{"target":outer.id}).ok and g._equipment(outer.id).is_empty() and g._equipment(inner.id).durability==30,"ECHO destroyed outer skips instead of hitting inner")
 # All original follow-through hits finish before replay; no new follow-through selection.
 g=game();target=g.add_fixture("ankle",100,100);Cards.play(t,g,"echo_cast",false)
 t.check(Cards.play(t,g,"boar_emperor_blaze",false,{"target":target.id}).ok and g.state.card_chain.is_empty(),"ECHO follow-through resolves both sequences atomically")
 t.check(g.state.logs.filter(func(log):return log.data.has("follow_through_hit")).size()==10,"ECHO five original plus five repeated hits on surviving original target")
 # A malformed new field cannot enter a live game through restore.
 g=game();Cards.play(t,g,"echo_cast",false);Cards.play(t,g,"adaptability",false);before=g.export_snapshot()
 var bad=before.duplicate(true);bad.powers[0].power_stacks="2"
 t.check(not g.restore_snapshot(bad).ok and g.state==before,"ECHO corrupt power repetition rejected atomically")
