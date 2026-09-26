extends VBoxContainer

const Catalog=preload("res://data/encyclopedia.gd")
const NameOrder=preload("res://ui/chinese_collation.gd")
var host
var cards: Array=[]
var query=""
var ordering=0
var cost_filter=0
var type_filter=""
var rarity_filter=""
var grid: GridContainer
var counter: Label
var empty: Label
var scroll: ScrollContainer
var selection_choices: Dictionary={}

func setup(ui, physical_cards: Array, powers_only: bool=false, empty_message: String="卡组为空。", choices: Dictionary={}) -> void:
 host=ui;name="DeckBrowser";selection_choices=choices
 size_flags_vertical=Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",16)
 # 牌堆浏览属全量入口（docs/ondemand-copy.md §1.3）：条目按需现算，字段与旧投影逐项相同。
 var live=ui.game.live_card_text_set(physical_cards)
 for physical in physical_cards:
  var card=Catalog.card(physical.type)
  card.merge(live.texts.get(physical.type,{}),true)
  card.merge(live.instances.get(physical.uid,{}),true)
  card.physical_uid=physical.uid
  card.source_order=cards.size()
  card.name_key=NameOrder.key(card.name)
  if powers_only: host.card_faces["display_deck_"+physical.uid+"_"+physical.type]=physical.power_face=="free"
  cards.append(card)
 var toolbar=HBoxContainer.new();toolbar.add_theme_constant_override("separation",16);add_child(toolbar)
 counter=host._label("",18,host.GOLD);counter.name="DeckCount";counter.size_flags_horizontal=Control.SIZE_EXPAND_FILL;toolbar.add_child(counter)
 var search=LineEdit.new();search.name="DeckSearch";search.placeholder_text="搜索卡牌名称";search.clear_button_enabled=true;search.custom_minimum_size.x=250;toolbar.add_child(search)
 search.text_changed.connect(func(value):query=value;refresh())
 var costs=OptionButton.new();costs.name="DeckCostFilter";costs.custom_minimum_size.x=140;toolbar.add_child(costs)
 for label in ["全部费用","0能量","1能量","2能量","3能量及以上","不可打出"]: costs.add_item(label)
 costs.item_selected.connect(func(index):cost_filter=index;refresh())
 for filter_kind in ["type","rarity"]:
  var selector=OptionButton.new();selector.name="DeckTypeFilter" if filter_kind=="type" else "DeckRarityFilter";toolbar.add_child(selector)
  selector.add_item("全部类型" if filter_kind=="type" else "全部稀有度");selector.set_item_metadata(0,"")
  var options=Catalog.Cards.TYPES if filter_kind=="type" else Catalog.Cards.RARITIES
  for id in options:
   selector.add_item(options[id]);selector.set_item_metadata(selector.item_count-1,id)
  selector.item_selected.connect(func(index):
   if filter_kind=="type": type_filter=str(selector.get_item_metadata(index))
   else: rarity_filter=str(selector.get_item_metadata(index))
   refresh())
 var sort=OptionButton.new();sort.name="DeckSort";sort.custom_minimum_size.x=150;toolbar.add_child(sort)
 for label in ["按费用排序","按名称排序","按获得顺序"]: sort.add_item(label)
 sort.item_selected.connect(func(index):ordering=index;refresh())
 scroll=ScrollContainer.new();scroll.name="DeckScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;add_child(scroll)
 var margin=MarginContainer.new();margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,14)
 scroll.add_child(margin)
 var column=VBoxContainer.new();margin.add_child(column)
 empty=host._label("没有符合筛选条件的卡牌。",22,host.MUTED);empty.name="DeckEmpty";empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(empty)
 if cards.is_empty(): empty.text=empty_message
 var center=CenterContainer.new();center.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_child(center)
 grid=GridContainer.new();grid.name="DeckGrid";grid.columns=6;grid.add_theme_constant_override("h_separation",24);grid.add_theme_constant_override("v_separation",26);center.add_child(grid)
 scroll.get_v_scroll_bar().value_changed.connect(func(_value):host._hide_term())
 refresh()

func numeric_cost(card: Dictionary) -> int:
 var side="free" if host.card_faces.get("display_deck_"+card.physical_uid+"_"+card.type,false) else "bound"
 var cost=card.get("face_costs",{}).get(side,card.cost)
 return 999 if cost=="—" else int(cost)

func comes_before(a: Dictionary, b: Dictionary) -> bool:
 if ordering==0 and numeric_cost(a)!=numeric_cost(b): return numeric_cost(a)<numeric_cost(b)
 if a.name_key!=b.name_key: return a.name_key.naturalnocasecmp_to(b.name_key)<0
 return a.source_order<b.source_order

func refresh() -> void:
 host._hide_term()
 var existing={}
 for child in grid.get_children(): existing[child.get_meta("physical_uid")]=child
 var shown=cards.filter(func(card):
  if query.strip_edges()!="" and not card.name.containsn(query.strip_edges()): return false
  if type_filter!="" and type_filter not in card.type_tags: return false
  if rarity_filter!="" and card.rarity!=rarity_filter: return false
  var cost=numeric_cost(card)
  return cost_filter==0 or (cost_filter<=3 and cost==cost_filter-1) or (cost_filter==4 and cost>=3 and cost<999) or (cost_filter==5 and cost==999))
 if ordering!=2:
  shown.sort_custom(comes_before)
 counter.text="%d / %d 张卡牌" % [shown.size(),cards.size()]
 empty.visible=shown.is_empty()
 for card in shown:
  var button=existing.get(card.physical_uid)
  if button==null:
   var choice=selection_choices.get(card.physical_uid,{})
   var select=Callable() if choice.is_empty() else func():host.command_router.emit(String(choice.payload.get("kind","")),choice)
   button=host._display_card(card.type,grid,select,"deck_"+card.physical_uid,Vector2(210,278),card.physical_uid,true,card)
   if not choice.is_empty():
    button.disabled=not choice.valid
    host.candidate_buttons[choice.key]=button
   button.set_meta("physical_uid",card.physical_uid)
   button.flip_requested.connect(func():refresh.call_deferred())
   button.pivot_offset=button.size/2
   button.mouse_entered.connect(func():
    button.scale=Vector2.ONE*1.045;button.z_index=4)
   button.mouse_exited.connect(func():button.scale=Vector2.ONE;button.z_index=0)
  existing.erase(card.physical_uid)
  grid.move_child(button,shown.find(card))
  button.set_meta("printed_cost",numeric_cost(card))
 for child in existing.values():
  var choice=selection_choices.get(child.get_meta("physical_uid"),{})
  if not choice.is_empty(): host.candidate_buttons.erase(choice.key)
  grid.remove_child(child);child.queue_free()
 scroll.scroll_vertical=0
