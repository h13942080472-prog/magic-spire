extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const D=preload("res://data/special_equipment.gd")

static func run(t) -> void:
 cup_exclusion(t)
 catalog_and_projection(t)
 capacity_and_composites(t)
 pleasure_and_battery(t)
 climax_slip(t)
 escape_routes(t)
 cup_reinforcements(t)
 manual_insertables(t)
 registry_paths(t)
 environment_classes(t)
 chastity_locks(t)
 unlocked_plate_strain(t)
 slip_mana(t)
 upgrade_components(t)

static func cup_exclusion(t) -> void:
 D.ensure_catalog()
 var types=D.TYPES.keys().filter(func(type):return D.exclusive_family(type)=="cup")
 for first in types:
  for second in types:
   var g=Game.new(42)
   var cup=g._install_special(first,D.DESIGNS[first].slots[0],3)
   var before=g.export_snapshot()
   t.check(not cup.is_empty() and g._install_special(second,D.DESIGNS[second].slots[0],3).is_empty() and g.state==before,"CUP EXCLUSION all types and grades share one slot: "+first+" / "+second)
 var g=Game.new(42)
 var cup=g._install_special("glans_cup_medium","special_2_b",2)
 var result=g.Application.execute_concrete(g,{"kind":"special_install","type":"urethral_full_cup_high"},"fixture",true)
 t.check(result.ok and g._equipment(cup.id).is_empty() and g.state.special_equipment.filter(func(e):return D.exclusive_family(e.type)=="cup").size()==1 and g.validate()=="","CUP EXCLUSION authorized higher-grade cross-family replacement removes the old cup")
 var before=g.export_snapshot()
 result=g.Application.execute_concrete(g,{"kind":"special_install","type":"glans_cup_medium"},"fixture",true)
 t.check(not result.ok and g.state==before,"CUP EXCLUSION weaker cross-family replacement rolls back")
 g=Game.new(42);cup=g._install_special("full_cup_medium","special_2_a",3)
 var band=g.state.special_equipment.filter(func(e):return D.reinforcement_matches(e,cup))[0]
 result=g.Application.execute_concrete(g,{"kind":"special_install","type":"forced_milking_cup_high"},"fixture",true)
 t.check(result.ok and g._equipment(cup.id).is_empty() and g._equipment(band.id).is_empty() and g.validate()=="","CUP EXCLUSION replacement also removes the previous cup's band")
 g=Game.new(42);cup=g._install_special("glans_cup_medium","special_2_b",2)
 t.check(not g._install_special("shaft_ring_low","special_2_a",1).is_empty() and g.validate()=="","CUP EXCLUSION other toy families retain their existing capacity rules")

static func unlocked_plate_strain(t) -> void:
 for type in D.CHASTITY_TYPES.filter(func(id):return id!="cursed_plate_lock"):
  var g=Game.new(42,false,"equipment",true,true,25)
  g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
  var lock=g._install_special(type,"special_2_a",3)
  var strap=g.state.special_equipment.filter(func(e):return e.owner_id==lock.id)[0]
  var other=g._install_special("nipple_ring_medium","special_1_a",2)
  var card=t.grant_fixture_card(g,"strain")
  var before=g.export_snapshot()
  var blocked=t.find_action(g,"card",{"uid":card.uid,"target":lock.id,"free":false})
  t.check(not blocked.valid and not g.dispatch(g.command(blocked.payload,g.state.version),g.state.version).ok and g.state==before,"PLATE STRAIN locked root rejects action without payment")
  var unlock=t.grant_fixture_card(g,"unlock")
  t.check(t.action(g,"card",{"uid":unlock.uid,"target":lock.id,"free":false}).ok,"PLATE STRAIN formal unlock opens root")
  lock=g._equipment(lock.id)
  # The attached tier-three band must not block a looser unlocked owner.
  lock.durability=lock.maximum*0.8
  before=g.export_snapshot()
  g._apply_equipment_damage(lock,0,"strain")
  t.check(g.state==before,"PLATE STRAIN zero damage does not remove root or band")
  var candidate=t.find_action(g,"card",{"uid":card.uid,"target":lock.id,"free":false})
  var preview=preload("res://core/release_view.gd").preview(g,candidate)
  t.check(candidate.valid and candidate.payload.preview.damage>0 and preview.after==0 and g.state==before,"PLATE STRAIN positive hit previews whole removal despite tighter band and stays read-only")
  t.check(not g.dispatch(g.command(candidate.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"PLATE STRAIN stale candidate rolls back resources and equipment")
  t.check(g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok and g._equipment(lock.id).is_empty() and g._equipment(strap.id).is_empty() and not g._equipment(other.id).is_empty() and g.state.energy==before.energy-candidate.cost,"PLATE STRAIN one paid hit removes root and own band only")
 var g=Game.new(42)
 g.RelicEffects.gain(g,"cursed_plate_lock")
 var cursed=g.state.special_equipment.filter(D.is_cursed_plate)[0]
 var before=g.export_snapshot()
 g._apply_equipment_damage(cursed,999,"strain")
 t.check(not D.unlocked_release(cursed,"strain") and g.escape_preview(cursed,"strain",999).reason==D.CURSED_PLATE_REASON and g.state==before,"PLATE STRAIN cursed branch keeps its exclusive key protection")

static func slip_mana(t) -> void:
 var g=Game.new(42,false,"equipment",true,true,25)
 g._install_special("negative_plate_lock_catheter_medium","special_2_a",2)
 g.state.mana=30;g.state.relics=["mana_earring"]
 g.Pressure.gain(g,120,"测试来源",true,["special_2_a"])
 var before=g.export_snapshot();var view=g.get_view();g.command_facts()
 var status=view.statuses.filter(func(entry):return entry.id=="slip_ejaculation")
 t.check(g.state==before and status.size()==1 and JSON.stringify(status[0]).contains("魔力") and JSON.stringify(status[0]).contains("10"),"SLIP MANA readonly status describes deferred loss")
 g._begin_player_turn()
 g.Pressure.gain(g,120,"测试来源",true,["special_2_a"])
 t.check(g.state.mana==20 and g.state.slip_ejaculation_turns==2,"SLIP MANA repeated trigger refreshes duration without immediate loss or stacked ticks")
 g.state.special_equipment.clear();g._cleanup()
 g.Pressure.gain(g,100,"测试来源",true)
 t.check(g.state.mana==20 and g.state.slip_ejaculation_turns==2,"SLIP MANA active debuff prevents immediate ordinary climax loss after triggering equipment is removed")
 g.state.mana=3;g.state.temporary_mana=20
 g._begin_player_turn()
 t.check(g.state.mana==0 and g.state.temporary_mana==20 and g.state.slip_ejaculation_turns==1 and g.state.combat.mana_spent==0,"SLIP MANA low resources clamp to zero without spending temporary mana or activating spell-payment relics")
 g._begin_player_turn();g.state.mana=20;g._begin_player_turn()
 t.check(g.state.mana==20 and g.state.slip_ejaculation_turns==0,"SLIP MANA zero-mana turn still expires and later turns stop draining")
 g.Pressure.gain(g,100,"测试来源",true)
 t.check(g.state.mana==0,"SLIP MANA normal immediate climax loss resumes after expiration")

static func upgrade_components(t) -> void:
 for reverse_order in [false,true]:
  var g=Game.new(42,false,"equipment",true,true,25)
  var old=g._install_special("negative_plate_lock_medium","special_2_a",3)
  var old_strap=g.state.special_equipment.filter(D.is_reinforcement)[0]
  var neighbour=g._install_special("nipple_ring_medium","special_1_a",2).duplicate(true)
  if reverse_order: g.state.special_equipment.reverse()
  var before=g.export_snapshot()
  var request={"kind":"special_install","type":"negative_vibrator_lock_catheter_high","slot":"special_2_a","grade":3,"tier":3}
  for protected_id in [old.id,old_strap.id]:
   var spec={"pool":"special","templates":[request.type],"grade":3,"tier":3,"count":1,"replace":true,"protected_ids":[protected_id]}
   t.check(not g.Application.can_apply(g,spec,"fixture") and g.state==before,"SPECIAL upgrade query excludes a protected root or component without mutation")
   var blocked=g.Application.execute_concrete(g,request,"fixture",true,[protected_id])
   t.check(not blocked.ok and g.state==before,"SPECIAL frozen upgrade cannot remove a protected root or component")
   g.state=before.duplicate(true)
   var spec_before=spec.duplicate(true)
   var batch=g.Application.execute(g,spec,"fixture")
   t.check(not batch.ok and batch.count==0 and g.state==before and spec==spec_before,"SPECIAL batch execution preserves caller protection just like its query and frozen submission")
   g.state=before.duplicate(true)
  var result=g.Application.execute_concrete(g,request,"fixture",true,[neighbour.id])
  t.check(result.ok and g._equipment(old.id).is_empty() and g._equipment(old_strap.id).is_empty(),"SPECIAL upgrade removes the old root and owned component before cleanup regardless of storage order")
  var straps=g.state.special_equipment.filter(D.is_reinforcement)
  t.check(straps.size()==1 and straps[0].owner_id==result.installed[0].id and g.validate()=="","SPECIAL upgrade immediately leaves one valid component owned by the new root")
  t.check(result.removed.size()==2 and old.id in result.removed and old_strap.id in result.removed,"SPECIAL upgrade receipt includes both removed physical ids for shared batch and event reporting")
  t.check(g._equipment(neighbour.id)==neighbour and g.state.energy==before.energy and g.state.mana==before.mana and g.state.pressure==before.pressure and g.state.rng==before.rng and g.state.deck==before.deck,"SPECIAL upgrade preserves unrelated equipment, resources, random streams and deck")

 var grouped=Game.new(42,false,"equipment",true,true,25)
 var covered=grouped._install_special("full_cup_medium","special_2_a",2)
 var group_before=grouped.export_snapshot()
 var requests=[{"kind":"special_install","type":"negative_plate_lock_medium","slot":"special_2_a","grade":2,"tier":3},{"kind":"install","template":"rope","slot":"ankle","grade":1,"tier":2,"variant":0}]
 var result=grouped.Application.execute_concrete(grouped,{"kind":"application_group","requests":requests},"fixture",true,[covered.id])
 t.check(not result.ok and grouped.state==group_before,"SPECIAL group preview cannot bypass protection through an automatic cross-family replacement")

static func catalog_and_projection(t) -> void:
 var g=Game.new(42,true,"special_equipment")
 t.check(g.validate()=="" and g.state.special_equipment.size()==3,"SPECIAL real equipment practice validates")
 t.check(g.state.pressure==8 and g.state.special_equipment[0].remaining==8,"SPECIAL first player turn applies the powered nipple clamp once")
 t.check(g.state.equipment.is_empty() and g.level("arms")==0 and g.level("legs")==0 and g.item_capacity()==3,"SPECIAL equipment does not change ordinary restraint or carried-item capacity")
 var groups=g.get_view().body_groups
 t.check(groups.map(func(b):return b.id)==["eyes","mouth","neck","upper_arm","special_1","forearm","wrist","hands","special_2","special_3","thigh","calf","ankle","feet"],"SPECIAL anatomical regions keep their requested display order")
 t.check(groups.filter(func(b):return b.special).map(func(b):return b.items.size())==[1,4,2],"SPECIAL seven concrete slots project in three named regions")
 t.check(groups[4].name=="乳头" and groups[8].name=="肉棒" and groups[9].name=="双穴","SPECIAL player-facing regions no longer use placeholder names")
 t.check(D.slot_name("special_2_a")=="柱身" and D.slot_name("special_2_d")=="马眼" and D.slot_name("special_3_b")=="后庭","SPECIAL concrete subslots use anatomical names")
 var before=g.state.duplicate(true)
 groups[4].items[0].equipment[0].name="altered"
 g.get_view();g.command_facts()
 t.check(g.state==before,"SPECIAL view and candidate projection are read-only")
 for slot in D.slots():
  t.check(g._install_template("rope",slot,4,10,false,"test").is_empty(),"SPECIAL ordinary restraint factory rejects reserved slot "+slot)
 var type_ids=D.TYPES.keys();var design_ids=D.DESIGNS.keys()
 type_ids.sort();design_ids.sort()
 t.check(type_ids==design_ids,"SPECIAL trigger and fixed-design catalogs pair by exact stable ID")
 var required_types=["forced_milking_cup_high","negative_plate_lock_medium","negative_plate_lock_catheter_medium","negative_vibrator_lock_catheter_high","cursed_plate_lock","chastity_reinforcement_medium","chastity_reinforcement_high","cup_reinforcement_medium","cup_reinforcement_high"]
 for family in ["nipple_clamp","nipple_ring","shaft_ring","corona_ring","urethral_rod","vaginal_egg","anal_egg","external_wand","crotch_rope"]:
  for grade in ["low","medium","high"]: required_types.append(family+"_"+grade)
 for family in ["glans_cup","full_cup","urethral_full_cup"]:
  for grade in ["medium","high"]: required_types.append(family+"_"+grade)
 for type in required_types:
  t.check(D.TYPES.has(type),"SPECIAL required built-in equipment remains registered "+type)
 for family in ["nipple_clamp","nipple_ring","shaft_ring","corona_ring","urethral_rod","vaginal_egg","anal_egg","external_wand","crotch_rope","glans_cup","full_cup","urethral_full_cup","forced_milking_cup"]:
  t.check(D.STIMULATION_TEXTS.has(family) and not D.STIMULATION_TEXTS[family].is_empty(),"SPECIAL every playable family owns current-wear stimulation prose "+family)
 for type in D.TYPES:
  if D.TYPES[type].get("component_only",false): continue
  var wear=D.wear_text(type)
  t.check(not wear.is_empty() and wear.contains(D.TYPES[type].name) and not wear.contains("{name}"),"SPECIAL every built-in type owns reusable exact-name wear prose "+type)
 t.check(not D.wear_text("vaginal_egg_low").contains("牵引线") and not D.wear_text("anal_egg_low").contains("牵引线"),"SPECIAL wireless internal eggs never invent a retrieval wire")
 var pressure_view=g.get_view().pressure
 var status=g.get_view().statuses.filter(func(entry):return entry.id=="equipment_stimulation")[0]
 var pressure_copy="\n".join(pressure_view.sources.map(func(source):return source.text))
 t.check(pressure_copy.contains("凸粒隔着肉棒正面清楚鼓起") and pressure_copy.contains("基础6 × 部位倍率1.5 × 当前来源倍率1＝9快感"),"SPECIAL status copy names urethral stimulation and exposes its current gain formula")
 var crotch_sources=pressure_view.sources.filter(func(source):return source.name.contains("裆部股绳"))
 t.check(pressure_view.sources.size()==3 and crotch_sources.size()==1 and crotch_sources[0].name.ends_with(" · 小穴、后庭"),"SPECIAL pressure source list deduplicates multi-position roots and names their full current location")
 t.check(status.detail.contains("绳股紧贴胯下") and status.detail.contains("基础5 × 部位倍率1 × 当前来源倍率1＝5快感") and not status.detail.contains("可用挣扎牌") and not status.detail.contains("无手部操作时"),"SPECIAL compact equipment status keeps formulas without escape-guide repetition")
 var rod_view=groups[8].items.filter(func(item):return item.slot=="special_2_d")[0].equipment[0]
 t.check(rod_view.description.contains("高潮时滑脱伤害：6－紧度2－等级2＝2") and rod_view.description.contains("尿道内壁与外侧突起"),"SPECIAL equipment detail shows current climax formula and physical stimulation")
 g=Game.new(42,true,"plate_lock")
 var locks=g.state.special_equipment.filter(D.is_chastity)
 var straps=g.state.special_equipment.filter(D.is_reinforcement)
 t.check(g.state.phase=="rest" and g.state.practice_kind=="plate_lock" and locks.size()==1 and locks[0].type=="negative_vibrator_lock_catheter_high" and locks[0].locked and g.tier(locks[0].durability,locks[0].maximum)==3,"SPECIAL plate-lock practice starts through the normal rest flow with one locked high-grade tier-three root")
 t.check(straps.size()==1 and straps[0].owner_id==locks[0].id and g.Pressure.maximum(g)==130 and g.state.hand.any(func(card):return card.type=="unlock"),"SPECIAL plate-lock practice attaches its real reinforcement, dynamic maximum and an immediately drawn unlock card")
 t.check(g.validate()=="","SPECIAL plate-lock practice is a valid isolated practice state")

static func capacity_and_composites(t) -> void:
 var g=Game.new(42)
 t.check(D.slots().map(func(slot):return D.capacity(slot))==[2,2,2,2,1,1,1],"SPECIAL corrected per-slot capacities are registered")
 var cup=g._install_special("full_cup_medium","special_2_a")
 var ring=g._install_special("corona_ring_low","special_2_c")
 var shaft=g._install_special("shaft_ring_low","special_2_a")
 var rod=g._install_special("urethral_rod_low","special_2_d")
 t.check(not cup.is_empty() and not ring.is_empty() and not shaft.is_empty() and not rod.is_empty() and g.validate()=="","SPECIAL one cup and compatible non-cup families fill shared positions atomically")
 t.check(D.occupied_slots(cup)==["special_2_a","special_2_b","special_2_c"] and g.targets_at("special_2_c").has(cup),"SPECIAL one composite cup root covers and targets through every declared slot")
 var before=g.state.duplicate(true)
 t.check(g._install_special("shaft_ring_high","special_2_a").is_empty() and g.state==before,"SPECIAL same family cannot be duplicated even when a slot has room")
 t.check(g._install_special("forced_milking_cup_high","special_2_a").is_empty() and g.state==before,"SPECIAL composite install rejects atomically when any covered slot is full")
 var card=t.hand_card(g,"strain")
 var choices=g.command_facts().filter(func(c):return c.payload.get("uid","")==card.uid and c.payload.get("target","")==cup.id)
 t.check(choices.size()==1,"SPECIAL a multi-slot physical root creates one card target, not one per covered slot")
 var saved=g.export_snapshot();var restored=Game.new(17)
 t.check(restored.restore_snapshot(saved).ok and restored.state.special_equipment==g.state.special_equipment,"SPECIAL composite coverage and independent durability survive save restore")
 saved.special_equipment[0].coverage=["special_2_a"]
 before=restored.state.duplicate(true)
 t.check(not restored.restore_snapshot(saved).ok and restored.state==before,"SPECIAL forged partial composite coverage rejects atomically")

 g=Game.new(42)
 var vaginal=g._install_special("vaginal_egg_low","special_3_a")
 var anal=g._install_special("anal_egg_low","special_3_b")
 var rope=g._install_special("crotch_rope_low","special_3_a")
 t.check(not vaginal.is_empty() and not anal.is_empty() and not rope.is_empty() and g.validate()=="","SPECIAL zero-capacity crotch rope can coexist with both occupied cavity slots")
 t.check(D.used_capacity(g.state.special_equipment,"special_3_a")==1 and D.used_capacity(g.state.special_equipment,"special_3_b")==1,"SPECIAL crotch rope occupies both child displays without consuming either capacity")
 t.check(D.occupied_slots(rope)==["special_3_a","special_3_b"] and D.TYPES[rope.type].stimulates==["special_3_a"],"SPECIAL crotch rope is shown in both cavities but stimulates only the vagina")

static func pleasure_and_battery(t) -> void:
 var g=Game.new(42)
 for type in D.TYPES:
  if D.TYPES[type].duration<=0: continue
  t.check(D.TYPES[type].duration=={1:6,2:9,3:12}[D.DESIGNS[type].grade],"SPECIAL powered equipment has the strengthened grade battery: "+type)
 var shaft=g._install_special("shaft_ring_low","special_2_a")
 var rod=g._install_special("urethral_rod_low","special_2_d")
 var glans=g._install_special("glans_cup_medium","special_2_b")
 t.check(is_equal_approx(D.gain(shaft,"turn_start"),2.4),"SPECIAL shaft gain applies the 0.6 sensitivity multiplier")
 t.check(is_equal_approx(D.gain(rod,"energy"),6.0),"SPECIAL urethral gain applies the 1.5 sensitivity multiplier")
 t.check(is_equal_approx(D.gain(glans,"turn_start"),24.0),"SPECIAL multi-position cup combines the sensitivity of stimulated positions")

 g=Game.new(42)
 var clamp=g._install_special("nipple_clamp_low","special_1_a")
 for i in range(6): g._tick_special("turn_start")
 t.check(g.state.special_equipment.has(clamp) and clamp.remaining==0 and g.state.pressure==36,"SPECIAL battery applies exactly its declared number of player-turn pulses")
 g._tick_special("turn_start")
 t.check(g.state.special_equipment.has(clamp) and g.state.pressure==36 and D.gain(clamp,"turn_start")==0,"SPECIAL empty battery stops stimulation but leaves the equipment installed")

 g=Game.new(42)
 rod=g._install_special("urethral_rod_low","special_2_d")
 var pressure=g.state.pressure
 t.check(t.action(g,"attack",{"type":"heavy"}).ok and g.state.pressure==pressure+6,"SPECIAL a multi-energy action triggers each energy-paid effect only once")
 var stale=t.find_action(g,"end");var before=g.state.duplicate(true)
 t.check(not g.dispatch(g.command(stale.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SPECIAL stale command causes no pleasure pulse or state change")

static func climax_slip(t) -> void:
 for pair in [["urethral_rod_low",3.0],["urethral_rod_medium",2.0],["urethral_rod_high",1.0]]:
  var g=Game.new(42)
  var rod=g._install_special(pair[0],"special_2_d")
  var neighbour=g._install_special("shaft_ring_low","special_2_a")
  g.state.pressure=99
  var choice=t.find_action(g,"attack",{"type":"heavy"})
  var before=g.export_snapshot()
  t.check(not g.dispatch(g.command(choice.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==before,"CLIMAX SLIP stale card leaves urethral and neighbouring equipment unchanged: "+pair[0])
  var durability=rod.durability
  t.check(g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(rod.id).durability,durability-pair[1]) and g._equipment(neighbour.id).durability==neighbour.durability,"CLIMAX SLIP formal climax applies 6 minus tier 2 minus grade only to urethral rod: "+pair[0])
  var records=g.state.logs.filter(func(log):return log.data.has("climax_slip"))
  t.check(records.size()==1 and records[0].data.climax_slip.tightness==2 and records[0].data.climax_slip.grade==rod.grade and records[0].data.climax_slip.damage==pair[1] and records[0].text.contains("固定滑脱伤害"),"CLIMAX SLIP structured mechanical log preserves formula and actual damage: "+pair[0])
 var g=Game.new(42)
 var rod=g._install_special("urethral_rod_high","special_2_d",3)
 g.state.pressure=99
 t.check(t.action(g,"attack",{"type":"heavy"}).ok and g._equipment(rod.id).durability==rod.maximum and g.state.logs.any(func(log):return log.data.has("climax_slip") and log.data.climax_slip.damage==0),"CLIMAX SLIP high grade at tier three reaches the exact zero-damage boundary and remains installed")
 g=Game.new(42)
 rod=g._install_special("urethral_rod_low","special_2_d")
 g.Pressure.gain(g,400,"连续高潮",true)
 var sequence=g.state.logs.filter(func(log):return log.data.has("climax_slip"))
 t.check(sequence.size()==3 and sequence.map(func(log):return log.data.climax_slip.tightness)==[2,2,1] and sequence.map(func(log):return log.data.climax_slip.damage)==[3.0,3.0,2.0] and g._equipment(rod.id).is_empty(),"CLIMAX SLIP consecutive climaxes recalculate tightness after each hit and stop once the rod comes out")
 t.check(g.validate()=="" and D.climax_slip_damage({"type":"shaft_ring_low","grade":1},2)==0 and D.climax_slip_rule("urethral_full_cup_medium")=="" and D.climax_slip_rule("urethral_full_cup_high")=="","CLIMAX SLIP unrelated rings and integrated cups remain outside urethral-rod rule")

static func escape_routes(t) -> void:
 for type in ["shaft_ring_low","corona_ring_low","urethral_rod_low","crotch_rope_low","full_cup_medium"]:
  var design=D.DESIGNS[type]
  t.check("strain" in design.methods and "slip" in design.methods and "magic_slip" in design.methods,"SPECIAL physical card families are registered for "+type)
 t.check(D.DESIGNS.urethral_rod_low.environments==["hook"],"SPECIAL urethral rod accepts only hook-class environmental leverage")
 t.check(D.DESIGNS.vaginal_egg_low.methods==["manual"] and D.DESIGNS.anal_egg_low.environments.is_empty(),"SPECIAL wireless insertables expose only their direct manual removal")
 t.check(D.DESIGNS.full_cup_medium.environments==["hook","wall"] and "sharp" not in D.DESIGNS.full_cup_medium.environments,"SPECIAL cups do not accept sharp-class leverage")

 var g=Game.new(42)
 var ring=g._install_special("shaft_ring_low","special_2_a")
 g.add_fixture("wrist",8);g.state.wall_distance=2
 var preview=g.escape_preview(ring,"strain",5)
 t.check(preview.reason.contains("墙壁类") and preview.damage==0,"SPECIAL no usable hand and no contacted environment blocks a physical card")
 g.state.wall_distance=0
 preview=g.escape_preview(ring,"strain",5)
 t.check(preview.reason=="" and preview.damage>0 and preview.assist.hands.is_empty(),"SPECIAL compatible wall contact opens the normal card formula without inventing hand assistance")
 g.state.wall_distance=2
 t.check(g.escape_preview(ring,"magic_slip",5).reason=="" and g.escape_preview(ring,"magic_slip",5).damage>0,"SPECIAL magic slip does not inherit the physical environment gate")

 g=Game.new(42)
 var nipple=g._install_special("nipple_ring_low","special_1_a")
 g.add_fixture("wrist",8);g.state.wall_distance=0
 t.check(g.escape_preview(nipple,"strain",5).reason.contains("尖锐类") and g.escape_preview(nipple,"strain",5).damage==0,"SPECIAL nipple ring cannot substitute ordinary wall contact for its whitelist")
 g._gain_tool("shard")
 var tool=g.state.items[0]
 t.check(t.action(g,"item_install",{"item":tool.id,"mount":"high_wall"}).ok,"SPECIAL sharp environment uses the normal tool installation transaction")
 preview=g.escape_preview(nipple,"strain",5)
 t.check(preview.reason=="" and preview.damage>0,"SPECIAL contacted installed sharp tool opens the card route")
 var card=t.hand_card(g,"strain")
 var candidate=t.find_action(g,"card",{"uid":card.uid,"target":nipple.id,"free":false})
 t.check(candidate.valid and not candidate.payload.tool_bonus.is_empty(),"SPECIAL installed sharp tool remains an existing card-damage passive, not a separate removal action")
 t.check(not g.command_facts().any(func(c):return c.payload.kind=="item_use" and c.payload.get("target","")==nipple.id),"SPECIAL carried tools never create a direct cutting action for sex toys")

 g=Game.new(42,true,"special_equipment")
 var rod=g.state.special_equipment.filter(func(item):return item.type=="urethral_rod_medium")[0]
 g.add_fixture("wrist",8)
 preview=g.escape_preview(rod,"strain",5)
 t.check(preview.reason=="" and preview.damage>0,"SPECIAL rest-room hook opens the urethral rod card route when the height can contact it")
 t.check(not g.command_facts().any(func(c):return c.payload.kind=="hook" and c.payload.get("target","")==rod.id),"SPECIAL hook remains a card prerequisite and never becomes a separate direct action")

static func cup_reinforcements(t) -> void:
 var medium=D.TYPES.urethral_full_cup_medium
 var design=D.DESIGNS.urethral_full_cup_medium
 t.check(medium.name=="中级马眼全包榨精杯" and medium.energy_gain==6.0 and medium.turn_gain==14.0 and medium.duration==9 and design.grade==2 and design.maximum==16 and design.slots==["special_2_a","special_2_b","special_2_c","special_2_d"],"CUP BAND medium urethral full cup owns the authored grade, coverage, battery and stimulation")
 t.check("urethral_full_cup_medium" in D.prison_pool(2,true) and "urethral_full_cup_medium" not in D.prison_pool(2,false),"CUP BAND medium urethral full cup follows the existing prison cup gate")
 for type in ["full_cup_medium","full_cup_high","urethral_full_cup_medium","urethral_full_cup_high"]:
  var g=Game.new(42)
  var cup=g._install_special(type,"special_2_a",3)
  var straps=g.state.special_equipment.filter(func(item):return D.reinforcement_matches(item,cup))
  t.check(not cup.is_empty() and straps.size()==1 and straps[0].grade==cup.grade and D.is_cup_reinforcement(straps[0]) and D.DESIGNS[straps[0].type].capacity_cost==0 and g.validate()=="","CUP BAND tier-three full cup creates one same-grade zero-capacity component: "+type)
  var strap=straps[0]
  var relation_snapshot=g.export_snapshot();var relation_restore=Game.new(17)
  t.check(relation_restore.restore_snapshot(relation_snapshot).ok and relation_restore.state.special_equipment==g.state.special_equipment,"CUP BAND owner relation survives snapshot restore: "+type)
  var before=strap.durability
  g._apply_equipment_damage(strap,5,"strain")
  t.check(strap.durability==before,"CUP BAND component ignores non-cutting damage: "+type)
  g._apply_equipment_damage(strap,5,"cut")
  t.check(strap.durability==before-5 and not g._equipment(cup.id).is_empty(),"CUP BAND cutting damages the component without removing its owner: "+type)
  var blocked=g.escape_preview(cup,"slip",20)
  t.check(blocked.reason.contains("固定带") and blocked.damage==0 and g.escape_preview(cup,"magic_slip",20).reason.contains("固定带"),"CUP BAND surviving component blocks ordinary and magic slip: "+type)
  var durability=cup.durability
  g._apply_equipment_damage(cup,20,"slip")
  t.check(cup.durability==durability,"CUP BAND direct slip resolution cannot bypass the component: "+type)
  var strain=g.escape_preview(cup,"strain",20)
  t.check(strain.reason=="" and strain.damage>0,"CUP BAND strain remains a direct route against the cup body: "+type)
  g._apply_equipment_damage(cup,cup.durability,"strain");g._cleanup()
  t.check(g._equipment(cup.id).is_empty() and g._equipment(strap.id).is_empty() and g.validate()=="","CUP BAND owner removal cascades its component: "+type)
 var g=Game.new(42)
 var cup=g._install_special("urethral_full_cup_medium","special_2_a",2)
 t.check(not cup.is_empty() and not g.state.special_equipment.any(func(item):return D.reinforcement_matches(item,cup)) and g.escape_preview(cup,"slip",20).reason=="","CUP BAND tier-two cup keeps its normal slip route without creating a component")
 var saved=g.export_snapshot();var restored=Game.new(17)
 t.check(restored.restore_snapshot(saved).ok and restored.state.special_equipment==g.state.special_equipment,"CUP BAND medium urethral cup survives snapshot restore")
 g=Game.new(42)
 cup=g._install_special("urethral_full_cup_medium","special_2_a",3)
 var cut_strap=g.state.special_equipment.filter(func(item):return D.reinforcement_matches(item,cup))[0]
 var no_tool=t.find_action(g,"card",{"uid":t.hand_card(g,"slip").uid,"target":cut_strap.id,"free":false})
 t.check(not no_tool.valid and no_tool.reason.contains("已安装") and g.validate()=="","CUP BAND a damage card cannot target the component without an installed compatible cutting tool")
 g._gain_tool("saw");var saw=g.state.items[-1]
 t.check(t.action(g,"item_install",{"item":saw.id,"mount":"hand_wall"}).ok,"CUP BAND cutting tool uses the formal installation transaction")
 cup=g._equipment(cup.id);cut_strap=g._equipment(cut_strap.id);saw=g._item(saw.id)
 cut_strap.durability=g.Tools.TYPES.saw.damage
 var cut_card=t.hand_card(g,"slip")
 var cut_action=t.find_action(g,"card",{"uid":cut_card.uid,"target":cut_strap.id,"free":false})
 var cut_before=g.export_snapshot()
 t.check(cut_action.valid and cut_action.payload.get("preview",{}).get("damage",-1)==0 and cut_action.payload.get("tool_bonus",{}).get("damage",-1)==g.Tools.TYPES.saw.damage,"CUP BAND real card candidate previews only installed-tool cutting damage: "+str(cut_action))
 t.check(g.dispatch(g.command(cut_action.payload,g.state.version),g.state.version).ok,"CUP BAND real card submission cuts the component")
 cup=g._equipment(cup.id);saw=g._item(saw.id)
 var magic_after_cut=g.escape_preview(cup,"magic_slip",20)
 t.check(not cup.is_empty() and g._equipment(cut_strap.id).is_empty(),"CUP BAND fully cutting the component preserves only its owner")
 t.check(cup.get("reinforcement_state","")=="removed" and g.validate()=="","CUP BAND fully cutting the component leaves a valid persistent owner state: "+g.validate())
 t.check(magic_after_cut.reason=="" and magic_after_cut.damage>0,"CUP BAND fully cutting the component reopens magic slip: "+magic_after_cut.reason)
 t.check(saw.uses==cut_before.items[-1].uses-1,"CUP BAND formal cutting consumes one installed-tool use")
 saved=g.export_snapshot();restored=Game.new(17)
 t.check(restored.restore_snapshot(saved).ok and restored._equipment(cup.id).get("reinforcement_state","")=="removed","CUP BAND cut history survives snapshot restore without recreating the component")
 g=Game.new(42)
 cup=g._install_special("full_cup_medium","special_2_a",3)
 var strap=g.state.special_equipment.filter(func(item):return D.reinforcement_matches(item,cup))[0]
 strap.owner_id="missing"
 t.check(g.validate().contains("固定带缺少对应主体"),"CUP BAND forged orphan component is rejected by the shared validator")
 g=Game.new(42)
 cup=g._install_special("full_cup_medium","special_2_a",2)
 var forged=g._install_special("nipple_ring_medium","special_1_a",2)
 forged.type="cup_reinforcement_medium";forged.name=D.TYPES.cup_reinforcement_medium.name;forged.slot="special_2_a";forged.coverage=D.DESIGNS.cup_reinforcement_medium.slots.duplicate();forged.contact_slots=forged.coverage.duplicate();forged.grade=2;forged.maximum=16;forged.durability=16;forged.remaining=0;forged.material="leather";forged.owner_id=cup.id
 t.check(g.validate().contains("未附带固定带"),"CUP BAND low-tightness owner cannot gain a forged component through snapshot data")
 cup.erase("reinforcement_state")
 t.check(g.validate().contains("固定带状态记录缺失"),"CUP BAND current snapshot cannot drop the owner state to reopen the legacy path")
 g=Game.new(42)
 cup=g._install_special("full_cup_medium","special_2_a",3)
 t.check(g._install_special("urethral_full_cup_medium","special_2_a",3).is_empty() and g.state.special_equipment.filter(D.is_reinforced_cup).size()==1 and g.validate()=="","CUP BAND ordinary and urethral full-cover families are mutually exclusive")
 var legacy=g.export_snapshot();legacy.save_revision=g.Snapshot.REINFORCEMENT_STATE_REVISION
 for item in legacy.special_equipment:
  if D.supports_reinforcement(item): item.erase("reinforcement_state")
 restored=Game.new(17)
 t.check(restored.restore_snapshot(legacy).ok and restored._equipment(cup.id).get("reinforcement_state","")=="active" and restored.validate()=="","CUP BAND revision-52 snapshots migrate owner state before strict validation")

static func manual_insertables(t) -> void:
 for pair in [["vaginal_egg_low","special_3_a"],["anal_egg_low","special_3_b"]]:
  var g=Game.new(42)
  var egg=g._install_special(pair[0],pair[1])
  var kept=g._install_special("shaft_ring_low","special_2_a").duplicate(true)
  var direct=t.find_action(g,"manual",{"target":egg.id})
  t.check(direct.valid and direct.cost==1 and direct.label=="直接取出","SPECIAL free hands expose one-action direct removal "+pair[0])
  var strain=t.hand_card(g,"strain")
  t.check(not t.find_action(g,"card",{"uid":strain.uid,"target":egg.id,"free":false}).valid,"SPECIAL wireless target rejects strain cards")
  for slot in ["upper_arm","wrist","palm","fingers"]:
   var restraint=g.add_fixture(slot,4)
   var before=g.export_snapshot()
   direct=t.find_action(g,"manual",{"target":egg.id})
   t.check(not direct.valid and not g.dispatch(g.command(direct.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"SPECIAL direct removal blocked atomically by "+slot)
   restraint.durability=0;g._cleanup()
  var energy=g.state.energy
  t.check(t.action(g,"manual",{"target":egg.id}).ok and g._equipment(egg.id).is_empty() and g.state.energy==energy-1 and g._equipment(kept.id)==kept,"SPECIAL removal costs one action and preserves unrelated root")

static func registry_paths(t) -> void:
 for type in D.TYPES:
  if D.TYPES[type].get("component_only",false): continue
  var g=Game.new(42)
  var target={}
  if D.TYPES[type].get("relic_only",false):
   g.RelicEffects.gain(g,type)
   target=g.state.special_equipment.filter(func(item):return item.type==type)[0]
  else: target=g._install_special(type,D.DESIGNS[type].slots[0])
  t.check(not target.is_empty() and g.validate()=="","SPECIAL every registered type installs through factory "+type)
  if target.is_empty(): continue
  var before=g.export_snapshot()
  g.get_view();g.command_facts()
  for mode in ["strain","slip","magic_slip"]: g.escape_preview(target,mode,5)
  t.check(g.export_snapshot()==before,"SPECIAL complete registry preview does not mutate or access ordinary template "+type)
  var card=t.hand_card(g,"strain")
  var candidate=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false})
  if candidate.valid:
   t.check(g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok,"SPECIAL registered target uses formal damage path "+type)

static func environment_classes(t) -> void:
 var g=Game.new(42);g.state.equipment=[];g.state.items=[]
 var anchor=g._install_special("crotch_rope_low","special_3_a")
 for wall in ["normal","rough","none"]:
  g.state.wall=wall;g.state.wall_distance=0
  t.check(D.environment_contact(g,anchor,"wall")== (wall!="none") and g.wall_view().environment_class==("wall" if wall!="none" else ""),"ENV CLASS both real wall surfaces, no fictitious wall "+wall)
 g.state.wall="normal";g.state.wall_distance=1
 t.check(not D.environment_contact(g,anchor,"wall"),"ENV CLASS wall tag does not bypass distance")
 g.state.wall_distance=0;g.state.posture="stand"
 for type in ["shard","saw"]:
  g.state.items=[];g._gain_tool(type)
  var tool=g.state.items[0]
  t.check(not D.environment_contact(g,anchor,"sharp"),"ENV CLASS carried sharp item is not an installed environment "+type)
  t.check(t.action(g,"item_install",{"item":tool.id,"mount":"hand_wall"}).ok and D.environment_contact(g,anchor,"sharp"),"ENV CLASS formal installation activates compatible sharp interface "+type)
  var before=g.export_snapshot();var item_view=g.get_view().items[0]
  t.check(item_view.environment_class=="sharp" and item_view.environment_name=="尖锐类" and g.export_snapshot()==before,"ENV CLASS read-only source label "+type)
  tool=g._item(tool.id)
  tool.mount="high_wall"
  t.check(not D.environment_contact(g,anchor,"sharp"),"ENV CLASS category does not bypass body contact height "+type)
  tool.mount="hand_wall";tool.uses=0
  t.check(not D.environment_contact(g,anchor,"sharp"),"ENV CLASS exhausted sharp source is inactive "+type)
 g=Game.new(42,true,"special_equipment")
 var rod=g.state.special_equipment.filter(func(item):return item.type=="urethral_rod_medium")[0]
 t.check(D.environment_contact(g,rod,"hook") and g.get_view().hook_environment_name=="挂钩类","ENV CLASS rest hook matches existing interface")
 t.check(not D.environment_contact(g,rod,"wall") and not D.environment_contact(g,rod,"unknown"),"ENV CLASS unaccepted or unknown class remains blocked")
 g.state.hook_uses=0
 t.check(not D.environment_contact(g,rod,"hook"),"ENV CLASS exhausted hook cannot supply environment")
 g.state.hook_uses=3;g.state.wall_distance=1
 t.check(not D.environment_contact(g,rod,"hook"),"ENV CLASS hook tag does not bypass wall contact")
 t.check(not g.Tools.TYPES.picks.has("environment_class") and not g.Tools.TYPES.return_seal.has("environment_class"),"ENV CLASS unrelated tools do not become environmental leverage")

static func chastity_locks(t) -> void:
 var g=Game.new(42,false,"equipment",true,true,25)
 var cup=g._install_special("full_cup_medium","special_2_a",3)
 var cup_strap=g.state.special_equipment.filter(func(item):return D.reinforcement_matches(item,cup))[0]
 var rod=g._install_special("urethral_rod_medium","special_2_d",2)
 var lock=g._install_special("negative_plate_lock_medium","special_2_a",2)
 t.check(not lock.is_empty() and lock.locked and g._equipment(cup.id).is_empty() and g._equipment(cup_strap.id).is_empty() and not g._equipment(rod.id).is_empty(),"CHASTITY plain plate atomically removes a full cup and its component while retaining an independent meatus rod")
 var locked_preview=g.escape_preview(lock,"slip",6)
 t.check(locked_preview.reason=="" and locked_preview.damage>0 and locked_preview.lock_multiplier==1.0,"CHASTITY an auto-locked root without reinforcement uses the ordinary lock rule and retains its slip route")
 t.check(g.Pressure.maximum(g)==120 and is_equal_approx(g.Pressure.source_multiplier(g,[]),1.2) and is_equal_approx(g.Pressure.source_multiplier(g,["special_2_a"]),1.0) and is_equal_approx(g.Pressure.source_multiplier(g,["special_2_d"]),1.2),"CHASTITY grade plus tightness raises maximum and multiplies only sources outside covered slots")
 var before=g.export_snapshot()
 t.check(g._install_special("shaft_ring_high","special_2_a",2).is_empty() and g.state==before,"CHASTITY ordinary toys cannot occupy or replace a worn lock")
 var replaced=g.Application.execute(g,{"pool":"special","templates":["shaft_ring_high"],"grade":3,"tier":3,"count":1,"replace":true},"enemy")
 t.check(not replaced.ok and not g._equipment(lock.id).is_empty(),"CHASTITY enemy replacement permission cannot remove the lock for another sex toy")
 var catheter=g._install_special("negative_plate_lock_catheter_medium","special_2_a",2)
 t.check(not catheter.is_empty() and g._equipment(lock.id).is_empty() and g._equipment(rod.id).is_empty() and g.state.special_equipment.filter(func(item):return D.is_chastity(item)).size()==1,"CHASTITY same-grade model with the integrated catheter upgrades the plain lock and outranks the standalone meatus rod")
 before=g.export_snapshot()
 t.check(g._install_special("negative_plate_lock_medium","special_2_a",2).is_empty() and g.state==before,"CHASTITY a less functional model cannot replace the current lock")
 var high=g._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 var straps=g.state.special_equipment.filter(func(item):return D.is_reinforcement(item) and item.owner_id==high.id)
 t.check(not high.is_empty() and high.locked and straps.size()==1 and is_equal_approx(D.gain(high,"turn_start"),24.48),"CHASTITY high vibrator lock upgrades the medium model and applies total covered-slot stimulation times 0.4")
 var strap=straps[0];var strap_before=strap.durability
 g._apply_equipment_damage(strap,5,"strain")
 t.check(strap.durability==strap_before,"CHASTITY reinforcement ignores non-cutting damage")
 g._apply_equipment_damage(strap,5,"cut")
 t.check(strap.durability==strap_before-5 and not g._equipment(high.id).is_empty(),"CHASTITY reinforcement is an independent cutting target and does not remove its owner early")
 t.check(g.escape_preview(high,"slip",6).reason.contains("加固带"),"CHASTITY reinforcement blocks slip only while its owner remains locked and exposes the specific reason")
 var locked_durability=high.durability
 g._apply_equipment_damage(high,6,"slip")
 t.check(high.durability==locked_durability,"CHASTITY a linked reinforcement prevents direct slip damage while the owner remains locked")
 g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
 var unlock=t.grant_fixture_card(g,"unlock")
 t.check(t.action(g,"card",{"uid":unlock.uid,"target":high.id,"free":false}).ok and not g._equipment(high.id).locked,"CHASTITY existing unlock card opens the auto-locked root without changing durability")
 high=g._equipment(high.id)
 var preview=g.escape_preview(high,"slip",1)
 t.check(preview.reason=="" and preview.damage>0,"CHASTITY unlocking permits any positive slip result even while reinforcement remains")
 g._apply_equipment_damage(high,preview.damage,"slip");g._cleanup()
 t.check(g._equipment(high.id).is_empty() and g._equipment(strap.id).is_empty(),"CHASTITY positive slip removes the whole unlocked lock and cascades its reinforcement")

 g=Game.new(42,false,"equipment",true,true,25)
 lock=g._install_special("negative_plate_lock_catheter_medium","special_2_a",2)
 g.state.mana=60
 g.state.pressure=119
 g.Pressure.gain(g,1,"锁内刺激",true,["special_2_a"])
 t.check(g.state.pressure==12 and g.state.chastity_climax_factor==4 and g.state.slip_ejaculation_turns==2 and g.state.slip_ejaculation_force_last and g.state.overload_energy==0 and g.state.mana==60,"CHASTITY climax retains S times factor and grants two-turn penalties without immediate mana loss")
 g.state.overloaded=false;g.state.energy=0;g._start_round()
 t.check(g.state.order=="last" and g.state.slip_ejaculation_turns==1 and g.state.energy==2 and g.state.mana==50,"CHASTITY next player turn is forced last with first energy and ten-mana penalties")
 g.state.enemies=[];g.state.phase="prepare";g._begin_player_turn()
 t.check(g.state.slip_ejaculation_turns==0 and g.state.energy==2 and g.state.mana==40,"CHASTITY second player turn consumes final energy and ten-mana penalties")
 g.state.chastity_climax_factor=7;g._restart_tower(true)
 t.check(g.state.chastity_climax_factor==7,"CHASTITY accumulated climax retention factor survives removal and continued towers within the run")

 g=Game.new(42,false,"equipment",true,true,100)
 var spec={"pool":"special","templates":["negative_plate_lock_medium","nipple_ring_medium"],"grade":2,"tier":2,"count":1,"replace":true}
 var chosen=g.Application.choose(g,spec,"enemy")
 t.check(chosen.get("type","")=="negative_plate_lock_medium","CHASTITY 100 percent setting selects a legal lock branch")
 lock=g._install_special("negative_vibrator_lock_catheter_high","special_2_a",2)
 chosen=g.Application.choose(g,spec,"enemy")
 t.check(chosen.get("type","")=="nipple_ring_medium","CHASTITY when no lock upgrade remains its probability is returned to legal ordinary toys")
 g=Game.new(42,false,"equipment",true,false,100)
 t.check(g.Application.choose(g,spec,"enemy").get("type","")=="nipple_ring_medium","CHASTITY disabled generation excludes lock types even at a stored 100 percent chance")
