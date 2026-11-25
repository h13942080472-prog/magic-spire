extends RefCounted

# Private-use codepoint keeps platform emoji fonts from replacing the HUD medallion.
const ICON="\U0F0001"
const Medallion=preload("res://assets/ui/energy-medallion.svg")
static var _glyph: FontFile
static var _rules: Array=[]
static var _fonts={}

static func glyph_font() -> FontFile:
 if _glyph!=null: return _glyph
 var image=Medallion.get_image()
 var size=image.get_height()
 var glyph=ICON.unicode_at(0)
 var strike=Vector2i(size,0)
 _glyph=FontFile.new()
 _glyph.fixed_size=size
 _glyph.fixed_size_scale_mode=TextServer.FIXED_SIZE_SCALE_ENABLED
 _glyph.set_cache_ascent(0,size,size*0.875)
 _glyph.set_cache_descent(0,size,size*0.125)
 _glyph.set_texture_image(0,strike,0,image)
 _glyph.set_glyph_texture_idx(0,strike,glyph,0)
 _glyph.set_glyph_uv_rect(0,strike,glyph,Rect2(Vector2.ZERO,image.get_size()))
 _glyph.set_glyph_size(0,strike,glyph,image.get_size())
 _glyph.set_glyph_offset(0,strike,glyph,Vector2(0,-size*0.875))
 _glyph.set_glyph_advance(0,size,glyph,Vector2(size*1.04,0))
 return _glyph

static func font_for(base: Font) -> Font:
 if not _fonts.has(base):
  var font=FontVariation.new()
  font.base_font=base
  font.fallbacks=[glyph_font()]
  _fonts[base]=font
 return _fonts[base]

# Keep prices, use limits and damage numbers as text. Only affirmative gains
# are matched, after localization, so every surface using CardFace shares them.
static func render(value: String) -> String:
 if not ("能量" in value or "energy" in value.to_lower() or "エネルギー" in value or "エナジー" in value): return value
 if _rules.is_empty():
  _add(r"能量、([^。；]+?)各[＋+]([0-9]+)", "获得", "，$1各＋$2",2)
  _add(r"(?i)(gain) ([0-9]+) each of Energy, ", "$1 ", ", $2 each of ",2)
  _add(r"(?:エネルギー|エナジー)、([^。]+?)をそれぞれ([0-9]+)得る", "", "を得て、$1をそれぞれ$2得る",2)
  _add(r"(获得|恢复|返还|魔力预备和)([0-9]+)点?能量", "$1", "",2)
  _add(r"能量\s*[＋+]\s*([0-9]+)", "获得", "",1)
  _add(r"(?i)\b(gain(?:s)?|get|recover|restore|Mana Reserve and) ([0-9]+) (?:additional |extra )?energy\b", "$1 ", "",2)
  _add(r"(?i)\bEnergy\s*[＋+]\s*([0-9]+)", "Gain ", "",1)
  _add(r"(?:エネルギー|エナジー)\s*[＋+]\s*([0-9]+)", "", "を獲得",1)
  _add(r"(?:エネルギー|エナジー)を([0-9]+)(?=獲得|得|回復)", "", "を",1)
  _add(r"([0-9]+)(?:点の?|ポイントの?)?(?:エネルギー|エナジー)(?=(?:を(?:獲得|得|回復)|が得られる))", "", "",1)
  _add(r"^([0-9]+)(?:エネルギー|エナジー)(?=[。．.]?$)", "", "",1)
 for rule in _rules:
  var matches=rule.regex.search_all(value)
  for i in range(matches.size()-1,-1,-1):
   var hit=matches[i]
   var count=int(hit.get_string(rule.amount))
   if count<=0: continue
   var before=String(rule.before)
   var after=String(rule.after)
   for group in range(1,hit.get_group_count()+1):
    before=before.replace("$"+str(group),hit.get_string(group))
    after=after.replace("$"+str(group),hit.get_string(group))
   value=value.left(hit.get_start())+before+ICON.repeat(count)+after+value.substr(hit.get_end())
 return value

static func _add(pattern: String, before: String, after: String, amount: int) -> void:
 var regex=RegEx.new()
 regex.compile(pattern)
 _rules.append({"regex":regex,"before":before,"after":after,"amount":amount})
