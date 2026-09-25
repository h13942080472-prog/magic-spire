extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func boss_reward(g) -> void:
 g.state.room="summit"
 g._start_battle()
 g._finish_battle()

static func run(t) -> void:
 preload("res://tests/cursed_plate_cases.gd").run(t)
 var g=Game.new(42)
 var size=g.state.deck.size()
 g.RelicEffects.gain(g,"tattoo_sticker")
 g.RelicEffects.gain(g,"shining_lamp")
 g.RelicEffects.gain(g,"shining_lamp")
 t.check(g.max_energy()==5 and g.state.mana_max==50 and g.state.mana==50 and g.state.deck.size()==size+2 and g.state.deck.filter(func(c):return c.type=="lewd_mark").size()==2,"BOSS pickups apply once, permanent curses and mana loss are real")
 for phase in ["battle","prepare","rest","prison"]:
  g=Game.new(42,true,"prison_test") if phase=="prison" else Game.new(42)
  g.RelicEffects.gain(g,"tattoo_sticker");g.RelicEffects.gain(g,"shining_lamp")
  match phase:
   "battle": g._start_battle()
   "prepare": g._start_preparation()
   "rest": g._start_rest();t.action(g,"rest_begin")
   "prison": g.Prison.enter(g)
  t.check(g.state.energy==5 and g.get_view().energy_max==5,"BOSS actual session refresh uses energy maximum: "+phase)
 g.state.next_energy=2;g.state.overload_energy=1;g.state.combat.energy=0
 g._begin_player_turn()
 t.check(g.state.energy==6 and g.state.next_energy==0,"BOSS energy maximum keeps existing preparation and overload arithmetic")
 g=Game.new(42);g.RelicEffects.gain(g,"nesting_doll")
 for i in range(3): t.action(g,"relic_bundle",{"op":"claim","index":i})
 for rarity in g.RelicRewards.TIERS:
  t.check(g.state.relics.filter(func(id):return id in g.Relics.REWARDS and g.Relics.TYPES[id].rarity==rarity).size()==1,"BOSS nesting doll grants one ordinary-pool relic of "+rarity)
 g=Game.new(42);g.state.relics.append_array(g.Relics.REWARDS);g.RelicEffects.gain(g,"nesting_doll")
 for i in range(3): t.action(g,"relic_bundle",{"op":"claim","index":i})
 t.check(g.state.relic_counters.get("rolling_log",0)==2 and g.state.relic_counters.get("intellect_cloak",0)==2,"BOSS empty pools grant one extra common cloak and two collectible logs")
 g=Game.new(42);g.RelicEffects.gain(g,"binding_pyramid")
 var kept=g.state.hand.duplicate(true);g._discard_end()
 t.check(g.state.hand==kept,"BOSS pyramid retains ordinary hand at turn end")
 g.RelicEffects.gain(g,"tattoo_sticker");var mark=t.hand_card(g,"lewd_mark");g._discard_end()
 t.check(g.state.hand.any(func(c):return c.uid==mark.uid),"BOSS pyramid also retains curse cards")
 pyramid_boundaries(t)
 mask(t)
 rewards(t)
 reward_pool(t)

static func reward_pool(t) -> void:
 for witch in [false,true]:
  var g=preload("res://tests/witch_character_cases.gd").fresh() if witch else Game.new(42)
  g.state.mana_max=g.B.MANA_MAX_FLOOR;g.state.mana=g.state.mana_max
  g.RelicEffects.gain(g,"binding_pyramid")
  var before=g.export_snapshot()
  var pool=g.RelicRewards.available(g,"boss")
  t.check(not pool.is_empty() and pool.all(func(id):return id in g.Relics.BOSS_POOL),"BOSS query selects boss definitions rather than ordinary rewards")
  t.check("binding_pyramid" not in pool and "shining_lamp" not in pool,"BOSS query excludes owned rewards and unaffordable mana reductions")
  t.check(("cursed_plate_lock" in pool)==(not witch),"BOSS query respects character equipment eligibility")
  pool.clear()
  t.check(g.state==before and not g.RelicRewards.available(g,"boss").is_empty(),"BOSS query and caller edits leave state, history, RNG and registry unchanged")
  var offered=g.RelicRewards.offer(g,"boss",null,g.Relics.BOSS_POOL.filter(func(id):return id!="shining_lamp"))
  t.check(offered==g.Relics.FALLBACK,"BOSS exclusion cannot offer an unaffordable remaining relic")
  g.state.relics.append_array(g.Relics.BOSS_POOL.filter(func(id):return id not in g.state.relics and id!="nesting_doll" and g.RelicEffects.gain_reason(g,id)==""))
  g.state.room="summit"
  g.RelicRewards.battle_drop(g)
  t.check(g.state.boss_relic_options==["nesting_doll"],"BOSS short pool freezes one eligible option without duplicates or filler")
  t.check(g.RelicRewards.offer(g,"boss")=="nesting_doll","BOSS single offer and battle options use the same eligibility")
  g.state.relics.append("nesting_doll")
  g.RelicRewards.battle_drop(g)
  t.check(g.state.boss_relic_options==[g.Relics.FALLBACK] and g.state.relic_seen.count(g.Relics.FALLBACK)==1,"BOSS exhausted eligible pool freezes one fallback and records it once")

static func pyramid_boundaries(t) -> void:
 for boundary in ["victory","prepare_early","prepare_last","rest_early","rest_last","prison_exit","prison_resist"]:
  var prison=boundary.begins_with("prison")
  var g=Game.new(42,true,"prison_test") if prison else Game.new(42)
  g.RelicEffects.gain(g,"binding_pyramid")
  if boundary.begins_with("prepare"):
   g._finish_battle();t.action(g,"reward",{"type":"skip"})
  elif boundary.begins_with("rest"):
   g._finish_battle();t.action(g,"reward",{"type":"skip"});t.action(g,"finish_prepare");g._start_rest();t.action(g,"rest_begin")
  if g.state.hand.size()==g.B.HAND_LIMIT: g.state.discard.append(g.state.hand.pop_back())
  g._gain_card("sensitive")
  var card=t.hand_card(g,"sensitive");card.retain_until=g.state.tick+20
  var uid=card.uid
  var deck=g.state.deck.duplicate(true)
  g._discard_end()
  t.check(g.state.hand.any(func(c):return c.uid==uid),"PYRAMID retains during the same session: "+boundary)
  match boundary:
   "victory":
    g._finish_battle()
    t.check(g.state.hand.any(func(c):return c.uid==uid),"PYRAMID victory retains hand for preparation")
    t.action(g,"reward",{"type":"skip"});t.action(g,"finish_prepare")
   "prepare_early": t.check(t.action(g,"finish_prepare").ok,"PYRAMID early preparation exit commits")
   "prepare_last": g.state.prepare_left=1;t.check(t.action(g,"end").ok,"PYRAMID final preparation turn commits")
   "rest_early": t.check(t.action(g,"finish_rest").ok,"PYRAMID early rest exit commits")
   "rest_last": g.state.rest_left=1;t.check(t.action(g,"end").ok,"PYRAMID final rest turn commits")
   "prison_exit": g.Prison.escape(g,"door")
   "prison_resist":
    g.state.phase="inspection";g.state.prison.stage="arrival";g.state.energy=0
    t.check(t.action(g,"prison",{"action":"resist"}).ok,"PYRAMID resisting starts a new session")
  var physical=[]
  for zone in ["hand","draw","discard","exhaust"]:
   physical.append_array(g.state[zone].filter(func(c):return c.uid==uid))
  t.check(g.state.deck==deck and physical.size()==1 and physical[0].retain_until==-1,"PYRAMID boundary clears retention without deleting or duplicating cards: "+boundary)
  if boundary!="prison_resist":
   t.check(g.state.hand.is_empty() and g.state.discard.any(func(c):return c.uid==uid),"PYRAMID session ends with cards in discard, not hand: "+boundary)

static func mask(t) -> void:
 var g=Game.new(42)
 for i in range(2): g._install_template("eye_leather","eyes",16,20,true,"fixture",2)
 g.RelicEffects.gain(g,"cursed_blindfold")
 var masks=g.equipment_at("eyes");var eye=masks[0]
 t.check(masks.size()==1 and eye.grade==3 and eye.locked and g.tier(eye.durability,eye.maximum)==3 and g.max_energy()==4,"BOSS cursed mask installs even with full eyes")
 var original=eye.duplicate(true)
 g._apply_equipment_damage(eye,999,"magic_slip");g._apply_manual_release(eye,0);g._cleanup()
 t.check(eye==original and g.escape_preview(eye,"magic_slip",999,[],false,true).damage==0,"BOSS cursed mask blocks direct and area damage plus manual removal")
 t.check(g.command_facts().filter(func(c):return c.payload.get("target","")==eye.id).all(func(c):return not c.valid and c.reason.contains("诅咒眼罩")),"BOSS eye facts cannot spend resources or alter the mask")
 t.check(g._install_template("eye_leather","eyes",20,20,false,"enemy",2).is_empty() and not g.Application.Replacement.plan(g,[{"kind":"install","template":"eye_leather","slot":"eyes","grade":3,"tier":3,"locked":true}],"enemy").ok,"BOSS eye installation and replacement are closed")
 var wrist=g.add_fixture("wrist",8)
 g._gain_card("henshin");var card=t.hand_card(g,"henshin")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g._equipment(wrist.id).is_empty() and g._equipment(eye.id)==original,"BOSS henshin removes ordinary gear and preserves cursed mask")
 var snapshot=g.export_snapshot();var restored=Game.new(2)
 t.check(restored.restore_snapshot(snapshot).ok,"BOSS permanent mask persists")
 var before_bad=restored.export_snapshot()
 var bad=snapshot.duplicate(true);bad.equipment=[]
 t.check(not restored.restore_snapshot(bad).ok and restored.state==before_bad,"BOSS missing permanent mask snapshot rejects atomically")
 preload("res://tests/demo_exit_cases.gd").exit_fixture(g)
 t.check(t.action(g,"demo_continue").ok and g._equipment(eye.id)==original,"BOSS continuation preserves permanent mask")

static func rewards(t) -> void:
 for selected in Game.Relics.BOSS_POOL:
  var g=Game.new(42);boss_reward(g)
  var options=g.state.boss_relic_options.duplicate()
  var snapshot=g.export_snapshot();var twin=Game.new(4)
  t.check(options.size()==3 and options.all(func(id):return options.count(id)==1 and id in g.Relics.BOSS_POOL) and twin.restore_snapshot(snapshot).ok and twin.state.boss_relic_options==options,"BOSS three unique relic choices persist without reroll")
  g.state.boss_relic_options=[selected]
  if selected not in g.state.relic_seen: g.state.relic_seen.append(selected)
  var cards=g.state.reward_options.duplicate()
  t.check(t.action(g,"reward",{"category":"relic","type":selected}).ok and selected in g.state.relics and g.state.reward_options==cards,"BOSS formal reward grants "+selected+" independently of cards")
  var after=g.export_snapshot()
  t.check(not t.action(g,"reward",{"category":"relic","type":selected}).ok and g.state==after and twin.restore_snapshot(after).ok,"BOSS reward cannot be collected twice and claimed snapshot restores")
  if selected=="nesting_doll": t.action(g,"relic_bundle",{"op":"finish"})
  t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.boss_relic_options.is_empty(),"BOSS leaving clears pending choices")
