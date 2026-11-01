extends RefCounted
const Localizer=preload("res://ui/localization.gd")

static func source() -> Dictionary:
 return {"schema_version":1,"locale":"zh_CN","messages":{
  "test.line":{"text":"{name}：剩余{count}次（{name}）","context":"参数边界测试"},
  "test.braces":{"text":"{{名称}}：{name}","context":"字面大括号测试"},
  "test.other":{"text":"中文回退","context":"缺译测试"}
 }}

static func translation(messages: Dictionary) -> Dictionary:
 return {"schema_version":1,"locale":"ja_JP","messages":messages}

static func numeric_literals(text: String, source_format: bool) -> Array:
 var placeholder=RegEx.new()
 placeholder.compile("%(?:[-+ 0#]*)(?:\\d+|\\*)?(?:\\.(?:\\d+|\\*))?[diouxXfFeEgGaAcsp]|\\{(?:[A-Za-z_][A-Za-z0-9_.]*|\\d+)\\}" if source_format else "\\{p\\d+\\}")
 var cleaned=placeholder.sub(text,"",true)
 var number=RegEx.new();number.compile("\\d+(?:\\.\\d+)?")
 var values=[]
 for found in number.search_all(cleaned): values.append(found.get_string())
 return values

# docs/spec/event-pipeline.md「证据入口」: the legacy English catalog has to
# match the validator wording this slice rewrote — retired sources deleted, rewritten
# sources translated.
const REMOVED_SOURCES=[
 "事件必须在普通 choices 与多阶段 stages 中选择一种结构。",
  "普通事件需要1—6个选项，allow_refuse 必须为布尔值。",
  "多阶段事件分别在每个阶段填写 allow_refuse。",
  "多阶段事件需要 start_stage 和2—12个阶段。",
  "start_stage 必须引用已有阶段。",
  "阶段 id、标题、介绍、离开设置或选项不正确。",
  "阶段recipe 与 effects 请择一填写。",
  "阶段选项至少需要 effects、recipe 或 outcomes。",
  "阶段选项使用的 recipe 待支持。",
  "阶段选项 effects 最多12项。",
  "带奖励的阶段选项目前必须结束事件，不能在领奖后继续下一阶段。",
  "阶段结果文案不正确。",
  "阶段预告文案不正确。",
  "阶段选项 id、文案或奖励有误。",
  "阶段选择器：",
  "阶段条件需要恰好一个事件计数或选择来源，以及 equals/minimum/maximum。",
  "阶段条件的事件计数名无效。",
  "阶段条件的选择来源：",
  "阶段条件计数必须是0—100整数。",
  "选项必须且只能填写 recipe 或 effects 之一。",
  "空 effects 只能用于无奖励离开或战斗选项。",
  "临时保管只允许用于声明了收尾步骤的多阶段事件。",
  "effects 最多8个效果。",
  "未知 recipe。",
  "不支持的 reward。"]

const REQUIRED_SOURCES={
 "事件介绍长度需在允许范围内。": "The event introduction is empty or too long.",
  "事件必须填写 start_node。": "The event needs start_node.",
  "事件需要1—12个节点。": "An event needs 1-12 nodes.",
  "节点 id 无效或重复。": "A node id is invalid or duplicated.",
  "单节点事件的节点 id 必须为 choice。": "A single-node event has to use the id choice.",
  "单节点事件需要省略 title 和 intro。": "A single-node event must not declare title or intro.",
  "节点标题或介绍有误。": "A node title or introduction is invalid.",
  "节点必须填写 allow_refuse 布尔值。": "Every node has to declare allow_refuse.",
  "节点的声明取值有误。": "A node declaration uses an unsupported value.",
  "节点需要1—6个选项。": "A node needs 1-6 options.",
  "start_node 必须引用已有节点。": "start_node has to name an existing node.",
  "选项 id、文案或奖励有误。": "An option id, label or reward is invalid.",
  "recipe 与 effects 请择一填写。": "An option cannot declare both recipe and effects.",
  "选项至少需要 effects、recipe 或 outcomes。": "An option needs effects, recipe or outcomes.",
  "选项使用的 recipe 待支持。": "An option uses an unknown recipe.",
  "选项 effects 最多12项。": "An option takes at most 12 effects.",
  "带奖励的选项必须结束事件。": "A rewarded option has to end the event instead of continuing.",
  "选项结果文案有误。": "An option result text is invalid.",
  "选项预告文案有误。": "An option preview text is invalid.",
  "选项选择器：": "Option selector: ",
  "选项条件需要恰好一个事件计数或选择来源，以及 equals/minimum/maximum。": "An option condition needs exactly one counter or selector source plus equals/minimum/maximum.",
  "选项条件的事件计数名无效。": "The option condition counter name is invalid.",
  "选项条件的选择来源：": "Option condition source: ",
  "选项条件计数必须是0—100整数。": "An option condition count has to be an integer from 0 to 100.",
  "availability 与 conditions 请择一填写。": "An option cannot declare both availability and conditions.",
  "conditions 需要1—8条条件。": "conditions needs 1-8 entries.",
  "选项 unavailable 只支持 hide 或 disable。": "An option unavailable value supports only hide or disable.",
  "unavailable 与 hide_when_unavailable 请择一填写。": "An option cannot declare both unavailable and hide_when_unavailable.",
  "事件选项同时携带两种状态条件。": "The event option carries both state condition spellings.",
  "条件模式只支持 optional 或 hidden。": "A condition mode supports only optional or hidden.",
  "待支持这种状态条件。": "This state condition is not supported yet.",
  "需要条件对象。": "A condition object is required.",
  "reason 需要1—240字的普通说明。": "reason needs 1-240 plain characters.",
  "has_relic 需要已注册的遗物 id。": "has_relic needs a registered relic id.",
 # B5 (A34): the chain-loop gate reason is player-visible, so it needs a manual entry too.
 "这段事件已经结束，请继续前进。": "This event has already happened. You cannot go back."}

static func locale_legacy_catalog_matches_current_sources(t) -> void:
 var reference_sources={}
 for locale in ["en_US","ja_JP"]:
  var path="res://assets/localization/legacy-"+locale+".json"
  var file=FileAccess.open(path,FileAccess.READ)
  t.check(file!=null,"LOCALE "+locale+" legacy catalog is readable")
  if file==null: continue
  var raw=file.get_as_text()
  if locale=="ja_JP":
   var forbidden=["広島","海外の反応","ありがとうございました","やってみよう","ショウジョウ","(笑)","ブラックリスト","⁇","�","[PH","ZXQ","カードキャプターさくら","この記事へのトラックバック","カーディガン","恐怖の根源","自律師"]
   t.check(forbidden.all(func(marker):return not raw.contains(marker)),"LOCALE Japanese legacy catalog rejects known generated hallucination markers")
  var parsed=JSON.parse_string(raw)
  t.check(parsed is Dictionary and parsed.get("locale")==locale,"LOCALE "+locale+" legacy catalog keeps its locale marker")
  var by_source={}
  var semantic_mismatch=false
  var localized_residue=false
  var missing_literal_number=false
  for message in parsed.get("messages",[]):
   by_source[message.get("source","")]=message
   if locale=="ja_JP":
    var source_text=str(message.get("source",""));var target_text=str(message.get("text",""))
    localized_residue=localized_residue or ["回合","原始","次数","装备","结算","档","施加","法阵","刷新","布局","概率","备用","基准","截图","紫发","降低"].any(func(marker):return target_text.contains(marker))
    semantic_mismatch=semantic_mismatch or (source_text.contains("回合") and ["回転","回路","逆転","結束","サイクル","輪"].any(func(marker):return target_text.contains(marker)))
    semantic_mismatch=semantic_mismatch or (source_text.contains("回合") and not ["ターン","ラウンド"].any(func(marker):return target_text.contains(marker)))
    semantic_mismatch=semantic_mismatch or (source_text.contains("档") and not source_text.contains("存档") and (target_text.contains("ファイル") or target_text.contains("ランキング")))
    semantic_mismatch=semantic_mismatch or (source_text.contains("生命") and target_text.contains("人生"))
    semantic_mismatch=semantic_mismatch or (source_text.contains("件拘束具") and target_text.contains("事件拘束具"))
    semantic_mismatch=semantic_mismatch or (source_text.contains("上限") and target_text.contains("国境"))
    semantic_mismatch=semantic_mismatch or (source_text.contains("自缚") and not ["自縛","自己拘束","自己結合"].any(func(marker):return target_text.contains(marker)))
    var negative_source=["无法","不能","不可","不得","禁止"].any(func(marker):return source_text.contains(marker))
    var negative_target=["ない","ません","不可","禁止","不能","無効","なし","ず","ぬ","できな","られな"].any(func(marker):return target_text.contains(marker))
    semantic_mismatch=semantic_mismatch or (negative_source and not negative_target)
    semantic_mismatch=semantic_mismatch or (source_text.contains("恢复") and not ["回復","復元","戻","再開","補充","返還"].any(func(marker):return target_text.contains(marker)))
    semantic_mismatch=semantic_mismatch or (source_text.contains("存档") and not ["セーブ","保存","ファイル","アーカイブ","記録"].any(func(marker):return target_text.contains(marker)))
    semantic_mismatch=semantic_mismatch or (source_text.contains("最多") and not ["最大","まで","以下","上限","せいぜい","のみ"].any(func(marker):return target_text.contains(marker)))
    semantic_mismatch=semantic_mismatch or (source_text.contains("至少") and not ["以上","最低","少なくとも"].any(func(marker):return target_text.contains(marker)))
    semantic_mismatch=semantic_mismatch or (source_text.contains("免费") and not ["無料","コスト0","無償"].any(func(marker):return target_text.contains(marker)))
    var target_numbers=numeric_literals(target_text,false)
    for number in numeric_literals(source_text,true):
     var index=target_numbers.find(number)
     if index<0: missing_literal_number=true
     else: target_numbers.remove_at(index)
  if locale=="ja_JP": t.check(not semantic_mismatch,"LOCALE Japanese legacy catalog rejects known source-conditioned semantic mistranslations")
  if locale=="ja_JP": t.check(not localized_residue,"LOCALE Japanese legacy targets reject known Simplified Chinese residue")
  if locale=="ja_JP": t.check(not missing_literal_number,"LOCALE Japanese legacy targets preserve every literal numeric rule value")
  if reference_sources.is_empty(): reference_sources=by_source
  else: t.check(by_source.size()==reference_sources.size() and reference_sources.keys().all(func(source):return by_source.has(source)),"LOCALE "+locale+" legacy catalog covers the same current sources as English")
  for source in REMOVED_SOURCES:
   t.check(not by_source.has(source),"LOCALE "+locale+" retired source is deleted from the catalog: "+source)
  for source in REQUIRED_SOURCES:
   t.check(by_source.has(source) and str(by_source[source].get("text","")).strip_edges()!="","LOCALE "+locale+" rewritten source keeps a non-empty translation: "+source)

static func run(t) -> void:
 enemy_profiles(t)
 locale_legacy_catalog_matches_current_sources(t)
 bundled_font(t)
 var l=Localizer.new()
 t.check(l.diagnostics().is_empty() and l.locale=="zh_CN","LOCALE shipped resources load locally and default to Chinese: "+str(l.diagnostics()))
 t.check(l.coverage("zh_CN").total>0 and l.coverage("en_US").missing==0 and l.coverage("ja_JP").missing==0,"LOCALE English and Japanese are complete for registered IDs")
 t.check(l.set_locale("en_US") and l.text("ui.home.title","紧缚尖塔")=="Bound Spire","LOCALE registered English copy resolves through its semantic ID")
 var practice_health=RegEx.new();practice_health.compile("(\\d+)生命")
 var chinese=RegEx.new();chinese.compile("[\\x{3400}-\\x{9fff}]")
 for entry in preload("res://data/encyclopedia.gd").entries().filter(func(row):return row.category=="enemies" and row.id in ["drone","versatile"]):
  var line=Array(entry.text.split("\n")).filter(func(value):return value.begins_with("长战斗："))[0]
  var translated=l.display("\n"+line)
  t.check(chinese.search(translated)==null and translated.contains("15") and translated.contains("20") and translated.contains("40") and translated.contains("boss battles") and translated.contains("support units"),"LOCALE long-battle enemy copy translates thresholds and boss exemption: "+entry.id)
  t.check(translated.contains("automatically leaves") if entry.id=="drone" else translated.contains("repeatedly prepares to arrest"),"LOCALE long-battle enemy outcome remains distinct: "+entry.id)
 var prison_entries=preload("res://data/tutorial.gd").entries()
 for id in ["prison0","prison3","prison4","prison6","prison_security"]:
  var entry=prison_entries.filter(func(row):return row.id==id)[0]
  var translated=l.display(entry.title)+"\n"+l.display(entry.text)
  t.check(chinese.search(translated)==null,"LOCALE current prison handbook translates its full title and rules: "+id)
  if id=="prison0": t.check(translated.contains("20/30/50") and translated.contains("pausing in battle and preparation") and translated.contains("levels 4/5 require escape"),"LOCALE sentence rules retain the combat pause and unlimited upper levels")
  if id=="prison6": t.check(translated.contains("Existing equipment is retained") and translated.contains("up to the quota") and translated.contains("levels 1-4"),"LOCALE security-five rules preserve the quota and seal restriction")
  if id=="prison_security":
   var floor_count=int(preload("res://data/balance.gd").PRISON_INTAKE[1].floor)
   var updated=l.display(entry.text.replace("保底%d件" % floor_count,"保底%d件" % (floor_count+1)))
   t.check(updated.contains("minimum %d restraints" % (floor_count+1)) and chinese.search(updated)==null,"LOCALE complete prison handbook keeps changing intake values through nested row templates")
 for kind in ["puppeteer_solo","binding_box_solo","drone_solo","mixed_bundle_solo","mixed_pair","rope_serpent_solo","small_circle_solo","versatile_solo"]:
  var source=preload("res://data/tower.gd").practice_spec(kind).description
  var hp=practice_health.search(source)
  var translated=l.display(source)
  t.check(hp!=null and translated.contains(hp.get_string(1)+" HP") and chinese.search(translated)==null,"LOCALE practice description translates full mechanics and current health: "+kind)
  if hp!=null:
   var next_hp=int(hp.get_string(1))+7
   var updated=practice_health.sub(source,"%d生命" % next_hp)
   t.check(l.display(updated).contains(str(next_hp)+" HP") and chinese.search(l.display(updated))==null,"LOCALE practice template preserves health after later balancing: "+kind)
 var save_help=l.display(preload("res://data/tutorial.gd").SAVE_HELP)
 t.check(save_help=="Autosaves occur on entering a higher floor, after battle, or after preparation. Continue restores the last saved start; Quick SL restores the current scene start.","LOCALE save help distinguishes automatic disk checkpoints from current-scene Quick SL")
 t.check(l.display("离地0.2米的墙缝")=="Wall crack 0.2 m above the floor" and l.display("离地1.4米的墙缝")=="Wall crack 1.4 m above the floor","LOCALE installed tool labels preserve the actual numeric height")
 t.check(l.display("随使用次数和可用条件变化更新")=="Updates with remaining uses and availability","LOCALE usable item status lifetime translates")
 t.check(l.display("精神集中")=="Mental Focus" and l.display("魔力预备")=="Mana Reserve" and l.display("施法预备")=="Spell Preparation","LOCALE character-two resources keep distinct consistent English terms")
 t.check(l.display("思维侵入")=="Mind Intrusion" and l.display("思维扰乱")=="Mind Disruption" and l.display("思维破坏")=="Mind Shatter" and l.display("吹雪")=="Flurry" and l.display("炎枪术")=="Flame Lance","LOCALE character-two spell names use reviewed English")
 t.check(l.display("\n失败返还50%自身耗魔，向下取整；临时魔力返还0，能量照扣。")=="\nFailed casts refund 50% of personal Mana spent, rounded down; temporary Mana refund: 0. Energy is still spent.","LOCALE character-two failure tooltip preserves its leading line break and actual payment rule")
 var capture_copy=l.display("被捕缚时无法移动，先解除捕缚。挣扎／滑脱牌可直接削减进度；除眼罩、口球外没有其他拘束具时伤害翻倍，环境加成为0。上身受限至少按1级计算。同种捕缚仅生效一次；新种类增加其初始值的一半。降至0全部解除，达到100后下一敌方回合执行收押。\n降紧每层固定削减8点捕缚，使用固定数值，蓄力保留。")
 t.check(capture_copy.contains("Capture") and not capture_copy.to_lower().contains("catch") and capture_copy.contains("next enemy turn") and capture_copy.contains("fixed 8") and capture_copy.contains("preserving Charge"),"LOCALE capture rules use the reviewed mechanic term and preserve the imprisonment timing")
 t.check(l.display("自缚")=="Self-Binding" and l.display("需要收紧4档，当前最多只能收紧2档；无法完整执行。")=="Requires 4 tiers of tightening, but only 2 are available. The full effect cannot be completed.","LOCALE self-binding name and actual tightening shortfall preserve the numeric rule")
 t.check(l.display("蓄力")=="Charge" and l.display("蓄力2")=="Charge 2","LOCALE legacy bridge translates exact and formatted presentation text")
 t.check(l.display("主体")=="Main piece" and l.display("手胸  2  ›")=="Arms & Chest  2  ›","LOCALE release region count and special equipment role translate without changing numbers")
 t.check(l.display("中级马眼全包榨精杯")=="Medium Urethral Full-Cover Milking Cup" and l.display("中级榨精杯固定带")=="Medium Milking Cup Fixing Strap" and l.display("固定带只能随对应主体自动附加。")=="A fixing strap can only be attached automatically with its matching main piece." and l.display("固定带只能借助已安装且能够接触该部位的切割类道具处理。")=="A fixing strap can only be handled with an installed cutting tool that can reach the body part.","LOCALE medium urethral full cup and its fixing-band rules have English compatibility copy")
 t.check(l.display("援军")=="Reinforcements" and l.display("3回合后抵达")=="Arrives in 3 turns" and not l.display("每4回合召来1名警卫。已召来1 / 3名；战斗胜利后停止。").contains("警卫"),"LOCALE reinforcement timer and shared limit translate")
 t.check(l.display("每佩戴2件拘束具，本回合获得1点力量，向下取整。")=="For every 2 restraints worn, gain 1 Strength this turn, rounded down.","LOCALE changed card text translates divisor and incomplete groups in static previews")
 t.check(l.display("每佩戴3件拘束具，恢复1点魔力。\n当前：恢复4魔力。")=="For every 3 restraints worn, restore 1 Mana.\nCurrent: restore 4 Mana.","LOCALE changed card text preserves the actual multiline resource preview")
 t.check(l.display("肘击与近身短打伤害×0.8（含力量和蓄力）；三级起无法使用这两种攻击。")=="Elbow Strike and Close Strike damage x0.8, including Strength and Charge. Both attacks are unavailable at level 3 or higher.","LOCALE physical damage copy includes strength and charge in body restriction multiplier")
 t.check(l.display("每佩戴1件拘束具，恢复2点魔力。\n当前：恢复6魔力。")=="For every 1 restraints worn, restore 2 Mana.\nCurrent: restore 6 Mana." and l.display("每佩戴1件拘束具，恢复2魔力，至多恢复至上限。")=="For every 1 restraints worn, restore 2 Mana, up to the maximum.","LOCALE confluence doubled mana rule and preview preserve actual values")
 t.check(l.display("魔路精通")=="Mana Circuit Mastery" and l.display("0费剩余2次")=="Zero-cost triggers remaining: 2","LOCALE mastery name and live quota translate")
 t.check(l.display("两面互斥：本场已启用「魔路精通」。").contains("Mutually exclusive"),"LOCALE mutual exclusion explains unavailable face")
 t.check(l.set_locale("ja_JP") and l.text("ui.home.title","紧缚尖塔")=="緊縛の尖塔","LOCALE registered Japanese copy resolves through its semantic ID")
 t.check(l.display("好了，带着这副样子进去吧❤").contains("格好") and l.display("好了，带着这副样子进去吧❤").contains("❤"),"LOCALE Japanese dialogue keeps the instruction instead of collapsing to punctuation")
 t.check(l.display("抽取2，失去20快感。").contains("2") and l.display("抽取2，失去20快感。").contains("20") and l.display("抽取2，失去20快感。").contains("快感"),"LOCALE Japanese card result keeps draw, loss and pleasure values")
 t.check(l.display("删牌服务 · %s魔力" % 12).contains("カード削除") and l.display("删牌服务 · %s魔力" % 12).contains("12"),"LOCALE Japanese dynamic service label keeps its action and price")
 t.check(l.display("正在提交，请稍候…").length()>8 and l.display("正在提交，请稍候…").contains("待"),"LOCALE Japanese pending message keeps its instruction instead of collapsing to an ellipsis")
 t.check(l.display("{mana_cost}本场全部伤害×2。打出时播放dj版雨爱。".format({"mana_cost":"50魔力"})).contains("雨愛"),"LOCALE Japanese authored music cue cannot turn into unrelated generated copy")
 for rain_source in ["{mana_cost}解除全部拘束与捕缚。打出时播放dj版雨爱。","{mana_cost}解除全部拘束具与捕缚。打出时播放dj版雨爱。"]:
  var rain_copy=l.display(rain_source.format({"mana_cost":"50魔力"}))
  t.check(rain_copy.contains("雨愛") and rain_copy.contains("解除") and not rain_copy.contains("ダンジョン"),"LOCALE every Japanese Rain Love cue preserves the authored song and release effect")
 t.check(l.display("下一个目标")=="次の対象" and l.display("无视身体和姿势限制。").contains("制限を受けない") and l.display("前进一回合")=="1ターン進む","LOCALE short Japanese action rules preserve qualifiers and negation")
 var prison_copy=l.display("已服刑%d回合 · 需自行逃脱" % 8)
 t.check(prison_copy.contains("8") and prison_copy.contains("自動釈放なし"),"LOCALE Japanese prison status keeps served turns and no-auto-release rule")
 var prison_rules=[
  l.display("安全等级1／2／3的刑期为20／30／50回合，4／5级需自行逃脱。刑期仅在牢房回合累计，战斗与整备暂停计时；检查耗时0回合。检查发现缺装或没收工具时，最多延长8回合；充电与恢复消耗牌按正常刑期继续。刑满检查通过后施加出狱装备并选择新塔路起点；失败则处罚并延长8回合，服满后复查。"),
  l.display("安全等级1／2／3／4：累计20／30／50回合／不自动出狱。牢房、反抗战及其整备均累计；检查确认不计回合。每次检查发现缺装或没收工具，最多延长8回合；正常充电、恢复消耗牌不延长。到期按当前安全等级执行一次入狱装备判定，再选择新塔路起点。"),
  l.display("安全等级1／2／3／4：累计20／30／50回合／不自动出狱。牢房、反抗战及其整备均累计；检查确认不计回合。每次检查发现缺装或没收工具，最多延长8回合；正常充电、恢复消耗牌不延长。到期立即执行一次临时巡视检查，不重置正常巡视周期。检查不通过则处罚并延长8回合，下次到期重新检查；通过后按当前安全等级施加出狱装备，再选择新塔路起点。")]
 t.check(prison_rules[0].contains("牢内ターンのみ進み") and prison_rules[0].contains("満期の検査") and prison_rules[0].contains("出獄装備"),"LOCALE Japanese prison overview preserves sentence progress, release inspection and release equipment")
 t.check(prison_rules[1].contains("抵抗戦") and prison_rules[1].contains("収監時装備判定") and prison_rules[2].contains("臨時巡回検査") and prison_rules[2].contains("通常巡回の周期はリセットしない"),"LOCALE Japanese prison variants preserve resistance-battle counting, intake equipment and temporary inspection timing")
 var prison_exit=l.display("保留正常收押生成的装备，从出口守卫战开始，守卫使用正常血量。胜利后领取稀有卡三选一、遗物和60魔瓶魔力，再选择10—11层起点。")
 t.check(prison_exit.contains("レアカード3枚から1枚") and prison_exit.contains("魔瓶魔力60") and prison_exit.contains("10～11層"),"LOCALE Japanese prison exit reward preserves one-of-three rare cards, flask mana and starting floors")
 var prison_capture=l.display("收押至监狱，保留原装备与传送符、没收其他道具并追加装备；随后榨精一次，立即损失最多20魔力。无战斗奖励，战斗结束遗物照常触发。")
 t.check(prison_capture.contains("転送符は保持") and prison_capture.contains("搾精を1回") and prison_capture.contains("最大20") and prison_capture.contains("戦闘報酬はなく"),"LOCALE Japanese prison capture result preserves the talisman, milking, mana loss and absent battle reward")
 t.check(l.display("一键解除 · %d能量" % 3)=="一括解除・エネルギー3","LOCALE Japanese one-click release label keeps both the action and dynamic energy cost")
 for growth_source in ["挣扎{base}。使用后，本场两面伤害＋{damage_growth}。","滑脱{base}。使用后，本场两面伤害＋{damage_growth}。"]:
  var growth_copy=l.display(growth_source.format({"base":8,"damage_growth":2}))
  t.check(growth_copy.contains("8") and growth_copy.contains("両面") and growth_copy.contains("＋2"),"LOCALE Japanese escape growth rules keep action value, both faces and growth")
 t.check(l.display("草稿已保留。")=="下書きを保存しました。","LOCALE Japanese draft status is a complete sentence")
 var discard_copy=l.display("将%d张「%s」混入弃牌堆。" % [2,"ProbeCard"])
 t.check(discard_copy.contains("2枚") and discard_copy.contains("ProbeCard") and discard_copy.contains("捨て札"),"LOCALE Japanese discard insertion keeps count, card name and destination")
 t.check(l.display("魅魔的魔力典当铺")=="サキュバスの魔力質店","LOCALE Japanese succubus pawnshop title keeps its actual meaning")
 t.check(l.display("保存失败：写入校验失败，原存档保留。").contains("書き込み検証") and l.display("保存失败：写入校验失败，原存档保留。").contains("セーブデータ"),"LOCALE Japanese save validation failure cannot become an unrelated exam")
 t.check(l.display("大魔棒")=="巨大魔法棒" and l.display("大魔棒：消耗4点，恢复12魔力。").contains("4") and l.display("大魔棒：消耗4点，恢复12魔力。").contains("12"),"LOCALE Japanese large wand name and resource result keep their meaning")
 t.check(l.display("每个整备回合结束时，恢复1魔力。").contains("準備ターンの終了時") and l.display("每个整备回合结束时，恢复1魔力。").contains("回復"),"LOCALE Japanese preparation-turn recovery keeps both timing and action")
 t.check(l.display("移动 · 第%d回合" % 7)=="移動・第7ターン" and l.display("第%d回合：%s。" % [7,"A"])=="第7ターン：A。" and l.display("第%d回合：%s，视线受阻，无法观察敌人意图。" % [7,"A"])=="第7ターン：A。視界が遮られ、敵の行動予告を確認できない。","LOCALE Japanese dynamic turn labels keep their runtime value and order")
 t.check(l.display("进度归零解除；达到100后下一敌方回合收押").contains("次の敵ターン") and not l.display("进度归零解除；达到100后下一敌方回合收押").contains("100年"),"LOCALE Japanese capture threshold uses the next enemy turn, not a calendar year")
 var delayed_pressure=l.display("失去20快感；下回合获得40快感。")
 t.check(delayed_pressure.contains("20") and delayed_pressure.contains("失") and delayed_pressure.contains("40") and delayed_pressure.contains("次のターン"),"LOCALE Japanese delayed pressure rule keeps both immediate loss and next-turn gain")
 t.check(l.display("快感跨战保留；可通过深呼吸降低")=="快感は戦闘をまたいで保持され、深呼吸で減少させられる","LOCALE Japanese pleasure summary preserves both cross-battle retention and deep-breath reduction")
 var pleasure_rule=l.display("快感达到%s：损失%s魔力，结束当前行动，下回合能量－%d。快感跨战保留，能量惩罚在场次结束时清空。滑精时免除高潮的即时魔力损失，后续两回合开始时各损失%s魔力。\n深呼吸：每回合最多2次，%d能量，基础快感－%s，下回合能量＋%d。嘴部拘束的等级＋紧度总值为2／3／4／5／6时，快感降低量衰减20%%／40%%／60%%／80%%／100%%；多件取最高总值。高级、紧度3档时无法使用。成功使用仍获得完整的下回合能量。" % [100,20,1,10,1,15,1])
 t.check(pleasure_rule.contains("戦闘をまたいで保持") and pleasure_rule.contains("エネルギーペナルティは持ち越さない") and pleasure_rule.contains("深呼吸") and pleasure_rule.contains("減衰"),"LOCALE Japanese pleasure rules preserve cross-battle state, energy scope and deep-breath scaling")
 var temporary_payment=l.display("本次耗魔全部由临时魔力支付时，施法失败获得1能量，返还魔力为0。0费牌每回合最多触发2次。两面互斥。唯一。")
 t.check(temporary_payment.contains("一時魔力") and temporary_payment.contains("返還は0") and temporary_payment.contains("エネルギーを1") and temporary_payment.contains("最大2回") and temporary_payment.contains("排他的"),"LOCALE Japanese temporary-mana rule preserves payment, failure, energy, quota and exclusivity")
 var formation_refresh=l.display("两面可同时生效。打出当回合立即获得次数，下回合刷新。0费牌也消耗次数。严密度仅在打出布阵时检查。")
 t.check(formation_refresh.contains("同時") and formation_refresh.contains("直ちに") and formation_refresh.contains("次のターンに更新") and formation_refresh.contains("コスト0") and formation_refresh.contains("布陣"),"LOCALE Japanese formation rule preserves immediate uses, refresh timing, zero-cost consumption and check timing")
 var ritual_growth=l.display("首回合启动仪式，之后每回合施加数量持续增长，尽快击破法阵。")
 t.check(ritual_growth.contains("第1ターン") and ritual_growth.contains("毎ターン") and ritual_growth.contains("増加") and ritual_growth.contains("魔法陣を破壊"),"LOCALE Japanese ritual rule preserves start, growth and destruction objective")
 var echo_fireball=l.display("下一次火球术每层免费额外施放一次，使用次数保留；只作用原目标，目标失效则跳过。每次施法各自判定成功率。")
 t.check(echo_fireball.contains("1層につき1回") and echo_fireball.contains("使用回数を消費しない") and echo_fireball.contains("元の対象") and echo_fireball.contains("スキップ") and echo_fireball.contains("各発動ごと"),"LOCALE Japanese echo fireball rule preserves free casts, original target, invalid-target skip and independent checks")
 var card_chain=l.display("每成功打出另一张牌，本回合施法成功率额外＋3个百分点。回合开始清零。唯一。")
 t.check(card_chain.contains("1枚使用するたび") and card_chain.contains("＋3") and card_chain.contains("ターン開始時に0") and card_chain.contains("唯一"),"LOCALE Japanese card-chain rule preserves per-card accumulation and turn reset")
 t.check(l.display("分裂时的生命记录有误")=="分裂時のHP記録が不正","LOCALE Japanese split-state error cannot become a divorce message")
 t.check(l.display("唯一。")=="唯一。" and l.display("电量剩余%d回合。" % 4)=="バッテリー残量：あと4ターン。","LOCALE Japanese short keyword and battery countdown remain complete phrases")
 t.check(l.display("沿已选路线前进，手牌与资源保持当前值；本段剩余%d回合。" % 3).ends_with("残り3ターン。"),"LOCALE Japanese route countdown keeps the remaining-turn value")
 var rope_snake=l.display("生命：%s\n行动：缠身→随机收紧或甩缚，循环；两种招式各50%%。\n缠身：紧缠＋1层。每个玩家回合结束，每层施加1件初级2档绳索类拘束具。\n收紧：加固1件绳索类拘束具至3档。甩缚：施加2件初级2档绳索类拘束具，含链接绳。\n特殊：预告收紧时没有目标则改为甩缚；预告后失去目标则不生效。打断不停止紧缠，击败该绳蛇才停止。" % 80)
 t.check(rope_snake.contains("中断されても緊縛は停止せず") and rope_snake.contains("倒した時だけ停止") and not rope_snake.contains("Haunt"),"LOCALE Japanese rope-snake rule preserves the interruption exception")
 t.check(l.display("传送符仅限一至四级牢房的可行动回合使用。").begins_with("転送符") and not l.display("传送符仅限一至四级牢房的可行动回合使用。").contains("送信機"),"LOCALE Japanese teleport talisman cannot become a communication device")
 var proficiency=l.display("施法成功率最低75%；每次使用魔法牌，额外牵扯1次（按1能量），无论成败。唯一。")
 t.check(proficiency.contains("最低75%") and proficiency.contains("牽引") and proficiency.contains("エネルギー1として判定") and proficiency.ends_with("唯一。"),"LOCALE Japanese proficiency rule preserves threshold, pull trigger, energy basis and uniqueness")
 var enemy_sequence=l.display("行动：①初级2档拘束具×2；②无力化1回合；③中级2档拘束具×1，准备就绪＋1；④优先施加中级马具口球或眼罩，无位置时改为其他普通拘束具。\n后续：重复①③④两轮，第11次行动收押。\n无力化：禁用体术，火球与卡牌魔法不受影响。\n准备就绪：每成功施加或替换1件消耗1层，使该件直接达到3档；失败保留。③先用旧层数，再获得新层数。\n范围：普通拘束具与链接绳，不施加复合拘束具；初级不含口球。出手时选择装备和位置，满位时可替换。")
 t.check(enemy_sequence.contains("第11行動で収監") and enemy_sequence.contains("体術を使用できない") and enemy_sequence.contains("ファイアボールとカード魔法には影響しない"),"LOCALE Japanese enemy sequence preserves the eleventh-action arrest and physical-skill-only disable")
 var guard_capture=l.display("开场会束住手腕、口部和脚踝，再准备并施加50/100的捕缚。无法新增或合法替换时，改为加固该处1次；紧度3且可上锁时，上锁并恢复满耐久。用挣扎或滑脱牌削减捕缚；达到100后，警卫下一次行动会收押你。")
 t.check(guard_capture.contains("もがく") and guard_capture.contains("抜け出し") and guard_capture.contains("100に達すると") and guard_capture.contains("次の行動で収監"),"LOCALE Japanese guard summary preserves release-card actions, capture threshold and next-action imprisonment")
 var membership=l.display("商店限定。购买会员卡仅可使用自身魔力。持有后，商店全部商品、删牌及解除拘束服务五折；其他交易仍可使用自身魔力或魔瓶付款。")
 t.check(membership.contains("自身の魔力だけ") and membership.contains("半額") and not membership.contains("5倍") and membership.contains("魔瓶"),"LOCALE Japanese membership card preserves its payment restriction and half-price services")
 var capture_rules=l.display("被捕缚时无法移动，先解除捕缚。挣扎／滑脱牌可直接削减进度；除眼罩、口球外没有其他拘束具时伤害翻倍，环境加成为0。上身受限至少按1级计算。同种捕缚仅生效一次；新种类增加其初始值的一半。降至0全部解除，达到100后下一敌方回合执行收押。\n降紧每层固定削减8点捕缚，使用固定数值，蓄力保留。")
 t.check(capture_rules.contains("カードで進度を減らし") and capture_rules.contains("別種追加は初期進度の半分") and capture_rules.contains("固定8減少"),"LOCALE Japanese capture glossary preserves direct reduction, added half progress and fixed loosening value")
 var binding_echo=l.display("下一张成功打出的双面效果各异的拘束面牌，每层额外释放一次。免费复放，只作用原目标，目标失效则跳过。")
 t.check(binding_echo.contains("1層につき1回追加発動") and binding_echo.contains("無料") and binding_echo.contains("元の対象") and binding_echo.contains("無効ならスキップ"),"LOCALE Japanese binding echo preserves per-layer replay, cost, target and invalid-target skip")
 var damage_cap=l.display("每回合受到的最终伤害合计最多%s点，多次攻击、多段及玩偶转移伤害共用额度；下一回合恢复。\n伤害严格超过屏障剩余额度时，玩偶普通反击容量上限－1，最低1，持续本场战斗；多段及群攻每次攻击只扣一次。额度耗尽后继续攻击仍可触发。" % 12)
 t.check(damage_cap.contains("最大12") and damage_cap.contains("同じ上限枠を共有") and damage_cap.contains("上限－1（最低1）") and damage_cap.contains("ちょうど使い切った攻撃では発動しない"),"LOCALE Japanese barrier rule preserves the shared cap and counter-capacity decrement boundary")
 var wand_points=l.display("每成功打出1张技能牌，积攒1点，上限15。右键图标消耗全部点数，恢复等量自身魔力；满15点自动兑换并清空。点数跨回合、跨战斗保留，仅主动出牌计数；恢复至多为魔力上限。")
 t.check(wand_points.contains("上限15") and wand_points.contains("15ポイントになると自動的") and wand_points.contains("ターンと戦闘をまたいで保持") and wand_points.contains("再発動では追加されない"),"LOCALE Japanese large-wand points preserve the cap, automatic exchange and carry-over rules")
 var free_hand_arts=l.display("接下来2次手部体术按自由态发动，忽略拘束限制与减益；包括肘击、近身短打及其连击。每次完整攻击消耗1次，姿势、费用与次数限制照常。每次使用增加2次，剩余次数可累计。")
 t.check(free_hand_arts.contains("手部体術") and free_hand_arts.contains("攻撃全体につき使用回数を1消費") and free_hand_arts.contains("残り回数は累積"),"LOCALE Japanese free-hand effect preserves martial arts, per-complete-attack use and stacked remainder")
 t.check(l.text("ui.flask.withdraw_uses","取 {dots}",{"dots":"..."})=="取り出す ..." and l.text("ui.flask.deposit_uses","存 {dots}",{"dots":"..."})=="預ける ...","LOCALE Japanese flask actions keep deposit and withdrawal verbs")
 t.check(l.display("恢复12魔力。").contains("回復") and l.display("支付12魔力。").contains("支払") and l.display("返还12魔力").contains("返還"),"LOCALE Japanese mana logs keep restore, pay and refund actions distinct")
 t.check(l.display("4件")=="4個" and l.display("3张")=="3枚" and l.display("张")=="枚","LOCALE Japanese dynamic counters keep their units")
 var damage_copy=l.display("对Dummy造成12点Fire伤害。")
 t.check(damage_copy.contains("Dummy") and damage_copy.contains("12") and damage_copy.contains("Fire") and damage_copy.contains("ダメージ"),"LOCALE Japanese generic damage log keeps target, amount and type")
 var self_bind_copy=l.display("自缚：在Hands佩戴Belt（Medium，紧度2档）。")
 t.check(self_bind_copy.contains("自縛") and self_bind_copy.contains("Hands") and self_bind_copy.contains("Belt") and self_bind_copy.contains("2"),"LOCALE Japanese self-binding log keeps the action, slot, item and tightness")
 t.check(not l.set_locale("../../invalid") and l.locale=="ja_JP","LOCALE invalid language is rejected without changing preference")
 var spec=source()
 t.check(l.install_source(spec),"LOCALE accepts complete named source templates")
 var base=spec.messages["test.line"].text
 var values={"name":"测试","count":2.5}
 # Deliberately artificial text tests reordering; this is not a Japanese translation.
 var translated="{count} | {name} / {name}"
 t.check(l.install_translation("ja_JP",translation({"test.line":{"source":base,"text":translated}})),"LOCALE accepts reordered parameters with preserved occurrences")
 t.check(l.text("test.line",base,values)=="2.5 | 测试 / 测试","LOCALE names and decimal values survive reordering")
 spec.messages["test.line"].text="外部修改"
 t.check(l.text("test.line",base,values)=="2.5 | 测试 / 测试","LOCALE installed catalog does not retain writable source aliases")
 t.check(l.text("test.other","中文回退")=="中文回退" and l.coverage("ja_JP")=={"total":3,"translated":1,"missing":2},"LOCALE per-key fallback and coverage stay explicit")
 t.check(l.text("test.braces","{{名称}}：{name}",{"name":"{count}"})=="{名称}：{count}","LOCALE escape braces and substituted values are interpreted only once")
 t.check(l.text("test.line","新正文{count}",{"count":7})=="新正文7","LOCALE stale callsite uses its current original text, never old translation")
 t.check(l.text("unknown.id","保留原文")=="保留原文","LOCALE unknown IDs cannot leak to the player")
 for invalid in [{"name":"test"},{"name":"test","count":2,"extra":1},{"name":[],"count":2},{"name":"test","count":INF}]:
  t.check(l.text("test.line",base,invalid)==Localizer.DISPLAY_ERROR,"LOCALE invalid call parameters yield a safe display result")
 for bad in [null,{}, {"schema_version":2,"locale":"ja_JP","messages":{}}, translation({"unknown.id":{"source":"中文","text":"TEST"}}), translation({"test.line":{"source":"旧文","text":translated}}),translation({"test.line":{"source":base,"text":"{name} {count}"}}),translation({"test.line":{"source":base,"text":"{name} {count} {name} {extra}"}}),translation({"test.line":{"source":base,"text":"{name"}}),translation({"test.line":{"source":base,"text":12}})]:
  t.check(not l.install_translation("ja_JP",bad) and l.text("test.line",base,values)=="2.5 | 测试 / 测试","LOCALE invalid pack is rejected atomically without replacing accepted copy")
 var invalid_source=source();invalid_source.messages["test.other"].text="坏{"
 t.check(not l.install_source(invalid_source) and l.text("test.line",base,values)=="2.5 | 测试 / 测试","LOCALE invalid base is rejected atomically")
 t.check(l.install_translation("ja_JP",translation({"test.line":{"source":base,"text":""}})) and l.text("test.line",base,values)=="测试：剩余2.5次（测试）","LOCALE empty draft remains an untranslated key")
 var notes=l.diagnostics();notes.clear()
 t.check(not l.diagnostics().is_empty(),"LOCALE diagnostics are detached from the display and returned by copy")
 t.check(l.install_source(source()) and l.coverage("ja_JP").translated==0,"LOCALE a new source load invalidates previously loaded translation versions")
 legacy_contract(t)
 display_cache(t)
 file_fallbacks(t)

static func display_cache(t) -> void:
 var l=Localizer.new();l.set_locale("en_US")
 var pack={"schema_version":1,"locale":"en_US","messages":[
  {"id":"legacy.remaining","source":"余量%d点","text":"Remaining {p0}"},
  {"id":"legacy.ascii","source":"HP","text":"Health"}]}
 t.check(l.install_legacy_translation("en_US",pack) and l.display("HP")=="Health" and l.display("Mana 42 / 100")=="Mana 42 / 100","LOCALE non-Chinese fast path preserves registered exact translations and untouched numeric text")
 for i in range(3): t.check(l.display("余量7点")=="Remaining 7","LOCALE repeated dynamic display keeps identical output")
 pack.messages[0].text="Left {p0}"
 t.check(l.install_legacy_translation("en_US",pack) and l.display("余量7点")=="Left 7","LOCALE accepted replacement invalidates previously displayed dynamic text")
 var invalid=pack.duplicate(true);invalid.messages[0].text="Missing parameter"
 t.check(not l.install_legacy_translation("en_US",invalid) and l.display("余量7点")=="Left 7","LOCALE rejected translation keeps accepted cached output")
 var japanese=pack.duplicate(true);japanese.locale="ja_JP";japanese.messages[0].text="JP {p0}"
 t.check(l.install_legacy_translation("ja_JP",japanese) and l.set_locale("ja_JP") and l.display("余量7点")=="JP 7","LOCALE language switch cannot reuse another language's cached text")
 l.set_locale("en_US")
 t.check(l.display("余量7点")=="Left 7","LOCALE switching back restores the correct catalog")
 for i in range(l.MAX_DISPLAY_ENTRIES+5): l.display("未知短句"+str(i))
 t.check(l._display_cache.size()<=l.MAX_DISPLAY_ENTRIES and l.display("余量7点")=="Left 7","LOCALE varied text has bounded entries and evicted results still resolve correctly")
 for i in range(40): l.display("文".repeat(2048)+str(i))
 t.check(l._display_cache_characters<=l.MAX_DISPLAY_CHARACTERS and l._display_cache.size()<40,"LOCALE long display strings obey the total character budget before the entry limit")
 var count=l._display_cache.size();var huge="文".repeat(l.MAX_DISPLAY_CHARACTERS+1)
 t.check(l.display(huge)==huge and l._display_cache.size()==count,"LOCALE oversized text remains intact without retaining it in the display cache")

static func bundled_font(t) -> void:
 var path="res://assets/fonts/NotoSansCJKsc-Regular.otf"
 var font=load(path) as FontFile
 t.check(font!=null,"LOCALE Chinese font ships as a loadable resource")
 if font==null: return
 var isolated=font.duplicate() as FontFile
 isolated.allow_system_fallback=false
 isolated.fallbacks=[]
 var missing=[]
 for ch in "紧缚尖塔開始遊戲設定繁體中文魔力回合あいうえおカタカナABCxyz0123456789，。！？＋－×％":
  if not isolated.has_char(ch.unicode_at(0)): missing.append(ch)
 t.check(missing.is_empty(),"LOCALE bundled font covers Chinese, traditional Chinese, kana and Latin without installed fonts: "+str(missing))
 var supported={}
 for ch in isolated.get_supported_chars(): supported[ch]=true
 var absent={}
 for file in ["res://assets/localization/zh_CN.json","res://assets/localization/legacy-en_US.json","res://assets/localization/legacy-ja_JP.json","res://data/balance.gd","res://ui/main.gd"]:
  for ch in FileAccess.get_file_as_string(file):
   var cp=ch.unicode_at(0)
   if cp>=0x3400 and cp<=0x9fff and not supported.has(ch): absent[ch]=true
 t.check(absent.is_empty(),"LOCALE authored Chinese UI and card copy has no missing bundled glyphs: "+str(absent.keys()))
 t.check(ProjectSettings.get_setting("gui/theme/custom_font","")==path,"LOCALE project default also supplies Chinese to unthemed popup controls")
 var presets=ConfigFile.new()
 t.check(presets.load("res://export_presets.cfg")==OK,"LOCALE export presets are readable")
 for section in ["preset.0","preset.1"]:
  t.check("assets/fonts/OFL" in str(presets.get_value(section,"include_filter","")),"LOCALE font license is included in "+section)

static func legacy_contract(t) -> void:
 var l=Localizer.new();l.set_locale("en_US")
 var document={"schema_version":1,"locale":"en_US","messages":[
  {"id":"legacy.turn","source":"第%d回合：%s","text":"Turn {p0}: {p1}"},
  {"id":"legacy.action","source":"行动","text":"Action"},
  {"id":"legacy.start","source":"开始","text":"Begin"},
  {"id":"legacy.end","source":"结束","text":"End"}]}
 t.check(l.install_legacy_translation("en_US",document) and l.display("第12回合：行动")=="Turn 12: Action","LOCALE compatibility templates localize nested display values without changing their source data")
 t.check(l.display("开始 / 结束")=="Begin / End","LOCALE compatibility fragments translate old UI concatenation without changing its source value")
 for bad in [null,{}, {"schema_version":1,"locale":"en_US","messages":[{"id":"legacy.turn","source":"第%d回合","text":"Turn"}]}, {"schema_version":1,"locale":"en_US","messages":[{"id":"legacy.same","source":"甲","text":"A"},{"id":"legacy.same","source":"乙","text":"B"}]}]:
  t.check(not l.install_legacy_translation("en_US",bad) and l.display("第3回合：等待")=="Turn 3: 等待","LOCALE invalid compatibility catalog is rejected atomically")
 document.messages.append({"id":"legacy.symbols","source":"%s / %s","text":"UNRELATED {p0} and {p1}"})
 document.messages.append({"id":"legacy.short","source":"第%d!","text":"Ordinal {p0}"})
 t.check(l.install_legacy_translation("en_US",document),"LOCALE weak legacy templates can be skipped without discarding valid entries")
 t.check(l.display("12 / 30")=="12 / 30" and l.display("第12!")=="Ordinal 12","LOCALE punctuation-only templates stay disabled while a numeric template may use one exact Chinese anchor")
 t.check(l.display("第12回合：行动")=="Turn 12: Action","LOCALE constrained Chinese templates still translate their nested values")

static func file_fallbacks(t) -> void:
 var folder="res://build/localization-fixture-%s" % OS.get_process_id()
 DirAccess.make_dir_recursive_absolute(folder)
 var base_path=folder.path_join("zh_CN.json")
 var target_path=folder.path_join("ja_JP.json")
 var l=Localizer.new()
 l.set_locale("en_US");l.display("蓄力2")
 # Isolated build fixtures exercise IO failures, never the shipped assets.
 var file=FileAccess.open(base_path,FileAccess.WRITE)
 file.store_string(JSON.stringify(source()));file.close()
 t.check(not l.load_directory(folder) and l.diagnostics().any(func(d):return d.code=="missing_file"),"LOCALE absent target file is diagnosed without throwing a runtime error")
 l.set_locale("en_US")
 t.check(l.display("蓄力")=="蓄力" and l.display("蓄力2")=="蓄力2","LOCALE reloading a directory without its legacy pack clears accepted exact, template and fragment translations")
 l.set_locale("ja_JP")
 t.check(l.text("test.other","中文回退")=="中文回退","LOCALE absent target file leaves the loaded Chinese catalog usable")
 file=FileAccess.open(target_path,FileAccess.WRITE)
 file.store_string("{ invalid JSON");file.close()
 t.check(not l.load_directory(folder) and l.text("test.other","中文回退")=="中文回退","LOCALE malformed target JSON still displays Chinese")
 file=FileAccess.open(base_path,FileAccess.WRITE)
 file.store_string("[]");file.close()
 t.check(not l.load_directory(folder) and l.text("test.other","中文回退")=="中文回退","LOCALE invalid source file preserves the last accepted catalog")
 DirAccess.remove_absolute(base_path);DirAccess.remove_absolute(target_path);DirAccess.remove_absolute(folder)
 t.check(not l.load_directory(folder) and l.text("unregistered.message","调用处原文")=="调用处原文","LOCALE missing entire directory still uses inline original text")

static func enemy_profiles(t) -> void:
 var g=preload("res://tests/iron_man_cases.gd").encounter()
 var actor=g.state.enemies[0]
 var localizer=Localizer.new()
 var chinese=RegEx.new();chinese.compile("[\\x{3400}-\\x{9fff}]")
 for entry in preload("res://data/encyclopedia.gd").entries().filter(func(row):return row.category=="enemies" and row.id in ["rope","drone","mixed_bundle","small_circle"]):
  for locale in ["en_US","ja_JP"]:
   localizer.set_locale(locale)
   var translated=localizer.display(entry.text)
   t.check(not translated.contains("初级2档") and not translated.contains("中级1档") and not translated.contains("medium tier 1") and not translated.contains("中級段階1"),"LOCALE weak enemy descriptions only advertise basic non-departure equipment: "+entry.id+" "+locale)
 for locale in ["en_US","ja_JP"]:
  localizer.set_locale(locale)
  for level in [0,1,2]:
   actor.iron_enhancements=level;actor.stage=3+5*level
   var plan=g.IronMan.plan(g,actor)
   var before=g.export_snapshot()
   var translated=localizer.display(plan.text)
   t.check(chinese.search(translated)==null if locale=="en_US" else not translated.contains("档"),"LOCALE enemy grade/tightness combinations translate as complete phrases: "+locale+str(level))
   t.check(translated.contains(str(plan.count)) and translated.contains("tier" if locale=="en_US" else "段階") and g.export_snapshot()==before,"LOCALE enemy profile display preserves count and state")
