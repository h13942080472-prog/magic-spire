extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")
const Settings=preload("res://ui/display_settings.gd")
const Portrait=preload("res://ui/equipment_portrait.gd")
const Art=preload("res://ui/pixel_art.gd")
const Cases=preload("res://tests/architecture_cases.gd")

# docs/spec/candidate-removal.md §5 G5（批 R3 的手牌／行动／姿态／墙面／底栏域）：夹具矩阵 0／12／26／44 件
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

# 本批删边的核对面（docs/spec/candidate-removal.md §2.2 的 D13 对应行）：手牌／行动／姿态／墙面／底栏域的
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

# 判定参考（docs/spec/candidate-removal.md §2.1 P2）：唯一判定对同一显示点输入的重算。原始输入来自
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

# docs/spec/candidate-removal.md §5 G5（批 R4 的装备／快捷解除／拖放／道具域）。
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

# docs/spec/candidate-removal.md §5 G3（批 R2）：拒绝语义不变。三类拒绝（陈旧版本／形状不合法／判定不通过）
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

# docs/spec/candidate-removal.md §5 G8（批 R2）：接管路径不变。真实演示入口、真实输入；
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

# docs/spec/candidate-removal.md §5 G5（批 R5 的服务／事件／监狱／路线／奖励／出发域）：夹具矩阵同 R4，
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

static func run(t) -> void:
 r3_display_points_do_not_read_rows(t)
 display_facts_match_determination(t)
 r4_display_points_do_not_read_rows(t)
 r4_display_facts_match_determination(t)
 r5_display_facts_match_determination(t)
 await portrait_snapshot_boundary(t)
 await submit_reject_semantics_unchanged(t)
 await takeover_path_unchanged(t)
 await portrait_composite_boundary(t)
 await copy_missing_key_never_crashes(t)
 var ui=t.ui
 await sidebar_refresh(t)
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
