extends RefCounted

const Game=preload("res://tests/game_fixture.gd")
# Living index-off reference for the B5 parity checks (single definition in the architecture suite).
const Arch=preload("res://tests/architecture_cases.gd")

static func ids(values: Array) -> Array:
 return values.map(func(e):return e.id)

# docs/spec/equipment-query-seam.md「证据入口」: the rope, anchor and target-list edges keep the declared order and the durability
# differences between them: a dead rope leaves links_at, yet links stay unfiltered in the lists.
static func index_link_edge_parity(t) -> void:
 for kind in ["component_links","crotch","plain"]:
  var g=Game.new(42)
  g.state.equipment.clear();g.state.composites.clear();g.state.links.clear();g.state.special_equipment.clear()
  if kind=="component_links":
   var root=g._install_assembly("leg","upper","fixture",2,2)
   var body=root.components.filter(func(e):return e.part=="body")[0]
   g._install_link(body.id,at(g,"below_knee").id,8,"fixture",1,[],["thigh","calf"],["above_knee","below_knee"])
  elif kind=="crotch":
   var crotch=g._install_special("crotch_rope_low","special_3_a")
   g._install_link(crotch.id,g.add_fixture("wrist",8).id,8,"fixture")
  else:
   at(g,"wrist",8)
   g.add_fixture("ankle",8)
  var reference=Arch.UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var previous=g._begin_equipment_read()
  var parity=true
  for slot in g.B.SLOTS:
   parity=parity and g.links_at(slot)==reference.links_at(slot) and ids(g.links_at(slot))==ids(reference.links_at(slot))
  parity=parity and g.link_anchors()==reference.link_anchors() and ids(g.link_anchors())==ids(reference.link_anchors())
  parity=parity and g.equipment_targets()==reference.equipment_targets() and ids(g.equipment_targets())==ids(reference.equipment_targets())
  parity=parity and g.action_targets()==reference.action_targets() and ids(g.action_targets())==ids(reference.action_targets())
  g._equipment_read=previous
  t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX link edge parity with the live path "+kind)
 var rope_fixture=Game.new(42)
 rope_fixture.state.equipment.clear();rope_fixture.state.composites.clear();rope_fixture.state.links.clear()
 var rope_root=rope_fixture._install_assembly("leg","upper","fixture",2,2)
 var band=at(rope_fixture,"below_knee",8)
 var end=rope_root.components.filter(func(e):return e.part=="body")[0]
 var rope=rope_fixture._install_link(end.id,band.id,8,"fixture",1,[],["thigh","calf"],["above_knee","below_knee"])
 var live=Arch.UncachedGame.new(42);live.state=rope_fixture.state.duplicate(true)
 rope.durability=0
 band.durability=0
 live.state=rope_fixture.state.duplicate(true)
 var before=rope_fixture.export_snapshot()
 var scope=rope_fixture._begin_equipment_read()
 var parity=rope_fixture.links_at("calf").is_empty() and rope_fixture.equipment_at("calf").is_empty()
 parity=parity and ids(rope_fixture.action_targets())==ids(live.action_targets()) and ids(rope_fixture.equipment_targets())==ids(live.equipment_targets())
 parity=parity and rope_fixture.action_targets().any(func(e):return e.id==rope.id) and rope_fixture.action_targets().any(func(e):return e.id==band.id)
 for slot in rope_fixture.B.SLOTS: parity=parity and ids(rope_fixture.links_at(slot))==ids(live.links_at(slot))
 rope_fixture._equipment_read=scope
 t.check(parity and rope_fixture.export_snapshot()==before,"INDEX dead rope leaves the link edge yet stays in the target lists")
 var anchor_fixture=Game.new(42)
 anchor_fixture.state.equipment.clear();anchor_fixture.state.composites.clear();anchor_fixture.state.links.clear();anchor_fixture.state.special_equipment.clear()
 var special=anchor_fixture._install_special("crotch_rope_low","special_3_a")
 var other=anchor_fixture._install_special("nipple_clamp_low","special_1_a")
 var anchor_live=Arch.UncachedGame.new(42);anchor_live.state=anchor_fixture.state.duplicate(true)
 var anchor_before=anchor_fixture.export_snapshot()
 var anchor_scope=anchor_fixture._begin_equipment_read()
 var anchor_parity=anchor_fixture.link_anchors().any(func(e):return e.id==special.id) and not anchor_fixture.link_anchors().any(func(e):return e.id==other.id)
 anchor_parity=anchor_parity and not anchor_fixture.equipment_targets().any(func(e):return e.id==special.id) and anchor_fixture.action_targets().any(func(e):return e.id==special.id)
 anchor_parity=anchor_parity and ids(anchor_fixture.link_anchors())==ids(anchor_live.link_anchors())
 anchor_fixture._equipment_read=anchor_scope
 t.check(anchor_parity and anchor_fixture.export_snapshot()==anchor_before,"INDEX crotch anchor reaches link_anchors and action_targets but not equipment_targets")


# Count work at the existing factory boundary without changing any rule result.
class OfferProbe extends Game:
 var preparations=0
 func _prepare_link(a: String, b: String, durability: float, source: String, grade: int=1, blocked_slip: Array=[], connection_slots: Array=[], connection_points: Array=[]) -> Dictionary:
  preparations+=1
  return super._prepare_link(a,b,durability,source,grade,blocked_slip,connection_slots,connection_points)

static func offer_enumeration(t) -> void:
 var g=OfferProbe.new(42)
 g.state.equipment.clear();g.state.composites.clear();g.state.links.clear();g.state.special_equipment.clear()
 for point in ["mid_forearm","wrist","below_knee","ankle"]:
  t.check(not at(g,point).is_empty(),"LINK offer fixture installs actual precise anchors")
 for slot in ["palm","fingers"]:
  t.check(not g._install_template("cord",slot,8,10,false,"fixture").is_empty(),"LINK offer fixture includes both sides of ordinary hand anchors")
 t.check(not g._install_assembly("leg","upper","fixture",2,2).is_empty(),"LINK offer fixture includes a real composite")
 t.check(not g._install_special("crotch_rope_low","special_3_a").is_empty(),"LINK offer fixture includes the special connector")
 for pass_index in range(2):
  var before=g.state.duplicate(true)
  g.preparations=0
  var offers=g.EquipmentOffers.links(g,2)
  var optimized_calls=g.preparations
  var expected=[]
  var exhaustive_calls=0
  # Exhaust every physical endpoint combination through the unchanged factory.
  # Preserve order as well as membership: selection indexes must retain RNG meaning.
  var anchors=g.link_anchors()
  for a in anchors:
   for b in anchors:
    if a.id>=b.id: continue
    for sa in g.Links.anchor_slots(a):
     for sb in g.Links.anchor_slots(b):
      for pa in g.Links.anchor_points(a,sa):
       for pb in g.Links.anchor_points(b,sb):
        exhaustive_calls+=1
        var link=g._prepare_link(a.id,b.id,12.8,"probe",2,[],[sa,sb],[pa,pb])
        if not link.is_empty(): expected.append([link.ends,link.slots,link.contact_points,link.name])
  t.check(not expected.is_empty() and offers.map(func(o):return [o.ends,o.slots,o.contact_points,o.name])==expected,"LINK optimized offers preserve exhaustive factory results and their random selection order")
  t.check(optimized_calls<exhaustive_calls,"LINK impossible geometry does not rebuild full physical links")
  t.check(g.state==before,"LINK offer enumeration preserves equipment, random counters and logs")
  if pass_index==0:
   var first=offers[0]
   t.check(not g._install_link(first.ends[0],first.ends[1],12.8,"fixture",2,[],first.slots,first.contact_points).is_empty(),"LINK second pass rechecks existing pairs and direction quotas after real installation")

static func at(g, point: String, durability: float=8, maximum: float=10, locked: bool=false, layer: int=-1, template: String="rope") -> Dictionary:
 return g._install_template(template,g.Links.point_slot(point),durability,maximum,locked,"fixture",1,layer,0,point)

static func precise_tool_fixture(g) -> Dictionary:
 g.state.equipment.clear();g.state.composites.clear();g.state.links.clear();g.state.items.clear()
 var root=g._install_assembly("leg","upper","fixture",2,2)
 var body=root.components.filter(func(e):return e.part=="body")[0]
 var calf=at(g,"below_knee")
 var link=g._install_link(body.id,calf.id,8,"fixture",1,[],["thigh","calf"],["above_knee","below_knee"])
 at(g,"thigh_root",4,10,false,root.layer+2)
 g._gain_tool("shard")
 return {"link":link.id,"tool":g.state.items[0].id,"layer":root.layer+2}

static func precise_tool_projection(t) -> void:
 var g=Game.new(42)
 var fixture=precise_tool_fixture(g)
 t.check(fixture.link!="" and g.validate()=="","CONTACT precise link fixture uses valid physical components")
 var before=g.export_snapshot()
 var c=t.find_action(g,"item_use",{"item":fixture.tool,"target":fixture.link})
 var item=g.get_view().items.filter(func(i):return i.id==fixture.tool)[0]
 t.check(c.valid and item.target_groups.any(func(group):return group.id=="thigh" and String(c.get("key","")) in group.keys),"CONTACT exposed knee link remains selectable despite unrelated covered thigh root")
 t.check(g.export_snapshot()==before,"CONTACT candidate and position projection preserve state, logs and random counters")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==before,"CONTACT stale projected link action rejects atomically")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._equipment(fixture.link).durability==3 and g._item(fixture.tool).uses==2 and g.state.energy==before.energy,"CONTACT projected link cut spends one use and only damages shared rope")
 at(g,"above_knee",4,10,false,fixture.layer)
 before=g.export_snapshot()
 c=t.find_action(g,"item_use",{"item":fixture.tool,"target":fixture.link})
 item=g.get_view().items.filter(func(i):return i.id==fixture.tool)[0]
 t.check(not c.valid and c.reason.contains("外层") and not item.target_groups.any(func(group):return String(c.get("key","")) in group.keys),"CONTACT covered precise knee cannot borrow another exposed point on the same component")
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"CONTACT covered link rejection preserves tool, equipment and resources")

static func run(t) -> void:
 index_link_edge_parity(t)
 offer_enumeration(t)
 precise_tool_projection(t)
 regional_cases(t)
 lower_only_cases(t)
 crotch_anchor_cases(t)
 var g=Game.new(42,true,"links")
 var link=g.state.links[0]
 var a=g._equipment(link.ends[0])
 var b=g._equipment(link.ends[1])
 t.check(g.validate()=="" and g.state.encounter==0 and g.state.rest_left==6,"LINK practice uses legal factory and rest flow")
 t.check(g.equipment_at("ankle").size()==1 and g.links_at("ankle").size()==1 and g.level("legs")==2,"LINK does not count as a second regional restraint")
 var before=JSON.stringify(g.state)
 g.get_view(); g.command_facts()
 t.check(JSON.stringify(g.state)==before,"LINK previews preserve ids, resources and randomness")
 var view=g.get_view()
 var ankle=view.bodies.filter(func(body):return body.id=="ankle")[0]
 var calf=view.bodies.filter(func(body):return body.id=="calf")[0]
 t.check(ankle.links[0].id==calf.links[0].id and ankle.count==1,"LINK both ends expose one shared target, capacity excludes it")
 ankle.links[0].durability=1
 t.check(g._equipment(link.id).durability==8,"LINK view is detached from authority")
 t.check(g._install_link(b.id,a.id,4,"fixture").is_empty() and JSON.stringify(g.state)==before,"LINK reversed duplicate rejected atomically")
 t.check(g._install_link(a.id,"absent",4,"fixture").is_empty(),"LINK missing target rejected")
 t.check(g._install_template("link_rope","ankle",4,10,false,"fixture").is_empty(),"LINK cannot enter ordinary generation")
 t.check(g.escape_preview(a,"slip",5).reason=="" and g.escape_preview(b,"slip",5).reason.contains("链接"),"LINK only explicitly declared exit is blocked")
 t.check(g.escape_preview(link,"slip",5).reason!="" and g.escape_preview(link,"magic_slip",5).reason!="","LINK no ordinary or magic slip")
 g._gain_card("magic_slip")
 for type in ["slip","magic_slip","ease","unlock"]:
  var card=t.grant_fixture_card(g,type)
  var c=t.find_action(g,"card",{"uid":card.uid,"target":link.id})
  before=JSON.stringify(g.state)
  t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and JSON.stringify(g.state)==before,"LINK forbidden card does not consume energy, magic or card "+type)
 var strain=t.hand_card(g,"strain")
 var c=t.find_action(g,"card",{"uid":strain.uid,"target":link.id,"slot":"ankle"})
 var damage=c.payload.preview.damage
 var version=g.state.version
 var a_before=a.durability
 var b_before=b.durability
 g.state.charge=1
 c=t.find_action(g,"card",{"uid":strain.uid,"target":link.id,"slot":"calf"})
 t.check(c.payload.preview.divisor==1 and c.payload.preview.lock_multiplier==1 and c.payload.preview.damage>damage,"LINK strain uses own tightness and charge without endpoint locks or stacks")
 damage=c.payload.preview.damage
 var splash=g.escape_preview(a,"strain",c.payload.preview.face_value*0.5,[],false,false,true,true).damage
 t.check(g.dispatch(g.command(c.payload,version),version).ok and is_equal_approx(g._equipment(link.id).durability,8-damage) and g.state.charge==0,"LINK one card damages shared rope once and spends charge")
 t.check(is_equal_approx(g._equipment(a.id).durability,a_before-splash) and g._equipment(b.id).durability==b_before,"LINK strain splashes only selected calf endpoint, preserving ankle endpoint")
 before=JSON.stringify(g.state)
 t.check(not g.dispatch(g.command(c.payload,version),version).ok and JSON.stringify(g.state)==before,"LINK stale drag cannot strike again")
 t.check(not t.find_action(g,"manual",{"target":link.id}).valid,"LINK standing cannot manually reach lower-leg connection")
 t.check(t.action(g,"posture",{"dest":"sit","wall":false}).ok,"LINK posture uses ordinary cost")
 t.check(t.action(g,"manual",{"target":link.id}).ok and g.state.links.is_empty(),"LINK sitting free hands can untie shared rope")
 t.check(g.escape_preview(g._equipment(b.id),"slip",5).reason=="" and g.state.equipment.size()==2,"LINK untying restores exit without removing endpoint equipment")

 g=Game.new(42,true,"links")
 link=g.state.links[0]; a=g._equipment(link.ends[0]); b=g._equipment(link.ends[1])
 t.action(g,"posture",{"dest":"sit","wall":false})
 var shard=g.state.items[0]
 before=JSON.stringify(g.state)
 var energy=g.state.energy
 t.check(t.action(g,"item_use",{"target":link.id,"item":shard.id}).ok and g._equipment(link.id).durability==3 and g.state.energy==energy,"LINK tool cuts fixed damage with zero energy")
 t.check(t.action(g,"item_use",{"target":link.id,"item":shard.id}).ok and g.state.links.is_empty() and g._item(shard.id).uses==1,"LINK second cut removes rope and decrements same tool uses")
 t.check(g.state.equipment.size()==2,"LINK cutting rope does not delete its anchors")

 g=Game.new(42,true,"links")
 link=g.state.links[0]; a=g._equipment(link.ends[0]); b=g._equipment(link.ends[1])
 t.action(g,"posture",{"dest":"sit","wall":false})
 t.action(g,"manual",{"target":a.id})
 t.check(g.state.links.is_empty() and not g._equipment(b.id).is_empty(),"LINK removing either required piece cascades rope only")
 g.add_fixture("calf",4,10,false,0,"rope")
 t.check(g.state.links.is_empty(),"LINK replacement equipment never rebinds old connection")
 var same=g._install_link(b.id,b.id,4,"fixture")
 var remote=g.add_fixture("upper_arm",4)
 t.check(same.is_empty() and g._install_link(b.id,remote.id,4,"fixture").is_empty(),"LINK rejects self and cross-region connection")

 # Contact can use either exposed end, independent of the anchor's material or lock.
 g=Game.new(42,true)
 g.state.equipment.clear()
 a=at(g,"above_knee",8,10,true,0,"belt")
 b=g.add_fixture("calf",8,10,false,0,"tape")
 link=g._install_link(a.id,b.id,8,"fixture")
 t.check(t.find_action(g,"manual",{"target":link.id}).valid,"LINK knot-free manual route does not require unlocking or untying anchor")
 g._install_template("rope","thigh",4,10,false,"fixture",1,2,0,a.points[0])
 t.check(not t.find_action(g,"manual",{"target":link.id}).valid,"LINK covered reachable end cannot substitute for unreachable exposed end")
 t.action(g,"posture",{"dest":"sit","wall":false})
 t.check(t.find_action(g,"manual",{"target":link.id}).valid,"LINK second exposed end allows contact after posture change")
 var low=g.escape_preview(link,"strain",5).damage
 link.durability=10
 t.check(g.escape_preview(link,"strain",5).damage<low,"LINK tighter rope reduces strain")
 t.action(g,"posture",{"dest":"lie","wall":false})
 t.check(not t.find_action(g,"hook",{"target":link.id}).valid,"LINK hook cannot bypass structural prohibition")
 link=g._equipment(link.id)
 link.locked=true
 t.check(g.validate()!="","LINK illegal lock rejected by validation")
 before=JSON.stringify(g.state)
 t.check(not t.action(g,"end").ok and JSON.stringify(g.state)==before,"LINK failed validation rolls back whole round")

 # Shared references and durability persist through reward, preparation and travel.
 g=Game.new(42)
 a=at(g,"mid_calf",8,10,false,0,"rope")
 b=g.add_fixture("ankle",8)
 g._install_link(a.id,b.id,8,"fixture")
 before=JSON.stringify(g.state.links)
 t.finish_room(g)
 t.check(g.state.phase=="map" and JSON.stringify(g.state.links)==before,"LINK battle and preparation preserve connection")
 t.action(g,"depart",{"room":"east"})
 while g.state.phase=="travel": t.action(g,"travel_step")
 t.check(JSON.stringify(g.state.links)==before and g.validate()=="","LINK room travel preserves exact targets")

static func lower_only_cases(t) -> void:
 var g=Game.new(42);g.state.equipment=[];g.state.links=[];g.state.composites=[]
 var a=at(g,"thigh_root");var b=at(g,"mid_thigh")
 var strain=g.escape_preview(a,"strain",5).damage
 var link=g._install_link(b.id,a.id,8,"fixture")
 for pose in ["stand","sit","lie"]:
  g.state.posture=pose
  t.check(g.Links.slip_factor(g,a)==1.25 and g.Links.slip_factor(g,b)==1.0,"LOWER LINK body order ignores posture and reversed stored endpoints "+pose)
 g.state.posture="stand"
 for mode in ["slip","magic_slip"]:
  var saved=g.state.links;g.state.links=[]
  var base=g.escape_preview(a,mode,5);g.state.links=saved
  var preview=g.escape_preview(a,mode,5)
  t.check(is_equal_approx(preview.damage,base.scaled_damage*1.25+base.environment_true) and preview.environment_true==base.environment_true and preview.link_factor==1.25 and g._formula(preview).contains("1.25仅向下链接"),"LOWER LINK exact active factor and formula "+mode)
 t.check(is_equal_approx(g.escape_preview(a,"strain",5).damage,strain),"LOWER LINK no strain bonus")
 var saved=g.state.links;g.state.links=[]
 var passive=g.escape_preview(a,"slip",1.2,[],true).damage;g.state.links=saved
 t.check(is_equal_approx(g.escape_preview(a,"slip",1.2,[],true).damage,passive*1.25),"LOWER LINK passive slip shares factor once")
 var second=at(g,"above_knee");g._install_link(a.id,second.id,8,"fixture")
 t.check(g.Links.slip_factor(g,a)==1.25,"LOWER LINK multiple downward links never multiply")
 var upper=g._install_special("crotch_rope_low","special_3_a");var up=g._install_link(upper.id,a.id,8,"fixture")
 t.check(g.Links.slip_factor(g,a)==1.0,"LOWER LINK any upward link removes bonus")
 up.durability=0;g._cleanup()
 t.check(g.Links.slip_factor(g,a)==1.25,"LOWER LINK removal immediately restores bonus")
 a.durability=a.maximum
 t.check(g.escape_preview(a,"slip",5).immune and g.escape_preview(a,"slip",5).scaled_damage==0,"LOWER LINK cannot bypass tier three immunity of scaled damage")
 a.durability=8
 var snapshot=g.export_snapshot();var restored=Game.new(9)
 t.check(restored.restore_snapshot(snapshot).ok and restored.Links.slip_factor(restored,restored._equipment(a.id))==1.25,"LOWER LINK restore derives same bonus without extra state")
 t.check(g.export_snapshot()==snapshot,"LOWER LINK previews preserve state")
 var card=t.hand_card(g,"slip");var candidate=t.find_action(g,"card",{"uid":card.uid,"target":a.id})
 var expected=candidate.payload.preview.damage;var durability=a.durability
 t.check(candidate.valid and g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok and (g._equipment(a.id).is_empty() if expected>=durability else is_equal_approx(g._equipment(a.id).durability,durability-expected)),"LOWER LINK formal card commits preview damage")
 var committed=g.export_snapshot()
 t.check(not g.dispatch(g.command(candidate.payload,candidate.version if candidate.has("version") else g.state.version-1),candidate.version if candidate.has("version") else g.state.version-1).ok and g.export_snapshot()==committed,"LOWER LINK stale card does not repeat damage")
 g.state.links=[]
 t.check(g.Links.slip_factor(g,a)==1.0,"LOWER LINK no link no bonus")

static func crotch_anchor_cases(t) -> void:
 for type in ["crotch_rope_low","crotch_rope_medium","crotch_rope_high"]:
  var g=Game.new(42);g.state.equipment=[];g.state.composites=[];g.state.links=[]
  var crotch=g._install_special(type,"special_3_a")
  var wrist=g.add_fixture("wrist",8);var thigh=g.add_fixture("thigh",8);var calf=g.add_fixture("calf",8)
  var lower=g._install_link(crotch.id,wrist.id,8,"fixture")
  var upper=g._install_link(thigh.id,crotch.id,8,"fixture")
  t.check(g._install_link(thigh.id,calf.id,8,"fixture").is_empty(),"CROTCH LINK thigh root cannot skip knee boundary")
  t.check(not lower.is_empty() and not upper.is_empty() and g.validate()=="","CROTCH LINK all grades use actual existing root "+type)
  if lower.is_empty() or upper.is_empty(): continue
  for pose in ["stand","sit","lie"]:
   g.state.posture=pose
   t.check(g.Links.slip_factor(g,wrist)==1.25 and g.Links.slip_factor(g,thigh)==1.0 and g.Links.slip_factor(g,crotch)==1.0,"CROTCH LINK lower for wrist, upper for thigh, no special-root bonus "+pose)
  var before=g.export_snapshot()
  var view=g.get_view()
  var special=view.body_groups.filter(func(b):return b.id=="special_3")[0]
  t.check(special.count==1 and special.links.size()==2 and special.targets.has(lower.id) and g.equipment_at("wrist").size()==1 and g.equipment_at("thigh").size()==1,"CROTCH LINK shared targets without phantom limb occupancy")
  t.check(g.export_snapshot()==before,"CROTCH LINK projection and facts preserve state")
  for pair in [[wrist.id,crotch.id],[calf.id,crotch.id],[crotch.id,crotch.id],[lower.id,crotch.id]]:
   t.check(g._install_link(pair[0],pair[1],8,"fixture").is_empty() and g.export_snapshot()==before,"CROTCH LINK duplicate, remote, self and rope anchors reject atomically")
  t.check(g._install_link(calf.id,crotch.id,8,"fixture",1,[],["thigh","special_3_a"]).is_empty() and g.export_snapshot()==before,"CROTCH LINK cannot forge contact on another region")
  var restored=Game.new(9)
  t.check(restored.restore_snapshot(before).ok and restored.Links.slip_factor(restored,restored._equipment(wrist.id))==1.25,"CROTCH LINK saves retain endpoint identities and direction")
  var invalid=g.export_snapshot();invalid.links[0].slots[0]="special_3_b"
  var saved=restored.export_snapshot()
  t.check(not restored.restore_snapshot(invalid).ok and restored.export_snapshot()==saved,"CROTCH LINK invalid saved contact rejects atomically")
  var middle=at(g,"mid_thigh")
  t.check(not g._install_link(thigh.id,middle.id,8,"fixture").is_empty(),"CROTCH LINK legal internal lower link remains independent")
  # Remove the real special root through a paid card. Links cascade, limb roots remain.
  g.state.posture="stand";crotch.durability=0.1
  var card=t.hand_card(g,"strain")
  var c=t.find_action(g,"card",{"uid":card.uid,"target":crotch.id})
  t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._equipment(crotch.id).is_empty() and g._equipment(lower.id).is_empty() and g._equipment(upper.id).is_empty(),"CROTCH LINK formal root removal cascades both ropes")
  t.check(not g._equipment(wrist.id).is_empty() and not g._equipment(thigh.id).is_empty() and g.Links.slip_factor(g,g._equipment(thigh.id))==1.25,"CROTCH LINK removal retains limbs and their unrelated lower link")
  g._install_special(type,"special_3_a")
  t.check(g.state.links.size()==1,"CROTCH LINK replacement never reconnects removed ropes")
 var g=Game.new(42);g.state.equipment=[];g.state.composites=[];g.state.links=[]
 var other=g._install_special("vaginal_egg_low","special_3_a")
 var thigh=g.add_fixture("thigh",8)
 t.check(not other.is_empty() and g._install_link(thigh.id,other.id,8,"fixture").is_empty(),"CROTCH LINK other special equipment is not an anchor")
 var crotch=g._install_special("crotch_rope_low","special_3_a")
 var link=g._install_link(thigh.id,crotch.id,8,"fixture")
 # Cover the thigh: free hands can still reach the rope's actual crotch end.
 g._install_template("rope","thigh",4,10,false,"fixture",1,2,0,thigh.points[0])
 t.check(t.find_action(g,"manual",{"target":link.id}).valid,"CROTCH LINK actual exposed crotch contact remains reachable")
 t.check(t.action(g,"manual",{"target":link.id}).ok and g.state.links.is_empty() and not g._equipment(crotch.id).is_empty(),"CROTCH LINK untying rope preserves special anchor")
 # Intake's real candidate enumeration can choose an already-worn crotch rope.
 var generated=false
 for seed_value in range(12):
  var prison=Game.new(seed_value,true,"guard")
  var anchor=prison._install_special("crotch_rope_low","special_3_a")
  prison.Guard.capture(prison,prison.state.enemies[0])
  t.check(prison.validate()=="","CROTCH LINK intake preserves valid special anchors")
  if prison.state.links.any(func(l):return anchor.id in l.ends): generated=true
 t.check(generated,"CROTCH LINK intake quota includes existing crotch ropes")


static func regional_cases(t) -> void:
 var g=Game.new(42);g.state.equipment=[];g.state.composites=[];g.state.links=[]
 var root=at(g,"thigh_root");var middle=at(g,"mid_thigh");var knee=at(g,"above_knee")
 var below=at(g,"below_knee");var ankle=g.add_fixture("ankle",8)
 var crotch=g._install_special("crotch_rope_low","special_3_a")
 var count=g.state.equipment.size();var level=g.level("legs")
 var rm=g._install_link(root.id,middle.id,8,"fixture")
 var rk=g._install_link(knee.id,root.id,8,"fixture")
 var mk=g._install_link(middle.id,knee.id,8,"fixture")
 var kb=g._install_link(knee.id,below.id,8,"fixture")
 var cr=g._install_link(crotch.id,root.id,8,"fixture")
 t.check([rm,rk,mk,kb,cr].all(func(l):return not l.is_empty()) and g.validate()=="","REGIONAL all thigh pairs, lower boundary and crotch exception coexist")
 t.check(g.state.equipment.size()==count and g.level("legs")==level and g.Equipment.capacity_points(rm).is_empty(),"REGIONAL links never consume restraint capacity or add limb restriction")
 t.check(g.Links.direction_limit("thigh_root",1)==2 and g.Links.direction_limit("above_knee",-1)==2 and g.Links.direction_limit("mid_thigh",1)==1 and g.Links.direction_limit("thigh_root",-1)==1,"REGIONAL directional counts use subpositions with minimum one")
 var extra=at(g,"mid_thigh")
 var before=g.export_snapshot()
 t.check(g._install_link(root.id,extra.id,8,"fixture").is_empty() and g.export_snapshot()==before,"REGIONAL third downward link exceeds physical root quota atomically")
 t.check(g._install_link(root.id,knee.id,8,"fixture").is_empty() and g._install_link(root.id,below.id,8,"fixture").is_empty() and g._install_link(below.id,ankle.id,8,"fixture").is_empty(),"REGIONAL duplicate pair, skipped boundary and skipped calf reject")
 t.check(g._prepare_link(root.id,knee.id,8,"fixture",1,[],["thigh","thigh"],["mid_thigh","above_knee"]).is_empty(),"REGIONAL cannot forge an anchor at a different subposition")
 var view=g.get_view();var text=g.Equipment.position_text(rk)
 t.check(text.contains("膝盖上方") and text.contains("大腿根") and not text.contains("大腿中部") and g.Equipment.display_points(rk)==rk.contact_points,"REGIONAL display lists only the two actual attachment positions")
 var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"regional triangle")
 var invalid=g.export_snapshot();var added=rm.duplicate(true)
 added.id="link_"+str(invalid.next_link);invalid.next_link+=1;added.ends=[root.id,extra.id];invalid.links.append(added)
 before=restored.export_snapshot()
 t.check(not restored.restore_snapshot(invalid).ok and restored.export_snapshot()==before,"REGIONAL restored over-quota graph rejected atomically")
 invalid=g.export_snapshot();invalid.links[0].contact_points=["thigh_root","below_knee"]
 t.check(not restored.restore_snapshot(invalid).ok,"REGIONAL saved forged or nonadjacent precise contact rejected")
 var old_id=rm.id
 t.check(t.action(g,"manual",{"target":old_id}).ok and g._equipment(old_id).is_empty(),"REGIONAL formal release removes one shared link")
 t.check(not g._install_link(root.id,extra.id,8,"fixture").is_empty(),"REGIONAL release immediately frees directional quota")
 # Distinct physical restraints may share a target position, within each end's quota.
 g=Game.new(42);g.state.equipment=[];g.state.links=[];g.state.composites=[]
 var assembly=g._install_assembly("leg","upper","fixture",2,2)
 var band=assembly.components.filter(func(e):return e.part=="thigh_root")[0]
 var own=assembly.components.filter(func(e):return e.part=="above_knee")[0]
 var one=at(g,"mid_thigh");var two=at(g,"mid_thigh");var third=at(g,"above_knee")
 t.check(not g._install_link(band.id,one.id,8,"fixture").is_empty() and not g._install_link(band.id,two.id,8,"fixture").is_empty(),"REGIONAL composite real band connects two distinct restraints even at one subposition")
 before=g.export_snapshot()
 t.check(g._install_link(band.id,third.id,8,"fixture").is_empty() and g._install_link(band.id,own.id,8,"fixture").is_empty() and g.export_snapshot()==before,"REGIONAL component shares quota and cannot invent same-root internal ropes")
 var missing=at(g,"mid_calf")
 var facts=g.EquipmentOffers.links(g,1)
 t.check(facts.all(func(o):return o.rank==1 and o.contact_points.size()==2 and g.Links.adjacent(o.contact_points[0],o.contact_points[1])) and g.export_snapshot()!=before,"REGIONAL enemy facts use precise adjacency at third priority")
