extends RefCounted

const ACTIONS={
 "card_1":["手牌1",KEY_1],"card_2":["手牌2",KEY_2],"card_3":["手牌3",KEY_3],"card_4":["手牌4",KEY_4],"card_5":["手牌5",KEY_5],
 "card_6":["手牌6",KEY_6],"card_7":["手牌7",KEY_7],"card_8":["手牌8",KEY_8],"card_9":["手牌9",KEY_9],"card_10":["手牌10",KEY_0],
 "flip":["翻面／切换",KEY_R],"confirm":["使用／确认目标",KEY_SPACE,KEY_ENTER],"next":["下一个目标",KEY_TAB],"previous":["上一个目标",KEY_TAB|KEY_MASK_SHIFT],
 "end":["结束回合",KEY_E],"strike":["肘击",KEY_Z],"heavy":["近身短打",KEY_V],"kick":["腿部动作",KEY_X],"fireball":["火球术",KEY_F],
 "draw":["抽牌堆",KEY_A],"discard":["弃牌堆",KEY_D],"deck":["完整卡组",KEY_C],"powers":["能力区",KEY_P],"items":["道具",KEY_I],
 "body":["身体与拘束具",KEY_B],"status":["角色状态",KEY_S],"map":["地图",KEY_M],"log":["行动日志",KEY_L]}
var bindings={}
var hold_end=false
var path="user://key-bindings.cfg"
var persist=true
var error=""

func _init() -> void:
 defaults()

func defaults() -> void:
 bindings.clear()
 for id in ACTIONS: bindings[id]=ACTIONS[id].slice(1)
 hold_end=false

func initialize(enabled: bool) -> void:
 persist=enabled
 if not persist: return
 var config=ConfigFile.new()
 if config.load(path)!=OK: return
 var saved=config.get_value("keyboard","bindings",{})
 if not saved is Dictionary or saved.keys().size()!=ACTIONS.size(): return
 var used=[]
 for id in ACTIONS:
  if not saved.has(id) or not saved[id] is Array or saved[id].size()!=ACTIONS[id].size()-1: return
  for key in saved[id]:
   if not key is int or key<=0 or (key & KEY_CODE_MASK)==KEY_ESCAPE or key in used: return
   used.append(key)
 bindings=saved.duplicate(true)
 hold_end=config.get_value("keyboard","hold_end",false)==true
 if bindings.heavy==[KEY_X] and bindings.kick==[KEY_V]:
  bindings.heavy=[KEY_V];bindings.kick=[KEY_X];save()

func assign(id: String, slot: int, key: int) -> bool:
 error=""
 if (key & KEY_CODE_MASK)==KEY_ESCAPE:
  error="Esc用于取消和返回。";return false
 for other in bindings:
  for index in range(bindings[other].size()):
   if bindings[other][index]==key and (other!=id or index!=slot):
    error="%s已用于「%s」。" % [OS.get_keycode_string(key),ACTIONS[other][0]];return false
 bindings[id][slot]=key;save();return true

func save() -> void:
 error=""
 if not persist: return
 var config=ConfigFile.new();config.set_value("keyboard","bindings",bindings);config.set_value("keyboard","hold_end",hold_end)
 if config.save(path)!=OK: error="键位保存失败，请重试。"

func match_key(key: int) -> String:
 for id in bindings:
  if key in bindings[id]: return id
 return ""

func caption(id: String) -> String:
 return " / ".join(bindings[id].map(func(key):return OS.get_keycode_string(key)))

func build(host, content: VBoxContainer, input) -> void:
 var note=host._label("Esc：取消选择／关闭窗口／菜单（固定）",14,host.MUTED);content.add_child(note)
 var hold=CheckBox.new();hold.name="HoldEndTurn";hold.text="长按0.5秒结束回合";hold.button_pressed=hold_end;content.add_child(hold)
 hold.toggled.connect(func(value):hold_end=value;save())
 var message=host._label(input.binding_message if input.binding_message!="" else error,15,host.RED);message.name="KeyBindingMessage";content.add_child(message)
 var list=host._scroll(content)
 var grid=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",24);list.add_child(grid)
 for id in ACTIONS:
  var row=HBoxContainer.new();row.custom_minimum_size.x=350;grid.add_child(row)
  var label=host._label(ACTIONS[id][0],15);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label)
  for slot in range(bindings[id].size()):
   var text="按键…" if input.capture_id==id and input.capture_slot==slot else OS.get_keycode_string(bindings[id][slot])
   var button=host._button(text,func():input.capture_id=id;input.capture_slot=slot;input.binding_message="请按新按键，Esc取消。";host._refresh_drawers(),host.CYAN)
   button.name="KeyBinding_"+id+"_"+str(slot);button.custom_minimum_size=Vector2(90,34);row.add_child(button)
 var reset=host._button("恢复默认键位",func():defaults();save();input.capture_id="";input.binding_message="";host._refresh_drawers();input.refresh_hints.call_deferred())
 reset.name="ResetKeyBindings";content.add_child(reset)
