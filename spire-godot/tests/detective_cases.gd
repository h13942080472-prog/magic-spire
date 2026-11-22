extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const D=preload("res://core/succubus_detective.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Battle="succubus_detective_solo"

static func run(t) -> void:
 cuffs(t)
 rotation(t)
 provoke(t)
 var g=Game.new(71,true,Battle)
 t.check(Battle in g.Tower.strong_groups(1) and Battle not in g.Tower.strong_groups(0) and Battle not in g.Tower.available_weak_groups(1,[]),"DETECTIVE only the Act II strong pool draws the solo encounter")

static func unlock(t,g,id: String) -> bool:
 var c=t.grant_fixture_card(g,"unlock")
 g.state.hand.erase(c);g.state.hand.insert(1,c)
 g.state.sure_cast=true
 return t.action(g,"card",{"uid":c.uid,"target":id,"free":false}).ok

static func cuffs(t) -> void:
 var g=Game.new(42,true,Battle)
 var e=g.state.enemies[0]
 t.check(e.hp==86 and e.ready_layers==0 and g.Enemies.TYPES[e.type].humanoid and t.action(g,"end").ok,"DETECTIVE 86 HP humanoid opens with arrest and no ready stacks")
 e=g.state.enemies[0]
 t.check(e.detective_cuffs.size()==2 and g.state.guard_bind.progress==40 and g.state.guard_bind.sources[D.TYPE].fitted.is_empty(),"DETECTIVE two opening cuffs do not add ordinary ledger value")
 var left=g.state.hand.front().uid
 var right=g.state.hand.back().uid
 var r=t.find_action(g,"card",{"uid":right})
 var before=g.export_snapshot()
 t.check(not r.valid and not r.payload.is_empty() and not g.dispatch(g.command(r.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"DETECTIVE a locked real card command cannot pay or mutate state")
 t.check(D.chained(g,left) and D.chained(g,right) and not D.chained(g,g.state.hand[1].uid),"DETECTIVE exactly current hand edges are chained")
 g._draw(1)
 t.check(not D.chained(g,right) and D.chained(g,g.state.hand.back().uid),"DETECTIVE drawing shifts the right chain immediately")
 e=g.state.enemies[0]
 var wrist=e.detective_cuffs.wrist
 var ankle=e.detective_cuffs.ankle
 var foreign=g._install_template("handcuffs","wrist",999,999,true,"fixture")
 g._unlock_equipment(foreign);g._cleanup()
 t.check(g.state.guard_bind.progress==40 and e.detective_cuffs.wrist==wrist,"DETECTIVE unrelated cuffs cannot release the edge and refund only their own ordinary value")
 t.check(unlock(t,g,wrist) and g.state.guard_bind.progress==20 and not D.chained(g,g.state.hand.front().uid) and D.chained(g,g.state.hand.back().uid) and g.state.enemies[0].intent.kind==D.PACK,"DETECTIVE unlocking wrist with a real spell frees only the left edge")
 var saved=Save.roundtrip(t,g,"detective single cuff")
 if saved!=null:
  var bad=saved.export_snapshot();bad.enemies[0].detective_cuffs.clear()
  var prior=saved.export_snapshot()
  t.check(not saved.restore_snapshot(bad).ok and saved.export_snapshot()==prior,"DETECTIVE missing cuff identity is rejected without mutation")
  bad=saved.export_snapshot();bad.guard_bind.sources[D.TYPE].fitted[ankle]=4
  t.check(not saved.restore_snapshot(bad).ok and saved.export_snapshot()==prior,"DETECTIVE managed cuffs cannot also be counted as ordinary equipment")
 t.check(unlock(t,g,ankle) and g.state.guard_bind.is_empty() and g.state.enemies[0].intent.kind==D.CUFF,"DETECTIVE releasing the last cuff breaks capture and changes announced Pack to Recuff")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==20 and g.state.enemies[0].detective_cuffs.size()==2 and g.state.enemies[0].intent.kind==D.RESTRAIN,"DETECTIVE both fresh cuffs rebuild capture at ten each without a new forty")
 t.check(D.chained(g,g.state.hand.front().uid) and D.chained(g,g.state.hand.back().uid),"DETECTIVE recuff restores both live locks")
 var single=g.state.hand.pop_back()
 g.state.discard.append_array(g.state.hand);g.state.hand=[single]
 t.check(D.chained(g,single.uid),"DETECTIVE a single card occupies both edges")
 g._unlock_equipment(g._equipment(g.state.enemies[0].detective_cuffs.wrist));g._cleanup()
 t.check(g.state.guard_bind.is_empty() and not D.chained(g,single.uid),"DETECTIVE capture hitting zero releases all chain effects even if a cuff remains")

static func rotation(t) -> void:
 for security in [0,2,5]:
  var g=Game.new(48,true,Battle)
  var e=g.state.enemies[0]
  g.state.security=security
  t.action(g,"end")
  var base=40
  var n=1+security
  var score=maxi(2,n)
  t.check(t.action(g,"end").ok,"DETECTIVE Pack commits at security "+str(security))
  var ties=g.state.equipment.filter(func(item):return item.template=="cable_tie")
  t.check(ties.size()==n+1 and ties.all(func(item):return item.grade+g.equipment_tier(item)==score) and g.state.guard_bind.progress==base+(n+1)*score,"DETECTIVE Pack fits the requested count and actual values enter capture")
  if ties.is_empty(): continue
  ties[0].durability=0.0;g._cleanup()
  var before=g.state.guard_bind.progress
  t.check(before==base+n*score,"DETECTIVE releasing a tie refunds exactly its installation value")
  # Keep player initiative to inspect third and fourth actions separately.
  g._enemy_phase()
  var items=g.state.special_equipment.filter(func(item):return not g.SpecialEquipment.is_reinforcement(item))
  var hog=g.worn_hogtie()
  var gag=g.equipment_at("mouth").filter(func(item):return item.template=="mouth_band")
  t.check(not items.is_empty() and items.size()<=n and items.all(func(item):return item.grade+g.equipment_tier(item)==score),"DETECTIVE fitted toys have the security-value profile")
  t.check(gag.size()==1 and gag[0].grade+g.equipment_tier(gag[0])==score and hog.get("template","")==D.HOGTIE and hog.grade+g.equipment_tier(hog)==score and g.state.posture=="lie","DETECTIVE mouth gag and wrist-ankle zip hogtie match the score")
  t.check(g.state.guard_bind.progress==minf(100.0,before+20+2*score) and items.all(func(item):return not g.state.guard_bind.sources[D.TYPE].fitted.has(item.id)),"DETECTIVE third move grants twenty and excludes toys from both capture directions")
  if security==5:
   g._start_round()
   t.check(g.state.phase=="captured" and g.validate()=="","DETECTIVE capture at one hundred uses the shared arrest flow")
   continue
  var tiers={}
  for item in ties.slice(1)+items+gag+[hog]: tiers[item.id]=g.equipment_tier(item)
  g._start_round()
  t.check(g.state.deck.filter(func(card):return card.type==D.STATUS).size()==n and g.state.draw.filter(func(card):return card.type==D.STATUS).size()==n,"DETECTIVE fourth move puts the security-scaled status count into draw")
  t.check(tiers.keys().all(func(id):return g.equipment_tier(g._equipment(id))==mini(3,tiers[id]+1)) and g.state.enemies[0].stage==5,"DETECTIVE fourth move tightens each eligible item one tier and cycles to Pack")
  Save.roundtrip(t,g,"detective hogtie and delayed hand status")
 var g=Game.new(5,true,Battle)
 t.action(g,"end")
 var e=g.state.enemies[0]
 g._unlock_equipment(g._equipment(e.detective_cuffs.ankle));g._cleanup()
 g.CaptureBind.damage_bind(g,100,"fixture")
 t.check(g.state.guard_bind.is_empty(),"DETECTIVE capture was broken ahead of the third move")
 D.execute(g,e,D.RESTRAIN)
 t.check(g.worn_hogtie().is_empty(),"DETECTIVE third move requires equipment at both wrists and ankles")

 t.check(g.state.guard_bind.progress==22 and e.detective_cuffs.size()==1 and not D.chained(g,g.state.hand.back().uid),"DETECTIVE third move rebuilds twenty, counts the gag and preserves the released ankle")

static func provoke(t) -> void:
 var g=Game.new(7,true,Battle)
 var toy=g._install_special("urethral_rod_low","special_2_d",1)
 var card=g._gain_temporary_card(D.STATUS,true)
 g.state.discard.append_array(g.state.hand);g.state.hand.clear()
 g.state.draw.erase(card);g.state.draw.push_back(card)
 var p=g.state.pressure
 var traction=g.SpecialEquipment.effective_gain(g,toy,"energy")
 g._draw(1)
 t.check(g.state.hand.has(card) and is_equal_approx(g.state.pressure,p+10+traction) and g.state.logs.filter(func(log):return log.data.has("provoke_traction")).size()==1,"DETECTIVE actual draw triggers pleasure and traction once")
 var energy=g.state.energy
 p=g.state.pressure
 t.check(t.action(g,"card",{"uid":card.uid}).ok and g.state.energy==energy-1 and g.state.exhaust.any(func(item):return item.uid==card.uid) and is_equal_approx(g.state.pressure,p+10+2*traction) and g.state.logs.filter(func(log):return log.data.has("provoke_traction")).size()==2,"DETECTIVE one-cost status triggers one card traction plus one payment traction and exhausts")
 t.check(traction>0,"DETECTIVE status test uses an active traction source")
