extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")

static func pleasure_extractor(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 ui.game.state.relics=[];ui.game.state.flask_mana=0;ui.game.state.pressure=99
 ui.game.RelicEffects.gain(ui.game,"pleasure_extractor")
 ui.game.state.pressure_sources=[preload("res://tests/pressure_cases.gd").source("extractor_ui","turn_end",5)]
 for enemy in ui.game.state.enemies: enemy.intent.delayed=true
 ui.render();await t.frames()
 var icon=ui.find_child("RelicShortcut_pleasure_extractor",true,false)
 t.check(icon!=null and preload("res://ui/relic_icon.gd").ART.has("pleasure_extractor"),"EXTRACTOR UI acquired relic has its dedicated icon")
 await t.move_mouse(icon.get_global_rect().get_center());await t.frames()
 t.check(ui.term_popup!=null and t.visible_text(ui.term_popup).contains("高潮后，魔瓶魔力＋10。"),"EXTRACTOR UI hover shows the concise effect")
 t.check(await t.click("end") and ui.game.state.flask_mana==10,"EXTRACTOR UI real end-turn input triggers automatic flask gain")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("快感汲取器")=="Pleasure Extractor" and ui.localization.display("高潮后，魔瓶魔力＋10。")=="After each climax, add 10 mana to the flask.","EXTRACTOR UI localized name and description are available")
 ui.localization.set_locale("zh_CN")

static func lucidity_necklace(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 ui.game.state.relics=[];ui.game.RelicEffects.gain(ui.game,"lucidity_necklace")
 ui.game.state.pressure_sources=[preload("res://tests/pressure_cases.gd").source("necklace_ui","posture",100)]
 for enemy in ui.game.state.enemies: enemy.intent.delayed=true
 ui.render();await t.frames()
 var icon=ui.find_child("RelicShortcut_lucidity_necklace",true,false)
 t.check(icon!=null and preload("res://ui/relic_icon.gd").ART.has("lucidity_necklace") and icon.find_child("RelicCounter",true,false).text=="0","NECKLACE UI acquired relic shows its dedicated icon and empty counter")
 t.check(await t.click("posture",{"dest":"sit","wall":false}) and ui.game.state.hand.is_empty(),"NECKLACE UI real climax does not draw immediately")
 icon=ui.find_child("RelicShortcut_lucidity_necklace",true,false)
 t.check(icon.find_child("RelicCounter",true,false).text=="1","NECKLACE UI pending counter updates after formal climax")
 await t.move_mouse(icon.get_global_rect().get_center());await t.frames()
 t.check(ui.term_popup!=null and t.visible_text(ui.term_popup).contains("高潮时，下回合多抽1张牌。") and t.visible_text(ui.term_popup).contains("下回合额外抽牌：1张。"),"NECKLACE UI tooltip explains effect and current pending reward")
 t.check(await t.click("end") and ui.view.hand.size()==ui.game.B.DRAW+1 and ui.find_child("RelicShortcut_lucidity_necklace",true,false).find_child("RelicCounter",true,false).text=="0","NECKLACE UI next-turn input deals the extra card and clears its badge")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("清醒项链")=="Lucidity Necklace" and ui.localization.display("下回合额外抽牌：2张。")=="Additional cards next turn: 2.","NECKLACE UI localized name and pending value are available")
 ui.localization.set_locale("zh_CN")

static func inspect(t, id: String) -> String:
 var button=t.ui.find_child("Status_"+id.validate_node_name(),true,false)
 if button==null: t.check(false,"STATUS inspect target exists: "+id);return ""
 var parent=button.get_parent()
 while parent!=null and not parent is ScrollContainer: parent=parent.get_parent()
 if parent!=null: parent.ensure_control_visible(button);await t.frames()
 await Navigation.press(t,button.name)
 return t.visible_text(t.ui.find_child("StatusDetail",true,false))

static func run(t) -> void:
 await preload("res://tests/lewd_relic_ui_cases.gd").run(t)
 await lucidity_necklace(t)
 await preload("res://tests/edging_seal_ui_cases.gd").run(t)
 await pleasure_extractor(t)
 await preload("res://tests/scrap_robot_ui_cases.gd").run(t)
 await preload("res://tests/first_turn_control_ui_cases.gd").run(t)
 await preload("res://tests/sundial_ui_cases.gd").run(t)
 await preload("res://tests/great_wand_ui_cases.gd").run(t)
 var ui=t.ui
 ui.restart(42);await t.frames()
 var before=JSON.stringify(ui.game.state)
 t.check(not t.visible_text(ui.layout).contains("上身束缚等级") and ui.find_child("OpenPressure",true,false)==null,"STATUS duplicated character/environment/pressure labels removed from battlefield")
 await Navigation.press(t,"OpenStatus")
 t.check(ui.find_child("Status_arms",true,false)!=null and ui.find_child("Status_legs",true,false)!=null,"STATUS real top button opens body levels even when zero")
 t.check(JSON.stringify(ui.game.state)==before,"STATUS opening is read-only")
 t.check(ui.find_child("StatusFilter_relic",true,false)==null and ui.view.statuses.all(func(e):return e.category!="relic"),"STATUS relics no longer duplicate their own interface")
 await t.capture("ui-74-status-overview.png")
 await Navigation.press(t,"StatusFilter_benefit")
 t.check(ui.find_child("Status_against_wall",true,false)!=null and t.visible_text(ui.layout).contains("贴墙"),"STATUS contact buff appears in benefit group")
 await Navigation.press(t,"CloseDrawer")
 ui.game.state.charge=2;ui.game.state.temporary_mana=5;ui.game.state.next_energy=1
 ui.render();await t.frames()
 t.check(ui.find_child("MainManaValue",true,false).text.contains("临时5"),"TEMP UI shows temporary pool alongside permanent mana")
 await Navigation.press(t,"OpenStatus")
 t.check((await inspect(t,"temporary_mana")).contains("整备结束最多保留20点"),"TEMP UI selected status explains independent point balance and lifetime")
 t.check(ui.find_child("Status_charge",true,false)!=null and ui.find_child("Status_temporary_mana",true,false)!=null,"STATUS stacked buffs appear using current projection")
 var grid=ui.find_child("StatusGrid",true,false)
 var scroll=grid.get_parent().get_parent()
 t.check(grid.get_children().all(func(tile):return scroll.get_global_rect().encloses(tile.get_global_rect())),"STATUS single-row overview keeps the entire card and value visible")
 await t.capture("ui-status-icons-overview.png")
 await Navigation.press(t,"OpenItems")
 t.check(ui.show_items and not ui.show_pressure,"STATUS uses existing mutually exclusive panel navigation")
 await t.start_practice("Practice_pressure")
 await Navigation.press(t,"OpenStatus");await Navigation.press(t,"StatusFilter_pressure")
 var source=ui.view.statuses.filter(func(e):return e.id.begins_with("pressure_"))[0]
 var description=await inspect(t,source.id)
 t.check(description.contains("身体与训练垫的摩擦") and description.contains("持续"),"STATUS pleasure effects show source and lifetime on selection")
 var old=ui.view.pressure.value
 t.check(await t.click("calm") and ui.view.pressure.value<old and ui.find_child("Status_pressure",true,false)!=null,"STATUS calm action updates panel through formal command")
 await t.capture("ui-76-status-pressure.png")

 await t.start_practice("Practice_pressure_battle")
 var breath=ui.find_child("DeepBreath",true,false)
 t.check(breath!=null and breath.find_child("BasicAttackTitle",true,false).text.begins_with("深呼吸") and not ui.show_pressure,"STATUS deep breath is available without opening status")
 for type in ["strike","heavy","kick","fireball"]:
  var attack=ui.find_child("BasicAttack_"+type,true,false)
  t.check(attack.get_global_rect().end.x<=breath.get_global_rect().position.x and is_equal_approx(attack.position.y,breath.position.y),"STATUS deep breath sits right of each attack on same row")
 ui.game.state.pressure=70;ui.render();await t.frames()
 var energy=ui.view.energy;var mana=ui.view.mana
 await Navigation.press(t,"DeepBreath")
 t.check(ui.view.pressure.value==50 and ui.view.energy==energy-1 and ui.view.mana==mana,"STATUS native deep breath reduces pressure and spends only one energy")
 await Navigation.press(t,"DeepBreath")
 t.check(ui.find_child("DeepBreath",true,false).disabled and ui.find_child("DeepBreathDetail",true,false).text.contains("已使用2次"),"STATUS second use shows the per-turn limit on the disabled action")
 await t.capture("ui-116-deep-breath-action.png")
 ui.game.state.pressure=0;ui.game.state.calm_uses=0;ui.render();await t.frames()
 t.check(ui.find_child("DeepBreath",true,false).disabled and ui.find_child("DeepBreathDetail",true,false).text.contains("当前快感已经降到最低"),"STATUS zero pleasure reason is visible beside disabled action")
 await icons(t)
 await charge_toggle(t)

static func charge_toggle(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._gain_charge(7);preload("res://tests/charge_cases.gd").unlock_single(ui.game);ui.game.state.temporary_mana=35.0;ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 var button=ui.find_child("StatusIcon_charge",true,false)
 var point=button.get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(ui.game.state.charge_all and ui.game.state.charge==7 and not ui.show_pressure,"CHARGE UI native right-click arms all stacks without opening the status drawer")
 var after=ui.game.export_snapshot()
 for key in ["version","logs","summary","charge_all"]: before.erase(key);after.erase(key)
 var changed=before.keys().filter(func(key):return before[key]!=after.get(key))
 t.check(before==after,"CHARGE UI mode switch spends no turn, energy, mana or stacks; changed: "+str(changed))
 button=ui.find_child("StatusIcon_charge",true,false)
 var icon=button.get_children().filter(func(child):return child.get_script()==preload("res://ui/status_icon.gd"))[0]
 t.check(icon.status.emphasized and icon.badge.text=="7","CHARGE UI all-stack mode visibly highlights the icon and retains its count")
 await t.move_mouse(Vector2(1500,700));await t.move_mouse(button.get_global_rect().get_center())
 var text=t.visible_text(ui.find_child("TermExplanation",true,false))
 t.check(text.contains("全量蓄力") and text.contains("21") and text.contains("整备结束最多保留2层"),"SHELL UI without relic explains the two-stack retention cap")
 ui.game.RelicEffects.gain(ui.game,"turtle_shell");ui.render();await t.frames()
 button=ui.find_child("StatusIcon_charge",true,false)
 await t.move_mouse(Vector2(1500,700));await t.move_mouse(button.get_global_rect().get_center())
 text=t.visible_text(ui.find_child("TermExplanation",true,false))
 t.check(text.contains("整备结束最多保留4层"),"SHELL UI gaining relic updates charge lifetime without changing stack counts")
 var row=ui.view.relics.filter(func(r):return r.id=="turtle_shell")[0]
 t.check(row.rarity=="rare" and row.current.contains("4层") and row.current.contains("30点临时魔力") and preload("res://ui/relic_icon.gd").ART.has("turtle_shell"),"SHELL UI shared relic strip has rare metadata, actual retained count and dedicated art")
 await t.capture("ui-charge-all.png")
 await Navigation.press(t,"StatusIcon_charge")
 t.check(ui.show_pressure and ui.find_child("Status_charge",true,false)!=null,"CHARGE UI left-click still opens status details")
 point=ui.find_child("Status_charge",true,false).get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(not ui.game.state.charge_all and ui.game.state.charge==7 and ui.show_pressure,"CHARGE UI detail card right-click restores ordinary mode without closing details")

static func icons(t) -> void:
 var ui=t.ui
 await t.start_practice("Practice_trader_solo")
 ui.game.state.charge=3;ui.game.state.temporary_mana=15
 ui.game.state.card_buffs=["embers_free"];ui.game.Cards.grant_buff(ui.game,"echo_cast_free")
 ui.game.state.relics.append("break_bracer")
 for id in ["wrist_bracer","wraith_ribbon","ethereal_pendant","intellect_cloak"]: ui.game.RelicEffects.gain(ui.game,id)
 ui.game.state.relic_used["break_bracer:turn"]=ui.game.state.tick
 var enemy=ui.game.state.enemies[0];enemy.ready_layers=2
 ui.render();await t.frames()
 await t.move_mouse(Vector2(782,140));await t.mouse_button(Vector2(782,140),MOUSE_BUTTON_LEFT,true);await t.mouse_button(Vector2(782,140),MOUSE_BUTTON_LEFT,false)
 var before=ui.game.state.duplicate(true)
 var hero=ui.find_child("StatusStrip_hero",true,false)
 var enemy_strip=ui.find_child("StatusStrip_"+enemy.id,true,false)
 var portrait=ui.find_child("HeroArt",true,false)
 t.check(hero.get_global_rect().end.x<=portrait.get_global_rect().position.x and hero.get_child(0) is VBoxContainer and hero.vertical_scroll_mode==ScrollContainer.SCROLL_MODE_AUTO and hero.horizontal_scroll_mode==ScrollContainer.SCROLL_MODE_DISABLED,"STATUS hero effects form a scrollable vertical column to the left of the enlarged portrait")
 t.check(hero!=null and enemy_strip!=null and hero.find_child("StatusIcon_ready_*",true,false)==null,"STATUS hero and enemy icons stay with their actual owner")
 t.check(Rect2(0,0,1600,900).encloses(hero.get_global_rect()) and enemy_strip.get_global_rect().end.y<=ui.find_child("BasicAttack_strike",true,false).get_global_rect().position.y,"STATUS strips stay in the viewport and above the action bar")
 var charge=ui.find_child("StatusIcon_charge",true,false)
 t.check(charge!=null and charge.find_child("StatusCount",true,false).text=="3","STATUS icon counter reads actual charge layers")
 await t.move_mouse(charge.get_global_rect().get_center());await t.frames()
 t.check(ui.term_popup!=null and t.visible_text(ui.term_popup).contains("整备结束最多保留2层"),"STATUS hovering the compact icon shows the default lifetime without turtle shell")
 await Navigation.press(t,"StatusIcon_charge")
 t.check(ui.show_pressure and ui.selected_status=="charge" and t.visible_text(ui.find_child("StatusDetail",true,false)).contains("3层"),"STATUS compact icon opens its current details")
 t.check(ui.game.state==before,"STATUS hover and selection do not change state or random streams")
 await Navigation.press(t,"CloseDrawer")
 var relic=ui.find_child("RelicShortcut_break_bracer",true,false)
 await t.move_mouse(relic.get_global_rect().get_center());await t.frames()
 t.check(ui.term_popup!=null and t.visible_text(ui.term_popup).contains("本次机会已使用"),"STATUS relic hover includes its own spent trigger")
 await t.move_mouse(Vector2(1550,60));await t.frames()
 await t.capture("ui-status-icons-battle.png")
 for pair in [["wrist_bracer","手腕被拘束时，力量＋2。"],["wraith_ribbon","灵巧＋1。"],["ethereal_pendant","每个整备回合结束时，恢复1魔力。"],["intellect_cloak","魔法牌的固定耗魔每件－1，最低为0。"]]:
  relic=ui.find_child("RelicShortcut_"+pair[0],true,false)
  t.check(relic!=null and preload("res://ui/relic_icon.gd").ART.has(pair[0]),"WRIST/RIBBON UI shows a dedicated relic icon: "+pair[0])
  if relic==null: continue
  await t.move_mouse(relic.get_global_rect().get_center());await t.frames()
  t.check(ui.term_popup!=null and t.visible_text(ui.term_popup).contains(pair[1]),"WRIST/RIBBON UI hover shows the final rule: "+pair[0])
