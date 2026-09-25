extends RefCounted
const Game=preload("res://core/game.gd")

# Play policy only sees the same projection as the player. No state edits, hidden
# plans, draw order, future RNG, injected equipment or shortened enemy health.
static func choose(v: Dictionary, route_style: String="cautious", navigation: Dictionary={}) -> Dictionary:
 var best={}
 var best_score=-INF
 for c in v.display_facts:
  if not c.valid: continue
  var value=score(v,c,route_style,navigation)
  if value>best_score:
   best=c;best_score=value
 return best

# Remember only a successfully submitted visible direction, never hidden cells.
static func remember(v: Dictionary, c: Dictionary, navigation: Dictionary) -> void:
 if navigation.get("security",-1)!=v.get("security",0): navigation.clear()
 navigation.security=v.get("security",0)
 if c.payload.kind=="prison" and c.payload.action=="explore" and c.payload.has("direction"):
  navigation.heading=c.payload.direction

static func target(v: Dictionary, id: String) -> Dictionary:
 for b in v.bodies:
  if b.targets.has(id): return b.targets[id]
 return {}

static func score(v: Dictionary, c: Dictionary, style: String, navigation: Dictionary={}) -> float:
 var p=c.payload
 var kind=p.kind
 var fight=v.phase=="battle"
 if kind=="end": return -50
 # Current repeating enemies can outlast this simple escape-first policy.
 # Use the player's real surrender after thirty visible battle rounds, then
 # continue playing the actual prison route; never shorten enemy health.
 if kind=="surrender": return 200 if v.round>=30 else -INF
 if kind=="travel_step": return 100
 if kind=="depart":
  var room=v.route.filter(func(r):return r.id==p.room)[0]
  return {"battle":55,"shop":35,"treasure":95,"rest":90,"event":75 if style=="trade" else 20,"elite":85 if style=="elite" else 5,"weak":60,"strong":40,"boss":30,"exit":100,"entry":100}.get(room.icon,0)
 if kind in ["reward","rest_card"] or (kind=="event" and p.action=="reward"):
  if p.type=="skip": return 5
  return {"focus":50,"magic_slip":48,"brace":40,"inch":35,"peel":30,"double_unlock":25,"chain":20,"tear":15}.get(p.type,10) if v.deck_count<18 else (-100 if kind=="rest_card" else 0)
 if kind=="rest_flask": return 60
 if kind=="rest_begin": return 5
 if kind=="service":
  if p.op=="leave": return 40
  if p.op=="take" and c.mana==0: return 70
  return 10
 if kind=="event":
  if p.action=="choose": return 70 if p.choice==("single" if style=="trade" else "refuse") else (50 if p.choice=="refuse" else 10)
  return 60 # Fixed first visible key; never inspect the actual hidden winning key.
 if kind in ["retain_skip","chain"]: return 25
 if kind=="retain": return 30
 if kind=="calm": return 60 if v.pressure.value>=75 else (-10 if v.pressure.value>=25 and not fight else -100)
 if kind=="prison":
  match p.action:
   "enter","door_exit","vent_exit","key": return 200
   "unlock": return 100
   "explore":
    if v.prison.space.sites.any(func(site):return site.here and site.get("interaction",{}).get("kind","")=="vent") and v.prison.vent_hits<v.prison.vent_total: return -100
    if not p.has("site"):
     # Follow the wall using only the last submitted direction and currently
     # legal movement facts; blind exploration is a real player action.
     var directions=["north","east","south","west"]
     var heading=navigation.get("heading","north") if navigation.get("security",-1)==v.get("security",0) else "north"
     var forward=directions.find(heading)
     var order=[directions[posmod(forward-1,4)],heading,directions[(forward+1)%4],directions[(forward+2)%4]]
     return 69-order.find(p.direction)
    var sites=v.prison.space.sites.filter(func(site):return site.id==p.site)
    if sites.is_empty(): return -100
    var site=sites[0]
    var interaction=site.get("interaction",{}).get("kind","")
    if interaction=="vent": return 70-site.distance*0.1
    if interaction=="door" and (v.prison.door_open or v.prison.key): return 90-site.distance*0.1
    return (65 if not site.visited else -100)-site.distance*0.1
   "vent_kick": return 80
   "inspect","accept","resume": return 80
   # If repeated inspections have not led to escape, try the other real route.
   # Only the visible inspection count informs this choice; combat is unmodified.
   "resist": return 160 if v.prison.checks>=2 else -100
 if kind=="attack":
  var enemy=v.enemies.filter(func(e):return e.id==p.enemy)[0]
  var efficiency=minf(enemy.hp,p.damage)/maxi(1,c.cost)
  var mana_penalty=c.mana*(0.3 if v.mana>65 else 0.9)
  return (100 if p.damage>=enemy.hp else 0)+efficiency*2-mana_penalty+(8 if p.interrupt and v.order=="first" else 0)-(10 if p.fall else 0)
 if kind=="posture":
  # Free sit/stand changes at a wall must not replace ending an exhausted turn.
  if not fight and v.energy==0: return -100
  if v.phase=="prison":
   if v.prison.door_open and v.movement.speed<1 and p.dest in ["sit","stand"]: return 75-c.cost
   if "vent" in v.prison.found and v.prison.vent_hits<v.prison.vent_total and p.dest=="sit": return 65-c.cost
   if v.posture=="stand" and p.dest=="sit" and v.bodies.any(func(b):return b.id in ["calf","ankle","foot","toes"] and b.occupied): return -15
   return -100
  if v.posture!="stand" and p.dest!="lie":
   return (70 if fight or v.phase=="prison" else (30 if v.bodies.all(func(b):return not b.occupied) else -40))-c.cost-(10 if p.wall else 0)
  if not fight and v.posture=="stand" and p.dest=="sit" and v.bodies.any(func(b):return b.id in ["calf","ankle","foot","toes"] and b.occupied): return -15
  return -100
 if kind=="item_discard": return 70 if v.carried_items>v.capacity else -100
 if kind=="item_retrieve": return 55 if v.carried_items<v.capacity else -100
 if kind in ["finish_rest","finish_prepare"]: return -30 if not fight and v.bodies.all(func(b):return not b.occupied) and v.phase=="rest" else -80
 if kind=="finish_pack": return 80
 if kind in ["card","manual","hook","item_use"]:
  if p.get("free",false):
   if fight: return -60
   return {"slip":6,"peel":5,"strain":4,"brace":4,"focus":3,"ease":2,"unlock":1}.get(p.type,0)
  var e=target(v,p.get("target",""))
  if e.is_empty(): return -100
  var reduction=0.0
  if p.has("preview"): reduction=minf(e.durability,p.preview.damage)
  elif p.has("after"): reduction=e.durability-p.after
  elif kind=="item_use":
   var item=v.items.filter(func(i):return i.id==p.item)[0]
   reduction=minf(e.durability,item.damage)
  if reduction<=0: return -60
  var weight={"wrist":9,"fingers":8,"mouth":9,"eyes":7,"ankle":5,"forearm":4,"upper_arm":4}.get(e.slot,2)
  if fight and (v.arms>=3 and e.slot in ["wrist","forearm","upper_arm"] or e.slot=="mouth"): weight+=12
  return reduction/maxi(1,c.cost)+(weight if fight else weight*2)+(8 if reduction>=e.durability else 0)-c.mana*0.4
 return -100

static func run(t) -> void:
 var resist={"valid":true,"payload":{"kind":"prison","action":"resist"}}
 var escape={"valid":true,"payload":{"kind":"prison","action":"door_exit"}}
 var visible={"phase":"inspection","prison":{"checks":1},"facts":[resist,escape]}
 t.check(score(visible,resist,"cautious")<0,"NORMAL repeated-inspection fallback does not immediately abandon the first escape attempt")
 visible.prison.checks=2
 var before=visible.duplicate(true)
 t.check(score(visible,resist,"cautious")>0 and choose(visible)==escape,"NORMAL inspection fallback still prefers an available real escape")
 t.check(visible==before,"NORMAL policy reads the visible projection without modifying it")
 var surrender={"valid":true,"payload":{"kind":"surrender"}}
 var end={"valid":true,"payload":{"kind":"end"}}
 var battle={"phase":"battle","round":29,"facts":[surrender,end]}
 t.check(choose(battle)==end,"NORMAL repeating battle still plays before the visible round bound")
 battle.round=30;before=battle.duplicate(true)
 t.check(choose(battle)==surrender and battle==before,"NORMAL bounded battle fallback selects the real surrender without changing the view")
 surrender.valid=false
 t.check(choose(battle)==end,"NORMAL fallback cannot invent an unavailable surrender")
 var north={"valid":true,"payload":{"kind":"prison","action":"explore","direction":"north"}}
 var east={"valid":true,"payload":{"kind":"prison","action":"explore","direction":"east"}}
 var west={"valid":false,"payload":{"kind":"prison","action":"explore","direction":"west"}}
 var blind={"phase":"prison","security":1,"prison":{"space":{"sites":[]},"vent_hits":0,"vent_total":3},"facts":[north,east,west,end]}
 var navigation={};before=blind.duplicate(true)
 t.check(choose(blind,"cautious",navigation)==north and navigation.is_empty() and blind==before,"NORMAL blind exploration uses legal visible directions without changing the view or remembering an uncommitted action")
 remember(blind,north,navigation);north.valid=false
 t.check(choose(blind,"cautious",navigation)==east,"NORMAL wall following turns at an actually blocked direction")
 blind.prison.space.sites=[{"here":true,"interaction":{"kind":"vent"}}]
 t.check(choose(blind,"cautious",navigation)==end,"NORMAL waits at the discovered vent instead of walking away between required kicks")
 blind.display_facts.append(escape)
 t.check(choose(blind,"cautious",navigation)==escape,"NORMAL real escape takes priority over further exploration")
 var reports=[]
 for setup in [[42,"cautious"],[20260906,"elite"],[7,"trade"]]:
  var g=Game.new(setup[0])
  navigation={}
  var report={"seed":setup[0],"style":setup[1],"initial":g.get_view().enemies,"steps":[],"rooms":[],"result":"action_limit"}
  var last_room=""
  var start_ticks=Time.get_ticks_msec()
  for i in range(1800):
   # Diagnostic checkpoint only; the play policy never reads this file or state.
   # Preserve the last reproducible position even if a later action times out.
   if i%25==0:
    var checkpoint=FileAccess.open("res://build/normal-checkpoint-%d.json" % setup[0],FileAccess.WRITE)
    if checkpoint!=null: checkpoint.store_string(JSON.stringify({"seed":setup[0],"style":setup[1],"step":i,"state":g.export_snapshot()}))
   var v=g.get_view()
   if v.room_name!=last_room:
    last_room=v.room_name
    report.rooms.append({"name":last_room,"phase":v.phase,"mana":v.mana,"pressure":v.pressure.value,"deck":v.deck_count,"arms":v.arms,"legs":v.legs,"step":i})
   if v.phase in ["cleared","prison_end"] or (v.phase=="map" and v.security>0):
    report.result="prison_route" if v.phase=="map" and v.map_region=="prison" else ("escaped" if v.phase=="map" else v.phase)
    break
   var c=choose(v,setup[1],navigation)
   if i%25==0: print("NORMAL PROGRESS seed=%d step=%d phase=%s room=%s security=%d action=%s ms=%d" % [setup[0],i,v.phase,v.room_name,v.security,c.get("label","none"),Time.get_ticks_msec()-start_ticks])
   if c.is_empty():
    report.result="no_candidate";break
   report.steps.append({"phase":v.phase,"room":v.room_name,"round":v.round,"kind":c.payload.kind,"payload":c.payload,"energy":v.energy,"mana":v.mana,"label":c.label})
   var result=g.dispatch(g.command(c.payload,v.version),v.version)
   t.check(result.ok,"NORMAL %s #%d %s" % [setup[1],i,c.label])
   if not result.ok:
    report.result=result.error;break
   remember(v,c,navigation)
  var final=g.get_view()
  report.final={"phase":final.phase,"room":final.room_name,"mana":final.mana,"pressure":final.pressure.value,"security":final.security,"encounters":final.encounter,"rewards":final.reward_count,"equipment":g.equipment_targets().size(),"statuses":final.statuses.map(func(status):return {"id":status.id,"value":status.value})}
  report.elapsed_ms=Time.get_ticks_msec()-start_ticks
  t.check(g.validate()=="","NORMAL final real state validates")
  t.check(report.result in ["cleared","escaped","prison_route","prison_end"],"NORMAL bounded run reaches a real completion or prison-route checkpoint")
  reports.append(report)
  print("NORMAL "+JSON.stringify({"seed":report.seed,"style":report.style,"result":report.result,"actions":report.steps.size(),"final":report.final,"ms":report.elapsed_ms}))
 DirAccess.make_dir_recursive_absolute("res://build")
 var file=FileAccess.open("res://build/normal-play.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(reports,"  "))
