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
 "but_also":preload("res://assets/ui/cards/but_also.svg"),
 "art_submission":preload("res://assets/ui/cards/art_submission.svg"),
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
 "liberating_grace":preload("res://assets/ui/cards/liberating_grace.svg"),
 "shining_debut":preload("res://assets/ui/cards/shining_debut.svg"),
 "binding_search":preload("res://assets/ui/cards/binding_search.svg"),
 "kip_up":preload("res://assets/ui/cards/kip_up.svg"),
 "dual_chant":preload("res://assets/ui/cards/dual_chant.svg"),
 "study":preload("res://assets/ui/cards/study.svg"),
 "shockwave":preload("res://assets/ui/cards/shockwave.svg"),
 "find_weakness":preload("res://assets/ui/cards/find_weakness.svg"),
 "yield_force":preload("res://assets/ui/cards/yield_force.svg"),
 "sympathetic_form":preload("res://assets/ui/cards/sympathetic_form.svg"),
 "endless_war_goddess":preload("res://assets/ui/cards/endless_war_goddess.svg"),
 "self_binding":preload("res://assets/ui/cards/self_binding.svg"),
 "full_escape":preload("res://assets/ui/cards/full_escape.svg"),
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
 "pocket_knife":preload("res://assets/ui/relics/pocket_knife.svg"),
 "royal_gift":preload("res://assets/ui/relics/kings_gift_revised.svg"),
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
 "forethought":preload("res://assets/ui/cards/forethought.svg"),
 "mana_search":preload("res://assets/ui/cards/mana_search.svg"),
 "mana_arm":preload("res://assets/ui/cards/mana_arm.svg"),
 "finesse":preload("res://assets/ui/cards/finesse.svg"),
 "last_resort":preload("res://assets/ui/cards/last_resort.svg"),
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
 "detective_provoke":preload("res://assets/ui/cards/detective_provoke.svg"),
 "disrupt":preload("res://assets/ui/cards/disrupt.svg"),
 "tease_plus":preload("res://assets/ui/cards/tease_plus.svg"),
}

signal flip_requested
signal drag_began(data: Dictionary)
signal description_changed(expanded: bool)

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
var preview_factory: Callable
var inspect_requested: Callable
var drag_grab=Vector2.ZERO
var drag_grabbed=false
var fit_all_copy=false
var art_bottom=174.0
# 正文溢出＝`fit_text` 的结果（唯一写入点）；悬停详情读它，不读 `Content.size`：
# 容器尺寸要等引擎的排序趟，直接读节点会拿到尚未按当前值重算的高度。
var text_overflow=false
var description_expanded=false
var _description_rise=0.0
var _fit_pending=false
# Keywords and requirements precede the ordered label slots.
const EnergyText=preload("res://ui/card_energy_text.gd")
const CONTENT_SLOTS=["CardEffect","CardWarning","CardAvailability"]
# 出树但未销毁的备用节点（按 kind 分区，仅词条／条件／魔力三类组）：多余节点先入池再复用，
# 翻回已应用过的面时用回同一实例；内容槽（`_content_slot`）不池化，理由见该函数。
var _spare: Dictionary={}

const Insignia=preload("res://assets/ui/card-insignia.svg")
const Metalwork=preload("res://assets/ui/card-metalwork.svg")
const EnergyMedallion=preload("res://assets/ui/energy-medallion.svg")
const Rules=preload("res://data/card_rules.gd")
const TYPE_ICONS={"skill":0,"magic":1,"power":2,"item":3,"curse":4,"status":5}
const RARITY_ICONS={"basic":8,"common":9,"uncommon":10,"rare":11,"curse":12,"status":13,"special":13}
const MANA_ICONS={"gain":14,"cost":15,"temporary":16}
var _mana_entries: Array=[]
var _type_icon=0
var _strip_y=0.0
var _type_y=0.0

static func _stamp(canvas: CanvasItem, slot: int, center: Vector2, span: float) -> void:
 canvas.draw_texture_rect_region(Insignia,Rect2(center-Vector2.ONE*span/2,Vector2.ONE*span),Rect2(slot*64,0,64,64))

const PRINT_INSET=11.0
const KEYWORD_INK=Color("ffe5b6")
const KeywordPlate=preload("res://assets/ui/card-keyword.tres")
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
# 条件槽（警告／可用性）文本为空即销毁；常驻槽（`always`，正文）保持挂载只切可见性。
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
  node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  node.name=label_name
  content.add_child(node)
  if label_name=="CardEffect": node.add_theme_font_override("font",EnergyText.font_for(node.get_theme_font("font")))
  changed=true
 if String(node.text)!=text: node.text=text;changed=true
 if node.get_theme_font_size("font_size")!=font_size: node.add_theme_font_size_override("font_size",font_size);changed=true
 if node.get_theme_color("font_color")!=color: node.add_theme_color_override("font_color",color);changed=true
 var wanted=text!=""
 if node.visible!=wanted: node.visible=wanted;changed=true
 # 固定槽序：目标槽位还没被前序标签占满时落在末尾（前序槽是后加的，`move_child` 不接受越界位置）。
 var want=mini(CONTENT_SLOTS.find(label_name)+2,content.get_child_count()-1)
 if want>=0 and node.get_index()!=want: content.move_child(node,want);changed=true
 return changed

# 词条／条件标签组的唯一写入路径：第 i 条写第 i 个槽（槽存在即复用，否则取池中备用，最后才新建），
# 多余项从组尾出树入池；组可见性跟随非空；有变才请求一次延迟布局。
# Keywords keep their plates on one line; requirements can wrap.
func _write_tags(group_name: String, bucket: String, list: Array, color: Color, wrap_off: bool) -> void:
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
   label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   if bucket=="keyword": label.add_theme_stylebox_override("normal",KeywordPlate)
   group.add_child(label)
   changed=true
  if label.get_parent()!=group: group.add_child(label)
  var shown=_shown(list[index])
  if String(label.text)!=shown: label.text=shown;changed=true
  if label.get_theme_font_size("font_size")!=font_size: label.add_theme_font_size_override("font_size",font_size);changed=true
  if label.get_theme_color("font_color")!=color: label.add_theme_color_override("font_color",color);changed=true
  if wrap_off and label.autowrap_mode!=TextServer.AUTOWRAP_OFF: label.autowrap_mode=TextServer.AUTOWRAP_OFF;changed=true
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
 if kind in MANA_ICONS:
  badge.draw.connect(func():
   var span=badge.size.y*0.79
   _stamp(badge,MANA_ICONS[kind],Vector2(span*0.54,badge.size.y/2),span))
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
  var size=Vector2(24,23)*unit
  if node.custom_minimum_size!=size: node.custom_minimum_size=size;changed=true
  var heart_font=roundi(12*unit)
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
 var bg=Color("27323e")
 if style.bg_color!=bg: style.bg_color=bg;changed=true
 if style.border_color!=MANA_COLORS[kind]: style.border_color=MANA_COLORS[kind];changed=true
 var radius=maxi(2,roundi(3*unit))
 if style.corner_radius_top_left!=radius:
  style.set_border_width_all(1)
  style.set_corner_radius_all(radius)
  changed=true
 var margin=16*unit
 if not is_equal_approx(style.content_margin_left,margin):
  style.content_margin_left=margin;style.content_margin_right=3*unit
  style.content_margin_top=0;style.content_margin_bottom=0
  changed=true
 var shown=_display(entry[1])
 if String(label.text)!=shown: label.text=shown;changed=true
 if label.get_theme_color("font_color")!=Color("fff1d6"): label.add_theme_color_override("font_color",Color("fff1d6"));changed=true
 var font=label.get_theme_font("font")
 var font_size=roundi((15 if compact else 15.5)*unit)
 while font_size>roundi(13*unit) and font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>49*unit: font_size-=1
 if label.get_theme_font_size("font_size")!=font_size: label.add_theme_font_size_override("font_size",font_size);changed=true
 var badge_size=Vector2(32,21)*unit
 if node.custom_minimum_size!=badge_size: node.custom_minimum_size=badge_size;changed=true
 return changed

# 魔力徽章按位置／kind 复用：条目数或 kind 变才增删，已存在的徽章节点与它的 `panel`
# 样式资源实例保持不变（翻回已应用过的面零增删、不新建 `StyleBox`）。
# `entries` 是值切片里的扁平条目 `[kind, text, detail]`（唯一取用点是 `ui/main.gd::_refresh_card_face`）。
func set_mana(entries: Array) -> void:
 _mana_entries=entries
 var unit=maxf(0.5,size.y/252.0)
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
 if changed: _request_fit()

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
 var label=$CardHeader/CardClassification
 var shown=_shown(text)
 var tags=Rules.type_tags(symbol,free_face) if Rules.SPECS.has(symbol) else []
 var icon=int(TYPE_ICONS.get(tags.front(),0)) if not tags.is_empty() else 0
 if label.text==shown and _type_icon==icon: return
 _type_icon=icon
 label.text=shown
 _request_fit()

func set_effect(text: String) -> void:
 if _content_slot("CardEffect",EnergyText.render(_shown(text)),roundi(13*text_scale()),Palette.TEXT,true): _request_fit()

func set_warning(text: String) -> void:
 if _content_slot("CardWarning",_shown(text),14,Palette.RED): _request_fit()

func set_availability(text: String) -> void:
 if _content_slot("CardAvailability",_shown(text),11,Palette.TEXT): _request_fit()

func set_keywords(list: Array) -> void:
 _write_tags("CardText/Content/CardKeywords","keyword",list,KEYWORD_INK,true)

func set_requirements(list: Array) -> void:
 _write_tags("CardText/Content/CardRequirements","requirement",list,Color("bedad4") if effect_free else Color("dec9da"),false)

# 纹理不缓存：每次都按当前画风现取，画风变（`_art_changed`）与换面共用同一条取纹理路径。
func _apply_art_texture() -> void:
 if not has_node("CardIllustration"): return
 var spec=preload("res://data/card_rules.gd").SPECS.get(symbol,{})
 # Wall cutters share an effect type across two illustrated faces.
 var art_side=free_face if spec.get("wall_face",false) else effect_free
 var texture=null if art_settings==null else art_settings.art_texture("cards",symbol,art_side)
 if texture==null: texture=ILLUSTRATIONS.get(spec.get("art_type",symbol))
 if $CardIllustration.texture!=texture:
  $CardIllustration.texture=texture
  _request_fit()
 var glyph=$CardIllustration.get_node_or_null("ToolGlyph")
 var is_tool=preload("res://data/field_tools.gd").TYPES.has(symbol)
 if is_tool and glyph==null:
  glyph=preload("res://ui/shop_glyph.gd").new();glyph.name="ToolGlyph";glyph.kind="tool"
  $CardIllustration.add_child(glyph)
 if glyph!=null:
  glyph.visible=is_tool and texture==null;glyph.symbol=symbol;glyph.queue_redraw()

func set_art(symbol_value: String, free_effect: bool) -> void:
 var layout_changed=symbol!=symbol_value or effect_free!=free_effect
 symbol=symbol_value
 effect_free=free_effect
 _apply_art_texture()
 if layout_changed: _layout_art()

func _layout_header() -> void:
 var title=get_node_or_null("CardTitle")
 if title==null: return
 var unit=maxf(0.5,size.y/252.0)
 var cost=$CardCost
 var diameter=28.0*unit
 cost.autowrap_mode=TextServer.AUTOWRAP_OFF
 cost.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 cost.add_theme_font_size_override("font_size",roundi(19*unit))
 cost.size=Vector2.ONE*diameter
 cost.position=Vector2(18,16)*unit-cost.size/2
 var right=size.x-(14+_gem_count()*6)*unit
 title.position=Vector2(35*unit,0)
 var width=maxf(1,right-title.position.x)
 title.clip_text=true
 title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 title.text=_display(display_name)
 title.autowrap_mode=TextServer.AUTOWRAP_OFF
 title.add_theme_constant_override("line_spacing",roundi(-3*unit))
 var title_height=32*unit
 var font=title.get_theme_font("font")
 var font_size=roundi(15*unit)
 while font_size>floori(10*unit) and font.get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width: font_size-=1
 if font.get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:
  title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 title.add_theme_font_size_override("font_size",font_size)
 title.size=Vector2(width,title_height)

func _gem_count() -> int:
 return 3 if rarity=="rare" else (2 if rarity=="uncommon" else 1)

func _type_text_left(unit: float) -> float:
 return (PRINT_INSET+(15 if single_face else 31))*unit

# A single resource shares the type row. Long translations can wrap within the left column.
func _layout_art() -> void:
 var unit=maxf(0.5,size.y/252.0)
 var header=get_node_or_null("CardHeader")
 var category=get_node_or_null("CardHeader/CardClassification")
 var mana=get_node_or_null("CardMana")
 var row_height=20*unit
 var inset=PRINT_INSET*unit
 var padding=2.0*unit
 var left=_type_text_left(unit)
 var mana_size=Vector2.ZERO
 if mana!=null and mana.visible:
  mana_size=mana.get_combined_minimum_size()
  mana.size=mana_size
 var stack_rows=false
 if category!=null:
  var type_size=roundi(13*unit)
  var font=category.get_theme_font("font")
  var minimum_size=maxi(1,floori(11*unit))
  var available=size.x-inset-left
  if mana_size.x>0:
   var beside_mana=available-mana_size.x-padding
   var compact_width=font.get_string_size(category.text,HORIZONTAL_ALIGNMENT_LEFT,-1,minimum_size).x
   stack_rows=beside_mana<minimum_size or (mana.get_child_count()>1 and compact_width>beside_mana)
   if not stack_rows: available=beside_mana
  available=maxf(1,available)
  while type_size>minimum_size and font.get_string_size(category.text,HORIZONTAL_ALIGNMENT_LEFT,-1,type_size).x>available:
   type_size-=1
  category.add_theme_font_size_override("font_size",type_size)
  category.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  category.size=Vector2(available,0)
  row_height=maxf(row_height,category.get_minimum_size().y)
 var band_height=row_height+mana_size.y+padding if stack_rows else maxf(row_height,mana_size.y)
 var picture=get_node_or_null("CardIllustration")
 var picture_width=maxf(1,size.x-12*unit)
 var picture_height=picture_width
 if picture!=null and picture.texture!=null:
  var texture_size=picture.texture.get_size()
  picture_height=picture_width*texture_size.y/maxf(1,texture_size.x)
 # Square art owns the full inner width. All copy below the band shares one scroll.
 var copy_height=maxf(20,17*unit)
 var content=get_node_or_null("CardText/Content")
 if content!=null and (not is_equal_approx(picture_width,picture_height) or fit_all_copy):
  var required_height=ceilf(content.get_combined_minimum_size().y)+unit
  var effect=content.get_node_or_null("CardEffect")
  if effect!=null and not fit_all_copy:
   var two_lines=2*effect.get_line_height()+effect.get_theme_constant("line_spacing")+2*unit
   var keywords=content.get_node("CardKeywords")
   if keywords.visible: two_lines+=keywords.get_combined_minimum_size().y+content.get_theme_constant("separation")
   required_height=minf(required_height,two_lines)
  copy_height=maxf(copy_height,required_height)
 var picture_top=32*unit
 var fixed_height=picture_top+band_height+2*padding+2*unit+copy_height+inset
 picture_height=clampf(picture_height,1,maxf(1,size.y-fixed_height))
 _description_rise=0.0
 if description_expanded and content!=null:
  var compact_height=size.y-(fixed_height-copy_height)-picture_height
  _description_rise=clampf(ceilf(content.get_combined_minimum_size().y)+1-compact_height,0,picture_height)
 _strip_y=picture_top+picture_height-_description_rise
 art_bottom=_strip_y+band_height+2*padding
 var row_bottom=art_bottom-padding
 _type_y=_strip_y+padding+(row_height if stack_rows else band_height)*0.5
 if mana_size.y>0:
  mana.position=Vector2(size.x-inset-mana_size.x,row_bottom-mana_size.y if stack_rows else _type_y-mana_size.y/2)
 if category!=null:
  category.position=Vector2(left,_type_y-row_height/2)
  category.size.y=row_height
 if picture!=null:
  picture.position=Vector2(6*unit,picture_top)
  picture.size=Vector2(picture_width,picture_height)
  var glyph=picture.get_node_or_null("ToolGlyph")
  if glyph!=null and glyph.visible:
   glyph.size=Vector2(80,80)
   glyph.scale=Vector2.ONE*minf(picture_width,picture_height)/80
   glyph.position=(picture.size-glyph.size*glyph.scale)/2
 if header!=null: header.queue_redraw()
 queue_redraw()

func set_description_expanded(value: bool) -> void:
 if description_expanded==value or (value and not text_overflow): return
 description_expanded=value
 if value and is_instance_valid(tween): tween.kill()
 $CardText.scroll_vertical=0
 fit_text()
 description_changed.emit(value)

func fit_text() -> void:
 _fit_pending=false
 _layout_header()
 _layout_art()
 var area=get_node_or_null("CardText")
 if area==null: return
 var unit=maxf(0.5,size.y/252.0)
 var inset=PRINT_INSET*unit
 var text_y=art_bottom+2*unit
 var keywords=get_node_or_null("CardText/Content/CardKeywords")
 var requirements=get_node_or_null("CardText/Content/CardRequirements")
 var available_width=maxf(1,size.x-2*inset)
 for group in [keywords,requirements]:
  if group==null or not group.visible: continue
  for label in group.get_children():
   var font_size=roundi(11*text_scale())
   if label.get_theme_font_size("font_size")!=font_size: label.add_theme_font_size_override("font_size",font_size)
 area.position=Vector2(inset,text_y)
 area.size=Vector2(available_width,maxf(1,size.y-inset-text_y))
 # 溢出判据的唯一写入点：读刚算完的可见高度与正文的最小高度（容器尺寸当帧未必已排序）。
 var content=area.get_node_or_null("Content")
 text_overflow=content!=null and content.get_combined_minimum_size().y>area.size.y
 for label in area.get_node("Content").get_children():
  if not label is Label: continue
  var base_size=13 if label.name=="CardEffect" else (14 if label.name=="CardWarning" else 11)
  label.add_theme_font_size_override("font_size",roundi(base_size*text_scale()))

func _draw_header() -> void:
 var header=get_node("CardHeader")
 var unit=maxf(0.5,size.y/252.0)
 var rail=6*unit
 var width=size.x-2*rail
 if _description_rise>0:
  var paper=Color("3d595a") if effect_free else Color("554657")
  header.draw_rect(Rect2(rail,art_bottom,width,_description_rise),Color(paper,0.96))
 header.draw_rect(Rect2(rail,_strip_y,width,art_bottom-_strip_y),Color("354d4e") if effect_free else Color("4c3e50"))
 for y in [_strip_y,art_bottom]:
  header.draw_line(Vector2(rail,y),Vector2(size.x-rail,y),Color(RARITY_COLORS[rarity],0.55),maxf(1.0,unit*0.65),true)
 header.draw_texture_rect(EnergyMedallion,Rect2(Vector2(4,2)*unit,Vector2(28,28)*unit),false)
 for i in range(_gem_count()):
  _stamp(header,RARITY_ICONS.get(rarity,8),Vector2(size.x-(14+i*6)*unit,16*unit),16*unit)
 if not single_face:
  _stamp(header,6 if effect_free else 7,Vector2((PRINT_INSET+5)*unit,_type_y),19*unit)
 _stamp(header,_type_icon,Vector2(_type_text_left(unit)-8.25*unit,_type_y),16*unit)

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  drag_grabbed=event.pressed
  if event.pressed: drag_grab=event.position
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
  accept_event()
  flip_requested.emit()

func _get_drag_data(at_position: Vector2) -> Variant:
 if drag_payload.is_empty(): return null
 # Hover motion may continue between press and drag; retain the original card-local grip.
 var grip=drag_grab if drag_grabbed else at_position
 drag_grabbed=false
 var ghost=Control.new()
 ghost.name="CardDragPreview";ghost.z_index=240
 ghost.scale=get_global_transform().get_scale()
 ghost.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(ghost)
 # Godot owns the preview root position; keep the grab offset on the card child.
 if preview_factory.is_valid(): preview_factory.call(ghost,size.y).position=-grip
 remove_child(ghost)
 set_drag_preview(ghost)
 drag_began.emit(drag_payload)
 return drag_payload

func set_chained(active: bool) -> void:
 var overlay=get_node_or_null("CaptureChain")
 if active and overlay==null:
  overlay=TextureRect.new()
  overlay.name="CaptureChain"
  overlay.texture=preload("res://assets/ui/card-capture-chain.svg")
  overlay.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
  overlay.z_index=5
  add_child(overlay)
  overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 if overlay!=null: overlay.visible=active

func _ready() -> void:
 mouse_entered.connect(func(): _hover(true))
 mouse_exited.connect(func(): _hover(false))
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 var illustration=TextureRect.new()
 illustration.name="CardIllustration"
 illustration.texture=ILLUSTRATIONS.get(preload("res://data/card_rules.gd").SPECS.get(symbol,{}).get("art_type",symbol))
 illustration.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 illustration.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 illustration.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 illustration.clip_contents=true
 illustration.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(illustration)
 _apply_art_texture()
 if art_settings!=null:
  art_settings.art_changed.connect(_art_changed)
  _art_changed("cards",symbol)
 var header=Control.new();header.name="CardHeader";header.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(header);header.draw.connect(_draw_header)
 var category=_new_label("",13,Palette.TEXT)
 category.name="CardClassification"
 category.mouse_filter=Control.MOUSE_FILTER_IGNORE
 category.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 header.add_child(category)
 _layout_art()
 resized.connect(func():
  if has_node("CardMana"): set_mana(_mana_entries)
  fit_text())

func _art_changed(category: String, id: String) -> void:
 if category!="cards" or id!=symbol: return
 _apply_art_texture()

func _hover(raised: bool) -> void:
 if not lift_on_hover: return
 if raised and description_expanded: return
 if inspect_requested.is_valid(): inspect_requested.call(raised)
 if is_instance_valid(tween): tween.kill()
 tween=create_tween().set_parallel(true)
 tween.tween_property(self,"position",home+Vector2(0,-44 if raised else 0),0.13)
 tween.tween_property(self,"rotation",0.0 if raised else resting_angle,0.13)
 z_index=100 if raised else (20 if chosen else 0)

func _draw() -> void:
 var accent=RARITY_COLORS[rarity]
 if size.x<=0 or size.y<=0: return
 var scale_y=size.y/252.0
 var cut=Vector2(size.x*0.052,8.0*scale_y)
 var outline=PackedVector2Array([Vector2(cut.x,0),Vector2(size.x-cut.x,0),Vector2(size.x,cut.y),Vector2(size.x,size.y-cut.y),Vector2(size.x-cut.x,size.y),Vector2(cut.x,size.y),Vector2(0,size.y-cut.y),Vector2(0,cut.y)])
 var shadow=outline.duplicate()
 for i in range(shadow.size()): shadow[i]+=Vector2(1,2)*scale_y
 draw_colored_polygon(shadow,Color(0.015,0.023,0.03,0.58))
 var free=effect_free
 draw_colored_polygon(outline,Color("3d595a") if free else Color("554657"))
 var inner_width=size.x-12*scale_y
 draw_rect(Rect2(6*scale_y,3*scale_y,inner_width,29*scale_y),Color("303943"))
 var art_y=32*scale_y
 var picture_slot=Rect2(6*scale_y,art_y,inner_width,maxf(1,_strip_y+_description_rise-art_y))
 draw_texture_rect(preload("res://assets/ui/card-art-well.svg"),picture_slot,false,Color("c2dedb") if free else Color("d9ccd5"))
 # Stretch only the vertical rails to accommodate a second row or inventory layout.
 var dst=[0.0,art_y,_strip_y,art_bottom,size.y]
 var src=[0.0,62.0,321.0,368.0,512.0]
 for i in range(4):
  if dst[i+1]>dst[i]:
   draw_texture_rect_region(Metalwork,Rect2(0,dst[i],size.x,dst[i+1]-dst[i]),Rect2(0,src[i],320,src[i+1]-src[i]),accent)
 if chosen:
  var closed=outline.duplicate();closed.append(outline[0])
  draw_polyline(closed,Palette.CYAN,2,true)
