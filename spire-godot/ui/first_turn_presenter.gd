extends Control

# Owns pacing and presentation only. Every click commits the original candidate/version.
const Dialogue=preload("res://data/doubao_dialogue.gd")
var host
var busy=false
var generation=0
var session
var turn_key=""
var intro_key=""
var banner: Label
var bubble: PanelContainer
var speech: Label
var caption: Label
var cursor=Vector2(480,150)
var cursor_visible=false
var clicking=false
var tail=Vector2.ZERO
var expires=0
var attacks=0
var cards=0
var deposited=false
var initial_hand=[]
var variant=0
var outcome_delay=0.0
var empty_said=false
var voice: AudioStreamPlayer
var read_until=0
var speech_phase=""

func _ready() -> void:
 name="FirstTurnPresenter";z_index=4000;size=Vector2(1600,900)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 voice=AudioStreamPlayer.new();voice.name="DoubaoVoice";voice.max_polyphony=1;add_child(voice)
 banner=host._label("",23,host.CYAN);banner.name="FirstTurnControlBanner"
 banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 host._place(banner,Rect2(560,116,950,38),self)
 bubble=PanelContainer.new();bubble.name="DoubaoSpeech"
 bubble.add_theme_stylebox_override("panel",host._style(Color(0.078,0.149,0.2,0.75),host.CYAN,10))
 bubble.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",8);bubble.add_child(column)
 caption=host._label("豆包",17,host.GOLD);column.add_child(caption)
 speech=host._label("",20);speech.name="DoubaoSpeechText";speech.custom_minimum_size.x=440;column.add_child(speech)
 add_child(bubble);host._ignore_mouse(bubble);bubble.hide();banner.hide()

func sync() -> void:
 configure_voice()
 if session!=host.game or host.show_home:
  generation+=1;busy=false;session=host.game;turn_key="";intro_key=""
  _stop_voice();read_until=0;speech_phase=""
  bubble.hide();banner.hide();cursor_visible=false
  mouse_filter=Control.MOUSE_FILTER_IGNORE;queue_redraw();return
 if speech_phase!="" and speech_phase!=host.view.phase:
  _stop_voice();bubble.hide();speech_phase=""
 var control=host.view.get("first_turn_control",{})
 var locked=control.get("locked",false)
 mouse_filter=Control.MOUSE_FILTER_STOP if locked else Control.MOUSE_FILTER_IGNORE
 if not control.is_empty():
  var key=control.key+":"+str(locked)
  if turn_key!=key:
   _stop_voice()
   turn_key=key;attacks=0;cards=0;deposited=false;empty_said=false
   initial_hand=host.view.hand.map(func(card):return card.uid+":"+str(card.draw_serial))
   variant=posmod(hash(str(host.view.seed)+key),2)
   expires=Time.get_ticks_msec()+5000
  banner.text=host.localization.display(control.name)
  banner.visible=locked or Time.get_ticks_msec()<expires
 else: banner.hide()
 if not locked:
  cursor_visible=false
  if Time.get_ticks_msec()>=expires: bubble.hide()
 if bubble.visible: _anchor()
 host.move_child(self,-1)
 queue_redraw()

func _anchor() -> void:
 var relic=host.find_child("RelicShortcut_doubao",true,false)
 if not is_instance_valid(relic): bubble.hide();return
 var bounds=get_global_transform().affine_inverse()*relic.get_global_rect()
 tail=Vector2(bounds.get_center().x,bounds.end.y+2)
 bubble.position=Vector2(clampf(tail.x-24,10,1590-bubble.size.x),tail.y+14)

func _say(cue: String, action: String="") -> void:
 var entry=Dialogue.entry(cue,variant)
 caption.text=host.localization.display("豆包")+(" · "+host.localization.display(action) if action!="" else "")
 speech.text=host.localization.display(entry.text)
 speech_phase=host.view.phase
 read_until=Time.get_ticks_msec()+ceili(clampf(speech.text.length()*0.065,2.4,5.0)*1000)
 _stop_voice();configure_voice()
 if host.display_settings.doubao_voice_enabled:
  voice.stream=load(entry.voice)
  voice.play()
 bubble.size=Vector2(472,0);bubble.show();_anchor()
 bubble.reset_size.call_deferred()
 var tween=create_tween()
 bubble.modulate.a=0
 tween.tween_property(bubble,"modulate:a",1.0,0.18)
 expires=Time.get_ticks_msec()+ceili(maxf(6.0,_reading_time()+0.6)*1000)

func configure_voice() -> void:
 if not is_instance_valid(voice): return
 voice.volume_linear=host.display_settings.doubao_voice_volume
 if not host.display_settings.doubao_voice_enabled: _stop_voice()

func _stop_voice() -> void:
 voice.stop();voice.stream=null

func _reading_time() -> float:
 var remaining=maxf(0.0,float(read_until-Time.get_ticks_msec())/1000.0)
 if voice.playing and voice.stream!=null:
  remaining=maxf(remaining,voice.stream.get_length()-voice.get_playback_position()+0.15)
 return remaining

func _current(token: int, version: int) -> bool:
 return token==generation and session==host.game and not host.show_home and host.view.version==version and host._takeover_locked()

func _pause(seconds: float) -> void:
 await get_tree().create_timer(seconds).timeout

func _center(control: Control) -> Vector2:
 return get_global_transform().affine_inverse()*(control.get_global_transform()*(control.size/2))

func _reveal(control: Control) -> void:
 var node=control.get_parent()
 while node!=null:
  if node is ScrollContainer: node.ensure_control_visible(control)
  node=node.get_parent()

func _point(control: Control) -> void:
 if not is_instance_valid(control): return
 _reveal(control)
 await get_tree().process_frame
 if not is_instance_valid(control): return
 var dest=_center(control)
 cursor_visible=true
 var tween=create_tween()
 tween.tween_property(self,"cursor",dest,0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 await tween.finished
 clicking=true;queue_redraw();await _pause(0.25);clicking=false

func _cue(c: Dictionary) -> String:
 var p=c.payload
 match p.kind:
  "posture": return p.dest
  "attack": return "attack_again" if attacks>0 else "attack"
  "flask": return "withdraw_again" if p.op=="withdraw" and deposited else p.op
  "card","prison":
   var matches=host.view.hand.filter(func(card):return card.uid==p.get("uid",""))
   if not matches.is_empty() and matches[0].uid+":"+str(matches[0].draw_serial) not in initial_hand: return "draw"
   return "card_first" if cards==0 else "card"
 return p.kind

func advance() -> void:
 sync()
 if busy or not host._takeover_locked() or is_instance_valid(host.enemy_feedback): return
 var control=host.view.first_turn_control
 if control.candidate.is_empty(): return
 busy=true
 var token=generation;var version=host.view.version;var c=control.candidate
 if intro_key!=turn_key:
  intro_key=turn_key
  host._close_drawers();host._clear_player_picker();host.selected_card="";host.quick_release_open=false
  if is_instance_valid(host.keyboard_input): host.keyboard_input.clear()
  if is_instance_valid(host.touch_input): host.touch_input.cancel();host.touch_input.dismiss_popup()
  host.render(host.view)
  var relic=host.find_child("RelicShortcut_doubao",true,false)
  if is_instance_valid(relic): _reveal(relic);cursor=_center(relic)
  _say("start");await _pause(_reading_time())
 if _current(token,version): await _step(c,token,version)
 if token==generation: busy=false

# 步骤按钮定位：全部显示点都按显示键（candidate_buttons 的唯一注册键面）取用。
static func _candidate_button(host, c: Dictionary) -> Control:
 return host.candidate_buttons.get(String(c.get("key","")))

func _step(c: Dictionary, token: int, version: int) -> void:
 var p=c.payload
 # Choose the displayed face/form before locating the same formal command on screen.
 if p.has("uid") and p.has("free"): host.card_faces[p.uid]=p.free
 if p.kind=="attack":
  host.attack_forms[p.type]=p.form
  if p.get("enemy","")!="": host.selected_enemy=p.enemy
 host.render(host.view)
 await get_tree().process_frame
 if not _current(token,version): return
 if host.view.energy<=0 and p.kind in ["flask","end"] and cards>0 and not empty_said:
  empty_said=true;_say("empty");await _pause(_reading_time())
  if not _current(token,version): return
 _say(_cue(c),c.label)
 var source=host.card_buttons.get(p.get("uid","")) if p.kind in ["card","prison"] else _candidate_button(host,c)
 if is_instance_valid(source): await _point(source)
 if not _current(token,version): return
 var target: Control
 if p.get("enemy","")!="": target=host.actor_targets.get(p.enemy)
 elif p.get("hand_uid","")!="": target=host.card_buttons.get(p.hand_uid)
 elif p.get("target","")!="" and p.get("slot","")!="":
  var data={"card_uid":p.uid,"free":p.get("free",false),"version":version} if p.has("uid") else {"fact_keys":[String(c.get("key",""))],"version":version}
  var region=host._body_at(p.slot)
  var groups=host.view.body_regions.filter(func(body):return body.id==region.id or body.members.any(func(member):return member.id==region.id))
  if not groups.is_empty() and groups[0].id not in host.expanded_body_regions:
   host.expanded_body_regions.append(groups[0].id);host.render(host.view)
   await get_tree().process_frame
  host._show_drop_targets(region.id,data,true)
  await get_tree().process_frame
  target=host.drop_targets.get(String(c.get("key","")))
 elif p.get("target","")=="guard_bind": target=host.actor_targets.get("guard_bind")
 elif p.kind in ["card","prison"]: target=host.actor_targets.get("hero")
 if is_instance_valid(target) and target!=source: await _point(target)
 await _pause(_reading_time())
 if not _current(token,version): return
 outcome_delay=0.7
 host.command_router.emit(String(c.payload.get("kind","")),c,version,true)
 if p.kind=="attack": attacks+=1
 if p.kind in ["card","prison"]: cards+=1
 if p.kind=="flask" and p.op=="deposit": deposited=true
 await _pause(outcome_delay)

func outcome(result: Dictionary, before: Dictionary, after: Dictionary, c: Dictionary) -> void:
 var cue=""
 if not result.ok: cue="interrupted"
 elif after.phase=="reward" and before.phase=="battle": cue="victory"
 elif result.get("spell_failed",false): cue="failed"
 elif after.pressure.overloaded and not before.pressure.overloaded: cue="interrupted"
 # The hand-back line was already spoken before committing this command.
 if cue!="": _say(cue);outcome_delay=_reading_time()
 expires=maxi(expires,Time.get_ticks_msec()+6000)

func _draw() -> void:
 if bubble.visible:
  draw_colored_polygon(PackedVector2Array([tail,Vector2(bubble.position.x+18,bubble.position.y+2),Vector2(bubble.position.x+36,bubble.position.y+2)]),Color("83c9c6"))
 if not cursor_visible: return
 if clicking: draw_arc(cursor,20,0,TAU,32,Color("ffdc91"),3,true)
 var points=PackedVector2Array([Vector2.ZERO,Vector2(0,30),Vector2(8,23),Vector2(14,35),Vector2(20,32),Vector2(14,21),Vector2(25,21)])
 for i in range(points.size()): points[i]+=cursor
 draw_colored_polygon(points,Color("fff4d8"))
 points.append(points[0]);draw_polyline(points,Color("203343"),2,true)
