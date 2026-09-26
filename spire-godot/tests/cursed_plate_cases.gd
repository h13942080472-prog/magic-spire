extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const TYPE="cursed_plate_lock"

static func run(t) -> void:
 var g=Game.new(42)
 g._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 g.RelicEffects.gain(g,TYPE)
 var locks=g.state.special_equipment.filter(g.SpecialEquipment.is_chastity)
 t.check(locks.size()==1 and locks[0].type==TYPE and locks[0].locked and g.tier(locks[0].durability,locks[0].maximum)==3 and g.max_energy()==4,"CURSED PLATE pickup replaces occupied lock and grants energy")
 if locks.size()!=1 or locks[0].type!=TYPE: return
 var lock=locks[0];var original=lock.duplicate(true)
 g._apply_equipment_damage(lock,999,"magic_slip");g._apply_manual_release(lock,0);g._cleanup()
 t.check(lock==original and g.escape_preview(lock,"magic_slip",999,[],false,true).damage==0,"CURSED PLATE rejects manual, area and slip removal")
 t.check(g.Tools.unlock_reason(g,lock).contains("专属钥匙"),"CURSED PLATE ordinary tools report dedicated key requirement")
 t.check(g.command_facts().filter(func(c):return c.payload.get("target","")==lock.id).all(func(c):return not c.valid and c.reason.contains("专属钥匙")),"CURSED PLATE all targeted actions are blocked")
 var blocked=g.command_facts().filter(func(c):return c.payload.get("target","")==lock.id)
 if not blocked.is_empty():
  var unchanged=g.export_snapshot()
  t.check(not g.dispatch(g.command(blocked[0].payload,g.state.version),g.state.version).ok and g.state==unchanged,"CURSED PLATE invalid submit changes no resources, logs or equipment")
 var replacement=g.Application.Replacement.plan(g,[{"kind":"special_install","type":"negative_vibrator_lock_catheter_high","slot":"special_2_a","tier":3}],"enemy")
 t.check(not replacement.ok and g._equipment(lock.id)==original,"CURSED PLATE cannot be replaced")
 g._gain_card("henshin");var card=t.hand_card(g,"henshin")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g._equipment(lock.id)==original,"CURSED PLATE henshin preserves lock")
 g.state.combat.active=true
 var pulses=0
 for turn in range(1,8):
  g.state.combat.turn=turn;g.state.pressure=0
  var before_logs=g.state.logs.size();g._tick_special("turn_start")
  if g.state.logs.size()>before_logs: pulses+=1
 t.check(pulses==6 and g._equipment(lock.id).remaining==0 and g.SpecialEquipment.effective_gain(g,g._equipment(lock.id),"turn_start")==0,"CURSED PLATE default vibrator stops after the first six turns of a session")
 g.RelicEffects.begin_combat(g);g.RelicEffects.begin_turn(g);g.state.pressure=0;g._tick_special("turn_start")
 t.check(g.state.pressure>0,"CURSED PLATE vibrator becomes active again in the first turn of the next session")
 g.state.chastity_climax_factor=10;g.state.pressure=g.Pressure.maximum(g)-1
 g.Pressure.gain(g,1,"测试高潮",true,["special_2_a"])
 t.check(g.state.chastity_climax_factor==10 and g.state.pressure==60,"CURSED PLATE default climax retention factor stops at ten")
 var concise=g.SpecialEquipment.description(lock,1.0,3,true,{"climax_factor":g.state.chastity_climax_factor,"masochist":false,"session_turn":7,"session_active":true})
 t.check(concise.contains("前6回合的刺激已经结束") and concise.contains("当前系数10＝60") and concise.contains("最高10") and not concise.contains("总刺激计算后×0.4"),"CURSED PLATE current description shows concrete stimulation and capped retention without the old formula dump")
 var snapshot=g.export_snapshot();var restored=Game.new(3)
 t.check(restored.restore_snapshot(snapshot).ok,"CURSED PLATE active curse roundtrips")
 var bad=snapshot.duplicate(true);bad.special_equipment=[]
 var before=restored.export_snapshot()
 t.check(not restored.restore_snapshot(bad).ok and restored.state==before,"CURSED PLATE missing lock rejects atomically")
 bad=snapshot.duplicate(true);bad.chastity_climax_factor=11
 t.check(not restored.restore_snapshot(bad).ok and restored.state==before,"CURSED PLATE capped mode rejects an over-limit retained factor")
 var extreme=Game.new(42,false,"equipment",true,true,25,false,true)
 extreme.RelicEffects.gain(extreme,TYPE);var extreme_lock=extreme.state.special_equipment.filter(extreme.SpecialEquipment.is_cursed_plate)[0]
 extreme.state.combat.active=true;extreme.state.combat.turn=12;extreme.state.pressure=0;extreme._tick_special("turn_start")
 extreme.state.chastity_climax_factor=10;extreme.state.pressure=extreme.Pressure.maximum(extreme)-1;extreme.Pressure.gain(extreme,1,"测试高潮",true,["special_2_a"])
 t.check(extreme.state.pressure>0 and extreme.state.chastity_climax_factor==11 and extreme.SpecialEquipment.description(extreme_lock,1.0,3,true,{"climax_factor":11,"masochist":true,"session_turn":12,"session_active":true}).contains("没有上限"),"CURSED PLATE masochist mode keeps the original unlimited vibrator and retention growth")
 for boundary in ["normal","saturated","boss"]:
  g=Game.new(42);g.RelicEffects.gain(g,TYPE)
  if boundary!="normal": g.state.room="summit";g._start_battle()
  for enemy in g.state.enemies.duplicate(): g._damage_enemy(enemy,99999,"magic","测试")
  g._finish_battle("saturated" if boundary=="saturated" else "victory")
  var released=boundary=="boss"
  t.check(g.state.cursed_plate_released==released and g.state.special_equipment.any(g.SpecialEquipment.is_chastity)!=released,"CURSED PLATE key only follows an actual Boss defeat: "+boundary)
  if released:
   t.check(g.state.special_equipment.is_empty() and g.max_energy()==4 and g.state.logs.any(func(row):return row.data.get("cursed_plate_key",{}).get("used",false)),"CURSED PLATE key automatically removes whole item and strap, retaining energy")
   t.check(restored.restore_snapshot(g.export_snapshot()).ok,"CURSED PLATE released state roundtrips")
   var count=g.state.logs.filter(func(row):return row.data.has("cursed_plate_key")).size()
   g.state.phase="battle";g._finish_battle()
   t.check(count==1 and g.state.logs.filter(func(row):return row.data.has("cursed_plate_key")).size()==count,"CURSED PLATE later Bosses do not drop another key")
 g=Game.new(42)
 t.check(TYPE not in g.SpecialEquipment.prison_pool(3,true,true) and TYPE not in g.SpecialEquipment.generation_pool(g.SpecialEquipment.TYPES.keys(),true),"CURSED PLATE never enters ordinary or prison generation pools")
 g.RelicEffects.gain(g,TYPE)
 g.state.phase="shop"
 var jobs=g.Services.release_jobs(g).filter(func(job):return job.name=="诅咒平板锁")
 t.check(jobs.size()==1 and jobs[0].reason==g.Services.ShopCopy.CURSED_PLATE_SERVICE_REASON,"CURSED PLATE shop shows current service restriction and never permits removal")
 g=Game.new(42)
 var ordinary=g._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 t.check(not g.cursed_plate(ordinary) and g.SpecialEquipment.TYPES[ordinary.type].duration==12,"CURSED PLATE original powered lock retains twelve-turn battery and normal unlock rules")
 ordinary.locked=false
 g._apply_equipment_damage(ordinary,1,"magic_slip");g._cleanup()
 t.check(g._equipment(ordinary.id).is_empty(),"CURSED PLATE ordinary unlocked lock still releases with positive slip damage")
