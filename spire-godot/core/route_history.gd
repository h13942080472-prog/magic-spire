extends RefCounted

# docs/spec/save-fixed-points.md「加性字段与只读入口」：state.route_history 按 局→周目→塔路 保存一条
# 紧凑记录。本文件是它的唯一写入者：open 关闭上一条、追加下一条；另两处写入只有 core/game.gd 的
# _init 字面与 restore_snapshot 的单行回填。记录键面固定，不含时间、外部标识或随机值，因此同一种子与
# 同一串指令复现同一段历史。
#
# 切换真正落下的时刻，调用方已经生成了下一张塔路图，所以被关闭那条路线的已完成房间楼层只能按它自己
# 的 seed／boss／security 重建：Tower.generate 与 Tower.prison_route 都是确定性的。只有测试夹具改名
# 后的房间 id 无法被生成器复现时，才回落到当前 state.rooms 里找同 id 的楼层。

const KEYS=["enter","cycle","generation","region","seed","boss","security","nodes","floor"]
const REGION_TOWER="tower"
const REGION_PRISON="prison"
const ENTER_START="start"
const ENTER_RELEASE="release"
const ENTER_ESCAPE="escape"
const ENTER_GATE_EXIT="gate_exit"
const ENTER_CYCLE="cycle"
const ENTER_UNKNOWN="unknown"

# 唯一追加点：每次真正换塔路（TRANSITIONS 里 route 标真的三条 kind）只追加一条。
static func open(g, kind: String) -> void:
 var history: Array=g.state.route_history
 if not history.is_empty(): _close(g,history[-1])
 history.append(_entry(g,_reason(g,kind)))

# 进入理由只看本次 kind 与已记录的历史；换塔时先比较周目，再区分监狱出口，最后才是普通重开。
static func reason(g, kind: String) -> String:
 match kind:
  "setup_init": return ENTER_START
  "prison_escape": return ENTER_ESCAPE
  "tower_restart":
   var last=_last(g)
   if int(g.state.demo_cycle)>int(last.get("cycle",0)): return ENTER_CYCLE
   if String(last.get("region",""))==REGION_PRISON: return ENTER_GATE_EXIT
   return ENTER_RELEASE
 return ENTER_UNKNOWN

# 旧档缺字段时的回填形态：一条无法归类的塔路，节点与楼层留待下次真正关闭时补齐；不改存档版本。
static func backfill(s: Dictionary) -> Array:
 var region=String(s.get("map_region",""))
 return [{"enter":ENTER_UNKNOWN,
  "cycle":int(s.get("demo_cycle",0)),
  "generation":int(s.get("tower_generation",0)),
  "region":region,
  "seed":int(s.get("seed",0)),
  "boss":_boss_of(region,s.get("room_encounters",{})),
  "security":int(s.get("security",0)),
  "nodes":-1,
  "floor":-1}]

static func _entry(g, enter: String) -> Dictionary:
 var region=String(g.state.map_region)
 return {"enter":enter,
  "cycle":int(g.state.demo_cycle),
  "generation":int(g.state.tower_generation),
  "region":region,
  "seed":int(g.state.seed),
  "boss":_boss_of(region,g.state.room_encounters),
  "security":int(g.state.security),
  "nodes":-1,
  "floor":-1}

static func _boss_of(region: String, encounters) -> String:
 if region==REGION_PRISON or not encounters is Dictionary: return ""
 return String(encounters.get("summit",""))

static func _last(g) -> Dictionary:
 var history: Array=g.state.route_history
 return {} if history.is_empty() else history[-1]

static func _close(g, record: Dictionary) -> void:
 var completed: Array=g.state.completed_rooms
 record["nodes"]=completed.size()
 record["floor"]=_reached_floor(g,record,completed)

# 与 ui/run_review.gd::_progress_text 同口径：已完成房间的最高层加一；没有完成房间时为 0。
static func _reached_floor(g, record: Dictionary, completed: Array) -> int:
 var floors=_floors(g,record)
 var highest=0
 for id in completed:
  if floors.has(String(id)): highest=maxi(highest,int(floors[String(id)])+1)
 return highest

static func _floors(g, record: Dictionary) -> Dictionary:
 var rooms=[]
 if String(record.get("region",""))==REGION_PRISON:
  rooms=g.Tower.prison_route(int(record.get("security",0)))
 else:
  rooms=g.Tower.generate(int(record.get("seed",0)),String(record.get("boss","")))
 var floors={}
 for room in rooms: floors[String(room.id)]=int(room.floor)
 for room in g.state.rooms:
  if not floors.has(String(room.id)): floors[String(room.id)]=int(room.floor)
 return floors
