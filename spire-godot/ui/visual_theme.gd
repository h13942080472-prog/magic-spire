extends RefCounted

# Presentation tokens only; no gameplay state or eligibility lives here.
const GOLD=Color("c9ad79")
const CYAN=Color("89d6d2")
const TEXT=Color("eee8d9")
const MUTED=Color("a5b3bd")
const RED=Color("ed9393")
const INK=Color("17191f")
const HUD=Color("101217")
const HAIRLINE=Color("383b43")
# Committed-feedback border tokens (ui/impact_feedback.gd): one per trigger family,
# so a colour is never written inline at the effect site.
const BORDER_CALM=Color("f2ede0")
const BORDER_CHARGE=Color("e8c47b")
const BORDER_MANA=Color("8fd3ee")
# Overload/climax pink: the pressure meter, the climax panel and the pleasure-filter
# overlay all read this one token. FEEDBACK_FALLBACK is the filter's standalone tint
# (host without OVERLOAD_COLOR); it is named here too so the effect layer carries no
# colour literal of its own.
const OVERLOAD=Color("ed82b9")
const FEEDBACK_FALLBACK=OVERLOAD
const UI_FONT=preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

static func surface(bg: Color=INK, border: Color=GOLD.darkened(0.5), radius: int=8) -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=bg;s.border_color=border
 s.set_border_width_all(1)
 s.set_corner_radius_all(radius)
 s.content_margin_left=12;s.content_margin_right=12
 s.content_margin_top=8;s.content_margin_bottom=8
 s.shadow_color=Color(0.015,0.022,0.035,0.45)
 s.shadow_size=4;s.shadow_offset=Vector2(0,2)
 return s

static func window_frame() -> StyleBoxFlat:
 var s=surface(INK,HAIRLINE,8)
 s.border_width_top=2
 s.shadow_size=12;s.shadow_color=Color(0,0,0,0.32)
 return s

static func button_style(state: String, accent: Color=GOLD, role: String="default") -> StyleBoxFlat:
 var backgrounds={"normal":Color("22252d"),"hover":Color("333741"),"pressed":Color("3d3b35"),"disabled":Color("191b21"),"focus":Color(0,0,0,0)}
 var s=surface(backgrounds[state],HAIRLINE if state=="disabled" else accent.darkened(0.5),5)
 s.shadow_size=0;s.set_border_width_all(0)
 s.border_width_bottom=1
 if role=="quiet":
  if state=="normal": s.bg_color=Color(0,0,0,0)
  s.border_width_bottom=0
 if role=="primary":
  s.set_corner_radius_all(40)
  if state not in ["disabled","focus"]:
   s.bg_color=GOLD.darkened(0.15 if state=="normal" else 0.02 if state=="hover" else 0.3)
   s.border_color=GOLD.lightened(0.25);s.set_border_width_all(1)
   s.shadow_color=Color(0.78,0.64,0.38,0.12);s.shadow_size=8
 if state in ["hover","pressed"]:
  s.border_color=accent;s.border_width_bottom=2
 if state=="focus":
  s.border_color=CYAN;s.set_border_width_all(2)
 return s

static func style_button(button: Button, accent: Color=GOLD, role: String="default") -> void:
 for state in ["normal","hover","pressed","focus","disabled"]:
  button.add_theme_stylebox_override(state,button_style(state,accent,role))
 for key in ["font_color","font_hover_color","font_pressed_color"]:
  button.add_theme_color_override(key,HUD if role=="primary" else TEXT)

static func hud_surface(separator: bool=false) -> StyleBoxFlat:
 var s=surface(HUD,HAIRLINE,0)
 s.set_border_width_all(0);s.shadow_size=0
 if separator: s.border_width_top=1
 return s

static func controls() -> Theme:
 var t=Theme.new();t.default_font=UI_FONT;t.default_font_size=16
 for type in ["Button","OptionButton"]:
  for state in ["normal","hover","pressed","disabled","focus"]: t.set_stylebox(state,type,button_style(state))
  t.set_color("font_color",type,TEXT);t.set_color("font_hover_color",type,TEXT);t.set_color("font_pressed_color",type,TEXT)
  t.set_color("font_disabled_color",type,MUTED.darkened(0.2))
 for state in ["normal","read_only"]:
  var input=surface(Color("0d1923"),Color("46595f"),6);input.shadow_size=0
  t.set_stylebox(state,"LineEdit",input)
 t.set_stylebox("focus","LineEdit",button_style("focus",CYAN))
 t.set_color("font_color","LineEdit",TEXT);t.set_color("font_placeholder_color","LineEdit",MUTED)
 t.set_color("caret_color","LineEdit",CYAN);t.set_color("selection_color","LineEdit",Color("33585f"))
 t.set_stylebox("panel","PopupMenu",surface(INK,GOLD.darkened(0.5),8))
 t.set_stylebox("hover","PopupMenu",button_style("hover",CYAN))
 t.set_color("font_color","PopupMenu",TEXT);t.set_color("font_hover_color","PopupMenu",TEXT)
 for type in ["HSeparator","VSeparator"]:
  var line=StyleBoxLine.new();line.color=Color("48514c");line.thickness=1;line.vertical=type=="VSeparator"
  t.set_stylebox("separator",type,line)
 for type in ["VScrollBar","HScrollBar"]:
  var track=StyleBoxFlat.new();track.bg_color=Color("0a141e");track.set_corner_radius_all(4)
  track.content_margin_left=4;track.content_margin_right=4;track.content_margin_top=4;track.content_margin_bottom=4
  t.set_stylebox("scroll",type,track)
  for state in ["grabber","grabber_highlight","grabber_pressed"]:
   var grip=track.duplicate();grip.bg_color=Color("536b70") if state=="grabber" else CYAN.darkened(0.25)
   t.set_stylebox(state,type,grip)
 return t
