extends RefCounted
const Cases=preload("res://tests/event_cases.gd")
const Catalog=preload("res://core/content_catalog.gd")
const Flow=preload("res://tests/event_flow_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func battle_preparation(t) -> void:
 await t.start_practice("Practice_floating_belt_cluster")
 var ui=t.ui
 t.check(await t.click("event",{"action":"choose","choice":"fight"}),"EVENT UI chooses authored encounter through actual option")
 for enemy in ui.game.state.enemies: enemy.hp=1.0
 ui.render();await t.frames()
 var point=ui.find_child("BasicAttack_kick",true,false).get_global_rect().get_center()
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(await t.click("attack",{"type":"kick","form":1}) and ui.view.phase=="event","EVENT UI winning combat action returns to authored result")
 var leave=Queries.find(ui.view,"event",{"action":"leave"})
 t.check(ui.candidate_buttons[leave.key].text=="开始整备" and t.visible_text(ui.layout).contains("3回合"),"EVENT UI victory offers preparation with clear duration")
 await press(t,ui.candidate_buttons[leave.key])
 t.check(ui.view.phase=="prepare" and ui.view.prepare_left==3 and not ui.view.hand.is_empty() and ui.find_child("EndTurnButton",true,false)!=null,"EVENT UI result button opens normal playable preparation with hand and end-turn control")
 t.check(await t.click("finish_prepare") and ui.view.phase=="cleared","EVENT UI shared early finish completes event practice")

static func arrive(t, id: String, seed_value: int=42) -> void:
 t.ui.restart(seed_value)
 Cases.arrive(t.ui.game,id)
 t.ui.render();await t.frames()

static func press(t, node: Control) -> void:
 var point=node.get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)

static func open_selection(t, id: String) -> void:
 var next=t.ui.find_child("EventContinue",true,false)
 if next!=null: await press(t,next)
 if id=="reward":
  var reward=t.ui.find_child("Reward_card",true,false)
  t.check(reward!=null,"EVENT UI reward uses the common reward popup")
  if reward!=null: await press(t,reward)
  t.check(t.ui.show_reward_cards and t.ui.find_child("RewardSkip_card",true,false)!=null,"EVENT UI common card choices include skip")
  return
 var opener=t.ui.find_child("EventOpen_"+id,true,false)
 t.check(opener!=null,"EVENT UI compact selector entry exists: "+id)
 if opener!=null: await press(t,opener)
 t.check(t.ui.show_event_selection and t.ui.find_child("EventSelectionGrid",true,false)!=null,"EVENT UI native click opens secondary selection")

static func event_button_count(ui) -> int:
 var ids=Queries.select(ui.view,"event").map(func(candidate):return Queries.fact_key(candidate))
 return ui.candidate_buttons.keys().filter(func(id):return id in ids).size()

static func run(t) -> void:
 await battle_preparation(t)
 var ui=t.ui
 ui.game=preload("res://core/game.gd").new(42)
 var target=ui.game.state.rooms.filter(func(room):return room.kind=="event")[0]
 preload("res://tests/event_draw_cases.gd").before_room(ui.game,target.id)
 ui.render();await t.frames()
 t.check(not target.has("event") and ui.game.room_description(target)=="抵达后发现事件。","EVENT UI unvisited room reveals no selected event")
 t.check(await t.click("depart",{"room":target.id}) and not target.has("event"),"EVENT UI departure keeps event unknown")
 while ui.game.state.phase=="travel":
  if not await t.click("travel_step"): break
 t.check(ui.view.phase=="event" and ui.view.room_event.id in ui.game.state.event_seen,"EVENT UI arrival opens selected event through normal movement")
 await arrive(t,"binding_cleric")
 var cleric_portrait=ui.find_child("EventPortrait",true,false) as TextureRect
 t.check(ui.view.room_event.id=="binding_cleric" and cleric_portrait!=null and cleric_portrait.texture!=null and cleric_portrait.texture.resource_path=="res://assets/art/event-binding-cleric-v1.png" and cleric_portrait.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"EVENT UI cleric displays its authored illustration at original aspect ratio")
 var text=t.visible_text(ui.layout)
 t.check(text.contains("缚疗修女") and text.contains("祈福") and text.contains("净化") and text.contains("道谢后继续前进"),"EVENT UI current event discloses its complete choices")
 var before=JSON.stringify(ui.game.state)
 ui.show_route=true;ui.render();await t.frames()
 t.check(ui.view.route.any(func(r):return r.icon=="event") and JSON.stringify(ui.game.state)==before,"EVENT UI map view during event changes no frozen outcomes")
 ui.show_route=false;ui.render();await t.frames()
 t.check(await t.click("event",{"action":"choose","choice":"leave_free"}) and ui.view.room_event.stage=="result","EVENT UI authored free exit reaches the ordinary result page")
 t.check(await t.click("event",{"action":"leave"}) and ui.view.phase=="map","EVENT UI leaves without preparation")

 await t.start_practice("Practice_succubus_magic_pawnshop")
 text=t.visible_text(ui.layout)
 t.check(ui.view.room_event.id=="succubus_magic_pawnshop" and Queries.select(ui.view,"event").size()==3 and text.contains("小额交易") and text.contains("大额交易") and text.contains("再加点料") and not text.contains("支付费用，离开"),"EVENT UI pawnshop presents exactly three mandatory trades")
 t.check(await t.click("event",{"action":"choose","choice":"extra_spice"}) and ui.view.room_event.stage=="reward","EVENT UI pawnshop extra trade commits and opens the rare reward")
 t.check(ui.view.room_event.report.contains("中级无线乳夹跳蛋") and ui.view.room_event.report.contains("中级无线后庭跳蛋") and ui.find_child("EventContinue",true,false)!=null,"EVENT UI pawnshop result displays both exact wear texts before reward selection")
 var reward_before=ui.game.export_snapshot()
 await open_selection(t,"reward")
 t.check(ui.find_child("BattleRewards",true,false)!=null and ui.find_child("EventPanel",true,false)==null,"EVENT UI standalone card payout uses battle-style rewards after its result is read")
 await press(t,ui.find_child("RewardSkip_card",true,false))
 t.check(ui.view.room_event.stage=="result" and ui.game.state.deck==reward_before.deck and ui.game.state.equipment==reward_before.equipment and ui.game.state.mana==reward_before.mana,"EVENT UI skipping cards keeps already committed option costs and equipment")

 ui.restart(64)
 ui.game._install_special("anal_egg_low","special_3_b")
 Cases.arrive(ui.game,"succubus_magic_pawnshop");ui.render();await t.frames()
 text=t.visible_text(ui.layout)
 t.check(Queries.select(ui.view,"event").size()==2 and text.contains("小额交易") and text.contains("大额交易") and not text.contains("再加点料") and not text.contains("支付费用，离开"),"EVENT UI occupied fixed slot hides only the extra trade without restoring an exit")

 await t.start_practice("Practice_smuggled_mana_potions")
 text=t.visible_text(ui.layout)
 t.check(ui.view.room_event.id=="smuggled_mana_potions" and Queries.select(ui.view,"event").size()==2 and text.contains("偷渡商人的魔药箱") and text.contains("嘘，小声点。我可是偷偷溜进来做生意的。") and text.contains("魔瓶魔力＋90"),"EVENT UI smuggler presents the confirmed introduction and two compact decisions")
 var flask_before=ui.game.state.flask_mana
 var deposits_before=ui.game.state.flask_deposits
 t.check(await t.click("event",{"action":"choose","choice":"credit"}) and ui.view.room_event.stage=="result" and ui.game.state.flask_mana==flask_before+90 and ui.game.state.flask_deposits==deposits_before,"EVENT UI smuggler credit commits the direct flask reward without using a deposit")
 t.check(ui.find_child("EventResultBanner",true,false).get_meta("result_status")=="success" and ui.view.room_event.report.contains("敏感"),"EVENT UI smuggler shows a prominent successful result and the curse consequence")

 await t.start_practice("Practice_floating_belt_cluster")
 text=t.visible_text(ui.layout)
 t.check(ui.view.room_event.id=="floating_belt_cluster" and Queries.select(ui.view,"event").size()==2 and text.contains("硬闯") and text.contains("接受灌注") and text.contains("恢复25魔力"),"EVENT UI floating belts present two compact authored decisions")
 ui.game.state.mana=50;ui.render();await t.frames()
 t.check(await t.click("event",{"action":"choose","choice":"infusion"}) and ui.view.room_event.stage=="result" and ui.game.state.mana==75 and ui.game.state.deck.any(func(card):return card.type=="lewd_mark"),"EVENT UI infusion restores personal mana and grants Lewd Mark")
 t.check(ui.view.room_event.report.contains("绕住肉棒根部") and ui.find_child("EventResultBanner",true,false).get_meta("result_status")=="neutral","EVENT UI infusion shows the confirmed scene through the shared result page")

 await t.start_practice("Practice_floating_belt_cluster")
 t.check(await t.click("event",{"action":"choose","choice":"fight"}) and ui.view.phase=="battle" and ui.game.state.room_event.stage=="battle","EVENT UI event fight changes to the ordinary battle screen through one formal choice")
 t.check(ui.view.enemies.size()==3 and ui.view.enemies.all(func(enemy):return enemy.type=="belt"),"EVENT UI event fight displays exactly three real floating belts")

 await t.start_practice("Practice_alchemist_tasting_stall")
 text=t.visible_text(ui.layout)
 t.check(ui.view.room_event.id=="alchemist_tasting_stall" and text.contains("魔力补剂") and text.contains("解缚溶剂") and text.contains("魅魔特调") and not text.contains("香蕉") and not text.contains("甜甜圈") and not text.contains("盒子"),"EVENT UI alchemist replaces all three source props with setting-appropriate potions")
 t.check(Queries.select(ui.view,"event").size()==3 and not text.contains("支付费用，离开"),"EVENT UI alchemist presents exactly its three authored choices")
 ui.game.state.mana=50;ui.render();await t.frames()
 t.check(await t.click("event",{"action":"choose","choice":"mana_tonic"}) and ui.game.state.mana==75 and ui.find_child("EventResultBanner",true,false).get_meta("result_status")=="success","EVENT UI mana tonic restores twenty-five personal mana and shows a clear success result")

 await t.start_practice("Practice_alchemist_tasting_stall")
 await open_selection(t,"dissolve")
 var tasting_grid=ui.find_child("EventSelectionGrid",true,false)
 t.check(tasting_grid.get_child_count()==1,"EVENT UI solvent opens the shared restraint selection window")
 var tasting_candidate=ui.view.display_facts.filter(func(c):return c.payload.get("choice","").begins_with("dissolve__"))[0]
 await press(t,ui.candidate_buttons[tasting_candidate.key])
 t.check(ui.view.room_event.stage=="result" and ui.game.state.equipment.is_empty() and ui.find_child("EventResultBanner",true,false).get_meta("result_status")=="success","EVENT UI solvent removes the selected restraint through the formal event candidate")

 await t.start_practice("Practice_alchemist_tasting_stall")
 var relic_before=ui.game.state.relics.size()
 var sensitive_before=ui.game.state.deck.filter(func(card):return card.type=="sensitive").size()
 t.check(await t.click("event",{"action":"choose","choice":"succubus_mix"}) and ui.game.state.relics.size()==relic_before+1 and ui.game.state.deck.filter(func(card):return card.type=="sensitive").size()==sensitive_before+1,"EVENT UI succubus mix grants one relic and the Sensitive curse")
 t.check(ui.view.room_event.report.contains("粉色媚药") and ui.find_child("EventResultBanner",true,false).get_meta("result_status")=="success","EVENT UI succubus mix describes the aphrodisiac and clearly marks the completed result")

 await t.start_practice("Practice_abandoned_storeroom")
 text=t.visible_text(ui.layout)
 t.check(ui.view.room_event.id=="abandoned_storeroom" and text.contains("废弃储物室") and text.contains("随机药剂、随机卷轴和随机工具各一件") and Queries.select(ui.view,"event").size()==1,"EVENT UI storeroom begins with one concise search choice")
 t.check(await t.click("event",{"action":"choose","choice":"search"}) and ui.view.phase=="reward" and ui.view.reward_title=="找到的道具","EVENT UI storeroom search enters the shared reward screen with an event title")
 var reward_rows=ui.view.battle_rewards
 t.check(reward_rows.size()==3 and reward_rows.map(func(row):return row.id)==["potion","scroll","tool"] and reward_rows.all(func(row):return row.category=="item"),"EVENT UI storeroom shows one frozen row for each item category")
 t.check(ui.find_child("Reward_item_potion",true,false)!=null and ui.find_child("Reward_item_scroll",true,false)!=null and ui.find_child("Reward_item_tool",true,false)!=null and ui.find_child("Reward_card",true,false)==null and ui.find_child("Reward_relic",true,false)==null,"EVENT UI storeroom reuses reward rows without card or relic rewards")
 var scroll_row=ui.game.state.room_event.loot.filter(func(row):return row.id=="scroll")[0]
 t.check(await t.click("reward",{"category":"item","type":scroll_row.type,"reward_id":"scroll"}) and ui.game.state.room_event.loot.filter(func(row):return row.id=="scroll")[0].claimed,"EVENT UI direct item click claims only that frozen row")
 t.check(await t.click("reward",{"type":"skip"}) and ui.view.phase=="cleared" and ui.view.phase not in ["prepare","pack"],"EVENT UI continue abandons remaining items and ends the practice without preparation or packing")

 await t.start_practice("Practice_bound_dream_guest_room")
 text=t.visible_text(ui.layout)
 t.check(ui.view.room_event.id=="bound_dream_guest_room" and text.contains("缚梦客房") and text.contains("恢复全部魔力") and text.contains("最大魔力－8") and Queries.select(ui.view,"event").size()==2,"EVENT UI guest room presents exactly its two compact trades")
 ui.game.state.mana=17;ui.render();await t.frames()
 var guest_equipment=ui.game.state.equipment.size()
 t.check(await t.click("event",{"action":"choose","choice":"sleep"}) and ui.game.state.mana==ui.game.state.mana_max and ui.game.state.equipment.size()==guest_equipment+3,"EVENT UI guest-room sleep restores all mana and applies all three restraints")
 t.check(ui.find_child("EventResultBanner",true,false).get_meta("result_status")=="success" and ui.view.room_event.report.contains("魔力恢复至"),"EVENT UI guest-room sleep shows a prominent result with final mana")

 await t.start_practice("Practice_bound_dream_guest_room")
 var guest_relics=ui.game.state.relics.size()
 t.check(await t.click("event",{"action":"choose","choice":"take_core"}) and ui.game.state.mana_max==92 and ui.game.state.mana==92 and ui.game.state.relics.size()==guest_relics+1,"EVENT UI bed-core trade lowers maximum mana, clamps current mana and grants its frozen relic")
 t.check(ui.view.room_event.report.contains("最大魔力永久降低8点") and ui.find_child("EventResultBanner",true,false).get_meta("result_status")=="success","EVENT UI bed-core result clearly reports the permanent cost")

 await t.start_practice("Practice_mysterious_woman_statue")
 var statue_lock=ui.game._install_special("negative_plate_lock_medium","special_2_a",2)
 ui.render();await t.frames()
 var blocked_sleeve=Queries.find(ui.view,"event",{"action":"choose","choice":"use_sleeve"})
 var blocked_button=ui.candidate_buttons.get(blocked_sleeve.key) as Button
 var blocked_reason="平板锁封住了肉棒，无法插进浅盘上的飞机杯。"
 var event_content=ui.find_child("EventContent",true,false)
 t.check(not statue_lock.is_empty() and not blocked_sleeve.valid and blocked_button!=null and blocked_button.disabled and not t.visible_text(event_content).contains(blocked_reason),"EVENT UI worn plate lock keeps the sleeve choice visible and disabled without an inline rule note")
 blocked_button.mouse_entered.emit();await t.frames()
 var explanation=ui.find_child("TermExplanation",true,false)
 t.check(explanation!=null and t.visible_text(explanation).contains(blocked_reason),"EVENT UI hovering the blocked sleeve choice opens the secondary explanation window")
 blocked_button.mouse_exited.emit();await t.frames()

 await t.start_practice("Practice_mysterious_woman_statue")
 text=t.visible_text(ui.layout)
 t.check(ui.view.room_event.id=="mysterious_woman_statue" and text.contains("神秘女人的雕像") and text.contains("浅盘") and text.contains("飞机杯") and Queries.select(ui.view,"event").size()==3,"EVENT UI statue presents the confirmed woman statue and three compact choices")
 t.check(not ui.view.room_event.intro.contains("翼魔") and not ui.view.room_event.intro.contains("魅魔圣像"),"EVENT UI statue does not restore the rejected creature identity")
 var statue_deck=ui.game.state.deck.size();var statue_climaxes=ui.game.state.overload_total
 t.check(await t.click("event",{"action":"choose","choice":"use_sleeve"}) and ui.view.room_event.stage=="remove_card" and ui.game.state.overload_total==statue_climaxes+1 and ui.game.state.deck.size()==statue_deck,"EVENT UI sleeve scene causes one climax before the shared removal stage")
 t.check(not ui.view.room_event.report.contains("卡组") and not ui.view.room_event.report.contains("卡牌") and ui.view.room_event.report.contains("飞机杯") and ui.find_child("EventContinue",true,false)!=null,"EVENT UI committed scene remains physical prose without diegetic card language")
 await open_selection(t,"remove")
 t.check(ui.find_child("EventSelectionGrid",true,false).get_child_count()==ui.view.deck_count,"EVENT UI statue removal reuses the shared physical-card modal")

 await t.start_practice("Practice_mysterious_woman_statue")
 var statue_collect=ui.game.state.room_event.options.filter(func(option):return option.id=="collect_mana")[0].effects[0].amount
 var statue_flask=ui.game.state.flask_mana
 t.check(await t.click("event",{"action":"choose","choice":"collect_mana"}) and ui.game.state.flask_mana==statue_flask+statue_collect and statue_collect>=30 and statue_collect<=60,"EVENT UI statue grants the exact frozen 30-to-60 flask mana")
 t.check(ui.view.room_event.report.contains(str(statue_collect)) and ui.find_child("EventResultBanner",true,false).get_meta("result_status")=="success","EVENT UI statue result clearly reports its exact random gain")

 await t.start_practice("Practice_maze_survey_team")
 text=t.visible_text(ui.layout)
 t.check(ui.view.room_event.id=="maze_survey_team" and text.contains("迷宫测绘队") and text.contains("独自探险") and text.contains("魔瓶魔力＋100") and text.contains("结伴而行") and text.contains("魔瓶魔力＋30") and Queries.select(ui.view,"event").size()==2,"EVENT UI survey team shows the two confirmed compact choices and flask rewards")
 var survey_portrait=ui.find_child("EventPortrait",true,false)
 t.check(survey_portrait!=null and survey_portrait.texture.resource_path=="res://assets/art/event-maze-survey-team-v1.png" and survey_portrait.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"EVENT UI survey team uses its authored illustration at full aspect")
 var survey_installs=ui.game.state.room_event.options.filter(func(option):return option.id=="solo")[0].effects.filter(func(effect):return effect.op=="install")
 var survey_flask=ui.game.state.flask_mana;var survey_equipment=ui.game.state.equipment.size()
 t.check(await t.click("event",{"action":"choose","choice":"solo"}) and ui.game.state.flask_mana==survey_flask+100 and ui.game.state.equipment.size()==survey_equipment+2,"EVENT UI solo exploration grants one hundred flask mana and both restraints")
 t.check(ui.find_child("EventResultBanner",true,false).get_meta("result_status")=="success" and survey_installs.all(func(effect):return ui.view.room_event.report.contains(ui.game.Equipment.wear_text(ui.game.Equipment.name_for(effect.template,effect.slot,effect.grade,effect.get("variant",0)),effect.slot,"animated"))) and not ui.view.room_event.report.contains("她把") and not ui.view.room_event.report.contains("她合拢"),"EVENT UI solo result clearly marks success with autonomous restraint prose")

 await t.start_practice("Practice_maze_survey_team")
 survey_flask=ui.game.state.flask_mana;survey_equipment=ui.game.state.equipment.size()
 t.check(await t.click("event",{"action":"choose","choice":"together"}) and ui.game.state.flask_mana==survey_flask+30 and ui.game.state.equipment.size()==survey_equipment,"EVENT UI travelling together grants thirty flask mana without restraints")

 await t.start_practice("Practice_binding_cleric")
 text=t.visible_text(ui.layout)
 t.check(ui.view.room_event.id=="binding_cleric" and text.contains("祈福") and text.contains("净化") and text.contains("道谢后继续前进") and not text.contains("支付费用，离开"),"EVENT UI cleric shows two services and its authored free exit")
 t.check(await t.click("event",{"action":"choose","choice":"purify"}) and ui.view.room_event.stage=="remove_card" and ui.find_child("EventContinue",true,false)!=null,"EVENT UI cleric purification presents its committed scene before card selection")
 await open_selection(t,"remove")
 t.check(ui.find_child("EventSelectionGrid",true,false).get_child_count()==ui.view.deck_count,"EVENT UI cleric removal uses the shared physical card modal")
 # The event card option is a real card face (docs/spec/card-terms.md「触发面」): hovering it must
 # show one box per term of the face it displays, next to the card and never over it.
 var event_face=ui.find_child("EventSelectionGrid",true,false).get_child(0).get_child(0)
 var event_uid=String(event_face.get_meta("physical_uid",""))
 var event_rows=ui.view.deck_cards.filter(func(row):return row.uid==event_uid)
 t.check(not event_rows.is_empty(),"EVENT UI card option tile maps to a real deck card: "+event_uid)
 if not event_rows.is_empty():
  var event_terms=preload("res://data/balance.gd").card_metadata(event_rows[0].type).face_keywords["free" if event_face.free_face else "bound"]
  t.check(not event_terms.is_empty(),"EVENT UI card option fixture carries face terms: "+event_rows[0].type)
  await t.move_mouse(event_face.get_global_rect().get_center());await t.frames()
  var event_popup=ui.find_child("TermExplanation",true,false)
  t.check(event_popup!=null and preload("res://tests/interface_ui_cases.gd").term_boxes(event_popup)==event_terms,"EVENT UI card option hover boxes equal the hovered face terms: "+str(preload("res://tests/interface_ui_cases.gd").term_boxes(event_popup)))
  var event_rect=event_popup.get_global_rect() if event_popup!=null else Rect2()
  t.check(event_popup!=null and not event_rect.intersects(event_face.get_global_rect()),"EVENT UI card option term boxes clear the anchor card")
  await t.move_mouse(Vector2(30,50));await t.frames()

 await t.start_practice("Practice_bound_adventurer_relic")
 text=t.visible_text(ui.layout)
 t.check(ui.view.room_event.id=="bound_adventurer_relic" and text.contains("拘束具堆里的微光") and text.contains("口球被头带紧紧勒住") and text.contains("25%成功") and text.contains("离开"),"EVENT UI bound adventurer opens through the shared compact event screen")
 t.check(Queries.select(ui.view,"event").size()==2 and ui.find_child("HeroSpeech",true,false)==null,"EVENT UI bound adventurer uses two event choices and no separate NPC dialogue interface")

 await t.start_practice("Practice_enchanters_empty_studio")
 text=t.visible_text(ui.layout)
 t.check(ui.view.room_event.id=="enchanters_empty_studio" and text.contains("回火") and text.contains("翻查") and text.contains("放下薄纱"),"EVENT UI empty studio exposes its three compact authored choices")
 var notes=ui.find_child("EventChoices",true,false).get_children().filter(func(node):return node is Label)
 t.check(notes.size()==1 and notes[0].text==Queries.select(ui.view,"event").filter(func(c):return c.payload.get("choice","")=="search")[0].detail,"EVENT UI only the additional reward and curse preview gets a note; empty details create no labels")
 before=JSON.stringify(ui.game.state)
 await open_selection(t,"temper")
 var grid=ui.find_child("EventSelectionGrid",true,false)
 var toggles=grid.find_children("EventToggle_*","",true,false).map(func(node):return node.name)
 t.check(grid.columns==3 and toggles.size()==2 and t.visible_text(ui.find_child("EventSelectionCount",true,false)).contains("0 / 2") and JSON.stringify(ui.game.state)==before,"EVENT UI two-restraint modal opens without committing and shows the required count")
 await press(t,ui.find_child(toggles[0],true,false))
 t.check(t.visible_text(ui.find_child("EventSelectionCount",true,false)).contains("1 / 2") and JSON.stringify(ui.game.state)==before,"EVENT UI first multi-selection is presentation-only")
 await press(t,ui.find_child(toggles[1],true,false))
 var confirm=ui.find_child("EventConfirmSelection",true,false)
 t.check(confirm!=null and not confirm.disabled and t.visible_text(ui.find_child("EventSelectionCount",true,false)).contains("2 / 2"),"EVENT UI exact multi-selection enables the shared confirm action")
 await press(t,confirm)
 t.check(ui.view.room_event.stage=="result" and ui.game.state.equipment.is_empty() and ui.find_child("EventResultBanner",true,false).get_meta("result_status")=="success","EVENT UI confirmed pair removes both restraints and opens a prominent success result")
 var leaving=Queries.select(ui.view,"event").filter(func(c):return c.payload.action=="leave")
 t.check(leaving.size()==1 and leaving[0].label=="离开" and leaving[0].detail=="" and ui.find_child("EventChoices",true,false).get_children().size()==1,"EVENT UI normal result has one short exit button without a duplicate caption")

 # The same event screen renders arbitrary authored stages; it does not know this
 # fixture's event id or branch names.
 var baseline=Catalog.tables(ui.game)
 var compiled=Catalog.compile(ui.game,[Flow.document()])
 t.check(compiled.ok,"EVENT UI staged content fixture compiles")
 if compiled.ok:
  Catalog.commit(ui.game,compiled.tables)
  ui.restart(17)
  var held=ui.game._install_special("shaft_ring_low","special_2_a").duplicate(true)
  Cases.arrive(ui.game,"flow_test");ui.render();await t.frames()
  text=t.visible_text(ui.layout)
  t.check(text.contains("第一阶段") and text.contains("暂存指定部位"),"EVENT UI reads the declared first stage and frozen option preview")
  t.check(await t.click("event",{"action":"choose","choice":"accept"}) and ui.view.room_event.stage=="penalty","EVENT UI advances an authored stage through the normal candidate")
  await press(t,ui.find_child("EventContinue",true,false))
  t.check(t.visible_text(ui.layout).contains("第二阶段") and t.visible_text(ui.layout).contains("随机安装两件初级绳索"),"EVENT UI renders the next stage without event-specific controls")
  t.check(await t.click("event",{"action":"choose","choice":"two_ropes"}) and ui.view.room_event.stage=="finale","EVENT UI executes a frozen batch effect")
  t.check(await t.click("event",{"action":"choose","choice":"finish"}) and ui.view.room_event.stage=="result","EVENT UI reaches the shared result screen")
  t.check(await t.click("event",{"action":"leave"}) and ui.game.state.special_equipment.size()==1 and ui.game.state.special_equipment[0]==held,"EVENT UI event cleanup restores the exact held equipment")
 Catalog.commit(ui.game,baseline)

 await t.start_practice("Practice_succubus_three_games")
 var portrait=ui.find_child("EventPortrait",true,false)
 t.check(ui.view.room_event.id=="succubus_three_games" and portrait!=null and portrait.texture.resource_path=="res://assets/art/event-fortune-teller-v1.png" and portrait.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"EVENT UI authored portrait uses stable event identity and preserves full aspect")
 await t.capture("ui-event-portrait.png")
 text=t.visible_text(ui.layout)
 t.check(ui.view.practice_kind=="succubus_three_games" and ui.view.phase=="event" and text.contains("第一局 · 押牌") and text.contains("陪姐姐玩三把"),"EVENT UI practice entry opens with the shipped scene and first-round copy")
 t.check(Queries.select(ui.view,"event").size()==11 and text.contains("胜率2/3") and text.contains("慌乱") and event_button_count(ui)==1,"EVENT UI ten card facts stay behind one compact selector plus refusal")
 var artwork=ui.find_child("EventArtwork",true,false).get_global_rect()
 var prose=ui.find_child("EventNarrativeScroll",true,false).get_global_rect()
 var choices=ui.find_child("EventChoices",true,false).get_global_rect()
 t.check(artwork.end.x<prose.position.x and prose.end.y<=choices.position.y and choices.end.y<=820,"EVENT UI illustration left, scrollable prose upper right, choices lower right stay inside frame")
 before=JSON.stringify(ui.game.state)
 await open_selection(t,"wager_card")
 grid=ui.find_child("EventSelectionGrid",true,false)
 t.check(grid.columns==6 and grid.get_child_count()==10 and JSON.stringify(ui.game.state)==before,"EVENT UI opens six-column physical card grid without changing game state")
 var ids=[]
 for tile in grid.get_children(): ids.append(tile.get_child(0).get_meta("physical_uid"))
 t.check(ids.size()==10 and ids.all(func(id):return ids.count(id)==1) and event_button_count(ui)==11,"EVENT UI duplicate card types retain independent physical choices")
 var face=grid.get_child(0).get_child(0)
 var point=face.get_global_rect().get_center()
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(JSON.stringify(ui.game.state)==before,"EVENT UI card face inspection does not commit selection")
 var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;t.root.push_input(escape,true);escape=escape.duplicate();escape.pressed=false;t.root.push_input(escape,true);await t.frames()
 t.check(not ui.show_event_selection and ui.find_child("InformationDrawer",true,false)==null and JSON.stringify(ui.game.state)==before,"EVENT UI Esc returns without payment, card changes or reroll")
 await open_selection(t,"wager_card")
 await t.close_information()
 t.check(JSON.stringify(ui.game.state)==before,"EVENT UI close button cancels without modifying state")
 await open_selection(t,"wager_card")
 var candidate=ui.view.display_facts.filter(func(c):return c.payload.get("choice","").begins_with("wager_card__"))[0]
 await press(t,ui.candidate_buttons[candidate.key])
 t.check(ui.view.room_event.stage=="after_round_one" and not ui.show_event_selection,"EVENT UI selecting an actual card commits once and returns to event")
 var result=ui.view.room_event.report
 var banner=ui.find_child("EventResultBanner",true,false)
 t.check(banner!=null and banner.get_meta("result_status")==ui.view.room_event.result_status and banner.get_rect().size.y>=70,"EVENT UI authored wager outcome gets a prominent fixed-height banner")
 var narrative=t.visible_text(ui.find_child("EventNarrative",true,false))
 t.check(narrative.contains(result) and not narrative.contains(ui.view.room_event.intro) and event_button_count(ui)==0 and ui.find_child("EventChoices",true,false).get_child_count()==1,"EVENT UI result-only page hides next prose and all rule choices")
 await t.capture("ui-event-result-page.png")
 before=JSON.stringify(ui.game.state)
 ui.render(ui.view);await t.frames()
 t.check(ui.find_child("EventContinue",true,false)!=null,"EVENT UI redraw does not silently acknowledge a result")
 await press(t,ui.find_child("EventContinue",true,false))
 narrative=t.visible_text(ui.find_child("EventNarrative",true,false))
 t.check(narrative.contains(ui.view.room_event.intro) and not narrative.contains(result) and JSON.stringify(ui.game.state)==before and not ui.candidate_buttons.is_empty(),"EVENT UI continue replaces result with next prose and choices without state or random changes")
 t.check(ui.find_child("EventResultBanner",true,false)==null,"EVENT UI next choice page does not retain previous success/failure banner")
 await t.capture("ui-event-next-page.png")
 ui.render(ui.view);await t.frames()
 t.check(ui.find_child("EventContinue",true,false)==null,"EVENT UI acknowledged result stays hidden across redraw")
 t.check(await t.click("event",{"action":"choose","choice":"continue"}) and ui.view.room_event.stage=="wager_restraint","EVENT UI next stage uses same generic presentation")
 t.check(not ui.view.room_event.report.contains(result),"EVENT UI later stages do not accumulate previous result prose")
 before=JSON.stringify(ui.game.state)
 await open_selection(t,"wager_restraint")
 grid=ui.find_child("EventSelectionGrid",true,false)
 t.check(grid.columns==3 and grid.get_child_count()==2 and grid.find_children("EquipmentLock_*","",true,false).any(func(icon):return icon.locked) and not t.visible_text(grid).contains("已上锁"),"EVENT UI equipment selection shows physical lock icons without status words")
 await t.close_information()
 t.check(JSON.stringify(ui.game.state)==before,"EVENT UI equipment cancellation changes no durability or random outcome")
 await open_selection(t,"wager_restraint")
 candidate=ui.view.display_facts.filter(func(c):return c.payload.get("choice","").begins_with("wager_restraint__"))[0]
 await press(t,ui.candidate_buttons[candidate.key])
 t.check(ui.view.room_event.stage in ["restraint_penalty","after_round_two"] and not ui.show_event_selection,"EVENT UI equipment choice submits the existing formal event candidate")

 # Simulate another successful commit while an older selection window is open.
 # Its actual button must still submit the captured version, never the new one.
 await t.start_practice("Practice_succubus_three_games")
 await open_selection(t,"wager_card")
 before=JSON.stringify(ui.game.state)
 var outside=Vector2(30,50)
 await t.mouse_button(outside,MOUSE_BUTTON_LEFT,true);await t.mouse_button(outside,MOUSE_BUTTON_LEFT,false)
 t.check(not ui.show_event_selection and JSON.stringify(ui.game.state)==before,"EVENT UI outside modal click only dismisses and does not pass through")
 await open_selection(t,"wager_card")
 candidate=ui.view.display_facts.filter(func(c):return c.payload.get("choice","").begins_with("wager_card__"))[0]
 var stale_button=ui.candidate_buttons[candidate.key]
 t.check(ui.game.dispatch(ui.game.command(candidate.payload,ui.view.version),ui.view.version).ok,"EVENT UI stale-window fixture advances through formal dispatch")
 before=JSON.stringify(ui.game.state)
 await press(t,stale_button)
 t.check(JSON.stringify(ui.game.state)==before and ui.notice!="" and not ui.show_event_selection,"EVENT UI stale choice is rejected without another payment, reward or random advance")

 # Regression for a player who enters round two with no restraint to select.
 await t.start_practice("Practice_succubus_three_games")
 ui.game.state.equipment.clear();ui.game.state.composites.clear();ui.game.state.links.clear();ui.render();await t.frames()
 await open_selection(t,"wager_card")
 candidate=ui.view.display_facts.filter(func(c):return c.payload.get("choice","").begins_with("wager_card__"))[0]
 await press(t,ui.candidate_buttons[candidate.key])
 t.check(await t.click("event",{"action":"choose","choice":"continue"}) and ui.view.room_event.stage=="wager_restraint","EVENT UI no-restraint player reaches round two from the existing Continue action")
 await press(t,ui.find_child("EventContinue",true,false))
 var fallback=ui.view.display_facts.filter(func(c):return c.payload.get("choice","")=="wager_without_restraint")
 t.check(fallback.size()==1 and fallback[0].valid and ui.candidate_buttons.has(String(fallback[0].get("key",""))),"EVENT UI replaces the empty equipment picker with an enabled fallback")
 var fallback_text=t.visible_text(ui.find_child("EventChoices",true,false))
 t.check(fallback_text.contains("直接翻牌") and fallback_text.contains("失败1/2") and fallback_text.contains("添加拘束具") and not fallback_text.contains("这一阶段没有能够执行的选项"),"EVENT UI compact fallback still previews the actual loss and remains playable")
 await press(t,ui.candidate_buttons[String(fallback[0].get("key",""))])
 t.check(ui.view.room_event.stage in ["after_round_two","restraint_penalty"] and ui.find_child("EventResultBanner",true,false)!=null,"EVENT UI fallback resolves normally with a prominent result page")
