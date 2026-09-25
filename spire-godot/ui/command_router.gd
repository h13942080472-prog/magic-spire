extends RefCounted

# M-I 指令路由（docs/spec/candidate-removal.md §3.1；N1）：前端唯一指令入口。
# 职责＝唯一分类点（ROUTES：kind → 子路由）＋交提交执行段（ui/main.gd::_submit）；装配在 command_routes.gd。
# 表外 kind fail-closed：拒绝并留一条只读记录，不静默放行、不崩（G2）。
# 本文件与 command_routes.gd 都不 preload core（依赖方向：ui 内只有 ui/main.gd 允许 preload core）。
const Routes=preload("res://ui/command_routes.gd")

# 唯一分类点：39 条 kind 各恰一条子路由（docs/spec/candidate-removal.md §3.3 的 kind 全集；本表是闭集，
# 新增 kind 必须先回填契约再实现）。子路由名＝command_routes.gd::assemble 的 route 分支。
const ROUTES={
 "card":"battle","chain":"battle","attack":"battle","status_toggle":"battle","posture":"battle",
 "wall_move":"battle","manual":"battle","hook":"battle","calm":"battle",
 "item_use":"item","item_install":"item","item_retrieve":"item","item_discard":"item",
 "end":"flow","surrender":"flow","finish_prepare":"flow","finish_rest":"flow","finish_pack":"flow",
 "retain":"flow","retain_skip":"flow",
 "rest_rare":"rest","rest_card":"rest","rest_flask":"rest","rest_begin":"rest",
 "service":"shop",
 "event":"event",
 "prison":"prison",
 "depart":"route","travel_step":"route",
 "reward":"reward","reward_skip":"reward","relic_bundle":"reward",
 "departure":"departure",
 "relic_toggle":"relic","relic_discharge":"relic","relic_control_done":"relic","flask":"relic",
 "demo_end":"demo","demo_continue":"demo",
}

var host
# 表外 kind 的只读记录：不进 state／View／存档、不渲染、不计数。
var rejections: Array=[]

func _init(h) -> void:
 host=h

# 前端唯一指令入口：kind＋意图来源＋expected_version → 分类 → 子路由装配 → 提交执行段。
# 返回 {ok, submitted, handled, kind}；ok=false 只出现在表外 kind（fail-closed）。
func emit(kind: String, source: Dictionary, expected_version: int=-1, takeover: bool=false) -> Dictionary:
 var route=String(ROUTES.get(kind,""))
 if route=="":
  rejections.append({"kind":kind,"keys":source.keys()})
  return {"ok":false,"submitted":false,"handled":true,"kind":kind}
 var cmd=Routes.assemble(route,host,source,expected_version)
 if cmd.has("handled"): return {"ok":true,"submitted":false,"handled":true,"kind":kind}
 if cmd.is_empty(): return {"ok":true,"submitted":false,"handled":false,"kind":kind}
 host._submit(cmd,takeover)
 return {"ok":true,"submitted":true,"handled":true,"kind":kind}

# 延迟装配（拖放落牌不在同一帧内重入）：同一入口的调度变体，不构成第二入口。
func emit_deferred(kind: String, source: Dictionary, expected_version: int=-1, takeover: bool=false) -> void:
 call_deferred("emit",kind,source,expected_version,takeover)
