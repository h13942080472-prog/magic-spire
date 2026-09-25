extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Book=preload("res://data/encyclopedia.gd")
const Text=preload("res://data/card_text.gd")

static func run(t) -> void:
 paired_faces(t)
 copy_fixed_set_matches_full_entry(t)
 var g=Game.new(42);var before=g.export_snapshot()
 var pot=Book.card("pot_of_greed")
 t.check(pot.face_keywords.bound==[Text.TERMS.exhaust] and pot.face_keywords.free==[Text.TERMS.exhaust] and pot.note=="","TERMS pot explains exhaust on both faces without a redundant draw glossary")
 var search=Book.card("mana_search")
 t.check(search.face_keywords.bound.size()==1 and search.face_keywords.bound[0].detail=="从抽牌堆抽取指定类型的牌。" and search.note=="","TERMS search has one concise explanation shared across cards")

 for type in g.Cards.Rules.SPECS:
  var spec=g.Cards.Rules.SPECS[type];var card=Book.card(type)
  for side in ["bound","free"]:
   var free=side=="free"
   var text=card[side]
   t.check(text!="" and not text.contains("{") and not text.contains("受拘束："),"TERMS every card face is fully expanded: "+type+side)
   t.check(card.face_requirements[side].any(func(line):return line.begins_with("施法："))==g.Cards.uses_magic({"type":type,"free":free}),"TERMS casting badge follows actual selected face: "+type+side)
   var terms=card.face_keywords[side].map(func(term):return term.name)
   t.check(terms.all(func(term):return terms.count(term)==1),"TERMS per-face glossary has no duplicate entries")
   if free and spec.has("free_max_levels"):
    t.check(card.face_requirements.free.filter(func(line):return line.contains("束缚等级")).size()==spec.free_max_levels.size(),"TERMS aggregate body limits displayed separately alongside any casting condition")
 t.check(Book.card("mana_search").free=="检索魔法2。" and Book.card("mana_search").face_requirements.free==["上身束缚等级＝0"],"TERMS search effect and total-level condition are separate")
 t.check(Book.card("fire_control").face_requirements.free==["手部自由","上身束缚等级≤1"] and not Book.card("fire_control").face_keywords.free.any(func(term):return term.name=="各部位紧度＝0"),"TERMS control combines hand freedom with aggregate upper limit and removes old restriction")
 t.check(Book.card("crossed_legs").face_requirements.bound==["目标：腿部"] and Book.card("crossed_legs").face_requirements.free==["腿部束缚等级≤1"],"TERMS target restriction stays on bound face")
 t.check(Book.card("unlock").free=="获得2层魔力预备。" and Book.card("unlock").face_requirements.free==["使用：手部"],"TERMS preparation retains hand eligibility without a casting roll")
 var metadata=Book.card("chain");metadata.face_keywords.bound[0].detail="changed";metadata.face_requirements.free.append("changed")
 t.check(not str(Book.card("chain")).contains("changed") and g.export_snapshot()==before,"TERMS reading and mutating projected copy cannot change state or shared terms")
 card_keyword_deps_stable_ids(t)
 var spec=g.Cards.Rules.SPECS.mana_search.duplicate(true)
 g.Cards.Rules.SPECS.mana_search.self_faces.free.effects[0].amount=3
 g.Cards.Rules.SPECS.mana_search.free_max_levels.arms=1
 t.check(Book.card("mana_search").free=="检索魔法3。" and Book.card("mana_search").face_requirements.free==["上身束缚等级≤1"],"TERMS text follows mechanical quantity and gate without a second lookup table")
 g.Cards.Rules.SPECS.mana_search=spec
 mana_badges(t)

# docs/spec/ondemand-copy.md「证据入口」：三个入口对全部注册牌型逐字段
# 相等；S 内的键在视图里、S 外的键不在；读取不改状态、随机与版本。
static func copy_fixed_set_matches_full_entry(t) -> void:
 var g=Game.new(42)
 preload("res://tests/curse_cases.gd").give(g,"strain")
 var before=g.export_snapshot()
 var view=g.get_view()
 var facts=g.command_facts()
 var shown=battle_display_set(g,facts)
 var mismatch=[]
 for type in g.Cards.Rules.SPECS:
  var single=g.live_card_text(type)
  if single!=g.live_card_text_set([{"type":type}]).texts.get(type,{}): mismatch.append("set "+type)
  if view.card_texts.has(type)!=shown.has(type): mismatch.append("scope "+type)
  elif shown.has(type) and view.card_texts[type]!=single: mismatch.append("value "+type)
 t.check(mismatch.is_empty(),"COPY scenario 1 three entries agree for every registered type: "+str(mismatch.slice(0,5)))
 t.check(g.export_snapshot()==before and g.state.version==view.version,"COPY scenario 1 reads leave state, random domains and version unchanged")

# S 按 契约声明的显示入口独立重算（与 game_view 的实现分开写）。
static func battle_display_set(g, facts: Array) -> Dictionary:
 var shown={}
 for card in g.state.hand: shown[card.type]=true
 for type in g.state.reward_options: shown[type]=true
 for type in g.state.rest_cards: shown[type]=true
 for candidate in facts:
  var type=String(candidate.payload.get("type",""))
  if g.Cards.Rules.SPECS.has(type): shown[type]=true
 for row in g.Services.view(g).get("stock",[]):
  if row.get("kind","")=="card": shown[String(row.get("type",""))]=true
 for selection in g.Events.view(g).get("selections",[]):
  if selection.get("kind","")!="card": continue
  for option in selection.get("options",[]):
   var selected=option.get("selected",{})
   var type=String(selected.get("type",option.get("type","")))
   if g.Cards.Rules.SPECS.has(type): shown[type]=true
 return shown

static func card_text_func_body(name: String) -> String:
 var handle=FileAccess.open("res://data/card_text.gd",FileAccess.READ)
 if handle==null: return ""
 var source=handle.get_as_text()
 var start=source.find("func "+name+"(")
 if start<0: return ""
 var rest=source.substr(start)
 var nxt=rest.find("func ",1)
 var body=rest if nxt<0 else rest.substr(0,nxt)
 var code=""
 for line in body.split("\n"): code+=String(line).split("#")[0]+"\n"
 return code

static func card_text_func_call_count(body: String, name: String) -> int:
 var needle=name+"("
 var count=0
 var from=0
 while true:
  var at=body.find(needle,from)
  if at<0: break
  count+=1
  from=at+needle.length()
 return count

static func card_keyword_deps_stable_ids(t) -> void:
 var keywords_body=card_text_func_body("keywords")
 t.check(keywords_body!="" and card_text_func_call_count(keywords_body,"keyword_ids")==1,"DEPS keywords() calls keyword_ids exactly once")
 t.check(keywords_body.find("_effect_terms(")<0 and keywords_body.find("_buff_terms(")<0 and keywords_body.find("unique_face(")<0 and keywords_body.find("Rules.exhausts(")<0 and keywords_body.find("ids.append")<0,"DEPS keywords() has no second SPECS/effect collector")
 var Rules=Text.Rules
 var g=Game.new(42)
 var traits=g.B.CARD_TRAITS
 var before=g.export_snapshot()
 var rng_before=g.state.rng.duplicate(true)
 var types=["strain","slip","crossed_legs","strong_elbow","magic_hand","pot_of_greed","mana_search"]
 var recorded={}
 for type in types:
  recorded[type]={}
  for free in [false,true]:
   var side_traits=traits.get(type,{})
   var kws_before=Text.keywords(type,free,side_traits)
   var projection=[]
   for term in kws_before:
    t.check(term.has("name") and term.has("detail") and not term.has("id"),"DEPS keywords projection has name and detail without id: "+type+str(free))
    projection.append({"name":term.name,"detail":term.detail})
   var ids=Text.keyword_ids(type,free,side_traits)
   var kws=Text.keywords(type,free,side_traits)
   var slots=Rules.SPECS[type].get("target_slots",[]).duplicate()
   var mode=Rules.face_mode(type,free)
   t.check(ids is Array and ids.size()==kws.size() and ids.size()==projection.size(),"DEPS keyword_ids is a string array aligned with keywords: "+type+str(free))
   for i in range(ids.size()):
    t.check(typeof(ids[i])==TYPE_STRING and Text.TERMS.has(ids[i]),"DEPS keyword id belongs to TERMS keys: "+str(ids[i]))
    t.check(kws[i].name==projection[i].name and kws[i].detail==projection[i].detail and not kws[i].has("id"),"DEPS keywords name/detail stay equal before TERMS mutate: "+type+str(free))
   recorded[type][free]={"ids":ids.duplicate(),"slots":slots,"mode":mode}
 t.check("strain" in recorded.strain[false].ids and recorded.strain[false].slots.is_empty() and recorded.strain[false].mode=="strain","DEPS strain bound ids contain strain, no target_slots, mode strain")
 t.check(recorded.crossed_legs[false].slots==Rules.FOLLOW_THROUGH_REGIONS.legs,"DEPS crossed_legs bound target_slots equal FOLLOW_THROUGH_REGIONS.legs")
 t.check(recorded.strong_elbow[false].slots==["upper_arm","forearm"],"DEPS strong_elbow target_slots are upper_arm and forearm")
 t.check("follow_through" in recorded.magic_hand[false].ids,"DEPS magic_hand bound ids contain follow_through")
 var ft=recorded.magic_hand[false].ids.find("follow_through")
 t.check(Text.keywords("magic_hand",false,traits.get("magic_hand",{}))[ft].name=="超级顺延","DEPS magic_hand follow_through display name is super follow through")
 var pot=Book.card("pot_of_greed")
 t.check("exhaust" in recorded.pot_of_greed[false].ids and "exhaust" in recorded.pot_of_greed[true].ids,"DEPS pot_of_greed ids contain exhaust on both faces")
 t.check(pot.face_keywords.bound==[Text.TERMS.exhaust] and pot.face_keywords.free==[Text.TERMS.exhaust],"DEPS pot face_keywords stay TERMS.exhaust without id")
 t.check("search" in recorded.mana_search[false].ids and "search" in recorded.mana_search[true].ids,"DEPS mana_search ids contain search")
 var originals={}
 for key in ["strain","follow_through","exhaust"]:
  var term=Text.TERMS[key]
  originals[key]=term.name
  term.name="__mutated_"+key+"__"
 for type in types:
  for free in [false,true]:
   var side_traits=traits.get(type,{})
   var ids=Text.keyword_ids(type,free,side_traits)
   var slots=Rules.SPECS[type].get("target_slots",[])
   var mode=Rules.face_mode(type,free)
   t.check(ids==recorded[type][free].ids and slots==recorded[type][free].slots and mode==recorded[type][free].mode,"DEPS ids slots mode unchanged after TERMS name mutate: "+type+str(free))
 for key in originals:
  var restored=Text.TERMS[key]
  restored.name=originals[key]
 t.check(g.export_snapshot()==before and g.state.rng==rng_before,"DEPS keyword_ids reads leave snapshot and rng unchanged")

static func mana_badges(t) -> void:
 var g=Game.new(42);g.state.pressure=75
 var before=g.export_snapshot();var view=g.get_view()
 for type in g.Cards.Rules.SPECS:
  for side in ["bound","free"]:
   var cost=g.Cards.face_mana(g,type,side=="free")
   var entries=g.live_card_text(type).face_mana[side].filter(func(entry):return entry.kind=="cost")
   t.check((entries.size()==1 and entries[0].amount==cost) if cost>0 else entries.is_empty(),"MANA badge matches actual modified per-face payment: "+type+side)
 t.check(g.export_snapshot()==before,"MANA all card projections leave state and random domains unchanged")
 var spell=g.live_card_text("unlock")
 t.check(spell.face_mana.bound[0].amount==10 and Book.card("unlock").face_mana.bound[0].amount==10 and not spell.face_effects.bound.contains("耗魔"),"MANA high-pressure runtime and catalog both use base cost; body omits duplicate cost")
 t.check(spell.face_mana.free[0].kind=="temporary" and spell.face_mana.free[0].amount==10 and spell.face_effects.free=="获得2层魔力预备。","MANA free preparation becomes ten temporary points with an explicit preparation description")
 var conversion=g.live_card_text("mana_conversion")
 t.check(conversion.face_mana.bound[0].amount==20 and conversion.face_mana.free[0].kind=="gain" and conversion.face_mana.free[0].amount==10 and conversion.face_costs.free=="1","MANA fixed exchange changes cost/gain with its face without pressure scaling")
 t.check(conversion.face_mana.bound[0].text=="−20" and conversion.face_mana.free[0].text=="+10" and spell.face_mana.free[0].text=="+10","MANA signed badge numbers omit redundant decimal zero while keeping separate pools")
 t.check(g.live_card_text("mana_invocation").face_mana.bound[0].amount==20 and g.live_card_text("fire_control").face_mana.bound[0].amount==10,"MANA direct restoration and temporary points use their real effect amounts")
 t.check(g.live_card_text("adaptability").face_mana.free.is_empty() and g.live_card_text("adaptability").face_effects.free.contains("回合开始：获得1层魔力预备"),"MANA turn-start power is not advertised as immediate gain")
 t.check(g.live_card_text("embers").face_mana.bound.size()==1 and g.live_card_text("embers").face_effects.bound.contains("再耗6魔力"),"MANA optional extra spending retains its condition and is not charged in the base badge")
 t.check(g.live_card_text("strain").face_mana.bound.is_empty() and g.live_card_text("strain").face_mana.free.is_empty(),"MANA no resource interaction means no badge on either face")

static func paired_faces(t) -> void:
 var g=Game.new(42)
 for pressure in [0,75,99]:
  g.state.pressure=pressure
  var before=g.export_snapshot()
  var text_matches=true;var metadata_matches=true
  for type in g.Cards.Rules.SPECS:
   var faces=g.Cards.face_texts(g,type)
   text_matches=text_matches and faces.bound==g.Cards.face_text(g,type,false) and faces.free==g.Cards.face_text(g,type,true)
   var costs={"bound":3.125,"free":17.875}
   var combined=g.B.card_info(type,costs,12.5,false,7)
   metadata_matches=metadata_matches and combined[1]==g.B.card_info(type,costs.bound,12.5,false,7)[1] and combined[2]==g.B.card_info(type,costs.free,12.5,false,7)[2]
   combined=g.B.card_info(type,{"bound":"3.13","free":"17.88"},12.5,true,7)
   text_matches=text_matches and combined[1]==g.B.card_info(type,"3.13",12.5,true,7)[1] and combined[2]==g.B.card_info(type,"17.88",12.5,true,7)[2]
  t.check(text_matches and metadata_matches,"TERMS batch faces preserve independent costs, inline rounding, base damage and equipment quantities at pressure "+str(pressure))
  t.check(g.export_snapshot()==before,"TERMS batch card text leaves all state and random domains unchanged")
 var original=g.Cards.Rules.SPECS.mana_search.duplicate(true)
 var old_text=g.Cards.face_texts(g,"mana_search")
 g.Cards.Rules.SPECS.mana_search.self_faces.free.effects[0].amount=3
 var updated=g.Cards.face_texts(g,"mana_search")
 t.check(updated!=old_text and updated.free==g.Cards.face_text(g,"mana_search",true),"TERMS batch text observes changed rule data without a stale static catalog")
 g.Cards.Rules.SPECS.mana_search=original
 for type in ["concentration","hannya_1","hannya_2"]:
  var card=preload("res://tests/curse_cases.gd").give(g,type)
  if type=="concentration": card.damage_bonus=6
  var faces=g.Cards.face_texts(g,type,card.uid)
  t.check(faces.bound==g.Cards.face_text(g,type,false,card.uid) and faces.free==g.Cards.face_text(g,type,true,card.uid),"TERMS batch faces retain physical growth and staged drink text "+type)
