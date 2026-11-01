extends RefCounted

static func hover(t, name: String) -> Control:
 var label=t.ui.find_child(name,true,false)
 t.check(label!=null,"INTENT UI actual highlighted term exists")
 if label==null: return null
 await t.move_mouse(label.get_global_rect().get_center())
 await t.frames()
 return t.ui.find_child("TermExplanation",true,false)

static func interrupted_action(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.card_buffs.append("infusion_bound");ui.render();await t.frames()
 var enemy=ui.view.enemies[0];var original=enemy.intent_icons.duplicate(true)
 t.check(await t.click("attack",{"type":"kick","form":0,"enemy":enemy.id}),"INTENT UI actual kick submits interrupt")
 var icons=ui.find_children("IntentIcon_"+enemy.id+"_*","",true,false)
 t.check(icons.size()==1 and icons[0].name=="IntentIcon_"+enemy.id+"_delayed","INTENT UI hides original icons while interrupted")
 var popup=await hover(t,"IntentIcon_"+enemy.id+"_delayed")
 t.check(popup!=null and t.visible_text(popup).strip_edges()=="敌人的行动已被打断","INTENT UI interrupt hover contains only the interrupted message")
 t.check(await t.click("end"),"INTENT UI completes the interrupted turn")
 t.check(ui.view.enemies[0].intent_icons==original and ui.find_child("IntentIcon_"+enemy.id+"_delayed",true,false)==null,"INTENT UI restores original icon and removes stale interrupt after skipped action")

static func run(t) -> void:
 await last_order_after_kick(t)
 await saturated_arrest(t)
 await interrupted_action(t)
 await t.start_practice("Practice_double_guard")
 var ui=t.ui
 var before=ui.game.export_snapshot()
 var first=ui.view.enemies[0];var second=ui.view.enemies[1]
 var popup=await hover(t,"IntentIcon_"+first.id+"_"+first.intent_icons[0].kind)
 t.check(popup!=null and t.visible_text(popup).strip_edges()==first.intent_icons[0].detail,"INTENT UI mouse hover shows only the concise sentence")
 t.check(popup!=null and Rect2(0,0,1600,900).encloses(popup.get_global_rect()),"INTENT UI first explanation fits viewport")
 t.check(ui.find_children("IntentTerm_*","",true,false).is_empty(),"INTENT UI no permanent text intent controls remain")
 await t.move_mouse(Vector2(700,510));await t.frames()
 t.check(ui.find_child("TermExplanation",true,false)==null,"INTENT UI leaving term closes explanation")
 popup=await hover(t,"IntentIcon_"+second.id+"_"+second.intent_icons[0].kind)
 t.check(popup!=null and Rect2(0,0,1600,900).encloses(popup.get_global_rect()),"INTENT UI right-side explanation automatically opens to left")
 t.check(ui.game.export_snapshot()==before,"INTENT UI hover and close cost no action and do not change plan")
 ui.game.add_fixture("eyes",4);ui.render();await t.frames()
 t.check(ui.find_child("TermExplanation",true,false)==null,"INTENT UI state refresh removes stale explanation")
 popup=await hover(t,"IntentIcon_"+first.id+"_hidden")
 t.check(popup!=null and t.visible_text(popup).strip_edges()=="视线受阻，敌人意图隐藏","INTENT UI blind hover only explains observation restriction")

 ui.restart(42);await t.frames()
 ui.game.state.enemies[0].intent.pressure=7
 ui.game.state.enemies[0].intent.text="PRIVATE_DEBUFF_DETAIL"
 ui.render();await t.frames()
 before=ui.game.export_snapshot()
 var id=ui.view.enemies[0].id
 popup=await hover(t,"IntentIcon_"+id+"_debuff")
 t.check(popup!=null and t.visible_text(popup).contains("敌人将要对你施加某种负面效果") and not t.visible_text(ui.layout).contains("PRIVATE_DEBUFF_DETAIL"),"INTENT UI dizzy symbol shows only generic negative-effect message")
 t.check(ui.game.export_snapshot()==before,"INTENT UI debuff hover never applies the effect")
 ui.game.add_fixture("eyes",4);ui.render();await t.frames()
 t.check(ui.find_child("IntentIcon_"+id+"_debuff",true,false)==null and ui.find_child("TermExplanation",true,false)==null,"INTENT UI blindness removes debuff icon and stale popup")
 ui.game.state.equipment.clear();ui.game.state.enemies[0].intent.erase("pressure")
 ui.render();await t.frames()
 t.check(ui.find_child("IntentIcon_"+id+"_debuff",true,false)==null,"INTENT UI ordinary intent has no debuff icon")
 await t.start_practice("Practice_rope_heap_solo")
 id=ui.view.enemies[0].id
 popup=await hover(t,"IntentIcon_"+id+"_debuff")
 t.check(popup!=null and t.visible_text(popup).contains("敌人将要对你施加某种负面效果") and not t.visible_text(ui.layout).contains("存活期间每回合新增"),"INTENT UI real heap growth uses shared dizzy cue without detailed preview")
 await t.move_mouse(Vector2(700,510));await t.frames()
 await t.start_practice("Practice_rope_mass_solo")
 before=ui.game.export_snapshot()
 popup=await hover(t,"IntentIcon_"+ui.view.enemies[0].id+"_wait")
 t.check(popup!=null and t.visible_text(popup).strip_edges()=="敌人正在蓄力","INTENT UI charging tooltip contains only the requested sentence")
 t.check(ui.game.export_snapshot()==before,"INTENT UI concise charging preview leaves frozen plan unchanged")
 t.check(popup!=null and popup.size.x<200 and popup.size.y<70,"INTENT UI short tooltip fits text without fixed-width blank space")
 var anchor=ui.find_child("IntentIcon_"+ui.view.enemies[0].id+"_wait",true,false)
 await t.move_mouse(Vector2(700,510));await t.frames()
 ui._show_term(anchor,{"label":"","detail":"较长的说明文字需要在达到最大宽度后自动换行。".repeat(5)})
 await t.frames()
 popup=ui.find_child("TermExplanation",true,false)
 t.check(popup!=null and popup.size.x<=350 and popup.size.y>70 and Rect2(0,0,1600,900).encloses(popup.get_global_rect()),"INTENT UI long tooltip wraps within bounded width and viewport")

static func last_order_after_kick(t) -> void:
 var ui=t.ui
 ui.restart(47);ui.game=preload("res://tests/six_bind_cases.gd").encounter(47)
 var g=ui.game;var id=g.state.enemies[0].id
 g.add_fixture("ankle",1)
 g._enemy(id).stage=3;g._enemy(id).intent=g._plan(g._enemy(id))
 ui.render();await t.frames()
 t.check(await t.click("attack",{"type":"kick","form":0,"enemy":id}),"LAST ORDER UI bound kick uses the real interrupt and fall")
 t.check(await t.click("end"),"LAST ORDER UI end turn advances into enemy-first turn")
 t.check(g.state.order=="last" and g._enemy(id).stage==4 and g._enemy(id).intent.is_empty() and g.state.deck.any(func(card):return card.type=="tease"),"LAST ORDER UI enemy already performed its real action before player input")
 var before=g.export_snapshot()
 var popup=await hover(t,"IntentIcon_"+id+"_wait")
 t.check(popup!=null and t.visible_text(popup).strip_edges()=="敌人本回合已行动，下一回合重新显示意图","LAST ORDER UI completed action is not described as idle; actual="+(t.visible_text(popup).strip_edges() if popup!=null else "<no popup>"))
 t.check(g.export_snapshot()==before,"LAST ORDER UI explanation never prepares or executes a future action")
 await t.move_mouse(Vector2(700,510));await t.frames()
 g.add_fixture("eyes",4);ui.render();await t.frames()
 popup=await hover(t,"IntentIcon_"+id+"_hidden")
 t.check(popup!=null and t.visible_text(popup).strip_edges()=="视线受阻，敌人意图隐藏","LAST ORDER UI eye obstruction retains its separate explanation")

static func saturated_arrest(t) -> void:
 var ui=t.ui
 ui.restart(42)
 var g=ui.game
 g.state.enemies.clear();g._spawn_enemies("drone_solo")
 var enemy=g.state.enemies[0]
 preload("res://tests/battle_saturation_cases.gd").exhaust(g,enemy)
 enemy.intent=g._plan(enemy)
 # Reveal the already-announced intent; changing equipment cannot silently
 # redraw it. Eye-obstruction rendering is covered separately below.
 g.state.equipment=g.state.equipment.filter(func(item):return item.slot!="eyes")
 ui.render();await t.frames()
 var before=g.export_snapshot()
 var popup=await hover(t,"IntentIcon_"+enemy.id+"_capture")
 t.check(popup!=null and t.visible_text(popup).strip_edges()=="敌人准备将你收押","ARREST UI uses the real capture icon and concise hover")
 t.check(g.state==before,"ARREST UI inspecting capture never changes the announced action")
 await t.move_mouse(Vector2(700,510));await t.frames()
 t.check(await t.click("end"),"ARREST UI real end-turn control submits the next enemy phase")
 t.check(g.state.phase=="captured" and g.state.capture.by==enemy.name,"ARREST UI enters the actual captured screen")


