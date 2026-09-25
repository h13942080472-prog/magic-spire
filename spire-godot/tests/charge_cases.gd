extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func gain(g, amount: int) -> void:
 g.Cards.apply_effects(g,[{"op":"charge","amount":amount}],{})

static func toggle(t,g) -> Dictionary:
 return t.action(g,"status_toggle",{"status":"charge"})

static func run(t) -> void:
 var g=Game.new(42)
 t.check(g.command_facts().all(func(c):return c.payload.kind!="status_toggle"),"CHARGE no mode action without stacks")
 gain(g,7)
 var before=g.export_snapshot()
 var stale=t.find_action(g,"attack",{"type":"strike","form":0,"enemy":g.state.enemies[0].id})
 t.check(toggle(t,g).ok and g.state.charge_all and g.charge_bonus()==21,"CHARGE right-click candidate arms all seven stacks")
 var after=g.export_snapshot()
 for key in ["version","logs","summary","charge_all"]: before.erase(key);after.erase(key)
 t.check(before==after,"CHARGE mode change preserves turn, resources, RNG, enemies, cards and equipment")
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(stale.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"CHARGE mode invalidates stale attack preview without consuming stacks")
 var c=t.find_action(g,"attack",{"type":"strike","form":0,"enemy":g.state.enemies[0].id})
 t.check(c.payload.damage==29 and c.brief.contains("29"),"CHARGE attack preview includes all stacks before normal multipliers")
 t.check(toggle(t,g).ok and not g.state.charge_all and g.charge_bonus()==3,"CHARGE toggling back restores one-stack mode without spending")
 for form in [0,1]:
  g=Game.new(42);gain(g,7);toggle(t,g)
  var enemy=g.state.enemies[0];enemy.hp=200;enemy.max_hp=200
  c=t.find_action(g,"attack",{"type":"strike","form":form,"enemy":enemy.id})
  var expected=c.payload.damage*c.payload.hits
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._enemy(enemy.id).hp==200-expected and g.state.charge==0 and not g.state.charge_all,"CHARGE basic attack keeps its existing multi-hit unit and consumes all only once")
 for type in ["strain","slip"]:
  g=Game.new(42);g.state.wall="normal"
  var target=g.add_fixture("ankle",60,100)
  gain(g,7);toggle(t,g)
  var card=t.hand_card(g,type)
  c=t.find_action(g,"card",{"uid":card.uid,"slot":"ankle","target":target.id})
  var damage=c.payload.preview.damage
  t.check(c.valid and c.payload.preview.charge==21 and g.escape_preview(target,type,5,[],true).charge==0,"CHARGE active preview uses all stacks while passive movement receives none: "+type)
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(target.id).durability,60-damage) and g.state.charge==0 and not g.state.charge_all,"CHARGE actual equipment damage matches all-stack preview: "+type)
 g=Game.new(42);g.state.wall="normal";gain(g,7);toggle(t,g)
 var multi_target=g.add_fixture("ankle",80,100)
 g._gain_card("repeated_strain")
 var multi_card=t.hand_card(g,"repeated_strain")
 var log_start=g.state.logs.size()
 t.check(t.action(g,"card",{"uid":multi_card.uid,"slot":"ankle","target":multi_target.id}).ok,"CHARGE multi-hit strain card resolves through the formal chain")
 var hits=g.state.logs.slice(log_start).filter(func(row):return row.data.has("follow_through_hit"))
 t.check(hits.size()==5 and hits[0].data.charge==21 and hits.slice(1).all(func(row):return row.data.charge==0) and g.state.charge==0,"CHARGE subsequent card hits recompute without reusing consumed stacks")
 g=Game.new(42,true,"guard");g.CaptureBind.apply_bind(g,g.state.enemies[0]);gain(g,7);toggle(t,g)
 var card=t.hand_card(g,"strain")
 c=t.find_action(g,"card",{"uid":card.uid,"target":g.CaptureBind.BIND_TARGET})
 t.check(c.valid and c.payload.preview.charge==21 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.charge==0 and not g.state.charge_all,"CHARGE capture damage uses the same all-stack consumer")
 g=Game.new(42);gain(g,3);toggle(t,g)
 t.check(t.action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id}).ok and g.state.charge==3 and g.state.charge_all,"CHARGE fireball leaves the prepared release untouched")
 g.state.energy=0;before=g.export_snapshot()
 c=t.find_action(g,"attack",{"type":"strike","enemy":g.state.enemies[0].id})
 t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"CHARGE unusable attack cannot spend stacks or disarm release")
 lifetime(t)

static func lifetime(t) -> void:
 var g=Game.new(42)
 t.check(g.Relics.TYPES.turtle_shell.rarity=="rare" and g.Relics.TYPES.turtle_shell.modifiers.combat_retention_layers==2 and "turtle_shell" in g.Relics.REWARDS,"SHELL remains a rare passive in the shared reward/shop pool")
 var excluded=g.Relics.REWARDS.filter(func(id):return g.Relics.TYPES[id].rarity=="rare" and id!="turtle_shell")
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,"rare",excluded)=="turtle_shell","SHELL shared rare reward selection can offer the relic")
 for shell in [false,true]:
  for phase in g.RelicEffects.COMBAT_PHASES:
   for amounts in [[0,0.0],[1,7.5],[2,20.0],[3,20.5],[27,1005.0]]:
    g=Game.new(42);g.state.relics=["turtle_shell"] if shell else [];g.state.phase=phase
    gain(g,amounts[0]);g.state.temporary_mana=amounts[1];g.state.charge_all=amounts[0]>0
    var expected_charge=mini(4 if shell else 2,amounts[0])
    var expected_mana=minf(30 if shell else 20,amounts[1])
    var before=g.export_snapshot()
    t.check(g.retained_charge()==expected_charge and g.retained_temporary_mana()==expected_mana and g.state==before,"RETENTION queries cap only carried balance and are read-only: "+phase)
    var control=Game.new(42);control.state=before.duplicate(true);control.state.charge=0;control.state.temporary_mana=0;control.state.charge_all=false
    control.RelicEffects.end_combat(control);g.RelicEffects.end_combat(g)
    t.check(g.state.charge==expected_charge and g.state.temporary_mana==expected_mana and g.state.charge_all==(expected_charge>0),"RETENTION zero/below/exact/above cap, both relic states and all session kinds: "+phase)
    var actual=g.export_snapshot();var baseline=control.export_snapshot()
    for key in ["charge","charge_all","temporary_mana"]: actual.erase(key);baseline.erase(key)
    t.check(actual==baseline,"RETENTION leaves unrelated cleanup, resources, cards, equipment and RNG unchanged: "+phase)
    before=g.export_snapshot();g.RelicEffects.end_combat(g)
    t.check(g.state==before,"RETENTION repeated session cleanup does not pay or grant twice")
 g=Game.new(42);gain(g,4);g.state.temporary_mana=35;g._finish_battle()
 t.check(g.state.charge==4 and g.state.temporary_mana==35,"RETENTION victory preserves both pools until preparation ends")
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare","RETENTION reward flow enters preparation")
 gain(g,3);g.Cards.apply_effects(g,[{"op":"reserve_mana","amount":3}],{})
 t.check(g.state.charge==7 and g.state.temporary_mana==50,"RETENTION gains remain uncapped during preparation")
 t.check(t.action(g,"finish_prepare").ok and g.state.charge==2 and g.state.temporary_mana==20,"RETENTION preparation applies the same carry caps")
 g.RelicEffects.gain(g,"turtle_shell")
 t.check(g.state.charge==2 and g.state.temporary_mana==20,"SHELL acquisition never restores discarded excess")
 g._start_preparation();gain(g,3);g.Cards.apply_effects(g,[{"op":"reserve_mana","amount":3}],{})
 t.check(t.action(g,"finish_prepare").ok and g.state.charge==4 and g.state.temporary_mana==30,"SHELL adds two layers to both retention caps")
 t.action(g,"depart",{"room":"east"})
 while g.state.phase=="travel": t.action(g,"travel_step")
 t.check(g.state.phase=="battle" and g.state.charge==4 and g.state.temporary_mana==30,"RETENTION survives travel and next combat opening")
 gain(g,2)
 t.check(t.action(g,"attack",{"type":"strike","form":0,"enemy":g.state.enemies[0].id}).ok and g.state.charge==5,"CHARGE ordinary attack consumes one carried or newly earned stack")
 var view=g.get_view()
 var status=view.statuses.filter(func(row):return row.id=="charge")[0]
 var mana_status=view.statuses.filter(func(row):return row.id=="temporary_mana")[0]
 var relic=view.relics.filter(func(row):return row.id=="turtle_shell")[0]
 t.check(status.duration.contains("最多保留4层") and mana_status.duration.contains("最多保留30点") and relic.current.contains("4层") and relic.current.contains("30点") and relic.detail.contains("各增加2层"),"SHELL status and relic descriptions cover both exact carried pools")
 g._finish_battle()
 t.check(g.state.charge==5 and g.state.temporary_mana==30,"SHELL battle-earned and preparation-earned balances both survive repeatedly")
 var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"both retained pools with turtle shell")
 t.check(restored!=null and restored.state.charge==5 and restored.state.temporary_mana==30,"RETENTION current snapshot restores both carried balances")
 t.action(g,"reward",{"type":"skip"});t.action(g,"finish_prepare")
 g._start_battle();g.state.enemies[0].hp=200;g.state.enemies[0].max_hp=200;gain(g,2);toggle(t,g)
 t.check(t.action(g,"attack",{"type":"strike","form":0,"enemy":g.state.enemies[0].id}).ok and g.state.charge==0 and not g.state.charge_all,"CHARGE full release consumes carried and newly earned stacks once and resets")
 gain(g,5);g.state.relics.erase("turtle_shell");g._finish_battle();t.action(g,"reward",{"type":"skip"});t.action(g,"finish_prepare")
 t.check(g.state.charge==2 and g.state.temporary_mana==20,"RETENTION losing relic restores both caps at the next ending")
 for shell in [false,true]:
  g=Game.new(42,true,"guard");g.state.relics=["turtle_shell"] if shell else []
  gain(g,7);g.state.temporary_mana=35;toggle(t,g)
  g.Guard.capture(g,g.state.enemies[0])
  t.check(g.state.phase=="captured" and g.state.charge==0 and g.state.temporary_mana==0 and not g.state.charge_all,"RETENTION existing incarceration reset still clears both pools regardless of relic")
