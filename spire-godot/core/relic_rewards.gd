extends RefCounted

# StS1 relic distributions. Card rarity offsets never participate.
const RATES={"normal":[50,33,17],"shop":[50,33,17],"small":[75,25,0],"medium":[35,50,15],"large":[0,75,25]}
const TIERS=["common","uncommon","rare"]
const CHESTS={"small":"小宝箱","medium":"中宝箱","large":"大宝箱"}

static func rarity(source: String, roll: int) -> String:
 var rates=RATES[source]
 return TIERS[0] if roll<rates[0] else (TIERS[1] if roll<rates[0]+rates[1] else TIERS[2])

static func random(g, size: int, rng=null) -> int:
 return g._random_index("relic",size) if rng==null else rng.randi_range(0,size-1)

static func chest(g, rng=null) -> String:
 var roll=random(g,100,rng)
 return "small" if roll<50 else ("medium" if roll<83 else "large")

static func available(g, source: String="normal") -> Array:
 var pool=g.Relics.BOSS_POOL if source=="boss" else (g.Relics.shop_pool() if source=="shop" else g.Relics.REWARDS)
 return pool.filter(func(id):
  if id in g.state.relics: return false
  if source=="boss": return g.RelicEffects.gain_reason(g,id)==""
  return g.Relics.TYPES[id].get("required_relic","") in [""]+g.state.relics and g.Character.relic_allowed(g,id) and (not g.Character.active(g) or g.RelicEffects.gain_reason(g,id)==""))

static func offer(g, source: String="normal", rng=null, excluded: Array=[], required_relic: String="") -> String:
 var pool=available(g,source).filter(func(id):return id not in excluded and (required_relic=="" or g.Relics.TYPES[id].get("required_relic","")==required_relic))
 var tier=source if source in TIERS or source=="boss" else ("" if required_relic!="" else rarity("normal" if source=="elite_bonus" else source,random(g,100,rng)))
 var choices=pool.filter(func(id):return tier=="" or g.Relics.TYPES[id].rarity==tier)
 var fallback=g.Relics.COMMON_FALLBACK if tier=="common" else g.Relics.FALLBACK
 if source=="elite_bonus" and fallback in excluded:
  fallback=g.Relics.FALLBACK if fallback==g.Relics.COMMON_FALLBACK else g.Relics.COMMON_FALLBACK
 var id=fallback if choices.is_empty() else choices[random(g,choices.size(),rng)]
 # Keep offer history for frozen reward validation, not eligibility.
 if id not in g.state.relic_seen: g.state.relic_seen.append(id)
 return id

const DROP_FIELDS={"relic":"battle_relic_drop","bonus_relic":"bonus_relic_drop"}

static func battle_drop(g) -> void:
 g.state.bonus_relic_drop=""
 g.state.battle_relic_drop=""
 g.state.boss_relic_options=[]
 var room=g.room_data(g.state.room)
 if room.get("boss",false):
  var pool=available(g,"boss")
  for i in range(mini(3,pool.size())):
   var id=pool[random(g,pool.size())]
   pool.erase(id)
   g.state.boss_relic_options.append(id)
   if id not in g.state.relic_seen: g.state.relic_seen.append(id)
  if g.state.boss_relic_options.is_empty():
   g.state.boss_relic_options=[g.Relics.FALLBACK]
   if g.Relics.FALLBACK not in g.state.relic_seen: g.state.relic_seen.append(g.Relics.FALLBACK)
  return
 var encounter=g.Enemies.ENCOUNTERS.get(g.state.room_encounters.get(g.state.room,""),{})
 if encounter.get("rank","")!="elite": return
 g.state.battle_relic_drop=offer(g)
 if g.relic_value("elite_extra_relic")>0: g.state.bonus_relic_drop=offer(g,"elite_bonus",null,[g.state.battle_relic_drop])
