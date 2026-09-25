extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func open_pressure(t) -> void:
 if not t.ui.show_pressure: await Navigation.press(t,"OpenStatus")
 if t.ui.show_pressure:
  await Navigation.press(t,"StatusFilter_pressure")

static func calm_detail(t) -> String:
 await t.close_information()
 var before=t.ui.game.export_snapshot()
 var button=t.ui.find_child("DeepBreath",true,false)
 t.check(button!=null and button.is_visible_in_tree(),"CALM UI hover action is visible")
 if button==null: return ""
 await t.move_mouse(Vector2(650,60));await t.frames()
 await t.move_mouse(button.get_global_rect().get_center());await t.frames()
 var popup=t.ui.term_popup
 t.check(is_instance_valid(popup) and popup.is_visible_in_tree() and t.ui.game.state==before,"CALM UI real hover opens read-only action detail")
 return t.visible_text(popup) if is_instance_valid(popup) else ""

static func run(t) -> void:
 await forced_loop_surrender(t)
 await climax_card_practice(t)
 t.ui.restart(42);t.ui.game.state.pressure=10
 for enemy in t.ui.game.state.enemies: enemy.intent.delayed=true
 t.ui.render();await t.frames();await open_pressure(t)
 var free_text=await preload("res://tests/status_ui_cases.gd").inspect(t,"pressure")
 t.check(free_text.contains("每回合结束快感降低2点"),"FREE COOLING UI explains exact condition and reduction")
 await t.close_information()
 t.check(await t.click("end") and t.ui.view.pressure.value==8,"FREE COOLING UI real end button updates visible pressure")
 var ui=t.ui
 ui.restart(42);ui.game.state.pressure=90
 var mouth=ui.game._install_template("mouth_band","mouth",12.8,16,false,"fixture",2)
 ui.render();await t.frames()
 var calm_text=await calm_detail(t)
 t.check(ui.find_child("DeepBreathDetail",true,false).text.contains("快感－8") and calm_text.contains("快感－8") and calm_text.contains("下回合能量＋1"),"CALM UI shows attenuated relief with unchanged deferred energy")
 t.check(await t.click("calm") and ui.game.state.pressure==82 and ui.game.state.next_energy==1 and ui.view.energy==2,"CALM UI actual click matches the mouth-attenuated preview")
 ui.game._apply_manual_release(ui.game._equipment(mouth.id),0.0)
 ui.game._cleanup()
 var blocked_mouth=ui.game._install_template("mouth_band","mouth",20,20,false,"fixture",3)
 t.check(not blocked_mouth.is_empty() and ui.game.validate()=="","CALM UI installs a valid fully restrictive mouth fixture after cleanup")
 ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 t.check(ui.find_child("DeepBreathDetail",true,false).text.contains("高级、紧度3档") and not await t.click("calm") and ui.game.state==before,"CALM UI fully blocked mouth shows reason and cannot spend or grant energy")
 await t.start_practice("Practice_special_equipment")
 await open_pressure(t)
 var equipment_detail=await preload("res://tests/status_ui_cases.gd").inspect(t,"equipment_stimulation")
 t.check(equipment_detail.contains("中级无线乳夹跳蛋") and equipment_detail.contains("电量剩余8回合"),"SOURCE merged equipment status preserves every source and remaining battery")
 t.check(await t.click("end") and ui.view.pressure.value==16,"SOURCE player round start applies the single powered source once; energy-only equipment does not pulse")
 await t.capture("ui-60-formal-pressure.png")
 await t.start_practice("Practice_guard")
 for turn in range(4):
  t.check(await t.click("end") and ui.view.pressure.value==0 and ui.view.pressure.sources.is_empty(),"SOURCE guard UI rounds have no charge pressure")
 await t.capture("ui-117-guard-no-charge.png")
 await t.start_practice("Practice_pressure")
 t.check(ui.view.practice_kind=="pressure" and ui.view.pressure.value==70,"PRESSURE actual menu initializes pressure and source conditions")
 await open_pressure(t)
 var pressure_text=await preload("res://tests/status_ui_cases.gd").inspect(t,"pressure")
 for row in ui.view.statuses.filter(func(entry):return entry.id.begins_with("pressure_")):
  pressure_text+="\n"+await preload("res://tests/status_ui_cases.gd").inspect(t,row.id)
 t.check(pressure_text.contains("身体与训练垫的摩擦") and pressure_text.contains("回合结束") and pressure_text.contains("损失20魔力"),"PRESSURE drawer explains both source timings and resource effect: "+pressure_text)
 calm_text=await calm_detail(t)
 t.check(calm_text.contains("下回合能量＋1"),"CALM UI action description exposes the deferred reward")
 t.check(await t.click("calm") and ui.view.pressure.value==50 and ui.view.energy==2 and ui.game.state.next_energy==1 and ui.view.mana==100,"PRESSURE visible calm button pays current energy and reserves next-turn energy")
 await open_pressure(t)
 await Navigation.press(t,"StatusFilter_benefit")
 var reserve_text=await preload("res://tests/status_ui_cases.gd").inspect(t,"next_energy")
 t.check(reserve_text.contains("深呼吸") and reserve_text.contains("下一玩家回合"),"CALM UI shared reserve status explains its source and timing")
 await t.close_information()
 t.check(await t.click("end") and ui.view.energy==4 and ui.game.state.next_energy==0,"CALM UI actual end-turn consumes the reserve on the next turn")
 await t.capture("ui-31-pressure-sources.png")

 await t.start_practice("Practice_pressure")
 var belt=ui.game.equipment_at("wrist")[0].id
 for i in range(2):
  var uid=ui.view.hand.filter(func(c):return c.type=="strain")[0].uid
  var c=Queries.find(ui.view,"card",{"uid":uid,"slot":"wrist","target":belt})
  t.check(c.risk.contains("20快感"),"PRESSURE strain preview reveals its source risk")
  await t.start_drag(uid,"wrist")
  await t.release_target(await t.reveal_drop_target(c.key))
 t.check(ui.view.pressure.overloaded and ui.view.pressure.value==10 and ui.view.mana==80 and ui.view.energy==0 and not ui.show_pressure,"PRESSURE second native card drag triggers interruption without opening the character-status drawer")
 t.check(ui.find_child("StatusDetail",true,false)==null,"PRESSURE climax presentation is not covered by a status detail window")
 var climax_panel=ui.find_child("ClimaxNarration",true,false)
 var climax_speech=ui.find_child("HeroSpeech",true,false)
 t.check(climax_panel!=null and t.visible_text(climax_panel).contains("你的腰腹") and not t.visible_text(climax_panel).contains("她的"),"PRESSURE second-person climax narration replaces the hand area")
 t.check(climax_speech!=null and ui.view.speech.cue=="hero.climax.normal.clear" and t.visible_text(climax_speech).contains("要射了"),"PRESSURE climax dialogue stays in the existing character speech bubble")
 var turn_actions=ui.view.display_facts.filter(func(c):return c.payload.kind not in ["flask","item_discard"])
 t.check(turn_actions.size()==1 and turn_actions[0].payload.kind=="end" and t.visible_text(ui.layout).contains("继续 · 高潮后缓一缓"),"PRESSURE interrupted UI only retains its visible continue action alongside the established flask controls")
 t.check(not t.visible_text(ui.layout).contains("可以继续固定行动"),"PRESSURE empty hand text does not invite forbidden actions")
 await t.capture("ui-32-overload.png")
 t.check(await t.click("end") and ui.view.energy==2 and ui.view.rest_left==5 and ui.view.pressure.value==35,"PRESSURE continue finishes exactly one rest turn and consumes penalty once")

 await t.start_practice("Practice_pressure_battle")
 t.check(ui.view.phase=="battle" and ui.view.enemies.all(func(e):return e.intent_icons.any(func(icon):return icon.kind=="debuff")),"PRESSURE battle intent displays actual extra enemy effect")
 await t.capture("ui-33-enemy-pressure.png")
 t.check(await t.click("end") and ui.view.energy==2 and ui.view.mana==80 and ui.view.pressure.value==98,"PRESSURE free cooling prevents a second overload before both enemy actions")
 var guard=0
 while ui.view.phase=="battle" and guard<8:
  t.check(await t.click("end"),"PRESSURE real battle proceeds without forced-turn deadlock")
  guard+=1
 t.check(ui.view.phase=="reward" and ui.view.pressure.energy_penalty>0 and not ui.view.pressure.overloaded,"PRESSURE reward retains next-turn penalty without blocking reward UI")
 var penalty=ui.view.pressure.energy_penalty
 var remaining=ui.view.pressure.value
 t.check(await t.click("reward",{"type":"skip"}) and ui.view.phase=="prepare" and ui.view.energy==maxi(0,3-penalty) and ui.view.pressure.energy_penalty==0 and ui.view.pressure.value==remaining,"PRESSURE preparation UI consumes carried next-turn penalty once")

static func climax_card_practice(t) -> void:
 var ui=t.ui
 await t.start_practice("Practice_climax_card")
 t.check(ui.view.practice_kind=="climax_card" and ui.view.phase=="battle" and ui.view.pressure.value==99,"CLIMAX PRACTICE UI opens the named 99-pressure battle")
 t.check(ui.view.body_groups.any(func(region):return region.special and region.equipment.any(func(item):return item.name.contains("马眼棒"))),"CLIMAX PRACTICE UI projects the equipped ordinary special item")
 var rod=ui.game.state.special_equipment.filter(func(item):return item.type=="urethral_rod_low")[0]
 var rod_before=rod.durability
 var card=ui.view.hand.filter(func(entry):return entry.type=="strain")[-1]
 var button=ui.card_buttons.get(card.uid)
 t.check(button!=null and t.visible_text(button).contains("用力！") and button.get_node("CardCost").text=="1","CLIMAX PRACTICE UI uses the ordinary paid opening card")
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 await t.frames()
 var panel=ui.find_child("ClimaxNarration",true,false)
 t.check(ui.view.pressure.overloaded and panel!=null and panel.is_visible_in_tree() and t.visible_text(panel).contains("高潮"),"CLIMAX PRACTICE native card click opens the formal climax presentation")
 t.check(is_equal_approx(ui.game._equipment(rod.id).durability,rod_before-3) and ui.game.state.logs.any(func(log):return log.data.has("climax_slip") and log.data.climax_slip.damage==3),"CLIMAX PRACTICE visible paid card applies the urethral rod's current fixed slip damage")
 t.check(ui.view.hand.is_empty() and ui.view.energy==0 and ui.view.pressure.energy_penalty==1,"CLIMAX PRACTICE overlay reflects ordinary discard and weakness")
 await t.capture("ui-climax-card-practice.png")


static func forced_loop_surrender(t) -> void:
 var ui=t.ui
 ui.restart(3440322309)
 ui.game=preload("res://tests/pressure_cases.gd").forced_loop_fixture()
 ui.render();await t.frames()
 var button=ui.find_child("SurrenderButton",true,false)
 t.check(ui.view.pressure.overloaded and button!=null and button.is_visible_in_tree(),"FEEDBACK UI forced-loop state still exposes surrender")
 if button==null: return
 var before=ui.game.export_snapshot()
 await Navigation.press(t,"SurrenderButton")
 t.check(ui.game.state==before and t.visible_text(ui.find_child("SurrenderButton",true,false)).contains("确定"),"FEEDBACK UI interrupted surrender still needs confirmation")
 await Navigation.press(t,"SurrenderButton")
 t.check(ui.game.state.phase=="captured" and ui.game.state.security==1 and ui.find_child("PrisonIntakePanel",true,false)!=null and ui.game.validate()=="","FEEDBACK UI confirmed surrender leaves the forced-loop battle for the intake page")
