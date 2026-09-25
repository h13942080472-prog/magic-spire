extends RefCounted

const Game=preload("res://tests/game_fixture.gd")
# Living index-off reference for the B4 parity checks (single definition in the architecture suite).
const Arch=preload("res://tests/architecture_cases.gd")

static func part(g, key: String) -> Dictionary:
 return g.state.composites[0].components.filter(func(e):return e.part==key)[0]

static func cover_ids(values: Array) -> Array:
 return values.map(func(e):return e.id)

# docs/spec/equipment-query-seam.md「证据入口」: the materialized root edge resolves roots by id, keeps root order for the
# composite part of targets_at and never hands out a copy of a root or its components.
static func index_root_edge_parity(t) -> void:
 for kind in ["glove","jacket","leg_layers","component_links","plain"]:
  var g=Game.new(42,true,kind) if kind!="plain" else Game.new(42)
  if kind=="plain": g.add_fixture("thigh",7,10)
  var reference=Arch.UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var previous=g._begin_equipment_read()
  var parity=g._composite_roots().map(func(root):return root.id)==reference.state.composites.map(func(root):return root.id)
  for root in reference.state.composites:
   parity=parity and is_same(g._composite(root.id),g.state.composites.filter(func(e):return e.id==root.id)[0])
  parity=parity and g._composite("missing_root").is_empty()
  for slot in g.B.SLOTS:
   parity=parity and g.targets_at(slot)==reference.targets_at(slot) and cover_ids(g.targets_at(slot))==cover_ids(reference.targets_at(slot))
  g._equipment_read=previous
  t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX root edge parity with the live path "+kind)
 # A disabled root stays addressable by id while its components leave the target lists.
 var leg=Game.new(42,true,"leg_layers")
 var outer=leg.state.composites[-1]
 var body=leg._composite(outer.id).components.filter(func(e):return e.part=="body")[0]
 body.durability=0
 var live=Arch.UncachedGame.new(42);live.state=leg.state.duplicate(true)
 var leg_before=leg.export_snapshot()
 var scope=leg._begin_equipment_read()
 var parity=is_same(leg._composite(outer.id),leg.state.composites[-1]) and not leg.Composites.active(leg._composite(outer.id))
 parity=parity and leg._composite(outer.id).components.size()==outer.components.size()
 for slot in leg.B.SLOTS: parity=parity and cover_ids(leg.targets_at(slot))==cover_ids(live.targets_at(slot))
 parity=parity and leg.get_view()==live.get_view()
 leg._equipment_read=scope
 t.check(parity and leg.export_snapshot()==leg_before,"INDEX disabled root keeps its components addressable and leaves the target lists")

static func play(t, g, type: String, target: String, slot: String="upper_arm") -> Dictionary:
 if not g._equipment(target).is_empty() and g.Equipment.is_shoulder(g._equipment(target)): slot="shoulder"
 var card=t.grant_fixture_card(g,type)
 return t.action(g,"card",{"uid":card.uid,"target":target,"slot":slot})

static func run(t) -> void:
 index_root_edge_parity(t)
 for variant in ["short","long"]:
  for straps in ["straight","cross"]:
   var g=Game.new(42)
   var root=g._install_assembly("glove",variant,"fixture",2,2,{},straps)
   t.check(not root.is_empty() and g.validate()=="","COMPOSITE complete factory "+variant+straps)
   t.check(g.level("arms")== (3 if variant=="short" else 4) and g.occupied("fingers")== (variant=="long"),"COMPOSITE exact coverage determines abilities")
   t.check(g.physical_pieces().size()== 3 and g.equipment_at("upper_arm").size()==1,"COMPOSITE root and shoulders do not duplicate body occupancy")
   var before=JSON.stringify(g.state)
   var view=g.get_view()
   var arm=view.bodies.filter(func(b):return b.id=="upper_arm")[0]
   var wrist=view.bodies.filter(func(b):return b.id=="wrist")[0]
   t.check(arm.groups.size()==1 and arm.groups[0].components.size()==1 and wrist.targets.keys()==arm.targets.keys(),"COMPOSITE every covered body opens the same component group")
   arm.targets.values()[0].durability=999
   t.check(JSON.stringify(g.state)==before,"COMPOSITE projected nested groups are read-only snapshots")
   t.check(g._install_assembly("glove",variant,"fixture",2,2,{},straps).is_empty() and JSON.stringify(g.state)==before,"COMPOSITE duplicate installation leaves all ids and state unchanged")
   var body=part(g,"body")
   t.check(g.escape_preview(body,"strain",5).divisor==1,"COMPOSITE multi-slot body counted once for damage")
   t.check(g.escape_preview(body,"slip",5).reason.contains("肩带") and g.escape_preview(body,"magic_slip",5).reason.contains("肩带"),"COMPOSITE structural slip prerequisite covers ordinary and magic damage")
   var unlock=t.grant_fixture_card(g,"unlock")
   var c=t.find_action(g,"card",{"uid":unlock.uid,"target":part(g,"left").id})
   t.check((c.reason.contains("手掌和手指"))==(variant=="long"),"COMPOSITE long closes gestures, short does not")
   var fire=t.find_action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})
   t.check(fire.valid and fire.payload.damage==(g.B.FIREBALL if variant=="long" else g.B.FIREBALL_ASSISTED),"COMPOSITE actual fireball loses only blocked gesture bonus")
   t.check(not t.find_action(g,"attack",{"type":"strike"}).valid and not t.find_action(g,"manual",{"target":body.id}).valid,"COMPOSITE body attack and one-click body removal disabled")

 # One straight shoulder is sufficient; eligibility is captured before the action.
 var g=Game.new(42,true,"glove_short")
 var body=part(g,"body")
 var left=part(g,"left")
 var right=part(g,"right")
 left.durability=1.0
 t.check(play(t,g,"slip",left.id).ok and g.state.composites.size()==1 and part(g,"body").durability==12.8,"COMPOSITE first shoulder slip cannot also remove body")
 body=part(g,"body")
 t.check(g.escape_preview(body,"slip",5).reason=="" and part(g,"right").locked,"COMPOSITE one open straight strap enables slip even with other strap locked")
 t.check(g.escape_preview(body,"strain",5).release,"COMPOSITE next strain previews complete release")
 var card=t.hand_card(g,"strain")
 var c=t.find_action(g,"card",{"uid":card.uid,"target":body.id,"slot":"wrist"})
 var old_version=g.state.version
 var energy=g.state.energy
 g.state.charge=1
 t.check(g.dispatch(g.command(c.payload,old_version),old_version).ok==false,"COMPOSITE changed charge invalidates old damage candidate even without version fixture update")
 t.check(play(t,g,"strain",body.id,"wrist").ok and g.state.composites.is_empty() and g.state.energy==energy-1 and g.state.charge==0,"COMPOSITE body hit from wrist removes full root, consumes one card, energy and charge")
 var before=JSON.stringify(g.state)
 t.check(not g.dispatch(g.command(c.payload,old_version),old_version).ok and JSON.stringify(g.state)==before,"COMPOSITE stale removed component cannot be reused")
 t.check(g.level("arms")==0 and g.item_capacity()==3,"COMPOSITE release restores ability and capacity in same commit")

 # Locks remain local; shoulder tier is independent of the body.
 g=Game.new(42,true,"glove_short")
 body=part(g,"body"); left=part(g,"left"); right=part(g,"right")
 body.durability=6.4; left.durability=16; right.durability=16;g._cleanup()
 t.check(g._effective_ratio(left)==1.0 and g.escape_preview(left,"strain",5).reason!="","COMPOSITE independent shoulder tier and no strain")
 t.check(g._slip_reason(left)!="","COMPOSITE crossed shoulder cannot borrow low body tier")
 t.check(play(t,g,"unlock",right.id).ok and not part(g,"right").locked and part(g,"body").durability==6.4,"COMPOSITE gesture unlock targets exactly one shoulder")

 # Third tier blocks automatic removal until a later action, not mid-hit.
 g=Game.new(42,true)
 g.state.equipment.clear()
 g._install_assembly("glove","short","fixture",2,3,{"left":{"tier":1},"right":{"tier":3}},"cross")
 var cross=part(g,"left")
 var hook_pose=g.state.posture
 g.state.posture="sit"
 t.check(t.action(g,"hook",{"target":cross.id}).ok and g.state.composites.size()==1,"COMPOSITE hook removes noncrossed left path only")
 g.state.posture=hook_pose
 body=part(g,"body")
 t.check(not g.escape_preview(body,"strain",5).release and g.escape_preview(body,"slip",5).immune,"COMPOSITE open strap does not override third-tier body")
 t.check(play(t,g,"strain",body.id).ok and g.state.composites.size()==1,"COMPOSITE a hit crossing third-tier boundary does not retroactively release")
 t.check(g.tier(part(g,"body").durability,16)==3,"COMPOSITE first weak hit remains above eighty percent")
 t.action(g,"end")
 body=part(g,"body")
 t.check(play(t,g,"ease",body.id).ok and g.state.composites.size()==1 and g.tier(part(g,"body").durability,16)<3,"COMPOSITE magic downgrade is not a strain event")
 t.check(play(t,g,"strain",body.id).ok and g.state.composites.is_empty(),"COMPOSITE later strain after actual downgrade releases")

 # Real outer coverage and capacities, not display count or component names.
 g=Game.new(42,true)
 g.state.equipment.clear()
 var inner=g.add_fixture("palm",4,10,false,0,"tape")
 var root=g._install_assembly("glove","long","fixture",2,2,{},"straight")
 t.check(root.layer>inner.layer and g.escape_preview(inner,"slip",5).reason!="","COMPOSITE existing hand item remains a covered inner piece")
 t.check(g._outer(part(g,"body")) and g._slip_reason(part(g,"body")).contains("肩带") and g._slip_reason(inner).contains(part(g,"body").name),"COMPOSITE exposed body has a shoulder restriction while inner hand tape identifies the covering body")
 before=JSON.stringify(g.state)
 t.check(g._install_template("cord","fingers",4,10,false,"fixture").is_empty() and JSON.stringify(g.state)==before,"COMPOSITE long closed hand rejects ordinary later addition")
 var outer=g._install_template("belt","wrist",4,10,false,"fixture")
 t.check(outer.layer>root.layer,"COMPOSITE later ordinary piece enters actual outer layer")
 t.check(not g._outer(part(g,"body")) and g._slip_reason(part(g,"body")).contains("肩带"),"COMPOSITE body with two blockers still names the shoulder prerequisite")
 var before_layer_check=g.export_snapshot()
 t.check(g._installation_reason("rope","forearm",1,false,"",root.layer)!="","COMPOSITE installation query rejects the same inner layer as the factory")
 t.check(g.export_snapshot()==before_layer_check,"COMPOSITE layer eligibility query preserves state, ids and random domains")
 t.check(g.add_fixture("forearm",4,10,false,root.layer).is_empty(),"COMPOSITE explicit same/inner layer cannot bypass order")
 hook_pose=g.state.posture
 g.state.posture="sit"
 for i in range(2): t.check(t.action(g,"hook",{"target":part(g,"left").id}).ok,"COMPOSITE formally loosens and then removes the covering fixture's left shoulder")
 g.state.posture=hook_pose
 body=part(g,"body")
 t.check(not g.escape_preview(body,"strain",5).release and g.escape_preview(body,"slip",5).reason!="","COMPOSITE a single exterior wrist band blocks full-body release")
 t.check(g._slip_reason(body).contains(outer.name) and g._slip_reason(body).contains("手腕"),"COMPOSITE after opening shoulder the reason identifies the actual covering wrist band")
 var strain_preview=g.escape_preview(body,"strain",5)
 t.check(is_equal_approx(strain_preview.divisor,1.25),"COMPOSITE union counts body, inner hand and outer wrist once each")
 # Tool can contact an exposed section of the shared body, even if another section is covered.
 g.state.items[0].mount="hand_wall"
 body.durability=1
 t.check(g.InstalledTools.reason(g,g.state.items[0],body)=="","COMPOSITE cutter contacts exposed body section despite separate wrist cover")
 g._apply_equipment_damage(body,5,"cut");g._cleanup()
 t.check(g.state.composites.is_empty() and not g._equipment(inner.id).is_empty() and not g._equipment(outer.id).is_empty(),"COMPOSITE body destruction cascades attached straps but preserves independent layers")
 t.check(g.validate()=="","COMPOSITE remaining physical layers validate after cascade")

 g=Game.new(42,true)
 g.state.equipment.clear()
 g.add_fixture("palm",4); g.add_fixture("palm",4)
 before=JSON.stringify(g.state)
 t.check(g._install_assembly("glove","long","fixture",2,2,{},"cross").is_empty() and JSON.stringify(g.state)==before,"COMPOSITE capacity rejects entire assembly without partial components")
 t.check(g._install_assembly("glove","short","fixture",1,2,{},"straight").is_empty() and g._install_assembly("glove","short","fixture",2,2,{},"missing").is_empty(),"COMPOSITE unsupported grade and structure rejected")
 t.check(g._install_assembly("glove","short","fixture",2,2,{"left":{"tier":9}},"straight").is_empty() and JSON.stringify(g.state)==before,"COMPOSITE invalid component leaves id counters untouched")

 # Cutting/slipping a shoulder does not trigger the special strain-only exit.
 g=Game.new(42,true,"glove_short")
 hook_pose=g.state.posture
 g.state.posture="sit"
 t.action(g,"hook",{"target":part(g,"left").id})
 g.state.posture=hook_pose
 body=part(g,"body")
 g.state.items[0].mount="hand_wall"
 g._apply_equipment_damage(body,5,"cut");g._cleanup()
 t.check(g.state.composites.size()==1 and is_equal_approx(part(g,"body").durability,7.8),"COMPOSITE shared cut damage does not trigger strain-only removal")
 # Test slipping alone: the mounted cutter can now make the stronger base card lethal.
 g.state.items[0].mount="carry"
 t.check(play(t,g,"slip",body.id).ok and g.state.composites.size()==1,"COMPOSITE ordinary slipping cannot trigger strain-only shortcut")

 # Long gloves block handheld tools, but preserve toe installation and mounted use.
 g=Game.new(42,true,"glove_long")
 body=part(g,"body")
 var item=g.state.items[0]
 var cut=t.find_action(g,"item_use",{"item":item.id,"target":body.id})
 before=JSON.stringify(g.state)
 t.check(not cut.valid and not g.dispatch(g.command(cut.payload,g.state.version),g.state.version).ok and JSON.stringify(g.state)==before,"COMPOSITE closed fingers block handheld cut without cost")
 t.check(t.action(g,"item_install",{"item":item.id,"mount":"foot_wall"}).ok,"COMPOSITE toe installation works with both hands covered")
 t.action(g,"posture",{"dest":"sit","wall":false}); t.action(g,"posture",{"dest":"lie","wall":false})
 t.check(g.InstalledTools.reason(g,g._item(item.id),body)=="" and part(g,"body").durability==24,"COMPOSITE lying reaches cutter but posture alone causes no damage")
 t.check(g.item_capacity()==2,"COMPOSITE finger and arm penalties do not stack twice")



 # Enemy targeting, persistence, and failed transaction rollback use the same physical targets.
 g=Game.new(42)
 root=g._install_assembly("glove","short","fixture",2,2,{},"straight")
 before=JSON.stringify(g.state.composites)
 g._finish_battle(); t.action(g,"reward",{"type":"skip"}); t.action(g,"finish_prepare")
 t.check(JSON.stringify(g.state.composites)==before,"COMPOSITE battle and preparation preserve components before movement")
 var expected=g.state.composites.duplicate(true)
 t.action(g,"depart",{"room":"east"})
 while g.state.phase=="travel": t.action(g,"travel_step")
 for log in g.state.logs:
  for hit in log.data.get("passive_slip",{}).get("results",[]):
   for expected_root in expected:
    for component in expected_root.components:
     if component.id==hit.target: component.durability=hit.after
 t.check(JSON.stringify(g.state.composites)==JSON.stringify(expected),"COMPOSITE travel changes only logged passive durability and preserves component references")
 g.state.room_encounters[g.state.room]="guard_solo";g._start_battle()
 var guard=g.state.enemies[0]
 var legal=g.EnemyPlans.targets(g,guard,"lock").filter(func(e):return e.has("root_id"))
 t.check(not legal.is_empty(),"COMPOSITE enemy lock selects actual component without fake root durability")
 var plan={"kind":"lock","target":legal[0].id,"text":"上锁","delayed":false}
 guard.intent={"kind":"guard_sequence","priority":false,"delayed":false,"text":"上锁","operations":[plan]}
 t.check(t.action(g,"end").ok and g._equipment(plan.target).locked,"COMPOSITE guard locks selected component through ordinary commit")
 part(g,"left").coverage=["fingers"]
 before=JSON.stringify(g.state)
 t.check(g.validate()!="" and not t.action(g,"end").ok and JSON.stringify(g.state)==before,"COMPOSITE invalid coverage causes full transactional rollback")
