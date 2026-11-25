extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")

static func run(t) -> void:
 for first in ["pleading_face","sweat_smile"]: gift(t,first)
 equipment(t)
 resources(t)
 elite(t)

static func gift(t, first: String) -> void:
 var second="sweat_smile" if first=="pleading_face" else "pleading_face"
 var g=Game.new(42)
 g.RelicEffects.gain(g,first)
 t.check(g.state.deck.all(func(c):return c.type!="but_also"),"EMOJI one relic grants no card: "+first)
 var twin=Game.new(99)
 t.check(twin.restore_snapshot(g.export_snapshot()).ok,"EMOJI restore before second pickup")
 twin.RelicEffects.gain(twin,second)
 twin.RelicEffects.gain(twin,first)
 var gifts=twin.state.deck.filter(func(c):return c.type=="but_also")
 t.check(gifts.size()==1 and "but_also" not in twin.Cards.Rules.REWARDS,"EMOJI permanent exclusive pickup in either order")
 if gifts.is_empty(): return
 var uid=gifts[0].uid
 twin._start_battle()
 t.check(twin.state.hand.any(func(c):return c.uid==uid) and twin.Enchantments.has_trait(twin,gifts[0],"innate"),"EMOJI native innate deals the physical gift into the opening hand")
 t.check(twin.state.evasion==1 and twin.state.energy==twin.max_energy()+1,"EMOJI battle starts with evasion and extra energy")
 var save=twin.export_snapshot();var result=g.restore_snapshot(save)
 t.check(result.ok and g.state.deck.filter(func(c):return c.type=="but_also").size()==1,"EMOJI collection survives save without duplicate")
 var info=g.B.card_info("but_also")
 t.check([info[1],info[2]].all(func(side):return side.contains("固有") and side.contains("消耗")),"EMOJI metadata shows both native keywords on both faces")
 var free=first=="pleading_face"
 if not free: g.add_fixture("wrist",4)
 g.state.energy=0
 t.check(t.action(g,"card",{"uid":uid,"free":free}).ok and g.state.energy==1 and g.state.evasion==2,"EMOJI both faces grant one energy and dodge from zero energy")
 t.check(g.state.exhaust.any(func(c):return c.uid==uid) and g.state.deck.any(func(c):return c.uid==uid),"EMOJI physical card exhausts only for this encounter")
 g._start_battle()
 t.check(g.state.hand.any(func(c):return c.uid==uid),"EMOJI exhausted innate gift returns at next battle opening")

static func equipment(t) -> void:
 var g=Game.new(42)
 g.state.relics=["weary_face","rolling_eyes","fearful_face"]
 g.state.round=2
 var source=g.state.enemies[0].id
 var request={"kind":"install","template":"rope","slot":"wrist","tier":3,"grade":1}
 g.state.evasion=1
 var failed=g.Application.execute_concrete(g,request,source)
 t.check(failed.evaded==1 and not g.state.combat.has("first_enemy_restraint_round") and g.state.relic_pending.is_empty(),"EMOJI dodge preserves wear and first-enemy triggers")
 var own=g.Application.execute_concrete(g,request,"card",false,[],true)
 g.RelicEffects.flush(g)
 t.check(own.ok and g.equipment_tier(own.installed[0])==3 and g.state.charge==2,"EMOJI own actual restraint charges without reducing its tier")
 request.slot="ankle"
 var incoming=g.Application.execute_concrete(g,request,source)
 t.check(incoming.ok and g.equipment_tier(incoming.installed[0])==1,"EMOJI round two applies floor two before floor one")
 request.slot="thigh"
 var again=g.Application.execute_concrete(g,request,source);g.RelicEffects.flush(g)
 t.check(again.ok and g.equipment_tier(again.installed[0])==2 and g.state.charge==2,"EMOJI only round-two modifier repeats")
 g.state.round=3;request.slot="calf";request.tier=1
 incoming=g.Application.execute_concrete(g,request,source)
 t.check(incoming.ok and g.equipment_tier(incoming.installed[0])==1 and g.state.combat.first_enemy_restraint_round==3,"EMOJI next round resets first trigger and tier one stays one")
 g=Game.new(42);g.state.relics=["weary_face","fearful_face","rolling_eyes"];g.state.round=2
 g._install_template("restriction_collar","neck",1,1,true,"prison",3)
 var root=g._install_assembly("glove","short",g.state.enemies[0].id,2,3)
 g.RelicEffects.flush(g)
 t.check(not root.is_empty() and root.components.all(func(p):return g.equipment_tier(p)==1) and g.state.charge==2,"EMOJI composite takes one installation trigger, collar excluded")

static func resources(t) -> void:
 var g=Game.new(42)
 g.state.relics=["monocle_face","joy_face","money_face","hot_face"]
 g.state.energy=8
 t.check(Give.play(t,g,"but_also",true).ok and g.state.temporary_mana==0,"EMOJI skill play leaves first-power reward available")
 var played=Give.play(t,g,"practiced",true)
 t.check(played.ok and g.state.temporary_mana==12,"EMOJI first successful power grants two six-point reserve layers")
 Give.play(t,g,"practiced",true)
 t.check(g.state.temporary_mana==12 and g.temporary_mana_retention_limit()==24,"EMOJI power only triggers once and four layers retain 24 points")
 g.state.pressure=19
 t.check(Give.play(t,g,"pleasure_conversion",true).ok and g.state.temporary_mana==18,"EMOJI whole reserve layer from conversion uses six mana per layer")
 for phase in ["battle","prepare","rest","prison"]:
  g.state.phase=phase
  t.check(g.ManaFlask.limit(g,"deposit")=={"battle":4,"prepare":4,"rest":0,"prison":2}[phase] and g.ManaFlask.limit(g,"withdraw")==int(phase=="battle")*4,"EMOJI restricted flask operations gain one use: "+phase)
 g.state.phase="battle";g.state.pressure=0
 g.Pressure.gain(g,1,"测试来源");g.Pressure.gain(g,0,"测试来源");g.Pressure.lose(g,1)
 t.check(g.state.pressure==2,"EMOJI flat pressure applies only to positive gains")

static func elite(t) -> void:
 var g=Game.new(42)
 g.RelicEffects.gain(g,"cool_face");g.RelicRewards.battle_drop(g)
 t.check(g.state.get("bonus_relic_drop","")=="","EMOJI ordinary encounter has no extra drop")
 g.state.room_encounters[g.state.room]="guard_solo"
 g._finish_battle()
 var first=g.state.battle_relic_drop;var second=g.state.bonus_relic_drop
 t.check(first!="" and second!="" and first!=second,"EMOJI elite freezes two distinct relic offers")
 var rows=g.get_view().battle_rewards.filter(func(row):return row.category=="relic")
 t.check(rows.size()==2 and rows[0].action_keys!=rows[1].action_keys and rows[0].skip_key!=rows[1].skip_key,"EMOJI UI offers independent claim and skip actions")
 var before=g.export_snapshot()
 t.check(t.action(g,"reward",{"category":"bonus_relic","type":second}).ok and second in g.state.relics and first not in g.state.relics,"EMOJI extra relic can be claimed first")
 var twin=Game.new(42)
 t.check(twin.restore_snapshot(g.export_snapshot()).ok and t.action(twin,"reward_skip",{"category":"relic"}).ok and twin.state.reward_claimed.bonus_relic==second,"EMOJI saved extra claim and ordinary skip independent")
 t.check(g.restore_snapshot(before).ok and t.action(g,"reward_skip",{"category":"bonus_relic"}).ok and t.action(g,"reward",{"category":"relic","type":first}).ok,"EMOJI extra skip and ordinary claim independent")
 var invalid=before.duplicate(true);invalid.bonus_relic_drop=9
 t.check(not g.restore_snapshot(invalid).ok and first in g.state.relics,"EMOJI malformed extra slot rejected atomically")
 g._start_battle()
 t.check(g.state.bonus_relic_drop=="" and g.restore_snapshot(g.export_snapshot()).ok,"EMOJI starting a fresh battle clears both reward slots")
 g.state.relics=g.Relics.REWARDS.duplicate()
 g.state.relics.append("cool_face")
 g.state.room_encounters[g.state.room]="guard_solo"
 g.RelicRewards.battle_drop(g)
 t.check(g.state.battle_relic_drop!=g.state.bonus_relic_drop and [g.state.battle_relic_drop,g.state.bonus_relic_drop].has(g.Relics.FALLBACK) and [g.state.battle_relic_drop,g.state.bonus_relic_drop].has(g.Relics.COMMON_FALLBACK),"EMOJI depleted pools use distinct collectible fallbacks")
 var legacy=Game.new(42).export_snapshot();legacy.erase("bonus_relic_drop")
 t.check(g.restore_snapshot(legacy).ok,"EMOJI previous saves load without bonus slot")
