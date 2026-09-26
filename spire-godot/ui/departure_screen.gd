extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

static func build(ui) -> void:
 var panel=ui.view.reward_panel
 var root=Control.new();root.name="BattleRewards";root.z_index=80
 ui._place(root,Rect2(0,78,1600,822))
 preload("res://ui/reward_backdrop.gd").build(ui,root,0.94)
 var crest=TextureRect.new();crest.texture=preload("res://assets/ui/crest.svg");crest.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 ui._place(crest,Rect2(773,34,54,54),root);crest.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var title=ui._label(panel.title,36,ui.GOLD);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ui._place(title,Rect2(250,104,1100,56),root)
 var subtitle=ui._label(panel.destination,19,ui.TEXT if panel.stage=="done" else ui.MUTED)
 subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 ui._place(subtitle,Rect2(270,184,1060,260 if panel.stage=="done" else 68),root)
 if panel.stage=="card":
  var scroll=ScrollContainer.new();scroll.name="DepartureCards";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
  ui._place(scroll,Rect2(185,268,1230,516),root)
  var contents=Control.new();contents.custom_minimum_size=Vector2(1200,ceilf(panel.entries.size()/5.0)*352)
  scroll.add_child(contents)
  for i in range(panel.entries.size()):
   var entry=panel.entries[i];var choice=Queries.fact_by_key(ui.view,entry.action_key)
   var card=preload("res://data/encyclopedia.gd").card(entry.type)
   card.uid=entry.uid if entry.uid!="" else "departure_"+entry.type
   var button=ui._card(card,Rect2((i%5)*242,floori(i/5.0)*352,224,330),func():ui.command_router.emit(String(choice.payload.get("kind","")),choice),0,contents,false,true)
   button.disabled=not entry.valid;button.name="DepartureCard_"+str(i)
   ui.candidate_buttons[choice.key]=button
  return
 var index=0
 var option_count=panel.entries.filter(func(entry):return entry.op=="choose").size()
 var start_x=(1600-(mini(option_count,4)*352-28))/2.0
 for entry in panel.entries:
  var choice=Queries.fact_by_key(ui.view,entry.action_key)
  if entry.op in ["skip","finish"]:
   var button=ui._button(entry.label,func():ui.command_router.emit(String(choice.payload.get("kind","")),choice),ui.GOLD)
   button.name="DepartureContinue";ui._place(button,Rect2(650,750 if option_count==5 else 692,300,54),root)
   ui.candidate_buttons[choice.key]=button
   continue
  var color=ui.GOLD if index in [2,3] else ui.CYAN
  var button=ui._button("",func():ui.command_router.emit(String(choice.payload.get("kind","")),choice),color);button.disabled=not entry.valid
  button.name="DepartureOption_"+str(index)
  if index==4:
   ui._place(button,Rect2(start_x+3*352,636,324,98),root)
   var extra_title=ui._label("05 · "+entry.label,20,ui.GOLD)
   ui._place(extra_title,Rect2(16,8,292,28),button)
   var extra_detail=ui._label(entry.detail if entry.valid else entry.reason,17,ui.TEXT if entry.valid else ui.RED)
   extra_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   ui._place(extra_detail,Rect2(16,38,292,54),button)
   for child in button.get_children(): ui._ignore_mouse(child)
   ui.candidate_buttons[choice.key]=button
   index+=1
   continue
  ui._place(button,Rect2(start_x+index*352,286,324,338),root)
  var number=ui._label("0%d" % (index+1),40,Color(color,0.40))
  ui._place(number,Rect2(24,22,100,54),button)
  var category=ui._label(entry.label,25,color)
  ui._place(category,Rect2(24,90,276,40),button)
  var detail=ui._label(entry.detail if entry.reason=="" else entry.reason,21,ui.TEXT if entry.valid else ui.RED)
  detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  ui._place(detail,Rect2(24,148,276,136),button)
  var select=ui._label("选择  ›",17,color);select.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
  ui._place(select,Rect2(24,293,276,25),button)
  for child in button.get_children(): ui._ignore_mouse(child)
  ui.candidate_buttons[choice.key]=button
  index+=1
