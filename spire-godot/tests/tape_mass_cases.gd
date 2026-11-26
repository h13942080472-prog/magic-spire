extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Tape=preload("res://core/tape_mass.gd")
const Battle="tape_mass_solo"

static func run(t) -> void:
 var seen=[]
 for seed in range(1,25):
  var g=Game.new(seed,true,Battle)
  var start=g.state.enemies[0].intent.kind
  if start in seen: continue
  seen.append(start)
  cycle(t,g,start)
  if seen.size()==2: break
 t.check(seen.size()==2,"TAPE MASS both openers appear from seeded battle entry")
 defense(t)
 preload("res://tests/tower_cases.gd").second_act_strong_groups(t)

static func cycle(t,g,start: String) -> void:
 var enemy=g.state.enemies[0]
 t.check(enemy.type==Tape.TYPE and enemy.hp==76 and enemy.flex_next==3 and enemy.mech_armor==0,"TAPE MASS enters at full health with flexible three and zero block")
 var sequence=[Tape.BOOST,Tape.FIT,Tape.FIT,Tape.BOOST,Tape.FIT,Tape.FIT]
 if start==Tape.FIT: sequence.push_front(Tape.FIT)
 var charges=0
 for i in sequence.size():
  var move=sequence[i]
  var id=enemy.id
  var before=g.export_snapshot()
  t.check(g._plan(enemy)==enemy.intent and g.export_snapshot()==before,"TAPE MASS preview preserves seeded sequence")
  t.check(enemy.intent.kind==move and Tape.boost_left(enemy)==charges,"TAPE MASS announced move and remaining boosted actions match at step "+str(i))
  if i==1:
   Save.roundtrip(t,g,"tape cycle mid-sequence")
   t.check(t.action(g,"posture",{"dest":"sit","wall":false}).ok and t.action(g,"attack",{"type":"kick","form":0,"enemy":id}).ok and g._enemy(id).intent.delayed,"TAPE MASS seated kick delays the real announced intent")
   var restored=Save.roundtrip(t,g,"tape interrupted with earned block")
   var stage=enemy.stage
   Save.step_both(t,g,restored,"end")
   t.check(g._enemy(id).stage==stage and g._enemy(id).intent.kind==move and Tape.boost_left(g._enemy(id))==charges,"TAPE MASS interruption retains the complete next batch")
  var old=g.state.equipment.map(func(item):return item.id)
  t.check(t.action(g,"end").ok,"TAPE MASS executes the announced move")
  enemy=g._enemy(id)
  if move==Tape.BOOST:
   charges=2
   t.check(g.state.combat.get("drone_weakness",0)==2 and g.Cards.weakness(g)==0.75,"TAPE MASS charge applies the shared two-layer weakness")
  else:
   var added=g.state.equipment.filter(func(item):return item.id not in old)
   var score=5 if charges>0 else 4
   t.check(added.size()==3 and added.all(func(item):return item.material=="tape" and item.grade+g.equipment_tier(item)==score),"TAPE MASS every successful piece uses the same action strength")
   charges=maxi(0,charges-1)
   # Keep enough legal slots to observe two full cycles.
   for item in added: item.durability=0.0
   g._cleanup()
  t.check(g.validate()=="","TAPE MASS state remains valid after move "+str(i))

static func defense(t) -> void:
 var g=Game.new(42,true,Battle)
 var id=g.state.enemies[0].id
 var hit=t.action(g,"attack",{"type":"heavy","form":1,"enemy":id})
 var enemy=g._enemy(id)
 var gains=g.state.logs.filter(func(log):return log.data.has("block_gain")).map(func(log):return log.data.block_gain)
 t.check(hit.ok and gains==[3,4,5] and enemy.hp==65 and enemy.mech_armor==5 and enemy.flex_next==6,"TAPE MASS real three-hit physical attack deals damage first and triggers per hit")
 g._damage_enemy(enemy,1,"physical","fixture",{"attack":true})
 t.check(enemy.hp==65 and enemy.mech_armor==10 and enemy.flex_next==7,"TAPE MASS fully blocked physical hit still earns the next block")
 g._damage_enemy(enemy,1,"fixed","fixture")
 t.check(enemy.mech_armor==9 and enemy.flex_next==7 and enemy.hp==65,"TAPE MASS fixed damage absorbs block without triggering flexibility")
 g.state.sure_cast=true
 t.check(t.action(g,"attack",{"type":"fireball","enemy":id}).ok and g._enemy(id).flex_next==7 and g._enemy(id).mech_armor==0 and g._enemy(id).hp<65,"TAPE MASS real fireball spends block without triggering flexibility")
 enemy=g._enemy(id)
 Save.roundtrip(t,g,"tape active block and next gain")
 var before=g.export_snapshot()
 for field in ["flex_next","mech_armor","tape_opens_fit","intent"]:
  var bad=before.duplicate(true)
  match field:
   "flex_next": bad.enemies[0].flex_next=2
   "mech_armor": bad.enemies[0].mech_armor=1000
   "tape_opens_fit": bad.enemies[0].tape_opens_fit=1
   "intent": bad.enemies[0].intent.kind=Tape.FIT if enemy.intent.kind==Tape.BOOST else Tape.BOOST
  t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==before,"TAPE MASS malformed save rejected atomically: "+field)
 t.check(t.action(g,"end").ok and g._enemy(id).flex_next==3 and g._enemy(id).mech_armor==0,"TAPE MASS owner turn resets both block and its next gain")
 enemy=g._enemy(id)
 g._damage_enemy(enemy,1000,"physical","fixture",{"attack":true})
 t.check(enemy.gone and enemy.mech_armor==0 and enemy.flex_next==3,"TAPE MASS lethal hit cannot generate block")
