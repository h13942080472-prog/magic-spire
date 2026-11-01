extends RefCounted
const TYPES={
 "strike":[{"name":"肘击","cost":1,"damage":8.0,"hits":1},{"name":"肘击 · 连击","cost":1,"damage":4.0,"hits":2}],
 "heavy":[{"name":"近身短打","cost":2,"damage":18.0,"hits":1},{"name":"近身短打 · 连击","cost":2,"damage":6.0,"hits":3}],
 "kick":[{"name":"正义飞踢","cost":2,"bound_cost":1,"seated_cost":1,"hits":1,"cooldown_turns":2},{"name":"横扫","cost":1,"damage":5.0,"hits":1,"all":true},{"name":"站着踢","cost":1,"hits":1,"postures":{"stand":{"name":"站着踢","damage":8.0,"max_level":0},"sit":{"name":"坐着踢","damage":6.0,"max_level":3}}},{"name":"连续踢！","cost":0,"x_cost":true,"hits":1,"fall_energy":3,"kick_posture":"sit","postures":{"sit":{"name":"连续踢！","damage":3.0,"max_level":3}}}],
 "fireball":[{"name":"火球术","cost":0,"first_use_cost":1,"hits":1,"uses_per_turn":2}]}

static func energy_cost(g, type: String, form: int=0) -> int:
 var spec=forms(g,type)[form]
 if spec.get("x_cost",false): return maxi(0,g.state.energy)
 return int(spec.first_use_cost) if spec.has("first_use_cost") and not g.state.combat.attack_started.has(type) else int(spec.cost)

static func posture(g, type: String, spec: Dictionary={}) -> String:
 if g.Cards.basic_attack_freedom(g): return spec.get("kick_posture","stand")
 var fixed=g.CaptureBind.fixed_posture(g)
 if fixed!="": return fixed
 for id in g.Cards.active_buffs(g):
  var buff=g.Cards.Rules.BUFFS[id]
  if buff.get("ignore_posture",false) and g.Cards.matches_attack(buff,type): return spec.get("kick_posture","stand")
 return g.state.posture

static func forms(g, type: String) -> Array:
 var result=TYPES[type].duplicate(true)
 for spec in result:
  if spec.get("x_cost",false): spec.hits=maxi(0,g.state.energy)+1
 if type!="kick" or not g.Cards.basic_attack_freedom(g): return result
 # All forms derive from the original kick definitions; indices are stable for UI cycling.
 for variant in [{"base":0,"posture":"stand","bound":true},{"base":0,"posture":"sit","bound":true},{"base":0,"posture":"sit","bound":false},{"base":2,"posture":"sit","bound":false}]:
  var spec=TYPES.kick[variant.base].duplicate(true)
  spec.kick_posture=variant.posture;spec.kick_bound=variant.bound
  result.append(spec)
 return result

static func cost_description(type: String) -> String:
 var spec=TYPES[type][0]
 return ("每回合首发%d能量，之后%d能量。" % [spec.first_use_cost,spec.cost]+("施法成功才消耗次数。" if type=="fireball" else "")) if spec.has("first_use_cost") else ""

static func kick_cooldown(g) -> int:
 return maxi(0,g.state.kick_last+int(TYPES.kick[0].cooldown_turns)+1-g.state.round)

static func physical_damage(g, base: float, body_level: int) -> float:
 return (base+g.RelicEffects.attribute(g,"strength")+g.charge_bonus())*g.B.BODY_DAMAGE[body_level]

static func fireball_damage(g) -> float:
 var base=g.B.FIREBALL_ASSISTED if fireball_gesture(g) else g.B.FIREBALL
 return (base+g.state.spell_base_bonuses.get("fireball",0)+g.Cards.spell_power(g,"fireball").get("base_bonus",0.0))*g.Cards.damage_multiplier(g,"fireball")

static func fireball_gesture(g) -> bool:
 return not g.Cards.spell_power(g,"fireball").get("disable_gesture",false) and (g.Cards.basic_attack_freedom(g) or g.Cards.action_ignores_restraints(g) or g.hand_cast_reason()=="")

static func usage(g, type: String) -> Dictionary:
 var base=int(TYPES[type][0].get("uses_per_turn",0))
 var limit=base+int(g.Cards.spell_power(g,type).get("extra_uses",0)) if base>0 else 0
 var used=int(g.state.combat.attack_uses.get(type,0))
 return {"limit":limit,"used":used,"remaining":maxi(0,limit-used)}
