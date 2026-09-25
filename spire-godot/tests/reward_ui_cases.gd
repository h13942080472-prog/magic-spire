extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

static func periodic_counter(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.RelicEffects.gain(ui.game,"happy_fa");ui.render();await t.frames()
 var shortcut=ui.find_child("RelicShortcut_happy_fa",true,false)
 t.check(shortcut!=null and shortcut.find_child("RelicCounter",true,false).text=="0","FA UI owned relic starts with visible zero counter")
 t.check(ui.layout.get_children().filter(func(node):return node is Label and node.text in [ui.view.room_name,ui.view.phase_caption]).is_empty(),"RELIC UI scene header omits redundant room and phase text")
 for count in [1,2]:
  t.check(await t.click("end"),"FA UI ends real player turn")
  shortcut=ui.find_child("RelicShortcut_happy_fa",true,false)
  t.check(shortcut.find_child("RelicCounter",true,false).text==str(count),"FA UI counter follows real turn progress")
 var before=ui.game.export_snapshot()
 await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_LEFT,true);await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_LEFT,false)
 await t.move_mouse(shortcut.get_global_rect().get_center());await t.frames()
 var badge=shortcut.find_child("RelicCounter",true,false)
 var icon=badge.get_parent()
 t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains("已累计2／3") and ui.game.state==before and badge.text=="2","FA UI hover shows matching read-only detail counter")
 t.check(badge.get_rect().get_center().x>=icon.size.x/2 and badge.get_rect().get_center().y>=icon.size.y/2 and badge.get_rect().end.is_equal_approx(icon.size),"FA UI counter is anchored exactly to bottom-right of relic icon")
 await t.capture("ui-relic-turn-counter.png")
 await t.move_mouse(Vector2(650,60));await t.frames()
 t.check(not is_instance_valid(ui.term_popup),"FA UI moving away closes hover detail")
 t.check(await t.click("end") and ui.view.energy==4 and ui.find_child("RelicShortcut_happy_fa",true,false).find_child("RelicCounter",true,false).text=="0","FA UI third turn immediately adds energy and resets displayed counter")
 await t.capture("ui-relic-turn-trigger.png")
 ui.restart(42);ui.game.RelicEffects.gain(ui.game,"small_gem");ui.game._finish_battle();ui.render();await t.frames()
 t.check(await t.click("reward",{"type":"skip"}) and ui.view.energy==3 and ui.find_child("EnergyValue",true,false).text=="3","GEM UI preparation refills without repeating opening bonus")
 shortcut=ui.find_child("RelicShortcut_small_gem",true,false)
 await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_LEFT,true);await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_LEFT,false)
 await t.move_mouse(shortcut.get_global_rect().get_center());await t.frames()
 t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains(ui.game.Relics.TYPES.small_gem.detail) and preload("res://ui/relic_icon.gd").ART.has("small_gem"),"GEM UI shared icon and hover explain the opening bonus")
 await t.move_mouse(Vector2(650,60));await t.frames()
 t.check(await t.click("end") and ui.view.energy==3,"GEM UI next turn does not repeat opening energy")
 ui.restart(42);await t.frames()

static func spicy_rice_noodles(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.RelicEffects.gain(ui.game,"spicy_rice_noodles");ui.game._finish_battle();ui.render();await t.frames()
 t.check(await t.click("reward",{"type":"skip"}) and ui.game.state.charge==0 and not ui.view.statuses.any(func(row):return row.id=="charge"),"NOODLES UI preparation does not repeat opening charge")
 t.check(ui.find_child("RelicShortcut_spicy_rice_noodles",true,false)!=null and preload("res://ui/relic_icon.gd").ART.has("spicy_rice_noodles"),"NOODLES UI uses shared owned relic icon")
 ui.restart(42);await t.frames()

static func braised_eggplant(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._finish_battle();ui.game.state.battle_relic_drop="braised_eggplant";ui.game.state.mana=100;ui.render();await t.frames()
 t.check(await t.click("reward",{"category":"relic"}) and ui.view.mana==120 and ui.view.mana_max==120 and ui.find_child("RelicShortcut_braised_eggplant",true,false)!=null,"EGGPLANT UI claiming reward updates mana, maximum and owned relic together")
 ui.restart(42);await t.frames()

static func green_bird(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._install_special("negative_plate_lock_medium","special_2_a",2);ui.game.RelicEffects.gain(ui.game,"green_bird");ui.game.state.pressure=118
 ui.game.state.pressure_sources=[preload("res://tests/pressure_cases.gd").source("bird_test","turn_end",20)]
 ui.render();await t.frames()
 t.check(await t.click("end") and ui.view.pressure.value==119 and ui.find_child("RelicShortcut_green_bird",true,false).find_child("RelicCounter",true,false).text=="5","BIRD UI actual turn caps at current maximum minus one and updates protection")
 t.check(ui.view.pressure.sources.any(func(row):return row.name=="绿色小鸟" and row.text.contains("119")),"BIRD UI resource detail explains current protection")
 ui.restart(42);await t.frames()

static func olihakimi(t) -> void:
 var ui=t.ui
 await t.start_practice("Practice_rope_heap_solo")
 ui.game.state.relics=["olihakimi"];ui.game.state.mana=40;ui.render();await t.frames()
 var icon=ui.find_child("RelicShortcut_olihakimi",true,false)
 t.check(icon!=null,"OLI UI displays relic icon")
 await t.move_mouse(icon.get_global_rect().get_center());await t.frames()
 t.check(t.visible_text(ui.layout).contains("本回合未消耗魔力") and t.visible_text(ui.layout).contains("罕见"),"OLI UI hover shows condition and rarity")
 await t.move_mouse(Vector2(650,60));await t.frames()
 t.check(await t.click("end") and ui.game.state.mana==48,"OLI UI actual unspent turn grants eight")
 t.check(await t.click("attack",{"type":"fireball"}),"OLI UI paid spell commits")
 var mana=ui.game.state.mana
 t.check(await t.click("end") and ui.game.state.mana==mana,"OLI UI spent turn does not restore")
 ui.restart(42);await t.frames()

static func setup(t) -> void:
 t.ui.restart(42)
 t.ui.game.state.phase="prepare";t.ui.game.state.prepare_left=3
 t.ui.game.state.wall="normal"

static func give(t, type: String) -> String:
 t.ui.game._gain_card(type)
 var card=t.ui.game.state.discard.pop_back()
 t.ui.game.state.hand.append(card)
 return card.uid

static func run(t) -> void:
 await rest_reward_layout(t)
 await magnifying_glass(t)
 await oune_hand(t)
 await skip_rewards(t)
 await boss_relics(t)
 await preload("res://tests/relic_bundle_ui_cases.gd").run(t)
 await crystal_guarantee(t)
 await pressure_relics(t)
 await olihakimi(t)
 await green_bird(t)
 await braised_eggplant(t)
 await spicy_rice_noodles(t)
 await kings_gift(t)
 await rolling_log(t)
 await marble(t)
 await graduate_certificate(t)
 await periodic_counter(t)
 await battle_loot(t)
 await card_motion(t)
 await resource_feedback(t)
 await preload("res://tests/curse_ui_cases.gd").run(t)
 var ui=t.ui
 setup(t)
 var a=ui.game.add_fixture("wrist",6);var b=ui.game.add_fixture("wrist",6);var c=ui.game.add_fixture("wrist",6)
 var uid=give(t,"peel")
 ui.render();await t.frames()
 t.check(ui.view.hand.filter(func(card):return card.uid==uid)[0].cost=="2","REWARD UI two-energy card shows actual cost")
 var choice=Queries.select(ui.view,"card",{"uid":uid,"slot":"wrist","target":a.id})[0]
 await t.start_drag(uid,"wrist");await t.release_target(await t.reveal_drop_target(choice.key))
 t.check(ui.view.card_chain.is_empty() and ui.view.energy==1,"REWARD UI real peel drag pays once and completes automatic continuation")
 t.check(Queries.select(ui.view,"chain").is_empty() and not t.visible_text(ui.layout).contains("选择下一段目标"),"REWARD UI automatic slip shows no obsolete target picker")
 t.check(preload("res://tests/follow_through_cases.gd").hits(ui.game).size()==3 and ui.game._equipment(b.id).durability==6 and ui.game._equipment(c.id).durability==6,"REWARD UI three actual hits stay on surviving target")

 setup(t);uid=give(t,"peel")
 var first=ui.game.state.hand[0].uid;var second=ui.game.state.hand[1].uid
 ui.render();await t.frames()
 if not ui.card_faces.get(uid,false): await t.flip(uid)
 var card_point=t.card_point(uid)
 await t.move_mouse(card_point);await t.mouse_button(card_point,MOUSE_BUTTON_LEFT,true)
 await t.move_mouse(card_point+Vector2(0,-42),true)
 var player=ui.actor_targets.get("hero")
 t.check(player!=null,"REWARD UI player free-effect drop target exists")
 if player!=null:
  var point=player.get_global_rect().get_center()
  await t.move_mouse(point,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 else: await t.mouse_button(Vector2(1050,90),MOUSE_BUTTON_LEFT,false)
 t.check(not ui.view.pending_retain and ui.game.state.next_energy==1 and ui.game.state.hand.all(func(c):return c.retain_until==ui.game.state.tick+1),"REWARD UI free peel directly retains all remaining cards without a picker")
 t.check(ui.game.state.hand.any(func(c):return c.uid==first) and ui.game.state.hand.any(func(c):return c.uid==second) and ui.game.B.card_info("peel")[2].contains("保留全部手牌"),"REWARD UI retains the real hand and shows the complete free-face rule")

 setup(t);a=ui.game.add_fixture("thigh",4,10,true);b=ui.game.add_fixture("ankle",4,10,true);uid=give(t,"double_unlock")
 ui.render();await t.frames()
 choice=Queries.select(ui.view,"card",{"uid":uid,"slot":"thigh","target":a.id})[0]
 await t.start_drag(uid,"thigh");await t.release_target(await t.reveal_drop_target(choice.key))
 t.check(not ui.game._equipment(a.id).locked and ui.view.mana==90 and not ui.view.card_chain.is_empty(),"REWARD UI spell drag opens first real lock and pays mana once")
 var chain_before=ui.game.export_snapshot()
 await preload("res://tests/interface_ui_cases.gd").press(t,"ReleaseEffectDetails")
 t.check(ui.game.state==chain_before,"REWARD UI expanding final unlock detail does not commit or pay")
 t.check(t.visible_text(ui.layout).contains("这是最后一把锁") and not t.visible_text(ui.layout).contains("至多还可处理"),"REWARD UI final unlock segment does not promise a third lock")
 await t.capture("ui-53-double-unlock.png")
 t.check(await t.click("chain",{"target":b.id}) and not ui.game._equipment(b.id).locked and ui.view.mana==90,"REWARD UI second lock opens without another magic payment")

 setup(t);ui.game._install_assembly("wrap","left","fixture",1,1);uid=give(t,"double_unlock")
 ui.render();await t.frames()
 if not ui.card_faces.get(uid,false): await t.flip(uid)
 var route_before=ui.game.state.duplicate(true)
 var free_facts=Queries.select(ui.view,"card",{"uid":uid,"free":true})
 t.check(not free_facts.is_empty() and free_facts.all(func(choice):return choice.valid) and ui.game.hand_cast_reason()!="" and ui.game.cast_view(ui.game.Cards.cast_profile(ui.game,"double_unlock")).part=="mouth","REWARD UI double unlock retains its mouth route when the hand route is blocked")
 t.check(ui.game.state==route_before,"REWARD UI route projection does not mutate state or random counters")
 ui.game._install_template("mouth_band","mouth",24,24,false,"fixture",3,0)
 a=ui.game.add_fixture("ankle",4,10,true)
 ui.render();await t.frames()
 if ui.card_faces.get(uid,false): await t.flip(uid)
 var blocked=Queries.select(ui.view,"card",{"uid":uid,"free":false,"target":a.id})
 t.check(not blocked.is_empty() and blocked.all(func(choice):return not choice.valid and choice.reason.contains("施法成功率为0%")) and t.visible_text(ui.card_buttons[uid]).contains("施法成功率为0%"),"REWARD UI both ineffective casting routes expose the actual zero-chance reason")
 t.check(Queries.select(ui.view,"card",{"uid":uid,"free":true}).any(func(choice):return choice.valid),"REWARD UI preparation face still does not roll the bound spell chance")

 setup(t);ui.game._install_assembly("wrap","left","fixture",1,1);uid=give(t,"unlock")
 ui.render();await t.frames()
 if not ui.card_faces.get(uid,false): await t.flip(uid)
 free_facts=Queries.select(ui.view,"card",{"uid":uid,"free":true})
 t.check(not free_facts.is_empty() and free_facts.all(func(choice):return not choice.valid and choice.reason=="需要双手的手掌和手指都自由。"),"REWARD UI hand-only free spell exposes actual two-hand restriction")

 setup(t);ui.game.state.phase="reward";ui.game.state.reward_options=["tear","peel","double_unlock"]
 ui.render();await t.frames()
 t.check(Queries.select(ui.view,"reward",{"kind":"reward"}).size()==4 and ui.find_child("Reward_card",true,false)!=null and ui.find_child("RewardSkip_card",true,false)!=null and ui.find_child("RewardChoice_tear",true,false)==null,"REWARD UI begins with a compact card reward row and a separate skip action")
 ui.find_child("Reward_card",true,false).pressed.emit();await t.frames()
 t.check(ui.find_child("RewardChoice_tear",true,false)!=null,"REWARD UI row opens complete new card choices")
 await t.capture("ui-54-reward-cards.png")
 var count=ui.view.deck_count
 t.check(await t.click("reward",{"type":"tear"}) and ui.view.deck_count==count+1 and ui.view.phase=="reward" and ui.find_child("Reward_card",true,false).disabled,"REWARD UI card pickup returns to list and marks reward claimed")
 t.check(await t.click("reward",{"type":"skip"}) and ui.view.phase=="prepare","REWARD UI continue leaves rewards for preparation")
 ui.game.RelicEffects.gain(ui.game,"cursed_blindfold")
 ui.game.RelicEffects.gain(ui.game,"cursed_plate_lock")
 ui.game.state.relics=ui.game.Relics.TYPES.keys()
 ui.render();await t.frames()
 await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_LEFT,true);await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_LEFT,false)
 t.check(ui.view.relics.size()==ui.game.Relics.TYPES.size() and ui.find_child("OpenRelics",true,false)==null,"REWARD UI all actual relics are projected without a separate relic button")
 await t.capture("ui-55-relics-complete.png")
 var grid=ui.find_child("RelicRow",true,false)
 t.check(grid.get_child_count()==ui.view.relics.size(),"REWARD UI each owned relic has exactly one scene icon")
 var last=grid.get_children().back()
 var ancestor=grid.get_parent()
 while ancestor!=null and not ancestor is ScrollContainer: ancestor=ancestor.get_parent()
 t.check(ancestor!=null,"REWARD UI relic cards retain scroll access")
 if ancestor!=null:
  ancestor.scroll_horizontal=int(ancestor.get_h_scroll_bar().max_value)
  await t.frames()
  t.check(ancestor.get_global_rect().encloses(last.get_global_rect()),"REWARD UI final relic icon is fully reachable through horizontal scroll")
 var before_hover=ui.game.export_snapshot()
 for relic in ui.view.relics:
  var shortcut=ui.find_child("RelicShortcut_"+relic.id,true,false)
  ancestor.ensure_control_visible(shortcut);await t.frames()
  await t.move_mouse(shortcut.get_global_rect().get_center());await t.frames()
  t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains(relic.name) and t.visible_text(ui.term_popup).contains(relic.detail),"REWARD UI owned relic hover shows full individual description: "+relic.id)
  t.check(is_equal_approx(shortcut.global_position.y,last.global_position.y),"REWARD UI all relics remain in one row")
 t.check(ui.game.state==before_hover,"REWARD UI inspecting all relics never changes gameplay")
 await t.capture("ui-55-relics-scrolled.png")

static func skip_rewards(t) -> void:
 var ui=t.ui
 var pointer=preload("res://tests/target_sidebar_ui_cases.gd")
 for boss in [false,true]:
  ui.restart(78)
  if boss: ui.game.state.room="summit";ui.game._start_battle()
  else: ui.game.state.room_encounters[ui.game.state.room]="guard_solo";ui.game.state.item_drop_chance=100
  ui.game._finish_battle();ui.render();await t.frames()
  var before=ui.game.export_snapshot()
  await pointer.press(t,ui.find_child("Reward_card",true,false))
  t.check(ui.find_child("RewardSkip_card",true,false)!=null and ui.show_reward_cards,"SKIP UI card selection has a visible skip button")
  await pointer.press(t,ui.find_child("RewardSkip_card",true,false))
  t.check(not ui.show_reward_cards and ui.game.state.phase=="reward" and ui.find_child("Reward_card",true,false).disabled and t.visible_text(ui.find_child("Reward_card",true,false)).contains("已跳过"),"SKIP UI card skip returns to overview and labels the result accurately")
  if boss:
   await pointer.press(t,ui.find_child("Reward_relic",true,false))
   t.check(ui.show_reward_relics and ui.find_child("RewardSkip_relic",true,false)!=null,"SKIP UI Boss selection has the same visible skip action")
   await t.capture("ui-rewards-unified.png")
  await pointer.press(t,ui.find_child("RewardSkip_relic",true,false))
  t.check(ui.game.state.relics==before.relics and ui.game.state.deck==before.deck and ui.game.state.rng==before.rng and ui.game.state.reward_claimed.relic=="skip" and not ui.show_reward_relics,"SKIP UI normal and Boss relics skip without pickup effects or random redraw")
  if not boss: t.check(await t.click("reward",{"category":"item"}),"SKIP UI remaining item reward stays claimable")
  await pointer.press(t,ui.find_child("RewardContinue",true,false))
  t.check(ui.view.phase=="prepare" and ui.find_child("BattleRewards",true,false)==null,"SKIP UI continue finishes the shared reward popup")

static func battle_loot(t) -> void:
 var ui=t.ui
 ui.restart(78)
 ui.game.state.room_encounters[ui.game.state.room]="guard_solo"
 ui.game.state.item_drop_chance=100
 ui.game._finish_battle();ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 t.check(ui.view.battle_rewards.size()==3 and ui.find_child("Reward_item",true,false)!=null and ui.find_child("Reward_relic",true,false)!=null,"LOOT UI real elite victory renders three independent reward rows")
 await t.capture("ui-reward-list.png")
 var row=ui.find_child("Reward_card",true,false)
 var point=row.get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.show_reward_cards and ui.find_child("RewardBack",true,false)!=null and ui.game.state==before,"LOOT UI native row click opens choices without changing state")
 # The reward card choice is a real card face (docs/spec/card-terms.md「触发面」): hovering it must
 # show one box per term of the face it displays, next to the card and never over it.
 var choice_face=ui.find_child("RewardChoice_"+ui.game.state.reward_options[0],true,false)
 var choice_terms=preload("res://data/balance.gd").card_metadata(ui.game.state.reward_options[0]).face_keywords["free" if choice_face.free_face else "bound"]
 t.check(not choice_terms.is_empty(),"LOOT UI reward choice fixture carries face terms: "+ui.game.state.reward_options[0])
 await t.move_mouse(choice_face.get_global_rect().get_center());await t.frames()
 var choice_popup=ui.find_child("TermExplanation",true,false)
 t.check(choice_popup!=null and preload("res://tests/interface_ui_cases.gd").term_boxes(choice_popup)==choice_terms,"LOOT UI reward choice hover boxes equal the hovered face terms: "+str(preload("res://tests/interface_ui_cases.gd").term_boxes(choice_popup)))
 var choice_rect=choice_popup.get_global_rect() if choice_popup!=null else Rect2()
 t.check(choice_popup!=null and not choice_rect.intersects(choice_face.get_global_rect()),"LOOT UI reward choice term boxes clear the anchor card")
 var card=ui.find_child("RewardChoice_"+ui.game.state.reward_options[0],true,false)
 point=card.get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(ui.card_faces.get("reward_"+ui.game.state.reward_options[0],false) and ui.game.state==before,"LOOT UI reward right-click flips card without spending reward")
 var back=ui.find_child("RewardBack",true,false)
 point=back.get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(not ui.show_reward_cards and ui.game.state==before,"LOOT UI native back button preserves rewards and RNG")
 var item=ui.find_child("Reward_item",true,false)
 var item_count=ui.view.items.size()
 point=item.get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.view.items.size()==item_count+1 and ui.find_child("Reward_item",true,false).disabled and ui.view.phase=="reward","LOOT UI native item click grants and disables only its row")
 t.check(await t.click("reward",{"category":"relic"}) and ui.find_child("Reward_relic",true,false).disabled,"LOOT UI relic claim uses real reward candidate")
 t.check(await t.click("reward",{"category":"card"}) and ui.find_child("Reward_card",true,false).disabled,"LOOT UI card choice returns to claimed list")
 await t.move_mouse(Vector2(1500,800))
 await t.capture("ui-reward-claimed.png")
 t.check(await t.click("reward",{"type":"skip"}) and ui.view.phase=="prepare" and ui.find_child("BattleRewards",true,false)==null,"LOOT UI continue closes loot and enters preparation")

static func kings_gift(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.relics=["kings_gift_revised"];ui.game.state.round=7
 for e in ui.game.state.enemies: e.hp=100;e.max_hp=100
 ui.render();await t.frames()
 var shortcut=ui.find_child("RelicShortcut_kings_gift_revised",true,false)
 t.check(shortcut!=null and shortcut.find_child("RelicCounter",true,false).text=="7","KING UI shows current battle round on relic icon")
 t.check(await t.click("end") and ui.view.enemies.all(func(e):return e.hp==23),"KING UI real seventh ending shows damage to every enemy")
 shortcut=ui.find_child("RelicShortcut_kings_gift_revised",true,false)
 t.check(shortcut.find_child("RelicCounter",true,false).text=="✓","KING UI counter switches to fired after committed ending")
 ui.restart(42);await t.frames()

static func marble(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.relics=["ember","marble"];ui.game.state.mana=60
 for enemy in ui.game.state.enemies: enemy.hp=0;enemy.gone=true
 ui.game.state.enemies[0].hp=1;ui.game.state.enemies[0].gone=false
 ui.render();await t.frames()
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.game.state.enemies[0].id}),"MARBLE UI lethal attack uses real action")
 t.check(ui.view.phase=="reward" and ui.view.mana==50 and ui.find_child("RelicShortcut_marble",true,false)!=null,"MARBLE UI victory defers both ending relics")
 t.check(await t.click("reward",{"type":"skip"}) and ui.view.mana==50,"MARBLE UI preparation entry does not heal")
 t.check(await t.click("finish_prepare") and ui.view.mana==80,"MARBLE UI preparation finish heals before pendant once")
 ui.restart(42);await t.frames()

static func resource_feedback(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 var energy=ui.view.energy
 var spell=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.game.state.enemies[0].id})
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.game.state.enemies[0].id}),"FX UI ordinary spell commits")
 t.check(ui.find_child("EnergyValue",true,false).text==str(ui.view.energy) and ui.view.energy==energy-spell.cost,"FX UI first fireball immediately displays its actual energy payment during mana animation")
 t.check(not ui.resource_feedback.shown.has("energy") and ui.resource_feedback.pending.all(func(event):return event.field!="energy") and ui.resource_feedback.active.get("field","")!="energy","FX UI energy has no float or interpolation queue")
 ui.restart(42);ui.game.state.mana=60
 for enemy in ui.game.state.enemies: enemy.hp=0;enemy.gone=true
 ui.game.state.enemies[0].hp=1;ui.game.state.enemies[0].gone=false
 ui.render();await t.frames()
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.game.state.enemies[0].id}),"FX UI lethal spell uses actual button")
 var committed=ui.game.export_snapshot()
 t.check(ui.view.phase=="reward" and ui.view.mana==50 and is_instance_valid(ui.resource_feedback),"FX UI presentation survives transition to reward")
 var presenter=ui.resource_feedback
 ui.render();await t.frames()
 t.check(ui.resource_feedback==presenter and (not presenter.pending.is_empty() or not presenter.active.is_empty()),"FX UI ordinary repaint preserves queued effects")
 var deadline=Time.get_ticks_msec()+9000
 var saw_decrease=false
 while (not presenter.active.is_empty() or not presenter.pending.is_empty()) and Time.get_ticks_msec()<deadline:
  if not saw_decrease and presenter.shown.get("mana",60)<56:
   saw_decrease=true
   await t.capture("ui-resource-feedback-spend.png")
  await t.process_frame
 t.check(saw_decrease and ui.find_child("MainManaValue",true,false).text=="50/100","FX UI mana visibly decreases to actual payment total")
 t.check(ui.game.export_snapshot()==committed and presenter.pending.is_empty() and presenter.active.is_empty(),"FX UI animation never modifies committed state")
 await t.capture("ui-resource-feedback-complete.png")

static func card_motion(t) -> void:
 setup(t)
 var ui=t.ui
 t.check(ui.card_buttons.values().all(func(card):return not card.visible),"DRAW UI initial hand stays hidden before dealing")
 var initial_state=ui.game.export_snapshot()
 ui.render();await t.frames(2,false)
 t.check(ui.card_buttons.values().all(func(card):return not card.visible),"DRAW UI redraw cannot reveal undealt cards")
 var deal_deadline=Time.get_ticks_msec()+2500
 while ui.card_buttons.values().all(func(card):return not card.visible) and Time.get_ticks_msec()<deal_deadline: await t.process_frame
 t.check(ui.card_buttons.values().any(func(card):return card.visible) and ui.card_buttons.values().any(func(card):return not card.visible),"DRAW UI cards become available one at a time")
 await t.capture("ui-sequential-deal.png")
 while not ui.card_motion.pending_draws.is_empty() and Time.get_ticks_msec()<deal_deadline: await t.process_frame
 t.check(ui.card_buttons.values().all(func(card):return card.visible) and ui.game.export_snapshot()==initial_state,"DRAW UI all cards appear after arrivals without changing game state")
 ui.game.state.discard.append_array(ui.game.state.draw);ui.game.state.draw.clear()
 ui.render();await t.frames()
 t.check(await t.click("end",{},false),"CARD FX UI real end-turn triggers transfers")
 var committed=ui.game.export_snapshot()
 var layer=ui.card_motion
 t.check(is_instance_valid(layer) and layer.get_child_count()>0 and layer.mouse_filter==Control.MOUSE_FILTER_IGNORE,"CARD FX UI moving cards are present without capturing input")
 ui.render();await t.frames(2,false)
 t.check(is_instance_valid(layer) and layer.get_child_count()>0,"CARD FX UI ordinary render preserves in-flight cards")
 await t.capture("ui-card-transfers.png")
 var deadline=Time.get_ticks_msec()+3500
 while layer.get_child_count()>0 and Time.get_ticks_msec()<deadline: await t.process_frame
 t.check(layer.get_child_count()==0 and ui.game.export_snapshot()==committed,"CARD FX UI completes without changing committed cards or energy")
 var uid=give(t,"panic");ui.render();await t.frames()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,uid)
 t.check(ui.game.state.exhaust.any(func(card):return card.uid==uid),"CARD FX UI plays consumable through actual button")
 t.check(layer.find_child("CardMotion_play_exhaust_"+uid,true,false)!=null,"CARD FX UI consumable uses exhaust animation")
 ui.restart(42);await t.frames()
 t.check(not is_instance_valid(layer),"CARD FX UI restart clears old animation layer")

static func graduate_certificate(t) -> void:
 var ui=t.ui
 setup(t)
 var strain=give(t,"strain");var slip=give(t,"slip")
 ui.render();await t.frames()
 for uid in [strain,slip]:
  if ui.card_buttons[uid].free_face: await t.flip(uid)
  t.check(t.visible_text(ui.card_buttons[uid]).contains(("挣扎" if uid==strain else "滑脱")+"6"),"BASIC UI hand faces print six before pickup")
 ui.game.RelicEffects.gain(ui.game,"graduate_certificate");ui.render();await t.frames()
 for uid in [strain,slip]:
  if ui.card_buttons[uid].free_face: await t.flip(uid)
  t.check(t.visible_text(ui.card_buttons[uid]).contains(("挣扎" if uid==strain else "滑脱")+"10"),"DIPLOMA UI hand face prints ten after pickup")
 var before=ui.game.export_snapshot()
 await preload("res://tests/interface_ui_cases.gd").press(t,"OpenDeck")
 for uid in [strain,slip]:
  var face=ui.find_child("DisplayCard_deck_"+uid,true,false)
  t.check(face!=null and t.visible_text(face).contains(("挣扎" if uid==strain else "滑脱")+"10"),"DIPLOMA UI deck overview uses current enhanced card value")
 await t.capture("ui-graduate-certificate-deck.png")
 await t.close_information()
 var shortcut=ui.find_child("RelicShortcut_graduate_certificate",true,false)
 await t.move_mouse(shortcut.get_global_rect().get_center());await t.frames()
 t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains("优秀学员毕业证书") and t.visible_text(ui.term_popup).contains("罕见") and t.visible_text(ui.term_popup).contains("＋4"),"DIPLOMA UI relic hover gives rarity and printed bonus")
 t.check(ui.game.export_snapshot()==before and preload("res://ui/relic_icon.gd").ART.has("graduate_certificate"),"DIPLOMA UI inspection remains read-only with dedicated certificate icon")
 ui.restart(42);await t.frames()

static func rolling_log(t) -> void:
 var ui=t.ui
 ui.restart(42)
 ui.game.RelicEffects.gain(ui.game,"rolling_log");ui.game.RelicEffects.gain(ui.game,"rolling_log");ui.render();await t.frames()
 var shortcut=ui.find_child("RelicShortcut_rolling_log",true,false)
 var before=ui.game.export_snapshot()
 await t.move_mouse(shortcut.get_global_rect().get_center());await t.frames()
 t.check(ui.find_children("RelicShortcut_rolling_log","",true,false).size()==1 and shortcut.find_child("RelicCounter",true,false).text=="2","LOG UI collectible uses one icon with quantity badge")
 t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains("特殊") and t.visible_text(ui.term_popup).contains("没有效果") and t.visible_text(ui.term_popup).contains("持有2件") and ui.game.state==before,"LOG UI hover explains no effect and count without changing state")
 await t.capture("ui-rolling-log.png")
 ui.game.state.relics.append_array(ui.game.Relics.REWARDS)
 ui.game.state.room_encounters[ui.game.state.room]="guard_solo";ui.game._finish_battle();ui.render();await t.frames()
 var dropped=ui.game.state.battle_relic_drop
 var copies=int(ui.game.state.relic_counters.get(dropped,1))
 t.check(dropped in ["rolling_log","intellect_cloak"] and ui.find_child("Reward_relic",true,false)!=null and t.visible_text(ui.find_child("Reward_relic",true,false)).contains(ui.game.Relics.TYPES[dropped].name),"LOG UI elite exhaustion displays the frozen tier fallback reward")
 t.check(await t.click("reward",{"category":"relic"}) and ui.find_child("RelicShortcut_"+dropped,true,false).find_child("RelicCounter",true,false).text==str(copies+1) and ui.find_child("Reward_relic",true,false).disabled,"LOG UI real claim increments the offered collectible and disables the claimed reward")
 ui.restart(42)
 for count in range(3): ui.game.RelicEffects.gain(ui.game,"rolling_log")
 ui.game.state.relics.append_array(ui.game.Relics.shop_pool())
 ui.game.state.room=ui.game.state.rooms.filter(func(room):return room.kind=="shop")[0].id
 ui.game.state.flask_mana=200;ui.game.Services.start(ui.game);ui.shop_payment="flask";ui.render();await t.frames()
 var flask_before=ui.game.state.flask_mana
 var offers=ui.view.shop.stock.filter(func(offer):return offer.kind=="relic")
 t.check(offers.size()==3 and offers.all(func(offer):return offer.type in ["rolling_log","intellect_cloak"] and offer.rarity_name==("普通" if offer.type=="intellect_cloak" else "特殊")),"LOG UI exhausted shop displays three fallback slots with their actual rarity")
 var quoted_payment=0.0
 for offer in offers:
  copies=int(ui.game.state.relic_counters.get(offer.type,1))
  quoted_payment+=offer.price
  t.check(await t.click("service",{"op":"take","index":offer.index,"payment":"flask"}) and ui.find_child("ShopOffer%d" % offer.index,true,false).disabled,"LOG UI each fallback slot has an independent real purchase button")
  var icons=ui.find_children("RelicShortcut_"+offer.type,"",true,false)
  t.check(icons.size()==1 and icons[0].find_child("RelicCounter",true,false).text==str(copies+1),"LOG UI each purchase increments only its collectible badge")
 t.check(ui.view.mana_flask.mana==flask_before-quoted_payment,"LOG UI purchases pay the displayed prices including owned relic discounts")
 ui.restart(42);await t.frames()

static func pressure_relics(t) -> void:
 var ui=t.ui
 ui.restart(42)
 for id in ["ice_heart","magic_blood"]: ui.game.RelicEffects.gain(ui.game,id)
 ui.game.state.pressure=10;ui.render();await t.frames()
 for id in ["ice_heart","magic_blood"]:
  var icon=ui.find_child("RelicShortcut_"+id,true,false)
  t.check(icon!=null and preload("res://ui/relic_icon.gd").ART.has(id),"PRESSURE RELIC UI shared icon is present")
  var before=ui.game.export_snapshot()
  await t.move_mouse(icon.get_global_rect().get_center());await t.frames()
  t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains(ui.game.Relics.TYPES[id].name) and ui.game.state==before,"PRESSURE RELIC UI hover explains relic without changing state")
 await t.move_mouse(Vector2(650,60));await t.frames()
 t.check(Queries.find(ui.view,"attack",{"type":"strike","form":0,"enemy":ui.selected_enemy}).payload.damage==10,"MAGIC BLOOD UI previews strength plus two damage")
 t.check(await t.click("end") and ui.game.state.pressure==10,"PRESSURE RELIC UI real end turn reduces three, adds five, then free-state relief lowers two")
 ui.restart(42);await t.frames()

static func crystal_guarantee(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.RelicEffects.gain(ui.game,"ember_crystal");ui.game.state.pressure=75
 ui.render();await t.frames()
 var c=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 t.check(c.valid and c.casting.percent=="100%" and c.casting.formula.contains("余烬晶石"),"CRYSTAL UI first paid spell displays actual guaranteed chance")
 var icon=ui.find_child("RelicShortcut_ember_crystal",true,false)
 await t.move_mouse(icon.get_global_rect().get_center());await t.frames()
 t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains("每回合首次耗魔施法必定成功"),"CRYSTAL UI shared description shows new effect")
 await t.move_mouse(Vector2(650,60));await t.frames()
 var mana=ui.game.state.mana
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy}) and ui.game.state.mana==mana-c.mana and not ui.game._magic_failed,"CRYSTAL UI actual cast pays full price and succeeds")
 t.check(Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy}).casting.chance<1,"CRYSTAL UI remaining casts show ordinary probability")
 t.check(await t.click("end") and Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy}).casting.percent=="100%","CRYSTAL UI new turn restores guarantee")
 ui.restart(42);await t.frames()

static func boss_relics(t) -> void:
 var ui=t.ui
 ui.restart(42)
 ui.game.state.room="summit";ui.game._start_battle()
 ui.game.state.item_drop_chance=100
 for enemy in ui.game.state.enemies: ui.game._damage_enemy(enemy,1000,"physical","测试")
 ui.game._finish_if_saturated()
 ui.render();await t.frames()
 var flask=ui.find_child("Reward_flask",true,false)
 var next=ui.find_child("RewardContinue",true,false)
 t.check(ui.view.battle_rewards.size()==4 and flask!=null and t.visible_text(flask).contains("80 魔瓶魔力"),"BOSS UI four independent rewards include the eighty-mana flask row")
 t.check(flask.position.y+flask.size.y<next.position.y and next.position.y+next.size.y<900,"BOSS UI four reward rows do not overlap continue or leave the viewport")
 await t.capture("ui-boss-flask-reward.png")
 var mana=ui.game.state.flask_mana
 t.check(await t.click("reward",{"category":"flask"}) and ui.game.state.flask_mana==mana+80 and ui.find_child("Reward_flask",true,false).disabled and ui.view.phase=="reward","BOSS UI click credits flask once and stays in reward list")
 var offered=ui.game.state.boss_relic_options.duplicate()
 ui.find_child("Reward_relic",true,false).pressed.emit();await t.frames()
 var buttons=[]
 for id in offered:
  var button=ui.find_child("BossRelicChoice_"+id,true,false)
  t.check(button!=null and button.is_visible_in_tree() and t.visible_text(button).contains(ui.game.Relics.TYPES[id].detail),"BOSS UI visible icon, name and effect for "+id)
  buttons.append(button)
 var snapshot=ui.game.export_snapshot()
 ui.find_child("RewardBack",true,false).pressed.emit();await t.frames()
 t.check(ui.game.state==snapshot,"BOSS UI closing choices does not reroll or collect")
 var card=Queries.select(ui.view,"reward",{"category":"card"})[0]
 t.check(await t.click("reward",{"category":"card","type":card.payload.type}),"BOSS UI rare card reward remains independent")
 ui.find_child("Reward_relic",true,false).pressed.emit();await t.frames()
 t.check(ui.show_reward_relics and ui.find_child("BossRelicChoice_"+offered[0],true,false)!=null,"BOSS UI relic chooser opens after card reward was claimed")
 await t.capture("ui-boss-relic-choices.png")
 ui.find_child("BossRelicChoice_"+offered[0],true,false).pressed.emit();await t.frames()
 if offered[0]=="nesting_doll":
  ui.find_child("BundleContinue",true,false).pressed.emit();await t.frames()
 t.check(offered[0] in ui.game.state.relics and not ui.show_reward_relics and ui.find_child("Reward_relic",true,false).disabled,"BOSS UI selects exactly one relic and returns to claimed reward")
 ui.restart(42);await t.frames()

static func oune_hand(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 ui.game.state.energy=6
 ui.game.RelicEffects.gain(ui.game,"oune_hand")
 var gift=ui.game.state.discard.filter(func(c):return c.type=="magic_hand_gift")[0]
 ui.game.state.discard.erase(gift);ui.game.state.hand.append(gift)
 var normal=preload("res://tests/curse_cases.gd").give(ui.game,"magic_hand")
 ui.render();await t.frames()
 t.check(ui.find_child("RelicShortcut_oune_hand",true,false)!=null and ui.card_buttons[gift.uid].get_node("CardIllustration").texture!=null,"OUNE UI shows relic and gifted card artwork")
 for free in [false,true]:
  if ui.card_faces.get(gift.uid,false)!=free: await t.flip(gift.uid)
  if ui.card_faces.get(normal.uid,false)!=free: await t.flip(normal.uid)
  var text=t.visible_text(ui.card_buttons[gift.uid])
  t.check(not text.contains("消耗") and t.visible_text(ui.card_buttons[normal.uid]).contains("消耗") and text.contains("下2次手部体术" if free else "超级顺延"),"OUNE UI only gifted copy omits exhaust on both real card faces")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,gift.uid)
 t.check(ui.game.state.card_buff_uses.get("magic_hand_free",0)==2 and ui.game.state.mana==80 and ui.game.state.discard.any(func(c):return c.uid==gift.uid) and not ui.game.state.exhaust.any(func(c):return c.uid==gift.uid),"OUNE UI native gifted card use pays and goes to discard")
 for i in range(2):
  t.check(await t.click("attack",{"type":"strike","form":0,"enemy":ui.selected_enemy}),"OUNE UI real hand attacks consume the existing two-use effect")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,normal.uid)
 t.check(ui.game.state.card_buff_uses.get("magic_hand_free",0)==2 and ui.game.state.exhaust.any(func(c):return c.uid==normal.uid) and ui.game.state.discard.any(func(c):return c.uid==gift.uid),"OUNE UI ordinary copy still exhausts alongside reusable gift")

static func rest_reward_layout(t) -> void:
 var ui=t.ui
 var Pointer=preload("res://tests/target_sidebar_ui_cases.gd")
 for kind in ["rest_rare","rest_card","rest_flask","rest_begin"]:
  ui.restart(42);ui.game.state.room="rest";ui.game._start_rest();ui.render();await t.frames()
  var before=ui.game.export_snapshot()
  var controls=[ui.find_child("Reward_card_uncommon",true,false),ui.find_child("Reward_card_rare",true,false),ui.find_child("Reward_item_flask",true,false)]
  t.check(controls.all(func(button):return button!=null and button.size==Vector2(656,94)) and controls.all(func(button):return button.position.x==controls[0].position.x),"REST UI three options share reward-card width, height and alignment")
  t.check(controls[1].position.y-controls[0].position.y==controls[2].position.y-controls[1].position.y and controls.all(func(button):return ui.get_viewport_rect().encloses(button.get_global_rect())),"REST UI rows have equal spacing and stay on screen")
  t.check(ui.find_child("RewardSkip_card_uncommon",true,false)==null and ui.find_child("RewardSkip_card_rare",true,false)==null and ui.find_child("RewardExtra_rest_rare",true,false)==null and ui.find_child("RewardExtra_rest_flask",true,false)==null and ui.find_child("RewardContinue",true,false).text.contains("休息6回合"),"REST UI has one clear skip footer without old detached actions")
  t.check(controls.all(func(button):return t.visible_text(button).contains("花费3回合")) and ui.game.state==before,"REST UI costs are visible without changing frozen choices or resources")
  if kind=="rest_rare": await t.capture("ui-rest-rewards.png")
  if kind=="rest_card":
   await Pointer.press(t,ui.find_child("Reward_card_uncommon",true,false))
   var cards=Queries.select(ui.view,"rest_service").filter(func(c):return c.payload.kind=="rest_card")
   t.check(cards.size()==3 and cards.all(func(c):return ui.find_child("RewardChoice_"+c.payload.type,true,false)!=null and ui.game.Cards.Rules.SPECS[c.payload.type].rarity=="uncommon"),"REST UI opens the three frozen uncommon choices")
   await Pointer.press(t,ui.find_child("RewardBack",true,false))
   t.check(ui.game.state==before,"REST UI returning from card choices neither pays nor rerolls")
  var selection={"type":before.rest_cards[0]} if kind=="rest_card" else {}
  t.check(await t.click(kind,selection),"REST UI shared reward control dispatches formal action: "+kind)
  var expected=6 if kind=="rest_begin" else 3
  t.check(ui.game.state.phase=="rest" and ui.game.state.rest_left==expected,"REST UI selection enters rest with exact remaining turns: "+kind)
  if kind=="rest_rare": t.check(ui.game.state.deck.size()==before.deck.size()+1 and ui.game.Cards.Rules.SPECS[ui.game.state.deck[-1].type].rarity=="rare","REST UI random card row grants one actual rare card")
  elif kind=="rest_card": t.check(ui.game.state.deck.size()==before.deck.size()+1 and ui.game.state.deck[-1].type==selection.type and ui.game.state.flask_mana==before.flask_mana,"REST UI grants exactly the selected uncommon card without changing the flask")
  elif kind=="rest_flask": t.check(ui.game.state.flask_mana==before.flask_mana+50 and ui.game.state.deck==before.deck,"REST UI flask row adds fifty only to flask and leaves deck unchanged")
  else: t.check(ui.game.state.deck==before.deck and ui.game.state.flask_mana==before.flask_mana,"REST UI skip keeps deck and flask unchanged")
 ui.restart(42);ui.game.state.room="rest";ui.game._start_rest();ui.game.state.rest_left=2;ui.render();await t.frames()
 for id in ["Reward_card_uncommon","Reward_card_rare","Reward_item_flask"]:
  var button=ui.find_child(id,true,false)
  t.check(button.disabled and t.visible_text(button).contains("休息回合不足"),"REST UI insufficient time disables option with visible reason: "+id)
 await Pointer.press(t,ui.find_child("RewardContinue",true,false))
 t.check(ui.game.state.phase=="rest" and ui.game.state.rest_left==2,"REST UI insufficient-time screen still permits free skip")

static func magnifying_glass(t) -> void:
 var ui=t.ui
 var Pointer=preload("res://tests/target_sidebar_ui_cases.gd")
 ui.restart(42);ui.game._finish_battle();ui.game.state.battle_relic_drop="magnifying_glass";ui.render();await t.frames()
 var original=ui.game.state.reward_options.duplicate()
 t.check(await t.click("reward",{"category":"relic"}) and ui.game.state.reward_options==original,"LENS UI pickup keeps same-window card options")
 t.check(ui.find_child("RelicShortcut_magnifying_glass",true,false)!=null and preload("res://ui/relic_icon.gd").ART.has("magnifying_glass"),"LENS UI shared relic artwork appears in owned row")
 await Pointer.press(t,ui.find_child("Reward_card",true,false))
 t.check(original.size()==3 and original.all(func(id):return ui.find_child("RewardChoice_"+id,true,false)!=null),"LENS UI current window still displays only original three")
 await Pointer.press(t,ui.find_child("RewardBack",true,false))
 await t.click("reward",{"type":"skip"})
 ui.game.state.phase="battle";ui.game._finish_battle();ui.render();await t.frames()
 await Pointer.press(t,ui.find_child("Reward_card",true,false))
 var offered=ui.game.state.reward_options.duplicate();var before=ui.game.export_snapshot()
 t.check(offered.size()==4 and offered.all(func(id):return ui.find_child("RewardChoice_"+id,true,false)!=null) and ui.find_child("RewardSkip_card",true,false)!=null,"LENS UI next reward exposes four choices and skip")
 var previous: Control=null
 for id in offered:
  var card=ui.find_child("RewardChoice_"+id,true,false)
  var rect=card.get_global_rect()
  t.check(ui.get_viewport_rect().encloses(rect) and (previous==null or not previous.get_global_rect().intersects(rect)),"LENS UI four cards fit without overlap")
  previous=card
 await t.capture("ui-magnifying-glass-reward.png")
 await Pointer.press(t,ui.find_child("RewardBack",true,false))
 t.check(ui.game.state==before,"LENS UI back preserves all four identities and random state")
 await Pointer.press(t,ui.find_child("Reward_card",true,false))
 var size=ui.game.state.deck.size()
 await Pointer.press(t,ui.find_child("RewardChoice_"+offered[-1],true,false))
 t.check(ui.game.state.deck.size()==size+1 and ui.game.state.deck[-1].type==offered[-1],"LENS UI clicking fourth card grants exactly that card")
 ui.restart(42);ui.game.RelicEffects.gain(ui.game,"magnifying_glass");ui.game.state.room="rest";ui.game._start_rest();ui.render();await t.frames()
 t.check(t.visible_text(ui.layout).contains("随机获得1张稀有卡") and t.visible_text(ui.layout).contains("罕见卡4选1"),"LENS UI expands uncommon choices but keeps a single random rare")
 await Pointer.press(t,ui.find_child("Reward_card_uncommon",true,false))
 await Pointer.press(t,ui.find_child("RewardSkip_card_uncommon",true,false))
 t.check(ui.game.state.phase=="rest" and ui.game.state.rest_left==ui.game.B.REST_TURNS,"LENS UI expanded rewards still allow skipping without cost")
 ui.restart(42);await t.frames()
