extends Control

# Transient, bounded display rows. The authoritative history remains in View.logs.
# Only committed deltas enter here; repainting never enqueues history again.
const MAX_ROWS=6
const ROW_GAP=2.0
const MIN_ROW_HEIGHT=32.0
const SLIDE_TIME=0.18
const INTERVAL=0.22
const HOLD=4.5
const FADE=0.7
var ui
var pending: Array=[]
var rows: Array=[]
var released: Dictionary={}
var seen_end=-1
var encounter=-1
var clock=0.0
var next_at=0.0
var entry: Button
var phase=""
var scene_hidden=false
const ACTIVE_PHASES=["battle","prepare","reward"]
const FINAL_PHASES=["captured","prison_end"]

func _ready() -> void:
 name="BattleFeed";z_index=180
 position=Vector2(1280,148);size=Vector2(304,256)
 mouse_filter=Control.MOUSE_FILTER_IGNORE;clip_contents=true
 entry=ui._button("≡",func():ui._open_drawer("show_log"),ui.GOLD)
 entry.name="OpenBattleLog";entry.tooltip_text=ui.localization.display("行动日志")
 entry.position=Vector2(264,0);entry.size=Vector2(40,36)
 add_child(entry)
 set_process(false)

func sync(view: Dictionary, hidden: bool) -> void:
 phase=view.phase;scene_hidden=hidden
 if encounter!=view.encounter or (seen_end>=0 and view.logs.size()<seen_end):
  clear();encounter=view.encounter
 if phase not in ACTIVE_PHASES and phase not in FINAL_PHASES:
  clear();hide();return
 visible=not hidden and (phase in ACTIVE_PHASES or not pending.is_empty() or not rows.is_empty())
 entry.disabled=is_instance_valid(ui.enemy_feedback)

func clear() -> void:
 pending.clear();released.clear();seen_end=-1;clock=0;next_at=0
 for row in rows:
  remove_child(row.node);row.node.queue_free()
 rows.clear()
 if is_instance_valid(entry): entry.text="≡"
 set_process(false)

func enqueue(before: Dictionary, after: Dictionary) -> void:
 var start=maxi(before.logs.size(),seen_end)
 seen_end=after.logs.size()
 for i in range(start,after.logs.size()):
  var log=after.logs[i]
  var action=log.data.get("enemy_action",{})
  # Raw calculation formulas stay in the detailed history, not the live strip.
  if log.kind=="mechanical" and action.is_empty(): continue
  var text=ui.game.ActionCopy.result(log).strip_edges()
  if text=="": continue
  var key=ui.CombatFeedback.enemy_key(action)
  var installed=String(log.data.get("installed_name",""))
  if installed!="" and key!="" and not pending.is_empty():
   var last=pending.back()
   if last.key==key and last.last_id==i-1 and not last.items.is_empty():
    last.items.append(installed);last.last_id=i
    continue
  var icon="◆" if not action.is_empty() else ("✦" if log.data.has("player_action") or log.data.has("round_start") else "·")
  pending.append({"id":i,"last_id":i,"text":text,"key":key,"icon":icon,"enemy":not action.is_empty(),"actor":action.get("actor",""),"items":[installed] if installed!="" and key!="" else [],"ritual":log.data.get("ritual",{}),"round_start":log.data.get("round_start",{})})
 set_process(true)
 visible=not scene_hidden
 _pump()

func release_step(key: String) -> void:
 released[key]=true
 _pump()

func release_remaining() -> void:
 for event in pending:
  if event.key!="": released[event.key]=true
 entry.disabled=false
 _pump()

func _pump() -> void:
 if pending.is_empty() or clock<next_at: return
 var event=pending[0]
 if event.key!="" and not released.has(event.key): return
 pending.pop_front()
 _append(event)
 next_at=clock+INTERVAL

func _display_text(event: Dictionary, label: Label) -> String:
 if event.items.size()>1:
  var heading=ui._text("ui.feed.installed","{actor}施加了 {count} 件拘束具",{"actor":ui.localization.display(event.actor),"count":event.items.size()})
  var lines=PackedStringArray()
  var line=""
  var separator=ui._text("ui.feed.join","、")
  var font=label.get_theme_font("font")
  for item in event.items:
   var item_name=ui.localization.display(item)
   var joined=line+separator+item_name if line!="" else item_name
   if line!="" and font.get_string_size(joined,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x>label.size.x:
    lines.append(line);line=item_name
   else: line=joined
  lines.append(line)
  return heading+"\n"+"\n".join(lines)
 if not event.ritual.is_empty():
  return ui._text("ui.feed.ritual","仪式生效：施加数量 +{gain}（累计 +{bonus}）",{"gain":event.ritual.gain,"bonus":event.ritual.bonus})
 if event.round_start.get("visible_intents",false):
  return ui._text("ui.feed.round","第 {round} 回合 · {order}",{"round":event.round_start.round,"order":ui.localization.display(event.round_start.order_text)})
 return ui.localization.log_display(event.text)

func _append(event: Dictionary) -> void:
 var panel=Panel.new();panel.name="BattleFeedRow_"+str(event.id)
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.size.x=size.x
 panel.set_meta("log_id",event.id)
 var style=StyleBoxFlat.new();style.bg_color=Color(0.035,0.06,0.085,0.78)
 style.border_color=Color("bc9663") if event.enemy else Color("558a8f")
 style.border_width_right=2;style.set_corner_radius_all(3)
 panel.add_theme_stylebox_override("panel",style);add_child(panel)
 var icon=ui._label(event.icon,20,ui.GOLD if event.enemy else ui.CYAN)
 icon.position=Vector2(8,3);icon.size=Vector2(26,28);panel.add_child(icon)
 var label=ui._label("",14,ui.TEXT)
 label.name="BattleFeedText";label.position=Vector2(38,4);label.size.x=size.x-48
 panel.add_child(label);label.text=_display_text(event,label);panel.set_meta("full_text",label.text)
 var available=size.y-entry.size.y-4
 var spacing=label.get_theme_constant("line_spacing")
 label.max_lines_visible=maxi(1,floori((available-8+spacing)/(label.get_line_height()+spacing)))
 label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 label.size.y=label.get_minimum_size().y
 panel.size.y=maxf(MIN_ROW_HEIGHT,label.size.y+8)
 label.position.y=(panel.size.y-label.size.y)/2
 rows.append({"node":panel,"label":label,"born":clock,"top":0.0})
 entry.text=event.icon
 _layout_rows()

func _layout_rows() -> void:
 var bottom=size.y
 for i in range(rows.size()-1,-1,-1):
  var panel=rows[i].node
  var top=bottom-panel.size.y
  if i<rows.size()-MAX_ROWS or top<entry.size.y+4:
   for dropped in rows.slice(0,i+1):
    remove_child(dropped.node);dropped.node.queue_free()
   rows=rows.slice(i+1);break
  rows[i].top=top;bottom=top-ROW_GAP
 _position_rows()

func _position_rows() -> void:
 if rows.is_empty(): return
 # The stack slides as one unit so wrapped rows never cross during entry.
 var newest=rows.back()
 var remaining=clampf(1.0-(clock-newest.born)/SLIDE_TIME,0.0,1.0)
 var shift=0.0 if ui.display_settings.reduced_card_motion else (newest.node.size.y+ROW_GAP)*remaining*remaining
 for row in rows: row.node.position.y=row.top+shift

func _process(delta: float) -> void:
 clock+=delta
 _pump()
 var changed=false
 for i in range(rows.size()-1,-1,-1):
  var row=rows[i];var age=clock-row.born
  row.node.modulate.a=clampf((HOLD+FADE-age)/FADE,0,1)
  row.label.modulate.a=1.0 if ui.display_settings.reduced_card_motion else clampf((age-0.08)/0.18,0,1)
  if age>=HOLD+FADE:
   remove_child(row.node);row.node.queue_free();rows.remove_at(i);changed=true
 if changed: _layout_rows()
 else: _position_rows()
 if pending.is_empty() and rows.is_empty():
  set_process(false)
  if phase in FINAL_PHASES: hide()
