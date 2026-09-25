extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func fresh(seed_value: int=42):
 var g=Game.new(seed_value,false,"equipment",true,false,25,false,false,"witch")
 g.state.relics=[];g.state.temporary_mana=0.0;g.state.mana=100.0;g.state.mana_max=100.0
 return g

static func run(t) -> void:
 preload("res://tests/witch_revision_cases.gd").run(t)
 preload("res://tests/witch_expansion_cases.gd").run(t)
 _revision(t)
 _cards_and_flows(t)
 var original=Game.new(42);var old=original.export_snapshot()
 var g=fresh()
 t.check(g.state.deck.map(func(c):return c.type)==g.Character.STARTER and g.validate()=="","WITCH eleven declared starter cards and valid character state")
 t.check(original.state==old and original.state.deck.size()==10 and not original.state.has("witch_charges"),"WITCH selection preserves original run and starter")
 t.check(g.Cards.Rules.SPECS.siphon.self_faces.bound.mana_gain==5 and g.Cards.Rules.SPECS.witch_siphon.self_faces.bound.mana_gain==10,"WITCH card values are isolated by character")
 for part in g.Character.PARTS:
  g=fresh();g.state.energy=20;g.state.mana=100
  var before=g.export_snapshot();var c=t.find_action(g,"attack",{"type":"witch_"+part,"form":0})
  t.check(c.valid and c.cost==1 and c.mana==5 and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"WITCH charge costs and stale rollback "+part)
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.witch_charges[part]==1 and g.state.mana==95 and g.state.energy==19,"WITCH real charge "+part)
 for part in ["hand","mouth","mind"]:
  for layers in [0,2,4]:
   g=fresh();g.state.energy=20;g.state.mana=100;g.state.witch_charges={"hand":3,"mouth":3,"legs":4,"mind":3};g.state.witch_charges[part]=layers
   var expected_charges=g.state.witch_charges.duplicate();expected_charges[part]=0
   g.state.enemies[0].hp=1000.0;g.state.enemies[0].max_hp=1000.0
   var c=t.find_action(g,"attack",{"type":"witch_"+part,"form":1})
   var expected=(6 if part=="hand" else 4)*(layers+1)
   t.check(c.payload.hits==layers+1 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.enemies[0].hp==1000-expected and g.state.witch_charges==expected_charges,"WITCH multi-hit damage consumes all and only the releasing part's charge "+str([part,layers]))
   t.check(t.find_action(g,"attack",{"type":"witch_"+part,"form":1}).payload.hits==1,"WITCH next release returns to one base hit "+str([part,layers]))
 g=fresh();g.state.witch_charges.hand=2;g.state.witch_focus=3;g.state.enemies[0].hp=1000.0;g.state.enemies[0].max_hp=1000.0
 t.check(t.action(g,"attack",{"type":"witch_hand","form":1}).ok and g.state.enemies[0].hp==973 and g.state.witch_focus==0,"WITCH focus applies to every hit and is consumed once")
 g=fresh();g.state.witch_charges.legs=3
 t.check(not t.find_action(g,"attack",{"type":"witch_legs","form":1}).valid,"WITCH kick needs current four leg charges")
 g.state.witch_charges.legs=4
 t.check(t.action(g,"attack",{"type":"witch_legs","form":1}).ok and g.state.witch_charges.legs==0 and g.state.enemies[0].intent.delayed,"WITCH kick damages and interrupts through real intent")
 g=fresh();g.state.energy=20;var key=t.hand_card(g,"witch_key")
 t.check(t.action(g,"card",{"uid":key.uid,"free":true}).ok and g.state.temporary_mana==20,"WITCH key free grants four reserves")
 var preparation=t.hand_card(g,"witch_preparation");g.state.temporary_mana=0;var mana=g.state.mana
 t.check(t.action(g,"card",{"uid":preparation.uid,"free":false}).ok and g.state.mana==mana-20 and g.state.temporary_mana==20 and g.state.witch_focus==2,"WITCH preparation pays twenty and grants reserve/focus")
 g=fresh();g.state.witch_charges.hand=2
 var result=g.Application.execute(g,{"pool":"ordinary","templates":["rope"],"slot":"wrist","grade":1,"tier":1,"count":1},"fixture")
 t.check(result.evaded==1 and g.state.witch_charges.hand==0 and g.state.equipment.is_empty(),"WITCH matching charge blocks real restraint application")
 g.state.witch_charges.mind=2;g.state.witch_charges.mouth=4;g.Pressure._apply_overloads(g,1)
 t.check(g.state.witch_charges.values().all(func(n):return n==0),"WITCH overload clears all body charge tracks")
 g=fresh()
 for type in g.SpecialEquipment.DESIGNS:
  var design=g.SpecialEquipment.DESIGNS[type]
  if design.slots.any(func(slot):return slot.begins_with("special_2")):
   t.check(g._special_install_reason(type,design.slots[0])!="","WITCH removed anatomy cannot receive equipment "+type)
 var view=g.get_view()
 t.check(not view.body_groups.any(func(body):return body.id=="special_2"),"WITCH body view omits removed region")
 var pool=g.Character.pool(g,g.Cards.Rules.REWARDS)
 t.check(pool.has("witch_magic_hand") and pool.has("witch_mana_conversion") and not pool.has("breath_control") and not pool.has("fire_mastery") and not pool.has("ready_to_strike"),"WITCH pool substitutes modified cards and excludes either-face incompatibility")
 var catalog=preload("res://data/encyclopedia.gd").entries(g).filter(func(row):return row.category=="cards")
 for type in ["confluence","supple_flesh","binding_enthusiast","binding_power","kip_up"]:
  t.check(not g.Character.allowed_card(g,type) and not g.Character.reward_member(g,type) and type not in pool and not catalog.any(func(row):return row.card==type),"WITCH strength effects or conditions on either face exclude the whole card from rewards and catalog "+type)
  t.check(original.Character.allowed_card(original,type) and original.Character.reward_member(original,type) and type in original.Character.pool(original,original.Cards.Rules.REWARDS),"WITCH strength filtering preserves original character pool "+type)
 t.check(g.Character.allowed_card(g,"self_binding") and g.Character.allowed_card(g,"shared_fate") and g.Character.allowed_card(g,"witch_mana_conversion") and not g.Character.incompatible(g,g.Cards.Rules.BUFFS.supple_flesh_bound),"WITCH compatible mana and dexterity effects remain allowed")
 for type in pool:
  t.check(g.Character.allowed_card(g,type),"WITCH every reward supports both faces "+type)
 var saved=g.export_snapshot()
 t.check(original.restore_snapshot(saved).ok and original.Character.active(original),"WITCH saved character can be restored from original menu")
 t.check(original.restore_snapshot(old).ok and not original.Character.active(original),"WITCH can restore original save without witch fields")
 for type in g.Cards.Rules.SPECS:
  if not type.begins_with("witch_"): continue
  t.check(g.Cards.Rules.definition_reason(g.Cards.Rules.SPECS[type])=="","WITCH card definition valid "+type)
  var text=g.B.card_info(type)
  t.check(not str(text).contains("{"),"WITCH all card text placeholders resolve "+type)

static func give(t,g,type: String) -> Dictionary:
 g._gain_card(type)
 return t.hand_card(g,g.Character.card_id(g,type))

static func _cards_and_flows(t) -> void:
 var g=fresh();g.state.energy=30;g.state.mana=50
 var card=t.hand_card(g,"witch_strain")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.witch_focus==1 and g.state.charge==0,"WITCH strain grants spirit instead of original charge")
 for pair in [["mana_surge",2],["focus",1]]:
  g=fresh();card=give(t,g,pair[0])
  t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.witch_focus==pair[1] and g.state.charge==0,"WITCH card grants intended focus "+pair[0])
 g=fresh();card=give(t,g,"magic_slip")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.temporary_mana==10,"WITCH magic slip free grants two reserves")
 for pair in [["siphon",false,10],["mana_invocation",false,10],["mana_invocation",true,10],["mana_conversion",true,20]]:
  g=fresh();g.state.mana=40;card=give(t,g,pair[0])
  t.check(t.action(g,"card",{"uid":card.uid,"free":pair[1]}).ok and g.state.mana==40+pair[2],"WITCH character-local mana gain "+str(pair))
  if pair[0]=="mana_invocation": t.check(g.state.temporary_mana==20,"WITCH invocation also grants four reserves")
 g=fresh();g.state.mana=50;card=give(t,g,"mana_conversion");var energy=g.state.energy
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.mana==30 and g.state.energy==energy+2,"WITCH conversion pays twenty for two energy")
 t.check(g.B.card_info("witch_mana_conversion")[1].contains("能量＋2"),"WITCH conversion text matches actual gain")
 g=fresh();card=give(t,g,"mana_search");var candidate=t.find_action(g,"card",{"uid":card.uid,"free":false});var mana=g.state.mana
 t.check(candidate.cost==0 and candidate.mana==5 and g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok and g.state.mana==mana-5 and g.state.exhaust.any(func(c):return c.uid==card.uid),"WITCH search zero energy five mana and exhaust")
 g=fresh();g.state.pressure=45;card=give(t,g,"pleasure_conversion");energy=g.state.energy
 candidate=t.find_action(g,"card",{"uid":card.uid,"free":false})
 t.check(g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok and g.state.energy==energy-candidate.cost+3,"WITCH pleasure conversion uses fifteen threshold")
 for free_face in [false,true]:
  g=fresh();g.state.energy=10;card=give(t,g,"ready_to_strike");var chosen=t.hand_card(g,"witch_slip")
  t.check(t.action(g,"card",{"uid":card.uid,"free":free_face,"hand_uid":chosen.uid}).ok and g.state.exhaust.any(func(c):return c.uid==chosen.uid),"WITCH ready consumes chosen hand card")
  if free_face:
   candidate=t.find_action(g,"attack",{"type":"witch_mouth","form":1})
   t.check(candidate.cost==0 and g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok and t.find_action(g,"attack",{"type":"witch_hand","form":0}).cost==1,"WITCH discount applies once to any basic action")
  else: t.check(g.state.witch_focus==3,"WITCH ready bound grants three focus")
 g=fresh();g.state.energy=10;card=give(t,g,"magic_hand")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok,"WITCH magic hand free casts normally")
 t.check(g.state.mana==70 and g.state.evasion==2 and not g.state.card_buffs.has("witch_hand_freedom"),"WITCH magic hand pays thirty for two evasion")
 for free_face in [false,true]:
  g=fresh();g.state.energy=10;card=give(t,g,"adaptability")
  t.check(t.action(g,"card",{"uid":card.uid,"free":free_face}).ok and t.action(g,"end").ok and (g.state.temporary_mana==10 if free_face else g.state.witch_focus==1),"WITCH adaptability triggers character-local turn start "+str(free_face))
 g=fresh();g.state.energy=10;card=give(t,g,"mana_circuit")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok,"WITCH mana circuit can be installed")
 card=t.hand_card(g,"witch_preparation")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.witch_focus==3,"WITCH circuit gives focus per twenty paid mana")
 g.state.powers[0].power_mana_progress=20.0
 g.Cards.end_powers(g)
 t.check(g.state.witch_focus==2,"WITCH final mana-circuit payout retains at most two focus")
 g=fresh();g.state.energy=20;g.state.mana=100;card=t.hand_card(g,"witch_accumulation")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok,"WITCH accumulation activates")
 g.state.enemies[0].hp=1000.0;g.state.enemies[0].max_hp=1000.0
 candidate=t.find_action(g,"attack",{"type":"witch_hand","form":1})
 t.check(candidate.brief.begins_with("11.7") and g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok and is_equal_approx(g.state.enemies[0].hp,988.3),"WITCH accumulation uses mana after payment and preview agrees")
 g.Cards.grant_buff(g,"henshin_free");g.state.mana=100
 t.check(g.Cards.bind_payload(g,"witch_strain").preview.damage_buff_multiplier==4.0,"WITCH accumulation and henshin also affect capture escape damage")
 t.check(t.action(g,"attack",{"type":"witch_mind","form":1}).ok and is_equal_approx(g.state.enemies[0].hp,972.7),"WITCH compatible henshin doubles another body part's basic damage")
 g.Cards.end_powers(g)
 t.check(g.state.witch_focus==0 and g.state.witch_charges.values().all(func(n):return n==0),"WITCH preparation end clears character effects")
 var outcomes={}
 for seed_value in range(8):
  g=fresh(seed_value);g.state.pressure=56.25;g.state.witch_charges.mind=2;g.state.witch_focus=3
  var before=g.export_snapshot();candidate=t.find_action(g,"attack",{"type":"witch_mind","form":1})
  t.check(g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok,"WITCH probability test commits action")
  var success=g.state.logs.filter(func(row):return row.data.has("spell")).back().data.spell.success
  outcomes[success]=true
  if not success: t.check(g.state.witch_charges==before.witch_charges and g.state.witch_focus==2 and g.state.enemies==before.enemies and g.state.mana==before.mana-2.5,"WITCH failed release refunds half mana, retains charges and loses one focus")
 t.check(outcomes.size()==2,"WITCH probability tests cover success and failure")
 g=fresh();var other=g.state.enemies[0].duplicate(true);other.id="fixture_second";g.state.enemies.append(other);g.state.witch_charges.mouth=2
 var hp=other.hp
 t.check(t.action(g,"attack",{"type":"witch_mouth","form":1}).ok and g.state.enemies.all(func(e):return e.hp==hp-12),"WITCH snow hits every enemy for all three segments")
 g=fresh()
 var catalog=preload("res://data/encyclopedia.gd").entries(g).filter(func(row):return row.category=="cards")
 t.check(catalog.any(func(row):return row.card=="witch_key") and catalog.any(func(row):return row.card=="witch_mana_conversion") and not catalog.any(func(row):return row.card in ["mana_conversion","fireball","fire_mastery"]),"WITCH encyclopedia uses correct faces and excludes incompatible cards")
 for seed_value in range(4):
  g=preload("res://core/game.gd").new(seed_value,false,"equipment",true,false,25,false,false,"witch")
  t.check(g.validate()=="" and Game.new(1).restore_snapshot(g.export_snapshot()).ok,"WITCH real opening and departure rewards validate and restore")
  var rng=RandomNumberGenerator.new();rng.seed=seed_value
  var transform=g.Departure.freeze(g,"transform",rng)
  t.check(transform.changes.size()==11 and transform.changes.values().all(func(type):return g.Character.allowed_card(g,type)),"WITCH all eleven basic starter transformations use compatible pool")
  g.state.room=g.state.rooms.filter(func(room):return room.kind=="shop")[0].id;g.Services.start(g)
  var stock=g.room_data(g.state.room).stock
  t.check(stock.filter(func(row):return row.kind=="card").all(func(row):return g.Character.allowed_card(g,row.type)) and g.validate()=="" and Game.new(1).restore_snapshot(g.export_snapshot()).ok,"WITCH shop offers and save restore use character pool")
 g=fresh();g.state.witch_charges.mouth=7
 t.check(t.action(g,"attack",{"type":"witch_mouth","form":1}).ok and g.state.phase=="reward" and g.state.reward_options.all(func(type):return g.Character.reward_member(g,type)),"WITCH real victory generates three compatible rewards")
 var reward=g.state.reward_options[0]
 t.check(t.action(g,"reward",{"type":reward}).ok and g.state.deck.any(func(c):return c.type==reward) and Game.new(1).restore_snapshot(g.export_snapshot()).ok,"WITCH reward acquisition and reward-phase save restore")
 g=fresh();var malformed=g.export_snapshot();malformed.erase("special_equipment");var before=g.export_snapshot()
 t.check(not g.restore_snapshot(malformed).ok and g.state==before,"WITCH incomplete character save is rejected atomically")
 var guaranteed=g.Relics.TYPES.keys().filter(func(id):return g.Relics.trigger(id).get("op","")=="guarantee")
 if not guaranteed.is_empty():
  g.state.relics.append(guaranteed[0]);g.state.pressure=56.25;g.state.witch_charges.legs=4
  var leg=t.find_action(g,"attack",{"type":"witch_legs","form":1})
  var charge=t.find_action(g,"attack",{"type":"witch_legs","form":0})
  t.check(leg.casting.chance==0.25 and charge.casting.chance==1.0,"WITCH zero-mana kick cannot show paid-cast guarantee")

static func _revision(t) -> void:
 var original=Game.new(42)
 var g=Game.new(42,false,"equipment",true,false,25,false,false,"witch")
 t.check(g.state.mana_max==75 and g.state.mana==75 and g.Pressure.maximum(g)==75 and g.state.flask_mana==50 and g.state.relics==["witch_amulet"],"WITCH revised starting resources and relic")
 t.check(g.state.temporary_mana==5,"WITCH amulet includes first battle turn")
 t.check(original.state.mana_max==100 and original.Pressure.maximum(original)==100 and original.state.relics==["ember"] and original.state.flask_mana==0,"WITCH original starter remains unchanged")
 var temp=g.state.temporary_mana
 g.RelicEffects.begin_turn(g)
 t.check(g.state.temporary_mana==temp+5,"WITCH amulet triggers following battle turn")
 for phase in ["prepare","rest","prison"]:
  g.state.phase=phase;temp=g.state.temporary_mana;g.RelicEffects.begin_turn(g)
  t.check(g.state.temporary_mana==temp,"WITCH amulet does not trigger outside battle "+phase)
 g=fresh();g.state.relics=["witch_noodles"];g.state.witch_focus=1
 g.RelicEffects.begin_combat(g)
 t.check(g.state.witch_focus==3,"WITCH noodles add two focus at battle entry")
 g.state.phase="rest";g.RelicEffects.begin_combat(g)
 t.check(g.state.witch_focus==3,"WITCH noodles do not trigger at rest entry")
 for source in ["normal","shop"]:
  var pool=g.RelicRewards.available(g,source)
  t.check(not pool.any(func(id):return id in ["olihakimi","mana_earring","break_bracer"]),"WITCH excluded relics absent from "+source)
  t.check("witch_noodles" not in original.RelicRewards.available(original,source),"WITCH exclusive noodles absent from original "+source)
 t.check(g.RelicEffects.gain_reason(g,"shining_lamp")!="" and original.RelicEffects.gain_reason(original,"witch_noodles")!="","WITCH direct relic gain respects role eligibility")
 var relic_catalog=preload("res://data/encyclopedia.gd").entries(g).filter(func(row):return row.category=="relics")
 for id in ["martial_book","magic_blood","wrist_bracer"]:
  t.check(not g.Character.relic_allowed(g,id) and g.RelicEffects.gain_reason(g,id)!="" and id not in g.RelicEffects.transform_pool(g) and not relic_catalog.any(func(row):return row.id==id),"WITCH strength relic excluded from gain, transformation and catalog "+id)
  for source in ["normal","shop","boss"]:
   t.check(id not in g.RelicRewards.available(g,source),"WITCH strength relic excluded from source "+source+" "+id)
  t.check(original.Character.relic_allowed(original,id) and id in original.RelicRewards.available(original,"normal"),"WITCH strength relic remains in original character rewards "+id)
 t.check(g.Character.relic_allowed(g,"witch_noodles") and g.Character.relic_allowed(g,"turtle_shell"),"WITCH compatible focus relics remain allowed")
 t.check(not g.Character.allowed_card(g,"ease") and original.Character.allowed_card(original,"ease"),"WITCH ease excluded only for role two")
 g=fresh();g.state.witch_charges.hand=1
 var applied=g.Application.execute(g,{"pool":"ordinary","templates":["rope"],"slot":"wrist","grade":1,"tier":1,"count":1},"fixture")
 t.check(applied.evaded==0 and not g.state.equipment.is_empty() and g.state.witch_charges.hand==1,"WITCH single charge cannot evade equipment")
 for shell in [false,true]:
  g=fresh();g.state.witch_focus=7;g.state.witch_charges.hand=4
  if shell: g.state.relics.append("turtle_shell")
  g.Cards.end_powers(g)
  t.check(g.state.witch_focus==(4 if shell else 2) and g.state.witch_charges.hand==0,"WITCH focus retention boundary and turtle bonus")
  var saved=g.export_snapshot();var restored=Game.new(7)
  t.check(restored.restore_snapshot(saved).ok and restored.state.witch_focus==g.state.witch_focus,"WITCH retained focus survives save restore")
 g=fresh();g.state.witch_focus=3;g.state.pressure=74;g.state.witch_charges.hand=2
 g.Pressure.gain(g,1,"fixture")
 t.check(g.state.overloaded and g.state.witch_focus==2 and g.state.witch_charges.hand==0,"WITCH new pressure limit triggers overload and loses one focus")
 for free_face in [false,true]:
  g=fresh();g.state.mana=40;var card=give(t,g,"siphon")
  var before=g.state.hand.size()
  t.check(t.action(g,"card",{"uid":card.uid,"free":free_face}).ok,"WITCH siphon face resolves")
  t.check(g.state.exhaust.any(func(c):return c.uid==card.uid)!=free_face and g.state.discard.any(func(c):return c.uid==card.uid)==free_face,"WITCH siphon exhaust is bound-only")
  t.check(g.state.mana==50 and (not free_face or g.state.hand.size()==before),"WITCH siphon gains ten and free draws one")
  t.check(g.B.card_info(card.type)[1].contains("消耗") and not g.B.card_info(card.type)[2].contains("消耗"),"WITCH siphon face keywords match settlement")
 g=fresh();g.state.energy=20;g.state.mana=50
 var accumulation=t.hand_card(g,"witch_accumulation")
 t.check(t.action(g,"card",{"uid":accumulation.uid,"free":true}).ok,"WITCH accumulation activation for mixed mana")
 g.state.temporary_mana=20;g.state.enemies[0].hp=1000.0;g.state.enemies[0].max_hp=1000.0
 var attack=t.find_action(g,"attack",{"type":"witch_hand","form":1})
 t.check(attack.brief.begins_with("9.9") and g.dispatch(g.command(attack.payload,g.state.version),g.state.version).ok and is_equal_approx(g.state.enemies[0].hp,990.1),"WITCH temporary mana contributes after payment and matches preview")
 var spec=g.Cards.Rules.SPECS.witch_magic_hand
 t.check(spec.cost==1 and spec.mana_cost==30 and spec.free_mana_cost==30 and spec.hits==4 and spec.follow_through_scope=="body","WITCH magic hand keeps super follow-through and new costs")
 t.check(g.Cards.Rules.SPECS.magic_hand.hits==3 and g.Cards.Rules.SPECS.magic_hand.mana_cost==20,"WITCH original magic hand unchanged")

 g=fresh();g.state.energy=20
 var target=g.add_fixture("wrist",10);var other=g.add_fixture("thigh",10)
 var hand=give(t,g,"magic_hand")
 var cast=t.find_action(g,"card",{"uid":hand.uid,"free":false,"target":target.id})
 var before=g.export_snapshot()
 t.check(not g.dispatch(g.command(cast.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"WITCH revised magic hand stale target refuses atomically")
 t.check(g.dispatch(g.command(cast.payload,g.state.version),g.state.version).ok and g._equipment(target.id).is_empty() and g.tier(g._equipment(other.id).durability,other.maximum)==2 and g.state.mana==70,"WITCH magic hand actually lowers four tiers across body fallback for thirty mana")
 t.check(g.state.exhaust.any(func(c):return c.uid==hand.uid) and g.state.card_chain.is_empty(),"WITCH magic hand finishes its four-stage chain and exhausts once")
 var real=preload("res://core/game.gd").new(42,false,"equipment",true,false,25,false,false,"witch")
 var choice=t.find_action(real,"departure",{"op":"choose","option":"boss"})
 var chosen=real.state.departure.options.filter(func(option):return option.id=="boss")[0].relics[0]
 t.check(choice.valid and choice.detail.contains("魔女护符") and not choice.detail.contains("余烬护符"),"WITCH opening exchange names the correct starter relic")
 t.check(real.dispatch(real.command(choice.payload,real.state.version),real.state.version).ok and "witch_amulet" not in real.state.relics and chosen in real.state.relics,"WITCH opening exchange actually replaces witch amulet")
