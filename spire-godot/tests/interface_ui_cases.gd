extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

static func feedback(t) -> void:
 var ui=t.ui;ui.restart(42);await t.frames()
 var report=ui.feedback_report;report.clear_draft()
 var before=ui.game.export_snapshot()
 var entry=ui.find_child("OpenFeedback",true,false)
 t.check(entry.is_visible_in_tree() and ui.find_child("OpenActionLog",true,false)==null,"FEEDBACK entry remains visible without a separate scene log button")
 await press(t,"OpenFeedback");await t.frames()
 t.check(ui.show_feedback and not report.draft.include_logs,"FEEDBACK opens without opting into logs")
 t.check(t.visible_text(ui.drawer_layer).contains("提交反馈需要开启梯子"),"FEEDBACK explains Google network access before submission")
 t.check(not t.visible_text(ui.drawer_layer).contains("gmail.com"),"FEEDBACK recipient is hidden from players")
 await press(t,"FeedbackReview");await t.frames()
 t.check(not report.confirming and report.message=="请填写标题。","FEEDBACK empty title cannot proceed")
 var title=ui.find_child("FeedbackTitle",true,false);title.text="测试反馈";title.text_changed.emit(title.text)
 var description=ui.find_child("FeedbackDescription",true,false);description.text="点击结束回合后出现问题，请检查。";description.text_changed.emit()
 report.draft.logs="本场行动测试记录"
 await press(t,"FeedbackCapture");await t.frames()
 t.check(report.draft.images.size()==1 and report.payload().logs=="" and report.draft.context.has("floor"),"FEEDBACK screenshot captured and unchecked logs omitted")
 var shot=report._decode(report.draft.images[0].data)
 t.check(not shot.is_empty() and maxi(shot.get_width(),shot.get_height())<=1600,"FEEDBACK captured attachment is a bounded JPEG")
 # Inspect the actual captured frame: report panel's opaque pixels must be absent.
 t.check(shot.get_pixel(int(shot.get_width()*0.23),int(shot.get_height()*0.15))!=shot.get_pixel(int(shot.get_width()*0.75),int(shot.get_height()*0.15)),"FEEDBACK screenshot exposes the game after hiding the report overlay")
 await t.capture("ui-feedback-report.png")
 report.add_image(shot);report.add_image(shot);report.add_image(shot);await t.frames()
 t.check(report.draft.images.size()==3 and ui.find_child("FeedbackCapture",true,false).disabled,"FEEDBACK three-image cap blocks extra captures")
 t.check(ui.find_child("FeedbackReview",true,false).get_global_rect().end.y<850 and ui.find_child("FeedbackForm",true,false).get_global_rect().end.x<ui.find_child("FeedbackAttachments",true,false).get_global_rect().position.x,"FEEDBACK split form and attachments keep primary action within the viewport")
 report.draft.context.version="0.17";report.draft.id="old-version-receipt"
 var original_context=report.draft.context.duplicate(true)
 var current_version=str(ProjectSettings.get_setting("application/config/version",""))
 original_context.version=current_version
 ui._close_drawers();ui._refresh_drawers();report.open();await t.frames()
 t.check(ui.find_child("FeedbackTitle",true,false).text=="测试反馈" and report.draft.images.size()==3,"FEEDBACK closing and reopening preserves text and screenshots")
 t.check(report.draft.context==original_context and report.draft.id=="" and report.payload().context.version==current_version,"FEEDBACK restored old draft refreshes runtime version and receipt while preserving captured scene")
 var include=ui.find_child("FeedbackLogs",true,false);include.button_pressed=true;include.toggled.emit(true)
 await press(t,"FeedbackReview");await t.frames()
 t.check(report.confirming and report.payload().logs=="本场行动测试记录" and t.visible_text(ui.drawer_layer).contains("本场行动测试记录"),"FEEDBACK confirmation previews explicitly selected logs")
 t.check(t.visible_text(ui.drawer_layer).contains("版本"+current_version),"FEEDBACK confirmation displays the current runtime version")
 t.check(not t.visible_text(ui.drawer_layer).contains("gmail.com"),"FEEDBACK confirmation also hides recipient")
 var old_endpoint=ProjectSettings.get_setting("feedback/endpoint",null)
 ProjectSettings.set_setting("feedback/endpoint","");await press(t,"FeedbackSend");await t.frames()
 t.check(report.message.contains("尚未开通") and not report.busy,"FEEDBACK missing endpoint preserves report instead of claiming success")
 var requests=[]
 report.transport=func(url,method,body):requests.append({"url":url,"method":method,"body":body});return OK
 ProjectSettings.set_setting("feedback/endpoint","https://feedback.invalid/exec")
 await press(t,"FeedbackSend");await t.frames()
 var id=report.draft.id
 report.submit()
 # The checked save opens with the service schema probe; the report itself follows as a POST.
 t.check(report.busy and requests.size()==1 and requests[0].method==HTTPClient.METHOD_GET and requests[0].body=="" and id.length()==32 and ui.find_child("FeedbackSend",true,false).disabled,"FEEDBACK confirmed submit freezes report and blocks duplicate clicks")
 report._completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"service":"spire-feedback","schema":2}).to_utf8_buffer());await t.frames()
 report._completed(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray());await t.frames()
 t.check(not report.busy and report.draft.id==id and report.draft.images.size()==3 and report.message.contains("草稿已保留"),"FEEDBACK timeout retains report and retry identity")
 await press(t,"FeedbackSend");await t.frames()
 t.check(requests.size()==3 and requests[1].body==requests[2].body,"FEEDBACK retry sends identical report identifier and content")
 report._completed(HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED,302,PackedStringArray(["Location: https://script.googleusercontent.com/macros/echo?receipt=test"]),PackedByteArray())
 t.check(report.busy and requests.size()==4 and requests[3].method==HTTPClient.METHOD_GET and requests[3].body=="" and report.draft.id==id,"FEEDBACK Google redirect reads receipt with GET without forwarding report")
 report._completed(HTTPRequest.RESULT_SUCCESS,302,PackedStringArray(["Location: https://untrusted.invalid/receipt"]),PackedByteArray());await t.frames()
 t.check(not report.busy and requests.size()==4 and report.draft.id==id,"FEEDBACK untrusted redirect preserves draft without sending")
 await press(t,"FeedbackSend");await t.frames()
 report.response_redirects=4
 report._completed(HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED,302,PackedStringArray(["Location: https://script.googleusercontent.com/macros/echo?receipt=test"]),PackedByteArray());await t.frames()
 t.check(not report.busy and requests.size()==5 and report.draft.id==id,"FEEDBACK redirect limit preserves retry identity")
 await press(t,"FeedbackSend");await t.frames()
 t.check(report.response_redirects==0,"FEEDBACK explicit retry resets receipt redirect limit")
 ProjectSettings.set_setting("feedback/endpoint","https://script.google.com/macros/s/test/exec")
 var sent_before_receipt=requests.size()
 report._completed(HTTPRequest.RESULT_SUCCESS,404,PackedStringArray(),PackedByteArray())
 t.check(report.busy and report.checking_receipt and requests.size()==sent_before_receipt+1 and requests[-1].method==HTTPClient.METHOD_GET and requests[-1].url.ends_with("?receipt="+id) and requests[-1].body=="","FEEDBACK missing response checks stored receipt without resending email")
 report._completed(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray());await t.frames()
 t.check(not report.busy and requests.size()==sent_before_receipt+1 and report.draft.id==id,"FEEDBACK receipt lookup failure stops without a loop and preserves draft")
 await press(t,"FeedbackSend");await t.frames()
 report._completed(HTTPRequest.RESULT_SUCCESS,404,PackedStringArray(),PackedByteArray())
 report._completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"ok":true,"id":id}).to_utf8_buffer());await t.frames()
 t.check(report.draft.title=="" and report.draft.images.is_empty() and report.message.contains("提交成功"),"FEEDBACK acknowledged report clears draft and shows receipt")
 t.check(ui.game.state==before,"FEEDBACK draft, capture, failure and submission never change gameplay state")
 report.transport=Callable();ProjectSettings.set_setting("feedback/endpoint",old_endpoint)
 ui._close_drawers();ui._refresh_drawers()

# Isolated stand-in for the save store: proves every attachment degradation reason without
# touching any real directory (docs/spec/feedback-deployment.md「存档附件」).
class SaveStub extends RefCounted:
 var mode=""
 func _init(reason: String) -> void:
  mode=reason
 func fixed_point_text(_game, _map_drawings: Dictionary={}) -> Dictionary:
  if mode=="rejected": return {"ok":false,"error":"无法生成当前进度存档：本局状态不一致。","code":"invalid"}
  return {"ok":true,"slot":"tower","filename":"tower.json","text":"x".repeat(2*1024*1024+1)}

# docs/spec/feedback-deployment.md「证据入口」：默认附带、取消勾选、超限／缺失与探测降级。
static func feedback_save(t) -> void:
 var ui=t.ui;var report=ui.feedback_report
 var Store=preload("res://core/save_store.gd")
 var old_endpoint=ProjectSettings.get_setting("feedback/endpoint",null)
 var old_saves=ui.saves
 ui.restart(42);await t.frames()
 var before=ui.game.export_snapshot()
 ProjectSettings.set_setting("feedback/endpoint","https://feedback.invalid/exec")
 var requests=[]
 report.transport=func(url,method,body):requests.append({"url":url,"method":method,"body":body});return OK
 # A new draft identity: close the drawer, drop the draft, reopen it so context and save re-capture.
 var new_draft=func():
  ui._close_drawers();ui._refresh_drawers()
  report.clear_draft()
  report.open()
  report.draft.title="存档反馈";report.draft.description="附带当前进度存档的测试反馈。"
 var posted=func(index: int):
  var row=requests[index] if requests.size()>index else {}
  return JSON.parse_string(String(row.get("body",""))) if row.get("method",0)==HTTPClient.METHOD_POST else null

 report.clear_draft()
 await press(t,"OpenFeedback");await t.frames()
 t.check(report.draft.include_save and ui.find_child("FeedbackIncludeSave",true,false).button_pressed,"FEEDBACK attaches the current save by default: the checkbox starts checked")
 var title=ui.find_child("FeedbackTitle",true,false);title.text="存档反馈";title.text_changed.emit(title.text)
 var description=ui.find_child("FeedbackDescription",true,false);description.text="附带当前进度存档的测试反馈。";description.text_changed.emit()
 var body=report.payload()
 var attachment=String(body.get("save",{}).get("data",""))
 t.check(body.has("save") and String(body.save.name)==ui.game.state.save_slot+".json","FEEDBACK attaches the current save by default: the payload names the file of the current slot: "+str(body.get("save",{}).get("name","")))
 var text=Marshalls.base64_to_raw(attachment).get_string_from_utf8()
 var envelope=JSON.parse_string(text)
 var decoded=Store.unpack(text)
 t.check(not attachment.is_empty() and envelope is Dictionary and envelope.format==2 and decoded.ok,"FEEDBACK attaches the current save by default: the attachment is a checksummed format 2 envelope: "+str(decoded.get("error","")))
 t.check(decoded.ok and decoded.snapshot.initial_seed==ui.game.state.initial_seed and decoded.snapshot==ui.game.restart_snapshot(),"FEEDBACK attaches the current save by default: the envelope carries this run's fixed point")
 report.review();await t.frames()
 t.check(t.visible_text(ui.drawer_layer).contains("tower.json") and t.visible_text(ui.drawer_layer).contains("KB"),"FEEDBACK attaches the current save by default: the confirmation page shows the attachment name and size")

 requests.clear()
 report.submit();await t.frames()
 t.check(requests.size()==1 and requests[0].method==HTTPClient.METHOD_GET and report.busy,"FEEDBACK new service schema includes the save: the checked draft probes the same endpoint first")
 report._completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"service":"spire-feedback","schema":2}).to_utf8_buffer());await t.frames()
 var with_save=posted.call(1)
 t.check(requests.size()==2 and with_save is Dictionary and with_save.has("save") and String(with_save.save.name)=="tower.json","FEEDBACK new service schema includes the save: schema 2 keeps the save in the payload")
 report._completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"ok":true,"id":report.draft.id}).to_utf8_buffer());await t.frames()
 t.check(not report.busy and report.message.contains("提交成功") and ui.game.export_snapshot()==before,"FEEDBACK new service schema includes the save: the acknowledged report changes no gameplay state")

 new_draft.call();report.review();await t.frames()
 requests.clear()
 report.submit();await t.frames()
 report._completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"service":"spire-feedback","schema":2}).to_utf8_buffer());await t.frames()
 var first_body=String(requests[1].body) if requests.size()>1 else ""
 report._completed(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray());await t.frames()
 t.check(not report.busy and not report.draft.id.is_empty(),"FEEDBACK retry keeps identical save bytes: the failed attempt keeps the draft identity")
 await press(t,"FeedbackSend");await t.frames()
 t.check(first_body!="" and requests.size()==3 and requests[-1].method==HTTPClient.METHOD_POST and String(requests[-1].body)==first_body,"FEEDBACK retry keeps identical save bytes: the retry posts the same body")
 t.check(posted.call(1)!=null and String(posted.call(1).save.data)==String(posted.call(2).save.data),"FEEDBACK retry keeps identical save bytes: the attachment data is unchanged")
 report._completed(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray());await t.frames()
 t.check(not report.busy,"FEEDBACK retry keeps identical save bytes: the repeated failure leaves the report ready for another attempt")

 new_draft.call();report.review();await t.frames()
 requests.clear()
 report.submit();await t.frames()
 report._completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"service":"spire-feedback","schema":1}).to_utf8_buffer());await t.frames()
 var old_format=posted.call(1)
 t.check(requests.size()==2 and old_format is Dictionary and not old_format.has("save"),"FEEDBACK old service schema submits without the save: the payload keeps the old format")
 t.check(t.visible_text(ui.drawer_layer).contains("当前反馈服务暂不支持附带存档。"),"FEEDBACK old service schema submits without the save: the page explains the downgrade")
 report._completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"ok":true,"id":report.draft.id}).to_utf8_buffer());await t.frames()
 t.check(not report.busy and report.message.contains("提交成功"),"FEEDBACK old service schema submits without the save: the report still reaches the old service")

 for failure in ["timeout","status","json"]:
  new_draft.call();report.review();await t.frames()
  requests.clear()
  report.submit();await t.frames()
  if failure=="timeout": report._completed(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray())
  elif failure=="status": report._completed(HTTPRequest.RESULT_SUCCESS,500,PackedStringArray(),PackedByteArray())
  else: report._completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),"{bad".to_utf8_buffer())
  await t.frames()
  var degraded=posted.call(1)
  t.check(requests.size()==2 and degraded is Dictionary and not degraded.has("save"),"FEEDBACK probe failure degrades without blocking: "+failure+" still submits without the save")
  t.check(t.visible_text(ui.drawer_layer).contains("当前反馈服务暂不支持附带存档。"),"FEEDBACK probe failure degrades without blocking: "+failure+" shows the downgrade notice")
  report._completed(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray());await t.frames()
  t.check(not report.busy and ui.game.export_snapshot()==before,"FEEDBACK probe failure degrades without blocking: "+failure+" leaves the draft and the game state")

 # A draft restored with its context already present has no capture yet: the checked box must
 # still carry the current run instead of claiming there is no save (docs/spec/feedback-deployment.md「存档附件」).
 var restored_context={"version":"0.0.0","platform":"test","phase":"战斗","scene":"入口","floor":"塔路","round":7,"seed":-1}
 var restored_draft=func(include_save: bool):
  ui._close_drawers()
  report.clear_draft()
  report.draft={"id":"","kind":"bug","title":"旧草稿","description":"上一进程保留的草稿。","include_logs":false,"include_save":include_save,"context":restored_context.duplicate(true),"logs":"","images":[]}
 restored_draft.call(true)
 t.check(not report.save_captured and not report.payload().has("save") and report.save_status_text().contains("没有捕获到存档") and not report.save_status_text().contains("当前没有可附带的存档。"),"FEEDBACK restored draft before its first use names the real reason: an uncaptured draft never claims no save exists")
 var restored_before=ui.game.restart_snapshot()
 report.open();await t.frames()
 # Reopening a draft of another build refreshes `context.version` and clears the old submission id
 # while keeping the original scene (docs/spec/feedback-deployment.md「输入域」); the restore must
 # not overwrite that scene with this process's startup game.
 var expected_context=restored_context.duplicate(true)
 expected_context.version=str(ProjectSettings.get_setting("application/config/version",""))
 t.check(report.save_captured and report.draft.context==expected_context,"FEEDBACK restored draft captures at its first use: the capture runs once, the restored scene is kept and only the version follows this build")
 var restored_body=report.payload()
 var restored_text=Marshalls.base64_to_raw(String(restored_body.get("save",{}).get("data",""))).get_string_from_utf8()
 var restored_decoded=Store.unpack(restored_text)
 t.check(restored_body.has("save") and String(restored_body.save.name)=="tower.json" and restored_decoded.ok and restored_decoded.snapshot==restored_before,"FEEDBACK restored draft captures at its first use: the attachment is this run's current fixed point")
 t.check(t.visible_text(ui.drawer_layer).contains("tower.json") and not t.visible_text(ui.drawer_layer).contains("当前没有可附带的存档。"),"FEEDBACK restored draft captures at its first use: the page shows the attachment instead of a missing save")
 var restored_json=JSON.stringify(restored_body)
 var drawings_before=ui.map_drawings
 ui.map_drawings={"probe":[PackedVector2Array([Vector2(3,4)])]}
 report._capture_context()
 t.check(JSON.stringify(report.payload())==restored_json,"FEEDBACK restored draft captures at its first use: a later use of the same draft keeps the attachment bytes")
 ui.map_drawings=drawings_before

 restored_draft.call(false);report.open();await t.frames()
 t.check(not report.save_captured and not report.payload().has("save"),"FEEDBACK restored draft checked later captures on the toggle: an unchecked draft stays without an attachment")
 var include=ui.find_child("FeedbackIncludeSave",true,false)
 if include!=null:
  include.button_pressed=true;include.toggled.emit(true);await t.frames()
 t.check(report.save_captured and report.payload().has("save") and t.visible_text(ui.drawer_layer).contains("tower.json"),"FEEDBACK restored draft checked later captures on the toggle: the checked box carries the current save")

 for reason in ["none","rejected","oversized"]:
  ui.saves=(null if reason=="none" else SaveStub.new(reason))
  new_draft.call()
  ui.saves=old_saves
  await t.frames()
  requests.clear()
  t.check(not report.payload().has("save") and t.visible_text(ui.drawer_layer).contains("未附带存档"),"FEEDBACK oversized or missing save never blocks: "+reason+" is visible and attaches nothing")
  var named={"none":"当前没有可附带的存档。","rejected":"当前进度存档校验未通过","oversized":"超过 2 MB"}[reason]
  t.check(t.visible_text(ui.drawer_layer).contains(named) and not (reason!="none" and t.visible_text(ui.drawer_layer).contains("当前没有可附带的存档。")),"FEEDBACK every missing save names its own reason: "+reason+" shows "+named+" and never claims no save exists")
  report.review();report.submit();await t.frames()
  t.check(requests.size()==1 and requests[0].method==HTTPClient.METHOD_POST and report.busy,"FEEDBACK oversized or missing save never blocks: the report submits without a probe")
  report._completed(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray());await t.frames()
  t.check(not report.busy and ui.game.export_snapshot()==before,"FEEDBACK oversized or missing save never blocks: the attempt never changes gameplay state")

 new_draft.call();await t.frames()
 include=ui.find_child("FeedbackIncludeSave",true,false)
 t.check(include!=null and include.button_pressed,"FEEDBACK unchecked save is omitted but submit still works: the real checkbox starts checked")
 if include!=null:
  include.button_pressed=false;include.toggled.emit(false);await t.frames()
 requests.clear()
 t.check(not report.draft.include_save and not report.payload().has("save") and t.visible_text(ui.drawer_layer).contains("未附带存档：已取消勾选。"),"FEEDBACK unchecked save is omitted but submit still works: the reason is visible and nothing is attached")
 report.review();report.submit();await t.frames()
 t.check(requests.size()==1 and requests[0].method==HTTPClient.METHOD_POST and report.busy,"FEEDBACK unchecked save is omitted but submit still works: the report posts without a probe")
 report._completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"ok":true,"id":report.draft.id}).to_utf8_buffer());await t.frames()
 t.check(not report.busy and report.message.contains("提交成功") and ui.game.export_snapshot()==before,"FEEDBACK unchecked save is omitted but submit still works: the acknowledged report changes no gameplay state")

 report.transport=Callable();ProjectSettings.set_setting("feedback/endpoint",old_endpoint)
 ui.saves=old_saves
 ui._close_drawers();ui._refresh_drawers()

# Judge pins for the hover term boxes (docs/spec/card-terms.md 判据1「按 data/card_text.gd::TERMS 的
# 字面比较」): rewording a term, dropping it from keywords() or rendering the wrong face must fail the
# assertion, which a comparison against the same metadata source could not do. Same shape as the
# wording pins in tests/card_text_cases.gd; product code keeps TERMS as the only wording source.
const TERM_PINS={
 "mana_search":{"bound":[{"name":"检索","detail":"从抽牌堆抽取指定类型的牌。"}],
  "free":[{"name":"检索","detail":"从抽牌堆抽取指定类型的牌。"},{"name":"束缚等级","detail":"上身或腿部综合受限程度（0—4级）。0级不等于各部位自由。"}]},
 "witch_escape_practice":{"bound":[{"name":"挣扎","detail":"受力量、蓄力和挣扎倍率影响。卡牌以卡面伤害的50%波及同位置其他拘束具，各自计算倍率。"}],
  "free":[{"name":"滑脱","detail":"受灵巧、蓄力和滑脱倍率影响；三档免疫。卡牌波及同大部位其他位置：各选最松的可滑脱装备1件，并列随机；基础为卡面伤害的50%，各自计算倍率。"}]}}

# One box per term, each box a name label plus a definition label, in face-metadata order.
static func pinned_terms(type: String, side: String) -> Array:
 return TERM_PINS[type][side].duplicate(true)

static func term_boxes(popup) -> Array:
 var result=[]
 if popup==null or popup.get_child_count()==0: return result
 for child in popup.get_child(0).get_children():
  if not child is PanelContainer: continue
  var labels=child.get_child(0).get_children()
  result.append({"name":labels[0].text,"detail":labels[1].text})
 return result

static func press(t, name: String) -> void:
 var button=t.ui.find_child(name,true,false)
 t.check(button!=null and button.is_visible_in_tree(),"INTERFACE actual navigation button available: "+name)
 if button==null: return
 var point=button.get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)

static func run(t) -> void:
 await feedback(t)
 await feedback_save(t)
 await run_header(t)
 await card_illustrations(t)
 await deck_browser(t)
 await deck_sorting(t)
 await pile_browsers(t)
 await card_terms(t)
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
 t.check(deck_card!=null and deck_card.get_script()==preload("res://ui/card_face.gd") and deck_card.drag_payload.is_empty(),"DECK uses hand face without gameplay drag")
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
 var face_script=preload("res://ui/card_face.gd")
 var before=t.ui.game.export_snapshot()
 var missing=[];var broken=[];var overflow=[];var paths={}
 var desire_art=["itching_heart","self_satisfaction","psychological_suggestion","rally_spirit","desire_rune","forced_edging","forced_climax"]
 for id in t.ui.game.Cards.Rules.SPECS:
  var spec=t.ui.game.Cards.Rules.SPECS[id]
  var art=spec.get("art_type",id)
  if not face_script.ILLUSTRATIONS.has(art):
   missing.append(id);continue
  var texture=face_script.ILLUSTRATIONS[art]
  var source=spec.get("art_source","magic_hand" if art=="magic_hand_gift" else art)
  if source in desire_art: source="itching_heart"
  if texture==null or texture!=face_script.ILLUSTRATIONS.get(source) or texture.get_image().get_used_rect().size==Vector2i.ZERO or (paths.has(texture.resource_path) and paths[texture.resource_path]!=source):
   broken.append(id);continue
  paths[texture.resource_path]=source
  var card=face_script.new()
  card.symbol=id;card.lift_on_hover=false
  card.position=Vector2(-2000,-2000);card.size=Vector2(190,285)
  t.root.add_child(card)
  var picture=card.get_node("CardIllustration")
  for dimensions in [Vector2(190,285),Vector2(290,360)]:
   card.size=dimensions;card.free_face=not card.free_face;card.queue_redraw()
   var art_ratio=2.0/3.0
   if picture.texture!=texture or picture.material!=null or picture.mouse_filter!=Control.MOUSE_FILTER_IGNORE or not Rect2(Vector2.ZERO,dimensions).encloses(picture.get_rect()) or not is_equal_approx(card.art_bottom-6,dimensions.y*art_ratio) or picture.stretch_mode!=TextureRect.STRETCH_KEEP_ASPECT_CENTERED or picture.position.y<42 or not picture.clip_contents:
    overflow.append(id)
  card.free()
 t.check(missing.is_empty(),"CARD ART every registered card has an illustration: "+str(missing))
 t.check(broken.is_empty(),"CARD ART illustrations are nonempty and distinct except declared art aliases and the desire-card group: "+str(broken))
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
 var keyword_errors=[]
 for dimensions in [Vector2(158,252),Vector2(181,290),Vector2(300,480)]:
  for free in [false,true]:
   for sample in samples:
    sample.face.size=dimensions;t.ui.card_faces[sample.data.uid]=free;t.ui._refresh_card_face(sample.face,sample.data)
   await t.frames()
   for sample in samples:
    var box=sample.face.get_node("CardText")
    var content=box.get_node("Content")
    var picture=sample.face.get_node("CardIllustration")
    var footer=sample.face.get_node("CardKeywords")
    var requirements=sample.face.get_node("CardRequirements")
    var art_ratio=2.0/3.0
    if not Rect2(Vector2.ZERO,dimensions).encloses(box.get_rect()) or box.position.y<picture.get_rect().end.y or not is_equal_approx(sample.face.art_bottom-6,dimensions.y*art_ratio) or content.size.x>box.size.x or not box.clip_contents: text_overflow.append(sample.data.type+str(free)+str(dimensions))
    # Scroll offsets are integer pixels; a fractional layout remainder is not a scrollable row.
    if floorf(content.size.y-box.size.y)>=1:
     box.scroll_vertical=int(ceilf(content.size.y))
     if box.scroll_vertical<=0: text_overflow.append(sample.data.type+" unreachable text "+str({"content":content.size.y,"height":box.size.y,"maximum":box.get_v_scroll_bar().max_value,"page":box.get_v_scroll_bar().page}))
     box.scroll_vertical=0
    var badges=sample.face.get_node("CardMana")
    var title=sample.face.get_node("CardTitle")
    var cost=sample.face.get_node("CardCost")
    var header_scale=1.5 if dimensions.y==480 else 1.0
    if not cost.get_rect().get_center().is_equal_approx(Vector2(19,19)*header_scale) or cost.get_line_count()!=1 or title.get_rect().end.y>picture.position.y: header_errors.append(sample.data.type+" header alignment")
    if sample.data.type=="hannya_henshin":
     t.check(title.text.replace("\n","")==sample.data.name and title.get_visible_line_count()==title.get_line_count() and title.get_rect().end.y<=42*header_scale,"HANNYA TITLE full perfect-henshin name fits the header without truncation: rect=%s lines=%d/%d font=%d" % [str(title.get_rect()),title.get_visible_line_count(),title.get_line_count(),title.get_theme_font_size("font_size")])
    var expected=sample.data.face_mana["free" if free else "bound"]
    if badges.visible!=not expected.is_empty() or badges.get_child_count()!=expected.size(): header_errors.append(sample.data.type+" visibility")
    if badges.visible and (not Rect2(Vector2.ZERO,dimensions).encloses(badges.get_rect()) or title.get_rect().end.x>badges.position.x or badges.position.y>2 or badges.get_rect().end.y>picture.position.y): header_errors.append(sample.data.type+" overlap: title="+str(title.get_rect())+" badges="+str(badges.get_rect())+" card="+str(dimensions))
    if footer.visible:
     if not Rect2(Vector2.ZERO,dimensions).encloses(footer.get_rect()) or box.get_rect().end.y>footer.position.y: keyword_errors.append(sample.data.type+" footer bounds")
     for label in footer.get_children():
      if not Rect2(Vector2.ZERO,footer.size).encloses(label.get_rect()) or label.get_line_count()!=1: keyword_errors.append(sample.data.type+" split keyword")
      if footer.get_children().any(func(other):return other!=label and label.get_rect().intersects(other.get_rect())): keyword_errors.append(sample.data.type+" overlapping keywords")
    var requirement_text=Array(sample.data.face_requirements["free" if free else "bound"])
    if requirements.get_children().map(func(label):return label.text)!=requirement_text: keyword_errors.append(sample.data.type+" missing requirements")
    if requirements.visible:
     if not Rect2(Vector2.ZERO,dimensions).encloses(requirements.get_rect()) or not is_equal_approx(requirements.get_rect().end.x,dimensions.x-12) or not is_equal_approx(requirements.get_rect().end.y,dimensions.y-14) or box.get_rect().end.y>requirements.position.y or requirements.position.y<picture.get_rect().end.y: keyword_errors.append(sample.data.type+" requirement bounds "+str(dimensions)+str(requirements.get_rect()))
     if footer.visible and requirements.get_rect().intersects(footer.get_rect()): keyword_errors.append(sample.data.type+" requirements overlap keywords")
     if requirements.get_children().any(func(label):return label.horizontal_alignment!=HORIZONTAL_ALIGNMENT_RIGHT or not Rect2(Vector2.ZERO,requirements.size).encloses(label.get_rect())): keyword_errors.append(sample.data.type+" requirement alignment")
    if sample.data.type=="fire_dynamics":
     if not footer.visible or footer.get_child_count()!=1 or footer.get_child(0).text!="唯一" or content.get_node("CardEffect").text.contains("唯一"): keyword_errors.append("fire dynamics unique must move to bottom on both faces")
 # A deliberate display-only long-copy fixture survives later wording simplifications.
 # Every real card and both faces have already been checked above.
 var dense=samples[0]
 dense.face.position=Vector2(700,280);dense.face.z_index=200
 dense.face.get_node("CardText/Content/CardEffect").text="使用前请确认目标。\n".repeat(12)
 dense.face.size=Vector2(158,252);dense.face.fit_text();await t.frames()
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
 t.check(keyword_errors.is_empty(),"CARD KEYWORDS standalone tags stay whole at the bottom outside scrollable effects: "+str(keyword_errors))
 var copy=face_script.separate_keywords("每消耗1张，恢复10魔力。消耗。",[{"name":"消耗"}])
 t.check(copy.body=="每消耗1张，恢复10魔力。" and copy.keywords==["消耗"],"CARD KEYWORDS preserve effect clauses mentioning a keyword")
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
 var wall_action=Queries.find(ui.view,"posture",{"dest":"stand","wall":true})
 var normal_action=Queries.find(ui.view,"posture",{"dest":"stand","wall":false})
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
 for type in ["pot_of_greed","focus","binding_enthusiast","unlock"]: ui.game._gain_card(type)
 ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await press(t,"OpenDeck")
 var grid=ui.find_child("DeckGrid",true,false)
 var sort=ui.find_child("DeckSort",true,false)
 var ordered=grid.get_children().map(func(card):return card.symbol)
 t.check(ordered.find("pot_of_greed")<ordered.find("unlock") and ordered.find("unlock")<ordered.find("strain") and ordered.find("strain")<ordered.find("binding_enthusiast"),"DECK costs use shown zero-cost unlock and override both name and rarity: "+str(grid.get_children().map(func(card):return [card.symbol,card.get_node("CardCost").text])))
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

# Battle-exterior card faces read their terms from the metadata of the dictionary they were built
# with (docs/spec/card-terms.md「取源」); the deck browser is the instance-card surface, where the
# merged growth note must survive next to the boxes.
static func card_terms(t) -> void:
 var ui=t.ui
 var Catalog=preload("res://data/encyclopedia.gd")
 ui.selected_character="witch";ui.restart(42);await t.frames()
 ui.game=preload("res://tests/witch_expansion_cases.gd").fresh()
 ui.game._gain_card("witch_escape_practice")
 # Tallest live face measured for this slice (build/term_probe sweep, docs/record/verification.md):
 # four boxes with the longest definitions of any card, so it is the worst case for the clamp.
 ui.game._gain_card("endless_war_goddess")
 var deck_card=ui.game.state.deck.filter(func(row):return row.type=="witch_escape_practice").back()
 ui.game.state.discard.filter(func(row):return row.uid==deck_card.uid).back().practice_plays=6
 ui.render();await t.frames()
 var catalog_note=Catalog.card("witch_escape_practice").note
 var instance_note=ui.game.live_card_text("witch_escape_practice",deck_card.uid).note
 t.check(instance_note.begins_with(catalog_note) and instance_note!=catalog_note,"TERMS UI deck instance carries growth text the catalog note does not")
 var before=ui.game.export_snapshot();var version=ui.view.version
 await press(t,"OpenDeck")
 var face=ui.find_child("DeckGrid",true,false).get_children().filter(func(button):return button.get_meta("physical_uid")==deck_card.uid)[0]
 var side="free" if face.free_face else "bound"
 await t.move_mouse(Vector2(70,100));await t.frames()
 await t.move_mouse(face.get_global_rect().get_center());await t.frames()
 var popup=ui.find_child("TermExplanation",true,false)
 var expected=pinned_terms("witch_escape_practice",side)
 t.check(popup!=null and term_boxes(popup)==expected,"TERMS UI deck instance hover boxes equal the current face metadata: "+str(term_boxes(popup)))
 t.check(popup!=null and popup.get_child(0).get_children().filter(func(node):return node is PanelContainer).size()==expected.size(),"TERMS UI deck instance box count equals the face term count")
 t.check(popup!=null and t.visible_text(popup).contains(instance_note),"TERMS UI deck instance hover keeps the growth text merged from the physical card")
 t.check(ui.game.export_snapshot()==before and ui.view.version==version,"TERMS UI deck hover changes no state and no view version")
 # The tallest live face of every card (374x710, four boxes, 825px longest definition): the popup
 # height is otherwise only bounded by the position clamp, so this is its worst case.
 var tall_rows=ui.game.state.deck.filter(func(row):return row.type=="endless_war_goddess")
 t.check(not tall_rows.is_empty(),"TERMS UI tallest face fixture sits in the deck")
 if not tall_rows.is_empty():
  var tall_face=ui.find_child("DeckGrid",true,false).get_children().filter(func(button):return button.get_meta("physical_uid")==tall_rows.back().uid)[0]
  var scroll=tall_face.get_parent()
  while scroll!=null and not scroll is ScrollContainer: scroll=scroll.get_parent()
  if scroll!=null: scroll.ensure_control_visible(tall_face)
  await t.frames()
  await t.move_mouse(Vector2(70,100));await t.frames()
  await t.move_mouse(tall_face.get_global_rect().get_center());await t.frames()
  var tall_popup=ui.find_child("TermExplanation",true,false)
  var tall_rect=tall_popup.get_global_rect() if tall_popup!=null else Rect2()
  t.check(tall_popup!=null and Rect2(0,0,1600,900).encloses(tall_rect) and not tall_rect.intersects(tall_face.get_global_rect()),"TERMS UI tallest face keeps every term box inside the viewport and clear of the anchor")
 await t.move_mouse(Vector2(70,100));await t.frames()
 await t.close_information()
 ui.selected_character="original";ui.restart(42);await t.frames()

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
 await t.open_menu();await press(t,"OpenLog")
 t.check(ui.find_child("HeaderRound",true,false).text=="第4回合" and ui.view.action_log.back().round==4 and t.visible_text(ui.find_child("InformationDrawer",true,false)).contains("魔法少女 · 第4回合"),"HEADER preparation and visible action log use the same fourth turn")
 await t.close_information()
 t.check(await t.click("end") and ui.find_child("HeaderRound",true,false).text=="第5回合" and ui.view.action_log.back().round==5,"HEADER next preparation turn advances header and latest log together")
 ui.game.state=before;ui.render();await t.frames()
