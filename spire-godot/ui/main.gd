extends Control

const Game=preload("res://core/game.gd")
const ShopScreen=preload("res://ui/shop_screen.gd")
const Arena=preload("res://ui/arena.gd")
const EquipmentPortrait=preload("res://ui/equipment_portrait.gd")
const OVERLOAD_COLOR=Color("ed82b9")
const CardFace=preload("res://ui/elements/card_face.gd")
const CardFaceScene=preload("res://ui/elements/card_face.tscn")
const StatusIcon=preload("res://ui/status_icon.gd")
const RouteMap=preload("res://ui/route_map.gd")
const DropTarget=preload("res://ui/elements/drop_target.gd")
const DropTargetScene=preload("res://ui/elements/drop_target.tscn")
const TermPopupScene=preload("res://ui/elements/term_popup.tscn")
const DrawerShellScene=preload("res://ui/elements/drawer_shell.tscn")
const BasicActionTileScene=preload("res://ui/elements/basic_action_tile.tscn")
const EnemyActorScene=preload("res://ui/elements/enemy_actor.tscn")
const EquipmentTileScene=preload("res://ui/elements/equipment_tile.tscn")
const EquipmentDropCardScene=preload("res://ui/elements/equipment_drop_card.tscn")
const PrisonSiteScene=preload("res://ui/elements/prison_site.tscn")
const ItemRowScene=preload("res://ui/elements/item_row.tscn")
const PanelFrameScene=preload("res://ui/shell/panel_frame.tscn")
const HeaderScene=preload("res://ui/shell/header.tscn")
const BottomControlsScene=preload("res://ui/shell/bottom_controls.tscn")
const BodyDrawerScene=preload("res://ui/shell/body_drawer.tscn")
const ActionSidebarScene=preload("res://ui/shell/action_sidebar.tscn")
const HomeScene=preload("res://ui/screens/home.tscn")
const DemoExitScene=preload("res://ui/screens/demo_exit.tscn")
const ChainScene=preload("res://ui/screens/chain.tscn")
const CaptureScene=preload("res://ui/screens/capture.tscn")
const InspectionScene=preload("res://ui/screens/inspection.tscn")
const PracticeScene=preload("res://ui/screens/practice.tscn")
const RouteScene=preload("res://ui/screens/route.tscn")
const BattleScene=preload("res://ui/screens/battle.tscn")
const ShopScene=preload("res://ui/screens/shop.tscn")
const EventScene=preload("res://ui/screens/event.tscn")
const RewardScene=preload("res://ui/screens/reward.tscn")
const DragTargets=preload("res://ui/drag_targets.gd")
const ActionIndex=preload("res://ui/action_index.gd")
const Backdrop=preload("res://ui/dungeon_backdrop.gd")
const Palette=preload("res://ui/visual_theme.gd")
const CombatFeedback=preload("res://ui/combat_feedback.gd")
const SaveStore=preload("res://core/save_store.gd")
var saves=SaveStore.new()
var persistence_enabled=true
var touch_input: Node
var keyboard_input: Node
var options_tab="display"
var card_music
var save_notice=""
var save_failed=false
var save_suspended=false
var show_saves=false
var show_home=true
var session_started=false
var show_options=false
var save_summaries={}
var actions: RefCounted
const GOLD=Palette.GOLD
const CYAN=Palette.CYAN
const TEXT=Palette.TEXT
const MUTED=Palette.MUTED
const RED=Palette.RED
const INK=Palette.INK
const ENEMY_STAGE_LEFT=788.0
const ENEMY_STAGE_WIDTH=780.0
const ENEMY_GROUP_WIDTH=260.0
const SCREENS=["home","battle","chain","reward","route","practice","shop","event","capture","inspection","demo_exit"]

var enemy_feedback: Control
var resource_feedback: Control
var card_motion: Control
var attack_forms: Dictionary={}
var feedback_duration=1.3
var display_settings=preload("res://ui/display_settings.gd").new()
var localization=preload("res://ui/localization.gd").new()

var game_factory=Game
var game=Game.new()
var view: Dictionary
var layout: Control
var backdrop: Control
var header_root: Control
var chrome_index:=0
var screen_layers: Dictionary={}
var screen_parent: Control
var drawer_layer: Control
var drawer_base_candidates={}
var building_drawer=false
var selected_card=""
var selected_slot="wrist"
var selected_enemy=""
var action_log_open=false
var action_log_pinned=false
var action_log_panel: PanelContainer
var action_log_toggle: Button
var selected_candidate=""
var notice=""
var show_route=false
var show_reward_cards=false
var reward_card_row=""
var show_reward_relics=false
var show_body=false
var show_log=false
var term_popup: PanelContainer
var term_anchor: Control
var show_deck=false
var deck_zone="deck"
var show_event_selection=false
var event_selection={}
var event_read_page=""
const EventScreen=preload("res://ui/event_screen.gd")
var candidate_buttons={}
var card_buttons={}
var body_buttons={}
var end_button: Button
var seed_field: LineEdit
var show_settings=false
var show_menu=false
var show_shop_service=false
var shop_service_mode="release"
var shop_payment="self"
var shop_sidebar_open=false
var shop_performance_seen=""
var shop_chatter_rng=RandomNumberGenerator.new()
var shop_last_chatter=""
var surrender_version=-1
var show_encyclopedia=false
var show_tutorial=false
var tutorial_category=""
const DRAWERS=["show_encyclopedia","show_shop_service","show_menu","show_tutorial","show_log","show_deck","show_event_selection","show_items","show_hook","show_pressure","show_settings","show_saves","show_options"]
var seed_text="20260906"
var card_faces={}
var card_draw_serials={}
var drop_panel: PanelContainer
var drop_targets: Dictionary={}
var drag_hover_key=""
var active_drag: Dictionary={}
var drag_hints: Array=[]
var drag_hidden: Array=[]
var actor_targets={}
var player_pick=false
var player_pick_data={}
var player_picker_panel: PanelContainer
var show_items=false
var selected_item=""
var selected_item_slot=""
var item_help=false
var prison_detail=""
var show_hook=false
var show_pressure=false
var status_filter="all"
var selected_status=""
var route_focus=""
var map_drawings: Dictionary={}
var map_current_room=""
var map_scroll_value=-1
var map_overview=false
var map_auto_travel=false
var map_step_pending=false
var travel_log_scroll=-1
var travel_log_count=0
var speech_id=""
var speech_deadline=0
var speech_group: Control

func _process(_delta: float) -> void:
 if speech_deadline>0 and Time.get_ticks_msec()>=speech_deadline: _dismiss_speech()

func _dismiss_speech() -> void:
 speech_deadline=0
 if is_instance_valid(speech_group): speech_group.hide()

func _speech_visible(id: String) -> bool:
 if speech_id!=id:
  speech_id=id
  speech_deadline=Time.get_ticks_msec()+5000
 return speech_deadline>Time.get_ticks_msec()

func _ready() -> void:
 if OS.has_feature("android"): get_tree().quit_on_go_back=false
 touch_input=preload("res://ui/touch_input.gd").new();touch_input.host=self;add_child(touch_input)
 keyboard_input=preload("res://ui/keyboard_input.gd").new();keyboard_input.host=self;add_child(keyboard_input)
 get_window().title=ProjectSettings.get_setting("application/config/name")
 shop_chatter_rng.randomize()
 display_settings.initialize(get_window(),persistence_enabled)
 localization.set_locale(display_settings.locale)
 card_music=preload("res://ui/card_music.gd").new();add_child(card_music)
 card_music.configure(display_settings.card_music_enabled,display_settings.card_music_volume)
 var font=SystemFont.new()
 font.font_names=localization.font_names()
 theme=Palette.controls(font)
 _restore_startup()
 render(view)

func _save_progress(replace_incompatible: bool=false) -> void:
 if not persistence_enabled or save_suspended or not session_started: return
 var result=saves.write_game(game,replace_incompatible)
 save_failed=not result.ok
 if not result.ok and result.get("code","")=="version": save_suspended=true
 save_notice=result.message if result.ok else result.error

func _restore_startup() -> void:
 if not persistence_enabled: return
 _refresh_save_summaries()
 if saves.has_files("tower") and not save_summaries.tower.available and not save_summaries.tower.get("finished",false):
  save_failed=true;save_suspended=true;save_notice=save_summaries.tower.text

func _return_home() -> void:
 map_auto_travel=false
 if is_instance_valid(enemy_feedback): enemy_feedback.finish()
 _close_drawers();_clear_drop_targets();_clear_player_picker();_hide_term()
 show_home=true;notice=""
 if persistence_enabled: _refresh_save_summaries()
 render(view)

func _home_continue() -> void:
 if session_started and view.demo_finished: return
 if session_started:
  _quick_sl()
 else: _continue_save("tower")

func _refresh_save_summaries() -> void:
 for slot in Game.Snapshot.SLOTS: save_summaries[slot]=saves.summary(slot)

func _open_saves() -> void:
 _refresh_save_summaries();_open_drawer("show_saves")

func _close_drawers() -> void:
 for field in DRAWERS: set(field,false)

func _open_drawer(field: String, zone: String="deck") -> void:
 if view.phase=="travel": map_auto_travel=false
 var was_open=bool(get(field)) and (field!="show_deck" or deck_zone==zone)
 if field=="show_deck": deck_zone=zone
 _close_drawers()
 set(field,not was_open)
 _clear_drop_targets();_clear_player_picker()
 _refresh_drawers()

func _drawer_shell(title: String, rect: Rect2, tone: Color=CYAN) -> VBoxContainer:
 # One dismiss surface prevents clicks passing through to underlying actions.
 var shell=_place(DrawerShellScene.instantiate(),Rect2(0,0,1600,900))
 var dismiss=shell.dismiss()
 dismiss.z_index=228
 var shade=StyleBoxFlat.new();shade.bg_color=Color(0.015,0.025,0.04,0.55)
 for state in ["normal","hover","pressed","focus"]: dismiss.add_theme_stylebox_override(state,shade)
 dismiss.pressed.connect(func():_close_drawers();_refresh_drawers())
 var dismiss_rect=Rect2(0,0,1600,900) if show_home or show_deck or show_event_selection else Rect2(376,64,1224,836)
 dismiss.position=dismiss_rect.position;dismiss.size=dismiss_rect.size
 var panel=shell.panel()
 panel.z_index=230;panel.add_theme_stylebox_override("panel",Palette.window_frame())
 panel.position=rect.position;panel.size=rect.size
 var content=shell.content();content.add_theme_constant_override("separation",12)
 var heading=shell.heading();heading.add_theme_constant_override("separation",10)
 var crest=shell.crest()
 crest.texture=preload("res://assets/ui/crest.svg");crest.custom_minimum_size=Vector2(32,32)
 crest.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;crest.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 crest.mouse_filter=Control.MOUSE_FILTER_IGNORE;crest.visible=rect.size.x>=650
 shell.title_label().size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _style_label(shell.title_label(),title,23,tone)
 _style_button(shell.close_button(),_text("ui.common.close","关闭 ×"),func():_close_drawers();_refresh_drawers(),MUTED)
 return content

func _menu_drawer() -> void:
 var content=_drawer_shell("游戏菜单",Rect2(1090,78,474,474))
 var save=_button("存档异常 · 查看" if save_failed else "存档 / 继续",_open_saves,RED if save_failed else CYAN)
 save.name="OpenSaves";content.add_child(save)
 var quick=_button("快速SL" if not view.demo_finished else "快速SL · 本局已结束",_quick_sl,CYAN)
 quick.name="QuickSL";quick.disabled=view.demo_finished
 quick.tooltip_text="回到当前场景开始，恢复初始手牌与资源。";content.add_child(quick)
 var log_button=_button("行动记录",func():_open_drawer("show_log"));log_button.name="OpenLog";content.add_child(log_button)
 var restart_button=_button("重开 / 练习",func():_open_drawer("show_settings"));restart_button.name="OpenRestart";content.add_child(restart_button)
 var options=_button(_text("ui.settings.title","设置"),func():_open_drawer("show_options"));options.name="OpenOptions";content.add_child(options)
 var home=_button("返回主页",_return_home,CYAN);home.name="ReturnHome";content.add_child(home)

func _open_tutorial(category: String="") -> void:
 tutorial_category=category
 _open_drawer("show_tutorial")

func _encyclopedia_drawer() -> void:
 var content=_drawer_shell("图鉴",Rect2(160,78,1280,748),GOLD)
 var book=preload("res://ui/encyclopedia.gd").new()
 content.add_child(book);book.setup(self)

func _tutorial_drawer() -> void:
 var content=_drawer_shell("教程书",Rect2(396,78,1168,748),GOLD)
 var book=preload("res://ui/tutorial_book.gd").new()
 content.add_child(book);book.setup(self,tutorial_category)

func _continue_save(slot: String) -> void:
 var result=saves.read_slot(slot)
 if not result.ok:
  _save_unavailable(result.error);return
 show_saves=false;save_failed=false;save_suspended=false
 save_notice="已恢复场景起点备份。" if result.backup else "已回到当前场景开始。"
 _resume_snapshot(result.snapshot)

func _resume_snapshot(snapshot: Dictionary) -> bool:
 var restored=game.restore_snapshot(snapshot)
 if not restored.ok:
  _save_unavailable(restored.error);return false
 var initial=game.get_view()
 _reset_interface(initial)
 render(initial)
 _animate_cards(initial.hand.map(func(card):return {"kind":"draw","uid":card.uid,"type":card.type}),{})
 return true

func _quick_sl() -> void:
 if view.demo_finished: return
 if _resume_snapshot(game.restart_snapshot()): _save_progress()

func _save_unavailable(message: String) -> void:
 save_notice=message;save_failed=true;save_suspended=true
 _return_home()

func _style(bg: Color=INK, border: Color=GOLD.darkened(0.4), radius: int=8) -> StyleBoxFlat:
 return Palette.surface(bg,border,radius)

func _text(key: String, fallback: String, params: Dictionary={}) -> String:
 return localization.text(key,fallback,params)

func _set_language(language: String) -> void:
 if not display_settings.set_locale(language): return
 localization.set_locale(language)
 var font=SystemFont.new();font.font_names=localization.font_names()
 theme=Palette.controls(font)
 render(view)

func _style_label(l: Label, text: String, fs: int, color: Color) -> Label:
 l.text=text.replace("右键","长按") if OS.has_feature("android") else text
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.add_theme_font_size_override("font_size",fs)
 l.add_theme_color_override("font_color",color)
 l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return l

func _label(text: String, fs: int=16, color: Color=TEXT) -> Label:
 return _style_label(Label.new(),text,fs,color)

func _style_button(b: Button, text: String, fn: Callable, color: Color=GOLD) -> Button:
 b.text=text
 for state in ["normal","hover","pressed","focus","disabled"]:
  b.add_theme_stylebox_override(state,Palette.button_style(state,CYAN if state=="focus" else color))
 b.add_theme_color_override("font_color",TEXT)
 b.add_theme_color_override("font_disabled_color",Color("8c99a3"))
 b.custom_minimum_size.y=36
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 b.pressed.connect(fn)
 return b

func _button(text: String, fn: Callable, color: Color=GOLD, drop_zone: bool=false) -> Button:
 return _style_button(DropTargetScene.instantiate() if drop_zone else Button.new(),text,fn,color)

func _place(node: Control, rect: Rect2, parent: Control=null) -> Control:
 var owner=parent
 if owner==null: owner=drawer_layer if building_drawer else (screen_parent if screen_parent!=null else layout)
 owner.add_child(node)
 node.position=rect.position
 node.size=rect.size
 return node

func _panel(rect: Rect2, parent: Control=null) -> PanelContainer:
 var p=PanelFrameScene.instantiate()
 p.add_theme_stylebox_override("panel",Palette.window_frame())
 return _place(p,rect,parent)

func _scroll(parent: Node) -> VBoxContainer:
 var scroll=ScrollContainer.new()
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 parent.add_child(scroll)
 var box=VBoxContainer.new()
 box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 box.add_theme_constant_override("separation",9)
 scroll.add_child(box)
 return box

func _style_bar(b: ProgressBar, value: float, maximum: float, color: Color) -> ProgressBar:
 b.max_value=maximum
 b.value=value
 b.show_percentage=false
 b.custom_minimum_size.y=8
 var back=StyleBoxFlat.new(); back.bg_color=Color("101c25");back.set_corner_radius_all(3)
 var fill=StyleBoxFlat.new(); fill.bg_color=color
 fill.set_corner_radius_all(3)
 b.add_theme_stylebox_override("background",back)
 b.add_theme_stylebox_override("fill",fill)
 return b

func _bar(value: float, maximum: float, color: Color) -> ProgressBar:
 return _style_bar(ProgressBar.new(),value,maximum,color)

# Single source of truth for which screen owns the frame. The home page is decided by
# show_home before this call; every remaining branch keeps the original priority order.
func current_screen(view: Dictionary) -> String:
 if view.reward_panel.get("layout","")=="relic_bundle": return "reward"
 if view.phase=="captured": return "capture"
 if view.demo_exit: return "demo_exit"
 if view.phase in ["inspection","prison_end"] or (view.phase=="pack" and view.prison.get("active",false)): return "inspection"
 if show_route or view.phase in ["map","travel","cleared","pack"]: return "practice" if view.practice else "route"
 if view.phase in ["treasure","departure"]: return "reward"
 if view.phase=="shop": return "shop"
 if view.phase=="event":
  if view.reward_panel.active and (view.room_event.report=="" or event_read_page==view.room_event.page_id): return "reward"
  return "event"
 if not view.card_chain.is_empty(): return "chain"
 if view.reward_panel.active: return "reward"
 return "battle"

# The frame tree is built once and keeps its draw order: backdrop, header band,
# the eleven screen slots, then the chrome band. A render never rebuilds it, it
# only refreshes the band that owns the current screen.
func _build_layout() -> void:
 layout=Control.new()
 add_child(layout)
 layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 backdrop=Backdrop.new();backdrop.name="MoonlitGallery"
 backdrop.position=Vector2.ZERO;backdrop.size=Vector2(1600,900)
 layout.add_child(backdrop)
 header_root=Control.new();header_root.name="HeaderBand"
 header_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 layout.add_child(header_root)
 header_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _build_screen_layers()
 chrome_index=layout.get_child_count()

# Chrome keeps the pre-persistent-tree shape: direct children of layout, appended
# after the bands, refreshed by index range instead of by a band container.
func _clear_chrome() -> void:
 if not is_instance_valid(layout): return
 for index in range(layout.get_child_count()-1,chrome_index-1,-1):
  var child=layout.get_child(index)
  layout.remove_child(child)
  child.queue_free()

# Detaches immediately instead of only queue_free(), so a node that is being
# replaced can never be hit by find_child during the same frame.
func _reset_layer(host: Node) -> void:
 if host==null: return
 for child in host.get_children():
  host.remove_child(child)
  child.queue_free()

func _build_screen_layers() -> void:
 screen_layers.clear()
 for screen in SCREENS:
  var layer=Control.new();layer.name="Screen_"+screen
  layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
  layout.add_child(layer)
  layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  screen_layers[screen]=layer

func render(snapshot: Dictionary={}) -> void:
 DragTargets.clear(self)
 _hide_term()
 view=game.get_view() if snapshot.is_empty() else snapshot
 if is_instance_valid(card_music): card_music.sync_phase(view.phase,show_home)
 if not view.reward_panel.active or view.battle_rewards.any(func(entry):return entry.category=="card" and entry.claimed): show_reward_cards=false
 if not view.reward_panel.active or view.battle_rewards.any(func(entry):return entry.category=="relic" and entry.claimed): show_reward_relics=false
 if show_event_selection and (view.phase!="event" or event_selection.get("version",-1)!=view.version): show_event_selection=false
 for card in view.hand:
  if card_draw_serials.get(card.uid,-1)!=card.draw_serial:
   card_draw_serials[card.uid]=card.draw_serial
   card_faces[card.uid]=card.draw_free
 actions=ActionIndex.new(view.candidates)
 var alive=view.enemies.filter(func(e):return not e.gone)
 if not alive.is_empty() and not alive.any(func(e):return e.id==selected_enemy): selected_enemy=alive[0].id
 _clear_drawer_layer();drawer_base_candidates.clear()
 candidate_buttons.clear(); card_buttons.clear(); body_buttons.clear()
 actor_targets.clear()
 if not is_instance_valid(layout): _build_layout()
 for name in SCREENS: _reset_layer(screen_layers[name])
 _reset_layer(header_root)
 _clear_chrome()
 if show_home:
  screen_parent=screen_layers["home"]
  var home=HomeScene.instantiate();home.ui=self;home.name="GameHome"
  _place(home,Rect2(0,0,1600,900))
  screen_parent=null
  _refresh_drawers()
  return
 if view.phase=="battle" and not show_route and not display_settings.first_battle_tutorial_seen:
  _close_drawers()
  tutorial_category="basics"
  show_tutorial=true
  display_settings.mark_first_battle_tutorial_seen()
 backdrop.rest=view.phase in ["rest","rest_choice"]
 screen_parent=header_root
 _header()
 screen_parent=screen_layers[current_screen(view)]
 if view.reward_panel.get("layout","")=="relic_bundle": _rewards()
 elif view.phase=="captured": _capture_screen()
 elif view.demo_exit: _demo_exit_screen()
 elif view.phase in ["inspection","prison_end"] or (view.phase=="pack" and view.prison.get("active",false)): _inspection_screen()
 elif show_route or view.phase in ["map","travel","cleared","pack"]:
  if view.practice: _practice_screen()
  else: _route_screen()
 elif view.phase in ["treasure","departure"]:
  _rewards()
 elif view.phase=="shop":
  _service_screen()
 elif view.phase=="event":
  if view.reward_panel.active and (view.room_event.report=="" or event_read_page==view.room_event.page_id): _rewards()
  else: _event_screen()
 else:
  screen_parent=screen_layers["battle"]
  _battle_scene()
  if not view.card_chain.is_empty():
   screen_parent=screen_layers["chain"];_chain_screen()
  elif view.reward_panel.active:
   screen_parent=screen_layers["reward"];_rewards()
  else:
   if not _selecting_hand(): _fixed_actions()
   _hand()
 screen_parent=null
 if view.phase=="shop" and not show_route:
  if shop_sidebar_open:
   _bottom_controls(false)
   _body_drawer()
  preload("res://ui/mana_flask.gd").build(self)
  var flask=find_child("ManaFlask",true,false)
  if flask!=null: flask.position=Vector2(760,86);flask.scale=Vector2(0.72,0.72)
  var toggle=_button("‹" if shop_sidebar_open else "›",func():
   shop_sidebar_open=not shop_sidebar_open
   if not shop_sidebar_open: show_body=false
   render(view),GOLD)
  toggle.name="ShopSidebarToggle";toggle.z_index=200
  toggle.tooltip_text="收起身体与状态" if shop_sidebar_open else "展开身体与状态"
  _place(toggle,Rect2(356,238,34,54))
 elif view.phase!="departure":
  _bottom_controls()
  _body_drawer()
  _installed_tools()
 if not show_route and view.phase in ["battle","prepare","rest","prison","event","shop","treasure"]: _action_sidebar()
 if player_pick: _player_picker()
 if selected_card!="" and not _selecting_hand(): DragTargets.focus_bodies(self,{"card_uid":selected_card,"free":card_faces.get(selected_card,false),"version":view.version})
 _refresh_drawers()
 if view.phase=="shop" and not show_route: ShopScreen.payment_overlay(self)
 if notice!="" and actor_targets.has("hero"):
  _show_term(actor_targets.hero,{"label":"","detail":notice})
 if is_instance_valid(keyboard_input): keyboard_input.refresh_hints.call_deferred()

# Information panels own only their overlay. Keep the scene, hand, focus and map alive.
# The drawer layer must leave the tree with the frame tree now living on: a nulled
# reference would otherwise leave the previous drawer nodes behind for find_child.
func _clear_drawer_layer() -> void:
 if is_instance_valid(drawer_layer):
  layout.remove_child(drawer_layer)
  drawer_layer.queue_free()
 drawer_layer=null

func _refresh_drawers() -> void:
 _hide_term()
 if is_instance_valid(drawer_layer):
  for key in candidate_buttons.keys():
   var button=candidate_buttons[key]
   if not is_instance_valid(button) or drawer_layer.is_ancestor_of(button):
    candidate_buttons.erase(key)
    var previous=drawer_base_candidates.get(key)
    if is_instance_valid(previous) and previous.is_inside_tree(): candidate_buttons[key]=previous
  drawer_layer.hide();layout.remove_child(drawer_layer);drawer_layer.queue_free()
 drawer_base_candidates=candidate_buttons.duplicate()
 drawer_layer=Control.new();drawer_layer.name="InformationLayer"
 drawer_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
 layout.add_child(drawer_layer)
 drawer_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 building_drawer=true
 if show_home:
  if show_encyclopedia: _encyclopedia_drawer()
  if show_tutorial: _tutorial_drawer()
  if show_settings: _settings_drawer()
  if show_options: _options_drawer()
  if show_saves: _save_drawer()
 else:
   if show_log: _log_drawer()
   if show_deck: _deck_drawer()
   if show_event_selection: EventScreen.drawer(self)
   if show_items: _items_drawer()
   if show_hook and view.phase=="rest": _hook_drawer()
   if show_pressure: _pressure_drawer()
   if show_settings: _settings_drawer()
   if show_saves: _save_drawer()
   if show_menu: _menu_drawer()
   if show_encyclopedia: _encyclopedia_drawer()
   if show_tutorial: _tutorial_drawer()
   if show_options: _options_drawer()
   if show_shop_service and view.phase=="shop":
    var title={"release":"拘束解除","remove":"删牌服务","discard":"整理道具"}[shop_service_mode]
    ShopScreen.services(self,_drawer_shell(title,Rect2(450,150,805,600),GOLD))
 building_drawer=false

func _header() -> void:
 var header=HeaderScene.instantiate()
 _place(header,Rect2(0,0,1600,62))
 var trim=header.trim_line();trim.color=GOLD.darkened(0.62)
 var info=header.info()
 var info_style=_style(Color("121e27"),Color("35424a"),9);info_style.shadow_size=0
 info.add_theme_stylebox_override("panel",info_style)
 var location=header.location()
 var location_style=_style(Color("302d25"),Color("65583e"),8);location_style.shadow_size=0
 location.add_theme_stylebox_override("panel",location_style)
 for index in [1,2]: header.divider(index).color=Color("35424a")
 var order_tone=RED if view.run_header.last else CYAN
 var order_badge=header.order_badge()
 var order_style=_style(order_tone.darkened(0.82),order_tone.darkened(0.62),6);order_style.shadow_size=0
 order_badge.add_theme_stylebox_override("panel",order_style)
 for entry in [[header.floor_label(),view.run_header.location,12,GOLD],[header.round_label(),view.run_header.turn,17,TEXT],[header.order_label(),view.run_header.order,16,order_tone]]:
  var label=entry[0]
  _style_label(label,entry[1],entry[2],entry[3])
  label.autowrap_mode=TextServer.AUTOWRAP_OFF;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 if view.wall!="none":
  var distance_label=_label("距墙%d格" % view.wall_position.distance,16,MUTED)
  distance_label.name="WallPosition"
  distance_label.autowrap_mode=TextServer.AUTOWRAP_OFF;distance_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;distance_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  _place(distance_label,Rect2(384,0,118,42),info)
 var security_label=header.security_label()
 _style_label(security_label,"警戒度%d级" % view.security,16,GOLD)
 security_label.autowrap_mode=TextServer.AUTOWRAP_OFF;security_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;security_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var book=header.tutorial_button()
 _style_button(book,"教程书",func():_open_tutorial(),GOLD)
 for state in ["normal","hover","pressed"]:
  var glow=_style(Color("514127") if state=="normal" else Color("695433") if state=="hover" else Color("3c3020"),Color("e4c17e"),8)
  glow.shadow_color=Color(0.79,0.65,0.34,0.22);glow.shadow_size=4
  book.add_theme_stylebox_override(state,glow)
  book.add_theme_color_override("font_color" if state=="normal" else "font_"+state+"_color",Color("ffe4a6"))
 var status_button=header.status_button()
 _style_button(status_button,"状态 !" if view.pressure.overloaded else "状态",func():_open_drawer("show_pressure"),RED if view.pressure.overloaded else CYAN)
 var items_button=header.items_button()
 _style_button(items_button,"道具 %d / %d" % [view.carried_items,view.capacity],func():_open_drawer("show_items"))
 var deck_button=header.deck_button()
 _style_button(deck_button,"卡组 %d" % view.deck_count,func():_open_drawer("show_deck"))
 var in_prison=view.prison.get("active",false) or view.phase in ["captured","prison_end"]
 var map_button=header.map_button()
 _style_button(map_button,"牢房说明" if in_prison else "返回房间" if show_route and view.phase in ["battle","prepare","reward","rest","event","shop","treasure","departure"] else ("练习说明" if view.practice else "塔路"),func():
  if in_prison:
   _open_tutorial("prison")
  elif view.phase in ["battle","prepare","reward","rest","event","shop","treasure","departure"]:
   show_route=not show_route;_close_drawers()
   selected_card=""; show_body=false
   render(view),CYAN)
 map_button.name="OpenPrisonTutorial" if in_prison else "OpenMap"
 var menu_button=header.menu_button()
 _style_button(menu_button,"菜单 !" if save_failed else "菜单 ≡",func():_open_drawer("show_menu"),RED if save_failed else MUTED)
 _relic_row()

func _relic_row() -> void:
 if view.relics.is_empty(): return
 var strip=ScrollContainer.new();strip.name="RelicStrip"
 strip.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 _place(strip,Rect2(405,78,1013,56))
 var icons=HBoxContainer.new();icons.name="RelicRow";icons.add_theme_constant_override("separation",8);strip.add_child(icons)
 for relic in view.relics:
  var shortcut=Control.new();shortcut.name="RelicShortcut_"+relic.id
  shortcut.custom_minimum_size=Vector2(40,40);shortcut.focus_mode=Control.FOCUS_ALL
  shortcut.mouse_default_cursor_shape=Control.CURSOR_HELP;icons.add_child(shortcut)
  var icon=preload("res://ui/relic_icon.gd").new();icon.relic=relic
  _place(icon,Rect2(0,0,40,40),shortcut)
  var detail=relic.rarity_name+"\n"+relic.detail
  if not relic.counter.is_empty(): detail+="\n\n"+relic.counter.detail
  if relic.current!="": detail+="\n\n"+relic.current
  var entry={"label":relic.name,"detail":detail}
  shortcut.mouse_entered.connect(func():icon.modulate=Color("ffe6ad");_show_term(shortcut,entry))
  shortcut.mouse_exited.connect(func():icon.modulate=Color.WHITE;_hide_term())
  shortcut.focus_entered.connect(func():_show_term(shortcut,entry));shortcut.focus_exited.connect(_hide_term)

func _status_tooltip(status: Dictionary) -> Dictionary:
 return {"label":status.name+" · "+status.value,"detail":status.detail+"\n\n来源："+status.source+"\n持续："+status.duration}

func _status_control(status: Dictionary, compact: bool) -> Button:
 var button=Button.new();button.name=("StatusIcon_" if compact else "Status_")+status.id.validate_node_name()
 button.custom_minimum_size=Vector2(38,38) if compact else Vector2(163,64)
 var tone=RED if status.tone=="bad" else CYAN if status.tone=="good" else GOLD
 var style=_style(Color("111d28"),tone.darkened(0.7));style.shadow_size=0
 style.set_corner_radius_all(10);style.set_content_margin_all(0)
 if compact: style.bg_color=Color.TRANSPARENT;style.set_border_width_all(0)
 button.add_theme_stylebox_override("normal",style)
 var hover=style.duplicate();hover.bg_color=Color("243b48");hover.border_color=tone
 button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("focus",hover)
 button.add_theme_stylebox_override("pressed",hover)
 var dim=style.duplicate();dim.bg_color=Color("0c141c");dim.border_color=Palette.MUTED.darkened(0.6)
 button.add_theme_stylebox_override("disabled",dim)
 var icon=StatusIcon.new();icon.status=status.duplicate()
 if not compact: icon.status.badge=""
 _place(icon,Rect2(0,0,38,38) if compact else Rect2(7,12,40,40),button)
 if not compact:
  var title=_label(status.name,13,tone);title.max_lines_visible=2
  _place(title,Rect2(55,9,101,34),button)
  var value=_label(status.value,11,MUTED);value.max_lines_visible=1
  _place(value,Rect2(55,43,101,18),button)
  if selected_status==status.id: button.add_theme_stylebox_override("normal",hover)
 var entry=_status_tooltip(status)
 button.mouse_entered.connect(func():_show_term(button,entry));button.mouse_exited.connect(_hide_term)
 button.focus_entered.connect(func():_show_term(button,entry));button.focus_exited.connect(_hide_term)
 if status.get("toggle",false):
  var choice=actions.find("status_toggle",{"status":status.id})
  if not choice.is_empty():
   button.gui_input.connect(func(event):
    if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
     button.accept_event();_hide_term();_submit(choice))
 button.pressed.connect(func():
  selected_status=status.id
  if compact: status_filter="all";_open_drawer("show_pressure")
  else: _refresh_drawers())
 return button

func _status_strip(owner: String, rect: Rect2, parent: Control=null) -> void:
 var entries=view.statuses.filter(func(e):return e.active and e.owner==owner)
 if entries.is_empty(): return
 var strip=ScrollContainer.new();strip.name="StatusStrip_"+owner
 strip.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 strip.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
 _place(strip,rect,parent)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",4);strip.add_child(row)
 for entry in entries: row.add_child(_status_control(entry,true))

func _battle_scene() -> void:
 var screen=BattleScene.instantiate()
 _place(screen,Rect2(0,0,1600,900))
 # Everything below belongs to the battle screen, so it is anchored inside the scene
 # container instead of being a sibling of the screen layers.
 screen_parent=screen.battlefield()
 _status_strip("hero",Rect2(405,146,366,52))
 var hero=Arena.new()
 hero.name="HeroArt"
 hero.fixed_portrait=display_settings.fixed_hero_portrait
 hero.pose=view.posture
 hero.has_restraint_level=view.has_restraint_level
 hero.hero_view=view
 _place(hero,Rect2(394,200,355,302))
 var hero_target=_actor_drop_area(Rect2(394,200,355,302))
 hero_target.accepted_kind="player"
 hero_target.hover_card=func(data): _player_drag_preview(data)
 hero_target.accept_card=func(data): return _can_drop_on_player(data)
 hero_target.receive_card=func(data): call_deferred("_receive_player_drop",data)
 actor_targets["hero"]=hero_target
 _resource_meter("HeroOverload",Rect2(491,502,160,13),view.pressure.value,view.pressure.maximum,OVERLOAD_COLOR)
 _resource_meter("HeroMana",Rect2(491,520,160,13),view.mana,view.mana_max,CYAN)
 if not view.guard_bind.is_empty():
  var bind_label=_place(_label("捕缚",11,RED),Rect2(451,537,40,15));bind_label.name="HeroGuardBindCaption"
  _resource_meter("HeroGuardBind",Rect2(491,538,160,13),view.guard_bind.value,view.guard_bind.maximum,RED)
  var bind_target=_actor_drop_area(Rect2(451,535,200,19),null,true)
  bind_target.name="GuardBindTarget"
  bind_target.accepted_kind="card"
  bind_target.tooltip_text=view.guard_bind.detail
  bind_target.hover_card=func(data): _guard_bind_drag_preview(data)
  bind_target.accept_card=func(data):
   var c=_guard_bind_card_candidate(data)
   return not c.is_empty() and c.valid
  bind_target.receive_card=func(data):
   var c=_guard_bind_card_candidate(data)
   if not c.is_empty() and c.valid: call_deferred("_submit",c,int(data.version))
  bind_target.pressed.connect(_activate_guard_bind_target)
  actor_targets["guard_bind"]=bind_target
 var cast_label=_label("嘴部施法成功率 "+view.casting.percent,11,CYAN)
 cast_label.name="HeroCastingChance";cast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _place(cast_label,Rect2(674 if not view.guard_bind.is_empty() else 481,537 if not view.guard_bind.is_empty() else 533,180,14))
 _speech_bubble()
 var living=view.enemies.filter(func(e):return not e.gone)
 # Presentation order only; combat and target IDs retain their original order.
 living=living.filter(func(e):return e.template!="puppeteer")+living.filter(func(e):return e.template=="puppeteer")
 var enemy_count=living.size()
 var enemy_scale=minf(1.0,3.0/maxi(1,enemy_count))
 var enemy_row_width=enemy_count*ENEMY_GROUP_WIDTH*enemy_scale
 var enemy_row_start=ENEMY_STAGE_LEFT+(ENEMY_STAGE_WIDTH-enemy_row_width)/2.0
 for i in range(enemy_count):
  var e=living[i]
  var group=EnemyActorScene.instantiate();group.name="EnemyGroup_"+e.id
  var x=0.0
  var guard=e.type in ["guard","six_bind","puppeteer"]
  # Arena builds its sprite and subscribes to art changes in _ready, so bind it before the group enters the tree.
  var picture=group.art(); picture.name="EnemyArt_"+e.id;picture.mode=e.type;picture.variant=e.visual_variant;picture.inactive=e.gone
  picture.template=e.template;picture.art_settings=display_settings
  var receiver=group.receiver()
  _style_actor_drop_area(_style_button(receiver,"",func(): pass,CYAN),true)
  var b=group.select_button()
  _style_button(b,("◇ " if selected_enemy==e.id and not e.gone else "")+e.name,func():_select_enemy(e.id),CYAN if selected_enemy==e.id else GOLD)
  b.name="EnemySelect_"+e.id
  _configure_enemy_drop(b,e.id)
  b.disabled=e.gone
  var bar=group.hp_bar()
  _style_bar(bar,e.hp,e.maximum,RED)
  var hp=group.hp_label()
  _style_label(hp,"%s / %s" % [game.number(e.hp),game.number(e.maximum)],14,TEXT)
  hp.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var screen_x=enemy_row_start+i*ENEMY_GROUP_WIDTH*enemy_scale
  _place(group,Rect2(screen_x,487.0*(1.0-enemy_scale),260,487))
  group.scale=Vector2.ONE*enemy_scale
  for n in range(e.intent_icons.size()):
   var entry=e.intent_icons[n]
   var icon=preload("res://ui/intent_icon.gd").new()
   icon.kind=entry.kind;icon.name="IntentIcon_"+e.id+"_"+entry.kind
   var columns=mini(4,e.intent_icons.size())
   var bottom=130 if guard else 220
   _place(icon,Rect2(110-columns*27+(n%4)*54,bottom-ceili(e.intent_icons.size()/4.0)*50+(n/4)*50,54,50),group)
   group.move_child(icon,n)
   icon.z_index=8
   icon.mouse_entered.connect(func():_show_term(icon,entry));icon.mouse_exited.connect(_hide_term)
   icon.focus_entered.connect(func():_show_term(icon,entry));icon.focus_exited.connect(_hide_term)
  var picture_rect=Rect2(x+40,134,146,270) if e.type=="guard" else (Rect2(x,134,226,270) if guard else Rect2(x,226,220,180))
  picture.position=picture_rect.position;picture.size=picture_rect.size
  var receiver_rect=picture_rect if guard else Rect2(x,236,220,169)
  receiver.position=receiver_rect.position;receiver.size=receiver_rect.size
  receiver.pressed.connect(func():_select_enemy(e.id))
  _configure_enemy_drop(receiver,e.id)
  actor_targets[e.id]=receiver
  b.position=Vector2(x-5,408);b.size=Vector2(236,37)
  bar.position=Vector2(x,451);bar.size=Vector2(226,9)
  hp.position=Vector2(x,463);hp.size=Vector2(226,24)
  _status_strip(e.id,Rect2(x,488,226,51),group)

func _select_enemy(enemy_id: String) -> void:
 if not view.enemies.any(func(e):return e.id==enemy_id and not e.gone): return
 selected_enemy=enemy_id;selected_card="";show_body=false;selected_candidate=""
 _clear_drop_targets();_clear_player_picker();_refresh_body_details()
 for card in card_buttons.values():
  card.chosen=false;card.queue_redraw()
 for enemy in view.enemies:
  var button=layout.find_child("EnemySelect_"+enemy.id,true,false)
  if button==null: continue
  var color=CYAN if selected_enemy==enemy.id else GOLD
  button.text=("◇ " if selected_enemy==enemy.id and not enemy.gone else "")+enemy.name
  button.add_theme_stylebox_override("normal",_style(Color("1b2b39"),color.darkened(0.25)))
  button.add_theme_stylebox_override("hover",_style(Color("2b4553"),color))
  button.add_theme_stylebox_override("pressed",_style(Color("24434c"),color))
  button.add_theme_stylebox_override("focus",_style(Color("2b4553"),color))
  button.add_theme_stylebox_override("disabled",_style(Color("141d26"),Palette.MUTED.darkened(0.6)))
 _remove_local_panel("AttackActions")
 if view.phase=="battle" and view.card_chain.is_empty(): _fixed_actions()

func _fixed_actions() -> void:
 if view.phase=="rest": _rest_controls()
 if view.phase=="prison": _prison_controls()
 if view.phase=="battle":
  var container=Control.new();container.name="AttackActions";container.mouse_filter=Control.MOUSE_FILTER_IGNORE
  _place(container,Rect2(0,0,1600,900))
  var rail=_panel(Rect2(384,550,1195,66),container)
  rail.name="BasicActionRail";rail.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var offers=actions.select("attack",{"enemy":selected_enemy}).filter(func(c):return c.payload.form==attack_forms.get(c.payload.type,0))
  offers.append_array(actions.select("pressure"))
  var width=(1195.0-20.0-maxi(0,offers.size()-1)*8.0)/maxi(1,offers.size())
  for i in range(offers.size()):
   var c=offers[i]
   var attack=c.payload.kind=="attack"
   var alternatives=actions.select("attack",{"enemy":selected_enemy,"type":c.payload.type}) if attack else []
   var summary=c.get("brief",c.detail.trim_suffix("。"))
   var tags=c.get("brief_tags","")
   if c.has("casting"): tags+=(" · " if tags!="" else "")+c.casting.percent
   var btn=_basic_action_tile(c,Rect2(394+i*(width+8),556,width,54),container,summary,tags,alternatives.size()>1,alternatives)
   if attack:
    btn.name="BasicAttack_"+c.payload.type
    btn.drag_payload={"action_type":c.payload.type,"form":c.payload.form,"version":view.version}
    btn.drag_label=c.label
    if alternatives.size()>1:
     btn.gui_input.connect(func(event):
      if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
       attack_forms[c.payload.type]=(c.payload.form+1)%alternatives.size()
       # Deferred: rebuilding the rail inside this tile's own input callback would
       # detach the node that is still handling the event.
       btn.accept_event();_rebuild_action_rail.call_deferred(btn.name,btn.is_hovered()))
   else: btn.name="DeepBreath"


 for c in ([] if view.phase=="battle" else actions.select("pressure")):
  var parent=layout
  var btn=_button(c.label+" · %d能量" % c.cost,func():_submit(c),CYAN)
  btn.name="DeepBreath";btn.disabled=not c.valid
  btn.add_theme_font_size_override("font_size",15)
  btn.tooltip_text=c.detail+("\n"+c.risk if c.risk!="" else "") if c.valid else c.reason
  _place(btn,Rect2(1347,555,218,38),parent)
  candidate_buttons[c.id]=btn
  var detail=_label(c.detail if c.valid else c.reason,12,MUTED if c.valid else RED)
  detail.name="DeepBreathDetail"
  _place(detail,Rect2(1347,598,218,40),parent)

# A form switch rebuilds the whole rail, which drops the open hover card with it. When
# the pointer never left the tile, the card has to come back for the newly chosen form.
func _rebuild_action_rail(tile_name: String, restore_hover: bool) -> void:
 render(view)
 if not restore_hover: return
 var tile=find_child(tile_name,true,false)
 if tile!=null and tile.is_visible_in_tree(): tile.mouse_entered.emit()

# Two-line action tiles share the original candidates, tooltips and drag receiver.
func _basic_action_tile(c: Dictionary, rect: Rect2, parent: Control, summary: String, tags: String, can_flip: bool, slot_actions: Array=[]) -> Button:
 var accent=CYAN if c.payload.kind=="calm" or c.has("casting") else GOLD
 var btn=BasicActionTileScene.instantiate()
 _style_button(btn,"",func():_submit(c),accent)
 btn.disabled=not c.valid;btn.clip_contents=true
 # The rail is one shared row of tiles, so its explanation opens below the tile
 # instead of covering the neighbouring skill text on the same row.
 btn.set_meta("term_below",true)
 _place(btn,rect,parent);candidate_buttons[c.id]=btn
 var cost="%d能量" % c.cost+(" · %s魔力" % game.number(c.mana) if c.mana>0 else "")
 var cost_width=102.0 if c.mana>0 else 44.0
 var title=_style_label(btn.title_label(),c.label,14,TEXT if c.valid else MUTED)
 title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 title.position=Vector2(10,5);title.size=Vector2(rect.size.x-cost_width-24,20)
 var price=_style_label(btn.price_label(),cost,11,accent if c.valid else MUTED)
 price.autowrap_mode=TextServer.AUTOWRAP_OFF;price.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 price.position=Vector2(rect.size.x-cost_width-10,7);price.size=Vector2(cost_width,17)
 var detail=_style_label(btn.detail_label(),summary if c.valid else c.reason.trim_suffix("。"),15 if c.valid else 11,TEXT if c.valid else RED)
 detail.name="BasicAttackDetail_"+c.payload.type if c.payload.kind=="attack" else "DeepBreathDetail"
 detail.position=Vector2(10,29 if c.valid else 27);detail.size=Vector2(rect.size.x-20,24 if c.valid else 26)
 if c.valid and tags!="":
  detail.size.x=112 if tags.length()>10 else 126
  var extra=_label(tags,10,RED if c.payload.get("fall",false) else accent)
  extra.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;extra.autowrap_mode=TextServer.AUTOWRAP_OFF
  _place(extra,Rect2(detail.size.x+12,31,rect.size.x-detail.size.x-22,17),btn)
 var tooltip=("当前施法成功率："+c.casting.percent+"\n" if c.has("casting") else "")+c.detail
 if not c.valid: tooltip+="\n"+c.reason
 if c.risk!="": tooltip+="\n"+c.risk
 if can_flip: tooltip+="\n右键切换招式"
 var entry={"label":c.label,"detail":tooltip}
 if slot_actions.size()>1:
  # This tile owns a hotkey slot with several skills: the hover card lists all of them
  # and each row releases its own skill, so the player never has to right-click first.
  btn.mouse_entered.connect(func():_show_term_slot(btn,entry,slot_actions))
  btn.focus_entered.connect(func():_show_term_slot(btn,entry,slot_actions))
  btn.mouse_exited.connect(func():_hide_term_when_away(btn))
  btn.focus_exited.connect(func():_hide_term_when_away(btn))
 else:
  btn.mouse_entered.connect(func():_show_term(btn,entry));btn.mouse_exited.connect(_hide_term)
  btn.focus_entered.connect(func():_show_term(btn,entry));btn.focus_exited.connect(_hide_term)
 return btn

func _posture_layout(count: int) -> Dictionary:
 var with_move=view.phase=="battle" and not actions.select("wall_move",{"direction":"toward"}).is_empty()
 var rows=count+(1 if with_move else 0)
 var stride=minf(48.0,100.0/maxi(1,rows)) if with_move else 48.0
 return {"top":725-rows*stride,"stride":stride,"with_move":with_move}

func _posture_controls() -> void:
 var choices=actions.select("posture").filter(func(c):return c.payload.adjacent)
 if choices.is_empty(): return
 var ordinary=choices.filter(func(c):return not c.payload.wall)
 var placement=_posture_layout(ordinary.size())
 var container=Control.new();container.name="PostureChoices"
 _place(container,Rect2(1330,placement.top+(placement.stride if placement.with_move else 0),249,ordinary.size()*placement.stride))
 for c in choices:
  var index=ordinary.find(ordinary.filter(func(o):return o.payload.dest==c.payload.dest)[0])
  var has_wall=choices.any(func(o):return o.payload.dest==c.payload.dest and o.payload.wall)
  var name_text=c.label if c.payload.wall else {"stand":"站起","sit":"坐下" if view.posture=="stand" else "坐起","lie":"躺下"}[c.payload.dest]
  var text=name_text+" · "+str(c.cost)+"能量"
  if not c.valid: text+="\n"+c.reason
  elif c.payload.wall and placement.stride>=48: text+="\n少耗1能量"
  var btn=_button(text,func():_submit(c),CYAN if c.payload.wall else GOLD,true)
  btn.custom_minimum_size.y=placement.stride-4
  btn.name="Posture_"+c.payload.dest+("_wall" if c.payload.wall else "")
  btn.drag_payload={"self_action_id":c.id,"version":view.version}
  btn.drag_label=c.label
  btn.add_theme_font_size_override("font_size",10 if placement.stride<48 else 12)
  btn.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  for state_name in ["normal","hover","pressed","focus","disabled"]:
   var style=btn.get_theme_stylebox(state_name).duplicate()
   style.content_margin_top=2;style.content_margin_bottom=2
   btn.add_theme_stylebox_override(state_name,style)
  btn.disabled=not c.valid;btn.tooltip_text=c.detail if c.valid else c.reason
  _place(btn,Rect2(128 if c.payload.wall else 0,index*placement.stride,121 if has_wall else 249,placement.stride-4),container)
  candidate_buttons[c.id]=btn

func _card(card: Dictionary, rect: Rect2, fn: Callable, rotation_value: float=0, parent: Node=null, hand_interaction: bool=true, lift: bool=true) -> Button:
 card=card.duplicate()
 card.merge(view.card_texts.get(card.type,{}),true)
 card.merge(view.get("card_instances",{}).get(card.get("physical_uid",card.uid),{}),true)
 var button=CardFaceScene.instantiate()
 button.art_settings=display_settings
 button.lift_on_hover=lift
 button.symbol=card.type
 button.chosen=selected_card==card.uid
 button.free_face=card_faces.get(card.uid,false)
 button.display_name=card.name
 button.rarity=card.rarity
 button.single_face=card.single_face
 button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
 button.add_theme_stylebox_override("hover",StyleBoxEmpty.new())
 button.add_theme_stylebox_override("pressed",StyleBoxEmpty.new())
 button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 var cost=button.get_node("CardCost")
 _style_label(cost,card.cost,23,TEXT);cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 cost.position=Vector2(0,1);cost.size=Vector2(38,37)
 var title=button.get_node("CardTitle")
 _style_label(title,card.name,17,TEXT)
 title.position=Vector2(43,10);title.size=Vector2(rect.size.x-48,31)
 var text_area=button.get_node("CardText")
 text_area.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 text_area.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
 text_area.mouse_filter=Control.MOUSE_FILTER_PASS
 text_area.mouse_force_pass_scroll_events=false
 text_area.position=Vector2(12,rect.size.y*CardFace.ART_HEIGHT_RATIO+10)
 text_area.size=Vector2(rect.size.x-24,rect.size.y/3-18)
 var textbox=text_area.get_node("Content")
 textbox.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 textbox.add_theme_constant_override("separation",1)
 _place(button,rect,parent)
 button.home=rect.position
 button.resting_angle=rotation_value
 button.pivot_offset=Vector2(rect.size.x/2,rect.size.y)
 button.rotation=rotation_value
 button.pressed.connect(fn)
 if hand_interaction and not card.uid.begins_with("reward_") and not card.get("unplayable",false):
  button.drag_payload={"card_uid":card.uid,"free":button.free_face,"version":view.version}
  button.drag_began.connect(func(_data): selected_card=""; selected_candidate=""; _clear_drop_targets(); _clear_player_picker())
 button.flip_requested.connect(func():
  if hand_interaction and _selecting_hand(): return
  if card.get("single_face",false): return
  card_faces[card.uid]=not card_faces.get(card.uid,false)
  player_pick=false
  selected_candidate=""
  _refresh_card_face(button,card)
  if hand_interaction:
   _clear_player_picker();_clear_drop_targets()
   _refresh_body_details())
 _refresh_card_face(button,card)
 button.mouse_entered.connect(func():_card_tooltip(button,card))
 button.mouse_exited.connect(_hide_term)
 button.focus_entered.connect(func():_card_tooltip(button,card))
 button.focus_exited.connect(_hide_term)
 _ignore_mouse(textbox)
 return button

# Catalog, shop and deck use the hand face with no gameplay drag or hover displacement.
func _display_card(type: String, parent: Node, fn: Callable=Callable(), key: String="", dimensions: Vector2=Vector2(226,290), physical_uid: String="") -> Button:
 var data=preload("res://data/encyclopedia.gd").card(type)
 data.uid="display_"+key+"_"+type
 data.physical_uid=physical_uid
 var button=_card(data,Rect2(Vector2.ZERO,dimensions),fn if fn.is_valid() else func():pass,0,parent,false,false)
 button.custom_minimum_size=dimensions
 button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
 button.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 button.name="DisplayCard_"+key
 return button

func _refresh_card_face(button: Button, card: Dictionary) -> void:
 button.free_face=card_faces.get(card.uid,false)
 var side="free" if button.free_face else "bound"
 button.effect_free=card.free_faces[side];button.face_name=card.face_names[side]
 button.set_mana(card.face_mana[side])
 button.get_node("CardCost").text=card.get("face_costs",{}).get("free" if button.free_face else "bound",card.cost)
 button.chosen=selected_card==card.uid
 if not button.drag_payload.is_empty(): button.drag_payload.free=button.free_face
 var text_area=button.get_node("CardText")
 text_area.scroll_vertical=0
 var textbox=text_area.get_node("Content")
 for child in textbox.get_children():
  textbox.remove_child(child);child.queue_free()
 var classification=_label(card.type_name+" · "+card.rarity_name+("" if card.single_face else (" · "+card.face_names[side]))+(" · 保留" if card.get("retained",false) else ""),11,button.RARITY_COLORS[card.rarity])
 classification.name="CardClassification";textbox.add_child(classification)
 var body=_label(card.face_effects[side],14,TEXT)
 body.visible=body.text!=""
 body.name="CardEffect";textbox.add_child(body)
 for text in card.face_requirements[side]:
  var requirement=_label(text,11,CYAN)
  requirement.name="CardRequirement";textbox.add_child(requirement)
 if card.has("availability"):
  var availability=card.availability.free if button.free_face else card.availability.bound
  button.modulate=Color(0.55,0.55,0.55,1) if availability.dim else Color.WHITE
  if not availability.usable and availability.text!="":
   var status=_label(availability.text,11,TEXT)
   status.name="CardAvailability";textbox.add_child(status)
 _ignore_mouse(textbox)
 button.fit_text.call_deferred()
 button.queue_redraw()
 if term_anchor==button or button.has_focus() or button.get_global_rect().has_point(get_global_mouse_position()): _card_tooltip(button,card)

func _card_tooltip(button: Button, card: Dictionary) -> void:
 var side="free" if button.free_face else "bound"
 button.effect_free=card.free_faces[side];button.face_name=card.face_names[side]
 var lines=[]
 var text_area=button.get_node("CardText")
 var content=text_area.get_node("Content")
 var keyboard_details=is_instance_valid(keyboard_input) and keyboard_input.selection.get("uid","")==card.uid
 if content.size.y>text_area.size.y or keyboard_details or (is_instance_valid(touch_input) and touch_input.held and touch_input.details_allowed):
  for label in content.get_children():
   if label.visible and label.name!="CardClassification": lines.append(label.text)
 if card.cast_faces[side] and card.has("casting"):
  lines.append("施法成功率 · "+card.casting.percent+"\n"+card.casting.formula)
  lines.append("失败扣费，原牌留手。")
 for term in card.face_keywords[side]: lines.append(term.name+"："+term.detail)
 if card.note!="": lines.append(card.note)
 if lines.is_empty(): _hide_term();return
 _show_term(button,{"label":card.name+("" if card.single_face else (" · "+card.face_names[side])),"detail":"\n".join(lines)})

# Removes every panel with this name: screens anchor their content inside a scene
# container, so a stale duplicate can live in a different subtree than layout.
func _remove_local_panel(node_name: String) -> void:
 for panel in layout.find_children(node_name,"",true,false):
  for key in candidate_buttons.keys():
   var button=candidate_buttons[key]
   if not is_instance_valid(button) or panel.is_ancestor_of(button): candidate_buttons.erase(key)
  panel.hide()
  var holder=panel.get_parent()
  if holder!=null: holder.remove_child(panel)
  panel.queue_free()

func _refresh_body_details() -> void:
 DragTargets.clear(self)
 _remove_local_panel("EquipmentDetails")
 if not _selecting_hand() and (show_body or selected_card!="" or view.pending_retain): _body_details()
 if selected_card!="" and not _selecting_hand(): DragTargets.focus_bodies(self,{"card_uid":selected_card,"free":card_faces.get(selected_card,false),"version":view.version})

func _hand() -> void:
 if view.pressure.overloaded:
  _climax_narration()
  return
 if view.hand.is_empty():
  _place(_label("手牌已用完",19,MUTED),Rect2(570,749,780,45))
  return
 var count=view.hand.size()
 var step=minf(192,746.0/maxi(1,count-1))
 var start=850.0-(float(count-1)*step+184)/2
 for i in range(count):
  var card=view.hand[i]
  var mid=float(i)-float(count-1)/2
  var y=630+absf(mid)*4
  var b=_card(card,Rect2(start+i*step,y,184,252),func(): _activate_card(card.uid),mid*0.018)
  card_buttons[card.uid]=b
  if _selecting_hand():
   var choice=_hand_choice(card.uid)
   b.drag_payload={};b.disabled=choice.is_empty() or not choice.valid
   b.chosen=not b.disabled;b.modulate=Color(0.45,0.45,0.45,1) if b.disabled else Color.WHITE
   b.set_meta("hand_selectable",not b.disabled);b.queue_redraw()
   if not choice.is_empty(): candidate_buttons[choice.id]=b
  if is_instance_valid(card_motion) and card_motion.pending_draws.has(card.uid): b.hide()

func _climax_narration() -> void:
 var panel=_panel(Rect2(530,636,790,138));panel.name="ClimaxNarration"
 var style=_style(Color("1c1019"),OVERLOAD_COLOR.darkened(0.35),12);style.shadow_size=5
 panel.add_theme_stylebox_override("panel",style)
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",9);panel.add_child(column)
 var title=_label("高潮",21,OVERLOAD_COLOR);title.name="ClimaxNarrationTitle";column.add_child(title)
 var text=str(view.climax.get("text",""))
 var body=_label(text,16,TEXT);body.name="ClimaxNarrationText";body.visible=text!="";column.add_child(body)

func _bottom_controls(include_tools: bool=true) -> void:
 var has_turn_controls=not show_route and view.phase in ["battle","prepare","rest","prison"]
 var bar=BottomControlsScene.instantiate()
 _place(bar,Rect2(0,0,1600,900))
 var resource_back=bar.resource_panel()
 var resource_style=_style(Color("0e1923"),Color("293e47"),10);resource_style.shadow_size=0;resource_style.set_border_width_all(1)
 resource_back.add_theme_stylebox_override("panel",resource_style)
 bar.show_tools(include_tools)
 if include_tools:
  var tool_back=bar.tool_panel()
  var tool_style=_style(Color("101c27"),Color("615439"),14);tool_style.set_border_width_all(1);tool_style.shadow_size=3
  tool_back.add_theme_stylebox_override("panel",tool_style)
  tool_back.size.y=188 if has_turn_controls else 88
 bar.show_turn_controls(has_turn_controls)
 if has_turn_controls: bar.tool_divider().color=Color("35464b")
 var meters=[
  {"id":"MainOverload","label":"快感","value":view.pressure.value,"maximum":view.pressure.maximum,"color":OVERLOAD_COLOR},
  {"id":"MainMana","label":"魔力","value":view.mana,"maximum":view.mana_max,"color":CYAN}]
 if not view.guard_bind.is_empty():
  meters.append({"id":"MainGuardBind","label":"捕缚","value":view.guard_bind.value,"maximum":view.guard_bind.maximum,"color":RED})
 var row_height=resource_back.size.y/meters.size()
 var bar_height=24.0 if meters.size()==2 else 17.0
 for i in range(meters.size()):
  var meter=meters[i]
  var center=resource_back.position.y+row_height*(i+0.5)
  var caption=_label(meter.label,13,meter.color);caption.name=meter.id+"Caption"
  caption.autowrap_mode=TextServer.AUTOWRAP_OFF
  caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  _place(caption,Rect2(38,center-12,64,24))
  _resource_meter(meter.id,Rect2(104,center-bar_height/2,234,bar_height),meter.value,meter.maximum,meter.color)
 var mana_bar=find_child("MainMana",true,false)
 mana_bar.mouse_filter=Control.MOUSE_FILTER_STOP;mana_bar.tooltip_text="嘴部施法成功率 · "+view.casting.percent+"\n临时魔力优先抵扣法术和卡牌耗魔，不受上限限制；不能存瓶或购物，本场结束清空。"
 if include_tools: preload("res://ui/mana_flask.gd").build(self)
 if not has_turn_controls: return
 var orb=bar.medallion()
 orb.tooltip_text="能量上限：%d。每回合恢复至上限，再结算额外能量与惩罚。" % view.energy_max
 orb.texture=preload("res://assets/ui/energy-medallion.svg");orb.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;orb.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 var energy=bar.energy_label()
 _style_label(energy,str(view.energy),43,TEXT);energy.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var powers=bar.powers_button()
 _style_button(powers,"能力区 · %d" % view.powers.size(),func():_open_drawer("show_deck","powers"),GOLD)
 powers.add_theme_font_size_override("font_size",15);powers.visible=view.phase=="battle"
 var draw_button=bar.draw_button()
 _style_button(draw_button,"抽牌堆  %d" % view.draw_count,func():_open_drawer("show_deck","draw"))
 draw_button.icon=preload("res://assets/ui/draw-pile.svg");draw_button.add_theme_font_size_override("font_size",16);draw_button.add_theme_constant_override("h_separation",12)
 var discard_button=bar.discard_button()
 _style_button(discard_button,"弃牌堆\n%d" % view.discard_count,func():_open_drawer("show_deck","discard"))
 for c in actions.select("flow"):
  var b=_button(c.label,func(): _submit(c),CYAN if c.payload.kind=="end" else GOLD)
  _place(b,Rect2(1424,735 if c.payload.kind=="end" else 837,155,90 if c.payload.kind=="end" else 38))
  candidate_buttons[c.id]=b
  if c.payload.kind=="end":
   end_button=b;b.name="EndTurnButton";b.add_theme_font_size_override("font_size",24)
 var surrender=actions.find("surrender")
 if not surrender.is_empty():
  var button=_button("确定要投降吗" if surrender_version==view.version else "投降",func():pass,RED)
  button.name="SurrenderButton";button.add_theme_font_size_override("font_size",16)
  button.add_theme_stylebox_override("normal",_style(Color("4a2228"),RED,8))
  button.add_theme_stylebox_override("hover",_style(Color("683039"),RED,8))
  button.add_theme_stylebox_override("pressed",_style(Color("55272e"),RED,8))
  button.add_theme_stylebox_override("focus",_style(Color("683039"),RED,8))
  button.add_theme_stylebox_override("disabled",_style(Color("241417"),Palette.MUTED.darkened(0.6),8))
  button.pressed.connect(func():
   if surrender_version==view.version:
    surrender_version=-1;_submit(surrender)
   else:
    surrender_version=view.version;button.text="确定要投降吗")
  _place(button,Rect2(1424,833,155,44))
 _wall_controls()
 _posture_controls()

func _resource_meter(id: String, rect: Rect2, value: float, maximum: float, color: Color, caption: String="") -> void:
 if caption!="":
  var label=_label(caption,13,color);label.name=id+"Caption"
  _place(label,Rect2(rect.position-Vector2(0,21),Vector2(rect.size.x,19)))
 var bar=_bar(value,maximum,color);bar.name=id
 _place(bar,rect)
 var number_label=_label("%s/%s" % [game.number(value),game.number(maximum)],11 if caption=="" else 13,TEXT)
 if id in ["MainMana","HeroMana"] and view.temporary_mana>0: number_label.text+=" · 临时"+game.number(view.temporary_mana)
 number_label.name=id+"Value";number_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 number_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 number_label.autowrap_mode=TextServer.AUTOWRAP_OFF;number_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 number_label.add_theme_color_override("font_shadow_color",Color.BLACK)
 number_label.add_theme_constant_override("shadow_offset_x",1);number_label.add_theme_constant_override("shadow_offset_y",1)
 _place(number_label,Rect2(rect.position+Vector2(0,(rect.size.y-22)/2),Vector2(rect.size.x,22)))

func _wall_controls() -> void:
 var choices=actions.select("wall_move",{"direction":"toward"})
 if choices.is_empty(): return
 var c=choices[0]
 var text="向墙移动 · %d格 / %d能量" % [c.payload.distance,c.cost] if c.payload.distance>0 else "向墙移动 · 距墙0格"
 if c.payload.distance>0 and not c.valid: text+="\n"+c.reason
 var btn=_button(text,func():_submit(c),GOLD)
 btn.name="WallMove_toward";btn.disabled=not c.valid
 btn.add_theme_font_size_override("font_size",13)
 btn.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 btn.tooltip_text=c.detail if c.valid else c.reason
 var placement=_posture_layout(actions.select("posture").filter(func(action):return action.payload.adjacent and not action.payload.wall).size())
 if placement.with_move:
  btn.custom_minimum_size.y=placement.stride-4
  for state_name in ["normal","hover","pressed","focus","disabled"]:
   var style=btn.get_theme_stylebox(state_name).duplicate()
   style.content_margin_top=2;style.content_margin_bottom=2
   btn.add_theme_stylebox_override(state_name,style)
 _place(btn,Rect2(1330,placement.top if placement.with_move else 493,249,placement.stride-4 if placement.with_move else 47))
 candidate_buttons[c.id]=btn

func _body_at(slot: String) -> Dictionary:
 for body in view.body_groups:
  if body.id==slot or slot in body.slots: return body
 return view.body_groups[0]

func _body_card_actions(slot: String, uid: String) -> Array:
 var body=_body_at(slot)
 var choices=actions.select("card",{"uid":uid}).filter(func(c):return c.payload.slot in body.slots or (body.id=="neck" and body.targets.has(c.payload.target)))
 var seen={};var unique=[]
 for c in choices:
  # Merged hand/foot groups must show a shared physical piece only once.
  var key=(c.payload.target if c.payload.target!="" or body.id=="neck" else c.payload.slot)+str(c.payload.free)
  if not seen.has(key):
   seen[key]=unique.size();unique.append(c)
  elif c.valid and not unique[seen[key]].valid:
   unique[seen[key]]=c
 return unique

func _body_drawer() -> void:
 var drawer=BodyDrawerScene.instantiate()
 var panel=drawer.panel()
 panel.add_theme_stylebox_override("panel",Palette.window_frame())
 var portrait=drawer.portrait()
 portrait.name="EquipmentPortrait"
 portrait.configure(view,display_settings.fixed_hero_portrait)
 drawer.divider().color=GOLD.darkened(0.65)
 # The portrait subscribes and aligns in _ready, so it must be configured before the drawer enters the tree.
 _place(drawer,Rect2(0,0,1600,900))
 var canvas=drawer.canvas()
 _place(_label("身体与拘束具",21,GOLD),Rect2(0,0,306,30),canvas)
 var index=0
 for body in view.body_groups:
  var slot_selected=show_body and body.id==_body_at(selected_slot).id
  var b=_button(body.name+("  "+str(body.count) if body.occupied else "")+("·链" if not body.links.is_empty() else ""),func():
   show_body=not show_body if _body_at(selected_slot).id==body.id else true
   selected_slot=body.id; selected_candidate=""; player_pick=false
   render(view),CYAN if slot_selected else (GOLD if body.occupied else MUTED.darkened(0.5)),true)
  b.tooltip_text=body.name+(" · %d件" % body.count if body.occupied else " · 自由")
  for state_name in ["normal","hover","pressed","focus","disabled"]:
   b.add_theme_stylebox_override(state_name,Palette.slot_style(state_name,slot_selected,body.can_release))
  if body.can_release: b.tooltip_text+=" · 可一键解除"
  b.set_meta("can_release",body.can_release)
  b.name="BodySlot_"+body.id;b.custom_minimum_size=Vector2(120,29)
  b.accepted_kind="any"
  b.add_theme_font_size_override("font_size",12)
  b.hover_card=func(data):
   _show_drop_targets(body.id,data)
  b.accept_card=func(data):
   var c=_free_player_candidate(data,body.id)
   return not c.is_empty() and c.valid
  b.receive_card=func(data):
   var c=_free_player_candidate(data,body.id)
   if not c.is_empty() and c.valid: call_deferred("_submit",c,int(data.version))
  _place(b,Rect2(186,34+index*32,120,29),canvas);body_buttons[body.id]=b
  for alias in body.slots: body_buttons[alias]=b
  index+=1
 if not _selecting_hand() and (show_body or selected_card!="" or view.pending_retain): _body_details()

func _body_equipment_entries(body: Dictionary) -> Dictionary:
 var entries={}
 for section in body.sections:
  for e in section.equipment:
   if not entries.has(e.id): entries[e.id]={"equipment":e,"locations":[]}
   entries[e.id].locations.append(section.name)
 return entries

func _single_body_card_action(slot: String, uid: String) -> Dictionary:
 var entries=_body_equipment_entries(_body_at(slot))
 if entries.size()!=1: return {}
 var choices=_body_card_actions(slot,uid).filter(func(c):return c.payload.free==card_faces.get(uid,false))
 if choices.size()!=1 or not entries.has(choices[0].payload.target): return {}
 return choices[0]

func _single_restraint_card_action(uid: String) -> Dictionary:
 var entries={}
 for body in view.body_groups:
  entries.merge(_body_equipment_entries(body))
 if entries.size()!=1: return {}
 var target=entries.keys()[0]
 var fields={"uid":uid,"free":card_faces.get(uid,false)}
 var choices=actions.select("card",fields).filter(func(c):return c.payload.get("target","")!="")
 # A capture bar or any other explicit target still requires player choice.
 if choices.is_empty() or choices.any(func(c):return c.payload.target!=target): return {}
 fields.target=target
 return actions.first_usable("card",fields)

func _over_body_slot(point: Vector2) -> bool:
 for button in body_buttons.values():
  if is_instance_valid(button) and button.get_global_rect().has_point(point): return true
 return false

# Any click outside the part panel and outside the part slots dismisses the panel.
# The click is never swallowed, so it still reaches whatever sits underneath, and the
# slot styles are refreshed in place because mouse-down must not rebuild the tree
# (that would cancel the click, or an in-flight drag).
func _dismiss_body_details_outside(point: Vector2) -> void:
 if not show_body or selected_card!="" or _selecting_hand(): return
 if _over_body_slot(point): return
 var details=layout.find_child("EquipmentDetails",true,false) if is_instance_valid(layout) else null
 if details!=null and details.get_global_rect().has_point(point): return
 show_body=false
 _remove_local_panel("EquipmentDetails")
 for body in view.body_groups:
  var button=body_buttons.get(body.id)
  if button==null: continue
  for state_name in ["normal","hover","pressed","focus","disabled"]:
   button.add_theme_stylebox_override(state_name,Palette.slot_style(state_name,false,body.can_release))

func _body_details() -> void:
 var panel=_panel(Rect2(364,132,388,402));panel.name="EquipmentDetails";panel.z_index=180
 var v=VBoxContainer.new();v.add_theme_constant_override("separation",8);panel.add_child(v)
 var heading=HBoxContainer.new();v.add_child(heading)
 var title=_label("部位装备",20,GOLD);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
 var book=_button("教程",func():_open_tutorial("equipment"),CYAN);book.name="EquipmentTutorial";heading.add_child(book)
 var close=_button("关闭 ×",func():show_body=false;selected_card="";selected_candidate="";player_pick=false;render(view),MUTED)
 close.name="CloseEquipmentDetails";heading.add_child(close)
 var content=_scroll(v)
 if view.pending_retain:
  content.add_child(_label("还可保留%d张，保留至下回合结束" % view.retain_left,16,CYAN))
  for c in actions.select("retain"): _action_row(content,c)
 elif selected_card!="" and view.hand.any(func(c):return c.uid==selected_card):
  var card=view.hand.filter(func(c):return c.uid==selected_card)[0]
  content.add_child(_label(card.name,22,CYAN))
  var bind_action=actions.find("card",{"uid":selected_card,"target":"guard_bind","free":card_faces.get(selected_card,false)})
  if not bind_action.is_empty():
   _card_target(content,bind_action)
   content.add_child(HSeparator.new())
  var choices=_body_card_actions(selected_slot,selected_card)
  var single=_single_body_card_action(selected_slot,selected_card)
  if not single.is_empty(): selected_candidate=single.id
  for c in choices:
   if c.payload.free==card_faces.get(selected_card,false): _card_target(content,c,not single.is_empty())
   elif not choices.any(func(other):return other.payload.free==card_faces.get(selected_card,false)): content.add_child(_label("请右键切换到"+card.face_names["free" if c.payload.free else "bound"]+"。",14,RED))
 else:
  var body=_body_at(selected_slot)
  content.add_child(_label(body.name+(" · 自由" if body.equipment.is_empty() else " · 装备"),16,CYAN))
  if body.equipment.is_empty(): content.add_child(_label("该部位自由。",14,MUTED))
  var grid=_equipment_grid(content)
  var entries=_body_equipment_entries(body)
  var empty=[]
  for section in body.sections:
   if section.equipment.is_empty(): empty.append(section.name)
  for entry in entries.values(): _equipment_tile(grid,entry.equipment,"、".join(entry.locations),entries.size()==1)
  if not empty.is_empty(): content.add_child(_label("空位："+"、".join(empty),12,MUTED))
  if view.phase=="rest": content.add_child(_label("休息房只能使用卡牌拘束效果。",13,CYAN))

func _equipment_grid(parent: Node) -> GridContainer:
 var grid=GridContainer.new();grid.columns=1
 grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 grid.add_theme_constant_override("h_separation",8)
 grid.add_theme_constant_override("v_separation",8)
 parent.add_child(grid)
 grid.resized.connect(func():grid.columns=maxi(1,mini(grid.get_child_count(),int((grid.size.x+8)/166))))
 return grid

# Shared presentation only: each card retains its projected physical target.
func _equipment_tile(parent: Node, e: Dictionary, location: String="", expanded: bool=false) -> void:
 var card=EquipmentTileScene.instantiate();card.name="EquipmentCard_"+e.id
 card.set_meta("equipment_id",e.id)
 card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 card.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 card.custom_minimum_size=Vector2(158,158)
 var accent=RED if e.tier==3 else (CYAN if e.linked else GOLD)
 card.add_theme_stylebox_override("panel",_style(Color("192a38"),accent.darkened(0.35),10))
 parent.add_child(card)
 var box=card.box();box.add_theme_constant_override("separation",5)
 _equipment_card_face(box,e,location,accent)
 for c in actions.select("manual",{"target":e.id}):
  if c.valid and c.payload.after==0.0:
   var release=_button("一键解除 · %d能量" % c.cost,func():_submit(c),CYAN)
   release.name="QuickRelease_"+e.id
   box.add_child(release);candidate_buttons[c.id]=release
 var details=VBoxContainer.new();details.name="EquipmentActions";details.visible=expanded
 var toggle=_button("收起详情 −" if expanded else "查看详情 ＋",func():pass,MUTED)
 toggle.pressed.connect(func():
  details.visible=not details.visible
  toggle.text="收起详情 −" if details.visible else "查看详情 ＋")
 toggle.name="EquipmentCardDetailsToggle";toggle.custom_minimum_size.y=26
 toggle.add_theme_font_size_override("font_size",12);box.add_child(toggle)
 box.add_child(details);details.add_child(_label(e.description,12,TEXT))
 for c in actions.select("attack",{"target":e.id}):
  _action_row(details,c)
  candidate_buttons[c.id].name="EquipmentSpell_"+e.id
 for c in actions.select("manual",{"target":e.id}):
  if not c.valid or c.payload.after!=0.0: _action_row(details,c)

func _equipment_card_face(box: Node,e: Dictionary,location: String,accent: Color,compact: bool=false) -> void:
 if location!="": box.add_child(_label(location,12,CYAN))
 var name_label=_label(e.name,14,GOLD);name_label.custom_minimum_size.y=0 if compact else 36;box.add_child(name_label)
 box.add_child(_label(e.material_name,11,MUTED))
 box.add_child(_label("耐久 %s / %s" % [game.number(e.durability),game.number(e.maximum)],12,TEXT))
 var meter=_bar(e.durability,e.maximum,accent);meter.custom_minimum_size.y=6;box.add_child(meter)
 var tightness=HBoxContainer.new();box.add_child(tightness)
 var tier_label=_label("紧度 %d档" % e.tier,12,accent)
 tier_label.autowrap_mode=TextServer.AUTOWRAP_OFF
 tightness.add_child(tier_label)
 _equipment_lock(tightness,e.locked,e.id,e.lockable)
 if e.linked: box.add_child(_label("共享耐久",12,CYAN))
 if e.card_status!="": box.add_child(_label(e.card_status,12,CYAN))

func _equipment_lock(parent: Node, locked: bool, id: String, lockable: bool) -> void:
 var icon=preload("res://ui/equipment_lock.gd").new()
 icon.name="EquipmentLock_"+id;icon.locked=locked;icon.lockable=lockable
 parent.add_child(icon)

func _action_row(parent: Node,c: Dictionary,label: String="") -> void:
 if c.payload.kind=="retain":
  var choices=view.hand.filter(func(card):return card.uid==c.payload.uid)
  if not choices.is_empty():
   var face=_display_card(choices[0].type,parent,func():_submit(c),"retain_"+c.payload.uid)
   face.disabled=not c.valid;candidate_buttons[c.id]=face
   return
 var fee=str(c.cost)+"能量"+(" / "+game.number(c.mana)+"魔力" if c.mana>0 else "")
 if c.payload.kind=="service": fee=game.number(c.mana)+("魔瓶魔力" if c.payload.get("payment","")=="flask" else "魔力") if c.mana>0 else "免费"
 var targeted=DragTargets.targeted(c)
 var b=_button((c.label if label.is_empty() else label)+("" if c.group in ["route","reward","rest_service","service_flow","demo_exit"] else " · "+fee),func(): _submit(c),RED if c.risk!="" else GOLD,targeted)
 if targeted: DragTargets.source(self,b,c)
 b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 b.disabled=not c.valid
 parent.add_child(b); candidate_buttons[c.id]=b
 parent.add_child(_label(c.detail if c.valid else c.reason,14,MUTED if c.valid else RED))
 if c.risk!="" and c.valid: parent.add_child(_label(c.risk,13,RED))

func _card_target(parent: Node,c: Dictionary, automatic: bool=false) -> void:
 if automatic:
  parent.add_child(_label(c.label,16,CYAN if c.valid else MUTED))
 else:
  var b=_button(c.label,func(): selected_candidate=c.id; render(view),CYAN)
  b.name="CardTarget_"+c.payload.target;b.disabled=not c.valid
  DragTargets.focus(self,b,c.valid)
  parent.add_child(b)
 if not c.valid: parent.add_child(_label(c.reason,14,RED))
 elif c.risk!="": parent.add_child(_label(c.risk,14,RED))
 if selected_candidate==c.id and c.valid:
  parent.add_child(_label(c.detail,15,TEXT))
  var fee=str(c.cost)+"能量"+(" / "+game.number(c.mana)+"魔力" if c.mana>0 else "")
  var commit=_button("打出 · "+fee,func(): _submit(c),CYAN)
  commit.name="PlaySelectedCard"
  parent.add_child(commit); candidate_buttons[c.id]=commit

func _rewards() -> void:
 var screen=RewardScene.instantiate()
 _place(screen,Rect2(0,0,1600,900))
 screen_parent=screen.frame()
 preload("res://ui/reward_screen.gd").build(self)

func _practice_screen() -> void:
 var screen=PracticeScene.instantiate()
 _place(screen,Rect2(0,0,1600,900))
 var panel=screen.panel();panel.add_theme_stylebox_override("panel",Palette.window_frame())
 var v=screen.column(); v.add_theme_constant_override("separation",20)
 v.add_child(_label("装备练习结束" if view.phase=="cleared" else "装备练习",28,GOLD))
 v.add_child(_label(view.practice_description,19))
 v.add_child(_label(view.practice_hint,18,CYAN))
 if view.phase=="pack":
  v.add_child(_label("随身道具超出容量，请先在道具栏使用或放下多余工具。",18,RED))
  for c in actions.select("flow"): _action_row(v,c)
 elif view.phase=="rest": v.add_child(_button("返回练习",func(): show_route=false; render(view),CYAN))
 if view.phase=="cleared":
  v.add_child(_button("再次练习",func(): restart(view.seed,true,view.practice_kind)))
  v.add_child(_button("从入口开始塔路",func(): restart(view.seed)))
 v.add_child(_label(view.summary,16,MUTED))

func _capture_screen() -> void:
 var screen=CaptureScene.instantiate()
 _place(screen,Rect2(0,0,1600,900))
 var panel=screen.panel();panel.add_theme_stylebox_override("panel",Palette.window_frame())
 var v=screen.column(); v.add_theme_constant_override("separation",17)
 v.add_child(_label("收押完成",29,RED))
 v.add_child(_label(view.capture.by+"将你送入监狱。当前警戒度：%d。" % view.security,21))
 v.add_child(_label("本级追加："+view.prison.equipment_rule+"；"+view.prison.toy_rule,18,GOLD))
 v.add_child(_label("原有装备、锁、链接、卡组、遗物、魔力和快感保留；本次没有战后恢复或卡牌奖励。",18,CYAN))
 v.add_child(_label("没收%d件道具，清除临时增益。追加%d件装备、%d条链接、%d/2件性玩具。" % [view.capture.confiscated,view.capture.added.size(),view.capture.links.size(),view.capture.special_added.size()],18))
 v.add_child(_label("五级将移入高安全监室，补齐高级三档装备，本局结束。" if view.security==5 else "可在左侧检查装备，然后进入牢房，开始探索与逃脱。",18,GOLD))
 for c in actions.select("prison"): _action_row(v,c)
 if view.practice:
  v.add_child(_button("再次挑战同一组魅魔警卫",func(): restart(view.seed,true,view.practice_kind),CYAN))
 else:
  v.add_child(_button("重新开始塔路",func(): restart(view.seed),CYAN))
 v.add_child(_button("选择其他练习",func():_open_drawer("show_settings")))

func _inspection_screen() -> void:
 var screen=InspectionScene.instantiate()
 _place(screen,Rect2(0,0,1600,900))
 var panel=screen.panel();panel.add_theme_stylebox_override("panel",Palette.window_frame())
 var v=screen.column(); v.add_theme_constant_override("separation",18)
 if view.phase=="pack":
  v.add_child(_label("整理随身道具",29,GOLD))
  v.add_child(_label("反抗战后的整备结束。先使用或放弃超出容量的工具，再返回牢房；巡视继续暂停。",20))
  v.add_child(_button("打开道具栏",func():_open_drawer("show_items"),CYAN))
  for c in actions.select("flow"): _action_row(v,c)
  return
 if view.phase=="prison_end":
  v.add_child(_label("本次逃脱失败",29,RED))
  v.add_child(_label("监狱警戒度已经达到5，普通逃脱流程结束。",21))
  v.add_child(_label(view.prison.terminal_text,18,GOLD))
  v.add_child(_label("可在左侧查看最终装备；选择重新开始会替换本局进度。",17,MUTED))
  v.add_child(_button("重新开始一局",func(): restart(view.seed),CYAN))
  return
 var p=view.prison
 v.add_child(_label({"arrival":"狱警来到门前","result":"检查结果","done":"检查完成"}[p.stage],29,GOLD))
 v.add_child(_label("已完成%d次检查 · 警戒度%d" % [p.checks,view.security],18,CYAN))
 v.add_child(_label("可以接受检查，或现在反抗；反抗会与魅魔警卫战斗。" if p.stage=="arrival" else p.report,20))
 v.add_child(_label("巡视中：仅可检查或反抗。",16,MUTED))
 for c in actions.select("prison"): _action_row(v,c)

func _prison_controls() -> void:
 var p=view.prison
 var panel=_panel(Rect2(803,155,735,337));panel.name="PrisonControls"
 var v=VBoxContainer.new();v.add_theme_constant_override("separation",8);panel.add_child(v)
 var heading=HBoxContainer.new();v.add_child(heading)
 var title=_label("巡视暂停" if p.paused else "巡视剩余 %d 回合" % p.left,20,GOLD)
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
 var remaining=_label("待探索 %d" % p.remaining,16,MUTED);remaining.name="PrisonRemaining";remaining.autowrap_mode=TextServer.AUTOWRAP_OFF;heading.add_child(remaining)
 var selected=p.space.sites.filter(func(site):return site.id==prison_detail and not site.interaction.is_empty())
 if not selected.is_empty():
  _prison_location_details(v,selected[0]);return
 prison_detail=""
 if view.pending_retain: v.add_child(_label("先选好要保留的手牌，再继续探索。",15,CYAN))
 var info="最多%d格 · %d能量 / 次" % [p.space.stride,p.space.cost]
 if p.space.fall.chance>0: info+=" · 摔倒率 %s%%" % str(snappedf(p.space.fall.chance*100,0.1))
 v.add_child(_label(info,15,CYAN))
 var scroll=_scroll(v);scroll.name="PrisonExploration"
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",8);scroll.add_child(grid)
 var locations=p.space.sites.filter(func(site):return site.has("installed"))+p.space.sites.filter(func(site):return not site.has("installed"))
 for site in locations:
  var tile=PrisonSiteScene.instantiate();tile.name="PrisonSite_"+site.id
  tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  tile.add_theme_stylebox_override("panel",_style(Color("192a38"),CYAN if site.here or (p.space.blind and site.near) else GOLD.darkened(0.5),8));grid.add_child(tile)
  var box=tile.box();box.add_theme_constant_override("separation",4)
  var name_label=_label(site.label+(" · 当前" if site.here else ""),16,CYAN if site.here or (p.space.blind and site.near) else GOLD);box.add_child(name_label)
  if not p.space.blind:
   box.add_child(_label("%s · %s" % [site.bearing,"靠墙" if site.wall_distance==0 else "离墙%d格" % site.wall_distance],13,MUTED))
   box.add_child(_prison_distance_meter(site))
  elif site.near: box.add_child(_label("两格以内",13,CYAN))
  if site.has("installed"): box.add_child(_label("%s · 剩余%d次" % [site.installed.mount,site.installed.uses],13,CYAN))
  var row=HBoxContainer.new();box.add_child(row)
  if not p.space.blind and not site.here:
   var c=actions.find("prison",{"action":"explore","site":site.id})
   if not c.is_empty():
    var go=_button("前往",func():_submit(c),CYAN);go.disabled=not c.valid;go.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(go);candidate_buttons[c.id]=go
  if not site.interaction.is_empty():
   var inspect=_button("查看 ›",func():prison_detail=site.id;render(view),GOLD)
   inspect.name="InspectPrison_"+site.id;inspect.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(inspect)
  if site.get("wall_warning","")!="": box.add_child(_label(site.wall_warning,13,RED))
 if p.space.blind:
  var directions=GridContainer.new();directions.columns=2;scroll.add_child(directions)
  for c in actions.select("prison",{"action":"explore"}):
   var choice=VBoxContainer.new();choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL;directions.add_child(choice)
   var b=_button(c.label,func():_submit(c),CYAN);b.disabled=not c.valid;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choice.add_child(b);candidate_buttons[c.id]=b
   if c.payload.wall_warning!="": choice.add_child(_label(c.payload.wall_warning,13,RED))
 # Common movement limitations appear once, instead of after every destination.
 var reasons=[]
 for c in actions.select("prison",{"action":"explore"}):
  if not c.valid and c.reason!="已经在这里。" and c.reason not in reasons: reasons.append(c.reason)
 if not reasons.is_empty(): v.add_child(_label("\n".join(reasons),13,RED))

func _prison_distance_meter(site: Dictionary) -> Control:
 var meter=PanelContainer.new();meter.name="PrisonDistance_"+site.id
 meter.custom_minimum_size.y=22;meter.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 var scale=maxi(1,maxi(site.distance,site.initial_distance))
 # The red layer is exposed only beyond the original distance; both share one scale.
 var overflow=_bar(site.distance,scale,RED);overflow.custom_minimum_size.y=22;overflow.name="Overflow";meter.add_child(overflow)
 var normal=_bar(mini(site.distance,site.initial_distance),scale,CYAN);normal.custom_minimum_size.y=22;normal.name="Normal"
 normal.add_theme_stylebox_override("background",StyleBoxEmpty.new());meter.add_child(normal)
 var text=_label("当前%d格 · 初始%d格" % [site.distance,site.initial_distance],12,TEXT)
 text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;text.autowrap_mode=TextServer.AUTOWRAP_OFF
 # An opaque text outline keeps small numbers legible over either fill colour.
 text.add_theme_color_override("font_outline_color",Color("111820"));text.add_theme_constant_override("outline_size",4)
 meter.add_child(text);_ignore_mouse(meter)
 return meter

func _prison_location_details(parent: Node,site: Dictionary) -> void:
 var heading=HBoxContainer.new();parent.add_child(heading)
 var back=_button("‹ 返回地点",func():prison_detail="";render(view),MUTED);back.name="PrisonDetailsBack";heading.add_child(back)
 var location_title=_label(site.label,20,GOLD);location_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(location_title)
 var scroll=_scroll(parent);scroll.name="PrisonLocationDetails"
 var kind=site.interaction.kind
 var installed=kind=="item" and view.items.any(func(i):return i.id==site.interaction.item and i.installed)
 if not site.get("installation_points",[]).is_empty():
  var points=site.installation_points.map(func(point):return point.short_label+" · "+("空闲" if point.occupant=="" else "已占用"))
  scroll.add_child(_label("   /   ".join(points),13,CYAN))
  if not installed:
   var carry=view.items.filter(func(i):return not i.installed and not actions.select("item",{"item":i.id}).filter(func(c):return c.payload.kind=="item_install").is_empty())
   if not carry.is_empty():
    if not carry.any(func(i):return i.id==selected_item): selected_item=carry[0].id
   var picker=OptionButton.new();picker.name="WallToolPicker"
   for item in carry:
    picker.add_item(item.name)
    if item.id==selected_item: picker.select(picker.item_count-1)
   picker.item_selected.connect(func(index):selected_item=carry[index].id;render(view));scroll.add_child(picker)
   for c in actions.select("item",{"kind":"item_install","item":selected_item}): _compact_action(scroll,c)
 if kind=="door":
  var door=_button("牢门 · "+("已打开" if view.prison.door_open else "上锁"),func():pass,CYAN,true)
  door.hover_card=func(data):
   var c=_door_candidate(data)
   _drag_rejection(door,"需要开锁牌的拘束面。" if c.is_empty() else ("" if c.valid else c.reason))
  door.accept_card=func(data):
   var c=_door_candidate(data)
   return not c.is_empty() and c.valid
  door.receive_card=func(data):
   var c=_door_candidate(data)
   if not c.is_empty() and c.valid: call_deferred("_submit",c,int(data.version))
  scroll.add_child(door);actor_targets["prison_door"]=door
 elif kind=="vent": scroll.add_child(_label("格栅 %d / %d" % [view.prison.vent_hits,view.prison.vent_total],18,CYAN))
 if installed:
  var item=view.items.filter(func(i):return i.id==site.interaction.item)[0]
  scroll.add_child(_label(item.contact_text,13,CYAN))
  scroll.add_child(_label(item.passive_text,15,CYAN))
 var selected_actions=[]
 for c in view.candidates:
  var matches=(kind=="door" and ((c.payload.kind=="prison" and c.payload.action in ["key","door_exit","unlock"]) or (c.payload.kind=="item_use" and c.payload.target=="prison_door"))) or (kind=="vent" and c.payload.kind=="prison" and c.payload.action in ["vent_kick","vent_exit"]) or (kind=="item" and c.payload.get("item","")==site.interaction.item)
  if matches and c.payload.kind!="item_install": selected_actions.append(c)
 for c in selected_actions:
  if c.payload.kind!="item_use": _compact_action(scroll,c)
 var targets=selected_actions.filter(func(c):return c.payload.kind=="item_use")
 targets.sort_custom(func(a,b):return a.valid and not b.valid)
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);scroll.add_child(grid)
 for c in targets: _tool_target_card(grid,c)
 if selected_actions.is_empty() and kind=="item": scroll.add_child(_label("这件工具已用完或不在身边。",14,MUTED))

func _compact_action(parent: Node,c: Dictionary,caption: String="",show_free_cost: bool=true) -> void:
 var label=c.label if caption=="" else caption
 if c.cost>0 or show_free_cost: label+=" · %d能量" % c.cost
 if c.mana>0: label+=" · %s魔力" % game.number(c.mana)
 var targeted=DragTargets.targeted(c)
 var button=_button(label,func():_submit(c),CYAN,targeted)
 if targeted: DragTargets.source(self,button,c)
 button.disabled=not c.valid;button.tooltip_text=c.detail if c.valid else c.reason
 parent.add_child(button);candidate_buttons[c.id]=button
 if not c.valid: parent.add_child(_label(c.reason,13,RED))
 elif c.risk!="": parent.add_child(_label(c.risk,13,RED))
 elif c.payload.kind in ["item_install","item_retrieve"]: parent.add_child(_label(c.detail,13,CYAN))

func _tool_target_card(parent: Node,c: Dictionary) -> void:
 var equipment={}
 for body in view.body_groups:
  if body.targets.has(c.payload.target):
   equipment=body.targets[c.payload.target];break
 if equipment.is_empty():
  var fallback=VBoxContainer.new();fallback.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(fallback)
  _action_row(fallback,c);return
 var panel=PanelContainer.new();panel.name="ToolTarget_"+c.payload.target;panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 panel.add_theme_stylebox_override("panel",_style(Color("192a38"),CYAN if c.valid else MUTED,8));parent.add_child(panel)
 var box=VBoxContainer.new();panel.add_child(box)
 _compact_action(box,c,"使用工具 · 1次")
 _equipment_card_face(box,equipment,equipment.get("position_text",""),CYAN if c.valid else MUTED,true)
 if c.valid: box.add_child(_label(c.detail,13,CYAN))

func _door_candidate(data: Dictionary) -> Dictionary:
 if data.get("version",-1)!=view.version or data.get("free",true): return {}
 return actions.first_usable("prison",{"action":"unlock","uid":data.get("card_uid","")})

func _route_screen() -> void:
 var current=view.route.filter(func(r):return r.current)[0].id
 if map_current_room!=current:
  map_current_room=current; map_scroll_value=-1; route_focus=current
 if not view.route.any(func(r):return r.id==route_focus): route_focus=current
 var screen=RouteScene.instantiate()
 _place(screen,Rect2(0,0,1600,900))
 var panel=screen.panel();panel.add_theme_stylebox_override("panel",Palette.window_frame())
 var row=screen.row();row.add_theme_constant_override("separation",12)
 var map_column=screen.map_column();map_column.add_theme_constant_override("separation",4)
 var relic_strip=layout.find_child("RelicStrip",true,false)
 if relic_strip!=null:
  relic_strip.reparent(map_column)
  map_column.move_child(relic_strip,0)
  relic_strip.custom_minimum_size=Vector2(0,48)
  relic_strip.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  relic_strip.position=Vector2.ZERO
 var scroll=screen.map_scroll()
 var graph=RouteMap.new(); graph.name="TowerRoute"
 graph.region_name=view.map_name
 graph.rooms=view.route; graph.selected=route_focus
 var drawing_key=view.map_name+str(view.seed)+JSON.stringify(view.route.map(func(room):return [room.id,room.floor,room.lane,room.paths.map(func(path):return path.to)]))
 if not map_drawings.has(drawing_key): map_drawings[drawing_key]=[]
 graph.strokes=map_drawings[drawing_key]
 graph.compact=map_overview
 var floors=1
 for room in view.route: floors=maxi(floors,room.floor)
 graph.custom_minimum_size=Vector2(710,620 if map_overview else 170+floors*132)
 graph.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 graph.size_flags_vertical=Control.SIZE_EXPAND_FILL
 graph.room_selected.connect(_select_route_room)
 scroll.add_child(graph)
 graph.set_process_input(not DRAWERS.any(func(field):return get(field)))
 _restore_map_scroll.call_deferred(scroll,graph,map_scroll_value)
 # Map nodes are the existing departure controls, with the same candidate/version checks.
 for c in actions.select("route",{"kind":"depart"}):
  candidate_buttons[c.id]=graph.buttons[c.payload.room]
 var right=screen.messages()
 right.add_child(_label("移动消息",20,GOLD))
 if view.phase=="travel":
  right.add_child(_label("%s · %d / %d回合" % [view.journey.mode,view.journey.total-view.journey.remaining,view.journey.total],14,CYAN))
  right.add_child(_bar(view.journey.total-view.journey.remaining,view.journey.total,CYAN))
 elif actions.select("route",{"kind":"depart"}).any(func(c):return c.valid): right.add_child(_label("%s · 每段%d回合" % [view.movement.mode,view.movement.turns],14,CYAN))
 elif view.phase=="cleared": right.add_child(_label("当前阶段完成",20,CYAN))
 var content=_scroll(right)
 var messages=content.get_parent() as ScrollContainer
 messages.name="TravelMessageScroll"
 for entry in view.travel_log:
  if entry.turn>=0: content.add_child(_label("移动 · 第%d回合" % entry.turn,13,CYAN))
  content.add_child(_label(entry.text,16,TEXT))
 var offset=-1 if travel_log_count!=view.travel_log.size() else travel_log_scroll
 travel_log_count=view.travel_log.size()
 _restore_travel_messages.call_deferred(messages,offset)
 if notice!="": right.add_child(_label(notice,14,MUTED))
 if view.phase=="travel":
  var step=actions.find("route",{"kind":"travel_step"})
  if not step.is_empty():
   var controls=HBoxContainer.new();right.add_child(controls)
   var advance=_button("前进一回合",func():_submit(step),CYAN)
   advance.name="TravelStep";advance.disabled=not step.valid;controls.add_child(advance);candidate_buttons[step.id]=advance
   if not step.valid: right.add_child(_label(step.reason,14,RED))
   var toggle=_button("暂停" if map_auto_travel else "自动前进",func():map_auto_travel=not map_auto_travel;render(view),CYAN)
   toggle.name="TravelToggle";controls.add_child(toggle)
  _queue_map_step()
 elif view.phase=="pack":
  for c in actions.select("flow"): _action_row(right,c)
 var navigation=GridContainer.new();navigation.columns=2;right.add_child(navigation)
 var overview=_button("详细路线" if map_overview else "地图总览",func():map_overview=not map_overview; map_scroll_value=-1; render(view),CYAN)
 overview.name="MapOverview";navigation.add_child(overview)
 var locate=_button("定位当前",func():map_overview=false;map_scroll_value=-1;route_focus=current;render(view),CYAN)
 locate.name="MapLocate";navigation.add_child(locate)
 var drawing_tools=HBoxContainer.new();right.add_child(drawing_tools)
 var hint=_label("右键绘画",14,MUTED);hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL;drawing_tools.add_child(hint)
 var clear=_button("清除画线",func():graph.clear_strokes(),CYAN)
 clear.name="MapClearDrawing";drawing_tools.add_child(clear)

 for group in right.get_children():
  if group is HBoxContainer or group is GridContainer:
   for control in group.get_children():
    if control is Button:
     control.add_theme_font_size_override("font_size",14)
     control.size_flags_horizontal=Control.SIZE_EXPAND_FILL

func _select_route_room(id: String) -> void:
 route_focus=id
 var candidate=actions.find("route",{"kind":"depart","room":id})
 if not candidate.is_empty() and candidate.valid:
  map_auto_travel=true
  _submit(candidate)
 else:
  var room=view.route.filter(func(r):return r.id==id)
  notice=room[0].entry_reason if not room.is_empty() else ""
  render(view)

func _queue_map_step() -> void:
 if not map_auto_travel or map_step_pending or view.phase!="travel": return
 map_step_pending=true
 var observed_game=game
 var observed_version=view.version
 await get_tree().create_timer(0.45).timeout
 map_step_pending=false
 if not is_inside_tree(): return
 if observed_game!=game:
  _queue_map_step();return
 if not map_auto_travel or view.phase!="travel": return
 if view.version!=observed_version:
  _queue_map_step();return
 var step=actions.find("route",{"kind":"travel_step"})
 if not step.is_empty() and step.valid and not view.pressure.overloaded: _submit(step)
 else: map_auto_travel=false

func _restore_travel_messages(scroll: ScrollContainer, offset: int) -> void:
 await get_tree().process_frame
 if not is_instance_valid(scroll): return
 scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value) if offset<0 else offset
 scroll.get_v_scroll_bar().value_changed.connect(func(value):travel_log_scroll=int(value))

func _restore_map_scroll(scroll: ScrollContainer, graph: Control, offset: int) -> void:
 await get_tree().process_frame
 if not is_instance_valid(scroll) or not is_instance_valid(graph): return
 if offset>=0: scroll.scroll_vertical=offset
 else:
  var room=graph.rooms.filter(func(r):return r.current)[0]
  scroll.scroll_vertical=int(graph.point_for(room).y-scroll.size.y*0.62)
 map_scroll_value=scroll.scroll_vertical
 scroll.get_v_scroll_bar().value_changed.connect(func(value):map_scroll_value=int(value))

func _log_drawer() -> void:
 var v=_drawer_shell("行动记录",Rect2(650,150,870,560))
 var scroll=_scroll(v)
 for i in range(view.logs.size()-1,maxi(-1,view.logs.size()-45),-1):
  var e=view.logs[i]
  scroll.add_child(_label(("计算 · " if e.kind=="mechanical" else "")+e.text,14,MUTED))

func _hide_term() -> void:
 if is_instance_valid(term_popup):
  term_popup.hide()
  term_popup.name="ClosingTermExplanation"
  term_popup.queue_free()
 term_popup=null
 term_anchor=null

func _show_term(anchor: Control, entry: Dictionary) -> void:
 if is_instance_valid(touch_input) and touch_input.finger>=0 and not touch_input.details_allowed: return
 _hide_term()
 term_anchor=anchor
 term_popup=_place(TermPopupScene.instantiate(),Rect2(0,0,0,0))
 term_popup.add_theme_stylebox_override("panel",Palette.window_frame())
 term_popup.z_index=260
 term_popup.set_meta("below",anchor.has_meta("term_below"))
 var column=term_popup.column();column.add_theme_constant_override("separation",10)
 var title_label=term_popup.title_label();title_label.visible=entry.label!=""
 _style_label(title_label,entry.label,19,CYAN)
 var detail_label=term_popup.detail_label();detail_label.visible=entry.detail!=""
 _style_label(detail_label,entry.detail,15,TEXT)
 var text_width=0.0
 for label in column.get_children():
  var font=label.get_theme_font("font")
  var font_size=label.get_theme_font_size("font_size")
  for line in label.text.split("\n"):
   text_width=maxf(text_width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
 column.custom_minimum_size.x=clampf(ceilf(text_width)+2,40,326)
 _ignore_mouse(term_popup)
 term_popup.minimum_size_changed.connect(func():
  if is_instance_valid(anchor): _position_term.call_deferred(anchor.get_global_rect())
  else: _hide_term())
 _position_term.call_deferred(anchor.get_global_rect())

# Hover card for a hotkey slot: every skill of that slot is listed and directly
# releasable, so a form never has to be cycled with right-click first.
func _show_term_slot(anchor: Control, entry: Dictionary, slot_actions: Array) -> void:
 _show_term(anchor,entry)
 if not is_instance_valid(term_popup) or term_anchor!=anchor: return
 var column=term_popup.column()
 var row=VBoxContainer.new();row.name="TermSlotActions"
 row.add_theme_constant_override("separation",4)
 for c in slot_actions:
  var row_text=c.label
  var brief=str(c.get("brief",""))
  var tags=str(c.get("brief_tags",""))
  if c.has("casting"): tags+=(" · " if tags!="" else "")+c.casting.percent
  if brief!="": row_text+=" · "+brief
  elif c.payload.has("damage"): row_text+=" · %s点伤害" % game.number(c.payload.damage)
  if tags!="": row_text+=" · "+tags
  if int(c.cost)>0: row_text+=" · %d能量" % c.cost
  var button=_button(row_text,func():attack_forms[c.payload.type]=int(c.payload.form);_submit(c),CYAN if c.valid else MUTED)
  button.name="TermSlotAction_"+c.payload.type+"_"+str(c.payload.form)
  button.disabled=not c.valid
  button.tooltip_text=c.detail if c.valid else c.reason
  button.add_theme_font_size_override("font_size",14)
  row.add_child(button)
 column.add_child(row)
 # The card itself only observes hover (PASS) so its padding never blocks the
 # battlefield, while its rows still take their own clicks. Leaving the card has to
 # schedule the same grace check as leaving the tile.
 term_popup.mouse_filter=Control.MOUSE_FILTER_PASS
 term_popup.mouse_exited.connect(func():_hide_term_when_away(anchor))
 _position_term.call_deferred(anchor.get_global_rect())

# The hover card is interactive for hotkey slots, so leaving the tile must not close
# it while the pointer is on its way into the card.
func _term_popup_wanted(anchor) -> bool:
 var point=get_viewport().get_mouse_position()
 if is_instance_valid(anchor) and anchor is Control and anchor.get_global_rect().grow(6).has_point(point): return true
 return is_instance_valid(term_popup) and term_popup.get_global_rect().grow(6).has_point(point)

func _hide_term_when_away(anchor: Object) -> void:
 # Grace delay: the pointer has to cross the gap between the tile and the card, and
 # the card is only laid out on the next frame. The anchor may already be freed by a
 # rebuild, so it stays an untyped reference and is validity-checked instead. A timer
 # started by a tile that a rebuild has already replaced belongs to no visible card
 # and must not close the card opened for the replacement anchor.
 await get_tree().create_timer(0.25).timeout
 if anchor!=term_anchor: return
 if not _term_popup_wanted(anchor): _hide_term()

func _position_term(anchor: Rect2) -> void:
 if not is_instance_valid(term_popup): return
 # Sizing the card changes its own minimum size when a label has to wrap, which
 # re-emits minimum_size_changed. Cap the passes so a resize can never become a loop.
 var passes=int(term_popup.get_meta("position_passes",0))
 if passes>=4: return
 term_popup.set_meta("position_passes",passes+1)
 anchor=layout.get_global_transform().affine_inverse()*anchor
 var target=term_popup.get_combined_minimum_size()
 if target!=term_popup.size: term_popup.size=target
 var x=anchor.end.x+12
 var y=clampf(anchor.position.y,74,maxf(74,886-term_popup.size.y))
 if bool(term_popup.get_meta("below",false)):
  x=anchor.position.x+anchor.size.x*0.5-term_popup.size.x*0.5
  y=anchor.end.y+12
  if y+term_popup.size.y>886: y=anchor.position.y-term_popup.size.y-12
 else:
  if is_instance_valid(drop_panel) and is_instance_valid(term_anchor) and drop_panel.is_ancestor_of(term_anchor): x=drop_panel.position.x+drop_panel.size.x+10
  if x+term_popup.size.x>1580: x=anchor.position.x-term_popup.size.x-12
 term_popup.position=Vector2(clampf(x,20,maxf(20,1580-term_popup.size.x)),clampf(y,74,maxf(74,886-term_popup.size.y)))

func _speech_bubble(point_to_hero: bool=true) -> void:
 if view.speech.is_empty(): return
 if not _speech_visible("hero:"+str(view.speech.id)): return
 speech_group=Control.new();speech_group.name="HeroSpeechGroup";speech_group.mouse_filter=Control.MOUSE_FILTER_IGNORE
 speech_group.z_index=20;_place(speech_group,Rect2(0,0,0,0))
 var panel=_panel(Rect2(408,82,300,96));panel.name="HeroSpeech"
 panel.reparent(speech_group)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);panel.add_child(row)
 var portrait=TextureRect.new();portrait.name="HeroSpeechPortrait";portrait.custom_minimum_size=Vector2(50,50)
 var atlas=AtlasTexture.new();atlas.atlas=Arena.Art.HERO_POSES.stand;atlas.region=Arena.Art.HERO_FACE;atlas.filter_clip=true
 portrait.texture=atlas;portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 row.add_child(portrait)
 var body=_label(view.speech.text,15,TEXT);body.name="HeroSpeechText"
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.size_flags_vertical=Control.SIZE_EXPAND_FILL
 body.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(body)
 if point_to_hero:
  var tail=Polygon2D.new();tail.polygon=PackedVector2Array([Vector2(566,177),Vector2(582,177),Vector2(574,192)]);tail.color=Color(0.055,0.09,0.135,0.97);speech_group.add_child(tail)

func _action_sidebar() -> void:
 var shell=ActionSidebarScene.instantiate()
 _place(shell,Rect2(0,0,1600,900))
 var toggle=shell.toggle()
 if view.phase=="shop":
  action_log_panel=null
  shell.panel().visible=false
  _style_button(toggle,"行动日志 ≡",func():_open_drawer("show_log"),GOLD)
  toggle.position=Vector2(570,104);toggle.size=Vector2(138,38)
  action_log_toggle=toggle
  return
 var panel=shell.panel()
 panel.add_theme_stylebox_override("panel",Palette.window_frame())
 panel.position=Vector2(1324,154)
 panel.size=Vector2(252,328 if view.phase!="battle" and not actions.select("wall_move").is_empty() else 382)
 action_log_panel=panel
 shell.column().add_theme_constant_override("separation",12)
 shell.heading().add_theme_constant_override("separation",6)
 _style_label(shell.title(),"行动日志",18,GOLD)
 var pin=shell.pin_button()
 _style_button(pin,"已固定" if action_log_pinned else "固定",_toggle_action_pin,CYAN if action_log_pinned else MUTED)
 pin.add_theme_font_size_override("font_size",12);pin.tooltip_text="固定后，点击其他位置不会收起日志。"
 var close=shell.close_button()
 _style_button(close,"收起",func():action_log_open=false;_sync_action_sidebar(),MUTED)
 close.add_theme_font_size_override("font_size",12)
 var content=shell.content();content.add_theme_constant_override("separation",9)
 if view.action_log.is_empty(): content.add_child(_label("尚无行动记录。",14,MUTED))
 for i in range(view.action_log.size()-1,-1,-1):
  var note=view.action_log[i]
  content.add_child(_label(note.actor+" · 第%d回合" % note.round,13,CYAN))
  content.add_child(_label(note.text,14,TEXT))
  content.add_child(HSeparator.new())
 _style_button(toggle,"行动日志 ≡",func():action_log_open=true;_sync_action_sidebar(),GOLD)
 action_log_toggle=toggle
 _sync_action_sidebar()

func _toggle_action_pin() -> void:
 action_log_pinned=not action_log_pinned
 var button=action_log_panel.find_child("PinActionLog",true,false)
 button.text="已固定" if action_log_pinned else "固定"
 var color=CYAN if action_log_pinned else MUTED
 button.add_theme_stylebox_override("normal",_style(Color("1b2b39"),color.darkened(0.25)))
 button.add_theme_stylebox_override("hover",_style(Color("2b4553"),color))
 button.add_theme_stylebox_override("pressed",_style(Color("24434c"),color))
 button.add_theme_stylebox_override("focus",_style(Color("2b4553"),color))
 button.add_theme_stylebox_override("disabled",_style(Color("141d26"),Palette.MUTED.darkened(0.6)))

func _sync_action_sidebar() -> void:
 if is_instance_valid(action_log_panel): action_log_panel.visible=action_log_open
 if is_instance_valid(action_log_toggle): action_log_toggle.visible=not action_log_open

func _input(event: InputEvent) -> void:
 if is_instance_valid(keyboard_input) and keyboard_input.handle(event):
  get_viewport().set_input_as_handled();return
 if player_pick and event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  _clear_player_picker();selected_card="";render(view);return
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT: _dismiss_speech()
 if (show_tutorial or show_encyclopedia or show_deck or show_event_selection) and event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  _close_drawers();_refresh_drawers();return
 if not event is InputEventMouseButton or not event.pressed or event.button_index not in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]: return
 _dismiss_body_details_outside(event.position)
 if not action_log_open or action_log_pinned or not is_instance_valid(action_log_panel) or not action_log_panel.is_visible_in_tree(): return
 if action_log_panel.get_global_rect().has_point(event.position): return
 # Hide only this panel: rebuilding controls on mouse-down would cancel clicks/drags.
 action_log_open=false
 _sync_action_sidebar()

func _deck_drawer() -> void:
 var powers_only=deck_zone=="powers"
 var cards={"deck":view.deck_cards,"draw":view.draw_cards,"discard":view.discard_cards,"powers":view.powers}[deck_zone]
 var title={"deck":"卡组一览","draw":"抽牌堆","discard":"弃牌堆","powers":"能力区"}[deck_zone]
 var v=_drawer_shell("能力区 · 本场战斗生效" if powers_only else "%s     /     %d张" % [title,cards.size()],Rect2(60,78,1480,780),GOLD)
 var browser=preload("res://ui/deck_browser.gd").new();v.add_child(browser);browser.setup(self,cards,powers_only,title+"为空。")

func _ignore_mouse(node: Node) -> void:
 if node is Control: node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 for child in node.get_children(): _ignore_mouse(child)

func _shop_chatter(pool: Array) -> void:
 if pool.is_empty() or view.phase!="shop": return
 var choices=pool.filter(func(line):return line!=shop_last_chatter)
 if choices.is_empty(): choices=pool
 var line=str(choices[shop_chatter_rng.randi_range(0,choices.size()-1)])
 shop_last_chatter=line
 var bubble=find_child("ShopkeeperSpeech",true,false)
 var body=find_child("ShopkeeperSpeechText",true,false)
 if not is_instance_valid(bubble) or not is_instance_valid(body): return
 body.text=line;bubble.show();speech_group=bubble
 speech_deadline=Time.get_ticks_msec()+5000

func _submit(c: Dictionary, expected_version: int=-1) -> void:
 surrender_version=-1
 if show_home or is_instance_valid(enemy_feedback): return
 if c.valid and c.payload.kind=="card" and c.payload.has("hand_uid") and not c.payload.get("self_target",false) and not _selecting_hand():
  _use_self_card(c,view.version if expected_version<0 else expected_version);return
 var previous=view
 var previous_cards=preload("res://ui/card_motion.gd").positions(self)
 var feedback_anchor=Vector2(560,250)
 if actor_targets.has("hero"):
  var bounds=actor_targets.hero.get_global_rect()
  feedback_anchor=Vector2(bounds.get_center().x,bounds.position.y)
 var result=game.dispatch(c.id,view.version if expected_version<0 else expected_version)
 var updated=game.get_view()
 notice="" if result.ok else result.error
 if result.ok:
  _save_progress()
  if c.payload.kind=="demo_continue": _reset_interface(updated)
  player_pick=false
  selected_card=""; selected_candidate=""; show_body=false
  show_route=false
  if updated.phase!=view.phase:
   _close_drawers()
  if updated.phase=="pack": show_items=true
  if updated.pressure.overloaded:
   # Climax owns the interruption presentation. Never cover it with the
   # general-purpose character-status drawer, even if that drawer was open.
   _close_drawers()
 render(updated)
 if result.ok and c.payload.kind=="demo_end":
  _return_home()
  return
 if result.ok:
  if not is_instance_valid(resource_feedback):
   resource_feedback=preload("res://ui/resource_feedback.gd").new();resource_feedback.host=self;add_child(resource_feedback)
  resource_feedback.enqueue(result.get("resource_feedback",[]),feedback_anchor,["mana","flask_mana"] if c.payload.kind=="flask" else [])
  _animate_cards(result.get("card_feedback",[]),previous_cards)
  card_music.consume(result.get("music_feedback",[]),updated.phase,show_home)
  CombatFeedback.play(self,previous,c.payload)

func _demo_exit_screen() -> void:
 if is_instance_valid(card_motion): card_motion.clear()
 if is_instance_valid(resource_feedback):
  remove_child(resource_feedback);resource_feedback.queue_free();resource_feedback=null
 var screen=DemoExitScene.instantiate()
 _place(screen,Rect2(0,0,1600,900))
 var panel=screen.panel();panel.add_theme_stylebox_override("panel",Palette.window_frame())
 var column=screen.column();column.add_theme_constant_override("separation",24)
 var title=_label("感谢游玩这次demo",36,GOLD);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(title)
 var subtitle=_label("第%s阶段完成" % ["一","二","三"][view.demo_cycle],22,CYAN);subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(subtitle)
 for c in actions.select("demo_exit"):
  _action_row(column,c)
 if view.demo_finished:
  column.add_child(_button("返回菜单",_return_home,CYAN))

func restart(seed_value: int, practice: bool=false, practice_kind: String="equipment") -> void:
 save_suspended=false
 game=game_factory.new(seed_value,practice,practice_kind,true,display_settings.chastity_locks_enabled and not display_settings.fixed_hero_portrait,display_settings.chastity_lock_chance,display_settings.cursed_plate_start)
 var initial=game.get_view()
 _reset_interface(initial)
 _save_progress(true)
 render(initial)
 _animate_cards(initial.hand.map(func(card):return {"kind":"draw","uid":card.uid,"type":card.type}),{})

func _animate_cards(events: Array, before: Dictionary) -> void:
 if events.is_empty(): return
 if not is_instance_valid(card_motion):
  card_motion=preload("res://ui/card_motion.gd").new();card_motion.host=self;add_child(card_motion)
 card_motion.enqueue(events,before)

func _reset_interface(initial: Dictionary) -> void:
 if is_instance_valid(card_music): card_music.stop_music()
 if is_instance_valid(keyboard_input): keyboard_input.clear()
 surrender_version=-1
 speech_id="";speech_deadline=0
 shop_payment="self"
 shop_sidebar_open=false
 shop_performance_seen=""
 shop_last_chatter=""
 show_reward_cards=false;show_reward_relics=false;reward_card_row=""
 attack_forms.clear()
 if is_instance_valid(card_motion):
  card_motion.clear();remove_child(card_motion);card_motion.queue_free();card_motion=null
 if is_instance_valid(resource_feedback):
  remove_child(resource_feedback);resource_feedback.queue_free();resource_feedback=null
 event_read_page=""
 show_home=false;session_started=true
 if is_instance_valid(enemy_feedback): enemy_feedback.finish()
 map_auto_travel=false;travel_log_scroll=-1;travel_log_count=0
 _clear_drop_targets()
 _close_drawers()
 seed_text=str(initial.seed)
 action_log_open=false;action_log_pinned=false
 status_filter="all"
 selected_card=""; selected_candidate=""; selected_slot=initial.practice_focus if initial.practice else "wrist"; selected_enemy=""
 notice=""; show_body=false; show_route=false;prison_detail=""
 card_faces.clear()
 card_draw_serials.clear()
 selected_item=""
 route_focus=""; map_current_room=""; map_scroll_value=-1; map_overview=false
 map_drawings.clear()
 player_pick=false
 player_pick_data={}

func _unhandled_key_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  if DRAWERS.any(func(field):return bool(get(field))):
   _close_drawers();_refresh_drawers();return
  if show_reward_cards or show_reward_relics:
   show_reward_cards=false;show_reward_relics=false;render(view);get_viewport().set_input_as_handled();return
  _close_drawers()
  player_pick=false
  selected_card=""; selected_candidate=""; show_body=false; show_route=false;prison_detail=""
  render(view)

func _clear_drop_targets() -> void:
 if is_instance_valid(drop_panel):
  if is_instance_valid(term_anchor) and drop_panel.is_ancestor_of(term_anchor): _hide_term()
  drop_panel.hide()
  drop_panel.queue_free()
 drop_targets.clear()
 drop_panel=null
 drag_hover_key=""

func modal_region() -> Control:
 var panel=layout.find_child("ShopPaymentPerformance",true,false) if is_instance_valid(layout) else null
 return panel if panel!=null and panel.is_visible_in_tree() and not panel.is_queued_for_deletion() else null

func _notification(what: int) -> void:
 if what==NOTIFICATION_DRAG_BEGIN: _begin_target_drag.call_deferred()
 if what==NOTIFICATION_WM_GO_BACK_REQUEST:
  touch_input.cancel();_hide_term()
  var modal=modal_region()
  if modal!=null:
   modal.find_child("ShopPaymentContinue",true,false).pressed.emit();return
  if player_pick:
   _clear_player_picker();selected_card="";render(view);return
  if DRAWERS.any(func(field):return bool(get(field))):
   _close_drawers();_refresh_drawers();return
  if show_reward_cards or show_reward_relics:
   show_reward_cards=false;show_reward_relics=false;render(view);return
  _open_drawer("show_menu")
 if what==NOTIFICATION_DRAG_END:
  DragTargets.clear(self)
  DragTargets.restore_sources()
  if is_instance_valid(term_popup) and term_popup.has_meta("drag_reason"): _hide_term()
  _clear_drop_targets()
  _refresh_body_details()

func _begin_target_drag() -> void:
 if not get_viewport().gui_is_dragging(): return
 var data=get_viewport().gui_get_drag_data()
 if data is Dictionary: DragTargets.begin(self,data)

func _show_drop_targets(slot: String, data: Dictionary, click_to_use: bool=false) -> void:
 if not body_buttons.has(slot): return
 var body=_body_at(slot)
 var choices=_body_card_actions(slot,data.card_uid) if data.has("card_uid") else DragTargets.equipment_choices(self,data,body)
 if choices.is_empty():
  _clear_drop_targets()
  _remove_local_panel("EquipmentDetails")
  var reason=("这张牌不能用于%s。" if data.has("card_uid") else "该动作不能用于%s。") % body.name
  if data.get("version",-1)!=view.version: reason="行动已失效，请重新选择。"
  _drag_rejection(body_buttons[slot],reason)
  return
 _drag_rejection(body_buttons[slot],"")
 var key=slot+str(data)
 if key==drag_hover_key: return
 _clear_drop_targets()
 _remove_local_panel("EquipmentDetails")
 drag_hover_key=key
 var body_rect=layout.get_global_transform().affine_inverse()*body_buttons[slot].get_global_rect()
 var origin=body_rect.position
 drop_panel=_panel(Rect2(origin.x+body_rect.size.x+3,origin.y,248,100))
 drop_panel.name="EquipmentDropStrip"
 drop_panel.set_meta("body_id",_body_at(slot).id)
 drop_panel.add_theme_stylebox_override("panel",_style(Color("101e29"),GOLD.darkened(0.5),5))
 drop_panel.z_index=220
 var v=VBoxContainer.new(); drop_panel.add_child(v)
 var scroller=_scroll(v)
 var targets=GridContainer.new();targets.columns=3;targets.add_theme_constant_override("h_separation",4);targets.add_theme_constant_override("v_separation",4);scroller.add_child(targets)
 var count=0
 choices.sort_custom(func(a,b):return body.targets.get(a.payload.target,{"sort_order":999}).sort_order<body.targets.get(b.payload.target,{"sort_order":999}).sort_order)
 var columns=3
 targets.columns=columns
 for c in choices:
  var reason=c.reason
  if data.has("card_uid") and c.payload.free!=data.free:
   if choices.any(func(other):return other.payload.free==data.free): continue
   reason="请右键切换到"+view.card_texts[c.payload.type].face_names["free" if c.payload.free else "bound"]+"。"
  if data.version!=view.version: reason="状态已变化，请重新拖牌。"
  var effect=reason
  if reason=="":
   if c.payload.has("preview"):
    var damage_type=preload("res://data/card_rules.gd").damage_type(c.payload.type,c.payload.free) if c.payload.kind=="card" else c.payload.get("damage_type",c.payload.get("mode",""))
    effect="%s点%s伤害" % [game.number(c.payload.preview.damage),{"strain":"挣扎","slip":"滑脱","cut":"切割"}.get(damage_type,"")]
   elif c.payload.has("after"): effect="耐久降至%s" % game.number(c.payload.after)
   elif c.payload.get("free",false): effect=c.detail
   elif c.payload.get("mode","")=="unlock": effect="开锁"
   else: effect=c.detail
   if not c.payload.get("tool_bonus",{}).is_empty(): effect+="\n另加%s点切割伤害" % game.number(c.payload.tool_bonus.damage)
   if c.payload.get("preview",{}).get("release",false): effect+="\n整件脱下"
  var tone=RED if reason!="" or c.risk!="" else CYAN
  var card=EquipmentDropCardScene.instantiate()
  card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  card.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
  var target=card.target_button()
  _style_button(target,"",func():
   if click_to_use and reason=="": _submit(c,int(data.version)),tone)
  target.name="EquipmentDropCard_"+c.payload.target
  target.disabled=click_to_use and reason!=""
  # A blocked entry stays readable on hover but never lights a highlight box.
  if reason!="": target.add_theme_stylebox_override("hover",StyleBoxEmpty.new())
  target.custom_minimum_size=Vector2(76,86);target.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var face=card.face();face.accent=tone
  var title=body.name
  var detail=""
  if c.payload.target!="":
   var equipment=body.targets[c.payload.target]
   face.equipment=equipment
   title=equipment.name
  card.modulate=Color.WHITE if reason=="" else Color(0.48,0.48,0.48,1)
  target.set_meta("target_selectable",reason=="")
  detail+=effect
  if c.risk!="": detail+="\n"+c.risk
  target.set_meta("preview_detail",detail)
  var explain=func():
   if term_anchor!=target: _show_term(target,{"label":title,"detail":detail})
  target.mouse_entered.connect(explain)
  target.mouse_exited.connect(func():
   if term_anchor==target: _hide_term())
  target.hover_card=func(_incoming): explain.call()
  # Keep blocked entries visible and hoverable so their reason remains readable.
  target.accepted_kind="any"
  target.accept_card=func(incoming): return reason=="" and incoming==data and incoming.version==view.version
  target.receive_card=func(incoming): call_deferred("_submit",c,int(incoming.version))
  targets.add_child(card)
  drop_targets[c.id]=target
  count+=1
 var rows=mini(3,maxi(1,ceili(count/float(columns))))
 drop_panel.size=Vector2(mini(columns,maxi(1,count))*80+20+(16 if count>columns*rows else 0),rows*90+16)
 drop_panel.position.y=clampf(origin.y,80,680-drop_panel.size.y)

func _style_actor_drop_area(button: Button, interactive: bool) -> Button:
 for style in ["normal","pressed","focus"]: button.add_theme_stylebox_override(style,StyleBoxEmpty.new())
 button.add_theme_stylebox_override("hover",_style(Color(0.4,0.8,0.8,0.05),Color(0.5,0.85,0.85,0.6),12) if interactive else StyleBoxEmpty.new())
 button.set_meta("idle_interactive",interactive)
 return button

func _actor_drop_area(rect: Rect2, parent: Control=null, interactive: bool=false) -> Button:
 return _place(_style_actor_drop_area(_button("",func(): pass,CYAN,true),interactive),rect,parent)

func _attack_drop_candidate(data: Dictionary, enemy_id: String) -> Dictionary:
 if data.get("version",-1)!=view.version: return {}
 return actions.find("attack",{"type":data.get("action_type",""),"form":data.get("form",0),"enemy":enemy_id})

func _configure_enemy_drop(button: Button, enemy_id: String) -> void:
 button.accepted_kind="attack"
 button.hover_card=func(data):
  var c=_attack_drop_candidate(data,enemy_id)
  _drag_rejection(button,"目标已离场或行动已失效。" if c.is_empty() else ("" if c.valid else c.reason))
 button.accept_card=func(data):
  var c=_attack_drop_candidate(data,enemy_id)
  return not c.is_empty() and c.valid
 button.receive_card=func(data):
  var c=_attack_drop_candidate(data,enemy_id)
  if not c.is_empty() and c.valid: call_deferred("_submit",c,int(data.version))

func _guard_bind_card_candidate(data: Dictionary) -> Dictionary:
 if data.get("version",-1)!=view.version or _card_is_free(data.get("card_uid",""),data.get("free",false)): return {}
 return actions.find("card",{"uid":data.get("card_uid",""),"target":"guard_bind","free":data.get("free",false)})

func _drag_rejection(anchor: Control, reason: String) -> void:
 if reason=="":
  if is_instance_valid(term_popup) and term_popup.has_meta("drag_reason"): _hide_term()
  return
 if is_instance_valid(term_popup) and term_anchor==anchor and term_popup.get_meta("drag_reason","")==reason: return
 _show_term(anchor,{"label":"","detail":reason})
 if not is_instance_valid(term_popup): return
 term_popup.set_meta("drag_reason",reason)
 if not anchor.has_meta("drag_rejection_bound"):
  anchor.set_meta("drag_rejection_bound",true)
  anchor.mouse_exited.connect(func():
   if term_anchor==anchor and is_instance_valid(term_popup) and term_popup.has_meta("drag_reason"): _hide_term())

func _guard_bind_drag_preview(data: Dictionary) -> void:
 var c=_guard_bind_card_candidate(data)
 _drag_rejection(actor_targets.guard_bind,"这张牌不能处理捕缚。" if c.is_empty() else ("" if c.valid else c.reason))

func _activate_guard_bind_target() -> void:
 if selected_card=="": return
 var c=actions.find("card",{"uid":selected_card,"target":"guard_bind","free":card_faces.get(selected_card,false)})
 if not c.is_empty() and c.valid: _submit(c,int(view.version))
 elif not c.is_empty():
  notice=c.reason
  render(view)

func _can_drop_on_player(data: Dictionary) -> bool:
 if data.get("version",-1)!=view.version: return false
 if data.has("self_action_id"):
  var c=actions.by_id.get(data.self_action_id,{})
  return not c.is_empty() and c.group=="posture" and c.valid
 var self_card=actions.find("card",{"uid":data.get("card_uid",""),"self_target":true,"free":data.get("free",false)})
 if not self_card.is_empty(): return self_card.valid
 if _card_is_free(data.get("card_uid",""),data.get("free",false)):
  var c=_free_player_candidate(data)
  return not c.is_empty() and c.valid
 return view.phase in ["battle","prepare","rest","prison"] and view.hand.any(func(c):return c.uid==data.get("card_uid",""))

func _player_drag_preview(data: Dictionary) -> void:
 if active_drag.is_empty(): _clear_drop_targets()
 if data.get("version",-1)!=view.version:
  _drag_rejection(actor_targets.hero,"行动已失效，请重新选择。")
  return
 if data.has("self_action_id"):
  var c=actions.by_id.get(data.self_action_id,{})
  _drag_rejection(actor_targets.hero,"行动已失效，请重新选择。" if c.is_empty() else ("" if c.valid else c.reason))
  return
 var self_card=actions.find("card",{"uid":data.get("card_uid",""),"self_target":true,"free":data.get("free",false)})
 if not self_card.is_empty():
  _drag_rejection(actor_targets.hero,"" if self_card.valid else self_card.reason)
  return
 if _card_is_free(data.get("card_uid",""),data.get("free",false)):
  var c=_free_player_candidate(data)
  _drag_rejection(actor_targets.hero,"没有可用的自由部位。" if c.is_empty() else ("" if c.valid else c.reason))
  return
 _drag_rejection(actor_targets.hero,"")

func _receive_player_drop(data: Dictionary) -> void:
 if not _can_drop_on_player(data): return
 var self_card=actions.find("card",{"uid":data.get("card_uid",""),"self_target":true,"free":data.get("free",false)})
 if not self_card.is_empty():
  _use_self_card(self_card,int(data.version))
  return
 if data.has("self_action_id"):
  _submit(actions.by_id[data.self_action_id],int(data.version))
  return
 if _card_is_free(data.get("card_uid",""),data.get("free",false)):
  _use_free_card(data)
  return
 player_pick_data=data.duplicate(true)
 selected_card=data.card_uid
 card_faces[selected_card]=data.free
 selected_candidate=""
 player_pick=true
 show_log=false; show_deck=false
 render(view)

func _card_is_free(uid: String, second: bool) -> bool:
 for card in view.hand:
  if card.uid==uid: return card.free_faces["free" if second else "bound"]
 return false

func _free_player_candidate(data: Dictionary, slot: String="") -> Dictionary:
 if not _card_is_free(data.get("card_uid",""),data.get("free",false)) or data.get("version",-1)!=view.version: return {}
 var fields={"uid":data.get("card_uid",""),"free":true}
 if slot=="": return actions.first_usable("card",fields)
 var matches=_body_card_actions(slot,data.get("card_uid","")).filter(func(c):return c.payload.free)
 for c in matches:
  if c.valid: return c
 return matches[0] if not matches.is_empty() else {}

func _use_free_card(data: Dictionary) -> void:
 var c=_free_player_candidate(data)
 if not c.is_empty() and c.valid: _submit(c,int(data.version))
 else:
  notice="没有可用的自由部位。" if c.is_empty() else c.reason
  render(view)

func _activate_card(uid: String) -> void:
 if _selecting_hand():
  var choice=_hand_choice(uid)
  if not choice.is_empty(): _submit(choice,int(player_pick_data.version))
  return
 player_pick=false
 var self_card=actions.find("card",{"uid":uid,"self_target":true,"free":card_faces.get(uid,false)})
 if not self_card.is_empty():
  if self_card.valid: _use_self_card(self_card,int(view.version))
  else:
   notice=self_card.reason
   render(view)
  return
 var card=view.hand.filter(func(c):return c.uid==uid)
 if not card.is_empty() and card[0].get("single_face",false):
  notice=card[0].bound
  render(view)
  return
 if _card_is_free(uid,card_faces.get(uid,false)):
  _use_free_card({"card_uid":uid,"free":true,"version":view.version})
  return
 var single=_single_restraint_card_action(uid)
 if not single.is_empty():
  if single.valid:
   _submit(single,int(view.version));return
  selected_slot=single.payload.slot
 selected_card=uid; selected_candidate=""; show_body=true; show_route=false; show_log=false; show_deck=false
 render(view)

func _use_self_card(c: Dictionary, expected_version: int) -> void:
 if not c.payload.has("hand_uid"):
  _submit(c,expected_version);return
 player_pick_data={"card_uid":c.payload.uid,"free":c.payload.free,"version":expected_version,"hand_selection":true,"target":c.payload.target,"slot":c.payload.slot}
 if is_instance_valid(keyboard_input): keyboard_input.clear()
 selected_card=c.payload.uid;selected_candidate="";show_body=false;player_pick=true
 render(view)

func _player_picker() -> void:
 if player_pick_data.get("hand_selection",false):
  _hand_target_picker();return
 var panel=_panel(Rect2(707,180,399,410))
 player_picker_panel=panel
 panel.z_index=215
 var v=VBoxContainer.new(); panel.add_child(v)
 v.add_child(_label("选择部位",22,CYAN))
 var grid=GridContainer.new(); grid.columns=3; v.add_child(grid)
 for body in view.body_groups:
  if body.special and _card_is_free(player_pick_data.card_uid,player_pick_data.free): continue
  var button=_button(body.name+"\n"+("%d件装备" % body.count if body.occupied else "自由"),func():
   selected_slot=body.id
   player_pick=false
   var data=player_pick_data.duplicate(true)
   render(view)
   if _single_body_card_action(body.id,selected_card).is_empty(): _show_drop_targets(body.id,data,true),CYAN)
  var usable=_body_card_actions(body.id,player_pick_data.card_uid).any(func(c):return c.payload.free==player_pick_data.free and c.valid)
  DragTargets.focus(self,button,usable)
  button.custom_minimum_size=Vector2(119,51)
  button.name="PlayerPart_"+body.id
  grid.add_child(button)
 v.add_child(_button("取消",func(): player_pick=false; selected_card=""; render(view)))

func _selecting_hand() -> bool:
 return player_pick and player_pick_data.get("hand_selection",false)

func _hand_choice(uid: String) -> Dictionary:
 return actions.find("card",{"uid":player_pick_data.card_uid,"free":player_pick_data.free,"hand_uid":uid,"target":player_pick_data.target,"slot":player_pick_data.slot})

func _hand_target_picker() -> void:
 var panel=_panel(Rect2(560,564,770,48));panel.name="HandSelectionBar"
 var row=HBoxContainer.new();panel.add_child(row)
 var label=_label("选择一张手牌消耗",19,CYAN);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label)
 var cancel=_button("取消",func():_clear_player_picker();selected_card="";render(view),MUTED)
 cancel.name="HandTargetCancel";cancel.custom_minimum_size=Vector2(90,30);row.add_child(cancel)

func _clear_player_picker() -> void:
 player_pick=false
 if is_instance_valid(player_picker_panel): player_picker_panel.queue_free()

func _rest_controls() -> void:
 var panel=_panel(Rect2(803,166,735,325))
 var v=VBoxContainer.new(); panel.add_child(v)
 v.add_child(_label("墙边挂钩 · 剩余%d / 3次" % view.hook_uses,22,CYAN))
 var button=_button("使用挂钩",func():_open_drawer("show_hook"),CYAN)
 button.name="OpenRestHook"
 v.add_child(button)
 v.add_child(_label("免费 · 紧度－1档",14,MUTED))
 v.add_child(_label("剩余%d回合休息" % view.rest_left,22,GOLD))
 _place(_label("自由效果禁用 · 不自然回魔"+(" · 练习工具已预置" if view.practice else ""),17,CYAN),Rect2(475,551,1020,42))

func _hook_drawer() -> void:
 var v=_drawer_shell(view.hook_location+" · 剩余%d次" % view.hook_uses,Rect2(650,150,870,560))
 var content=_scroll(v)
 content.add_child(_label(view.hook_environment_name+" · "+view.hook_contact,14,CYAN))
 var targets=actions.select("hook")
 for c in targets: _action_row(content,c)
 if targets.is_empty(): content.add_child(_label("当前没有需要处理的装备。",17,MUTED))

func _pressure_drawer() -> void:
 var entries=view.statuses.filter(func(e):return status_filter=="all" or e.category==status_filter)
 var height=clampf(326+ceili(entries.size()/6.0)*72,398,560)
 var v=_drawer_shell("角色状态",Rect2(416,150,1132,height))
 var filters=HBoxContainer.new();filters.add_theme_constant_override("separation",8);v.add_child(filters)
 for spec in [["all","全部"],["body","身体"],["benefit","增益"],["limit","行动限制"],["pressure","快感"],["enemy","敌人"],["environment","环境与房间"]]:
  var tab=_button(spec[1],func():status_filter=spec[0];_refresh_drawers(),CYAN if status_filter==spec[0] else MUTED)
  tab.toggle_mode=true;tab.button_pressed=status_filter==spec[0]
  tab.name="StatusFilter_"+spec[0];tab.add_theme_font_size_override("font_size",14);filters.add_child(tab)
 var content=_scroll(v)
 var grid=GridContainer.new();grid.name="StatusGrid";grid.columns=6;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);content.add_child(grid)
 if not entries.any(func(e):return e.id==selected_status) and not entries.is_empty(): selected_status=entries[0].id
 for e in entries:
  grid.add_child(_status_control(e,false))
 if entries.is_empty(): content.add_child(_label("当前没有这类状态。",16,MUTED))
 else:
  var selected=entries.filter(func(e):return e.id==selected_status)[0]
  var detail_panel=PanelContainer.new();detail_panel.name="StatusDetail"
  var style=_style(Color("111d28"),CYAN.darkened(0.7));style.shadow_size=0
  detail_panel.add_theme_stylebox_override("panel",style);v.add_child(detail_panel)
  var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=164
  scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;detail_panel.add_child(scroll)
  var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",6);scroll.add_child(box)
  box.add_child(_label(selected.name+" · "+selected.value,19,CYAN))
  box.add_child(_label(selected.detail,15,TEXT))
  box.add_child(_label("来源："+selected.source+"\n持续："+selected.duration,13,MUTED))

func _installed_tools() -> void:
 if show_route or view.phase not in ["battle","prepare","rest","prison"]: return
 var installed=view.items.filter(func(item):return item.installed)
 if installed.is_empty(): return
 var panel=_panel(Rect2(24,706,330,46));panel.name="InstalledTools"
 var rows=_scroll(panel)
 
 for item in installed:
  var button=_button(item.fixed_label+"："+item.name+" · %d次" % item.uses,func():
   selected_item=item.id
   _open_drawer("show_items"),CYAN)
  button.name="InstalledTool_"+item.id
  button.custom_minimum_size.y=26
  button.add_theme_font_size_override("font_size",12)
  rows.add_child(button)

func _items_drawer() -> void:
 if not view.items.is_empty() and not view.items.any(func(i):return i.id==selected_item):
  selected_item=view.items[0].id;selected_item_slot="";item_help=false
 var needs_space=view.items.any(func(item):return item.id==selected_item and item.target_scope=="body_group")
 var v=_drawer_shell("道具 · %d / %d格" % [view.carried_items,view.capacity],Rect2(582,156,820,190 if view.items.is_empty() else (540 if needs_space else 420)))
 if view.items.is_empty():
  v.add_child(_label("尚未携带道具。",17,MUTED))
  return
 var row=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; row.add_theme_constant_override("separation",16); v.add_child(row)
 var left=_scroll(row);left.name="InventoryList";left.get_parent().custom_minimum_size.x=224
 for item in view.items:
  var item_button=ItemRowScene.instantiate()
  _style_button(item_button,item.name+"\n%s · 剩余%d次" % [item.mount,item.uses],func(): selected_item=item.id; selected_item_slot=""; item_help=false; _refresh_drawers(),CYAN if selected_item==item.id else MUTED)
  item_button.alignment=HORIZONTAL_ALIGNMENT_LEFT;item_button.add_theme_font_size_override("font_size",15)
  item_button.custom_minimum_size.y=84;item_button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  for style_name in ["normal","hover","pressed","focus","disabled"]:
   var style=item_button.get_theme_stylebox(style_name).duplicate();style.content_margin_left=72
   item_button.add_theme_stylebox_override(style_name,style)
  var icon=item_button.icon();icon.name="ToolIcon_"+item.id
  icon.kind="tool";icon.symbol="return_scroll" if item.type=="return_seal" else item.type
  icon.position=Vector2(4,10);icon.size=Vector2(64,64)
  item_button.name="ToolItem_"+item.id;left.add_child(item_button)
 var right=_scroll(row)
 right.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var selected=view.items.filter(func(i):return i.id==selected_item)[0]
 right.name="InventoryDetail"
 right.add_child(_label(selected.name,22,CYAN))
 right.add_child(_label(selected.category+" · "+selected.mount,13,MUTED))
 if selected.summary!="": right.add_child(_label(selected.summary,17,TEXT))
 if selected.usage_note!="": right.add_child(_label(selected.usage_note,13,MUTED))
 if selected.environment_name!="": right.add_child(_label(selected.environment_name+(" · "+selected.fixed_label if selected.installed else " · 安装后可作借力环境"),14,GOLD))
 if selected.contact_text!="": right.add_child(_label(selected.contact_text,14,CYAN))
 if selected.installed and selected.passive_text!="": right.add_child(_label(selected.passive_text,14,CYAN))
 var item_actions=actions.select("item",{"item":selected_item})
 var usage_actions=item_actions.filter(func(c):return c.payload.kind!="item_discard")
 if usage_actions.is_empty(): right.add_child(_label(selected.inactive_reason,13,MUTED))
 if selected.direct_use:
  if selected.target_scope=="body_group":
   right.add_child(_label("选择涂抹部位",16,GOLD))
   var grid=GridContainer.new();grid.columns=3;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",4);right.add_child(grid)
   for c in item_actions:
    if c.payload.kind!="item_use": continue
    var group=view.body_groups.filter(func(body):return body.id==c.payload.target)[0]
    var button=_button(group.name,func():_submit(c),CYAN)
    button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    button.name="ToolSlot_"+group.id;button.disabled=not c.valid
    grid.add_child(button);candidate_buttons[c.id]=button
    if not c.valid: button.tooltip_text=c.reason
    else:
     for item_action in item_actions:
      if item_action.payload.kind=="item_use": _compact_action(right,c,"使用",false)
      elif not selected.installed and not usage_actions.is_empty():
       right.add_child(_label("选择使用位置",16,GOLD))
       for target_group in selected.target_groups:
        var target_button=_button(target_group.name+" · %d个目标" % target_group.candidates.size(),func():selected_item_slot=target_group.id if selected_item_slot!=target_group.id else "";_refresh_drawers(),CYAN)
        target_button.name="ToolSlot_"+target_group.id;right.add_child(target_button)
        if selected_item_slot==target_group.id:
         for id in target_group.candidates:
          var matches=item_actions.filter(func(c):return c.id==id)
          if not matches.is_empty(): _tool_target_card(right,matches[0])
     if selected.target_groups.is_empty():
      for reason in selected.unavailable_reasons: right.add_child(_label(reason,14,RED))

 var installations=item_actions.filter(func(c):return c.payload.kind=="item_install")
 if not installations.is_empty():
  var expanded=selected_item_slot=="@install"
  var install_button=_button("安装到墙缝"+(" −" if expanded else " ＋"),func():selected_item_slot="" if selected_item_slot=="@install" else "@install";_refresh_drawers(),GOLD)
  install_button.name="ToolInstallMenu";right.add_child(install_button)
  if expanded:
   for c in installations: _compact_action(right,c,"",false)
 for c in item_actions:
  if c.payload.kind not in ["item_use","item_install","item_discard"]: _compact_action(right,c,"",false)
 var help_button=_button("使用说明  −" if item_help else "使用说明  ＋",func():item_help=not item_help;_refresh_drawers(),MUTED)
 help_button.name="ItemHelpToggle";help_button.custom_minimum_size.y=30;help_button.add_theme_font_size_override("font_size",13);right.add_child(help_button)
 if item_help:
  var help_box=VBoxContainer.new();help_box.name="ItemHelpContent";right.add_child(help_box)
  help_box.add_child(_label(selected.description,14,MUTED))
  if selected.passive_text!="" and not selected.installed: help_box.add_child(_label("安装后："+selected.passive_text,14,CYAN))
 var footer=HBoxContainer.new();footer.alignment=BoxContainer.ALIGNMENT_END;v.add_child(footer)
 for c in item_actions:
  if c.payload.kind=="item_discard":
   var discard=_button("丢弃",func():_submit(c),MUTED);discard.name="ItemDiscard";discard.custom_minimum_size=Vector2(90,32)
   discard.add_theme_font_size_override("font_size",14);discard.tooltip_text="丢弃后无法取回。";discard.disabled=not c.valid
   footer.add_child(discard);candidate_buttons[c.id]=discard

func _options_drawer() -> void:
 var content=_drawer_shell(_text("ui.settings.title","设置"),Rect2(390,110,820,700) if options_tab=="keys" else Rect2(550,145,500,590))
 var tabs=HBoxContainer.new();content.add_child(tabs)
 for id in (["display","audio"] if display_settings.mobile else ["display","audio","keys"]):
  var tab=_button(_text("ui.settings.tab."+id,{"display":"显示","audio":"声音","keys":"键位"}[id]),func():options_tab=id;keyboard_input.capture_id="";keyboard_input.binding_message="";_refresh_drawers(),CYAN if options_tab==id else GOLD)
  tab.name="SettingsTab_"+id;tabs.add_child(tab)
 if options_tab=="audio":
  _audio_options(content);return
 if options_tab=="keys" and not display_settings.mobile:
  keyboard_input.settings.build(self,content,keyboard_input);return
 content.add_child(_label(_text("ui.settings.language","语言"),17,GOLD))
 var language=OptionButton.new();language.name="LanguageSelection"
 language.add_item(_text("ui.settings.language.zh_cn","简体中文"))
 language.add_item(_text("ui.settings.language.ja_jp","日语（待翻译）"))
 for index in range(localization.LOCALES.size()): language.set_item_metadata(index,localization.LOCALES[index])
 language.select(localization.LOCALES.find(display_settings.locale))
 language.item_selected.connect(func(index):_set_language(language.get_item_metadata(index)))
 content.add_child(language)
 if display_settings.mobile:
  content.add_child(_label(_text("ui.settings.mobile","横屏 · 长按查看详情／切换"),17,GOLD))
 else:
  content.add_child(_label(_text("ui.settings.mode","显示模式"),17,GOLD))
  var mode=OptionButton.new();mode.name="DisplayMode"
  for index in range(display_settings.MODES.size()): mode.add_item(_text("ui.settings.mode."+["windowed","borderless","fullscreen"][index],display_settings.MODES[index]))
  mode.select(display_settings.mode)
  mode.item_selected.connect(func(index):display_settings.set_mode(index);_refresh_drawers())
  content.add_child(mode)
  content.add_child(_label(_text("ui.settings.resolution","分辨率"),17,GOLD))
  var resolution=OptionButton.new();resolution.name="DisplayResolution"
  var sizes=display_settings.choices()
  if display_settings.mode==2:
   var native=DisplayServer.screen_get_size(get_window().current_screen)
   resolution.add_item("%d × %d" % [native.x,native.y]);resolution.select(0);resolution.disabled=true
  else:
   for dimensions in sizes: resolution.add_item("%d × %d" % [dimensions.x,dimensions.y])
   resolution.select(sizes.find(display_settings.resolution))
  resolution.item_selected.connect(func(index):display_settings.set_resolution(sizes[index]);_refresh_drawers())
  content.add_child(resolution)
  if display_settings.mode==2: content.add_child(_label(_text("ui.settings.native_resolution","全屏使用显示器原生分辨率。"),14,MUTED))
 if display_settings.save_error!="": content.add_child(_label(display_settings.save_error,14,RED))
 content.add_child(_label(_text("ui.settings.feedback_speed","敌方行动展示速度"),17,GOLD))
 var speed=OptionButton.new();speed.name="FeedbackSpeed"
 for index in range(3): speed.add_item(_text("ui.settings.speed."+["fast","normal","slow"][index],["快速","标准","舒缓"][index]))
 speed.select(0 if feedback_duration<1.0 else (1 if feedback_duration<1.6 else 2))
 speed.item_selected.connect(func(index):feedback_duration=[0.8,1.3,1.8][index])
 content.add_child(speed)

func _audio_options(content: Control) -> void:
 var toggle=CheckButton.new();toggle.name="CardMusicEnabled"
 toggle.text=_text("ui.settings.music_enabled","打出卡牌时播放音乐");toggle.button_pressed=display_settings.card_music_enabled
 toggle.toggled.connect(func(enabled):
  display_settings.set_card_music(enabled,display_settings.card_music_volume)
  card_music.configure(enabled,display_settings.card_music_volume))
 content.add_child(toggle)
 var caption=_label(_text("ui.settings.music_volume","音乐音量 · {percent}%",{"percent":roundi(display_settings.card_music_volume*100)}),19,GOLD)
 caption.name="CardMusicVolumeLabel";content.add_child(caption)
 var volume=HSlider.new();volume.name="CardMusicVolume"
 volume.min_value=0;volume.max_value=100;volume.step=1;volume.value=display_settings.card_music_volume*100
 volume.custom_minimum_size=Vector2(0,44)
 volume.value_changed.connect(func(value):
  display_settings.set_card_music(display_settings.card_music_enabled,value/100.0)
  card_music.configure(display_settings.card_music_enabled,value/100.0)
  caption.text=_text("ui.settings.music_volume","音乐音量 · {percent}%",{"percent":roundi(value)}))
 content.add_child(volume)
 if display_settings.save_error!="": content.add_child(_label(display_settings.save_error,14,RED))

func _settings_drawer() -> void:
 var shade=ColorRect.new(); shade.color=Color(0.02,0.03,0.04,0.85); shade.z_index=300
 _place(shade,Rect2(0,0,1600,900))
 var panel=_panel(Rect2(500,155,600,575)); panel.z_index=301
 var content=VBoxContainer.new(); panel.add_child(content)
 content.add_theme_constant_override("separation",12)
 content.add_child(_label("重新开始",25,GOLD))
 content.add_child(_label("相同种子生成相同初始局面。新塔路覆盖塔路存档；新练习只覆盖练习存档。",16))
 var row=HBoxContainer.new(); content.add_child(row)
 var caption=_label("种子",16); caption.custom_minimum_size.x=95; row.add_child(caption)
 seed_field=LineEdit.new(); seed_field.text=seed_text; seed_field.custom_minimum_size.x=195
 seed_field.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.add_child(seed_field)
 var tower_button=_button("从入口开始塔路",func():
  if seed_field.text.is_valid_int():
   restart(int(seed_field.text)))
 content.add_child(tower_button)
 var start_buttons=[tower_button]
 var options=_scroll(content)
 for option in view.practice_options:
  var button=_button(option.label,func():
   if seed_field.text.is_valid_int(): restart(int(seed_field.text),true,option.id),CYAN)
  button.name=option.node
  options.add_child(button); start_buttons.append(button)
 var issue=_label("",14,RED); content.add_child(issue)
 for button in start_buttons: button.disabled=not seed_text.is_valid_int()
 issue.text="种子需要填写整数。" if tower_button.disabled else ""
 seed_field.text_changed.connect(func(value):
  seed_text=value
  var valid=value.is_valid_int()
  for button in start_buttons: button.disabled=not valid
  issue.text="" if valid else "种子需要填写整数。")
 content.add_child(_button("返回主页" if show_home else "返回当前游戏",func(): show_settings=false; _refresh_drawers()))

func _save_drawer() -> void:
 var shade=ColorRect.new();shade.color=Color(0.02,0.03,0.04,0.85);shade.z_index=310
 _place(shade,Rect2(0,0,1600,900))
 var panel=_panel(Rect2(485,150,660,590));panel.z_index=311
 var content=VBoxContainer.new();panel.add_child(content)
 content.add_child(_label("存档与继续游戏",26,GOLD))
 content.add_child(_label(save_notice if save_notice!="" else "自动保存场景起点，继续游戏时从此处重来。",16,RED if save_failed else CYAN))
 content.add_child(_label("塔路与练习分别保存进度。",16))
 for slot in Game.Snapshot.SLOTS:
  var entry=save_summaries.get(slot,{"available":false,"text":"尚无存档。"})
  var button=_button("继续塔路" if slot=="tower" else "继续练习",func(): _continue_save(slot),GOLD)
  button.name="ContinueTower" if slot=="tower" else "ContinuePractice"
  button.disabled=not entry.available
  content.add_child(button)
  content.add_child(_label(entry.text,15,MUTED if entry.available else RED))
 var retry=_button("保存场景起点",func(): _save_progress();_refresh_save_summaries();render(view),CYAN)
 retry.disabled=save_suspended or not session_started
 retry.name="SaveCurrent";content.add_child(retry)
 if save_suspended: content.add_child(_label("这份进度无法继续。请返回主界面开始新游戏；原文件会保留到开始新游戏时。",14,RED))
 if save_suspended or not session_started:
  var home=_button("返回主界面",_return_home,CYAN);home.name="SaveReturnHome";content.add_child(home)
 else: content.add_child(_button("返回游戏",func(): show_saves=false;_refresh_drawers()))

func _event_screen() -> void:
 var screen=EventScene.instantiate()
 _place(screen,Rect2(0,0,1600,900))
 screen_parent=screen.frame()
 EventScreen.build(self)

func _chain_screen() -> void:
 var screen=ChainScene.instantiate()
 _place(screen,Rect2(0,0,1600,900))
 screen.panel().add_theme_stylebox_override("panel",Palette.window_frame())
 var content=screen.content();content.add_theme_constant_override("separation",9)
 content.add_child(_label(view.card_chain.name+" · 选择下一段目标",24,GOLD))
 content.add_child(_label("费用已支付，选择下一段目标。",16,CYAN))
 for c in actions.select("chain"): _action_row(content,c)

func _service_screen() -> void:
 var shop=ShopScene.instantiate();shop.ui=self;shop.name="RoomServicePanel";shop.size=Vector2(1552,790)
 _place(shop,Rect2(24,84,1552,790))
