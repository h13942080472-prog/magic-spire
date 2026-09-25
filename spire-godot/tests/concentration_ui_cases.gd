extends RefCounted
const Click=preload("res://tests/interface_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 ui.game.state.wall="normal";ui.game.state.wall_distance=0
 var target=ui.game.add_fixture("ankle",400.0,1000.0)
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"concentration")
 var twin=preload("res://tests/curse_cases.gd").give(ui.game,"concentration")
 ui.card_faces[card.uid]=false;ui.card_faces[twin.uid]=false
 ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await t.flip(card.uid)
 var face=ui.card_buttons[card.uid]
 t.check(ui.card_faces[card.uid] and not face.effect_free and t.visible_text(face).contains("拘束2") and t.visible_text(face).contains("滑脱6") and ui.game.state==before,"CONCENTRATION UI native flip changes only face and correctly labels second bound effect")
 await t.drop_card_on_actor(card.uid,"hero")
 t.check(ui.player_pick and ui.game.state==before,"CONCENTRATION UI second face opens target selection instead of applying a free effect")
 await Click.press(t,"PlayerPart_ankle")
 var candidate=Queries.find(ui.view,"card",{"uid":card.uid,"target":target.id,"free":true})
 t.check(ui.selected_candidate==String(candidate.get("key","")) and ui.drop_targets.is_empty(),"CONCENTRATION UI single equipment auto-selects the current face without another target step")
 var summary=t.visible_text(ui.find_child("EquipmentDetails",true,false))
 t.check(summary.contains(candidate.release_preview.headline) and summary.contains(candidate.release_preview.change),"CONCENTRATION UI collapsed second-face summary shows the formal outcome")
 await Click.press(t,"ReleaseEffectDetails")
 t.check(t.visible_text(ui.find_child("EquipmentDetails",true,false)).contains(ui.game.candidate_detail(candidate)),"CONCENTRATION UI selected second-face preview uses the formal candidate")
 await Click.press(t,"PlaySelectedCard");await t.frames()
 t.check(ui.game.Cards.base_damage(ui.game,card.type,card.uid)==9 and ui.game.state.energy==before.energy-1,"CONCENTRATION UI selected slip executes once and grows once")
 preload("res://tests/concentration_cases.gd").redraw(ui.game,card)
 ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 face=ui.card_buttons[card.uid]
 t.check(t.visible_text(face).contains("滑脱9") and t.visible_text(ui.card_buttons[twin.uid]).contains("挣扎6"),"CONCENTRATION UI redraw preserves growth and a second copy stays at six")
 await t.capture("ui-concentration.png")
 await Click.press(t,"OpenDeck")
 var browser=ui.find_child("DeckBrowser",true,false)
 var physical=browser.grid.get_children().filter(func(button):return button.get_meta("physical_uid","")==card.uid)
 t.check(physical.size()==1 and t.visible_text(physical[0]).contains("挣扎9"),"CONCENTRATION UI deck browser uses live physical card growth")
 await Click.press(t,"CloseDrawer")
 var grown=ui.game.state.hand.filter(func(entry):return entry.uid==card.uid)[0]
 ui.game.state.hand.erase(grown);ui.game.state.discard.append(grown)
 ui.render();await t.frames()
 var discarded=ui.game.export_snapshot()
 t.check(ui.view.card_texts.has(card.type) and not ui.view.card_instances.has(card.uid),"CONCENTRATION UI fixture keeps a same-type hand card while the grown copy is outside the hand")
 for entry_point in ["OpenDeck","DiscardPileButton"]:
  await Click.press(t,entry_point)
  browser=ui.find_child("DeckBrowser",true,false)
  physical=browser.grid.get_children().filter(func(button):return button.get_meta("physical_uid","")==card.uid)
  t.check(physical.size()==1 and t.visible_text(physical[0]).contains("挣扎9"),"CONCENTRATION UI non-hand growth survives same-type hand projection: "+entry_point)
  if physical.size()==1:
   physical[0].flip_requested.emit();await t.frames()
   t.check(t.visible_text(physical[0]).contains("滑脱9"),"CONCENTRATION UI non-hand second face retains its physical growth: "+entry_point)
   physical[0].flip_requested.emit();await t.frames()
  await Click.press(t,"CloseDrawer")
 t.check(ui.game.export_snapshot()==discarded,"CONCENTRATION UI pile browsing and flips do not change state or random domains")
