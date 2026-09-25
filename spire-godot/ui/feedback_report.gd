extends Node
# UI-owned report drafts; never writes GameState or dispatches gameplay commands.
const DRAFT="user://feedback-draft.json"
const MAX_IMAGES=3
const MAX_IMAGE_BYTES=2*1024*1024
# docs/spec/feedback-deployment.md「存档附件」: decoded limit 2 MiB (base64 stays under 2796204 chars).
const MAX_SAVE_BYTES=2*1024*1024
# Stable reason codes for a missing attachment; the visible line maps them, so a failure never
# borrows another reason's wording (docs/spec/feedback-deployment.md「存档附件」).
const SAVE_NONE="none"
const SAVE_INVALID="invalid"
const SAVE_OVERSIZED="oversized"
var host
var draft={"id":"","kind":"bug","title":"","description":"","include_logs":false,"include_save":true,"context":{},"logs":"","images":[]}
var message=""
var busy=false
var confirming=false
var request: HTTPRequest
var save_timer: Timer
var transport: Callable
var response_redirects=0
var checking_receipt=false
# The attachment and the probe answer belong to one draft identity: captured and probed once,
# only serialized through SaveStore.fixed_point_text, never written into the draft file, so a
# retry of the same draft sends a byte-identical body (docs/spec/feedback-deployment.md).
# `save_reason` is the code of the failed capture; "" means this draft never ran its capture.
var save_attachment={}
var save_reason=""
var save_captured=false
var save_probed=false
var save_declined=false
var probing=false

func _ready() -> void:
 request=HTTPRequest.new();request.timeout=40;request.max_redirects=0;request.body_size_limit=65536
 add_child(request);request.request_completed.connect(_completed)
 save_timer=Timer.new();save_timer.one_shot=true;save_timer.wait_time=0.6
 add_child(save_timer);save_timer.timeout.connect(save_draft)
 if host.persistence_enabled and FileAccess.file_exists(DRAFT):
  var file=FileAccess.open(DRAFT,FileAccess.READ)
  if file!=null and file.get_length()<9*1024*1024:
   var restored=JSON.parse_string(file.get_as_text())
   if restored is Dictionary and valid_draft(restored):
    draft=restored
    if not draft.has("include_save"): draft.include_save=true

static func valid_draft(value: Dictionary) -> bool:
 if value.get("kind","") not in ["bug","suggestion"] or not value.get("id") is String: return false
 if not value.get("include_save",true) is bool: return false
 if not value.get("title") is String or value.title.length()>100 or not value.get("description") is String or value.description.length()>4000: return false
 if not value.get("include_logs") is bool or not value.get("context") is Dictionary or not value.get("logs") is String or value.logs.length()>18000: return false
 if not value.get("images") is Array or value.images.size()>MAX_IMAGES: return false
 for picture in value.images:
  if not picture is Dictionary or not picture.get("data") is String or picture.data.length()>MAX_IMAGE_BYTES*4/3+4: return false
 return true

func save_draft() -> void:
 if not host.persistence_enabled: return
 var file=FileAccess.open(DRAFT,FileAccess.WRITE)
 if file!=null: file.store_string(JSON.stringify(draft))

func changed() -> void:
 # A changed draft is a new identity: the next submit probes the service again.
 draft.id="";confirming=false;message="";save_probed=false;save_declined=false;save_timer.start()

func open() -> void:
 _capture_context()
 host._open_drawer("show_feedback")

func _capture_context() -> void:
 var version=str(ProjectSettings.get_setting("application/config/version",""))
 if draft.context.is_empty():
  var v=host.view
  draft.context={"version":version,"platform":OS.get_name(),"phase":v.get("phase_caption",""),"scene":v.get("room_name",""),"floor":v.get("run_header",{}).get("location",""),"round":v.get("round",0),"seed":v.get("seed",0)}
  var rows=[]
  for item in v.get("action_log",[]).slice(-40): rows.append("%s · 第%s回合：%s" % [item.get("actor",""),str(item.get("round",0)),item.get("text","")])
  draft.logs="\n".join(rows).left(18000)
  save_draft()
 elif draft.context.get("version","")!=version:
  # Upgrade restored drafts without discarding their original scene or attachments.
  draft.context.version=version
  changed()
  save_draft()
 _capture_save_once()

# One capture per draft identity: a draft with its context captured right away attaches the run of
# that moment, and a draft restored from disk (context already present) attaches at its first use,
# where the game is the playing run instead of this process's startup game. Editing stays inside
# the same identity, so a retry never recaptures and never changes the body
# (docs/spec/feedback-deployment.md「存档附件」).
func _capture_save_once() -> void:
 if save_captured or not draft.include_save: return
 save_captured=true
 _capture_save()

func endpoint() -> String:
 return str(ProjectSettings.get_setting("feedback/endpoint","")).strip_edges()

# Read-only capture of this run's current fixed point: no file access, no state change.
func _capture_save() -> void:
 save_attachment={};save_reason=""
 if host.saves==null or host.game==null:
  save_reason=SAVE_NONE;return
 var result=host.saves.fixed_point_text(host.game,host.map_drawings)
 if not result.ok:
  save_reason=SAVE_INVALID;return
 var bytes=String(result.text).to_utf8_buffer()
 if bytes.size()>MAX_SAVE_BYTES:
  save_reason=SAVE_OVERSIZED;return
 save_attachment={"name":String(result.filename),"data":Marshalls.raw_to_base64(bytes),"bytes":bytes.size()}

# The visible attachment line: the confirmation page shows the name and size, or the real reason
# this draft carries no attachment. Every variant is player copy and reads its zh_CN source key.
func save_status_text() -> String:
 if draft.context.is_empty(): return ""
 if save_declined: return host._text("ui.feedback.save.declined","当前反馈服务暂不支持附带存档。")
 if not draft.include_save: return host._text("ui.feedback.save.unchecked","未附带存档：已取消勾选。")
 if save_attachment.is_empty():
  match save_reason:
   SAVE_NONE: return host._text("ui.feedback.save.none","未附带存档：当前没有可附带的存档。")
   SAVE_INVALID: return host._text("ui.feedback.save.invalid","未附带存档：当前进度存档校验未通过，未附带。")
   SAVE_OVERSIZED: return host._text("ui.feedback.save.oversized","未附带存档：存档过大（超过 2 MB），未附带。")
   _: return host._text("ui.feedback.save.uncaptured","未附带存档：本次草稿没有捕获到存档。")
 return host._text("ui.feedback.save.attached","将附带当前进度存档：{name}（{size} KB）",{"name":save_attachment.name,"size":"%.1f" % (float(save_attachment.bytes)/1024.0)})

func _save_included() -> bool:
 return draft.include_save and not save_declined and not save_attachment.is_empty()

func payload() -> Dictionary:
 var body={"schema":1,"id":draft.id,"kind":draft.kind,"title":draft.title.strip_edges(),"description":draft.description.strip_edges(),"context":draft.context.duplicate(true),"logs":draft.logs if draft.include_logs else "","images":draft.images.duplicate(true)}
 # The report format stays 1; `save` is additive and only set after a successful probe.
 if _save_included(): body.save={"name":save_attachment.name,"data":save_attachment.data}
 return body

func validation() -> String:
 if draft.title.strip_edges().is_empty(): return "请填写标题。"
 if draft.description.strip_edges().is_empty(): return "请描述遇到的问题或修改建议。"
 if draft.description.length()>4000: return "详细描述最多4000字。"
 return ""

func refresh() -> void:
 if host.show_feedback: host._refresh_drawers()

func build(column: VBoxContainer) -> void:
 column.add_theme_constant_override("separation",14)
 var steps=HBoxContainer.new();steps.add_theme_constant_override("separation",24);column.add_child(steps)
 steps.add_child(host._label("01  填写内容",15,host.MUTED if confirming else host.CYAN))
 steps.add_child(host._label("—",15,host.MUTED))
 steps.add_child(host._label("02  确认提交",15,host.CYAN if confirming else host.MUTED))
 for label in steps.get_children(): label.autowrap_mode=TextServer.AUTOWRAP_OFF
 var workspace=HBoxContainer.new();workspace.add_theme_constant_override("separation",18);workspace.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(workspace)
 var form=_section(workspace,1.7,"FeedbackForm")
 var attachments=_section(workspace,1.0,"FeedbackAttachments")
 if confirming:
  form.add_child(host._label("确认这次反馈",18,host.GOLD))
  var preview=host._scroll(form)
  preview.add_child(host._label(("Bug反馈" if draft.kind=="bug" else "修改建议")+" · "+draft.title,22,host.CYAN))
  preview.add_child(host._label(draft.description,17))
  preview.add_child(HSeparator.new())
  var context=draft.context
  preview.add_child(host._label("版本%s · %s · %s · 第%s回合\n%s · %s · 种子%s" % [context.version,context.platform,context.floor,str(context.round),context.scene,context.phase,str(context.seed)],14,host.MUTED))
  if draft.include_logs: preview.add_child(host._label("行动日志：\n"+(draft.logs if not draft.logs.is_empty() else "暂无记录"),14,host.MUTED))
  else: preview.add_child(host._label("未附带行动日志",14,host.MUTED))
 else:
  var tabs=HBoxContainer.new();tabs.add_theme_constant_override("separation",10);form.add_child(tabs)
  for kind in ["bug","suggestion"]:
   var tab=host._button("Bug反馈" if kind=="bug" else "修改建议",func():draft.kind=kind;changed();refresh(),host.CYAN if draft.kind==kind else host.MUTED)
   tab.name="FeedbackKind_"+kind;tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tab.custom_minimum_size.y=40
   if draft.kind==kind: tab.add_theme_stylebox_override("normal",host._style(Color("23403f"),host.CYAN.darkened(0.25)))
   tabs.add_child(tab)
  form.add_child(host._label("标题",16,host.GOLD))
  var title=LineEdit.new();title.name="FeedbackTitle";title.placeholder_text="用一句话概括问题或建议";title.max_length=100;title.text=draft.title;title.custom_minimum_size.y=42;form.add_child(title)
  title.text_changed.connect(func(value):draft.title=value;changed())
  var caption=HBoxContainer.new();form.add_child(caption)
  var heading=host._label("详细描述",16,host.GOLD);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;caption.add_child(heading)
  var count=host._label("%d / 4000" % draft.description.length(),13,host.MUTED);count.custom_minimum_size.x=90;count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;caption.add_child(count)
  var description=TextEdit.new();description.name="FeedbackDescription";description.placeholder_text="发生了什么？\n\n可以写下操作步骤、实际结果，以及你期望的表现。" if draft.kind=="bug" else "你希望游戏怎样改进？\n\n可以说说想法，以及这样修改的原因。";description.text=draft.description
  description.custom_minimum_size=Vector2(0,180);description.size_flags_vertical=Control.SIZE_EXPAND_FILL;description.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
  description.add_theme_stylebox_override("normal",host._style(Color("0b141d"),Color("354751"),6));description.add_theme_stylebox_override("focus",host._style(Color("0d1922"),host.CYAN.darkened(0.4),6));form.add_child(description)
  description.text_changed.connect(func():
   if description.text.length()>4000: description.text=description.text.left(4000)
   draft.description=description.text;count.text="%d / 4000" % draft.description.length();changed())
  var include=CheckBox.new();include.name="FeedbackLogs";include.text="附带最近40条行动日志";include.button_pressed=draft.include_logs;include.add_theme_stylebox_override("normal",StyleBoxEmpty.new());form.add_child(include)
  include.toggled.connect(func(value):draft.include_logs=value;changed())
 var image_heading=HBoxContainer.new();attachments.add_child(image_heading)
 var image_label=host._label("截图附件",18,host.GOLD);image_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;image_heading.add_child(image_label)
 var image_count=host._label("%d / 3" % draft.images.size(),15,host.MUTED);image_count.custom_minimum_size.x=50;image_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;image_heading.add_child(image_count)
 if not confirming:
  var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",8);attachments.add_child(actions)
  var capture=host._button("截取游戏画面",capture_screen);capture.name="FeedbackCapture";capture.disabled=draft.images.size()>=MAX_IMAGES;actions.add_child(capture)
  var attach=host._button("本地图片",choose_image,host.MUTED);attach.name="FeedbackAttach";attach.disabled=draft.images.size()>=MAX_IMAGES;actions.add_child(attach)
  for button in [capture,attach]: button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.add_theme_font_size_override("font_size",14)
 var gallery=host._scroll(attachments)
 if draft.images.is_empty():
  var empty=host._label("＋\n\n尚未添加截图\n\nPNG / JPEG · 最多3张",18,host.MUTED)
  empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.custom_minimum_size.y=220;gallery.add_child(empty)
 else: _pictures(gallery,not confirming)
 attachments.add_child(host._label("点击截图可放大查看。" if confirming else "截图时会隐藏此窗口，图片自动压缩。",13,host.MUTED))
 var save_heading=HBoxContainer.new();attachments.add_child(save_heading)
 var save_label=host._label("进度存档",18,host.GOLD);save_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;save_heading.add_child(save_label)
 if not confirming:
  var include_save=CheckBox.new();include_save.name="FeedbackIncludeSave";include_save.text="一并附带当前进度存档";include_save.button_pressed=draft.include_save
  include_save.add_theme_stylebox_override("normal",StyleBoxEmpty.new());save_heading.add_child(include_save)
  include_save.toggled.connect(func(value):draft.include_save=value;changed();_capture_save_once();save_draft();refresh())
  attachments.add_child(host._label("反馈会连同当前进度存档一起发送；取消勾选则只发送上面的内容。",13,host.MUTED))
 if save_status_text()!="": attachments.add_child(host._label(save_status_text(),14,host.CYAN if _save_included() else host.MUTED))
 column.add_child(HSeparator.new())
 column.add_child(host._label("提交反馈需要开启梯子（能访问 Google 服务）。",14,host.GOLD))
 var notice=host._label(message if not message.is_empty() else "关闭会保留草稿；确认后仅发送本次预览内容。",14,host.CYAN if message.begins_with("提交成功") else host.MUTED)
 notice.name="FeedbackNotice";column.add_child(notice)
 var buttons=HBoxContainer.new();buttons.add_theme_constant_override("separation",12);column.add_child(buttons)
 var spacer=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if confirming:
  var edit=host._button("← 返回修改",func():confirming=false;refresh(),host.MUTED);edit.disabled=busy;buttons.add_child(edit);buttons.add_child(spacer)
  var send=host._button("发送中…" if busy else "确认提交",submit,host.CYAN);send.name="FeedbackSend";send.disabled=busy;send.custom_minimum_size=Vector2(190,44);buttons.add_child(send)
 else:
  var clear=host._button("清空草稿",clear_draft,host.MUTED);clear.name="FeedbackClear";buttons.add_child(clear)
  buttons.add_child(spacer)
  var review_button=host._button("预览并提交 →",review,host.CYAN);review_button.name="FeedbackReview";review_button.custom_minimum_size=Vector2(190,44);buttons.add_child(review_button)

func _section(parent: HBoxContainer, ratio: float, id: String) -> VBoxContainer:
 var panel=PanelContainer.new();panel.name=id;panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.size_flags_stretch_ratio=ratio
 panel.add_theme_stylebox_override("panel",host._style(Color("0e1923"),Color("35464c"),8));parent.add_child(panel)
 var content=VBoxContainer.new();content.add_theme_constant_override("separation",12);panel.add_child(content)
 return content

func _pictures(column: VBoxContainer, removable: bool) -> void:
 if draft.images.is_empty(): return
 for index in range(draft.images.size()):
  var box=VBoxContainer.new();column.add_child(box)
  var heading=HBoxContainer.new();box.add_child(heading)
  var label=host._label("截图 %02d" % (index+1),13,host.MUTED);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(label)
  if removable:
   var remove=host._button("删除",func():draft.images.remove_at(index);changed();save_draft();refresh(),host.MUTED);remove.name="FeedbackRemove%d" % index;remove.custom_minimum_size.y=25;remove.add_theme_font_size_override("font_size",12);heading.add_child(remove)
  var image=_decode(draft.images[index].data)
  var button=TextureButton.new();button.name="FeedbackImage%d" % index;button.texture_normal=ImageTexture.create_from_image(image)
  button.ignore_texture_size=true;button.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED;button.custom_minimum_size=Vector2(240,180 if draft.images.size()==1 else 105);box.add_child(button)
  button.pressed.connect(func():preview_image(index))

static func _decode(data: String) -> Image:
 var image=Image.new()
 if image.load_jpg_from_buffer(Marshalls.base64_to_raw(data))!=OK: return Image.create(1,1,false,Image.FORMAT_RGB8)
 return image

func preview_image(index: int) -> void:
 var popup=AcceptDialog.new();popup.title="截图预览";popup.dialog_text="";popup.ok_button_text="关闭"
 var image=TextureRect.new();image.texture=ImageTexture.create_from_image(_decode(draft.images[index].data));image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.custom_minimum_size=Vector2(640,360);popup.add_child(image);add_child(popup);popup.popup_centered(Vector2i(860,530));popup.confirmed.connect(popup.queue_free);popup.canceled.connect(popup.queue_free)

func capture_screen() -> void:
 if busy or draft.images.size()>=MAX_IMAGES: return
 var layer=host.drawer_layer
 host._hide_term();layer.hide()
 await RenderingServer.frame_post_draw
 var image=get_viewport().get_texture().get_image()
 if is_instance_valid(layer): layer.show()
 add_image(image)

func choose_image() -> void:
 var picker=FileDialog.new();picker.file_mode=FileDialog.FILE_MODE_OPEN_FILE;picker.access=FileDialog.ACCESS_FILESYSTEM
 picker.title="选择截图";picker.filters=PackedStringArray(["*.png ; PNG截图","*.jpg,*.jpeg ; JPEG截图"])
 picker.use_native_dialog=true;add_child(picker)
 picker.file_selected.connect(func(path):load_image(path);picker.queue_free())
 picker.canceled.connect(picker.queue_free);picker.popup_centered_ratio(0.75)

func load_image(path: String) -> void:
 if busy or draft.images.size()>=MAX_IMAGES: return
 var file=FileAccess.open(path,FileAccess.READ)
 if file==null or file.get_length()>12*1024*1024:
  message="无法读取图片，或文件超过12MB。";refresh();return
 var bytes=file.get_buffer(file.get_length());var image=Image.new();var error=ERR_FILE_UNRECOGNIZED
 if path.get_extension().to_lower()=="png": error=image.load_png_from_buffer(bytes)
 elif path.get_extension().to_lower() in ["jpg","jpeg"]: error=image.load_jpg_from_buffer(bytes)
 if error!=OK:
  message="图片无法解码，请选择PNG或JPEG截图。";refresh();return
 add_image(image)

func add_image(image: Image) -> void:
 if busy or draft.images.size()>=MAX_IMAGES: return
 if image==null or image.is_empty(): message="未能获取截图，请重试。";refresh();return
 var picture=image.duplicate()
 var scale=minf(1.0,1600.0/maxi(picture.get_width(),picture.get_height()))
 if scale<1: picture.resize(maxi(1,int(picture.get_width()*scale)),maxi(1,int(picture.get_height()*scale)),Image.INTERPOLATE_LANCZOS)
 picture.convert(Image.FORMAT_RGB8)
 var bytes=picture.save_jpg_to_buffer(0.82)
 if bytes.size()>MAX_IMAGE_BYTES: message="压缩后的截图仍超过2MB，请裁剪后添加。";refresh();return
 draft.images.append({"data":Marshalls.raw_to_base64(bytes)})
 changed();save_draft();refresh()

func review() -> void:
 _capture_context()
 message=validation()
 if message.is_empty(): confirming=true
 refresh()

func submit() -> void:
 if busy or not confirming: return
 message=validation()
 if not message.is_empty(): refresh();return
 var url=endpoint()
 if not url.begins_with("https://") or url.contains("@"):
  message="反馈服务尚未开通，草稿已保留。";save_draft();refresh();return
 if draft.id.is_empty(): draft.id=Crypto.new().generate_random_bytes(16).hex_encode()
 save_draft();busy=true;response_redirects=0;checking_receipt=false;message="正在提交，请稍候…";refresh()
 # docs/spec/feedback-deployment.md「服务版本门控」: never attach the save before the
 # same endpoint answered the GET schema probe; the answer is cached per draft identity.
 if draft.include_save and not save_probed and not save_attachment.is_empty():
  probing=true
  if _send_request(url,HTTPClient.METHOD_GET)==OK: return
  # The probe never left the process: degrade to the old format and keep submitting.
  probing=false;save_probed=true;save_declined=true
 _send_report(url)

func _send_report(url: String) -> void:
 message="正在提交，请稍候…";refresh()
 var error=_send_request(url,HTTPClient.METHOD_POST,JSON.stringify(payload()))
 if error!=OK: busy=false;message="无法连接反馈服务，草稿已保留，请稍后重试。";refresh()

func _send_request(url: String, method: int, body: String="") -> int:
 if transport.is_valid(): return transport.call(url,method,body)
 var headers=PackedStringArray(["Content-Type: application/json"]) if method==HTTPClient.METHOD_POST else PackedStringArray()
 return request.request(url,headers,method,body)

func _completed(result: int, status: int, headers: PackedStringArray, body: PackedByteArray) -> void:
 if not busy: return
 # The schema probe answered: only a well-formed version document with schema>=2 may carry
 # the save; anything else (non-200, timeout, bad JSON) degrades without blocking the submit.
 if probing:
  probing=false;save_probed=true
  save_declined=not _service_supports_save(result,status,body)
  _send_report(endpoint())
  return
 # Apps Script receipts are a separate GET; never forward the report to a redirect.
 if result in [HTTPRequest.RESULT_SUCCESS,HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED] and status in [302,303] and response_redirects<4:
  for header in headers:
   if not header.to_lower().begins_with("location:"): continue
   var location=header.substr(9).strip_edges()
   if location.begins_with("https://script.googleusercontent.com/"):
    response_redirects+=1
    if _send_request(location,HTTPClient.METHOD_GET)==OK: return
   break
 var reply=JSON.parse_string(body.get_string_from_utf8()) if result==HTTPRequest.RESULT_SUCCESS and status==200 else null
 # A missing redirect response does not imply the email failed. Query once by ID.
 if reply==null and not checking_receipt and endpoint().begins_with("https://script.google.com/macros/s/"):
  checking_receipt=true;response_redirects=0
  var receipt_url=endpoint()+("&" if endpoint().contains("?") else "?")+"receipt="+draft.id
  if _send_request(receipt_url,HTTPClient.METHOD_GET)==OK: return
 busy=false
 if reply is Dictionary and reply.get("ok")==true and reply.get("id")==draft.id:
  var id=draft.id;clear_draft();message="提交成功，邮件服务已接受。反馈编号："+id;refresh();return
 var code=reply.get("code","") if reply is Dictionary else ""
 message={"limited":"反馈服务今日额度已用完，请明天重试。","busy":"反馈服务繁忙，请稍后重试。","invalid":"反馈内容未通过检查，请返回修改后重试。"}.get(code,"未确认提交成功，请稍后重试；相同反馈会沿用原编号。")+"草稿已保留。"
 save_draft();refresh()

# The service version document is the only source of the schema level; a missing or
# mismatched service name counts as unsupported, which only drops the attachment.
static func _service_supports_save(result: int, status: int, body: PackedByteArray) -> bool:
 if result!=HTTPRequest.RESULT_SUCCESS or status!=200: return false
 # A parser instance keeps a malformed document a plain "not supported" answer instead of an
 # engine error; the report body is never trusted from this response.
 var parser=JSON.new()
 if parser.parse(body.get_string_from_utf8())!=OK or not parser.data is Dictionary: return false
 var reply=parser.data
 if reply.get("service","")!="spire-feedback": return false
 var schema=reply.get("schema",0)
 return (schema is int or schema is float) and schema>=2

func clear_draft() -> void:
 if busy: return
 draft={"id":"","kind":"bug","title":"","description":"","include_logs":false,"include_save":true,"context":{},"logs":"","images":[]}
 save_attachment={};save_reason="";save_captured=false;save_probed=false;save_declined=false
 confirming=false;message="";save_draft();refresh()
