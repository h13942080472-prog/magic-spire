extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func doll(g) -> Dictionary:
 return g.Puppets.owned(g,g.state.enemies[0])

static func start(t, awaken: bool=true):
 var g=Game.new(42,true,"puppeteer_solo")
 t.check(g.state.enemies.size()==2 and doll(g).hp==15 and g.state.enemies[0].stage==1 and g.state.enemies[0].intent.kind=="puppet_awaken","PUPPET encounter starts with its protected doll and awakening as the first intent")
 if awaken: t.check(t.action(g,"end").ok,"PUPPET first turn activates the hit response and taunt")
 return g

static func run(t) -> void:
 barrier_and_stock(t)
 scaled_barrier(t)
 barrier_capacity(t)
 var g=start(t,false)
 var master_id=g.state.enemies[0].id
 t.check(g.Enemies.TYPES.puppeteer.hp==96 and g.Enemies.TYPES.puppeteer.humanoid and g.Enemies.TYPES.puppet.humanoid and "puppeteer_solo" in g.Enemies.FirstFloor.ELITE_ENCOUNTERS,"PUPPET elite registration, health and both humanoid types")
 var id=doll(g).id
 var before=g.export_snapshot()
 g.command_facts();g.get_view()
 t.check(g.state==before and doll(g).hp==15 and not doll(g).puppet_awakened and doll(g).stage==1,"PUPPET summon has innate protection and read-only preview, no early taunt")
 g._damage_enemy(g._enemy(id),17,"physical","测试伤害")
 t.check(g._enemy(id).hp==1 and g._enemy(master_id).hp==93 and g.state.equipment.is_empty(),"PUPPET innate floor forwards exactly three excess damage without an early reaction")
 t.check(t.find_action(g,"attack",{"type":"strike","enemy":master_id}).valid,"PUPPET master remains targetable until awakening")
 var twin=Save.roundtrip(t,g,"puppet before awakening")
 Save.step_both(t,g,twin,"end")
 t.check(doll(g).puppet_awakened and doll(g).stage==1,"PUPPET awakened summon never takes an action")
 var blocked=t.find_action(g,"attack",{"type":"strike","enemy":master_id})
 before=g.export_snapshot()
 t.check(not blocked.valid and blocked.reason.contains("嘲讽") and not g.dispatch(g.command(blocked.payload,g.state.version),g.state.version).ok and g.state==before,"PUPPET taunt rejects direct master attacks without payment or state change")
 t.check(t.find_action(g,"attack",{"type":"kick","form":1,"enemy":master_id}).valid,"PUPPET taunt does not block area attacks")
 var health=g._enemy(master_id).hp
 t.check(t.action(g,"attack",{"type":"strike","form":1,"enemy":id}).ok,"PUPPET real two-hit attack")
 t.check(g._enemy(master_id).hp==health-8 and g._enemy(id).hp==1 and g.physical_pieces().size()==2 and g.physical_pieces().all(func(e):return e.grade==1 and g.tier(e.durability,e.maximum)==2),"PUPPET two hits at one HP each transfer and install once")

 g=start(t)
 master_id=g.state.enemies[0].id;id=doll(g).id
 t.check(t.action(g,"end").ok and doll(g).puppet_prepared.keys()==["composite"] and doll(g).max_hp==15,"PUPPET second action freezes a composite without mending or equipping the player")
 t.check(t.action(g,"end").ok and doll(g).puppet_prepared.has("special") and g.state.special_equipment.is_empty() and g.state.composites.is_empty(),"PUPPET third action freezes a medium tier-three special without premature installation")
 t.check(t.action(g,"end").ok and doll(g).max_hp==20 and doll(g).hp==20 and doll(g).puppet_stock==4,"PUPPET fourth action raises health and reaction capacity and fills both")
 twin=Save.roundtrip(t,g,"both puppet prepared payloads")
 var prepared=doll(g).puppet_prepared.duplicate(true)
 g._damage_enemy(g._enemy(id),1,"fixed","遗物")
 t.check(doll(g).puppet_prepared==prepared and g.physical_pieces().size()==1,"PUPPET positive non-attack damage reacts but keeps the next-attack payloads")
 before=g.export_snapshot()
 g._damage_enemy(g._enemy(id),0,"fixed","零伤害")
 t.check(g.state==before,"PUPPET zero damage creates no hit reaction")
 t.check(t.action(g,"attack",{"type":"strike","enemy":id}).ok and doll(g).puppet_prepared.is_empty(),"PUPPET next successful attack consumes both prepared slots")
 t.check(g.state.special_equipment.size()==1 and g.state.special_equipment[0].grade==2 and g.tier(g.state.special_equipment[0].durability,g.state.special_equipment[0].maximum)==3,"PUPPET special payload actually installs at medium tier three")
 t.check(g.state.composites.size()==1 and g.state.composites[0].components.all(func(piece):return piece.grade==2 and g.tier(piece.durability,piece.maximum)==2),"PUPPET composite payload uses real components and tier two")
 t.check(t.action(g,"end").ok and doll(g).max_hp==20 and doll(g).puppet_prepared.has("composite"),"PUPPET fifth action starts the next composite-special-mend cycle")
 t.check(t.action(g,"end").ok and t.action(g,"end").ok and doll(g).max_hp==25 and doll(g).hp==25 and doll(g).puppet_stock==5,"PUPPET seventh action mends again and fills increased capacity")
 t.check(g.validate()=="","PUPPET reacted and mended encounter retains valid state")
 var good=twin.export_snapshot()
 for key in ["puppet_owner","puppet_mends","puppet_prepared"]:
  var bad=good.duplicate(true)
  var target=bad.enemies.filter(func(e):return e.type=="puppet")[0]
  if key=="puppet_owner": target[key]="enemy_missing"
  elif key=="puppet_mends": target[key]=-1
  else: target[key].special.tier=2
  t.check(not twin.restore_snapshot(bad).ok and twin.state==good,"PUPPET corrupted "+key+" is rejected atomically")
 Save.step_both(t,twin,Save.roundtrip(t,twin,"ready puppet deterministic hit"),"attack",{"type":"fireball","enemy":id})

 g=start(t);master_id=g.state.enemies[0].id;id=doll(g).id
 g._enemy(id).hp=1;g._enemy(master_id).hp=3
 t.check(t.action(g,"attack",{"type":"strike","form":1,"enemy":id}).ok and g.state.enemies.all(func(e):return e.gone),"PUPPET lethal transfer dismisses the puppet during the hit sequence")
 t.check(g.state.phase=="reward" and g.state.reward_count==1 and g.physical_pieces().size()==1,"PUPPET no post-death second hit, one reaction and one room reward")
 t.check(g.get_view().statuses.all(func(s):return not s.id.begins_with("puppet_")),"PUPPET death removes protection, taunt and prepared status")

 g=start(t);master_id=g.state.enemies[0].id;id=doll(g).id
 var sweep_damage=float(g.BasicAttacks.TYPES.kick[1].damage)
 health=g._enemy(master_id).hp
 t.check(t.action(g,"attack",{"type":"kick","form":1,"enemy":master_id}).ok and g._enemy(master_id).hp==health-sweep_damage and doll(g).hp==15-sweep_damage and g.physical_pieces().size()==1,"PUPPET actual area attack hits master and doll while taunted, reacting once")
 g=start(t,false);master_id=g.state.enemies[0].id
 g._enemy(master_id).hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":master_id}).ok and g.state.phase=="reward" and g.state.reward_count==1,"PUPPET direct defeat before awakening also dismisses the summon and rewards once")

 # Explicit special tightness must survive both original and replacement factories.
 g=Game.new(42)
 var type=g.Enemies.TYPES.puppeteer.special_pool[0]
 var design=g.SpecialEquipment.DESIGNS[type]
 g._install_special(type.replace("_medium","_low"),design.slots[0])
 var applied=g.Application.execute(g,{"pool":"special","templates":[type],"grade":2,"tier":3,"count":1,"replace":true},"fixture")
 t.check(applied.ok and g.state.special_equipment.size()==1 and g.state.special_equipment[0].type==type and g.tier(g.state.special_equipment[0].durability,g.state.special_equipment[0].maximum)==3 and g.validate()=="","PUPPET explicit tier three survives legal special replacement")

static func barrier_and_stock(t) -> void:
 for amount in [29.0,30.0,31.0]:
  var g=start(t,false);var master=g.state.enemies[0]
  g._damage_enemy(master,amount,"physical","屏障边界")
  t.check(master.hp==96-minf(amount,30) and g.Enemies.barrier_remaining(master,g.DemoExit.health_multiplier(g.state))==maxf(0,30-amount),"PUPPET BARRIER boundary clamps actual turn damage")
 var g=start(t,false);var master=g.state.enemies[0]
 g._damage_enemy(master,12,"magic","屏障测试")
 g._damage_enemy(doll(g),35,"physical","转移测试")
 t.check(master.hp==66 and doll(g).hp==1 and master.barrier_damage==30,"PUPPET BARRIER direct and transferred damage share the same turn allowance")
 g._damage_enemy(master,20,"fixed","遗物测试")
 t.check(master.hp==66,"PUPPET BARRIER exhausted allowance blocks later fixed damage in the same turn")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"PUPPET BARRIER previews do not refill allowance")
 var twin=Save.roundtrip(t,g,"barrier exhausted allowance")
 t.check(twin.Enemies.barrier_remaining(twin.state.enemies[0],twin.DemoExit.health_multiplier(twin.state))==0,"PUPPET BARRIER restore preserves exhausted allowance")
 var c=t.find_action(g,"end")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"PUPPET BARRIER stale end turn cannot reset allowance")
 t.check(t.action(g,"end").ok and master.barrier_damage==30 and g.state.enemies[0].barrier_damage==0,"PUPPET BARRIER next formal round resets only committed state")
 master=g.state.enemies[0]
 g._damage_enemy(master,31,"fixed","新回合测试")
 t.check(master.hp==36 and master.barrier_damage==30,"PUPPET BARRIER new turn grants a fresh thirty damage allowance")
 # Real two-hit action exceeds the budget in its first hit; a second action cannot reset it.
 g=start(t);g.state.energy=10;g.state.turn_strength=50;doll(g).hp=1
 var master_id=g.state.enemies[0].id
 t.check(t.action(g,"attack",{"type":"strike","form":1,"enemy":doll(g).id}).ok and g._enemy(master_id).hp==66 and doll(g).puppet_stock==1,"PUPPET BARRIER real multihit transfer shares thirty damage while each hit consumes ordinary stock")
 g._damage_enemy(g._enemy(master_id),40,"magic","另一攻击")
 t.check(g._enemy(master_id).hp==66,"PUPPET BARRIER later attack remains capped for whole turn")
 g=start(t)
 for i in range(3):g._damage_enemy(doll(g),1,"fixed","反击测试")
 t.check(doll(g).puppet_stock==0 and g.physical_pieces().size()==3,"PUPPET STOCK initial three charges allow exactly three ordinary reactions")
 var pieces=g.physical_pieces().duplicate(true)
 g._damage_enemy(doll(g),1,"fixed","耗尽测试")
 t.check(doll(g).puppet_stock==0 and g.physical_pieces()==pieces,"PUPPET STOCK fourth positive hit cannot apply ordinary equipment")
 before=g.export_snapshot();g._damage_enemy(doll(g),0,"fixed","零伤害")
 t.check(g.state==before,"PUPPET STOCK zero damage neither consumes nor applies")
 twin=Save.roundtrip(t,g,"puppet empty stock")
 t.check(doll(twin).puppet_stock==0,"PUPPET STOCK save restore cannot replenish reactions")
 t.check(t.action(g,"end").ok and t.action(g,"end").ok and doll(g).puppet_prepared.size()==2,"PUPPET STOCK depleted stock does not stop preparing extra equipment")
 g._damage_enemy(doll(g),1,"physical","额外装束测试",{"attack":true})
 t.check(doll(g).puppet_stock==0 and doll(g).puppet_prepared.is_empty() and g.state.composites.size()==1 and g.state.special_equipment.size()==1,"PUPPET STOCK prepared composite and special apply independently at zero ordinary stock")
 t.check(t.action(g,"end").ok and doll(g).puppet_stock==4 and g.Puppets.capacity(g,doll(g))==4 and doll(g).hp==20,"PUPPET STOCK mend increases capacity and refills health and ordinary stock")
 before=g.export_snapshot()
 for value in [-1,5,"3"]:
  var bad=before.duplicate(true);bad.enemies.filter(func(e):return e.type=="puppet")[0].puppet_stock=value
  t.check(not g.restore_snapshot(bad).ok and g.state==before,"PUPPET STOCK corrupt remaining count is rejected atomically")
 for value in [-1,31,"0"]:
  var bad=before.duplicate(true);bad.enemies[0].barrier_damage=value
  t.check(not g.restore_snapshot(bad).ok and g.state==before,"PUPPET BARRIER corrupt turn damage is rejected atomically")
 g=start(t);g.state.evasion=1
 g._damage_enemy(doll(g),1,"fixed","闪避免装测试")
 t.check(doll(g).puppet_stock==2 and g.physical_pieces().is_empty() and g.state.evasion==0,"PUPPET STOCK evaded ordinary counter still consumes a charge without installing equipment")
 g=start(t,false)
 var other=g._append_enemies([{"type":"puppeteer","grade":2}])[0]
 g._damage_enemy(g.state.enemies[0],40,"magic","独立屏障测试")
 g._damage_enemy(other,7,"fixed","独立屏障测试")
 t.check(g.state.enemies[0].barrier_damage==30 and other.barrier_damage==7 and other.hp==89,"PUPPET BARRIER each owner keeps an independent turn allowance")

static func scaled_barrier(t) -> void:
 for cycle in range(3):
  var g=Game.new(42)
  g.state.room_encounters.entrance="puppeteer_solo"
  g.state.demo_cycle=cycle;g._start_battle()
  var master=g.state.enemies[0]
  var factor=[1.0,1.5,2.0][cycle];var limit=[30.0,45.0,60.0][cycle]
  t.check(master.max_hp==96*factor and g.Enemies.barrier_limit(master,factor)==limit,"PUPPET CYCLE health and damage allowance share the cycle multiplier")
  g._damage_enemy(master,limit-1,"magic","周目屏障边界")
  g=Save.roundtrip(t,g,"scaled barrier one damage remaining")
  master=g.state.enemies[0]
  var status=g.get_view().statuses.filter(func(s):return s.id=="damage_barrier_"+master.id)[0]
  t.check(status.detail.contains("最多%s点" % g.number(limit)) and g.Enemies.barrier_remaining(master,factor)==1,"PUPPET CYCLE status and restored allowance use the scaled limit")
  g._damage_enemy(doll(g),doll(g).hp+2,"fixed","周目转移伤害")
  t.check(master.barrier_damage==limit and master.hp==96*factor-limit,"PUPPET CYCLE transfer shares and cannot exceed the scaled turn budget")
  g._damage_enemy(master,999,"fixed","周目屏障已耗尽")
  t.check(master.hp==96*factor-limit,"PUPPET CYCLE further damage remains blocked after scaled allowance is exhausted")
  g=Save.roundtrip(t,g,"scaled barrier exhausted")
  var stable=g.export_snapshot();var invalid=stable.duplicate(true)
  invalid.enemies[0].barrier_damage=limit+0.5
  t.check(not g.restore_snapshot(invalid).ok and g.state==stable,"PUPPET CYCLE above-limit saved damage rejects atomically at every cycle")
  t.check(t.action(g,"end").ok and g.Enemies.barrier_remaining(g.state.enemies[0],factor)==limit,"PUPPET CYCLE formal next turn restores the full scaled allowance")

static func barrier_capacity(t) -> void:
 var g=start(t,false);var master=g.state.enemies[0]
 g._damage_enemy(master,30,"fixed","恰好上限")
 g._damage_enemy(master,0,"fixed","零伤害")
 t.check(g.Puppets.capacity(g,doll(g))==3 and doll(g).puppet_stock==3,"PUPPET CAPACITY exact limit and zero damage do not trigger loss")
 for expected in [2,1,1,1]:
  g._damage_enemy(master,1,"fixed","屏障阻挡")
  t.check(g.Puppets.capacity(g,doll(g))==expected and doll(g).puppet_stock==expected,"PUPPET CAPACITY each later damage event lowers and clamps capacity without negative debt")
 t.check(doll(g).puppet_capacity_lost==2,"PUPPET CAPACITY repeated blocking at one cannot accumulate future capacity debt")
 g=Save.roundtrip(t,g,"minimum puppet capacity")
 t.check(t.action(g,"end").ok and g.Puppets.capacity(g,doll(g))==1,"PUPPET CAPACITY next round resets the barrier but preserves lost capacity")
 for i in range(3): t.check(t.action(g,"end").ok,"PUPPET CAPACITY normal cycle proceeds to mending")
 t.check(g.Puppets.capacity(g,doll(g))==2 and doll(g).puppet_stock==2,"PUPPET CAPACITY mending restores one capacity and refills after the one-capacity floor")
 var stable=g.export_snapshot()
 for value in [-1,5,"1",1.5]:
  var bad=stable.duplicate(true);bad.enemies.filter(func(e):return e.type=="puppet")[0].puppet_capacity_lost=value
  t.check(not g.restore_snapshot(bad).ok and g.state==stable,"PUPPET CAPACITY malformed or excessive loss rejects atomically")
 # A previous version could save capacity zero. Keep spent stock empty, but mend +1.
 g=start(t,false)
 var zero_save=g.export_snapshot()
 var old_doll=zero_save.enemies.filter(func(e):return e.type=="puppet")[0]
 old_doll.puppet_capacity_lost=3;old_doll.puppet_stock=0
 t.check(g.restore_snapshot(zero_save).ok and g.Puppets.capacity(g,doll(g))==1 and doll(g).puppet_stock==0,"PUPPET CAPACITY old zero-capacity saves show floor one without granting unspent reactions")
 for i in range(4):t.check(t.action(g,"end").ok,"PUPPET CAPACITY old zero-capacity save reaches real mend")
 t.check(g.Puppets.capacity(g,doll(g))==2 and doll(g).puppet_stock==2,"PUPPET CAPACITY old zero-capacity save mends from the new floor to two")
 g=start(t,false)
 var legacy=g.export_snapshot();legacy.enemies.filter(func(e):return e.type=="puppet")[0].erase("puppet_capacity_lost")
 t.check(g.restore_snapshot(legacy).ok and g.Puppets.capacity(g,doll(g))==3,"PUPPET CAPACITY older saves without a loss field retain their original capacity")
 g.state.energy=20;g.state.turn_strength=50
 var master_id=g.state.enemies[0].id
 t.check(t.action(g,"attack",{"type":"strike","form":1,"enemy":master_id}).ok and g.Puppets.capacity(g,doll(g))==2,"PUPPET CAPACITY a real two-hit attack reduces capacity only once")
 t.check(t.action(g,"attack",{"type":"strike","form":1,"enemy":master_id}).ok and g.Puppets.capacity(g,doll(g))==1,"PUPPET CAPACITY a second attack in the same turn gets its own trigger")
 g=start(t);g.state.energy=20;g.state.turn_strength=50;doll(g).hp=1
 t.check(t.action(g,"attack",{"type":"strike","form":1,"enemy":doll(g).id}).ok and g.Puppets.capacity(g,doll(g))==2 and doll(g).puppet_stock==1,"PUPPET CAPACITY multi-hit transfer shares the attack group while reactions still consume stock")
 g=start(t,false);g.state.energy=20;g.state.turn_strength=50
 var other=g._append_enemies([{"type":"puppeteer","grade":2}])[0]
 t.check(t.action(g,"attack",{"type":"kick","form":1,"enemy":g.state.enemies[0].id}).ok and g.Puppets.capacity(g,doll(g))==2 and g.Puppets.capacity(g,g.Puppets.owned(g,g._enemy(other.id)))==2,"PUPPET CAPACITY area damage and transfers trigger once per owner, not once per target")
 g=Game.new(42,false,"equipment",true,false,25,false,false,"witch")
 g.state.room_encounters.entrance="puppeteer_solo";g._start_battle()
 g.state.witch_charges.mouth=2;g.state.witch_focus=50;g.state.mana=g.state.mana_max
 t.check(t.action(g,"attack",{"type":"witch_mouth","form":1,"enemy":g.state.enemies[0].id}).ok and g.Puppets.capacity(g,doll(g))==2,"PUPPET CAPACITY witch multi-hit area casting shares the same attack grouping")
 g=start(t,false);g._discard_end();g.state.energy=30;doll(g).hp=1
 g._damage_enemy(g.state.enemies[0],30,"fixed","耗尽屏障")
 t.check(Cards.play(t,g,"letter_opener",true).ok,"PUPPET CAPACITY activate the real area-damage power")
 for expected in [2,1]:
  for i in range(3):t.check(Cards.play(t,g,"slip",true).ok,"PUPPET CAPACITY skill play advances the power trigger")
  t.check(g.Puppets.capacity(g,doll(g))==expected,"PUPPET CAPACITY each power volley groups master damage and doll transfer once")
 g=start(t,false);g.state.relics=["kings_gift_revised"];g.state.round=7;doll(g).hp=1
 g._damage_enemy(g.state.enemies[0],30,"fixed","耗尽屏障")
 t.check(t.action(g,"end").ok and g.Puppets.capacity(g,doll(g))==2 and g.RelicEffects.used(g,"kings_gift_revised"),"PUPPET CAPACITY real turn-ending relic volley groups master damage and doll transfer once")
