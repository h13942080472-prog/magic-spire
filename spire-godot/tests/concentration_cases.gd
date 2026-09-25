extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")

static func setup() -> Dictionary:
 var g=Game.new(42);g.state.wall="normal";g.state.wall_distance=0
 var card=Give.give(g,"concentration")
 var target=g.add_fixture("ankle",400.0,1000.0)
 return {"g":g,"card":card,"target":target}

static func redraw(g, card: Dictionary) -> void:
 card=g.Cards.instance(g,card.uid)
 g.state.discard.erase(card);g.state.draw.erase(card)
 g.state.draw.push_back(card)
 g._draw(1)

static func run(t) -> void:
 var f=setup();var g=f.g;var card=f.card;var target=f.target
 t.check("concentration" in g.Cards.Rules.UNCOMMON and g.Cards.Rules.definition_reason(g.Cards.Rules.SPECS.concentration)=="","CONCENTRATION valid uncommon reward definition")
 var row=g.get_view().hand.filter(func(c):return c.uid==card.uid)[0]
 t.check(row.face_names=={"bound":"拘束1","free":"拘束2"} and not row.free_faces.free and row.bound.contains("挣扎6") and row.free.contains("滑脱6"),"CONCENTRATION both printed faces start at six and are bound effects")
 var twin=Give.give(g,"concentration")
 for second in [false,true]:
  var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":second},true)
  var before=g.export_snapshot();var damage=c.payload.preview.damage
  t.check(c.valid and c.cost==1 and c.payload.preview.base==(9 if second else 6) and c.payload.mode==("slip" if second else "strain"),"CONCENTRATION each face reuses its own damage preview and shared instance base")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(target.id).durability,before.equipment.filter(func(e):return e.id==target.id)[0].durability-damage),"CONCENTRATION actual target damage matches selected face")
  t.check(g.Cards.base_damage(g,card.type,card.uid)==(12 if second else 9) and g.Cards.base_damage(g,twin.type,twin.uid)==6 and g.state.mana==before.mana and g.state.rng.magic==before.rng.magic,"CONCENTRATION only the played physical card grows with no magic payment or roll")
  var after=g.export_snapshot()
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==after,"CONCENTRATION stale replay cannot grow or pay twice")
  redraw(g,card)
 var view=g.get_view()
 t.check(view.card_instances[card.uid].bound.contains("挣扎12") and view.card_instances[card.uid].free.contains("滑脱12") and g.live_card_text("concentration").bound.contains("挣扎6"),"CONCENTRATION live instance text differs from base catalog without changing its twin")
 var restored=Game.new(5)
 t.check(restored.restore_snapshot(g.export_snapshot()).ok and restored.Cards.base_damage(restored,card.type,card.uid)==12,"CONCENTRATION current-run restore preserves physical growth")
 var broken=g.export_snapshot();broken.hand.filter(func(c):return c.uid==card.uid)[0].damage_bonus=-4
 t.check(not restored.restore_snapshot(broken).ok,"CONCENTRATION invalid growth rejects atomically")
 g.RelicEffects.end_combat(g)
 t.check(g.Cards.base_damage(g,card.type,card.uid)==6 and g.state.deck.all(func(c):return not c.has("damage_bonus")),"CONCENTRATION session end clears live growth without touching permanent deck")
 f=setup();g=f.g;card=f.card;target=f.target
 g.state.phase="rest"
 t.check(t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":true},true).valid,"CONCENTRATION second bound face remains usable in rest")
 g.state.equipment.clear();var options=g.command_facts().filter(func(c):return c.payload.get("uid","")==card.uid)
 t.check(options.is_empty() and not g.get_view().hand.filter(func(c):return c.uid==card.uid)[0].availability.free.usable,"CONCENTRATION neither bound face offers an empty body target")
 f=setup();g=f.g;card=f.card;target=f.target
 target.durability=target.maximum
 var immune=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":true},true)
 t.check(immune.valid and immune.payload.preview.damage==0 and g.dispatch(g.command(immune.payload,g.state.version),g.state.version).ok and g.Cards.instance(g,card.uid).get("damage_bonus",0)==3,"CONCENTRATION legal zero-damage slip still counts as one use")
 f=setup();g=f.g;card=f.card;target=f.target
 g.Cards.grant_buff(g,"echo_cast_bound")
 var replay=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":true},true)
 var before=g.export_snapshot()
 t.check(g.dispatch(g.command(replay.payload,g.state.version),g.state.version).ok and g.Cards.instance(g,card.uid).get("damage_bonus",0)==6 and g.state.energy==before.energy-1 and "echo_cast_bound" not in g.state.card_buffs,"CONCENTRATION second bound face replays freely and both actual releases grow")
 var hits=g.state.logs.filter(func(log):return log.data.has("action_result") and log.data.has("base"))
 t.check(hits.size()==2 and hits[0].data.base==6 and hits[1].data.base==9 and hits.all(func(log):return log.data.action_result.contains("滑脱")),"CONCENTRATION replay preserves second-face type and recomputes the grown base")
 f=setup();g=f.g;card=f.card;target=f.target
 target.durability=0.5;g.Cards.grant_buff(g,"echo_cast_bound")
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and g.Cards.instance(g,card.uid).get("damage_bonus",0)==3 and g.state.logs.any(func(log):return log.data.get("replay",{}).get("skipped",false)),"CONCENTRATION missing original target skips replay and its growth")
