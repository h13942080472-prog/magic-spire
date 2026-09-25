extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")

static func setup(count: int=0):
 var g=preload("res://tests/confluence_cases.gd").setup();g.state.relics=[];g.state.energy=20
 for slot in g.B.SLOTS.slice(0,count): g.add_fixture(slot,8)
 return g

static func run(t) -> void:
 var g=setup();var spec=g.Cards.Rules.SPECS.binding_power
 t.check(spec.rarity=="common" and "binding_power" in g.Cards.Rules.COMMON and g.Cards.Rules.definition_reason(spec)=="","BIND POWER common dual-bound definition enters normal pool")
 var invalid=spec.duplicate(true);invalid.bound_modes=["self","slip"]
 t.check(g.Cards.Rules.definition_reason(invalid)!="","BIND POWER rejects mixed self and equipment modes")
 invalid=spec.duplicate(true);invalid.self_faces.free.worn_resource.resource="unknown"
 t.check(g.Cards.Rules.definition_reason(invalid)!="","BIND POWER worn resource registry rejects unknown resource")
 for count in range(10):
  for second in [false,true]:
   g=setup(count);var card=Give.give(g,"binding_power")
   var c=t.find_action(g,"card",{"uid":card.uid,"free":second});var before=g.export_snapshot()
   var expected=int(count/(4 if second else 2))
   var row=g.get_view().hand.filter(func(item):return item.uid==card.uid)[0]
   t.check(c.valid and c.cost==1 and c.mana==0 and c.payload.self_target and row.face_names=={"bound":"拘束1","free":"拘束2"} and not row.free_faces.bound and not row.free_faces.free,"BIND POWER both faces are one-energy noncasting bound self actions")
   t.check(g.Cards.face_text(g,"binding_power",second).contains("当前："+("获得%d层蓄力。" if second else "力量＋%d。") % expected) and g.state==before,"BIND POWER live preview includes formula and exact rounded gain without state writes")
   t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"BIND POWER stale submission cannot pay or grant")
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.RelicEffects.attribute(g,"strength")==(0 if second else expected) and g.state.charge==(expected if second else 0) and g.state.energy==19 and g.state.exhaust.any(func(item):return item.uid==card.uid) and g.state.rng.magic==before.rng.magic,"BIND POWER actual odd and even counts grant exact resource and exhaust once: "+str([count,second]))
 for second in [false,true]:
  g=setup(4);var card=Give.give(g,"binding_power");g.state.energy=0;var before=g.export_snapshot()
  t.check(not t.action(g,"card",{"uid":card.uid,"free":second}).ok and g.state==before,"BIND POWER insufficient energy is atomic")
  g=setup(4);g.Cards.grant_buff(g,"echo_cast_bound")
  t.check(Give.play(t,g,"binding_power",second).ok and g.state.energy==19 and g.RelicEffects.attribute(g,"strength")==(0 if second else 4) and g.state.charge==(2 if second else 0) and g.state.exhaust.size()==1,"BIND POWER both bound faces replay effect without repeated payment or card exhaustion")
  g=Game.new(42,true,"pressure");g.state.pressure_sources=[];g.state.pressure=0
  t.check(Give.play(t,g,"binding_power",second).ok,"BIND POWER second bound face remains usable when rest blocks free effects")
 g=setup();g.add_fixture("eyes",8);g._install_assembly("glove","short","fixture",2,1);g._install_special("vaginal_egg_low","special_3_a");g.add_fixture("ankle",8)
 t.check(g.Cards.worn_count(g)==4 and Give.play(t,g,"binding_power",true).ok and g.state.charge==1,"BIND POWER composite counts once and special equipment uses shared worn count")
 g=setup(4);Give.play(t,g,"binding_power",false);Give.play(t,g,"binding_power",true)
 var removed=g.state.equipment.back();removed.durability=0;g._cleanup()
 t.check(g.RelicEffects.attribute(g,"strength")==2 and g.state.charge==1 and g.Cards.face_text(g,"binding_power",true).contains("当前：获得0层蓄力。"),"BIND POWER equipment loss updates future gain without revoking granted resources")
 var copy=Game.new(42)
 t.check(copy.restore_snapshot(g.export_snapshot()).ok and copy.RelicEffects.attribute(copy,"strength")==2 and copy.state.charge==1 and copy.state.exhaust.size()==2,"BIND POWER save preserves effects and both exhausted cards")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.RelicEffects.attribute(g,"strength")==2 and g.state.charge==1 and g.Cards.buff_stacks(g,"binding_power_last")==2,"BIND POWER all strength stacks survive into the next player turn")
 t.check(copy.restore_snapshot(g.export_snapshot()).ok and copy.RelicEffects.attribute(copy,"strength")==2,"BIND POWER save preserves final-turn strength stacks")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.RelicEffects.attribute(g,"strength")==0 and g.state.strength==0 and g.state.charge==1,"BIND POWER strength expires at the next turn end while unused charge persists")
 duration_cases(t)
 var info=g.B.card_info("binding_power")
 t.check(info[1].contains("÷2") and info[2].contains("÷4") and not info[1].contains("当前：") and not info[2].contains("当前："),"BIND POWER catalog retains both formulas without inventing live counts")

static func duration_cases(t) -> void:
 var g=setup(4)
 var invalid=g.Cards.Rules.SPECS.binding_power.duplicate(true)
 invalid.self_faces.bound.worn_resource.erase("buff")
 t.check(g.Cards.Rules.definition_reason(invalid)!="","BIND POWER rejects strength gains without a registered stack buff")
 Give.play(t,g,"binding_power",false)
 var status=g.get_view().statuses.filter(func(row):return row.id=="power_binding_power_current")[0]
 t.check(status.duration=="下回合结束" and status.value=="力量＋2","BIND POWER status reports active strength and next-turn expiry")
 g.Cards.expire_turn_buffs(g)
 t.check(g.RelicEffects.attribute(g,"strength")==2,"BIND POWER bonus remains active during the enemy phase")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 var log_start=g.state.logs.size()
 t.check(t.action(g,"end").ok,"BIND POWER reaches next turn through official end action")
 t.check(not g.state.logs.slice(log_start).any(func(row):return row.text=="拘束就是力量！的本回合效果结束。"),"BIND POWER continuing strength must not announce expiry at next turn start")
 Give.play(t,g,"binding_power",false);Give.play(t,g,"confluence",false)
 t.check(g.RelicEffects.attribute(g,"strength")==6,"BIND POWER consecutive-turn grants coexist with ordinary turn strength")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.RelicEffects.attribute(g,"strength")==2 and g.state.turn_strength==0,"BIND POWER only the newer grant survives while old grant and confluence expire")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.RelicEffects.attribute(g,"strength")==0,"BIND POWER newer grant expires at its own next turn end")
 g=setup(4);g._start_preparation();Give.play(t,g,"binding_power",false)
 t.check(t.action(g,"finish_prepare").ok and g.RelicEffects.attribute(g,"strength")==0 and g.validate()=="","BIND POWER leaving preparation clears pending strength and saved counters")
