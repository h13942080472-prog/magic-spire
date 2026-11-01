extends RefCounted

const DEBUFF_MESSAGE="敌人将要对你施加某种负面效果"
const ICON_TYPES={
 "puppet_awaken":"wait","puppet_mend":"wait","puppet_composite":"bind","puppet_special":"bind",
 "apply":"bind","carried_apply":"bind","turn_install":"debuff","debuff":"debuff","link":"bind","shoulder":"bind","install":"bind","special_install":"bind","assembly":"bind","split_burst":"bind",
 "tighten_budget":"tighten","tighten":"tighten","lock":"lock","charge":"wait","pause":"wait","idle":"wait","acted":"wait","spawned":"wait","bind_prepare":"wait","bind_apply":"debuff","bind_gain":"debuff",
 "iron_stunned":"wait","iron_bind_gain":"debuff","iron_restraints":"bind","iron_composite":"bind","iron_recharge":"wait","iron_upgrade":"wait",
 "art_intro":"wait","art_domain":"debuff","art_sweep":"bind","art_tighten":"tighten","art_tightest":"tighten","art_refill":"wait",
 "art_weave":"bind","art_enchant":"debuff","art_admire":"debuff","art_seal":"debuff","art_grief":"wait","art_revive":"wait",
 "art_prepare":"wait","art_status":"bind","art_patch":"bind","art_respect":"debuff","art_play":"debuff","art_rest":"wait","art_help":"wait",
 "capture":"capture","leave":"leave","hidden":"hidden","delayed":"delayed"}
const ICON_MESSAGES={
 "debuff":DEBUFF_MESSAGE,"bind":"敌人准备对你施加拘束","tighten":"敌人准备加固你的拘束具",
 "lock":"敌人准备给你的拘束具上锁","wait":"敌人正在准备行动","capture":"敌人准备将你收押",
 "leave":"敌人准备离场","hidden":"视线受阻，敌人意图隐藏","delayed":"敌人的行动已被打断"}
const WAIT_MESSAGES={"charge":"敌人正在蓄力","pause":"敌人正在发呆","idle":"敌人本次休息","acted":"敌人本回合已行动，下一回合重新显示意图","spawned":"敌人刚刚登场，从下一回合开始行动","bind_prepare":"敌人正在准备捕缚"}
const SPECIFIC_MESSAGES={"bind_apply":"敌人准备施加捕缚","bind_gain":"敌人将使捕缚进度增加10","puppet_awaken":"玩偶师准备赋予玩偶嘲讽与受击反应","puppet_mend":"玩偶师准备缝补玩偶，提高生命上限并回满，同时增加普通反击容量并补满","puppet_composite":"玩偶师准备为玩偶装上复合拘束具","puppet_special":"玩偶师准备为玩偶装上特殊装备"}

static func add(out: Array, term: String) -> void:
 var kind=ICON_TYPES[term]
 var detail=SPECIFIC_MESSAGES.get(term,WAIT_MESSAGES.get(term,ICON_MESSAGES[kind]))
 var matches=out.filter(func(icon):return icon.kind==kind)
 if matches.is_empty(): out.append({"kind":kind,"label":"","detail":detail,"caption":""})
 elif matches[0].detail!=detail: matches[0].detail=ICON_MESSAGES[kind]

static func operation(out: Array, plan: Dictionary) -> void:
 if plan.get("delayed",false):
  add(out,"delayed")
  return
 if plan.is_empty():
  add(out,"acted")
  return
 if plan.kind=="six_tune":
  add(out,"apply");add(out,"tighten");add(out,"debuff")
 elif plan.kind in ["six_opening","six_composite"]: add(out,"apply")
 elif plan.kind in ["six_tease","six_finale"]:
  add(out,"apply");add(out,"debuff")
 elif plan.kind=="six_prepare": add(out,"charge")
 elif plan.kind=="iron_restraints":
  add(out,"apply")
  if plan.get("reinforce",0)>0: add(out,"tighten")
 elif plan.kind=="iron_composite":
  add(out,"apply")
  if plan.get("locks",0)>0: add(out,"lock")
 elif plan.kind in ["guard_sequence","equipment_batch"]:
  if plan.kind=="equipment_batch": add(out,"tighten" if plan.tighten else "apply")
  else:
   for child in plan.operations: operation(out,child)
 else: add(out,plan.kind)
 if plan.get("tighten_after",false): add(out,"tighten")
 if plan.get("tighten_missing",false):
  add(out,"tighten")
  for icon in out:
   if icon.kind=="tighten": icon.detail="没有合法新增位置时，剩余施加次数改为加固拘束具"
 if plan.get("pressure",0)>0 or plan.has("pressure_effect"): add(out,"debuff")

static func build(g, enemy: Dictionary, visible: bool) -> Array:
 var out: Array=[]
 if enemy.gone: return out
 if not visible:
  add(out,"hidden")
  return out
 operation(out,enemy.intent)
 if not enemy.intent.get("delayed",false) and (enemy.get("spawned_round",-1)==g.state.round or enemy.get("reinforcement_round",-1)==g.state.round): add(out,"spawned")
 return out
