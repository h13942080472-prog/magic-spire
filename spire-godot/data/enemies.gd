extends RefCounted
const RestraintValue=preload("res://data/restraint_value.gd")

const Library=preload("res://data/enemy_library.gd")
const FirstFloor=preload("res://data/first_floor_enemy_pools.gd")
const B=preload("res://data/balance.gd")
const Special=preload("res://data/special_equipment.gd")
const PUPPET_MIN_CAPACITY=1
const BARRIER_CAPACITY_DESCRIPTION="伤害严格超过屏障剩余额度时，玩偶普通反击容量上限－1，最低1，持续本场战斗；多段及群攻每次攻击只扣一次。额度耗尽后继续攻击仍可触发。"
# Strength is an independent encounter-design value, never an equipment grade or damage multiplier.
static var TYPES=definitions()

static func definitions() -> Dictionary:
 # Ordinary sources may include links; composite roots and components stay separate.
 var ordinary_initial=["rope","cord","belt","fine_belt","tape","cable_tie","eye_tape","mouth_tape"]
 var ordinary_medium=["rope","cord","belt","fine_belt","tape","cable_tie","eye_leather","eye_tape","mouth_tape","mouth_band"]
 var opening=[
  {"kind":"apply","text":"施加两件拘束具 · 初级2档／中级1档","delayed":false,"final":false,"replace":true,"count":2,"grade":1,"tier":2,"profiles":RestraintValue.profiles(3),"pool":"ordinary","templates":ordinary_initial},
  {"kind":"debuff","text":"施加无力化","delayed":false,"effect":"weakness","turns":1},
  {"kind":"apply","text":"施加一件拘束具 · 初级3档／中级2档／高级1档，随后准备就绪","delayed":false,"final":false,"replace":true,"count":1,"grade":2,"tier":2,"profiles":RestraintValue.profiles(4),"pool":"ordinary","templates":ordinary_medium,"ready_gain":1},
  {"kind":"apply","text":"优先施加中级马具口球或眼罩","delayed":false,"final":false,"replace":true,"count":1,"grade":2,"tier":2,"pool":"ordinary","templates":["mouth_band","eye_leather","eye_tape"],"preferred_slots":["mouth","eyes"],"fallback_templates":ordinary_medium.duplicate(),"variants":{"mouth_band":0}}]
 var versatile_special={"kind":"apply","text":"安装一件初级2档性玩具","delayed":false,"final":false,"replace":true,"count":1,"grade":1,"tier":2,"pool":"special","templates":Special.RANDOM_POOLS[1].duplicate()}
 var versatile_control={"kind":"versatile_control","text":"寻找可以上锁或加固的拘束具","delayed":false}
 var result={
 "reinforced_rope":{"behavior":"reinforced_rope","visual":"reinforced_rope","name":"魔力强化绳索","hp":23,"debut_act":2,"hp_rolls":6,"hit_cap":8,"order":11,"strength":1,"ordinary_max_grade":3,"install_pool":["rope","cord"]},
 "drone_operator":{"behavior":"drone_operator","humanoid":true,"visual":"drone_operator","name":"无人机操作员","hp":108,"hp_rolls":1,"debut_act":2,"order":42},
 "operator_drone":{"behavior":"operator_drone","mechanical":true,"capture_kind":"drone","capture_start":30.0,"capture_pose":"stand","include_shackles":false,"visual":"operator_drone","name":"魔导无人机","hp":20,"hp_rolls":1,"debut_act":2,"order":44,"install_pool":["tape","eye_tape","mouth_tape"],"special_pool":Special.prison_pool(1,true)+Special.prison_pool(2,true)+Special.prison_pool(3,true)},
 "succubus_detective":{"behavior":"succubus_detective","humanoid":true,"visual":"succubus_detective","name":"魅魔侦探","hp":86,"hp_rolls":1,"debut_act":2,"order":49,"capture_kind":"succubus_detective","capture_start":40.0,"include_shackles":false,"install_pool":["cable_tie","handcuffs","ankle_cuffs"],"special_pool":Special.prison_pool(1,true)+Special.prison_pool(2,true)+Special.prison_pool(3,true)},
 "tape_mass":{"behavior":"tape_mass","visual":"tape_mass","name":"胶带团","hp":76,"hp_rolls":1,"debut_act":2,"order":31,"install_pool":["tape","eye_tape","mouth_tape"]},
 "anti_mage_drone":{"behavior":"anti_mage_drone","mechanical":true,"capture_kind":"anti_mage_drone","capture_start":40.0,"include_shackles":false,"visual":"anti_mage_drone","name":"对法师特化无人机Ⅱ型","hp":70,"hp_rolls":1,"debut_act":2,"order":44,"install_pool":["belt","fine_belt","eye_leather","mouth_band"]},
 "binding_box_plus":{"behavior":"binding_box_plus","mechanical":true,"can_arrest":false,"include_shackles":false,"visual":"binding_box_plus","name":"拘束盒 Plus","hp":86,"hp_rolls":1,"debut_act":2,"order":43,"strength":2,"ordinary_max_grade":3,"install_pool":["belt","fine_belt","tape","cable_tie","mouth_tape","mouth_band"],"special_pool":Special.RANDOM_POOLS[1].duplicate()},
 "mana_smuggler":{"behavior":"mana_smuggler","humanoid":true,"include_shackles":false,"visual":"mana_smuggler","name":"魔力走私者","hp":55,"previous_base_hp":[45.0],"hp_rolls":1,"debut_act":2,"order":45,"strength":1,"ordinary_max_grade":3,"install_pool":["belt","fine_belt","rope","cord","cable_tie","tape"]},
 "mini_restraint_mech":{"behavior":"restraint_mechs","mechanical":true,"can_arrest":false,"include_shackles":false,"visual":"mini_restraint_mech","name":"微型拘束机甲","hp":32,"hp_rolls":1,"debut_act":2,"order":46,"strength":1,"ordinary_max_grade":3,"install_pool":["belt","fine_belt","eye_leather","mouth_band"]},
 "support_restraint_mech":{"behavior":"restraint_mechs","mechanical":true,"include_shackles":false,"visual":"support_restraint_mech","name":"辅助拘束机甲","hp":30,"hp_rolls":1,"debut_act":2,"order":47,"strength":1,"capture_kind":"support_restraint_mech","capture_start":40.0,"special_max_grade":2,"special_pool":Special.RANDOM_POOLS[2].duplicate()},
 "rope_master":{"behavior":"rope_master","humanoid":true,"visual":"rope_master","name":"绳艺大师","hp":140,"strength":6,"order":62,"capture_kind":"rope_master","capture_start":0.0,"install_pool":["rope","cord"]},
 "rope_assistant":{"behavior":"rope_assistant","humanoid":true,"can_arrest":false,"visual":"rope_assistant","name":"绳艺助手","hp":36,"order":61,"install_pool":["rope","cord"]},
 "iron_man":{"behavior":"iron_man","humanoid":true,"mechanical":true,"visual":"iron_man","name":"铁男","hp":140,"strength":6,"order":40,"capture_kind":"iron_man","capture_start":30.0,"capture_poses":["sit","lie"],"install_pool":["belt","fine_belt","eye_leather","mouth_band"]},
 "iron_drone":{"behavior":"iron_drone","mechanical":true,"can_arrest":false,"capture_kind":"iron_drone","capture_start":20.0,"visual":"drone","name":"捕缚无人机","hp":40,"order":44},
 "puppeteer":{"behavior":"puppeteer","humanoid":true,"visual":"puppeteer","name":"玩偶师","hp":96,"order":51,"damage_cap":30.0,"special_pool":Special.RANDOM_POOLS[2].duplicate()},
 "puppet":{"behavior":"puppet","humanoid":true,"visual":"puppet","name":"玩偶","hp":15,"order":52,"reaction_capacity":3,"capacity_per_mend":1,"health_per_mend":5,"install_pool":ordinary_medium.duplicate()},
 "six_bind":{"behavior":"six_bind","humanoid":true,"visual":"six_bind","name":"六缚","hp":200,"strength":6,"order":60,"climax_capture_threshold":4,"climax_capture_repeat":1,
  "install_pool":ordinary_medium.duplicate(),"opening_pool":ordinary_initial+['mouth_band'],"special_pools":{1:Special.RANDOM_POOLS[1].duplicate(),2:Special.RANDOM_POOLS[2].duplicate()}},
 "versatile":{"behavior":"humanoid","humanoid":true,"visual":"versatile","name":"多面手","hp":60,"strength":2,"order":49,
  "special_pool":Special.RANDOM_POOLS[1].duplicate(),"install_pool":ordinary_medium.duplicate(),
  "opening":[{"kind":"idle","text":"发呆","delayed":false},versatile_special.duplicate(true),versatile_control.duplicate(true)],
  "repeat_cycle":[versatile_special.duplicate(true),versatile_control.duplicate(true)]},
 "mixed_bundle":{"behavior":"restraint","visual":"mixed_bundle","name":"一团分不清的拘束具","hp":56,"strength":2,"order":28,
  "install_pool":ordinary_initial+["mouth_band"],"final_pool":ordinary_initial+["mouth_band"],"install_grade":1,"restraint_name":"混合拘束具","quantity_gain":1,
  "weighted_moves":{
   "scatter":{"weight":25,"limit":1,"plan":{"kind":"apply","text":"散缚","delayed":false,"pool":"ordinary","templates":ordinary_initial+["mouth_band"],"grade":1,"tier":2,"profiles":RestraintValue.profiles(3),"count":2,"replace":false}},
   "roll":{"weight":30,"limit":2,"plan":{"kind":"apply","text":"翻卷收紧","delayed":false,"pool":"ordinary","templates":ordinary_initial+["mouth_band"],"grade":1,"tier":2,"profiles":RestraintValue.profiles(3),"count":1,"replace":false,"tighten_after":true}},
   "swell":{"weight":45,"limit":1,"plan":{"kind":"charge","text":"躁动膨胀","delayed":false,"quantity_gain":1}}}},
 "rope_serpent":{"behavior":"restraint","visual":"rope_serpent","name":"游动的绳蛇","hp":60,"strength":3,"order":27,
  "install_pool":["rope","cord"],"final_pool":["rope","cord"],"restraint_name":"绳索","install_grade":1,"install_count":2,
  "cycle":["turn_install","random_strike"],"turn_install_effect":{"name":"紧缠","timing":"turn_end","stack":true}},
 "ominous_circle":{"behavior":"sequence","visual":"ominous_circle","name":"看着不妙的魔法阵","hp":40,"strength":2,"order":47,
  "ritual_gain":3,"opening":[{"kind":"charge","ritual_gain":3,"text":"启动仪式","delayed":false}],
  "repeat_cycle":[{"kind":"apply","text":"施加拘束具，无处添加时加固","delayed":false,"pool":"ordinary","templates":ordinary_medium.duplicate(),"grade":1,"tier":2,"count":1,"replace":false,"tighten_missing":true,"profiles":RestraintValue.profiles(3)}]},
 "trader":{"behavior":"humanoid","humanoid":true,"visual":"trader","name":"奴隶贩子","full_name":"被魔法控制的奴隶贩子","hp":56,"strength":2,"order":48,
  "opening":opening,"repeat_cycle":[opening[0].duplicate(true),opening[2].duplicate(true),opening[3].duplicate(true)],"repeat_count":2},
 "rope_heap":{"install_pool":["rope","cord"],"final_pool":["rope","cord"],"behavior":"restraint","visual":"rope_heap","name":"一堆绳","hp":96,"order":26,
  "install_grade":2,"cycle":["turn_install","prepare","install_pair","tighten_pair","prepare_burst","split_burst"],"turn_install_effect":{"name":"绳索增生","timing":"turn_start","stack":false},
  "split_threshold":0.5,"split_spawns":[{"type":"rope_mass","grade":2,"hp_ratio":1.0},{"type":"rope","grade":1,"hp_ratio":0.5},{"type":"rope","grade":1,"hp_ratio":0.5}]},
 "rope_mass":{"install_pool":["rope","cord"],"final_pool":["rope","cord"],"behavior":"restraint","visual":"rope_mass","name":"一团绳","hp":48,"strength":3,"order":25,
  "install_grade":2,"cycle":["prepare_install","install_prepared","tighten"],"defeat_spawns":[{"type":"rope","grade":1},{"type":"rope","grade":1}]},
 "binding_box":{"behavior":"binding_box","mechanical":true,"capture_kind":"binding_box","capture_start":40.0,"capture_pose":"sit","capture_turn_install":true,
  "visual":"binding_box","name":"魔导拘束盒","hp":64,"strength":4,"order":43,
  "install_pool":["belt","fine_belt","eye_leather","mouth_band"],"capture_pool":["belt","fine_belt","eye_leather"],"reinforce_material":"leather",
  "carried_composites":[{"family":"leg","variant":"upper","straps":"straight"},{"family":"leg","variant":"lower","straps":"straight"},{"family":"glove","variant":"short","straps":"straight"}]},
 "drone":{"behavior":"drone","mechanical":true,"capture_kind":"drone","capture_start":30.0,"capture_pose":"stand","visual":"drone","name":"魔导无人机","hp":32,"strength":2,"order":44,"install_pool":["tape","eye_tape","mouth_tape"]},
 "guard":{"capture_kind":"guard","capture_start":50.0,"behavior":"guard","humanoid":true,"visual":"guard","visual_pool":["guard_purple","guard_brown"],"name":"魅魔警卫","hp":B.GUARD_HP,"order":50},
 "rope":{"install_pool":["rope","cord"],"final_pool":["rope","cord"],"behavior":"restraint","visual":"rope","name":"漂浮绳索","hp":B.ROPE_HP,"strength":1,"order":10},
 "belt":{"install_pool":["belt","fine_belt","eye_leather"],"final_pool":["belt","fine_belt","eye_leather"],"behavior":"restraint","visual":"belt","name":"漂浮皮带","hp":B.BELT_HP,"strength":1,"order":20},
 "tape":{"install_pool":["tape","eye_tape","mouth_tape"],"final_pool":["tape","eye_tape","mouth_tape"],"behavior":"restraint","visual":"tape","name":"漂浮胶带","hp":30,"strength":1,"order":30},
 "cable_tie":{"install_pool":["cable_tie"],"final_pool":["cable_tie"],"behavior":"restraint","visual":"cable_tie","name":"漂浮扎带","hp":30,"strength":1,"order":35},
 "gag":{"unique_in_group":true,"attachment_pool":["mouth_band"],"attachment_slot":"mouth","behavior":"attachment","visual":"silencer","name":"漂浮口球","hp":B.SILENCER_HP,"strength":1,"order":40},
 "lock":{"unique_in_group":true,"behavior":"lock","visual":"lock","name":"漂浮锁","hp":B.LOCK_HP,"strength":1,"order":36,
  "chastity_departure":{"kind":"apply","pool":"special","templates":["negative_plate_lock_medium"],"grade":B.ENEMY_DEPARTURE_GRADE,"tier":B.ENEMY_DEPARTURE_TIER,"count":1,"locked":false,"final":true,"replace":false,"text":"附加中级3档平板锁，随后离场","delayed":false}},
 "toybox":{"behavior":"dispenser","visual":"toybox","name":"漂浮玩具箱","hp":30,"strength":1,"order":45,
  "special_pool":Special.RANDOM_POOLS[1].duplicate()}}
 for type in ["rope","belt","tape","cable_tie"]:
  result[type].install_restraint_value=3
  result[type].departure_restraint_value=5
 # Material variants inherit the complete cycle and split rules; only their pool,
 # appearance and descendants differ. No second implementation of the behavior.
 for size in ["mass","heap"]:
  result["rope_"+size].restraint_name="绳索"
  result["rope_"+size].family="mass_family" if size=="mass" else "heap_family"
  var skin=result["rope_"+size].duplicate(true)
  skin.name="一团皮带" if size=="mass" else "一堆皮带"
  skin.visual="belt_"+size;skin.restraint_name="皮带"
  if skin.has("turn_install_effect"): skin.turn_install_effect.name="皮带增生"
  skin.install_pool=result.belt.install_pool.duplicate()
  skin.final_pool=result.belt.final_pool.duplicate()
  var spawn_key="defeat_spawns" if size=="mass" else "split_spawns"
  for member in skin[spawn_key]: member.type="belt_mass" if member.type=="rope_mass" else "belt"
  result["belt_"+size]=skin
 var small_circle=result.ominous_circle.duplicate(true)
 small_circle.name="小型魔法阵";small_circle.hp=30;small_circle.strength=1;small_circle.order=46
 result.small_circle=small_circle
 return result

static var ENCOUNTERS={
 "rope_master_solo":{"group":"绳艺大师","rank":"boss","members":[{"type":"rope_master","grade":3}]},
 "iron_man_solo":{"group":"铁男","rank":"boss","members":[{"type":"iron_man","grade":3},{"type":"binding_box","grade":2,"hp":40,"name":"凑数型拘束盒","capture_start":20.0,"capture_gain":5.0,"application_tier":1,"reinforce_budget":2},{"type":"iron_drone","grade":2,"name":"凑数型无人机"}]},
 "puppeteer_solo":{"group":"玩偶师","rank":"elite","members":[{"type":"puppeteer","grade":2}]},
 "event_belt_trio":{"group":"漂浮皮带群","rank":"event","members":[{"type":"belt","grade":1},{"type":"belt","grade":1},{"type":"belt","grade":1}]},
 "drone_pair":{"group":"双魔导无人机","rank":"strong","members":[],"fixed_members":[{"type":"drone","grade":1},{"type":"drone","grade":1}],"weak_strength":0},
 "ominous_circle_pair":{"group":"双不妙魔法阵","rank":"strong","members":[],"fixed_members":[{"type":"ominous_circle","grade":2},{"type":"ominous_circle","grade":2}],"weak_strength":0},
 "serpent_weak":{"group":"绳蛇＋弱怪","rank":"strong","members":[],"fixed_members":[{"type":"rope_serpent","grade":2}],"weak_strength":1,"max_weak_strength":1},
 "versatile_trader":{"group":"多面手与奴隶贩子","rank":"strong","members":[],"fixed_members":[{"type":"versatile","grade":2},{"type":"trader","grade":2}],"weak_strength":0},
 "six_bind_solo":{"group":"六缚","rank":"boss","members":[{"type":"six_bind","grade":3}]},
 "binding_box_solo":{"group":"魔导拘束盒","rank":"strong","members":[],"fixed_members":[{"type":"binding_box","grade":2}],"weak_strength":0},
 "drone_solo":{"group":"弱怪","rank":"weak","members":[{"type":"drone","grade":1}]},
 "mixed_bundle_solo":{"group":"弱怪","rank":"weak","members":[{"type":"mixed_bundle","grade":1}]},
 "mixed_pair":{"group":"两团杂乱拘束具","rank":"strong","members":[],"fixed_members":[{"type":"mixed_bundle","grade":1},{"type":"mixed_bundle","grade":1}],"weak_strength":0},
 "rope_serpent_solo":{"group":"强怪练习","rank":"strong","members":[{"type":"rope_serpent","grade":2}]},
 "small_circle_solo":{"group":"弱怪","rank":"weak","members":[{"type":"small_circle","grade":1}]},
 "ominous_circle_solo":{"group":"强怪练习","rank":"strong","members":[{"type":"ominous_circle","grade":2}]},
 "trader_solo":{"group":"强怪练习","rank":"strong","members":[{"type":"trader","grade":2}]},
 "versatile_solo":{"group":"强怪练习","rank":"strong","members":[{"type":"versatile","grade":2}]},
 "mass_weak":{"group":"一团＋弱怪","rank":"strong","members":[],"family":"mass_family","weak_strength":1},
 "four_weak":{"group":"四只弱怪","rank":"strong","members":[],"weak_strength":FirstFloor.STRONG_STRENGTH,"max_weak_strength":1,"unique_weak_types":true},
 "mass_family":{"group":"一团X","rank":"strong","members":[],"variants":["rope_mass_solo","belt_mass_solo"]},
 "heap_family":{"group":"一堆X","rank":"elite","members":[],"variants":["rope_heap_solo","belt_heap_solo"]},
 "belt_mass_solo":{"group":"强怪练习","rank":"strong","members":[{"type":"belt_mass","grade":2}]},
 "belt_heap_solo":{"group":"精英","rank":"elite","members":[{"type":"belt_heap","grade":2}]},
 "rope_heap_solo":{"group":"精英","rank":"elite","members":[{"type":"rope_heap","grade":2}]},
 "rope_mass_solo":{"group":"强怪练习","rank":"strong","members":[{"type":"rope_mass","grade":2}]},
 "reinforced_rope_trio":{"group":"魔力强化绳索×3","rank":"weak","members":[{"type":"reinforced_rope","grade":1},{"type":"reinforced_rope","grade":1},{"type":"reinforced_rope","grade":1}]},
 "reinforced_rope_quartet":{"group":"魔力强化绳索×4","rank":"strong","members":[{"type":"reinforced_rope","grade":1},{"type":"reinforced_rope","grade":1},{"type":"reinforced_rope","grade":1},{"type":"reinforced_rope","grade":1}]},
 "drone_operator_solo":{"group":"无人机操作员","rank":"strong","members":[{"type":"drone_operator","grade":2}]},
 "succubus_detective_solo":{"group":"魅魔侦探","rank":"strong","members":[{"type":"succubus_detective","grade":2}]},
 "tape_mass_solo":{"group":"胶带团","rank":"strong","members":[{"type":"tape_mass","grade":2}]},
 "anti_mage_drone_solo":{"group":"对法师特化无人机Ⅱ型","rank":"strong","members":[{"type":"anti_mage_drone","grade":2}]},
 "binding_box_plus_circle":{"group":"拘束盒 Plus 与不妙法阵","rank":"strong","members":[{"type":"binding_box_plus","grade":2},{"type":"ominous_circle","grade":2}]},
 "binding_box_plus_solo":{"group":"拘束盒 Plus","rank":"weak","members":[{"type":"binding_box_plus","grade":2}]},
 "mana_smuggler_pair":{"group":"魔力走私者×2","rank":"weak","members":[{"type":"mana_smuggler","grade":1,"thefts":3},{"type":"mana_smuggler","grade":1,"thefts":4}]},
 "restraint_mech_pair":{"group":"双拘束机甲","rank":"weak","members":[{"type":"mini_restraint_mech","grade":1},{"type":"support_restraint_mech","grade":2}]},
 "weak_group":{"group":"弱怪组合","rank":"weak","members":[],"weak_strength":FirstFloor.WEAK_STRENGTH},
 "guard_solo":{"group":"精英","rank":"elite","members":[{"type":"guard","grade":2}]},
 "double_guard":{"group":"双魅魔警卫","rank":"elite","members":[{"type":"guard","grade":2},{"type":"guard","grade":2}]},
 "pressure_drill":{"group":"快感练习","rank":"practice","members":[{"type":"rope","grade":1,"pressure":65.0},{"type":"rope","grade":1,"pressure":65.0}]},
 "rope_solo":{"group":"弱怪","rank":"weak","members":Library.members(["rope_basic"])},
 "belt_solo":{"group":"弱怪","rank":"weak","members":Library.members(["belt_basic"])},
 "tape_solo":{"group":"弱怪","rank":"weak","members":Library.members(["tape_basic"])},
 "cable_tie_solo":{"group":"弱怪","rank":"weak","members":Library.members(["cable_tie_basic"])},
 "gag_solo":{"group":"弱怪","rank":"weak","members":Library.members(["gag_basic"])},
 "toybox_solo":{"group":"弱怪","rank":"weak","members":Library.members(["toybox_basic"])},
 "lock_solo":{"group":"弱怪","rank":"weak","members":Library.members(["lock_basic"])},
 # Explicit combination fixtures are not added to the random pools.
 "belt_tie":{"group":"组合练习","rank":"strong","members":Library.members(["belt_basic","cable_tie_basic"])},
 "belt_gag":{"group":"组合练习","rank":"strong","members":Library.members(["belt_basic","gag_basic"])},
 "rope_tape":{"group":"组合练习","rank":"strong","members":Library.members(["rope_basic","tape_basic"])},
 "double_rope":{"group":"组合练习","rank":"strong","members":Library.members(["rope_basic","rope_basic"])}}
static func encounter_member(state: Dictionary, type: String) -> Dictionary:
 var encounter=ENCOUNTERS.get(state.room_encounters.get(state.room,""),{})
 for member in encounter.get("members",[]):
  if member.type==type: return member
 return {}

static func description(id: String) -> String:
 if id=="weak_group": return "弱怪组合"
 var encounter=ENCOUNTERS[id]
 if encounter.has("weak_strength"): return encounter.group
 if encounter.has("variants"):
  var variants=encounter.variants.map(func(v):return TYPES[ENCOUNTERS[v].members[0].type].name)
  return encounter.group+" · "+"／".join(variants)+"（进入时确定）"
 var names: Array[String]=[]
 for member in encounter.members:
  names.append(TYPES[member.type].name+("（中级装备）" if behavior(member.type)=="attachment" and member.grade==2 else ""))
 return encounter.group+" · "+"＋".join(names)

# New templates reuse one behavior and one visual; encounters still refer to template ids.
static func behavior(type: String) -> String:
 return TYPES.get(type,{}).get("behavior","")

static func damage_multiplier(g, type: String, damage_type: String) -> float:
 if damage_type in ["fixed","magic"] or not TYPES[type].get("mechanical",false): return 1.0
 if g.IronMan.armor_disabled(g,type): return 1.0
 var reduction=50.0
 for id in g.state.relics:
  var override=g.RelicEffects.definition(g,id).modifiers.get("mechanical_damage_reduction_percent",-1)
  if override>=0: reduction=minf(reduction,override)
 return 1.0-reduction/100.0

static func cap_hit(enemy: Dictionary, damage: float) -> float:
 return minf(damage,TYPES[enemy.type].get("hit_cap",INF))

static func barrier_limit(enemy: Dictionary, health_scale: float) -> float:
 return TYPES[enemy.type].get("damage_cap",INF)*health_scale

static func barrier_remaining(enemy: Dictionary, health_scale: float) -> float:
 return maxf(0.0,barrier_limit(enemy,health_scale)-enemy.barrier_damage)
