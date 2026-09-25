extends RefCounted
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func rows_aligned(ui) -> bool:
 var bounds=ui.find_child("MainResourcePanel",true,false).get_global_rect()
 for id in ["MainOverload","MainMana","MainGuardBind"]:
  var bar=ui.find_child(id,true,false)
  if bar==null: continue
  for suffix in ["Caption","Value"]:
   var rect=ui.find_child(id+suffix,true,false).get_global_rect()
   if not bounds.encloses(rect) or absf(rect.get_center().y-bar.get_global_rect().get_center().y)>1: return false
 return true

static func balances_shown(ui, mana: float, flask: float) -> bool:
 for id in ["MainMana","HeroMana"]:
  var bar=ui.find_child(id,true,false)
  if bar!=null and (not is_equal_approx(bar.value,mana) or ui.find_child(id+"Value",true,false).text!=ui.game.number(mana)+"/100"): return false
 return ui.find_child("FlaskManaValue",true,false).text==ui.game.number(flask)

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 var before=ui.game.export_snapshot()
 var panel=ui.find_child("ManaFlask",true,false)
 t.check(panel.find_child("FlaskIcon",true,false)!=null and panel.find_child("FlaskIcon",true,false).tooltip_text=="贴身魔瓶" and not t.visible_text(panel).contains("贴身魔瓶"),"FLASK UI replaces permanent title with a bottle icon and hover name")
 t.check(panel.find_child("FlaskIcon",true,false).size.y>ui.find_child("FlaskDeposit",true,false).size.y*2 and ui.find_child("FlaskDeposit",true,false).text=="存入","FLASK UI large bottle dominates compact side controls")
 var draw=ui.find_child("DrawPileButton",true,false)
 t.check(panel.get_global_rect().end.y<draw.get_global_rect().position.y,"FLASK UI bottle sits above draw pile")
 var expanded_mana=ui.find_child("MainMana",true,false).get_global_rect()
 var expanded_gap=expanded_mana.position.y-ui.find_child("MainOverload",true,false).position.y
 var flask_rect=panel.get_global_rect()
 t.check(ui.find_child("MainGuardBind",true,false)==null and expanded_gap>=expanded_mana.size.y*2 and ui.find_child("MainResourcePanel",true,false).get_global_rect().encloses(expanded_mana),"FLASK UI without capture uses two spacious resource rows inside the panel")
 t.check(rows_aligned(ui),"FLASK UI expanded captions and values align with bars and stay inside panel")
 var text=t.visible_text(ui.layout)
 t.check(not text.contains("共用能量") and not text.contains("右键翻面 · 拖牌选目标") and ui.find_child("CastingChance",true,false)==null,"FLASK UI removes redundant permanent help text")
 await Pointer.press(t,ui.find_child("FlaskDeposit",true,false));await t.frames()
 t.check(ui.view.mana==90 and ui.view.mana_flask.mana==10 and ui.view.mana_flask.remaining==2 and ui.game.state.tick==before.tick,"FLASK UI actual deposit button transfers and updates remaining uses")
 t.check(balances_shown(ui,90,10),"FLASK UI deposit immediately updates both mana bars and bottle balance")
 await Pointer.press(t,ui.find_child("FlaskDeposit",true,false));await t.frames()
 t.check(not ui.find_child("FlaskDeposit",true,false).disabled,"FLASK UI second deposit leaves third use available")
 await Pointer.press(t,ui.find_child("FlaskDeposit",true,false));await t.frames()
 t.check(ui.find_child("FlaskDeposit",true,false).disabled and ui.find_child("FlaskDeposit",true,false).tooltip_text.contains("3次"),"FLASK UI exhausted deposit button has specific reason")
 t.check(ui.find_child("FlaskDepositUses",true,false).text=="存 ○○○" and ui.find_child("FlaskWithdrawUses",true,false).text=="取 ●●●","FLASK UI indicators distinguish separate allowances")
 t.check(balances_shown(ui,70,30),"FLASK UI consecutive deposit immediately shows committed balances")
 await Pointer.press(t,ui.find_child("FlaskWithdraw",true,false));await t.frames()
 t.check(ui.view.mana==80 and ui.view.mana_flask.mana==20,"FLASK UI native withdrawal button restores mana")
 t.check(balances_shown(ui,80,20) and ui.resource_feedback.active.is_empty() and ui.resource_feedback.pending.is_empty(),"FLASK UI withdrawal immediately updates balances without queuing transfer floats")
 for i in range(2): await Pointer.press(t,ui.find_child("FlaskWithdraw",true,false));await t.frames()
 t.check(ui.find_child("FlaskWithdraw",true,false).disabled and ui.find_child("FlaskWithdraw",true,false).tooltip_text.contains("3次") and ui.find_child("FlaskWithdrawUses",true,false).text=="取 ○○○","FLASK UI third withdrawal exhausts its independent allowance")
 await t.move_mouse(Vector2(1500,700));await t.capture("ui-mana-flask.png")
 await transfer_during_feedback(t)
 ui.restart(42,true,"guard")
 ui.game.CaptureBind.apply_bind(ui.game,ui.game.state.enemies[0]);ui.render();await t.frames()
 var compact_mana=ui.find_child("MainMana",true,false).get_global_rect()
 var compact_gap=compact_mana.position.y-ui.find_child("MainOverload",true,false).position.y
 var bind_rect=ui.find_child("MainGuardBind",true,false).get_global_rect()
 t.check(ui.find_child("MainGuardBindValue",true,false).text=="50/100" and compact_gap<expanded_gap and compact_mana.size.y<expanded_mana.size.y and is_equal_approx(bind_rect.position.y-compact_mana.position.y,compact_gap),"FLASK UI actual capture switches resources to three evenly spaced compact rows")
 t.check(ui.find_child("MainResourcePanel",true,false).get_global_rect().encloses(bind_rect) and ui.find_child("ManaFlask",true,false).get_global_rect()==flask_rect,"FLASK UI compact capture stays inside the panel without moving the bottle")
 t.check(rows_aligned(ui),"FLASK UI compact captions and values align with bars and stay inside panel")
 await t.capture("ui-mana-flask-capture.png")
 ui.game.CaptureBind.clear_bind(ui.game)
 before=ui.game.export_snapshot();ui.render();await t.frames()
 t.check(ui.find_child("MainGuardBind",true,false)==null and ui.find_child("MainMana",true,false).get_global_rect()==expanded_mana and ui.game.export_snapshot()==before,"FLASK UI clearing capture restores the expanded layout without changing resources or random state")
 ui.restart(42)
 t.check(preload("res://tests/mana_flask_cases.gd").shop(ui.game),"FLASK UI reaches actual shop through travel")
 ui.game.state.flask_mana=100;ui.game.state.mana=0;ui.render();await t.frames()
 var candidate=Queries.find(ui.view,"service",{"op":"take","payment":"flask"})
 var index=candidate.payload.index
 t.check(ui.find_child("ShopOffer%d" % index,true,false).disabled,"FLASK UI personal payment begins blocked when mana is empty")
 before=ui.game.export_snapshot()
 await Pointer.press(t,ui.find_child("ShopPayment_flask",true,false));await t.frames()
 t.check(ui.shop_payment=="flask" and not ui.find_child("ShopOffer%d" % index,true,false).disabled and ui.game.state==before,"FLASK UI payment switch only changes selection and enables real bottle candidate")
 await t.capture("ui-shop-flask-payment.png")
 await Pointer.press(t,ui.find_child("ShopOffer%d" % index,true,false));await t.frames()
 t.check(ui.view.mana==0 and ui.view.mana_flask.mana==100-candidate.mana,"FLASK UI native purchase deducts selected bottle balance")
 await preparation_deposit(t)
 await prison_deposit(t)

static func prison_deposit(t) -> void:
 var ui=t.ui
 ui.restart(42,true,"prison_test")
 preload("res://tests/prison_cases.gd").clear_fixture(ui.game)
 ui.game.state.mana=50.0;ui.game.state.flask_mana=100.0
 ui.render();await t.frames()
 t.check(ui.find_child("FlaskDepositUses",true,false).text=="存 ●" and ui.find_child("FlaskWithdrawUses",true,false)==null,"FLASK UI cell shows one deposit dot and no withdrawal limit")
 await Pointer.press(t,ui.find_child("FlaskDeposit",true,false));await t.frames()
 t.check(ui.view.mana==40 and ui.view.mana_flask.mana==110 and ui.find_child("FlaskDepositUses",true,false).text=="存 ○","FLASK UI cell native deposit updates balances and consumes one dot")
 var button=ui.find_child("FlaskDeposit",true,false)
 t.check(button.disabled and button.tooltip_text=="本回合已存入1次。" and not ui.find_child("FlaskWithdraw",true,false).disabled,"FLASK UI exhausted cell deposit explains denial without disabling withdrawal")
 t.check(await t.click("end") and ui.view.phase=="prison","FLASK UI actual cell end advances exploration")
 t.check(ui.find_child("FlaskDepositUses",true,false).text=="存 ●" and not ui.find_child("FlaskDeposit",true,false).disabled,"FLASK UI next cell turn restores one deposit dot")

static func transfer_during_feedback(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.mana=60
 for enemy in ui.game.state.enemies: enemy.hp=0;enemy.gone=true
 ui.game.state.enemies[0].hp=1;ui.game.state.enemies[0].gone=false
 ui.render();await t.frames()
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.game.state.enemies[0].id}) and ui.view.phase=="reward" and ui.view.mana==50,"FLASK UI spell pays now while battle-end recovery waits for preparation")
 var presenter=ui.resource_feedback
 presenter.set_process(false)
 t.check(await t.click("reward",{"type":"skip"}) and ui.view.phase=="prepare" and ui.view.mana==50,"FLASK UI reward continuation preserves the paid balance")
 t.check(await t.click("finish_prepare") and ui.view.phase=="map" and ui.view.mana==60,"FLASK UI formal preparation completion produces the relic recovery")
 t.check(not ui.view.mana_flask.limited and ui.find_child("FlaskDepositUses",true,false)==null and ui.find_child("FlaskWithdrawUses",true,false)==null and ui.find_child("FlaskDeposit",true,false).tooltip_text.contains("不限次数"),"FLASK UI outside battle hides limited-use indicators and explains unlimited transfers")
 var count=presenter.pending.size()+(0 if presenter.active.is_empty() else 1)
 t.check(count>=2 and presenter.pending.any(func(event):return event.source!=""),"FLASK UI interruption fixture includes payment and relic recovery")
 await Pointer.press(t,ui.find_child("FlaskDeposit",true,false));await t.frames()
 t.check(balances_shown(ui,50,10) and count==presenter.pending.size()+(0 if presenter.active.is_empty() else 1),"FLASK UI deposit during feedback updates immediately and preserves earlier action/relic floats")
 await Pointer.press(t,ui.find_child("FlaskWithdraw",true,false));await t.frames()
 var committed=ui.game.export_snapshot()
 var stable=balances_shown(ui,60,0)
 for step in range(count+1):
  presenter._process(presenter.duration)
  stable=stable and balances_shown(ui,60,0)
 presenter.set_process(true)
 t.check(stable and presenter.pending.is_empty() and presenter.active.is_empty() and ui.game.export_snapshot()==committed,"FLASK UI old feedback cannot rewind transferred balances or modify committed state")

static func preparation_deposit(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._finish_battle()
 ui.render();await t.frames()
 t.check(await t.click("reward",{"type":"skip"}) and ui.view.phase=="prepare","FLASK UI enters preparation through reward action")
 ui.game.state.mana=60;ui.game.state.flask_mana=100;ui.render();await t.frames()
 t.check(ui.find_child("FlaskDepositUses",true,false).text=="存 ●●●" and ui.find_child("FlaskWithdrawUses",true,false)==null,"FLASK UI preparation shows three deposit uses and no withdrawal counter")
 for i in range(3): await Pointer.press(t,ui.find_child("FlaskDeposit",true,false))
 t.check(ui.find_child("FlaskDeposit",true,false).disabled and ui.find_child("FlaskDepositUses",true,false).text=="存 ○○○" and ui.find_child("FlaskDeposit",true,false).tooltip_text=="本回合已存入3次。","FLASK UI third preparation deposit disables only deposit")
 for i in range(5): await Pointer.press(t,ui.find_child("FlaskWithdraw",true,false))
 t.check(balances_shown(ui,80,80) and not ui.find_child("FlaskWithdraw",true,false).disabled and ui.find_child("FlaskDeposit",true,false).disabled,"FLASK UI five preparation withdrawals commit without restoring deposits")
 t.check(await t.click("end") and ui.view.phase=="prepare" and ui.find_child("FlaskDepositUses",true,false).text=="存 ●●●" and not ui.find_child("FlaskDeposit",true,false).disabled,"FLASK UI next preparation turn restores three visible deposit uses")
