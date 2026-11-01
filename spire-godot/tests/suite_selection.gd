extends RefCounted

# Scheduling labels never suppress explicitly selected tests.
const ACTIVE=["witch_character","card_power","card_expansion","relics","rewards","basic_attacks","casting","keyboard"]
const DEFERRED=["persistence","home_persistence"]
const LONG_RUNS=["normal_play","baseline"]

static func stage(name: String) -> String:
 if name in DEFERRED: return "deferred: saves after demo"
 if name in LONG_RUNS: return "milestone: explicit long run"
 if name in ACTIVE: return "active: current feature work"
 return "stable: run when changed"

# Named suites run directly. Explicit impact mode expands ONCE from the request,
# never from suites added as coverage; helper imports are not test prerequisites.
const CROSS_AREAS={
 "rope_master":["core","enemies","equipment","links","replacement","application","casting","card_power","pressure","persistence","basic_attacks","status"],
 "enchantments":["core","rewards","services","casting","card_power","card_expansion","card_splash","persistence","status","relics","prison","content"],
 "witch_character":["core","basic_attacks","casting","card_power","card_expansion","equipment","special_equipment","application","pressure","status","enemies","relics","services","prison","rewards","content","persistence"],
 "localization":["content"],
 "card_power":["enchantments","rewards","casting","core","equipment","composites","links","status","pressure","persistence","content","special_equipment","slip_motion","services","prison","enemies"],
 "card_expansion":["enchantments","rewards","casting","core","equipment","enemies","basic_attacks","status","pressure","persistence","content","special_equipment","slip_motion","services","prison"],
 "relics":["enchantments","rewards","core","equipment","casting","pressure","services","tower","prison","status","persistence","content","special_equipment","slip_motion","enemies"],"card_splash":["enchantments","core","equipment","composites","links","casting","rewards","relics","card_power","card_growth","witch_character"],"card_growth":["core","casting","equipment","rewards","content","persistence"],"item_discard":["installed_tools","services","prison","rewards","pressure","events"],"consumables":["core","equipment","rewards","casting","persistence","enemies","guard","services","installed_tools","special_equipment","content","status","slip_motion"],"basic_attacks":["core","enemies","equipment","casting","card_power","card_expansion","relics","witch_character","persistence"],"battle_saturation":["core","enemies","application","equipment","rewards","guard","replacement","persistence","intent"],"replacement":["equipment","composites","links","special_equipment","enemies","guard","events","persistence"],"application":["equipment","composites","enemies","events","guard","prison","persistence"],"architecture":["enchantments","services","card_growth","core","equipment","composites","links","prison","events","content","rewards","casting","tower","persistence","card_power","card_expansion","relics"],"installation_priority":["equipment","composites","links","application","replacement","core","enemies","guard","events","content","persistence"],"encyclopedia":["content","equipment","special_equipment","enemies","rewards","installed_tools","consumables"],"shop_release":["services","equipment","composites","links","persistence"],"content":["enchantments","equipment","special_equipment","events","enemies","rewards","persistence","tower"],"installed_tools":["equipment","composites","wall","environment_height","persistence","rewards","special_equipment"],"environment_height":["contact","wall","prison","persistence","special_equipment"],"exploration":["prison","wall","pressure","persistence","equipment","casting"],"shoulder":["contact","equipment","composites","links","enemies","guard","events","prison","persistence","status","slip_motion"],"slip_motion":["equipment","composites","links","casting","wall","prison","tower","persistence"],"torso_binding":["contact","equipment","composites","enemies","guard","events","persistence"],
 "pressure":["core","status","persistence","card_power","card_expansion","relics","special_equipment"],
 "event_flow":["events","content","persistence","equipment","special_equipment","pressure","rewards"],
 "events":["tower","persistence"],
 "curses":["rewards","pressure","events","status","persistence","casting","special_equipment"],
 "core":["contact","casting"],
 "enemies":["persistence","rewards","status","tower","guard","basic_attacks","witch_character","card_power","relics"],
 "iron_man":["core","guard","enemies","persistence","rewards","status","tower","application","replacement","special_equipment","pressure"],
 "trader":["enemies","application","replacement","guard","casting","status","persistence","content"],
 "hand_assist":["contact","equipment","links","composites"],
 "equipment":["contact"],
 "links":["contact","equipment","special_equipment","guard","persistence"],
 "composites":["contact","equipment","links"],
 "equipment_complete":["contact","equipment","links","composites"],
 "casting":["enchantments","pressure","core","services","consumables","persistence","status"],
 "prison":["enchantments","contact","casting","guard","wall","application","replacement","persistence","tower","rewards","enemies","status","content"],
 "status":["enchantments","hand_assist","casting","wall","pressure","special_equipment","rewards","enemies","intent","basic_attacks","equipment","guard","prison","core","card_power","card_expansion","relics"],
 "rewards":["enchantments","content","pressure","casting","special_equipment","persistence","status","equipment","slip_motion","services","prison","core","enemies","card_power","card_expansion","relics"],
 "special_equipment":["casting","pressure","equipment","hand_assist","wall","persistence"],
 "tower_progression":["tower","prison","rewards","enemies","persistence"],
 "services":["enchantments","tower","rewards","content","pressure"],
 "wall":["rewards"],
 "intent":["guard","enemies"],
 "action_copy":["hand_assist","guard","enemies","events","casting","equipment","slip_motion","rewards","core"]
}

# Daily seeds exercise repeatability and known branches. Exhaustive mode preserves
# every previously used seed; directed boundary/rollback cases are never sampled.
const SEED_SETS={
 "enemy_cycle":{"count":16,"daily":[0,1,7,15]}, # material, fallback grade, weighted-control and upper seed branches
 "enemy_pool":{"count":24,"daily":[0,1,7,23]},
 "tower_graph":{"count":200,"extra":[20260906],"daily":[0,1,2,7,42,199,20260906]}
}

static func seeds(id: String, exhaustive: bool) -> Array:
 var spec=SEED_SETS[id]
 return range(spec.count)+spec.get("extra",[]) if exhaustive else spec.daily.duplicate()

static func resolve(suites: Array, requested: Array, impact: bool=false) -> Dictionary:
 var known=suites+["all"]+(["contact"] if impact else [])
 if requested.is_empty() or requested.any(func(name):return name not in known):
  return {"ok":false,"selected":[],"error":"Unknown or empty rule suite"}
 var selected=[]
 var reasons={}
 for name in suites:
  var matches=CROSS_AREAS.get(name,[]).filter(func(area):return area in requested)
  if "all" in requested or name in requested or (impact and not matches.is_empty()):
   selected.append(name)
   reasons[name]="all" if "all" in requested else ("requested" if name in requested else "cross: "+",".join(matches))
 return {"ok":true,"selected":selected,"reasons":reasons,"error":""}
