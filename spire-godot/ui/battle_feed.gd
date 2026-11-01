extends Control

# Transient, bounded display rows. The authoritative history remains in View.logs.
# Only committed deltas enter here; repainting never enqueues history again.
const MAX_ROWS=6
const ROW_HEIGHT=36.0
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
 mouse_filter=Control.MOUSE_FILTER_IGNORE
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
  var icon="◆" if not action.is_empty() else ("✦" if log.data.has("player_action") else "·")
  pending.append({"id":i,"text":text,"key":key,"icon":icon,"enemy":not action.is_empty()})
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

func _append(event: Dictionary) -> void:
 if rows.size()==MAX_ROWS:
  var oldest=rows.pop_front();remove_child(oldest.node);oldest.node.queue_free()
 var panel=Panel.new();panel.name="BattleFeedRow_"+str(event.id)
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.size=Vector2(size.x,ROW_HEIGHT-2)
 panel.set_meta("log_id",event.id);panel.set_meta("full_text",event.text)
 var style=StyleBoxFlat.new();style.bg_color=Color(0.035,0.06,0.085,0.78)
 style.border_color=Color("bc9663") if event.enemy else Color("558a8f")
 style.border_width_right=2;style.set_corner_radius_all(3)
 panel.add_theme_stylebox_override("panel",style);add_child(panel)
 var icon=ui._label(event.icon,20,ui.GOLD if event.enemy else ui.CYAN)
 icon.position=Vector2(8,3);icon.size=Vector2(26,28);panel.add_child(icon)
 var label=ui._label(event.text.replace("\n"," · "),14,ui.TEXT)
 label.name="BattleFeedText";label.position=Vector2(38,1);label.size=Vector2(size.x-48,32)
 label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.max_lines_visible=2
 label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 panel.add_child(label)
 rows.append({"node":panel,"label":label,"born":clock})
 entry.text=event.icon
 _animate_rows()

func _animate_rows() -> void:
 for i in range(rows.size()):
  var row=rows[i]
  var y=size.y-(rows.size()-i)*ROW_HEIGHT
  if not row.has("placed"):
   row.node.position=Vector2(0,y+10);row.placed=true
  if row.has("slide") and row.slide.is_valid(): row.slide.kill()
  if ui.display_settings.reduced_card_motion: row.node.position.y=y
  else:
   row.slide=row.node.create_tween()
   row.slide.tween_property(row.node,"position:y",y,0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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
 if changed: _animate_rows()
 if pending.is_empty() and rows.is_empty():
  set_process(false)
  if phase in FINAL_PHASES: hide()
