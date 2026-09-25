extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 await quick_selection_refresh(t)
 await quick_release_magic(t)
 await quick_equipment_navigation(t)
 await exploration_fireball(t)
 await quick_release(t)
 await combo_label_fit(t)
 await disabled_layout(t)
 await infusion(t)
 await justice_opening(t)
 await bound_kick(t)
 t.ui.restart(42);t.ui.game.state.round=2;t.ui.render();await t.frames()
 var ui=t.ui
 var kick=ui.find_child("BasicAttack_kick",true,false)
 var choice=Queries.find(ui.view,"attack",{"type":"kick","form":0,"enemy":ui.selected_enemy})
 t.check(t.visible_text(kick).contains("正义飞踢") and choice.cost==2 and ui.find_child("BasicAttackDetail_kick",true,false).text=="18 伤害","JUSTICE UI displays official name two-energy cost and eighteen damage")
 ui.game.state.pressure=40;ui.render();await t.frames()
 var rail=ui.find_child("BasicActionRail",true,false)
 var slots=[ui.find_child("BasicAttack_strike",true,false),ui.find_child("BasicAttack_kick",true,false),ui.find_child("BasicAttack_heavy",true,false),ui.find_child("BasicAttack_fireball",true,false),ui.find_child("DeepBreath",true,false)]
 t.check(range(1,slots.size()).all(func(i):return slots[i-1].get_global_rect().end.x<=slots[i].get_global_rect().position.x),"BASIC UI order is elbow, kick, close strike, fireball, breath")
 t.check(rail.position.x==384 and rail.size.x==1195 and rail.position.y+rail.size.y<630,"BASIC UI rail fills the battle column and clears the hand")
 t.check(slots.all(func(b):return rail.get_global_rect().encloses(b.get_global_rect()) and is_equal_approx(b.size.x,slots[0].size.x)),"BASIC UI five equal action tiles stay inside the rail")
 t.check(is_equal_approx(slots[0].position.x,rail.position.x+10) and is_equal_approx(slots[-1].position.x+slots[-1].size.x,rail.position.x+rail.size.x-60),"BASIC UI action slots reserve the far-right switch")
 for type in ["strike","heavy","kick","fireball"]:
  var c=Queries.find(ui.view,"attack",{"type":type,"form":0,"enemy":ui.selected_enemy})
  var label=ui.find_child("BasicAttackDetail_"+type,true,false)
  t.check(label.text==c.brief and not label.text.contains(ui.view.enemies[0].name),"BASIC UI compact damage uses the authoritative preview without target prose")
  check_alignment(t,ui.find_child("BasicAttack_"+type,true,false))
 await t.capture("ui-basic-action-rail.png")
 for type in ["strike","heavy","kick"]:
  ui.restart(42);await t.frames()
  var before=ui.game.export_snapshot()
  var button=ui.find_child("BasicAttack_"+type,true,false)
  var point=button.get_global_rect().get_center()
  await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true)
  await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
  t.check(ui.attack_forms[type]==1 and ui.game.export_snapshot()==before,"BASIC UI right click flips form without cost or randomness")
  button=ui.find_child("BasicAttack_"+type,true,false)
  t.check(button.drag_payload.form==1,"BASIC UI drag payload preserves selected form")
  var c=Queries.find(ui.view,"attack",{"type":type,"form":1,"enemy":ui.selected_enemy})
  t.check(ui.candidate_buttons.has(ui.display_key(c.payload)) and t.visible_text(button).contains(c.label),"BASIC UI flipped form uses its actual candidate")
  if type=="heavy":
   t.check(button.size.x<240 and t.visible_text(button).contains("6 × 3 伤害"),"BASIC UI multi-hit short strike fits its action slot")
   check_alignment(t,button)
   await t.capture("ui-basic-attack-forms.png")
  var old_energy=ui.game.state.energy
  t.check(await t.click("attack",{"type":type,"form":1,"enemy":ui.selected_enemy}) and ui.game.state.energy==old_energy-c.cost,"BASIC UI selected form submits once")
  if type=="kick":
   t.check(ui.game.state.enemies.all(func(enemy):return enemy.hp==enemy.max_hp-5),"BASIC UI sweep damages all enemies")
   t.check(await t.click("attack",{"type":type,"form":1,"enemy":ui.selected_enemy}),"BASIC UI sweep can immediately repeat")
 ui.restart(42);ui.game.state.energy=0;ui.render();await t.frames()
 var fire=ui.find_child("BasicAttack_fireball",true,false)
 t.check(fire.disabled and fire.get_node("BasicActionEnergy/EnergyCost").text=="1","FIREBALL UI first use shows one energy in the left icon and blocks at zero")
 ui.game.state.energy=1;ui.render();await t.frames()
 var mana=ui.view.mana
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy}) and ui.view.energy==0 and ui.view.mana==mana-10,"FIREBALL UI first click pays one energy and mana once")
 fire=ui.find_child("BasicAttack_fireball",true,false)
 t.check(not fire.disabled and fire.get_node("BasicActionEnergy/EnergyCost").text=="0","FIREBALL UI later use switches left energy icon to zero")
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy}) and ui.view.energy==0 and ui.view.mana==mana-20,"FIREBALL UI second click works at zero energy")
 var button=ui.find_child("BasicAttack_heavy",true,false)
 var point=button.get_global_rect().get_center()
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(ui.attack_forms.get("heavy",0)==1 and ui.find_child("BasicAttack_heavy",true,false).disabled,"BASIC UI disabled attack can still change form")
 await third_kick(t)
 await continuous_kick(t)

static func third_kick(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 for form in [1,2]:
  var point=ui.find_child("BasicAttack_kick",true,false).get_global_rect().get_center()
  await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
  t.check(ui.attack_forms.kick==form,"KICK UI cycles through all three formal alternatives")
 var button=ui.find_child("BasicAttack_kick",true,false)
 t.check(button.drag_payload.form==2 and t.visible_text(button).contains("站着踢") and ui.find_child("BasicAttackDetail_kick",true,false).text=="8 伤害","KICK UI third form carries standing name, damage and drag identity")
 t.check(await t.click("attack",{"type":"kick","form":2,"enemy":ui.selected_enemy}) and ui.view.energy==2,"KICK UI standing ordinary kick pays one energy")
 t.check(await t.click("posture",{"dest":"sit","wall":false}),"KICK UI changes to actual sitting posture")
 button=ui.find_child("BasicAttack_kick",true,false)
 t.check(ui.attack_forms.kick==2 and t.visible_text(button).contains("坐着踢") and ui.find_child("BasicAttackDetail_kick",true,false).text=="6 伤害","KICK UI current third form automatically updates after posture change")
 t.check(await t.click("attack",{"type":"kick","form":2,"enemy":ui.selected_enemy}),"KICK UI ordinary sitting kick remains reusable after standing kick")
 ui.game.add_fixture("ankle",4);ui.game.add_fixture("foot",4);ui.render();await t.frames()
 var preview=Queries.find(ui.view,"attack",{"type":"kick","form":2,"enemy":ui.selected_enemy})
 t.check(preview.valid and is_equal_approx(preview.payload.damage,3.6) and ui.find_child("BasicAttackDetail_kick",true,false).text=="3.6 伤害","KICK UI level-three sitting preview reads shared damage")
 for slot in ["thigh","calf","toes"]: ui.game.add_fixture(slot,4)
 ui.render();await t.frames()
 t.check(ui.find_child("BasicAttack_kick",true,false).disabled and t.visible_text(ui.find_child("BasicAttack_kick",true,false)).contains("4级"),"KICK UI full leg restraint shows specific disabled reason")
 var before=ui.game.export_snapshot()
 for form in [3,0,1,2]:
  var point=ui.find_child("BasicAttack_kick",true,false).get_global_rect().get_center()
  await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
  t.check(ui.attack_forms.kick==form and ui.game.export_snapshot()==before,"KICK UI disabled forms still cycle without spending resources or resetting cooldown")

static func continuous_kick(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.posture="sit";ui.game.state.energy=3
 ui.game.state.enemies[0].hp=100;ui.game.state.enemies[0].max_hp=100
 ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 for form in [1,2,3]:
  var point=t.action_button("kick").get_global_rect().get_center()
  await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
  t.check(ui.attack_forms.kick==form and ui.game.state==before,"CONTINUOUS KICK UI cycling reaches seated combo without changing state")
 var button=t.action_button("kick")
 t.check(t.visible_text(button).contains("连续踢！") and button.get_node("BasicActionEnergy/EnergyCost").text=="3" and ui.find_child("BasicAttackDetail_kick",true,false).text=="3 × 4 伤害" and t.visible_text(button).contains("击后躺下"),"CONTINUOUS KICK UI shows real X cost hit count and fall warning")
 check_alignment(t,button)
 await t.drag_control_to(button,ui.selected_enemy)
 t.check(ui.view.energy==0 and ui.view.posture=="lie" and ui.game.state.enemies[0].hp==88,"CONTINUOUS KICK UI native drag pays and resolves the full combo then falls")
 ui.game.state.posture="sit";ui.render();await t.frames()
 t.check(t.action_button("kick").disabled and t.visible_text(t.action_button("kick")).contains("至少需要1"),"CONTINUOUS KICK UI zero energy displays the formal rejection")

static func justice_opening(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.energy=6
 ui.game.state.enemies[0].hp=100;ui.game.state.enemies[0].max_hp=100
 ui.render();await t.frames()
 var button=ui.find_child("BasicAttack_kick",true,false)
 t.check(not button.disabled and ui.game.state.round==1 and not t.visible_text(button).contains("打断"),"JUSTICE UI first-round action is available without innate interrupt")
 t.check(await t.click("attack",{"type":"kick","form":0,"enemy":ui.selected_enemy}) and ui.game.state.kick_last==-10,"JUSTICE UI actual click does not start cooldown")
 t.check(await t.click("attack",{"type":"kick","form":0,"enemy":ui.selected_enemy}) and ui.view.energy==2,"JUSTICE UI can immediately repeat")
 ui.game.add_fixture("thigh",4);ui.render();await t.frames()
 t.check(ui.find_child("BasicAttack_kick",true,false).disabled and t.visible_text(ui.find_child("BasicAttack_kick",true,false)).contains("双腿活动自由"),"JUSTICE UI leg restriction explains the real reason")
static func bound_kick(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.posture="sit";ui.game.add_fixture("ankle",4);ui.render();await t.frames()
 var c=Queries.find(ui.view,"attack",{"type":"kick","form":0,"enemy":ui.selected_enemy})
 t.check(c.valid and c.payload.fall and ui.game.candidate_detail(c).contains("3回合冷却") and c.risk.contains("躺下") and ui.find_child("BasicAttackDetail_kick",true,false).text.contains("4 伤害"),"BOUND KICK UI shows reduced seated damage shared cooldown and fall cost")
 ui.game.state.strength=2;ui.game.state.charge=1;ui.render();await t.frames()
 var hp=ui.game._enemy(ui.selected_enemy).hp
 t.check(ui.find_child("BasicAttackDetail_kick",true,false).text.contains("8 伤害"),"BOUND KICK UI includes strength and charge before body damage reduction")
 t.check(await t.click("attack",{"type":"kick","form":0,"enemy":ui.selected_enemy}) and ui.view.posture=="lie" and ui.game._enemy(ui.selected_enemy).hp==hp-8 and ui.game.state.charge==0,"BOUND KICK UI actual seated kick matches preview and consumes charge once")
 t.check(await t.click("posture",{"dest":"sit","wall":false}),"BOUND KICK UI recovers through actual posture action")
 c=Queries.find(ui.view,"attack",{"type":"kick","form":0,"enemy":ui.selected_enemy})
 t.check(not c.valid and c.reason.contains("冷却") and ui.find_child("BasicAttack_kick",true,false).disabled and ui.view.statuses.any(func(s):return s.id=="kick_cooldown" and s.detail.contains("共用冷却")),"BOUND KICK UI displays cooldown in both actual action and status after sitting up")

static func infusion(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._discard_end();ui.game.state.energy=6
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"infusion")
 ui.card_faces[card.uid]=false;ui.render();await t.frames()
 var face=ui.card_buttons[card.uid];var c=Queries.find(ui.view,"card",{"uid":card.uid,"free":false})
 t.check(face.rarity=="rare" and t.visible_text(face).contains("腿部体术") and c.cost==2 and c.mana==10,"INFUSION UI rare bound face shows leg preparation and actual prices")
 var before=ui.game.export_snapshot();await t.flip(card.uid)
 face=ui.card_buttons[card.uid];c=Queries.find(ui.view,"card",{"uid":card.uid,"free":true})
 t.check(ui.game.state==before and t.visible_text(face).contains("手部体术") and c.cost==1 and c.mana==20,"INFUSION UI flip shows hand preparation without spending resources")
 await t.capture("ui-infusion.png")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
 t.check("infusion_free" in ui.game.state.card_buffs and ui.view.energy==5 and ui.view.mana==80 and t.visible_text(ui.find_child("BasicAttack_strike",true,false)).contains("打断"),"INFUSION UI actual card use adds interruption to the matching action preview")
 t.check(await t.click("attack",{"type":"strike","form":0,"enemy":ui.selected_enemy}) and "infusion_free" not in ui.game.state.card_buffs and ui.game.state.enemies[0].intent.delayed,"INFUSION UI actual attack consumes the buff and delays intent")

static func check_alignment(t, button: Button) -> void:
 var title=button.get_node("BasicAttackTitle")
 var detail=button.get_node("BasicAttackDetail_"+button.drag_payload.action_type)
 var meta=button.get_node("BasicAttackMeta")
 var energy=button.get_node("BasicActionEnergy")
 var candidate=Queries.find(t.ui.view,"attack",{"type":button.drag_payload.action_type,"form":button.drag_payload.form,"enemy":t.ui.selected_enemy})
 t.check(energy.get_node("EnergyCost").get_global_rect().get_center().distance_to(energy.get_global_rect().get_center())<0.5,"BASIC UI available energy numeral is centered")
 t.check(energy.get_node("EnergyCost").text==str(candidate.cost) and energy.texture!=null and meta.text.contains(candidate.body_part) and not meta.text.contains("能量"),"BASIC UI left energy medallion replaces cost text and metadata identifies the body part")
 t.check(title.get_theme_font_size("font_size")>=10 and title.get_theme_font_size("font_size")<=16 and detail.get_theme_font_size("font_size")==title.get_theme_font_size("font_size") and meta.get_theme_font_size("font_size")>=12,"BASIC UI action name and damage share an adaptive readable font")
 t.check(is_equal_approx(title.position.y,detail.position.y) and is_equal_approx(title.size.y,detail.size.y) and title.autowrap_mode==TextServer.AUTOWRAP_OFF and detail.autowrap_mode==TextServer.AUTOWRAP_OFF,"BASIC UI name and damage occupy one shared row")
 t.check(absf((title.position.x+detail.position.x+detail.size.x)/2-(46+button.size.x-12)/2)<1 and is_equal_approx(meta.position.x+meta.size.x/2,(46+button.size.x-18)/2),"BASIC UI text rows center within the area beside the energy icon")
 t.check(title.position.x>=energy.position.x+energy.size.x and meta.position.x>=energy.position.x+energy.size.x and detail.position.x>=title.position.x+title.size.x and detail.position.x+detail.size.x<=button.size.x-10,"BASIC UI energy icon and enlarged primary labels fit without overlapping")
 t.check(meta.get_theme_font("font").get_string_size(meta.text,HORIZONTAL_ALIGNMENT_LEFT,-1,meta.get_theme_font_size("font_size")).x<=meta.size.x+1,"BASIC UI complete cost usage and cast chance fit without truncation")
 var hint=button.get_node_or_null("KeyboardHint")
 t.check(hint!=null and hint.get_theme_font_size("font_size")==11 and not meta.get_global_rect().intersects(hint.get_global_rect()),"BASIC UI original shortcut style keeps a separate clear area")

static func disabled_layout(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.energy=0;ui.render();await t.frames()
 for type in ["strike","heavy","kick","fireball"]:
  var button=ui.find_child("BasicAttack_"+type,true,false)
  var badge=button.get_node("BasicActionEnergy")
  var cost=badge.get_node("EnergyCost")
  var reason=button.get_node("BasicAttackDetail_"+type)
  var meta=button.get_node("BasicAttackMeta")
  t.check(cost.get_global_rect().get_center().distance_to(badge.get_global_rect().get_center())<0.5 and badge.get_global_rect().encloses(cost.get_global_rect()),"BASIC UI energy numeral stays centered inside the medallion after layout")
  t.check(button.disabled and not reason.text.is_empty() and reason.get_theme_color("font_color")==ui.RED and reason.get_theme_font_size("font_size")==11,"BASIC UI unavailable action has a small red reason")
  t.check(button.get_global_rect().encloses(reason.get_global_rect()) and reason.position.y>=meta.position.y+meta.size.y and reason.autowrap_mode==TextServer.AUTOWRAP_OFF,"BASIC UI reason fits below body metadata without wrapping outside the clipped button: %s button=%s meta=%s reason=%s" % [type,button.get_global_rect(),meta.get_global_rect(),reason.get_global_rect()])
 ui.restart(42);ui.game.add_fixture("thigh",4);ui.render();await t.frames()
 var kick=ui.find_child("BasicAttack_kick",true,false)
 t.check(kick.disabled and kick.get_node("BasicAttackDetail_kick").text=="需要双腿活动自由","BASIC UI bound legs use the concise official restriction rather than a generic unavailable label")

static func combo_label_fit(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.energy=5
 for installed in [false,true]:
  if installed:
   ui.game._gain_tool("shard")
   ui.game.state.items.back().mount="hand_wall"
  ui.attack_forms.strike=1;ui.attack_forms.heavy=1
  var before=ui.game.export_snapshot()
  ui.render();await t.frames()
  for type in ["strike","heavy"]:
   var button=ui.find_child("BasicAttack_"+type,true,false)
   var title=button.get_node("BasicAttackTitle")
   var damage=button.get_node("BasicAttackDetail_"+type)
   t.check(title.text==("肘击 · 连击" if type=="strike" else "近身短打 · 连击"),"COMBO UI keeps the complete technique name")
   for label in [title,damage]:
    var width=label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
    t.check(width<=label.size.x and button.get_global_rect().encloses(label.get_global_rect()),"COMBO UI full text fits without ellipsis, including installed-tool rail")
   t.check(title.get_global_rect().end.x<=damage.get_global_rect().position.x,"COMBO UI complete name and damage never overlap")
  t.check(ui.game.export_snapshot()==before,"COMBO UI fitting text leaves resources and combat unchanged")
 ui.restart(42);await t.frames()


static func quick_selection_refresh(t) -> void:
 var ui=t.ui;var quick=preload("res://ui/quick_release_bar.gd")
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.energy=8
 var palm=ui.game.add_fixture("palm",60,100)
 var fingers=ui.game.add_fixture("fingers",30,100)
 ui.render();await t.frames()
 quick.toggle(ui);await t.frames()
 var button=ui.find_child("QuickRelease_region_upper",true,false)
 var frozen=ui.game.export_snapshot();var original_view=ui.view.duplicate(true)
 t.check(button.get_meta("target_id")==fingers.id,"QUICK REFRESH initial selection uses current facts")
 # These UI inputs change in the same View, without a transaction or a full render.
 ui.quick_release_parts.region_upper="hands";ui.quick_release_targets.region_upper=palm.id
 quick.refresh(ui)
 t.check(button.get_meta("target_id")==palm.id and is_equal_approx(button.get_node("DurabilityBar").value,0.6),"QUICK REFRESH same-version explicit target immediately updates title and durability")
 var uid=ui.view.hand.filter(func(card):return card.type=="strain")[0].uid
 var data={"card_uid":uid,"free":false,"version":ui.view.version}
 var c=quick.candidate(ui,"region_upper",data)
 quick.refresh(ui,data)
 t.check(c.valid and c.payload.target==palm.id and button.get_meta("target_selectable") and Queries.fact_by_key(ui.view,Queries.fact_key(c))==c,"QUICK REFRESH highlight and selected target use the original candidate")
 ui.card_faces[uid]=true;var free=data.duplicate();free.free=true
 quick.refresh(ui,free)
 t.check(not button.get_meta("target_selectable") and button.get_meta("target_id")==palm.id and quick.candidate(ui,"region_upper",free).is_empty(),"QUICK REFRESH same-version face change cannot reuse the bound-face action or change target")
 ui.card_faces[uid]=false;quick.refresh(ui,data)
 t.check(button.get_meta("target_selectable") and quick.candidate(ui,"region_upper",data)==c,"QUICK REFRESH flipping back restores the original candidate")
 var stale=data.duplicate();stale.version-=1;quick.refresh(ui,stale)
 t.check(not button.get_meta("target_selectable") and button.get_node("Reason").text=="行动已失效，请重新选择。","QUICK REFRESH stale payload replaces the previous usable highlight with its specific reason")
 ui.quick_release_targets.region_upper="missing-target";quick.refresh(ui)
 t.check(button.get_meta("target_id")==fingers.id,"QUICK REFRESH missing target falls back within the selected small part")
 ui.quick_release_parts.region_upper="upper_arm";quick.refresh(ui)
 t.check(button.get_meta("body_id")=="upper_arm" and button.get_meta("target_id")=="" and not button.get_node("DurabilityBar").visible,"QUICK REFRESH selected empty part stays empty instead of silently choosing another part")
 ui.quick_release_parts.region_upper="missing-part";quick.refresh(ui)
 t.check(button.get_meta("body_id")=="hands" and button.get_meta("target_id")==fingers.id,"QUICK REFRESH missing part falls back to the current region order")
 t.check(ui.game.export_snapshot()==frozen and ui.view==original_view and ui.find_child("QuickRelease_region_upper",true,false)==button,"QUICK REFRESH all selection changes preserve state random cursor View and tile node")
 ui.restart(42);await t.frames()

static func quick_release(t) -> void:
 var ui=t.ui
 var pointer=preload("res://tests/target_sidebar_ui_cases.gd")
 var quick=preload("res://ui/quick_release_bar.gd")
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.items.clear()
 var wrist=ui.game.add_fixture("wrist",60,100)
 var ankle=ui.game.add_fixture("ankle",60,100)
 ui.game.state.energy=6;ui.render();await t.frames()
 var frozen=ui.game.export_snapshot()
 var hero=ui.layout.hero.get_instance_id();var cards=ui.card_buttons.values()[0].get_instance_id()
 await pointer.press(t,ui.find_child("ActionRailToggle",true,false))
 t.check(ui.quick_release_open and ui.find_child("DeepBreath",true,false)==null and ui.game.export_snapshot()==frozen,"QUICK switch replaces actions without a gameplay change")
 t.check(ui.layout.hero.get_instance_id()==hero and ui.card_buttons.values()[0].get_instance_id()==cards,"QUICK page switch preserves portrait and hand nodes")
 var prior=0.0
 for id in quick.ORDER:
  var b=ui.find_child("QuickRelease_"+id,true,false)
  t.check(b!=null and b.position.x>prior and b.size.y==60,"QUICK four ordered body targets fit the existing rail")
  prior=b.position.x
 var upper=ui.find_child("QuickRelease_region_upper",true,false)
 t.check(upper.get_meta("body_id")=="wrist" and upper.get_meta("target_id")==wrist.id and t.visible_text(upper).contains("60/100"),"QUICK default shows occupied playable part and true durability")
 var point=upper.get_global_rect().get_center()
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 upper=ui.find_child("QuickRelease_region_upper",true,false)
 t.check(upper.get_meta("body_id")!="wrist" and ui.game.export_snapshot()==frozen,"QUICK right click cycles small parts without cost")
 for i in range(8):
  if upper.get_meta("body_id")=="wrist":break
  await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
  upper=ui.find_child("QuickRelease_region_upper",true,false)
 if ui.show_body:
  await pointer.press(t,upper)
  upper=ui.find_child("QuickRelease_region_upper",true,false)
 await pointer.press(t,upper)
 t.check(ui.quick_release_region=="region_upper" and ui.game.export_snapshot()==frozen and ui.show_body and ui.quick_release_inspected==wrist.id,"QUICK clicking region selects current equipment and opens its details without acting")
 var inspected=ui.find_child("EquipmentCard_"+wrist.id,true,false)
 t.check(inspected!=null and inspected.find_child("EquipmentActions",true,false).visible,"QUICK clicking region expands matching third-level equipment actions")
 await pointer.press(t,ui.find_child("QuickRelease_region_upper",true,false))
 t.check(not ui.show_body and ui.quick_release_region=="region_upper","QUICK closing details retains the target for the following direct card click")
 var uid=ui.view.hand.filter(func(card):return card.type=="strain")[0].uid
 if ui.card_faces.get(uid,false):await t.flip(uid)
 var data={"card_uid":uid,"free":false,"version":ui.view.version}
 var c=quick.candidate(ui,"region_upper",data)
 t.check(c.valid and c.payload.target==wrist.id,"QUICK selected part resolves its original card candidate")
 var old=ui.game._equipment(wrist.id).durability;var energy=ui.view.energy
 var click=t.card_point(uid)
 await t.move_mouse(click);await t.mouse_button(click,MOUSE_BUTTON_LEFT,true);await t.mouse_button(click,MOUSE_BUTTON_LEFT,false)
 t.check(not ui.view.hand.any(func(card):return card.uid==uid) and ui.view.energy==energy-c.cost and is_equal_approx(ui.game._equipment(wrist.id).durability,old-c.payload.preview.damage),"QUICK part then card native clicks submit exactly once with formal damage and fee")
 t.check(ui.game._equipment(ankle.id).durability==60,"QUICK card click leaves other region unchanged")
 uid=ui.view.hand.filter(func(card):return card.type=="slip")[0].uid
 if ui.card_faces.get(uid,false):await t.flip(uid)
 data={"card_uid":uid,"free":false,"version":ui.view.version}
 var lower=ui.find_child("QuickRelease_region_lower",true,false)
 c=quick.candidate(ui,"region_lower",data);old=ui.game._equipment(ankle.id).durability;energy=ui.view.energy
 t.check(c.valid and c.payload.target==ankle.id,"QUICK slip has an original lower-body candidate")
 ui.game.state.energy=0;ui.render();await t.frames()
 lower=ui.find_child("QuickRelease_region_lower",true,false)
 var blocked={"card_uid":uid,"free":false,"version":ui.view.version}
 var reason=quick.candidate(ui,"region_lower",blocked).reason
 frozen=ui.game.export_snapshot()
 t.check(not lower._can_drop_data(Vector2.ZERO,blocked) and t.visible_text(lower).contains(reason) and t.visible_text(lower).contains("60/100"),"QUICK insufficient energy shows formal reason while preserving durability")
 lower._drop_data(Vector2.ZERO,blocked)
 t.check(ui.game.export_snapshot()==frozen,"QUICK invalid drop cannot spend resources or apply damage")
 blocked.free=true
 t.check(not lower._can_drop_data(Vector2.ZERO,blocked),"QUICK free-effect face is never silently flipped to escape")
 ui.game.state.energy=energy;ui.render();await t.frames()
 lower=ui.find_child("QuickRelease_region_lower",true,false)
 frozen=ui.game.export_snapshot()
 var stale=data.duplicate();stale.version-=1
 t.check(not lower.accept_card.call(stale) and not lower.accept_card.call({"action_type":"strike","version":ui.view.version}) and ui.game.export_snapshot()==frozen,"QUICK stale payload and basic attacks cannot be submitted as escape cards")
 var start=t.card_point(uid)
 await t.move_mouse(start);await t.mouse_button(start,MOUSE_BUTTON_LEFT,true);await t.move_mouse(start+Vector2(0,-42),true)
 t.check(t.root.gui_is_dragging(),"QUICK native slip drag starts")
 point=lower.get_global_rect().get_center()
 await t.move_mouse(point,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(not ui.view.hand.any(func(card):return card.uid==uid) and ui.view.energy==energy-c.cost and is_equal_approx(ui.game._equipment(ankle.id).durability,old-c.payload.preview.damage),"QUICK native drag onto region submits slip once")
 for phase in ["prepare","rest"]:
  ui.restart(42);ui.game.state.phase=phase;ui.game.state.pressure=40;ui.render();await t.frames()
  t.check(ui.find_child("BasicActionRail",true,false)!=null and ui.find_child("DeepBreath",true,false)!=null,"QUICK noncombat keeps action rail and breath: "+phase)
  check_exploration_rail_alignment(t)
  frozen=ui.game.export_snapshot()
  await pointer.press(t,ui.find_child("ActionRailToggle",true,false));await pointer.press(t,ui.find_child("ActionRailToggle",true,false))
  t.check(ui.game.export_snapshot()==frozen,"QUICK noncombat page switches are read-only: "+phase)
  var calm=Queries.find(ui.view,"pressure")
  t.check(calm.valid,"QUICK noncombat breath original candidate remains valid")
  await pointer.press(t,ui.find_child("DeepBreath",true,false))
  t.check(ui.view.energy==frozen.energy-calm.cost and ui.game.state.pressure<frozen.pressure,"QUICK noncombat breath click still pays and lowers pressure")
 await t.start_practice("Practice_prison_test")
 t.check(ui.find_child("BasicActionRail",true,false)!=null,"QUICK exploration retains rail")
 check_exploration_rail_alignment(t)
 ui.game._gain_tool("shard");var tool=ui.game.state.items[-1];tool.mount="hand_wall";ui.render();await t.frames()
 await pointer.press(t,ui.find_child("ActionRailToggle",true,false))
 var mounted=ui.find_child("InstalledTools",true,false)
 t.check(mounted!=null and not mounted.get_global_rect().intersects(ui.find_child("ManaFlask",true,false).get_global_rect()),"QUICK exploration puts installed items in fifth slot clear of flask")
 await pointer.press(t,ui.find_child("InstalledTool_"+tool.id,true,false))
 t.check(ui.show_items and ui.selected_item==tool.id,"QUICK installed item opens the original item drawer")
 await t.close_information()
 ui.restart(42);ui.localization.set_locale("en_US");ui.render();await t.frames()
 await pointer.press(t,ui.find_child("ActionRailToggle",true,false))
 t.check(ui.find_child("QuickReleaseTools",true,false).text=="Use items" and ui.find_child("QuickRelease_region_upper",true,false).tooltip_text.contains("Select a body part"),"QUICK controls and interaction guidance have English translations")
 ui.localization.set_locale("zh_CN");ui.restart(42);await t.frames()


static func quick_release_magic(t) -> void:
 var ui=t.ui;var click=preload("res://tests/target_sidebar_ui_cases.gd")
 var quick=preload("res://ui/quick_release_bar.gd");var cards=preload("res://tests/curse_cases.gd")
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.energy=8
 var wrist=ui.game.add_fixture("wrist",7)
 var ankle=ui.game.add_fixture("ankle",7,10,true)
 var ease=cards.give(ui.game,"ease");var unlock=cards.give(ui.game,"unlock")
 ui.card_faces[ease.uid]=false;ui.card_faces[unlock.uid]=false
 ui.render();await t.frames()
 await click.press(t,ui.find_child("ActionRailToggle",true,false))
 await click.press(t,ui.find_child("QuickRelease_region_upper",true,false))
 var data={"card_uid":ease.uid,"free":false,"version":ui.view.version}
 var c=quick.candidate(ui,"region_upper",data)
 t.check(not c.is_empty() and c.valid and c.payload.target==wrist.id and c.payload.mode=="lower","QUICK MAGIC selected restraint exposes original lowering candidate")
 if c.is_empty():return
 var frozen=ui.game.export_snapshot()
 var point=t.card_point(ease.uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(is_equal_approx(ui.game._equipment(wrist.id).durability,c.payload.after) and ui.view.energy==frozen.energy-c.cost and ui.view.mana==frozen.mana-c.mana and not ui.view.hand.any(func(card):return card.uid==ease.uid),"QUICK MAGIC select then click lowers exact restraint once with formal spell costs")
 t.check(ui.game._equipment(ankle.id).durability==7 and ui.game._equipment(ankle.id).locked and ui.selected_card=="","QUICK MAGIC direct lowering leaves other equipment unchanged and no second target prompt")
 # An unlocked selected target must not fall back to the locked ankle.
 frozen=ui.game.export_snapshot()
 c=quick.candidate(ui,"region_upper",{"card_uid":unlock.uid,"free":false,"version":ui.view.version})
 t.check(not c.is_empty() and not c.valid,"QUICK MAGIC original unlock rule rejects already-unlocked selected target")
 point=t.card_point(unlock.uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.export_snapshot()==frozen and ui.notice==c.reason,"QUICK MAGIC invalid direct unlock keeps exact target and original reason without spending")
 await click.press(t,ui.find_child("QuickRelease_region_lower",true,false))
 ui.game.state.mana=0;ui.render();await t.frames()
 data={"card_uid":unlock.uid,"free":false,"version":ui.view.version}
 c=quick.candidate(ui,"region_lower",data);frozen=ui.game.export_snapshot()
 var button=ui.find_child("QuickRelease_region_lower",true,false)
 t.check(not button._can_drop_data(Vector2.ZERO,data) and t.visible_text(button).contains(c.reason),"QUICK MAGIC insufficient mana displays original rejection on selected restraint")
 button._drop_data(Vector2.ZERO,data)
 t.check(ui.game.export_snapshot()==frozen,"QUICK MAGIC rejected mana payment cannot unlock or consume card")
 ui.game.state.mana=90;ui.render();await t.frames()
 button=ui.find_child("QuickRelease_region_lower",true,false)
 data={"card_uid":unlock.uid,"free":false,"version":ui.view.version}
 c=quick.candidate(ui,"region_lower",data);frozen=ui.game.export_snapshot()
 var stale=data.duplicate();stale.version-=1
 var free=data.duplicate();free.free=true
 t.check(c.valid and not button.accept_card.call(stale) and not button.accept_card.call(free),"QUICK MAGIC accepts bound unlock without accepting stale or free preparation face")
 point=t.card_point(unlock.uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 t.check(t.root.gui_is_dragging(),"QUICK MAGIC native unlock card drag starts")
 point=button.get_global_rect().get_center()
 await t.move_mouse(point,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(not ui.game._equipment(ankle.id).locked and ui.game._equipment(ankle.id).durability==7 and ui.view.energy==frozen.energy-c.cost and ui.view.mana==frozen.mana-c.mana and not ui.view.hand.any(func(card):return card.uid==unlock.uid),"QUICK MAGIC native drop unlocks only selected gear and pays formal costs once")
 ui.restart(42);await t.frames()

static func quick_equipment_navigation(t) -> void:
 var ui=t.ui;var click=preload("res://tests/target_sidebar_ui_cases.gd");var keys=preload("res://tests/keyboard_ui_cases.gd")
 var quick=preload("res://ui/quick_release_bar.gd")
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.energy=8
 var palm=ui.game.add_fixture("palm",60,100)
 var fingers=ui.game.add_fixture("fingers",30,100)
 ui.render();await t.frames()
 var frozen=ui.game.export_snapshot()
 await click.press(t,ui.find_child("ActionRailToggle",true,false))
 var button=ui.find_child("QuickRelease_region_upper",true,false)
 t.check(button.get_meta("body_id")=="hands" and button.get_meta("target_id")==fingers.id,"QUICK default picks lowest-tier available outer strain target")
 for id in quick.ORDER:
  var region_button=ui.find_child("QuickRelease_"+id,true,false)
  var previous=region_button.get_node("QuickEquipmentPrevious_"+id)
  var next=region_button.get_node("QuickEquipmentNext_"+id)
  t.check(previous.position==Vector2.ZERO and is_equal_approx(next.position.x+next.size.x,region_button.size.x) and previous.size==Vector2(28,60) and next.size==Vector2(28,60),"QUICK arrows occupy full-height opposite edges "+id)
  for name in ["Title","Equipment","Status","Reason","KeyboardHint"]:
   var text=region_button.get_node(name)
   t.check(text.position.x>=previous.size.x and text.position.x+text.size.x<=next.position.x+0.5,"QUICK text stays between side arrows "+id+" "+name)
  t.check(previous.disabled==(id!="region_upper") and next.disabled==previous.disabled,"QUICK empty regions disable both side arrows "+id)
  var bar=region_button.get_node("DurabilityBar")
  t.check(bar.visible==(id=="region_upper") and not bar.show_percentage and bar.mouse_filter==Control.MOUSE_FILTER_IGNORE,"QUICK durability bar has no numbers or input capture and is hidden for empty parts "+id)
  if bar.visible:
   t.check(is_equal_approx(bar.value,0.3) and region_button.get_node("Equipment").get_global_rect().end.x<bar.get_global_rect().position.x and bar.position.x+bar.size.x<next.position.x,"QUICK durability bar shows selected remaining ratio beside name clear of arrows")
 var bar_point=button.get_node("DurabilityBar").get_global_rect().get_center()
 await t.move_mouse(bar_point);await t.mouse_button(bar_point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(bar_point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.show_body and ui.quick_release_inspected==fingers.id and ui.game.export_snapshot()==frozen,"QUICK clicking through durability bar opens selected equipment without spending")
 await t.mouse_button(bar_point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(bar_point,MOUSE_BUTTON_LEFT,false)
 t.check(not ui.show_body,"QUICK clicking through durability bar still toggles details closed")
 button=ui.find_child("QuickRelease_region_upper",true,false)
 await click.press(t,button)
 var current_tile=ui.find_child("EquipmentCard_"+fingers.id,true,false)
 t.check(ui.quick_release_inspected==fingers.id and current_tile!=null and current_tile.find_child("EquipmentActions",true,false).visible and ui.game.export_snapshot()==frozen,"QUICK center click opens selected low-tier equipment detail when several pieces share the part")
 await click.press(t,ui.find_child("QuickRelease_region_upper",true,false))
 t.check(not ui.show_body and ui.find_child("EquipmentDetails",true,false)==null and ui.quick_release_region=="region_upper" and quick.equipment_at(ui,"region_upper").id==fingers.id and ui.game.export_snapshot()==frozen,"QUICK second center click closes details while retaining selected target without spending")
 await click.press(t,ui.find_child("QuickRelease_region_upper",true,false))
 t.check(ui.show_body and ui.find_child("EquipmentCard_"+fingers.id,true,false).find_child("EquipmentActions",true,false).visible,"QUICK third center click reopens same equipment details")
 await click.press(t,ui.find_child("QuickEquipmentNext_region_upper",true,false))
 t.check(ui.quick_release_targets.region_upper==palm.id and ui.selected_slot=="hands" and "region_upper" in ui.expanded_body_regions and ui.show_body,"QUICK arrow selects next exact equipment and opens matching left body section")
 t.check(is_equal_approx(ui.find_child("QuickRelease_region_upper",true,false).get_node("DurabilityBar").value,0.6),"QUICK durability bar follows equipment cycling")
 var tile=ui.find_child("EquipmentCard_"+palm.id,true,false)
 t.check(tile!=null and tile.find_child("EquipmentActions",true,false).visible and ui.find_child("EquipmentDetails",true,false).get_global_rect().end.y<ui.find_child("BasicActionRail",true,false).get_global_rect().position.y,"QUICK matching third-level equipment details open without covering rail arrows")
 await keys.tap(t,KEY_LEFT)
 t.check(ui.quick_release_targets.region_upper==fingers.id and ui.find_child("EquipmentCard_"+fingers.id,true,false).find_child("EquipmentActions",true,false).visible,"QUICK keyboard Left cycles back and synchronizes equipment details")
 await keys.tap(t,KEY_RIGHT)
 t.check(ui.quick_release_targets.region_upper==palm.id and ui.game.export_snapshot()==frozen,"QUICK keyboard Right cycles with no game state or random change")
 var card=ui.view.hand.filter(func(c):return c.type=="strain")[0]
 if ui.card_faces.get(card.uid,false):await t.flip(card.uid)
 var c=quick.candidate(ui,"region_upper",{"card_uid":card.uid,"free":false,"version":ui.view.version})
 t.check(c.payload.target==palm.id,"QUICK explicitly cycled target is used instead of changing to an easier restraint")
 var energy=ui.view.energy
 var point=t.card_point(card.uid);await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.view.energy==energy-c.cost and is_equal_approx(ui.game._equipment(palm.id).durability,60-c.payload.preview.damage) and ui.game._equipment(fingers.id).durability==30,"QUICK card click damages only the explicitly selected equipment")
 t.check(is_equal_approx(ui.find_child("QuickRelease_region_upper",true,false).get_node("DurabilityBar").value,ui.game._equipment(palm.id).durability/100.0),"QUICK durability bar follows actual card damage")
 var wrist=ui.game.add_fixture("wrist",25,100)
 ui.render();await t.frames()
 for i in range(4):
  if quick.equipment_at(ui,"region_upper").get("id","")==wrist.id:break
  await keys.tap(t,KEY_RIGHT)
 t.check(ui.selected_slot=="wrist" and ui.quick_release_inspected==wrist.id and ui.find_child("EquipmentCard_"+wrist.id,true,false).find_child("EquipmentActions",true,false).visible,"QUICK cycling crosses small parts and opens the corresponding third-level details")
 ui.quick_release_parts.region_upper="upper_arm";ui.quick_release_targets.erase("region_upper");ui.render();await t.frames()
 await keys.tap(t,KEY_LEFT)
 t.check(not quick.equipment_at(ui,"region_upper").is_empty(),"QUICK arrows from an empty small part can still select another restraint in the region")
 ui.restart(42);ui.keyboard_input.settings.defaults();ui.render();await t.frames()
 await keys.tap(t,KEY_X)
 t.check(ui.keyboard_input.selection.get("type","")=="kick","KEYS X now selects kick")
 await keys.tap(t,KEY_ESCAPE);await keys.tap(t,KEY_V)
 t.check(ui.keyboard_input.selection.get("type","")=="heavy","KEYS V now selects close strike")
 await keys.tap(t,KEY_ESCAPE)
 ui.restart(42);await t.frames()

static func exploration_fireball(t) -> void:
 var ui=t.ui;var click=preload("res://tests/target_sidebar_ui_cases.gd")
 ui.restart(42);ui.game.state.phase="prepare";ui.game.state.equipment.clear();ui.game.state.energy=8
 var target=ui.game.add_fixture("wrist",60,100)
 ui.render();await t.frames()
 var fire=ui.find_child("BasicAttack_fireball",true,false)
 t.check(fire!=null and fire.disabled and fire.tooltip_text.contains("尚未获得"),"FIRE exploration retains a disabled fireball with its missing-ability reason")
 check_exploration_rail_alignment(t)
 await t.capture("ui-exploration-action-rail.png")
 ui.localization.set_locale("en_US");ui.render();await t.frames()
 check_exploration_rail_alignment(t)
 ui.localization.set_locale("zh_CN");ui.render();await t.frames()
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"flame_flourish")
 ui.render();await t.frames()
 var power=Queries.find(ui.view,"card",{"uid":card.uid,"free":false})
 ui.command_router.emit(String(power.payload.get("kind","")),power,ui.view.version);await t.frames()
 fire=ui.find_child("BasicAttack_fireball",true,false)
 t.check(fire!=null and not fire.disabled and fire.drag_payload.action_type=="fireball" and ui.find_child("DeepBreath",true,false)!=null,"FIRE exploration power exposes draggable fireball beside breath")
 var c=Queries.find(ui.view,"attack",{"type":"fireball","target":target.id})
 await t.reveal_body("wrist")
 fire=ui.find_child("BasicAttack_fireball",true,false)
 var frozen=ui.game.export_snapshot()
 var point=fire.get_global_rect().get_center();await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-40),true)
 t.check(t.root.gui_is_dragging(),"FIRE exploration native fireball drag starts")
 point=ui.body_buttons.wrist.get_global_rect().get_center();await t.move_mouse(point,true)
 await t.release_target(await t.reveal_drop_target(c.key))
 t.check(is_equal_approx(ui.game._equipment(target.id).durability,frozen.equipment[0].durability-c.payload.damage) and ui.view.energy==frozen.energy-c.cost and ui.view.mana<frozen.mana,"FIRE exploration drag to restraint pays official mana and energy and applies magic damage")
 ui.game.state.equipment.clear();ui.render();await t.frames()
 fire=ui.find_child("BasicAttack_fireball",true,false)
 t.check(fire.disabled and fire.tooltip_text.contains("没有拘束具"),"FIRE exploration empty-target placeholder retains the full reason")
 check_exploration_rail_alignment(t)
 ui.restart(42);await t.frames()

static func check_exploration_rail_alignment(t) -> void:
 var rail=t.ui.find_child("BasicActionRail",true,false).get_global_rect()
 var fire=t.ui.find_child("BasicAttack_fireball",true,false).get_global_rect()
 var breath=t.ui.find_child("DeepBreath",true,false).get_global_rect()
 var toggle=t.ui.find_child("ActionRailToggle",true,false).get_global_rect()
 t.check(rail.encloses(fire) and is_equal_approx(fire.position.y,breath.position.y) and is_equal_approx(fire.end.y,breath.end.y) and is_equal_approx(fire.end.y,toggle.end.y),"FIRE exploration placeholder aligns with breath and toggle inside the rail")
