extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func count(g) -> int:
 return g.physical_pieces().size()+g.state.links.size()

static func run(t) -> void:
 var g=Game.new(42,true,"rope_serpent_solo")
 var id=g.state.enemies[0].id
 t.action(g,"end")
 t.check(count(g)==0 and g._enemy(id).turn_install_layers==1 and g._enemy(id).intent.kind=="apply","SERPENT first constrict activates without an early pulse; empty reinforcement becomes lash")
 g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.action(g,"attack",{"type":"kick","form":2,"enemy":id})
 var twin=Save.roundtrip(t,g,"serpent delayed with active constrict")
 Save.step_both(t,g,twin,"end")
 t.check(count(g)==1 and g._enemy(id).stage==2 and g._enemy(id).turn_install_layers==1,"SERPENT interrupted action preserves branch but passive end pulse still installs")
 Save.step_both(t,g,twin,"end")
 t.check(count(g)==4 and g._enemy(id).intent.kind=="turn_install","SERPENT resumed lash applies two after one passive pulse then returns to constrict")
 Save.step_both(t,g,twin,"end")
 t.check(count(g)==5 and g._enemy(id).turn_install_layers==2,"SERPENT existing one-layer pulse precedes new layer acquisition")
 var before=g.export_snapshot();var bad=before.duplicate(true);bad.enemies[0].turn_install_layers=-1
 t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==before,"SERPENT invalid saved layer count rejects atomically")

 # Both random branches use actual installed targets; previews do not redraw the branch.
 # This directed two-branch check needs its full seed matrix even in daily mode;
 # the shared material-cycle sample does not cover both serpent actions.
 var branches={}
 for seed in t.Selection.seeds("enemy_cycle",true):
  g=Game.new(seed,true,"rope_serpent_solo");id=g.state.enemies[0].id
  g.add_fixture("wrist",4,10,false,0,"rope")
  t.action(g,"end")
  var plan=g._enemy(id).intent.duplicate(true);branches[plan.kind]=true
  before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(g.export_snapshot()==before and not plan.has("target"),"SERPENT random branch freezes without choosing a concrete target")
 t.check(branches.has("apply") and branches.has("tighten"),"SERPENT equal-weight branch selector reaches both actions")
 # Remove the last reinforcement target after its declaration; also make the passive source inactive.
 g=Game.new(42,true,"rope_serpent_solo");id=g.state.enemies[0].id
 var piece=g.add_fixture("wrist",4,10,false,0,"rope")
 g._enemy(id).stage=2;g._enemy(id).intent={"kind":"tighten","text":"收紧","delayed":false,"tier":3,"random_target":true}
 piece.durability=0;g._cleanup();t.action(g,"end")
 t.check(count(g)==0 and g._enemy(id).stage==3,"SERPENT announced reinforcement with no surviving target misses without fallback")

 # Source isolation and source death: no pending installs from the defeated snake.
 g=Game.new(42,true,"rope_serpent_solo");id=g.state.enemies[0].id
 var other=g._append_enemies([{"type":"rope_serpent","grade":2}])[0];var other_id=other.id
 other.intent=g._plan(other);t.action(g,"end")
 g._enemy(id).hp=1;t.action(g,"attack",{"type":"strike","enemy":id})
 t.check(not g._enemy(id).has("turn_install_layers") and g._enemy(other_id).turn_install_layers==1,"SERPENT source death removes only its own layers")
 t.action(g,"end")
 t.check(count(g)==3 and g.physical_pieces().all(func(x):return x.source==other_id),"SERPENT surviving source alone continues its pulse and lash")

 # Enemy-first order still pulses only at the end of the player's own turn.
 g=Game.new(42,true,"rope_serpent_solo");g.state.posture="lie";g._start_battle();id=g.state.enemies[0].id
 t.check(count(g)==0 and g._enemy(id).turn_install_layers==1,"SERPENT enemy-first constrict does not fire before player actions")
 t.action(g,"end")
 t.check(count(g)==3,"SERPENT enemy-first player end pulses once before the next enemy action")
