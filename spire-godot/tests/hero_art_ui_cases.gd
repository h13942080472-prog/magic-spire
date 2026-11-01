extends RefCounted
const Art=preload("res://ui/pixel_art.gd")
const Game=preload("res://tests/game_fixture.gd")
const Portrait=preload("res://ui/equipment_portrait.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(20260906);await t.frames()
 var before=ui.game.export_snapshot()
 ui.render();await t.frames()
 t.check(ui.game.export_snapshot()==before,"ART redraw does not advance rules or random state")
 var last_height=INF
 for pose in ["stand","sit","lie"]:
  if pose!="stand": t.check(await t.click("posture",{"dest":pose,"wall":false}),"ART real adjacent posture action "+pose)
  var hero=ui.find_child("HeroArt",true,false)
  var sprite=hero.get_node("HeroPose")
  var expected=Art.HERO_POSES[pose]
  if pose=="stand":
   t.check(is_equal_approx(sprite.size.y,390.0*0.85) and is_equal_approx(hero.size.x,348.0*0.85),"ART battle hero is fifteen percent smaller")
   t.check(is_equal_approx(hero.get_rect().end.y,502.0) and is_equal_approx(hero.get_rect().get_center().x,590.0) and is_equal_approx(hero.get_rect().get_center().x,ui.find_child("HeroMana",true,false).position.x+80),"ART hero moves left with its meters and keeps its size and foot line")
  var target=ui.actor_targets.hero.get_global_rect()
  var portrait_bounds=hero.get_global_rect()
  t.check(target==portrait_bounds.grow_individual(-38,0,-38,0) and target.get_center().is_equal_approx(portrait_bounds.get_center()),"ART narrower drag target stays centered on the portrait "+pose)
  t.check(hero.pose==pose and sprite.texture==expected,"ART formal posture selects supplied cutout "+pose)
  t.check(sprite.material==null and sprite.texture.get_image().detect_alpha()!=Image.ALPHA_NONE,"ART real alpha without green-key shader "+pose)
  t.check(is_equal_approx(sprite.size.x/expected.get_width(),sprite.size.y/expected.get_height()),"ART original proportions preserved "+pose)
  t.check(is_equal_approx(sprite.position.y+sprite.size.y,hero.size.y) and sprite.position.x>=0 and sprite.position.x+sprite.size.x<=hero.size.x and sprite.size.y<=last_height,"ART complete sprite fits and shares ground line "+pose)
  last_height=sprite.size.y
  await t.capture("ui-21-hero-"+pose+".png")

 # A free-standing flat lock uses the supplied aligned image differences.
 ui.game=Game.new(42);ui.game._install_special("negative_plate_lock_medium","special_2_a",2)
 ui.render();await t.frames()
 var free_hero=ui.find_child("HeroArt",true,false);var free_sprite=free_hero.get_node("HeroPose")
 t.check(not ui.view.has_restraint_level and free_sprite.get_script()==Portrait and free_sprite.texture==Portrait.BATTLE_FREE and free_sprite.active_special_layers==["flat_lock"],"ART free-standing flat lock keeps the free pose and activates only its extracted lock difference")
 t.check(free_sprite.get_node("Overlay_free_flat_lock").visible and not free_sprite.get_node("Overlay_free_flat_lock_reinforcement").visible,"ART free-standing plain lock hides the reinforcement difference")
 await t.capture("ui-hero-free-flat-lock.png")
 ui.game=Game.new(42);ui.game._install_special("negative_plate_lock_medium","special_2_a",3)
 ui.render();await t.frames()
 free_hero=ui.find_child("HeroArt",true,false);free_sprite=free_hero.get_node("HeroPose")
 t.check(not ui.view.has_restraint_level and free_sprite.get_script()==Portrait and free_sprite.texture==Portrait.BATTLE_FREE and free_sprite.active_special_layers==["flat_lock","flat_lock_reinforcement"],"ART free-standing tier-three lock uses the same free base with its formal reinforcement state")
 t.check(free_sprite.get_node("Overlay_free_flat_lock").visible and free_sprite.get_node("Overlay_free_flat_lock_reinforcement").visible,"ART free-standing reinforcement displays both extracted differences")
 await t.capture("ui-hero-free-flat-lock-reinforced.png")

 # A nonzero arm or leg restriction level switches the formal combat pose.
 # Standing reuses the equipment portrait compositor, including its overlays.
 ui.game=Game.new(42)
 ui.game.add_fixture("wrist",4)
 ui.render();await t.frames()
 t.check(ui.view.has_restraint_level,"ART physical wrist restraint projects a restraint level")
 var hero=ui.find_child("HeroArt",true,false)
 var sprite=hero.get_node("HeroPose")
 var equipment=ui.find_child("EquipmentPortrait",true,false)
 t.check(sprite.get_script()==Portrait and sprite.texture==equipment.texture and sprite.variant==equipment.variant and sprite.active_leg_layers==equipment.active_leg_layers,"ART restrained standing battle portrait matches equipment portrait composition")
 await t.capture("ui-96-hero-restrained-stand.png")

 ui.game=Game.new(42,true,"glove_short")
 ui.render();await t.frames()
 hero=ui.find_child("HeroArt",true,false);sprite=hero.get_node("HeroPose");equipment=ui.find_child("EquipmentPortrait",true,false)
 t.check(sprite.get_script()==Portrait and sprite.texture==Portrait.BOUND_SINGLE_GLOVE and sprite.texture==equipment.texture and sprite.active_composite_layers==["single_glove"],"ART active single-glove assembly reaches both bound-standing portrait instances")
 await t.capture("ui-hero-single-glove.png")

 ui.game._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 ui.render();await t.frames()
 hero=ui.find_child("HeroArt",true,false);sprite=hero.get_node("HeroPose")
 t.check(sprite.get_script()==Portrait and sprite.texture==Portrait.BOUND_SINGLE_GLOVE_FLAT_LOCK and sprite.active_special_layers==["flat_lock","flat_lock_reinforcement","urethral_rod"],"ART restrained standing battle portrait reuses the combined single-glove and special-equipment composition")
 await t.capture("ui-hero-restrained-special-equipment.png")
 for pose in ["sit","lie"]:
  t.check(await t.click("posture",{"dest":pose,"wall":false}),"ART restrained real adjacent posture action "+pose)
  hero=ui.find_child("HeroArt",true,false);sprite=hero.get_node("HeroPose")
  var expected=Art.HERO_RESTRAINED_POSES[pose]
  t.check(hero.pose==pose and hero.has_restraint_level and sprite.get_script()!=Portrait and sprite.texture==expected,"ART restrained posture selects its supplied cutout without standing-only special differences "+pose)
  t.check(sprite.texture.get_image().detect_alpha()!=Image.ALPHA_NONE and is_equal_approx(sprite.size.x/expected.get_width(),sprite.size.y/expected.get_height()),"ART restrained cutout keeps alpha and original proportions "+pose)
  await t.capture("ui-96-hero-restrained-"+pose+".png")

 # Face equipment has no integer arm or leg restriction level.
 ui.game=Game.new(42);ui.game.add_fixture("eyes",4)
 ui.render();await t.frames()
 hero=ui.find_child("HeroArt",true,false);sprite=hero.get_node("HeroPose")
 t.check(not ui.view.has_restraint_level and sprite.texture==Art.HERO_POSES.stand,"ART face-only equipment does not invent an arm or leg restraint level")
 await hogtie_pose(t)
 await witch_portraits(t)
 await fixed_portrait(t)

static func hogtie_pose(t) -> void:
 var ui=t.ui
 ui.game=preload("res://tests/rope_master_cases.gd").encounter()
 ui.render();await t.frames()
 var hero=ui.find_child("HeroArt",true,false);var sprite=hero.get_node("HeroPose")
 t.check(ui.view.body_coverage.get("special_pose","")=="" and sprite.texture!=Art.HERO_SPECIAL_POSES.hogtie,"ART ordinary rope-master battle keeps the current posture art before hogtie")
 var boss=ui.game.RopeArt.master(ui.game);boss.rope_art.stock=100
 ui.game.RopeArt.hogtie(ui.game,boss,2)
 ui.render();await t.frames()
 hero=ui.find_child("HeroArt",true,false);sprite=hero.get_node("HeroPose")
 t.check(ui.view.body_coverage.get("special_pose","")=="hogtie" and hero.special_pose=="hogtie" and sprite.texture==Art.HERO_SPECIAL_POSES.hogtie,"ART live hogtie switches only the battle hero to its extracted special pose")
 t.check(sprite.texture.get_image().detect_alpha()!=Image.ALPHA_NONE and is_equal_approx(sprite.size.x/sprite.texture.get_width(),sprite.size.y/sprite.texture.get_height()),"ART hogtie cutout keeps real alpha and its original proportions")
 var sidebar=ui.find_child("EquipmentPortrait",true,false)
 t.check(sidebar.get_script()==Portrait and sidebar.texture!=Art.HERO_SPECIAL_POSES.hogtie,"ART hogtie special pose stays out of the body sidebar compositor")
 ui.display_settings.fixed_hero_portrait=true;ui.render();await t.frames()
 hero=ui.find_child("HeroArt",true,false);sprite=hero.get_node("HeroPose")
 t.check(hero.fixed_portrait and hero.special_pose=="" and sprite.texture==Portrait.FREE,"ART fixed portrait preference keeps its fixed battle image while hogtied")
 ui.display_settings.fixed_hero_portrait=false;ui.render();await t.frames()
 hero=ui.find_child("HeroArt",true,false);sprite=hero.get_node("HeroPose")
 t.check(hero.special_pose=="hogtie" and sprite.texture==Art.HERO_SPECIAL_POSES.hogtie,"ART leaving fixed portrait restores the still-active hogtie pose")
 var hogtie=ui.game._equipment(boss.rope_art.hogtie);hogtie.durability=0.0
 ui.render();await t.frames()
 hero=ui.find_child("HeroArt",true,false);sprite=hero.get_node("HeroPose")
 t.check(ui.view.body_coverage.get("special_pose","")=="" and hero.special_pose=="" and sprite.texture!=Art.HERO_SPECIAL_POSES.hogtie,"ART exhausted hogtie no longer projects the special pose before cleanup")
 ui.game._cleanup()
 ui.render();await t.frames()
 hero=ui.find_child("HeroArt",true,false);sprite=hero.get_node("HeroPose")
 t.check(ui.view.body_coverage.get("special_pose","")=="" and hero.special_pose=="" and sprite.texture!=Art.HERO_SPECIAL_POSES.hogtie,"ART removing hogtie immediately restores the ordinary battle posture")
 var witch=Game.new(42,false,"equipment",true,false,25,false,false,"witch")
 witch.state.room_encounters.entrance="rope_master_solo";witch._start_battle()
 boss=witch.RopeArt.master(witch);boss.rope_art.stock=100;witch.RopeArt.hogtie(witch,boss,2)
 ui.game=witch;ui.render();await t.frames()
 hero=ui.find_child("HeroArt",true,false);sprite=hero.get_node("HeroPose")
 t.check(ui.view.body_coverage.get("special_pose","")=="hogtie" and hero.character_id=="witch" and hero.special_pose=="" and hero.pose==ui.view.posture and sprite.texture==Art.WITCH_POSES[ui.view.posture],"ART witch keeps her own current pose while a live hogtie remains equipped")

static func witch_portraits(t) -> void:
 var ui=t.ui
 ui.game=Game.new(42,false,"equipment",true,false,25,false,false,"witch")
 ui.game.add_fixture("eyes",4)
 ui.render();await t.frames()
 var sidebar=ui.find_child("EquipmentPortrait",true,false)
 t.check(sidebar.texture==Portrait.WITCH_SIDEBAR and sidebar.witch_portrait and sidebar.get_children().all(func(n):return not n.visible),"ART witch sidebar uses its narrow source crop without unavailable restraint differences")
 for pose in ["stand","sit","lie"]:
  if pose!="stand": t.check(await t.click("posture",{"dest":pose,"wall":false}),"ART witch real adjacent posture action "+pose)
  var hero=ui.find_child("HeroArt",true,false)
  var sprite=hero.get_node("HeroPose")
  var expected=Art.WITCH_POSES[pose]
  t.check(hero.pose==pose and hero.character_id=="witch" and not hero.fixed_portrait and sprite.texture==expected,"ART witch formal posture selects supplied cutout "+pose)
  t.check(sprite.get_script()!=Portrait and sprite.texture.get_image().detect_alpha()!=Image.ALPHA_NONE and is_equal_approx(sprite.size.x/expected.get_width(),sprite.size.y/expected.get_height()),"ART witch keeps real alpha and source proportions "+pose)
  t.check(is_equal_approx(sprite.position.y+sprite.size.y,hero.size.y) and sprite.position.x>=0 and sprite.position.x+sprite.size.x<=hero.size.x,"ART witch complete sprite fits and shares the battle ground line "+pose)
  await t.capture("ui-witch-portrait-"+pose+".png")

static func fixed_portrait(t) -> void:
 var ui=t.ui
 ui.game=Game.new(42);ui.game.add_fixture("wrist",4);ui.game.add_fixture("eyes",4);ui.game.add_fixture("mouth",4);ui.game.add_fixture("ankle",4)
 ui.game._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 ui._return_home();await t.frames()
 await preload("res://tests/interface_ui_cases.gd").press(t,"HomeFixedPortrait")
 t.check(ui.display_settings.fixed_hero_portrait and ui.game.export_snapshot()==before,"ART homepage toggle enables static art without changing gameplay")
 await t.capture("ui-home-fixed-portrait.png")
 # Homepage Continue intentionally reloads the room checkpoint. This art test
 # keeps its current fixture to isolate rendering from save/restore behavior.
 ui.show_home=false;ui.render();await t.frames()
 var height=0.0
 for pose in ["stand","sit","lie"]:
  if pose!="stand": t.check(await t.click("posture",{"dest":pose,"wall":false}),"ART fixed portrait preserves real posture actions "+pose)
  var hero=ui.find_child("HeroArt",true,false);var sprite=hero.get_node("HeroPose")
  var equipment=ui.find_child("EquipmentPortrait",true,false)
  t.check(ui.view.posture==pose and hero.pose=="stand" and sprite.texture==Portrait.FREE and equipment.texture==Portrait.FREE,"ART both areas retain the supplied standing image through actual posture changes")
  t.check(equipment.get_children().all(func(n):return not n.visible) and sprite.get_child_count()==0,"ART fixed portrait hides mouth eyes and every leg difference")
  if height>0: t.check(is_equal_approx(height,sprite.size.y),"ART fixed standing sprite does not shrink for seated or lying state")
  height=sprite.size.y
 await t.capture("ui-fixed-portrait-battle.png")
 before=ui.game.export_snapshot();ui._return_home();await t.frames()
 await preload("res://tests/interface_ui_cases.gd").press(t,"HomeFixedPortrait")
 ui.show_home=false;ui.render();await t.frames()
 var hero=ui.find_child("HeroArt",true,false);var equipment=ui.find_child("EquipmentPortrait",true,false)
 t.check(not ui.display_settings.fixed_hero_portrait and ui.game.export_snapshot()==before,"ART disabling does not change gameplay")
 t.check(hero.get_node("HeroPose").texture==Art.HERO_RESTRAINED_POSES.lie,"ART disabling restores the restrained lying pose")
 t.check(equipment.get_node("Overlay_eyes").visible and equipment.get_node("Overlay_mouth").visible,"ART disabling restores eye and mouth differences")
