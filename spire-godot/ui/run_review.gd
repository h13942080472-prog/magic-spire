extends RefCounted

# docs/spec/run-review.md：本局回顾面板的唯一组装入口（与 ui/event_screen.gd::drawer 同形）。
# Read-only display: it reads ui.view and ui.seed_report_text() and its only write is the copy
# button calling ui.copy_seed(). Nothing here submits a candidate, dispatches, or writes to disk.
const TITLE_KEY="ui.run_review.title"
const TITLE_FALLBACK="本局回顾"
const RouteMap=preload("res://ui/route_map.gd")
const DeckBrowser=preload("res://ui/deck_browser.gd")

static func title_text(ui) -> String:
 return ui._text(TITLE_KEY,TITLE_FALLBACK)

# The single entry-visibility rule: practice runs and the prison cell project an empty route and
# therefore must not create the control at all (a hidden shell is not an absent entry).
static func can_open(route: Array) -> bool:
 return not route.is_empty()

static func drawer(ui) -> void:
 var content=ui._drawer_shell(title_text(ui),Rect2(60,78,1480,780),ui.GOLD)
 var column=ui._scroll(content)
 _identity_block(ui,column)
 _route_block(ui,column)
 _deck_block(ui,column)

# Identity block: the shared run report text plus the second view of the one copy entry.
static func _identity_block(ui, column: Node) -> void:
 column.add_child(ui._label(ui._text("ui.run_review.identity","本局标识"),20,ui.GOLD))
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);column.add_child(row)
 # Text selection needs RichTextLabel: Label has no selection API. Same four-part run report text,
 # no bbcode, content-fitted height, and the pointer stays on the control so the text can be read.
 var identity=RichTextLabel.new()
 identity.name="RunReviewIdentity"
 identity.bbcode_enabled=false
 identity.fit_content=true
 identity.scroll_active=false
 identity.selection_enabled=true
 identity.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 identity.mouse_filter=Control.MOUSE_FILTER_STOP
 identity.add_theme_font_size_override("normal_font_size",15)
 identity.add_theme_color_override("default_color",ui.TEXT)
 identity.add_theme_color_override("font_selected_color",ui.TEXT)
 identity.text=ui.seed_report_text()
 identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 row.add_child(identity)
 var copy=ui._button(ui._run_review_copy_text(),ui.copy_seed,ui.CYAN)
 copy.name="RunReviewCopy"
 row.add_child(copy)
 ui.run_review_copy=copy

# Route block: progress line and map both derive from the same projected route array.
static func _route_block(ui, column: Node) -> void:
 column.add_child(ui._label(ui._text("ui.run_review.route","节点概况"),20,ui.GOLD))
 var route: Array=ui.view.route
 var progress=ui._label(_progress_text(ui,route),16,ui.CYAN)
 progress.name="RunReviewProgress"
 column.add_child(progress)
 if route.is_empty():
  # Extreme case (phase replaced while the drawer is open): the map slot carries the explicit
  # missing-data caption instead of a blank area or an empty map.
  var missing=ui._label(ui._text("ui.run_review.no_route","没有可回顾的路线数据。"),16,ui.MUTED)
  missing.name="RunReviewMap"
  column.add_child(missing)
  return
 var graph=RouteMap.new()
 graph.name="RunReviewMap"
 graph.rooms=route
 graph.compact=true
 graph.read_only=true
 graph.custom_minimum_size=Vector2(710,420)
 column.add_child(graph)

# floor: highest floor among completed/current rooms plus one (the tower bottom at floor -1 reads
# as 0, matching core/game_view.gd::run_header); nodes: completed rooms only.
static func _progress_text(ui, route: Array) -> String:
 var floor=0
 var nodes=0
 for room in route:
  if room.status=="completed": nodes+=1
  if room.status=="completed" or room.status=="current": floor=maxi(floor,int(room.floor)+1)
 return ui._text("ui.run_review.progress","已到达第 {floor} 层 · 已走过 {nodes} 个节点",{"floor":floor,"nodes":nodes})

# Deck block: the shared browser in its full read-only entry, never a second card list.
static func _deck_block(ui, column: Node) -> void:
 column.add_child(ui._label(ui._text("ui.run_review.deck","卡组"),20,ui.GOLD))
 var browser=DeckBrowser.new()
 browser.custom_minimum_size.y=340
 column.add_child(browser)
 browser.setup(ui,ui.view.deck_cards,false,ui._text("ui.run_review.deck_empty","卡组为空。"))
 browser.name="RunReviewDeck"
