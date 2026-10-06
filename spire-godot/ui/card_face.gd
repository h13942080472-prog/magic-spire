extends Button

const Palette=preload("res://ui/visual_theme.gd")
const WIDTH_TO_HEIGHT=5.0/8.0

static func dimensions(height: float) -> Vector2:
 return Vector2(roundf(height*WIDTH_TO_HEIGHT),height)

# Only standalone glossary sentences move; effect clauses keep their full wording.
static func separate_keywords(effect: String, terms: Array) -> Dictionary:
 var names=terms.map(func(term):return term.name)
 var result={"body":"","keywords":[]}
 var sentences=effect.split("。",true)
 for index in range(sentences.size()):
  var sentence=sentences[index]
  var keyword=sentence.strip_edges()
  if keyword in names:
   if keyword not in result.keywords: result.keywords.append(keyword)
  else:
   result.body+=sentence+("。" if index<sentences.size()-1 else "")
 result.body=result.body.strip_edges()
 return result

const ILLUSTRATIONS={
 "witch_binding_lure":preload("res://assets/ui/cards/witch_binding_lure.svg"),
 "itching_heart":preload("res://assets/ui/cards/desire_magic.svg"),
 "self_satisfaction":preload("res://assets/ui/cards/desire_magic.svg"),
 "psychological_suggestion":preload("res://assets/ui/cards/desire_magic.svg"),
 "rally_spirit":preload("res://assets/ui/cards/desire_magic.svg"),
 "desire_rune":preload("res://assets/ui/cards/desire_magic.svg"),
 "forced_edging":preload("res://assets/ui/cards/desire_magic.svg"),
 "forced_climax":preload("res://assets/ui/cards/desire_magic.svg"),
 "supple_flesh":preload("res://assets/ui/cards/supple_flesh.svg"),
 "binding_power":preload("res://assets/ui/cards/binding_power.svg"),
 "mana_attachment":preload("res://assets/ui/cards/mana_attachment.svg"),
 "binding_search":preload("res://assets/ui/cards/binding_search.svg"),
 "kip_up":preload("res://assets/ui/cards/kip_up.svg"),
 "sympathetic_form":preload("res://assets/ui/cards/sympathetic_form.svg"),
 "endless_war_goddess":preload("res://assets/ui/cards/endless_war_goddess.svg"),
 "self_binding":preload("res://assets/ui/cards/self_binding.svg"),
 "prepared_chant":preload("res://assets/ui/cards/prepared_chant.svg"),
 "confluence":preload("res://assets/ui/cards/confluence.svg"),
 "reuse":preload("res://assets/ui/cards/reuse.svg"),
 "resonance":preload("res://assets/ui/cards/resonance.svg"),
 "formation":preload("res://assets/ui/cards/formation.svg"),
 "practiced":preload("res://assets/ui/cards/practiced.svg"),
 "hannya_1":preload("res://assets/ui/cards/hannya_1.svg"),
 "hannya_2":preload("res://assets/ui/cards/hannya_2.svg"),
 "hannya_3":preload("res://assets/ui/cards/hannya_3.svg"),
 "hannya_4":preload("res://assets/ui/cards/hannya_4.svg"),
 "good_soup":preload("res://assets/ui/cards/good_soup.svg"),
 "hannya_swallow":preload("res://assets/ui/cards/light_as_swallow.svg"),
 "hannya_infusion":preload("res://assets/ui/cards/infusion.svg"),
 "hannya_henshin":preload("res://assets/ui/cards/henshin.svg"),

 "siphon_strength":preload("res://assets/ui/cards/siphon_strength.svg"),
 "shared_fate":preload("res://assets/ui/cards/shared_fate.svg"),
 "magic_hand":preload("res://assets/ui/cards/magic_hand.svg"),
 "magic_hand_gift":preload("res://assets/ui/cards/magic_hand.svg"),
 "leverage":preload("res://assets/ui/cards/leverage.svg"),
 "light_as_swallow":preload("res://assets/ui/cards/light_as_swallow.svg"),
 "restraint_embrace":preload("res://assets/ui/cards/restraint_embrace.svg"),
 "infusion":preload("res://assets/ui/cards/infusion.svg"),
 "siphon":preload("res://assets/ui/cards/siphon.svg"),
 "concentration":preload("res://assets/ui/cards/concentration.svg"),
 "mana_circuit":preload("res://assets/ui/cards/mana_circuit.svg"),
 "breath_control":preload("res://assets/ui/cards/breath_control.svg"),
 "ready_to_strike":preload("res://assets/ui/cards/ready_to_strike.svg"),
 "crossed_legs":preload("res://assets/ui/cards/crossed_legs.svg"),
 "mana_search":preload("res://assets/ui/cards/mana_search.svg"),
 "pot_of_greed":preload("res://assets/ui/cards/pot_of_greed.svg"),
 "repeated_strain":preload("res://assets/ui/cards/repeated_strain.svg"),
 "echo_cast":preload("res://assets/ui/cards/echo_cast.svg"),
 "embers":preload("res://assets/ui/cards/embers.svg"),
 "wildfire_descent":preload("res://assets/ui/cards/wildfire_descent.svg"),
 "boar_emperor_blaze":preload("res://assets/ui/cards/boar_emperor_blaze.svg"),
 "adaptability":preload("res://assets/ui/cards/adaptability.svg"),
 "rekindle":preload("res://assets/ui/cards/rekindle.svg"),
 "fire_dynamics":preload("res://assets/ui/cards/fire_dynamics.svg"),
 "flame_flourish":preload("res://assets/ui/cards/flame_flourish.svg"),
 "letter_opener":preload("res://assets/ui/cards/letter_opener.svg"),
 "fire_control":preload("res://assets/ui/cards/fire_control.svg"),
 "mana_invocation":preload("res://assets/ui/cards/mana_invocation.svg"),
 "mana_surge":preload("res://assets/ui/cards/mana_surge.svg"),
 "mana_conversion":preload("res://assets/ui/cards/mana_conversion.svg"),
 "pleasure_conversion":preload("res://assets/ui/cards/pleasure_conversion.svg"),
 "henshin":preload("res://assets/ui/cards/henshin.svg"),
 "fire_mastery":preload("res://assets/ui/cards/fire_mastery.svg"),
 "binding_enthusiast":preload("res://assets/ui/cards/binding_enthusiast.svg"),
 "strong_elbow":preload("res://assets/ui/cards/strong_elbow.svg"),
 "strain":preload("res://assets/ui/cards/strain.svg"),
 "slip":preload("res://assets/ui/cards/slip.svg"),
 "ease":preload("res://assets/ui/cards/ease.svg"),
 "unlock":preload("res://assets/ui/cards/unlock.svg"),
 "brace":preload("res://assets/ui/cards/brace.svg"),
 "inch":preload("res://assets/ui/cards/inch.svg"),
 "magic_slip":preload("res://assets/ui/cards/magic_slip.svg"),
 "focus":preload("res://assets/ui/cards/focus.svg"),
 "tear":preload("res://assets/ui/cards/tear.svg"),
 "chain":preload("res://assets/ui/cards/chain.svg"),
 "peel":preload("res://assets/ui/cards/peel.svg"),
 "double_unlock":preload("res://assets/ui/cards/double_unlock.svg"),
 "panic":preload("res://assets/ui/cards/panic.svg"),
 "sensitive":preload("res://assets/ui/cards/sensitive.svg"),
 "lewd_mark":preload("res://assets/ui/cards/lewd_mark.svg"),
 "tease":preload("res://assets/ui/cards/tease.svg"),
 "tease_plus":preload("res://assets/ui/cards/tease_plus.svg"),
}

signal flip_requested
signal drag_began(data: Dictionary)

const RARITY_COLORS={"special":Color("b7d8ce"),"basic":Color("bec3c8"),"common":Color("bec3c8"),"uncommon":Color("77b8ed"),"rare":Color("d5b86d"),"curse":Color("b091c8"),"status":Color("bec3c8")}
var rarity="basic"
var single_face=false
var symbol="strain"
var art_settings
var home=Vector2.ZERO
var resting_angle=0.0
var chosen=false
var tween: Tween
var drag_payload: Dictionary={}
var display_name=""
var free_face=false
var effect_free=false:
 set(value):
  if effect_free==value: return
  effect_free=value
  if art_settings!=null and has_node("CardIllustration"): _art_changed("cards",symbol)
var face_name="拘束"
var localize: Callable
var lift_on_hover=true
const ART_HEIGHT_RATIO=2.0/3.0
var art_bottom=174.0
# 正文溢出＝`fit_text` 的结果（唯一写入点）；悬停详情读它，不读 `Content.size`：
# 容器尺寸要等引擎的排序趟，直接读节点会拿到尚未按当前值重算的高度。
var text_overflow=false
var _fit_pending=false
# Content 的固定槽序：分类／正文／警告／可用性。按槽序写、同名标签就地改写，tooltip 行序才稳定。
const CONTENT_SLOTS=["CardClassification","CardEffect","CardWarning","CardAvailability"]
# 出树但未销毁的备用节点（按 kind 分区，仅词条／条件／魔力三类组）：多余节点先入池再复用，
# 翻回已应用过的面时用回同一实例；内容槽（`_content_slot`）不池化，理由见该函数。
var _spare: Dictionary={}

const MANA_COLORS={"cost":Color("8dd6ef"),"gain":Color("80e0c5"),"temporary":Color("c4a0ef")}

func text_scale() -> float:
 return maxf(1.0,size.y/320.0)

func _display(value: Variant) -> String:
 var text=str(value)
 return str(localize.call(text)) if localize.is_valid() else text

# 玩家可见文案与 ui/main.gd::_label 同一口径（本地化后再做安卓输入提示替换）。
func _shown(value: Variant) -> String:
 var text=_display(value)
 return text.replace("右键","长按") if OS.has_feature("android") else text

func _new_label(text: String, font_size: int, color: Color) -> Label:
 var label=Label.new()
 label.text=text
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",color)
 return label

func _take(bucket: String) -> Node:
 var pool=_spare.get(bucket,[])
 return pool.pop_back() if not pool.is_empty() else null

func _park(bucket: String, node: Node) -> void:
 var owner=node.get_parent()
 if owner!=null: owner.remove_child(node)
 if not _spare.has(bucket): _spare[bucket]=[]
 _spare[bucket].append(node)

func _exit_tree() -> void:
 for bucket in _spare:
  for node in _spare[bucket]:
   if is_instance_valid(node): node.queue_free()
 _spare={}

# 每卡每帧至多一次延迟布局：同批 setter 只请求一次，值没变则一次都不请求。
func _request_fit() -> void:
 if _fit_pending: return
 _fit_pending=true
 fit_text.call_deferred()

# Content 槽：同名标签保持在固定槽序上；缺件即新建。
# 条件槽（警告／可用性）文本为空即销毁；常驻槽（`always`，分类／正文）保持挂载只切可见性。
# 内容标签出 Content 后不得再插回：配方里把已移除的标签重新挂进 ScrollContainer 的 `Content` 必崩、
# 停用该池化即消失（E1 表明该形态单独不足以复现；机理未确证——证据见 docs/record/verification.md 2026-10-05 条），
# 故这个槽位不做池化复用。池（`_spare`）只保留给词条／条件／魔力三类组：它们的回插目标不是 `Content`，
# 但这不证明安全——卡面会被放进 ScrollContainer 子树（图鉴／牌库／离狱），该复用仍属未证（待 E2）。
func _content_slot(label_name: String, text: String, font_size: int, color: Color, always: bool=false) -> bool:
 var area=get_node_or_null("CardText")
 var content=area.get_node_or_null("Content") if area!=null else null
 if content==null: return false
 var node=null
 for child in content.get_children():
  if String(child.name)==label_name: node=child;break
 if text=="" and not always:
  if node==null: return false
  content.remove_child(node)
  node.queue_free()
  return true
 var changed=false
 if node==null:
  node=_new_label("",font_size,color)
  node.name=label_name
  content.add_child(node)
  changed=true
 if String(node.text)!=text: node.text=text;changed=true
 if node.get_theme_font_size("font_size")!=font_size: node.add_theme_font_size_override("font_size",font_size);changed=true
 if node.get_theme_color("font_color")!=color: node.add_theme_color_override("font_color",color);changed=true
 var wanted=text!=""
 if node.visible!=wanted: node.visible=wanted;changed=true
 # 固定槽序：目标槽位还没被前序标签占满时落在末尾（前序槽是后加的，`move_child` 不接受越界位置）。
 var want=mini(CONTENT_SLOTS.find(label_name),content.get_child_count()-1)
 if want>=0 and node.get_index()!=want: content.move_child(node,want);changed=true
 return changed

# 词条／条件标签组的唯一写入路径：第 i 条写第 i 个槽（槽存在即复用，否则取池中备用，最后才新建），
# 多余项从组尾出树入池；组可见性跟随非空；有变才请求一次延迟布局。
# 两个 setter 只给样式差异：词条金色且不拆字换行，条件蓝色且右对齐。
func _write_tags(group_name: String, bucket: String, list: Array, color: Color, wrap_off: bool, right_aligned: bool) -> void:
 var group=get_node_or_null(group_name)
 if group==null: return
 var font_size=roundi(11*text_scale())
 var changed=false
 for index in range(list.size()):
  var label=null
  if index<group.get_child_count():
   var seat=group.get_child(index)
   if seat is Label: label=seat
  if label==null: label=_take(bucket) as Label
  if label==null:
   label=_new_label("",font_size,color)
   group.add_child(label)
   changed=true
  if label.get_parent()!=group: group.add_child(label)
  var shown=_shown(list[index])
  if String(label.text)!=shown: label.text=shown;changed=true
  if label.get_theme_font_size("font_size")!=font_size: label.add_theme_font_size_override("font_size",font_size);changed=true
  if label.get_theme_color("font_color")!=color: label.add_theme_color_override("font_color",color);changed=true
  if wrap_off and label.autowrap_mode!=TextServer.AUTOWRAP_OFF: label.autowrap_mode=TextServer.AUTOWRAP_OFF;changed=true
  if right_aligned and label.horizontal_alignment!=HORIZONTAL_ALIGNMENT_RIGHT: label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;changed=true
 while group.get_child_count()>list.size():
  _park(bucket,group.get_child(group.get_child_count()-1));changed=true
 var wanted=not list.is_empty()
 if group.visible!=wanted: group.visible=wanted;changed=true
 if changed: _request_fit()

# 魔力徽章槽：以位置为主、kind 只作匹配提示（同 kind 可有多条）。位置不符时先在组内
# 按位置顺序找同 kind 的节点并前移，再取池中同 kind 的备用节点，最后才新建。
func _mana_slot(group: Node, index: int, kind: String) -> Control:
 var children=group.get_children()
 if index<children.size() and String(children[index].get_meta("mana_kind",""))==kind: return children[index]
 for other in range(index+1,children.size()):
  if String(children[other].get_meta("mana_kind",""))==kind:
   var node=children[other]
   group.move_child(node,index)
   return node
 var pooled=_take("mana_"+kind) as Control
 if pooled!=null: return pooled
 var badge=Control.new() if kind=="pressure" else PanelContainer.new()
 badge.name="Mana_"+kind
 badge.set_meta("mana_kind",kind)
 badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return badge

func _write_mana(node: Control, entry: Array, unit: float, compact: bool) -> bool:
 var kind=String(entry[0])
 var changed=false
 if kind=="pressure":
  var art=null
  var amount=null
  for child in node.get_children():
   if child is Label: amount=child
   elif child is TextureRect: art=child
  if art==null:
   art=TextureRect.new()
   art.texture=preload("res://assets/ui/cards/pressure_heart.svg")
   art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
   art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   art.mouse_filter=Control.MOUSE_FILTER_IGNORE
   node.add_child(art);art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
   changed=true
  if amount==null:
   amount=Label.new()
   amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   amount.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
   amount.add_theme_color_override("font_color",Color("fff3fa"))
   amount.mouse_filter=Control.MOUSE_FILTER_IGNORE
   node.add_child(amount);amount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
   changed=true
  if String(amount.text)!=String(entry[1]): amount.text=entry[1];changed=true
  var size=Vector2(42,36)*unit
  if node.custom_minimum_size!=size: node.custom_minimum_size=size;changed=true
  var heart_font=roundi(16*text_scale())
  if amount.get_theme_font_size("font_size")!=heart_font: amount.add_theme_font_size_override("font_size",heart_font);changed=true
  var detail=_display(entry[2])
  if node.tooltip_text!=detail: node.tooltip_text=detail;changed=true
  return changed
 var label=null
 for child in node.get_children():
  if child is Label: label=child
 if label==null:
  label=Label.new()
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  node.add_child(label)
  changed=true
 var style=node.get_theme_stylebox("panel") if node.has_theme_stylebox_override("panel") else null
 if not (style is StyleBoxFlat):
  style=StyleBoxFlat.new()
  node.add_theme_stylebox_override("panel",style)
  changed=true
 var detail=_display(entry[2])
 if node.tooltip_text!=detail: node.tooltip_text=detail;changed=true
 var bg=Color("29233e") if kind=="temporary" else Color("143542")
 if style.bg_color!=bg: style.bg_color=bg;changed=true
 if style.border_color!=MANA_COLORS[kind]: style.border_color=MANA_COLORS[kind];changed=true
 var radius=roundi((7 if kind=="temporary" else 18)*unit)
 if style.corner_radius_top_left!=radius:
  style.set_border_width_all(2)
  style.set_corner_radius_all(radius)
  changed=true
 var margin=(4 if compact else 6)*unit
 if not is_equal_approx(style.content_margin_left,margin):
  style.content_margin_left=margin;style.content_margin_right=margin
  changed=true
 var shown=_display(entry[1])
 if String(label.text)!=shown: label.text=shown;changed=true
 if label.get_theme_color("font_color")!=MANA_COLORS[kind]: label.add_theme_color_override("font_color",MANA_COLORS[kind]);changed=true
 var font=label.get_theme_font("font")
 var font_size=17 if compact else roundi(21*text_scale())
 while font_size>roundi(13*unit) and font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>49*unit: font_size-=1
 if label.get_theme_font_size("font_size")!=font_size: label.add_theme_font_size_override("font_size",font_size);changed=true
 var badge_size=Vector2(32 if compact else 38,36)*unit
 if node.custom_minimum_size!=badge_size: node.custom_minimum_size=badge_size;changed=true
 return changed

# 魔力徽章按位置／kind 复用：条目数或 kind 变才增删，已存在的徽章节点与它的 `panel`
# 样式资源实例保持不变（翻回已应用过的面零增删、不新建 `StyleBox`）。
# `entries` 是值切片里的扁平条目 `[kind, text, detail]`（唯一取用点是 `ui/main.gd::_refresh_card_face`）。
func set_mana(entries: Array) -> void:
 var unit=text_scale()
 var compact=size.x<180
 var group=get_node_or_null("CardMana")
 if group==null:
  group=HBoxContainer.new();group.name="CardMana"
  group.add_theme_constant_override("separation",3)
  group.mouse_filter=Control.MOUSE_FILTER_IGNORE
  add_child(group)
 var wanted=not entries.is_empty()
 var changed=group.visible!=wanted
 group.visible=wanted
 for index in range(entries.size()):
  var badge=_mana_slot(group,index,String(entries[index][0]))
  if badge.get_parent()!=group: group.add_child(badge)
  if badge.get_index()!=index: group.move_child(badge,index)
  changed=_write_mana(badge,entries[index],unit,compact) or changed
 while group.get_child_count()>entries.size():
  var extra=group.get_child(group.get_child_count()-1)
  _park("mana_"+String(extra.get_meta("mana_kind","")),extra)
  changed=true
 if changed: _layout_header()

func set_title(text: String) -> void:
 if display_name==text: return
 display_name=text
 _layout_header()

func set_cost(text: String) -> void:
 var label=get_node_or_null("CardCost")
 if label==null or String(label.text)==text: return
 label.text=text
 _layout_header()

func set_classification(text: String) -> void:
 if _content_slot("CardClassification",_shown(text),11,RARITY_COLORS[rarity],true): _request_fit()

func set_effect(text: String) -> void:
 if _content_slot("CardEffect",_shown(text),14,Palette.TEXT,true): _request_fit()

func set_warning(text: String) -> void:
 if _content_slot("CardWarning",_shown(text),14,Palette.RED): _request_fit()

func set_availability(text: String) -> void:
 if _content_slot("CardAvailability",_shown(text),11,Palette.TEXT): _request_fit()

func set_keywords(list: Array) -> void:
 _write_tags("CardKeywords","keyword",list,Palette.GOLD,true,false)

func set_requirements(list: Array) -> void:
 _write_tags("CardRequirements","requirement",list,Palette.CYAN,false,true)

# 纹理不缓存：每次都按当前画风现取，画风变（`_art_changed`）与换面共用同一条取纹理路径。
func _apply_art_texture() -> void:
 if not has_node("CardIllustration"): return
 var texture=null if art_settings==null else art_settings.art_texture("cards",symbol,effect_free)
 if texture==null: texture=ILLUSTRATIONS.get(preload("res://data/card_rules.gd").SPECS.get(symbol,{}).get("art_type",symbol))
 $CardIllustration.texture=texture

func set_art(symbol_value: String, free_effect: bool) -> void:
 var layout_changed=symbol!=symbol_value or effect_free!=free_effect
 symbol=symbol_value
 effect_free=free_effect
 _apply_art_texture()
 if layout_changed: _layout_art()

func _layout_header() -> void:
 var title=get_node_or_null("CardTitle")
 if title==null: return
 var unit=text_scale()
 var group=get_node_or_null("CardMana")
 title.position=Vector2(43*unit,0)
 title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var right=size.x-5*unit
 if group!=null and group.visible:
  group.size=group.get_combined_minimum_size()
  group.position=Vector2(size.x-group.size.x-unit,unit)
  right=group.position.x-4*unit
 var width=maxf(1,right-title.position.x)
 title.clip_text=true
 var full_title=_display(display_name) if display_name!="" else title.text.replace("\n","")
 title.text=full_title
 title.autowrap_mode=TextServer.AUTOWRAP_OFF
 var title_height=38.0*unit
 title.add_theme_constant_override("line_spacing",0)
 var font_size=roundi(17*text_scale())
 while font_size>roundi(11*unit) and title.get_theme_font("font").get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width: font_size-=1
 title.add_theme_font_size_override("font_size",font_size)
 # Long names use the existing header height instead of pushing into mana badges.
 if title.get_theme_font("font").get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:
  var separator=full_title.find("（")
  if separator<0: separator=full_title.find("(")
  if separator>0: title.text=full_title.substr(0,separator)+"\n"+full_title.substr(separator)
  title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  title_height=40*unit
 title.size=Vector2(width,title_height)
 var cost=get_node_or_null("CardCost")
 if cost!=null:
  cost.autowrap_mode=TextServer.AUTOWRAP_OFF
  cost.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  cost.add_theme_font_size_override("font_size",roundi(23*unit))
  cost.position=Vector2.ZERO;cost.size=Vector2(38,38)*unit

# The illustration keeps its share even when a face has long requirements.
func _layout_art() -> void:
 art_bottom=6.0+size.y*ART_HEIGHT_RATIO
 var picture=get_node_or_null("CardIllustration")
 if picture!=null:
  # Fit the full illustration below the header without cropping or stretching.
  picture.position=Vector2(8,42*text_scale())
  picture.size=Vector2(maxf(1,size.x-16),maxf(1,art_bottom-picture.position.y))
 var header=get_node_or_null("CardHeader")
 if header!=null: header.queue_redraw()
 queue_redraw()

func fit_text() -> void:
 _fit_pending=false
 _layout_header()
 _layout_art()
 var area=get_node_or_null("CardText")
 if area==null: return
 area.position=Vector2(12,art_bottom+4)
 var bottom=size.y-8
 var footer=get_node_or_null("CardKeywords")
 var requirements=get_node_or_null("CardRequirements")
 var available_width=size.x-24
 var keyword_width=0.0
 var requirement_width=0.0
 for group in [footer,requirements]:
  if group==null or not group.visible: continue
  for label in group.get_children():
   var font_size=roundi(11*text_scale())
   if label.get_theme_font_size("font_size")!=font_size: label.add_theme_font_size_override("font_size",font_size)
   if group==footer:
    keyword_width+=label.get_combined_minimum_size().x+8
   else:
    for line in label.text.split("\n"):
     requirement_width=maxf(requirement_width,ceilf(label.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x))
 keyword_width=maxf(0,keyword_width-8)
 requirement_width=minf(available_width,requirement_width)
 var side_by_side=keyword_width+requirement_width+8<=available_width
 if requirements!=null and requirements.visible:
  requirements.size=Vector2(requirement_width,requirements.get_combined_minimum_size().y)
  requirements.position=Vector2(size.x-12-requirements.size.x,size.y-14-requirements.size.y)
  bottom=requirements.position.y-4
 if footer!=null and footer.visible:
  # The flow owns keyword widths after font shaping; a minimum-size update reflows the body.
  footer.size=Vector2(available_width-requirement_width-8 if side_by_side and requirement_width>0 else available_width,footer.get_combined_minimum_size().y)
  footer.position=Vector2(12,size.y-14-footer.size.y)
  if requirement_width>0 and not side_by_side: footer.position.y=bottom-footer.size.y
  bottom=minf(bottom,footer.position.y-4)
 area.size=Vector2(size.x-24,maxf(1,bottom-area.position.y))
 # 溢出判据的唯一写入点：读刚算完的可见高度与正文的最小高度（容器尺寸当帧未必已排序）。
 var content=area.get_node_or_null("Content")
 text_overflow=content!=null and content.get_combined_minimum_size().y>area.size.y
 for label in area.get_node("Content").get_children():
  var base_size=12 if label.name=="CardEffect" else (14 if label.name=="CardWarning" else 11)
  label.add_theme_font_size_override("font_size",roundi(base_size*text_scale()))

func _draw_header() -> void:
 var header=get_node("CardHeader")
 var accent=RARITY_COLORS[rarity]
 var unit=text_scale()
 header.draw_rect(Rect2(8,6,size.x-16,41*unit-6),Color("142c36") if effect_free else Color("17222f"))
 header.draw_line(Vector2(8,40*unit),Vector2(size.x-8,40*unit),Color(accent,0.55),1,true)
 header.draw_circle(Vector2(19,19)*unit,20*unit,Color("102634") if effect_free else Color("2f2b25"))
 header.draw_arc(Vector2(19,19)*unit,19*unit,0,TAU,32,accent,2,true)
 header.draw_arc(Vector2(19,19)*unit,15*unit,0,TAU,32,Color(accent,0.4),1,true)

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
  accept_event()
  flip_requested.emit()

func _get_drag_data(_at_position: Vector2) -> Variant:
 if drag_payload.is_empty(): return null
 var ghost=PanelContainer.new()
 ghost.name="CardDragPreview";ghost.z_index=240;ghost.position=Vector2(18,18)
 ghost.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ghost.custom_minimum_size=Vector2(190,75)
 ghost.modulate=Color(1,1,1,0.94)
 ghost.add_theme_stylebox_override("panel",Palette.surface(Palette.INK,Palette.CYAN if effect_free else Palette.GOLD))
 var label=Label.new()
 label.text=_display(display_name)+"\n"+_display("单面卡牌" if single_face else face_name)
 label.add_theme_font_size_override("font_size",18)
 ghost.add_child(label)
 set_drag_preview(ghost)
 drag_began.emit(drag_payload)
 return drag_payload

func _ready() -> void:
 mouse_entered.connect(func(): _hover(true))
 mouse_exited.connect(func(): _hover(false))
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var illustration=TextureRect.new()
 illustration.name="CardIllustration"
 illustration.texture=ILLUSTRATIONS.get(preload("res://data/card_rules.gd").SPECS.get(symbol,{}).get("art_type",symbol))
 illustration.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 illustration.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 illustration.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 illustration.clip_contents=true
 illustration.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(illustration)
 if art_settings!=null:
  art_settings.art_changed.connect(_art_changed)
  _art_changed("cards",symbol)
 var header=Control.new();header.name="CardHeader";header.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(header);header.draw.connect(_draw_header)
 _layout_art()
 resized.connect(fit_text)

func _art_changed(category: String, id: String) -> void:
 if category!="cards" or id!=symbol: return
 _apply_art_texture()

func _hover(raised: bool) -> void:
 if not lift_on_hover: return
 if is_instance_valid(tween): tween.kill()
 tween=create_tween().set_parallel(true)
 tween.tween_property(self,"position",home+Vector2(0,-44 if raised else 0),0.13)
 tween.tween_property(self,"rotation",0.0 if raised else resting_angle,0.13)
 z_index=100 if raised else (20 if chosen else 0)

func _draw() -> void:
 var accent=RARITY_COLORS[rarity]
 var outline=PackedVector2Array([Vector2(11,0),Vector2(size.x-11,0),Vector2(size.x,11),Vector2(size.x,size.y-11),Vector2(size.x-11,size.y),Vector2(11,size.y),Vector2(0,size.y-11),Vector2(0,11)])
 var shadow=outline.duplicate()
 for i in range(shadow.size()): shadow[i]+=Vector2(3,6)
 draw_colored_polygon(shadow,Color(0.015,0.023,0.03,0.75))
 draw_colored_polygon(outline,Color("193c43") if effect_free else Color("393127"))
 var closed=outline.duplicate();closed.append(outline[0])
 draw_polyline(closed,Palette.CYAN if chosen else accent,2,true)
 draw_rect(Rect2(6,6,size.x-12,size.y-12),Color("142c36") if effect_free else Color("17222f"))
 draw_rect(Rect2(8,6,size.x-16,art_bottom-6),Color("24515a") if effect_free else Color("3b3b37"))
 for i in range(9):
  var alpha=0.08*(1-float(i)/9)
  var band=(art_bottom-42*text_scale()-1)/9
  draw_rect(Rect2(8,42*text_scale()+i*band,size.x-16,band),Color(accent,alpha))
 draw_line(Vector2(8,art_bottom),Vector2(size.x-8,art_bottom),Color(accent,0.7),1,true)
 # Foil corner brackets distinguish the two faces even with illustration overlap.
 for side in [-1,1]:
  var x=10 if side<0 else size.x-10
  draw_line(Vector2(x,10),Vector2(x,31),accent,1,true)
  draw_line(Vector2(x,size.y-25),Vector2(x,size.y-10),accent,1,true)
  draw_line(Vector2(x,size.y-10),Vector2(x-side*17,size.y-10),accent,1,true)
