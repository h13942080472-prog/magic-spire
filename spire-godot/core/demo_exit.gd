extends RefCounted

const HEALTH=[1.0,1.5,2.0]
const PRESSURE_RELIEF=40.0

static func health_multiplier(state: Dictionary) -> float:
 return HEALTH[state.demo_cycle]

static func at_exit(g) -> bool:
 return not g.state.practice and g.state.phase=="cleared" and g.room_data(g.state.room).get("kind","")=="exit"

# 试玩出口的显示事实（批 R5：行生产转发改显示事实构建，docs/spec/candidate-removal.md §2.1 T5／T8）。
static func facts(g) -> Array:
 var out=[]
 if not at_exit(g) or g.state.demo_finished: return out
 out.append(g._fact({"kind":"demo_end"},"结束并返回菜单",{"kind":"demo_exit.end","args":{},"fallback":end_detail(g,{})},0,0.0,"","","demo_exit"))
 if g.state.demo_cycle<2:
  var continue_args={"next_cycle":g.state.demo_cycle+1}
  out.append(g._fact({"kind":"demo_continue"},"继续游玩",{"kind":"demo_exit.continue","args":continue_args,"fallback":continue_detail(g,continue_args)},0,0.0,"","","demo_exit"))
 return out

# R1（docs/ondemand-copy.md §11.5）：文案类别登记在路由，正文仍留本模块。
static func end_detail(_g, _args: Dictionary) -> String:
 return "结束本次游玩。"

static func continue_detail(g, args: Dictionary) -> String:
 return "保留卡组、遗物、成长与监狱警戒度，开启全新塔路。怪物基础生命×%s；解除可解除的装备并补满魔力，快感降低%s（最低0），姿势变为站立。" % [g.number(HEALTH[int(args.get("next_cycle",1))]),g.number(PRESSURE_RELIEF)]

static func continue_run(g) -> void:
 for target in g.action_targets():
  if g.cursed_eyes(target) or g.cursed_plate(target) or g.Equipment.lock_only(target): continue
  target.locked=false
  g._apply_manual_release(target,0.0)
 g._cleanup()
 g.CaptureBind.clear_bind(g)
 g.Cards.end_powers(g);g.Cards.purge_temporary(g)
 g.RelicEffects.end_combat(g)
 g.state.demo_cycle+=1
 g._restart_tower(true)
 g.state.encounter=0;g.state.reward_count=0;g.state.reward_claimed={};g.state.battle_relic_drop=""
 g.state.boss_relic_options=[]
 g.state.mana=g.state.mana_max
 g.state.pending_retain=false;g.state.retain_left=0;g.state.retain_draw_after=0;g.Cards.cancel_chain(g)
 g._clear_charge();g.state.temporary_mana=0.0;g.state.next_energy=0;g.state.sure_cast=false;g.state.weakness_turns=0
 var pressure_before=g.state.pressure
 var posture_before=g.state.posture
 g.Pressure.lose(g,PRESSURE_RELIEF)
 g.state.posture="stand"
 g._reset_piles()
 g._emit("event","新的塔路已展开。第%s阶段：怪物基础生命×%s，可解除的装备已解除，魔力已补满；快感降低%s，姿势变为站立。" % [["一","二","三"][g.state.demo_cycle],g.number(health_multiplier(g.state)),g.number(pressure_before-g.state.pressure)],{"demo_cycle":g.state.demo_cycle,"pressure_before":pressure_before,"pressure_after":g.state.pressure,"posture_before":posture_before,"posture_after":"stand"})

static func validate(state: Dictionary) -> String:
 if not state.get("demo_cycle") is int or state.demo_cycle<0 or state.demo_cycle>2 or not state.get("demo_finished") is bool: return "游玩阶段记录不正确。"
 if state.demo_finished and (state.get("phase")!="cleared" or state.get("practice")!=false or state.get("room")!="exit"): return "已结束的游戏必须位于出口。"
 if state.get("practice",false) and state.demo_cycle!=0: return "练习不能进入后续阶段。"
 return ""
