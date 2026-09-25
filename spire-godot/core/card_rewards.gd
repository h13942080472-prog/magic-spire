extends RefCounted
const Rules=preload("res://data/card_rules.gd")

static func eligible(g, type: String) -> bool:
 if not g.Character.allowed_card(g,type): return false
 var spec=Rules.SPECS[type]
 var required=Rules.REWARD_POOL_RELICS.get(spec.get("reward_pool",""),"")
 if required!="" and required not in g.state.relics: return false
 if spec.card_type!="power" or not Rules.unique_face(type,false) or not Rules.unique_face(type,true): return true
 return not g.state.deck.any(func(card):return card.type==type)

# Roll each displayed slot in order. Negative rare probability also reduces
# the uncommon band; clamping the first threshold would change the distribution.
static func rarity(source: String, offset: int, roll: int) -> String:
 if source=="boss": return "rare"
 var rate=Rules.REWARD_RATES[source]
 if roll<rate.rare+offset: return "rare"
 if roll<rate.rare+offset+rate.uncommon: return "uncommon"
 return "common"

static func next_offset(offset: int, tier: String) -> int:
 if tier=="rare": return Rules.RARE_OFFSET_INITIAL
 return mini(Rules.RARE_OFFSET_MAX,offset+1) if tier=="common" else offset

static func offer(g, pool: Array, source: String, rng=null, count: int=3) -> Array:
 var available=pool.filter(func(type):return eligible(g,type))
 var chosen=[]
 while not available.is_empty() and chosen.size()<count:
  var tier=""
  if source!="fixed":
   var roll=g._random_index("reward",100) if rng==null else rng.randi_range(0,99)
   tier=rarity(source,g.state.rare_offset,roll)
  var tier_pool=available if tier=="" else available.filter(func(id):return Rules.SPECS[id].rarity==tier)
  if tier_pool.is_empty() and g.Character.active(g): tier_pool=available
  # Formal weighted pools contain at least three cards of every tier.
  assert(not tier_pool.is_empty(),"Reward pool lacks the selected rarity")
  if tier_pool.is_empty(): return []
  var index=g._random_index("reward",tier_pool.size()) if rng==null else rng.randi_range(0,tier_pool.size()-1)
  var type=tier_pool[index]
  chosen.append(type);available.erase(type)
  if source!="fixed": g.state.rare_offset=next_offset(g.state.rare_offset,tier)
 return chosen
