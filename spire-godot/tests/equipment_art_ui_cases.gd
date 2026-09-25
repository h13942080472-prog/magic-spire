extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Portrait=preload("res://ui/equipment_portrait.gd")
const Queries=preload("res://ui/target_queries.gd")

static func region_fixture(g,region: String,level: int) -> void:
 var slots=g.B.ARM_SLOTS if region=="arms" else g.B.LEG_SLOTS
 var indices=[[],[0],[2],[2,3],[0,1,2,3,4]][level]
 for index in indices: g.add_fixture(slots[index],4,10,false,0,"rope")

static func visible_region_equal(left: Image,right: Image,rect: Rect2i) -> bool:
 for y in range(rect.position.y,rect.end.y):
  for x in range(rect.position.x,rect.end.x):
   var a=left.get_pixel(x,y);var b=right.get_pixel(x,y)
   if not is_equal_approx(a.a,b.a):return false
   if a.a>0.001 and not a.is_equal_approx(b):return false
 return true

static func run(t) -> void:
 var ui=t.ui
 # All combinations distinguish occupied locations, even when they have the same level.
 var slots=["thigh","calf","ankle","foot"]
 var layers=[["thigh_root"],["below_knee"],["ankle"],["foot"]]
 for mask in range(16):
  ui.game=Game.new(42)
  var expected: Array=[]
  for bit in range(4):
   if mask & (1<<bit):
    ui.game.add_fixture(slots[bit],4,10,false,0,"rope");expected.append_array(layers[bit])
  var before=ui.game.export_snapshot()
  ui.render();await t.frames()
  var portrait=ui.find_child("EquipmentPortrait",true,false)
  t.check(portrait.texture==(Portrait.FREE if mask==0 else Portrait.BOUND_BASE),"PORTRAIT shared base depends on actual limb occupancy")
  for key in Portrait.leg_layers:
   t.check(portrait.get_node("Overlay_"+key).visible==(mask!=0) and portrait.get_node("Overlay_"+key).texture==(Portrait.leg_layers[key].texture if key in expected else Portrait.leg_layers[key].free_texture),"PORTRAIT actual occupied locations select independent layer %d/%s" % [mask,key])
  t.check(ui.game.export_snapshot()==before,"PORTRAIT layers do not change state or random cursor")
  if mask in [1,2,4,8,15]: await t.capture("ui-94-equipment-parts-%d.png" % mask)
 ui.game=Game.new(42);ui.game.add_fixture("toes",4)
 ui.render();await t.frames()
 t.check(ui.find_child("EquipmentPortrait",true,false).active_leg_layers.is_empty(),"PORTRAIT toes alone never create a foot or ankle rope")
 # Face slots are independent of body level and of one another.
 ui.game=Game.new(42)
 var eye=ui.game.add_fixture("eyes",4)
 ui.render();await t.frames()
 var eyes_only=ui.find_child("EquipmentPortrait",true,false)
 t.check(eyes_only.get_node("Overlay_eyes").visible and not eyes_only.get_node("Overlay_mouth").visible,"PORTRAIT eye-only equipment never imports the mouth shown in source image seven")
 await t.capture("ui-91-equipment-eyes-only.png")
 var mouth=ui.game.add_fixture("mouth",4)
 ui.render();await t.frames()
 var p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.variant==-1 and p.get_node("Overlay_mouth").visible and p.get_node("Overlay_eyes").visible,"PORTRAIT both face overlays work on the free-body base")
 await t.capture("ui-89-equipment-free-face.png")
 await t.inspect_body("eyes")
 t.check(await t.click("manual",{"target":eye.id}),"PORTRAIT remove eye equipment through actual action")
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check(not p.get_node("Overlay_eyes").visible and p.get_node("Overlay_mouth").visible,"PORTRAIT removing eyes preserves independent mouth layer")
 await t.inspect_body("mouth")
 t.check(await t.click("manual",{"target":mouth.id}),"PORTRAIT remove mouth equipment through actual action")
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check(not p.get_node("Overlay_eyes").visible and not p.get_node("Overlay_mouth").visible and p.texture==Portrait.FREE,"PORTRAIT clearing face slots restores base without stale patches")
 ui.game=Game.new(42)
 region_fixture(ui.game,"arms",1);region_fixture(ui.game,"legs",4)
 ui.game.add_fixture("eyes",4);ui.game.add_fixture("mouth",4)
 ui.render();await t.frames()
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.variant==0 and p.active_leg_layers.size()==4 and p.equipped_eyes and p.equipped_mouth,"PORTRAIT body variant composes with both actual face slots")
 await t.capture("ui-90-equipment-bound-face.png")
 var thigh=ui.game.equipment_at("thigh")[0]
 await t.inspect_body("thigh")
 t.check(await t.click("manual",{"target":thigh.id}),"PORTRAIT actual release changes leg restriction level")
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check(ui.view.legs==3 and not "thigh_root" in p.active_leg_layers and not "mid_thigh" in p.active_leg_layers and not "above_knee" in p.active_leg_layers and "ankle" in p.active_leg_layers and p.equipped_eyes and p.equipped_mouth,"PORTRAIT body reduction refreshes variant without clearing face equipment")

 # Active short and long single-glove assemblies share the supplied local arm replacement.
 for practice in ["glove_short","glove_long"]:
  ui.game=Game.new(42,true,practice)
  var before=ui.game.export_snapshot()
  ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
  t.check(p.texture==Portrait.BOUND_SINGLE_GLOVE and p.active_composite_layers==["single_glove"],"PORTRAIT %s selects the supplied single-glove replacement from the real composite" % practice)
  t.check(p.get_node("Overlay_thigh_root").texture==Portrait.SINGLE_GLOVE_THIGH.free,"PORTRAIT single glove keeps the matching free thigh-root slice")
  t.check(ui.game.export_snapshot()==before,"PORTRAIT single-glove display does not change state or random cursor")
 await t.capture("ui-equipment-single-glove.png")

 # Supplied single-leg differences cover the ordinary horizontal leg slices.
 var leg_practices={"leg_upper":"single_leg_upper","leg_lower":"single_leg_lower","leg_ankle":"single_leg_long","leg_toes":"single_leg_long"}
 var covered_slices={"leg_upper":["thigh_root","mid_thigh","above_knee"],"leg_lower":["below_knee","mid_calf","ankle"],"leg_ankle":["thigh_root","mid_thigh","above_knee","below_knee","mid_calf","ankle"],"leg_toes":["thigh_root","mid_thigh","above_knee","below_knee","mid_calf","ankle"]}
 for practice in leg_practices:
  ui.game=Game.new(42,true,practice)
  var before=ui.game.export_snapshot()
  ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
  var expected=leg_practices[practice]
  t.check(p.active_composite_layers==[expected] and p.get_node("Overlay_"+expected).visible,"PORTRAIT %s selects its supplied single-leg difference" % practice)
  t.check(p.texture==Portrait.single_leg_bases[expected][p._single_leg_base_context(false,false)],"PORTRAIT %s replaces old leg pixels in the body base" % practice)
  for key in Portrait.single_leg_layers:
   t.check(p.get_node("Overlay_"+key).visible==(key==expected),"PORTRAIT %s does not show another single-leg variant" % practice)
  for slice_id in covered_slices[practice]:
   var context=p._single_leg_slice_context(slice_id,slice_id in p.active_leg_layers)
   t.check(p.get_node("Overlay_"+slice_id).texture==Portrait.single_leg_layers[expected].slices[slice_id][context],"PORTRAIT %s replaces covered slice %s instead of leaving an old silhouette" % [practice,slice_id])
  t.check(p.get_node("Overlay_"+expected).get_index()>p.get_node("Overlay_foot").get_index(),"PORTRAIT single-leg difference stays above every ordinary leg slice: "+practice)
  t.check(ui.game.export_snapshot()==before,"PORTRAIT single-leg display does not change state or random cursor: "+practice)
 await t.capture("ui-equipment-single-leg-long.png")

 ui.game=Game.new(42,true,"component_links")
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.active_composite_layers==["single_leg_upper","single_leg_lower"] and p.get_node("Overlay_single_leg_upper").visible and p.get_node("Overlay_single_leg_lower").visible,"PORTRAIT two short single-leg sleeves compose the supplied thigh-and-calf appearance")
 t.check(p.texture==Portrait.single_leg_bases.single_leg_upper_lower[p._single_leg_base_context(false,false)],"PORTRAIT paired short sleeves share a body base with both old silhouettes cleared")
 await t.capture("ui-equipment-single-leg-short-pair.png")

 ui.game=Game.new(42,true,"leg_layers")
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.active_composite_layers==["single_leg_upper","single_leg_lower","single_leg_long"],"PORTRAIT stacked short and long sleeves retain all real active composite layers")
 t.check(not p.get_node("Overlay_single_leg_upper").visible and not p.get_node("Overlay_single_leg_lower").visible and p.get_node("Overlay_single_leg_long").visible,"PORTRAIT long sleeve suppresses transparent-edge penetration from stacked short sleeves")
 t.check(p.texture==Portrait.single_leg_bases.single_leg_long[p._single_leg_base_context(false,false)],"PORTRAIT long sleeve clears old pixels from its complete body region")
 for slice_id in ["thigh_root","mid_thigh","above_knee","below_knee","mid_calf","ankle"]:
  var context=p._single_leg_slice_context(slice_id,slice_id in p.active_leg_layers)
  t.check(p.get_node("Overlay_"+slice_id).texture==Portrait.single_leg_layers["single_leg_long"].slices[slice_id][context],"PORTRAIT long sleeve replaces stacked short-sleeve slice "+slice_id)

 ui.game=Game.new(42,true,"glove_long")
 ui.game._install_special("negative_plate_lock_medium","special_2_a",2)
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.texture==Portrait.BOUND_SINGLE_GLOVE_FLAT_LOCK and p.get_node("Overlay_thigh_root").texture==Portrait.SINGLE_GLOVE_THIGH.flat_lock_free,"PORTRAIT single glove and flat lock select their combined replacement without restoring old arm pixels")
 await t.capture("ui-equipment-single-glove-flat-lock.png")

 # Special-equipment differences are read-only layers on the bound standing art.
 ui.game=Game.new(42);ui.game.add_fixture("wrist",4,10,false,0,"rope")
 ui.game._install_special("negative_plate_lock_medium","special_2_a",2)
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.texture==Portrait.BOUND_FLAT_LOCK and p.active_special_layers==["flat_lock"],"PORTRAIT a worn flat lock selects the local replacement on the bound standing art")
 t.check(not p.get_node("Overlay_flat_lock_reinforcement").visible and not p.get_node("Overlay_urethral_rod").visible,"PORTRAIT plain flat lock does not invent reinforcement or a urethral rod")
 await t.capture("ui-equipment-flat-lock.png")

 ui.game=Game.new(42);ui.game.add_fixture("wrist",4,10,false,0,"rope")
 ui.game._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.active_special_layers==["flat_lock","flat_lock_reinforcement","urethral_rod"] and p.get_node("Overlay_flat_lock_reinforcement").visible and p.get_node("Overlay_urethral_rod").visible,"PORTRAIT reinforced catheter flat lock composes all three verified differences")
 await t.capture("ui-equipment-flat-lock-reinforced-rod.png")

 ui.game=Game.new(42);ui.game.add_fixture("wrist",4,10,false,0,"rope")
 ui.game._install_special("urethral_rod_low","special_2_d")
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.texture==Portrait.BOUND_BASE and p.active_special_layers.is_empty() and not p.get_node("Overlay_urethral_rod").visible,"PORTRAIT a standalone urethral rod has no flat-lock-specific difference")

 ui.game=Game.new(42);ui.game.add_fixture("wrist",4,10,false,0,"rope")
 ui.game._install_special("negative_plate_lock_medium","special_2_a",2)
 ui.game._install_special("urethral_rod_low","special_2_d")
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.texture==Portrait.BOUND_FLAT_LOCK and p.active_special_layers==["flat_lock","urethral_rod"] and p.get_node("Overlay_urethral_rod").visible,"PORTRAIT a separate urethral rod uses its difference only together with a worn flat lock")

 ui.game=Game.new(42)
 ui.game._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(not ui.view.has_restraint_level and p.texture==Portrait.FREE and p.get_children().all(func(node):return not node.visible),"PORTRAIT special differences stay hidden when the standing portrait is not the bound variant")

 # A remaining physical band at the knee must not invent whole-thigh rope groups.
 ui.game=Game.new(42,true,"leg_upper")
 var root=ui.game.state.composites[0]
 var body=root.components.filter(func(e):return e.part=="body")[0]
 body.durability=1
 var item=ui.game.state.items[0].id
 ui.render();await t.frames()
 ui.show_items=true;ui.selected_item=item;ui.render();await t.frames()
 t.check(await t.click("item_use",{"item":item,"target":body.id}),"PORTRAIT real cutting removes leg sleeve while retaining outer bands")
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.active_composite_layers.is_empty() and not p.get_node("Overlay_single_leg_upper").visible,"PORTRAIT real sleeve removal clears its supplied difference")
 t.check("thigh_root" in p.active_leg_layers and "above_knee" in p.active_leg_layers and not "mid_thigh" in p.active_leg_layers,"PORTRAIT real independent thigh bands exclude middle layer")
 await t.close_information();await t.inspect_body("thigh")
 var band=root.components.filter(func(e):return e.part=="thigh_root")[0]
 t.check(await t.click("manual",{"target":band.id}),"PORTRAIT actual root-band removal")
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.active_leg_layers==["above_knee"],"PORTRAIT remaining knee band renders only its physical anchor")
 await t.capture("ui-95-equipment-knee-band.png")
 await crotch_rope(t)
 await material_art(t)

static func material_art(t) -> void:
 var ui=t.ui
 # All counts use live physical pieces; outer leather overrides a rope majority.
 for row in [[1,2,1,0,"leather"],[1,2,0,1,"rope"],[2,1,0,1,"leather"],[1,1,0,1,"rope"],[0,0,0,0,"rope"]]:
  ui.game=Game.new(42)
  for i in range(row[0]):ui.game.add_fixture("ankle",4,10,false,row[2],"belt")
  for i in range(row[1]):ui.game.add_fixture("ankle",4,10,false,row[3],"rope")
  var before=ui.game.export_snapshot()
  ui.render();await t.frames()
  var expected=row[4]
  t.check(ui.game.state.equipment.size()==row[0]+row[1],"MATERIAL art fixture installs every counted piece")
  t.check(ui.view.body_coverage.materials.ankle==expected,"MATERIAL outer precedence, majority, tie and empty fallback %s" % str(row))
  t.check(ui.game.export_snapshot()==before,"MATERIAL display never changes equipment or RNG")
 # Different positions remain independent; upper body sums across its locations.
 ui.game=Game.new(42)
 ui.game.add_fixture("upper_arm",4,10,false,0,"rope")
 ui.game.add_fixture("forearm",4,10,false,0,"rope")
 ui.game.add_fixture("wrist",4,10,false,0,"belt")
 ui.game.add_fixture("wrist",4,10,false,1,"rope")
 ui.game.add_fixture("thigh",4,10,false,0,"belt")
 ui.game.add_fixture("ankle",4,10,false,0,"rope")
 ui.render();await t.frames()
 var sidebar=ui.find_child("EquipmentPortrait",true,false)
 t.check(ui.view.body_coverage.materials.upper=="rope" and sidebar.texture==Portrait.BOUND_BASE,"MATERIAL upper body aggregates arms and wrist instead of following one location")
 t.check(sidebar.get_node("Overlay_thigh_root").texture==Portrait.leg_layers.thigh_root.styles.plain.leather and sidebar.get_node("Overlay_ankle").texture==Portrait.leg_layers.ankle.texture,"MATERIAL leather and rope regions compose independently")
 # Mixed lower-leg materials share canonical pixels at both slice edges, so
 # switching between rope and leather cannot expose a horizontal color seam.
 for slice_id in ["mid_thigh","above_knee","below_knee","mid_calf","ankle","foot"]:
  var styles=Portrait.leg_layers[slice_id].styles.plain
  var free_image: Image=styles.free.get_image()
  var width=free_image.get_width();var height=free_image.get_height()
  var top=Rect2i(0,0,width,5);var bottom=Rect2i(0,height-5,width,5)
  for material in ["rope","leather"]:
   var material_image: Image=styles[material].get_image()
   var edges_match=visible_region_equal(material_image,free_image,top)
   if slice_id!="foot":edges_match=edges_match and visible_region_equal(material_image,free_image,bottom)
   t.check(edges_match,"MATERIAL %s %s keeps seam-edge skin pixels canonical" % [slice_id,material])
 ui.game.add_fixture("wrist",4,10,false,2,"belt")
 ui.render();await t.frames()
 sidebar=ui.find_child("EquipmentPortrait",true,false)
 t.check(sidebar.texture==Portrait.BOUND_BASES.plain.leather_free,"MATERIAL outer upper-body belt overrides rope total")
 # Real removal changes material while keeping the occupied point and body pose.
 ui.game=Game.new(42)
 ui.game.add_fixture("ankle",4,10,false,0,"rope")
 var belt=ui.game.add_fixture("ankle",1,1,false,1,"belt")
 ui.render();await t.frames()
 sidebar=ui.find_child("EquipmentPortrait",true,false)
 var battle=ui.find_child("HeroArt",true,false).get_node("HeroPose")
 t.check(sidebar.get_node("Overlay_ankle").texture==Portrait.leg_layers.ankle.styles.plain.leather and battle.get_node("Overlay_ankle").texture==sidebar.get_node("Overlay_ankle").texture,"MATERIAL both live views display outer belt")
 var uid=ui.view.hand.filter(func(card):return card.type=="strain")[0].uid
 var candidate=Queries.find(ui.view,"card",{"uid":uid,"target":belt.id,"slot":"ankle"})
 if ui.card_faces.get(uid,false):await t.flip(uid)
 await t.start_drag(uid,"ankle")
 t.check(candidate.valid and ui.drop_targets.has(candidate.key),"MATERIAL actual strain candidate targets outer belt")
 await t.release_target(await t.reveal_drop_target(candidate.key))
 sidebar=ui.find_child("EquipmentPortrait",true,false)
 battle=ui.find_child("HeroArt",true,false).get_node("HeroPose")
 t.check("ankle" in sidebar.active_leg_layers and sidebar.get_node("Overlay_ankle").texture==Portrait.leg_layers.ankle.texture and battle.get_node("Overlay_ankle").texture==sidebar.get_node("Overlay_ankle").texture,"MATERIAL release refreshes both views despite unchanged body occupancy")
 # Any active single glove keeps all original slices, even with leather elsewhere.
 ui.game=Game.new(42,true,"glove_short")
 ui.game.add_fixture("ankle",4,10,false,1,"belt")
 ui.render();await t.frames()
 sidebar=ui.find_child("EquipmentPortrait",true,false)
 t.check(sidebar.texture==Portrait.BOUND_SINGLE_GLOVE and sidebar.get_node("Overlay_ankle").texture==Portrait.leg_layers.ankle.glove_texture,"MATERIAL any single-glove composition retains original art")

static func crotch_rope(t) -> void:
 var ui=t.ui
 for grade in ["low","medium","high"]:
  var item={"type":"crotch_rope_"+grade,"durability":1}
  t.check(Game.SpecialEquipment.portrait_layers([item])==["crotch_rope"],"PORTRAIT every live rope grade projects its family")
  item.durability=0
  t.check(Game.SpecialEquipment.portrait_layers([item]).is_empty(),"PORTRAIT exhausted rope never projects an appearance")
 for key in Portrait.BOUND_BASES:
  ui.game=Game.new(42);ui.game.add_fixture("ankle",4)
  if "flat_lock" in key:ui.game._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
  for worn in [false,true]:
   if worn:ui.game._install_special("crotch_rope_low","special_3_a")
   var before=ui.game.export_snapshot()
   ui.render();await t.frames()
   var sidebar=ui.find_child("EquipmentPortrait",true,false)
   var battle=ui.find_child("HeroArt",true,false).get_node("HeroPose")
   var expected=Portrait.BOUND_BASES[key]["bound" if worn else "free"]
   t.check(sidebar.texture==expected and battle.texture==expected,"PORTRAIT both standing views select actual rope state %s/%s" % [key,worn])
   var strap=sidebar.get_node("Overlay_flat_lock_reinforcement")
   t.check(strap.visible==("flat_lock" in key) and strap.texture==(Portrait.SPECIAL_LAYERS.flat_lock_reinforcement.texture if worn else Portrait.REINFORCEMENT_WITHOUT_CROTCH_ROPE),"PORTRAIT reinforcement follows rope state without inventing a strap")
   t.check(ui.game.export_snapshot()==before,"PORTRAIT rope display is a pure projection")
 ui.game=Game.new(42);ui.game.add_fixture("ankle",4)
 var rope=ui.game._install_special("crotch_rope_low","special_3_a")
 rope.durability=1
 ui.render();await t.frames()
 var uid=ui.view.hand.filter(func(card):return card.type=="strain")[0].uid
 var candidate=Queries.find(ui.view,"card",{"uid":uid,"target":rope.id,"slot":"special_3_a"})
 if ui.card_faces.get(uid,false):await t.flip(uid)
 await t.start_drag(uid,"special_3")
 t.check(candidate.valid and ui.drop_targets.has(candidate.key),"PORTRAIT actual strain candidate targets rope")
 await t.release_target(await t.reveal_drop_target(candidate.key))
 var sidebar=ui.find_child("EquipmentPortrait",true,false)
 var battle=ui.find_child("HeroArt",true,false).get_node("HeroPose")
 t.check(not "crotch_rope" in ui.view.equipment_portrait_layers and sidebar.texture==Portrait.BOUND_BASE and battle.texture==Portrait.BOUND_BASE,"PORTRAIT real release clears rope in both standing views")
 await t.capture("ui-equipment-crotch-rope-removed.png")
 # User excludes every composition containing a single glove from this art switch.
 for locked in [false,true]:
  ui.game=Game.new(42,true,"glove_short")
  if locked:ui.game._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
  for worn in [false,true]:
   if worn:ui.game._install_special("crotch_rope_low","special_3_a")
   ui.render();await t.frames()
   sidebar=ui.find_child("EquipmentPortrait",true,false)
   battle=ui.find_child("HeroArt",true,false).get_node("HeroPose")
   var expected=Portrait.BOUND_SINGLE_GLOVE_FLAT_LOCK if locked else Portrait.BOUND_SINGLE_GLOVE
   t.check(sidebar.texture==expected and battle.texture==expected,"PORTRAIT any single-glove composition retains original art regardless of rope")
   t.check(sidebar.get_node("Overlay_flat_lock_reinforcement").texture==Portrait.SPECIAL_LAYERS.flat_lock_reinforcement.texture,"PORTRAIT single glove retains original reinforcement artwork")
