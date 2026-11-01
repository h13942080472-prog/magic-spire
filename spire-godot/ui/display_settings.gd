extends RefCounted
signal art_changed(category: String, id: String)

const INFUSION_ART={"bound":"res://assets/art/card-infusion-leg-formal-v1.png","free":"res://assets/art/card-infusion-hand-formal-v1.png"}
const HANNYA_ART="res://assets/art/card-hannya-formal-v1.png"
const ART_STYLE_GROUPS={"cards":{"hannya_1":["hannya_1","hannya_2","hannya_3","hannya_4","good_soup","hannya_swallow","hannya_infusion","hannya_henshin"]}}
const FORMAL_ART={"cards":{
 "strain":"res://assets/art/card-strain-formal-v1.png",
 "slip":"res://assets/art/card-slip-formal-v1.png",
 "crossed_legs":"res://assets/art/card-crossed-legs-formal-v1.png",
 "fire_dynamics":"res://assets/art/card-fire-dynamics-formal-v1.png",
 "henshin":"res://assets/art/card-henshin-formal-v1.png",
 "hannya_henshin":"res://assets/art/card-henshin-formal-v1.png",
 "light_as_swallow":"res://assets/art/card-light-as-swallow-formal-v1.png",
 "hannya_swallow":"res://assets/art/card-light-as-swallow-formal-v1.png",
 "mana_circuit":"res://assets/art/card-mana-circuit-formal-v1.png",
 "fire_mastery":"res://assets/art/card-fire-mastery-formal-v1.png",
 "siphon_strength":"res://assets/art/card-siphon-strength-formal-v1.png",
 "infusion":INFUSION_ART,
 "hannya_infusion":INFUSION_ART,
 "endless_war_goddess":"res://assets/art/card-endless-war-goddess-formal-v1.png",
 "practiced":"res://assets/art/card-practiced-formal-v1.png",
 "shared_fate":"res://assets/art/card-shared-fate-formal-v1.png",
 "sympathetic_form":"res://assets/art/card-sympathetic-form-formal-v1.png",
 "pleasure_conversion":"res://assets/art/card-pleasure-conversion-formal-v1.png",
 "hannya_1":HANNYA_ART,
 "hannya_2":HANNYA_ART,
 "hannya_3":HANNYA_ART,
 "hannya_4":HANNYA_ART,
 "good_soup":HANNYA_ART,
 "boar_emperor_blaze":"res://assets/art/card-boar-emperor-blaze-formal-v1.jpg",
 "binding_enthusiast":{"mode":"fixed_hero_portrait","variants":{
  "original":{"label":"正式版·原图","path":"res://assets/art/card-binding-enthusiast-formal-v1.png"},
  "fixed":{"label":"正式版·扶她出去","path":"res://assets/art/card-binding-enthusiast-fixed-formal-v1.png"},
 }},
},"enemies":{
 "six_bind":"res://assets/art/enemy-six-bind-formal-v1.png",
 "puppeteer":"res://assets/art/enemy-puppeteer-formal-v1.png",
 "puppet":"res://assets/art/enemy-puppet-formal-v1.png",
}}
var art_choices={}
var fixed_hero_portrait=false
var chastity_locks_enabled=false
var chastity_lock_chance=25
var cursed_plate_start=false
var cursed_plate_masochist_mode=false
var first_battle_tutorial_seen=false
var card_music_enabled=true
var card_music_volume=0.2
var doubao_voice_enabled=true
var doubao_voice_volume=0.32
var interaction_audio_enabled=true
var interaction_audio_volume=0.7

const MODES=["窗口","无边框窗口","全屏"]
const FRAME_LIMITS=[60,120,240,0]
var frame_limit=60
var vsync_enabled=true
var reduced_card_motion=false
const Localization=preload("res://ui/localization.gd")
var locale=Localization.DEFAULT_LOCALE
const RESOLUTIONS=[Vector2i(1280,720),Vector2i(1440,810),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]
var mode=0
var resolution=Vector2i(1440,810)
var path="user://display-settings.cfg"
var persistence_enabled=true
var save_error=""
var window: Window
var mobile=OS.has_feature("android")

func choices() -> Array:
 var sizes=RESOLUTIONS.duplicate()
 if resolution.x>=640 and resolution.y>=360 and resolution.x<=3840 and resolution.y<=2160 and resolution not in sizes:
  sizes.append(resolution);sizes.sort_custom(func(a,b):return a.x<b.x)
 return sizes

func initialize(target: Window, persist: bool=true) -> void:
 window=target;persistence_enabled=persist
 locale=Localization.DEFAULT_LOCALE
 art_choices.clear()
 fixed_hero_portrait=false
 chastity_locks_enabled=false
 chastity_lock_chance=25
 cursed_plate_start=false
 cursed_plate_masochist_mode=false
 first_battle_tutorial_seen=false
 card_music_enabled=true;card_music_volume=0.2
 doubao_voice_enabled=true;doubao_voice_volume=0.32
 interaction_audio_enabled=true;interaction_audio_volume=0.7
 frame_limit=60;vsync_enabled=true
 reduced_card_motion=false
 _apply_frame_settings()
 mode=2 if window.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN] else (1 if window.borderless else 0)
 resolution=window.size
 if not persistence_enabled: return
 var config=ConfigFile.new()
 if config.load(path)!=OK: return
 var saved_locale=config.get_value("localization","locale",Localization.DEFAULT_LOCALE)
 if Localization.supported(saved_locale): locale=saved_locale
 var saved_music=config.get_value("audio","card_music_enabled",true)
 var saved_volume=config.get_value("audio","card_music_volume",0.2)
 if saved_music is bool: card_music_enabled=saved_music
 if (saved_volume is float or saved_volume is int) and is_finite(float(saved_volume)):
  card_music_volume=clampf(float(saved_volume),0.0,1.0)
 var saved_voice=config.get_value("audio","doubao_voice_enabled",true)
 var saved_voice_volume=config.get_value("audio","doubao_voice_volume",0.32)
 if saved_voice is bool: doubao_voice_enabled=saved_voice
 if (saved_voice_volume is float or saved_voice_volume is int) and is_finite(float(saved_voice_volume)):
  doubao_voice_volume=clampf(float(saved_voice_volume),0.0,1.0)
 var saved_fixed=config.get_value("art","fixed_hero_portrait",false)
 var saved_effects=config.get_value("audio","interaction_audio_enabled",true)
 var saved_effects_volume=config.get_value("audio","interaction_audio_volume",0.7)
 if saved_effects is bool: interaction_audio_enabled=saved_effects
 if (saved_effects_volume is float or saved_effects_volume is int) and is_finite(float(saved_effects_volume)):
  interaction_audio_volume=clampf(float(saved_effects_volume),0.0,1.0)
 if saved_fixed is bool: fixed_hero_portrait=saved_fixed
 var saved_chastity=config.get_value("gameplay","chastity_locks_enabled",false)
 var saved_chance=config.get_value("gameplay","chastity_lock_chance",25)
 if saved_chastity is bool: chastity_locks_enabled=saved_chastity
 if saved_chance is int and saved_chance>=0 and saved_chance<=100 and saved_chance%5==0: chastity_lock_chance=maxi(5,saved_chance)
 if fixed_hero_portrait: chastity_locks_enabled=false
 var saved_start=config.get_value("gameplay","cursed_plate_start",false)
 if saved_start is bool: cursed_plate_start=saved_start and chastity_locks_enabled
 var saved_masochist=config.get_value("gameplay","cursed_plate_masochist_mode",false)
 if saved_masochist is bool: cursed_plate_masochist_mode=saved_masochist and chastity_locks_enabled
 var saved_tutorial=config.get_value("onboarding","first_battle_tutorial_seen",false)
 if saved_tutorial is bool: first_battle_tutorial_seen=saved_tutorial
 var saved_art=config.get_value("art","choices",{})
 if saved_art is Dictionary:
  for category in FORMAL_ART:
   var choices_for_category=saved_art.get(category,{})
   if not choices_for_category is Dictionary: continue
   for id in choices_for_category:
    if id is String and choices_for_category[id] in art_style_options(category,id):
     if not art_choices.has(category): art_choices[category]={}
     var owner=art_choice_id(category,id)
     if id==owner or not art_choices[category].has(owner): art_choices[category][owner]=choices_for_category[id]
 var saved_mode=config.get_value("display","mode",mode)
 var saved_limit=config.get_value("display","frame_limit",60)
 var saved_vsync=config.get_value("display","vsync_enabled",true)
 var saved_motion=config.get_value("display","reduced_card_motion",false)
 if saved_motion is bool: reduced_card_motion=saved_motion
 if saved_limit is int and saved_limit in FRAME_LIMITS: frame_limit=saved_limit
 if saved_vsync is bool: vsync_enabled=saved_vsync
 var saved_size=config.get_value("display","resolution",resolution)
 if saved_mode is int and saved_mode in range(MODES.size()): mode=saved_mode
 if saved_size is Vector2i and saved_size.x>=640 and saved_size.y>=360: resolution=saved_size
 if resolution not in choices(): resolution=choices().back()
 apply()

func set_mode(value: int) -> void:
 if mobile: return
 if value not in range(MODES.size()): return
 mode=value;apply();save()

func set_resolution(value: Vector2i) -> void:
 if mobile: return
 if mode==2 or value not in choices(): return
 resolution=value;apply();save()

func apply() -> void:
 _apply_frame_settings()
 if mobile: return
 if mode==2:
  window.mode=Window.MODE_FULLSCREEN
  return
 window.mode=Window.MODE_WINDOWED
 # Fullscreen also sets this flag, so explicitly clear it when returning to a framed window.
 window.borderless=mode==1
 window.size=resolution
 var screen=DisplayServer.screen_get_usable_rect(window.current_screen)
 var offset=Vector2i(maxi(0,(screen.size.x-resolution.x)/2),maxi(0,(screen.size.y-resolution.y)/2))
 window.position=screen.position+offset

func _apply_frame_settings() -> void:
 Engine.max_fps=frame_limit
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED,window.get_window_id())

func set_frame_limit(value: int) -> bool:
 if value not in FRAME_LIMITS: return false
 frame_limit=value;_apply_frame_settings();save()
 return true

func set_vsync(enabled: bool) -> void:
 vsync_enabled=enabled;_apply_frame_settings();save()

func save() -> void:
 save_error=""
 if not persistence_enabled: return
 var config=ConfigFile.new()
 config.set_value("display","mode",mode)
 config.set_value("display","frame_limit",frame_limit)
 config.set_value("display","vsync_enabled",vsync_enabled)
 config.set_value("display","reduced_card_motion",reduced_card_motion)
 config.set_value("localization","locale",locale)
 config.set_value("display","resolution",resolution)
 config.set_value("art","choices",art_choices)
 config.set_value("art","fixed_hero_portrait",fixed_hero_portrait)
 config.set_value("gameplay","chastity_locks_enabled",chastity_locks_enabled)
 config.set_value("gameplay","chastity_lock_chance",chastity_lock_chance)
 config.set_value("gameplay","cursed_plate_start",cursed_plate_start)
 config.set_value("gameplay","cursed_plate_masochist_mode",cursed_plate_masochist_mode)
 config.set_value("onboarding","first_battle_tutorial_seen",first_battle_tutorial_seen)
 config.set_value("audio","card_music_enabled",card_music_enabled)
 config.set_value("audio","card_music_volume",card_music_volume)
 config.set_value("audio","doubao_voice_enabled",doubao_voice_enabled)
 config.set_value("audio","doubao_voice_volume",doubao_voice_volume)
 config.set_value("audio","interaction_audio_enabled",interaction_audio_enabled)
 config.set_value("audio","interaction_audio_volume",interaction_audio_volume)
 if config.save(path)!=OK: save_error="设置保存失败，请重试。"

func set_locale(value: String) -> bool:
 if not Localization.supported(value): return false
 locale=value;save()
 return true

func set_card_music(enabled: bool, volume: float) -> void:
 card_music_enabled=enabled;card_music_volume=clampf(volume,0.0,1.0)
 save()

func set_fixed_hero_portrait(enabled: bool) -> void:
 fixed_hero_portrait=enabled
 if enabled: chastity_locks_enabled=false
 if not chastity_locks_enabled:
  cursed_plate_start=false
  cursed_plate_masochist_mode=false
 save()
 for category in FORMAL_ART:
  for id in FORMAL_ART[category]:
   var source=FORMAL_ART[category][id]
   if source is Dictionary and source.get("mode","")=="fixed_hero_portrait": art_changed.emit(category,id)

func set_doubao_voice(enabled: bool, volume: float) -> void:
 doubao_voice_enabled=enabled;doubao_voice_volume=clampf(volume,0.0,1.0)
 save()

func set_interaction_audio(enabled: bool, volume: float) -> void:
 interaction_audio_enabled=enabled;interaction_audio_volume=clampf(volume,0.0,1.0)
 save()

func set_chastity_locks(enabled: bool) -> void:
 chastity_locks_enabled=enabled and not fixed_hero_portrait
 if not chastity_locks_enabled:
  cursed_plate_start=false
  cursed_plate_masochist_mode=false
 save()

func set_cursed_plate_start(enabled: bool) -> void:
 cursed_plate_start=enabled and chastity_locks_enabled and not fixed_hero_portrait
 save()

func set_cursed_plate_masochist_mode(enabled: bool) -> void:
 cursed_plate_masochist_mode=enabled and chastity_locks_enabled and not fixed_hero_portrait
 save()

func adjust_chastity_chance(delta: int) -> void:
 if fixed_hero_portrait or not chastity_locks_enabled: return
 chastity_lock_chance=clampi(chastity_lock_chance+delta,5,100)
 chastity_lock_chance=int(round(float(chastity_lock_chance)/5.0))*5
 save()

func mark_first_battle_tutorial_seen() -> void:
 first_battle_tutorial_seen=true
 save()

func has_formal_art(category: String, id: String) -> bool:
 return FORMAL_ART.get(category,{}).has(id)

func art_style_options(category: String, id: String) -> Dictionary:
 var options={"test":"测试版画风","formal":"正式版立绘"}
 var source=FORMAL_ART.get(category,{}).get(id)
 if source is Dictionary and source.has("variants"):
  options.formal="正式版·跟随模式"
  for variant in source.variants: options[variant]=source.variants[variant].label
 return options

func art_style(category: String, id: String) -> String:
 if not has_formal_art(category,id): return "test"
 return art_choices.get(category,{}).get(art_choice_id(category,id),"formal")

func art_choice_id(category: String, id: String) -> String:
 for owner in ART_STYLE_GROUPS.get(category,{}):
  if id in ART_STYLE_GROUPS[category][owner]: return owner
 return id

func art_texture(category: String, id: String, effect_free: bool=false) -> Texture2D:
 var style=art_style(category,id)
 if style=="test": return null
 var source=FORMAL_ART[category][id]
 if source is Dictionary and source.has("variants"):
  var variant=("fixed" if get(source.mode) else "original") if style=="formal" else style
  source=source.variants[variant].path
 if source is Dictionary: source=source["free" if effect_free else "bound"]
 return load(source)

func set_art_style(category: String, id: String, style: String) -> void:
 if not FORMAL_ART.has(category) or id.is_empty() or style not in art_style_options(category,id): return
 if style=="formal" and not has_formal_art(category,id): return
 if not art_choices.has(category): art_choices[category]={}
 var owner=art_choice_id(category,id)
 art_choices[category][owner]=style
 save()
 for member in ART_STYLE_GROUPS.get(category,{}).get(owner,[id]): art_changed.emit(category,member)
