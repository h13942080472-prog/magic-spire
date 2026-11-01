extends RefCounted
const Book=preload("res://data/encyclopedia.gd")
const Game=preload("res://tests/game_fixture.gd")
static func run(t) -> void:
 var g=Game.new(42);var before=g.export_snapshot()
 var entries=Book.entries();var seen=[]
 var items=entries.filter(func(entry):return entry.category=="items")
 t.check(items.size()==Book.Tools.TYPES.size() and Book.Tools.TYPES.keys().all(func(type):return items.any(func(entry):return entry.id==type)),"BOOK every registered tool, potion and scroll is included once")
 var neutral=Game.new(42);neutral.state.equipment.clear();neutral.state.relics=[]
 for entry in items:
  var spec=Book.Tools.TYPES[entry.id]
  t.check(entry.text.contains(neutral.Tools.description(neutral,entry.id)) and entry.text.contains("使用次数：%d" % spec.uses),"BOOK item effect and charges share inventory formatter "+entry.id)
  if not spec.get("trigger_damage_types",[]).is_empty():
   t.check(entry.text.contains(Book.InstalledTools.effect_description(entry.id,spec.damage)),"BOOK installed passive uses shared actual trigger contract "+entry.id)
 t.check(items.filter(func(entry):return entry.group=="药剂").size()==Book.Tools.TYPES.values().filter(func(spec):return spec.get("category","")=="potion").size(),"BOOK potion branch follows registered categories")

 var illustrated=entries.filter(func(e):return e.category=="equipment")
 var wraps=illustrated.filter(func(e):return e.id.begins_with("composite_wrap_"))
 t.check(wraps.size()==3 and wraps.map(func(e):return e.grade)==[1,2,3] and wraps.all(func(e):return e.title=="胶带包裹" and e.text.contains("只包裹对应一侧的手掌和手指")),"BOOK hand wraps share one single-hand entry per grade")
 t.check(illustrated.all(func(e):return not e.text.contains("紧度：剩余耐久")),"BOOK omits the unwanted generic tightness-band explanation")
 var wrap=illustrated.filter(func(e):return e.id=="composite_wrap_left_straight3")[0]
 t.check(wrap.text.contains("覆盖：手掌、手指\n\n包裹：耐久30；") and not wrap.text.contains("组件：包裹") and not wrap.text.contains("30.0") and wrap.text.contains("\n\n只包裹"),"BOOK compact composite paragraphs separate coverage, component values and effects without duplicate labels")
 for config in [[1,0],[2,0],[2,1],[3,0]]:
  var entry=entries.filter(func(e):return e.id=="equipment_mouth_band_%d_%d" % config)[0]
  var grade_factor=Book.B.MOUTH_CAST_GRADE[config[0]]
  t.check(entry.text.contains("品质倍率×"+str(grade_factor)) and not entry.text.contains("组合效果以该品质"),"BOOK gag states actual grade multiplier rather than a placeholder")
  for tightness in [1,2,3]:
   t.check(entry.text.contains(str(grade_factor*Book.B.MOUTH_CAST_TIGHTNESS[tightness])),"BOOK gag lists every actual combined tightness multiplier")
  t.check(entry.text.contains("马具结构禁止")==Book.E.mouth_combination(config[0],config[1]).harness,"BOOK only harness combinations claim structural slip prohibition")
 for entry in illustrated:
  if entry.id.begins_with("equipment_eye_"): t.check(entry.text.contains("敌人意图隐藏"),"BOOK every eye cover explains visual limitation")
  if entry.id.begins_with("composite_"): t.check(entry.text.contains("耐久"),"BOOK composite components include actual durability and methods")
 t.check(illustrated.filter(func(e):return e.id=="composite_glove_long_cross2")[0].text.contains("滑脱效果×0.5") and illustrated.filter(func(e):return e.id=="composite_leg_toes_straight2")[0].text.contains("外带保留"),"BOOK composite structure exceptions are explicit")
 t.check(illustrated.filter(func(e):return e.id=="link_rope")[0].text.contains("×1.25"),"BOOK link explains the ordinary downward-link modifier")
 for entry in entries.filter(func(e):return e.category=="special"):
  var spec=Book.S.TYPES[entry.id]
  if spec.duration>0: t.check(entry.text.contains("装备继续佩戴"),"BOOK battery expiry does not imply removal")
  if "manual" in Book.S.DESIGNS[entry.id].methods: t.check(entry.text.contains("1能量直接取出"),"BOOK manual special equipment explains actual cost and body conditions")
  if Book.S.is_chastity_type(entry.id): t.check(entry.text.contains(spec.detail) and entry.text.contains("品质＋紧度"),"BOOK plate-lock entries include their registered exceptions and numerical effects")
 t.check(not illustrated.is_empty() and illustrated.all(func(e):return e.get("image","")!="" and load(e.image) is Texture2D),"BOOK ordinary, composite and link entries have loadable equipment images")
 var missing=entries.filter(func(e):return e.category=="special" and Book.S.TYPES[e.id].family not in Book.Images.SPECIAL)
 t.check(missing.all(func(e):return e.image==""),"BOOK special equipment without existing art keeps no unrelated image")
 for type in ["urethral_rod_low","urethral_rod_medium","urethral_rod_high"]:
  var sample=Game.new(42)
  var equipped=sample._install_special(type,"special_2_d")
  var entry=entries.filter(func(e):return e.category=="special" and e.id==type)[0]
  var image=sample.View.equipment_entry(sample,equipped,equipped.slot).image
  t.check(entry.image==image and load(image) is Texture2D,"BOOK special icon matches actual equipped grade "+type)
 for entry in entries:
  var key=entry.category+"/"+entry.id
  t.check(key not in seen and entry.title!="" and entry.text!="" and entry.category in Book.CATEGORIES,"BOOK unique complete entry "+key)
  seen.append(key)
 var variants=["magic_hand_gift","hannya_swallow","hannya_infusion","hannya_henshin","hannya_2","hannya_3","hannya_4","good_soup","double_unlock"]
 var card_entries=entries.filter(func(e):return e.category=="cards")
 var visible_types=Book.Cards.SPECS.keys().filter(func(type):return not Book.Cards.SPECS[type].get("encyclopedia_hidden",false) and Book.Cards.SPECS[type].get("character_id","original")=="original")
 t.check(card_entries.size()==visible_types.size() and variants.all(func(type):return not card_entries.any(func(e):return e.id==type)) and not card_entries.any(func(e):return e.id.begins_with("witch_")),"BOOK duplicate special variants and other-character cards omitted from original entries")
 for type in variants:
  t.check(Book.Cards.SPECS.has(type) and Book.card(type).name==Book.B.CARD_NAMES[type],"BOOK hidden variant retains full gameplay card display: "+type)
 for original in Book.CARD_VARIANTS:
  var entry=card_entries.filter(func(e):return e.id==original)[0]
  t.check(entry.related_cards==Book.CARD_VARIANTS[original] and entry.related_cards.all(func(id):return entry.search_text.contains(Book.card(id).name)),"BOOK original detail and search include its real variant: "+original)
 var chain=Book.related_cards("hannya_1")
 for stage in range(1,4):
  var source=Book.card("hannya_%d" % stage)
  var full_name=Book.B.CARD_NAMES["hannya_%d" % (stage+1)]
  var reward=Book.Cards.HANNYA_REWARDS[stage]
  t.check(source.bound.contains(full_name+"加入弃牌堆") and source.free.contains(full_name+"加入弃牌堆") and reward.bound.contains(full_name+"加入弃牌堆") and reward.free.contains(full_name+"加入弃牌堆"),"BOOK soup card and live reward descriptions use complete generated name: "+full_name)
 t.check(chain==["hannya_2","hannya_swallow","hannya_3","hannya_infusion","hannya_4","hannya_henshin","good_soup"],"BOOK soup chain shows all descendants once in generation order")
 t.check(Book.related_cards("hannya_4")==["hannya_henshin","good_soup"] and Book.related_cards("good_soup").is_empty() and Book.related_cards("strain").is_empty(),"BOOK final stage includes only its descendants and ordinary cards have none")
 chain.clear()
 t.check(Book.related_cards("hannya_1").size()==7,"BOOK related card results do not mutate definitions")
 for type in ["magic_hand","light_as_swallow","infusion","henshin","hannya_1"]:
  t.check(card_entries.any(func(e):return e.id==type),"BOOK original cards remain as family entries: "+type)
 t.check(entries.filter(func(e):return e.category=="special").size()==Book.S.TYPES.size(),"BOOK all registered special equipment included")
 for type in ["urethral_rod_low","urethral_rod_medium","urethral_rod_high"]:
  t.check(entries.filter(func(e):return e.category=="special" and e.id==type)[0].text.contains("每次高潮：受到6－当前紧度档位－装备等级的固定滑脱伤害"),"BOOK urethral rod explains climax slip formula: "+type)
 t.check(not entries.filter(func(e):return e.category=="special" and e.id=="urethral_full_cup_high")[0].text.contains("固定滑脱伤害"),"BOOK integrated urethral cup does not inherit the separate rod-family rule")
 t.check(entries.filter(func(e):return e.category=="enemies").size()==Book.N.TYPES.size(),"BOOK all registered enemies included, not pending designs")
 for entry in entries.filter(func(e):return e.category=="enemies"):
  var spec=Book.N.TYPES[entry.id]
  var affected=not spec.get("humanoid",false) or not spec.has("capture_kind")
  t.check(not entry.text.contains("不会自行离场") and entry.text.contains("长战斗：")==affected,"BOOK long-battle copy follows humanoid and capture boundaries: "+entry.id)
  if affected:
   t.check(entry.text.contains("第15回合") and entry.text.contains("20件") and entry.text.contains("40") and entry.text.contains("首领战及其随行单位维持原规则"),"BOOK long-battle thresholds and boss exemption are explicit: "+entry.id)
   t.check(entry.text.contains("反复准备逮捕") if spec.get("humanoid",false) else entry.text.contains("自动离场"),"BOOK long-battle outcome follows the registered enemy kind: "+entry.id)
 var iron_box=entries.filter(func(e):return e.category=="enemies" and e.id=="binding_box")[0]
 t.check(iron_box.text.contains("生命：64") and iron_box.text.contains("铁男战中的随行实例为40") and iron_box.text.contains("小魔女铁男战为52"),"BOOK binding box distinguishes its ordinary and Iron Man encounter health")
 var relics=entries.filter(func(e):return e.category=="relics")
 t.check(relics.size()==g.Relics.TYPES.values().filter(func(spec):return spec.get("character_id","")!="witch").size() and relics.all(func(e):return e.rarity==g.Relics.TYPES[e.id].rarity and e.rarity_name==g.Relics.RARITIES[e.rarity]),"RELIC every registered relic has its authoritative rarity in encyclopedia")
 t.check(relics.any(func(e):return e.id=="ember" and e.group=="初始遗物") and "ember" not in g.Relics.REWARDS,"RELIC starter classification does not add it to reward sources")
 var projected=g.get_view().relics[0]
 t.check(projected.rarity=="common" and projected.rarity_name=="普通" and projected.detail==g.Relics.TYPES[projected.id].detail,"RELIC owned view keeps effect and explicit rarity together")
 t.check(entries.any(func(e):return e.category=="cards" and e.group=="诅咒牌" and e.id=="panic"),"BOOK curse branch includes actual curse")
 t.check(entries.any(func(e):return e.category=="cards" and e.group=="诅咒牌" and e.id=="sensitive" and e.text.contains("1.2")),"BOOK sensitive registered in curse branch with actual multiplier")
 for type in ["tease","tease_plus"]:
  var status_card=Book.card(type)
  t.check(entries.any(func(e):return e.category=="cards" and e.group=="状态牌" and e.id==type) and status_card.rarity=="status" and not Book.B.CARD_TRAITS[type].get("curse",false) and type not in Book.Cards.REWARDS,"BOOK status cards have a separate branch and remain outside reward pools")
 var guard=entries.filter(func(e):return e.category=="enemies" and e.id=="guard")[0]
 t.check(guard.text.contains("50/100") and guard.text.contains("伤害×2") and guard.text.contains("躺姿→坐姿→站姿") and not guard.text.contains("10个战斗回合"),"BOOK guard entry explains current bind route without removed deadline")
 t.check(g.export_snapshot()==before,"BOOK browsing never changes state or random counters")
 var item=entries[0];item.text="changed"
 t.check(Book.entries()[0].text!="changed","BOOK snapshot does not mutate registry")
 for type in Book.Cards.SPECS:
  var face=Book.card(type)
  t.check(face.bound==Book.B.card_info(type)[1] and face.free==Book.B.card_info(type)[2],"BOOK card face reads authoritative text "+type)
