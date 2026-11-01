extends HBoxContainer

const Book=preload("res://data/tutorial.gd")
var host
var category=""
var query=""
var rows: Array=[]
var results: VBoxContainer
var scroll: ScrollContainer
var caption: Label
var categories: Dictionary={}

func setup(ui, initial: String="") -> void:
 host=ui;category="basics" if initial=="" else initial;rows=Book.entries(ui.game)
 name="TutorialBook";size_flags_vertical=Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",22)
 var left=VBoxContainer.new();left.custom_minimum_size.x=170;add_child(left)
 var labels={"basics":Book.CATEGORIES.basics,"":"全部条目"};labels.merge(Book.CATEGORIES)
 for id in labels:
  var key=str(id)
  var button=host._button(labels[key],func():category=key;refresh(),host.GOLD)
  button.name="TutorialCategory_"+("all" if key=="" else key)
  button.add_theme_font_size_override("font_size",16)
  button.custom_minimum_size.y=37;categories[key]=button;left.add_child(button)
 var right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;add_child(right)
 right.add_theme_constant_override("separation",12)
 var search=LineEdit.new();search.name="TutorialSearch"
 search.placeholder_text="搜索名称或规则"
 search.clear_button_enabled=true;search.custom_minimum_size.y=42
 search.add_theme_font_size_override("font_size",18);right.add_child(search)
 # Update only results: native typing focus and caret survive every keystroke.
 search.text_changed.connect(func(value):query=value;refresh())
 caption=host._label("",14,host.MUTED);caption.name="TutorialResultCount";right.add_child(caption)
 results=host._scroll(right);results.name="TutorialResults";scroll=results.get_parent()
 refresh()

func refresh() -> void:
 for child in results.get_children(): results.remove_child(child);child.queue_free()
 var count=0
 for row in rows:
  if category!="" and row.category!=category: continue
  if query.strip_edges()!="" and not (row.title+" "+row.text).containsn(query.strip_edges()): continue
  count+=1
  var title=host._label(row.title,20,host.GOLD);results.add_child(title)
  if category=="": results.add_child(host._label(Book.CATEGORIES[row.category],12,host.CYAN))
  var body=host._label(row.text,16,host.TEXT)
  # This introduction explicitly teaches both platforms; preserve their names.
  if row.id in ["basics0","basics1"]: body.text=row.text
  results.add_child(body)
  results.add_child(HSeparator.new())
 caption.text=("全部分类" if category=="" else Book.CATEGORIES[category])+" · %d条" % count
 if count==0: results.add_child(host._label("匹配结果：0项。请尝试其他关键词。",17,host.MUTED))
 for id in categories: categories[id].modulate=host.CYAN if id==category else Color.WHITE
 scroll.scroll_vertical=0
