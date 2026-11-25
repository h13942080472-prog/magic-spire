extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/target_sidebar_ui_cases.gd")
const Interface=preload("res://tests/interface_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func select_filter(t, selector: OptionButton, id: String) -> void:
 for index in range(selector.item_count):
  if selector.get_item_metadata(index)==id:
   selector.select(index);selector.item_selected.emit(index)
   return
 t.check(false,"DECK UI missing filter option: "+id)

static func run(t) -> void:
 await preload("res://tests/lewd_magic_ui_cases.gd").run(t)
 await preload("res://tests/supple_flesh_ui_cases.gd").run(t)
 await preload("res://tests/binding_power_ui_cases.gd").run(t)
 await preload("res://tests/mana_attachment_ui_cases.gd").run(t)
 await preload("res://tests/binding_search_ui_cases.gd").run(t)
 await preload("res://tests/kip_up_ui_cases.gd").run(t)
 await preload("res://tests/formation_ui_cases.gd").run(t)
 await preload("res://tests/sympathetic_form_ui_cases.gd").run(t)
 await preload("res://tests/endless_war_goddess_ui_cases.gd").run(t)
 await self_binding(t)
 await reuse(t)
 await confluence(t)
 await resonance(t)
 await preload("res://tests/practiced_ui_cases.gd").run(t)
 await preload("res://tests/hannya_ui_cases.gd").run(t)
 await henshin_costs(t)
 await combat_extension(t)
 await preload("res://tests/siphon_strength_ui_cases.gd").run(t)
 await magic_hand(t)
 await leverage(t)
 await breath_control(t)
 await preload("res://tests/restraint_embrace_ui_cases.gd").run(t)
 await mana_circuit(t)
 await stacked_flourish(t)
 await revised_preparation(t)
 await ready_to_strike(t)
 await crossed_legs(t)
 await mana_search(t)
 await forethought(t)
 await pot_of_greed(t)
 await revised_multihit(t)
 await repeated_strain(t)
 await echo_cast(t)
 await embers(t)
 await cumulative_preparations(t)
 await follow_through(t)
 await wildfire_descent(t)
 await adaptability(t)
 await rekindle(t)
 await fire_dynamics(t)
 await flame_flourish(t)
 await fire_control(t)
 await binding_enthusiast(t)
 var ui=t.ui
 ui.restart(42);await t.frames()
 ui.game._discard_end()
 var card=Cards.give(ui.game,"fire_mastery")
 ui.game._install_template("mouth_band","mouth",24.0,24.0,false,"fixture",3,0)
 ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.get_node("CardHeader/CardClassification").text=="能力" and face._gem_count()==3 and face.rarity=="rare" and not face.single_face,"POWER UI shared face shows both classification axes")
 var body=face.get_node("CardText")
 t.check(body.position.y+body.get_combined_minimum_size().y<=face.size.y-4,"POWER UI compact text stays within hand card")
 await t.flip(card.uid)
 t.check(ui.card_buttons[card.uid].free_face,"POWER UI ability has a real free face")
 await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.view.powers.size()==1 and ui.game.state.energy==2 and not ui.card_buttons.has(card.uid),"POWER UI native play moves card into ability zone")
 var fire=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 t.check(fire.valid and fire.payload.damage==ui.game.B.FIREBALL and fire.casting.percent=="100%","POWER UI fixed spell preview uses active body exemption")
 await Click.press(t,ui.find_child("OpenPowers",true,false));await t.frames()
 var grid=ui.find_child("DeckGrid",true,false)
 t.check(grid.get_child_count()==1 and t.visible_text(grid).contains("火焰精通") and grid.get_child(0).drag_payload.is_empty(),"POWER UI ability drawer shows only active physical card, read-only")
 var before=ui.game.export_snapshot()
 var kinds=ui.find_child("DeckTypeFilter",true,false);select_filter(t,kinds,"skill");await t.frames()
 t.check(grid.get_child_count()==0 and ui.game.export_snapshot()==before,"POWER UI type filter does not mutate live ability")
 select_filter(t,kinds,"power")
 var rarity=ui.find_child("DeckRarityFilter",true,false);select_filter(t,rarity,"rare");await t.frames()
 t.check(grid.get_child_count()==1,"POWER UI ability and rare filters combine")
 await t.close_information()
 await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy})
 t.check(ui.view.powers.size()==1 and ui.game.state.mana<100,"POWER UI real fireball still pays mana and keeps ability")
 ui.restart(42);await t.frames()
 ui.game._discard_end();card=Cards.give(ui.game,"fire_mastery")
 ui.render();await t.frames();await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.view.powers.size()==1 and ui.view.powers[0].power_face=="free","DUAL UI click commits the chosen free face")
 fire=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 t.check(fire.payload.damage==ui.game.B.FIREBALL_ASSISTED*2,"DUAL UI free mastery retains gesture bonus and doubles real damage")
 await Click.press(t,ui.find_child("OpenPowers",true,false));await t.frames()
 grid=ui.find_child("DeckGrid",true,false)
 t.check(grid.get_child(0).free_face,"DUAL UI active ability drawer starts on the committed face")
 await t.close_information()
 ui.game._discard_end();card=Cards.give(ui.game,"mana_surge")
 ui.render();await t.frames();await t.flip(card.uid)
 face=ui.card_buttons[card.uid]
 var hover_state=ui.game.export_snapshot()
 await t.move_mouse(Vector2(1100,90));await t.frames()
 await t.move_mouse(t.card_point(card.uid));await t.frames()
 var tip=ui.find_child("TermExplanation",true,false)
 var spell=ui.view.hand.filter(func(entry):return entry.uid==card.uid)[0]
 t.check(tip!=null and t.visible_text(tip).contains("施法部位：") and t.visible_text(tip).contains(spell.casting.percent),"DUAL UI paid free-face spell shows its projected casting chance")
 t.check(ui.game.export_snapshot()==hover_state,"DUAL UI free-face hover does not roll or change gameplay")
 var mana=ui.game.state.mana
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.mana==mana and ui.game.state.temporary_mana==10 and ui.game.state.charge==0,"DUAL UI free surge grants two reserve layers without paying mana")
 ui.game._discard_end();card=Cards.give(ui.game,"mana_conversion");ui.game.state.energy=0
 ui.render();await t.frames();await t.flip(card.uid)
 face=ui.card_buttons[card.uid]
 t.check(t.visible_text(face).contains("能量") and not ui.view.hand[0].availability.free.usable,"DUAL UI exchange free face explains actual energy shortage")
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.mana=40
 card=Cards.give(ui.game,"mana_invocation");ui.render();await t.frames()
 face=ui.card_buttons[card.uid]
 t.check(face.get_node("CardHeader/CardClassification").text=="魔法" and face.rarity=="common" and face._gem_count()==1 and t.visible_text(face.get_node("CardMana/Mana_gain")).strip_edges()=="+20" and t.visible_text(face).contains("消耗"),"INVOCATION UI shows rarity, spell type, restoration and exhaust")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.mana==60 and ui.view.energy==2 and not ui.card_buttons.has(card.uid) and ui.game.state.exhaust.back().uid==card.uid,"INVOCATION UI actual click restores mana and exhausts the card")
 for type in ["adaptability","strong_elbow","pleasure_conversion","mana_conversion","mana_surge","mana_invocation","henshin","fire_control"]:
  ui.restart(42);await t.frames();ui.game._discard_end();card=Cards.give(ui.game,type)
  ui.render();await t.frames()
  for side in range(2):
   face=ui.card_buttons[card.uid];body=face.get_node("CardText")
   t.check(body.position.y+body.get_combined_minimum_size().y<=face.size.y-4,"DUAL UI both faces fit within hand card "+type)
   await t.flip(card.uid)

static func henshin_costs(t) -> void:
 var ui=t.ui
 for free in [false,true]:
  var cost=4 if free else 3
  ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=cost
  var card=Cards.give(ui.game,"henshin")
  ui.render();await t.frames()
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  t.check(ui.card_buttons[card.uid].get_node("CardCost").text==str(cost),"HENSHIN UI bound shows three and free shows four energy")
  await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
  t.check(ui.game.state.energy==0 and ui.game.state.mana==60 and ui.game.state.exhaust.any(func(c):return c.uid==card.uid),"HENSHIN UI actual click pays selected face cost, forty mana and exhausts")

static func leverage(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 var card=Cards.give(ui.game,"leverage")
 ui.game.add_fixture("ankle",8)
 ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="common" and t.visible_text(face).contains("当前2") and t.visible_text(face).contains("每佩戴1件拘束具，这张牌的基础挣扎伤害增加2点") and face.get_node("CardIllustration").texture!=null,"LEVERAGE UI shows common rarity, actual count and illustration")
 await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("上身束缚等级＝0") and t.visible_text(ui.card_buttons[card.uid]).contains("获得1层闪避") and t.visible_text(ui.card_buttons[card.uid]).contains("蓄力1"),"LEVERAGE UI free face shows both buffs and upper requirement")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.evasion==1 and ui.game.state.charge==1 and ui.game.state.energy==2,"LEVERAGE UI native play commits both effects once")

static func binding_enthusiast(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=6
 ui.game.add_fixture("eyes",8.0)
 ui.game._install_special("vaginal_egg_low","special_3_a")
 var card=Cards.give(ui.game,"binding_enthusiast")
 ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="rare" and face.get_node("CardHeader/CardClassification").text=="能力" and face._gem_count()==3 and t.visible_text(face).contains("你每佩戴1件拘束具或性玩具，力量和灵巧各增加1点") and t.visible_text(face).contains("每成功打出1张其他牌的拘束面，固定获得10点快感") and face.get_node("CardIllustration").texture!=null,"BINDING ENTHUSIAST UI shows rare power, dynamic wording, fixed trigger and dedicated art")
 var body=face.get_node("CardText")
 var picture=face.get_node("CardIllustration")
 t.check(picture.size.x>=face.size.x*0.92 and picture.size.y>=face.size.x*0.76,"BINDING ENTHUSIAST UI gives the long-copy hand card a large illustration")
 body.scroll_vertical=int(ceilf(body.get_node("Content").size.y));await t.frames()
 var effect=body.get_node("Content/CardEffect")
 t.check(effect.get_global_rect().end.y<=body.get_global_rect().end.y+1,"BINDING ENTHUSIAST UI complete wording remains reachable by scrolling")
 body.scroll_vertical=0
 await t.capture("ui-binding-enthusiast.png")
 await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("你每佩戴1件拘束具或性玩具，力量和灵巧各增加1点") and t.visible_text(ui.card_buttons[card.uid]).contains("每成功打出1张其他牌的拘束面，固定获得10点快感"),"BINDING ENTHUSIAST UI matching free face keeps the complete effect")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.view.powers.size()==1 and ui.view.statuses.any(func(row):return row.id=="power_binding_enthusiast" and row.value.contains("2件")) and ui.view.statuses.any(func(row):return row.id=="strength" and row.value=="2"),"BINDING ENTHUSIAST UI activation immediately projects current count and strength")
 ui.game.add_fixture("ankle",8.0);ui.render();await t.frames()
 t.check(ui.view.statuses.any(func(row):return row.id=="power_binding_enthusiast" and row.value.contains("3件")) and ui.view.statuses.any(func(row):return row.id=="dexterity" and row.value=="3"),"BINDING ENTHUSIAST UI updates without replaying the power when equipment changes")

static func forethought(t) -> void:
 var ui=t.ui
 for free in [false,true]:
  ui.restart(42);ui.game._discard_end()
  var zone="draw" if free else "discard"
  if free: ui.game._install_template("restriction_collar","neck",1,1,true,"fixture",3)
  var card=preload("res://tests/enchantment_cases.gd").give(ui.game,"forethought","replay");var chosen=Cards.give(ui.game,"ease")
  var second=Cards.give(ui.game,"strain");ui.game.state.hand.erase(second);ui.game.state[zone].append(second)
  ui.game.state.hand.erase(chosen);ui.game.state[zone].append(chosen)
  ui.render();await t.frames()
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var face=ui.card_buttons[card.uid]
  t.check(t.visible_text(face).contains("从抽牌堆" if free else "从弃牌堆") and (t.visible_text(face).contains("全身无拘束")==free),"FORETHOUGHT UI shows the source and face-specific requirement")
  await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
  t.check(ui.view.card_chain.get("hand_source","")==zone and await t.click("chain",{"selected_uid":chosen.uid}),"FORETHOUGHT UI click a real pile entry")
  t.check(ui.view.card_chain.get("hand_source","")==zone and await t.click("chain",{"selected_uid":second.uid}),"FORETHOUGHT UI replay offers a second real choice")
  t.check(ui.card_buttons.has(chosen.uid) and ui.card_buttons.has(second.uid) and not ui.card_buttons.has(card.uid) and ui.view.card_chain.is_empty(),"FORETHOUGHT UI closes the chooser and shows both picked physical cards")

static func mana_search(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 var card=Cards.give(ui.game,"mana_search")
 Cards.give(ui.game,"wildfire_descent")
 var drawn=Cards.give(ui.game,"ease");ui.game.state.hand.erase(drawn);ui.game.state.draw.append(drawn)
 ui.render();await t.frames()
 t.check(t.visible_text(ui.card_buttons[ui.view.hand[1].uid]).contains("魔法／能力"),"SEARCH UI wildfire shows both actual tags")
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("抽取魔法2") and ui.card_buttons[card.uid].rarity=="common","SEARCH UI free face has correct ordinary skill effect")
 ui.game.add_fixture("eyes",2.0);ui.render();await t.frames()
 t.check(ui.game.level("arms")==0 and ui.view.hand.filter(func(v):return v.uid==card.uid)[0].availability.free.usable and t.visible_text(ui.card_buttons[card.uid]).contains("束缚等级"),"SEARCH UI head restraint alone allows free face and explains total-level gate")
 ui.game.add_fixture("upper_arm",2.0);ui.render();await t.frames()
 var projected=ui.view.hand.filter(func(v):return v.uid==card.uid)[0]
 t.check(not projected.availability.free.usable and projected.availability.bound.usable,"SEARCH UI upper-body restriction disables only free face")
 await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("抽取魔法1"),"SEARCH UI right click reveals usable bound face")
 await t.move_mouse(Vector2(1100,90));await t.move_mouse(t.card_point(card.uid));await t.frames()
 var tip=ui.find_child("TermExplanation",true,false)
 t.check(tip!=null and Interface.term_boxes(tip)==Interface.pinned_terms("mana_search","bound") and t.visible_text(tip).length()<65,"SEARCH UI hover keeps exactly one short box naming and defining the term: "+str(Interface.term_boxes(tip)))
 var before=ui.game.state.hand.size()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.energy==2 and ui.game.state.hand.size()==before and not ui.card_buttons.has(card.uid),"SEARCH UI real bound play costs one and draws a replacement")
 await Click.press(t,ui.find_child("OpenDeck",true,false));await t.frames()
 var snapshot=ui.game.export_snapshot()
 var kinds=ui.find_child("DeckTypeFilter",true,false)
 for id in ["magic","power"]:
  select_filter(t,kinds,id);await t.frames()
  t.check(t.visible_text(ui.find_child("DeckGrid",true,false)).contains("猛火下山") and ui.game.state==snapshot,"SEARCH UI magic and power filters both include dual-tag card without modifying state")
 await t.close_information()

static func revised_multihit(t) -> void:
 for type in ["peel","chain"]:
  var ui=t.ui
  ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.wall="normal"
  var target=ui.game.add_fixture("thigh",60.0,100.0)
  var card=Cards.give(ui.game,type)
  ui.render();await t.frames()
  if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
  var face=ui.card_buttons[card.uid]
  t.check(face.rarity=="uncommon" and t.visible_text(face).contains(("滑脱" if type=="peel" else "挣扎")+"4×3") and t.visible_text(face).contains("顺延"),type+" UI shared card face displays new damage count and keyword")
  await t.start_drag(card.uid,"thigh")
  var choice=Queries.find(ui.view,"card",{"uid":card.uid,"target":target.id,"free":false})
  t.check(choice.payload.mode==("slip" if type=="peel" else "strain") and choice.payload.preview.base==4,type+" UI target preview uses real damage formula")
  await t.release_target(await t.reveal_drop_target(choice.key));await t.frames()
  t.check(preload("res://tests/follow_through_cases.gd").hits(ui.game).size()==3 and ui.game.state.card_chain.is_empty() and ui.game.state.energy==1 and not ui.card_buttons.has(card.uid),type+" UI native drop completes three hits and single payment without secondary selection")

static func repeated_strain(t) -> void:
 var ui=t.ui
 for free in [false,true]:
  ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.wall="normal"
  var target=ui.game.add_fixture("thigh",100.0,100.0)
  var card=Cards.give(ui.game,"repeated_strain")
  ui.render();await t.frames()
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var face=ui.card_buttons[card.uid]
  t.check(face.rarity=="common" and t.visible_text(face).contains("消耗") and t.visible_text(face).contains("蓄力2" if free else "挣扎1×5"),"REPEATED UI both common faces show correct value and exhaust")
  var body=face.get_node("CardText")
  t.check(body.position.y+body.get_combined_minimum_size().y<=face.size.y-4,"REPEATED UI text fits shared card face")
  await t.start_drag(card.uid,"wrist" if free else "thigh")
  if free: await t.release_target()
  else:
   var choice=Queries.find(ui.view,"card",{"uid":card.uid,"target":target.id,"free":false})
   await t.release_target(await t.reveal_drop_target(choice.key))
  await t.frames()
  t.check(ui.game.state.energy==2 and ui.game.state.exhaust.any(func(c):return c.uid==card.uid) and not ui.card_buttons.has(card.uid),"REPEATED UI real drop pays one and exhausts selected face")
  t.check(ui.game.state.charge==2 if free else preload("res://tests/follow_through_cases.gd").hits(ui.game).size()==5,"REPEATED UI applies charge or five actual hits")

static func follow_through(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.wall="normal"
 var target=ui.game._install_template("rope","thigh",0.1,1.0,false,"fixture",1,0,0,"thigh_root")
 var next=ui.game._install_template("rope","thigh",0.1,1.0,false,"fixture",1,0,0,"mid_thigh")
 var last=ui.game.add_fixture("toes",0.1,1.0)
 var remote=ui.game.add_fixture("wrist",0.1,1.0)
 var expected_hits=floori(ui.game.BasicAttacks.fireball_damage(ui.game))
 var card=Cards.give(ui.game,"boar_emperor_blaze")
 ui.render();await t.frames()
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="rare" and t.visible_text(face).contains("6×%d" % expected_hits) and t.visible_text(face).contains("超级顺延") and not t.visible_text(face).contains("无视紧度减伤") and not t.visible_text(face).contains("同一大片区域"),"FOLLOW UI concise rare card face contains only damage and keyword")
 ui.localization.set_locale("en_US");ui.render();await t.frames()
 face=ui.card_buttons[card.uid]
 var english=t.visible_text(face)
 var chinese=RegEx.new();chinese.compile(r"[\x{3400}-\x{9fff}]")
 t.check(english.contains("Struggle 6 × %d hits" % expected_hits) and english.contains("Full Follow-Through") and not english.contains("Ignores Tightness damage reduction") and chinese.search(english)==null,"FOLLOW UI English rare bound face translates its post-keyword body as a complete sentence: "+english)
 ui.localization.set_locale("zh_CN");ui.render();await t.frames()
 face=ui.card_buttons[card.uid]
 await t.move_mouse(Vector2(1100,90));await t.move_mouse(t.card_point(card.uid));await t.frames()
 var tip=ui.find_child("TermExplanation",true,false)
 t.check(tip!=null and t.visible_text(tip).contains("区域内无合法目标后") and t.visible_text(tip).contains("全身合法目标"),"FOLLOW UI hover explains full-body fallback continuation")
 for side in range(2):
  face=ui.card_buttons[card.uid]
  var body=face.get_node("CardText")
  t.check(body.position.y+body.get_combined_minimum_size().y<=face.size.y-4,"FOLLOW UI both faces fit in card")
  await t.flip(card.uid)
 await t.start_drag(card.uid,"thigh")
 var choice=Queries.find(ui.view,"card",{"uid":card.uid,"target":target.id,"free":false})
 await t.release_target(await t.reveal_drop_target(choice.key));await t.frames()
 t.check(ui.game._equipment(target.id).is_empty() and ui.game._equipment(next.id).is_empty() and ui.game._equipment(last.id).is_empty() and ui.game._equipment(remote.id).is_empty() and ui.game.state.energy==0 and ui.game.state.card_chain.is_empty(),"FOLLOW UI actual targeted drop automatically resolves points then region and full-body fallback for one payment")
 ui.restart(42);await t.frames();ui.game._discard_end()
 ui.game.state.energy=6
 card=Cards.give(ui.game,"boar_emperor_blaze");ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("蓄力0"),"FOLLOW UI free face is concise")
 await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy})
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("蓄力1"),"BLAZE UI a successful Fireball refreshes the held free face")
 var energy=ui.game.state.energy
 await t.start_drag(card.uid,"wrist");await t.release_target();await t.frames()
 t.check(ui.game.state.charge==1 and ui.game.state.energy==energy-3 and not ui.card_buttons.has(card.uid),"BLAZE UI free drop grants the displayed charge and discards once")

static func flame_flourish(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=10
 var target=ui.game.add_fixture("thigh",60.0,60.0,true)
 var card=Cards.give(ui.game,"flame_flourish")
 ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="uncommon" and t.visible_text(face).contains("炫火") and t.visible_text(face).contains("火球术可以攻击最外层的拘束具，对其造成一半伤害"),"FLAME UI uncommon ability shows the authored bound equipment effect")
 for side in range(2):
  face=ui.card_buttons[card.uid]
  var body=face.get_node("CardText")
  t.check(body.position.y+body.get_combined_minimum_size().y<=face.size.y-4,"FLAME UI both card faces fit")
  await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.powers.any(func(c):return c.type=="flame_flourish" and c.power_face=="bound"),"FLAME UI real card click activates bound face")
 await t.inspect_body("thigh")
 var tile=ui.find_child("EquipmentCard_"+target.id,true,false)
 if not tile.find_child("EquipmentActions",true,false).visible:
  await Click.press(t,tile.find_child("EquipmentCardDetailsToggle",true,false));await t.frames()
 var spell=ui.find_child("EquipmentSpell_"+target.id,true,false)
 t.check(spell!=null and spell.is_visible_in_tree() and not spell.disabled,"FLAME UI equipment details expose usable self spell")
 var candidate=Queries.find(ui.view,"attack",{"target":target.id})
 var durability=target.durability
 await Click.press(t,spell);await t.frames()
 t.check(is_equal_approx(ui.game._equipment(target.id).durability,durability-candidate.payload.damage) and ui.game.BasicAttacks.usage(ui.game,"fireball").used==1 and ui.game.state.mana==90,"FLAME UI click damages selected equipment and spends mana plus shared use")
 await t.close_information()
 card=Cards.give(ui.game,"flame_flourish");ui.render();await t.frames();await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 candidate=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 t.check(ui.game.candidate_detail(candidate).contains("2／3次") and ui.game.state.powers.size()==2,"FLAME UI free face increases shared remaining count in fireball description")

static func embers(t) -> void:
 var ui=t.ui
 ui.restart(42)
 var fire=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 ui.game.dispatch(ui.game.command(fire.payload,ui.game.state.version),ui.game.state.version)
 ui.game._discard_end();ui.game.state.mana=12;ui.game.state.energy=0
 var card=Cards.give(ui.game,"embers")
 ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="common" and t.visible_text(face).contains("手部") and t.visible_text(face).contains("再耗6魔力") and t.visible_text(face).contains("成功使用过火球术"),"EMBERS UI shared card displays hand requirement and optional price")
 t.check(t.visible_text(face.get_node("CardMana/Mana_cost")).strip_edges()=="−6","EMBERS UI top-right badge is the actual base cost six")
 await t.capture("ui-embers-six.png")
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.mana==0 and ui.view.hand.size()==2 and ui.game.state.energy==0,"EMBERS UI zero energy cast actually draws twice and updates mana")

static func rekindle(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._discard_end();ui.game.state.combat.attack_uses.fireball=2
 var card=Cards.give(ui.game,"rekindle")
 ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="common" and t.visible_text(face).contains("手部") and t.visible_text(face).contains("刷新"),"REKINDLE UI common hand spell uses shared card face")
 await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 var fire=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 t.check(fire.valid and ui.game.state.combat.attack_uses.fireball==0 and ui.game.state.energy==2 and ui.game.state.mana==90,"REKINDLE UI free-face play restores real fireball button and pays once")

static func fire_dynamics(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._discard_end();ui.game.state.energy=10
 var card=Cards.give(ui.game,"fire_dynamics")
 ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="rare" and t.visible_text(face).contains("30") and not t.visible_text(face).contains("唯一") and face.get_node("CardCost").text=="1" and face.get_node("CardIllustration").texture!=null,"DYNAMICS UI rare card displays additive effect and illustration")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 ui.game.state.pressure=75
 card=Cards.give(ui.game,"fire_dynamics");ui.render();await t.frames()
 await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("全体攻击") and t.visible_text(ui.card_buttons[card.uid]).contains("唯一"),"DYNAMICS UI free face describes enemy area damage")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 var fire=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 t.check(fire.payload.all and fire.casting.percent=="55%" and ui.view.powers.size()==2,"DYNAMICS UI formal play projects both area targeting and increased chance")

static func echo_cast(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=8
 var card=Cards.give(ui.game,"echo_cast")
 ui.render();await t.frames()
 for free in [false,true]:
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var face=ui.card_buttons[card.uid]
  t.check(face.rarity=="uncommon" and t.visible_text(face).contains("余势复演") and t.visible_text(face).contains("魔法牌" if free else "伤害＋5"),"ECHO UI new name, uncommon rarity and correct face")
  t.check(t.visible_text(face).contains("嘴部")==free,"ECHO UI only the free face shows mouth casting")
  var body=face.get_node("CardText")
  t.check(body.position.y+body.get_combined_minimum_size().y<=face.size.y-4,"ECHO UI text fits shared card")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.view.statuses.any(func(row):return row.id=="power_echo_recharge"),"ECHO UI shows the active recharge")
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy}) and ui.game.BasicAttacks.usage(ui.game,"fireball").remaining==1,"ECHO UI Fireball spends one use")
 card=Cards.give(ui.game,"echo_cast");ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.BasicAttacks.usage(ui.game,"fireball").remaining==1 and ui.game.Cards.buff_stacks(ui.game,"echo_recharge")==2,"ECHO UI second skill adds a layer without restoring uses")
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy}),"ECHO UI spend the second use")
 card=Cards.give(ui.game,"mana_invocation");ui.render();await t.frames()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.BasicAttacks.usage(ui.game,"fireball").remaining==2,"ECHO UI a played magic card recharges Fireball")

static func wildfire_descent(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 var card=Cards.give(ui.game,"wildfire_descent")
 ui.render();await t.frames()
 for i in range(2):
  var face=ui.card_buttons[card.uid]
  t.check(face.rarity=="uncommon" and t.visible_text(face.get_node("CardMana/Mana_cost")).strip_edges()=="−10" and t.visible_text(face).contains("成功施放火球术，抽1张牌"),"WILDFIRE UI uncommon ability displays paid effect on either face")
  await t.move_mouse(Vector2(1100,90));await t.frames()
  await t.move_mouse(t.card_point(card.uid));await t.frames()
  var tip=ui.find_child("TermExplanation",true,false)
  t.check(tip!=null and t.visible_text(tip).contains("100%"),"WILDFIRE UI both faces show mouth casting chance")
  var body=face.get_node("CardText")
  t.check(body.position.y+body.get_combined_minimum_size().y<=face.size.y-4,"WILDFIRE UI card text fits")
  await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.powers.size()==1 and ui.game.state.mana==90 and ui.game.state.energy==2 and ui.game.state.hand.is_empty(),"WILDFIRE UI click pays and activates without self draw")
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy}) and ui.game.state.hand.size()==1 and ui.game.state.mana==80,"WILDFIRE UI fireball click draws one actual card")
 t.check(ui.view.statuses.any(func(row):return row.id=="power_wildfire_descent"),"WILDFIRE UI status describes active draw power")

static func adaptability(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 ui.game.state.charge=3;ui.game.state.temporary_mana=2
 for free in [true,false]:
  var card=Cards.give(ui.game,"adaptability")
  ui.render();await t.frames()
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var face=ui.card_buttons[card.uid]
  var expected="将全部蓄力转化为等量魔力预备" if free else "将全部魔力预备转化为等量蓄力"
  t.check(face.rarity=="uncommon" and t.visible_text(face).contains(expected),"ADAPT UI uncommon skill displays the selected conversion")
  await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
  t.check(ui.game.state.charge==(0 if free else 3) and ui.game.state.temporary_mana==(17 if free else 2) and ui.game.state.discard.any(func(c):return c.uid==card.uid),"ADAPT UI actual click converts immediately and discards")


static func fire_control(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 var card=Cards.give(ui.game,"fire_control")
 ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 t.check(ui.card_buttons[card.uid].rarity=="uncommon" and t.visible_text(ui.card_buttons[card.uid]).contains("永久＋1"),"CONTROL UI uncommon skill shows permanent free effect")
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("手部自由") and t.visible_text(ui.card_buttons[card.uid]).contains("上身束缚等级≤1") and not t.visible_text(ui.card_buttons[card.uid]).contains("各部位紧度＝0"),"CONTROL UI shows new combined requirements without the old per-slot restriction")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 var attack=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 t.check(ui.game.state.energy==2 and attack.payload.damage==ui.game.B.FIREBALL_ASSISTED+1 and not ui.card_buttons.has(card.uid),"CONTROL UI click exhausts card and updates actual fireball damage")
 t.check(ui.view.statuses.any(func(row):return row.id=="permanent_spell_fireball" and row.value=="＋1"),"CONTROL UI permanent bonus visible in status")
 ui.game.add_fixture("wrist",2.0);card=Cards.give(ui.game,"fire_control")
 ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var before=ui.game.export_snapshot()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state==before and not ui.view.hand.filter(func(row):return row.uid==card.uid)[0].availability.free.usable,"CONTROL UI upper restraint blocks free-side click without payment")
 await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.temporary_mana==10 and ui.game.state.spell_base_bonuses.fireball==1 and ui.game.state.discard.any(func(c):return c.uid==card.uid) and not ui.game.state.exhaust.any(func(c):return c.uid==card.uid),"CONTROL UI bound click grants two reserves and discards the card")

static func pot_of_greed(t) -> void:
 var ui=t.ui
 for free in [false,true]:
  ui.restart(42);await t.frames();ui.game._discard_end()
  var card=Cards.give(ui.game,"pot_of_greed")
  ui.render();await t.frames()
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var face=ui.card_buttons[card.uid]
  t.check(face.rarity=="uncommon" and face.get_node("CardCost").text=="0" and t.visible_text(face).contains("抽牌2。") and t.visible_text(face).contains("消耗") and t.visible_text(face).contains("技能"),"POT UI both faces show zero-cost uncommon skill, draw two and exhaust")
  var snapshot=ui.game.export_snapshot()
  await t.move_mouse(Vector2(1100,90));await t.move_mouse(t.card_point(card.uid));await t.frames()
  var tooltip=ui.find_child("TermExplanation",true,false)
  t.check(tooltip!=null and t.visible_text(tooltip).contains("移入本场消耗区") and not t.visible_text(tooltip).contains("抽牌：") and t.visible_text(tooltip).length()<65 and ui.game.export_snapshot()==snapshot,"POT UI hovering explains exhaust and preserves state")
  await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
  t.check(ui.game.state.hand.size()==2 and ui.game.state.energy==3 and ui.game.state.exhaust.any(func(c):return c.uid==card.uid) and ui.card_buttons.size()==2,"POT UI real click draws two, preserves energy and exhausts the played card")

static func revised_preparation(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 for type in ["brace","inch","unlock","double_unlock","echo_cast"]: Cards.give(ui.game,type)
 ui.render();await t.frames()
 for card in ui.view.hand:
  var free=card.type in ["unlock","double_unlock"]
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var expected={"brace":"挣扎5","inch":"滑脱5","unlock":"+2","double_unlock":"+1","echo_cast":"火球术剩余次数为0"}[card.type]
  t.check(t.visible_text(ui.card_buttons[card.uid]).contains(expected),"REVISED UI current card value and wording: "+card.type)
  if card.type=="inch":
   await t.flip(card.uid)
   var text=t.visible_text(ui.card_buttons[card.uid])
   t.check(text.contains("抽牌1") and text.contains("1层滑溜") and not text.contains("保留"),"INCH UI free face displays draw and slippery without retention")
 ui.restart(42);await t.frames();ui.game._discard_end()
 var card=Cards.give(ui.game,"focus");ui.render();await t.frames()
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("蓄力1；抽牌1"),"REVISED UI focus bound face shows shared preparation")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
 t.check(ui.game.state.energy==2 and ui.game.state.charge==1 and ui.game.state.hand.size()==1 and not ui.card_buttons.has(card.uid),"REVISED UI focus real click grants charge and draws without target picker")

static func crossed_legs(t) -> void:
 var ui=t.ui
 for free in [false,true]:
  ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.wall="normal"
  var target=ui.game.add_fixture("thigh",10 if free else 60,10 if free else 100)
  if free: ui.game.state.energy=0
  var card=Cards.give(ui.game,"crossed_legs")
  ui.render();await t.frames()
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var face=ui.card_buttons[card.uid]
  t.check(face.get_node("CardCost").text==("0" if free else "1") and t.visible_text(face).contains("抽牌1") and t.visible_text(face).contains("腿部束缚等级≤1" if free else "滑脱8"),"CROSS UI selected face displays actual fee and exact effect")
  await t.start_drag(card.uid,"wrist" if free else "thigh")
  if free: await t.release_target()
  else:
   var choice=Queries.find(ui.view,"card",{"uid":card.uid,"target":target.id,"free":false})
   await t.release_target(await t.reveal_drop_target(choice.key))
  await t.frames()
  t.check(ui.game.state.hand.size()==1 and ui.game.state.energy==(0 if free else 2) and ui.game.state.discard.any(func(c):return c.uid==card.uid),"CROSS UI both real drops draw one and charge their displayed fee")
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.add_fixture("ankle",1)
 var card=Cards.give(ui.game,"crossed_legs")
 ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("当前为2") and ui.card_buttons[card.uid].get_node("CardCost").text=="0","CROSS UI zero-cost blocked face shows actual overall leg level")

 ui.restart(42);await t.frames();ui.game._discard_end()
 card=Cards.give(ui.game,"crossed_legs")
 preload("res://tests/crossed_legs_cases.gd").isolate(ui.game,card)
 ui.game.state.energy=0;ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
 t.check(ui.game.state.hand.is_empty() and ui.game.state.draw.is_empty() and ui.game.state.discard.size()==1 and ui.game.state.discard[0].uid==card.uid and not ui.card_buttons.has(card.uid),"CROSS UI empty piles do not draw the card being played")
 t.check(ui.find_child("DrawPileButton",true,false).text.contains("0") and ui.find_child("DiscardPileButton",true,false).text.contains("1"),"CROSS UI pile counts show zero draw and the settled discard")

static func breath_control(t) -> void:
 var ui=t.ui
 for free in [false,true]:
  ui.restart(42);await t.frames();ui.game._discard_end()
  var target=ui.game.add_fixture("wrist",70,100)
  var source=Cards.give(ui.game,"breath_control");var chosen=Cards.give(ui.game,"sensitive");var peer=Cards.give(ui.game,"sensitive")
  ui.render();await t.frames()
  if ui.card_faces.get(source.uid,false)!=free: await t.flip(source.uid)
  var text=t.visible_text(ui.card_buttons[source.uid])
  t.check(text.contains("口部自由" if free else "滑脱8×2") and text.contains("选择并消耗1张手牌") and ui.card_buttons[source.uid].get_node("CardCost").text=="2","BREATH UI both faces show two energy and exact effect, free mouth requirement visible")
  var before=ui.game.export_snapshot()
  await preload("res://tests/curse_ui_cases.gd").click_card(t,source.uid)
  t.check(ui._selecting_hand() and ui.game.export_snapshot()==before and ui.card_buttons[source.uid].disabled,"BREATH UI target choice opens native hand selection without payment")
  if not ui._selecting_hand(): continue
  t.check(ui._hand_choice(chosen.uid).payload.target==("" if free else target.id),"BREATH UI hand choices preserve chosen equipment or free target")
  await Click.press(t,ui.find_child("HandTargetCancel",true,false));await t.frames()
  t.check(not ui._selecting_hand() and ui.game.export_snapshot()==before,"BREATH UI cancel preserves both cards and resources")
  await preload("res://tests/curse_ui_cases.gd").click_card(t,source.uid)
  await preload("res://tests/curse_ui_cases.gd").click_card(t,chosen.uid)
  t.check(ui.game.state.energy==1 and ui.game.state.mana==100 and ui.game.state.exhaust.any(func(x):return x.uid==chosen.uid) and ui.game.state.hand.any(func(x):return x.uid==peer.uid) and not ui._selecting_hand(),"BREATH UI selects exact duplicate, exhausts once and pays once")
  t.check(ui.game.state.charge==(1 if free else 0) and (ui.game._equipment(target.id).durability==70)==free,"BREATH UI selected face applies to the originally chosen target")
 ui.restart(42);await t.frames();ui.game._discard_end()
 var target=ui.game.add_fixture("wrist",70,100);ui.game.add_fixture("ankle",70,100)
 var source=Cards.give(ui.game,"breath_control");var chosen=Cards.give(ui.game,"sensitive");Cards.give(ui.game,"sensitive")
 ui.render();await t.frames()
 if ui.card_faces.get(source.uid,false): await t.flip(source.uid)
 var before=ui.game.export_snapshot();var point=t.card_point(source.uid)
 var c=Queries.find(ui.view,"card",{"uid":source.uid,"target":target.id,"hand_uid":chosen.uid,"free":false})
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 t.check(ui.find_child("HandDragTarget_"+chosen.uid,true,false)==null,"BREATH UI bound drag asks for equipment before a hand card")
 await t.move_mouse(ui.body_buttons.wrist.get_global_rect().get_center(),true)
 if not ui.drop_targets.has(c.key):
  t.check(false,"BREATH UI bound drag opens the chosen equipment target")
  await t.mouse_button(Vector2(1550,70),MOUSE_BUTTON_LEFT,false);return
 await t.release_target(await t.reveal_drop_target(c.key))
 t.check(ui._selecting_hand() and ui.game.export_snapshot()==before and ui.player_pick_data.target==target.id,"BREATH UI equipment drop preserves target and waits for hand selection")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,chosen.uid)
 t.check(ui.game.state.exhaust.any(func(x):return x.uid==chosen.uid) and ui.game._equipment(target.id).durability<70 and ui.game.state.energy==1,"BREATH UI equipment drag then hand click completes one formal action")

 # 快捷解除区域选中时的牌面点击（原 A45 分支）：与其他已解析行走同一条改道 —— 先选要消耗的手牌。
 # 两件拘束具使唯一装备面（A24）不再命中，本块只观测快捷解除分支。
 ui.restart(42);await t.frames();ui.game._discard_end()
 var quick=preload("res://ui/quick_release_bar.gd")
 var quick_target=ui.game.add_fixture("wrist",70,100);ui.game.add_fixture("ankle",70,100)
 var quick_source=Cards.give(ui.game,"breath_control");var quick_chosen=Cards.give(ui.game,"sensitive");Cards.give(ui.game,"sensitive")
 ui.render();await t.frames()
 if ui.card_faces.get(quick_source.uid,false): await t.flip(quick_source.uid)
 await Click.press(t,ui.find_child("ActionRailToggle",true,false));await t.frames()
 await Click.press(t,ui.find_child("QuickRelease_region_upper",true,false));await t.frames()
 await Click.press(t,ui.find_child("QuickRelease_region_upper",true,false));await t.frames()
 t.check(ui.quick_release_open and ui.quick_release_region=="region_upper" and not ui.show_body and quick.equipment_at(ui,"region_upper").id==quick_target.id,"BREATH UI quick-release fixture holds the wrist target with details closed")
 var quick_before=ui.game.export_snapshot()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,quick_source.uid)
 t.check(ui._selecting_hand() and ui.game.export_snapshot()==quick_before and ui.player_pick_data.target==quick_target.id,"BREATH UI quick-release card click opens native hand selection without payment")
 if not ui._selecting_hand(): return
 await preload("res://tests/curse_ui_cases.gd").click_card(t,quick_chosen.uid)
 t.check(ui.game.state.exhaust.any(func(x):return x.uid==quick_chosen.uid) and ui.game._equipment(quick_target.id).durability<70 and ui.game.state.energy==1 and not ui._selecting_hand(),"BREATH UI quick-release then picked hand click submits once with the chosen card")

static func ready_to_strike(t) -> void:
 var ui=t.ui
 for free in [false,true]:
  ui.restart(42);await t.frames();ui.game._discard_end()
  var source=Cards.give(ui.game,"ready_to_strike");var chosen=Cards.give(ui.game,"sensitive");var peer=Cards.give(ui.game,"sensitive")
  ui.render();await t.frames()
  if ui.card_faces.get(source.uid,false)!=free: await t.flip(source.uid)
  t.check(t.visible_text(ui.card_buttons[source.uid]).contains("下一次体术费用－1" if free else "蓄力3"),"READY UI prints the distinct face effect")
  var before=ui.game.export_snapshot()
  await preload("res://tests/curse_ui_cases.gd").click_card(t,source.uid)
  t.check(ui.find_child("HandTargetPicker",true,false)==null and ui.find_child("HandSelectionBar",true,false)!=null and ui.game.export_snapshot()==before,"READY UI clicking either face selects directly in the hand without a second window or payment")
  var options=Queries.select(ui.view,"card",{"uid":source.uid,"free":free})
  t.check(options.size()==2 and options.all(func(c):return ui.candidate_buttons.get(ui.display_key(c.payload))==ui.card_buttons[c.payload.hand_uid]),"READY UI duplicate cards remain separate selectable physical targets")
  t.check(ui.card_buttons[source.uid].disabled and not ui.card_buttons[chosen.uid].disabled and ui.card_buttons[chosen.uid].get_meta("hand_selectable",false),"READY UI dims source and highlights actual eligible hand cards")
  if not free: await t.capture("ui-hand-exhaust-selection.png")
  await Click.press(t,ui.find_child("HandTargetCancel",true,false));await t.frames()
  t.check(ui.find_child("HandSelectionBar",true,false)==null and ui.game.export_snapshot()==before,"READY UI cancelling selection leaves cards resources and random state unchanged")
  await preload("res://tests/curse_ui_cases.gd").click_card(t,source.uid)
  await preload("res://tests/curse_ui_cases.gd").click_card(t,chosen.uid)
  t.check(ui.game.state.exhaust.any(func(card):return card.uid==chosen.uid) and ui.game.state.hand.any(func(card):return card.uid==peer.uid) and ui.game.state.discard.any(func(card):return card.uid==source.uid),"READY UI native target click exhausts only selected hand card")
  t.check(ui.game.state.energy==2 and ui.game.state.mana==90 and ui.game.state.charge==(0 if free else 3) and ("ready_to_strike_free" in ui.game.state.card_buffs)==free and ui.find_child("HandTargetPicker",true,false)==null,"READY UI completes one paid spell and closes selection")
  if free:
   var attack=Queries.find(ui.view,"attack",{"type":"heavy","form":0})
   t.check(attack.cost==1 and ui.view.statuses.any(func(s):return s.id=="power_ready_to_strike_free" and s.detail.contains("费用－1")),"READY UI exposes discounted actual cost and status")

 ui.restart(42);await t.frames();ui.game._discard_end()
 var source=Cards.give(ui.game,"ready_to_strike");var chosen=Cards.give(ui.game,"sensitive")
 ui.render();await t.frames()
 var keys=preload("res://tests/keyboard_ui_cases.gd")
 var before=ui.game.export_snapshot()
 await keys.tap(t,KEY_1)
 t.check(ui._selecting_hand() and ui.find_child("KeyboardTargets",true,false)==null and ui.game.export_snapshot()==before,"READY UI keyboard enters the same inline hand selection without separate target controls")
 await keys.tap(t,KEY_ESCAPE)
 t.check(not ui._selecting_hand() and ui.game.export_snapshot()==before,"READY UI Escape cancels without spending or consuming")
 await keys.tap(t,KEY_1);await keys.tap(t,KEY_2)
 t.check(ui.game.state.exhaust.any(func(card):return card.uid==chosen.uid) and not ui._selecting_hand(),"READY UI number key selects the actual hand card and resolves once")
 ui.restart(42);await t.frames();ui.game._discard_end()
 source=Cards.give(ui.game,"ready_to_strike");chosen=Cards.give(ui.game,"sensitive")
 ui.render();await t.frames()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,source.uid)
 ui.game.state.version+=1;before=ui.game.export_snapshot()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,chosen.uid)
 t.check(ui.game.export_snapshot()==before,"READY UI stale inline selection is atomically rejected without payment or card movement")
 await keys.tap(t,KEY_ESCAPE)

static func stacked_flourish(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=10
 for i in range(2):
  var card=Cards.give(ui.game,"flame_flourish")
  ui.render();await t.frames()
  if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
  await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
 t.check(ui.game.state.powers.size()==2 and ui.game.state.energy==8 and ui.game.BasicAttacks.usage(ui.game,"fireball").limit==4,"STACK UI repeated free flourish pays and increases real limit")
 t.check(ui.view.statuses.any(func(s):return s.id=="power_flame_flourish_free" and s.value.contains("2重") and s.detail.contains("每回合火球术可用次数＋1。") and not s.detail.contains("可叠加") and not s.detail.contains("2→3")),"STACK UI status shows layers and accurate repeatable description")

static func mana_circuit(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=20
 for i in range(2):
  var card=Cards.give(ui.game,"mana_circuit")
  ui.render();await t.frames()
  if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
  t.check(t.visible_text(ui.card_buttons[card.uid]).contains("累计消耗30点魔力，获得" + preload("res://ui/card_energy_text.gd").ICON),"CIRCUIT UI rare ability displays free threshold and energy reward")
  await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
 t.check(ui.game.state.powers.size()==2 and ui.game.state.energy==16,"CIRCUIT UI native duplicate activations each pay two energy")
 for i in range(3):
  var spell=Cards.give(ui.game,"rekindle");ui.render();await t.frames()
  await preload("res://tests/curse_ui_cases.gd").click_card(t,spell.uid);await t.frames()
 t.check(ui.game.state.energy==15 and ui.game.state.powers.all(func(c):return c.power_mana_progress==0),"CIRCUIT UI three paid spells trigger both active copies")
 t.check(ui.view.statuses.any(func(s):return s.name=="魔力回路·能量" and str(s).contains("2重") and str(s).contains("0／30")),"CIRCUIT UI status projects stack count and remaining progress")
 ui.game.add_fixture("ankle",1);var card=Cards.give(ui.game,"mana_circuit");ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("需要腿部束缚等级≤0"),"CIRCUIT UI explains blocked free activation with current body rule")
 await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("累计消耗20点魔力，获得1层蓄力"),"CIRCUIT UI bound face displays charge threshold")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
 t.check(ui.game.state.powers.size()==3,"CIRCUIT UI bound face remains usable despite lower-body restraints")

static func magic_hand(t) -> void:
 var ui=t.ui
 for free in [false,true]:
  ui.restart(42);await t.frames();ui.game._discard_end()
  var target=ui.game.add_fixture("wrist",10)
  var card=Cards.give(ui.game,"magic_hand")
  ui.render();await t.frames()
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var face=ui.card_buttons[card.uid];var text=t.visible_text(face)
  var keywords=t.visible_text(face.get_node("CardText/Content/CardKeywords"))
  t.check(face.rarity=="uncommon" and face.get_node("CardCost").text=="1" and keywords.contains("消耗") and (face.get_node("CardText/Content/CardEffect").text.contains("下2次手部体术") if free else (face.get_node("CardText/Content/CardEffect").text=="降紧3。" and keywords.contains("超级顺延"))),"HAND UI uncommon faces separate exact effects from bottom keywords and preserve energy")
  t.check(t.visible_text(face.get_node("CardMana")).contains("20") and text.contains("嘴部"),"HAND UI both faces expose mouth casting and twenty mana")
  var before=ui.game.export_snapshot()
  await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
  t.check(ui.game.state.energy==2 and ui.game.state.mana==80 and ui.game.state.exhaust.any(func(x):return x.uid==card.uid) and ui.game.state.card_chain.is_empty(),"HAND UI native click pays and exhausts once, no continuation picker")
  t.check((ui.game._equipment(target.id).is_empty() if not free else ui.game.state.card_buff_uses.get("magic_hand_free")==2 and ui.game._equipment(target.id).durability==10) and ui.game.state.deck==before.deck,"HAND UI chosen face resolves its real effect and preserves permanent card")
  if free:
   var rows=ui.view.statuses.filter(func(s):return s.id=="power_magic_hand_free")
   t.check(rows.size()==1 and rows[0].badge=="2" and rows[0].detail.contains("自由态") and ui.find_child("StatusIcon_power_magic_hand_free",true,false)!=null,"HAND UI counted buff appears with its remaining uses and explanation")
   if ui.attack_forms.get("strike",0)!=1:
    var point=ui.find_child("BasicAttack_strike",true,false).get_global_rect().get_center()
    await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
   t.check(await t.click("attack",{"type":"strike","form":1,"enemy":ui.selected_enemy}),"HAND UI multi-hit elbow uses the formal attack button")
   rows=ui.view.statuses.filter(func(s):return s.id=="power_magic_hand_free")
   t.check(rows.size()==1 and rows[0].badge=="1" and rows[0].value=="剩余1次","HAND UI complete two-hit elbow decrements icon once")
   await t.capture("ui-magic-hand-free.png")
 ui.restart(42);await t.frames();ui.game._discard_end()
 var target=ui.game.add_fixture("thigh",4);var wrist=ui.game.add_fixture("wrist",8)
 var card=Cards.give(ui.game,"magic_hand");ui.render();await t.frames()
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var c=Queries.find(ui.view,"card",{"uid":card.uid,"target":target.id,"free":false})
 var before=ui.game.export_snapshot();var point=t.card_point(card.uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 await t.move_mouse(ui.body_buttons.thigh.get_global_rect().get_center(),true)
 t.check(ui.drop_targets.has(c.key) and ui.game.export_snapshot()==before,"HAND UI drag exposes formal target without spending or rolling")
 if not ui.drop_targets.has(c.key):
  await t.mouse_button(Vector2(1550,70),MOUSE_BUTTON_LEFT,false);return
 await t.release_target(await t.reveal_drop_target(c.key))
 t.check(ui.game._equipment(target.id).is_empty() and ui.game._equipment(wrist.id).is_empty() and ui.game.state.mana==80 and ui.game.state.energy==2 and ui.game.state.exhaust.any(func(x):return x.uid==card.uid),"HAND UI native drop automatically spends remaining two tiers on whole-body fallback")

static func combat_extension(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.relics=[];ui.game._discard_end();ui.game.state.energy=4
 var card=Cards.give(ui.game,"henshin")
 ui.render();await t.frames()
 var text=ui.game.live_card_text("henshin")
 t.check(text.face_costs.bound=="3" and text.face_costs.free=="4","EXTENSION UI henshin shows three bound and four free energy")
 await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.energy==0 and "henshin_free" in ui.game.state.card_buffs,"EXTENSION UI henshin native play pays displayed cost")
 ui.game._finish_battle();ui.render();await t.frames()
 t.check(ui.find_child("BattleRewards",true,false)!=null and ui.view.statuses.any(func(row):return row.id=="power_henshin_free" and row.duration=="本场整备结束"),"EXTENSION UI reward window preserves visible battle buff with correct duration")
 t.check(await t.click("reward",{"type":"skip"}) and ui.view.phase=="prepare" and ui.view.energy==3 and ui.game.state.exhaust.any(func(c):return c.uid==card.uid),"EXTENSION UI preparation starts with refill and original exhausted card")
 t.check(ui.find_child("StatusIcon_power_henshin_free",true,false)!=null,"EXTENSION UI buff remains visible during preparation")
 t.check(await t.click("finish_prepare") and not ui.game.state.card_buffs.has("henshin_free"),"EXTENSION UI leaving preparation clears battle buff")
 ui.restart(42);await t.frames()

static func cumulative_preparations(t) -> void:
 var ui=t.ui
 for type in ["magic_hand","echo_cast"]:
  ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=10
  for n in range(2):
   var card=Cards.give(ui.game,type);ui.render();await t.frames()
   if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
   t.check(not t.visible_text(ui.card_buttons[card.uid]).contains("唯一"),"CUMULATIVE UI repeatable card has no unique label")
   await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
  var id="magic_hand_free" if type=="magic_hand" else "echo_recharge"
  var count=4 if type=="magic_hand" else 2
  t.check(ui.game.state.card_buff_uses.get(id)==count and ui.view.statuses.any(func(row):return row.id=="power_"+id and row.value.contains(str(count))),"CUMULATIVE UI displays actual accumulated uses after two clicks")
 ui.restart(42);await t.frames();ui.game._discard_end()
 var card=Cards.give(ui.game,"mana_surge");ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("2层魔力预备") and ui.card_buttons[card.uid].get_node_or_null("CardMana/Mana_cost")==null and t.visible_text(ui.card_buttons[card.uid].get_node("CardMana/Mana_temporary")).strip_edges()=="+2","SURGE UI free card describes two reserve layers and shows only the temporary mana badge")
 await t.capture("ui-surge-reserve.png")

static func resonance(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=8
 ui.game.add_fixture("ankle",8)
 var card=Cards.give(ui.game,"resonance");ui.render();await t.frames()
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="uncommon" and face.get_node("CardCost").text=="1" and t.visible_text(face).contains("5%") and t.visible_text(face).contains("唯一") and face.ILLUSTRATIONS.has("resonance"),"RESONANCE UI bound uncommon one energy unique with its own artwork")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.view.statuses.any(func(row):return row.id=="power_resonance_bound" and row.value.contains("5%")),"RESONANCE UI bound activation displays live reduction")
 var spell=Cards.give(ui.game,"rekindle");ui.render();await t.frames()
 t.check(t.visible_text(ui.card_buttons[spell.uid].get_node("CardMana/Mana_cost")).strip_edges()=="−9.5","RESONANCE UI real spell badge reflects fractional reduced payment")
 card=Cards.give(ui.game,"resonance");ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 t.check(ui.card_buttons[card.uid].get_node("CardCost").text=="2" and not t.visible_text(ui.card_buttons[card.uid]).contains("唯一") and t.visible_text(ui.card_buttons[card.uid]).contains("获得2层闪避") and t.visible_text(ui.card_buttons[card.uid]).contains("消耗"),"RESONANCE UI free face costs two energy and displays the exhaust keyword")
 var energy_before=ui.game.state.energy
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.energy==energy_before-2,"RESONANCE UI native free play spends two energy")
 card=Cards.give(ui.game,"resonance");ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 energy_before=ui.game.state.energy
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.energy==energy_before-2 and ui.game.state.evasion==4 and ui.game.state.exhaust.any(func(c):return c.uid==card.uid),"RESONANCE UI repeat free face grants evasion and exhausts")
 for enemy in ui.game.state.enemies: enemy.intent.delayed=true
 ui.render();await t.frames()
 t.check(await t.click("end") and ui.game.state.evasion==4,"RESONANCE UI next turn preserves unspent evasion")

static func confluence(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=0;ui.game.state.mana=30
 var card=Cards.give(ui.game,"confluence");ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="common" and face.get_node("CardCost").text=="0" and t.visible_text(face).contains("技能") and t.visible_text(face.get_node("CardMana/Mana_gain")).strip_edges()=="+0","CONFLUENCE UI common zero-energy skill displays zero gain with no equipment")
 t.check(t.visible_text(face).contains("你每佩戴1件拘束具或性玩具，恢复2点魔力。") and t.visible_text(face).contains("当前：恢复0魔力。") and t.visible_text(face.get_node("CardText/Content/CardKeywords")).contains("消耗"),"CONFLUENCE UI zero-gain card retains its equipment scaling rule and exhaust keyword")
 await t.capture("ui-confluence-description.png")
 for slot in ["eyes","ankle","thigh"]: ui.game.add_fixture(slot,8)
 ui.render();await t.frames()
 t.check(t.visible_text(ui.card_buttons[card.uid].get_node("CardMana/Mana_gain")).strip_edges()=="+6","CONFLUENCE UI mana corner updates after equipment changes")
 await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("本回合力量＋1") and not ui.card_buttons[card.uid].get_node("CardMana").visible,"CONFLUENCE UI bound face shows floored strength without a false mana badge")
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("你每佩戴2件拘束具或性玩具，本回合获得1点力量。"),"CONFLUENCE UI bound face keeps threshold and duration alongside current strength")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.turn_strength==1 and ui.game.state.strength==0 and ui.view.statuses.any(func(row):return row.id=="strength" and row.value=="1" and row.detail.contains("本回合结束清除")),"CONFLUENCE UI actual bound play updates strength and expiry detail")
 card=Cards.give(ui.game,"confluence");ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.mana==36 and ui.game.state.energy==0 and ui.game.state.exhaust.any(func(x):return x.uid==card.uid) and not ui.game.state.discard.any(func(x):return x.uid==card.uid),"CONFLUENCE UI free play restores six mana without energy and exhausts")


static func reuse(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=8;ui.game.state.equipment.clear()
 var card=Cards.give(ui.game,"reuse");ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="rare" and face.get_node("CardCost").text=="1" and t.visible_text(face).contains("抽1张牌") and t.visible_text(face).contains("返还魔力为0") and t.visible_text(face).contains("魔路精通") and t.visible_text(face).contains("唯一") and face.ILLUSTRATIONS.has("reuse"),"REUSE UI rare free face shows one energy, unique, temporary conversion and artwork")
 await t.flip(card.uid)
 face=ui.card_buttons[card.uid]
 var blocked=Queries.find(ui.view,"card",{"uid":card.uid,"free":false})
 t.check(face.get_node("CardCost").text=="3" and t.visible_text(face).contains("上身束缚等级≥3") and t.visible_text(face).contains("腿部束缚等级≥3") and t.visible_text(face).contains("紧度≥2") and t.visible_text(face).contains("至少10件") and t.visible_text(face).contains("取消次数限制") and not blocked.valid,"REUSE UI bound face shows three energy, tier/count upgrade and both live requirements")
 ui.game.add_fixture("wrist",8);ui.game.add_fixture("ankle",8);ui.render();await t.frames()
 t.check(not Queries.find(ui.view,"card",{"uid":card.uid,"free":false}).valid,"REUSE UI level-two regions still block activation")
 ui.game.add_fixture("palm",8);ui.game.add_fixture("foot",8);ui.render();await t.frames()
 t.check(Queries.find(ui.view,"card",{"uid":card.uid,"free":false}).valid,"REUSE UI condition changes enable the original card")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.view.statuses.any(func(row):return row.id=="power_reuse_bound" and row.value.contains("100%") and row.value.contains("剩余2次")),"REUSE UI actual play creates the full refund and energy power status")
 for slot in ["eyes","fingers","upper_arm","forearm","thigh","calf"]: ui.game.add_fixture(slot,8)
 ui.render();await t.frames()
 t.check(ui.view.statuses.any(func(row):return row.id=="power_reuse_bound" and row.value.contains("可反复触发")),"REUSE UI ten tight ordinary items immediately display unlimited conversion")
 ui.game.state.equipment.clear();ui.render();await t.frames()
 t.check(ui.view.statuses.any(func(row):return row.id=="power_reuse_bound" and row.value.contains("待生效") and row.value.contains("上身")),"REUSE UI status explicitly reports the lost ongoing requirement")


static func self_binding(t) -> void:
 var ui=t.ui
 ui.game=preload("res://tests/self_binding_cases.gd").setup(1)
 var card=Cards.give(ui.game,"self_binding")
 ui.render();await t.frames()
 if not ui.card_buttons[card.uid].free_face: await t.flip(card.uid)
 var face=ui.card_buttons[card.uid]
 t.check(face.get_node("CardCost").text=="X" and face.rarity=="uncommon" and face.ILLUSTRATIONS.has("self_binding"),"SELF BIND UI shows X cost, uncommon rarity and its existing illustration")
 t.check(t.visible_text(face).contains("每件品质＋紧度＝2X") and t.visible_text(face).contains("15X") and t.visible_text(face).contains("需要足够空间"),"SELF BIND UI keeps complete formula and failure conditions")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.equipment.size()==2 and ui.game.state.energy==0 and ui.game.state.mana==15 and not ui.card_buttons.has(card.uid),"SELF BIND UI click actually installs two restraints and pays the X cost")
 ui.game=preload("res://tests/self_binding_cases.gd").setup(2)
 card=Cards.give(ui.game,"self_binding");ui.game.add_fixture("ankle",4)
 ui.render();await t.frames()
 if ui.card_buttons[card.uid].free_face: await t.flip(card.uid)
 var before=ui.game.export_snapshot()
 var c=Queries.find(ui.view,"card",{"uid":card.uid,"free":false})
 t.check(not c.valid and c.reason.contains("需要收紧4档") and c.reason.contains("只能收紧2档"),"SELF BIND UI explains the exact shortfall on the bound face")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.export_snapshot()==before and ui.card_buttons.has(card.uid),"SELF BIND UI unavailable click changes neither equipment nor mana nor card zone")
 ui.restart(42);await t.frames()
