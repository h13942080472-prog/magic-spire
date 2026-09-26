extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func give(t,g) -> Dictionary:
 g._gain_card("fire_mastery")
 return t.hand_card(g,"fire_mastery")

static func fire(t,g) -> Dictionary:
 return t.find_action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})

static func run(t) -> void:
 preload("res://tests/formation_cases.gd").run(t)
 preload("res://tests/sympathetic_form_cases.gd").run(t)
 preload("res://tests/self_binding_cases.gd").run(t)
 reuse(t)
 preload("res://tests/resonance_cases.gd").run(t)
 preload("res://tests/cumulative_cards_cases.gd").run(t)
 preload("res://tests/practiced_cases.gd").run(t)
 stacking(t)
 preload("res://tests/card_music_cases.gd").run(t)
 preload("res://tests/restraint_embrace_cases.gd").run(t)
 preload("res://tests/card_text_cases.gd").run(t)
 preload("res://tests/mana_search_cases.gd").run(t)
 preload("res://tests/echo_cast_cases.gd").run(t)
 preload("res://tests/wildfire_descent_cases.gd").run(t)
 preload("res://tests/adaptability_cases.gd").run(t)
 preload("res://tests/fire_dynamics_cases.gd").run(t)
 preload("res://tests/flame_flourish_cases.gd").run(t)
 preload("res://tests/letter_opener_cases.gd").run(t)
 preload("res://tests/binding_enthusiast_cases.gd").run(t)
 var g=Game.new(42)
 var card=give(t,g)
 var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
 var before=g.export_snapshot()
 t.check(c.valid and c.cost==1 and c.mana==0 and c.payload.self_target,"POWER self-target one-energy candidate")
 g.get_view();g.command_facts()
 t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"POWER preview and stale submission preserve state")
 g.state.energy=0;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state==before,"POWER insufficient energy refuses atomically")
 g.state.energy=3
 var result=t.action(g,"card",{"uid":card.uid,"free":false})
 t.check(result.ok and g.state.energy==2 and g.state.mana==100 and g.state.powers[0].uid==card.uid and g.validate()=="","POWER actual play conserves card in ability zone and pays only energy")
 t.check(result.card_feedback.any(func(e):return e.kind=="play_power" and e.uid==card.uid) and g.get_view().statuses.any(func(e):return e.id=="power_fire_mastery_bound"),"POWER feedback and status reflect committed ability")
 t.check(fire(t,g).payload.damage==g.B.FIREBALL,"POWER free fingers no longer add gesture damage")
 var duplicate=give(t,g);before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":duplicate.uid,"free":false}).ok and g.state==before,"POWER duplicate refuses without discarding or paying")
 g._install_template("mouth_band","mouth",24.0,24.0,false,"fixture",3,0)
 g.add_fixture("fingers",8)
 g.state.posture="lie";g.state.pressure=75
 var profile=g.Cards.cast_profile(g,"fireball")
 t.check(is_equal_approx(g.cast_view(profile).chance,0.25) and g.cast_view(g.Cards.cast_profile(g,"ease")).chance==0 and fire(t,g).valid,"POWER only fireball ignores mouth equipment; pressure chance remains")
 var restored=Save.roundtrip(t,g,"active power")
 if restored!=null:
  Save.step_both(t,g,restored,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})
  t.check(g.state.powers.size()==1 and g.state.rng.magic==1,"POWER survives casting and uses original random domain")
 g.state.mana=0;before=g.export_snapshot()
 t.check(not t.action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id}).ok and g.state==before,"POWER does not bypass magic cost")
 g.state.mana=100;g.state.pressure=0;g.state.energy=3
 g._discard_end();g._draw(5)
 t.check(g.state.powers.size()==1 and not g.state.hand.any(func(x):return x.uid==card.uid) and g.validate()=="","POWER remains out of turn discard and reshuffle")
 var damaged=g.export_snapshot();damaged.powers.append(damaged.hand.pop_back());before=g.export_snapshot()
 t.check(not g.restore_snapshot(damaged).ok and g.state==before,"POWER damaged zone refuses restore atomically")
 for enemy in g.state.enemies: enemy.hp=1
 while g.state.phase=="battle":
  if g.BasicAttacks.usage(g,"fireball").remaining==0:
   t.action(g,"end")
   if g.state.phase!="battle": break
  g.state.energy=3;g.state.mana=100
  var target=g.state.enemies.filter(func(e):return not e.gone)[0]
  var shot=t.action(g,"attack",{"type":"fireball","enemy":target.id})
  t.check(shot.ok,"POWER finish encounter through real fireball")
  if not shot.ok: break
 t.check(g.state.phase=="reward" and g.state.powers.any(func(x):return x.uid==card.uid) and g.validate()=="","POWER victory preserves the active ability")
 t.check(t.action(g,"reward",{"type":"skip"}).ok and t.action(g,"finish_prepare").ok and g.state.powers.is_empty() and g.state.discard.any(func(x):return x.uid==card.uid),"POWER preparation end returns physical power card to discard")
 g=Game.new(42);card=give(t,g);t.action(g,"card",{"uid":card.uid,"free":false})
 g.Guard.capture(g,g.state.enemies[0])
 t.check(g.state.powers.is_empty() and g.validate()=="","POWER capture also clears battle ability")
 g=Game.new(42,true,"equipment");card=give(t,g);before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.powers.size()==1 and g.validate()=="","POWER bound face works during special battle")

 # Registry categories drive every acquisition list and projected face.
 for type in g.Cards.Rules.SPECS:
  var spec=g.Cards.Rules.SPECS[type]
  var face=preload("res://data/encyclopedia.gd").card(type)
  t.check(face.card_type==spec.card_type and face.rarity==spec.rarity and face.single_face==g.Cards.Rules.single_face(type),"CARD classification and single face projection "+type)
  var common_pool=spec.get("character_id","original")=="original" and spec.rarity in ["common","uncommon","rare"] and not spec.get("reward_excluded",false)
  t.check((type in g.Cards.Rules.REWARDS)==common_pool,"CARD common reward membership follows character, rarity and explicit gift exclusion "+type)
 for type in ["witch_mana_transfer","witch_patience","witch_endurance","witch_small_fry","witch_authority"]:
  t.check(g.Character.reward_member(g,type,"witch") and not g.Character.reward_member(g,type,"original") and type in g.Character.pool(g,g.Cards.Rules.REWARDS,"witch") and type not in g.Character.pool(g,g.Cards.Rules.REWARDS,"original"),"CARD witch-exclusive reward is offered only to its character "+type)

static func stacking(t) -> void:
 var helper=preload("res://tests/curse_cases.gd")
 for type in ["wildfire_descent","binding_enthusiast","restraint_embrace","adaptability","letter_opener","flame_flourish"]:
  for free in [false,true]:
   if type=="flame_flourish" and not free: continue
   var g=Game.new(42);g._discard_end();g.state.energy=30
   for copy in range(2):
    var card=helper.give(g,type)
    var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
    var before=g.export_snapshot();g.get_view();g.command_facts()
    t.check(c.valid and g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"STACK read-only and stale copy "+type)
    t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"STACK repeated paid activation "+type)
   var id=g.Cards.Rules.SPECS[type].self_faces["free" if free else "bound"].buff
   t.check(g.Cards.buff_stacks(g,id)==2 and g.state.powers.size()==2 and g.validate()=="","STACK two physical powers remain valid "+id)
   t.check(g.Cards.Rules.BUFFS[id].detail.contains("可叠加"),"STACK status explains repeatable effect "+id)
   if type=="wildfire_descent":
    var count=g.state.hand.size()
    t.check(t.action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id}).ok and g.state.hand.size()==count+2,"STACK fireball draws two cards")
   elif type=="adaptability":
    var mana=g.state.temporary_mana;var charge=g.state.charge
    t.check(t.action(g,"end").ok and g.state.temporary_mana==mana+(10 if free else 0) and g.state.charge==charge+(0 if free else 2),"STACK turn-start grants twice")
   elif type=="binding_enthusiast":
    var target=g.add_fixture("eyes",20,20)
    t.check(g.Cards.power_attribute_modifier(g,"strength")==2 and g.Cards.power_attribute_modifier(g,"dexterity")==2,"STACK worn attributes double")
    var pressure=g.state.pressure
    t.check(helper.play(t,g,"pleasure_conversion",false).ok and g.state.pressure==pressure+20,"STACK bound-card pressure doubles too")
    g._equipment(target.id).durability=0;g._cleanup()
    t.check(g.Cards.power_attribute_modifier(g,"strength")==0,"STACK removal recomputes all layers")
   elif type=="restraint_embrace":
    var target=g.add_fixture("ankle",1)
    if free:
     var count=g.state.hand.size()
     var energy=g.state.energy
     t.check(helper.play(t,g,"slip",false,{"target":target.id}).ok and g._equipment(target.id).is_empty() and g.state.hand.size()==count+2,"STACK release draws twice")
     t.check(g.state.energy==energy+1,"STACK two embrace copies recover two energy after paying one for slip")
    else:
     t.check(g.Cards.pending_draw(g,id)==2,"STACK wear schedules two draws")
     g.Cards.begin_turn(g)
     t.check(g.Cards.pending_draw(g,id)==0 and g.state.logs.filter(func(log):return log.data.get("power_draw",{}).get("requested",0)==1).size()==2,"STACK both scheduled draws delivered once")
   elif type=="letter_opener":
    var target=g.add_fixture("ankle",60,60)
    var hp=g.state.enemies[0].hp
    var damage=g.escape_preview(target,"strain",3,[],false,true).damage
    for i in range(3): t.check(helper.play(t,g,"pleasure_conversion",true).ok,"STACK counted skill")
    t.check(g.state.powers.all(func(card):return card.power_progress==0),"STACK each opener has its own counter")
    if free:
     t.check(g.state.enemies[0].hp==hp-10,"STACK both opener enemy damage effects apply")
    else:
     var hits=g.state.logs.filter(func(log):return log.data.get("power_damage",{}).get("target","")==target.id)
     t.check(hits.size()==2 and is_equal_approx(hits[0].data.power_damage.preview.damage,damage) and hits[0].data.power_damage.after==hits[1].data.power_damage.before and g._equipment(target.id).durability==hits[1].data.power_damage.after,"STACK both opener equipment waves apply in order using current target multipliers")
   else:
    t.check(g.BasicAttacks.usage(g,"fireball").limit==4,"STACK two flourish powers add two maximum casts")
   g.Cards.end_powers(g)
   t.check(g.state.powers.is_empty() and id not in g.Cards.active_buffs(g),"STACK all layers expire together "+id)


static func reuse_setup(t, free: bool, role: String="original"):
 var Cards=preload("res://tests/curse_cases.gd")
 var g=Game.new(42,false,"equipment",true,false,25,false,false,role)
 g._discard_end();g.state.equipment.clear();g.state.relics=[];g.state.energy=30
 g.add_fixture("wrist",8);g.add_fixture("ankle",8)
 if not free: g.add_fixture("palm",8);g.add_fixture("foot",8)
 t.check(Cards.play(t,g,"reuse",free).ok,"MASTERY activates selected face "+role)
 return g

static func reuse_fail(t,g,type: String="fireball", free: bool=false) -> Dictionary:
 var Cards=preload("res://tests/curse_cases.gd")
 g.state.pressure=75
 var c: Dictionary
 if type=="fireball": c=fire(t,g)
 else:
  var card=Cards.give(g,type)
  c=t.find_action(g,"card",{"uid":card.uid,"free":free})
 preload("res://tests/practiced_cases.gd").force_failure(g,type)
 var before=g.export_snapshot()
 g.get_view();g.command_facts();g.Cards.failure_outcome(g,c)
 t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"MASTERY previews and stale attempts do not consume quota")
 t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed,"MASTERY real failed cast "+type)
 return {"before":before,"candidate":c,"spell":g.state.logs.filter(func(row):return row.data.has("spell")).back().data.spell}

static func reuse(t) -> void:
 var Cards=preload("res://tests/curse_cases.gd")
 var Rules=preload("res://data/card_rules.gd")
 t.check("reuse" in Rules.UNCOMMON and Rules.energy_cost("reuse",true)==1 and Rules.energy_cost("reuse",false)==2 and Rules.unique_face("reuse",true) and Rules.unique_face("reuse",false),"MASTERY rarity costs and unique unchanged")
 t.check(Rules.energy_cost("henshin",false)==3 and Rules.energy_cost("henshin",true)==4 and Rules.energy_cost("hannya_henshin",false)==0 and Rules.energy_cost("hannya_henshin",true)==2,"HENSHIN bound costs three, free remains four, perfect variant unchanged")
 for role in ["original","witch"]:
  var g=reuse_setup(t,true,role)
  t.check(g.B.CARD_NAMES.reuse=="魔路精通" and g.Character.card_id(g,"reuse")=="reuse" and g.Character.card_id(g,"henshin")=="henshin","MASTERY both characters share definitions")
  for side in [true,false]:
   var card=Cards.give(g,"reuse");var before=g.export_snapshot()
   var c=t.find_action(g,"card",{"uid":card.uid,"free":side})
   t.check(not c.valid and c.reason.contains("互斥") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"MASTERY same and opposite faces reject atomically")
  var extra=Cards.give(g,"reuse");g.state.hand.erase(extra);extra.power_face="bound";g.state.powers.append(extra)
  var invalid=g.export_snapshot();var copy=Game.new(0);var before=copy.export_snapshot()
  t.check(not copy.restore_snapshot(invalid).ok and copy.state==before,"MASTERY snapshot rejects mutually exclusive faces")
 # Paid basic spell: pure personal, split payment, pure temporary.
 for side in [true,false]:
  for temporary in [0.0,4.0,30.0]:
   var g=reuse_setup(t,side);g.state.mana=50;g.state.temporary_mana=temporary
   var result=reuse_fail(t,g);var c=result.candidate;var before=result.before
   var eligible=not side or c.mana_payment.mana==0
   var rate=(0.0 if side else 1.0) if eligible else 0.5
   t.check(is_equal_approx(g.state.mana,before.mana-c.mana_payment.mana*(1-rate)) and is_equal_approx(g.state.temporary_mana,before.temporary_mana-c.mana_payment.temporary_mana*(1-rate)),"MASTERY actual refund matches paid sources")
   t.check(g.state.energy==before.energy-c.cost+(1 if eligible else 0) and result.spell.energy_refund==(1 if eligible else 0) and g.state.flask_mana==before.flask_mana,"MASTERY energy and log agree; flask untouched")
   t.check(g.state.powers[0].power_failure_count==0,"MASTERY paid actions never consume zero-card quota")
 # Zero-energy spells: exactly two conversions, third returns normal 50%.
 for side in [true,false]:
  var g=reuse_setup(t,side)
  for n in range(3):
   g.state.mana=50;g.state.temporary_mana=30
   var result=reuse_fail(t,g,"mana_surge")
   var rate=(0.0 if side else 1.0) if n<2 else 0.5
   t.check(result.candidate.cost==0 and result.spell.energy_refund==(1 if n<2 else 0) and is_equal_approx(result.spell.mana_refund.temporary_mana,result.candidate.mana*rate),"MASTERY zero-card conversion exact quota "+str(n))
  t.check(g.state.powers[0].power_failure_count==2,"MASTERY counter saturates at limit")
  var copy=Game.new(0)
  t.check(copy.restore_snapshot(g.export_snapshot()).ok and copy.state.powers[0].power_failure_count==2,"MASTERY saving cannot refresh spent quota")
  var bad=g.export_snapshot();bad.powers[0].power_failure_count=3;var before=copy.export_snapshot()
  t.check(not copy.restore_snapshot(bad).ok and copy.state==before,"MASTERY invalid quota restores atomically")
  g._begin_player_turn()
  t.check(g.state.powers[0].power_failure_count==0,"MASTERY next turn restores two opportunities")
 # Basic requirements gate activation and ongoing conversion independently of quota.
 for missing in ["palm","foot"]:
  var blocked=reuse_setup(t,false)
  blocked.Cards.end_powers(blocked)
  var item=blocked.state.equipment.filter(func(e):return e.slot==missing)[0]
  item.durability=0;blocked._cleanup()
  var card=Cards.give(blocked,"reuse");var before=blocked.export_snapshot()
  var action=t.find_action(blocked,"card",{"uid":card.uid,"free":false})
  t.check(not action.valid and not blocked.dispatch(blocked.command(action.payload,blocked.state.version),blocked.state.version).ok and blocked.state==before,"MASTERY level two in either region rejects activation atomically")
 var g=reuse_setup(t,false);g.state.powers[0].power_failure_count=2
 for slot in ["eyes","fingers","upper_arm","forearm","thigh"]: g.add_fixture(slot,8)
 g.state.mana=50;g.state.temporary_mana=30
 var result=reuse_fail(t,g,"mana_surge")
 t.check(g.level("arms")>=3 and g.level("legs")>=3 and g.Cards.worn_count(g,false,2)==9 and result.spell.energy_refund==0,"MASTERY both qualifying regions with nine tight items retain cap")
 var special=g._install_special("vaginal_egg_low","special_3_a")
 g.state.temporary_mana=30;result=reuse_fail(t,g,"mana_surge")
 t.check(not special.is_empty() and g.Cards.worn_count(g)==10 and result.spell.energy_refund==0,"MASTERY special equipment cannot supply the tenth item")
 var tenth=g.add_fixture("calf",4)
 g.state.temporary_mana=30;result=reuse_fail(t,g,"mana_surge")
 t.check(g.tier(tenth.durability,tenth.maximum)==1 and result.spell.energy_refund==0,"MASTERY forty percent durability is still below tightness two")
 g._equipment(tenth.id).durability=4.0001
 for n in range(3):
  g.state.mana=50;g.state.temporary_mana=30
  result=reuse_fail(t,g,"mana_surge")
  t.check(g.Cards.worn_count(g,false,2)==10 and result.spell.energy_refund==1 and result.spell.mana_refund.temporary_mana==result.candidate.mana,"MASTERY ten tight ordinary items permit repeated full refunds")
 g._equipment(tenth.id).durability=4;g.state.temporary_mana=30
 result=reuse_fail(t,g,"mana_surge")
 t.check(result.spell.energy_refund==0 and g.state.powers[0].power_failure_count==2,"MASTERY lowering item tightness restores cap without refreshing it")
 g._equipment(tenth.id).durability=8
 var copy=Game.new(0)
 t.check(copy.restore_snapshot(g.export_snapshot()).ok and copy.Cards.failure_unlimited(copy,Rules.BUFFS.reuse_bound) and copy.state.powers[0].power_failure_count==2,"MASTERY restore recomputes worn upgrade and preserves quota")
 g.state.equipment.clear();g.state.temporary_mana=30
 result=reuse_fail(t,g)
 t.check(result.spell.energy_refund==0 and g.get_view().statuses.any(func(row):return row.id=="power_reuse_bound" and row.value.contains("未生效")),"MASTERY lost requirement immediately pauses conversion")
 for slot in ["wrist","ankle","palm","foot"]: g.add_fixture(slot,8)
 g.state.temporary_mana=30
 result=reuse_fail(t,g)
 t.check(result.spell.energy_refund==1,"MASTERY re-equipping reactivates without replaying power")
 var composite=g._install_assembly("glove","short","fixture",2,2)
 t.check(not composite.is_empty() and composite.components.size()>1 and g.Cards.worn_count(g,false,2)==5,"MASTERY tight composite body counts once regardless of straps")
 var body=g._composite_body(composite);body.durability=body.maximum*0.4
 t.check(g.Cards.worn_count(g,false,2)==4 and g.Cards.worn_count(g,false)==5,"MASTERY loose composite body excludes its tighter straps only from tier-filtered count")
 # Success, replay, zero-mana and lifecycle boundaries.
 g=reuse_setup(t,true);g.state.pressure=0;g.state.temporary_mana=30
 var c=fire(t,g);var before=g.export_snapshot()
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and not g._magic_failed and g.state.energy==before.energy-c.cost and g.state.temporary_mana==before.temporary_mana-c.mana and g.state.powers[0].power_failure_count==0,"MASTERY success never converts refunds or consumes quota")
 var no_payment=c.duplicate(true);no_payment.mana_payment={"mana":0.0,"temporary_mana":0.0}
 t.check(g.Cards.failure_outcome(g,no_payment).energy==0,"MASTERY zero mana is not a fully temporary payment")
 c.payload.replay=true
 t.check(g.Cards.failure_outcome(g,c).energy==0,"MASTERY replay never generates energy")
 g.Cards.end_powers(g)
 t.check(g.state.powers.is_empty() and g.state.discard.all(func(card):return not card.has("power_failure_count")) and g.validate()=="","MASTERY end of preparation clears power counters")
