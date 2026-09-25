extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")
const Settings=preload("res://ui/display_settings.gd")

static func choose(t, locale: String) -> void:
 var picker=t.ui.find_child("LanguageSelection",true,false)
 t.check(picker!=null,"LOCALE UI language selector exists in shared settings")
 if picker==null: return
 var index=t.ui.localization.LOCALES.find(locale)
 picker.select(index);picker.item_selected.emit(index)
 await t.frames()
 check_font(t)

static func check_font(t) -> void:
 var font=t.ui.theme.default_font
 t.check(font is FontFile and font.resource_path=="res://assets/fonts/NotoSansCJKsc-Regular.otf","LOCALE UI uses the bundled font after startup and language changes")
 var title=t.ui.find_child("HomeTitle",true,false)
 if title!=null: t.check(title.get_theme_font("font")==font,"LOCALE real title inherits the bundled font")

static func chinese_runs(text: String) -> Array:
 var regex=RegEx.new();regex.compile(r"[\x{3400}-\x{9fff}]+")
 return regex.search_all(text).map(func(hit):return hit.get_string())

static func run(t) -> void:
 var ui=t.ui
 ui.options_tab="display"
 ui._return_home();await t.frames()
 check_font(t)
 var before=ui.game.export_snapshot()
 var facts=ui.view.display_facts.duplicate(true)
 await Navigation.press(t,"HomeOptions")
 var picker=ui.find_child("LanguageSelection",true,false)
 t.check(picker.item_count==3 and picker.get_item_text(1)=="English" and picker.get_item_text(2)=="日本語","LOCALE UI lists the finished Japanese pack")
 await choose(t,"en_US")
 t.check(ui.localization.locale=="en_US" and ui.find_child("HomeTitle",true,false).text=="Bound Spire","LOCALE UI selects the completed English catalog")
 t.check(ui.find_child("HomeCursedPlateMasochist",true,false).text=="Masochist Mode","LOCALE new-game mode reads a semantic message instead of fragment translation")
 t.check(ui.find_child("DisplayMode",true,false).get_item_text(0)=="Windowed","LOCALE UI translates registered setting options")
 var home_remains=chinese_runs(t.visible_text(ui.layout))
 t.check(home_remains.is_empty(),"LOCALE English home and settings contain no Chinese display fragments: "+str(home_remains.slice(0,12)))
 await t.capture("ui-english-settings.png")
 await choose(t,"ja_JP")
 t.check(ui.localization.locale=="ja_JP" and ui.display_settings.locale=="ja_JP" and ui.find_child("HomeTitle",true,false).text=="緊縛の尖塔","LOCALE UI real language selection uses the completed Japanese catalog")
 t.check(ui.find_child("HomeNewGame",true,false).text=="ニューゲーム" and ui.find_child("SettingsTab_audio",true,false).text=="サウンド","LOCALE Japanese home and settings use authored copy")
 await t.capture("ui-japanese-settings.png")
 t.check(ui.game.export_snapshot()==before and ui.view.display_facts==facts,"LOCALE UI switching keeps game state, facts, RNG and version unchanged")
 var panel=ui.find_child("InformationDrawer",true,false)
 var settings_scroll=ui.find_child("DisplayOptionsScroll",true,false)
 var final_setting=ui.find_child("FeedbackSpeed",true,false)
 settings_scroll.ensure_control_visible(final_setting);await t.frames()
 t.check(panel.get_global_rect().encloses(final_setting.get_global_rect()) and settings_scroll.get_global_rect().encloses(final_setting.get_global_rect()),"LOCALE UI final display setting remains fully reachable by scrolling inside the window")
 settings_scroll.scroll_vertical=0;await t.frames()
 t.check(settings_scroll.get_global_rect().encloses(ui.find_child("LanguageSelection",true,false).get_global_rect()),"LOCALE UI can scroll back to the language selector")
 # In-memory pseudo copy proves that wired controls actually read the resource.
 var sample={"schema_version":1,"locale":"ja_JP","messages":{
  "ui.home.title":{"source":"紧缚尖塔","text":"[TEST TITLE]"},
  "ui.settings.music_volume":{"source":"音乐音量 · {percent}%","text":"{percent}% [TEST VOLUME]"}
 }}
 t.check(ui.localization.install_translation("ja_JP",sample),"LOCALE UI isolated pseudo catalog loads without changing shipped Japanese file")
 ui.render(ui.view);await t.frames()
 t.check(ui.find_child("HomeTitle",true,false).text=="[TEST TITLE]","LOCALE UI static caption uses selected language resource")
 await Navigation.press(t,"SettingsTab_audio")
 var volume=ui.find_child("CardMusicVolume",true,false)
 var old_volume=volume.value
 volume.value=37;await t.frames()
 t.check(ui.find_child("CardMusicVolumeLabel",true,false).text=="37% [TEST VOLUME]","LOCALE UI dynamic caption resolves reordered named parameter after slider update")
 volume.value=old_volume
 await Navigation.press(t,"SettingsTab_display")
 await choose(t,"zh_CN")
 t.check(ui.find_child("HomeTitle",true,false).text=="紧缚尖塔" and ui.game.export_snapshot()==before,"LOCALE UI switch back restores Chinese without altering game")
 ui.localization.load_directory()
 await t.capture("ui-localization-framework.png")
 await t.close_information()
 # Only test settings files; never the player's preferences or saves.
 var path="res://build/localization-settings-%s.cfg" % OS.get_process_id()
 var settings=Settings.new();settings.path=path;settings.initialize(t.root,false);settings.persistence_enabled=true
 t.check(settings.set_locale("ja_JP") and settings.save_error.is_empty(),"LOCALE preference saves through the existing display settings store")
 var restored=Settings.new();restored.path=path;restored.initialize(t.root)
 t.check(restored.locale=="ja_JP" and not restored.set_locale("unknown") and restored.locale=="ja_JP","LOCALE preference reloads and rejects unsupported languages")
 var config=ConfigFile.new();config.load(path);config.set_value("localization","locale",99);config.save(path)
 restored.initialize(t.root)
 t.check(restored.locale=="zh_CN","LOCALE malformed saved language falls back to Chinese")
 config.erase_section("localization");config.save(path);restored.initialize(t.root)
 t.check(restored.locale=="zh_CN","LOCALE existing settings without a language remain valid Chinese defaults")
 DirAccess.remove_absolute(path)
 ui.restart(42);await t.frames()
 before=ui.game.export_snapshot();facts=ui.view.display_facts.duplicate(true)
 await t.open_menu();await Navigation.press(t,"OpenOptions")
 await choose(t,"ja_JP");await choose(t,"zh_CN")
 t.check(ui.game.export_snapshot()==before and ui.view.display_facts==facts,"LOCALE in-game settings use the same selector without restarting or submitting an action")
 t.check(ui.localization.diagnostics().is_empty(),"LOCALE wired screens resolve every registered template without silent errors")
 await t.close_information()
 ui._set_language("en_US");await t.frames()
 var remains=chinese_runs(t.visible_text(ui.layout))
 t.check(remains.is_empty(),"LOCALE English in-game interface has no Chinese display fragments: "+str(remains.slice(0,12)))
 await t.start_practice("Practice_shop");await t.frames()
 remains=chinese_runs(t.visible_text(ui.layout))
 t.check(remains.is_empty(),"LOCALE English shop surface has no Chinese display fragments: "+str(remains.slice(0,12)))
 await t.capture("ui-english-shop.png")
 await t.start_practice("Practice_floating_belt_cluster");await t.frames()
 remains=chinese_runs(t.visible_text(ui.layout))
 t.check(remains.is_empty(),"LOCALE English event surface has no Chinese display fragments: "+str(remains.slice(0,12)))
 await t.capture("ui-english-event.png")
 await t.start_practice("Practice_henshin");await t.frames()
 remains=chinese_runs(t.visible_text(ui.layout))
 t.check(remains.is_empty(),"LOCALE English battle surface has no Chinese display fragments: "+str(remains.slice(0,12)))
 await t.capture("ui-english-battle.png")
 ui._set_language("zh_CN");await t.frames()
