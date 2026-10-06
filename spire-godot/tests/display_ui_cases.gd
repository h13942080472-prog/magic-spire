extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")
const Settings=preload("res://ui/display_settings.gd")
const Portrait=preload("res://ui/equipment_portrait.gd")
const Art=preload("res://ui/pixel_art.gd")
const Cases=preload("res://tests/architecture_cases.gd")

# docs/spec/candidate-removal.md「接口」判据真源（r3_display_points_do_not_read_rows；批 R3 的手牌／行动／姿态／墙面／底栏域）：夹具矩阵 0／12／26／44 件
# × 战斗／整备／休息（同种子 42）。①每个显示点的可用／原因／风险／费用与唯一判定对同一形状的输出逐字段相等
# （同一形状恰有一条候选行＝G2 已断言的前提）；②显示文本与未改源码基线逐字相等（基线于批 R3 前用未改源码复算，
# 只含显示文本字段，不含提交身份 id）。键＝显示点（kind＋声明 params 的 8 位摘要；手牌点＝hand|uid）。
const R3_G5_CELLS=[["battle",0],["battle",12],["battle",26],["battle",44],["prepare",0],["prepare",12],["prepare",26],["prepare",44],["rest",0],["rest",12],["rest",26],["rest",44]]
const R3_G5_BASELINE={
 "battle:0":{"attack|08fca583":"ebcecd4a035227be67b22d098ba35a83","attack|0c0c7bd1":"0a1b193599a04105a0d109039781b9b8","attack|113750c3":"237d7d23d5ab52c223807e9a90b3bf70","attack|2c270d2a":"eb89680af2670fe8c0f8b312b9861e0b","attack|52271fb5":"4de1bd5271b4cda78e40e480149e5920","attack|52fc0492":"9eed933e9067640e55df0697bf87aae5","attack|576c7b23":"638426dd3d8bc3f4cfc2ce8c351d6d32","attack|57c9f6c8":"9d8c1538d03513e2dc45f55a28a5546d","attack|6234891c":"495dfff5b54eba4ba4d31aa180db5c06","attack|828e3ba0":"1b01362e632760344a9d3c8fd687ae49","attack|a2e396da":"e24c68f50bc5da0b10030899f2e348a6","attack|d845d27a":"e0cf1531d0f801334eb0b6112957f9b7","attack|e01afa84":"e03c0e7604d0d09f5874c40bf3707e6b","attack|e271ef98":"93e85e7c5148fb4adb815a0e1cc062e9","attack|e8b9ed92":"21c8238f2244fe1a2e94c381bc0efc85","attack|edbfd60b":"237d7d23d5ab52c223807e9a90b3bf70","attack|f1466260":"59035bc1ddd448038b67af9bd27ab48a","attack|fd8648f7":"36c7a68bbc66301508eeec21d95013c2","calm|44136fa3":"22f22bd5655c18cf140d6b62a6d553c0","end|44136fa3":"669b85ed16826d266af4864f98c18aff","hand|card_1":"2cef93ec87602eca7a69f21b2dd03bfe","hand|card_10":"dc7af853ad29313100ec20d785605a3f","hand|card_4":"b6c18d758f81d807b1e6082e625c5efb","hand|card_7":"2cef93ec87602eca7a69f21b2dd03bfe","hand|card_9":"25301a25f02a59e025f9fe69d72a77a1","posture|415624d6":"2dd0890dd2101b22bb642e55937056c0","posture|99cbd16f":"f19cc76fdf4e9eddc9289705ea7c699b","posture|b7ae54f1":"1ba4b0f2263a41546ccdefde8482bf31","surrender|44136fa3":"be8c1cda992e77565be9e8d4c859f37a","wall_move|3c876c16":"5f366e62149218c26561a0c838ac79ff","wall_move|8d07fe3f":"57383e77989ec6113b5bcd39b30ae430"},
 "battle:12":{"attack|08fca583":"6fc557d137f0980f6469cff113cf059f","attack|0c0c7bd1":"ec60867ee6befbea6b04befac9d3b2e4","attack|113750c3":"187dd276d48337c9351f73f86651a8cf","attack|2c270d2a":"a388e0c26f0abf0f4c96743da1b57a1a","attack|52271fb5":"f7342cf5520c97bee4425ed69ab7d2df","attack|52fc0492":"c31235bb26bba9b7db939b7f1b1b0996","attack|576c7b23":"08401c88d053d4aa4e8dd539b3d50abe","attack|57c9f6c8":"732abe3ba841068a101537b8d18e2cc7","attack|6234891c":"fdaa61935e43240f89bbebaba020acda","attack|828e3ba0":"afdfb2a5e743000cb0576e684ac2fdb8","attack|a2e396da":"febd5617f363b273eafd5d718fc10373","attack|d845d27a":"bd728aa7a950c3e6b3c9516b86ffe9b6","attack|e01afa84":"a7ce455637c28c61542c83891e079be3","attack|e271ef98":"4c3628ce5c4d941f517e2a0398e8e512","attack|e8b9ed92":"beb6d0508599c0026a617aff36c2bd10","attack|edbfd60b":"187dd276d48337c9351f73f86651a8cf","attack|f1466260":"86dafa295a7c4d4388009121f3446110","attack|fd8648f7":"f5972417ee2f3f33a859b8e0d8dbd553","calm|44136fa3":"41ea03020ea2e37ff17b9aa376452480","end|44136fa3":"669b85ed16826d266af4864f98c18aff","hand|card_1":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_10":"6a43699b10926047d1f401cd755856fe","hand|card_4":"d634fc537a1de9bf73f2a74480de9a13","hand|card_7":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_9":"d9dccd7e156b95a9c8063c1bfcd9901d","posture|415624d6":"c068e1c3526291d1cddfb6cfce8891a4","posture|99cbd16f":"893f5abd33222c88851a76cdbd17f95e","posture|b7ae54f1":"b2ab8c5543f2ef0dee335d72d9383b8f","surrender|44136fa3":"be8c1cda992e77565be9e8d4c859f37a","wall_move|3c876c16":"cb750472dd2c00db35c4a8096ff7ae20","wall_move|8d07fe3f":"92135c9b7739223dd37b80192ffe4dd6"},
 "battle:26":{"attack|08fca583":"6fc557d137f0980f6469cff113cf059f","attack|0c0c7bd1":"ec60867ee6befbea6b04befac9d3b2e4","attack|113750c3":"187dd276d48337c9351f73f86651a8cf","attack|2c270d2a":"a388e0c26f0abf0f4c96743da1b57a1a","attack|52271fb5":"f7342cf5520c97bee4425ed69ab7d2df","attack|52fc0492":"c31235bb26bba9b7db939b7f1b1b0996","attack|576c7b23":"08401c88d053d4aa4e8dd539b3d50abe","attack|57c9f6c8":"732abe3ba841068a101537b8d18e2cc7","attack|6234891c":"fdaa61935e43240f89bbebaba020acda","attack|828e3ba0":"afdfb2a5e743000cb0576e684ac2fdb8","attack|a2e396da":"febd5617f363b273eafd5d718fc10373","attack|d845d27a":"bd728aa7a950c3e6b3c9516b86ffe9b6","attack|e01afa84":"a7ce455637c28c61542c83891e079be3","attack|e271ef98":"4c3628ce5c4d941f517e2a0398e8e512","attack|e8b9ed92":"beb6d0508599c0026a617aff36c2bd10","attack|edbfd60b":"187dd276d48337c9351f73f86651a8cf","attack|f1466260":"86dafa295a7c4d4388009121f3446110","attack|fd8648f7":"f5972417ee2f3f33a859b8e0d8dbd553","calm|44136fa3":"41ea03020ea2e37ff17b9aa376452480","end|44136fa3":"669b85ed16826d266af4864f98c18aff","hand|card_1":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_10":"6a43699b10926047d1f401cd755856fe","hand|card_4":"d634fc537a1de9bf73f2a74480de9a13","hand|card_7":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_9":"d9dccd7e156b95a9c8063c1bfcd9901d","posture|415624d6":"c068e1c3526291d1cddfb6cfce8891a4","posture|99cbd16f":"893f5abd33222c88851a76cdbd17f95e","posture|b7ae54f1":"b2ab8c5543f2ef0dee335d72d9383b8f","surrender|44136fa3":"be8c1cda992e77565be9e8d4c859f37a","wall_move|3c876c16":"cb750472dd2c00db35c4a8096ff7ae20","wall_move|8d07fe3f":"92135c9b7739223dd37b80192ffe4dd6"},
 "battle:44":{"attack|08fca583":"6fc557d137f0980f6469cff113cf059f","attack|0c0c7bd1":"ec60867ee6befbea6b04befac9d3b2e4","attack|113750c3":"187dd276d48337c9351f73f86651a8cf","attack|2c270d2a":"4369f312c78ee15fb41002b26d1e3b4f","attack|52271fb5":"f7342cf5520c97bee4425ed69ab7d2df","attack|52fc0492":"c31235bb26bba9b7db939b7f1b1b0996","attack|576c7b23":"08401c88d053d4aa4e8dd539b3d50abe","attack|57c9f6c8":"732abe3ba841068a101537b8d18e2cc7","attack|6234891c":"fdaa61935e43240f89bbebaba020acda","attack|828e3ba0":"bdcd892e2dbb67f40cf741789e2531a8","attack|a2e396da":"febd5617f363b273eafd5d718fc10373","attack|d845d27a":"bd728aa7a950c3e6b3c9516b86ffe9b6","attack|e01afa84":"a7ce455637c28c61542c83891e079be3","attack|e271ef98":"4c3628ce5c4d941f517e2a0398e8e512","attack|e8b9ed92":"beb6d0508599c0026a617aff36c2bd10","attack|edbfd60b":"187dd276d48337c9351f73f86651a8cf","attack|f1466260":"86dafa295a7c4d4388009121f3446110","attack|fd8648f7":"f5972417ee2f3f33a859b8e0d8dbd553","calm|44136fa3":"41ea03020ea2e37ff17b9aa376452480","end|44136fa3":"669b85ed16826d266af4864f98c18aff","hand|card_1":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_10":"6a43699b10926047d1f401cd755856fe","hand|card_4":"d634fc537a1de9bf73f2a74480de9a13","hand|card_7":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_9":"d9dccd7e156b95a9c8063c1bfcd9901d","posture|415624d6":"c068e1c3526291d1cddfb6cfce8891a4","posture|99cbd16f":"893f5abd33222c88851a76cdbd17f95e","posture|b7ae54f1":"b2ab8c5543f2ef0dee335d72d9383b8f","surrender|44136fa3":"be8c1cda992e77565be9e8d4c859f37a","wall_move|3c876c16":"cb750472dd2c00db35c4a8096ff7ae20","wall_move|8d07fe3f":"92135c9b7739223dd37b80192ffe4dd6"},
 "prepare:0":{"calm|44136fa3":"22f22bd5655c18cf140d6b62a6d553c0","end|44136fa3":"ccf506b0f535604ecfd0b85263063020","finish_prepare|44136fa3":"16e153aaa7bcde7b75927b5313c20f3b","hand|card_2":"b6c18d758f81d807b1e6082e625c5efb","hand|card_3":"2cef93ec87602eca7a69f21b2dd03bfe","hand|card_4":"b6c18d758f81d807b1e6082e625c5efb","hand|card_5":"2cef93ec87602eca7a69f21b2dd03bfe","hand|card_6":"b6c18d758f81d807b1e6082e625c5efb","posture|415624d6":"2dd0890dd2101b22bb642e55937056c0","posture|99cbd16f":"f19cc76fdf4e9eddc9289705ea7c699b","posture|b7ae54f1":"1ba4b0f2263a41546ccdefde8482bf31","wall_move|3c876c16":"5f366e62149218c26561a0c838ac79ff","wall_move|8d07fe3f":"57383e77989ec6113b5bcd39b30ae430"},
 "prepare:12":{"calm|44136fa3":"41ea03020ea2e37ff17b9aa376452480","end|44136fa3":"ccf506b0f535604ecfd0b85263063020","finish_prepare|44136fa3":"16e153aaa7bcde7b75927b5313c20f3b","hand|card_2":"d634fc537a1de9bf73f2a74480de9a13","hand|card_3":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_4":"d634fc537a1de9bf73f2a74480de9a13","hand|card_5":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_6":"d634fc537a1de9bf73f2a74480de9a13","posture|415624d6":"c068e1c3526291d1cddfb6cfce8891a4","posture|99cbd16f":"893f5abd33222c88851a76cdbd17f95e","posture|b7ae54f1":"b2ab8c5543f2ef0dee335d72d9383b8f","wall_move|3c876c16":"cb750472dd2c00db35c4a8096ff7ae20","wall_move|8d07fe3f":"92135c9b7739223dd37b80192ffe4dd6"},
 "prepare:26":{"calm|44136fa3":"41ea03020ea2e37ff17b9aa376452480","end|44136fa3":"ccf506b0f535604ecfd0b85263063020","finish_prepare|44136fa3":"16e153aaa7bcde7b75927b5313c20f3b","hand|card_2":"d634fc537a1de9bf73f2a74480de9a13","hand|card_3":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_4":"d634fc537a1de9bf73f2a74480de9a13","hand|card_5":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_6":"d634fc537a1de9bf73f2a74480de9a13","posture|415624d6":"c068e1c3526291d1cddfb6cfce8891a4","posture|99cbd16f":"893f5abd33222c88851a76cdbd17f95e","posture|b7ae54f1":"b2ab8c5543f2ef0dee335d72d9383b8f","wall_move|3c876c16":"cb750472dd2c00db35c4a8096ff7ae20","wall_move|8d07fe3f":"92135c9b7739223dd37b80192ffe4dd6"},
 "prepare:44":{"calm|44136fa3":"41ea03020ea2e37ff17b9aa376452480","end|44136fa3":"ccf506b0f535604ecfd0b85263063020","finish_prepare|44136fa3":"16e153aaa7bcde7b75927b5313c20f3b","hand|card_2":"d634fc537a1de9bf73f2a74480de9a13","hand|card_3":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_4":"d634fc537a1de9bf73f2a74480de9a13","hand|card_5":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_6":"d634fc537a1de9bf73f2a74480de9a13","posture|415624d6":"c068e1c3526291d1cddfb6cfce8891a4","posture|99cbd16f":"893f5abd33222c88851a76cdbd17f95e","posture|b7ae54f1":"b2ab8c5543f2ef0dee335d72d9383b8f","wall_move|3c876c16":"cb750472dd2c00db35c4a8096ff7ae20","wall_move|8d07fe3f":"92135c9b7739223dd37b80192ffe4dd6"},
 "rest:0":{"calm|44136fa3":"22f22bd5655c18cf140d6b62a6d553c0","end|44136fa3":"ccf506b0f535604ecfd0b85263063020","finish_rest|44136fa3":"080e941244f81ab6fb9b5f4aeaf3ae69","hand|card_1":"e490995e413e23d65606cc925a4cdd61","hand|card_10":"bb2d9be540a8cb6ec4c2713e85fde8e4","hand|card_4":"3c12bac8e29d0304432814eeea7b4d52","hand|card_7":"e490995e413e23d65606cc925a4cdd61","hand|card_9":"5d2f81969b0798537bc18a05cc83ff4f","posture|415624d6":"2dd0890dd2101b22bb642e55937056c0","posture|99cbd16f":"f19cc76fdf4e9eddc9289705ea7c699b","posture|b7ae54f1":"1ba4b0f2263a41546ccdefde8482bf31","wall_move|3c876c16":"5f366e62149218c26561a0c838ac79ff","wall_move|8d07fe3f":"57383e77989ec6113b5bcd39b30ae430"},
 "rest:12":{"calm|44136fa3":"41ea03020ea2e37ff17b9aa376452480","end|44136fa3":"ccf506b0f535604ecfd0b85263063020","finish_rest|44136fa3":"080e941244f81ab6fb9b5f4aeaf3ae69","hand|card_1":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_10":"6a43699b10926047d1f401cd755856fe","hand|card_4":"d634fc537a1de9bf73f2a74480de9a13","hand|card_7":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_9":"d9dccd7e156b95a9c8063c1bfcd9901d","posture|415624d6":"c068e1c3526291d1cddfb6cfce8891a4","posture|99cbd16f":"893f5abd33222c88851a76cdbd17f95e","posture|b7ae54f1":"b2ab8c5543f2ef0dee335d72d9383b8f","wall_move|3c876c16":"cb750472dd2c00db35c4a8096ff7ae20","wall_move|8d07fe3f":"92135c9b7739223dd37b80192ffe4dd6"},
 "rest:26":{"calm|44136fa3":"41ea03020ea2e37ff17b9aa376452480","end|44136fa3":"ccf506b0f535604ecfd0b85263063020","finish_rest|44136fa3":"080e941244f81ab6fb9b5f4aeaf3ae69","hand|card_1":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_10":"6a43699b10926047d1f401cd755856fe","hand|card_4":"d634fc537a1de9bf73f2a74480de9a13","hand|card_7":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_9":"d9dccd7e156b95a9c8063c1bfcd9901d","posture|415624d6":"c068e1c3526291d1cddfb6cfce8891a4","posture|99cbd16f":"893f5abd33222c88851a76cdbd17f95e","posture|b7ae54f1":"b2ab8c5543f2ef0dee335d72d9383b8f","wall_move|3c876c16":"cb750472dd2c00db35c4a8096ff7ae20","wall_move|8d07fe3f":"92135c9b7739223dd37b80192ffe4dd6"},
 "rest:44":{"calm|44136fa3":"41ea03020ea2e37ff17b9aa376452480","end|44136fa3":"ccf506b0f535604ecfd0b85263063020","finish_rest|44136fa3":"080e941244f81ab6fb9b5f4aeaf3ae69","hand|card_1":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_10":"6a43699b10926047d1f401cd755856fe","hand|card_4":"d634fc537a1de9bf73f2a74480de9a13","hand|card_7":"a227f1b4f8ca3f81c9adde7512fec8de","hand|card_9":"d9dccd7e156b95a9c8063c1bfcd9901d","posture|415624d6":"c068e1c3526291d1cddfb6cfce8891a4","posture|99cbd16f":"893f5abd33222c88851a76cdbd17f95e","posture|b7ae54f1":"b2ab8c5543f2ef0dee335d72d9383b8f","wall_move|3c876c16":"cb750472dd2c00db35c4a8096ff7ae20","wall_move|8d07fe3f":"92135c9b7739223dd37b80192ffe4dd6"},
}

# 显示点的显示文本字段（与基线同一取数口径：标签、费用、可用性、原因、风险、短文案、部位、施法、详情）。
static func r3_point_fields(c: Dictionary) -> Array:
 var casting=c.get("casting",{})
 return [String(c.label),str(c.cost),str(c.mana),str(c.valid),String(c.reason),String(c.risk),String(c.get("brief","")),String(c.get("brief_tags","")),String(c.get("body_part","")),str(casting.get("percent","")),str(casting.get("formula","")),String(c.get("detail",""))]

# 本批删边的核对面（docs/spec/candidate-removal.md「接口」显示消费；机读面＝tests/display_ui_cases.gd::r3_display_points_do_not_read_rows）：手牌／行动／姿态／墙面／底栏域的
# 显示读只经显示事实，不再在点名函数里按 payload 字段取候选行。域外显示点（练习／捕获／路线／身体／道具／
# 拖放等）本批不动，仍按行读，故按函数点名核对而不是全文件扫描。
const R3_DISPLAY_POINTS={
 "_build_action_rail":["attack","pressure"],
 "_posture_layout":["wall_move"],
 "_posture_controls":["posture"],
 "_wall_controls":["wall_move","posture"],
 "_bottom_controls":["flow","surrender"],
 "_hand_choice":["card"],
}

static func r3_display_points_do_not_read_rows(t) -> void:
 var handle=FileAccess.open("res://ui/main.gd",FileAccess.READ)
 var declaration=RegEx.new()
 var slash=String.chr(92)
 declaration.compile("^"+slash+"s*func"+slash+"s+([A-Za-z_][A-Za-z0-9_]*)")
 var offenders=[]
 var current=""
 var text="" if handle==null else handle.get_as_text()
 for line in text.split(String.chr(10)):
  var code=String(line).split("#")[0]
  var declared=declaration.search(code)
  if declared!=null: current=declared.get_string(1)
  if not R3_DISPLAY_POINTS.has(current): continue
  if not (code.contains("actions.select(") or code.contains("actions.find(")): continue
  for group in R3_DISPLAY_POINTS[current]:
   if code.contains(String.chr(34)+group+String.chr(34)): offenders.append(current+" "+code.strip_edges())
 t.check(offenders.is_empty(),"G5 display_facts_match_determination: the R3 display points read display facts instead of candidate rows: "+str(offenders.slice(0,3)))

static func r3_point_key(g, payload: Dictionary) -> String:
 var kind=String(payload.get("kind",""))
 return kind+"|"+JSON.stringify(g.command_params(kind,payload)).sha256_text().substr(0,8)

# 判定参考（docs/spec/candidate-removal.md「接口」唯一合法性判定）：唯一判定对同一显示点输入的重算。原始输入来自
# core/game.gd::command_facts（未合并判定的事实），投影来自 view.display_facts；接管锁定的显示点在接管期内
# 的结论由接管锁给出（G8 覆盖面），此处按其锁结论核对。
static func r3_determination_mismatches(g, view: Dictionary, groups: Array) -> Array:
 var queries=preload("res://ui/target_queries.gd")
 var raw={}
 for f in g._fact_source(): raw[g.shape_key(f.payload)]=f
 var lock=g.eligibility_takeover()
 var chosen=""
 for f in view.display_facts:
  if bool(f.get("automated",false)): chosen=String(queries.fact_key(f))
 var mismatches=[]
 for group in groups:
  for f in queries.facts(view,group):
   var key=g.shape_key(f.payload)
   var source=raw.get(key,{})
   if source.is_empty():
    mismatches.append("no source fact for "+key)
    continue
   var verdict=g.eligibility(source.payload,source.get("cost",0),source.get("mana",0.0),String(source.get("source_reason","")),String(source.get("risk","")))
   if not lock.is_empty() and String(queries.fact_key(f))!=chosen: verdict=lock
   for field in ["valid","reason","risk","cost","mana"]:
    if f.get(field)!=verdict.get(field): mismatches.append(key+"."+field+" fact="+str(f.get(field))+" determination="+str(verdict.get(field)))
   if JSON.stringify(f.get("mana_payment",{}))!=JSON.stringify(verdict.get("mana_payment",{})): mismatches.append(key+".mana_payment fact="+JSON.stringify(f.get("mana_payment",{}))+" determination="+JSON.stringify(verdict.get("mana_payment",{})))
 return mismatches

static func display_facts_match_determination(t) -> void:
 var queries=preload("res://ui/target_queries.gd")
 for cell in R3_G5_CELLS:
  var name="%s:%d" % [cell[0],cell[1]]
  var g=Cases.r1_build(cell[0],cell[1])
  var view=g.get_view()
  var points={}
  var mismatches=r3_determination_mismatches(g,view,["attack","pressure","flow","surrender","posture","wall_move","card","prison"])
  for group in ["attack","pressure","flow","surrender","posture","wall_move"]:
   for f in queries.facts(view,group): points[r3_point_key(g,f.payload)]=r3_point_fields(f)
  for card in view.hand:
   points["hand|"+String(card.uid)]=[JSON.stringify(card.availability),String(card.bound),String(card.free),String(card.cost)]
  t.check(mismatches.is_empty(),"G5 display_facts_match_determination: every display fact equals the single determination for the same shape ("+name+"): "+str(mismatches.slice(0,3)))
  var expected=R3_G5_BASELINE.get(name,{})
  var problems=[]
  for key in points:
   var digest=JSON.stringify(points[key]).sha256_text().substr(0,32)
   if expected.get(key,"")!=digest: problems.append(key+" baseline="+str(expected.get(key,""))+" current="+digest)
  for key in expected:
   if not points.has(key): problems.append(key+" missing")
  t.check(problems.is_empty(),"G5 display_facts_match_determination: display text equals the unmodified-source baseline ("+name+"): "+str(problems.slice(0,3)))

# docs/spec/candidate-removal.md「接口」判据真源（r4_display_points_do_not_read_rows；批 R4 的装备／快捷解除／拖放／道具域）。
# 夹具与 R3 相同，并补上商店／事件／监狱（该节 Given 的其余阶段）。文本基线在未改源码上复算后冻结。
# 冻结基线的前缀（View 键名）；事实组名由 R4_POINT_GROUPS 声明。
const R4_FACT_GROUPS=["equipment","hooks","items","chain","retain"]
const R4_G5_CELLS=[["battle",0],["battle",12],["battle",26],["battle",44],["prepare",0],["prepare",12],["prepare",26],["prepare",44],["rest",0],["rest",12],["rest",26],["rest",44],["shop",0],["shop",12],["shop",26],["shop",44],["event",0],["event",12],["event",26],["event",44],["prison",0],["prison",12],["prison",26],["prison",44]]
const R4_G5_BASELINE={
 "battle:0":"cd11601cef15dee6221c6b67194dc3f5","battle:12":"dc76ae993b1ece44d0e6dbc6fa3489b4","battle:26":"747f1f340aa4a487bb4a6e3859734ce1","battle:44":"c8245d8251be3248813419d915e27f0d",
 "prepare:0":"4686740a193e4ccc3949dabddf08d22c","prepare:12":"79c6856820354267857b66fd23bef424","prepare:26":"5585eedfffa067602b30a044b0784ec8","prepare:44":"bd5c73996249d50ec0f2279c5b5e0aa0",
 "rest:0":"88bb205f9ffc3093160531e9fee2b42f","rest:12":"62f2f96078c1a53ccf59789b61754431","rest:26":"76cf5608dc0c0ea0d6f1c25374667e3b","rest:44":"3b6385ebe71ab599b63d02c6a57c549b",
 "shop:0":"e3b0c44298fc1c149afbf4c8996fb924","shop:12":"e3b0c44298fc1c149afbf4c8996fb924","shop:26":"e3b0c44298fc1c149afbf4c8996fb924","shop:44":"e3b0c44298fc1c149afbf4c8996fb924",
 "event:0":"e3b0c44298fc1c149afbf4c8996fb924","event:12":"e3b0c44298fc1c149afbf4c8996fb924","event:26":"e3b0c44298fc1c149afbf4c8996fb924","event:44":"e3b0c44298fc1c149afbf4c8996fb924",
 "prison:0":"9ace64537bb8d66433e1b8282826f18b","prison:12":"455261e120f7e7baee46523ec5ba40c0","prison:26":"db91e6b5ccec79b4c6085c7ab7c45449","prison:44":"0d164eed90414ba73198c3d0de0c7a4e",
}
const R4_ROW_FREE_FUNCTIONS={
 "res://ui/main.gd":["_equipment_actions","_attack_drop_candidate","_item_details","_door_candidate","_free_player_candidate","_hook_drawer","_guard_bind_card_candidate","_chain_screen"],
}

# R4 点面：View 键名（冻结基线的前缀）→ 事实组名（事实自带的 group 字段）。
const R4_POINT_GROUPS=[["equipment","manual"],["hooks","hook"],["items","item"],["chain","chain"],["retain","retain"]]

static func r4_entries(view: Dictionary, group: String) -> Array:
 return preload("res://ui/target_queries.gd").facts(view,group)

static func r4_points(g, view: Dictionary) -> Dictionary:
 var queries=preload("res://ui/target_queries.gd")
 var points={}
 for pair in R4_POINT_GROUPS:
  for f in r4_entries(view,pair[1]):
   points[pair[0]+"|"+r3_point_key(g,f.payload)]=r3_point_fields(f)
 for f in r4_entries(view,"card"):
  if not (String(f.payload.get("mode","")) in queries.RELEASE_MODES): continue
  points["release|"+r3_point_key(g,f.payload)]=[String(f.label),str(f.valid),String(f.reason),str(f.cost),str(f.mana)]
 for item in view.items:
  points["itemview|"+String(item.id)]=[JSON.stringify(item.get("unavailable_reasons",[])),JSON.stringify(item.get("target_groups",[]))]
 return points

static func r4_digest(points: Dictionary) -> String:
 var keys=points.keys()
 keys.sort()
 var lines=[]
 for key in keys: lines.append(String(key)+"="+JSON.stringify(points[key]))
 return "\n".join(lines).sha256_text().substr(0,32)

static func r4_fact_mismatches(g, view: Dictionary) -> Array:
 var queries=preload("res://ui/target_queries.gd")
 var mismatches=r3_determination_mismatches(g,view,["manual","hook","item","chain","retain","card","service","event","prison","route","reward","relic","flask","status_toggle","rest_service","departure","demo_exit"])
 return mismatches

static func r4_display_points_do_not_read_rows(t) -> void:
 var declaration=RegEx.new()
 var slash=String.chr(92)
 declaration.compile("^"+slash+"s*func"+slash+"s+([A-Za-z_][A-Za-z0-9_]*)")
 var offenders=[]
 for path in R4_ROW_FREE_FUNCTIONS:
  var handle=FileAccess.open(path,FileAccess.READ)
  var text="" if handle==null else handle.get_as_text()
  var current=""
  var watched=R4_ROW_FREE_FUNCTIONS[path]
  for line in text.split(String.chr(10)):
   var code=String(line).split("#")[0]
   var declared=declaration.search(code)
   if declared!=null: current=declared.get_string(1)
   if not (current in watched): continue
   if code.contains("actions.select(") or code.contains("actions.find(") or code.contains("actions.first_usable(") or code.contains("actions.by_id"):
    offenders.append(path+" "+current)
 var keyboard=FileAccess.open("res://ui/keyboard_input.gd",FileAccess.READ)
 var keyboard_text="" if keyboard==null else keyboard.get_as_text()
 if keyboard_text.contains("host.actions"): offenders.append("ui/keyboard_input.gd host.actions")
 for path in ["res://ui/quick_release_bar.gd","res://ui/drag_targets.gd"]:
  var reader=FileAccess.open(path,FileAccess.READ)
  var body="" if reader==null else reader.get_as_text()
  if body.contains("ui.actions") or body.contains(".actions.select") or body.contains(".actions.find"): offenders.append(path)
 var queries=FileAccess.open("res://ui/target_queries.gd",FileAccess.READ)
 var query_text="" if queries==null else queries.get_as_text()
 if query_text.contains(".by_id") or query_text.contains("Action"+"Index"): offenders.append("ui/target_queries.gd row index")
 t.check(offenders.is_empty(),"G5 display_facts_match_determination: R4 display points read display facts instead of candidate rows: "+str(offenders.slice(0,4)))

static func r4_display_facts_match_determination(t) -> void:
 for cell in R4_G5_CELLS:
  var name="%s:%d" % [cell[0],cell[1]]
  var g=Cases.r1_build(cell[0],cell[1])
  var view=g.get_view()
  var mismatches=r4_fact_mismatches(g,view)
  t.check(mismatches.is_empty(),"G5 display_facts_match_determination: every R4 display fact equals the single determination for the same shape ("+name+"): "+str(mismatches.slice(0,3)))
  var digest=r4_digest(r4_points(g,view))
  var expected=String(R4_G5_BASELINE.get(name,""))
  t.check(expected!="" and expected==digest,"G5 display_facts_match_determination: R4 display text equals the unmodified-source baseline ("+name+"): baseline="+expected+" current="+digest)

static func choose(t, name: String, index: int) -> void:
 var picker=t.ui.find_child(name,true,false)
 t.check(picker!=null and not picker.disabled,"DISPLAY enabled selector "+name)
 if picker==null or picker.disabled: return
 picker.select(index);picker.item_selected.emit(index)
 await t.frames(10)

static func portrait_snapshot_boundary(t) -> void:
 var ui=t.ui
 var saved_fixed=ui.display_settings.fixed_hero_portrait
 var saved_character=ui.selected_character
 ui.display_settings.fixed_hero_portrait=false
 ui.selected_character="original";ui.restart(42);await t.frames()
 var original_game=ui.game;var original_view=ui.view
 var original_state=original_game.export_snapshot()
 ui.selected_character="witch";ui.restart(42);await t.frames()
 var witch_game=ui.game;var witch_view=ui.view
 var witch_state=witch_game.export_snapshot()
 var witch_hero=ui.find_child("HeroArt",true,false)
 var witch_sidebar=ui.find_child("EquipmentPortrait",true,false)
 t.check(not witch_hero.fixed_portrait and not witch_sidebar.fixed_portrait and witch_hero.get_node("HeroPose").texture==Art.WITCH_POSES[witch_view.posture] and witch_sidebar.texture==Portrait.WITCH_SIDEBAR,"DISPLAY witch snapshot selects its posture art and narrow sidebar crop in both scenes")
 # Render a detached snapshot while the authoritative game is a different character.
 # Neither portrait may call live character rules behind that snapshot.
 ui.render(original_view);await t.frames()
 t.check(not ui.find_child("HeroArt",true,false).fixed_portrait and not ui.find_child("EquipmentPortrait",true,false).fixed_portrait,"DISPLAY original snapshot controls both portraits even while live game is witch")
 ui.display_settings.fixed_hero_portrait=true;ui.render(original_view);await t.frames()
 t.check(ui.find_child("HeroArt",true,false).fixed_portrait and ui.find_child("EquipmentPortrait",true,false).fixed_portrait,"DISPLAY explicit fixed preference still overrides original snapshot in both scenes")
 ui.display_settings.fixed_hero_portrait=false;ui.game=original_game;ui.render(witch_view);await t.frames()
 witch_hero=ui.find_child("HeroArt",true,false);witch_sidebar=ui.find_child("EquipmentPortrait",true,false)
 t.check(not witch_hero.fixed_portrait and not witch_sidebar.fixed_portrait and witch_hero.get_node("HeroPose").texture==Art.WITCH_POSES[witch_view.posture] and witch_sidebar.texture==Portrait.WITCH_SIDEBAR,"DISPLAY witch snapshot controls both character-specific portraits even while live game is original")
 t.check(original_game.export_snapshot()==original_state and witch_game.export_snapshot()==witch_state,"DISPLAY snapshot rendering and preferences do not change either game's state or random domains")
 ui.display_settings.fixed_hero_portrait=saved_fixed;ui.selected_character=saved_character
 ui.restart(42);await t.frames()

static func portrait_composite_boundary(t) -> void:
 var ui=t.ui
 var saved_fixed=ui.display_settings.fixed_hero_portrait
 ui.display_settings.fixed_hero_portrait=false
 for practice in ["glove_short","glove_long"]:
  ui.game=preload("res://tests/game_fixture.gd").new(42,true,practice)
  var before=ui.game.export_snapshot()
  ui.render();await t.frames()
  var hero=ui.find_child("HeroArt",true,false)
  var sidebar=ui.find_child("EquipmentPortrait",true,false)
  t.check(hero.hero_sprite is Portrait and hero.hero_sprite.texture==sidebar.texture and sidebar.texture==Portrait.BOUND_SINGLE_GLOVE,"DISPLAY composite portrait reaches both arena and sidebar: "+practice)
  t.check(hero.hero_sprite.active_composite_layers==["single_glove"] and hero.hero_sprite.get_node("Overlay_thigh_root").texture==Portrait.SINGLE_GLOVE_THIGH.free,"DISPLAY arena retains composite layer and matching slice: "+practice)
  var exposed=ui.view.duplicate(true)
  var retained=Portrait.snapshot(exposed)
  exposed.composite_portrait_layers.clear();exposed.body_coverage.clear();exposed.bodies[0].occupied=not exposed.bodies[0].occupied
  t.check(retained==Portrait.snapshot(ui.view) and not retained.has("facts") and ui.game.export_snapshot()==before,"DISPLAY retained appearance is detached from mutable input and does not retain gameplay facts: "+practice)
 ui.display_settings.fixed_hero_portrait=saved_fixed;ui.restart(42);await t.frames()

static func portrait_refresh(t) -> void:
 var ui=t.ui
 ui.restart(20260906);await t.frames(8)
 var before=ui.game.export_snapshot()
 var hero=ui.find_child("HeroArt",true,false)
 var equipment=ui.find_child("EquipmentPortrait",true,false)
 var enemy=ui.find_child("EnemyArt_*",true,false)
 var layout_id=ui.layout.get_instance_id()
 var sprite=hero.hero_sprite
 var draws=[0,0,0]
 hero.draw.connect(func():draws[0]+=1)
 equipment.draw.connect(func():draws[1]+=1)
 enemy.draw.connect(func():draws[2]+=1)
 await t.frames(8)
 draws.assign([0,0,0])
 for count in range(3):
  ui.render(ui.view)
  await t.frames(3)
 t.check(ui.layout.get_instance_id()==layout_id,"DISPLAY scene root persists across ordinary view refreshes")
 t.check(ui.find_child("HeroArt",true,false)==hero and hero.hero_sprite==sprite,"DISPLAY unchanged hero keeps its arena and sprite instances")
 t.check(ui.find_child("EquipmentPortrait",true,false)==equipment and ui.find_child("EnemyArt_*",true,false)==enemy,"DISPLAY equipment and enemy portrait instances survive UI refreshes")
 t.check(draws==[0,0,0],"DISPLAY unrelated UI refreshes do not redraw portraits")
 t.check(not hero.is_processing() and not enemy.is_processing(),"DISPLAY portraits have no idle frame callbacks")
 t.check(ui.game.export_snapshot()==before,"DISPLAY retained scenes never mutate game state")
 # The procedural fallback must also stay idle (not just texture-backed enemies).
 var fallback=preload("res://ui/elements/arena.tscn").instantiate()
 fallback.mode="six_bind";fallback.size=Vector2(240,288)
 ui.add_child(fallback)
 var fallback_draws=[0]
 fallback.draw.connect(func():fallback_draws[0]+=1)
 await t.frames(8);fallback_draws[0]=0
 await t.frames(12)
 t.check(fallback_draws[0]==0 and not fallback.is_processing(),"DISPLAY procedural enemy portrait does not redraw every frame")
 ui.remove_child(fallback);fallback.queue_free()
 var changed=ui.view.duplicate(true)
 changed.posture="sit"
 hero.configure_hero(changed,false);await t.frames(3)
 t.check(hero.pose=="sit" and hero.hero_sprite.texture==preload("res://ui/pixel_art.gd").hero_texture("sit",ui.view.has_restraint_level),"DISPLAY posture changes update the existing hero scene")
 hero.configure_hero(ui.view,false);await t.frames(3)
 t.check(hero.pose==ui.view.posture,"DISPLAY restoring the pose restores the retained portrait")
 hero.configure_hero(ui.view,true);equipment.configure(ui.view,true);await t.frames(4)
 draws.assign([0,0,0])
 hero.configure_hero(changed,true);equipment.configure(changed,true);await t.frames(4)
 t.check(draws[0]==0 and draws[1]==0,"DISPLAY fixed portraits ignore posture changes that cannot alter their image")
 hero.configure_hero(ui.view,false);equipment.configure(ui.view,false);await t.frames(4)
 draws.assign([0,0,0])
 ui.display_settings.art_changed.emit("cards",enemy.template)
 ui.display_settings.art_changed.emit("enemies","unrelated_enemy")
 await t.frames(3)
 t.check(draws[2]==0,"DISPLAY unrelated art imports do not invalidate this enemy")
 var enemy_node=enemy.get_instance_id()
 ui.display_settings.art_changed.emit("enemies",enemy.template)
 await t.frames(3)
 t.check(enemy.get_instance_id()==enemy_node and draws[2]>0,"DISPLAY matching art imports refresh the existing enemy scene")

static func sidebar_refresh(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.selected_slot="region_upper";ui.show_body=true;ui.render(ui.view);await t.frames(5)
 var panel=ui.find_child("BodyEquipmentPanel",true,false)
 panel.size.y=300;await t.frames(5)
 var scroll=panel.find_child("BodyRegionContent_region_upper",true,false)
 scroll.scroll_vertical=40;await t.frames(3)
 var offset=scroll.scroll_vertical
 var header=ui.body_buttons.region_upper
 var header_text=header.text
 var scroll_height=scroll.size.y
 var wrist=ui.body_buttons.wrist
 var before=ui.game.export_snapshot()
 t.check(offset>0,"DISPLAY sidebar fixture has real scrollable overflow")
 for count in range(3):
  ui.render(ui.view);await t.frames(3)
 t.check(ui.body_buttons.region_upper==header and ui.body_buttons.wrist==wrist,"DISPLAY unchanged body controls retain their instances and input index")
 scroll=panel.find_child("BodyRegionContent_region_upper",true,false)
 t.check(scroll.scroll_vertical==offset,"DISPLAY ordinary refresh preserves the scrolled body region")
 t.check(ui.game.export_snapshot()==before,"DISPLAY cached body presentation does not mutate gameplay")
 # Same visible facts in a fresh view must not depend on dictionary identity.
 ui.render(ui.view.duplicate(true));await t.frames(3)
 t.check(ui.body_buttons.wrist==wrist,"DISPLAY equivalent fresh projection retains body controls")
 ui.localization.set_locale("en_US");ui.render(ui.view);await t.frames(5)
 t.check(ui.body_buttons.region_upper.text!=header_text and not ui.body_buttons.region_upper.text.contains("手胸"),"DISPLAY body labels update when language changes")
 ui.localization.set_locale("zh_CN");ui.render(ui.view);await t.frames(5)
 t.check(ui.body_buttons.region_upper.text.contains("手胸"),"DISPLAY retained sidebar returns to Chinese without stale translated labels")
 var old_count=ui.view.body_regions.filter(func(region):return region.id=="region_upper")[0].count
 ui.game.add_fixture("upper_arm",4,10);ui.render();await t.frames(5)
 var new_count=ui.view.body_regions.filter(func(region):return region.id=="region_upper")[0].count
 t.check(new_count>old_count and ui.body_buttons.region_upper.text.contains(str(new_count)),"DISPLAY equipment changes invalidate the body count")
 ui.selected_slot="wrist";ui.render(ui.view);await t.frames(3)
 t.check(ui.body_buttons.wrist.get_theme_stylebox("hover").border_color==ui.CYAN,"DISPLAY inspection focus refreshes body selection styles")
 panel.size.y=512;await t.frames(5)
 t.check(panel.find_child("BodyRegionContent_region_upper",true,false).size.y>scroll_height,"DISPLAY resized body panel recalculates its visible region")

class GetViewCountingGame extends "res://tests/game_fixture.gd":
 var get_view_calls=0
 func get_view() -> Dictionary:
  get_view_calls+=1
  return super.get_view()

class SubmitCountingGame extends GetViewCountingGame:
 var last_result={}
 func dispatch(cmd: Dictionary, expected_version: int) -> Dictionary:
  last_result=super.dispatch(cmd,expected_version)
  return last_result

class SubmitSaveProbe extends RefCounted:
 var writes=0
 func write_game(_game, _replace=false, _drawings={}) -> Dictionary:
  writes+=1
  return {"ok":true,"message":""}

class SubmitFeedbackProbe extends "res://ui/resource_feedback.gd":
 var calls=0
 var presented_version=-1
 func enqueue(events: Array, point: Vector2, instant_fields: Array=[]) -> void:
  calls+=1
  presented_version=host.view.version
  super.enqueue(events,point,instant_fields)

# Given a mounted battle, when local/full presentation and real submissions run,
# then node identity, committed projection, and success-only side effects agree.
static func submit_presents_local_dirty_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(ui.view.phase=="battle" and not ui.show_home and not ui.show_route and not ui.show_log and not ui.view.pressure.overloaded and not ui._takeover_locked() and not ui._selecting_hand() and ui.notice=="","SUBMIT PRESENT fixture is an ordinary mounted battle")
 var counting=SubmitCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"SUBMIT PRESENT counting game restores the live run")
 ui.game=counting
 # Restore advances version; synchronize once before measuring submissions.
 ui.render(counting.get_view());await t.frames()
 t.check(ui.view.version==counting.state.version,"SUBMIT PRESENT counting baseline uses the restored version")
 var baseline=counting.get_view_calls
 var before=counting.export_snapshot()
 var before_rng=counting.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var hero=ui.find_child("HeroArt",true,false)
 var resources=ui.find_child("MainResourcePanel",true,false)
 var attacks=ui.find_child("AttackActions",true,false)
 ui.present(["header","resources"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header and ui.find_child("HeroArt",true,false)==hero,"SUBMIT PRESENT two local sections preserve header and hero")
 t.check((resources==null or ui.find_child("MainResourcePanel",true,false)==resources) and (attacks==null or ui.find_child("AttackActions",true,false)==attacks),"SUBMIT PRESENT unchanged resource and attack panels retain identity")
 t.check(counting.get_view_calls==baseline,"SUBMIT PRESENT local sections do not fetch a view")
 for dirty in [["*"],["header","not_a_section"],["page"]]:
  var old_header=ui.find_child("GameHeader",true,false).get_instance_id()
  ui.present(dirty);await t.frames()
  t.check(ui.find_child("GameHeader",true,false).get_instance_id()!=old_header,"SUBMIT PRESENT explicit full fallback replaces header: "+str(dirty))
  t.check(counting.get_view_calls==baseline,"SUBMIT PRESENT full fallback uses current view: "+str(dirty))
 t.check(counting.export_snapshot()==before and counting.state.rng==before_rng,"SUBMIT PRESENT read-only presentation preserves snapshot and RNG")
 var usable=ui.view.display_facts.filter(func(c):return c.valid and c.payload.get("kind","")=="attack" and c.payload.get("enemy","")!="")
 t.check(not usable.is_empty(),"SUBMIT PRESENT fixture has a valid enemy attack")
 if usable.is_empty(): return
 var attack=usable[0].duplicate(true)
 var version=ui.view.version
 var energy=ui.view.energy
 header=ui.find_child("GameHeader",true,false)
 hero=ui.find_child("HeroArt",true,false)
 var old_saves=ui.saves
 var old_persistence=ui.persistence_enabled
 var save_probe=SubmitSaveProbe.new()
 ui.saves=save_probe;ui.persistence_enabled=true
 if is_instance_valid(ui.resource_feedback):
  ui.remove_child(ui.resource_feedback);ui.resource_feedback.queue_free()
 var feedback=SubmitFeedbackProbe.new();feedback.host=ui;ui.add_child(feedback);ui.resource_feedback=feedback
 var outcome=ui.command_router.emit("attack",attack,version)
 t.check(outcome.submitted and counting.last_result.ok and feedback.calls==1 and feedback.presented_version==ui.view.version and ui.view.version>version,"SUBMIT PRESENT success feedback runs after the committed view is presented")
 await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header and ui.find_child("HeroArt",true,false)==hero and present_named_live_count(ui,"HeroArt")==1,"SUBMIT PRESENT battle attack preserves header and the single hero")
 var energy_label=ui.find_child("EnergyValue",true,false)
 t.check(ui.view.energy<energy and ui.view.energy==counting.state.energy and energy_label!=null and String(energy_label.text)==ui.game.number(ui.view.energy),"SUBMIT PRESENT attack payment appears in EnergyValue and committed view")
 t.check(counting.get_view_calls==baseline+1 and counting.export_snapshot()!=before and ui.view.version==counting.state.version,"SUBMIT PRESENT attack advances snapshot with exactly one get_view")
 var committed=counting.export_snapshot()
 var committed_rng=counting.state.rng.duplicate(true)
 var writes=save_probe.writes
 var feedback_calls=feedback.calls
 var damage_nodes=ui.find_children("DamageFeedback","",true,false).map(func(node):return node.get_instance_id())
 outcome=ui.command_router.emit("attack",attack,version)
 t.check(outcome.submitted and not counting.last_result.ok and String(counting.last_result.get("checkpoint",""))=="" and save_probe.writes==writes,"SUBMIT PRESENT stale rejection has no checkpoint and does not save")
 t.check(feedback.calls==feedback_calls and ui.find_children("DamageFeedback","",true,false).all(func(node):return node.get_instance_id() in damage_nodes),"SUBMIT PRESENT stale rejection creates no success feedback")
 await t.frames()
 t.check(counting.export_snapshot()==committed and counting.state.rng==committed_rng,"SUBMIT PRESENT stale rejection preserves snapshot and RNG")
 t.check(ui.notice!="" and ui.notice.contains("状态已更新，请重新选择行动。") and ui.notice.contains(String(counting.last_result.error)),"SUBMIT PRESENT stale rejection keeps the verbatim reason")
 t.check(ui.find_child("GameHeader",true,false)==header and counting.get_view_calls==baseline+2,"SUBMIT PRESENT stale rejection preserves header and fetches exactly one view")
 ui.saves=old_saves;ui.persistence_enabled=old_persistence
 ui.restart(42);await t.frames()
 await t.start_practice("StartEquipmentPractice")
 t.check(ui.view.phase!="battle","SUBMIT PRESENT practice reaches a non-battle page")
 var flows=ui.view.display_facts.filter(func(c):return c.valid and c.payload.get("kind","") in ["end","finish_rest"])
 t.check(not flows.is_empty(),"SUBMIT PRESENT non-battle fixture has a legal flow")
 if flows.is_empty(): return
 var old_header=ui.find_child("GameHeader",true,false).get_instance_id()
 version=ui.view.version
 ui.command_router.emit(String(flows[0].payload.kind),flows[0],version);await t.frames()
 t.check(ui.view.version>version and ui.find_child("GameHeader",true,false).get_instance_id()!=old_header,"SUBMIT PRESENT non-battle submission rebuilds the page")

# Given mounted overlays, when a legal battle attack submits, then those overlays unmount.
static func submit_unmounts_closed_overlay_sections(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(ui.view.phase=="battle" and not ui.show_home and not ui.show_route and not ui.show_log and not ui.view.pressure.overloaded and not ui._takeover_locked() and ui.find_child("GameHeader",true,false)!=null,"SUBMIT UNMOUNT hand fixture is a mounted battle")
 var counting=SubmitCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"SUBMIT UNMOUNT hand counting game restores the live run")
 ui.game=counting
 ui.render(counting.get_view());await t.frames()
 t.check(not ui.view.hand.is_empty(),"SUBMIT UNMOUNT hand fixture has a card")
 ui.open_hand_selection({"uid":ui.view.hand[0].uid,"free":false,"target":"","slot":""},ui.view.version);await t.frames()
 t.check(ui._selecting_hand() and ui.find_child("HandSelectionBar",true,false)!=null and ui.find_child("HandTargetCancel",true,false)!=null,"SUBMIT UNMOUNT opens HandSelectionBar before the attack")
 var baseline=counting.get_view_calls
 var usable=ui.view.display_facts.filter(func(c):return c.valid and c.payload.get("kind","")=="attack" and c.payload.get("enemy","")!="")
 t.check(not usable.is_empty(),"SUBMIT UNMOUNT hand fixture has a valid enemy attack")
 if usable.is_empty(): return
 ui.command_router.emit("attack",usable[0].duplicate(true),ui.view.version);await t.frames()
 t.check(ui.find_child("HandSelectionBar",true,false)==null and ui.find_child("HandTargetCancel",true,false)==null,"SUBMIT UNMOUNT attack removes HandSelectionBar and HandTargetCancel")
 t.check(present_named_live_count(ui,"HandSelectionBar")==0 and present_named_live_count(ui,"HandTargetCancel")==0,"SUBMIT UNMOUNT attack leaves no live hand overlay")
 t.check(counting.get_view_calls==baseline+1,"SUBMIT UNMOUNT hand attack fetches exactly one view")
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(ui.view.phase=="battle" and not ui.show_home and not ui.show_route and not ui.show_log and not ui.view.pressure.overloaded and not ui._takeover_locked() and ui.find_child("GameHeader",true,false)!=null,"SUBMIT UNMOUNT details fixture is a mounted battle")
 counting=SubmitCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"SUBMIT UNMOUNT details counting game restores the live run")
 ui.game=counting
 ui.render(counting.get_view());await t.frames()
 ui.selected_slot="wrist";ui.show_body=true;ui.selected_card="";ui.selected_candidate=""
 ui.render(ui.view);await t.frames()
 t.check(ui.find_child("EquipmentDetails",true,false)!=null and ui.find_child("CloseEquipmentDetails",true,false)!=null,"SUBMIT UNMOUNT opens EquipmentDetails before the attack")
 baseline=counting.get_view_calls
 usable=ui.view.display_facts.filter(func(c):return c.valid and c.payload.get("kind","")=="attack" and c.payload.get("enemy","")!="")
 t.check(not usable.is_empty(),"SUBMIT UNMOUNT details fixture has a valid enemy attack")
 if usable.is_empty(): return
 ui.command_router.emit("attack",usable[0].duplicate(true),ui.view.version);await t.frames()
 t.check(ui.find_child("EquipmentDetails",true,false)==null and ui.find_child("CloseEquipmentDetails",true,false)==null,"SUBMIT UNMOUNT attack removes EquipmentDetails and CloseEquipmentDetails")
 t.check(present_named_live_count(ui,"EquipmentDetails")==0 and present_named_live_count(ui,"CloseEquipmentDetails")==0,"SUBMIT UNMOUNT attack leaves no live equipment details")
 t.check(counting.get_view_calls==baseline+1,"SUBMIT UNMOUNT details attack fetches exactly one view")

static func present_visible_slot_names(ui) -> Array:
 var names=[]
 for node in ui.find_children("BodySlot_*","",true,false):
  if node.is_visible_in_tree(): names.append(String(node.name))
 names.sort()
 return names

static func present_expected_slot_names(ui) -> Array:
 var names=[]
 for region in ui.view.body_regions:
  if region.id not in ui.expanded_body_regions: continue
  for body in region.members:
   names.append("BodySlot_"+String(body.id))
 names.sort()
 return names

static func present_routes_body_bar_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.selected_slot="region_upper";ui.show_body=true;ui.render(ui.view);await t.frames(5)
 t.check(String(ui.view.phase)=="battle" and ui.find_child("GameHeader",true,false)!=null and is_instance_valid(ui.layout) and is_instance_valid(ui.layout.body),"DISPLAY present fixture is a battle page with header and body")
 var panel=ui.find_child("BodyEquipmentPanel",true,false)
 panel.size.y=300;await t.frames(5)
 var scroll=panel.find_child("BodyRegionContent_region_upper",true,false)
 scroll.scroll_vertical=40;await t.frames(3)
 t.check(scroll.scroll_vertical>0,"DISPLAY present fixture has real scrollable overflow")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY present counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 panel=ui.find_child("BodyEquipmentPanel",true,false)
 panel.size.y=300;await t.frames(5)
 scroll=panel.find_child("BodyRegionContent_region_upper",true,false)
 scroll.scroll_vertical=40;await t.frames(3)
 var header=ui.find_child("GameHeader",true,false)
 var wrist=ui.body_buttons.wrist
 var offset=scroll.scroll_vertical
 t.check(offset>0 and is_instance_valid(header) and is_instance_valid(wrist),"DISPLAY present baseline has header, wrist control, and overflow")
 var oracle=ui.layout.body._presentation_key(ui)
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.layout.body._presentation_key(ui)==oracle,"DISPLAY present body_bar keeps the body presentation key")
 t.check(ui.find_child("GameHeader",true,false)==header,"DISPLAY present body_bar keeps GameHeader")
 t.check(ui.body_buttons.wrist==wrist,"DISPLAY present body_bar keeps wrist instance")
 t.check(panel.find_child("BodyRegionContent_region_upper",true,false).scroll_vertical==offset,"DISPLAY present body_bar keeps region scroll")
 t.check(counting.get_view_calls==baseline,"DISPLAY present body_bar does not call get_view")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present body_bar end_frame keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present body_bar end_frame keeps enemies")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var wrist_before_mutation=ui.body_buttons.wrist
 var mutated=null
 for region in ui.view.body_regions:
  if region.id!="region_upper": continue
  for body in region.members:
   mutated=body;break
  if mutated!=null: break
 t.check(mutated!=null,"DISPLAY present mutation target exists on the expanded region")
 var new_count=int(mutated.count)+7
 mutated.count=new_count
 var expected=present_expected_slot_names(ui)
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present body_bar after a key change keeps GameHeader")
 t.check(ui.body_buttons.wrist.get_instance_id()!=wrist_before_mutation.get_instance_id(),"DISPLAY present body_bar rebuilds body buttons when the presentation key changes")
 t.check(present_visible_slot_names(ui)==expected,"DISPLAY present body_bar visible slots match the mutated view")
 t.check(not mutated.occupied or String(ui.body_buttons[mutated.id].text).contains(str(new_count)),"DISPLAY present body_bar shows the mutated member count")
 t.check(counting.get_view_calls==baseline,"DISPLAY present body_bar after a key change does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["body_bar"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present body_bar snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present replaces view with the given snapshot")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present does not mutate random cursors")

static func present_header_button_count(header) -> int:
 return header.find_children("*","Button",true,false).size()

static func present_hand_live_count(ui, uid: String) -> int:
 var n=0
 for node in ui.find_children("HandCard_"+String(uid),"",true,false):
  if is_instance_valid(node) and node.is_inside_tree(): n+=1
 return n

static func present_named_live_count(ui, node_name: String) -> int:
 var n=0
 for node in ui.find_children(node_name,"",true,false):
  if is_instance_valid(node) and node.is_inside_tree(): n+=1
 return n

static func present_routes_header_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and ui.find_child("GameHeader",true,false)!=null,"DISPLAY header fixture is a battle page with GameHeader")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY header counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 t.check(present_header_button_count(header)==6,"DISPLAY header baseline Button count is 6")
 var tutorial=header.find_child("OpenTutorial",true,false)
 var relics=ui.find_children("RelicStrip","",true,false)
 var relic=relics[0] if not relics.is_empty() else null
 var relic_count=relics.size()
 var oracle=header._presentation_key(ui)
 t.check(is_instance_valid(tutorial) and header.get_node("HeaderInfo/HeaderSecurity")!=null,"DISPLAY header baseline has OpenTutorial and HeaderSecurity")
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header,"DISPLAY present header keeps GameHeader on first call")
 t.check(header.find_child("OpenTutorial",true,false).get_instance_id()==tutorial.get_instance_id(),"DISPLAY present header keeps OpenTutorial on first call")
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header,"DISPLAY present header keeps GameHeader on second call")
 t.check(ui.find_children("GameHeader","",true,false).size()==1,"DISPLAY present header keeps a single GameHeader")
 t.check(present_header_button_count(header)==6,"DISPLAY present header does not stack Buttons")
 t.check(header.find_child("OpenTutorial",true,false).get_instance_id()==tutorial.get_instance_id(),"DISPLAY present header keeps OpenTutorial on second call")
 t.check(header.find_child("OpenStatus",true,false)!=null and header.find_child("OpenItems",true,false)!=null and header.find_child("OpenDeck",true,false)!=null and header.find_child("OpenMenu",true,false)!=null,"DISPLAY present header keeps named action buttons")
 var map_keys=0
 if header.find_child("OpenMap",true,false)!=null: map_keys+=1
 if header.find_child("OpenPrisonTutorial",true,false)!=null: map_keys+=1
 t.check(map_keys==1,"DISPLAY present header keeps one map or prison button")
 t.check(ui.find_children("RelicStrip","",true,false).size()==relic_count,"DISPLAY present header does not grow RelicStrip")
 t.check(relic==null or ui.find_child("RelicStrip",true,false)==relic,"DISPLAY present header keeps RelicStrip instance when present")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present header keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present header keeps enemies")
 t.check(header._presentation_key(ui)==oracle,"DISPLAY present header keeps the presentation key")
 t.check(counting.get_view_calls==baseline,"DISPLAY present header does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 ui.view.security=int(ui.view.security)+3
 var expected_security=int(ui.view.security)
 ui.present(["header"]);await t.frames()
 header=ui.find_child("GameHeader",true,false)
 t.check(header==header_after_full,"DISPLAY present header after a key change keeps GameHeader")
 t.check(String(header.get_node("HeaderInfo/HeaderSecurity").text).contains(str(expected_security)),"DISPLAY present header shows the mutated security")
 t.check(present_header_button_count(header)==6,"DISPLAY present header after a key change does not stack Buttons")
 t.check(counting.get_view_calls==baseline,"DISPLAY present header after a key change does not call get_view")
 var header_after_mutation=header
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["header"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present header snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present header replaces view with the given snapshot")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present header does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present header does not mutate random cursors")

static func present_routes_relics_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and ui.find_child("GameHeader",true,false)!=null,"DISPLAY relics fixture is a battle page with GameHeader")
 t.check(not ui.view.relics.is_empty(),"DISPLAY relics fixture has a non-empty relics view")
 var first_id=String(ui.view.relics[0].id)
 t.check(ui.find_children("RelicStrip","",true,false).size()==1 and ui.find_child("RelicShortcut_"+first_id,true,false)!=null,"DISPLAY relics fixture has one RelicStrip and the first RelicShortcut")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY relics counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var strip=ui.find_child("RelicStrip",true,false)
 var shortcut=ui.find_child("RelicShortcut_"+first_id,true,false)
 var wrist=ui.body_buttons.get("wrist")
 t.check(is_instance_valid(header) and is_instance_valid(strip) and is_instance_valid(shortcut),"DISPLAY relics baseline has header, strip, and shortcut")
 ui.present(["relics"]);await t.frames()
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("RelicStrip",true,false)==strip,"DISPLAY present relics keeps RelicStrip on key hit")
 t.check(ui.find_children("RelicStrip","",true,false).size()==1,"DISPLAY present relics keeps a single RelicStrip")
 t.check(ui.find_child("RelicShortcut_"+first_id,true,false)==shortcut,"DISPLAY present relics keeps RelicShortcut instance")
 t.check(ui.find_children("RelicShortcut_"+first_id,"",true,false).size()==1,"DISPLAY present relics keeps a single RelicShortcut for the same id")
 t.check(ui.find_child("GameHeader",true,false)==header,"DISPLAY present relics keeps GameHeader")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present relics keeps wrist instance")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present relics keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present relics keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present relics does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var strip_before_mutation=ui.find_child("RelicStrip",true,false)
 ui.view.relics[0].counter={"text":"probe","detail":"probe detail"}
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present relics after a key change keeps GameHeader")
 var strip_after_mutation=ui.find_child("RelicStrip",true,false)
 t.check(is_instance_valid(strip_after_mutation) and strip_after_mutation.get_instance_id()!=strip_before_mutation.get_instance_id(),"DISPLAY present relics rebuilds RelicStrip when the presentation key changes")
 var badge=ui.find_child("RelicCounter",true,false)
 t.check(badge!=null and String(badge.text)=="probe","DISPLAY present relics shows the mutated counter")
 t.check(ui.find_children("RelicStrip","",true,false).size()==1,"DISPLAY present relics after a key change keeps a single RelicStrip")
 t.check(counting.get_view_calls==baseline,"DISPLAY present relics after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 t.check(ui.find_child("RelicStrip",true,false)==strip_after_mutation,"DISPLAY present header does not replace RelicStrip")
 var header_after_header=ui.find_child("GameHeader",true,false)
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_header,"DISPLAY present body_bar still keeps GameHeader")
 t.check(ui.find_child("RelicStrip",true,false)==strip_after_mutation,"DISPLAY present body_bar does not replace RelicStrip")
 t.check(ui.find_children("RelicStrip","",true,false).size()==1,"DISPLAY present body_bar keeps a single RelicStrip")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["relics"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present relics snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present relics replaces view with the given snapshot")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present relics does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present relics does not mutate random cursors")
 t.check(not ui.find_children("RelicStrip","",true,false).is_empty(),"DISPLAY relics snapshot path still has a RelicStrip")
 var extra_host=Control.new();ui.layout.add_child(extra_host)
 var extra=ScrollContainer.new();extra.name="RelicStrip"
 extra_host.add_child(extra)
 t.check(ui.find_children("RelicStrip","",true,false).size()==2,"DISPLAY relics duplicate RelicStrip fixture has two strips")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_children("RelicStrip","",true,false).size()==1,"DISPLAY present relics collapses extra RelicStrip to one")
 var host=VBoxContainer.new();host.name="RouteMapColumn"
 ui.layout.add_child(host)
 var live=ui.find_child("RelicStrip",true,false)
 live.reparent(host)
 live.custom_minimum_size=Vector2(0,48)
 live.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 live.position=Vector2.ZERO
 var map_scroll=ScrollContainer.new();map_scroll.name="TowerMapScroll"
 host.add_child(map_scroll)
 t.check(live.get_index()==0 and host.get_child(1)==map_scroll,"DISPLAY relics host fixture has RelicStrip then TowerMapScroll")
 ui.view.relics[0].counter={"text":"host-probe","detail":"host probe"}
 ui.present(["relics"]);await t.frames()
 var rebuilt=ui.find_child("RelicStrip",true,false)
 t.check(is_instance_valid(rebuilt) and rebuilt.get_parent()==host,"DISPLAY present relics rebuild keeps RelicStrip parent")
 t.check(rebuilt.get_index()==0,"DISPLAY present relics rebuild keeps RelicStrip at child index 0")
 t.check(host.get_child_count()>1 and host.get_child(1)==map_scroll,"DISPLAY present relics rebuild keeps TowerMapScroll as the next sibling")
 t.check(rebuilt.position==Vector2.ZERO,"DISPLAY present relics rebuild keeps RelicStrip position")
 t.check(rebuilt.size_flags_horizontal==Control.SIZE_EXPAND_FILL,"DISPLAY present relics rebuild keeps RelicStrip size flags")
 t.check(ui.find_children("RelicStrip","",true,false).size()==1,"DISPLAY present relics rebuild under host keeps a single RelicStrip")
 var header_before_empty=ui.find_child("GameHeader",true,false)
 ui.view.relics=[]
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_before_empty,"DISPLAY present relics empty view keeps GameHeader")
 t.check(ui.find_children("RelicStrip","",true,false).is_empty(),"DISPLAY present relics unloads RelicStrip when view relics are empty")
 t.check(counting.get_view_calls==baseline,"DISPLAY present relics empty unload does not call get_view")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present relics empty unload does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present relics empty unload does not mutate random cursors")
 var leftover=ScrollContainer.new();leftover.name="RelicStrip"
 ui.layout.add_child(leftover)
 t.check(ui.find_children("RelicStrip","",true,false).size()==1,"DISPLAY relics leftover RelicStrip fixture has one strip")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_children("RelicStrip","",true,false).is_empty(),"DISPLAY present relics unloads leftover RelicStrip when view relics stay empty")
 t.check(counting.get_view_calls==baseline,"DISPLAY present relics leftover unload does not call get_view")

static func present_routes_hand_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and ui.find_child("GameHeader",true,false)!=null and not ui.view.hand.is_empty() and not bool(ui.view.pressure.overloaded),"DISPLAY hand fixture is a battle page with a non-empty non-overloaded hand")
 var first_uid=String(ui.view.hand[0].uid)
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY hand counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var relics=ui.find_children("RelicStrip","",true,false)
 var relic=relics[0] if not relics.is_empty() else null
 var first_card=ui.card_buttons.get(first_uid)
 var wrist=ui.body_buttons.get("wrist")
 t.check(is_instance_valid(header) and is_instance_valid(first_card),"DISPLAY hand baseline has GameHeader and first card button")
 ui.present(["hand"]);await t.frames()
 ui.present(["hand"]);await t.frames()
 t.check(ui.card_buttons.get(first_uid)==first_card,"DISPLAY present hand keeps first card instance")
 t.check(present_hand_live_count(ui,first_uid)==1,"DISPLAY present hand keeps one live button per uid")
 t.check(ui.card_buttons.size()==ui.view.hand.size(),"DISPLAY present hand card_buttons keys match hand size")
 t.check(ui.find_child("GameHeader",true,false)==header,"DISPLAY present hand keeps GameHeader")
 t.check(relic==null or ui.find_child("RelicStrip",true,false)==relic,"DISPLAY present hand keeps RelicStrip instance when present")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present hand keeps wrist instance")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present hand keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present hand keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present hand does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var card_before_mutation=ui.card_buttons.get(first_uid)
 if bool(ui.card_faces.get(first_uid,false)): await t.flip(first_uid)
 var face="free" if bool(ui.card_faces.get(first_uid,false)) else "bound"
 var subtree_before=present_hand_nodes(card_before_mutation)
 var av=ui.view.hand[0].availability[face]
 av.text="probe-hand";av.usable=false;av.dim=true
 ui.present(["hand"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present hand after a key change keeps GameHeader")
 var card_after_mutation=ui.card_buttons.get(first_uid)
 t.check(is_instance_valid(card_after_mutation) and card_after_mutation.get_instance_id()==card_before_mutation.get_instance_id(),"DISPLAY present hand keeps the card and rewrites its values when the presentation key changes")
 var availability=card_after_mutation.find_child("CardAvailability",true,false)
 t.check(availability!=null and String(availability.text).contains("probe-hand"),"DISPLAY present hand shows the mutated availability")
 t.check(present_hand_nodes(card_after_mutation)==subtree_before,"DISPLAY present hand rewrites the key-changed card in place with zero create and zero destroy: "+str(present_hand_lost(present_hand_nodes(card_after_mutation),subtree_before)))
 t.check(present_hand_live_count(ui,first_uid)==1,"DISPLAY present hand after a key change keeps one live button per uid")
 t.check(counting.get_view_calls==baseline,"DISPLAY present hand after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 var card_after_hand_mutation=ui.card_buttons.get(first_uid)
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 t.check(ui.card_buttons.get(first_uid)==card_after_hand_mutation,"DISPLAY present header does not replace the hand card")
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 t.check(ui.card_buttons.get(first_uid)==card_after_hand_mutation,"DISPLAY present body_bar does not replace the hand card")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present relics still keeps GameHeader")
 t.check(ui.card_buttons.get(first_uid)==card_after_hand_mutation,"DISPLAY present relics does not replace the hand card")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["hand"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present hand snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present hand replaces view with the given snapshot")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present does not mutate random cursors")

static func present_routes_actions_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and ui.find_child("GameHeader",true,false)!=null and not bool(ui.view.pressure.overloaded) and not ui._selecting_hand() and not ui.quick_release_open and ui.view.card_chain.is_empty() and not bool(ui.view.reward_panel.active),"DISPLAY actions fixture is a battle page without full-render extras")
 t.check(ui.find_child("AttackActions",true,false)!=null and ui.find_child("DeepBreath",true,false)!=null,"DISPLAY actions fixture has AttackActions and DeepBreath")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY actions counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var relics=ui.find_children("RelicStrip","",true,false)
 var relic=relics[0] if not relics.is_empty() else null
 var rail=ui.find_child("AttackActions",true,false)
 var breath=ui.find_child("DeepBreath",true,false)
 var wrist=ui.body_buttons.get("wrist")
 t.check(is_instance_valid(header) and is_instance_valid(rail) and is_instance_valid(breath),"DISPLAY actions baseline has header, AttackActions, and DeepBreath")
 ui.present(["actions"]);await t.frames()
 ui.present(["actions"]);await t.frames()
 t.check(ui.find_child("AttackActions",true,false)==rail,"DISPLAY present actions keeps AttackActions on key hit")
 t.check(ui.find_children("AttackActions","",true,false).size()==1,"DISPLAY present actions keeps a single AttackActions")
 t.check(ui.find_child("DeepBreath",true,false)==breath,"DISPLAY present actions keeps DeepBreath instance")
 t.check(ui.find_children("DeepBreath","",true,false).size()==1,"DISPLAY present actions keeps a single DeepBreath")
 t.check(ui.find_children("ActionRailToggle","",true,false).size()==1,"DISPLAY present actions keeps a single ActionRailToggle")
 t.check(ui.find_child("GameHeader",true,false)==header,"DISPLAY present actions keeps GameHeader")
 t.check(relic==null or ui.find_child("RelicStrip",true,false)==relic,"DISPLAY present actions keeps RelicStrip instance when present")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present actions keeps wrist instance")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present actions keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present actions keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present actions does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var rail_before_mutation=ui.find_child("AttackActions",true,false)
 var probe=null
 for fact in ui.view.display_facts:
  if String(fact.get("group",""))=="pressure" and String(fact.payload.get("kind",""))=="calm":
   probe=fact
   break
 t.check(probe!=null,"DISPLAY actions mutation target exists")
 probe.label="probe-actions"
 ui.present(["actions"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present actions after a key change keeps GameHeader")
 var rail_after_mutation=ui.find_child("AttackActions",true,false)
 t.check(is_instance_valid(rail_after_mutation) and rail_after_mutation.get_instance_id()!=rail_before_mutation.get_instance_id(),"DISPLAY present actions rebuilds AttackActions when the presentation key changes")
 breath=ui.find_child("DeepBreath",true,false)
 t.check(is_instance_valid(breath),"DISPLAY present actions rebuilt DeepBreath")
 var title=breath.find_child("BasicAttackTitle",true,false)
 t.check(title!=null and String(title.text).contains("probe-actions"),"DISPLAY present actions shows the mutated calm label")
 t.check(ui.find_children("AttackActions","",true,false).size()==1,"DISPLAY present actions after a key change keeps a single AttackActions")
 t.check(counting.get_view_calls==baseline,"DISPLAY present actions after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 var rail_after_actions_mutation=ui.find_child("AttackActions",true,false)
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 t.check(ui.find_child("AttackActions",true,false)==rail_after_actions_mutation,"DISPLAY present header does not replace AttackActions")
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 t.check(ui.find_child("AttackActions",true,false)==rail_after_actions_mutation,"DISPLAY present body_bar does not replace AttackActions")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present relics still keeps GameHeader")
 t.check(ui.find_child("AttackActions",true,false)==rail_after_actions_mutation,"DISPLAY present relics does not replace AttackActions")
 ui.present(["hand"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present hand still keeps GameHeader")
 t.check(ui.find_child("AttackActions",true,false)==rail_after_actions_mutation,"DISPLAY present hand does not replace AttackActions")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["actions"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present actions snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present actions replaces view with the given snapshot")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present does not mutate random cursors")

static func present_routes_posture_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and not ui.show_route and ui.find_child("GameHeader",true,false)!=null and not bool(ui.view.pressure.overloaded),"DISPLAY posture fixture is a battle page with GameHeader")
 t.check(ui.find_child("PostureChoices",true,false)!=null and ui.find_child("Posture_sit",true,false)!=null,"DISPLAY posture fixture has PostureChoices and Posture_sit")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY posture counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var relics=ui.find_children("RelicStrip","",true,false)
 var relic=relics[0] if not relics.is_empty() else null
 var rail=ui.find_child("AttackActions",true,false)
 var choices=ui.find_child("PostureChoices",true,false)
 var sit=ui.find_child("Posture_sit",true,false)
 var wall=ui.find_child("WallMove_toward",true,false)
 var end_button=ui.find_child("EndTurnButton",true,false)
 var wrist=ui.body_buttons.get("wrist")
 t.check(is_instance_valid(header) and is_instance_valid(choices) and is_instance_valid(sit),"DISPLAY posture baseline has header, PostureChoices, and Posture_sit")
 ui.present(["posture"]);await t.frames()
 ui.present(["posture"]);await t.frames()
 t.check(ui.find_child("PostureChoices",true,false)==choices,"DISPLAY present posture keeps PostureChoices on key hit")
 t.check(present_named_live_count(ui,"PostureChoices")==1,"DISPLAY present posture keeps a single PostureChoices")
 t.check(ui.find_child("Posture_sit",true,false)==sit,"DISPLAY present posture keeps Posture_sit instance")
 t.check(present_named_live_count(ui,"Posture_sit")==1,"DISPLAY present posture keeps a single Posture_sit")
 t.check(wall==null or ui.find_child("WallMove_toward",true,false)==wall,"DISPLAY present posture keeps WallMove_toward instance when present")
 t.check(wall==null or present_named_live_count(ui,"WallMove_toward")==1,"DISPLAY present posture keeps a single WallMove_toward when present")
 t.check(ui.find_child("GameHeader",true,false)==header,"DISPLAY present posture keeps GameHeader")
 t.check(relic==null or ui.find_child("RelicStrip",true,false)==relic,"DISPLAY present posture keeps RelicStrip instance when present")
 t.check(rail==null or ui.find_child("AttackActions",true,false)==rail,"DISPLAY present posture keeps AttackActions instance when present")
 t.check(end_button==null or ui.find_child("EndTurnButton",true,false)==end_button,"DISPLAY present posture keeps EndTurnButton instance when present")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present posture keeps wrist instance")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present posture keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present posture keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present posture does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var end_after_full=ui.find_child("EndTurnButton",true,false)
 var choices_before_mutation=ui.find_child("PostureChoices",true,false)
 var probe=null
 for fact in ui.view.display_facts:
  if String(fact.get("group",""))=="posture" and bool(fact.payload.get("adjacent",false)) and String(fact.payload.get("dest",""))=="sit" and not bool(fact.payload.get("wall",false)):
   probe=fact
   break
 t.check(probe!=null,"DISPLAY posture mutation target exists")
 probe.cost=99
 ui.present(["posture"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present posture after a key change keeps GameHeader")
 var choices_after_mutation=ui.find_child("PostureChoices",true,false)
 t.check(is_instance_valid(choices_after_mutation) and choices_after_mutation.get_instance_id()!=choices_before_mutation.get_instance_id(),"DISPLAY present posture rebuilds PostureChoices when the presentation key changes")
 sit=ui.find_child("Posture_sit",true,false)
 t.check(sit!=null and String(sit.text).contains("99"),"DISPLAY present posture shows the mutated sit cost")
 t.check(present_named_live_count(ui,"PostureChoices")==1,"DISPLAY present posture after a key change keeps a single PostureChoices")
 t.check(end_after_full==null or ui.find_child("EndTurnButton",true,false)==end_after_full,"DISPLAY present posture after a key change keeps EndTurnButton")
 t.check(counting.get_view_calls==baseline,"DISPLAY present posture after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 var choices_after_posture_mutation=ui.find_child("PostureChoices",true,false)
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 t.check(ui.find_child("PostureChoices",true,false)==choices_after_posture_mutation,"DISPLAY present header does not replace PostureChoices")
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 t.check(ui.find_child("PostureChoices",true,false)==choices_after_posture_mutation,"DISPLAY present body_bar does not replace PostureChoices")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present relics still keeps GameHeader")
 t.check(ui.find_child("PostureChoices",true,false)==choices_after_posture_mutation,"DISPLAY present relics does not replace PostureChoices")
 ui.present(["hand"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present hand still keeps GameHeader")
 t.check(ui.find_child("PostureChoices",true,false)==choices_after_posture_mutation,"DISPLAY present hand does not replace PostureChoices")
 ui.present(["actions"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present actions still keeps GameHeader")
 t.check(ui.find_child("PostureChoices",true,false)==choices_after_posture_mutation,"DISPLAY present actions does not replace PostureChoices")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["posture"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present posture snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present posture replaces view with the given snapshot")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present does not mutate random cursors")

static func present_routes_resources_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and not ui.show_route and ui.find_child("GameHeader",true,false)!=null and not bool(ui.view.pressure.overloaded),"DISPLAY resources fixture is a battle page with GameHeader")
 t.check(ui.find_child("MainResourcePanel",true,false)!=null and ui.find_child("EnergyValue",true,false)!=null and ui.find_child("EndTurnButton",true,false)!=null,"DISPLAY resources fixture has MainResourcePanel, EnergyValue, and EndTurnButton")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY resources counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var relics=ui.find_children("RelicStrip","",true,false)
 var relic=relics[0] if not relics.is_empty() else null
 var rail=ui.find_child("AttackActions",true,false)
 var choices=ui.find_child("PostureChoices",true,false)
 var sit=ui.find_child("Posture_sit",true,false)
 var panel=ui.find_child("MainResourcePanel",true,false)
 var energy=ui.find_child("EnergyValue",true,false)
 var end_button=ui.find_child("EndTurnButton",true,false)
 var draw_pile=ui.find_child("DrawPileButton",true,false)
 var wrist=ui.body_buttons.get("wrist")
 var hero_overload=ui.find_child("HeroOverload",true,false)
 var hero_mana=ui.find_child("HeroMana",true,false)
 t.check(is_instance_valid(header) and is_instance_valid(panel) and is_instance_valid(energy) and is_instance_valid(end_button) and is_instance_valid(draw_pile),"DISPLAY resources baseline has header and resource bar")
 ui.present(["resources"]);await t.frames()
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("MainResourcePanel",true,false)==panel,"DISPLAY present resources keeps MainResourcePanel on key hit")
 t.check(present_named_live_count(ui,"MainResourcePanel")==1,"DISPLAY present resources keeps a single MainResourcePanel")
 t.check(ui.find_child("EnergyValue",true,false)==energy,"DISPLAY present resources keeps EnergyValue instance")
 t.check(present_named_live_count(ui,"EnergyValue")==1,"DISPLAY present resources keeps a single EnergyValue")
 t.check(ui.find_child("EndTurnButton",true,false)==end_button,"DISPLAY present resources keeps EndTurnButton instance")
 t.check(present_named_live_count(ui,"EndTurnButton")==1,"DISPLAY present resources keeps a single EndTurnButton")
 t.check(ui.end_button==end_button,"DISPLAY present resources keeps end_button pointing at EndTurnButton")
 t.check(ui.find_child("DrawPileButton",true,false)==draw_pile,"DISPLAY present resources keeps DrawPileButton instance")
 t.check(present_named_live_count(ui,"DrawPileButton")==1,"DISPLAY present resources keeps a single DrawPileButton")
 t.check(ui.find_child("GameHeader",true,false)==header,"DISPLAY present resources keeps GameHeader")
 t.check(relic==null or ui.find_child("RelicStrip",true,false)==relic,"DISPLAY present resources keeps RelicStrip instance when present")
 t.check(rail==null or ui.find_child("AttackActions",true,false)==rail,"DISPLAY present resources keeps AttackActions instance when present")
 t.check(choices==null or ui.find_child("PostureChoices",true,false)==choices,"DISPLAY present resources keeps PostureChoices instance when present")
 t.check(sit==null or ui.find_child("Posture_sit",true,false)==sit,"DISPLAY present resources keeps Posture_sit instance when present")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present resources keeps wrist instance")
 t.check(hero_overload==null or ui.find_child("HeroOverload",true,false)==hero_overload,"DISPLAY present resources keeps HeroOverload instance when present")
 t.check(hero_mana==null or ui.find_child("HeroMana",true,false)==hero_mana,"DISPLAY present resources keeps HeroMana instance when present")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present resources keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present resources keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present resources does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var choices_after_full=ui.find_child("PostureChoices",true,false)
 var panel_before_mutation=ui.find_child("MainResourcePanel",true,false)
 ui.view.energy=99
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present resources after a key change keeps GameHeader")
 var panel_after_mutation=ui.find_child("MainResourcePanel",true,false)
 t.check(is_instance_valid(panel_after_mutation) and panel_after_mutation.get_instance_id()!=panel_before_mutation.get_instance_id(),"DISPLAY present resources rebuilds MainResourcePanel when the presentation key changes")
 energy=ui.find_child("EnergyValue",true,false)
 t.check(energy!=null and String(energy.text).contains("99"),"DISPLAY present resources shows the mutated energy")
 t.check(present_named_live_count(ui,"MainResourcePanel")==1,"DISPLAY present resources after a key change keeps a single MainResourcePanel")
 t.check(present_named_live_count(ui,"EnergyMedallion")==1,"DISPLAY present resources after a key change keeps a single EnergyMedallion")
 t.check(present_named_live_count(ui,"EndTurnButton")==1,"DISPLAY present resources after a key change keeps a single EndTurnButton")
 t.check(choices_after_full==null or ui.find_child("PostureChoices",true,false)==choices_after_full,"DISPLAY present resources after a key change keeps PostureChoices")
 t.check(counting.get_view_calls==baseline,"DISPLAY present resources after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 var panel_after_resources_mutation=ui.find_child("MainResourcePanel",true,false)
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 t.check(ui.find_child("MainResourcePanel",true,false)==panel_after_resources_mutation,"DISPLAY present header does not replace MainResourcePanel")
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 t.check(ui.find_child("MainResourcePanel",true,false)==panel_after_resources_mutation,"DISPLAY present body_bar does not replace MainResourcePanel")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present relics still keeps GameHeader")
 t.check(ui.find_child("MainResourcePanel",true,false)==panel_after_resources_mutation,"DISPLAY present relics does not replace MainResourcePanel")
 ui.present(["hand"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present hand still keeps GameHeader")
 t.check(ui.find_child("MainResourcePanel",true,false)==panel_after_resources_mutation,"DISPLAY present hand does not replace MainResourcePanel")
 ui.present(["actions"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present actions still keeps GameHeader")
 t.check(ui.find_child("MainResourcePanel",true,false)==panel_after_resources_mutation,"DISPLAY present actions does not replace MainResourcePanel")
 ui.present(["posture"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present posture still keeps GameHeader")
 t.check(ui.find_child("MainResourcePanel",true,false)==panel_after_resources_mutation,"DISPLAY present posture does not replace MainResourcePanel")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["resources"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present resources snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present resources replaces view with the given snapshot")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present does not mutate random cursors")

static func present_routes_show_log_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and not ui.show_route and ui.find_child("GameHeader",true,false)!=null and not bool(ui.view.pressure.overloaded) and not ui.show_home,"DISPLAY show_log fixture is a battle page with GameHeader")
 ui._open_drawer("show_log");await t.frames()
 t.check(ui.show_log and ui.find_child("InformationLayer",true,false)!=null and ui.find_child("InformationDrawer",true,false)!=null and ui.find_child("DismissDrawer",true,false)!=null and ui.find_child("LogBackToMenu",true,false)!=null and ui.find_child("LogDetails",true,false)!=null,"DISPLAY show_log fixture has the log overlay")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY show_log counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 t.check(ui.show_log,"DISPLAY show_log remains open after counting render")
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var layer=ui.find_child("InformationLayer",true,false)
 var drawer=ui.find_child("InformationDrawer",true,false)
 var dismiss=ui.find_child("DismissDrawer",true,false)
 var back=ui.find_child("LogBackToMenu",true,false)
 var details=ui.find_child("LogDetails",true,false)
 var panel=ui.find_child("MainResourcePanel",true,false)
 var rail=ui.find_child("AttackActions",true,false)
 var choices=ui.find_child("PostureChoices",true,false)
 var wrist=ui.body_buttons.get("wrist")
 t.check(is_instance_valid(header) and is_instance_valid(layer) and is_instance_valid(drawer) and is_instance_valid(dismiss) and is_instance_valid(back) and is_instance_valid(details),"DISPLAY show_log baseline has header and log overlay")
 ui.present(["show_log"]);await t.frames()
 ui.present(["show_log"]);await t.frames()
 t.check(ui.find_child("InformationDrawer",true,false)==drawer,"DISPLAY present show_log keeps InformationDrawer on key hit")
 t.check(present_named_live_count(ui,"InformationDrawer")==1,"DISPLAY present show_log keeps a single InformationDrawer")
 t.check(ui.find_child("InformationLayer",true,false)==layer,"DISPLAY present show_log keeps InformationLayer instance")
 t.check(present_named_live_count(ui,"InformationLayer")==1,"DISPLAY present show_log keeps a single InformationLayer")
 t.check(ui.find_child("DismissDrawer",true,false)==dismiss,"DISPLAY present show_log keeps DismissDrawer instance")
 t.check(present_named_live_count(ui,"DismissDrawer")==1,"DISPLAY present show_log keeps a single DismissDrawer")
 t.check(ui.find_child("LogBackToMenu",true,false)==back,"DISPLAY present show_log keeps LogBackToMenu instance")
 t.check(present_named_live_count(ui,"LogBackToMenu")==1,"DISPLAY present show_log keeps a single LogBackToMenu")
 t.check(ui.find_child("LogDetails",true,false)==details,"DISPLAY present show_log keeps LogDetails instance")
 t.check(present_named_live_count(ui,"LogDetails")==1,"DISPLAY present show_log keeps a single LogDetails")
 t.check(ui.find_child("GameHeader",true,false)==header,"DISPLAY present show_log keeps GameHeader")
 t.check(panel==null or ui.find_child("MainResourcePanel",true,false)==panel,"DISPLAY present show_log keeps MainResourcePanel instance when present")
 t.check(rail==null or ui.find_child("AttackActions",true,false)==rail,"DISPLAY present show_log keeps AttackActions instance when present")
 t.check(choices==null or ui.find_child("PostureChoices",true,false)==choices,"DISPLAY present show_log keeps PostureChoices instance when present")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present show_log keeps wrist instance")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present show_log keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present show_log keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present show_log does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var layer_after_full=ui.find_child("InformationLayer",true,false)
 var panel_after_full=ui.find_child("MainResourcePanel",true,false)
 var drawer_before_mutation=ui.find_child("InformationDrawer",true,false)
 ui.view.action_log.append({"actor":"切片探针","round":99,"text":"show_log键未命中"})
 ui.present(["show_log"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present show_log after a key change keeps GameHeader")
 t.check(ui.find_child("InformationLayer",true,false)==layer_after_full,"DISPLAY present show_log after a key change keeps InformationLayer")
 var drawer_after_mutation=ui.find_child("InformationDrawer",true,false)
 t.check(is_instance_valid(drawer_after_mutation) and drawer_after_mutation.get_instance_id()!=drawer_before_mutation.get_instance_id(),"DISPLAY present show_log rebuilds InformationDrawer when the presentation key changes")
 t.check(t.visible_text(drawer_after_mutation).contains("切片探针"),"DISPLAY present show_log shows the mutated action_log actor")
 t.check(present_named_live_count(ui,"InformationDrawer")==1,"DISPLAY present show_log after a key change keeps a single InformationDrawer")
 t.check(present_named_live_count(ui,"DismissDrawer")==1,"DISPLAY present show_log after a key change keeps a single DismissDrawer")
 t.check(present_named_live_count(ui,"LogBackToMenu")==1,"DISPLAY present show_log after a key change keeps a single LogBackToMenu")
 t.check(panel_after_full==null or ui.find_child("MainResourcePanel",true,false)==panel_after_full,"DISPLAY present show_log after a key change keeps MainResourcePanel")
 t.check(counting.get_view_calls==baseline,"DISPLAY present show_log after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 var drawer_after_log_mutation=ui.find_child("InformationDrawer",true,false)
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_log_mutation,"DISPLAY present header does not replace InformationDrawer")
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_log_mutation,"DISPLAY present body_bar does not replace InformationDrawer")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present relics still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_log_mutation,"DISPLAY present relics does not replace InformationDrawer")
 ui.present(["hand"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present hand still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_log_mutation,"DISPLAY present hand does not replace InformationDrawer")
 ui.present(["actions"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present actions still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_log_mutation,"DISPLAY present actions does not replace InformationDrawer")
 ui.present(["posture"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present posture still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_log_mutation,"DISPLAY present posture does not replace InformationDrawer")
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present resources still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_log_mutation,"DISPLAY present resources does not replace InformationDrawer")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["show_log"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present show_log snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present show_log replaces view with the given snapshot")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present does not mutate random cursors")

static func present_routes_body_details_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and ui.find_child("GameHeader",true,false)!=null and not ui.show_route and not bool(ui.view.pressure.overloaded) and not ui._selecting_hand() and not ui.quick_release_open and not bool(ui.view.pending_retain),"DISPLAY body_details fixture is a battle page with GameHeader")
 ui.selected_slot="wrist";ui.show_body=true;ui.selected_card="";ui.selected_candidate=""
 ui.render(ui.view);await t.frames()
 t.check(ui.find_child("EquipmentDetails",true,false)!=null and ui.find_child("CloseEquipmentDetails",true,false)!=null and ui.find_child("EquipmentTutorial",true,false)!=null,"DISPLAY body_details fixture has EquipmentDetails")
 ui._open_drawer("show_log");await t.frames()
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY body_details counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 t.check(ui.show_body and ui.show_log,"DISPLAY body_details remains open after counting render")
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var details=ui.find_child("EquipmentDetails",true,false)
 var close=ui.find_child("CloseEquipmentDetails",true,false)
 var tutorial=ui.find_child("EquipmentTutorial",true,false)
 var panel=ui.find_child("BodyEquipmentPanel",true,false)
 var resources=ui.find_child("MainResourcePanel",true,false)
 var rail=ui.find_child("AttackActions",true,false)
 var choices=ui.find_child("PostureChoices",true,false)
 var drawer=ui.find_child("InformationDrawer",true,false)
 var wrist=ui.body_buttons.get("wrist")
 t.check(is_instance_valid(header) and is_instance_valid(details) and is_instance_valid(close) and is_instance_valid(tutorial),"DISPLAY body_details baseline has header and equipment details")
 var header_before_hit=ui.find_child("GameHeader",true,false)
 var details_before_hit=ui.find_child("EquipmentDetails",true,false)
 ui.present(["body_details"]);await t.frames()
 ui.present(["body_details"]);await t.frames()
 t.check(ui.find_child("EquipmentDetails",true,false)==details_before_hit,"DISPLAY present body_details keeps EquipmentDetails on key hit")
 t.check(present_named_live_count(ui,"EquipmentDetails")==1,"DISPLAY present body_details keeps a single EquipmentDetails")
 t.check(ui.find_child("CloseEquipmentDetails",true,false)==close,"DISPLAY present body_details keeps CloseEquipmentDetails instance")
 t.check(present_named_live_count(ui,"CloseEquipmentDetails")==1,"DISPLAY present body_details keeps a single CloseEquipmentDetails")
 t.check(ui.find_child("EquipmentTutorial",true,false)==tutorial,"DISPLAY present body_details keeps EquipmentTutorial instance")
 t.check(present_named_live_count(ui,"EquipmentTutorial")==1,"DISPLAY present body_details keeps a single EquipmentTutorial")
 t.check(ui.find_child("GameHeader",true,false)==header_before_hit,"DISPLAY present body_details keeps GameHeader")
 t.check(panel==null or ui.find_child("BodyEquipmentPanel",true,false)==panel,"DISPLAY present body_details keeps BodyEquipmentPanel instance when present")
 t.check(resources==null or ui.find_child("MainResourcePanel",true,false)==resources,"DISPLAY present body_details keeps MainResourcePanel instance when present")
 t.check(rail==null or ui.find_child("AttackActions",true,false)==rail,"DISPLAY present body_details keeps AttackActions instance when present")
 t.check(choices==null or ui.find_child("PostureChoices",true,false)==choices,"DISPLAY present body_details keeps PostureChoices instance when present")
 t.check(drawer==null or ui.find_child("InformationDrawer",true,false)==drawer,"DISPLAY present body_details keeps InformationDrawer instance when present")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present body_details keeps wrist instance")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present body_details keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present body_details keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present body_details does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var panel_after_full=ui.find_child("BodyEquipmentPanel",true,false)
 var resources_after_full=ui.find_child("MainResourcePanel",true,false)
 var details_before_mutation=ui.find_child("EquipmentDetails",true,false)
 var wrist_body=ui._body_at("wrist")
 var other=null
 for body in ui.view.body_groups:
  if String(body.id)!=String(wrist_body.id) and String(body.name)!=String(wrist_body.name):
   other=body
   break
 t.check(other!=null,"DISPLAY body_details mutation target exists in body_groups")
 ui.selected_slot=String(other.id)
 ui.present(["body_details"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present body_details after a key change keeps GameHeader")
 t.check(panel_after_full==null or ui.find_child("BodyEquipmentPanel",true,false)==panel_after_full,"DISPLAY present body_details after a key change keeps BodyEquipmentPanel")
 var details_after_mutation=ui.find_child("EquipmentDetails",true,false)
 t.check(is_instance_valid(details_after_mutation) and details_after_mutation.get_instance_id()!=details_before_mutation.get_instance_id(),"DISPLAY present body_details rebuilds EquipmentDetails when the presentation key changes")
 t.check(t.visible_text(details_after_mutation).contains(String(other.name)),"DISPLAY present body_details shows the mutated body name")
 t.check(present_named_live_count(ui,"EquipmentDetails")==1,"DISPLAY present body_details after a key change keeps a single EquipmentDetails")
 t.check(present_named_live_count(ui,"CloseEquipmentDetails")==1,"DISPLAY present body_details after a key change keeps a single CloseEquipmentDetails")
 t.check(resources_after_full==null or ui.find_child("MainResourcePanel",true,false)==resources_after_full,"DISPLAY present body_details after a key change keeps MainResourcePanel")
 t.check(counting.get_view_calls==baseline,"DISPLAY present body_details after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 var details_after_slot_mutation=ui.find_child("EquipmentDetails",true,false)
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 t.check(ui.find_child("EquipmentDetails",true,false)==details_after_slot_mutation,"DISPLAY present header does not replace EquipmentDetails")
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 t.check(ui.find_child("EquipmentDetails",true,false)==details_after_slot_mutation,"DISPLAY present body_bar does not replace EquipmentDetails")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present relics still keeps GameHeader")
 t.check(ui.find_child("EquipmentDetails",true,false)==details_after_slot_mutation,"DISPLAY present relics does not replace EquipmentDetails")
 ui.present(["hand"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present hand still keeps GameHeader")
 t.check(ui.find_child("EquipmentDetails",true,false)==details_after_slot_mutation,"DISPLAY present hand does not replace EquipmentDetails")
 ui.present(["actions"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present actions still keeps GameHeader")
 t.check(ui.find_child("EquipmentDetails",true,false)==details_after_slot_mutation,"DISPLAY present actions does not replace EquipmentDetails")
 ui.present(["posture"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present posture still keeps GameHeader")
 t.check(ui.find_child("EquipmentDetails",true,false)==details_after_slot_mutation,"DISPLAY present posture does not replace EquipmentDetails")
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present resources still keeps GameHeader")
 t.check(ui.find_child("EquipmentDetails",true,false)==details_after_slot_mutation,"DISPLAY present resources does not replace EquipmentDetails")
 ui.present(["show_log"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present show_log still keeps GameHeader")
 t.check(ui.find_child("EquipmentDetails",true,false)==details_after_slot_mutation,"DISPLAY present show_log does not replace EquipmentDetails")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["body_details"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present body_details snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present body_details replaces view with the given snapshot")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present body_details does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present body_details does not mutate random cursors")

static func present_routes_pickers_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and ui.find_child("GameHeader",true,false)!=null and not ui.show_route and not bool(ui.view.pressure.overloaded) and ui.view.hand.size()>=2,"DISPLAY pickers fixture is a battle page with GameHeader and two cards")
 ui._open_drawer("show_log");await t.frames()
 t.check(ui.show_log,"DISPLAY pickers fixture opens the log before hand selection")
 var source=ui.view.hand[0]
 var other=null
 for card in ui.view.hand:
  if String(card.uid)!=String(source.uid):
   other=card
   break
 t.check(other!=null,"DISPLAY pickers fixture has a second hand card")
 ui.open_hand_selection({"uid":source.uid,"free":false,"target":"","slot":""},int(ui.view.version));await t.frames()
 t.check(ui._selecting_hand() and ui.find_child("HandSelectionBar",true,false)!=null and ui.find_child("HandTargetCancel",true,false)!=null,"DISPLAY pickers fixture has HandSelectionBar")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY pickers counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 t.check(ui._selecting_hand() and ui.show_log,"DISPLAY pickers remains selecting after counting render")
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var bar=ui.find_child("HandSelectionBar",true,false)
 var cancel=ui.find_child("HandTargetCancel",true,false)
 var drawer=ui.find_child("InformationDrawer",true,false)
 var resources=ui.find_child("MainResourcePanel",true,false)
 var choices=ui.find_child("PostureChoices",true,false)
 var wrist=ui.body_buttons.get("wrist")
 t.check(is_instance_valid(header) and is_instance_valid(bar) and is_instance_valid(cancel) and bar.is_ancestor_of(cancel),"DISPLAY pickers baseline has header and HandSelectionBar")
 var header_before_hit=ui.find_child("GameHeader",true,false)
 var bar_before_hit=ui.find_child("HandSelectionBar",true,false)
 ui.present(["pickers"]);await t.frames()
 ui.present(["pickers"]);await t.frames()
 t.check(ui.find_child("HandSelectionBar",true,false)==bar_before_hit,"DISPLAY present pickers keeps HandSelectionBar on key hit")
 t.check(present_named_live_count(ui,"HandSelectionBar")==1,"DISPLAY present pickers keeps a single HandSelectionBar")
 t.check(ui.find_child("HandTargetCancel",true,false)==cancel,"DISPLAY present pickers keeps HandTargetCancel instance")
 t.check(present_named_live_count(ui,"HandTargetCancel")==1,"DISPLAY present pickers keeps a single HandTargetCancel")
 t.check(ui.find_child("HandSelectionBar",true,false).is_ancestor_of(ui.find_child("HandTargetCancel",true,false)),"DISPLAY present pickers keeps HandTargetCancel under HandSelectionBar")
 t.check(ui.find_child("GameHeader",true,false)==header_before_hit,"DISPLAY present pickers keeps GameHeader")
 t.check(drawer==null or ui.find_child("InformationDrawer",true,false)==drawer,"DISPLAY present pickers keeps InformationDrawer instance when present")
 t.check(resources==null or ui.find_child("MainResourcePanel",true,false)==resources,"DISPLAY present pickers keeps MainResourcePanel instance when present")
 t.check(choices==null or ui.find_child("PostureChoices",true,false)==choices,"DISPLAY present pickers keeps PostureChoices instance when present")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present pickers keeps wrist instance")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present pickers keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present pickers keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present pickers does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var drawer_after_full=ui.find_child("InformationDrawer",true,false)
 var bar_before_mutation=ui.find_child("HandSelectionBar",true,false)
 ui.player_pick_data.card_uid=String(other.uid)
 ui.present(["pickers"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present pickers after a key change keeps GameHeader")
 t.check(drawer_after_full==null or ui.find_child("InformationDrawer",true,false)==drawer_after_full,"DISPLAY present pickers after a key change keeps InformationDrawer")
 var bar_after_mutation=ui.find_child("HandSelectionBar",true,false)
 t.check(is_instance_valid(bar_after_mutation) and bar_after_mutation.get_instance_id()!=bar_before_mutation.get_instance_id(),"DISPLAY present pickers rebuilds HandSelectionBar when the presentation key changes")
 t.check(t.visible_text(bar_after_mutation).contains("选择一张手牌消耗"),"DISPLAY present pickers shows the hand selection prompt")
 t.check(present_named_live_count(ui,"HandSelectionBar")==1,"DISPLAY present pickers after a key change keeps a single HandSelectionBar")
 t.check(present_named_live_count(ui,"HandTargetCancel")==1,"DISPLAY present pickers after a key change keeps a single HandTargetCancel")
 t.check(String(ui.player_pick_data.card_uid)==String(other.uid),"DISPLAY present pickers keeps the mutated card_uid")
 t.check(counting.get_view_calls==baseline,"DISPLAY present pickers after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 var bar_after_card_mutation=ui.find_child("HandSelectionBar",true,false)
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 t.check(ui.find_child("HandSelectionBar",true,false)==bar_after_card_mutation,"DISPLAY present header does not replace HandSelectionBar")
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 t.check(ui.find_child("HandSelectionBar",true,false)==bar_after_card_mutation,"DISPLAY present body_bar does not replace HandSelectionBar")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present relics still keeps GameHeader")
 t.check(ui.find_child("HandSelectionBar",true,false)==bar_after_card_mutation,"DISPLAY present relics does not replace HandSelectionBar")
 ui.present(["hand"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present hand still keeps GameHeader")
 t.check(ui.find_child("HandSelectionBar",true,false)==bar_after_card_mutation,"DISPLAY present hand does not replace HandSelectionBar")
 ui.present(["posture"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present posture still keeps GameHeader")
 t.check(ui.find_child("HandSelectionBar",true,false)==bar_after_card_mutation,"DISPLAY present posture does not replace HandSelectionBar")
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present resources still keeps GameHeader")
 t.check(ui.find_child("HandSelectionBar",true,false)==bar_after_card_mutation,"DISPLAY present resources does not replace HandSelectionBar")
 ui.present(["show_log"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present show_log still keeps GameHeader")
 t.check(ui.find_child("HandSelectionBar",true,false)==bar_after_card_mutation,"DISPLAY present show_log does not replace HandSelectionBar")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["pickers"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present pickers snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present pickers replaces view with the given snapshot")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present pickers does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present pickers does not mutate random cursors")

static func present_routes_speech_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and ui.find_child("GameHeader",true,false)!=null and not ui.show_route and not ui.show_home and not bool(ui.view.pressure.overloaded) and not ui._takeover_locked() and ui.view.get("npc_speech",{}).is_empty() and not ui._selecting_hand(),"DISPLAY speech fixture is a battle page with GameHeader")
 ui.view.speech={"id":9001,"text":"切片探针台词"}
 ui.render(ui.view);await t.frames()
 t.check(ui.find_child("HeroSpeechGroup",true,false)!=null and ui.find_child("HeroSpeech",true,false)!=null and ui.find_child("HeroSpeechText",true,false)!=null,"DISPLAY speech fixture has HeroSpeechGroup")
 ui._open_drawer("show_log");await t.frames()
 t.check(ui.show_log,"DISPLAY speech fixture opens the log after the bubble")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY speech counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 t.check(ui.show_log and not ui.view.get("speech",{}).is_empty(),"DISPLAY speech remains after counting render")
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var group=ui.find_child("HeroSpeechGroup",true,false)
 var bubble=ui.find_child("HeroSpeech",true,false)
 var body=ui.find_child("HeroSpeechText",true,false)
 var drawer=ui.find_child("InformationDrawer",true,false)
 var resources=ui.find_child("MainResourcePanel",true,false)
 var choices=ui.find_child("PostureChoices",true,false)
 var rail=ui.find_child("AttackActions",true,false)
 var wrist=ui.body_buttons.get("wrist")
 t.check(is_instance_valid(header) and is_instance_valid(group) and is_instance_valid(bubble) and is_instance_valid(body) and group.is_ancestor_of(bubble) and group.is_ancestor_of(body),"DISPLAY speech baseline has header and HeroSpeechGroup")
 var header_before_hit=ui.find_child("GameHeader",true,false)
 var group_before_hit=ui.find_child("HeroSpeechGroup",true,false)
 ui.present(["speech"]);await t.frames()
 ui.present(["speech"]);await t.frames()
 t.check(ui.find_child("HeroSpeechGroup",true,false)==group_before_hit,"DISPLAY present speech keeps HeroSpeechGroup on key hit")
 t.check(present_named_live_count(ui,"HeroSpeechGroup")==1,"DISPLAY present speech keeps a single HeroSpeechGroup")
 t.check(ui.find_child("HeroSpeech",true,false)==bubble,"DISPLAY present speech keeps HeroSpeech instance")
 t.check(present_named_live_count(ui,"HeroSpeech")==1,"DISPLAY present speech keeps a single HeroSpeech")
 t.check(ui.find_child("HeroSpeechGroup",true,false).is_ancestor_of(ui.find_child("HeroSpeech",true,false)),"DISPLAY present speech keeps HeroSpeech under HeroSpeechGroup")
 t.check(ui.find_child("HeroSpeechText",true,false)==body,"DISPLAY present speech keeps HeroSpeechText instance")
 t.check(present_named_live_count(ui,"HeroSpeechText")==1,"DISPLAY present speech keeps a single HeroSpeechText")
 t.check(ui.find_child("HeroSpeechGroup",true,false).is_ancestor_of(ui.find_child("HeroSpeechText",true,false)),"DISPLAY present speech keeps HeroSpeechText under HeroSpeechGroup")
 t.check(ui.find_child("GameHeader",true,false)==header_before_hit,"DISPLAY present speech keeps GameHeader")
 t.check(drawer==null or ui.find_child("InformationDrawer",true,false)==drawer,"DISPLAY present speech keeps InformationDrawer instance when present")
 t.check(resources==null or ui.find_child("MainResourcePanel",true,false)==resources,"DISPLAY present speech keeps MainResourcePanel instance when present")
 t.check(choices==null or ui.find_child("PostureChoices",true,false)==choices,"DISPLAY present speech keeps PostureChoices instance when present")
 t.check(rail==null or ui.find_child("AttackActions",true,false)==rail,"DISPLAY present speech keeps AttackActions instance when present")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present speech keeps wrist instance")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present speech keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present speech keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present speech does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var drawer_after_full=ui.find_child("InformationDrawer",true,false)
 var group_before_mutation=ui.find_child("HeroSpeechGroup",true,false)
 ui.view.speech.text="切片探针台词·键未命中"
 ui.present(["speech"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present speech after a key change keeps GameHeader")
 t.check(drawer_after_full==null or ui.find_child("InformationDrawer",true,false)==drawer_after_full,"DISPLAY present speech after a key change keeps InformationDrawer")
 var group_after_mutation=ui.find_child("HeroSpeechGroup",true,false)
 t.check(is_instance_valid(group_after_mutation) and group_after_mutation.get_instance_id()!=group_before_mutation.get_instance_id(),"DISPLAY present speech rebuilds HeroSpeechGroup when the presentation key changes")
 t.check(t.visible_text(group_after_mutation).contains("切片探针台词·键未命中"),"DISPLAY present speech shows the mutated line")
 t.check(present_named_live_count(ui,"HeroSpeechGroup")==1,"DISPLAY present speech after a key change keeps a single HeroSpeechGroup")
 t.check(present_named_live_count(ui,"HeroSpeech")==1,"DISPLAY present speech after a key change keeps a single HeroSpeech")
 t.check(present_named_live_count(ui,"HeroSpeechText")==1,"DISPLAY present speech after a key change keeps a single HeroSpeechText")
 t.check(int(ui.view.speech.id)==9001,"DISPLAY present speech keeps the mutated speech id")
 t.check(counting.get_view_calls==baseline,"DISPLAY present speech after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 var group_after_text_mutation=ui.find_child("HeroSpeechGroup",true,false)
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 t.check(ui.find_child("HeroSpeechGroup",true,false)==group_after_text_mutation,"DISPLAY present header does not replace HeroSpeechGroup")
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 t.check(ui.find_child("HeroSpeechGroup",true,false)==group_after_text_mutation,"DISPLAY present body_bar does not replace HeroSpeechGroup")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present relics still keeps GameHeader")
 t.check(ui.find_child("HeroSpeechGroup",true,false)==group_after_text_mutation,"DISPLAY present relics does not replace HeroSpeechGroup")
 ui.present(["hand"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present hand still keeps GameHeader")
 t.check(ui.find_child("HeroSpeechGroup",true,false)==group_after_text_mutation,"DISPLAY present hand does not replace HeroSpeechGroup")
 ui.present(["actions"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present actions still keeps GameHeader")
 t.check(ui.find_child("HeroSpeechGroup",true,false)==group_after_text_mutation,"DISPLAY present actions does not replace HeroSpeechGroup")
 ui.present(["posture"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present posture still keeps GameHeader")
 t.check(ui.find_child("HeroSpeechGroup",true,false)==group_after_text_mutation,"DISPLAY present posture does not replace HeroSpeechGroup")
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present resources still keeps GameHeader")
 t.check(ui.find_child("HeroSpeechGroup",true,false)==group_after_text_mutation,"DISPLAY present resources does not replace HeroSpeechGroup")
 ui.present(["show_log"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present show_log still keeps GameHeader")
 t.check(ui.find_child("HeroSpeechGroup",true,false)==group_after_text_mutation,"DISPLAY present show_log does not replace HeroSpeechGroup")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["speech"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present speech snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present speech replaces view with the given snapshot")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present speech does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present speech does not mutate random cursors")

static func present_routes_notice_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and ui.find_child("GameHeader",true,false)!=null and not ui.show_route and not ui.show_home and not bool(ui.view.pressure.overloaded) and not ui._takeover_locked() and ui.view.get("npc_speech",{}).is_empty() and not ui._selecting_hand() and ui.actor_targets.has("hero") and is_instance_valid(ui.actor_targets.hero) and ui.actor_targets.hero.is_inside_tree(),"DISPLAY notice fixture is a battle page with GameHeader and hero target")
 ui.view.speech={"id":9001,"text":"切片探针台词"}
 ui.notice="切片探针提示"
 ui.render(ui.view);await t.frames()
 t.check(is_instance_valid(ui.term_popup) and String(ui.term_popup.name)=="TermExplanation" and ui.term_anchor==ui.actor_targets.hero and t.visible_text(ui.term_popup).contains("切片探针提示"),"DISPLAY notice fixture has TermExplanation on the hero")
 ui._open_drawer("show_log");await t.frames()
 t.check(ui.show_log,"DISPLAY notice fixture opens the log after the bubble")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY notice counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 t.check(ui.show_log and ui.notice=="切片探针提示" and is_instance_valid(ui.term_popup),"DISPLAY notice remains after counting render")
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var term=ui.find_child("TermExplanation",true,false)
 var drawer=ui.find_child("InformationDrawer",true,false)
 var resources=ui.find_child("MainResourcePanel",true,false)
 var choices=ui.find_child("PostureChoices",true,false)
 var rail=ui.find_child("AttackActions",true,false)
 var speech=ui.find_child("HeroSpeechGroup",true,false)
 var wrist=ui.body_buttons.get("wrist")
 var hero=ui.actor_targets.hero
 t.check(is_instance_valid(header) and is_instance_valid(term) and is_instance_valid(hero) and ui.term_anchor==hero,"DISPLAY notice baseline has header, TermExplanation, and hero anchor")
 var header_before_hit=ui.find_child("GameHeader",true,false)
 var term_before_hit=ui.find_child("TermExplanation",true,false)
 ui.present(["notice"]);await t.frames()
 ui.present(["notice"]);await t.frames()
 t.check(ui.find_child("TermExplanation",true,false)==term_before_hit,"DISPLAY present notice keeps TermExplanation on key hit")
 t.check(present_named_live_count(ui,"TermExplanation")==1,"DISPLAY present notice keeps a single TermExplanation")
 t.check(ui.term_anchor==hero,"DISPLAY present notice keeps term_anchor on the hero")
 t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains("切片探针提示"),"DISPLAY present notice keeps the probe notice")
 t.check(not ui.term_popup.has_meta("drag_reason"),"DISPLAY present notice keeps a notice bubble without drag_reason")
 t.check(ui.find_child("GameHeader",true,false)==header_before_hit,"DISPLAY present notice keeps GameHeader")
 t.check(drawer==null or ui.find_child("InformationDrawer",true,false)==drawer,"DISPLAY present notice keeps InformationDrawer instance when present")
 t.check(resources==null or ui.find_child("MainResourcePanel",true,false)==resources,"DISPLAY present notice keeps MainResourcePanel instance when present")
 t.check(choices==null or ui.find_child("PostureChoices",true,false)==choices,"DISPLAY present notice keeps PostureChoices instance when present")
 t.check(rail==null or ui.find_child("AttackActions",true,false)==rail,"DISPLAY present notice keeps AttackActions instance when present")
 t.check(speech==null or ui.find_child("HeroSpeechGroup",true,false)==speech,"DISPLAY present notice keeps HeroSpeechGroup instance when present")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present notice keeps wrist instance")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present notice keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present notice keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present notice does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var drawer_after_full=ui.find_child("InformationDrawer",true,false)
 var term_before_mutation=ui.find_child("TermExplanation",true,false)
 ui.notice="切片探针提示·键未命中"
 ui.present(["notice"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present notice after a key change keeps GameHeader")
 t.check(drawer_after_full==null or ui.find_child("InformationDrawer",true,false)==drawer_after_full,"DISPLAY present notice after a key change keeps InformationDrawer")
 var term_after_mutation=ui.find_child("TermExplanation",true,false)
 t.check(is_instance_valid(term_after_mutation) and term_after_mutation.get_instance_id()!=term_before_mutation.get_instance_id(),"DISPLAY present notice rebuilds TermExplanation when the presentation key changes")
 t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains("切片探针提示·键未命中"),"DISPLAY present notice shows the mutated line")
 t.check(present_named_live_count(ui,"TermExplanation")==1,"DISPLAY present notice after a key change keeps a single TermExplanation")
 t.check(ui.term_anchor==ui.actor_targets.hero,"DISPLAY present notice after a key change keeps term_anchor on the hero")
 t.check(counting.get_view_calls==baseline,"DISPLAY present notice after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present relics still keeps GameHeader")
 ui.present(["hand"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present hand still keeps GameHeader")
 ui.present(["actions"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present actions still keeps GameHeader")
 ui.present(["posture"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present posture still keeps GameHeader")
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present resources still keeps GameHeader")
 ui.present(["show_log"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present show_log still keeps GameHeader")
 ui.present(["speech"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present speech still keeps GameHeader")
 ui.present(["notice"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present notice after other local sections keeps GameHeader")
 t.check(present_named_live_count(ui,"TermExplanation")==1,"DISPLAY present notice after other local sections rebuilds a single TermExplanation")
 t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains("切片探针提示·键未命中"),"DISPLAY present notice after other local sections shows the mutated line")
 t.check(ui.term_anchor==ui.actor_targets.hero,"DISPLAY present notice after other local sections keeps term_anchor on the hero")
 t.check(counting.get_view_calls==baseline,"DISPLAY present notice after other local sections does not call get_view")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["notice"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present notice snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present notice replaces view with the given snapshot")
 t.check(ui.notice=="切片探针提示·键未命中","DISPLAY present notice snapshot keeps the mutated notice")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present notice does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present notice does not mutate random cursors")

static func present_routes_drawers_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and ui.find_child("GameHeader",true,false)!=null and not ui.show_route and not ui.show_home and not bool(ui.view.pressure.overloaded) and not ui._takeover_locked() and not ui._selecting_hand() and not ui.save_failed and not bool(ui.view.get("demo_finished",false)),"DISPLAY drawers fixture is a battle page with GameHeader")
 ui._open_drawer("show_menu");await t.frames()
 t.check(ui.show_menu and ui.DRAWERS.all(func(field):return field=="show_menu" or not bool(ui.get(field))) and ui.find_child("InformationLayer",true,false)!=null and ui.find_child("InformationDrawer",true,false)!=null and ui.find_child("DismissDrawer",true,false)!=null and ui.find_child("OpenSaves",true,false)!=null and ui.find_child("QuickSL",true,false)!=null,"DISPLAY drawers fixture has the game menu overlay")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY drawers counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 t.check(ui.show_menu,"DISPLAY drawers remains open after counting render")
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var layer=ui.find_child("InformationLayer",true,false)
 var drawer=ui.find_child("InformationDrawer",true,false)
 var dismiss=ui.find_child("DismissDrawer",true,false)
 var saves=ui.find_child("OpenSaves",true,false)
 var quick=ui.find_child("QuickSL",true,false)
 var resources=ui.find_child("MainResourcePanel",true,false)
 var choices=ui.find_child("PostureChoices",true,false)
 var rail=ui.find_child("AttackActions",true,false)
 var speech=ui.find_child("HeroSpeechGroup",true,false)
 var wrist=ui.body_buttons.get("wrist")
 t.check(is_instance_valid(header) and is_instance_valid(layer) and is_instance_valid(drawer) and is_instance_valid(dismiss) and is_instance_valid(saves) and is_instance_valid(quick) and layer.is_ancestor_of(saves) and layer.is_ancestor_of(quick),"DISPLAY drawers baseline has header and menu overlay")
 var header_before_hit=ui.find_child("GameHeader",true,false)
 var drawer_before_hit=ui.find_child("InformationDrawer",true,false)
 ui.present(["drawers"]);await t.frames()
 ui.present(["drawers"]);await t.frames()
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_before_hit,"DISPLAY present drawers keeps InformationDrawer on key hit")
 t.check(present_named_live_count(ui,"InformationDrawer")==1,"DISPLAY present drawers keeps a single InformationDrawer")
 t.check(ui.find_child("InformationLayer",true,false)==layer,"DISPLAY present drawers keeps InformationLayer instance")
 t.check(present_named_live_count(ui,"InformationLayer")==1,"DISPLAY present drawers keeps a single InformationLayer")
 t.check(ui.find_child("DismissDrawer",true,false)==dismiss,"DISPLAY present drawers keeps DismissDrawer instance")
 t.check(present_named_live_count(ui,"DismissDrawer")==1,"DISPLAY present drawers keeps a single DismissDrawer")
 t.check(ui.find_child("OpenSaves",true,false)==saves,"DISPLAY present drawers keeps OpenSaves instance")
 t.check(present_named_live_count(ui,"OpenSaves")==1,"DISPLAY present drawers keeps a single OpenSaves")
 t.check(ui.find_child("InformationLayer",true,false).is_ancestor_of(ui.find_child("OpenSaves",true,false)),"DISPLAY present drawers keeps OpenSaves under InformationLayer")
 t.check(ui.find_child("QuickSL",true,false)==quick,"DISPLAY present drawers keeps QuickSL instance")
 t.check(present_named_live_count(ui,"QuickSL")==1,"DISPLAY present drawers keeps a single QuickSL")
 t.check(ui.find_child("InformationLayer",true,false).is_ancestor_of(ui.find_child("QuickSL",true,false)),"DISPLAY present drawers keeps QuickSL under InformationLayer")
 t.check(ui.find_child("GameHeader",true,false)==header_before_hit,"DISPLAY present drawers keeps GameHeader")
 t.check(resources==null or ui.find_child("MainResourcePanel",true,false)==resources,"DISPLAY present drawers keeps MainResourcePanel instance when present")
 t.check(choices==null or ui.find_child("PostureChoices",true,false)==choices,"DISPLAY present drawers keeps PostureChoices instance when present")
 t.check(rail==null or ui.find_child("AttackActions",true,false)==rail,"DISPLAY present drawers keeps AttackActions instance when present")
 t.check(speech==null or ui.find_child("HeroSpeechGroup",true,false)==speech,"DISPLAY present drawers keeps HeroSpeechGroup instance when present")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present drawers keeps wrist instance")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present drawers keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present drawers keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present drawers does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var layer_after_full=ui.find_child("InformationLayer",true,false)
 var drawer_before_mutation=ui.find_child("InformationDrawer",true,false)
 ui.save_failed=true
 ui.present(["drawers"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present drawers after a key change keeps GameHeader")
 t.check(ui.find_child("InformationLayer",true,false)==layer_after_full,"DISPLAY present drawers after a key change keeps InformationLayer")
 var drawer_after_mutation=ui.find_child("InformationDrawer",true,false)
 t.check(is_instance_valid(drawer_after_mutation) and drawer_after_mutation.get_instance_id()!=drawer_before_mutation.get_instance_id(),"DISPLAY present drawers rebuilds InformationDrawer when the presentation key changes")
 t.check(t.visible_text(drawer_after_mutation).contains("存档异常"),"DISPLAY present drawers shows the mutated save_failed text")
 t.check(present_named_live_count(ui,"InformationDrawer")==1,"DISPLAY present drawers after a key change keeps a single InformationDrawer")
 t.check(present_named_live_count(ui,"DismissDrawer")==1,"DISPLAY present drawers after a key change keeps a single DismissDrawer")
 t.check(present_named_live_count(ui,"OpenSaves")==1,"DISPLAY present drawers after a key change keeps a single OpenSaves")
 t.check(counting.get_view_calls==baseline,"DISPLAY present drawers after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 var drawer_after_menu_mutation=ui.find_child("InformationDrawer",true,false)
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_menu_mutation,"DISPLAY present header does not replace InformationDrawer")
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_menu_mutation,"DISPLAY present body_bar does not replace InformationDrawer")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present relics still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_menu_mutation,"DISPLAY present relics does not replace InformationDrawer")
 ui.present(["hand"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present hand still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_menu_mutation,"DISPLAY present hand does not replace InformationDrawer")
 ui.present(["actions"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present actions still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_menu_mutation,"DISPLAY present actions does not replace InformationDrawer")
 ui.present(["posture"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present posture still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_menu_mutation,"DISPLAY present posture does not replace InformationDrawer")
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present resources still keeps GameHeader")
 t.check(ui.find_child("InformationDrawer",true,false)==drawer_after_menu_mutation,"DISPLAY present resources does not replace InformationDrawer")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["drawers"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present drawers snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present drawers replaces view with the given snapshot")
 t.check(ui.save_failed,"DISPLAY present drawers snapshot keeps save_failed")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present drawers does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present drawers does not mutate random cursors")

static func present_routes_scene_instances_or_full(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and ui.find_child("GameHeader",true,false)!=null and not ui.show_route and not ui.show_home and String(ui.view.get("character_id","original"))!="witch" and not bool(ui.display_settings.fixed_hero_portrait) and not bool(ui.view.pressure.overloaded) and not ui._takeover_locked() and not ui._selecting_hand(),"DISPLAY scene_instances fixture is a battle page with GameHeader")
 t.check(is_instance_valid(ui.layout.hero) and String(ui.layout.hero.name)=="HeroArt" and ui.layout.hero.is_inside_tree() and is_instance_valid(ui.layout.body) and ui.layout.body.is_inside_tree() and ui.layout.body.get_node_or_null("Canvas/EquipmentPortrait")!=null and ui.view.enemies.any(func(e):return not bool(e.get("gone",false)) and is_instance_valid(ui.layout.enemies.get(e.get("id","")))),"DISPLAY scene_instances fixture has hero, body portrait, and a living enemy group")
 var counting=GetViewCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY scene_instances counting wrapper restores the live run")
 ui.game=counting
 ui.render(ui.view);await t.frames(3)
 var baseline=counting.get_view_calls
 var before=ui.game.export_snapshot()
 var before_rng=ui.game.state.rng.duplicate(true)
 var header=ui.find_child("GameHeader",true,false)
 var hero=ui.layout.hero
 var hero_appearance=hero.appearance.duplicate(true)
 var pose=hero.find_child("HeroPose",true,false)
 var body_portrait=ui.layout.body.get_node("Canvas/EquipmentPortrait")
 var body_appearance=body_portrait.appearance.duplicate(true)
 var living_id=""
 for e in ui.view.enemies:
  if not bool(e.get("gone",false)) and is_instance_valid(ui.layout.enemies.get(e.get("id",""))):
   living_id=String(e.id)
   break
 var enemy_group=ui.layout.enemies[living_id]
 var enemy_art=enemy_group.get_child(0)
 var intent_count=present_named_live_count(ui,"IntentIcon_*")
 var enemy_select=ui.find_child("EnemySelect_*",true,false)
 var resources=ui.find_child("MainResourcePanel",true,false)
 var choices=ui.find_child("PostureChoices",true,false)
 var rail=ui.find_child("AttackActions",true,false)
 var drawer=ui.find_child("InformationDrawer",true,false)
 var speech=ui.find_child("HeroSpeechGroup",true,false)
 var wrist=ui.body_buttons.get("wrist")
 t.check(is_instance_valid(header) and is_instance_valid(hero) and is_instance_valid(body_portrait) and is_instance_valid(enemy_group) and is_instance_valid(enemy_art),"DISPLAY scene_instances baseline has header, hero, body portrait, and enemy art")
 var header_before_hit=ui.find_child("GameHeader",true,false)
 var hero_before_hit=ui.layout.hero
 ui.present(["scene_instances"]);await t.frames()
 ui.present(["scene_instances"]);await t.frames()
 t.check(ui.layout.hero==hero_before_hit,"DISPLAY present scene_instances keeps HeroArt on key hit")
 t.check(present_named_live_count(ui,"HeroArt")==1,"DISPLAY present scene_instances keeps a single HeroArt")
 t.check(ui.layout.hero.appearance==hero_appearance,"DISPLAY present scene_instances keeps hero appearance on key hit")
 t.check(pose==null or ui.layout.hero.find_child("HeroPose",true,false)==pose,"DISPLAY present scene_instances keeps HeroPose instance when present")
 t.check(ui.layout.body.get_node("Canvas/EquipmentPortrait")==body_portrait,"DISPLAY present scene_instances keeps body EquipmentPortrait")
 t.check(ui.layout.enemies[living_id]==enemy_group,"DISPLAY present scene_instances keeps the enemy group")
 t.check(ui.layout.enemies[living_id].get_child(0)==enemy_art,"DISPLAY present scene_instances keeps the enemy art child")
 t.check(present_named_live_count(ui,"IntentIcon_*")==intent_count,"DISPLAY present scene_instances keeps IntentIcon count")
 t.check(enemy_select==null or ui.find_child("EnemySelect_*",true,false)==enemy_select,"DISPLAY present scene_instances keeps EnemySelect instance when present")
 t.check(ui.find_child("GameHeader",true,false)==header_before_hit,"DISPLAY present scene_instances keeps GameHeader")
 t.check(resources==null or ui.find_child("MainResourcePanel",true,false)==resources,"DISPLAY present scene_instances keeps MainResourcePanel instance when present")
 t.check(choices==null or ui.find_child("PostureChoices",true,false)==choices,"DISPLAY present scene_instances keeps PostureChoices instance when present")
 t.check(rail==null or ui.find_child("AttackActions",true,false)==rail,"DISPLAY present scene_instances keeps AttackActions instance when present")
 t.check(drawer==null or ui.find_child("InformationDrawer",true,false)==drawer,"DISPLAY present scene_instances keeps InformationDrawer instance when present")
 t.check(speech==null or ui.find_child("HeroSpeechGroup",true,false)==speech,"DISPLAY present scene_instances keeps HeroSpeechGroup instance when present")
 t.check(wrist==null or ui.body_buttons.wrist==wrist,"DISPLAY present scene_instances keeps wrist instance")
 t.check(is_instance_valid(ui.layout.hero) and ui.layout.hero.visible and is_instance_valid(ui.layout.body),"DISPLAY present scene_instances keeps hero and body")
 t.check(ui.layout.enemies.values().all(func(group):return is_instance_valid(group)),"DISPLAY present scene_instances keeps enemies")
 t.check(counting.get_view_calls==baseline,"DISPLAY present scene_instances does not call get_view")
 var header_before_star=ui.find_child("GameHeader",true,false)
 ui.present(["*"]);await t.frames()
 var header_after_star=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_star) and header_after_star.get_instance_id()!=header_before_star.get_instance_id(),"DISPLAY present * replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present * does not call get_view")
 var header_before_unknown=ui.find_child("GameHeader",true,false)
 ui.present(["not_a_section"]);await t.frames()
 var header_after_unknown=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_unknown) and header_after_unknown.get_instance_id()!=header_before_unknown.get_instance_id(),"DISPLAY present unknown section replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present unknown section does not call get_view")
 var header_after_full=header_after_unknown
 var hero_after_full=ui.layout.hero
 var body_portrait_after_full=ui.layout.body.get_node("Canvas/EquipmentPortrait")
 var enemy_group_after_full=ui.layout.enemies[living_id]
 var intent_after_full=present_named_live_count(ui,"IntentIcon_*")
 ui.view.equipment_portrait_layers=ui.view.equipment_portrait_layers.duplicate()
 ui.view.equipment_portrait_layers.append("slice_probe_layer")
 ui.present(["scene_instances"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_full,"DISPLAY present scene_instances after a key change keeps GameHeader")
 t.check(ui.layout.hero==hero_after_full,"DISPLAY present scene_instances after a key change keeps HeroArt")
 t.check(ui.layout.hero.appearance!=hero_appearance,"DISPLAY present scene_instances updates hero appearance when the leaf key misses")
 t.check(ui.layout.body.get_node("Canvas/EquipmentPortrait")==body_portrait_after_full,"DISPLAY present scene_instances after a key change keeps body EquipmentPortrait")
 t.check(ui.layout.body.get_node("Canvas/EquipmentPortrait").appearance!=body_appearance,"DISPLAY present scene_instances updates body portrait appearance when the leaf key misses")
 t.check(present_named_live_count(ui,"IntentIcon_*")==intent_after_full,"DISPLAY present scene_instances after a key change keeps IntentIcon count")
 t.check(ui.layout.enemies[living_id]==enemy_group_after_full,"DISPLAY present scene_instances after a key change keeps the enemy group")
 t.check(present_named_live_count(ui,"HeroArt")==1,"DISPLAY present scene_instances after a key change keeps a single HeroArt")
 t.check(counting.get_view_calls==baseline,"DISPLAY present scene_instances after a key change does not call get_view")
 var header_after_mutation=ui.find_child("GameHeader",true,false)
 var hero_after_mutation=ui.layout.hero
 ui.present(["header"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present header still keeps GameHeader")
 t.check(ui.layout.hero==hero_after_mutation,"DISPLAY present header does not replace HeroArt")
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present body_bar still keeps GameHeader")
 t.check(ui.layout.hero==hero_after_mutation,"DISPLAY present body_bar does not replace HeroArt")
 ui.present(["relics"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present relics still keeps GameHeader")
 t.check(ui.layout.hero==hero_after_mutation,"DISPLAY present relics does not replace HeroArt")
 ui.present(["hand"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present hand still keeps GameHeader")
 t.check(ui.layout.hero==hero_after_mutation,"DISPLAY present hand does not replace HeroArt")
 ui.present(["actions"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present actions still keeps GameHeader")
 t.check(ui.layout.hero==hero_after_mutation,"DISPLAY present actions does not replace HeroArt")
 ui.present(["posture"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present posture still keeps GameHeader")
 t.check(ui.layout.hero==hero_after_mutation,"DISPLAY present posture does not replace HeroArt")
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("GameHeader",true,false)==header_after_mutation,"DISPLAY present resources still keeps GameHeader")
 t.check(ui.layout.hero==hero_after_mutation,"DISPLAY present resources does not replace HeroArt")
 var header_before_page=ui.find_child("GameHeader",true,false)
 ui.present(["page"]);await t.frames()
 var header_after_page=ui.find_child("GameHeader",true,false)
 t.check(is_instance_valid(header_after_page) and header_after_page.get_instance_id()!=header_before_page.get_instance_id(),"DISPLAY present page replaces GameHeader")
 t.check(counting.get_view_calls==baseline,"DISPLAY present page does not call get_view")
 var snap=ui.view.duplicate(true)
 ui.present(["scene_instances"],snap);await t.frames()
 t.check(counting.get_view_calls==baseline,"DISPLAY present scene_instances snapshot does not call get_view")
 t.check(is_same(ui.view,snap),"DISPLAY present scene_instances replaces view with the given snapshot")
 t.check(ui.view.equipment_portrait_layers.has("slice_probe_layer"),"DISPLAY present scene_instances snapshot keeps slice_probe_layer")
 t.check(ui.game.export_snapshot()==before,"DISPLAY present scene_instances does not mutate export_snapshot")
 t.check(ui.game.state.rng==before_rng,"DISPLAY present scene_instances does not mutate random cursors")

# docs/spec/response-pipeline.md「resources」／「scene_instances」: a successful battle
# submission refreshes through the local sections, so the hero-stage meters and every
# enemy's stage widgets must follow the committed View without a full page rebuild.
static func present_syncs_battle_stage_widgets(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and not ui.show_home and not ui.show_route,"DISPLAY present stage_widgets fixture is an ordinary battle page")
 var overload=ui.find_child("HeroOverload",true,false)
 var mana=ui.find_child("HeroMana",true,false)
 var overload_value=ui.find_child("HeroOverloadValue",true,false)
 var mana_value=ui.find_child("HeroManaValue",true,false)
 t.check(is_instance_valid(overload) and is_instance_valid(mana) and is_instance_valid(overload_value) and is_instance_valid(mana_value),"DISPLAY present stage_widgets baseline has both hero-stage meters and labels")
 if not (is_instance_valid(overload) and is_instance_valid(mana) and is_instance_valid(overload_value) and is_instance_valid(mana_value)): return
 # (a) hero-stage meters follow a changed View through the ["resources"] section.
 var pressure_before=float(overload.value)
 var mana_before=float(mana.value)
 ui.view.pressure.value=maxf(0.0,float(ui.view.pressure.maximum)-13.0)
 ui.view.mana=float(ui.view.mana_max)-3.0
 ui.view.temporary_mana=4.0
 t.check(not is_equal_approx(pressure_before,float(ui.view.pressure.value)) and not is_equal_approx(mana_before,float(ui.view.mana)),"DISPLAY present stage_widgets fixture moves both hero-stage meters away from their displayed values")
 var header=ui.find_child("GameHeader",true,false)
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("HeroOverload",true,false)==overload and ui.find_child("HeroMana",true,false)==mana,"DISPLAY present resources keeps the hero-stage meter instances")
 t.check(ui.find_child("HeroOverloadValue",true,false)==overload_value and ui.find_child("HeroManaValue",true,false)==mana_value,"DISPLAY present resources keeps the hero-stage meter labels")
 t.check(present_named_live_count(ui,"HeroOverload")==1 and present_named_live_count(ui,"HeroMana")==1,"DISPLAY present resources keeps a single hero-stage meter pair")
 t.check(is_equal_approx(overload.value,float(ui.view.pressure.value)) and is_equal_approx(overload.max_value,float(ui.view.pressure.maximum)),"DISPLAY present resources syncs the hero overload meter value and maximum")
 t.check(String(overload_value.text)=="%s/%s" % [ui.game.number(ui.view.pressure.value),ui.game.number(ui.view.pressure.maximum)],"DISPLAY present resources syncs the hero overload label")
 t.check(is_equal_approx(mana.value,float(ui.view.mana)) and is_equal_approx(mana.max_value,float(ui.view.mana_max)),"DISPLAY present resources syncs the hero mana meter value and maximum have="+str(mana.value)+"/"+str(mana.max_value)+" view="+str(ui.view.mana)+"/"+str(ui.view.mana_max))
 t.check(String(mana_value.text)==("%s/%s · 临时%s" % [ui.game.number(ui.view.mana),ui.game.number(ui.view.mana_max),ui.game.number(ui.view.temporary_mana)]),"DISPLAY present resources syncs the hero mana label with the temporary pool have="+String(mana_value.text))
 t.check(ui.find_child("GameHeader",true,false)==header,"DISPLAY present resources keeps GameHeader while syncing the hero-stage meters")
 ui.view.pressure.value=maxf(0.0,float(ui.view.pressure.value)-5.0)
 ui.view.temporary_mana=0.0
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("HeroOverload",true,false)==overload and is_equal_approx(overload.value,float(ui.view.pressure.value)),"DISPLAY present resources updates the same hero overload meter on the next value change")
 t.check(String(ui.find_child("HeroManaValue",true,false).text)==("%s/%s" % [ui.game.number(ui.view.mana),ui.game.number(ui.view.mana_max)]),"DISPLAY present resources drops the temporary pool from the hero mana label")
 ui.present(["resources"]);await t.frames()
 t.check(ui.find_child("HeroOverload",true,false)==overload and ui.find_child("HeroMana",true,false)==mana,"DISPLAY present resources keeps the hero-stage meters on a key hit")
 # (b) enemy-stage widgets follow a changed View through the ["scene_instances"] section.
 var living=ui.view.enemies.filter(func(e):return not e.gone)
 t.check(not living.is_empty(),"DISPLAY present stage_widgets fixture has a living enemy")
 if living.is_empty(): return
 var enemy=living[0]
 var enemy_id=String(enemy.id)
 var group=ui.layout.enemies.get(enemy_id)
 var bar=group.get_node_or_null("EnemyHp_"+enemy_id) if is_instance_valid(group) else null
 var hp=group.get_node_or_null("EnemyHpValue_"+enemy_id) if is_instance_valid(group) else null
 var select=group.get_node_or_null("EnemySelect_"+enemy_id) if is_instance_valid(group) else null
 t.check(is_instance_valid(group) and is_instance_valid(bar) and is_instance_valid(hp) and is_instance_valid(select),"DISPLAY present stage_widgets baseline has the enemy group, health bar, health text and name button")
 if not (is_instance_valid(group) and is_instance_valid(bar) and is_instance_valid(hp) and is_instance_valid(select)): return
 var other=""
 for e in living:
  if String(e.id)!=enemy_id: other=String(e.id)
 ui.selected_enemy=other if other!="" else enemy_id
 enemy.hp=float(enemy.hp)-9.0
 enemy.intent_icons=[{"kind":"delayed","label":"","detail":"敌人的行动已被打断","caption":""}]
 ui.present(["scene_instances"]);await t.frames()
 t.check(ui.layout.enemies.get(enemy_id)==group and group.get_node_or_null("EnemyHp_"+enemy_id)==bar and group.get_node_or_null("EnemyHpValue_"+enemy_id)==hp and group.get_node_or_null("EnemySelect_"+enemy_id)==select,"DISPLAY present scene_instances keeps the enemy group and its stage widget instances")
 t.check(is_equal_approx(bar.value,float(enemy.hp)) and is_equal_approx(bar.max_value,float(enemy.maximum)),"DISPLAY present scene_instances syncs the enemy health bar")
 t.check(String(hp.text)=="%s / %s" % [ui.game.number(enemy.hp),ui.game.number(enemy.maximum)],"DISPLAY present scene_instances syncs the enemy health text")
 t.check(not String(select.text).begins_with("◇ ") and String(select.text).contains(String(enemy.name)),"DISPLAY present scene_instances clears the mark on an unselected enemy")
 t.check(present_named_live_count(ui,"IntentIcon_"+enemy_id+"_*")==1 and present_named_live_count(ui,"IntentIcon_"+enemy_id+"_delayed")==1,"DISPLAY present scene_instances replaces the intent icon set with the View list")
 var icon=group.get_node_or_null("IntentIcon_"+enemy_id+"_delayed")
 t.check(is_instance_valid(icon),"DISPLAY present scene_instances builds the icon of the current View list")
 if is_instance_valid(icon):
  await t.move_mouse(icon.get_global_rect().get_center());await t.frames()
  var popup=ui.find_child("TermExplanation",true,false)
  t.check(popup!=null and t.visible_text(popup).strip_edges()=="敌人的行动已被打断","DISPLAY present scene_instances wires hover on a replaced intent icon")
  await t.move_mouse(Vector2(700,510));await t.frames()
 ui.selected_enemy=enemy_id
 ui.present(["scene_instances"]);await t.frames()
 t.check(String(select.text).begins_with("◇ ") and String(select.text).contains(String(enemy.name)) and not select.disabled,"DISPLAY present scene_instances marks the selected enemy and keeps it selectable")
 if other!="":
  var other_group=ui.layout.enemies.get(other)
  var other_select=other_group.get_node_or_null("EnemySelect_"+other) if is_instance_valid(other_group) else null
  t.check(other_select==null or not String(other_select.text).begins_with("◇ "),"DISPLAY present scene_instances clears the mark on the enemy that lost the selection")
 var keeper=living[1] if living.size()>1 else null
 var keeper_before=Vector2.INF
 if keeper!=null:
  var keeper_group=ui.layout.enemies.get(String(keeper.id))
  if is_instance_valid(keeper_group): keeper_before=keeper_group.position
 enemy.gone=true
 ui.present(["scene_instances"]);await t.frames()
 t.check(not ui.layout.enemies.has(enemy_id) and ui.find_child("EnemyGroup_"+enemy_id,true,false)==null,"DISPLAY present scene_instances releases a gone enemy's stage slot")
 t.check(not ui.actor_targets.has(enemy_id),"DISPLAY present scene_instances drops the gone enemy's actor target")
 t.check(keeper==null or is_instance_valid(ui.layout.enemies.get(String(keeper.id))),"DISPLAY present scene_instances keeps a living enemy's group")
 # The surviving row is re-laid out, not left in the pre-kill geometry.
 var order=ui._enemy_row()
 var row_scale=minf(1.0,ui.ENEMY_STAGE_WIDTH/(ui.ENEMY_GROUP_WIDTH*maxi(1,order.size())))
 var row_width=order.size()*ui.ENEMY_GROUP_WIDTH*row_scale
 var row_start=ui.ENEMY_STAGE_LEFT+(ui.ENEMY_STAGE_WIDTH-row_width)/2.0
 var misplaced=[]
 var moved=false
 for i in range(order.size()):
  var placed=ui.layout.enemies.get(String(order[i].get("id","")))
  if not is_instance_valid(placed): misplaced.append(String(order[i].get("id",""))+":missing");continue
  var want=Vector2(row_start+i*ui.ENEMY_GROUP_WIDTH*row_scale,497.0*(1.0-row_scale))
  if not placed.position.is_equal_approx(want) or not placed.scale.is_equal_approx(Vector2.ONE*row_scale): misplaced.append(String(order[i].get("id",""))+"@"+str(placed.position)+"/"+str(placed.scale))
  if keeper!=null and placed==ui.layout.enemies.get(String(keeper.id)) and not placed.position.is_equal_approx(keeper_before): moved=true
 t.check(misplaced.is_empty() and (keeper==null or moved),"DISPLAY present scene_instances re-lays out the surviving row after a kill have="+str(misplaced.slice(0,2)))
 # (c) the defect's own trigger: a successful battle submission lands both stages on the
 # committed View through the local sections.
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var counting=SubmitCountingGame.new(42,false,"equipment",false)
 t.check(counting.restore_snapshot(ui.game.export_snapshot()).ok,"DISPLAY present stage_widgets counting game restores the live run")
 ui.game=counting
 ui.render(counting.get_view());await t.frames(3)
 var usable=ui.view.display_facts.filter(func(c):return c.valid and String(c.payload.get("kind",""))=="attack" and String(c.payload.get("enemy",""))!="")
 t.check(not usable.is_empty(),"DISPLAY present stage_widgets battle fixture has a valid attack")
 if usable.is_empty(): return
 var attack=usable[0].duplicate(true)
 var target_id=String(attack.payload.enemy)
 for row in counting.state.enemies:
  if String(row.id)==target_id: row.hp=float(row.max_hp)
 ui.render(counting.get_view());await t.frames(3)
 var baseline=counting.get_view_calls
 var header_before=ui.find_child("GameHeader",true,false)
 var hp_before=float(ui.view.enemies.filter(func(e):return String(e.id)==target_id)[0].hp)
 ui.command_router.emit("attack",attack,ui.view.version);await t.frames()
 var committed=ui.view.enemies.filter(func(e):return String(e.id)==target_id)[0]
 t.check(bool(counting.last_result.get("ok",false)) and String(ui.view.phase)=="battle" and float(committed.hp)<hp_before,"DISPLAY present stage_widgets real attack lowers the committed enemy hp on a battle page")
 t.check(counting.get_view_calls==baseline+1 and ui.find_child("GameHeader",true,false)==header_before,"DISPLAY present stage_widgets real attack refreshes through the local sections without a full page rebuild")
 var committed_group=ui.layout.enemies.get(target_id)
 var committed_bar=committed_group.get_node_or_null("EnemyHp_"+target_id) if is_instance_valid(committed_group) else null
 var committed_text=committed_group.get_node_or_null("EnemyHpValue_"+target_id) if is_instance_valid(committed_group) else null
 t.check(is_instance_valid(committed_bar) and is_equal_approx(committed_bar.value,float(committed.hp)) and is_equal_approx(committed_bar.max_value,float(committed.maximum)),"DISPLAY present stage_widgets real attack leaves the enemy health bar on the committed view")
 t.check(is_instance_valid(committed_text) and String(committed_text.text)=="%s / %s" % [ui.game.number(committed.hp),ui.game.number(committed.maximum)],"DISPLAY present stage_widgets real attack leaves the enemy health text on the committed view")
 var committed_overload=ui.find_child("HeroOverload",true,false)
 t.check(is_instance_valid(committed_overload) and is_equal_approx(committed_overload.value,float(ui.view.pressure.value)) and is_equal_approx(committed_overload.max_value,float(ui.view.pressure.maximum)),"DISPLAY present stage_widgets real attack leaves the hero overload meter on the committed view")

# docs/spec/ondemand-copy.md「证据入口」: the body detail section resolves the card face through
# the single display entry, so a deleted card_texts key must recompute the same text and leave a
# named record instead of raising or silently blanking.
static func copy_missing_key_never_crashes(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.wall="normal"
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"strain")
 ui.game.add_fixture("wrist",4,10,false);ui.game.add_fixture("wrist",4,10,false)
 ui.selected_slot="wrist";ui.show_body=true;ui.selected_card=card.uid
 ui.render();await t.frames()
 t.check(ui.projection_misses.is_empty(),"COPY complete projection records no display miss")
 var before=ui.game.export_snapshot()
 var baseline={};var hinted=false
 for free_face in [false,true]:
  ui.card_faces[card.uid]=free_face
  ui.render();await t.frames()
  t.check(ui.find_child("EquipmentDetails",true,false)!=null,"COPY body detail section renders for face "+str(free_face))
  baseline[free_face]=t.visible_text(ui.find_child("EquipmentDetails",true,false))
  hinted=hinted or baseline[free_face].contains("请右键切换到")
 t.check(hinted,"COPY body detail fixture exercises the right-click face hint")
 var copy=ui.game.get_view().duplicate(true)
 copy.card_texts.erase(card.type)
 for free_face in [false,true]:
  ui.card_faces[card.uid]=free_face
  ui.render(copy);await t.frames()
  var erased=t.visible_text(ui.find_child("EquipmentDetails",true,false))
  t.check(erased==baseline[free_face],"COPY deleted card_texts key keeps the body detail text identical for face "+str(free_face))
 t.check(ui.projection_misses.any(func(entry):return entry.point=="card_entry" and entry.key.begins_with(card.type)),"COPY deleted card key is recomputed through the single entry and recorded: "+str(ui.projection_misses))
 t.check(ui.game.export_snapshot()==before,"COPY missing-key rendering never changes state or random cursors")

# docs/spec/candidate-removal.md「失败语义」（批 R2）：拒绝语义不变。三类拒绝（陈旧版本／形状不合法／判定不通过）
# 与五预检各一例，文案逐字、失败全回滚；真实窗口、真实输入，不绕过 UI 入口。
static func g3_reject_probes(g) -> Array:
 return [
  {"name":"Consumables.validate_buffs","break":func():g.state.body_buffs=[{"type":"not_a_tool","group":"torso"}],
   "restore":func():g.state.body_buffs=[]},
  {"name":"Binding.state_issue","break":func():
   if g.state.equipment.is_empty(): g.add_fixture("wrist",7,10)
   g.state.equipment[0].binding={"kind":"no_such_binding"},
   "restore":func():g.state.equipment[0].erase("binding")},
  {"name":"SpecialEquipment.validate","break":func():
   g.state.special_equipment=[{"id":"probe","type":"not_a_special"}],
   "restore":func():g.state.special_equipment=[]},
  {"name":"Cards.validate","break":func():g.state.evasion=-1,
   "restore":func():g.state.evasion=0},
  {"name":"RelicEffects.validate","break":func():g.state.cursed_plate_released="probe",
   "restore":func():g.state.cursed_plate_released=false},
 ]

static func submit_reject_semantics_unchanged(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 var g=ui.game
 var usable=ui.view.display_facts.filter(func(c):return c.valid)
 t.check(not usable.is_empty(),"REJECT fixture exposes a usable command")
 if usable.is_empty(): return
 var version=ui.view.version
 var before=g.export_snapshot()
 # 1) 陈旧 expected_version
 var stale=g.dispatch(g.command(usable[0].payload,version-1),version-1)
 t.check(not stale.ok and String(stale.error)=="状态已更新，请重新选择行动。" and g.export_snapshot()==before,"REJECT stale expected_version keeps its verbatim text and rolls back")
 # 2) 当前状态不可提交的指令形状（表外 kind／键面外参数）
 var unknown=g.dispatch({"kind":"no_such_command","params":{},"expected_version":version},version)
 t.check(not unknown.ok and String(unknown.error)=="该行动已经失效，请重新选择。" and g.export_snapshot()==before,"REJECT an unknown kind keeps its verbatim text and rolls back")
 var forged=g.dispatch({"kind":"end","params":{"label":"probe"},"expected_version":version},version)
 t.check(not forged.ok and String(forged.error)=="该行动已经失效，请重新选择。" and g.export_snapshot()==before,"REJECT a parameter outside the declared face keeps its verbatim text and rolls back")
 # 3) 判定不通过：判定 reason 原文
 var blocked=ui.view.display_facts.filter(func(c):return not c.valid and c.reason!="")
 if not blocked.is_empty():
  var rejected=g.dispatch(g.command(blocked[0].payload,version),version)
  t.check(not rejected.ok and String(rejected.error)==String(blocked[0].reason) and g.export_snapshot()==before,"REJECT a blocked command returns the determination reason verbatim and rolls back")
 # 4) 五预检各一例失败：error 逐字等于该预检文本，失败后全回滚
 for probe in g3_reject_probes(g):
  probe["break"].call()
  var expected=""
  match String(probe.name):
   "Consumables.validate_buffs": expected=g.Consumables.validate_buffs(g,g.state.body_buffs)
   "Binding.state_issue": expected=g.Binding.state_issue(g)
   "SpecialEquipment.validate": expected=g.SpecialEquipment.validate(g.state.special_equipment)
   "Cards.validate": expected=g.Cards.validate(g)
   "RelicEffects.validate": expected=g.RelicEffects.validate(g)
  var frozen=g.export_snapshot()
  var refused=g.dispatch(g.command(usable[0].payload,g.state.version),g.state.version)
  t.check(expected!="" and not refused.ok and String(refused.error)==expected and g.export_snapshot()==frozen,"REJECT precheck keeps its verbatim text and rolls back: "+String(probe.name)+" error="+str(refused.get("error","")))
  probe["restore"].call()

# docs/spec/candidate-removal.md「接口」唯一合法性判定（接管路径；批 R2）：接管路径不变。真实演示入口、真实输入；
# 只有已选步骤可提交，其余显示同一文案；手动输入被接管锁阻挡；换局后旧步骤不提交。
static func takeover_path_unchanged(t) -> void:
 var ui=t.ui
 await t.start_practice("StartDoubaoPractice")
 t.check(ui.view.practice_kind=="doubao" and ui.view.phase=="battle" and ui._takeover_locked(),"TAKEOVER the real practice entry starts the locked takeover")
 var banner=ui.find_child("FirstTurnControlBanner",true,false)
 t.check(banner!=null and banner.text=="豆包接管中","TAKEOVER the banner keeps its text")
 var rows=ui.view.display_facts
 var automated=rows.filter(func(c):return c.get("automated",false))
 var blocked=rows.filter(func(c):return String(c.get("reason",""))=="豆包接管中")
 var still_open=blocked.filter(func(c):c.valid)
 t.check(automated.size()==1 and not blocked.is_empty() and still_open.is_empty(),"TAKEOVER only the selected step is committable and the rest keep the same reason: automated="+str(automated.size())+" blocked="+str(blocked.size())+" open="+str(still_open.map(func(c):return [c.payload,c.valid])))
 if automated.is_empty() or blocked.is_empty(): return
 # 手动输入被挡：真实点击被挡行动 + 同一入口不带接管标记
 var before=ui.game.export_snapshot()
 var button=ui.candidate_buttons.get(String(blocked[0].get("key","")))
 if button!=null:
  var point=button.get_global_rect().get_center()
  await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
  await t.frames()
 t.check(ui.game.export_snapshot()==before,"TAKEOVER a manual click on a blocked step changes nothing")
 ui.command_router.emit(String(blocked[0].payload.get("kind","")),blocked[0],ui.view.version)
 t.check(ui.game.export_snapshot()==before,"TAKEOVER a manual command without the takeover flag is refused by the lock")
 # 只有已选步骤可提交，且经同一入口（takeover 参数语义不变）
 var version=ui.view.version
 var outcome=ui.command_router.emit(String(automated[0].payload.get("kind","")),automated[0],version,true)
 t.check(outcome.submitted and ui.view.version>version,"TAKEOVER the selected step commits through the single entry")
 # 返回首页后旧步骤不提交（首页守卫与接管锁都在同一入口上）
 ui._return_home();await t.frames()
 var home_before=ui.game.export_snapshot()
 ui.command_router.emit(String(automated[0].payload.get("kind","")),automated[0],version)
 t.check(ui.show_home and ui.game.export_snapshot()==home_before,"TAKEOVER a previous step cannot commit after returning home")
 ui.restart(42);await t.frames()

# docs/spec/candidate-removal.md「接口」判据真源（r5_display_facts_match_determination；批 R5 的服务／事件／监狱／路线／奖励／出发域）：夹具矩阵同 R4，
# 另按真实阶段补奖励／路线／出发／demo 四个夹具。文本基线由 G6 的 facts_text 摘要承担（全显示点），
# 这里承担「每个显示点的可用／原因／风险／费用＝唯一判定对同一形状的输出」的逐字段相等与域覆盖。
const R5_G5_GROUPS=["attack","pressure","flow","surrender","posture","wall_move","card","prison","manual","hook","item","chain","retain","relic","flask","status_toggle","service","event","reward","rest_service","route","departure","demo_exit"]
const R5_G5_REQUIRED={"shop":"service","event":"event","prison":"prison","battle":"attack","prepare":"flow","rest":"flow"}

static func r5_group_counts(view: Dictionary) -> Dictionary:
 var counts={}
 for f in view.display_facts:
  var group=String(f.get("group","action"))
  counts[group]=int(counts.get(group,0))+1
 return counts

static func r5_cell_problems(g, name: String, required: Array=[]) -> Array:
 var view=g.get_view()
 var problems=r3_determination_mismatches(g,view,R5_G5_GROUPS)
 if not problems.is_empty(): problems=[name+": "+str(problems.slice(0,2))]
 var counts=r5_group_counts(view)
 for group in required:
  if int(counts.get(group,0))<=0: problems.append(name+" missing "+String(group))
 return problems

static func r5_display_facts_match_determination(t) -> void:
 var problems=[]
 for cell in R4_G5_CELLS:
  var name="%s:%d" % [cell[0],cell[1]]
  problems.append_array(r5_cell_problems(Cases.r1_build(cell[0],cell[1]),name,[String(R5_G5_REQUIRED.get(cell[0],"attack"))]))
 # 奖励阶段：真实战斗胜利后停在奖励屏。
 var reward=Cases.r1_build("battle",12)
 reward._finish_battle("victory")
 problems.append_array(r5_cell_problems(reward,"reward stage",["reward"]))
 # 路线阶段：领完奖励并结束整备后进入塔图（route 显示点与 depart 事实）。
 var route=Cases.r1_build("prepare",12)
 problems.append_array(r5_cell_problems(route,"route stage",["route"]))
 # 出发阶段：新局的出狱起点选择（departure 显示点；其事实组名为 reward／flow，按 kind 核对到达）。
 var departure=preload("res://core/game.gd").new(42)
 var departure_problems=r5_cell_problems(departure,"departure stage",[])
 if not departure.get_view().display_facts.any(func(f):return String(f.payload.get("kind",""))=="departure"): departure_problems.append("departure stage missing departure facts")
 problems.append_array(departure_problems)
 # demo 出口：真实通关夹具的显示点。
 var demo=preload("res://tests/game_fixture.gd").new(42)
 preload("res://tests/demo_exit_cases.gd").exit_fixture(demo)
 problems.append_array(r5_cell_problems(demo,"demo stage",["demo_exit"]))
 t.check(problems.is_empty(),"G5 display_facts_match_determination: every R5 display domain equals the single determination and is really reached: "+str(problems.slice(0,3)))

# ---- 手牌卡增量刷新（hand refresh，本片）：计数只用测试侧实例 id 集合差，不新增生产计数器 ----

# 某卡子树（该 uid 的手牌按钮及其全部后代）的实例 id 集合。
static func present_hand_nodes(button) -> Dictionary:
 var out={}
 if button==null or not is_instance_valid(button): return out
 var pending: Array=[button]
 while not pending.is_empty():
  var node=pending.pop_back()
  out[node.get_instance_id()]=String(node.name)
  for child in node.get_children(): pending.append(child)
 return out

# 每个魔力徽章的 `panel` 样式资源实例 id（按名＋位置），用于"不新建 StyleBox"判据。
static func present_hand_styles(button) -> Dictionary:
 var out={}
 if button==null or not is_instance_valid(button): return out
 var group=button.get_node_or_null("CardMana")
 if group==null: return out
 for badge in group.get_children():
  if not badge.has_theme_stylebox_override("panel"): continue
  out[String(badge.name)+"#"+str(badge.get_index())]=badge.get_theme_stylebox("panel").get_instance_id()
 return out

static func present_hand_children(button) -> Dictionary:
 var out={}
 if button==null or not is_instance_valid(button): return out
 for child in button.get_children(): out[String(child.name)]=child.get_instance_id()
 return out

static func present_hand_lost(before: Dictionary, after: Dictionary) -> Array:
 var out=[]
 for id in before:
  if not after.has(id): out.append(String(before[id]))
 out.sort()
 return out

# Instance ids lost and gained between two subtree maps, ignoring the content labels whose
# destroy/create is allowed when a content slot crosses the empty boundary
# (docs/spec/hand-refresh-dependencies.md, content delta).
static func present_hand_delta(before: Dictionary, after: Dictionary, allowed: Array) -> Dictionary:
 var lost=[]
 var gained=[]
 for id in before:
  if not after.has(id) and not (String(before[id]) in allowed): lost.append(String(before[id]))
 for id in after:
  if not before.has(id) and not (String(after[id]) in allowed): gained.append(String(after[id]))
 lost.sort();gained.sort()
 return {"lost":lost,"gained":gained}

# Per-face usability from the projected hand row: the hand face slice shows the availability line
# exactly when the face is not usable (ui/main.gd::_hand_face_slice).
static func present_hand_usable(row, free: bool) -> bool:
 return bool(row.availability.get("free" if free else "bound",{}).get("usable",true))

# 每张手牌按钮的判据行：实例 id、子树实例集合、徽章样式资源、八个直接子级、位置。
static func present_hand_row(button) -> Dictionary:
 return {"id":button.get_instance_id(),"nodes":present_hand_nodes(button),"styles":present_hand_styles(button),"children":present_hand_children(button),"position":button.position}

static func present_hand_rows(ui) -> Dictionary:
 var out={}
 for uid in ui.card_buttons: out[String(uid)]=present_hand_row(ui.card_buttons[uid])
 return out

# 行几何（与 ui/main.gd::_hand_place_row 同一公式；测试侧独立复算，用于槽位断言）。
static func present_hand_slot(index: int, count: int) -> Vector2:
 var dimensions=preload("res://ui/card_face.gd").dimensions(252)
 var step=minf(dimensions.x+8,746.0/maxi(1,count-1))
 var start=850.0-(float(count-1)*step+dimensions.x)/2
 var mid=float(index)-float(count-1)/2
 return Vector2(start+index*step,630+absf(mid)*4)

static func present_hand_seat(ui, uid: String) -> int:
 for index in range(ui.view.hand.size()):
  if String(ui.view.hand[index].uid)==uid: return index
 return -1

static func present_hand_given(ui, type: String, free: bool) -> Dictionary:
 var card=preload("res://tests/curse_cases.gd").give(ui.game,type)
 ui.card_faces[card.uid]=free
 ui.view=ui.game.get_view()
 ui.present(["hand"])
 return card

static func present_hand_incremental(t) -> void:
 var ui=t.ui
 var face_script=preload("res://ui/card_face.gd")
 var Cards=preload("res://tests/curse_cases.gd")
 var Click=preload("res://tests/curse_ui_cases.gd")
 # ---------- P1 值变只改值 ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 t.check(String(ui.view.phase)=="battle" and ui.view.hand.size()>=3 and not bool(ui.view.pressure.overloaded),"DISPLAY hand refresh fixture is a battle page with a non-overloaded hand")
 var uid=String(ui.view.hand[0].uid)
 if bool(ui.card_faces.get(uid,false)): await t.flip(uid)
 await t.move_mouse(Vector2(1100,90));await t.frames(30)
 var reads=ui.game.view_reads
 var before=ui.game.export_snapshot()
 var faces_before=ui.card_faces.keys();faces_before.sort()
 var base=present_hand_row(ui.card_buttons[uid])
 var face="free" if bool(ui.card_faces.get(uid,false)) else "bound"
 var availability=ui.view.hand[0].availability[face]
 availability.text="probe-hand"
 ui.present(["hand"]);await t.frames()
 var after_key=present_hand_row(ui.card_buttons[uid])
 var faces_after=ui.card_faces.keys();faces_after.sort()
 t.check(after_key.id==base.id,"DISPLAY hand refresh value change keeps the card instance")
 t.check(after_key.nodes==base.nodes,"DISPLAY hand refresh value change keeps the card subtree with zero create and zero destroy: "+str(present_hand_lost(after_key.nodes,base.nodes)))
 t.check(after_key.children==base.children,"DISPLAY hand refresh value change keeps the eight direct children")
 t.check(ui.card_buttons[uid].home==base.position and ui.card_buttons[uid].position==base.position and is_equal_approx(ui.card_buttons[uid].rotation,ui.card_buttons[uid].resting_angle),"DISPLAY hand refresh value change writes no position and keeps the resting angle: "+str(ui.card_buttons[uid].position)+" vs "+str(base.position))
 t.check(String(ui.card_buttons[uid].find_child("CardAvailability",true,false).text).contains("probe-hand") and t.visible_text(ui.card_buttons[uid]).contains("probe-hand"),"DISPLAY hand refresh value change rewrites only its values")
 t.check(ui.card_buttons.size()==ui.view.hand.size() and ui.game.view_reads==reads and faces_after==faces_before,"DISPLAY hand refresh value change keeps one button per uid without reprojecting")
 t.check(ui.game.export_snapshot()==before and ui.card_buttons[uid].drag_payload.version==ui.view.version,"DISPLAY hand refresh value change does not change gameplay state")
 ui.selected_card=uid
 ui.present(["hand"]);await t.frames()
 t.check(ui.card_buttons[uid].chosen and ui.card_buttons[uid].get_node("CardText").scroll_vertical==0,"DISPLAY hand refresh marks the selected card without rebuilding it")
 ui.selected_card=""
 ui.present(["hand"]);await t.frames()
 t.check(not ui.card_buttons[uid].chosen and present_hand_row(ui.card_buttons[uid]).id==base.id,"DISPLAY hand refresh clears the selection mark when the submit drops it")
 # ---------- P2 翻面不重建（含翻回零增删、切片至多构造一次） ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var flip_uid=""
 # The zero create/destroy claim covers a round trip whose starting face carries no conditional
 # content label the other face lacks (a one-sided label would be destroyed on the way out and
 # rebuilt as a new instance on the way back). Pick such a card when one exists, so the judgement
 # is explicit instead of fixture luck; the excluded round trip is pinned by P4 below.
 for card in ui.view.hand:
  if bool(card.single_face): continue
  var bound_shape=[card.face_mana.bound.size(),card.face_keywords.bound.size(),card.face_requirements.bound.size()]
  var free_shape=[card.face_mana.free.size(),card.face_keywords.free.size(),card.face_requirements.free.size()]
  var card_start_free=bool(ui.card_faces.get(String(card.uid),false))
  if bound_shape!=free_shape and (present_hand_usable(card,card_start_free) or not present_hand_usable(card,not card_start_free)): flip_uid=String(card.uid);break
 if flip_uid=="":
  for card in ui.view.hand:
   if bool(card.single_face): continue
   var card_start_free=bool(ui.card_faces.get(String(card.uid),false))
   if present_hand_usable(card,card_start_free) or not present_hand_usable(card,not card_start_free): flip_uid=String(card.uid);break
 if flip_uid=="":
  for card in ui.view.hand:
   if not bool(card.single_face): flip_uid=String(card.uid);break
 t.check(flip_uid!="","DISPLAY hand refresh flip fixture has a non-single-face hand card")
 var flip_row=null
 for card in ui.view.hand:
  if String(card.uid)==flip_uid: flip_row=card
 var flip_start_free=bool(ui.card_faces.get(flip_uid,false))
 var flip_coverage_ok=flip_row!=null and (present_hand_usable(flip_row,flip_start_free) or not present_hand_usable(flip_row,not flip_start_free))
 t.check(flip_coverage_ok,"DISPLAY hand refresh flip fixture starts without a one-sided content label (the zero create/destroy claim holds only for that round trip)")
 var reads_flip=ui.game.view_reads
 var snapshot_flip=ui.game.export_snapshot()
 var flip_base=present_hand_row(ui.card_buttons[flip_uid])
 var flip_face=bool(ui.card_faces.get(flip_uid,false))
 await t.flip(flip_uid)
 var cached=ui._hand_cards[flip_uid].sides.duplicate()
 var flip_type=""
 for card in ui.view.hand:
  if String(card.uid)==flip_uid: flip_type=String(card.type)
 t.check(ui.card_buttons[flip_uid].get_instance_id()==flip_base.id and ui.card_buttons[flip_uid].free_face!=flip_face,"DISPLAY hand refresh flip keeps the card instance and switches the face")
 t.check(present_hand_children(ui.card_buttons[flip_uid])==flip_base.children,"DISPLAY hand refresh flip keeps the eight direct children")
 t.check(t.visible_text(ui.card_buttons[flip_uid]).contains(ui.game.Cards.face_text(ui.game,flip_type,not flip_face,flip_uid)),"DISPLAY hand refresh flip shows the current face copy")
 t.check(cached.has("bound") and cached.has("free"),"DISPLAY hand refresh flip caches one slice per face")
 await t.flip(flip_uid)
 var flip_back=present_hand_row(ui.card_buttons[flip_uid])
 t.check(flip_back.id==flip_base.id and flip_back.nodes==flip_base.nodes and flip_back.styles==flip_base.styles,"DISPLAY hand refresh flip back restores the same subtree and styles with zero create and zero destroy: "+str(present_hand_lost(flip_back.nodes,flip_base.nodes)))
 t.check(is_same(cached.bound,ui._hand_cards[flip_uid].sides.bound) and is_same(cached.free,ui._hand_cards[flip_uid].sides.free),"DISPLAY hand refresh flip back reuses the cached face slices (at most one build per card and side)")
 t.check(ui.game.view_reads==reads_flip and ui.game.export_snapshot()==snapshot_flip,"DISPLAY hand refresh flip does not reproject or change gameplay state")
 # 两面同 kind 的魔力条目：只改文本，徽章节点与 `panel` 样式资源实例 id 不变。
 var steady=present_hand_given(ui,"sensitive",false)
 await t.frames()
 var steady_before=present_hand_row(ui.card_buttons[steady.uid])
 if not bool(ui.card_faces.get(steady.uid,false)): await t.flip(steady.uid)
 var swap_before=present_hand_row(ui.card_buttons[steady.uid])
 await t.flip(steady.uid)
 var swap_after=present_hand_row(ui.card_buttons[steady.uid])
 t.check(swap_after.id==swap_before.id and swap_after.styles==swap_before.styles,"DISPLAY hand refresh flip keeps unchanged mana badges and their panel styles: "+str(swap_before.styles)+" vs "+str(swap_after.styles))
 t.check(not steady_before.nodes.is_empty() and swap_after != {} and swap_after.id==swap_before.id,"DISPLAY hand refresh keeps the given card instance across both faces")
 # ---------- P3 顺序变仅重排（幂等） ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var order_before=ui.card_buttons.keys()
 var rows_before=present_hand_rows(ui)
 var ids_before={}
 for key in rows_before: ids_before[key]=rows_before[key].id
 ui.view.hand.reverse()
 ui.present(["hand"]);await t.frames()
 var rows_after=present_hand_rows(ui)
 var instable=true
 for key in rows_after: instable=instable and rows_after[key].id==ids_before[key]
 var seat_ok=true
 for index in range(ui.view.hand.size()):
  var seat_uid=String(ui.view.hand[index].uid)
  seat_ok=seat_ok and rows_after[seat_uid].position==present_hand_slot(index,ui.view.hand.size())
 t.check(instable,"DISPLAY hand refresh reorder keeps every surviving card instance")
 t.check(seat_ok,"DISPLAY hand refresh reorder swaps cards into the new row slots")
 var created_reorder=0
 for key in rows_after: created_reorder+=present_hand_lost(rows_after[key].nodes,rows_before[key].nodes).size()
 t.check(created_reorder==0,"DISPLAY hand refresh reorder creates no node")
 var settled=present_hand_rows(ui)
 ui.present(["hand"]);await t.frames()
 var rows_again=present_hand_rows(ui)
 t.check(rows_again==settled,"DISPLAY hand refresh second present writes nothing (positions, instances and subtrees unchanged)")
 t.check(order_before.size()==ui.card_buttons.size(),"DISPLAY hand refresh reorder keeps the row size")
 # ---------- P4 content delta across the empty boundary: only that content label may be rebuilt ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var delta_uid=""
 for card in ui.view.hand:
  if not bool(card.single_face): delta_uid=String(card.uid);break
 if delta_uid=="": delta_uid=String(ui.view.hand[0].uid)
 var delta_row=null
 for card in ui.view.hand:
  if String(card.uid)==delta_uid: delta_row=card
 var delta_face="free" if bool(ui.card_faces.get(delta_uid,false)) else "bound"
 var delta_button=ui.card_buttons[delta_uid]
 # Normalise to the usable state first: the starting line, if the fixture had one, is a delta of
 # its own and must not leak into the baseline below.
 delta_row.availability[delta_face].usable=true
 delta_row.availability[delta_face].text=""
 delta_row.availability[delta_face].dim=false
 ui.present(["hand"]);await t.frames()
 t.check(delta_button.find_child("CardAvailability",true,false)==null,"DISPLAY hand refresh content-delta fixture starts with no availability line")
 var delta_base=present_hand_row(delta_button)
 delta_row.availability[delta_face].usable=false
 delta_row.availability[delta_face].text="（内容差额探针）"
 delta_row.availability[delta_face].dim=true
 ui.present(["hand"]);await t.frames()
 var line_first=delta_button.find_child("CardAvailability",true,false)
 t.check(line_first!=null and String(line_first.text)=="（内容差额探针）","DISPLAY hand refresh mounts the availability line when the face becomes unusable")
 var with_line=present_hand_row(delta_button)
 var mounted_delta=present_hand_delta(delta_base.nodes,with_line.nodes,["CardAvailability"])
 t.check(mounted_delta.lost.is_empty() and mounted_delta.gained.is_empty() and with_line.id==delta_base.id and with_line.children==delta_base.children and with_line.position==delta_base.position,"DISPLAY hand refresh an appearing availability adds only that content label: "+str(mounted_delta))
 # Same occupancy, new value: zero create and zero destroy.
 delta_row.availability[delta_face].text="（内容差额探针二）"
 ui.present(["hand"]);await t.frames()
 t.check(present_hand_row(delta_button).nodes==with_line.nodes and String(delta_button.find_child("CardAvailability",true,false).text)=="（内容差额探针二）","DISPLAY hand refresh rewrites the line in place while it stays mounted")
 delta_row.availability[delta_face].usable=true
 delta_row.availability[delta_face].text=""
 delta_row.availability[delta_face].dim=false
 ui.present(["hand"]);await t.frames()
 var cleared=present_hand_row(delta_button)
 var cleared_delta=present_hand_delta(with_line.nodes,cleared.nodes,["CardAvailability"])
 t.check(delta_button.find_child("CardAvailability",true,false)==null and (not is_instance_valid(line_first) or line_first.is_queued_for_deletion()),"DISPLAY hand refresh clearing the availability drops that instance")
 t.check(cleared_delta.lost.is_empty() and cleared_delta.gained.is_empty() and cleared.id==delta_base.id and cleared.children==delta_base.children,"DISPLAY hand refresh clearing the availability removes only that content label: "+str(cleared_delta))
 delta_row.availability[delta_face].usable=false
 delta_row.availability[delta_face].text="（内容差额探针三）"
 delta_row.availability[delta_face].dim=true
 ui.present(["hand"]);await t.frames()
 var line_again=delta_button.find_child("CardAvailability",true,false)
 var refilled=present_hand_row(delta_button)
 var refill_delta=present_hand_delta(cleared.nodes,refilled.nodes,["CardAvailability"])
 t.check(line_again!=null and line_again!=line_first and String(line_again.text)=="（内容差额探针三）","DISPLAY hand refresh rebuilds the availability line instead of re-inserting the freed instance")
 t.check(refill_delta.lost.is_empty() and refill_delta.gained.is_empty() and refilled.id==delta_base.id and refilled.children==delta_base.children,"DISPLAY hand refresh refilling the availability adds only that content label: "+str(refill_delta))
 # Across faces: one face unusable and the other usable, so the round trip crosses the boundary.
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var cross_uid=""
 for card in ui.view.hand:
  if not bool(card.single_face): cross_uid=String(card.uid);break
 t.check(cross_uid!="","DISPLAY hand refresh cross-face fixture has a non-single-face hand card")
 var cross_face="free" if bool(ui.card_faces.get(cross_uid,false)) else "bound"
 var cross_other="bound" if cross_face=="free" else "free"
 var cross_row=null
 for card in ui.view.hand:
  if String(card.uid)==cross_uid: cross_row=card
 cross_row.availability[cross_face]["usable"]=false
 cross_row.availability[cross_face]["dim"]=true
 cross_row.availability[cross_face]["text"]="（跨面探针）"
 cross_row.availability[cross_other]["usable"]=true
 cross_row.availability[cross_other]["dim"]=false
 cross_row.availability[cross_other]["text"]=""
 ui.present(["hand"]);await t.frames()
 var cross_button=ui.card_buttons[cross_uid]
 var cross_line=cross_button.find_child("CardAvailability",true,false)
 t.check(cross_line!=null and String(cross_line.text)=="（跨面探针）","DISPLAY hand refresh cross-face fixture shows the line on the unusable face")
 var cross_before=present_hand_row(cross_button)
 await t.flip(cross_uid)
 var cross_on_other=present_hand_row(cross_button)
 var other_delta=present_hand_delta(cross_before.nodes,cross_on_other.nodes,["CardAvailability"])
 t.check(cross_button.find_child("CardAvailability",true,false)==null and other_delta.lost.is_empty() and other_delta.gained.is_empty() and cross_on_other.id==cross_before.id and cross_on_other.children==cross_before.children,"DISPLAY hand refresh flipping onto the usable face removes only that content label: "+str(other_delta))
 await t.flip(cross_uid)
 var cross_back_line=cross_button.find_child("CardAvailability",true,false)
 var cross_back=present_hand_row(cross_button)
 var back_delta=present_hand_delta(cross_on_other.nodes,cross_back.nodes,["CardAvailability"])
 t.check(cross_back_line!=null and cross_back_line!=cross_line and String(cross_back_line.text)=="（跨面探针）","DISPLAY hand refresh flipping back rebuilds the line instead of re-inserting it")
 t.check(back_delta.lost.is_empty() and back_delta.gained.is_empty() and cross_back.id==cross_before.id and cross_back.children==cross_before.children,"DISPLAY hand refresh flipping back across unequal occupancy rebuilds only that content label: "+str(back_delta))
 # ---------- E7 draw_serial 变、面不变 ⇒ 零写入 ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var serial_uid=String(ui.view.hand[0].uid)
 var serial_seat=present_hand_seat(ui,serial_uid)
 var serial_face=bool(ui.card_faces.get(serial_uid,false))
 var serial_row=present_hand_row(ui.card_buttons[serial_uid])
 var serial_key=ui._hand_presentation_key()
 ui.view.hand[serial_seat].draw_serial=int(ui.view.hand[serial_seat].get("draw_serial",0))+1
 ui.present(["hand"]);await t.frames()
 t.check(ui._hand_presentation_key()!=serial_key,"DISPLAY hand refresh moves the row key when only the draw serial changes")
 t.check(bool(ui.card_faces.get(serial_uid,false))==serial_face and present_hand_row(ui.card_buttons[serial_uid])==serial_row,"DISPLAY hand refresh rewrites nothing when only the draw serial changes (the row key moved, the face slice did not)")
 # ---------- E8 抽牌换面 ⇒ 值更新（不重建） ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var draw_uid=String(ui.view.hand[0].uid)
 var draw_face=bool(ui.card_faces.get(draw_uid,false))
 var draw_base=present_hand_row(ui.card_buttons[draw_uid])
 var draw_key=ui._hand_presentation_key()
 ui.card_draw_serials[draw_uid]=int(ui.card_draw_serials.get(draw_uid,0))-1
 for index in range(ui.view.hand.size()):
  if String(ui.view.hand[index].uid)==draw_uid: ui.view.hand[index].draw_free=not draw_face
 ui.present(["hand"]);await t.frames()
 var draw_after=present_hand_row(ui.card_buttons[draw_uid])
 t.check(bool(ui.card_faces.get(draw_uid,false))!=draw_face and ui.card_buttons[draw_uid].free_face==bool(ui.card_faces.get(draw_uid,false)),"DISPLAY hand refresh applies a new draw face")
 t.check(ui._hand_presentation_key()!=draw_key,"DISPLAY hand refresh moves the row key on a draw face change")
 t.check(draw_after.id==draw_base.id and draw_after.children==draw_base.children,"DISPLAY hand refresh applies a new draw face without rebuilding the card: instance "+str(draw_after.id)+" vs "+str(draw_base.id))
 # ---------- E4 与卡面无关的设置项变：零动作 ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var quiet_before=present_hand_rows(ui)
 var reads_quiet=ui.game.view_reads
 ui.display_settings.set_frame_limit(0)
 ui.display_settings.set_vsync(false)
 ui.present(["hand"]);await t.frames()
 t.check(present_hand_rows(ui)==quiet_before,"DISPLAY hand refresh ignores unrelated display settings")
 t.check(ui.game.view_reads==reads_quiet,"DISPLAY hand refresh ignores unrelated display settings without reprojecting")
 ui.display_settings.set_frame_limit(60)
 ui.display_settings.set_vsync(true)
 # ---------- E3 语言切换的键覆盖（局部路径） ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var locale_uid=String(ui.view.hand[0].uid)
 var locale_before=t.visible_text(ui.card_buttons[locale_uid])
 ui.display_settings.set_locale("en_US")
 ui.localization.set_locale("en_US")
 ui.present(["hand"]);await t.frames()
 var locale_en=t.visible_text(ui.card_buttons[locale_uid])
 t.check(locale_en!=locale_before and not locale_en.contains("可用"),"DISPLAY hand refresh key covers the locale on a local path: "+locale_en.substr(0,60))
 ui.display_settings.set_locale("zh_CN")
 ui.localization.set_locale("zh_CN")
 ui.present(["hand"]);await t.frames()
 t.check(t.visible_text(ui.card_buttons[locale_uid])==locale_before,"DISPLAY hand refresh restores the Chinese copy after the local locale round trip")
 # ---------- N5 语言切换（唯一入口的全量路径） ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var lang_uid=String(ui.view.hand[0].uid)
 var lang_zh=t.visible_text(ui.card_buttons[lang_uid])
 ui._set_language("en_US")
 await t.frames()
 t.check(ui.card_buttons.size()==ui.view.hand.size() and present_hand_live_count(ui,lang_uid)==1,"DISPLAY hand refresh follows a language switch with a complete row")
 t.check(not t.visible_text(ui.card_buttons[lang_uid]).contains("拘束"),"DISPLAY hand refresh follows a language switch without stale card copy")
 ui._set_language("zh_CN")
 await t.frames()
 t.check(t.visible_text(ui.card_buttons[lang_uid])==lang_zh,"DISPLAY hand refresh returns to the Chinese copy through the single entry")
 # ---------- E1 同提交多字段变 ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var many_uid=String(ui.view.hand[2].uid)
 if bool(ui.card_faces.get(many_uid,false)): await t.flip(many_uid)
 var many_face="free" if bool(ui.card_faces.get(many_uid,false)) else "bound"
 var many_base=present_hand_row(ui.card_buttons[many_uid])
 var many_row=null
 var many_type=""
 for card in ui.view.hand:
  if String(card.uid)==many_uid: many_row=card;many_type=String(card.type)
 var many_sources=[ui.view.card_texts[many_type]]
 if ui.view.card_instances.has(many_uid): many_sources.append(ui.view.card_instances[many_uid])
 many_row.name="多字段探针"
 many_row.cost="7"
 many_row.availability[many_face].text="探针可用性"
 many_row.availability[many_face].usable=false
 var extra_mana=many_sources[0].face_mana[many_face]+[{"kind":"temporary","text":"+3","detail":"探针。"}]
 var extra_keywords=Array(many_sources[0].face_keywords[many_face])+[{"name":"探针词条","detail":"探针。"}]
 var extra_effect=String(many_sources[0].face_effects[many_face])+"附加探针。探针词条。"
 for source in many_sources:
  source.face_mana[many_face]=extra_mana
  source.face_keywords[many_face]=extra_keywords
  source.face_effects[many_face]=extra_effect
  source.face_costs[many_face]="7"
 ui.present(["hand"]);await t.frames()
 var many_after=present_hand_row(ui.card_buttons[many_uid])
 var many=ui.card_buttons[many_uid]
 t.check(many_after.id==many_base.id and many_after.children==many_base.children,"DISPLAY hand refresh applies many field changes in one pass without rebuilding the face")
 t.check(String(many.get_node("CardCost").text)=="7" and String(many.get_node("CardTitle").text).contains("多字段探针"),"DISPLAY hand refresh applies the title and cost in place")
 t.check(many.get_node("CardMana").get_child_count()==extra_mana.size(),"DISPLAY hand refresh keeps one mana badge per entry: "+str(many.get_node("CardMana").get_child_count())+" vs "+str(extra_mana.size()))
 var expected_tags=face_script.separate_keywords(extra_effect,extra_keywords)
 var expected_tag_count=expected_tags.keywords.size()+(1 if bool(many_row.get("retained",false)) and "保留" not in expected_tags.keywords else 0)
 t.check(many.get_node("CardKeywords").get_child_count()==expected_tag_count,"DISPLAY hand refresh keeps one keyword tag per entry: "+str(many.get_node("CardKeywords").get_child_count())+" vs "+str(expected_tag_count))
 t.check(t.visible_text(many).contains("附加探针") and t.visible_text(many).contains("探针词条") and t.visible_text(many).contains("探针可用性"),"DISPLAY hand refresh shows every changed field")
 t.check(many.get_node("CardText").get_rect().end.y<=many.size.y and many.get_node("CardTitle").get_rect().end.x<=many.size.x,"DISPLAY hand refresh lays the changed fields out once")
 # ---------- E9 一致性守卫失灵只修一张 ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var broken_uid=String(ui.view.hand[1].uid)
 if not bool(ui.card_faces.get(broken_uid,false)):
  ui.card_faces[broken_uid]=true
  ui.present(["hand"])
  await t.frames()
 t.check(bool(ui.card_faces.get(broken_uid,false)) and ui.card_buttons[broken_uid].free_face,"DISPLAY hand refresh broken-card fixture starts on the turned face")
 var intact={}
 for key in ui.card_buttons:
  if String(key)!=broken_uid: intact[String(key)]=present_hand_row(ui.card_buttons[key])
 # 选择态下登记的候选键 + 一条指向同一按钮的幽灵行：外部释放后都不得留下悬空条目。
 ui.candidate_buttons["probe|"+broken_uid]=ui.card_buttons[broken_uid]
 ui.card_buttons["card_ghost"]=ui.card_buttons[broken_uid]
 ui.card_buttons[broken_uid].queue_free()
 await t.frames(3)
 var reads_broken=ui.game.view_reads
 ui.present(["hand"]);await t.frames()
 var intact_after=true
 for key in intact: intact_after=intact_after and present_hand_row(ui.card_buttons[key])==intact[key]
 t.check(ui.card_buttons.has(broken_uid) and is_instance_valid(ui.card_buttons[broken_uid]) and present_hand_live_count(ui,broken_uid)==1,"DISPLAY hand refresh repairs only the broken card")
 t.check(ui.card_buttons[broken_uid].free_face and bool(ui.card_faces.get(broken_uid,false)),"DISPLAY hand refresh keeps the turned face across a same-row release and mount")
 t.check(not ui.candidate_buttons.has("probe|"+broken_uid) and ui.candidate_buttons.values().all(func(button):return is_instance_valid(button)),"DISPLAY hand refresh drops the stale candidate entry of a released button")
 t.check(not ui.card_buttons.has("card_ghost"),"DISPLAY hand refresh drops a non-member row without mounting it")
 t.check(intact_after,"DISPLAY hand refresh repair leaves every other card untouched")
 t.check(ui.game.view_reads==reads_broken and ui.card_buttons.size()==ui.view.hand.size(),"DISPLAY hand refresh repair does not reproject")
 # ---------- E5 手牌清空与从空恢复 ----------
 ui.restart(42);ui.game.state.equipment.clear();ui.game._discard_end()
 ui.game.state.wall="normal"
 ui.game.add_fixture("ankle",400,1000)
 var last=Cards.give(ui.game,"strain")
 ui.game.state.hand=[last]
 ui.selected_slot="wrist"
 ui.card_faces[last.uid]=false
 ui.view=ui.game.get_view()
 ui.render();await t.frames()
 t.check(ui.view.hand.size()==1 and ui.card_buttons.has(last.uid),"DISPLAY hand refresh empty fixture starts with exactly one card")
 await Click.click_card(t,last.uid);await t.frames()
 t.check(ui.view.hand.is_empty() and ui.card_buttons.is_empty() and present_named_live_count(ui,"EmptyHand")==1,"DISPLAY hand refresh mounts the empty row when the last card leaves")
 t.check(not ui.card_faces.has(last.uid) and not ui.card_draw_serials.has(last.uid) and not ui._hand_cards.has(last.uid),"DISPLAY hand refresh drops every per-uid table when the last card leaves")
 t.check(present_named_live_count(ui,"HandCard_*")==0 and ui.find_children("HandCard_*","",true,false).is_empty(),"DISPLAY hand refresh leaves no live hand card when the row is empty")
 var drawn=Cards.give(ui.game,"slip")
 ui.card_faces[drawn.uid]=false
 ui.view=ui.game.get_view()
 ui.present(["hand"]);await t.frames()
 t.check(present_named_live_count(ui,"EmptyHand")==0 and ui.card_buttons.has(drawn.uid) and present_hand_live_count(ui,drawn.uid)==1,"DISPLAY hand refresh unmounts the empty row when a card comes back")
 var restored=present_hand_row(ui.card_buttons[drawn.uid])
 ui.present(["hand"]);await t.frames()
 t.check(present_hand_row(ui.card_buttons[drawn.uid])==restored,"DISPLAY hand refresh empty-to-card transition registers the row key")
 # ---------- E6 满手牌 ----------
 ui.restart(42);await t.frames(8)
 ui.game.state.hand=[]
 for index in range(10): ui.game._gain_card("strain" if index%2==0 else "slip",{},true)
 ui.view=ui.game.get_view()
 ui.render(ui.view);await t.frames()
 var full_before=present_hand_rows(ui)
 t.check(ui.view.hand.size()==10 and ui.card_buttons.size()==10,"DISPLAY hand refresh full-hand fixture holds ten cards")
 var full_uid=String(ui.view.hand[0].uid)
 var full_face="free" if bool(ui.card_faces.get(full_uid,false)) else "bound"
 ui.view.hand[0].availability[full_face].text="满手牌探针"
 ui.present(["hand"]);await t.frames()
 var full_after=present_hand_rows(ui)
 t.check(full_after[full_uid].nodes==full_before[full_uid].nodes,"DISPLAY hand refresh keeps a full hand stable on a value change")
 var full_geometry=true
 for index in range(ui.view.hand.size()):
  full_geometry=full_geometry and full_after[String(ui.view.hand[index].uid)].position==present_hand_slot(index,ui.view.hand.size())
 t.check(full_geometry,"DISPLAY hand refresh keeps the full-hand row geometry")
 var full_positions={}
 for key in full_after: full_positions[key]=full_after[key].position
 ui.game._gain_card("ease",{},true)
 ui.view=ui.game.get_view()
 ui.present(["hand"]);await t.frames()
 var capped=true
 for key in ui.card_buttons: capped=capped and ui.card_buttons[key].position==full_positions.get(String(key),ui.card_buttons[key].position)
 t.check(ui.view.hand.size()==10 and ui.card_buttons.size()==10 and capped,"DISPLAY hand refresh keeps ten cards and their positions when the draw is capped")
 # ---------- N1／E2 出牌与抽牌同提交：只动涉及 uid ----------
 ui.restart(42);ui.game.state.equipment.clear();ui.game._discard_end()
 ui.game.state.wall="normal"
 var ankle=ui.game.add_fixture("ankle",400,1000)
 var playable=Cards.give(ui.game,"strain")
 var play_uid=String(playable.uid)
 ui.selected_slot="wrist"
 ui.card_faces[play_uid]=false
 ui.render();await t.frames()
 t.check(ui.view.hand.any(func(c):return String(c.uid)==play_uid),"DISPLAY hand refresh play fixture holds the chosen card in the current view")
 var survivors={}
 for key in ui.card_buttons:
  if String(key)!=play_uid: survivors[String(key)]=present_hand_row(ui.card_buttons[key])
 var survivors_ids={}
 for key in survivors: survivors_ids[key]=survivors[key].id
 var reads_play=ui.game.view_reads
 var version_play=ui.view.version
 await Click.click_card(t,play_uid);await t.frames()
 t.check(ui.view.version>version_play,"DISPLAY hand refresh play fixture commits the click: version "+str(version_play)+" -> "+str(ui.view.version))
 t.check(not ui.card_buttons.has(play_uid),"DISPLAY hand refresh removes the played card and only it")
 t.check(not ui.card_faces.has(play_uid) and not ui.card_draw_serials.has(play_uid) and not ui._hand_cards.has(play_uid),"DISPLAY hand refresh drops the played card from every per-uid table")
 var untouched=true
 var reused=0
 for key in survivors:
  var now=ui.card_buttons.get(key)
  if now==null:
   continue
  if present_hand_row(now).id!=survivors_ids[key]: untouched=false
  reused+=present_hand_lost(present_hand_nodes(now),survivors[key].nodes).size()
 t.check(untouched and reused==0,"DISPLAY hand refresh keeps every surviving card instance and creates no node for them: "+str(reused))
 t.check(ui.card_buttons.size()==ui.view.hand.size() and ui.game.view_reads>reads_play,"DISPLAY hand refresh keeps one button per remaining uid after the play")
 t.check(ui._hand_cards.keys().size()==ui.view.hand.size() and ui.card_buttons.keys().all(func(key):return ui._hand_cards.has(String(key))),"DISPLAY hand refresh keeps every per-uid table aligned with the hand")
 # ---------- 过载行态（S8：climax 面板替换整行，随后恢复） ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 ui.view.pressure.overloaded=true
 ui.present(["hand"]);await t.frames()
 t.check(present_named_live_count(ui,"ClimaxNarration")==1 and ui.card_buttons.is_empty() and ui._hand_cards.is_empty(),"DISPLAY hand refresh mounts the climax row when the pressure overloads")
 t.check(ui.find_children("HandCard_*","",true,false).is_empty(),"DISPLAY hand refresh unmounts the card row on the climax row")
 ui.view.pressure.overloaded=false
 ui.present(["hand"]);await t.frames()
 t.check(present_named_live_count(ui,"ClimaxNarration")==0 and ui.card_buttons.size()==ui.view.hand.size(),"DISPLAY hand refresh returns to the card row after the overload ends")
 # ---------- 计数同提交（E2：出牌＋抽牌同一次提交） ----------
 ui.restart(42);ui.game.state.equipment.clear();ui.game._discard_end()
 ui.game.state.wall="normal"
 ui.game.add_fixture("ankle",400,1000)
 var kept_card=Cards.give(ui.game,"kip_up")
 var discarded_card=Cards.give(ui.game,"strain")
 var discarded_uid=String(discarded_card.uid)
 var kept_uid=String(kept_card.uid)
 ui.view=ui.game.get_view()
 ui.render(ui.view);await t.frames()
 t.check(ui.view.hand.any(func(c):return String(c.uid)==kept_uid) and ui.view.hand.any(func(c):return String(c.uid)==discarded_uid),"DISPLAY hand refresh combo fixture holds the retained and the discarded card")
 var combo_before=present_hand_rows(ui)
 var combo_version=ui.view.version
 t.check(await t.click("end",{},false),"DISPLAY hand refresh combo fixture submits the end turn without settling")
 await t.frames(2,false)
 var pending_uid=""
 if is_instance_valid(ui.card_motion):
  for key in ui.card_motion.pending_draws: pending_uid=String(key)
 t.check(pending_uid!="" and ui.card_buttons.has(pending_uid) and not ui.card_buttons[pending_uid].visible,"DISPLAY hand refresh hides the pending draw while it animates: "+pending_uid)
 var pending_id=ui.card_buttons[pending_uid].get_instance_id() if ui.card_buttons.has(pending_uid) else 0
 if ui.card_buttons.has(pending_uid):
  for card in ui.view.hand:
   if String(card.uid)==pending_uid:
    var pending_face="free" if bool(ui.card_faces.get(pending_uid,false)) else "bound"
    card.availability[pending_face].text="pending-probe"
  ui.present(["hand"])
  await t.frames(2,false)
 t.check(ui.card_buttons.has(pending_uid) and ui.card_buttons[pending_uid].get_instance_id()==pending_id and not ui.card_buttons[pending_uid].visible,"DISPLAY hand refresh keeps the pending draw instance across a local refresh")
 await t.frames(20)
 t.check(ui.card_buttons.has(pending_uid) and ui.card_buttons[pending_uid].get_instance_id()==pending_id and ui.card_buttons[pending_uid].visible,"DISPLAY hand refresh shows the pending draw after the animation on the same instance")
 var combo_new=ui.card_buttons.keys().filter(func(key):return not combo_before.has(String(key)))
 var combo_gone=combo_before.keys().filter(func(key):return not ui.card_buttons.has(String(key)))
 var combo_touched=present_hand_rows(ui).keys().filter(func(key):return combo_before.has(String(key)) and present_hand_row(ui.card_buttons[key]).id!=combo_before[key].id)
 t.check(ui.view.version>combo_version and not combo_gone.is_empty() and not combo_new.is_empty(),"DISPLAY hand refresh handles a simultaneous remove and draw: gone="+str(combo_gone)+" new="+str(combo_new))
 t.check(ui.card_buttons.has(kept_uid) and present_hand_row(ui.card_buttons[kept_uid]).id==combo_before[kept_uid].id,"DISPLAY hand refresh keeps the retained card instance across the end turn")
 t.check(combo_touched.is_empty(),"DISPLAY hand refresh rebuilds no surviving card on a remove plus draw commit: "+str(combo_touched))
 t.check(ui._hand_cards.keys().size()==ui.view.hand.size(),"DISPLAY hand refresh keeps the hand cache aligned after a remove plus draw commit")
 # ---------- 悬停详情读当前数据（不是挂载快照） ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var hover_uid=""
 var hover_seat=-1
 for index in range(ui.view.hand.size()):
  var hover_row=ui.view.hand[index]
  var hover_side="free" if bool(ui.card_faces.get(String(hover_row.uid),false)) else "bound"
  if bool(hover_row.get("cast_faces",{}).get(hover_side,false)):
   hover_uid=String(hover_row.uid);hover_seat=index;break
 t.check(hover_uid!="","DISPLAY hand refresh hover fixture has a spell hand card whose current face casts")
 await t.move_mouse(Vector2(1100,90));await t.frames()
 # 焦点与旧弹层都清掉：否则  的延迟重入会用当前数据补弹层，掩盖闭包路径。
 ui.card_buttons[hover_uid].release_focus()
 ui.get_viewport().gui_release_focus()
 var hover_face="free" if bool(ui.card_faces.get(hover_uid,false)) else "bound"
 var hover_type=String(ui.view.hand[hover_seat].type)
 var hover_texts=ui.view.card_texts[hover_type]
 # 整个 `face_casting`／`casting` 换成新字典：浅拷贝共享同一对象，只改内层字段会让挂载快照一起变，
 # 那样就掩盖了闭包路径（本条的靶子）。
 for source in [hover_texts,ui.view.card_instances.get(hover_uid,{})]:
  if source.has("face_casting"):
   var casting_faces={}
   for face_key in source.face_casting:
    var face_copy=(source.face_casting[face_key] as Dictionary).duplicate()
    if String(face_key)==hover_face: face_copy.percent="0%"
    casting_faces[face_key]=face_copy
   source.face_casting=casting_faces
  if source.has("casting"):
   var profile_copy=(source.casting as Dictionary).duplicate()
   profile_copy.percent="0%"
   source.casting=profile_copy
 ui.present(["hand"]);await t.frames()
 await t.move_mouse(t.card_point(hover_uid));await t.frames()
 t.check(ui.find_child("TermExplanation",true,false)!=null and t.visible_text(ui.term_popup).contains("施法成功率 · 0%"),"DISPLAY hand refresh keeps the hover detail on the current casting copy: "+t.visible_text(ui.term_popup).substr(0,80))
 await t.move_mouse(Vector2(1100,90));await t.frames()
 # ---------- E10 源文本判据：手牌行只有一条例程 ----------
 present_hand_source_text(t)
 # ---------- N2 type 变只重建该 uid ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var swap_uid=String(ui.view.hand[0].uid)
 var keep_uid=String(ui.view.hand[1].uid)
 var keep_row=present_hand_row(ui.card_buttons[keep_uid])
 var swap_id=ui.card_buttons[swap_uid].get_instance_id()
 if not bool(ui.card_faces.get(swap_uid,false)):
  ui.card_faces[swap_uid]=true
  ui.present(["hand"])
  await t.frames()
 ui.view.hand[0].type="concentration"
 ui.view.hand[0].name="凝神"
 ui.view.hand[0].cost="1"
 ui.present(["hand"]);await t.frames()
 t.check(ui.card_buttons.has(swap_uid) and ui.card_buttons[swap_uid].get_instance_id()!=swap_id,"DISPLAY hand refresh rebuilds exactly the card whose type changed")
 t.check(present_hand_row(ui.card_buttons[keep_uid])==keep_row,"DISPLAY hand refresh type change leaves every other card untouched")
 t.check(String(ui.card_buttons[swap_uid].symbol)=="concentration","DISPLAY hand refresh type change shows the new symbol")
 t.check(ui.card_buttons[swap_uid].free_face and bool(ui.card_faces.get(swap_uid,false)),"DISPLAY hand refresh type change keeps the turned face across the rebuild")
 # ---------- N3 行矩变（收窄口径：不重建） ----------
 ui.restart(42);ui.game.state.equipment.clear();ui.game._discard_end()
 ui.game.state.wall="normal"
 ui.game.add_fixture("ankle",400,1000)
 var retreat=Cards.give(ui.game,"strain")
 ui.selected_slot="wrist"
 ui.card_faces[String(retreat.uid)]=false
 ui.render();await t.frames()
 var count_before=ui.view.hand.size()
 var row_before=present_hand_rows(ui)
 await Click.click_card(t,String(retreat.uid));await t.frames()
 t.check(ui.view.hand.size()==count_before-1,"DISPLAY hand refresh row geometry fixture removes exactly one card: "+str(count_before)+" -> "+str(ui.view.hand.size()))
 var geometry_ok=true
 var kept=0
 for key in ui.card_buttons:
  var index=present_hand_seat(ui,String(key))
  if index<0: continue
  kept+=1
  geometry_ok=geometry_ok and ui.card_buttons[key].position==present_hand_slot(index,ui.view.hand.size())
  geometry_ok=geometry_ok and ui.card_buttons[key].home==ui.card_buttons[key].position
 t.check(kept==ui.view.hand.size() and geometry_ok,"DISPLAY hand refresh places row geometry in place after a member change")
 var row_after=present_hand_rows(ui)
 var row_rebuilt=[]
 for key in row_after:
  if row_before.has(key) and row_after[key].id!=row_before[key].id: row_rebuilt.append(key)
 t.check(row_rebuilt.is_empty(),"DISPLAY hand refresh does not rebuild surviving cards when the row geometry changes: "+str(row_rebuilt))
 # ---------- N4 卡面画风变：就地换图 ----------
 ui.restart(42);await t.frames(8)
 ui.render(ui.view);await t.frames()
 var art_card=present_hand_given(ui,"strain",false)
 await t.frames()
 var art_uid=String(art_card.uid)
 var art_row=present_hand_row(ui.card_buttons[art_uid])
 var art_tex=ui.card_buttons[art_uid].get_node("CardIllustration").texture
 ui.display_settings.set_art_style("cards","strain","test")
 ui.present(["hand"]);await t.frames()
 var fallback=ui.card_buttons[art_uid].get_node("CardIllustration").texture
 t.check(ui.card_buttons[art_uid].get_instance_id()==art_row.id and present_hand_nodes(ui.card_buttons[art_uid])==art_row.nodes,"DISPLAY hand refresh swaps card art in place when the display style changes")
 t.check(fallback!=art_tex and fallback==face_script.ILLUSTRATIONS.get("strain"),"DISPLAY hand refresh falls back to the built-in illustration for the test style")
 ui.display_settings.set_art_style("cards","strain","formal")
 ui.present(["hand"]);await t.frames()
 t.check(ui.card_buttons[art_uid].get_node("CardIllustration").texture==art_tex,"DISPLAY hand refresh restores the formal illustration in place")

# 源文本判据（裁定 9）：手牌行只有一条例程，建卡只有一个构造点。
static func present_hand_source_text(t) -> void:
 var handle=FileAccess.open("res://ui/main.gd",FileAccess.READ)
 var declaration=RegEx.new()
 var slash=String.chr(92)
 declaration.compile("^"+slash+"s*func"+slash+"s+([A-Za-z_][A-Za-z0-9_]*)")
 var bodies={}
 var current=""
 var text="" if handle==null else handle.get_as_text()
 for line in text.split(String.chr(10)):
  var code=String(line).split("#")[0]
  var declared=declaration.search(code)
  if declared!=null:
   current=declared.get_string(1)
   bodies[current]=""
   continue
  if current!="": bodies[current]=String(bodies[current])+code+String.chr(10)
 t.check(bodies.has("render") and String(bodies["render"]).contains("_hand()"),"DISPLAY hand refresh keeps render on the single row routine")
 var face_new=[]
 for name in bodies:
  if String(bodies[name]).contains("CardFace.new()"): face_new.append(name)
 t.check(face_new==["_card"],"DISPLAY hand refresh keeps one card constructor: "+str(face_new))
 var caller=RegEx.new()
 caller.compile("(^|[^A-Za-z0-9_])_card"+slash+"(")
 var callers=[]
 for name in bodies:
  if name=="_card": continue
  if caller.search(String(bodies[name]))!=null: callers.append(name)
 callers.sort()
 t.check(callers==["_display_card","_hand_mount_card"],"DISPLAY hand refresh builds hand cards only through the member step: "+str(callers))

static func run(t) -> void:
 r3_display_points_do_not_read_rows(t)
 display_facts_match_determination(t)
 r4_display_points_do_not_read_rows(t)
 r4_display_facts_match_determination(t)
 r5_display_facts_match_determination(t)
 await portrait_snapshot_boundary(t)
 await submit_reject_semantics_unchanged(t)
 await submit_presents_local_dirty_or_full(t)
 await submit_unmounts_closed_overlay_sections(t)
 await takeover_path_unchanged(t)
 await portrait_composite_boundary(t)
 await copy_missing_key_never_crashes(t)
 var ui=t.ui
 await sidebar_refresh(t)
 await present_routes_body_bar_or_full(t)
 await present_routes_header_or_full(t)
 await present_routes_relics_or_full(t)
 await present_routes_hand_or_full(t)
 await present_hand_incremental(t)
 await present_routes_actions_or_full(t)
 await present_routes_posture_or_full(t)
 await present_routes_resources_or_full(t)
 await present_routes_show_log_or_full(t)
 await present_routes_body_details_or_full(t)
 await present_routes_pickers_or_full(t)
 await present_routes_speech_or_full(t)
 await present_routes_notice_or_full(t)
 await present_routes_drawers_or_full(t)
 await present_routes_scene_instances_or_full(t)
 await present_syncs_battle_stage_widgets(t)
 await portrait_refresh(t)
 var backdrop=ui.find_child("MoonlitGallery",true,false)
 var static_draws=[0]
 backdrop.draw.connect(func():static_draws[0]+=1)
 await t.frames(8)
 static_draws[0]=0
 await t.frames(12)
 t.check(static_draws[0]==0,"DISPLAY idle decorative animation does not redraw static scenery")
 t.check(Engine.max_fps==60,"DISPLAY game presentation defaults to a 60 FPS budget")
 var old_mode=t.root.mode;var old_border=t.root.borderless;var old_size=t.root.size;var old_position=t.root.position
 var before=ui.game.export_snapshot()
 await t.open_menu();await Navigation.press(t,"OpenOptions")
 var fps=ui.find_child("FrameLimit",true,false)
 t.check(fps.item_count==4 and range(4).map(func(index):return fps.get_item_text(index))==["60帧","120帧","240帧","无上限"],"DISPLAY exposes all four frame budgets")
 for index in range(4):
  await choose(t,"FrameLimit",index)
  t.check(Engine.max_fps==[60,120,240,0][index] and ui.display_settings.frame_limit==Engine.max_fps,"DISPLAY frame selection immediately changes the actual engine budget")
 await Navigation.press(t,"VSyncEnabled")
 t.check(not ui.display_settings.vsync_enabled and DisplayServer.window_get_vsync_mode(t.root.get_window_id())==DisplayServer.VSYNC_DISABLED,"DISPLAY vertical sync can be disabled independently of the unlimited budget")
 await choose(t,"FrameLimit",1)
 await Navigation.press(t,"VSyncEnabled")
 t.check(ui.display_settings.vsync_enabled and Engine.max_fps==120 and DisplayServer.window_get_vsync_mode(t.root.get_window_id())==DisplayServer.VSYNC_ENABLED,"DISPLAY vertical sync re-enables without replacing the chosen frame cap")
 var picker=ui.find_child("DisplayMode",true,false)
 t.check(picker.item_count==3 and range(3).map(func(index):return picker.get_item_text(index))==["窗口","无边框窗口","全屏"],"DISPLAY three distinct native window modes")
 var sizes=ui.display_settings.choices()
 t.check(Vector2i(3840,2160) in sizes and Vector2i(2560,1440) in sizes,"DISPLAY 1440p and 4K stay selectable regardless of monitor size")
 var small=sizes.find(Vector2i(1280,720))
 t.check(small>=0,"DISPLAY 720p is selectable on test monitor")
 await choose(t,"DisplayResolution",small)
 t.check(t.root.size==Vector2i(1280,720) and t.root.mode==Window.MODE_WINDOWED and not t.root.borderless,"DISPLAY resolution changes actual framed window")
 await choose(t,"DisplayMode",1)
 t.check(t.root.mode==Window.MODE_WINDOWED and t.root.borderless and t.root.size==Vector2i(1280,720),"DISPLAY borderless retains chosen window resolution")
 await choose(t,"DisplayMode",2)
 t.check(t.root.mode==Window.MODE_FULLSCREEN and ui.find_child("DisplayResolution",true,false).disabled,"DISPLAY fullscreen uses monitor size and does not offer ineffective window resolution")
 await choose(t,"DisplayMode",0)
 t.check(t.root.mode==Window.MODE_WINDOWED and not t.root.borderless and t.root.size==Vector2i(1280,720),"DISPLAY leaving fullscreen restores chosen size and clears forced borderless flag")
 t.check(Engine.max_fps==120 and ui.display_settings.vsync_enabled,"DISPLAY window transitions retain frame and sync preferences")
 t.check(ui.game.export_snapshot()==before,"DISPLAY changing resolution and modes never changes game or turn state")
 await t.capture("ui-display-settings.png")
 # The same preference reader/writer uses a test-only file, never the player's settings.
 var path="res://build/display-settings-%s.cfg" % OS.get_process_id()
 var settings=Settings.new();settings.path=path;settings.initialize(t.root,false)
 settings.persistence_enabled=true;settings.set_mode(1)
 settings.set_frame_limit(240);settings.set_vsync(false)
 settings.set_art_style("enemies","six_bind","test")
 settings.set_art_style("cards","strain","test")
 settings.set_art_style("cards","slip","test")
 settings.set_chastity_locks(true);settings.adjust_chastity_chance(10)
 t.check(not settings.cursed_plate_start and not settings.cursed_plate_masochist_mode,"CUSTOM DISPLAY cursed-plate preferences default off")
 settings.set_cursed_plate_start(true)
 settings.set_cursed_plate_masochist_mode(true)
 var custom_reload=Settings.new();custom_reload.path=path;custom_reload.initialize(t.root)
 t.check(custom_reload.frame_limit==240 and not custom_reload.vsync_enabled and Engine.max_fps==240 and DisplayServer.window_get_vsync_mode(t.root.get_window_id())==DisplayServer.VSYNC_DISABLED,"DISPLAY frame and sync preferences persist and apply in a fresh settings instance")
 settings.set_frame_limit(0)
 custom_reload.initialize(t.root)
 t.check(custom_reload.frame_limit==0 and Engine.max_fps==0,"DISPLAY unlimited survives preference reload")
 t.check(not settings.set_frame_limit(90) and settings.frame_limit==0 and Engine.max_fps==0,"DISPLAY unsupported frame cap is rejected without side effects")
 t.check(custom_reload.cursed_plate_start and custom_reload.cursed_plate_masochist_mode and custom_reload.chastity_locks_enabled,"CUSTOM DISPLAY enabled cursed-plate preferences persist")
 t.check(settings.chastity_locks_enabled and settings.chastity_lock_chance==35,"DISPLAY chastity pool defaults to 25 percent and adjusts in five-point steps")
 settings.set_fixed_hero_portrait(true)
 t.check(not settings.cursed_plate_start and not settings.cursed_plate_masochist_mode,"CUSTOM DISPLAY fixed portrait clears both cursed-plate preferences")
 t.check(not settings.chastity_locks_enabled,"DISPLAY fixed hero portrait disables the incompatible chastity pool")
 settings.set_resolution(Vector2i(3840,2160))
 t.check(settings.resolution==Vector2i(3840,2160),"DISPLAY selecting 4K keeps requested resolution")
 t.check(settings.save_error.is_empty() and FileAccess.file_exists(path),"DISPLAY preferences saved separately from game snapshots")
 var restored=Settings.new();restored.path=path;restored.initialize(t.root)
 t.check(restored.mode==1 and restored.resolution==Vector2i(3840,2160) and t.root.borderless,"DISPLAY fresh settings instance restores persisted mode and size")
 t.check(restored.fixed_hero_portrait,"DISPLAY fixed portrait preference survives a settings reload")
 t.check(not restored.chastity_locks_enabled and restored.chastity_lock_chance==35,"DISPLAY fixed portrait keeps the saved chance but suppresses the chastity pool")
 t.check(restored.art_style("enemies","six_bind")=="test" and restored.art_choices.cards.keys().size()==2,"ART each card and enemy choice persists independently alongside display settings")
 restored.set_art_style("enemies","six_bind","formal")
 t.check(restored.art_texture("enemies","six_bind")!=null and restored.art_choices.cards==settings.art_choices.cards,"ART changing one enemy keeps both card preferences")
 var config=ConfigFile.new();config.set_value("display","mode",99);config.set_value("display","resolution",Vector2i(99999,99999));config.set_value("gameplay","chastity_locks_enabled","invalid");config.set_value("gameplay","chastity_lock_chance",27);config.save(path)
 restored.initialize(t.root)
 t.check(restored.frame_limit==60 and restored.vsync_enabled and Engine.max_fps==60,"DISPLAY absent pacing settings use safe defaults")
 config.set_value("display","frame_limit",90);config.set_value("display","vsync_enabled","invalid");config.save(path)
 restored.initialize(t.root)
 t.check(restored.frame_limit==60 and restored.vsync_enabled and DisplayServer.window_get_vsync_mode(t.root.get_window_id())==DisplayServer.VSYNC_ENABLED,"DISPLAY malformed pacing settings fall back to 60 FPS and vertical sync")
 t.check(not restored.fixed_hero_portrait,"DISPLAY missing fixed portrait setting defaults off")
 t.check(not restored.chastity_locks_enabled and restored.chastity_lock_chance==25,"DISPLAY invalid chastity settings fall back to off and 25 percent")
 restored.set_cursed_plate_start(true)
 restored.set_cursed_plate_masochist_mode(true)
 t.check(not restored.cursed_plate_start and not restored.cursed_plate_masochist_mode,"CUSTOM DISPLAY disabled pool cannot set cursed-plate preferences")
 config.set_value("gameplay","cursed_plate_start",true);config.save(path);restored.initialize(t.root)
 t.check(not restored.cursed_plate_start,"CUSTOM DISPLAY inconsistent saved setting is suppressed")
 config.set_value("gameplay","chastity_locks_enabled",true);config.set_value("gameplay","cursed_plate_start","invalid");config.save(path);restored.initialize(t.root)
 t.check(not restored.cursed_plate_start,"CUSTOM DISPLAY malformed saved setting defaults off")
 config.set_value("gameplay","chastity_lock_chance",0);config.save(path)
 restored.initialize(t.root)
 t.check(restored.chastity_lock_chance==5,"DISPLAY formerly saved zero chance clamps to five percent")
 restored.set_chastity_locks(true);restored.adjust_chastity_chance(-5)
 t.check(restored.chastity_lock_chance==5,"DISPLAY repeated lowering cannot pass the five-percent minimum")
 restored.adjust_chastity_chance(200)
 t.check(restored.chastity_lock_chance==100,"DISPLAY probability upper bound stays at one hundred percent")
 t.check(restored.mode in range(3) and restored.resolution in restored.choices(),"DISPLAY invalid saved preference falls back to supported resolution")
 DirAccess.remove_absolute(path)
 t.root.mode=Window.MODE_WINDOWED;t.root.borderless=old_border;t.root.size=old_size;t.root.position=old_position;t.root.mode=old_mode
 ui.display_settings.initialize(t.root,false)
 await t.close_information();await t.frames()
 await preload("res://tests/card_music_ui_cases.gd").run(t)
