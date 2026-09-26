extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")

static func fresh():
 var g=Game.new(42,false,"equipment",true,false,25,false,false,"witch")
 g.state.relics=[];g.state.temporary_mana=0.0;g.state.mana=100.0;g.state.mana_max=100.0;g.state.energy=30
 g.state.enemies[0].hp=1000.0;g.state.enemies[0].max_hp=1000.0
 return g

static func play(t,g,type: String,free: bool=false) -> Dictionary:
 var card=Give.give(g,type)
 return t.action(g,"card",{"uid":card.uid,"free":free})

static func run(t) -> void:
 _patience_turn_window(t)
 var g=fresh()
 t.check(g.state.deck.size()==11 and g.state.deck.filter(func(c):return c.type=="witch_slip").size()==3 and g.state.deck.any(func(c):return c.type=="witch_magic_slip") and g.state.deck.any(func(c):return c.type=="witch_escape_practice") and not g.state.deck.any(func(c):return c.type=="witch_magic_hand"),"WITCH expansion exact eleven-card starter")
 for part in g.Character.PARTS:
  g=fresh();g.state.witch_charges[part]=4
  for repeat in range(3): t.check(t.action(g,"attack",{"type":"witch_"+part,"form":0}).ok,"WITCH unlimited preparation "+part)
  t.check(t.action(g,"attack",{"type":"witch_"+part,"form":1}).ok,"WITCH first release succeeds "+part)
  var blocked=t.find_action(g,"attack",{"type":"witch_"+part,"form":1});var before=g.export_snapshot()
  t.check(not blocked.valid and blocked.reason.contains("本回合已经释放") and not g.dispatch(g.command(blocked.payload,g.state.version),g.state.version).ok and g.state==before,"WITCH repeat release rejected atomically "+part)
  t.check(t.action(g,"attack",{"type":"witch_"+part,"form":0}).ok,"WITCH can prepare after releasing "+part)
  g._begin_player_turn();g.state.witch_charges[part]=4
  t.check(t.find_action(g,"attack",{"type":"witch_"+part,"form":1}).valid,"WITCH next turn restores release quota "+part)
 _training(t)
 g=fresh();g.state.mana=80;g.state.flask_mana=50
 t.check(play(t,g,"witch_mana_transfer").ok and g.state.mana==100 and g.state.flask_mana==30,"WITCH transfer only withdraws missing mana")
 g.state.mana=0;g.state.flask_mana=8
 t.check(play(t,g,"witch_mana_transfer").ok and g.state.mana==8 and g.state.flask_mana==0,"WITCH transfer handles partial flask")
 t.check(play(t,g,"witch_mana_transfer",true).ok and g.state.temporary_mana==20,"WITCH transfer free gives four reserves")
 g=fresh();t.check(play(t,g,"witch_patience",true).ok and g.state.next_energy==3 and g.state.mana==80,"WITCH patience pays twenty for next energy")
 g._begin_player_turn();t.check(g.state.energy==6,"WITCH patience awards next-turn energy")
 g=fresh();g._install_template("mouth_band","mouth",24.0,24.0,false,"fixture",3,0)
 var card=Give.give(g,"witch_patience")
 t.check(not t.find_action(g,"card",{"uid":card.uid,"free":true}).valid,"WITCH patience rejects mouth grade three")
 g=fresh();t.check(play(t,g,"witch_patience").ok,"WITCH preparation protection plays")
 g.state.witch_charges.hand=4
 t.check(t.action(g,"attack",{"type":"witch_hand","form":1}).ok and g.state.witch_charges.hand==0,"WITCH protection allows voluntary release to consume charges")
 g.state.witch_charges.hand=4
 t.check(not g.Character.evade(g,[{"template":"rope","slot":"wrist"}],"fixture") and g.state.witch_charges.hand==4,"WITCH protection disables charge evasion")
 g.Pressure._apply_overloads(g,1)
 t.check(g.state.witch_charges.hand==4,"WITCH protection preserves charges at climax")
 g._begin_player_turn();t.check(not g.Character.Expansion.protects_preparation(g),"WITCH protection expires at next start")
 for free in [false,true]:
  g=fresh();t.check(play(t,g,"witch_endurance",free).ok,"WITCH endurance plays both faces")
  t.check(g.state.exhaust.back().type=="witch_endurance" and g.state.discard.any(func(c):return c.type=="witch_sensitive")==not free,"WITCH endurance exhausts and bound creates sensitive")
  g.Pressure.gain(g,20,"fixture");t.check(g.state.pressure==(20 if free else 10),"WITCH endurance current-turn window")
  g.state.pressure=0;g._begin_player_turn()
  # Isolate the reduction from the generated Sensitive hand modifier.
  for generated in g.state.hand.duplicate():
   if generated.type=="witch_sensitive": g.state.hand.erase(generated);g.state.discard.append(generated)
  g.Pressure.gain(g,20,"fixture");t.check(g.state.pressure==10,"WITCH endurance next-turn reduction")
  g.state.mana=50;g.state.pressure=10;g.Pressure.balance_mana(g)
  t.check(g.state.pressure==30 and g.state.mana==30,"WITCH endurance never changes shared fate redistribution")
  g.state.pressure=0;g._begin_player_turn();g.Pressure.gain(g,20,"fixture")
  t.check(g.state.pressure==20,"WITCH endurance ends after next turn")
 for part in ["hand","mouth"]:
  g=fresh();t.check(play(t,g,"witch_small_fry",part=="hand").ok,"WITCH interrupt spell plays "+part)
  t.check(t.action(g,"attack",{"type":"witch_"+part,"form":0}).ok and "witch_interrupt_"+part in g.state.card_buffs,"WITCH preparing does not spend interrupt")
  t.check(t.action(g,"attack",{"type":"witch_"+part,"form":1}).ok and g.state.enemies[0].intent.delayed and "witch_interrupt_"+part not in g.state.card_buffs,"WITCH release interrupts once and consumes enhancement")
 for free in [false,true]:
  g=fresh();g.state.pressure=0
  if not free: g.add_fixture("wrist",8);g._install_assembly("glove","long","fixture",2,2)
  t.check(play(t,g,"witch_authority",free).ok,"WITCH authority plays both ability faces")
  t.check(g.state.mana==40 and g.state.pressure==0 and g.state.powers.back().type=="witch_authority","WITCH authority pays sixty and enters powers")
  if free: t.check(g.state.energy==33 and g.state.temporary_mana==40 and g.state.witch_focus==3,"WITCH authority grants energy reserve and focus")
  else: t.check(g.state.equipment.is_empty() and g.state.composites.is_empty() and g.state.guard_bind.is_empty(),"WITCH authority clears physical restraints")
  var blocked=t.find_action(g,"end");var before=g.export_snapshot()
  t.check(not blocked.valid and not g.dispatch(g.command(blocked.payload,g.state.version),g.state.version).ok and g.state==before and t.find_action(g,"surrender").valid,"WITCH authority locks end transaction while surrender remains")
  g.Pressure.gain(g,20,"fixture");t.check(g.state.pressure==10,"WITCH authority halves current pressure")
  var saved=g.export_snapshot();t.check(Game.new(42).restore_snapshot(saved).ok,"WITCH authority lock survives snapshot")
  g._damage_enemy(g.state.enemies[0],10000,"magic","fixture");g._finish_battle()
  t.check(g.state.phase=="reward" and g.Character.Expansion.end_reason(g)=="","WITCH authority permits victory progression")
 for role in ["original","witch"]:
  var book=preload("res://data/encyclopedia.gd").entries(g,role)
  t.check(book.any(func(row):return row.id=="witch_authority")== (role=="witch") and book.any(func(row):return row.id=="witch_amulet")== (role=="witch"),"WITCH encyclopedia role isolates cards and relics "+role)

static func _patience_turn_window(t) -> void:
 var Save=preload("res://tests/persistence_cases.gd")
 for protected in [false,true]:
  var g=_patience_encounter()
  g.state.posture="stand";g.state.order="first";g.state.witch_charges.hand=4
  var enemy=g.state.enemies[0]
  var intent=g.EnemyPlans.application(["rope"],1,1);intent.slot="wrist"
  enemy.intent=intent.duplicate(true)
  if protected:
   t.check(play(t,g,"witch_patience").ok,"PATIENCE protection activates through card submission")
   var status=g.get_view().statuses.filter(func(row):return row.id=="power_witch_patience")[0]
   t.check(status.duration=="下回合开始","PATIENCE status describes its actual next-start boundary")
  var restored=Save.roundtrip(t,g,"patience before enemy action")
  t.check(t.action(g,"end").ok,"PATIENCE real end turn includes enemy application and next player start")
  t.check(g.state.witch_charges.hand==(4 if protected else 2),"PATIENCE only protected charges survive the intervening enemy action")
  t.check(g.state.equipment.any(func(item):return item.source==enemy.id and item.slot=="wrist")==protected,"PATIENCE protection suspends charge evasion, allowing actual restraint installation")
  t.check(not g.Character.Expansion.protects_preparation(g),"PATIENCE protection is gone when the next player turn opens")
  if restored!=null:
   t.check(t.action(restored,"end").ok and restored.state.witch_charges==g.state.witch_charges and restored.state.equipment==g.state.equipment,"PATIENCE restored protection follows identical enemy and expiry sequence")
  if protected:
   g.state.enemies[0].intent=intent.duplicate(true)
   t.check(t.action(g,"end").ok and g.state.witch_charges.hand==2,"PATIENCE next round restores ordinary charge evasion")
 var g=_patience_encounter()
 g.state.posture="lie";g.state.order="last";g.state.witch_charges.hand=4
 var intent=g.EnemyPlans.application(["rope"],1,1);intent.slot="wrist";g.state.enemies[0].intent=intent
 g.state.enemies[0].acted_round=g.state.round
 t.check(play(t,g,"witch_patience").ok and t.action(g,"end").ok and g.state.witch_charges.hand==2,"PATIENCE expires before enemy-first actions belonging to the next round")
 g=fresh();play(t,g,"witch_patience");g.Cards.end_powers(g)
 t.check(not g.Character.Expansion.protects_preparation(g),"PATIENCE session cleanup still clears protection")

static func _patience_encounter():
 var g=fresh()
 g.state.room_encounters.entrance="rope_solo";g._start_battle()
 g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[]
 g.state.relics=[];g.state.energy=30;g.state.mana=100
 return g

static func _training(t) -> void:
 var shared=fresh();shared.state.equipment.clear()
 var shared_target=shared._install_template("belt","wrist",24.0,24.0,true,"fixture",3,0)
 var shared_card=shared.state.deck.filter(func(item):return item.type=="witch_escape_practice")[0]
 for side in [false,true]:
  for zone in ["draw","discard"]:
   for item in shared.state[zone].duplicate():
    if item.uid==shared_card.uid: shared.state[zone].erase(item);shared.state.hand.append(item)
  t.check(t.action(shared,"card",{"uid":shared_card.uid,"free":side,"target":shared_target.id}).ok,"WITCH same starter plays both bound faces")
 t.check(shared.state.deck.filter(func(item):return item.uid==shared_card.uid)[0].practice_plays==2 and shared.state.discard.filter(func(item):return item.uid==shared_card.uid)[0].practice_plays==2,"WITCH both faces share the same physical starter progress")
 var valid=shared.export_snapshot();var invalid=valid.duplicate(true)
 for item in invalid.discard:
  if item.uid==shared_card.uid: item.practice_plays=3
 t.check(not shared.restore_snapshot(invalid).ok and shared.state==valid,"WITCH rejects mismatched permanent and live progress even within one stage")
 for count in [0,6,7,13,14,20,21,27,28,34,35]:
  for free in [false,true]:
   var g=fresh();g.state.equipment.clear()
   var target=g._install_template("belt","wrist",24.0,24.0,true,"fixture",3,0)
   var type=g.Character.Expansion.TRAINING[mini(5,count/7)]
   var card=Give.give(g,type);card.practice_plays=count
   for permanent in g.state.deck:
    if permanent.uid==card.uid: permanent.practice_plays=count
   var c=t.find_action(g,"card",{"uid":card.uid,"free":free,"target":target.id})
   var before=g.export_snapshot()
   t.check(c.valid and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"WITCH training stale use rolls back "+str([count,free]))
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"WITCH training real multihit "+str([count,free]))
   var played=g.state.discard.filter(func(item):return item.uid==card.uid)
   t.check(not played.is_empty() and played[0].practice_plays==count+1 and played[0].type==g.Character.Expansion.TRAINING[mini(5,(count+1)/7)],"WITCH training counts one whole card and evolves after threshold "+str([count,free]))
   var expected=g.Cards.Rules.SPECS[type].hits
   var hits=g.state.logs.filter(func(row):return row.data.has("base") and row.data.has("action_result"))
   t.check(hits.size()==expected and hits.all(func(row):return row.data.base==g.Cards.Rules.SPECS[type].base),"WITCH training keeps separate base damage per hit "+str([count,free]))
   t.check(g.state.card_chain.is_empty() and g.state.energy==before.energy-(0 if count>=35 else 1),"WITCH training pays once and completes every segment "+str([count,free]))
   var saved=g.export_snapshot()
   t.check(Game.new(42).restore_snapshot(saved).ok,"WITCH training evolution restores consistently "+str([count,free]))
   g.Cards.end_powers(g);g._reset_piles()
   t.check(g.state.draw.any(func(item):return item.uid==card.uid and item.practice_plays==count+1),"WITCH training persists through session cleanup "+str([count,free]))
