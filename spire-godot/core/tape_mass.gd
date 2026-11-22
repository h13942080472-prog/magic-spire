extends RefCounted

const TYPE="tape_mass"
const FIT="tape_triple"
const BOOST="tape_charge"
const Actions=[FIT,BOOST]
const BaseBlock=3

static func initialize(g, enemy: Dictionary) -> void:
 enemy.tape_opens_fit=g._random_index("enemy",2)==1
 enemy.flex_next=BaseBlock
 enemy.mech_armor=0.0

# Stage advances only on executed intents. An optional unboosted opener precedes the cycle.
static func cycle_position(enemy: Dictionary) -> int:
 return enemy.stage-1-int(enemy.tape_opens_fit)

static func boost_left(enemy: Dictionary) -> int:
 var position=cycle_position(enemy)
 if position<0 or position%3==0: return 0
 return 3-position%3

static func plan(enemy: Dictionary) -> Dictionary:
 if cycle_position(enemy)>=0 and cycle_position(enemy)%3==0:
  return {"kind":BOOST,"text":"蓄胶 · 施加2层虚弱，强化下两次三连贴","delayed":false}
 var text="三连贴 · 施加3件强化胶带" if boost_left(enemy)>0 else "三连贴 · 施加3件胶带"
 return {"kind":FIT,"text":text,"delayed":false}

static func application(g, enhanced: bool) -> Dictionary:
 var spec=g.EnemyPlans.application(g.Enemies.TYPES[TYPE].install_pool,2,2,3,false,5 if enhanced else 4)
 spec.allow_links=false
 return spec

static func execute(g, enemy: Dictionary, move: String) -> void:
 if move==BOOST: g.Cards.add_weakness(g,enemy.name)
 else: g._enemy_operation(enemy,application(g,boost_left(enemy)>0))

static func begin_enemy_turn(enemy: Dictionary) -> void:
 if enemy.type!=TYPE: return
 enemy.flex_next=BaseBlock
 enemy.mech_armor=0.0

static func after_hit(g, enemy: Dictionary, damage_type: String, details: Dictionary) -> void:
 if enemy.type!=TYPE or damage_type!="physical" or not details.get("attack",false): return
 var gain=int(enemy.flex_next)
 enemy.mech_armor+=gain
 enemy.flex_next+=1
 g._emit("mechanical","柔韧使%s获得%d点格挡。" % [enemy.name,gain],{"enemy":enemy.id,"block_gain":gain})

static func issue(g, enemy: Dictionary) -> String:
 var move=enemy.intent.get("kind","")
 if enemy.type!=TYPE:
  return "敌人的柔韧或胶带行动记录有误。" if enemy.has("flex_next") or enemy.has("tape_opens_fit") or move in Actions else ""
 if not g.Snapshot.fields(enemy,"tape_opens_fit:b flex_next:i mech_armor:n") or enemy.stage<1 or enemy.flex_next<BaseBlock: return "胶带团状态有误。"
 var earned=(float(enemy.flex_next)-BaseBlock)*(float(enemy.flex_next)+BaseBlock-1.0)/2.0
 if not is_finite(enemy.mech_armor) or enemy.mech_armor<0.0 or enemy.mech_armor>earned: return "胶带团格挡记录有误。"
 if not enemy.intent.is_empty():
  var expected=plan(enemy)
  if move!=expected.kind or enemy.intent.get("text","")!=expected.text: return "胶带团行动顺序有误。"
 return ""
