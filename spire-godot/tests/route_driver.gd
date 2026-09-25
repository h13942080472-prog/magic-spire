extends RefCounted

# Traversal-only fixture: shorten persistent fights without bypassing attack, reward or travel commands.
# Full guard, toybox and configured repeating enemy cycles have their own behavior suites.
static func shorten_persistent_enemies(g) -> bool:
 var found=false
 for e in g.state.enemies:
  if not e.gone and (g.Enemies.behavior(e.type) in ["guard","drone","binding_box","six_bind","dispenser","lock","sequence","humanoid","puppeteer"] or g.Enemies.TYPES[e.type].has("cycle") or g.Enemies.TYPES[e.type].has("weighted_moves")):
   e.hp=1.0
   found=true
 return found

# One packing policy for rule and window traversal; callers still submit real actions.
static func packing_action(g) -> Dictionary:
 if g.state.phase!="pack": return {}
 var kind="item_discard" if g.carried_items()>g.item_capacity() else "finish_pack"
 for c in g.command_facts():
  if c.valid and c.payload.kind==kind: return c
 return {}

# Events need not offer refusal; choose a real visible exit or their next legal step.
static func event_action(facts: Array) -> Dictionary:
 var choices=facts.filter(func(c):return c.payload.kind=="event" and c.valid)
 var preferred=choices.filter(func(c):return c.payload.get("choice","")=="refuse" or c.payload.get("type","")=="skip" or c.payload.action=="leave")
 return preferred[0] if not preferred.is_empty() else (choices[0] if not choices.is_empty() else {})

static func attack(g) -> Dictionary:
 var best={}
 for c in g.command_facts():
  if c.payload.kind!="attack" or not c.valid or c.payload.damage<=0 or c.payload.fall: continue
  if best.is_empty() or g._enemy(c.payload.enemy).hp<g._enemy(best.payload.enemy).hp: best=c
 return best

# Traversal scenarios must use their preparation turns once mouth hazards exist;
# blindly carrying every restraint to the summit is not a navigation prerequisite.
static func prepare_action(g) -> Dictionary:
 if g.state.phase!="prepare" or not g.occupied("mouth"): return {}
 var choices=g.command_facts().filter(func(c):return c.valid and c.payload.get("target","") in g.equipment_at("mouth").map(func(e):return e.id))
 for c in choices:
  if c.payload.kind=="manual": return c
 choices=choices.filter(func(c):return c.payload.get("preview",{}).get("damage",0)>0)
 choices.sort_custom(func(a,b):return a.payload.preview.damage/maxi(1,a.cost)>b.payload.preview.damage/maxi(1,b.cost))
 if not choices.is_empty(): return choices[0]
 for c in g.command_facts():
  if c.valid and c.payload.kind=="end": return c
 return {}
