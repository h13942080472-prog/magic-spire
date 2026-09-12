extends RefCounted

static func press(t, name: String) -> void:
 var button=t.ui.find_child(name,true,false)
 t.check(button!=null and button.is_visible_in_tree(),"INTERFACE actual navigation button available: "+name)
 if button==null: return
 var point=button.get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)

static func run(t) -> void:
 await run_header(t)
 await card_illustrations(t)
 await deck_browser(t)
 await deck_sorting(t)
 await pile_browsers(t)
 var ui=t.ui
 ui.restart(42);await t.frames()
 var scene_id=ui.layout.get_instance_id()
 var hand_ids=ui.card_buttons.values().map(func(card):return card.get_instance_id())
 var before=JSON.stringify(ui.game.state)
 t.check(ui.find_child("OpenRestart",true,false)==null and ui.find_child("OpenSaves",true,false)==null,"INTERFACE secondary controls are inside menu, not repeated in header")
 await t.open_menu()
 await t.capture("ui-71-game-menu.png")
 await press(t,"OpenLog")
 t.check(ui.show_log and not ui.show_menu and ui.find_children("InformationDrawer","",true,false).size()==1,"INTERFACE menu hands off to one log panel")
 await press(t,"OpenItems")
 t.check(ui.show_items and not ui.show_log,"INTERFACE direct tab replaces prior panel")
 await press(t,"OpenStatus")
 t.check(ui.show_pressure and not ui.show_items,"INTERFACE status tab replaces items")
 await press(t,"OpenDeck")
 t.check(ui.show_deck and not ui.show_pressure,"INTERFACE deck tab replaces status")
 var deck_card=ui.find_child("DisplayCard_deck_*",true,false)
 t.check(deck_card!=null and deck_card.get_script()==preload("res://ui/elements/card_face.gd") and deck_card.drag_payload.is_empty(),"DECK uses hand face without gameplay drag")
 deck_card.flip_requested.emit();await t.frames()
 t.check(deck_card.free_face and JSON.stringify(ui.game.state)==before,"DECK flip preserves game state")
 await t.capture("ui-72-unified-drawer.png")
 var inside=Vector2(1450,640)
 await t.move_mouse(inside);await t.mouse_button(inside,MOUSE_BUTTON_LEFT,true);await t.mouse_button(inside,MOUSE_BUTTON_LEFT,false)
 t.check(ui.show_deck,"INTERFACE clicking inside panel never triggers outside dismissal")
 # Wide deck covers the action area; the remaining outside strip dismisses only.
 var point=Vector2(1570,600)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(not ui.show_deck and JSON.stringify(ui.game.state)==before,"INTERFACE outside click dismisses without activating covered attack")
 await press(t,"OpenDeck");await press(t,"CloseDrawer")
 t.check(not ui.show_deck,"INTERFACE shared close button dismisses")
 await press(t,"OpenItems");await press(t,"OpenItems")
 t.check(not ui.show_items,"INTERFACE pressing active tab toggles it closed")
 await t.open_menu()
 var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true
 t.root.push_input(escape,true);escape=escape.duplicate();escape.pressed=false;t.root.push_input(escape,true);await t.frames()
 t.check(not ui.show_menu and JSON.stringify(ui.game.state)==before,"INTERFACE Escape closes focused menu without a turn or save")
 t.check(ui.layout.get_instance_id()==scene_id and ui.card_buttons.values().map(func(card):return card.get_instance_id())==hand_ids,"INTERFACE opening/switching/closing panels preserves the live scene and hand controls")
 t.check(ui.candidate_buttons.values().all(func(button):return is_instance_valid(button) and button.is_inside_tree()),"INTERFACE closed panels leave no stale candidate controls")
 await t.capture("ui-73-simplified-battle.png")
 await tutorial(t)
 # The dismiss surface must also be gone for actual subsequent gameplay.
 await t._actor_drag_tests()
 await posture_controls(t)

static func card_illustrations(t) -> void:
 var face_script=preload("res://ui/elements/card_face.gd")
 var before=t.ui.game.export_snapshot()
 var missing=[];var broken=[];var overflow=[];var paths=[]
 for id in t.ui.game.Cards.Rules.SPECS:
  if not face_script.ILLUSTRATIONS.has(id):
   missing.append(id);continue
  var texture=face_script.ILLUSTRATIONS[id]
  var source=preload("res://data/card_rules.gd").SPECS[id].get("art_source","magic_hand" if id=="magic_hand_gift" else "")
  var shared=source!="" and texture==face_script.ILLUSTRATIONS[source]
  if texture==null or texture.get_image().get_used_rect().size==Vector2i.ZERO or (texture.resource_path in paths and not shared):
   broken.append(id);continue
  paths.append(texture.resource_path)
  var card=preload("res://ui/elements/card_face.tscn").instantiate()
  card.symbol=id;card.lift_on_hover=false
  card.position=Vector2(-2000,-2000);card.size=Vector2(190,285)
  t.root.add_child(card)
  var picture=card.get_node("CardIllustration")
  for dimensions in [Vector2(190,285),Vector2(290,360)]:
   card.size=dimensions;card.free_face=not card.free_face;card.queue_redraw()
   var art_ratio=0.58 if id=="binding_enthusiast" else 2.0/3.0
   if picture.texture!=texture or picture.material!=null or picture.mouse_filter!=Control.MOUSE_FILTER_IGNORE or not Rect2(Vector2.ZERO,dimensions).encloses(picture.get_rect()) or not is_equal_approx(card.art_bottom-6,dimensions.y*art_ratio) or picture.stretch_mode!=TextureRect.STRETCH_KEEP_ASPECT_CENTERED or picture.position.y<42 or not picture.clip_contents:
    overflow.append(id)
  card.free()
 t.check(missing.is_empty(),"CARD ART every registered card has an illustration: "+str(missing))
 t.check(broken.is_empty(),"CARD ART illustrations are nonempty and distinct except the magic-hand gift variant: "+str(broken))
 t.check(face_script.ILLUSTRATIONS.magic_hand_gift==face_script.ILLUSTRATIONS.magic_hand,"CARD ART gift variant shares the original magic-hand illustration")
 t.check(overflow.is_empty(),"CARD ART both sizes/faces keep their specified art area and fit the full image proportionally below the header: "+str(overflow))
 t.check(t.ui.game.export_snapshot()==before,"CARD ART display never changes cards, resources or random state")
 # All real card text, requirements and both faces share the same compact layout.
 var samples=[]
 for type in t.ui.game.Cards.Rules.SPECS:
  var data=preload("res://data/encyclopedia.gd").card(type);data.uid="layout_probe_"+type
  var face=t.ui._card(data,Rect2(-2000,-2000,184,252),func():pass,0,t.ui.layout,false,false)
  samples.append({"face":face,"data":data})
 var text_overflow=[]
 var header_errors=[]
 for dimensions in [Vector2(184,252),Vector2(226,290)]:
  for free in [false,true]:
   for sample in samples:
    sample.face.size=dimensions;t.ui.card_faces[sample.data.uid]=free;t.ui._refresh_card_face(sample.face,sample.data)
   await t.frames()
   for sample in samples:
    var box=sample.face.get_node("CardText")
    var content=box.get_node("Content")
    var picture=sample.face.get_node("CardIllustration")
    var art_ratio=0.58 if sample.data.type=="binding_enthusiast" else 2.0/3.0
    if not Rect2(Vector2.ZERO,dimensions).encloses(box.get_rect()) or box.position.y<picture.get_rect().end.y or not is_equal_approx(sample.face.art_bottom-6,dimensions.y*art_ratio) or content.size.x>box.size.x or not box.clip_contents: text_overflow.append(sample.data.type+str(free)+str(dimensions))
    if content.size.y>box.size.y:
     box.scroll_vertical=int(ceilf(content.size.y))
     if box.scroll_vertical<=0: text_overflow.append(sample.data.type+" unreachable text")
     box.scroll_vertical=0
    var badges=sample.face.get_node("CardMana")
    var title=sample.face.get_node("CardTitle")
    if sample.data.type=="hannya_henshin":
     t.check(title.text.replace("\n","")==sample.data.name and title.get_visible_line_count()==title.get_line_count() and title.get_rect().end.y<=42,"HANNYA TITLE full perfect-henshin name fits the header without truncation: rect=%s lines=%d/%d font=%d" % [str(title.get_rect()),title.get_visible_line_count(),title.get_line_count(),title.get_theme_font_size("font_size")])
    var expected=sample.data.face_mana["free" if free else "bound"]
    if badges.visible!=not expected.is_empty() or badges.get_child_count()!=expected.size(): header_errors.append(sample.data.type+" visibility")
    if badges.visible and (not Rect2(Vector2.ZERO,dimensions).encloses(badges.get_rect()) or title.get_rect().end.x>badges.position.x or badges.position.y>2): header_errors.append(sample.data.type+" overlap: title="+str(title.get_rect())+" badges="+str(badges.get_rect())+" card="+str(dimensions))
 # A deliberate display-only long-copy fixture survives later wording simplifications.
 # Every real card and both faces have already been checked above.
 var dense=samples[0]
 dense.face.position=Vector2(700,280);dense.face.z_index=200
 dense.face.get_node("CardText/Content/CardEffect").text="使用前请确认目标。\n".repeat(12)
 dense.face.size=Vector2(184,252);dense.face.fit_text();await t.frames()
 var scroll=dense.face.get_node("CardText")
 var art_rect=dense.face.get_node("CardIllustration").get_rect()
 t.check(scroll.get_node("Content").size.y>scroll.size.y,"CARD TEXT explicit long-copy fixture overflows the narrow hand card")
 var scroll_point=scroll.get_global_rect().get_center()
 await t.move_mouse(scroll_point)
 await t.mouse_button(scroll_point,MOUSE_BUTTON_WHEEL_DOWN,true)
 await t.mouse_button(scroll_point,MOUSE_BUTTON_WHEEL_DOWN,false)
 t.check(scroll.scroll_vertical>0 and dense.face.get_node("CardIllustration").get_rect()==art_rect,"CARD TEXT wheel reveals long conditions without shrinking the art")
 dense.face.flip_requested.emit();await t.frames()
 t.check(scroll.scroll_vertical==0,"CARD TEXT changing face resets the reading position")
 for sample in samples:
  t.ui.card_faces.erase(sample.data.uid);sample.face.free()
 t.check(text_overflow.is_empty(),"CARD TEXT both face sizes keep full scrollable effects and restrictions below the fixed art area: "+str(text_overflow))
 t.check(header_errors.is_empty(),"CARD MANA badges stay at top right without covering titles on either face/size: "+str(header_errors))
 t.check(t.ui.game.export_snapshot()==before,"CARD TEXT layout and flip do not change game state")

static func tutorial(t) -> void:
 var ui=t.ui
 var before=ui.game.export_snapshot()
 var header_book=ui.find_child("OpenTutorial",true,false)
 t.check(header_book!=null and header_book.get_global_rect().position.y<62 and header_book.get_global_rect().end.y<=62 and header_book.get_theme_stylebox("normal").bg_color!=ui.find_child("OpenStatus",true,false).get_theme_stylebox("normal").bg_color,"BOOK tutorial is a highlighted permanent header button")
 await t.open_menu()
 t.check(ui.drawer_layer.find_child("OpenTutorial",true,false)==null,"BOOK menu no longer duplicates the header tutorial entry")
 await press(t,"OpenTutorial")
 var book=ui.find_child("TutorialBook",true,false)
 t.check(ui.show_tutorial and not ui.show_menu and book!=null,"BOOK header opens shared tutorial drawer and closes previous menu")
 t.check(book.category=="basics" and book.results.get_child(0).text=="卡牌翻面" and book.categories.keys()[0]=="basics","BOOK opens with basic controls pinned first")
 t.check(t.visible_text(book.results).contains("电脑：右键") and t.visible_text(book.results).contains("手机：长按") and t.visible_text(book.results).contains("拖动使用"),"BOOK opening view explains both platform gestures and dragging")
 await t.capture("ui-tutorial-basics.png")
 await t.capture("ui-header-tutorial.png")
 var data=preload("res://data/tutorial.gd")
 var entries=data.entries();var ids=[]
 for entry in entries:
  t.check(not entry.id in ids and data.CATEGORIES.has(entry.category) and entry.text!="","BOOK unique categorized populated entry: "+entry.id)
  ids.append(entry.id)
 t.check(not data.CATEGORIES.has("enemy") and not data.CATEGORIES.has("relics") and ui.find_child("TutorialCategory_enemy",true,false)==null and ui.find_child("TutorialCategory_relics",true,false)==null,"BOOK removes enemy and relic categories from navigation")
 t.check(entries.all(func(row):return not row.has("card") and not row.id.begins_with("item_") and not row.id.begins_with("relic_") and not row.id.begins_with("term_")),"BOOK rules do not regenerate catalog cards, items, relics or enemy intents")
 t.check(ids.has("card_keyword_retain") and ids.has("card_keyword_reserve_mana") and entries.any(func(row):return row.title=="蓄力") and data.CATEGORIES.items=="环境","BOOK retains shared keywords, buffs and environment rules")
 var catalog=preload("res://data/encyclopedia.gd").entries()
 for category in ["cards","items","relics","enemies"]:
  t.check(catalog.any(func(row):return row.category==category),"BOOK removed tutorial catalogs remain available in encyclopedia: "+category)
 await press(t,"TutorialCategory_escape")
 t.check(t.visible_text(book.results).contains("同层") and not t.visible_text(book.results).contains("余烬护符"),"BOOK category filters result content")
 await t.capture("ui-92-tutorial-escape.png")
 await press(t,"TutorialCategory_all")
 t.check(book.results.get_child(0).text=="卡牌翻面","BOOK all entries also start with basic controls")
 var search=ui.find_child("TutorialSearch",true,false)
 for query in ["光滑的丝袜","施法动作教程","余烬护符","火焰精通"]:
  search.text=query;search.text_changed.emit(query);await t.frames()
  t.check(t.visible_text(book.results).contains("没有匹配条目"),"BOOK search does not resurface specific card or relic explanations: "+query)
 search.text="乌龟壳";search.text_changed.emit(search.text);await t.frames()
 t.check(t.visible_text(book.results).contains("跨战能量") and t.visible_text(book.results).contains("30点") and t.visible_text(book.results).contains("4层"),"BOOK shared resource rules remain searchable by their turtle-shell modifier")
 search.text="力量与灵巧";search.text_changed.emit(search.text);await t.frames()
 t.check(t.visible_text(book.results).contains("每段基础伤害") and t.visible_text(book.results).contains("移动滑脱"),"BOOK concise attributes still explain the affected damage")
 search.text="";search.text_changed.emit("");await t.frames()
 var point=search.get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 for character in "肩带":
  var key=InputEventKey.new();key.unicode=character.unicode_at(0);key.pressed=true;t.root.push_input(key,true)
 await t.frames()
 t.check(search.has_focus() and search.text=="肩带" and t.visible_text(book.results).contains("单手套") and not t.visible_text(book.results).contains("余烬护符"),"BOOK native search preserves typing focus and filters across categories")
 await t.capture("ui-93-tutorial-search.png")
 search.text="不存在的测试词";search.text_changed.emit(search.text);await t.frames()
 t.check(t.visible_text(book.results).contains("没有匹配条目"),"BOOK empty search has visible recovery hint")
 var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;t.root.push_input(escape,true);escape=escape.duplicate();escape.pressed=false;t.root.push_input(escape,true);await t.frames()
 t.check(not ui.show_tutorial and ui.game.export_snapshot()==before,"BOOK browsing/search/Escape never changes gameplay or random state")

static func posture_controls(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 var panel=ui.find_child("PostureChoices",true,false)
 t.check(panel.get_child_count()==1 and ui.find_child("Posture_sit",true,false)!=null,"POSTURE standing shows only adjacent sitting choice")
 t.check(panel.get_global_rect().end.y<ui.end_button.get_global_rect().position.y and panel.position.x>=1260,"POSTURE all choices are above the end-turn button on the right")
 var before=ui.game.export_snapshot()
 ui.render();await t.frames()
 t.check(ui.game.export_snapshot()==before,"POSTURE visibility projection changes no resources or random state")
 await press(t,"Posture_sit")
 panel=ui.find_child("PostureChoices",true,false)
 t.check(ui.view.posture=="sit" and panel.get_child_count()==3,"POSTURE sitting shows both directions plus wall ascent")
 for button in panel.get_children():
  var bounds=button.get_global_rect()
  t.check(bounds.end.y<ui.end_button.get_global_rect().position.y and panel.get_children().all(func(other):return other==button or not bounds.intersects(other.get_global_rect())),"POSTURE multiline tiles do not overlap each other or the action rail")
 var wall=ui.find_child("Posture_stand_wall",true,false).get_global_rect()
 var normal=ui.find_child("Posture_stand",true,false).get_global_rect()
 t.check(wall.position.x>normal.position.x and wall.position.y==normal.position.y,"POSTURE wall option sits to the right of the matching ordinary choice")
 var wall_action=ui.actions.find("posture",{"dest":"stand","wall":true})
 var normal_action=ui.actions.find("posture",{"dest":"stand","wall":false})
 t.check(ui.find_child("Posture_stand_wall",true,false).text.contains(str(wall_action.cost)+"能量") and ui.find_child("Posture_stand",true,false).text.contains(str(normal_action.cost)+"能量") and wall_action.cost<normal_action.cost,"POSTURE both actual costs make the wall discount visible without hover")
 await t.capture("ui-86-posture-choices-seated.png")
 await press(t,"Posture_lie")
 t.check(ui.view.posture=="lie" and ui.find_child("PostureChoices",true,false).get_child_count()==2 and ui.find_child("Posture_stand",true,false)==null,"POSTURE lying shows only ordinary and wall sitting, no direct standing")
 await t.capture("ui-87-posture-choices-lying.png")
 ui.restart(42);ui.game.state.energy=2;ui.render();await t.frames();await press(t,"Posture_sit")
 for i in range(2):
  var kick_point=ui.find_child("BasicAttack_kick",true,false).get_global_rect().get_center()
  await t.mouse_button(kick_point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(kick_point,MOUSE_BUTTON_RIGHT,false)
 for i in range(2): t.check(await t.click("attack",{"type":"kick","form":2}),"POSTURE spend energy through actual seated kick")
 t.check(ui.view.energy==0 and ui.find_child("Posture_stand",true,false).disabled and ui.find_child("Posture_stand",true,false).text.contains("能量"),"POSTURE unaffordable adjacent choice remains visible with reason")
 t.check(not ui.find_child("Posture_stand_wall",true,false).disabled,"POSTURE discounted wall choice can remain usable")
 var round_before=ui.view.round
 await press(t,"Posture_stand_wall")
 t.check(ui.view.posture=="stand" and ui.view.round==round_before,"POSTURE real wall click changes stance and preserves the player turn")
 await t.start_practice("StartEquipmentPractice")
 t.check(ui.find_child("Posture_stand_wall",true,false)==null and ui.find_child("Posture_sit_wall",true,false)==null,"POSTURE noncombat room does not invent wall choices")

static func deck_browser(t) -> void:
 var ui=t.ui
 ui.restart(42)
 for index in range(22): ui.game._gain_card("tear" if index%2==0 else "slip")
 ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await press(t,"OpenDeck");await t.frames()
 var grid=ui.find_child("DeckGrid",true,false)
 var scroll=ui.find_child("DeckScroll",true,false)
 t.check(grid.columns==6 and grid.get_child_count()==ui.view.deck_count,"DECK six-column gallery displays every physical copy")
 var ids=[]
 var previous_cost=-1
 for card in grid.get_children():
  ids.append(card.get_meta("physical_uid"))
  t.check(card.get_meta("printed_cost")>=previous_cost and card.drag_payload.is_empty(),"DECK sorted cards never dispatch gameplay drags")
  previous_cost=card.get_meta("printed_cost")
 t.check(ids.size()==ui.view.deck_cards.size() and ids.all(func(id):return ids.count(id)==1),"DECK physical cards neither merged nor duplicated")
 var first=grid.get_child(0)
 await t.move_mouse(first.get_global_rect().get_center());await t.frames()
 t.check(first.scale.x>1 and ui.find_child("TermExplanation",true,false)!=null,"DECK hover enlarges card and exposes complete text")
 await t.move_mouse(Vector2(70,100));await t.frames()
 await t.capture("ui-deck-gallery.png")
 scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await t.frames()
 t.check(scroll.scroll_vertical>0 and grid.get_child(grid.get_child_count()-1).get_global_rect().position.y<scroll.get_global_rect().end.y,"DECK final row reachable through scroll")
 await t.capture("ui-deck-gallery-bottom.png")
 var search=ui.find_child("DeckSearch",true,false)
 search.text="扯开缺口";search.text_changed.emit(search.text);await t.frames()
 t.check(grid.get_child_count()==11 and scroll.scroll_vertical==0,"DECK search retains individual duplicate cards and resets scroll")
 var costs=ui.find_child("DeckCostFilter",true,false)
 costs.select(2);costs.item_selected.emit(2);await t.frames()
 t.check(grid.get_child_count()==0 and ui.find_child("DeckEmpty",true,false).visible,"DECK empty filter gives explicit feedback")
 costs.select(0);costs.item_selected.emit(0)
 search.text="";search.text_changed.emit("");await t.frames()
 var sort=ui.find_child("DeckSort",true,false)
 sort.select(2);sort.item_selected.emit(2);await t.frames()
 t.check(grid.get_children().map(func(card):return card.get_meta("physical_uid"))==ui.view.deck_cards.map(func(card):return card.uid),"DECK acquisition order uses the permanent deck sequence")
 var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;t.root.push_input(escape,true);escape=escape.duplicate();escape.pressed=false;t.root.push_input(escape,true);await t.frames()
 t.check(not ui.show_deck and ui.game.export_snapshot()==before,"DECK browsing, filtering, sorting and Escape preserve full game state")

static func deck_sorting(t) -> void:
 var ui=t.ui
 ui.restart(42)
 for type in ["pot_of_greed","focus","binding_enthusiast"]: ui.game._gain_card(type)
 ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await press(t,"OpenDeck")
 var grid=ui.find_child("DeckGrid",true,false)
 var sort=ui.find_child("DeckSort",true,false)
 var ordered=grid.get_children().map(func(card):return card.symbol)
 t.check(ordered.find("pot_of_greed")<ordered.find("unlock") and ordered.find("unlock")<ordered.find("strain") and ordered.find("strain")<ordered.find("binding_enthusiast"),"DECK costs use shown zero-cost unlock and override both name and rarity")
 var last=-1
 for card in grid.get_children():
  var shown=int(card.get_node("CardCost").text)
  t.check(shown>=last and shown==card.get_meta("printed_cost"),"DECK cost order and filter metadata match actual displayed face")
  last=shown
 sort.select(1);sort.item_selected.emit(1);await t.frames()
 var named=grid.get_children().map(func(card):return card.symbol)
 var expected=["slip","binding_enthusiast","ease","pot_of_greed","unlock","strain","focus"]
 var positions=expected.map(func(type):return named.find(type))
 var sorted_positions=positions.duplicate();sorted_positions.sort()
 t.check(sort.selected==1 and positions==sorted_positions and named!=ordered,"DECK name selector sorts Chinese names independently of cost and rarity")
 sort.select(0);sort.item_selected.emit(0);await t.frames()
 t.check(grid.get_children().map(func(card):return card.symbol)==ordered,"DECK returning to cost restores the same order")
 var unlock=grid.get_children().filter(func(card):return card.symbol=="unlock")[0]
 unlock.flip_requested.emit();await t.frames()
 unlock=grid.get_children().filter(func(card):return card.symbol=="unlock")[0]
 t.check(unlock.get_node("CardCost").text=="1" and unlock.get_meta("printed_cost")==1,"DECK flipping a face refreshes its displayed sorting cost")
 var costs=ui.find_child("DeckCostFilter",true,false)
 costs.select(1);costs.item_selected.emit(1);await t.frames()
 t.check(grid.get_children().all(func(card):return card.get_node("CardCost").text=="0") and not grid.get_children().any(func(card):return card.symbol=="unlock"),"DECK zero-cost filter excludes the flipped one-cost face")
 costs.select(0);costs.item_selected.emit(0);sort.select(2);sort.item_selected.emit(2);await t.frames()
 t.check(grid.get_children().map(func(card):return card.get_meta("physical_uid"))==ui.view.deck_cards.map(func(card):return card.uid) and ui.game.export_snapshot()==before,"DECK sorting and flipping preserve acquisition order and authoritative state")
 await t.close_information()

static func pile_browsers(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 var before=ui.game.export_snapshot()
 await press(t,"DiscardPileButton")
 t.check(ui.deck_zone=="discard" and ui.find_child("DeckGrid",true,false).get_child_count()==0 and ui.find_child("DeckEmpty",true,false).text=="弃牌堆为空。","PILES empty discard never falls back to the complete deck")
 t.check(ui.game.state==before,"PILES opening an empty pile preserves game state")
 await t.close_information()
 ui.game._discard_end();ui.game._gain_card("slip");ui.game._gain_card("slip")
 ui.render();await t.frames()
 for zone in ["discard","draw","deck"]:
  before=ui.game.export_snapshot()
  await press(t,{"discard":"DiscardPileButton","draw":"DrawPileButton","deck":"OpenDeck"}[zone])
  var browser=ui.find_child("DeckBrowser",true,false)
  var actual=browser.grid.get_children().map(func(card):return card.get_meta("physical_uid"));actual.sort()
  var expected=before[zone].map(func(card):return card.uid);expected.sort()
  t.check(ui.deck_zone==zone and actual==expected and browser.counter.text=="%d / %d 张卡牌" % [expected.size(),expected.size()],"PILES "+zone+" shows exactly its physical card instances and matching count")
  t.check(ui.game.state==before,"PILES "+zone+" browsing never draws, shuffles, or modifies state")
  await t.close_information()
 # Exhaust the draw pile via the real draw/shuffle routine, keeping the UI read-only.
 ui.game.state.discard.append_array(ui.game.state.draw);ui.game.state.draw.clear()
 ui.render();await t.frames()
 await press(t,"DrawPileButton")
 t.check(ui.find_child("DeckGrid",true,false).get_child_count()==0 and ui.find_child("DeckEmpty",true,false).text=="抽牌堆为空。","PILES empty draw has its own empty state")
 await t.close_information()
 ui.game._draw(1);ui.render();await t.frames()
 before=ui.game.export_snapshot()
 await press(t,"DiscardPileButton")
 t.check(ui.find_child("DeckGrid",true,false).get_child_count()==0 and ui.view.discard_count==0,"PILES discard becomes empty after actual reshuffle")
 await t.close_information();await press(t,"DrawPileButton")
 var actual=ui.find_child("DeckGrid",true,false).get_children().map(func(card):return card.get_meta("physical_uid"));actual.sort()
 var expected=before.draw.map(func(card):return card.uid);expected.sort()
 t.check(actual==expected and actual.size()==ui.view.draw_count and ui.game.state==before,"PILES reopened draw reflects current cards after drawing and reshuffling")
 await t.close_information()

static func run_header(t) -> void:
 var ui=t.ui
 var before=ui.game.export_snapshot()
 t.check(ui.find_child("HeaderFloor",true,false).text=="第1层" and ui.find_child("HeaderRound",true,false).text=="第1回合" and ui.find_child("HeaderOrder",true,false).text=="先手","HEADER current room floor and battle order replace title")
 t.check(ui.find_child("HeaderSecurity",true,false).text=="警戒度%d级" % ui.view.security,"HEADER shows current security from game projection")
 ui.game.state.order="last";ui.game.state.round=12;ui.game.state.security=3;ui.render();await t.frames()
 t.check(ui.find_child("HeaderRound",true,false).text=="第12回合" and ui.find_child("HeaderOrder",true,false).text=="后手","HEADER refresh reflects authoritative turn and order")
 t.check(ui.find_child("HeaderSecurity",true,false).text=="警戒度3级","HEADER updates security after state changes")
 var labels=["HeaderFloor","HeaderRound","HeaderOrder","WallPosition","HeaderSecurity","OpenTutorial","OpenStatus","OpenItems","OpenDeck","OpenMap","OpenMenu"].map(func(id):return ui.find_child(id,true,false))
 for i in range(labels.size()-1): t.check(labels[i].get_global_rect().end.x<=labels[i+1].get_global_rect().position.x,"HEADER status labels and wall distance do not overlap")
 var info=ui.find_child("HeaderInfo",true,false)
 for id in ["HeaderFloor","HeaderRound","HeaderOrder","WallPosition","HeaderSecurity"]:
  var label=ui.find_child(id,true,false)
  t.check(info.get_global_rect().encloses(label.get_global_rect()) and label.get_line_count()==1 and is_equal_approx(label.get_global_rect().get_center().y,info.get_global_rect().get_center().y),"HEADER information stays on one aligned row: "+id)
 t.check(info.mouse_filter==Control.MOUSE_FILTER_IGNORE and ui.find_child("HeaderOrderBadge",true,false).mouse_filter==Control.MOUSE_FILTER_IGNORE,"HEADER decorative panels do not intercept input")
 ui.game.state.phase="prison";ui.game.state.room="prison";ui.game.state.prison={"turn":7}
 var projection=preload("res://core/game_view.gd").run_header(ui.game)
 t.check(projection.location=="牢房" and projection.turn=="第7回合" and projection.order=="非战斗","HEADER prison uses its own turn without inventing a tower floor or combat order")
 ui.game.state=before.duplicate(true);ui.game.state.phase="shop"
 projection=preload("res://core/game_view.gd").run_header(ui.game)
 t.check(projection.turn=="回合 —" and projection.order=="非战斗","HEADER noncombat rooms do not show stale battle turns")
 ui.game.state=before.duplicate(true)
 var noncombat_header=ui.game.get_view();noncombat_header.run_header=projection
 ui.render(noncombat_header);await t.frames()
 t.check(ui.find_child("HeaderOrderBadge",true,false).get_global_rect().encloses(ui.find_child("HeaderOrder",true,false).get_global_rect().grow_individual(0,-7,0,-7)),"HEADER noncombat text fits its status badge")
 ui.game.state=before;ui.render();await t.frames()
 await t.capture("ui-run-header.png")
 ui.game.state.round=3;ui.game.state.combat.turn=3;ui.game._finish_battle();ui.render();await t.frames()
 t.check(await t.click("reward",{"type":"skip"}),"HEADER log fixture enters preparation through real reward completion")
 ui.action_log_open=true;ui.action_log_pinned=true;ui.render();await t.frames()
 t.check(ui.find_child("HeaderRound",true,false).text=="第4回合" and ui.view.action_log.back().round==4 and t.visible_text(ui.find_child("ActionSidebar",true,false)).contains("魔法少女 · 第4回合"),"HEADER preparation and visible action log use the same fourth turn")
 t.check(await t.click("end") and ui.find_child("HeaderRound",true,false).text=="第5回合" and ui.view.action_log.back().round==5,"HEADER next preparation turn advances header and latest log together")
 ui.action_log_open=false;ui.action_log_pinned=false;ui.game.state=before;ui.render();await t.frames()
