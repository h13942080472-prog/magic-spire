extends RefCounted

# First floor means the whole first act, not its first map row.
# Lists contain encounter IDs, never individual monster IDs. Registration alone does not add a draw.
static var POOLS={
 "weak":["rope_solo","belt_solo","tape_solo","cable_tie_solo","gag_solo","toybox_solo","lock_solo","small_circle_solo","mixed_bundle_solo","drone_solo"],
 "strong":["mass_weak","four_weak","mixed_pair","binding_box_solo","drone_pair","ominous_circle_pair","serpent_weak","versatile_trader"]}

static func choices(rank: String) -> Array:
 return POOLS.get(rank,[]).duplicate()

const WEAK_STRENGTH=2
const STRONG_STRENGTH=4

# Read-only admission based on equipment already worn before the encounter.
# A sampled creature cannot make another creature eligible during this draw.
static func eligible(g, member: Dictionary, strict: bool=true) -> bool:
 var spec=g.Enemies.TYPES[member.type]
 if not strict and spec.behavior not in ["lock","attachment"]: return true
 if spec.has("capture_kind"): return true
 match spec.behavior:
  "sequence","restraint":
   for plan in g.EnemyPlans.installation_intents(g,{"type":member.type}):
    var application=g.EnemyPlans.application_spec(g,{"type":member.type},plan)
    if g.Application.can_apply(g,application,"probe"): return true
   return false
  "lock": return g.physical_pieces().any(func(e):return g.Equipment.allows(e,"lock") and not e.locked)
  "attachment": return spec.attachment_pool.any(func(id):return g._installation_reason(id,spec.attachment_slot,member.grade)=="")
  "dispenser": return spec.special_pool.any(func(id):return g._special_install_reason(id,g.SpecialEquipment.DESIGNS[id].slots[0])=="")
 return false

static func candidates(g, strict: bool=true) -> Array:
 var result=[];var seen={}
 for id in choices("weak"):
  for member in g.Enemies.ENCOUNTERS[id].members:
   var key=member.type+":"+str(member.grade)
   if not seen.has(key) and eligible(g,member,strict):
    seen[key]=true;result.append(member.duplicate(true))
 return result

static func unique_type(g, type: String, unique_types: bool) -> bool:
 return unique_types or g.Enemies.TYPES[type].get("unique_in_group",false)

static func remaining_options(g, options: Array, type: String, unique_types: bool) -> Array:
 return options.filter(func(other):return other.type!=type) if unique_type(g,type,unique_types) else options

static func can_fill(g, options: Array, budget: int, unique_types: bool) -> bool:
 var reachable=[];reachable.resize(budget+1);reachable.fill(false);reachable[0]=true
 var seen={}
 for member in options:
  if seen.has(member.type): continue
  seen[member.type]=true
  var strength=int(g.Enemies.TYPES[member.type].strength)
  # Descending totals spend a unique type once; ascending totals allow repeats.
  var totals=range(budget,strength-1,-1) if unique_type(g,member.type,unique_types) else range(strength,budget+1)
  for total in totals:
   reachable[total]=reachable[total] or reachable[total-strength]
 return reachable[budget]

static func roll(g, budget: int=WEAK_STRENGTH, max_strength: int=0, unique_types: bool=false) -> Array:
 var options=candidates(g)
 if options.is_empty(): options=candidates(g,false)
 if max_strength>0: options=options.filter(func(m):return g.Enemies.TYPES[m.type].strength<=max_strength)
 if not can_fill(g,options,budget,unique_types):
  options=candidates(g,false).filter(func(m):return max_strength<=0 or g.Enemies.TYPES[m.type].strength<=max_strength)
 # Check the remaining budget before each draw, including removal of that type.
 if not can_fill(g,options,budget,unique_types): return []
 var result=[];var remaining=budget
 while remaining>0:
  var valid=options.filter(func(m):return int(g.Enemies.TYPES[m.type].strength)<=remaining and can_fill(g,remaining_options(g,options,m.type,unique_types),remaining-int(g.Enemies.TYPES[m.type].strength),unique_types))
  var member=valid[g._random_index("encounter",valid.size())].duplicate(true)
  result.append(member);remaining-=int(g.Enemies.TYPES[member.type].strength)
  options=remaining_options(g,options,member.type,unique_types)
 return result

const ELITE_ENCOUNTERS=["guard_solo","heap_family","puppeteer_solo"]
const SUMMIT_ENCOUNTERS=["six_bind_solo","iron_man_solo","rope_master_solo"]

static func summit_name(encounter: String) -> String:
 return {"six_bind_solo":"六缚","iron_man_solo":"铁男","rope_master_solo":"绳艺大师"}.get(encounter,"首领")
