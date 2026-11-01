extends RefCounted

# Post-commit feedback consumes structured damage records. It never forecasts or
# modifies damage, intent, timing, resources or the command that produced it.
static func play_damage(ui, before: Dictionary) -> void:
 var index=0
 for i in range(before.logs.size(),ui.view.logs.size()):
  var record=ui.view.logs[i].data
  var hit=record.get("follow_through_hit",{})
  var equipment=not hit.is_empty()
  var anchor: Control
  var damage=0.0
  if equipment:
   if not ui.body_buttons.has(hit.slot): continue
   anchor=ui.body_buttons[hit.slot];damage=maxf(0,hit.before-hit.after)
  else:
   if not record.has("damage") or not record.has("enemy") or not ui.actor_targets.has(record.enemy): continue
   anchor=ui.actor_targets[record.enemy];damage=float(record.damage)
  var label=Label.new()
  label.name=("EquipmentHitFeedback_" if equipment else "DamageFeedback_")+str(index)
  label.text="−"+ui.game.number(damage)
  if equipment: label.text+=" · "+str(hit.hit)
  elif record.get("hits",1)>1: label.text+=" · %d/%d" % [record.hit,record.hits]
  label.set_meta("damage",damage);label.set_meta("target",hit.target if equipment else record.enemy)
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  label.add_theme_font_size_override("font_size",32)
  label.add_theme_color_override("font_color",Color("ffdec0"))
  label.add_theme_color_override("font_outline_color",Color("13202d"))
  label.add_theme_constant_override("outline_size",6)
  label.z_index=240
  ui.layout.add_child(label)
  label.position=ui.layout.get_global_transform().affine_inverse()*(anchor.get_global_transform()*(anchor.size*Vector2(0.4,0.3)))
  label.modulate.a=0
  var tween=label.create_tween()
  tween.tween_interval(minf(index*0.12,1.2) if not ui.display_settings.reduced_card_motion else 0)
  tween.tween_callback(func():label.modulate.a=1)
  tween.set_parallel(true)
  tween.tween_property(label,"position:y",label.position.y-45,0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  tween.tween_property(label,"modulate:a",0.0,0.35).set_delay(0.25)
  tween.chain().tween_callback(label.queue_free)
  index+=1

static func card_result(ui, before: Dictionary, payload: Dictionary, result: Dictionary) -> void:
 if not result.get("spell_failed",false): return
 var card=before.hand.filter(func(row):return row.uid==payload.get("uid",""))
 if card.is_empty(): return
 var title=ui._text("ui.card.use_failed","施法失败 · {card}",{"card":card[0].name})
 var panel=ui._panel(Rect2(610,224,330,44));panel.name="CardUseResult";panel.z_index=241
 panel.add_child(ui._label(title,18,ui.RED))
 ui._ignore_mouse(panel)
 var tween=panel.create_tween();tween.tween_interval(0.95)
 tween.tween_property(panel,"modulate:a",0.0,0.18);tween.tween_callback(panel.queue_free)

const ACTION_NAMES={"carried_apply":"施加备用装备","apply":"施加装备","turn_install":"持续施加","equipment_batch":"连续施加","split_burst":"全身施加","split":"分裂","special_install":"佩戴装备","pause":"停顿","install":"施加装备","assembly":"施加整套装备","tighten_budget":"加固","tighten":"加固","lock":"上锁","charge":"蓄力","bind_prepare":"准备捕缚","bind_apply":"施加捕缚","bind_gain":"推进捕缚","capture":"执行收押","six_prepare":"展开六缚阵","six_opening":"六重束装","six_tease":"戏弄封缚","six_tune":"调教升温","six_composite":"复合束装","six_finale":"六缚齐收","iron_stunned":"系统失灵","iron_bind_gain":"推进捕缚","iron_restraints":"皮革束缚","iron_composite":"复合束装","iron_recharge":"补充电量","iron_upgrade":"强化系统","art_intro":"隆重介绍","art_domain":"领域展开","art_sweep":"看我手速","art_tighten":"收紧！","art_tightest":"收到最紧！","art_refill":"补充绳索","art_weave":"编织绳网","art_enchant":"绳索附魔","art_admire":"欣赏作品并指指点点","art_seal":"我已探明施加","art_grief":"悲伤逆流成河","art_revive":"复活吧我的助理","art_prepare":"跃跃欲试","art_status":"硬上弓","art_patch":"查漏补缺","art_respect":"你必须尊重艺术","art_play":"调弄","art_rest":"手累了歇会","art_help":"我来帮忙","delayed":"行动被打断","leave":"离场","idle":"停顿","unseen":"视线受阻","guard_sequence":"连续施加"}

# Group committed events by exact enemy instance and operation; never parse names.
static func enemy_key(action: Dictionary) -> String:
 return "" if action.is_empty() else "%s:%s:%s" % [action.enemy_id,action.sequence,action.kind]

static func steps(before: Dictionary, after: Dictionary, sounds: Array=[]) -> Array:
 var result=[]
 var scoped={}
 for sound in sounds:
  if not sound is Dictionary: continue
  var key=enemy_key(sound)
  if not scoped.has(key): scoped[key]=[]
  if sound.cue not in scoped[key]: scoped[key].append(sound.cue)
 for i in range(before.logs.size(),after.logs.size()):
  var log=after.logs[i]
  var action=log.data.get("enemy_action",{})
  if action.is_empty(): continue
  var key=enemy_key(action)
  if result.is_empty() or result.back().key!=key:
   var cues=scoped.get(key,[]).duplicate()
   scoped.erase(key)
   # Hidden preparation retains its public identity while consuming its own receipt.
   if action.kind=="unseen":
    for kind in ["charge","bind_prepare"]:
     var hidden=action.duplicate();hidden.kind=kind
     var hidden_key=enemy_key(hidden)
     for cue in scoped.get(hidden_key,[]):
      if cue not in cues: cues.append(cue)
     scoped.erase(hidden_key)
   result.append({"key":key,"enemy_id":action.enemy_id,"actor":action.actor,"kind":action.kind,"title":ACTION_NAMES.get(action.kind,"行动"),"slots":[],"texts":[],"sound_feedback":cues})
  for slot in action.slots:
   if slot not in result.back().slots: result.back().slots.append(slot)
  result.back().texts.append(log.text)
 return result

static func equipment_changes(before: Dictionary, after: Dictionary) -> Array:
 var old_targets={};var new_targets={};var result=[]
 for body in before.bodies: old_targets.merge(body.targets,true)
 for body in after.bodies: new_targets.merge(body.targets,true)
 for id in old_targets:
  var old=old_targets[id]
  var current=new_targets.get(id,{})
  if current.is_empty(): result.append({"name":old.name,"position":old.position_text,"slot":old.slot,"text":"已解除"})
  elif current.durability<old.durability:
   result.append({"name":old.name,"position":old.position_text,"slot":old.slot,"text":"耐久度：%s → %s / %s%s" % [str(snappedf(old.durability,0.01)),str(snappedf(current.durability,0.01)),str(current.maximum),(" · 降至%d档" % current.tier) if current.tier<old.tier else ""]})
  elif old.locked and not current.locked: result.append({"name":old.name,"position":old.position_text,"slot":old.slot,"text":"锁已打开"})
 return result

static func movement_changes(before: Dictionary, after: Dictionary) -> Array:
 var changes=[]
 for i in range(before.logs.size(),after.logs.size()):
  for hit in after.logs[i].data.get("passive_slip",{}).get("results",[]):
   if hit.damage<=0: continue
   changes.append({"name":hit.name,"position":hit.position,"slot":hit.slot,"text":"已解除" if hit.after<=0 else "耐久度：%s → %s" % [str(snappedf(hit.before,0.01)),str(snappedf(hit.after,0.01))]})
 return changes

static func play_player(ui, before: Dictionary, payload: Dictionary) -> void:
 var movement=payload.get("kind","") in ["wall_move","travel_step"] or (payload.get("kind","")=="prison" and payload.get("action","")=="explore")
 if not movement and (payload.get("kind","") not in ["card","chain","manual","item_use","hook"] or payload.get("free",false)): return
 var changes=movement_changes(before,ui.view) if movement else equipment_changes(before,ui.view)
 var text=""
 if movement:
  for i in range(before.logs.size(),ui.view.logs.size()):
   var log=ui.view.logs[i]
   if log.data.has("exploration_move") or log.data.has("exploration_fall"): text+=log.text+"\n"
  if changes.is_empty() and text=="": return
 for change in changes:
  text+=change.name+" · "+change.position+"\n"+change.text+"\n"
  if ui.body_buttons.has(change.slot):
   var button=ui.body_buttons[change.slot]
   button.modulate=Color("a6fff2")
   button.create_tween().tween_property(button,"modulate",Color.WHITE,0.65)
 if text=="":
  # For a blocked/zero hit or a setup card, show its already committed result.
  var lines=[]
  for i in range(before.logs.size(),ui.view.logs.size()):
   var log=ui.view.logs[i]
   if log.data.has("player_action") and not log.data.has("enemy_action"): lines.append(log.text)
  text="\n".join(lines)
 if text=="": return
 var panel=ui._panel(Rect2(380,380,500,112));panel.name="PlayerActionFeedback";panel.z_index=245
 var label=ui._label(text.strip_edges(),16,ui.CYAN)
 label.max_lines_visible=4;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 panel.add_child(label);panel.tooltip_text=text
 ui._ignore_mouse(panel)
 var tween=panel.create_tween()
 tween.tween_interval(2.0)
 tween.tween_property(panel,"modulate:a",0.0,0.3)
 tween.tween_callback(panel.queue_free)

static func sync_feed(ui) -> void:
 if not is_instance_valid(ui.battle_feed) and not ui.show_home and ui.view.phase=="battle":
  ui.battle_feed=preload("res://ui/battle_feed.gd").new()
  ui.battle_feed.ui=ui;ui.add_child(ui.battle_feed)
 if is_instance_valid(ui.battle_feed): ui.battle_feed.sync(ui.view,ui.show_home or ui.show_route)

static func play(ui, before: Dictionary, payload: Dictionary={}, sounds: Array=[]) -> void:
 sync_feed(ui)
 if is_instance_valid(ui.battle_feed) and before.phase=="battle" and ui.view.phase in ui.battle_feed.ACTIVE_PHASES+ui.battle_feed.FINAL_PHASES: ui.battle_feed.enqueue(before,ui.view)
 play_damage(ui,before)
 play_player(ui,before,payload)
 var queue=steps(before,ui.view,sounds)
 if queue.is_empty(): return
 var presenter=preload("res://ui/enemy_feedback.gd").new()
 presenter.name="EnemyActionFeedback"
 presenter.ui=ui;presenter.queue=queue;presenter.duration=ui.feedback_duration
 ui.enemy_feedback=presenter
 ui.add_child(presenter)
 if is_instance_valid(ui.battle_feed): ui.battle_feed.entry.disabled=true
