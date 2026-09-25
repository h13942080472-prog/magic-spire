extends RefCounted
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 var fire=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 var fire_button=ui.candidate_buttons[ui.display_key(fire.payload)]
 var hover_before=ui.game.export_snapshot()
 await t.move_mouse(Vector2(1100,90));await t.frames()
 await t.move_mouse(fire_button.get_global_rect().get_center());await t.frames()
 var fire_tip=ui.find_child("TermExplanation",true,false)
 t.check(fire_tip!=null and t.visible_text(fire_tip).contains("当前施法成功率："+ui.game.cast_view(ui.game.Cards.Rules.cast_profile("fireball")).percent),"CAST fireball hover uses actual spell probability")
 t.check(ui.game.export_snapshot()==hover_before,"CAST fireball hover does not roll or pay costs")
 t.check(t.visible_text(fire_tip).contains("失败返还本次耗魔的50%") and t.visible_text(fire_tip).contains("能量照扣") and t.visible_text(fire_tip).contains("火球术次数不消耗"),"CAST tooltip describes half-mana refund and retained energy cost")
 ui.game._install_template("mouth_band","mouth",24.0,24.0,false,"fixture",3,0)
 # A valid independent target isolates the zero-chance reason from the gag's
 # integrated harness, which has no slip route.
 ui.game.add_fixture("wrist",8.0)
 var magic={}
 for zone in ["hand","draw","discard"]:
  for card in ui.game.state[zone]:
   if card.type=="ease": magic=card;break
  if not magic.is_empty(): break
 for zone in ["draw","discard"]: ui.game.state[zone].erase(magic)
 if not ui.game.state.hand.has(magic): ui.game.state.hand.append(magic)
 ui.game.state.pressure=75
 ui.render();await t.frames()
 fire=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 fire_button=ui.candidate_buttons[ui.display_key(fire.payload)]
 await t.move_mouse(Vector2(1100,90));await t.frames()
 await t.move_mouse(fire_button.get_global_rect().get_center());await t.frames()
 fire_tip=ui.find_child("TermExplanation",true,false)
 t.check(fire_tip!=null and t.visible_text(fire_tip).contains("当前施法成功率：0%"),"CAST disabled fireball hover updates to zero chance")
 ui.card_faces[magic.uid]=false;ui.render();await t.frames()
 var b=ui.card_buttons[magic.uid]
 t.check(b.modulate.r<0.7 and t.visible_text(b).contains("（当前施法成功率为0%）") and not t.visible_text(b).contains("需口部自由"),"CARD UI exact reason and low brightness replace static requirement")
 t.check(ui.find_child("MainMana",true,false).tooltip_text.contains("0%") and ui.find_child("HeroCastingChance",true,false).text.contains("0%"),"CAST UI mana hover and hero display same probability")
 t.check(ui.find_child("MainGuardBind",true,false)==null and ui.find_child("MainResourcePanel",true,false).get_global_rect().encloses(ui.find_child("MainMana",true,false).get_global_rect()),"CAST UI mana fills its expanded row when no capture is active")
 await t.close_information()
 var before=ui.game.export_snapshot()
 # Leave the hand before entering: a prior suite may finish at this same card coordinate.
 await t.move_mouse(Vector2(1100,90));await t.frames()
 await t.move_mouse(t.card_point(magic.uid));await t.frames()
 t.check(ui.find_child("TermExplanation",true,false)!=null and t.visible_text(ui.find_child("TermExplanation",true,false)).contains("0%"),"CAST UI dim spell remains hoverable with success tooltip")
 t.check(ui.game.export_snapshot()==before,"CAST UI hover never rolls or charges")
 await t.capture("ui-107-card-casting-tooltip.png")
 var old_face=ui.card_faces[magic.uid]
 var layout_id=ui.layout.get_instance_id();var card_id=b.get_instance_id()
 var other=ui.card_buttons.values().filter(func(x):return x!=b)[0]
 var other_id=other.get_instance_id();var reads=ui.game.view_reads
 await t.mouse_button(t.card_point(magic.uid),MOUSE_BUTTON_RIGHT,true)
 await t.mouse_button(t.card_point(magic.uid),MOUSE_BUTTON_RIGHT,false)
 t.check(ui.card_faces[magic.uid]!=old_face and ui.card_buttons[magic.uid].modulate.r==1,"CARD UI dim paid face flips to available free preparation")
 t.check(t.visible_text(ui.card_buttons[magic.uid]).contains(ui.game.Cards.face_text(ui.game,magic.type,true,magic.uid)),"CARD UI preparation remains explicit beside its mana badge")
 t.check(ui.find_child("TermExplanation",true,false)!=null and not t.visible_text(ui.term_popup).contains("施法成功率") and t.visible_text(ui.term_popup).contains("临时魔力"),"CAST UI free face replaces casting explanation with its keyword: "+(t.visible_text(ui.term_popup) if is_instance_valid(ui.term_popup) else "missing"))
 t.check(ui.layout.get_instance_id()==layout_id and ui.card_buttons[magic.uid].get_instance_id()==card_id and is_instance_valid(other) and other.get_instance_id()==other_id and ui.game.view_reads==reads,"CARD UI flip preserves scene/card controls and does not reproject rules")
 t.check(ui.card_buttons[magic.uid].drag_payload.free==ui.card_faces[magic.uid] and ui.card_buttons[magic.uid].drag_payload.version==ui.view.version,"CARD UI partial flip updates drag face without changing version")
 ui.game.state.equipment.clear();ui.game.state.pressure=0
 ui.render();await t.frames()
 if not ui.card_faces[magic.uid]:
  await t.mouse_button(t.card_point(magic.uid),MOUSE_BUTTON_RIGHT,true)
  await t.mouse_button(t.card_point(magic.uid),MOUSE_BUTTON_RIGHT,false)
 t.check(ui.card_buttons[magic.uid].modulate.r==1 and ui.card_buttons[magic.uid].find_child("CardAvailability",true,false)==null,"CARD UI restored body condition restores brightness and clears the restriction text")
 ui.game.state.energy=0;ui.render();await t.frames()
 t.check(ui.view.hand.filter(func(card):return card.type!="magic_slip").all(func(card):return ui.card_buttons[card.uid].modulate.r<0.7),"CARD UI unaffordable positive-energy starter cards dim")

 await body_routes(t)
 await failed_card_stays(t)
 await mana_badges(t)
 await unlock_preparation(t)
 await prepared_chant(t)
 await secret_weapon(t)

static func secret_weapon(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 var g=ui.game
 g.add_fixture("palm",4)
 var target=g.add_fixture("ankle",8,10,true)
 var card=preload("res://tests/curse_cases.gd").give(g,"unlock")
 g.RelicEffects.gain(g,"secret_weapon")
 ui.card_faces[card.uid]=false;ui.render();await t.frames()
 var before=g.export_snapshot()
 var shown=ui.view.hand.filter(func(c):return c.uid==card.uid)[0]
 t.check(shown.casting.source_part=="toes" and shown.casting.detail.contains("脚趾") and ui.find_child("RelicShortcut_secret_weapon",true,false)!=null and preload("res://ui/relic_icon.gd").ART.has("secret_weapon"),"SECRET UI shared relic icon and card casting details show toe route")
 await t.move_mouse(t.card_point(card.uid));await t.frames()
 t.check(g.state==before,"SECRET UI inspection never spends resources")
 preload("res://tests/secret_weapon_cases.gd").toes(g,2,2)
 ui.render();await t.frames()
 shown=ui.view.hand.filter(func(c):return c.uid==card.uid)[0]
 t.check(shown.availability.bound.dim and ui.view.statuses.any(func(s):return s.id=="secret_weapon_traction" and s.detail.contains("基础快感＋3")),"SECRET UI bound toes disable hand spell and show current traction calculation")

static func prepared_chant(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"prepared_chant")
 ui.card_faces[card.uid]=false;ui.render();await t.frames()
 for free in [false,true]:
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var face=ui.card_buttons[card.uid];var text=t.visible_text(face)
  t.check(face.rarity=="common" and face.get_node("CardCost").text=="1" and text.contains("100%") and text.contains("保留") and text.contains("消耗") and face.ILLUSTRATIONS.has("prepared_chant"),"CHANT UI both faces display common rarity, cost, full effect, retention, exhaust and illustration")
  t.check(text.contains("下回合" if free else "本回合"),"CHANT UI flipping distinguishes current and next-turn effects")
 var before=ui.game.export_snapshot()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 ui.game.state.pressure=99;ui.render();await t.frames()
 t.check(ui.game.state.energy==before.energy-1 and ui.game.state.mana==before.mana-10 and ui.game.state.exhaust.any(func(c):return c.uid==card.uid) and not ui.find_child("HeroCastingChance",true,false).text.contains("100%") and ui.view.statuses.any(func(s):return s.id=="power_prepared_chant_next" and s.value=="下回合生效"),"CHANT UI free play exhausts and shows pending status without current certainty")
 for enemy in ui.game.state.enemies: enemy.intent.delayed=true
 ui.render();await t.frames()
 t.check(await t.click("end"),"CHANT UI native end-turn action advances the queued effect")
 t.check(ui.find_child("HeroCastingChance",true,false).text.contains("100%") and ui.view.statuses.any(func(s):return s.id=="power_prepared_chant") and not ui.view.statuses.any(func(s):return s.id=="power_prepared_chant_next"),"CHANT UI next turn replaces pending status and displays active certainty")

static func unlock_preparation(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"unlock")
 ui.render();await t.frames()
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 await t.flip(card.uid)
 var face=ui.card_buttons[card.uid]
 t.check(t.visible_text(face).contains("获得2层魔力预备") and t.visible_text(face.get_node("CardMana/Mana_temporary")).strip_edges()=="+10","UNLOCK UI free face and mana badge both show two stacks worth ten points")
 var before=ui.game.export_snapshot()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.temporary_mana==before.temporary_mana+10 and ui.game.state.energy==before.energy-1 and ui.game.state.mana==before.mana and ui.game.state.discard.any(func(row):return row.uid==card.uid),"UNLOCK UI actual free-face click grants ten temporary mana and spends one energy")
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.equipment.clear()
 var target=ui.game.add_fixture("ankle",8,10,true)
 card=preload("res://tests/curse_cases.gd").give(ui.game,"unlock")
 ui.game.state.energy=0;ui.game.state.mana=10;ui.card_faces[card.uid]=false
 ui.render();await t.frames()
 t.check(ui.card_buttons[card.uid].get_node("CardCost").text=="0" and ui.card_buttons[card.uid].modulate.r==1,"UNLOCK UI zero-energy bound face is bright and displays zero cost")
 await t.flip(card.uid)
 t.check(ui.card_buttons[card.uid].get_node("CardCost").text=="1" and ui.card_buttons[card.uid].modulate.r<0.7,"UNLOCK UI free face still needs one energy after flipping")
 await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(not ui.game._equipment(target.id).locked and ui.game.state.energy==0 and ui.game.state.mana==0 and ui.game.state.discard.any(func(row):return row.uid==card.uid),"UNLOCK UI actual zero-energy click opens the sole lock and pays ten mana")

static func mana_badges(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.pressure=75;ui.game.state.mana=40
 var cards={}
 for type in ["mana_conversion","fire_control","strain","mana_invocation","mana_surge"]:
  cards[type]=preload("res://tests/curse_cases.gd").give(ui.game,type)
  ui.card_faces[cards[type].uid]=false
 ui.render();await t.frames()
 var exchange=ui.card_buttons[cards.mana_conversion.uid]
 var temporary=ui.card_buttons[cards.fire_control.uid]
 var gain=ui.card_buttons[cards.mana_invocation.uid]
 var surge=ui.card_buttons[cards.mana_surge.uid]
 t.check(t.visible_text(surge.get_node("CardMana/Mana_cost")).strip_edges()=="−5" and Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy}).mana==10,"MANA UI high-pressure spell card badge and fireball retain base costs")
 t.check(not ui.view.pressure.detail.contains("施法魔力消耗"),"MANA UI pressure description no longer advertises surcharge")
 t.check(t.visible_text(exchange.get_node("CardMana/Mana_cost")).strip_edges()=="−20" and not t.visible_text(exchange.get_node("CardText")).contains("耗魔"),"MANA UI fixed payment lives only in the top badge")
 t.check(t.visible_text(temporary.get_node("CardMana/Mana_temporary")).strip_edges()=="+10" and t.visible_text(gain.get_node("CardMana/Mana_gain")).strip_edges()=="+20","MANA UI temporary and regular restoration display point values")
 t.check(temporary.get_node("CardMana/Mana_temporary").get_theme_stylebox("panel").border_color!=gain.get_node("CardMana/Mana_gain").get_theme_stylebox("panel").border_color,"MANA UI temporary pool has a distinct visual style")
 t.check(not ui.card_buttons[cards.strain.uid].get_node("CardMana").visible,"MANA UI ordinary physical card has no visible mana component")
 await t.move_mouse(Vector2(600,80));await t.frames()
 await t.capture("ui-card-mana-badges.png")
 var before=ui.game.export_snapshot()
 await t.flip(cards.mana_conversion.uid)
 t.check(exchange.get_node("CardCost").text=="1" and exchange.get_node_or_null("CardMana/Mana_cost")==null and t.visible_text(exchange.get_node("CardMana/Mana_gain")).strip_edges()=="+10","MANA UI flip switches payment to restoration alongside energy cost")
 await t.flip(cards.fire_control.uid)
 t.check(not temporary.get_node("CardMana").visible and ui.game.export_snapshot()==before,"MANA UI flip to unrelated effect hides badge without changing resources")
 ui.restart(42);await t.frames();ui.game._discard_end()
 ui.game.state.pressure=75;ui.game.state.relics=["ember_crystal"]
 var free_surge=preload("res://tests/curse_cases.gd").give(ui.game,"mana_surge")
 ui.render();await t.frames();await t.flip(free_surge.uid)
 var shown=ui.view.hand.filter(func(entry):return entry.uid==free_surge.uid)[0]
 t.check(shown.face_casting.bound.percent=="100%" and shown.face_casting.free.percent=="25%","SURGE only the paid bound face previews the crystal guarantee")
 await t.move_mouse(Vector2(1100,90));await t.frames();await t.move_mouse(t.card_point(free_surge.uid));await t.frames()
 t.check(t.visible_text(ui.find_child("TermExplanation",true,false)).contains("施法成功率 · 25%") and ui.card_buttons[free_surge.uid].get_node_or_null("CardMana/Mana_cost")==null,"SURGE free hover uses actual unpaid chance and hides mana cost")

 ui.restart(42);await t.frames();ui.game._discard_end()
 var slip=preload("res://tests/curse_cases.gd").give(ui.game,"magic_slip")
 ui.game.state.pressure=75;ui.render();await t.frames()
 if not ui.card_faces[slip.uid]: await t.flip(slip.uid)
 t.check(t.visible_text(ui.card_buttons[slip.uid]).contains("施法：嘴部") and ui.card_buttons[slip.uid].get_node_or_null("CardMana/Mana_cost")==null,"MAGIC SLIP free UI shows mouth casting without mana payment")
 await t.move_mouse(Vector2(1100,90));await t.frames();await t.move_mouse(t.card_point(slip.uid));await t.frames()
 t.check(t.visible_text(ui.find_child("TermExplanation",true,false)).contains("施法成功率 · 25%"),"MAGIC SLIP free tooltip shows actual mouth chance")
 var entry=preload("res://data/encyclopedia.gd").card("magic_slip")
 t.check(entry.face_requirements.free==["施法：嘴部"] and entry.cast_faces.free,"MAGIC SLIP catalog also declares free mouth casting")

static func failed_card_stays(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._discard_end();ui.game.state.pressure=99
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"mana_surge")
 var rng=ui.game.state.rng.magic
 while ui.game._random_index("magic",ui.game.B.CAST_ROLL_STEPS)<ui.game.cast_view(ui.game.Cards.cast_profile(ui.game,"mana_surge")).winning_rolls: rng=ui.game.state.rng.magic
 ui.game.state.rng.magic=rng
 ui.render();await t.frames()
 var failed_cost=Queries.find(ui.view,"card",{"uid":card.uid,"free":false}).mana
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game._magic_failed and ui.card_buttons.has(card.uid) and ui.game.state.exhaust.is_empty() and ui.game.state.mana<100,"CAST UI failed exhaust card remains visible after paid attempt")
 t.check(is_equal_approx(ui.game.state.mana,100-failed_cost*0.5) and ui.game.state.logs.any(func(log):return log.data.has("spell") and log.text.contains("返还") and is_equal_approx(log.data.spell.mana_refund.mana,failed_cost*0.5)),"CAST UI failed attempt reports actual refund and remaining mana")
 ui.game.state.sure_cast=true;ui.render();await t.frames()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(not ui.card_buttons.has(card.uid) and ui.game.state.exhaust.any(func(x):return x.uid==card.uid) and ui.game.state.charge==2,"CAST UI retry succeeds and then animates actual exhaust")

static func body_routes(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"double_unlock")
 ui.game.add_fixture("ankle",8,10,true)
 ui.game._install_template("mouth_band","mouth",24,24,false,"fixture",3,0)
 ui.game.state.pressure=75
 ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(t.visible_text(face).contains("施法：手部或嘴部") and face.modulate.r==1,"ROUTE UI displays alternatives and does not dim a valid hand route")
 await t.move_mouse(Vector2(1100,90));await t.frames()
 await t.move_mouse(t.card_point(card.uid));await t.frames()
 var tip=ui.find_child("TermExplanation",true,false)
 t.check(tip!=null and t.visible_text(tip).contains("施法部位：手部") and t.visible_text(tip).contains("25%"),"ROUTE UI tooltip shows selected best path and actual chance")
 t.check(tip!=null and Rect2(0,0,1600,900).encloses(tip.get_global_rect()),"TERMS combined casting and keyword explanation stays inside viewport")
 ui.game.add_fixture("palm",4);ui.render();await t.frames()
 t.check(ui.card_buttons[card.uid].modulate.r<0.7,"ROUTE UI updates when neither path can cast")
 ui.game.state.equipment.clear();ui.game.add_fixture("ankle",8,10,true);ui.game.add_fixture("fingers",4)
 ui.render();await t.frames()
 await t.move_mouse(Vector2(1100,90));await t.frames()
 await t.move_mouse(t.card_point(card.uid));await t.frames()
 tip=ui.find_child("TermExplanation",true,false)
 t.check(ui.card_buttons[card.uid].modulate.r==1 and tip!=null and t.visible_text(tip).contains("施法部位：嘴部"),"ROUTE UI switches to mouth when hand is blocked")
 var entry=preload("res://data/encyclopedia.gd").card("mana_invocation")
 t.check(entry.face_requirements.bound==["施法：无"],"ROUTE catalog shares the same requirement projection")
 ui.game._discard_end();card=preload("res://tests/curse_cases.gd").give(ui.game,"unlock")
 ui.render();await t.frames()
 face=ui.card_buttons[card.uid]
 t.check(face.modulate.r<0.7 and t.visible_text(face).contains("手掌和手指"),"ROUTE UI hand-only card explains the actual blocked body condition")
 var body=face.get_node("CardText")
 t.check(body.position.y+body.get_combined_minimum_size().y<=face.size.y-4,"ROUTE UI requirement plus blocked reason fits inside card")
 ui.restart(42);await t.frames();ui.game._discard_end()
 card=preload("res://tests/curse_cases.gd").give(ui.game,"unlock")
 ui.game.add_fixture("ankle",8,10,true);ui.game._install_assembly("wrap","left","fixture",1,1)
 ui.render();await t.frames()
 face=ui.card_buttons[card.uid]
 t.check(face.modulate.r<0.7 and t.visible_text(face).contains("需要双手"),"MANUAL UI default blocked card explains both-hand requirement")
 var fire=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 t.check(fire.payload.damage==ui.game.B.FIREBALL,"MANUAL UI one hand initially has no fireball gesture bonus")
 ui.game.RelicEffects.gain(ui.game,"casting_manual");ui.render();await t.frames()
 fire=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 t.check(ui.card_buttons[card.uid].modulate.r==1 and fire.payload.damage==ui.game.B.FIREBALL_ASSISTED,"MANUAL UI pickup immediately updates card and fireball qualification")
 var manual=ui.find_child("RelicShortcut_casting_manual",true,false)
 await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_LEFT,true);await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_LEFT,false)
 await t.move_mouse(manual.get_global_rect().get_center());await t.frames()
 t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains("施法动作教程") and t.visible_text(ui.term_popup).contains("只需一只手的手掌和手指自由"),"MANUAL UI relic hover shows its real effect")
 await t.move_mouse(Vector2(650,60))
