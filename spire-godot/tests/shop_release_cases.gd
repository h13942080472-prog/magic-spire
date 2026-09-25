extends RefCounted
const Game=preload("res://core/game.gd")

static func shop() -> RefCounted:
 var g=Game.new(42)
 g.state.room=g.state.rooms.filter(func(r):return r.kind=="shop")[0].id
 g.Services.start(g)
 return g

static func unchanged(t, g, before: Dictionary) -> void:
 for key in ["energy","posture","round","tick","rng","pressure","temporary_mana","charge","deck","items"]:
  t.check(g.state[key]==before[key],"SHOP RELEASE preserves "+key)

static func plate_payment(t) -> void:
 var g=shop();g.state.flask_mana=500
 var wrist=g.add_fixture("wrist",8)
 var lock=g._install_special("negative_plate_lock_medium","special_2_a",2)
 for op in ["remove","release"]:
  var payload={"op":op,"payment":"self"}
  if op=="release": payload.target=wrist.id
  var blocked=t.find_action(g,"service",payload)
  var before=g.export_snapshot()
  t.check(not blocked.valid and blocked.reason==g.Services.ShopCopy.PLATE_SELF_BLOCK_REASON and not g.dispatch(g.command(blocked.payload,g.state.version),g.state.version).ok and g.state==before,"SHOP PLATE self mana cannot pay for "+op+" and rejection preserves state")
  payload.payment="flask"
  var allowed=t.find_action(g,"service",payload)
  var mana=g.state.mana;var bottle=g.state.flask_mana
  t.check(allowed.valid and g.dispatch(g.command(allowed.payload,g.state.version),g.state.version).ok and g.state.mana==mana and g.state.flask_mana==bottle-allowed.mana and not g._equipment(lock.id).is_empty(),"SHOP PLATE bottle payment remains usable for "+op)
 var release=t.find_action(g,"service",{"op":"release","target":lock.id,"payment":"self"})
 t.check(release.valid and g.dispatch(g.command(release.payload,g.state.version),g.state.version).ok and g._equipment(lock.id).is_empty() and t.find_action(g,"service",{"op":"take","payment":"self"}).valid,"SHOP PLATE own mana may remove the normal lock and restore normal payment")
 g=shop();g.state.flask_mana=500;wrist=g.add_fixture("wrist",8)
 var stale=t.find_action(g,"service",{"op":"release","target":wrist.id,"payment":"flask"})
 g.RelicEffects.gain(g,"cursed_plate_lock")
 var before=g.export_snapshot()
 var releases=g.command_facts().filter(func(c):return c.payload.kind=="service" and c.payload.op=="release")
 t.check(releases.size()>=4 and releases.all(func(c):return not c.valid) and g.Services.release_jobs(g).all(func(job):return job.reason==g.Services.ShopCopy.CURSED_PLATE_SERVICE_REASON),"SHOP CURSED PLATE blocks every release target and both payment sources")
 for c in releases:
  t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"SHOP CURSED PLATE denied release never pays or removes equipment")
 t.check(not g.dispatch(g.command(stale.payload,g.state.version),g.state.version).ok and g.state==before,"SHOP CURSED PLATE commit rechecks newly worn curse against old release choice")
 t.check(t.find_action(g,"service",{"op":"remove","payment":"flask"}).valid and t.find_action(g,"service",{"op":"take","payment":"flask"}).valid,"SHOP CURSED PLATE does not disable unrelated bottle purchases or card removal")

static func run(t) -> void:
 plate_payment(t)
 for locked in [false,true]:
  var g=shop()
  var target=g.add_fixture("ankle",8,10,locked,0,"belt")
  var wrist=g.add_fixture("wrist",8)
  g.state.posture="lie";g.state.pressure=70;g.state.temporary_mana=10;g.state.charge=2
  var before=g.export_snapshot()
  var c=t.find_action(g,"service",{"op":"release","target":target.id})
  t.check(c.valid and c.cost==0 and c.mana==(30 if locked else 20),"SHOP RELEASE ordinary exact quote with blocked player hands")
  g.get_view();g.command_facts()
  t.check(g.export_snapshot()==before,"SHOP RELEASE quote never mutates")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._equipment(target.id).is_empty(),"SHOP RELEASE complete ordinary removal")
  t.check(g._equipment(wrist.id)==wrist and g.state.mana==100-c.mana,"SHOP RELEASE unrelated equipment preserved and exact payment")
  unchanged(t,g,before)
  var committed=g.export_snapshot()
  t.check(not g.dispatch(g.command(c.payload,before.version),before.version).ok and g.export_snapshot()==committed,"SHOP RELEASE stale purchase rejected atomically")
  var restored=Game.new(8)
  t.check(restored.restore_snapshot(committed).ok and preload("res://tests/persistence_cases.gd").same(restored.export_snapshot(),committed),"SHOP RELEASE save round trip")
  t.check(t.action(g,"service",{"op":"release","target":wrist.id}).ok,"SHOP RELEASE may buy again for another root")
 for spec in [["glove","long"],["leg","upper"],["leg","lower"],["jacket","standard"]]:
  var g=shop()
  var kept=g.add_fixture("eyes",4)
  var root=g._install_assembly(spec[0],spec[1],"fixture")
  t.check(not root.is_empty(),"SHOP RELEASE composite fixture "+str(spec))
  for part in root.components: part.locked=g.Equipment.allows(part,"lock")
  var ids=root.components.map(func(p):return p.id)
  var c=t.find_action(g,"service",{"op":"release","target":root.id})
  var has_lock=root.components.any(func(p):return p.locked)
  t.check(c.valid and c.mana==(45 if has_lock else 35),"SHOP RELEASE lock surcharge once for whole composite")
  var before=g.export_snapshot()
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"SHOP RELEASE composite commits "+str(spec))
  t.check(g.state.composites.is_empty() and ids.all(func(id):return g._equipment(id).is_empty()) and g._equipment(kept.id)==kept,"SHOP RELEASE removes body and independent bands, keeps other roots")
  unchanged(t,g,before)
 var g=shop()
 var inner=g.add_fixture("thigh",4)
 var outer=g.add_fixture("thigh",4,10,false,1)
 outer.points=inner.points.duplicate();outer.layer=1
 var c=t.find_action(g,"service",{"op":"release","target":inner.id})
 var before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("外层") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"SHOP RELEASE covered target cannot charge or remove other roots")
 t.check(t.action(g,"service",{"op":"release","target":outer.id}).ok and t.find_action(g,"service",{"op":"release","target":inner.id}).valid,"SHOP RELEASE exposure refreshes after outer removal")
 g.state.mana=19
 c=t.find_action(g,"service",{"op":"release","target":inner.id});before=g.export_snapshot()
 t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"SHOP RELEASE insufficient mana preserves all state")
 g.state.mana=20
 t.check(t.action(g,"service",{"op":"release","target":inner.id}).ok and g.state.mana==0,"SHOP RELEASE exact balance accepted")
 g=shop()
 var a=g._install_template("rope","calf",8,10,false,"fixture",1,-1,0,"mid_calf")
 var b=g.add_fixture("ankle",8)
 var link=g._install_link(a.id,b.id,8,"fixture")
 var target_id=link.id
 t.check(t.action(g,"service",{"op":"release","target":target_id}).ok and g.state.links.is_empty() and g._equipment(a.id)==a and g._equipment(b.id)==b,"SHOP RELEASE connection-only service preserves both endpoints")
 link=g._install_link(a.id,b.id,8,"fixture")
 t.check(t.action(g,"service",{"op":"release","target":a.id}).ok and g.state.links.is_empty() and g._equipment(b.id)==b,"SHOP RELEASE root removal uses dependency cleanup")
 g=shop()
 var host=g._install_template("belt","upper_arm",10,10,false,"fixture")
 var pair=g.Shoulders.attached(g,host)
 t.check(pair.size()==2,"SHOP RELEASE ordinary attachment fixture")
 for strap in pair: strap.locked=true
 c=t.find_action(g,"service",{"op":"release","target":host.id})
 t.check(c.valid and c.mana==30,"SHOP RELEASE ordinary attached locks add once without composite surcharge")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.action_targets().is_empty(),"SHOP RELEASE attached straps, torso connection fully cleaned")
 g=shop();a=g.add_fixture("wrist",4)
 g.state.relics.append("break_bracer");g.state.relics.append("ember_crystal")
 var charge=g.state.charge
 t.check(t.action(g,"service",{"op":"release","target":a.id}).ok and g.state.charge==charge and g.state.mana==80,"SHOP RELEASE labor is neither strain damage nor refundable spell")
 g=shop();a=g.add_fixture("wrist",4)
 # Force final validation failure to exercise the same transaction rollback as all actions.
 g.state.mana=101
 c=t.find_action(g,"service",{"op":"release","target":a.id})
 g.state.energy=-1;before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"SHOP RELEASE post-execution validation failure rolls back payment and removal")
