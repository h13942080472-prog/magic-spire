extends Control

const Game=preload("res://core/game.gd")
const ShopScreen=preload("res://ui/shop_screen.gd")
const Arena=preload("res://ui/arena.gd")
const EquipmentPortrait=preload("res://ui/equipment_portrait.gd")
const CardFace=preload("res://ui/card_face.gd")
const StatusIcon=preload("res://ui/status_icon.gd")
const RouteMap=preload("res://ui/route_map.gd")
const RunReview=preload("res://ui/run_review.gd")
const DropTarget=preload("res://ui/drop_target.gd")
const DragTargets=preload("res://ui/drag_targets.gd")
const ActionIndex=preload("res://ui/action_index.gd")
const TargetQueries=preload("res://ui/target_queries.gd")
const Backdrop=preload("res://ui/dungeon_backdrop.gd")
const Palette=preload("res://ui/visual_theme.gd")
const OVERLOAD_COLOR=Palette.OVERLOAD
const CombatFeedback=preload("res://ui/combat_feedback.gd")
const ImpactFeedback=preload("res://ui/impact_feedback.gd")
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
const ENEMY_GROUP_WIDTH=280.0
const HERO_STAGE_RECT=Rect2(442.1,170.5,295.8,331.5)
const HERO_STATUS_RECT=Rect2(386,196,52,306)

var enemy_feedback: Control
var resource_feedback: Control
var impact_feedback: Control
var card_motion: Control
var attack_forms: Dictionary={}
var selected_character="original"
var feedback_duration=1.3
var display_settings=preload("res://ui/display_settings.gd").new()
var localization=preload("res://ui/localization.gd").new()

var game_factory=Game
var game=Game.new()
var view: Dictionary
# Read-only display diagnostics (docs/ondemand-copy.md §3): one entry per (point, key, view version),
# cleared when ui.view is replaced. Never rendered, logged, saved or counted.
var projection_misses: Array=[]
var layout: Control
var drawer_layer: Control
var drawer_base_candidates={}
var building_drawer=false
var quick_release_open=false
var quick_release_region=""
var quick_release_parts: Dictionary={}
var quick_release_targets: Dictionary={}
var quick_release_inspected=""
var selected_card=""
var selected_slot="wrist"
var selected_enemy=""
var selected_candidate=""
var notice=""
var show_route=false
var show_reward_cards=false
var reward_card_row=""
var show_reward_relics=false
var show_body=false
var expanded_body_regions: Array=[]
var show_log=false
var show_feedback=false
var feedback_report: Node
var term_popup: PanelContainer
var term_anchor: Control
var show_deck=false
var deck_zone="deck"
var show_run_review=false
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
const DRAWERS=["show_feedback","show_encyclopedia","show_shop_service","show_menu","show_tutorial","show_log","show_deck","show_run_review","show_event_selection","show_items","show_hook","show_pressure","show_settings","show_saves","show_options"]
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
var takeover_presenter: Control
var travel_log_scroll=-1
var travel_log_count=0
# docs/spec/seed-identity.md: the map chip only mirrors this deadline; clicking writes the
# clipboard and this display state, never a candidate, the random stream, the save or game.state.
var seed_chip: Button
# Second view of the same copy entry (docs/spec/run-review.md): the run review panel button.
# It owns no timer and no text; only _refresh_seed_chip writes both view texts.
var run_review_copy: Button
var seed_copied_until=0
const SEED_COPIED_MS=1200
var speech_id=""
var suppressed_hero_speech_id=""
var speech_deadline=0
var speech_group: Control

func _process(_delta: float) -> void:
 if speech_deadline>0 and Time.get_ticks_msec()>=speech_deadline: _dismiss_speech()
 _refresh_seed_chip()
 _queue_takeover_step()

func _takeover_locked() -> bool:
 return not show_home and view.get("first_turn_control",{}).get("locked",false)

func _takeover_banner() -> void:
 if is_instance_valid(takeover_presenter): takeover_presenter.sync()

func _queue_takeover_step() -> void:
 if is_instance_valid(takeover_presenter): takeover_presenter.advance()

func _dismiss_speech() -> void:
 speech_deadline=0
 if is_instance_valid(speech_group): speech_group.hide()

func _skip_hero_speech(entry: Dictionary) -> void:
 if entry.is_empty(): return
 suppressed_hero_speech_id="hero:"+str(entry.id)
 speech_id=suppressed_hero_speech_id
 _dismiss_speech()

func _speech_visible(id: String) -> bool:
 if speech_id!=id:
  speech_id=id
  speech_deadline=Time.get_ticks_msec()+5000
 return speech_deadline>Time.get_ticks_msec()

func _ready() -> void:
 if OS.has_feature("android"): get_tree().quit_on_go_back=false
 touch_input=preload("res://ui/touch_input.gd").new();touch_input.host=self;add_child(touch_input)
 keyboard_input=preload("res://ui/keyboard_input.gd").new();keyboard_input.host=self;add_child(keyboard_input)
 feedback_report=preload("res://ui/feedback_report.gd").new();feedback_report.host=self;add_child(feedback_report)
 takeover_presenter=preload("res://ui/first_turn_presenter.gd").new();takeover_presenter.host=self;add_child(takeover_presenter)
 get_window().title=ProjectSettings.get_setting("application/config/name")
 shop_chatter_rng.randomize()
 display_settings.initialize(get_window(),persistence_enabled)
 localization.set_locale(display_settings.locale)
 card_music=preload("res://ui/card_music.gd").new();add_child(card_music)
 card_music.configure(display_settings.card_music_enabled,display_settings.card_music_volume)
 theme=Palette.controls()
 _restore_startup()
 render(view)

func _save_progress(replace_incompatible: bool=false) -> void:
 if not persistence_enabled or save_suspended or not session_started: return
 var result=saves.write_game(game,replace_incompatible,map_drawings)
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
 _clear_impact_feedback()
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
 var dismiss=Button.new()
 dismiss.name="DismissDrawer";dismiss.z_index=228
 var shade=StyleBoxFlat.new();shade.bg_color=Color(0.015,0.025,0.04,0.55)
 for state in ["normal","hover","pressed","focus"]: dismiss.add_theme_stylebox_override(state,shade)
 dismiss.pressed.connect(func():_close_drawers();_refresh_drawers())
 _place(dismiss,Rect2(0,0,1600,900) if show_home or show_deck or show_run_review or show_event_selection or show_feedback else Rect2(376,64,1224,836))
 var panel=_panel(rect);panel.z_index=230;panel.name="InformationDrawer"
 var content=VBoxContainer.new();content.add_theme_constant_override("separation",12);panel.add_child(content)
 var heading=HBoxContainer.new();content.add_child(heading)
 heading.add_theme_constant_override("separation",10)
 if rect.size.x>=650:
  var crest=TextureRect.new();crest.texture=preload("res://assets/ui/crest.svg");crest.custom_minimum_size=Vector2(32,32)
  crest.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;crest.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;crest.mouse_filter=Control.MOUSE_FILTER_IGNORE;heading.add_child(crest)
 var label=_label(title,23,tone);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(label)
 var close=_button(_text("ui.common.close","关闭 ×"),func():_close_drawers();_refresh_drawers(),MUTED);close.name="CloseDrawer";heading.add_child(close)
 content.add_child(HSeparator.new())
 return content

func _menu_drawer() -> void:
 var content=_drawer_shell("游戏菜单",Rect2(1090,78,474,474))
 var save=_button("存档异常 · 查看" if save_failed else "存档 / 继续",_open_saves,RED if save_failed else CYAN)
 save.name="OpenSaves";content.add_child(save)
 var quick=_button("快速SL" if not view.demo_finished else "快速SL · 本局已结束",_quick_sl,CYAN)
 quick.name="QuickSL";quick.disabled=view.demo_finished
 quick.tooltip_text="回到当前场景开始，恢复初始手牌与资源。";content.add_child(quick)
 var log_button=_button("行动日志",func():_open_drawer("show_log"));log_button.name="OpenLog";content.add_child(log_button)
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
 save_notice="已恢复场景起点备份。" if result.backup else "已回到最近保存的起点。"
 _resume_snapshot(result.snapshot,result.map_drawings)

func _resume_snapshot(snapshot: Dictionary, drawings: Dictionary={}) -> bool:
 var restored=game.restore_snapshot(snapshot)
 if not restored.ok:
  _save_unavailable(restored.error);return false
 var initial=game.get_view()
 var restored_drawings=drawings.duplicate(true)
 _reset_interface(initial)
 map_drawings=restored_drawings
 render(initial)
 _animate_cards(initial.hand.map(func(card):return {"kind":"draw","uid":card.uid,"type":card.type}),{})
 return true

func _quick_sl() -> void:
 if view.demo_finished: return
 # docs/save-fixed-points.md §1：恢复不是进度固定点；磁盘仍持有上一次固定点内容。
 _resume_snapshot(game.restart_snapshot(),map_drawings)

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
 theme=Palette.controls()
 render(view)

func _label(text: String, fs: int=16, color: Color=TEXT) -> Label:
 var l=Label.new()
 text=localization.display(text)
 l.text=text.replace("右键","长按") if OS.has_feature("android") else text
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.add_theme_font_size_override("font_size",fs)
 l.add_theme_color_override("font_color",color)
 l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return l

func _button(text: String, fn: Callable, color: Color=GOLD, drop_zone: bool=false) -> Button:
 var b=DropTarget.new() if drop_zone else Button.new()
 b.text=localization.display(text)
 for state in ["normal","hover","pressed","focus","disabled"]:
  b.add_theme_stylebox_override(state,Palette.button_style(state,CYAN if state=="focus" else color))
 b.add_theme_color_override("font_color",TEXT)
 b.add_theme_color_override("font_disabled_color",Color("8c99a3"))
 b.custom_minimum_size.y=36
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 b.pressed.connect(fn)
 return b

func _place(node: Control, rect: Rect2, parent: Control=null) -> Control:
 var owner=parent if parent!=null else (drawer_layer if building_drawer else layout)
 owner.add_child(node)
 node.position=rect.position
 node.size=rect.size
 return node

func _panel(rect: Rect2, parent: Control=null) -> PanelContainer:
 var p=PanelContainer.new()
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

func _bar(value: float, maximum: float, color: Color) -> ProgressBar:
 var b=ProgressBar.new()
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

func render(snapshot: Dictionary={}) -> void:
 # The old controls still reference the previous View here. Rebuild the quick bar
 # after replacing View/ActionIndex instead of querying old targets against a new game.
 DragTargets.clear(self,false)
 _hide_term()
 view=game.get_view() if snapshot.is_empty() else snapshot
 projection_misses=[]
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
 drawer_layer=null;drawer_base_candidates.clear()
 candidate_buttons.clear(); card_buttons.clear(); body_buttons.clear()
 actor_targets.clear()
 if not is_instance_valid(layout):
  layout=preload("res://ui/shell/game_layout.tscn").instantiate()
  add_child(layout)
 layout.begin_frame(show_home)
 if show_home:
  var home=preload("res://ui/home_screen.gd").new();home.ui=self;home.name="GameHome"
  _place(home,Rect2(0,0,1600,900))
  _refresh_drawers()
  _localize_controls(layout)
  layout.end_frame()
  return
 if view.phase=="battle" and not _takeover_locked() and not show_route and not display_settings.first_battle_tutorial_seen:
  _close_drawers()
  tutorial_category="basics"
  show_tutorial=true
  display_settings.mark_first_battle_tutorial_seen()
 layout.get_node("MoonlitGallery").rest=view.phase in ["rest","rest_choice"]
 _header()
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
  _battle_scene()
  if not view.card_chain.is_empty(): _chain_screen()
  elif view.reward_panel.active: _rewards()
  else:
   if not _selecting_hand(): _fixed_actions()
   _hand()
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
 if not show_route and view.phase in ["battle","prepare","rest","prison","event","shop","treasure"]: _feedback_entry()
 _npc_speech_bubble()
 if player_pick: _player_picker()
 if selected_card!="" and not _selecting_hand(): DragTargets.focus_bodies(self,{"card_uid":selected_card,"free":card_faces.get(selected_card,false),"version":view.version})
 _refresh_drawers()
 if view.phase=="shop" and not show_route: ShopScreen.payment_overlay(self)
 if notice!="" and actor_targets.has("hero"):
  _show_term(actor_targets.hero,{"label":"","detail":notice})
 _takeover_banner()
 layout.end_frame()
 if is_instance_valid(keyboard_input): keyboard_input.refresh_hints.call_deferred()
 _localize_controls(layout)

func _release_candidate_controls(root: Control) -> void:
 for key in candidate_buttons.keys():
  var button=candidate_buttons[key]
  if not is_instance_valid(button) or root.is_ancestor_of(button):
   candidate_buttons.erase(key)
   var previous=drawer_base_candidates.get(key)
   if is_instance_valid(previous) and previous.is_inside_tree(): candidate_buttons[key]=previous

# Information panels own only their overlay. Keep the scene, hand, focus and map alive.
func _refresh_drawers() -> void:
 _hide_term()
 if is_instance_valid(drawer_layer):
  _release_candidate_controls(drawer_layer)
  drawer_layer.hide();layout.remove_child(drawer_layer);drawer_layer.queue_free()
 drawer_base_candidates=candidate_buttons.duplicate()
 drawer_layer=Control.new();drawer_layer.name="InformationLayer"
 drawer_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
 layout.add_child(drawer_layer)
 drawer_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 building_drawer=true
 if show_feedback: feedback_report.build(_drawer_shell("问题与建议",Rect2(270,74,1060,752),CYAN))
 if show_home:
  if show_encyclopedia: _encyclopedia_drawer()
  if show_tutorial: _tutorial_drawer()
  if show_settings: _settings_drawer()
  if show_options: _options_drawer()
  if show_saves: _save_drawer()
 else:
  if show_log: _log_drawer()
  if show_deck: _deck_drawer()
  if show_run_review: RunReview.drawer(self)
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
 _localize_controls(drawer_layer)

func _localize_controls(root: Node) -> void:
 if localization.locale==localization.DEFAULT_LOCALE or not is_instance_valid(root): return
 for node in root.find_children("*","Control",true,false):
  if node is Label or node is Button or node is RichTextLabel: node.text=localization.display(node.text)
  if node is LineEdit or node is TextEdit: node.placeholder_text=localization.display(node.placeholder_text)
  if node is OptionButton:
   for index in range(node.item_count): node.set_item_text(index,localization.display(node.get_item_text(index)))
  if node is ItemList:
   for index in range(node.item_count): node.set_item_text(index,localization.display(node.get_item_text(index)))
  if node.tooltip_text!="": node.tooltip_text=localization.display(node.tooltip_text)

func _header() -> void:
 var header=preload("res://ui/shell/header.tscn").instantiate()
 _place(header,Rect2(0,0,1600,62))
 header.configure(self)
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
  var choice=actions.find("relic",{"kind":"relic_discharge","relic":relic.id})
  if choice.is_empty(): choice=actions.find("relic",{"kind":"relic_toggle","relic":relic.id})
  if not choice.is_empty():
   shortcut.gui_input.connect(func(event):
    if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
     shortcut.accept_event();_hide_term();_submit(choice))

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
  if status.has("item_id"):
   selected_item=status.item_id;_open_drawer("show_items");return
  selected_status=status.id
  if compact: status_filter="all";_open_drawer("show_pressure")
  else: _refresh_drawers())
 return button

func _status_strip(owner: String, rect: Rect2, parent: Control=null, vertical: bool=false) -> void:
 var entries=view.statuses.filter(func(e):return e.active and e.owner==owner)
 if entries.is_empty(): return
 var strip=ScrollContainer.new();strip.name="StatusStrip_"+owner
 strip.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO if vertical else ScrollContainer.SCROLL_MODE_DISABLED
 strip.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED if vertical else ScrollContainer.SCROLL_MODE_AUTO
 _place(strip,rect,layout if parent==null else parent)
 var row: BoxContainer=VBoxContainer.new() if vertical else HBoxContainer.new()
 row.add_theme_constant_override("separation",4);strip.add_child(row)
 for entry in entries: row.add_child(_status_control(entry,true))

func _battle_scene() -> void:
 layout.hero_portrait(view,EquipmentPortrait.uses_fixed_portrait(view,display_settings.fixed_hero_portrait),HERO_STAGE_RECT)
 var hero_target=_actor_drop_area(HERO_STAGE_RECT.grow_individual(-38,0,-38,0))
 hero_target.accepted_kind="player"
 hero_target.hover_card=func(data): _player_drag_preview(data)
 hero_target.accept_card=func(data): return _can_drop_on_player(data)
 hero_target.receive_card=func(data): call_deferred("_receive_player_drop",data)
 actor_targets["hero"]=hero_target
 _status_strip("hero",HERO_STATUS_RECT,null,true)
 var meter_x=HERO_STAGE_RECT.get_center().x-80
 _resource_meter("HeroOverload",Rect2(meter_x,502,160,13),view.pressure.value,view.pressure.maximum,OVERLOAD_COLOR)
 _resource_meter("HeroMana",Rect2(meter_x,520,160,13),view.mana,view.mana_max,CYAN)
 if not view.guard_bind.is_empty():
  var bind_label=_place(_label("捕缚",11,RED),Rect2(meter_x-40,537,40,15));bind_label.name="HeroGuardBindCaption"
  _resource_meter("HeroGuardBind",Rect2(meter_x,538,160,13),view.guard_bind.value,view.guard_bind.maximum,RED)
  var bind_target=_guard_bind_drop_target(Rect2(meter_x-40,535,200,19),"GuardBindTarget")
  actor_targets["guard_bind"]=bind_target
 var cast_label=_label("嘴部施法成功率 "+view.casting.percent,11,CYAN)
 cast_label.name="HeroCastingChance";cast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _place(cast_label,Rect2(meter_x+183 if not view.guard_bind.is_empty() else meter_x-10,537 if not view.guard_bind.is_empty() else 533,180,14))
 _speech_bubble()
 var living=view.enemies.filter(func(e):return not e.gone)
 # Presentation order only; combat and target IDs retain their original order.
 living=living.filter(func(e):return e.template=="iron_drone")+living.filter(func(e):return e.template not in ["puppeteer","iron_man","iron_drone"])+living.filter(func(e):return e.template in ["puppeteer","iron_man"])
 var enemy_count=living.size()
 var enemy_scale=minf(1.0,ENEMY_STAGE_WIDTH/(ENEMY_GROUP_WIDTH*maxi(1,enemy_count)))
 var enemy_row_width=enemy_count*ENEMY_GROUP_WIDTH*enemy_scale
 var enemy_row_start=ENEMY_STAGE_LEFT+(ENEMY_STAGE_WIDTH-enemy_row_width)/2.0
 for i in range(enemy_count):
  var e=living[i]
  var group=layout.enemy_group(e,display_settings)
  var screen_x=enemy_row_start+i*ENEMY_GROUP_WIDTH*enemy_scale
  group.position=Vector2(screen_x,497.0*(1.0-enemy_scale))
  group.scale=Vector2.ONE*enemy_scale
  var x=(ENEMY_GROUP_WIDTH-226.0)/2.0
  var guard=e.type in ["guard","six_bind","puppeteer","iron_man"]
  for n in range(e.intent_icons.size()):
   var entry=e.intent_icons[n]
   var icon=preload("res://ui/intent_icon.gd").new()
   icon.kind=entry.kind;icon.name="IntentIcon_"+e.id+"_"+entry.kind
   var columns=mini(4,e.intent_icons.size())
   var bottom=120 if guard else 192
   _place(icon,Rect2(x+113-columns*27+(n%4)*54,bottom-ceili(e.intent_icons.size()/4.0)*50+(n/4)*50,54,50),group)
   icon.z_index=8
   icon.mouse_entered.connect(func():_show_term(icon,entry));icon.mouse_exited.connect(_hide_term)
   icon.focus_entered.connect(func():_show_term(icon,entry));icon.focus_exited.connect(_hide_term)
  var picture=group.get_child(0)
  var picture_rect=Rect2(x+35,126,156,288) if e.type=="guard" else (Rect2(x-8,126,242,288) if guard else Rect2(x-19,198,264,216))
  picture.position=picture_rect.position;picture.size=picture_rect.size
  var receiver_rect=picture_rect
  var receiver=_actor_drop_area(receiver_rect,group,true)
  receiver.pressed.connect(func():_select_enemy(e.id))
  _configure_enemy_drop(receiver,e.id)
  actor_targets[e.id]=receiver
  var b=_button(("◇ " if selected_enemy==e.id and not e.gone else "")+e.name,func():_select_enemy(e.id),CYAN if selected_enemy==e.id else GOLD,true)
  b.name="EnemySelect_"+e.id
  _configure_enemy_drop(b,e.id)
  b.disabled=e.gone
  _place(b,Rect2(x-5,418,236,37),group)
  _place(_bar(e.hp,e.maximum,RED),Rect2(x,461,226,9),group)
  var hp=_label("%s / %s" % [game.number(e.hp),game.number(e.maximum)],14,TEXT)
  hp.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  _place(hp,Rect2(x,473,226,24),group)
  _status_strip(e.id,Rect2(x,498,226,51),group)

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
 _remove_local_panel("AttackActions")
 if view.phase=="battle" and view.card_chain.is_empty(): _fixed_actions()

func _fixed_actions() -> void:
 if view.phase=="rest": _rest_controls()
 if view.phase=="prison": _prison_controls()
 _build_action_rail()

func _build_action_rail() -> void:
 if view.phase in ["battle","prepare","rest","prison"]:
  var container=Control.new();container.name="AttackActions";container.mouse_filter=Control.MOUSE_FILTER_IGNORE
  _place(container,Rect2(0,0,1600,900))
  var rail=_panel(Rect2(384,550,1195,72),container)
  rail.name="BasicActionRail";rail.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var switcher=_button("⇄",func():preload("res://ui/quick_release_bar.gd").toggle(self),CYAN)
  switcher.name="ActionRailToggle"
  switcher.tooltip_text=preload("res://ui/quick_release_bar.gd").message(self,"to_actions","切换至动作栏") if quick_release_open else preload("res://ui/quick_release_bar.gd").message(self,"to_release","切换至快捷挣脱栏")
  _place(switcher,Rect2(1530,556,39,60),container)
  if quick_release_open:
   preload("res://ui/quick_release_bar.gd").build(self,container,218.6)
   return
  var attack_choices=actions.select("attack",{"enemy":selected_enemy})
  for type in attack_forms.keys():
   var forms=attack_choices.filter(func(c):return c.payload.type==type).map(func(c):return c.payload.form)
   if not forms.is_empty() and attack_forms[type] not in forms: attack_forms[type]=forms[0]
  var offers=attack_choices.filter(func(c):return c.payload.form==attack_forms.get(c.payload.type,0))
  if view.phase!="battle":
   var spells=actions.select("attack",{"type":"fireball","enemy":""})
   var spell=preload("res://ui/quick_release_bar.gd").first(spells)
   offers=[] if spell.is_empty() else [spell]
  var heavy_index=-1;var kick_index=-1
  for i in range(offers.size()):
   if offers[i].payload.type=="heavy": heavy_index=i
   elif offers[i].payload.type=="kick": kick_index=i
  if heavy_index>=0 and kick_index>=0:
   var heavy=offers[heavy_index]
   offers[heavy_index]=offers[kick_index];offers[kick_index]=heavy
  offers.append_array(actions.select("pressure"))
  var width=218.6
  if view.phase!="battle":
   _place(_label(preload("res://ui/quick_release_bar.gd").message(self,"exploration","切换至快捷挣脱栏，可对选中的拘束具使用解除牌，也可使用已安装道具。"),15,MUTED),Rect2(402,565,650,38),container)
  if view.phase!="battle" and view.character_id!="witch" and not offers.any(func(c):return c.payload.kind=="attack"):
   var reason=preload("res://ui/quick_release_bar.gd").message(self,"fire_locked","尚未获得用火球术解除拘束具的能力。") if not view.equipment_fireball_unlocked else preload("res://ui/quick_release_bar.gd").message(self,"fire_empty","没有拘束具可供火球术选为目标。")
   var empty_fire=_button("",func():pass,CYAN)
   empty_fire.name="BasicAttack_fireball";empty_fire.disabled=true;empty_fire.tooltip_text=reason
   empty_fire.clip_contents=true
   _place(empty_fire,Rect2(394+3*(width+8),556,width,60),container)
   var title=_label("火球术",16,MUTED)
   title.name="BasicAttackTitle";title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.clip_text=true
   title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
   _place(title,Rect2(8,2,width-16,24),empty_fire)
   var explanation=_label(reason,11,MUTED)
   explanation.name="BasicAttackDetail_fireball";explanation.max_lines_visible=2
   explanation.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
   explanation.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;explanation.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
   _place(explanation,Rect2(8,26,width-16,30),empty_fire)
  for i in range(offers.size()):
   var c=offers[i]
   var attack=c.payload.kind=="attack"
   var alternatives=actions.select("attack",{"enemy":selected_enemy,"type":c.payload.type}) if attack else []
   var summary=c.get("brief","")
   if not c.has("brief"): summary=detail_of(c).trim_suffix("。")
   var tags=c.get("brief_tags","")
   if c.has("casting"): tags+=(" · " if tags!="" else "")+c.casting.percent
   var btn=_basic_action_tile(c,Rect2(394+(i if view.phase=="battle" else 3 if attack else 4)*(width+8),556,width,60),container,summary,tags,alternatives.size()>1)
   if attack:
    btn.name="BasicAttack_"+c.payload.type
    btn.drag_payload={"action_type":c.payload.type,"form":c.payload.form,"version":view.version}
    btn.drag_label=c.label
    if alternatives.size()>1:
     btn.gui_input.connect(func(event):
      if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
       attack_forms[c.payload.type]=(c.payload.form+1)%alternatives.size()
       btn.accept_event();render(view))
   else: btn.name="DeepBreath"



# Action tiles share the original candidates, tooltips and drag receiver.
func _basic_action_tile(c: Dictionary, rect: Rect2, parent: Control, summary: String, tags: String, can_flip: bool) -> Button:
 var accent=CYAN if c.payload.kind=="calm" or c.has("casting") else GOLD
 var btn=_button("",func():
  if view.phase!="battle" and c.payload.kind=="attack": keyboard_input.select_attack(c.payload.type)
  else: _submit(c),accent,c.payload.kind=="attack")
 btn.disabled=not c.valid;btn.clip_contents=true
 _place(btn,rect,parent);candidate_buttons[c.id]=btn
 _attack_tile_labels(btn,c,rect.size,summary,tags,accent)
 var tooltip="部位："+c.body_part+"\n消耗%d能量。\n" % c.cost+("当前施法成功率："+c.casting.percent+"\n" if c.has("casting") else "")+detail_of(c)
 if c.has("casting"): tooltip+="\n失败返还本次耗魔的50%，能量照扣。"+("蓄力保留，精神集中失去1层。" if c.payload.get("witch_action",false) else "火球术次数不消耗。")
 if not c.valid: tooltip+="\n"+c.reason
 if c.risk!="": tooltip+="\n"+c.risk
 if can_flip: tooltip+="\n右键切换招式"
 var entry={"label":c.label,"detail":tooltip}
 btn.mouse_entered.connect(func():_show_term(btn,entry));btn.mouse_exited.connect(_hide_term)
 btn.focus_entered.connect(func():_show_term(btn,entry));btn.focus_exited.connect(_hide_term)
 return btn

# Cost stays in the left medallion; both text rows share the remaining space.
func _attack_tile_labels(btn: Button, c: Dictionary, bounds: Vector2, summary: String, tags: String, accent: Color) -> void:
 var badge=TextureRect.new();badge.name="BasicActionEnergy"
 badge.texture=preload("res://assets/ui/energy-medallion.svg")
 badge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;badge.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
 badge.modulate=Color.WHITE if c.valid else Color(0.6,0.6,0.6)
 _place(badge,Rect2(7,(bounds.y-32)/2,32,32),btn)
 var energy=_label(str(c.cost),17,TEXT if c.valid else MUTED)
 energy.autowrap_mode=TextServer.AUTOWRAP_OFF;energy.clip_text=true
 energy.name="EnergyCost";energy.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;energy.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 _place(energy,Rect2(0,0,32,32),badge)
 var inset=46.0
 var available=bounds.x-inset-12
 var title=_label(c.label,16,TEXT if c.valid else MUTED)
 title.name="BasicAttackTitle";title.autowrap_mode=TextServer.AUTOWRAP_OFF
 title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.clip_text=true
 var value=_label(summary,16,TEXT if c.valid else MUTED)
 var detail_name="BasicAttackDetail_"+c.payload.type if c.payload.kind=="attack" else "DeepBreathDetail"
 value.name=detail_name if c.valid else "BasicAttackDamage"
 value.autowrap_mode=TextServer.AUTOWRAP_OFF;value.clip_text=true
 var row_y=3 if c.valid else 0
 var row_height=28 if c.valid else 24
 _place(title,Rect2(inset,row_y,1,row_height),btn);_place(value,Rect2(inset,row_y,1,row_height),btn)
 var font=title.get_theme_font("font")
 var fs=16
 var gap=6.0
 while fs>10 and ceilf(font.get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x)+ceilf(font.get_string_size(value.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x)+gap>available: fs-=1
 title.add_theme_font_size_override("font_size",fs);value.add_theme_font_size_override("font_size",fs)
 var value_width=ceilf(font.get_string_size(value.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x)
 var title_width=ceilf(font.get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x)
 var start=inset+(available-title_width-value_width-gap)/2
 title.position.x=start;title.size.x=title_width
 value.position.x=start+title_width+gap;value.size.x=value_width
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var metadata=["%d能量" % c.cost] if c.payload.get("witch_action",false) else [c.body_part]
 if c.mana>0: metadata.append("%s魔力" % game.number(c.mana))
 if tags!="": metadata.append(tags)
 var secondary=_label("  ".join(metadata).replace(" · ","  "),14 if c.valid else 11,accent if c.valid else MUTED)
 secondary.name="BasicAttackMeta"
 secondary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;secondary.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 secondary.autowrap_mode=TextServer.AUTOWRAP_OFF
 secondary.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;secondary.clip_text=true
 _place(secondary,Rect2(inset,32 if c.valid else 24,bounds.x-inset-18,24 if c.valid else 17),btn)
 var secondary_size=14 if c.valid else 11
 while secondary_size>12 and font.get_string_size(secondary.text,HORIZONTAL_ALIGNMENT_LEFT,-1,secondary_size).x>secondary.size.x: secondary_size-=1
 secondary.add_theme_font_size_override("font_size",secondary_size)
 if not c.valid:
  var reason=_label(_basic_action_reason(c),11,RED)
  reason.name=detail_name
  reason.autowrap_mode=TextServer.AUTOWRAP_OFF;reason.clip_text=true
  reason.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  reason.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;reason.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  _place(reason,Rect2(inset,41,bounds.x-inset-18,17),btn)

# Short display copy only; eligibility and full hover text stay with the candidate.
func _basic_action_reason(c: Dictionary) -> String:
 var short={
  "双臂活动受限达到三级，无法完成"+c.label+"。":"双臂受限达到三级",
  "近身短打需要双腿活动自由。":"需要双腿活动自由",
  "正义飞踢需要双腿活动自由。":"需要双腿活动自由",
  "站着踢需要双腿活动自由。":"需要双腿活动自由",
  "腿部严密度达到4级，无法坐着踢。":"腿部严密度达到4级",
  "双腿无法独立活动，不能横扫。":"双腿无法独立活动",
  "无力化：本回合不能使用基础攻击。":"无力化，无法攻击",
  "本回合"+c.label+"次数已用完。":"本回合次数已用完",
  c.label+"需要站姿。":"需要站姿",
 }
 return short.get(c.reason,c.reason.trim_suffix("。"))

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
  btn.disabled=not c.valid;btn.tooltip_text=detail_of(c) if c.valid else c.reason
  _place(btn,Rect2(128 if c.payload.wall else 0,index*placement.stride,121 if has_wall else 249,placement.stride-4),container)
  candidate_buttons[c.id]=btn

# 显示边界的唯一卡面取用点（docs/ondemand-copy.md §3）：命中投影即用，未命中经 §1.4 单条入口补算并记录。
func card_entry(type: String, uid: String="") -> Dictionary:
 var texts=view.get("card_texts",{})
 var instances=view.get("card_instances",{})
 if texts.has(type) or (uid!="" and instances.has(uid)):
  var entry=(texts[type] if texts.has(type) else {}).duplicate()
  if uid!="" and instances.has(uid): entry.merge(instances[uid],true)
  return entry
 _record_projection_miss("card_entry",type if uid=="" else type+"#"+uid)
 return game.live_card_text(type,uid) if game.Cards.Rules.SPECS.has(type) else {}

# 卡面名称的安全取用：缺条目时补算并记录，仍取不到时返回空串，由调用方保留原文案。
func card_face_name(type: String, uid: String, free: bool) -> String:
 var side="free" if free else "bound"
 var names=card_entry(type,uid).get("face_names",{})
 if names.has(side): return names[side]
 _record_projection_miss("card_face_name",type+"#"+side)
 return ""

# 候选详情的唯一取用点（docs/ondemand-copy.md §3）：命中即用，缺失时经 §2 只读入口按 payload 补算并记录。
func detail_of(candidate: Dictionary) -> String:
 if candidate.has("detail"): return candidate.detail
 # B3（docs/ondemand-copy.md §1.5）：card 目标候选组本来就不带 detail，现算是正常路径，不记缺失；
 # 其余组缺 detail 才是意外，留具名记录而不是静默空白。
 if String(candidate.payload.get("kind",""))!="card":
  _record_projection_miss("detail_of",String(candidate.get("id","")))
 return game.candidate_detail(candidate)

func _record_projection_miss(point: String, key: String) -> void:
 var version=int(view.get("version",-1))
 for entry in projection_misses:
  if entry.point==point and entry.key==key and entry.view_version==version: return
 projection_misses.append({"point":point,"key":key,"view_version":version})

func _card(card: Dictionary, rect: Rect2, fn: Callable, rotation_value: float=0, parent: Node=null, hand_interaction: bool=true, lift: bool=true, live_state: bool=true) -> Button:
 var dimensions=CardFace.dimensions(rect.size.y)
 rect.position.x+=(rect.size.x-dimensions.x)/2
 rect.size=dimensions
 card=card.duplicate()
 if live_state:
  card.merge(view.card_texts.get(card.type,{}),true)
  card.merge(view.get("card_instances",{}).get(card.get("physical_uid",card.uid),{}),true)
 var button=CardFace.new()
 button.art_settings=display_settings
 button.localize=localization.display
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
 var cost=_label(card.cost,23,TEXT);cost.name="CardCost"; cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _place(cost,Rect2(0,1,38,37),button)
 var title=_label(card.name,17,TEXT);title.name="CardTitle"
 _place(title,Rect2(43,10,rect.size.x-48,31),button)
 var text_area=ScrollContainer.new();text_area.name="CardText"
 text_area.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 text_area.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
 text_area.mouse_filter=Control.MOUSE_FILTER_PASS
 text_area.mouse_force_pass_scroll_events=false
 _place(text_area,Rect2(12,rect.size.y*CardFace.ART_HEIGHT_RATIO+10,rect.size.x-24,rect.size.y/3-18),button)
 var textbox=VBoxContainer.new();textbox.name="Content"
 textbox.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 textbox.add_theme_constant_override("separation",1)
 text_area.add_child(textbox)
 var keywords=HFlowContainer.new();keywords.name="CardKeywords";keywords.mouse_filter=Control.MOUSE_FILTER_IGNORE
 keywords.add_theme_constant_override("h_separation",8);keywords.add_theme_constant_override("v_separation",2)
 keywords.minimum_size_changed.connect(func(): button.fit_text.call_deferred())
 button.add_child(keywords)
 var requirements=VBoxContainer.new();requirements.name="CardRequirements";requirements.mouse_filter=Control.MOUSE_FILTER_IGNORE
 requirements.add_theme_constant_override("separation",1)
 requirements.minimum_size_changed.connect(func(): button.fit_text.call_deferred())
 button.add_child(requirements)
 _refresh_card_face(button,card)
 button.mouse_entered.connect(func():_card_tooltip(button,card))
 button.mouse_exited.connect(_hide_term)
 button.focus_entered.connect(func():_card_tooltip(button,card))
 button.focus_exited.connect(_hide_term)
 _ignore_mouse(textbox)
 return button

# Catalog, shop and deck use the hand face with no gameplay drag or hover displacement.
func _display_card(type: String, parent: Node, fn: Callable=Callable(), key: String="", dimensions: Vector2=Vector2(226,290), physical_uid: String="", live_state: bool=true, source: Dictionary={}) -> Button:
 var data=preload("res://data/encyclopedia.gd").card(type)
 # 全量入口的条目（docs/ondemand-copy.md §1.3）：非显示集合来源的卡面在这里合并，视图不再带它们的文案。
 # 身份键在合并之后写入，避免被来源行的 uid／physical_uid 覆盖（卡面翻转共用同一个键）。
 if not source.is_empty(): data.merge(source,true)
 data.uid="display_"+key+"_"+type
 data.physical_uid=physical_uid
 # An explicit source already includes physical-instance text. Reapplying the hand's
 # type-only projection would erase growth on a same-type card in another pile.
 var button=_card(data,Rect2(Vector2.ZERO,dimensions),fn if fn.is_valid() else func():pass,0,parent,false,false,live_state and source.is_empty())
 button.custom_minimum_size=button.size
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
 var classification=_label(card.get("face_type_names",{}).get(side,card.type_name)+" · "+card.rarity_name+("" if card.single_face else (" · "+card.face_names[side])),11,button.RARITY_COLORS[card.rarity])
 classification.name="CardClassification";textbox.add_child(classification)
 var warning=card.get("face_warnings",{}).get(side,"")
 var copy=CardFace.separate_keywords(card.face_effects[side].replace(warning,"") if warning!="" else card.face_effects[side],card.face_keywords[side])
 if card.get("retained",false) and "保留" not in copy.keywords: copy.keywords.append("保留")
 var keywords=button.get_node("CardKeywords")
 for child in keywords.get_children():
  keywords.remove_child(child);child.queue_free()
 for keyword in copy.keywords:
  var tag=_label(keyword,roundi(11*button.text_scale()),GOLD);tag.autowrap_mode=TextServer.AUTOWRAP_OFF
  keywords.add_child(tag)
 keywords.visible=not copy.keywords.is_empty()
 var body=_label(copy.body,14,TEXT)
 body.visible=body.text!=""
 body.name="CardEffect";textbox.add_child(body)
 if warning!="":
  var warning_label=_label(warning,14,RED);warning_label.name="CardWarning";textbox.add_child(warning_label)
 var requirements=button.get_node("CardRequirements")
 for child in requirements.get_children():
  requirements.remove_child(child);child.queue_free()
 for text in card.face_requirements[side]:
  var requirement=_label(text,11,CYAN)
  requirement.name="CardRequirement";requirement.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
  requirements.add_child(requirement)
 requirements.visible=requirements.get_child_count()>0
 _ignore_mouse(requirements)
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
  for label in button.get_node("CardRequirements").get_children(): lines.append(label.text)
 if card.cast_faces[side] and card.has("casting"):
  var casting=card.get("face_casting",{}).get(side,card.casting)
  lines.append("施法成功率 · "+casting.percent+"\n"+casting.formula)
  lines.append("失败返还50%耗魔。")
 for term in card.face_keywords[side]: lines.append(term.name+"："+term.detail)
 if card.note!="": lines.append(card.note)
 if lines.is_empty(): _hide_term();return
 _show_term(button,{"label":card.name+("" if card.single_face else (" · "+card.face_names[side])),"detail":"\n".join(lines)})

func _remove_local_panel(node_name: String) -> void:
 var panel=layout.get_node_or_null(node_name)
 if panel==null: return
 for key in candidate_buttons.keys():
  var button=candidate_buttons[key]
  if not is_instance_valid(button) or panel.is_ancestor_of(button): candidate_buttons.erase(key)
 panel.hide();layout.remove_child(panel);panel.queue_free()

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
 var dimensions=CardFace.dimensions(252)
 var step=minf(dimensions.x+8,746.0/maxi(1,count-1))
 var start=850.0-(float(count-1)*step+dimensions.x)/2
 for i in range(count):
  var card=view.hand[i]
  var mid=float(i)-float(count-1)/2
  var y=630+absf(mid)*4
  var b=_card(card,Rect2(Vector2(start+i*step,y),dimensions),func(): _activate_card(card.uid),mid*0.018)
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
 var resource_back=Panel.new();resource_back.mouse_filter=Control.MOUSE_FILTER_IGNORE
 resource_back.name="MainResourcePanel"
 var resource_style=_style(Color("0e1923"),Color("293e47"),10);resource_style.shadow_size=0;resource_style.set_border_width_all(1)
 resource_back.add_theme_stylebox_override("panel",resource_style)
 _place(resource_back,Rect2(0,599,375,96))
 if include_tools:
  var tool_back=Panel.new();tool_back.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var tool_style=_style(Color("101c27"),Color("615439"),14);tool_style.set_border_width_all(1);tool_style.shadow_size=3
  tool_back.add_theme_stylebox_override("panel",tool_style)
  tool_back.name="ResourceToolsPanel"
  _place(tool_back,Rect2(0,699,375,201))
 if has_turn_controls:
  var divider=ColorRect.new();divider.color=Color("35464b");divider.mouse_filter=Control.MOUSE_FILTER_IGNORE
  _place(divider,Rect2(160,781,199,1))
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
  _place(caption,Rect2(18,center-12,64,24))
  _resource_meter(meter.id,Rect2(90,center-bar_height/2,269,bar_height),meter.value,meter.maximum,meter.color)
  if meter.id=="MainGuardBind": _guard_bind_drop_target(Rect2(12,center-14,351,28),"SidebarGuardBindTarget")
 var mana_bar=find_child("MainMana",true,false)
 mana_bar.mouse_filter=Control.MOUSE_FILTER_STOP;mana_bar.tooltip_text="嘴部施法成功率 · "+view.casting.percent+"\n临时魔力优先抵扣法术和卡牌耗魔，不受上限限制；不能存瓶或购物，本场结束清空。"
 if include_tools: preload("res://ui/mana_flask.gd").build(self)
 if not has_turn_controls: return
 var orb=TextureRect.new();orb.name="EnergyMedallion";orb.mouse_filter=Control.MOUSE_FILTER_PASS
 orb.tooltip_text="能量上限：%d。每回合恢复至上限，再结算额外能量与惩罚。" % view.energy_max
 orb.texture=preload("res://assets/ui/energy-medallion.svg");orb.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;orb.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 _place(orb,Rect2(44,782,102,102))
 var energy=_label(str(view.energy),43,TEXT); energy.name="EnergyValue";energy.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _place(energy,Rect2(5,17,92,64),orb)
 if view.phase=="battle":
  var powers=_button("能力区 · %d" % view.powers.size(),func():_open_drawer("show_deck","powers"),GOLD)
  powers.name="OpenPowers";powers.add_theme_font_size_override("font_size",15);_place(powers,Rect2(161,790,198,36))
 var draw_button=_button("抽牌堆  %d" % view.draw_count,func():_open_drawer("show_deck","draw"));draw_button.name="DrawPileButton"
 draw_button.icon=preload("res://assets/ui/draw-pile.svg");draw_button.add_theme_font_size_override("font_size",16);draw_button.add_theme_constant_override("h_separation",12)
 _place(draw_button,Rect2(161,835,198,42))
 var discard_button=_button("弃牌堆\n%d" % view.discard_count,func():_open_drawer("show_deck","discard"));discard_button.name="DiscardPileButton"
 _place(discard_button,Rect2(1327,786,82,70))
 for c in actions.select("flow"):
  var b=_button(c.label,func(): _submit(c),CYAN if c.payload.kind=="end" else GOLD)
  _place(b,Rect2(1424,735 if c.payload.kind=="end" else 837,155,90 if c.payload.kind=="end" else 38))
  candidate_buttons[c.id]=b
  if c.payload.kind=="end":
   end_button=b;b.name="EndTurnButton";b.add_theme_font_size_override("font_size",24)
   b.disabled=not c.valid;b.tooltip_text=c.reason
   if view.end_turn_locked:
    var seal=TextureRect.new();seal.name="EndTurnLockPattern"
    seal.texture=preload("res://assets/ui/end-turn-locked.svg")
    seal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;seal.stretch_mode=TextureRect.STRETCH_SCALE
    seal.mouse_filter=Control.MOUSE_FILTER_IGNORE
    _place(seal,Rect2(0,0,155,90),b)
 var surrender=actions.find("surrender")
 if not surrender.is_empty():
  var button=_button("确定要投降吗" if surrender_version==view.version else "投降",func():pass,RED)
  button.name="SurrenderButton";button.add_theme_font_size_override("font_size",16)
  button.add_theme_stylebox_override("normal",_style(Color("4a2228"),RED,8))
  button.add_theme_stylebox_override("hover",_style(Color("683039"),RED,8))
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
 var placement=_posture_layout(actions.select("posture").filter(func(action):return action.payload.adjacent and not action.payload.wall).size())
 if not c.valid and (c.payload.distance>0 or not view.guard_bind.is_empty()):
  text=c.reason if placement.with_move and placement.stride<48 else text+"\n"+c.reason
 var btn=_button(text,func():_submit(c),GOLD)
 btn.name="WallMove_toward";btn.disabled=not c.valid
 btn.add_theme_font_size_override("font_size",11 if placement.with_move and placement.stride<48 else 13)
 btn.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 btn.tooltip_text=detail_of(c) if c.valid else c.reason
 if placement.with_move:
  btn.custom_minimum_size.y=placement.stride-4
  for state_name in ["normal","hover","pressed","focus","disabled"]:
   var style=btn.get_theme_stylebox(state_name).duplicate()
   style.content_margin_top=2;style.content_margin_bottom=2
   btn.add_theme_stylebox_override(state_name,style)
 _place(btn,Rect2(1330,placement.top if placement.with_move else 493,249,placement.stride-4 if placement.with_move else 47))
 candidate_buttons[c.id]=btn

func _body_at(slot: String) -> Dictionary:
 return TargetQueries.body_at(view,slot)

func _body_card_actions(slot: String, uid: String) -> Array:
 return TargetQueries.body_cards(actions,_body_at(slot),uid)

func _body_drawer() -> void:
 layout.body_sidebar(self)
 if not _selecting_hand() and (show_body or selected_card!="" or view.pending_retain): _body_details()

func _body_equipment_entries(body: Dictionary) -> Dictionary:
 return TargetQueries.equipment_entries(body)

func _single_body_card_action(slot: String, uid: String) -> Dictionary:
 return TargetQueries.single_body_card(actions,_body_at(slot),uid,card_faces.get(uid,false))

func _single_restraint_card_action(uid: String) -> Dictionary:
 return TargetQueries.single_equipment_card(actions,view.body_groups,uid,card_faces.get(uid,false))

func _body_details() -> void:
 var compact=selected_card!="" and not _single_body_card_action(selected_slot,selected_card).is_empty() and view.guard_bind.is_empty()
 var sidebar=find_child("BodyEquipmentPanel",true,false)
 var detail_x=sidebar.position.x+sidebar.size.x+10 if sidebar!=null else 344.0
 var panel=_panel(Rect2(detail_x,100,448,350 if compact else 440 if quick_release_open else 470));panel.name="EquipmentDetails";panel.z_index=180
 var v=VBoxContainer.new();v.add_theme_constant_override("separation",8);panel.add_child(v)
 var heading=HBoxContainer.new();v.add_child(heading)
 var title=_label(_body_at(selected_slot).name+" · 解缚",20,GOLD);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
 var book=_button("教程",func():_open_tutorial("equipment"),CYAN);book.name="EquipmentTutorial";heading.add_child(book)
 var close=_button("关闭 ×",func():show_body=false;selected_card="";selected_candidate="";player_pick=false;render(view),MUTED)
 close.name="CloseEquipmentDetails";heading.add_child(close)
 preload("res://ui/release_details.gd").region_summary(self,v,_body_at(selected_slot))
 var content=_scroll(v)
 if view.pending_retain:
  content.add_child(_label("还可保留%d张，保留至下回合结束" % view.retain_left,16,CYAN))
  for c in actions.select("retain"): _action_row(content,c)
 elif selected_card!="" and view.hand.any(func(c):return c.uid==selected_card):
  var card=view.hand.filter(func(c):return c.uid==selected_card)[0]
  content.add_child(_label(card.name,22,CYAN))
  var bind_action=actions.find("card",{"uid":selected_card,"target":"guard_bind","free":card_faces.get(selected_card,false)})
  if not bind_action.is_empty():
   _card_target(content,bind_action,false,v)
   content.add_child(HSeparator.new())
  var choices=_body_card_actions(selected_slot,selected_card)
  var single=_single_body_card_action(selected_slot,selected_card)
  if not single.is_empty(): selected_candidate=single.id
  for c in choices:
   if c.payload.free==card_faces.get(selected_card,false): _card_target(content,c,not single.is_empty(),v)
   elif not choices.any(func(other):return other.payload.free==card_faces.get(selected_card,false)):
    var face_name=card_face_name(card.type,card.uid,c.payload.free)
    if face_name!="": content.add_child(_label("请右键切换到"+face_name+"。",14,RED))
 else:
  var body=_body_at(selected_slot)
  var members=body.get("members",[body])
  var shown={};var free_names=[];var all_entries=_body_equipment_entries(body)
  for member in members:
   var entries=_body_equipment_entries(member)
   if entries.is_empty():
    if members.size()==1: free_names.append_array(member.sections.map(func(part):return part.name))
    else: free_names.append(member.name)
    continue
   var fresh=entries.keys().filter(func(id):return not shown.has(id))
   if members.size()==1:
    for part in member.sections:
     if part.equipment.is_empty(): free_names.append(part.name)
   if fresh.is_empty(): continue
   if members.size()>1: content.add_child(_label(member.name,16,CYAN))
   var grid=_equipment_grid(content)
   for id in fresh:
    var entry=all_entries[id];shown[id]=true
    _equipment_tile(grid,entry.equipment,"、".join(entry.locations),(entries.size()==1 and members.size()==1) or (quick_release_open and id==quick_release_inspected))
  if not free_names.is_empty(): content.add_child(_label("自由："+"、".join(free_names),12,MUTED))
  if view.phase=="rest": content.add_child(_label("休息房只能使用卡牌拘束效果。",13,CYAN))

func _equipment_grid(parent: Node) -> GridContainer:
 var grid=GridContainer.new();grid.columns=1
 grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 grid.add_theme_constant_override("h_separation",8)
 grid.add_theme_constant_override("v_separation",8)
 parent.add_child(grid)
 # One vertical sequence per body section makes physical layers legible.
 return grid

# Shared presentation only: each card retains its projected physical target.
func _equipment_tile(parent: Node, e: Dictionary, location: String="", expanded: bool=false) -> void:
 var card=PanelContainer.new();card.name="EquipmentCard_"+e.id
 card.set_meta("equipment_id",e.id)
 card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 card.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 card.custom_minimum_size=Vector2(158,0)
 var accent=RED if e.tier==3 else (CYAN if e.linked else GOLD)
 card.add_theme_stylebox_override("panel",_style(Color("192a38"),accent.darkened(0.35),10))
 parent.add_child(card)
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",5);card.add_child(box)
 preload("res://ui/release_details.gd").equipment_header(self,box,e,location,accent)
 for c in actions.select("manual",{"target":e.id}):
  if c.valid and c.payload.after==0.0:
   var release=_button("一键解除 · %d能量" % c.cost,func():_submit(c),CYAN)
   release.name="QuickRelease_"+e.id
   box.add_child(release);candidate_buttons[c.id]=release
 var details=VBoxContainer.new();details.name="EquipmentActions";details.visible=expanded
 var toggle=_button("收起详情 −" if expanded else "查看详情 ＋",func():pass,MUTED)
 toggle.pressed.connect(func():
  details.visible=not details.visible
  if details.visible and details.get_child_count()==0: _equipment_actions(details,e)
  toggle.text=localization.display("收起详情 −" if details.visible else "查看详情 ＋"))
 toggle.name="EquipmentCardDetailsToggle";toggle.custom_minimum_size.y=26
 toggle.size_flags_horizontal=Control.SIZE_SHRINK_END
 for state in ["normal","hover","pressed","focus","disabled"]:
  var style=toggle.get_theme_stylebox(state).duplicate()
  style.content_margin_top=3;style.content_margin_bottom=3
  toggle.add_theme_stylebox_override(state,style)
 toggle.add_theme_font_size_override("font_size",12);box.add_child(toggle)
 box.add_child(details)
 if expanded: _equipment_actions(details,e)

func _equipment_actions(details: VBoxContainer, e: Dictionary) -> void:
 var description=_label(e.description,12,MUTED);description.visible=false
 var more=_button("装备说明 ＋",func():description.visible=not description.visible,MUTED)
 more.name="EquipmentDescriptionToggle"
 more.custom_minimum_size.y=24;more.add_theme_font_size_override("font_size",11)
 details.add_child(more);details.add_child(description)
 for c in actions.select("attack",{"target":e.id}):
  _action_row(details,c)
  candidate_buttons[c.id].name="EquipmentSpell_"+e.id
 for c in actions.select("manual",{"target":e.id}):
  if not c.valid or c.payload.after!=0.0: _action_row(details,c)
 _localize_controls(details)

func _equipment_card_face(box: Node,e: Dictionary,location: String,accent: Color,compact: bool=false) -> void:
 if location!="": box.add_child(_label(location,12,CYAN))
 var name_label=_label(e.name,14,GOLD);name_label.custom_minimum_size.y=0 if compact else 36;box.add_child(name_label)
 box.add_child(_label(e.material_name,11,MUTED))
 if not e.get("lock_only",false):
  box.add_child(_label("耐久 %s / %s" % [game.number(e.durability),game.number(e.maximum)],12,TEXT))
  var meter=_bar(e.durability,e.maximum,accent);meter.custom_minimum_size.y=6;box.add_child(meter)
 var tightness=HBoxContainer.new();box.add_child(tightness)
 var tier_label=_label("无耐久" if e.get("lock_only",false) else "紧度 %d档" % e.tier,12,accent)
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
 if c.has("release_preview") and c.valid: preload("res://ui/release_details.gd").preview(self,parent,c)
 else: parent.add_child(_label(detail_of(c) if c.valid else c.reason,14,MUTED if c.valid else RED))
 if c.risk!="" and c.valid: parent.add_child(_label(c.risk,13,RED))

func _card_target(parent: Node,c: Dictionary, automatic: bool=false, footer: Node=null) -> void:
 if automatic:
  parent.add_child(_label(c.label,16,CYAN if c.valid else MUTED))
 else:
  var b=_button(c.label,func(): selected_candidate=c.id; render(view),CYAN)
  b.name="CardTarget_"+c.payload.target;b.disabled=not c.valid
  DragTargets.focus(self,b,c.valid)
  parent.add_child(b)
 var equipment=_body_at(selected_slot).targets.get(c.payload.target,{})
 if not equipment.is_empty(): parent.add_child(_label(equipment.position_text+" · "+equipment.get("layer_label",""),12,MUTED))
 if not c.valid: parent.add_child(_label(c.reason,14,RED))
 elif c.risk!="": parent.add_child(_label(c.risk,14,RED))
 if selected_candidate==c.id and c.valid:
  if c.has("release_preview"): preload("res://ui/release_details.gd").preview(self,parent,c)
  else: parent.add_child(_label(detail_of(c),15,TEXT))
  var fee=str(c.cost)+"能量"+(" / "+game.number(c.mana)+"魔力" if c.mana>0 else "")
  var commit=_button("打出 · "+fee,func(): _submit(c),CYAN)
  commit.name="PlaySelectedCard"
  (footer if footer!=null else parent).add_child(commit); candidate_buttons[c.id]=commit

func _rewards() -> void:
 preload("res://ui/reward_screen.gd").build(self)

func _practice_screen() -> void:
 var panel=_panel(Rect2(415,172,1100,506))
 var v=VBoxContainer.new(); v.add_theme_constant_override("separation",20); panel.add_child(v)
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
 var panel=_panel(Rect2(405,158,895,652));panel.name="PrisonIntakePanel"
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",24);panel.add_child(row)
 var left=VBoxContainer.new();left.custom_minimum_size.x=300;row.add_child(left)
 var artwork=PanelContainer.new();artwork.name="PrisonIntakeArtwork";artwork.custom_minimum_size=Vector2(300,520)
 artwork.add_theme_stylebox_override("panel",_style(Color("111923"),GOLD.darkened(0.5)));left.add_child(artwork)
 artwork.add_child(_guard_portrait(game.Prison.SENIOR_GUARD,Vector2(300,520)))
 var right=VBoxContainer.new();right.name="PrisonIntakeContent";right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",12);row.add_child(right)
 right.add_child(_label("监狱收押",25,GOLD))
 var banner=PanelContainer.new();banner.name="PrisonIntakeBanner";banner.custom_minimum_size.y=64
 banner.add_theme_stylebox_override("panel",_style(Color("10221e"),Color("8fdfba")));right.add_child(banner)
 var banner_label=_label("✓  收押完成",30,Color("8fdfba"));banner_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;banner.add_child(banner_label)
 var prose=_scroll(right);prose.name="PrisonIntakeNarrative";prose.get_parent().name="PrisonIntakeNarrativeScroll"
 var scene=view.capture.get("intake_scene",{})
 if scene.is_empty():
  prose.add_child(_label("棕发狱警把你押到牢门前，逐件收紧新添的拘束，最后在登记板上盖下印章。",18,TEXT))
 else:
  prose.add_child(_label(scene.opening,18,TEXT))
  prose.add_child(_label("“%s”" % scene.guard_intro,18,CYAN))
  for line in scene.restraints: prose.add_child(_label(line,17,TEXT))
  for line in scene.links: prose.add_child(_label(line,17,TEXT))
  for line in scene.toys: prose.add_child(_label(line,17,TEXT))
  prose.add_child(_label(scene.milking,18,TEXT))
  prose.add_child(_label(scene.closing,18,TEXT))
  prose.add_child(_label("“%s”" % scene.guard_done,18,CYAN))
 var climax=scene.get("climax",{})
 right.add_child(_label("警戒度 %d　·　没收道具 %d件　·　榨取魔力 %s" % [view.security,view.capture.confiscated,game.number(climax.get("mana_lost",0.0))],15,MUTED))
 right.add_child(HSeparator.new())
 var options=VBoxContainer.new();options.name="PrisonIntakeChoices";options.add_theme_constant_override("separation",8);right.add_child(options)
 for c in actions.select("prison"): preload("res://ui/event_screen.gd").action(self,options,c)
 if view.practice:
  left.add_child(_button("再次挑战",func(): restart(view.seed,true,view.practice_kind),CYAN))
 else:
  left.add_child(_button("重新开始",func(): restart(view.seed),CYAN))
 left.add_child(_button("其他练习",func():_open_drawer("show_settings")))

func _inspection_screen() -> void:
 if view.phase in ["pack","prison_end"]:
  var flow_panel=_panel(Rect2(397,158,1140,530))
  var flow=VBoxContainer.new();flow.add_theme_constant_override("separation",14);flow_panel.add_child(flow)
  if view.phase=="pack":
   flow.add_child(_label("整理随身道具",29,GOLD))
   flow.add_child(_label("反抗战后的整备结束。先使用或放弃超出容量的工具，再返回牢房；巡视继续暂停。",20))
   flow.add_child(_button("打开道具栏",func():_open_drawer("show_items"),CYAN))
   for c in actions.select("flow"): _action_row(flow,c)
  else:
   flow.add_child(_label("本次逃脱失败",29,RED))
   flow.add_child(_label("监狱警戒度已经达到5，普通逃脱流程结束。",21))
   flow.add_child(_label(view.prison.terminal_text,18,GOLD))
   flow.add_child(_label("可在左侧查看最终装备；选择重新开始会替换本局进度。",17,MUTED))
   flow.add_child(_button("重新开始一局",func():restart(view.seed),CYAN))
  return
 var panel=_panel(Rect2(405,158,895,652));panel.name="PrisonInspectionPanel"
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",24);panel.add_child(row)
 var left=VBoxContainer.new();left.custom_minimum_size.x=300;row.add_child(left)
 var artwork=PanelContainer.new();artwork.name="PrisonInspectionArtwork";artwork.custom_minimum_size=Vector2(300,520)
 artwork.add_theme_stylebox_override("panel",_style(Color("111923"),GOLD.darkened(0.5)));left.add_child(artwork)
 if view.phase=="inspection": artwork.add_child(_guard_portrait(view.prison.get("guard_visual",game.Prison.PATROL_GUARD),Vector2(300,520)))
 var v=VBoxContainer.new();v.size_flags_horizontal=Control.SIZE_EXPAND_FILL;v.add_theme_constant_override("separation",14);row.add_child(v)
 var p=view.prison
 v.add_child(_label("狱警巡视",25,GOLD))
 var status=p.get("result_status","neutral")
 var tone=Color("8fdfba") if status=="success" else (Color("ff8797") if status=="failure" else GOLD)
 var banner=PanelContainer.new();banner.name="PrisonInspectionBanner";banner.custom_minimum_size.y=64
 banner.set_meta("result_status",status);banner.add_theme_stylebox_override("panel",_style(Color(tone.r*0.14,tone.g*0.14,tone.b*0.14,1),tone));v.add_child(banner)
 var banner_text={"arrival":"◇  巡视开始","result":"✓  登记无误" if status=="success" else "×  发现问题","done":"✓  检查通过" if status=="success" else "×  处罚执行"}[p.stage]
 var banner_label=_label(banner_text,30,tone);banner_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;banner.add_child(banner_label)
 var prose=_scroll(v);prose.name="PrisonInspectionNarrative";prose.get_parent().name="PrisonInspectionNarrativeScroll"
 if p.get("narrative","")!="": prose.add_child(_label(p.narrative,18,TEXT))
 if p.get("guard_dialogue","")!="": prose.add_child(_label("“%s”" % p.guard_dialogue,18,CYAN))
 if p.stage!="arrival" and p.report!="": prose.add_child(_label(p.report,18,TEXT))
 v.add_child(_label(p.sentence,15,MUTED))
 v.add_child(HSeparator.new())
 var options=VBoxContainer.new();options.name="PrisonInspectionChoices";options.add_theme_constant_override("separation",8);v.add_child(options)
 for c in actions.select("prison"): EventScreen.action(self,options,c)

func _prison_controls() -> void:
 var p=view.prison
 var panel=_panel(Rect2(803,155,735,337));panel.name="PrisonControls"
 var v=VBoxContainer.new();v.add_theme_constant_override("separation",8);panel.add_child(v)
 var heading=HBoxContainer.new();v.add_child(heading)
 var title=_label("巡视暂停" if p.paused else "巡视剩余 %d 回合" % p.left,20,GOLD)
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
 var remaining=_label("待探索 %d" % p.remaining,16,MUTED);remaining.name="PrisonRemaining";remaining.autowrap_mode=TextServer.AUTOWRAP_OFF;heading.add_child(remaining)
 var sentence=_label(p.sentence,16,CYAN);sentence.name="PrisonSentence";v.add_child(sentence)
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
  var tile=PanelContainer.new();tile.name="PrisonSite_"+site.id
  tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  tile.add_theme_stylebox_override("panel",_style(Color("192a38"),CYAN if site.here or (p.space.blind and site.near) else GOLD.darkened(0.5),8));grid.add_child(tile)
  var box=VBoxContainer.new();box.add_theme_constant_override("separation",4);tile.add_child(box)
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
 button.disabled=not c.valid;button.tooltip_text=detail_of(c) if c.valid else c.reason
 parent.add_child(button);candidate_buttons[c.id]=button
 if not c.valid: parent.add_child(_label(c.reason,13,RED))
 elif c.risk!="": parent.add_child(_label(c.risk,13,RED))
 elif c.payload.kind in ["item_install","item_retrieve"]: parent.add_child(_label(detail_of(c),13,CYAN))

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
 if c.valid: box.add_child(_label(detail_of(c),13,CYAN))

func _door_candidate(data: Dictionary) -> Dictionary:
 if data.get("version",-1)!=view.version or data.get("free",true): return {}
 return actions.first_usable("prison",{"action":"unlock","uid":data.get("card_uid","")})

func _route_screen() -> void:
 var current=view.route.filter(func(r):return r.current)[0].id
 if view.tower_start_pending:
  var starts=view.route.filter(func(r):return r.status=="available")
  if not starts.is_empty(): current=starts[0].id
 if map_current_room!=current:
  map_current_room=current; map_scroll_value=-1; route_focus=current
 if not view.route.any(func(r):return r.id==route_focus): route_focus=current
 var panel=_panel(Rect2(376,68,1212,820));panel.name="RouteWorkspace"
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);panel.add_child(row)
 var map_column=VBoxContainer.new();map_column.name="RouteMapColumn"
 map_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 map_column.add_theme_constant_override("separation",4);row.add_child(map_column)
 if view.tower_start_pending:
  var title=_label("选择出狱起点 · 第10—11层非休息、非宝箱区域 · 不消耗回合",20,GOLD)
  title.name="PrisonStartTitle";map_column.add_child(title)
 var relic_strip=layout.find_child("RelicStrip",true,false)
 if relic_strip!=null:
  relic_strip.reparent(map_column)
  relic_strip.custom_minimum_size=Vector2(0,48)
  relic_strip.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  relic_strip.position=Vector2.ZERO
 var scroll=ScrollContainer.new(); scroll.name="TowerMapScroll"
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 map_column.add_child(scroll)
 var graph=RouteMap.new(); graph.name="TowerRoute"
 graph.region_name=view.map_name
 graph.localize=localization.display
 graph.rooms=view.route; graph.selected=route_focus
 var drawing_key=view.map_name+str(view.seed)+JSON.stringify(view.route.map(func(room):return [room.id,room.floor,room.lane,room.paths.map(func(path):return path.to)]))
 if not map_drawings.has(drawing_key): map_drawings[drawing_key]=[]
 graph.strokes=map_drawings[drawing_key]
 graph.drawings_changed.connect(_save_progress)
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
 var right=VBoxContainer.new();right.name="RouteMessages";right.custom_minimum_size.x=220;row.add_child(right)
 for room in view.route:
  if room.icon=="boss":
   var boss_title=_label(room.name,20,GOLD)
   boss_title.name="TowerBossPreview";right.add_child(boss_title)
 var title_row=HBoxContainer.new();title_row.add_theme_constant_override("separation",8);right.add_child(title_row)
 var title=_label("移动消息",20,GOLD);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_row.add_child(title)
 # Run identity chip: the only view/copy entry, hung on the existing title row (no extra row).
 var chip=_button(_seed_chip_text(),copy_seed,CYAN)
 chip.name="SeedChip";chip.custom_minimum_size.x=118;chip.add_theme_font_size_override("font_size",12)
 chip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 chip.tooltip_text=seed_report_text()
 title_row.add_child(chip);seed_chip=chip
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
 # The single run review entry of this screen; it only opens the drawer (no candidate, no save).
 if RunReview.can_open(view.route):
  var review=_button(RunReview.title_text(self),func():_open_drawer("show_run_review"),CYAN)
  review.name="OpenRunReview";navigation.add_child(review)
 var drawing_tools=HBoxContainer.new();right.add_child(drawing_tools)
 var hint=_label("右键绘画",14,MUTED);hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL;drawing_tools.add_child(hint)
 var clear=_button("清除画线",func():graph.clear_strokes(),CYAN)
 clear.name="MapClearDrawing";drawing_tools.add_child(clear)

 for group in right.get_children():
  if group is HBoxContainer or group is GridContainer:
   for control in group.get_children():
    if control is Button and control!=chip:
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

# The four identity parts a player can quote. The identity is not a reproduction recipe:
# the current tower seed and the random counters move with play, so an exact replay needs
# the save that the same draft uploads (docs/spec/seed-identity.md).
func seed_report_text() -> String:
 return "紧缚尖塔 · 初始种子 %d · 第 %d 次塔路 · 当前塔路种子 %d（精确复现需同批上传的存档）" % [int(view.initial_seed),int(view.tower_generation)+1,int(view.seed)]

func copy_seed() -> String:
 var text=seed_report_text()
 DisplayServer.clipboard_set(text)
 seed_copied_until=Time.get_ticks_msec()+SEED_COPIED_MS
 _refresh_seed_chip(true)
 return text

func _seed_chip_text() -> String:
 if seed_copied_until>Time.get_ticks_msec(): return _text("ui.map.seed_copied","已复制")
 return _text("ui.map.seed","初始种子 {initial} · 第 {iteration} 次塔路",{"initial":int(view.initial_seed),"iteration":int(view.tower_generation)+1})

# The panel button is the route chip's second view: same copy entry, same deadline, same caption.
func _run_review_copy_text() -> String:
 if seed_copied_until>Time.get_ticks_msec(): return _text("ui.map.seed_copied","已复制")
 return _text("ui.run_review.copy","复制本局标识")

# Polled like speech: the deadline expires on its own frame, and a stale deadline can never
# rewrite a replaced run or a closed screen (no callback is kept at all, and a rebuilt control
# re-reads the deadline when it is created). copy_seed() forces the same writer so both views
# change together inside one window; a freed second view is skipped by the shared guard.
func _refresh_seed_chip(force: bool=false) -> void:
 if not force:
  if seed_copied_until<=0 or Time.get_ticks_msec()<seed_copied_until: return
  seed_copied_until=0
 if is_instance_valid(seed_chip): seed_chip.text=_seed_chip_text()
 if is_instance_valid(run_review_copy): run_review_copy.text=_run_review_copy_text()

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
  var room=graph.rooms.filter(func(r):return r.id==route_focus if view.tower_start_pending else r.current)[0]
  scroll.scroll_vertical=int(graph.point_for(room).y-scroll.size.y*0.62)
 map_scroll_value=scroll.scroll_vertical
 scroll.get_v_scroll_bar().value_changed.connect(func(value):map_scroll_value=int(value))

func _log_drawer() -> void:
 var v=_drawer_shell("行动日志",Rect2(650,150,870,560))
 var back=_button("返回菜单",func():_open_drawer("show_menu"),MUTED);back.name="LogBackToMenu";v.add_child(back)
 var scroll=_scroll(v)
 if view.action_log.is_empty(): scroll.add_child(_label("尚无行动记录。",14,MUTED))
 for i in range(view.action_log.size()-1,-1,-1):
  var note=view.action_log[i]
  scroll.add_child(_label(note.actor+" · 第%d回合" % note.round,13,CYAN))
  scroll.add_child(_label(note.text,14,TEXT))
  scroll.add_child(HSeparator.new())
 var toggle=_button("详细记录",func():pass,MUTED);toggle.name="LogDetails";toggle.toggle_mode=true;scroll.add_child(toggle)
 var details=VBoxContainer.new();details.name="LogDetailRows";details.visible=false;scroll.add_child(details)
 toggle.toggled.connect(func(visible: bool):details.visible=visible)
 for i in range(view.logs.size()-1,maxi(-1,view.logs.size()-45),-1):
  var e=view.logs[i]
  details.add_child(_label(("计算 · " if e.kind=="mechanical" else "")+e.text,14,MUTED))

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
 term_popup=_panel(Rect2(0,0,0,0));term_popup.name="TermExplanation";term_popup.z_index=260
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",10);term_popup.add_child(column)
 if entry.label!="": column.add_child(_label(entry.label,19,CYAN))
 if entry.detail!="": column.add_child(_label(entry.detail,15,TEXT))
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

func _position_term(anchor: Rect2) -> void:
 if not is_instance_valid(term_popup): return
 anchor=layout.get_global_transform().affine_inverse()*anchor
 term_popup.size=term_popup.get_combined_minimum_size()
 var x=anchor.end.x+12
 if is_instance_valid(drop_panel) and is_instance_valid(term_anchor) and drop_panel.is_ancestor_of(term_anchor): x=drop_panel.position.x+drop_panel.size.x+10
 if x+term_popup.size.x>1580: x=anchor.position.x-term_popup.size.x-12
 term_popup.position=Vector2(clampf(x,20,maxf(20,1580-term_popup.size.x)),clampf(anchor.position.y,74,maxf(74,886-term_popup.size.y)))

func _speech_bubble(point_to_hero: bool=true) -> void:
 if view.speech.is_empty(): return
 if _takeover_locked():
  _skip_hero_speech(view.speech);return
 if suppressed_hero_speech_id=="hero:"+str(view.speech.id): return
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
  var center=HERO_STAGE_RECT.get_center().x
  var tail=Polygon2D.new();tail.polygon=PackedVector2Array([Vector2(center-8,177),Vector2(center+8,177),Vector2(center,192)]);tail.color=Color(0.055,0.09,0.135,0.97);speech_group.add_child(tail)
 _ignore_mouse(speech_group)

func _guard_portrait(visual: String, minimum: Vector2) -> TextureRect:
 var portrait=TextureRect.new();portrait.name="PrisonGuardPortrait";portrait.custom_minimum_size=minimum
 portrait.texture=Arena.Art.GUARD_PORTRAITS.get(visual,Arena.Art.GUARD_PORTRAITS.guard_purple)
 portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 portrait.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return portrait

func _npc_speech_bubble() -> void:
 var entry=view.get("npc_speech",{})
 if entry.is_empty(): return
 var release_after_inspection=entry.get("cue","")=="prison.guard.release_pass" and view.get("tower_start_pending",false)
 if entry.get("phase","")!=view.phase and not release_after_inspection: return
 if not _speech_visible("npc:"+str(entry.id)): return
 speech_group=Control.new();speech_group.name="NpcSpeechGroup";speech_group.mouse_filter=Control.MOUSE_FILTER_IGNORE
 speech_group.z_index=220;_place(speech_group,Rect2(0,0,0,0))
 var panel=_panel(Rect2(930,72,472,112));panel.name="NpcSpeech";panel.reparent(speech_group)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);panel.add_child(row)
 row.add_child(_guard_portrait(entry.get("visual",game.Prison.PATROL_GUARD),Vector2(64,64)))
 var body=_label(entry.text,15,TEXT);body.name="NpcSpeechText"
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.size_flags_vertical=Control.SIZE_EXPAND_FILL
 body.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(body)
 _ignore_mouse(speech_group)

func _feedback_entry() -> void:
 var report_button=_button("问题与建议",feedback_report.open,CYAN);report_button.name="OpenFeedback"
 _place(report_button,Rect2(570,66,138,32) if view.phase=="shop" else Rect2(1438,82,138,34))

func handle_portrait_input(event: InputEvent) -> bool:
 return is_instance_valid(layout) and is_instance_valid(layout.body) and layout.body.handle_portrait_input(event)

func _input(event: InputEvent) -> void:
 if _takeover_locked():
  get_viewport().set_input_as_handled();return
 var inspection=modal_region()
 if inspection!=null and inspection.has_method("dismiss") and event.is_action_pressed("ui_cancel"):
  inspection.dismiss();get_viewport().set_input_as_handled();return
 if handle_portrait_input(event):
  get_viewport().set_input_as_handled();return
 if is_instance_valid(keyboard_input) and keyboard_input.handle(event):
  get_viewport().set_input_as_handled();return
 if player_pick and event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  _clear_player_picker();selected_card="";render(view);return
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT: _dismiss_speech()
 if (show_tutorial or show_encyclopedia or show_deck or show_event_selection) and event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  _close_drawers();_refresh_drawers();return

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

func _submit(c: Dictionary, expected_version: int=-1, takeover: bool=false) -> void:
 if _takeover_locked() and not takeover: return
 surrender_version=-1
 if show_home or is_instance_valid(enemy_feedback): return
 if c.valid and not c.get("automated",false) and c.payload.kind=="card" and c.payload.has("hand_uid") and not c.payload.get("self_target",false) and not _selecting_hand():
  _use_self_card(c,view.version if expected_version<0 else expected_version);return
 var previous=view
 var previous_cards=preload("res://ui/card_motion.gd").positions(self)
 var feedback_anchor=Vector2(560,250)
 if actor_targets.has("hero"):
  var bounds=actor_targets.hero.get_global_rect()
  feedback_anchor=Vector2(bounds.get_center().x,bounds.position.y)
 var result=game.dispatch(c.id,view.version if expected_version<0 else expected_version)
 var updated=game.get_view()
 # Consume automated speech even when the last command has already ended takeover.
 if takeover: _skip_hero_speech(updated.speech)
 notice="" if result.ok else result.error
 if result.ok:
  preload("res://ui/shell/body_sidebar.gd").expand_applied(self,previous,updated)
  if c.payload.get("witch_action",false) and not c.payload.charge_action: attack_forms[c.payload.type]=0
  # docs/save-fixed-points.md §2／§5.1：只有提交结果带非空 checkpoint 才写盘；
  # 不比较内容、不读快照，其余提交一律不写。
  if String(result.get("checkpoint",""))!="": _save_progress()
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
 if takeover and is_instance_valid(takeover_presenter): takeover_presenter.outcome(result,previous,updated,c)
 if result.ok and c.payload.kind=="demo_end":
  _return_home()
  return
 if result.ok:
  if not is_instance_valid(resource_feedback):
   resource_feedback=preload("res://ui/resource_feedback.gd").new();resource_feedback.host=self;add_child(resource_feedback)
  # 快感与精神集中由瞬时层呈现（粉滤镜／蓝边框），不再另出浮字：只有这两处在同一提交里各自展示一次。
  var instant_fields=["pressure","witch_focus"]
  if c.payload.kind=="flask": instant_fields=["mana","flask_mana","pressure","witch_focus"]
  resource_feedback.enqueue(result.get("resource_feedback",[]),feedback_anchor,instant_fields)
  _impact_feedback(result.get("resource_feedback",[]),c.payload,updated)
  _animate_cards(result.get("card_feedback",[]),previous_cards)
  card_music.consume(result.get("music_feedback",[]),updated.phase,show_home)
  CombatFeedback.play(self,previous,c.payload)

func _demo_exit_screen() -> void:
 if is_instance_valid(card_motion): card_motion.clear()
 if is_instance_valid(resource_feedback):
  remove_child(resource_feedback);resource_feedback.queue_free();resource_feedback=null
 _clear_impact_feedback()
 # Tall enough for the exit actions, the finished-run menu button and the run review entry.
 var panel=_panel(Rect2(460,220,680,520));panel.name="DemoExitPanel"
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",24);panel.add_child(column)
 var title=_label("感谢游玩这次demo",36,GOLD);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(title)
 var subtitle=_label("第%s阶段完成" % ["一","二","三"][view.demo_cycle],22,CYAN);subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(subtitle)
 for c in actions.select("demo_exit"):
  _action_row(column,c)
 if RunReview.can_open(view.route):
  var review=_button(RunReview.title_text(self),func():_open_drawer("show_run_review"),CYAN)
  review.name="OpenRunReview";column.add_child(review)
 if view.demo_finished:
  column.add_child(_button("返回菜单",_return_home,CYAN))

func restart(seed_value: int, practice: bool=false, practice_kind: String="equipment") -> void:
 save_suspended=false
 game=game_factory.new(seed_value,practice,practice_kind,true,display_settings.chastity_locks_enabled and not display_settings.fixed_hero_portrait,display_settings.chastity_lock_chance,display_settings.cursed_plate_start,display_settings.cursed_plate_masochist_mode,selected_character)
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

func _impact_feedback(events: Array, payload: Dictionary, snapshot: Dictionary) -> void:
 if not ImpactFeedback.will_play(events,payload): return
 if not is_instance_valid(impact_feedback):
  impact_feedback=ImpactFeedback.new();impact_feedback.host=self;add_child(impact_feedback)
 impact_feedback.play(events,payload,snapshot)

func _clear_impact_feedback() -> void:
 if not is_instance_valid(impact_feedback): return
 remove_child(impact_feedback)
 impact_feedback.queue_free()
 impact_feedback=null

func _reset_interface(initial: Dictionary) -> void:
 if is_instance_valid(layout) and is_instance_valid(layout.body): layout.body.set_portrait_expanded(false)
 if is_instance_valid(card_music): card_music.stop_music()
 if is_instance_valid(keyboard_input): keyboard_input.clear()
 surrender_version=-1
 speech_id="";suppressed_hero_speech_id="";speech_deadline=0
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
 _clear_impact_feedback()
 event_read_page=""
 show_home=false;session_started=true
 if is_instance_valid(enemy_feedback): enemy_feedback.finish()
 map_auto_travel=false;travel_log_scroll=-1;travel_log_count=0
 _clear_drop_targets()
 _close_drawers()
 seed_text=str(initial.seed)
 status_filter="all"
 selected_card=""; selected_candidate=""; selected_slot=initial.practice_focus if initial.practice else "wrist"; selected_enemy=""
 quick_release_open=false;quick_release_region="";quick_release_parts.clear();quick_release_targets.clear();quick_release_inspected=""
 notice=""; show_body=false;expanded_body_regions.clear(); show_route=false;prison_detail=""
 card_faces.clear()
 card_draw_serials.clear()
 selected_item=""
 route_focus=""; map_current_room=""; map_scroll_value=-1; map_overview=false
 map_drawings.clear()
 player_pick=false
 player_pick_data={}

func _unhandled_key_input(event: InputEvent) -> void:
 if _takeover_locked():
  get_viewport().set_input_as_handled();return
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
 if not is_instance_valid(layout): return null
 for id in ["CardArtInspection","ShopPaymentPerformance"]:
  var panel=layout.get_node_or_null(id)
  if panel!=null and panel.is_visible_in_tree() and not panel.is_queued_for_deletion(): return panel
 return null

func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_GO_BACK_REQUEST and _takeover_locked(): return
 if what==NOTIFICATION_DRAG_BEGIN: _begin_target_drag.call_deferred()
 if what==NOTIFICATION_WM_GO_BACK_REQUEST:
  touch_input.cancel();_hide_term()
  if touch_input.dismiss_popup(): return
  var modal=modal_region()
  if modal!=null:
   if modal.has_method("dismiss"): modal.dismiss();return
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
   var face_name=card_face_name(c.payload.type,c.payload.get("uid",""),c.payload.free)
   if face_name!="": reason="请右键切换到"+face_name+"。"
  if data.version!=view.version: reason="状态已变化，请重新拖牌。"
  var effect=reason
  if reason=="":
   if c.payload.has("preview"):
    var damage_type=preload("res://data/card_rules.gd").damage_type(c.payload.type,c.payload.free) if c.payload.kind=="card" else c.payload.get("damage_type",c.payload.get("mode",""))
    effect="%s点%s伤害" % [game.number(c.payload.preview.damage),{"strain":"挣扎","slip":"滑脱","cut":"切割"}.get(damage_type,"")]
   elif c.payload.has("after"): effect="耐久降至%s" % game.number(c.payload.after)
   elif c.payload.get("free",false): effect=detail_of(c)
   elif c.payload.get("mode","")=="unlock": effect="开锁"
   else: effect=detail_of(c)
   if not c.payload.get("tool_bonus",{}).is_empty(): effect+="\n另加%s点切割伤害" % game.number(c.payload.tool_bonus.damage)
   if c.payload.get("preview",{}).get("release",false): effect+="\n整件脱下"
  var tone=RED if reason!="" or c.risk!="" else CYAN
  var target=_button("",func():
   if click_to_use and reason=="": _submit(c,int(data.version)),tone,true)
  target.name="EquipmentDropCard_"+c.payload.target
  target.disabled=click_to_use and reason!=""
  target.custom_minimum_size=Vector2(76,86);target.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var card=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  card.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
  card.add_child(target)
  var face=preload("res://ui/equipment_target_face.gd").new();face.accent=tone
  var title=body.name
  var detail=""
  if c.payload.target!="":
   var equipment=body.targets[c.payload.target]
   face.equipment=equipment
   title=equipment.name
  card.add_child(face)
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

func _actor_drop_area(rect: Rect2, parent: Control=null, interactive: bool=false) -> Button:
 var button=_button("",func(): pass,CYAN,true)
 for style in ["normal","pressed","focus"]: button.add_theme_stylebox_override(style,StyleBoxEmpty.new())
 button.add_theme_stylebox_override("hover",_style(Color(0.4,0.8,0.8,0.05),Color(0.5,0.85,0.85,0.6),12) if interactive else StyleBoxEmpty.new())
 button.set_meta("idle_interactive",interactive)
 return _place(button,rect,parent)

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

func _guard_bind_drop_target(rect: Rect2, node_name: String) -> Button:
 var target=_actor_drop_area(rect,null,true)
 target.custom_minimum_size=Vector2.ZERO;target.size=rect.size
 target.name=node_name;target.accepted_kind="card"
 target.tooltip_text=view.guard_bind.detail
 target.hover_card=func(data):
  var c=_guard_bind_card_candidate(data)
  _drag_rejection(target,"这张牌不能处理捕缚。" if c.is_empty() else ("" if c.valid else c.reason))
 target.accept_card=func(data):return _guard_bind_card_candidate(data).get("valid",false)
 target.receive_card=func(data):
  var c=_guard_bind_card_candidate(data)
  if not c.is_empty() and c.valid: call_deferred("_submit",c,int(data.version))
 target.pressed.connect(_activate_guard_bind_target)
 return target

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
 return TargetQueries.first_usable(matches)

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
 if quick_release_open and quick_release_region!="":
  var data={"card_uid":uid,"free":card_faces.get(uid,false),"version":view.version}
  var quick=preload("res://ui/quick_release_bar.gd").candidate(self,quick_release_region,data)
  if not quick.is_empty() and quick.valid:
   _submit(quick,int(data.version));return
  var matching=actions.select("card",{"uid":uid,"free":data.free})
  if matching.any(func(c):return c.payload.get("mode","") in TargetQueries.RELEASE_MODES):
   notice=quick.reason if not quick.is_empty() else preload("res://ui/quick_release_bar.gd").message(self,"wrong_card","这张牌不能用于当前选中的拘束具")
   selected_card=uid;selected_candidate="";show_body=false
   render(view);return
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
 _place(_label("自由效果禁用 · 不自然回魔"+(" · 练习工具已预置" if view.practice else ""),17,CYAN),Rect2(805,497,730,36))

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

func _installed_tools(placement: Rect2, parent: Control) -> void:
 if show_route or view.phase not in ["battle","prepare","rest","prison"]: return
 var installed=view.items.filter(func(item):return item.installed)
 if installed.is_empty(): return
 var panel=_panel(placement,parent);panel.name="InstalledTools"
 var frame=panel.get_theme_stylebox("panel").duplicate()
 frame.content_margin_top=3;frame.content_margin_bottom=3
 panel.add_theme_stylebox_override("panel",frame)
 var rows=_scroll(panel)
 
 for item in installed:
  var button=_button(item.fixed_label+"："+item.name+" · %d次" % item.uses,func():
   selected_item=item.id
   _open_drawer("show_items"),CYAN)
  button.name="InstalledTool_"+item.id
  button.custom_minimum_size.y=26
  button.add_theme_font_size_override("font_size",12)
  for state_name in ["normal","hover","pressed","focus","disabled"]:
   var style=button.get_theme_stylebox(state_name).duplicate()
   style.content_margin_top=2;style.content_margin_bottom=2
   button.add_theme_stylebox_override(state_name,style)
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
  var item_button=_button(item.name+"\n%s · 剩余%d次" % [item.mount,item.uses],func(): selected_item=item.id; selected_item_slot=""; item_help=false; _refresh_item_details(),CYAN if selected_item==item.id else MUTED)
  item_button.set_meta("selected_item",selected_item==item.id)
  item_button.alignment=HORIZONTAL_ALIGNMENT_LEFT;item_button.add_theme_font_size_override("font_size",15)
  item_button.custom_minimum_size.y=84;item_button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  for style_name in ["normal","hover","pressed","focus","disabled"]:
   var style=item_button.get_theme_stylebox(style_name).duplicate();style.content_margin_left=72
   item_button.add_theme_stylebox_override(style_name,style)
  var icon=preload("res://ui/shop_glyph.gd").new();icon.name="ToolIcon_"+item.id
  icon.kind="tool";icon.symbol="return_scroll" if item.type=="return_seal" else item.type
  icon.position=Vector2(4,10);icon.size=Vector2(64,64);item_button.add_child(icon)
  item_button.name="ToolItem_"+item.id;left.add_child(item_button)
 var right=_scroll(row)
 right.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL
 right.name="InventoryDetail"
 var footer=HBoxContainer.new();footer.name="InventoryFooter";footer.alignment=BoxContainer.ALIGNMENT_END;v.add_child(footer)
 _item_details(right,footer)

func _refresh_item_details() -> void:
 if not is_instance_valid(drawer_layer): return
 var right=drawer_layer.find_child("InventoryDetail",true,false)
 var footer=drawer_layer.find_child("InventoryFooter",true,false)
 if right==null or footer==null: return
 _hide_term()
 for parent in [right,footer]:
  _release_candidate_controls(parent)
  for child in parent.get_children():
   parent.remove_child(child);child.queue_free()
 for item in view.items:
  var button=drawer_layer.find_child("ToolItem_"+item.id,true,false)
  var chosen=item.id==selected_item
  if button.get_meta("selected_item")==chosen: continue
  button.set_meta("selected_item",chosen)
  for state in ["normal","hover","pressed","focus","disabled"]:
   var style=Palette.button_style(state,CYAN if state=="focus" or chosen else MUTED)
   style.content_margin_left=72;button.add_theme_stylebox_override(state,style)
 _item_details(right,footer)
 var selected=view.items.filter(func(item):return item.id==selected_item)[0]
 var panel=drawer_layer.find_child("InformationDrawer",true,false)
 panel.set_deferred("size",Vector2(820,540 if selected.target_scope=="body_group" else 420))
 _localize_controls(right);_localize_controls(footer)

func _item_details(right: VBoxContainer, footer: HBoxContainer) -> void:
 var selected=view.items.filter(func(i):return i.id==selected_item)[0]
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
   for c in item_actions:
    if c.payload.kind=="item_use": _compact_action(right,c,"使用",false)
 elif not selected.installed and not usage_actions.is_empty():
  right.add_child(_label("选择使用位置",16,GOLD))
  for group in selected.target_groups:
   var button=_button(group.name+" · %d个目标" % group.candidates.size(),func():selected_item_slot=group.id if selected_item_slot!=group.id else "";_refresh_item_details(),CYAN)
   button.name="ToolSlot_"+group.id;right.add_child(button)
   if selected_item_slot==group.id:
    for id in group.candidates:
     var matches=item_actions.filter(func(c):return c.id==id)
     if not matches.is_empty(): _tool_target_card(right,matches[0])
  if selected.target_groups.is_empty():
   for reason in selected.unavailable_reasons: right.add_child(_label(reason,14,RED))

 var installations=item_actions.filter(func(c):return c.payload.kind=="item_install")
 if not installations.is_empty():
  var expanded=selected_item_slot=="@install"
  var install_button=_button("安装到墙缝"+(" −" if expanded else " ＋"),func():selected_item_slot="" if selected_item_slot=="@install" else "@install";_refresh_item_details(),GOLD)
  install_button.name="ToolInstallMenu";right.add_child(install_button)
  if expanded:
   for c in installations: _compact_action(right,c,"",false)
 for c in item_actions:
  if c.payload.kind not in ["item_use","item_install","item_discard"]: _compact_action(right,c,"",false)
 var help_button=_button("使用说明  −" if item_help else "使用说明  ＋",func():item_help=not item_help;_refresh_item_details(),MUTED)
 help_button.name="ItemHelpToggle";help_button.custom_minimum_size.y=30;help_button.add_theme_font_size_override("font_size",13);right.add_child(help_button)
 if item_help:
  var help_box=VBoxContainer.new();help_box.name="ItemHelpContent";right.add_child(help_box)
  help_box.add_child(_label(selected.description,14,MUTED))
  if selected.passive_text!="" and not selected.installed: help_box.add_child(_label("安装后："+selected.passive_text,14,CYAN))
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
 content=_scroll(content)
 content.get_parent().name="DisplayOptionsScroll"
 content.add_child(_label(_text("ui.settings.language","语言"),17,GOLD))
 var language=OptionButton.new();language.name="LanguageSelection"
 language.add_item(_text("ui.settings.language.zh_cn","简体中文"))
 language.add_item(_text("ui.settings.language.en_us","English"))
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
 content.add_child(_label(_text("ui.settings.frame_limit","帧率上限"),17,GOLD))
 var frame_limit=OptionButton.new();frame_limit.name="FrameLimit"
 for value in display_settings.FRAME_LIMITS:
  frame_limit.add_item(_text("ui.settings.frame_unlimited","无上限") if value==0 else _text("ui.settings.frame_value","{fps}帧",{"fps":value}))
 frame_limit.select(display_settings.FRAME_LIMITS.find(display_settings.frame_limit))
 frame_limit.item_selected.connect(func(index):display_settings.set_frame_limit(display_settings.FRAME_LIMITS[index]);_refresh_drawers())
 content.add_child(frame_limit)
 var vsync=CheckButton.new();vsync.name="VSyncEnabled"
 vsync.text=_text("ui.settings.vsync","垂直同步");vsync.button_pressed=display_settings.vsync_enabled
 vsync.toggled.connect(func(enabled):display_settings.set_vsync(enabled);_refresh_drawers())
 content.add_child(vsync)
 content.add_child(_label(_text("ui.settings.vsync_note","开启垂直同步可减少画面撕裂；即使选择无上限，帧率仍可能受显示器刷新率限制。"),13,MUTED))
 if display_settings.save_error!="": content.add_child(_label(display_settings.save_error,14,RED))
 content.add_child(_label(_text("ui.settings.feedback_speed","敌方行动展示速度"),17,GOLD))
 var speed=OptionButton.new();speed.name="FeedbackSpeed"
 for index in range(3): speed.add_item(_text("ui.settings.speed."+["fast","normal","slow"][index],["快速","标准","舒缓"][index]))
 speed.select(0 if feedback_duration<1.0 else (1 if feedback_duration<1.6 else 2))
 speed.item_selected.connect(func(index):feedback_duration=[0.8,1.3,1.8][index])
 content.add_child(speed)

func _audio_options(content: Control) -> void:
 _audio_option(content,{"name":"CardMusic","key":"music","enabled_text":"打出卡牌时播放音乐","volume_text":"音乐音量 · {percent}%","enabled":display_settings.card_music_enabled,"volume":display_settings.card_music_volume},func(enabled,value):
  display_settings.set_card_music(enabled,value);card_music.configure(enabled,value))
 _audio_option(content,{"name":"DoubaoVoice","key":"doubao_voice","enabled_text":"播放豆包语音","volume_text":"豆包语音音量 · {percent}%","enabled":display_settings.doubao_voice_enabled,"volume":display_settings.doubao_voice_volume},func(enabled,value):
  display_settings.set_doubao_voice(enabled,value);takeover_presenter.configure_voice())
 if display_settings.save_error!="": content.add_child(_label(display_settings.save_error,14,RED))

func _audio_option(content: Control, spec: Dictionary, update: Callable) -> void:
 var toggle=CheckButton.new();toggle.name=spec.name+"Enabled"
 toggle.text=_text("ui.settings."+spec.key+"_enabled",spec.enabled_text);toggle.button_pressed=spec.enabled
 content.add_child(toggle)
 var caption=_label(_text("ui.settings."+spec.key+"_volume",spec.volume_text,{"percent":roundi(spec.volume*100)}),19,GOLD)
 caption.name=spec.name+"VolumeLabel";content.add_child(caption)
 var volume=HSlider.new();volume.name=spec.name+"Volume"
 volume.min_value=0;volume.max_value=100;volume.step=1;volume.value=spec.volume*100
 volume.custom_minimum_size=Vector2(0,44)
 toggle.toggled.connect(func(enabled):update.call(enabled,volume.value/100.0))
 volume.value_changed.connect(func(value):
  update.call(toggle.button_pressed,value/100.0)
  caption.text=_text("ui.settings."+spec.key+"_volume",spec.volume_text,{"percent":roundi(value)}))
 content.add_child(volume)

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
 content.add_child(_label(save_notice if save_notice!="" else preload("res://data/tutorial.gd").SAVE_HELP,16,RED if save_failed else CYAN))
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
 EventScreen.build(self)

func _chain_screen() -> void:
 var panel=_panel(Rect2(450,420,1060,325))
 var content=_scroll(panel)
 content.add_child(_label(view.card_chain.name+(" · 选择要消耗的牌" if view.card_chain.get("selection",false) else " · 选择下一段目标"),24,GOLD))
 content.add_child(_label("费用已支付，选择下一段目标。",16,CYAN))
 for c in actions.select("chain"): _action_row(content,c)

func _service_screen() -> void:
 var shop=ShopScreen.new();shop.ui=self;shop.name="RoomServicePanel";shop.size=Vector2(1552,790)
 _place(shop,Rect2(24,84,1552,790))
