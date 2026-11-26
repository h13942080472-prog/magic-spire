extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Battle="anti_mage_drone_solo"

static func run(t) -> void:
 opening(t)
 spells(t)
 weaken(t)

static func opening(t) -> void:
 var g=Game.new(42,true,Battle)
 var drone=g.state.enemies[0]
 var maximum=g.Equipment.maximum(3)
 var old=g._install_template("mouth_band","mouth",maximum,maximum,true,"fixture",3,0,0)
 g._install_template("mouth_tape","mouth",8.0,10.0,false,"fixture")
 var prior=g.add_fixture("ankle",4.0)
 g.state.evasion=3
 t.check(drone.hp==70 and drone.intent.kind=="bind_apply" and t.action(g,"end").ok,"ANTI DRONE 70 HP and opening through turn end")
 var mouth=g.equipment_at("mouth")
 t.check(mouth.size()==1 and mouth[0].id!=old.id and mouth[0].grade==2 and mouth[0].variant==1 and mouth[0].locked and g.equipment_tier(mouth[0])==3,"ANTI DRONE forces the prescribed locked gag through stronger layered gear and dodge")
 t.check(g.state.guard_bind.get("progress",0)==40 and g.state.guard_bind.sources.anti_mage_drone.fitted.is_empty(),"ANTI DRONE opening replacement contributes no capture")
 mouth[0].durability=0;g._equipment(prior.id).durability=0;g._cleanup()
 t.check(g.state.guard_bind.progress==40,"ANTI DRONE opening gag and pre-battle gear do not refund capture")
 var spec=g.EnemyPlans.application(["belt","fine_belt","tape","cable_tie"],1,2)
 spec.allow_links=false
 g.state.evasion=0
 for i in 40:
  if g.Cards.worn_count(g)>=20: break
  g.Application.execute(g,spec,"fixture")
 g.state.round=g.B.ENEMY_LONG_BATTLE_ROUND
 g.CaptureBind.gain_bind(g,100,"fixture")
 t.check(g.EnemyPlans.long_battle_limit(g),"ANTI DRONE arrest fixture also meets the long battle departure threshold")
 t.check(g._enemy(drone.id).intent.kind=="capture" and t.action(g,"end").ok and g.state.phase=="captured" and g.validate()=="","ANTI DRONE full capture reaches a valid imprisonment state")

static func spells(t) -> void:
 var g=Game.new(42,true,Battle)
 t.action(g,"end")
 var id=g.state.enemies[0].id
 for index in 2:
  var card=t.grant_fixture_card(g,"mana_surge")
  g.state.sure_cast=true
  t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok,"ANTI DRONE paid magic card settles normally")
  if index==0:
   t.check(g.state.guard_bind.progress==42 and g.state.combat.mana_listeners[id]==1 and g.state.guard_bind.sources.anti_mage_drone.spells==1,"ANTI DRONE first card records payment and progress separately")
   Save.roundtrip(t,g,"anti-drone odd mana and magic counters")
 var ledger=g.state.guard_bind.sources.anti_mage_drone.fitted
 t.check(ledger.size()==2 and ledger.values().all(func(v):return v==4) and g.state.guard_bind.progress==52 and g.state.combat.mana_listeners[id]==0,"ANTI DRONE second spell consumes listening bonus immediately and charges both successful fits")
 if ledger.is_empty(): return
 var item=g._equipment(ledger.keys()[0])
 item.durability=0.0;g._cleanup();g._cleanup()
 t.check(g.state.guard_bind.progress==48 and ledger.size()==1,"ANTI DRONE releasing a registered item refunds its entry value exactly once")
 var before=g.export_snapshot()
 var bad=before.duplicate(true);bad.guard_bind.sources.anti_mage_drone.spells=2
 t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==before,"ANTI DRONE invalid half-pair rolls back atomically")
 bad=before.duplicate(true);bad.combat.erase("mana_listeners")
 t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==before,"ANTI DRONE an active listener cannot disappear on load")
 var request={"kind":"install","template":"mouth_band","slot":"mouth","grade":3,"tier":3,"locked":true,"variant":0,"point":"mouth"}
 var plan=g.Application.Replacement.plan(g,[request],"fixture")
 t.check(plan.ok and g.export_snapshot()==before,"ANTI DRONE replacement preview never counts fitted equipment or mana changes")
 var committed=g.Application.Replacement.execute(g,plan)
 t.check(committed.ok and g.state.guard_bind.progress==before.guard_bind.progress+6 and g.state.guard_bind.sources.anti_mage_drone.fitted.size()==before.guard_bind.sources.anti_mage_drone.fitted.size()+1,"ANTI DRONE committed replacement registers only its new physical item once")
 g.CaptureBind.damage_bind(g,100,"fixture")
 g.equipment_at("mouth")[0].durability=0.0;g._cleanup()
 g.state.posture="sit"
 for op in ["deposit","withdraw"]: t.check(t.action(g,"flask",{"op":op}).ok,"ANTI DRONE dispatches real flask "+op)
 t.check(g.get_view().enemies[0].intent_icons[0].badge=="2" and g.state.combat.mana_listeners[id]==2,"ANTI DRONE both mana directions count even after capture breaks")
 var free=t.grant_fixture_card(g,"mana_surge")
 t.check(t.action(g,"card",{"uid":free.uid,"free":true}).ok and g.state.guard_bind.is_empty() and g.state.combat.mana_listeners[id]==2,"ANTI DRONE temporary mana alone leaves the listener unchanged")

static func weaken(t) -> void:
 var g=Game.new(42,true,Battle)
 t.action(g,"end");t.action(g,"end")
 var id=g.state.enemies[0].id
 var item=g.state.equipment.filter(func(piece):return piece.slot!="mouth")[0]
 var arm=g.BasicAttacks.physical_damage(g,8,0)
 var strained=g.Cards.bind_payload(g,"strain","").preview.damage
 var slipped=g.Cards.bind_payload(g,"slip","").preview.damage
 for i in 6: g.set_own_mana(80.0 if i%2==0 else 90.0)
 t.check(g.get_view().enemies[0].intent_icons[0].badge=="4","ANTI DRONE weakening intent projects all three banked extras")
 var total=g.state.equipment.size()
 t.check(t.action(g,"end").ok and g.state.combat.drone_weakness==2 and g._enemy(id).intent.kind=="drone_fit","ANTI DRONE weaken keeps its two-turn loop")
 t.check(g.state.equipment.size()==total and g._equipment(item.id).locked and g.equipment_tier(g._equipment(item.id))==3 and g.state.combat.mana_listeners[id]==0,"ANTI DRONE excess lock targets expire and only eligible items tighten")
 t.check(is_equal_approx(g.BasicAttacks.physical_damage(g,8,0),arm*0.75) and is_equal_approx(g.Cards.bind_payload(g,"strain","").preview.damage,strained*0.75) and g.Cards.bind_payload(g,"slip","").preview.damage==slipped,"ANTI DRONE weakness reduces physical and struggle damage only")
 Save.roundtrip(t,g,"anti-drone weakness and capture contributions")
 t.action(g,"end")
 t.check(g.state.combat.drone_weakness==1 and g._enemy(id).intent.kind=="drone_weaken","ANTI DRONE weakness loses one layer per player turn")
