extends RefCounted
const FirstFloor=preload("res://data/first_floor_enemy_pools.gd")
const Catalog=preload("res://data/equipment_catalog.gd")

# Fifteen ascending floors, the summit boss, then the exit.
const DISTANCE=5.0
const LAST_FLOOR=15
const PRACTICE={
 "name":"装备练习室",
 "description":"初始佩戴绳索、胶带、已锁皮带和扎带，携带小石片与锈锯条。练习采用6回合休息规则，禁用卡牌自由效果。",
 "hint":"绳索可徒手解开，皮带须先开锁；胶带和扎带请用解除牌或适用工具处理。切割塑料扎带需要锈锯条。操作需满足姿态、部位与外露条件。",
 "equipment":[
  {"template":"rope","slot":"wrist","durability":3.2,"locked":false},
  {"template":"tape","slot":"calf","durability":3.2,"locked":false},
  {"template":"belt","slot":"ankle","durability":6.4,"locked":true},
  {"template":"cable_tie","slot":"thigh","durability":6.4,"locked":false}],
 "items":["shard","saw"]}
const LINK_PRACTICE={
 "name":"链接练习室",
 "description":"小腿绳索与脚踝皮带之间接有一条链接绳，共享6.4点耐久。携带两件切割工具，拥有6回合和3次挂钩；卡牌自由效果禁用。",
 "hint":"链接绳牵住脚踝皮带。先挣扎解除链接绳，或坐下后切割、徒手解开；也可解除相连的小腿绳索。链接绳容量占用0，解除方式为挣扎、徒手或适用工具，锁孔：无。",
 "equipment":[{"template":"rope","slot":"calf","point":"mid_calf","durability":6.4,"locked":false},{"template":"belt","slot":"ankle","durability":6.4,"locked":false}],
 "links":[{"a":0,"b":1,"durability":6.4,"blocked_end":1}],
 "items":["shard","saw"]}

const GLOVE_SHORT_PRACTICE={
 "name":"短型单手套练习室",
 "description":"短型套体固定大臂、小臂与手腕；两条直肩带分别处理，手掌与手指保持自由。限时6回合，挂钩可用3次，提供两件切割工具。",
 "hint":"先将滑脱牌拖到左侧手臂，选择左肩带；解除一侧后，再对套体使用挣扎牌可直接脱下。短型仍允许手势魔法。套体需使用解除牌或工具。",
 "equipment":[],"items":["shard","saw"],
 "composites":[{"variant":"short","straps":"straight","tier":2,"parts":{"left":{"tier":1},"right":{"locked":true}}}]}
const GLOVE_LONG_PRACTICE={
 "name":"长型单手套练习室",
 "description":"长型套体额外包住手掌与手指，交叉肩带左右独立耐久，需先用兼容工具松到一档才能滑脱。套体开局三档；拥有6回合、3次挂钩与两件切割工具。",
 "hint":"先解除交叉肩带。三档套体还需挣扎或魔力撑隙降档，再次挣扎才能直接脱下。手势施法与握持工具需要手指自由；脚趾仍可把工具装入墙脚的缝隙，躺下后切割外露套体。",
 "equipment":[],"items":["shard","saw"],
 "composites":[{"variant":"long","straps":"cross","grade":3,"tier":3,"parts":{}}]}
const PRACTICES={
 "doubao":{"label":"豆包练习 · 首回合接管","node":"StartDoubaoPractice","focus":"wrist","spec":{"name":"豆包练习","description":"携带豆包进入漂浮玩具箱战斗，体验首回合接管、模拟鼠标与对白。","hint":"接管结束后可自行操作。离开战斗、战后整备、休息及监狱后，右键遗物可切换为DeepSeek。","equipment":[],"items":[],"relics":["doubao"],"encounter":"toybox_solo"}},
 "equipment":{"label":"装备练习 · 四种材质与切割工具","node":"StartEquipmentPractice","focus":"wrist","spec":PRACTICE},
 "links":{"label":"链接练习 · 连接、挣扎与切割","node":"StartLinkPractice","focus":"calf","spec":LINK_PRACTICE},
 "glove_short":{"label":"短型单手套 · 直肩带与挣扎解除","node":"StartShortGlovePractice","focus":"upper_arm","spec":GLOVE_SHORT_PRACTICE},
 "glove_long":{"label":"长型单手套 · 交叉肩带与工具","node":"StartLongGlovePractice","focus":"upper_arm","spec":GLOVE_LONG_PRACTICE}}

static func practice_spec(kind: String) -> Dictionary:
 return all_practices().get(kind,PRACTICES.equipment).spec

static func all_practices() -> Dictionary:
 var result=PRACTICES.duplicate(true)
 result.merge(Catalog.entries())
 return result
# Six walks through the seven-column grid; first two starts are distinct.
const MAP_VERSION=3
const PATHS=6
const WEAK_ENCOUNTERS=3
const ROOM_RATES={"shop":0.05,"rest":0.12,"event":0.22,"elite":0.08}

static func prison_route(security: int) -> Array:
 return [
  {"id":"prison_start","name":"出发点","kind":"entry","wall":"normal","next":["prison_rest"],"floor":0,"lane":0.5},
  {"id":"prison_rest","name":"休息点","kind":"rest","wall":"rough","next":["prison_gate"],"floor":1,"lane":0.5},
  {"id":"prison_gate","name":"监狱出口 · 精英战","kind":"battle","wall":"normal","next":[],"floor":2,"lane":0.5,"encounter":"guard_solo","encounter_repeats":security,"requires_defeat":true}]

static func generate(run_seed: int, retained_summit: String="") -> Array:
 var random=RandomNumberGenerator.new()
 random.seed=run_seed ^ 791939
 var grid={}
 var edges=[]
 var first_start=-1
 for path in range(PATHS):
  var column=random.randi_range(0,6)
  if path==0: first_start=column
  elif path==1 and column==first_start: column=(column+random.randi_range(1,6))%7
  for floor in range(LAST_FLOOR):
   var key=Vector2i(column,floor)
   if not grid.has(key): grid[key]={"floor":floor,"column":column,"lane":float(column)/6.0,"next":[],"kind":""}
   if floor==LAST_FLOOR-1: break
   var options=[]
   for next_column in range(maxi(0,column-1),mini(6,column+1)+1):
    if edges.any(func(edge):return edge[0].y==floor and (edge[0].x-column)*(edge[1].x-next_column)<0): continue
    options.append(next_column)
   var next_column=options[random.randi_range(0,options.size()-1)]
   var end=Vector2i(next_column,floor+1)
   if not edges.has([key,end]): edges.append([key,end])
   column=next_column
 # Keep a single incoming edge on the second row, matching the first-row pruning.
 var second_row=[]
 var pruned=[]
 for edge in edges:
  if edge[0].y==0:
   if edge[1] in second_row: continue
   second_row.append(edge[1])
  pruned.append(edge)
 edges=pruned
 for key in grid.keys():
  if key.y==0 and not edges.any(func(edge):return edge[0]==key): grid.erase(key)
 var rooms=grid.values()
 rooms.sort_custom(func(a,b):return a.floor<b.floor if a.floor!=b.floor else a.column<b.column)
 for r in rooms:
  r.id="floor_%d_%d" % [r.floor,r.column]
  r.wall="normal" if random.randi_range(0,1)==0 else "rough"
  if r.floor==0: r.kind="battle"
  elif r.floor==8: r.kind="treasure"
  elif r.floor==14: r.kind="rest"
 for edge in edges: grid[edge[0]].next.append(grid[edge[1]].id)
 var bucket=[]
 for kind in ROOM_RATES:
  for i in range(roundi(rooms.size()*ROOM_RATES[kind])): bucket.append(kind)
 while bucket.size()<rooms.filter(func(r):return r.kind=="").size(): bucket.append("battle")
 for i in range(bucket.size()-1,0,-1):
  var j=random.randi_range(0,i)
  var swap=bucket[i];bucket[i]=bucket[j];bucket[j]=swap
 for r in rooms:
  if r.kind!="": continue
  var parents=rooms.filter(func(other):return r.id in other.next)
  var siblings=[]
  for parent in parents: siblings.append_array(rooms.filter(func(other):return other.id!=r.id and other.id in parent.next))
  for index in range(bucket.size()):
   var kind=bucket[index]
   if kind in ["rest","elite"] and r.floor<5: continue
   if kind=="rest" and r.floor==13: continue
   if kind in ["rest","elite","shop"] and parents.any(func(other):return other.kind==kind): continue
   if siblings.any(func(other):return other.kind==kind): continue
   r.kind=kind;bucket.remove_at(index);break
 # Empty rooms become normal battles only after all constrained assignments.
 for r in rooms:
  if r.kind=="": r.kind="battle"
 # Keep one stable id on the final rest row for declared equipment practices.
 var rests=rooms.filter(func(r):return r.kind=="rest" and r.floor==14)
 var rest_id=rests[0].id
 rests[0].id="rest"
 for r in rooms:
  if rest_id in r.next: r.next[r.next.find(rest_id)]="rest"
  match r.kind:
   "battle":
    r.pool="ordinary"
    r.name=["最左回廊","左侧回廊","偏左回廊","中央回廊","偏右回廊","右侧回廊","最右回廊"][r.column]
   "elite":
    r.kind="battle";r.encounter=FirstFloor.ELITE_ENCOUNTERS[random.randi_range(0,FirstFloor.ELITE_ENCOUNTERS.size()-1)];r.name="精英遭遇"
   "event":
    r.name="事件"
   "rest": r.name="挂钩休息室";r.wall="normal"
   "shop": r.name="魔力商店";r.wall="normal"
   "treasure": r.name="遗物宝箱";r.wall="normal"
  r.name="%02d · %s" % [r.floor+1,r.name]
 rooms.push_front({"id":"entrance","name":"塔底入口","floor":-1,"lane":0.5,"wall":"normal","next":rooms.filter(func(r):return r.floor==0).map(func(r):return r.id),"kind":"entry","map_version":MAP_VERSION})
 var summit_encounter=FirstFloor.SUMMIT_ENCOUNTERS[random.randi_range(0,FirstFloor.SUMMIT_ENCOUNTERS.size()-1)]
 if retained_summit!="": summit_encounter=retained_summit
 var summit={"id":"summit","name":"塔顶 · "+FirstFloor.summit_name(summit_encounter),"floor":LAST_FLOOR,"lane":0.5,"wall":"rough","next":["exit"],"kind":"battle","encounter":summit_encounter,"boss":true,"requires_defeat":true}
 for r in rooms:
  if r.floor==14: r.next=["summit"]
 rooms.append(summit)
 rooms.append({"id":"exit","name":"塔顶出口","floor":LAST_FLOOR+1,"lane":0.5,"wall":"none","next":[],"kind":"exit","requires_clear":"summit"})
 return rooms

