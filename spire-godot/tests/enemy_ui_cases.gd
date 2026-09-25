extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

static func floating_illustrations(t) -> void:
 var arena=preload("res://ui/arena.gd")
 var before=t.ui.game.export_snapshot()
 var missing=[];var broken=[];var display=[];var paths=[]
 for type in ["rope","belt","lock","gag"]:
  var visual=t.ui.game.Enemies.TYPES[type].visual
  if not arena.ILLUSTRATIONS.has(visual):
   missing.append(type);continue
  var texture=arena.ILLUSTRATIONS[visual]
  if texture==null or texture.resource_path in paths or texture.get_image().get_used_rect().size==Vector2i.ZERO or texture.get_image().detect_alpha()==Image.ALPHA_NONE:
   broken.append(type);continue
  paths.append(texture.resource_path)
  for inactive in [false,true]:
   var actor=arena.new()
   actor.mode=visual;actor.inactive=inactive;actor.position=Vector2(-2000,-2000);actor.size=Vector2(220,180)
   t.root.add_child(actor)
   actor.size=Vector2(110,90)
   var sprite=actor.enemy_sprite
   if sprite.texture!=texture or sprite.material!=null or sprite.texture_filter!=CanvasItem.TEXTURE_FILTER_LINEAR or sprite.mouse_filter!=Control.MOUSE_FILTER_IGNORE or sprite.size!=actor.size or (sprite.self_modulate.a<1.0)!=inactive:
    display.append(type)
   actor.free()
 t.check(missing.is_empty() and broken.is_empty(),"FLOAT ART actual floating enemy definitions resolve to distinct transparent art: "+str(missing+broken))
 t.check(display.is_empty(),"FLOAT ART scales in the existing actor, preserves inactive tint, and never blocks targeting: "+str(display))
 t.check(not arena.ILLUSTRATIONS.has("guard") and t.ui.game.export_snapshot()==before,"FLOAT ART keeps supplied guards separate and never changes battle or random state")

static func run(t) -> void:
 await six_bind_idle(t)
 t.ui.game=preload("res://tests/six_bind_cases.gd").encounter()
 t.ui._reset_interface(t.ui.game.get_view());t.ui.render();await t.frames()
 var art_settings=t.ui.display_settings
 var old_choices=art_settings.art_choices.duplicate(true)
 var old_persist=art_settings.persistence_enabled;art_settings.persistence_enabled=false
 var portrait_snapshot=t.ui.game.export_snapshot()
 var boss=t.ui.find_child("EnemyArt_"+t.ui.view.enemies[0].id,true,false)
 art_settings.set_art_style("enemies","six_bind","formal");await t.frames()
 t.check(boss.template=="six_bind" and boss.enemy_sprite.texture.resource_path.ends_with("enemy-six-bind-formal-v1.png"),"ART actual battle consumes individual formal selection")
 await t.capture("ui-six-bind-formal.png")
 art_settings.set_art_style("enemies","six_bind","test");await t.frames()
 t.check(not is_instance_valid(boss.enemy_sprite) and t.ui.game.export_snapshot()==portrait_snapshot,"ART live switching restores original battle drawing without touching combat")
 art_settings.art_choices=old_choices;art_settings.persistence_enabled=old_persist
 await floating_illustrations(t)
 var ui=t.ui
 ui.display_settings.persistence_enabled=false
 ui.display_settings.set_art_style("enemies","puppeteer","formal")
 ui.display_settings.set_art_style("enemies","puppet","formal")
 await t.start_practice("Practice_puppeteer_solo")
 var master=ui.view.enemies[0].id
 var master_art=ui.find_child("EnemyArt_"+master,true,false)
 t.check(ui.view.enemies[0].maximum==96 and master_art.enemy_sprite.texture.resource_path.ends_with("enemy-puppeteer-formal-v1.png"),"PUPPET UI practice displays supplied formal illustration and 96 HP")
 t.check(ui.view.enemies.size()==2 and ui.game.state.enemies[0].intent.kind=="puppet_awaken","PUPPET UI opening already shows both real actors with awakening intent")
 var doll=ui.view.enemies.filter(func(e):return e.template=="puppet")[0].id
 var doll_art=ui.find_child("EnemyArt_"+doll,true,false)
 t.check(doll_art.enemy_sprite.texture.resource_path.ends_with("enemy-puppet-formal-v1.png"),"PUPPET UI summoned doll uses separate transparent formal art")
 ui.display_settings.set_art_style("enemies","puppet","test");await t.frames()
 t.check(doll_art.enemy_sprite.texture.resource_path.ends_with("puppet.svg") and ui.find_child("EnemyArt_"+master,true,false).enemy_sprite.texture.resource_path.ends_with("enemy-puppeteer-formal-v1.png"),"PUPPET UI doll switches independently from its summoner")
 ui.display_settings.set_art_style("enemies","puppet","formal");await t.frames()
 var formation_state=ui.game.export_snapshot()
 var formation_order=ui.view.enemies.map(func(e):return e.id)
 ui.render();await t.frames()
 var doll_rect=ui.find_child("EnemyGroup_"+doll,true,false).get_global_rect()
 var master_rect=ui.find_child("EnemyGroup_"+master,true,false).get_global_rect()
 t.check(doll_rect.end.x<=master_rect.position.x and ui.actor_targets[doll].get_global_rect().get_center().x<ui.actor_targets[master].get_global_rect().get_center().x,"PUPPET UI doll and its target appear left of the puppeteer")
 t.check(ui.game.export_snapshot()==formation_state and ui.view.enemies.map(func(e):return e.id)==formation_order,"PUPPET UI visual order does not reorder combat actors or change state")
 await t.capture("ui-puppet-formation.png")
 ui.display_settings.art_choices=old_choices;ui.display_settings.persistence_enabled=old_persist
 t.check(ui.find_child("StatusIcon_puppet_"+doll,true,false)!=null and ui.actor_targets.has(doll),"PUPPET UI innate protection visible immediately with an actual hit target")
 t.check(ui.find_child("StatusIcon_damage_barrier_"+master,true,false).find_child("StatusCount",true,false).text=="30" and ui.find_child("StatusIcon_puppet_stock_"+doll,true,false).find_child("StatusCount",true,false).text=="3","PUPPET UI initial barrier allowance and reaction stock are visible on enemy icons")
 t.check(await t.click("attack",{"type":"strike","form":0,"enemy":master}) and ui.find_child("StatusIcon_damage_barrier_"+master,true,false).find_child("StatusCount",true,false).text=="22","PUPPET UI direct attack immediately reduces barrier badge by actual damage")
 t.check(await t.click("end") and ui.view.statuses.any(func(s):return s.id=="puppet_"+doll and s.detail.contains("单体攻击必须选择玩偶")),"PUPPET UI awakening updates the shared puppet status")
 t.check(ui.find_child("StatusIcon_damage_barrier_"+master,true,false).find_child("StatusCount",true,false).text=="30","PUPPET UI next turn resets barrier badge to thirty")
 t.check(not Queries.find(ui.view,"attack",{"type":"strike","enemy":master}).valid and Queries.find(ui.view,"attack",{"type":"strike","enemy":master}).reason.contains("嘲讽"),"PUPPET UI master target gives the actual taunt reason")
 var target_point=ui.find_child("EnemySelect_"+doll,true,false).get_global_rect().get_center()
 await t.mouse_button(target_point,MOUSE_BUTTON_LEFT,true)
 await t.mouse_button(target_point,MOUSE_BUTTON_LEFT,false)
 var attack_point=ui.find_child("BasicAttack_strike",true,false).get_global_rect().get_center()
 await t.mouse_button(attack_point,MOUSE_BUTTON_RIGHT,true)
 await t.mouse_button(attack_point,MOUSE_BUTTON_RIGHT,false)
 ui.game.state.turn_strength=50;ui.render();await t.frames()
 t.check(await t.click("attack",{"type":"strike","form":1,"enemy":doll}) and ui.game.physical_pieces().size()==2,"PUPPET UI two-hit attack performs two real reactions")
 var barrier=ui.view.statuses.filter(func(s):return s.id=="damage_barrier_"+master)[0]
 t.check(ui.find_child("StatusIcon_damage_barrier_"+master,true,false).find_child("StatusCount",true,false).text=="0" and not barrier.detail.contains("层") and barrier.value.contains("0点伤害"),"PUPPET UI exhausted barrier displays zero remaining damage with no stack count")
 ui.localization.set_locale("en_US")
 var translated_barrier=ui.localization.display(barrier.detail)
 t.check(translated_barrier.contains("per turn") and translated_barrier.contains("capacity"),"PUPPET UI barrier has English turn-limit and capacity explanations: "+translated_barrier+" diagnostics="+str(ui.localization.diagnostics()))
 ui.localization.set_locale("zh_CN")
 t.check(ui.find_child("StatusIcon_puppet_stock_"+doll,true,false).find_child("StatusCount",true,false).text=="1","PUPPET UI real multihit updates ordinary stock icon")
 t.check(await t.click("end") and ui.game._enemy(doll).puppet_prepared.has("composite") and ui.game._enemy(doll).max_hp==15,"PUPPET UI next action prepares composite before mending")
 t.check(ui.view.statuses.filter(func(s):return s.id=="puppet_stock_"+doll)[0].value=="1/2" and barrier.detail.contains("容量上限－1"),"PUPPET UI barrier trigger updates the visible stock maximum and explanation")
 t.check(await t.click("end") and await t.click("end") and ui.game._enemy(doll).hp==20 and ui.game._enemy(doll).max_hp==20 and ui.find_child("StatusIcon_puppet_stock_"+doll,true,false).find_child("StatusCount",true,false).text=="3","PUPPET UI mending adds one to the reduced capacity and refills it")
 await t.start_practice("Practice_binding_box_solo")
 var box_id=ui.view.enemies[0].id
 t.check(ui.find_child("EnemyArt_"+box_id,true,false).mode=="binding_box" and ui.view.statuses.any(func(s):return s.id=="carried_"+box_id and s.value=="3件"),"BOX UI practice renders mechanical box and actual carried stock")
 t.check(await t.click("end") and ui.view.posture=="sit" and ui.find_child("HeroGuardBindValue",true,false).text=="40/100" and ui.view.statuses.any(func(s):return s.id=="guard_bind" and s.detail.contains("首个玩家回合不触发")),"BOX UI opening preserves forty and explains the first upkeep skip")
 await t.start_practice("Practice_drone_solo")
 var drone_id=ui.view.enemies[0].id
 t.check(ui.view.enemies[0].template=="drone" and ui.find_child("EnemyArt_"+drone_id,true,false).mode=="drone" and ui.find_child("StatusIcon_hard_"+drone_id,true,false)!=null,"DRONE UI native practice renders mechanical enemy and hard buff")
 t.check(await t.click("end") and ui.view.guard_bind.value==30.0 and ui.view.posture=="stand","DRONE UI direct opening capture fixes standing")
 t.check(ui.actor_targets.has("guard_bind") and ui.find_child("HeroGuardBindValue",true,false).text=="30/100" and ui.view.statuses.any(func(s):return s.id=="guard_bind" and s.detail.contains("同种捕缚不叠加")),"DRONE UI uses one real target meter and explains source stacking")
 var escape_cards=ui.view.hand.filter(func(c):return c.type=="strain")
 t.check(not escape_cards.is_empty(),"DRONE UI has an actual escape card")
 if not escape_cards.is_empty():
  await t.drop_card_on_actor(escape_cards[0].uid,"guard_bind")
  t.check(ui.view.guard_bind.value==18.0 and ui.game.state.guard_bind.sources.drone.energy==1,"DRONE UI six-base card deals twelve damage to shared bar and retains paid energy")
 await t.start_practice("Practice_versatile_solo")
 var versatile_id=ui.view.enemies[0].id
 t.check(ui.view.enemies[0].template=="versatile" and ui.view.enemies[0].maximum==60 and ui.layout.find_child("EnemyArt_"+versatile_id,true,false).mode=="versatile","VERSATILE UI practice uses its human silhouette and actual health")
 t.check(ui.view.enemies[0].intent_icons[0].kind=="wait" and await t.click("end") and ui.view.enemies[0].intent_icons[0].kind=="bind","VERSATILE UI idle advances to announced special installation")
 t.check(await t.click("end") and ui.game.state.special_equipment.size()==1 and ui.view.enemies[0].intent_icons[0].kind in ["lock","tighten"],"VERSATILE UI installs a special item and exposes the chosen control branch")
 t.check(await t.click("end") and ui.view.enemies[0].intent_icons[0].kind=="bind","VERSATILE UI control returns to the two-step cycle")
 await t.start_practice("Practice_mixed_pair")
 t.check(ui.view.enemies.size()==2 and ui.view.enemies.all(func(e):return e.template=="mixed_bundle" and e.maximum==56),"MIXED UI exposes the strong pair with independent targets")
 t.check(ui.layout.find_child("EnemyArt_"+ui.view.enemies[0].id,true,false).mode=="mixed_bundle","MIXED UI uses its mixed-material silhouette")
 for enemy in ui.view.enemies:
  var art=ui.layout.find_child("EnemyArt_"+enemy.id,true,false)
  var label=ui.layout.find_child("EnemySelect_"+enemy.id,true,false)
  t.check(art.size==Vector2(264,216) and art.get_parent().scale==Vector2.ONE,"MIXED UI paired monsters are twenty percent larger without shrinking the pair")
  t.check(art.get_global_rect().end.y<label.get_global_rect().position.y and ui.actor_targets[enemy.id].get_global_rect()==art.get_global_rect(),"MIXED UI enlarged art retains a matching target above its name")
  for entry in enemy.intent_icons:
   var icon=ui.layout.find_child("IntentIcon_"+enemy.id+"_"+entry.kind,true,false)
   t.check(icon.get_global_rect().end.y<art.get_global_rect().position.y,"MIXED UI intent remains above enlarged art")
 await t.capture("ui-enlarged-monsters.png")
 t.check(await t.click("end") and ui.game.physical_pieces().size()+ui.game.state.links.size()==4,"MIXED UI pair applies four actual restraints through end turn")
 await t.start_practice("Practice_rope_serpent_solo")
 var serpent_id=ui.view.enemies[0].id
 t.check(ui.view.enemies[0].maximum==60 and ui.layout.find_child("EnemyArt_"+serpent_id,true,false).mode=="rope_serpent","SERPENT UI uses actual sixty HP enemy and distinct silhouette")
 t.check(await t.click("end") and ui.view.statuses.any(func(s):return s.name=="紧缠" and s.value.contains("1层") and s.detail.contains("结束")),"SERPENT UI exposes source-bound end-of-player-turn effect")
 t.check(await t.click("end") and ui.game.physical_pieces().size()+ui.game.state.links.size()==3,"SERPENT UI end turn performs passive pulse and lash")
 await t.start_practice("Practice_small_circle_solo")
 t.check(ui.view.enemies[0].maximum==30 and ui.view.enemies[0].template=="small_circle","RITUAL UI weak practice renders the thirty HP variant")
 t.check(await t.click("end") and ui.view.enemies[0].intent_icons.any(func(icon):return icon.kind=="tighten" and icon.detail.contains("剩余施加次数改为加固")),"RITUAL UI announces conditional reinforcement on the real weak variant")
 await t.start_practice("Practice_ominous_circle_solo")
 var circle_id=ui.view.enemies[0].id
 t.check(ui.view.enemies[0].maximum==40 and ui.layout.find_child("EnemyArt_"+circle_id,true,false).mode=="ominous_circle","RITUAL UI practice exposes actual magic circle and HP")
 t.check(await t.click("end") and ui.view.statuses.any(func(s):return s.id=="ritual_"+circle_id and s.value.contains("＋3")),"RITUAL UI first action exposes active ritual and current bonus")
 t.check(await t.click("end") and ui.game.equipment_targets().size()==4 and ui.view.statuses.any(func(s):return s.id=="ritual_"+circle_id and s.value.contains("＋6")),"RITUAL UI actual application updates equipment and growth")
 await t.start_practice("Practice_belt_heap_solo")
 var leather_id=ui.view.enemies[0].id
 t.check(ui.layout.find_child("EnemyArt_"+leather_id,true,false).mode=="belt_heap" and ui.view.enemies[0].intent_icons.any(func(icon):return icon.kind=="debuff"),"SKIN UI elite has leather silhouette and generic debuff intent")
 t.check(await t.click("end") and ui.view.statuses.any(func(s):return s.name=="皮带增生"),"SKIN UI source effect matches the actual skin")
 await t.start_practice("Practice_belt_mass_solo")
 leather_id=ui.view.enemies[0].id
 t.check(ui.layout.find_child("EnemyArt_"+leather_id,true,false).mode=="belt_mass","SKIN UI mass has its own leather silhouette")
 ui.game._enemy(leather_id).hp=1;ui.render();await t.frames()
 t.check(await t.click("attack",{"type":"strike","enemy":leather_id}) and ui.view.enemies.filter(func(e):return not e.gone).all(func(e):return e.template=="belt"),"SKIN UI death creates actual selectable leather children")
 await t.start_practice("Practice_rope_heap_solo")
 var heap_id=ui.view.enemies[0].id
 t.check(ui.view.enemies[0].template=="rope_heap" and ui.view.enemies[0].maximum==96 and ui.layout.find_child("EnemyArt_"+heap_id,true,false).mode=="rope_heap","HEAP UI practice has distinct elite silhouette and actual HP")
 t.check(await t.click("end") and ui.view.statuses.any(func(s):return s.id=="turn_install_"+heap_id),"HEAP UI first action exposes active source effect")
 var hit=Queries.find(ui.view,"attack",{"type":"strike","enemy":heap_id})
 ui.game._enemy(heap_id).hp=47+hit.payload.damage;ui.render();await t.frames()
 t.check(await t.click("attack",{"type":"strike","enemy":heap_id}) and ui.view.enemies.filter(func(e):return not e.gone).size()==3,"HEAP UI formal attack splits elite into three actual targets")
 t.check(ui.view.statuses.all(func(s):return s.id!="turn_install_"+heap_id) and ui.view.enemies.filter(func(e):return not e.gone).all(func(e):return Queries.select(ui.view,"attack").any(func(c):return c.payload.enemy==e.id)),"HEAP UI removes source status and supplies child attack targets")
 t.check(ui.layout.find_child("EnemyGroup_"+heap_id,true,false)==null and not ui.actor_targets.has(heap_id),"CROWD split parent immediately releases its entire visual slot")
 var large_child=ui.view.enemies.filter(func(e):return not e.gone and e.template=="rope_mass")[0]
 ui.game._enemy(large_child.id).hp=1;ui.render();await t.frames()
 t.check(await t.click("attack",{"type":"strike","enemy":large_child.id}) and ui.view.enemies.filter(func(e):return not e.gone).size()==4,"CROWD actual second split produces four living enemies")
 t.check(ui.layout.find_child("EnemyGroup_"+large_child.id,true,false)==null,"CROWD defeated child also releases its visual slot")
 var previous_width=220.0
 for count in range(4,8):
  if count>4:
   var extra=ui.game._append_enemies([{"type":"rope","grade":1}])[0]
   extra.intent=ui.game._plan(extra)
   ui.render();await t.frames()
  var snapshot=ui.game.export_snapshot()
  var living=ui.view.enemies.filter(func(e):return not e.gone)
  var width=ui.layout.find_child("EnemyArt_"+living[0].id,true,false).get_global_rect().size.x
  var last_right=-INF
  for enemy in living:
   var receiver=ui.actor_targets[enemy.id].get_global_rect()
   t.check(receiver.position.x>=last_right and ui.layout.get_global_rect().encloses(receiver),"CROWD scaled targets do not overlap or leave the viewport")
   last_right=receiver.end.x
   t.check(ui.layout.find_child("EnemySelect_"+enemy.id,true,false)!=null,"CROWD each living enemy retains a selectable name")
  t.check(width<previous_width and living.size()==count and ui.game.export_snapshot()==snapshot,"CROWD size decreases at each additional enemy without altering state")
  previous_width=width
 var target_id=ui.view.enemies.filter(func(e):return not e.gone)[-1].id
 ui.actor_targets[target_id].pressed.emit();await t.frames()
 t.check(ui.selected_enemy==target_id,"CROWD scaled actor still selects the correct actual enemy")
 await t.start_practice("Practice_rope_mass_solo")
 var mass_id=ui.view.enemies[0].id
 t.check(ui.view.enemies[0].template=="rope_mass" and ui.view.enemies[0].maximum==48 and ui.find_child("StatusIcon_split_"+mass_id,true,false)!=null,"MASS UI practice exposes death split as a passive status before attack")
 t.check(ui.layout.find_child("EnemyArt_"+mass_id,true,false).mode=="rope_mass","MASS UI uses distinct rope bundle silhouette")
 ui.game._enemy(mass_id).hp=1;ui.render();await t.frames()
 t.check(await t.click("attack",{"type":"strike","enemy":mass_id}) and ui.view.phase=="battle" and ui.view.enemies.filter(func(e):return not e.gone).size()==2,"MASS UI lethal attack creates two selectable children without reward screen")
 var children=ui.view.enemies.filter(func(e):return not e.gone)
 t.check(children.all(func(e):return e.intent_icons.any(func(row):return row.kind=="wait")) and ui.view.action_log.any(func(l):return l.cue=="enemy.split"),"MASS UI shows entry timing and split result")
 t.check(children.all(func(e):return Queries.select(ui.view,"attack").any(func(c):return c.payload.enemy==e.id and c.valid)),"MASS UI children receive actual attack facts")
 await t.start_practice("Practice_gag_solo")
 for button in ui.card_buttons.values():
  var illustration=button.get_node("CardIllustration")
  t.check(illustration.size.x>0 and illustration.size.y>0 and illustration.get_rect().end.x<=button.size.x,"ART card illustration receives final card size and stays inside it")
 t.check(ui.view.enemies.size()==1 and ui.view.enemies[0].type=="silencer" and ui.view.enemies[0].intent_icons[0].detail=="敌人正在蓄力","MOUTH native practice shows distinct enemy and first charge")
 await t.capture("ui-62-floating-silencer.png")
 t.check(await t.click("end") and ui.view.enemies[0].intent_icons[0].detail=="敌人正在蓄力","MOUTH real first charge advances public intent")
 t.check(await t.click("end") and ui.view.bodies.filter(func(b):return b.id=="mouth")[0].equipment.is_empty(),"MOUTH two charges do not apply early")
 t.check(await t.click("end") and ui.view.phase=="reward" and ui.view.bodies.filter(func(b):return b.id=="mouth")[0].equipment.size()==1,"MOUTH actual attachment leaves one retained equipment and one reward screen")
 var attached=ui.game.equipment_at("mouth")[0]
 t.check(attached.grade==2 and ui.game.tier(attached.durability,attached.maximum)==3,"MOUTH UI departure applies the announced medium tier-three equipment")
 t.check(await t.click("reward",{"type":"skip"}) and ui.view.phase=="prepare","MOUTH reward enters normal preparation")
 ui.selected_slot="mouth";ui.render();await t.frames()
 var target=ui.view.bodies.filter(func(b):return b.id=="mouth")[0].equipment[0]
 var card=ui.view.hand.filter(func(c):return c.type=="strain")[0]
 var candidate=Queries.find(ui.view,"card",{"uid":card.uid,"slot":"mouth","target":target.id})
 var damage=candidate.payload.preview.damage
 var original=target.durability
 await t.start_drag(card.uid,"mouth")
 await t.release_target(await t.reveal_drop_target(candidate.key))
 var remaining=ui.view.bodies.filter(func(b):return b.id=="mouth")[0].equipment
 t.check((remaining.is_empty() and damage>=original) or (not remaining.is_empty() and is_equal_approx(remaining[0].durability,original-damage)),"MOUTH native drag applies actual equipment damage")
 await t.start_practice("Practice_belt_gag")
 t.check(ui.view.enemies.size()==2 and ui.view.enemies[0].type=="belt" and ui.view.enemies[1].type=="silencer","MOUTH strong practice renders actual separate targets")
 for i in range(3): t.check(await t.click("end"),"MOUTH mixed battle progresses via real turns")
 t.check(ui.view.phase=="battle" and ui.view.enemies[1].gone and not ui.view.enemies[0].gone,"MOUTH one departure does not end mixed encounter")
 t.check(ui.view.display_facts.any(func(c):return c.payload.kind=="attack" and c.payload.type=="fireball" and c.valid) and ui.view.casting.chance>0 and ui.view.casting.chance<1,"MOUTH UI receives actual reduced spell chance")
 await t.capture("ui-63-mouth-restriction.png")

 # Controlled visibility boundary; normal-play runs below never use fixtures.
 ui.restart(20260906);await t.frames()
 var mask=ui.game.add_fixture("eyes",4)
 ui.render();await t.frames()
 t.check(ui.view.enemies.all(func(e):return not e.intent_visible and e.intent_icons.size()==1 and e.intent_icons[0].kind=="hidden"),"VISION UI hides every living enemy intent")
 await t.capture("ui-66-hidden-intents.png")
 var slip=ui.view.hand.filter(func(c):return c.type=="slip")[0]
 if ui.card_faces.get(slip.uid,false): await t.flip(slip.uid)
 var escape=Queries.find(ui.view,"card",{"uid":slip.uid,"slot":"eyes","target":mask.id})
 var plans=ui.game.state.enemies.duplicate(true)
 await t.start_drag(slip.uid,"eyes")
 await t.release_target(await t.reveal_drop_target(escape.key))
 t.check(ui.view.enemies.all(func(e):return e.intent_visible) and ui.game.state.enemies==plans,"VISION native escape reveals unchanged intent in same turn")
 await t.capture("ui-67-restored-intents.png")
 var attack=Queries.select(ui.view,"attack").filter(func(c):return c.valid)[0]
 ui.selected_enemy=attack.payload.enemy;ui.render();await t.frames()
 var old_hp=ui.view.enemies.filter(func(e):return e.id==attack.payload.enemy)[0].hp
 t.check(await t.click("attack",attack.payload),"ART feedback follows a real legal attack")
 var new_hp=ui.view.enemies.filter(func(e):return e.id==attack.payload.enemy)[0].hp
 var feedback=ui.layout.find_child("DamageFeedback",true,false)
 t.check(feedback!=null and feedback.text=="−"+ui.game.number(old_hp-new_hp),"ART floating damage matches actual target HP loss")
 var committed=JSON.stringify(ui.game.state)
 await t.create_timer(0.7).timeout
 t.check(JSON.stringify(ui.game.state)==committed and ui.layout.find_child("DamageFeedback",true,false)==null,"ART completed feedback removes itself without advancing game state")

 for type in ["rope","belt","tape","cable_tie","toybox"]:
  await t.start_practice("Practice_"+type+"_solo")
  t.check(ui.view.enemies[0].template==type and not ui.view.enemies[0].has("strength") and not t.visible_text(ui.layout).contains("强度 1"),"WEAK UI live replacement hides internal strength "+type)
  t.check(ui.layout.find_child("EnemyArt_"+ui.view.enemies[0].id,true,false)!=null,"WEAK UI equipment silhouette "+type)
 t.check(ui.view.enemies[0].intent_icons[0].kind=="wait","BOX UI first phase preparation")
 await t.capture("ui-weak-toybox-prepare.png")
 t.check(await t.click("end") and ui.game.state.special_equipment.is_empty() and ui.view.enemies[0].intent_icons[0].kind=="bind","BOX UI prepare then show wearable intent")
 var declared=ui.game.state.enemies[0].intent.duplicate(true)
 t.check(await t.click("end") and ui.game.state.special_equipment.size()==1 and ui.game.state.special_equipment[0].type in declared.templates and ui.view.enemies[0].intent_icons[0].kind=="wait","BOX UI installs one allowed design at execution then shows pause")
 t.check(ui.view.action_log.any(func(l):return l.text.contains("施加了")),"BOX UI actual installation enters shared feedback log")
 await t.capture("ui-weak-toybox-pause.png")
 t.check(await t.click("end") and ui.game.state.special_equipment.size()==1 and ui.view.enemies[0].intent_icons[0].kind=="wait","BOX UI pause returns to preparation")


 await t.start_practice("Practice_lock_solo")
 t.check(ui.view.enemies[0].template=="lock" and not ui.view.enemies[0].has("strength") and ui.view.enemies[0].intent_icons[0].detail=="敌人正在蓄力","LOCK UI practice announces with backend-only strength")
 var equipment=ui.game.state.equipment.duplicate(true)
 t.check(equipment.size()==2 and equipment.all(func(e):return not e.locked),"LOCK UI practice starts with real unlocked targets")
 t.check(await t.click("end") and ui.game.state.equipment==equipment and ui.view.enemies[0].intent_icons[0].kind=="lock","LOCK UI announcement does not apply early")
 t.check(await t.click("end") and ui.game.state.equipment.filter(func(e):return e.locked).size()==1 and ui.view.enemies[0].intent_icons[0].detail=="敌人正在蓄力" and ui.view.phase=="battle","LOCK UI native turn locks then repeats announcement")
 await t.capture("ui-floating-lock.png")
 t.check(await t.click("end") and await t.click("end") and ui.view.phase=="reward","SATURATION UI last lockable position leads to reward through normal turns")
 t.check(ui.game.state.equipment.all(func(e):return e.locked) and ui.view.enemies.all(func(e):return e.gone) and ui.game.state.reward_count==1,"SATURATION UI keeps equipment and removes living enemy targets without duplicate reward")


 await t.start_practice("Practice_rope_solo")
 ui.game._install_template("rope","forearm",8,10,false,"fixture",1,-1,0,"mid_forearm");ui.game.add_fixture("wrist",8);ui.game.add_fixture("fingers",8,10,false,0,"cord")
 var rope_enemy=ui.game.state.enemies[0]
 rope_enemy.intent=ui.game.EnemyPlans.application(["link_rope"])
 ui.render();await t.frames()
 t.check(ui.view.enemies[0].intent_icons[0].kind=="bind","LINK UI displays declared link installation")
 await t.capture("ui-enemy-link-intent.png")
 var before_link=ui.view
 t.check(await t.click("end") and ui.game.state.links.size()==1 and ui.view.action_log.any(func(l):return l.text.contains("链接绳")),"LINK UI real turn installs one link with feedback")
 t.check(preload("res://ui/combat_feedback.gd").steps(before_link,ui.view).any(func(step):return step.slots==ui.game.state.links[0].slots),"LINK UI feedback retains both real connection locations")

 ui.game_factory=preload("res://core/game.gd");ui.restart(42);await t.frames()
 t.check(await t.click("departure",{"op":"skip"}) and ui.view.phase=="map","POOL UI completes the formal opening before choosing a room")
 var destinations=Queries.select(ui.view,"route")
 t.check(not destinations.is_empty(),"POOL UI opening map exposes actual destinations")
 if destinations.is_empty(): return
 var destination=destinations[0].payload.room
 t.check(await t.click("depart",{"room":destination}),"POOL UI enters an ordinary room from the live map")
 while ui.view.phase=="travel":await t.click("travel_step")
 t.check(ui.view.enemies.size() in [1,2] and ui.view.enemies.all(func(e):return e.template!="lock" and not e.has("strength")),"POOL UI shows actual budgeted enemies and excludes lock at free opening")
 await t.capture("ui-weak-budget-group.png")


static func six_bind_idle(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game=preload("res://tests/six_bind_cases.gd").encounter()
 var enemy=ui.game.state.enemies[0];enemy.stage=10;enemy.intent=ui.game._plan(enemy)
 ui.render();await t.frames()
 var icons=ui.view.enemies[0].intent_icons
 t.check(icons.size()==1 and icons[0].kind=="wait" and icons[0].detail=="敌人暂不行动","SIX IDLE UI shows wait intent without equipment or debuff icons")
 var popup=await preload("res://tests/intent_ui_cases.gd").hover(t,"IntentIcon_"+enemy.id+"_wait")
 t.check(t.visible_text(popup).contains("敌人暂不行动"),"SIX IDLE UI hover explains the idle turn")
 await t.move_mouse(Vector2(650,60));await t.frames()
 t.check(await t.click("end") and ui.game.state.enemies[0].stage==11 and ui.view.enemies[0].intent_icons.any(func(icon):return icon.kind=="bind") and ui.game.state.equipment.is_empty(),"SIX IDLE UI end-turn leaves equipment alone and announces next cycle")
 ui.restart(42);await t.frames()
