extends RefCounted

static func region_summary(ui, parent: Node, body: Dictionary) -> void:
 var regions=ui.view.body_regions.filter(func(region):return region.id==body.id or region.members.any(func(member):return member.id==body.id))
 if regions.is_empty() or regions[0].severity.is_empty(): return
 var severity=regions[0].severity
 var row=HBoxContainer.new();row.name="RegionSeverity";row.add_theme_constant_override("separation",12);parent.add_child(row)
 var caption=ui._label(severity.label,14,ui.MUTED);caption.autowrap_mode=TextServer.AUTOWRAP_OFF;row.add_child(caption)
 var color=ui.RED if severity.value>=3 else ui.GOLD
 var meter=ui._bar(severity.value,severity.maximum,color)
 meter.size_flags_horizontal=Control.SIZE_EXPAND_FILL;meter.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 meter.custom_minimum_size=Vector2(70,5);row.add_child(meter)
 var value=ui._label("%s / %s" % [ui.game.number(severity.value),ui.game.number(severity.maximum)],17,color)
 value.autowrap_mode=TextServer.AUTOWRAP_OFF;row.add_child(value)

static func equipment_header(ui, parent: Node, e: Dictionary, location: String, accent: Color) -> void:
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);parent.add_child(row)
 if e.image!="" and ResourceLoader.exists(e.image):
  var icon=TextureRect.new();icon.texture=load(e.image);icon.custom_minimum_size=Vector2(44,52)
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(icon)
 var text=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",3);row.add_child(text)
 var heading=HBoxContainer.new();text.add_child(heading)
 var title=ui._label(e.name,17,ui.TEXT);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
 var badge=ui._label(e.get("layer_label",""),12,ui.MUTED if not e.get("covers",[]).is_empty() else ui.CYAN)
 badge.autowrap_mode=TextServer.AUTOWRAP_OFF;heading.add_child(badge)
 text.add_child(ui._label(location+" · "+e.material_name,12,ui.MUTED))
 var state=HBoxContainer.new();text.add_child(state)
 var label=ui._label("无耐久" if e.get("lock_only",false) else "耐久 %s / %s · 紧度%d档" % [ui.game.number(e.durability),ui.game.number(e.maximum),e.tier],13,accent)
 label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;state.add_child(label)
 ui._equipment_lock(state,e.locked,e.id,e.lockable)
 if not e.get("lock_only",false):
  var bar=ui._bar(e.durability,e.maximum,accent);bar.custom_minimum_size.y=5;text.add_child(bar)
 if not e.get("covers",[]).is_empty(): parent.add_child(ui._label("外层覆盖："+"、".join(e.covers),12,ui.MUTED))
 if e.card_status!="": parent.add_child(ui._label(e.card_status,12,ui.CYAN))

static func preview(ui, parent: Node, candidate: Dictionary) -> void:
 var p=candidate.release_preview
 if p.headline=="": return
 var panel=PanelContainer.new();panel.name="ReleasePreview"
 panel.add_theme_stylebox_override("panel",ui._style(Color("102c32"),ui.CYAN.darkened(0.65),8));parent.add_child(panel)
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",5);panel.add_child(box)
 if p.method!="": box.add_child(ui._label(p.method,12,ui.CYAN))
 var row=HBoxContainer.new();box.add_child(row)
 var main=ui._label(p.headline,20,ui.TEXT);main.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(main)
 var change=ui._label(p.change,20,ui.CYAN);change.autowrap_mode=TextServer.AUTOWRAP_OFF;row.add_child(change)
 if p.note!="": box.add_child(ui._label(p.note,13,ui.CYAN))
 if not p.modifiers.is_empty(): box.add_child(ui._label(" · ".join(p.modifiers),12,ui.RED))
 # Original effect text remains reachable, including secondary effects and chains.
 var detail=ui._label(ui.detail_of(candidate),12,ui.MUTED);detail.visible=false
 var toggle=ui._button("效果详情 ＋",func():detail.visible=not detail.visible,ui.MUTED)
 toggle.name="ReleaseEffectDetails";toggle.custom_minimum_size.y=22;toggle.add_theme_font_size_override("font_size",11)
 parent.add_child(toggle);parent.add_child(detail)
