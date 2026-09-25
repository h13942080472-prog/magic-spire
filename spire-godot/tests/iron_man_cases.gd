extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func encounter(witch: bool=false, seed_value: int=42):
 var g=Game.new(seed_value,false,"equipment",true,false,25,false,false,"witch" if witch else "original")
 g.state.room_encounters.entrance="iron_man_solo"
 g._start_battle()
 return g

static func enemy(g, type: String) -> Dictionary:
 return g.state.enemies.filter(func(e):return e.type==type)[0]

static func run(t) -> void:
 interrupt_contract(t)
 capture_contract(t)
 practice_contract(t)
 cup_progression(t)
 fallback_progression(t)
 energy_remainder(t)
 upgrade_reversal(t)
 installation_fallback(t)
 support_contract(t)
 legacy_drone(t)
 capture_gain_contract(t)
 capture_postures(t)
 var g=encounter()
 var iron=enemy(g,"iron_man")
 var box=enemy(g,"binding_box")
 var drone=enemy(g,"iron_drone")
 t.check(iron.hp==140 and box.hp==40 and drone.hp==40 and iron.intent.kind=="bind_apply" and drone.intent.kind=="bind_apply","IRON encounter starts with approved health and independent opening intents")
 t.check(box.name=="凑数型拘束盒" and drone.name=="凑数型无人机","IRON encounter owns both support display names")
 t.check(iron.iron_support_ids.has(box.id) and iron.iron_support_ids.has(drone.id) and g.validate()=="","IRON boss owns both support identities in a valid state")

 var witch=encounter(true)
 t.check(enemy(witch,"iron_man").hp==182 and enemy(witch,"binding_box").hp==52 and enemy(witch,"iron_drone").hp==52,"IRON witch encounter multiplies exactly the three boss members by 1.3")

 var plate_game=encounter(false,43)
 var ordinary_plate=plate_game._install_special("negative_plate_lock_medium","special_2_a",3)
 plate_game.IronMan.apply_capture_equipment(plate_game,enemy(plate_game,"iron_man"))
 t.check(not ordinary_plate.is_empty() and not plate_game.state.special_equipment.any(func(item):return item.id==ordinary_plate.id) and plate_game.state.special_equipment.any(func(item):return item.type=="glans_cup_medium"),"IRON capture replaces an ordinary plate lock with the approved medium glans cup")

 var cursed_game=encounter(false,44)
 cursed_game.RelicEffects.gain(cursed_game,"cursed_plate_lock")
 var cursed_id=cursed_game.state.special_equipment.filter(cursed_game.SpecialEquipment.is_cursed_plate)[0].id
 cursed_game.IronMan.apply_capture_equipment(cursed_game,enemy(cursed_game,"iron_man"))
 var cursed_toys=cursed_game.state.special_equipment.filter(func(item):return item.id!=cursed_id and not cursed_game.SpecialEquipment.is_reinforcement(item))
 t.check(cursed_game.state.special_equipment.any(func(item):return item.id==cursed_id) and cursed_toys.size()==3 and not cursed_game.state.special_equipment.any(func(item):return item.type=="glans_cup_medium"),"IRON cursed plate remains worn and redirects capture equipment to three other medium toys")

 var witch_equipment_before=witch.state.special_equipment.size()
 witch.IronMan.apply_capture_equipment(witch,enemy(witch,"iron_man"))
 t.check(witch.state.special_equipment.size()==witch_equipment_before+3 and not witch.state.special_equipment.any(func(item):return item.type=="glans_cup_medium"),"IRON witch capture installs three medium toys instead of the glans cup")

 t.check(t.action(g,"end").ok,"IRON opening enemy phase resolves through formal turn end")
 iron=enemy(g,"iron_man");drone=enemy(g,"iron_drone")
 var cup=g.state.special_equipment.filter(func(item):return item.type=="glans_cup_medium")
 t.check(cup.size()==1 and g.tier(cup[0].durability,cup[0].maximum)==2 and g.CaptureBind.has_bind(g,"iron_man") and g.state.posture=="sit","IRON opening capture installs the tier-two glans cup and combines posture restrictions")
 g.add_fixture("wrist",4)
 var energy_source=g.state.guard_bind.sources.iron_man
 var pressure=g.state.pressure
 var remaining=cup[0].remaining
 var bind_before=g.state.guard_bind.progress
 var drone_source=g.state.guard_bind.sources.iron_drone
 g.CaptureBind.energy_spent(g,2)
 t.check(energy_source.energy==2 and drone_source.energy==2 and g.state.pressure==pressure,"IRON two energy only accumulates independent remainders")
 g.CaptureBind.energy_spent(g,1)
 var tapes=g.state.equipment.filter(func(item):return item.template in g.IronMan.TAPE_POOL)
 t.check(energy_source.energy==3 and drone_source.energy==0 and not tapes.is_empty() and g.state.guard_bind.progress==bind_before+5 and cup[0].remaining==remaining-1,"IRON independent third energy triggers drone tape, capture and remote battery drain")
 t.check(g.physical_pieces().any(func(item):return item.locked),"IRON drone locks a restraint on its own third energy")
 pressure=g.state.pressure
 g.CaptureBind.energy_spent(g,2)
 t.check(energy_source.energy==0 and drone_source.energy==2 and g.state.pressure>pressure and g.state.guard_bind.progress==bind_before+5 and cup[0].remaining==remaining-1,"IRON fifth energy triggers the boss without repeating drone effects")

 var stimulation=encounter(false,45)
 t.check(t.action(stimulation,"end").ok,"IRON stimulation fixture resolves its opening capture")
 var stimulation_cup=stimulation.state.special_equipment.filter(func(item):return item.type=="glans_cup_medium")[0]
 stimulation_cup.remaining=1
 var stimulation_log=stimulation.state.logs.size()
 stimulation._apply_traction(5,false,0)
 var stimulation_hits=stimulation.state.logs.slice(stimulation_log).filter(func(log):return String(log.data.get("source","")).contains(stimulation_cup.name))
 t.check(stimulation_hits.size()==3 and stimulation_cup.remaining==0,"IRON one-charge battery receives normal, capture and drone stimulation before drone drain")

 var reinforcement=encounter(false,46)
 var ordinary=reinforcement.add_fixture("wrist",4)
 var composite_root=reinforcement._install_assembly("leg","upper","fixture",2,1)
 var composite_before=composite_root.components.map(func(item):return item.durability)
 reinforcement.EnemyPlans.execute_tighten_budget(reinforcement,enemy(reinforcement,"iron_man"),{"budget":1})
 t.check(ordinary.durability>4 and composite_root.components.map(func(item):return item.durability)==composite_before,"IRON reinforcement budget only tightens ordinary restraints, never composite components")

 g.CaptureBind.damage_bind(g,100,"测试挣脱")
 t.check(not g.CaptureBind.has_bind(g) and iron.intent.kind=="iron_stunned" and iron.iron_stun_turns==1 and iron.iron_armor_break_turns==2,"IRON removing capture schedules one idle action and two armor-break turns")
 t.check(g.Enemies.damage_multiplier(g,"iron_man","physical")==1.0,"IRON armor break removes mechanical damage reduction")
 iron.intent.delayed=true
 var delayed_one=t.action(g,"end")
 iron=enemy(g,"iron_man")
 t.check(delayed_one.ok and iron.iron_armor_break_turns==1,"IRON interrupted idle still consumes the first armor-break turn")
 iron.intent.delayed=true
 var delayed_two=t.action(g,"end")
 iron=enemy(g,"iron_man")
 t.check(delayed_two.ok and iron.iron_armor_break_turns==0 and g.Enemies.damage_multiplier(g,"iron_man","physical")==0.5,"IRON repeated interruption cannot extend the two-turn armor break")

 iron.iron_enhancements=4
 iron.iron_stun_turns=0
 iron.stage=23
 var restraints=g.IronMan.plan(g,iron)
 iron.stage=24
 var composite=g.IronMan.plan(g,iron)
 t.check(restraints.kind=="iron_restraints" and restraints.grade==3 and restraints.tier==3 and restraints.count==5 and restraints.reinforce==6,"IRON four upgrades accumulate grade, tightness, ordinary count and six reinforcement tiers")
 t.check(composite.kind=="iron_composite" and composite.special==2 and composite.locks==3,"IRON third and fourth upgrade groups accumulate two special installs and three locks")
 iron.intent=g.EnemyPlans.build(g,iron)

 var saved=Save.roundtrip(t,g,"iron boss capture break and upgrades")
 t.check(saved.validate()=="" and enemy(saved,"iron_man").iron_enhancements==4,"IRON snapshot preserves boss-specific counters")
 var invalid=saved.export_snapshot()
 var invalid_iron=invalid.enemies.filter(func(e):return e.type=="iron_man")[0]
 invalid_iron.iron_stun_turns=0
 invalid_iron.intent={"kind":"iron_stunned","text":"机械减伤失效 · 发呆","delayed":false}
 var stable=saved.export_snapshot()
 t.check(not saved.restore_snapshot(invalid).ok and saved.export_snapshot()==stable,"IRON snapshot atomically rejects an intent that contradicts its stage and stun counter")
 invalid=saved.export_snapshot()
 invalid_iron=invalid.enemies.filter(func(e):return e.type=="iron_man")[0]
 invalid_iron.iron_enhancements=5
 t.check(not saved.restore_snapshot(invalid).ok and saved.export_snapshot()==stable,"IRON snapshot atomically rejects an enhancement count that contradicts its stage")

 g=encounter(false,17);iron=enemy(g,"iron_man");box=enemy(g,"binding_box");drone=enemy(g,"iron_drone")
 g._damage_enemy(iron,999,"magic","测试终结")
 t.check(iron.gone and box.gone and drone.gone and box.hp==0 and drone.hp==0,"IRON defeat immediately stops both supports regardless of their health")

 var summit_seen={}
 for seed_value in range(64):
  var tower=Game.new(seed_value)
  summit_seen[tower.state.room_encounters.summit]=true
 t.check(summit_seen.has("six_bind_solo") and summit_seen.has("iron_man_solo") and summit_seen.size()==2,"IRON first-floor boss pool can draw both Six Bind and Iron Man")

static func capture_contract(t) -> void:
 for witch in [false,true]:
  var g=encounter(witch,52)
  t.check(t.action(g,"end").ok,"IRON CAPTURE opening commits")
  g.CaptureBind.gain_bind(g,99.0-g.state.guard_bind.progress,"测试边界")
  t.check(g.state.phase=="battle" and enemy(g,"iron_man").intent.kind!="capture","IRON CAPTURE ninety-nine does not announce arrest")
  g.CaptureBind.gain_bind(g,1.0,"测试边界")
  t.check(g.state.phase=="battle" and enemy(g,"iron_man").intent.kind=="capture","IRON CAPTURE one hundred announces arrest without interrupting resolution")
  g=Save.roundtrip(t,g,"iron full capture before arrest")
  var outcome=t.action(g,"end")
  t.check(outcome.ok and g.state.phase=="captured" and g.state.room=="prison","IRON CAPTURE full progress commits intake: "+str(outcome))
  if not outcome.ok or g.state.phase!="captured": continue
  t.check(g.state.security==1 and g.state.guard_bind.is_empty() and g.state.reward_count==0 and g.validate()=="","IRON CAPTURE intake occurs once and clears bind without victory rewards")
  g=Save.roundtrip(t,g,"iron captured state")
  t.check(t.action(g,"prison",{"action":"enter"}).ok and g.state.phase=="prison","IRON CAPTURE confirmed intake enters the real cell")
 var shared=encounter(false,53)
 shared.CaptureBind.apply_bind(shared,enemy(shared,"binding_box"))
 shared.CaptureBind.gain_bind(shared,90,"测试共用进度")
 t.check(not shared.CaptureBind.has_bind(shared,"iron_man") and enemy(shared,"iron_man").intent.kind=="capture" and shared.validate()=="","IRON CAPTURE shared full bar takes priority even before the boss applies its own source")
 t.check(t.action(shared,"end").ok and shared.state.phase=="captured","IRON CAPTURE shared source follows the same formal intake route")
 var delayed=encounter(false,54)
 t.action(delayed,"end")
 delayed.CaptureBind.gain_bind(delayed,100,"测试打断")
 for e in delayed.state.enemies:
  if e.intent.kind=="capture": e.intent.delayed=true
 t.check(t.action(delayed,"end").ok and delayed.state.phase=="battle","IRON CAPTURE interrupted arrest waits instead of capturing immediately")
 delayed.CaptureBind.damage_bind(delayed,100,"测试解除")
 t.check(enemy(delayed,"iron_man").intent.kind=="iron_stunned" and delayed.validate()=="","IRON CAPTURE clearing the bar cancels arrest and keeps the existing break response")

static func practice_contract(t) -> void:
 var localizer=preload("res://ui/localization.gd").new()
 localizer.set_locale("en_US")
 var spec=Game.Tower.practice_spec("iron_man_solo")
 t.check(localizer.display(spec.name)=="Iron Man Practice" and localizer.display(spec.description).contains("140 HP") and localizer.display(spec.hint).contains("At 100"),"IRON PRACTICE English description preserves health and capture timing")
 for role in ["original","witch"]:
  var g=preload("res://core/game.gd").new(42,true,"iron_man_solo",true,false,25,false,false,role)
  t.check(g.state.practice_kind=="iron_man_solo" and g.state.phase=="battle" and g.state.enemies.size()==3,"IRON PRACTICE real initialization starts the complete encounter: "+role)
  t.check(enemy(g,"iron_man").hp==(182 if role=="witch" else 140) and g.validate()=="","IRON PRACTICE uses normal role-specific health and valid support identities: "+role)
  t.check(t.action(g,"end").ok and g.CaptureBind.has_bind(g,"iron_man"),"IRON PRACTICE opening uses the formal enemy action pipeline: "+role)

static func cup_progression(t) -> void:
 var g=encounter()
 for type in ["binding_box","iron_drone"]: g._defeat_enemy(enemy(g,type))
 t.check(t.action(g,"end").ok,"IRON CUP opening uses the real enemy action")
 var types=["glans_cup_medium","full_cup_medium","full_cup_medium","urethral_full_cup_medium","urethral_full_cup_high","urethral_full_cup_high"]
 var tiers=[2,2,3,3,3,3]
 for level in range(types.size()):
  var iron=enemy(g,"iron_man")
  iron.stage=5+5*level;iron.intent=g.EnemyPlans.build(g,iron)
  var before=g.export_snapshot();var action=t.find_action(g,"end")
  t.check(not g.dispatch(g.command(action.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"IRON CUP stale recharge rejects without replacement or random changes")
  t.check(t.action(g,"end").ok,"IRON CUP recharge commits at level "+str(level))
  var cups=g.state.special_equipment.filter(func(item):return g.SpecialEquipment.exclusive_family(item.type)=="cup")
  t.check(cups.size()==1 and cups[0].type==types[level] and g.tier(cups[0].durability,cups[0].maximum)==tiers[level],"IRON CUP current upgrade level selects exactly one prescribed cup: "+str(level))
  t.check(cups[0].remaining>=g.SpecialEquipment.TYPES[cups[0].type].duration-1,"IRON CUP installed cup starts with a full battery before opening tick")
  t.check(t.action(g,"end").ok and enemy(g,"iron_man").iron_enhancements==level+1,"IRON CUP formal fifth action adds one upgrade")
 g=Save.roundtrip(t,g,"iron cup upgrades beyond the fourth")
 for witch in [false,true]:
  g=encounter(witch)
  if not witch: g.RelicEffects.gain(g,"cursed_plate_lock")
  g.IronMan.apply_capture_equipment(g,enemy(g,"iron_man"))
  var ids=g.state.special_equipment.map(func(item):return item.id)
  g.IronMan.recharge(g,enemy(g,"iron_man"))
  t.check(g.state.special_equipment.any(func(item):return item.id not in ids) and g.validate()=="","IRON CUP recharge also installs or replaces fallback special equipment")

static func upgrade_reversal(t) -> void:
 for level in range(1,6):
  var g=encounter();var iron=enemy(g,"iron_man")
  iron.iron_enhancements=level;iron.stage=5*level+2
  g.CaptureBind.apply_bind(g,iron)
  var worn=g.state.special_equipment.duplicate(true)
  var next_profile=g.IronMan.cup_spec({"iron_enhancements":level-1})
  g.CaptureBind.damage_bind(g,100,"测试解除")
  t.check(iron.iron_enhancements==level-1 and g.IronMan.cup_spec(iron)==next_profile and g.state.special_equipment==worn,"IRON UPGRADE escape removes one current layer and future cup upgrade without editing worn gear")
  t.check(g.IronMan.modifiers(iron)==g.IronMan.modifiers({"iron_enhancements":level-1}) and g.IronMan.capture_start(iron)==30+5*(level-1),"IRON UPGRADE all ordinary, composite and capture effects retract together")
  g=Save.roundtrip(t,g,"iron removed upgrade "+str(level))
  var remaining=enemy(g,"iron_man").iron_enhancements
  g.CaptureBind.damage_bind(g,100,"重复解除")
  t.check(enemy(g,"iron_man").iron_enhancements==remaining,"IRON UPGRADE clearing an already-free bar cannot remove another layer")
 var g=encounter();var iron=enemy(g,"iron_man")
 g.CaptureBind.apply_bind(g,iron);g.CaptureBind.damage_bind(g,100,"零层解除")
 t.check(iron.iron_enhancements==0 and g.validate()=="","IRON UPGRADE zero layers cannot become negative")

static func installation_fallback(t) -> void:
 for grade in [2,3]:
  var g=encounter();var iron=enemy(g,"iron_man")
  var fill=g.EnemyPlans.application(g.IronMan.LEATHER_POOL,grade,3,100);fill.shoulders=true
  g.Application.execute(g,g.EnemyPlans.application_spec(g,iron,fill),iron.id)
  t.check(not g.Application.can_apply(g,fill,iron.id),"IRON INSTALL fixture exhausts its declared empty positions")
  var victim=g.state.equipment.filter(func(item):return g._can_tighten(item) or not g.Equipment.is_shoulder(item))[0]
  if grade==3: victim.durability=victim.maximum*0.7
  var before=victim.durability;var log_start=g.state.logs.size()
  iron.iron_enhancements=2 if grade==2 else 0
  iron.stage=13 if grade==2 else 3;iron.intent=g.EnemyPlans.build(g,iron)
  g._enemy_operation(iron,iron.intent)
  if grade==2:
   t.check(g.state.logs.slice(log_start).any(func(row):return not row.data.get("replaced",[]).is_empty()),"IRON INSTALL full weak body uses the formal replacement transaction")
  else:
   t.check(victim.durability>before,"IRON INSTALL unavailable ordinary replacements fall back to reinforcement")
   victim.durability=victim.maximum*0.7;before=victim.durability
   iron.stage=4;iron.intent=g.EnemyPlans.build(g,iron)
   g._enemy_operation(iron,iron.intent)
   t.check(victim.durability>before,"IRON INSTALL unavailable composite replacements share reinforcement fallback")

static func fallback_progression(t) -> void:
 var counts=[3,3,4,4,5,6]
 for witch in [false,true]:
  for level in range(counts.size()):
   var g=encounter(witch);var iron=enemy(g,"iron_man")
   if not witch: g.RelicEffects.gain(g,"cursed_plate_lock")
   var initial_ids=g.state.special_equipment.map(func(item):return item.id)
   iron.iron_enhancements=level;iron.stage=5*level+2;iron.intent=g.EnemyPlans.build(g,iron)
   g.IronMan.apply_capture_equipment(g,iron)
   var installed=g.state.special_equipment.filter(func(item):return item.id not in initial_ids and not g.SpecialEquipment.is_reinforcement(item))
   var grade=3 if level>=3 else 2;var tier=3 if level>=1 else 2
   t.check(installed.size()==mini(5,counts[level]) and installed.all(func(item):return item.grade==grade and g.tier(item.durability,item.maximum)==tier and g.SpecialEquipment.exclusive_family(item.type)!="cup"),"IRON FALLBACK actual opening respects independent count, grade and tier: "+str([witch,level]))
   t.check(g.validate()=="","IRON FALLBACK generated gear and announced intent remain valid")
   if level==5:
    var rest={"pool":"special","templates":g.SpecialEquipment.prison_pool(grade,false,false),"grade":grade,"tier":tier,"count":1,"replace":true,"protected_ids":installed.map(func(item):return item.id)}
    t.check(g.IronMan.fallback_spec(iron).count==6 and not g.Application.can_apply(g,rest,iron.id),"IRON FALLBACK sixth requested piece cannot displace the five pieces already installed in this batch")
   if level>0:
    g.CaptureBind.apply_bind(g,iron);g.CaptureBind.damage_bind(g,100,"测试替代降级")
    var expected_level=level-1
    var expected={"count":counts[expected_level],"grade":3 if expected_level>=3 else 2,"tier":3 if expected_level>=1 else 2}
    t.check(g.IronMan.fallback_spec(iron)==expected,"IRON FALLBACK escape retracts only the removed tier of the alternative upgrade sequence")
 var g=encounter(true);var iron=enemy(g,"iron_man")
 g.IronMan.apply_capture_equipment(g,iron)
 var existing=g.state.special_equipment.map(func(item):return item.id)
 iron.iron_enhancements=3;iron.stage=20;iron.intent=g.EnemyPlans.build(g,iron)
 t.check(t.action(g,"end").ok and g.state.special_equipment.any(func(item):return item.id not in existing and item.grade==3),"IRON FALLBACK formal recharge applies the upgraded special-equipment profile")

static func energy_remainder(t) -> void:
 var g=encounter();t.action(g,"end")
 g.CaptureBind.energy_spent(g,4)
 g=Save.roundtrip(t,g,"iron legal four-energy remainder")
 t.check(g.state.guard_bind.sources.iron_man.energy==4 and g.state.guard_bind.sources.iron_drone.energy==1 and g.CaptureBind.view(g).detail.contains("4/5") and g.CaptureBind.view(g).detail.contains("1/3"),"IRON ENERGY independent saved remainders and visible thresholds use five and three")
 var before=g.export_snapshot();var invalid=before.duplicate(true)
 invalid.guard_bind.sources.iron_man.energy=5
 t.check(g.Snapshot.check(invalid,g)!="" and not g.restore_snapshot(invalid).ok and g.state==before,"IRON ENERGY unsettled threshold value rejects and rolls back the save restore")
 g.CaptureBind.energy_spent(g,1)
 t.check(g.state.guard_bind.sources.iron_man.energy==0 and g.state.guard_bind.sources.iron_drone.energy==2,"IRON ENERGY restored boss remainder triggers on fifth energy while drone retains two")
 before=g.export_snapshot();invalid=before.duplicate(true)
 invalid.guard_bind.sources.iron_drone.energy=3
 t.check(g.Snapshot.check(invalid,g)!="" and not g.restore_snapshot(invalid).ok and g.state==before,"IRON ENERGY drone threshold rejects atomically instead of admitting an unsettled trigger")

static func support_contract(t) -> void:
 var g=encounter()
 var drone=enemy(g,"iron_drone");var box=enemy(g,"binding_box")
 t.check(g.CaptureBind.initial_value(g,drone)==20 and g.CaptureBind.initial_value(g,box)==20,"IRON SUPPORT encounter capture declarations are twenty each")
 drone.intent.delayed=true
 t.check(t.action(g,"end").ok and not g.CaptureBind.has_bind(g,"iron_drone"),"IRON SUPPORT interrupted drone opening does not apply its source")
 var before=g.state.guard_bind.progress
 g.CaptureBind.energy_spent(g,5)
 t.check(g.state.guard_bind.progress==before and not g.state.equipment.any(func(item):return item.template in g.IronMan.TAPE_POOL),"IRON SUPPORT living drone without its capture cannot piggyback on the boss trigger")
 t.check(t.action(g,"end").ok,"IRON SUPPORT interrupted opening prepares again")
 t.check(t.action(g,"end").ok and g.CaptureBind.has_bind(g,"iron_drone"),"IRON SUPPORT preparation reapplies the independent capture")
 drone=enemy(g,"iron_drone")
 t.check(drone.intent.kind=="idle" and g.state.guard_bind.sources.iron_drone.energy==0,"IRON SUPPORT captured drone has no extra enemy-turn action")
 g.CaptureBind.damage_bind(g,100,"测试解除")
 t.check(drone.intent.kind=="bind_prepare","IRON SUPPORT escape announces drone preparation")
 t.check(t.action(g,"end").ok and enemy(g,"iron_drone").intent.kind=="bind_apply","IRON SUPPORT next enemy turn prepares rather than applying effects")
 t.check(t.action(g,"end").ok and g.CaptureBind.has_bind(g,"iron_drone"),"IRON SUPPORT prepared drone reapplies capture")
 g._defeat_enemy(enemy(g,"iron_drone"))
 before=g.state.guard_bind.progress
 g.CaptureBind.energy_spent(g,3)
 t.check(not g.CaptureBind.has_bind(g,"iron_drone") and g.state.guard_bind.progress==before,"IRON SUPPORT defeat removes the drone trigger independently")
 for boss_encounter in [true,false]:
  g=encounter()
  if not boss_encounter: g.state.room_encounters.entrance="binding_box_solo"
  box=enemy(g,"binding_box")
  g.CaptureBind.apply_bind(g,box)
  t.check(g.state.guard_bind.progress==(20 if boss_encounter else 40),"IRON BOX capture override is isolated from ordinary encounters")
  var plan=g.EnemyPlans.build(g,box)
  t.check(plan.kind=="apply" and plan.count==2 and plan.grade==2 and plan.tier==(1 if boss_encounter else 2),"IRON BOX first cycle application uses encounter-specific tightness")
  t.check(g.EnemyPlans.installation_intents(g,box)[0].tier==plan.tier,"IRON BOX fallback declaration shares the actual application profile")
  g._enemy_operation(box,plan)
  t.check(g.state.equipment.size()==2 and g.state.equipment.all(func(item):return item.grade==2 and g.tier(item.durability,item.maximum)==plan.tier),"IRON BOX application execution wears two restraints at the declared grade and tier")
  var seen=false
  for attempt in range(32):
   plan=g.EnemyPlans.build(g,box)
   if plan.kind!="tighten_budget": continue
   seen=true
   t.check(plan.budget==(2 if boss_encounter else 4),"IRON BOX reinforcement branch uses encounter-specific total tiers")
   var tiers_before=g.state.equipment.reduce(func(total,item):return total+g.tier(item.durability,item.maximum),0)
   g._enemy_operation(box,plan)
   var tiers_after=g.state.equipment.reduce(func(total,item):return total+g.tier(item.durability,item.maximum),0)
   t.check(tiers_after-tiers_before==2,"IRON BOX reinforcement executes all available tiers without exceeding its budget")
   break
  t.check(seen,"IRON BOX deterministic fixture reaches the reinforcement alternative")

static func legacy_drone(t) -> void:
 var g=encounter();t.action(g,"end")
 var old=g.export_snapshot()
 old.save_revision=g.Snapshot.IRON_DRONE_REVISION
 var drone=old.enemies.filter(func(e):return e.type=="iron_drone")[0]
 drone.erase("guard");drone.intent={"kind":"idle","text":"待机","delayed":true}
 old.guard_bind.sources.erase("iron_drone")
 var random_before=old.rng.duplicate(true)
 t.check(g.restore_snapshot(old).ok and g.state.save_revision==g.Snapshot.REVISION,"IRON SAVE previous revision acquires drone action state")
 t.check(enemy(g,"iron_drone").intent.kind=="bind_prepare" and enemy(g,"iron_drone").intent.delayed and not g.CaptureBind.has_bind(g,"iron_drone") and g.state.rng==random_before,"IRON SAVE migration preserves interruption and randomness without fabricating capture")
 var stable=g.export_snapshot();var invalid=stable.duplicate(true)
 invalid.enemies.filter(func(e):return e.type=="iron_drone")[0].erase("guard")
 t.check(not g.restore_snapshot(invalid).ok and g.state==stable,"IRON SAVE current revision still rejects missing drone progress atomically")
 invalid=old.duplicate(true)
 invalid.enemies.filter(func(e):return e.type=="iron_drone")[0].guard={"bind_ready":"broken","cycle_step":0}
 t.check(not g.restore_snapshot(invalid).ok and g.state==stable,"IRON SAVE migration does not conceal corrupt existing drone progress")

static func capture_postures(t) -> void:
 var g=encounter()
 t.check(g.CaptureBind.allowed_postures(g).is_empty() and g.CaptureBind.fixed_posture(g)=="","CAPTURE POSTURE absent sources impose no fixed pose")
 g.CaptureBind.apply_bind(g,enemy(g,"iron_man"))
 t.check(g.state.posture=="sit" and g.CaptureBind.allowed_postures(g)==["sit","lie"],"CAPTURE POSTURE boss corrects standing while retaining both authored poses")
 g.state.posture="lie"
 var before=g.export_snapshot()
 var allowed=g.CaptureBind.allowed_postures(g)
 allowed.clear()
 t.check(g.CaptureBind.allowed_postures(g)==["sit","lie"] and g.CaptureBind.fixed_posture(g)=="" and g.state==before,"CAPTURE POSTURE queries are isolated and preserve a legal pose, state and randomness")
 t.check(g.CaptureBind.posture_reason(g,"sit")=="" and g.CaptureBind.posture_reason(g,"stand")!="","CAPTURE POSTURE boss allows sitting but rejects standing through the shared query")
 g.CaptureBind.apply_bind(g,enemy(g,"binding_box"))
 t.check(g.state.posture=="sit" and g.CaptureBind.allowed_postures(g)==["sit"] and g.CaptureBind.fixed_posture(g)=="sit","CAPTURE POSTURE box and boss intersect at sitting")
 t.check(g.CaptureBind.posture_reason(g,"lie")!="","CAPTURE POSTURE combined sources reject the boss-only lying option")
 g._defeat_enemy(enemy(g,"binding_box"))
 t.check(g.CaptureBind.allowed_postures(g)==["sit","lie"] and g.CaptureBind.posture_reason(g,"lie")=="","CAPTURE POSTURE defeated box releases only its own restriction")
 g.CaptureBind.damage_bind(g,100,"测试解除")
 t.check(g.CaptureBind.allowed_postures(g).is_empty() and g.CaptureBind.fixed_posture(g)=="" and g.CaptureBind.posture_reason(g,"stand")=="","CAPTURE POSTURE clearing capture removes the final restriction")

static func capture_gain_contract(t) -> void:
 var g=encounter()
 t.check(t.action(g,"end").ok,"IRON GAIN real opening reaches the next player turn")
 var applications=g.state.logs.filter(func(log):return log.data.get("guard_bind",{}).get("action")=="apply")
 t.check(applications.size()==3 and applications.map(func(log):return log.data.guard_bind.value)==[30.0,40.0,50.0],"IRON GAIN initial sources add thirty plus two halves of twenty")
 t.check(g.state.guard_bind.progress==50 and g.state.equipment.is_empty(),"IRON GAIN first player turn skips both box installation and capture addition")
 t.check(g.CaptureBind.view(g).detail.contains("捕缚＋5"),"IRON GAIN box status projects the encounter gain")
 var iron=enemy(g,"iron_man")
 t.check(iron.intent.text=="捕缚＋10","IRON GAIN boss announcement matches the reduced addition")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==65,"IRON GAIN next real round adds boss ten and box five")
 for boss_encounter in [true,false]:
  g=encounter()
  if not boss_encounter: g.state.room_encounters.entrance="binding_box_solo"
  var box=enemy(g,"binding_box")
  g.CaptureBind.apply_bind(g,box)
  var before=g.state.guard_bind.progress
  g=Save.roundtrip(t,g,"box first-turn suppression before upkeep")
  box=enemy(g,"binding_box")
  g.CaptureBind.turn_start(g)
  t.check(g.state.guard_bind.progress==before and g.state.equipment.is_empty(),"IRON GAIN both box variants skip the first upkeep after application across restore")
  g.CaptureBind.turn_start(g)
  t.check(g.state.guard_bind.progress-before==(5 if boss_encounter else 10),"IRON GAIN box upkeep reduction is scoped to the boss encounter")
  t.check(g.state.equipment.size()==1,"IRON GAIN both box variants resume installation on the following upkeep")
  box.carried_indices.clear();box.guard.cycle_step=2
  var plan=g.EnemyPlans.build(g,box)
  before=g.state.guard_bind.progress
  g._enemy_operation(box,plan)
  t.check(plan.kind=="bind_gain" and plan.text==("捕缚进度＋5" if boss_encounter else "捕缚进度＋10") and g.state.guard_bind.progress-before==(5 if boss_encounter else 10),"IRON GAIN empty box reserve uses the same encounter gain in plan and execution")
  var stable=g.export_snapshot();var invalid=stable.duplicate(true)
  invalid.guard_bind.sources.binding_box.skip_turn_start="false"
  t.check(not g.restore_snapshot(invalid).ok and g.state==stable,"IRON GAIN corrupt upkeep suppression cannot silently skip recurring effects on restore")
  var pieces=g.state.equipment.size()
  g.CaptureBind.damage_bind(g,100,"测试重新捕缚")
  g.CaptureBind.apply_bind(g,box)
  before=g.state.guard_bind.progress
  g.CaptureBind.turn_start(g)
  t.check(g.state.guard_bind.progress==before and g.state.equipment.size()==pieces,"IRON GAIN reapplying either box capture also skips its first upkeep")

static func interrupt_contract(t) -> void:
 for witch in [false,true]:
  for stage in range(1,7):
   var g=encounter(witch)
   var iron=enemy(g,"iron_man")
   for support in g.state.enemies:
    if support.type!="iron_man": support.gone=true;support.defeated=true;support.hp=0;support.intent={}
   iron.stage=stage;iron.intent=g._plan(iron)
   var kind=iron.intent.kind
   var attack={"type":"witch_legs" if witch else "strike","form":1 if witch else 0,"enemy":iron.id}
   if witch: g.state.witch_charges.legs=4
   else: g.Cards.grant_buff(g,"infusion_free")
   var candidate=t.find_action(g,"attack",attack)
   t.check(candidate.valid and candidate.payload.interrupt and g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok,"IRON INTERRUPT real character attack commits "+str([witch,stage]))
   iron=enemy(g,"iron_man")
   t.check(iron.intent.kind==kind and iron.intent.delayed and iron.stage==stage,"IRON INTERRUPT post-action capture observation preserves delayed intent "+str([witch,stage]))
   var before=g.export_snapshot();g.get_view();g.command_facts()
   t.check(g.state==before,"IRON INTERRUPT projections preserve delayed intent and random state")
   var twin=Save.roundtrip(t,g,"iron interrupted action "+str([witch,stage]))
   t.check(twin!=null and enemy(twin,"iron_man").intent.delayed,"IRON INTERRUPT save retains delayed action")
   t.check(t.action(g,"end").ok and enemy(g,"iron_man").stage==stage and enemy(g,"iron_man").intent.kind==kind and not enemy(g,"iron_man").intent.delayed,"IRON INTERRUPT enemy skips one action without advancing cycle "+str([witch,stage]))
   t.check(t.action(g,"end").ok and enemy(g,"iron_man").stage==stage+1,"IRON INTERRUPT original action resumes on following enemy turn "+str([witch,stage]))
