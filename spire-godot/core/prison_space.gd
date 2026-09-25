extends RefCounted

# Hidden geometry, shared by destination travel, blind directions and wall contact.
const SIZE=7
const ENTRY=[0,6]
const DIRECTIONS={"north":[0,-1],"east":[1,0],"south":[0,1],"west":[-1,0]}
const NAMES={"north":"向前","east":"向右","south":"向后","west":"向左"}
const FALL=[0.0,0.2,0.4,0.5,0.6]

static func cell(v) -> bool:
 return v is Array and v.size()==2 and v.all(func(n):return n is int and n>=0 and n<SIZE)

static func walkable(s: Dictionary, pos: Array) -> bool:
 return cell(pos) and not pos in s.blocked

static func wall_distance(pos: Array) -> int:
 return mini(mini(pos[0],pos[1]),mini(SIZE-1-pos[0],SIZE-1-pos[1]))

static func path(s: Dictionary, start: Array, goal: Array) -> Array:
 if not walkable(s,start) or not walkable(s,goal): return []
 var queue=[start];var seen={str(start):[]};var i=0
 while i<queue.size():
  var at=queue[i];i+=1
  if at==goal: return seen[str(at)]
  for delta in DIRECTIONS.values():
   var next=[at[0]+delta[0],at[1]+delta[1]]
   if not walkable(s,next) or seen.has(str(next)): continue
   seen[str(next)]=seen[str(at)]+[next];queue.append(next)
 return []

static func initial(g) -> Dictionary:
 var s={"position":ENTRY.duplicate(),"blocked":[[1,4],[1,5],[4,2]],"sites":[{"id":"place_0","position":[0,6],"label":"床边","discovery":"","visited":true},{"id":"place_1","position":[6,3],"label":"牢门","discovery":"","visited":false}]}
 for discovery in g.Prison.ACTIVE_DISCOVERIES:
  var choices=[]
  for y in range(SIZE):
   for x in range(SIZE):
    var pos=[x,y]
    if not walkable(s,pos) or s.sites.any(func(site):return site.position==pos): continue
    if (wall_distance(pos)>0)!=(discovery=="shard"): continue
    if path(s,s.position,pos).is_empty(): continue
    choices.append(pos)
  var pos=choices[g._random_index("explore",choices.size())]
  s.sites.append({"id":"place_"+str(s.sites.size()),"position":pos,"label":"？？？" if discovery=="shard" else ("墙脚窄缝" if discovery=="vent" else "松动砖缝"),"discovery":discovery,"visited":false})
 return s

static func active(g) -> bool:
 return g.state.room=="prison" and g.state.prison.get("active",false) and g.state.prison.has("space") and g.state.phase in ["prison","inspection"]

static func at(g, discovery: String) -> bool:
 if not active(g): return false
 return g.state.prison.space.sites.any(func(site):return (site.id=="place_1" if discovery=="door" else site.discovery==discovery) and site.position==g.state.prison.space.position)

static func site_path(g, id: String) -> Array:
 var s=g.state.prison.space
 for site in locations(g):
  if site.id==id: return path(s,s.position,site.position)
 return []

static func direction_path(g, direction: String, steps: int=0) -> Array:
 if not DIRECTIONS.has(direction): return []
 var s=g.state.prison.space;var at=s.position;var result=[];var delta=DIRECTIONS[direction]
 for i in range(g.wall_movement_profile().distance if steps==0 else mini(steps,g.wall_movement_profile().distance)):
  var next=[at[0]+delta[0],at[1]+delta[1]]
  if not walkable(s,next): break
  result.append(next);at=next
 return result

static func wall_path(g, toward: bool) -> Array:
 var s=g.state.prison.space;var best=[];var nearest=999
 if toward and wall_distance(s.position)==0: return []
 for y in range(SIZE):
  for x in range(SIZE):
   var goal=[x,y];var distance=wall_distance(goal)
   if (toward and distance!=0) or (not toward and distance<=wall_distance(s.position)): continue
   var route=path(s,s.position,goal)
   if route.size()>0 and route.size()<nearest:
    best=route;nearest=route.size()
 return best

static func bearing(start: Array, end: Array) -> String:
 var vertical="前" if end[1]<start[1] else ("后" if end[1]>start[1] else "")
 var horizontal="左" if end[0]<start[0] else ("右" if end[0]>start[0] else "")
 return "当前位置" if start==end else horizontal+vertical+"方"

static func fall_profile(g, started_at_wall: bool=false) -> Dictionary:
 var level=g.level("legs");var factor=2.0-g.Pressure.cast_chance(g.state.pressure,g.Pressure.maximum(g))
 var protected=started_at_wall or g.at_wall()
 var eligible=g.state.phase=="prison" and g.state.posture=="stand" and level>0 and not protected
 var chance=clampf(FALL[level]*factor+(0.2 if g.occupied("eyes") else 0.0),0.0,1.0) if eligible else 0.0
 return {"chance":chance,"level":level,"base":FALL[level],"multiplier":factor,"blind_bonus":0.2 if g.occupied("eyes") else 0.0,"protected":protected}

static func locations(g) -> Array:
 var result=g.state.prison.space.sites.duplicate(true)
 for item in g.state.items:
  if item.mount=="carry" or not item.has("prison_position"): continue
  result.append({"id":"tool_"+item.id,"position":item.prison_position,"label":"已安装的"+g.Tools.TYPES[item.type].name,"discovery":"","visited":true})
 return result

# Read only the next paid movement segment, including a detour that returns to a wall.
static func wall_warning(g, route: Array) -> String:
 if not g.wall_contact() or route.is_empty(): return ""
 var segment=route.slice(0,mini(route.size(),g.wall_movement_profile().distance))
 if not segment.any(func(pos):return wall_distance(pos)>0): return ""
 if g.relic_value("always_wall")>0: return "本次会离开墙边；遗物仍提供贴墙效果，墙上工具需回到安装处使用。"
 return "本次会暂时离墙，结束时回到墙边。" if wall_distance(segment.back())==0 else "本次移动后将离墙，墙面效果暂停。"

static func view(g) -> Dictionary:
 var s=g.state.prison.space;var blind=g.occupied("eyes");var sites=[]
 for site in locations(g):
  var route=path(s,s.position,site.position);var here=s.position==site.position
  var label=site.label
  if site.visited and site.discovery!="": label=g.Tools.TYPES[site.discovery].name if g.Tools.TYPES.has(site.discovery) else "通风口"
  var item={"id":site.id,"label":"？？？" if blind and not here else label,"near":not here and route.size()>0 and route.size()<=2,"here":here,"visited":site.visited if not blind or here else false}
  item.interaction={}
  item.installation_points=g.Tools.installation_points(g) if here else []
  if not blind or here:
   if here and not item.installation_points.is_empty(): item.interaction={"kind":"wall"}
   if site.id=="place_1": item.interaction={"kind":"door"}
   elif site.discovery=="vent" and site.visited: item.interaction={"kind":"vent"}
   else:
    var tools=g.state.items.filter(func(tool):return site.id=="tool_"+tool.id or (site.visited and site.discovery==tool.type))
    if not tools.is_empty(): item.interaction={"kind":"item","item":tools[0].id}
  if not blind:
   item.distance=route.size();item.bearing=bearing(s.position,site.position)
   item.wall_distance=wall_distance(site.position)
   item.initial_distance=path(s,ENTRY,site.position).size()
   item.wall_warning=wall_warning(g,route)
  if (not blind or here) and site.id.begins_with("tool_"):
   var tool=g._item(site.id.trim_prefix("tool_"))
   item.installed={"mount":g.Tools.mount_label(tool.mount),"uses":tool.uses}
  sites.append(item)
 return {"blind":blind,"sites":sites,"fall":fall_profile(g),"stride":g.wall_movement_profile().distance,"cost":g.wall_movement_profile().cost}

# 牢房空间移动的显示事实（批 R5：行生产转发改显示事实构建，docs/spec/candidate-removal.md §2.1 T5／T8）。
static func facts(g) -> Array:
 var out=[]
 var v=view(g);var profile=g.wall_movement_profile()
 if v.blind:
  for direction in DIRECTIONS:
   for steps in range(1,profile.distance+1):
    var route=direction_path(g,direction,steps)
    g.Prison.add(out,g,"explore",NAMES[direction]+"摸索%d格" % steps,{"kind":"prison_space.explore_blind","args":{},"fallback":explore_blind_detail(g,{})},profile.cost,"这个方向紧邻墙壁或家具，无法移动。" if route.is_empty() else "",{"direction":direction,"steps":steps,"wall_warning":wall_warning(g,route)})
 else:
  for site in v.sites:
   var text="%s · %s · %d格 · %s" % [site.label,site.bearing,site.distance,"靠墙" if site.wall_distance==0 else "离墙%d格" % site.wall_distance]
   var site_args={"distance":profile.distance,"cost":profile.cost}
   g.Prison.add(out,g,"explore",text,{"kind":"prison_space.explore_site","args":site_args,"fallback":explore_site_detail(g,site_args)},profile.cost,"已经在这里。" if site.here else "",{"site":site.id,"wall_warning":site.wall_warning})
 return out

# R3（docs/ondemand-copy.md §11.5）：探索文案的 builder，正文留在本模块。
static func explore_blind_detail(_g, _args: Dictionary) -> String:
 return "遇到家具或墙会停下；经过地点自动探索。"

static func explore_site_detail(_g, args: Dictionary) -> String:
 return "每次最多移动%d格，花%d能量；抵达或经过地点自动探索。" % [int(args.get("distance",0)),int(args.get("cost",0))]

static func discover(g) -> void:
 for site in g.state.prison.space.sites:
  if site.position!=g.state.prison.space.position or site.visited: continue
  site.visited=true
  if site.discovery=="":
   g._emit("event","你来到"+site.label+"。")
   continue
  var p=g.state.prison;p.discoveries.erase(site.discovery);p.found.append(site.discovery)
  if g.Tools.TYPES.has(site.discovery): g._gain_tool(site.discovery)
  g._emit("event",{"shard":"你在地面找到一枚尖锐的小石片。","saw":"你在松动砖缝里找到一截锈锯条。","vent":"你摸到墙脚的通风口，可以坐下踢开格栅。"}[site.discovery])

static func move(g, route: Array, trigger: String="explore") -> String:
 if route.is_empty(): return "前方没有可移动的位置。"
 var s=g.state.prison.space;var stride=mini(route.size(),g.wall_movement_profile().distance)
 var started_at_wall=g.at_wall()
 for i in range(stride):
  var next=route[i]
  if not walkable(s,next) or absi(next[0]-s.position[0])+absi(next[1]-s.position[1])!=1: return "移动路径已经失效。"
  s.position=next.duplicate();g.state.wall_distance=wall_distance(s.position)
  discover(g)
 var moved="你移动了%d格，%s。" % [stride,"来到墙边" if g.wall_contact() else "现在离墙%d格" % g.state.wall_distance]
 if not g.wall_contact() and g.at_wall(): moved+="遗物仍提供贴墙效果。"
 g._emit("event",moved,{"exploration_move":{"distance":stride,"started_at_wall":started_at_wall,"at_wall":g.at_wall()}})
 g.SlipMotion.apply(g,trigger)
 g._settle_energy_pressure()
 var fall=fall_profile(g,started_at_wall);var roll=-1;var fell=false
 if fall.chance>0:
  roll=g._random_index("fall",10000);fell=roll<int(round(fall.chance*10000))
  if fell:
   g.state.posture="sit" if fall.level<=2 else "lie"
  var result=("你没能站稳，坐倒在地。" if fall.level<=2 else "你失去平衡，摔倒躺在地上。") if fell else "你稳住身体，没有摔倒。"
  fall.roll=roll;fall.fell=fell
  g._emit("event",result+" 摔倒概率%s%%。" % g.number(fall.chance*100),{"exploration_fall":fall})
 return ""

static func execute(g, payload: Dictionary) -> String:
 var route=direction_path(g,payload.get("direction",""),payload.get("steps",0)) if g.occupied("eyes") else site_path(g,payload.get("site",""))
 return move(g,route)

static func attachment_position(g) -> Array:
 # Combat uses the existing abstract wall distance. Retain its tool at the nearest
 # concrete exploration wall, without moving the stored exploration position.
 var pos=g.state.prison.space.position
 if wall_distance(pos)==0: return pos.duplicate()
 var route=wall_path(g,true)
 return route.back().duplicate()

static func mounted_reason(g, item: Dictionary) -> String:
 if active(g) and item.mount!="carry" and item.get("prison_position",[])!=g.state.prison.space.position: return "需要回到安装这件工具的墙缝前。"
 return ""

static func validate(g) -> String:
 var p=g.state.prison
 if p.is_empty(): return ""
 var s=p.get("space",{})
 if not g.Snapshot.fields(s,"position:a blocked:a sites:a") or not cell(s.position): return "牢房位置记录不完整。"
 if s.blocked.size()!=s.blocked.reduce(func(found,pos):found[str(pos)]=true;return found,{}).size(): return "牢房家具位置重复。"
 if s.blocked.any(func(pos):return not cell(pos)) or not walkable(s,s.position): return "牢房位置落在墙外或家具中。"
 if s.sites.size()!=5: return "牢房地点数量不正确。"
 var ids=[];var positions=[];var discoveries=[]
 for site in s.sites:
  if not g.Snapshot.fields(site,"id:s position:a label:s discovery:s visited:b") or not walkable(s,site.position) or site.id in ids or site.position in positions: return "牢房地点重复或不合法。"
  if site.position!=s.position and path(s,s.position,site.position).is_empty(): return "牢房地点无法到达。"
  if site.id in ["place_0","place_1"] and site.discovery!="": return "牢房入口不能兼作隐藏发现。"
  if site.id=="place_0" and (site.position!=[0,6] or site.label!="床边" or not site.visited): return "牢房起点记录不一致。"
  if site.id=="place_1" and (site.position!=[6,3] or site.label!="牢门"): return "牢门位置记录不一致。"
  if site.discovery in ["saw","vent"] and wall_distance(site.position)!=0: return "墙缝和通风口必须靠墙。"
  if site.discovery=="shard" and wall_distance(site.position)==0: return "地面未知物必须位于室内。"
  ids.append(site.id);positions.append(site.position)
  if site.discovery!="":
   if site.discovery not in g.Prison.ACTIVE_DISCOVERIES or site.discovery in discoveries or site.visited!=(site.discovery in p.found): return "牢房发现与地点不一致。"
   discoveries.append(site.discovery)
 if not ["place_0","place_1","place_2","place_3","place_4"].all(func(id):return id in ids) or discoveries.size()!=3: return "牢房地点缺少必要入口。"
 if active(g) and g.state.wall_distance!=wall_distance(s.position): return "距墙与牢房位置不一致。"
 for item in g.state.items:
  if p.active and item.mount!="carry" and (not cell(item.get("prison_position")) or wall_distance(item.prison_position)!=0): return "墙上工具缺少安装位置。"
 return ""
