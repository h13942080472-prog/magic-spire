extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Boss=preload("res://tests/boss_relic_cases.gd")

static func setup() -> RefCounted:
 var g=Game.new(42);Boss.boss_reward(g)
 g.state.boss_relic_options=["nesting_doll"]
 if "nesting_doll" not in g.state.relic_seen: g.state.relic_seen.append("nesting_doll")
 return g

static func run(t) -> void:
 var g=setup();var original=g.export_snapshot()
 t.check(t.action(g,"reward",{"category":"relic","type":"nesting_doll"}).ok,"BUNDLE official Boss pickup opens pending rewards")
 var entries=g.state.relic_bundle.entries.duplicate(true)
 t.check(g.state.relics==original.relics+["nesting_doll"] and entries.size()==3 and entries.map(func(e):return g.Relics.TYPES[e.type].rarity)==g.RelicRewards.TIERS,"BUNDLE freezes one relic per rarity without granting children")
 var frozen=g.export_snapshot();var view=g.get_view();g.get_view();g.command_facts()
 t.check(g.state==frozen and view.reward_panel.layout=="relic_bundle" and view.reward_panel.entries.size()==3,"BUNDLE read-only views and facts neither reroll nor grant rewards")
 var c=t.find_action(g,"relic_bundle",{"op":"claim","index":0})
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==frozen,"BUNDLE stale child claim rejects atomically")
 t.check(not t.action(g,"reward",{"type":"skip"}).ok and g.state==frozen,"BUNDLE parent rewards cannot bypass pending child decisions")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and entries[0].type in g.state.relics and g.state.relic_bundle.entries[0].status=="claimed","BUNDLE first child only granted on claim")
 var claimed=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==claimed,"BUNDLE cannot claim the same child twice")
 t.check(t.action(g,"relic_bundle",{"op":"skip","index":1}).ok and entries[1].type not in g.state.relics and g.state.relic_bundle.entries[1].status=="skipped","BUNDLE one skipped child leaves other child available")
 var saved=g.export_snapshot();var restored=Game.new(4)
 t.check(restored.restore_snapshot(saved).ok and restored.state.relic_bundle==g.state.relic_bundle,"BUNDLE mid-selection snapshot restores exact offers and claim status")
 var bad=saved.duplicate(true);bad.relic_bundle.entries[2].rarity="common"
 var before_bad=restored.export_snapshot()
 t.check(not restored.restore_snapshot(bad).ok and restored.state==before_bad,"BUNDLE damaged rarity rejects without replacing live state")
 t.check(t.action(g,"relic_bundle",{"op":"claim","index":2}).ok and entries[2].type in g.state.relics,"BUNDLE third reward remains claimable after skip")
 t.check(g.state.tick==original.tick and g.state.round==original.round and g.state.energy==original.energy and g.state.reward_options==original.reward_options and g.state.rng==frozen.rng,"BUNDLE child decisions consume no rounds energy or random rolls and preserve parent card offer")
 t.check(t.action(g,"relic_bundle",{"op":"finish"}).ok and g.state.relic_bundle.is_empty() and g.state.phase=="reward" and g.state.reward_claimed.relic=="nesting_doll","BUNDLE finish returns to existing parent reward state")
 t.check(t.action(g,"reward",{"category":"card","type":g.state.reward_options[0]}).ok,"BUNDLE parent card reward is still available")
 g=setup();t.action(g,"reward",{"category":"relic","type":"nesting_doll"});entries=g.state.relic_bundle.entries.duplicate(true)
 for i in range(3): t.check(t.action(g,"relic_bundle",{"op":"claim","index":i}).ok,"BUNDLE all three children may be claimed")
 t.check(entries.all(func(e):return e.type in g.state.relics),"BUNDLE full grant keeps original three-relic value")
 g=setup();t.action(g,"reward",{"category":"relic","type":"nesting_doll"});var owned=g.state.relics.duplicate()
 t.check(t.action(g,"relic_bundle",{"op":"finish"}).ok and g.state.relics==owned,"BUNDLE finish can discard all remaining children without granting them")
