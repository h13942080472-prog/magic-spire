extends Control

# A presentation screen only; starting/resuming uses the existing controller.
const Art=preload("res://ui/pixel_art.gd")
var ui

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 var character=OptionButton.new();character.name="CharacterSelect"
 character.add_item(ui._text("ui.home.character.original","魔法少女(futa)"))
 character.add_item(ui._text("ui.home.character.witch","小魔女·测试版"))
 character.select(1 if ui.selected_character=="witch" else 0)
 character.add_theme_font_size_override("font_size",18)
 ui._place(character,Rect2(1030,140,365,36),self)
 character.item_selected.connect(func(index):ui.selected_character="witch" if index==1 else "original")
 var title=ui._label(ui._text("ui.home.title","紧缚尖塔"),96,ui.GOLD);title.name="HomeTitle"
 ui._place(title,Rect2(145,330,720,140),self)
 var language=ui._language_selector()
 language.add_theme_font_size_override("font_size",18)
 ui._place(language,Rect2(145,475,365,42),self)
 var disclaimer=ui._label(ui._text("ui.home.disclaimer","免责声明：本游戏为爱发电，免费发布。\n如果你花钱购买了本游戏，说明你上当了。"),14,Color("858585"))
 disclaimer.name="HomeDisclaimer";disclaimer.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui._place(disclaimer,Rect2(100,825,850,50),self)
 var entry=ui.save_summaries.get("tower",{"available":false,"text":"开始塔路冒险"})
 var resume_text=ui._text("ui.home.continue_practice","继续练习") if ui.session_started and ui.view.practice else ui._text("ui.home.continue","继续游戏")
 var resume=ui._button(resume_text,ui._home_continue,ui.CYAN)
 resume.name="HomeContinue";resume.disabled=(not ui.session_started and not entry.available) or (ui.session_started and ui.view.demo_finished)
 var start=ui._button(ui._text("ui.home.new_game","开始新游戏"),func():ui.restart(int(randi())),ui.GOLD);start.name="HomeNewGame"
 var buttons=[resume,start,
  ui._button(ui._text("ui.home.encyclopedia","图鉴"),func():ui._open_drawer("show_encyclopedia")),
  ui._button(ui._text("ui.home.tutorial","教程书"),func():ui._open_tutorial()),
  ui._button(ui._text("ui.home.practice","练习与自定义"),func():ui._open_drawer("show_settings")),
  ui._button(ui._text("ui.settings.title","设置"),func():ui._open_drawer("show_options")),
  ui._button(ui._text("ui.home.quit","退出游戏"),func():get_tree().quit(),ui.MUTED)]
 var names=["HomeContinue","HomeNewGame","HomeEncyclopedia","HomeTutorial","HomePractice","HomeOptions","HomeQuit"]
 for i in range(buttons.size()):
  var button=buttons[i];button.name=names[i]
  button.add_theme_font_size_override("font_size",20 if i<2 else 17)
  ui._place(button,Rect2(1030,185+i*62,365,54),self)
 start.size.x=226
 var seeded=ui._button(ui._text("ui.seed.open","种子开局"),func():ui._open_drawer("show_settings","seed"),ui.CYAN)
 seeded.name="HomeSeedGame";seeded.add_theme_font_size_override("font_size",17)
 ui._place(seeded,Rect2(1266,247,129,54),self)
 var progress=(ui.view.room_name+" · "+("练习进度" if ui.view.practice else "当前进度")) if ui.session_started else entry.text
 if not ui.session_started and not ui.saves.has_files("tower"): progress="首次来到尖塔？从「开始新游戏」出发。"
 if ui.save_failed: progress=ui.save_notice
 elif ui.session_started and ui.view.demo_finished: progress="本次demo已结束。"
 ui._place(ui._label(progress,14,ui.RED if ui.save_failed else ui.MUTED),Rect2(1030,629,365,60),self)
 var saved=ui._button(ui._text("ui.home.saves","存档与继续"),ui._open_saves,ui.MUTED);saved.name="HomeSaves"
 ui._place(saved,Rect2(1260,95,165,42),self)
 var save_notice=ui._label(ui.display_settings.save_error,13,ui.RED)
 save_notice.name="HomeSettingsSaveNotice"
 var fixed=ui._button("扶她出去",func():pass,ui.CYAN)
 fixed.name="HomeFixedPortrait";fixed.toggle_mode=true
 fixed.button_pressed=ui.display_settings.fixed_hero_portrait
 fixed.text="扶她出去 · "+("开" if fixed.button_pressed else "关")
 fixed.tooltip_text="装备与战斗立绘固定为初始站姿。"
 ui._place(fixed,Rect2(1030,697,365,48),self)
 var chastity=ui._button("",func():pass,ui.GOLD);chastity.name="HomeChastityLocks";chastity.toggle_mode=true
 var down=ui._button("▼",func():pass,ui.MUTED);down.name="HomeChastityChanceDown"
 var up=ui._button("▲",func():pass,ui.MUTED);up.name="HomeChastityChanceUp"
 var custom=CheckBox.new();custom.name="HomeCursedPlateStart"
 custom.text="用「诅咒平板锁」替换初始遗物"
 custom.add_theme_font_size_override("font_size",16)
 custom.add_theme_color_override("font_color",ui.GOLD)
 ui._place(custom,Rect2(1030,805,365,32),self)
 var masochist=CheckBox.new();masochist.name="HomeCursedPlateMasochist"
 masochist.text=ui._text("ui.home.masochist_mode","抖M专用版")
 masochist.add_theme_font_size_override("font_size",16)
 masochist.add_theme_color_override("font_color",ui.RED)
 ui._place(masochist,Rect2(1030,837,365,32),self)
 var custom_hint=ui._label("",13,ui.MUTED);custom_hint.name="HomeCursedPlateHint"
 ui._place(custom_hint,Rect2(1030,869,365,18),self)
 var refresh_chastity=func():
  var witch=ui.selected_character=="witch"
  fixed.disabled=witch
  fixed.set_pressed_no_signal(witch or ui.display_settings.fixed_hero_portrait)
  fixed.text="角色2 · 固定站立立绘" if witch else "扶她出去 · "+("开" if fixed.button_pressed else "关")
  chastity.set_pressed_no_signal(ui.display_settings.chastity_locks_enabled)
  var state=ui.localization.display("开" if chastity.button_pressed else "关")
  chastity.text=ui.localization.display("贞操锁池 · %s（%d%%）" % [state,ui.display_settings.chastity_lock_chance])
  chastity.disabled=witch or ui.display_settings.fixed_hero_portrait
  down.disabled=chastity.disabled or not chastity.button_pressed or ui.display_settings.chastity_lock_chance<=5
  up.disabled=chastity.disabled or not chastity.button_pressed or ui.display_settings.chastity_lock_chance>=100
  custom.disabled=chastity.disabled or not chastity.button_pressed
  custom.set_pressed_no_signal(ui.display_settings.cursed_plate_start)
  masochist.disabled=chastity.disabled or not chastity.button_pressed
  masochist.set_pressed_no_signal(ui.display_settings.cursed_plate_masochist_mode)
  custom_hint.text="魔法少女开局选项" if witch else ui.localization.display("开启贞操锁池后可选" if custom.disabled else "仅新局生效")
  custom.tooltip_text=ui.localization.display("新局以「诅咒平板锁」替换「余烬护符」，保留前三项开局选择和直接出发。")
  masochist.tooltip_text=ui.localization.display("诅咒平板锁的跳蛋持续生效，高潮后快感保留系数可持续增长。")
  chastity.tooltip_text=ui.localization.display("随机施加性玩具时选择平板锁的概率。范围5%～100%，每次调整5%；锁具位置已满时改选普通性玩具。")
 refresh_chastity.call()
 character.item_selected.connect(func(_index):refresh_chastity.call())
 fixed.toggled.connect(func(enabled):
  ui.display_settings.set_fixed_hero_portrait(enabled)
  fixed.text="扶她出去 · "+("开" if enabled else "关")
  refresh_chastity.call()
  save_notice.text=ui.display_settings.save_error)
 chastity.toggled.connect(func(enabled):
  ui.display_settings.set_chastity_locks(enabled)
  refresh_chastity.call()
  save_notice.text=ui.display_settings.save_error)
 down.pressed.connect(func():ui.display_settings.adjust_chastity_chance(-5);refresh_chastity.call();save_notice.text=ui.display_settings.save_error)
 up.pressed.connect(func():ui.display_settings.adjust_chastity_chance(5);refresh_chastity.call();save_notice.text=ui.display_settings.save_error)
 custom.toggled.connect(func(enabled):ui.display_settings.set_cursed_plate_start(enabled);refresh_chastity.call();save_notice.text=ui.display_settings.save_error)
 masochist.toggled.connect(func(enabled):ui.display_settings.set_cursed_plate_masochist_mode(enabled);refresh_chastity.call();save_notice.text=ui.display_settings.save_error)
 ui._place(chastity,Rect2(1030,751,235,48),self)
 ui._place(down,Rect2(1271,751,58,48),self)
 ui._place(up,Rect2(1337,751,58,48),self)
 ui._place(save_notice,Rect2(100,790,850,28),self)
 # Fixed homepage captions should not retain a tall wrap minimum from initial layout.
 for child in get_children():
  if child is Label:
   child.autowrap_mode=TextServer.AUTOWRAP_OFF
   child.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
   child.max_lines_visible=4
   child.size.y=child.get_minimum_size().y

func _draw() -> void:
 draw_texture_rect(Art.BACKGROUND,Rect2(0,0,1600,900),false,Color(0.6,0.68,0.8))
 draw_rect(Rect2(0,0,1600,900),Color(0.02,0.035,0.06,0.34))
 for i in range(80):
  var x=i*20.0
  var opacity=0.68+0.20*absf(x-800)/800
  draw_rect(Rect2(x,0,20,900),Color(0.025,0.035,0.055,opacity))
 draw_style_box(ui.Palette.window_frame(),Rect2(1000,164,425,734))
 for x in [65,1535]:
  draw_line(Vector2(x,65),Vector2(x,835),Color(0.78,0.66,0.43,0.22),1)
  draw_line(Vector2(x,65),Vector2(x+(35 if x<800 else -35),65),Color(0.78,0.66,0.43,0.5),2)
