extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func run(t) -> void:
 for type in ["strain","slip"]:
  var plain=Game.new(42);plain.state.wall="normal"
  var equipment=plain.add_fixture("wrist",6)
  var card=t.hand_card(plain,type)
  var action=t.find_action(plain,"card",{"uid":card.uid,"target":equipment.id,"free":false})
  var durability=equipment.durability;var energy=plain.state.energy
  var expected=plain.escape_preview(equipment,type,6).damage
  t.check(action.valid and action.payload.preview.base==6 and plain.dispatch(plain.command(action.payload,plain.state.version),plain.state.version).ok,"BASIC six-point escape card submits its formal candidate: "+type)
  t.check(is_equal_approx(plain._equipment(equipment.id).durability,durability-expected) and plain.state.energy==energy-1 and plain._card(card.uid).is_empty(),"BASIC actual damage uses six while retaining one-energy cost and normal card movement: "+type)
 var g=Game.new(42)
 var original=g.Cards.Rules.SPECS.duplicate(true)
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="graduate_certificate")
 t.check(g.Relics.TYPES.graduate_certificate.rarity=="uncommon" and preload("res://tests/rolling_log_cases.gd").offer_tier(g,g.Relics.TYPES.graduate_certificate.rarity,excluded)=="graduate_certificate","DIPLOMA uncommon relic enters shared pool")
 for type in ["strain","slip"]:
  g=Game.new(42);g.state.wall="normal"
  var target=g.add_fixture("wrist",6)
  var free_text=g.Cards.face_text(g,type,true)
  var old=g.Cards.target_payload(g,type,"wrist",target).preview
  t.check(old.base==6 and g.Cards.face_text(g,type,false).contains(("挣扎" if type=="strain" else "滑脱")+"6"),"BASIC both escape cards print and preview six before bonuses: "+type)
  var ordinary=g.escape_preview(target,type,5)
  g.RelicEffects.gain(g,"graduate_certificate")
  var enhanced=g.Cards.target_payload(g,type,"wrist",target).preview
  var expected_preview=g.escape_preview(target,type,10);expected_preview.face_value=10.0
  t.check(enhanced==expected_preview and enhanced.damage>old.damage,"DIPLOMA card base increases before all existing escape factors: "+type)
  t.check(g.escape_preview(target,type,5)==ordinary and g.Cards.face_text(g,type,true)==free_text,"DIPLOMA leaves passive/raw escape and free face unchanged: "+type)
  g.state.card_buffs.append("henshin_free")
  t.check(is_equal_approx(g.Cards.target_payload(g,type,"wrist",target).preview.damage,enhanced.damage*2),"DIPLOMA card bonus participates in existing damage multiplier: "+type)
  g.state.card_buffs.clear()
  var card=t.hand_card(g,type)
  var before=g.export_snapshot();var shown=g.get_view()
  var printed=("挣扎" if type=="strain" else "滑脱")+"10"
  t.check(shown.hand.any(func(row):return row.type==type and row.bound.contains(printed)) and g.live_card_text_set([{"type":type}]).texts[type].bound.contains(printed),"DIPLOMA hand and deck projections share modified printed value: "+type)
  t.check(g.state==before and g.Cards.Rules.SPECS==original,"DIPLOMA viewing never mutates state or shared card templates")
  var action=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false})
  var version=g.state.version;var durability=target.durability
  t.check(not action.is_empty() and action.payload.preview==enhanced and g.dispatch(g.command(action.payload,version),version).ok,"DIPLOMA actual card dispatch consumes enhanced candidate: "+type)
  var remaining=g._equipment(target.id)
  t.check((remaining.is_empty() if enhanced.damage>=durability else is_equal_approx(remaining.durability,durability-enhanced.damage)),"DIPLOMA actual durability loss matches enhanced preview: "+type)
  before=g.export_snapshot()
  t.check(not g.dispatch(g.command(action.payload,version),version).ok and g.state==before,"DIPLOMA stale card command is atomically rejected")
  g.RelicEffects.gain(g,"graduate_certificate")
  t.check(g.Cards.base_damage(g,type)==10,"DIPLOMA duplicate pickup does not stack itself")
  for other in ["brace","inch","chain","peel","magic_slip","strong_elbow"]:
   t.check(g.Cards.base_damage(g,other)==original[other].base,"DIPLOMA excludes other named cards: "+other)
 g=Game.new(42,true,"guard")
 for turn in range(3): t.check(t.action(g,"end").ok,"DIPLOMA actual guard sequence reaches capture setup")
 t.check(g.CaptureBind.has_bind(g),"DIPLOMA capture fixture uses the real active guard binding")
 g.RelicEffects.gain(g,"graduate_certificate")
 for type in ["strain","slip"]:
  var card=t.hand_card(g,type)
  var action=t.find_action(g,"card",{"uid":card.uid,"target":g.CaptureBind.BIND_TARGET})
  t.check(action.payload.has("preview") and action.payload.preview.base==10,"DIPLOMA capture target receives the same printed base: "+type)
  if not action.payload.has("preview"): continue
  var before=g.CaptureBind.view(g).value
  var expected=maxf(0,before-action.payload.preview.damage)
  t.check(g.dispatch(g.command(action.payload,g.state.version),g.state.version).ok and is_equal_approx(g.CaptureBind.view(g).get("value",0),expected),"DIPLOMA actual capture damage uses enhanced base: "+type)
 var fresh=Game.new(42)
 t.check(g.Cards.Rules.SPECS==original and fresh.Cards.base_damage(fresh,"strain")==6,"DIPLOMA leaves new runs and shared definitions unchanged")
 g=Game.new(42);g.state.relics=["graduate_certificate"]
 var tight=g.add_fixture("wrist",10)
 var immune=g.Cards.target_payload(g,"slip","wrist",tight).preview
 t.check(immune.immune and immune.scaled_damage==0 and immune.damage==immune.environment_true,"DIPLOMA cannot bypass tier-three slip immunity; only existing environment true damage remains")
 tight.durability=6;tight.locked=true
 g.add_fixture("wrist",6)
 var expected_preview=g.escape_preview(tight,"strain",10);expected_preview.face_value=10.0
 t.check(g.Cards.target_payload(g,"strain","wrist",tight).preview==expected_preview,"DIPLOMA lock and stacking still use the normal multipliers")
