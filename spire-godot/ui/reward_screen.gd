extends RefCounted
const Glyph=preload("res://ui/shop_glyph.gd")

static func build(ui) -> void:
 if ui.view.reward_panel.get("layout","")=="departure":
  preload("res://ui/departure_screen.gd").build(ui)
  return
 if ui.view.reward_panel.get("layout","")=="relic_bundle":
  preload("res://ui/relic_bundle_screen.gd").build(ui)
  return
 var root=Control.new();root.name="BattleRewards";root.z_index=80;root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui._place(root,Rect2(0,0,1600,900))
 var shade=ColorRect.new();shade.color=Color(0.018,0.026,0.04,0.90)
 ui._place(shade,Rect2(0,78,1600,822),root)
 var crest=TextureRect.new();crest.texture=preload("res://assets/ui/crest.svg");crest.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 crest.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui._place(crest,Rect2(766,101,68,68),root)
 var title=ui._label("选择一件遗物" if ui.show_reward_relics else ("选择一张牌" if ui.show_reward_cards else ui.view.reward_title),36,ui.GOLD)
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ui._place(title,Rect2(410,173,780,56),root)
 var line=ColorRect.new();line.color=Color(ui.GOLD,0.45)
 ui._place(line,Rect2(610,242,380,1),root)
 if ui.show_reward_cards:
  cards(ui,root)
  return
 if ui.show_reward_relics:
  relics(ui,root)
  return
 var rows=ui.view.battle_rewards
 for i in range(rows.size()): row(ui,root,rows[i],Rect2(472,284+i*110,656,94))
 var pending=rows.any(func(entry):return not entry.claimed)
 var destination=ui._label(ui.view.reward_destination,15,ui.MUTED)
 destination.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ui._place(destination,Rect2(470,637,660,32),root)
 var footer=ui.view.reward_panel
 var exit=ui.actions.by_id[footer.continue_id]
 var extra_y=682
 for id in footer.extra_ids:
  var choice=ui.actions.by_id[id]
  var extra=ui._button(choice.label,func():ui._submit(choice),ui.CYAN);extra.disabled=not choice.valid
  extra.name="RewardExtra_"+choice.payload.kind;ui._place(extra,Rect2(540,extra_y,520,50),root);ui.candidate_buttons[id]=extra
  extra_y+=62
 var next=ui._button(footer.continue_label,func():ui._submit(exit),ui.GOLD)
 next.name="RewardContinue";ui._place(next,Rect2(658,693 if footer.extra_ids.is_empty() else extra_y,284,54),root)
 ui.candidate_buttons[exit.id]=next
 if pending and footer.extra_ids.is_empty() and not rows.any(func(entry):return entry.get("hide_skip",false)):
  var warning=ui._label("未领取的奖励将被放弃",13,ui.MUTED)
  warning.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  ui._place(warning,Rect2(590,758,420,25),root)

static func row(ui, root: Control, entry: Dictionary, rect: Rect2) -> void:
 var choices=entry.action_ids.map(func(id):return ui.actions.by_id[id])
 var click=func():
  if entry.category=="card" and not entry.get("direct",false):
   ui.reward_card_row=entry.id;ui.show_reward_cards=true;ui.render(ui.view)
  elif entry.has("choices"):
   ui.show_reward_relics=true;ui.render(ui.view)
  elif not choices.is_empty(): ui._submit(choices[0])
 var accent=ui.CYAN if entry.category=="item" else ui.GOLD
 var button=preload("res://ui/elements/reward_row.tscn").instantiate()
 ui._style_button(button,"",click,accent)
 button.name="Reward_"+entry.category+("_"+entry.id if entry.id!="" else "")
 button.disabled=entry.claimed or not entry.available
 var normal=ui.Palette.surface(Color("152530"),accent.darkened(0.38),10);normal.border_width_left=3
 var pressed=ui.Palette.surface(Color("1d3340"),accent,10);pressed.border_width_left=3
 var dim=ui.Palette.surface(Color("0e1922"),ui.Palette.MUTED.darkened(0.6),10);dim.border_width_left=3
 button.add_theme_stylebox_override("normal",normal)
 button.add_theme_stylebox_override("hover",ui.Palette.button_style("hover",accent))
 button.add_theme_stylebox_override("pressed",pressed)
 button.add_theme_stylebox_override("focus",ui.Palette.button_style("hover",accent))
 button.add_theme_stylebox_override("disabled",dim)
 root.add_child(button);button.position=rect.position;button.size=rect.size
 if (entry.category!="card" or entry.get("direct",false)) and not entry.has("choices") and not choices.is_empty(): ui.candidate_buttons[choices[0].id]=button
 var glyph: Control
 if entry.category=="relic":
  glyph=preload("res://ui/relic_icon.gd").new();glyph.relic={"id":entry.symbol}
 else:
  glyph=Glyph.new();glyph.kind="tool" if entry.category=="item" else entry.category;glyph.symbol=entry.symbol
 glyph.modulate=Color(1,1,1,0.4) if entry.claimed else Color.WHITE
 ui._place(glyph,Rect2(12,8,78,78),button);button.move_child(glyph,0)
 var name=ui._style_label(button.title_label(),entry.name,23,ui.MUTED if entry.claimed else ui.TEXT)
 name.name="BattleItemDrop" if entry.category=="item" else ("BattleRelicDrop" if entry.category=="relic" else "RewardCardTitle")
 name.position=Vector2(106,17);name.size=Vector2(389,34)
 var subtitle=ui._style_label(button.subtitle_label(),entry.reason if entry.reason!="" else entry.subtitle,14,ui.RED if entry.reason!="" else ui.MUTED)
 subtitle.position=Vector2(106,55);subtitle.size=Vector2(389,28)
 var action_text="已跳过" if entry.skipped else ("✓ 已领取" if entry.claimed else ("无法领取" if not entry.available else entry.get("action_label",("选择  ›" if (entry.category=="card" and not entry.get("direct",false)) or entry.has("choices") else "领取  ›"))))
 var action=ui._style_label(button.action_label(),action_text,18,ui.MUTED if entry.claimed or not entry.available else accent)
 action.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 action.position=Vector2(510,31);action.size=Vector2(123,30)
 for child in button.get_children():
  if child is Control: ui._ignore_mouse(child)
 button.mouse_entered.connect(func():ui._show_term(button,{"label":entry.name,"detail":entry.detail}))
 button.mouse_exited.connect(ui._hide_term)
 if entry.skip_id!="" and entry.category in ["card","relic"] and not entry.claimed and not entry.get("hide_skip",false):
  skip_button(ui,root,entry,Rect2(rect.end.x+14,rect.position.y+22,86,50))

static func cards(ui, root: Control) -> void:
 var entries=ui.view.battle_rewards.filter(func(row):return row.category=="card" and row.id==ui.reward_card_row and not row.claimed)
 if entries.is_empty(): return
 var entry=entries[0]
 var choices=entry.action_ids.map(func(id):return ui.actions.by_id[id])
 var width=250.0;var gap=34.0
 var left=(1600-(choices.size()*width+(choices.size()-1)*gap))/2
 for i in range(choices.size()):
  var choice=choices[i]
  var card=preload("res://data/encyclopedia.gd").card(choice.payload.get("type",entry.symbol))
  card.uid="reward_"+card.type
  var button=ui._card(card,Rect2(left+i*(width+gap),295,width,324),func():ui._submit(choice),0,root,false,true)
  button.name="RewardChoice_"+card.type
  button.disabled=not choice.valid
  ui.candidate_buttons[choice.id]=button
 var back=ui._button("‹  返回奖励",func():ui.show_reward_cards=false;ui.render(ui.view),ui.GOLD)
 back.name="RewardBack";ui._place(back,Rect2(568,699,216,50),root)
 skip_button(ui,root,entry,Rect2(816,699,216,50))

static func relics(ui, root: Control) -> void:
 var entries=ui.view.battle_rewards.filter(func(row):return row.has("choices"))
 if entries.is_empty(): return
 var options=entries[0].choices
 var width=280.0;var gap=28.0
 var left=(1600-options.size()*width-(options.size()-1)*gap)/2
 for i in range(options.size()):
  var entry=options[i]
  var choice=entries[0].action_ids.map(func(id):return ui.actions.by_id[id]).filter(func(c):return c.payload.type==entry.id)[0]
  var button=ui._button("",func():ui._submit(choice),ui.GOLD)
  button.name="BossRelicChoice_"+entry.id;button.disabled=not choice.valid
  ui._place(button,Rect2(left+i*(width+gap),282,width,360),root)
  var icon=preload("res://ui/relic_icon.gd").new();icon.relic=entry
  ui._place(icon,Rect2(92,28,96,96),button)
  var title=ui._label(entry.name,24,ui.GOLD);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  ui._place(title,Rect2(12,142,256,42),button)
  var detail=ui._label(entry.detail if choice.valid else choice.reason,18,ui.TEXT if choice.valid else ui.RED)
  detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  ui._place(detail,Rect2(24,200,232,126),button)
  for child in button.get_children(): ui._ignore_mouse(child)
  ui.candidate_buttons[choice.id]=button
 var back=ui._button("‹  返回奖励",func():ui.show_reward_relics=false;ui.render(ui.view),ui.GOLD)
 back.name="RewardBack";ui._place(back,Rect2(568,699,216,50),root)
 skip_button(ui,root,entries[0],Rect2(816,699,216,50))

static func skip_button(ui, root: Control, entry: Dictionary, rect: Rect2) -> void:
 if entry.skip_id=="": return
 var choice=ui.actions.by_id[entry.skip_id]
 var button=ui._button("跳过",func():ui._submit(choice),ui.MUTED)
 button.name="RewardSkip_"+entry.category+("_"+entry.id if entry.id!="" else "");button.disabled=not choice.valid
 ui._place(button,rect,root);ui.candidate_buttons[choice.id]=button
