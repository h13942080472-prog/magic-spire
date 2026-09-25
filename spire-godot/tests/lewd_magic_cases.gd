extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Pack=["itching_heart","self_satisfaction","psychological_suggestion","rally_spirit","desire_rune","forced_edging","forced_climax"]

static func give(t,g,type: String) -> Dictionary:
 g._gain_card(type)
 return t.hand_card(g,type)

static func fresh() -> RefCounted:
 var g=Game.new(42)
 g.state.pressure=50
 g.state.energy=10
 return g

static func run(t) -> void:
 for type in Pack:
  var g=fresh()
  t.check(not g.can_offer_card(type),"LEWD locked conditional pool: "+type)
  g.state.relics.append("desire_cube_pro_max")
  t.check(g.can_offer_card(type) and ((type in g.Cards.Rules.COMMON+g.Cards.Rules.UNCOMMON+g.Cards.Rules.RARE)==(type!="itching_heart")),"LEWD unlocked pool keeps starter rarity excluded: "+type)
  var card=give(t,g,type)
  t.check(g.validate()=="","LEWD definitions and card instance validate: "+type+" / "+g.validate())
  var info=g.B.card_metadata(type)
  if g.Cards.Rules.lewd_magic(type):
   t.check(info.face_type_names.bound=="淫魔法" and info.face_mana.bound[0].kind=="pressure","LEWD static metadata has subtype and heart: "+type)
 failures(t)
 costs(t)
 meters(t)
 suggestion(t)
 selection(t)
 prison(t)
 witch_variants(t)

static func witch_variants(t) -> void:
 var g=preload("res://tests/witch_character_cases.gd").fresh()
 g.RelicEffects.gain(g,"desire_cube_pro_max")
 for type in Pack:
  var id=g.Character.card_id(g,type);var original=g.Cards.Rules.SPECS[type]
  var variant=g.Cards.Rules.SPECS[id]
  t.check(id=="witch_"+type and variant.reward_pool=="lewd_magic" and variant.rarity==original.rarity and variant.cost==original.cost and g.Character.allowed_card(g,id) and g.can_offer_card(id),"LEWD WITCH independent compatible card preserves original costs and pool: "+type)
  t.check(not g.Character.incompatible(g,variant) and g.B.card_info(id).all(func(text):return not text.contains("蓄力")),"LEWD WITCH effect tree and copy use focus instead of charge: "+type)
 var rare=g.reward_offer(g.Cards.Rules.RARE,"fixed",null,3,"lewd_magic")
 t.check(rare.size()==2 and rare.has("witch_forced_edging") and rare.has("witch_forced_climax"),"LEWD WITCH filtered rare reward cannot leak unrelated witch expansion cards")
 t.check(g.Cards.Rules.BUFFS.desire_rune_bound.pressure_gained.effects==[{"op":"charge","amount":1}] and g.Cards.Rules.SPECS.self_satisfaction.self_faces.free.effects.has({"op":"charge","amount":2}),"LEWD WITCH registration leaves original charge mechanics intact")
 for entry in [["self_satisfaction",2],["psychological_suggestion",1]]:
  g=preload("res://tests/witch_character_cases.gd").fresh();g.state.pressure=37.5;g.state.energy=10;g.state.sure_cast=true
  var card=preload("res://tests/curse_cases.gd").give(g,entry[0])
  t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.witch_focus==entry[1] and g.state.charge==0,"LEWD WITCH actual free face grants matching focus count: "+entry[0])
 g=preload("res://tests/witch_character_cases.gd").fresh();g.state.pressure=37.5
 var card=preload("res://tests/curse_cases.gd").give(g,"desire_rune")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok,"LEWD WITCH adapted rune enters power zone through real play")
 g.Pressure.gain(g,29,"test")
 t.check(g.state.witch_focus==0,"LEWD WITCH rune keeps the thirty-pressure threshold")
 g.Pressure.gain(g,1,"test")
 t.check(g.state.witch_focus==1 and g.state.charge==0 and g.state.powers[0].power_pressure_progress==0,"LEWD WITCH rune grants focus once at exact threshold")
 preload("res://tests/persistence_cases.gd").roundtrip(t,g,"witch lewd power meter")

static func costs(t) -> void:
 var g=fresh();var card=give(t,g,"forced_edging")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.pressure==30 and g.state.energy==11,"LEWD pressure payment converts to energy at peak")
 g=fresh();card=give(t,g,"forced_edging");g.state.pressure=19
 var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.export_snapshot()==before,"LEWD insufficient pressure rejects without RNG or payment")
 g=fresh();card=give(t,g,"forced_edging");var mana=g.state.mana
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.pressure==30 and g.state.energy==9 and g.state.mana==mana-10,"LEWD free face uses mana and lowers pressure")
 g=fresh();card=give(t,g,"self_satisfaction");mana=g.state.mana
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.pressure==70 and g.state.mana==mana-10 and g.state.rng.magic==0,"LEWD skill face never rolls casting")
 g=fresh();card=give(t,g,"rally_spirit")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.energy==9 and g.state.pressure==30,"LEWD rally free cost and immediate loss")
 g.Cards.expire_turn_buffs(g,true)
 t.check(g.state.pressure==70 and "rally_spirit_next" not in g.state.card_buffs,"LEWD delayed pressure applies once at next start")
 g=fresh();card=give(t,g,"itching_heart")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.special_equipment.any(func(e):return e.grade==1 and e.type in g.SpecialEquipment.RANDOM_POOLS[1]),"LEWD self toy installs through legal application")

static func meters(t) -> void:
 var g=fresh();var card=give(t,g,"desire_rune")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.pressure==20,"LEWD power pays pressure without spell roll")
 g.Pressure.gain(g,29,"test")
 t.check(g.state.charge==0,"LEWD gain meter below threshold")
 g.Pressure.gain(g,1,"test")
 t.check(g.state.charge==1 and g.state.powers[0].power_pressure_progress==0,"LEWD exact gain threshold triggers once")
 var saved=g.export_snapshot();var restored=Game.new(9)
 t.check(restored.restore_snapshot(saved).ok,"LEWD resource meter snapshot restores")
 g.Cards.end_powers(g)
 t.check(g.state.powers.is_empty() and g.state.discard.all(func(c):return not c.has("power_pressure_progress")),"LEWD meter does not leak beyond session")

static func suggestion(t) -> void:
 var g=fresh();var card=give(t,g,"psychological_suggestion")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.Cards.action_ignores_restraints(g),"LEWD suggestion grants next action without consuming itself")
 var saved=g.export_snapshot();g.command_facts();g.get_view()
 t.check(g.export_snapshot()==saved,"LEWD suggestion previews do not consume use")
 g.add_fixture("mouth",8,10,false,3)
 var profile=g.Cards.cast_profile(g,"fireball")
 t.check(g.cast_view(profile).factors.is_empty(),"LEWD suggestion bypasses mouth multiplier")
 card=give(t,g,"self_satisfaction")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and not g.Cards.action_ignores_restraints(g),"LEWD next card consumes one suggestion use")

static func selection(t) -> void:
 var g=fresh();var card=give(t,g,"forced_climax");var deck=g.state.deck.duplicate(true)
 var selected=[]
 for zone in ["draw","hand","discard"]:
  if zone=="discard" and g.state.discard.is_empty():
   var moved=g.state.draw.pop_back();g.state.discard.append(moved)
  for c in g.state[zone]:
   if c.uid!=card.uid:
    selected.append(c.uid)
    break
 t.check(selected.size()==3,"LEWD fixture supplies one selectable card per zone")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.card_chain.remaining==3,"LEWD successful cast opens three-card selection")
 var saved=g.export_snapshot();var restored=Game.new(9)
 t.check(restored.restore_snapshot(saved).ok,"LEWD pending selection snapshot restores")
 var choices=g.command_facts().filter(func(c):return c.payload.kind=="chain")
 t.check(not choices.any(func(c):return c.payload.get("selected_uid","")==card.uid),"LEWD selection excludes its own played card")
 for uid in selected:
  t.check(t.action(g,"chain",{"selected_uid":uid}).ok,"LEWD selected zone card commits through dispatcher")
 t.check(g.state.card_chain.is_empty() and g.state.play.is_empty() and g.state.deck==deck,"LEWD selection completes without deleting permanent deck")
 t.check(selected.all(func(uid):return g.state.exhaust.any(func(c):return c.uid==uid)) and g.state.exhaust.any(func(c):return c.uid==card.uid),"LEWD chosen three and spell itself are exhausted")
 t.check(g.state.pressure==80 and g.state.overload_total==1 and g.state.overloaded,"LEWD forced climax preserves post-gain pressure while triggering ordinary consequences")
 t.check(g.validate()=="","LEWD final selection state validates: "+g.validate())
 g=fresh();card=give(t,g,"forced_climax")
 for zone in ["draw","hand","discard"]:
  for c in g.state[zone].duplicate():
   if c.uid==card.uid: continue
   g.state[zone].erase(c);g.state.exhaust.append(c)
 var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.export_snapshot()==before,"LEWD fewer than three eligible cards rejects atomically")

static func failures(t) -> void:
 var failed=false
 for seed in range(1,20):
  var g=Game.new(seed);g.state.pressure=25;g.state.energy=3
  var card=give(t,g,"forced_edging")
  t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok,"LEWD partial chance attempt commits")
  if not g._magic_failed: continue
  failed=true
  t.check(g.state.pressure==25 and g.state.hand.any(func(c):return c.uid==card.uid),"LEWD failed cast returns full pressure cost and retains card")
  break
 t.check(failed,"LEWD deterministic seeds exercise actual failed cast")
 var g=fresh();g.state.sure_cast=true;g.state.pressure=90
 var card=give(t,g,"forced_climax")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok,"LEWD threshold fixture starts selection")
 for i in range(3):
  var choice=g.command_facts().filter(func(c):return c.payload.kind=="chain")[0]
  t.check(g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok,"LEWD threshold selection commits")
 t.check(g.state.pressure==20 and g.state.overload_total==2,"LEWD natural threshold and explicit climax both occur; explicit one preserves remainder")
 g=fresh();g.Cards.grant_buff(g,"psychological_suggestion")
 card=give(t,g,"forced_climax")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.Cards.action_ignores_restraints(g),"LEWD suggestion persists across unfinished multistep action")
 var saved=g.export_snapshot();saved.card_chain.action_buffs=["nonexistent"]
 var restored=Game.new(9)
 t.check(not restored.restore_snapshot(saved).ok,"LEWD malformed pending action bonus is rejected")
 for bad in [3,"psychological_suggestion",["psychological_suggestion","psychological_suggestion"]]:
  saved.card_chain.action_buffs=bad
  t.check(not restored.restore_snapshot(saved).ok,"LEWD malformed pending action bonus type or duplicate is rejected")
 for i in range(3):
  var choice=g.command_facts().filter(func(c):return c.payload.kind=="chain")[0]
  t.check(g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok,"LEWD protected continuation commits")
 t.check(not g.Cards.action_ignores_restraints(g),"LEWD suggestion consumed once when full card resolves")

static func prison(t) -> void:
 var fixture=preload("res://tests/prison_cases.gd")
 var g=fixture.intake(t);fixture.clear_fixture(g)
 preload("res://tests/exploration_fixture.gd").at_site(g,"door")
 g.add_fixture("palm",4)
 var target=g.add_fixture("thigh",4,10,true)
 var card=give(t,g,"double_unlock")
 g.Cards.grant_buff(g,"psychological_suggestion")
 t.check(t.action(g,"prison",{"action":"unlock","uid":card.uid}).ok and g.Cards.action_ignores_restraints(g),"LEWD prison door card shares freedom across its full chain")
 t.check(t.action(g,"chain",{"target":target.id}).ok and not g.Cards.action_ignores_restraints(g),"LEWD door-first second segment consumes freedom at completion")
 var saw_failure=false
 for seed in range(1,15):
  g=fixture.intake(t);fixture.clear_fixture(g)
  preload("res://tests/exploration_fixture.gd").at_site(g,"door")
  g.state.seed=seed;g.state.pressure=75
  g.add_fixture("palm",4);card=give(t,g,"unlock")
  g.Cards.grant_buff(g,"psychological_suggestion")
  var result=t.action(g,"prison",{"action":"unlock","uid":card.uid})
  t.check(result.ok and not g.Cards.action_ignores_restraints(g),"LEWD prison single cast consumes freedom on success or failure")
  if g._magic_failed:
   saw_failure=true
   break
 t.check(saw_failure,"LEWD prison negative casting branch exercised")
