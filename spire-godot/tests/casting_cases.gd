extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const P=preload("res://core/pressure.gd")

static func run(t) -> void:
 magic_slip_free(t)
 prepared_chant(t)
 fireball_failed_retries(t)
 failure_refunds(t)
 unlock_zero_energy(t)
 retry_failed_cards(t)
 preload("res://tests/temporary_mana_cases.gd").run(t)
 body_routes(t)
 cost_descriptions(t)
 for pair in [[0,1.0],[49,1.0],[50,1.0],[60,0.64],[75,0.25],[90,0.04],[100,0.0]]:
  t.check(is_equal_approx(P.cast_chance(pair[0]),pair[1]),"CAST curve anchor "+str(pair[0]))
 var previous=1.0
 for value in range(101):
  var rate=P.cast_chance(value)
  t.check(rate<=previous and rate>=0 and rate<=1,"CAST bounded monotonic curve "+str(value))
  previous=rate
 var seen={};var failed_game
 for seed_value in range(8):
  var g=Game.new(seed_value)
  var e=g.add_fixture("wrist",8)
  var card=t.hand_card(g,"ease")
  g.state.pressure=75
  var chosen=t.find_action(g,"card",{"uid":card.uid,"target":e.id})
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(g.state==before and not g.dispatch(g.command(chosen.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"CAST preview and stale dispatch consume no RNG or payment")
  var restored=Game.new(0);t.check(restored.restore_snapshot(before).ok,"CAST save restore")
  t.check(g.dispatch(g.command(chosen.payload,g.state.version),g.state.version).ok and restored.dispatch(restored.command(chosen.payload,restored.state.version),restored.state.version).ok,"CAST real action commits even when spell fails")
  var result=g.state.logs.filter(func(x):return x.data.has("spell")).back().data.spell
  seen[result.success]=true
  t.check(g.state.rng.magic==1 and restored.state.rng.magic==1 and restored.state.logs.back().text==g.state.logs.back().text and restored._equipment(e.id).durability==g._equipment(e.id).durability,"CAST saved RNG reproduces result")
  t.check(g.state.energy==before.energy-chosen.cost and is_equal_approx(g.state.mana,before.mana-chosen.mana*(1.0 if result.success else 0.5)) and (g.state.discard if result.success else g.state.hand).any(func(c):return c.uid==card.uid),"CAST failure refunds half mana and only success discards the card")
  t.check(g._equipment(e.id).durability==chosen.payload.after if result.success else g._equipment(e.id).durability==8,"CAST only successful spell changes durability")
  if not result.success: failed_game=g
 t.check(seen.has(true) and seen.has(false),"CAST deterministic sample covers both outcomes")
 var g=Game.new(42);g.state.pressure=99
 var card=t.hand_card(g,"ease");var before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.temporary_mana==before.temporary_mana+10 and g.state.rng.magic==0 and g.state.mana==before.mana,"CAST free preparation remains guaranteed and never rolls")
 g=Game.new(42);var e=g.add_fixture("wrist",8);card=t.hand_card(g,"ease")
 t.check(t.action(g,"card",{"uid":card.uid,"target":e.id}).ok and g._equipment(e.id).durability<8 and g.state.rng.magic==0,"CAST low-pressure guaranteed success does not consume random sequence")
 # A failed double unlock must not queue a second target or consume two spells.
 g=Game.new(failed_game.state.seed);g._gain_card("double_unlock")
 var a=g.add_fixture("ankle",8,10,true);var b=g.add_fixture("thigh",8,10,true)
 card=t.hand_card(g,"double_unlock");g.state.pressure=75
 t.check(t.action(g,"card",{"uid":card.uid,"target":a.id}).ok and g._equipment(a.id).locked and g._equipment(b.id).locked and g.state.card_chain.is_empty() and g.state.rng.magic==1,"CAST failed double unlock has no continuation")
 g=Game.new(failed_game.state.seed);g.state.pressure=75
 before=g.export_snapshot()
 t.check(t.action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id}).ok and g.state.enemies[0].hp==before.enemies[0].hp and g.state.energy==before.energy-1 and g.state.mana<before.mana and t.find_action(g,"attack",{"type":"fireball"}).cost==0,"CAST fireball uses same real failure path")
 t.check(not g.state.logs.back().text.contains("卡牌"),"CAST fixed spell failure does not claim a card was spent")
 g=Game.new(42);card=t.hand_card(g,"ease");g.add_fixture("mouth",4)
 var view=g.get_view();var face=view.hand.filter(func(c):return c.uid==card.uid)[0]
 t.check(face.availability.free.usable and face.availability.bound.usable and is_equal_approx(view.casting.chance,0.75),"CARD basic mouth equipment changes chance without banning casting")
 g=Game.new(42);card=t.hand_card(g,"strain")
 face=g.get_view().hand.filter(func(c):return c.uid==card.uid)[0]
 t.check(face.availability.free.usable and face.availability.free.text=="可用" and face.availability.bound.dim,"CARD face-specific target availability")
 g.state.energy=0
 face=g.get_view().hand.filter(func(c):return c.uid==card.uid)[0]
 t.check(face.availability.free.dim and face.availability.free.text.contains("能量"),"CARD ordinary card dims for insufficient energy")
 g._gain_card("sensitive");card=t.hand_card(g,"sensitive")
 face=g.get_view().hand.filter(func(c):return c.uid==card.uid)[0]
 t.check(not face.availability.free.dim and not face.availability.bound.dim and not face.availability.free.usable,"CARD curse exempt from dimming but remains unplayable")
 g=Game.new(42);var c=t.hand_card(g,"ease");g.add_fixture("wrist",8);g.state.mana=0
 face=g.get_view().hand.filter(func(x):return x.uid==c.uid)[0]
 t.check(face.availability.bound.dim and face.availability.bound.text.contains("魔力") and face.availability.free.usable,"CARD mana shortage applies only to paid face")
 g=Game.new(42,true,"equipment");c=t.hand_card(g,"ease")
 face=g.get_view().hand.filter(func(x):return x.uid==c.uid)[0]
 t.check(face.availability.free.dim and face.availability.free.text.contains("休息房"),"CARD free effect unavailable in rest")

 for grade in [1,2,3]:
  for tightness in [1,2,3]:
   g=Game.new(42);g.state.pressure=75
   var maximum=g.Equipment.maximum(grade)
   var oral=g._install_template("mouth_band","mouth",maximum*{1:0.2,2:0.6,3:1.0}[tightness],maximum,false,"fixture",grade,0)
   var expected=0.25*{1:0.5,2:0.25,3:0.0}[grade]*{1:1.5,2:1.0,3:0.5}[tightness]
   expected=roundi(expected*g.B.CAST_ROLL_STEPS)/float(g.B.CAST_ROLL_STEPS)
   t.check(not oral.is_empty() and is_equal_approx(g.cast_view().chance,expected),"CAST mouth grade and tightness independent multipliers "+str([grade,tightness]))
 g=Game.new(42)
 var oral=g._install_template("mouth_band","mouth",24.0,24.0,false,"fixture",3,0)
 # Advanced mouth equipment now includes a harness. Keep a separate legal
 # spell target so this case measures zero casting chance, not its structure.
 var cast_target=g.add_fixture("wrist",8.0)
 card=t.hand_card(g,"ease");face=g.get_view().hand.filter(func(c):return c.uid==card.uid)[0]
 before=g.export_snapshot()
 t.check(face.availability.bound.dim and face.availability.bound.text.contains("成功率为0%") and not t.action(g,"card",{"uid":card.uid,"target":cast_target.id}).ok and g.state==before,"CAST zero chance spell is unavailable without paying or rolling")
 t.check(face.availability.free.usable,"CAST free preparation remains usable even at zero spell probability")
 t.check(g.cast_view({"parts":["hand"],"multiplier":1.0}).chance==1.0,"CAST non-mouth profile ignores even advanced mouth equipment")
 g.state.pressure=75
 t.check(is_equal_approx(g.cast_view({"parts":["hand"],"multiplier":1.5}).chance,0.375),"CAST per-spell bonus uses same pressure curve without mouth penalty")
 g.state.pressure=0
 g.state.equipment.clear()
 t.check(g.cast_view().chance==1.0,"CAST removing mouth equipment immediately restores base chance")

 # Failed magic slip neither damages gear nor grants its success-side benefits.
 g=Game.new(failed_game.state.seed);g._gain_card("magic_slip")
 e=g.add_fixture("ankle",8);card=t.hand_card(g,"magic_slip");g.state.pressure=75
 g.state.energy=0
 before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"target":e.id}).ok and g.state.energy==0 and g.state.mana<before.mana and g._equipment(e.id).durability==8 and g.state.hand==before.hand and g.state.pressure==75,"CAST zero-energy magic slip still pays mana on failure, keeps the hand and has no success effects")
 # Prison door is a real card use and must obey the identical zero/failure gate.
 var prison=preload("res://tests/prison_cases.gd")
 g=prison.intake(t);prison.clear_fixture(g);preload("res://tests/exploration_fixture.gd").at_site(g,"door")
 g.add_fixture("palm",4)
 t.grant_fixture_card(g,"unlock")
 before=g.export_snapshot()
 t.check(not t.action(g,"prison",{"action":"unlock"}).ok and g.state==before,"CAST prison cannot bypass blocked hands or consume card")
 g.state.equipment.clear();g.state.pressure=75;g.state.seed=failed_game.state.seed
 card=t.grant_fixture_card(g,"unlock");before=g.export_snapshot()
 t.check(t.action(g,"prison",{"action":"unlock"}).ok and not g.state.prison.door_open and g.state.mana<before.mana and g.state.hand.any(func(x):return x.uid==card.uid),"CAST failed prison door spell pays and keeps its real card without opening door")
 t.check(g.state.logs.any(func(x):return x.data.has("spell") and not x.data.spell.success and x.text.contains("卡牌留在手中")),"CAST prison failure reports actual card location")

 # One quantized probability governs display, eligibility and the actual roll.
 for pressure in [99.0,99.5,99.6,99.7,99.9,100.0]:
  g=Game.new(42);e=g.add_fixture("thigh",8);card=t.hand_card(g,"ease");g.state.pressure=pressure
  var rate=g.cast_view()
  var choice=t.find_action(g,"card",{"uid":card.uid,"target":e.id})
  t.check(is_equal_approx(float(rate.percent.trim_suffix("%"))/100.0,rate.chance) and rate.chance==float(rate.winning_rolls)/g.B.CAST_ROLL_STEPS,"CAST display and lottery share exact precision "+str(pressure))
  t.check(choice.valid==(rate.winning_rolls>0),"CAST eligibility agrees with winning outcomes "+str(pressure))
  before=g.export_snapshot()
  if rate.winning_rolls==0:
   t.check(not g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and g.state==before,"CAST rounded zero rejects without costs or RNG")
  else:
   t.check(g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok,"CAST smallest supported probability remains playable")
   var spell=g.state.logs.filter(func(x):return x.data.has("spell")).back().data.spell
   t.check(spell.success==(spell.roll<rate.winning_rolls) and spell.chance==rate.chance,"CAST actual roll uses displayed winning threshold")

static func fireball_failed_retries(t) -> void:
 var g=Game.new(42);g._discard_end();g.state.pressure=75
 for attempt in range(3):
  var c=t.find_action(g,"attack",{"type":"fireball"})
  var rng=g.state.rng.magic
  while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"fireball")).winning_rolls: rng=g.state.rng.magic
  g.state.rng.magic=rng
  var before=g.export_snapshot()
  t.check(c.valid and c.cost==(1 if attempt==0 else 0),"FIREBALL failed retries preserve the existing first-attempt energy rule")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and g.BasicAttacks.usage(g,"fireball").remaining==2 and g.state.enemies==before.enemies and is_equal_approx(g.state.mana,before.mana-c.mana*0.5),"FIREBALL repeated failures preserve all charges and refund half mana")
  t.check(g.state.logs.any(func(log):return log.data.has("spell") and log.text.contains("次数未消耗")),"FIREBALL failure log explains preserved charges")
 g.state.sure_cast=true
 t.check(t.action(g,"attack",{"type":"fireball"}).ok and not g._magic_failed and g.BasicAttacks.usage(g,"fireball").remaining==1,"FIREBALL successful retry consumes exactly one charge")

static func failure_refunds(t) -> void:
 var helper=preload("res://tests/curse_cases.gd")
 for type in ["mana_conversion","rekindle","mana_invocation","fireball"]:
  for temporary in [0.0,7.5,100.0]:
   var g=Game.new(42);g._discard_end();g.state.pressure=75;g.state.mana=50;g.state.temporary_mana=temporary
   g.state.relics.append("mana_earring")
   var payload={"type":"fireball","enemy":g.state.enemies[0].id}
   if type!="fireball": payload={"uid":helper.give(g,type).uid,"free":false}
   var c=t.find_action(g,"attack" if type=="fireball" else "card",payload)
   var rng=g.state.rng.magic
   while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,type)).winning_rolls: rng=g.state.rng.magic
   g.state.rng.magic=rng
   var before=g.export_snapshot();g.get_view();g.command_facts()
   t.check(c.valid and g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"REFUND preview and stale request preserve resources "+type)
   var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
   t.check(result.ok and g._magic_failed and is_equal_approx(g.state.mana,before.mana-c.mana_payment.mana*0.5) and is_equal_approx(g.state.temporary_mana,before.temporary_mana-c.mana_payment.temporary_mana*0.5),"REFUND half actual payment returns to each original pool "+type+str(temporary))
   t.check(g.state.energy==before.energy-c.cost and g.state.hand==before.hand and g.state.flask_mana==before.flask_mana and g.state.enemies==before.enemies,"REFUND does not restore energy or apply success effects "+type)
   var spell=g.state.logs.filter(func(log):return log.data.has("spell")).back().data.spell
   t.check(is_equal_approx(spell.mana_refund.mana,c.mana_payment.mana*0.5) and is_equal_approx(spell.mana_refund.temporary_mana,c.mana_payment.temporary_mana*0.5),"REFUND structured spell log reports both returned amounts")
   for field in ["mana","temporary_mana"]:
    if c.mana_payment[field]>0: t.check(result.resource_feedback.any(func(e):return e.field==field and is_equal_approx(e.after-e.before,c.mana_payment[field]*0.5)),"REFUND resource animation reports returned "+field)
   if type=="fireball": t.check(g.BasicAttacks.usage(g,"fireball").used==0,"REFUND failed fireball preserves its cast count")
   t.check(is_equal_approx(g.state.combat.mana_spent,c.mana_payment.mana),"REFUND spending counters retain gross actual payment")
   t.check(g.validate()=="","REFUND fractional balances remain valid")
 var g=Game.new(42);g.state.pressure=75
 var before=g.export_snapshot()
 g._cast_magic({"payload":{"type":"fireball","replay":true},"label":"额外火球术","mana_payment":{"mana":0.0}})
 t.check(g.state.mana==before.mana and g.state.temporary_mana==before.temporary_mana,"REFUND free replay cannot create mana")

static func retry_failed_cards(t) -> void:
 for type in ["rekindle","mana_surge"]:
  var g=Game.new(42);g._discard_end();g.state.pressure=75
  var card=preload("res://tests/curse_cases.gd").give(g,type)
  card.retain_until=g.state.tick+1
  var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
  var rng=g.state.rng.magic
  while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,type)).winning_rolls: rng=g.state.rng.magic
  g.state.rng.magic=rng
  var before=g.export_snapshot()
  var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
  t.check(result.ok and g._magic_failed and g.state.hand==before.hand and g.state.discard==before.discard and g.state.exhaust==before.exhaust and result.card_feedback.is_empty(),"CAST failure preserves physical card, order and retain marker without departure animation")
  var restored=Game.new(7)
  t.check(restored.restore_snapshot(g.export_snapshot()).ok and restored.state.hand==g.state.hand,"CAST failed card can be saved and restored in hand")
  g.state.sure_cast=true
  t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and not g.state.hand.any(func(x):return x.uid==card.uid) and (g.state.exhaust if type=="mana_surge" else g.state.discard).any(func(x):return x.uid==card.uid),"CAST same physical card can retry and only success discards or exhausts")

static func unlock_zero_energy(t) -> void:
 var g=Game.new(42);g.state.energy=0;g.state.mana=9
 var target=g.add_fixture("ankle",8,10,true)
 var card=t.grant_fixture_card(g,"unlock")
 var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false})
 var before=g.export_snapshot()
 t.check(c.cost==0 and c.mana==10 and not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"UNLOCK zero energy does not bypass ten-mana payment and rejected use is atomic")
 g.state.mana=10
 c=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false})
 var free=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var costs=g.live_card_text("unlock").face_costs
 t.check(c.valid and not free.valid and free.cost==1 and costs.bound=="0" and costs.free=="1","UNLOCK bound is playable at zero energy while free preparation still costs one")
 before=g.export_snapshot()
 t.check(g.dispatch(g.command(c.payload,before.version),before.version).ok and not g._equipment(target.id).locked and g._equipment(target.id).durability==8 and g.state.energy==0 and g.state.mana==0 and g.state.discard.any(func(row):return row.uid==card.uid),"UNLOCK zero-energy success pays mana opens only the lock and discards the card")
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,before.version-1),before.version-1).ok and g.state==before,"UNLOCK stale zero-cost play cannot repeat the effect")

static func body_routes(t) -> void:
 var g=Game.new(42)
 var target=g.add_fixture("ankle",8,10,true)
 var card=t.grant_fixture_card(g,"unlock")
 g._install_template("mouth_band","mouth",24,24,false,"fixture",3,0)
 g.state.pressure=75
 var shown=g.get_view().hand.filter(func(c):return c.uid==card.uid)[0]
 var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 t.check(c.valid and shown.casting.part=="hand" and shown.casting.chance==0.25,"ROUTE hand-only spell ignores mouth penalty and uses pressure probability")
 var palm=g.add_fixture("palm",4);palm.side="left"
 t.check(not t.find_action(g,"card",{"uid":card.uid,"target":target.id}).valid,"ROUTE default hand spell requires both complete hands")
 g.RelicEffects.gain(g,"casting_manual")
 t.check(t.find_action(g,"card",{"uid":card.uid,"target":target.id}).valid,"ROUTE casting manual permits one complete free hand")
 var fingers=g.add_fixture("fingers",4);fingers.side="right"
 c=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 var before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("手掌和手指") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"ROUTE cannot combine fingers and palm from opposite hands; rejected play is atomic")
 g.state.sure_cast=true
 t.check(not t.find_action(g,"card",{"uid":card.uid,"target":target.id}).valid,"ROUTE guaranteed casting does not bypass hand requirement")
 g.state.sure_cast=false
 g._gain_card("double_unlock");card=t.hand_card(g,"double_unlock")
 t.check(not t.find_action(g,"card",{"uid":card.uid,"target":target.id}).valid,"ROUTE all paths unusable rejects dual-path spell")
 g.state.equipment=g.state.equipment.filter(func(e):return e.slot!="mouth" and e.get("parent_id","")=="")
 shown=g.get_view().hand.filter(func(e):return e.uid==card.uid)[0]
 t.check(shown.casting.part=="mouth" and shown.casting.chance==0.25 and t.find_action(g,"card",{"uid":card.uid,"target":target.id}).valid,"ROUTE dual unlock falls back to mouth with both hands blocked")
 g.state.equipment.clear();g.add_fixture("ankle",8,10,true)
 g._install_template("mouth_band","mouth",4,10,false,"fixture",1,0)
 shown=g.get_view().hand.filter(func(e):return e.uid==card.uid)[0]
 t.check(shown.casting.part=="hand" and shown.casting.chance==0.25,"ROUTE chooses highest chance instead of penalized mouth")
 t.check(g.cast_view({"parts":["mouth","hand"],"multiplier":1.0}).part=="hand","ROUTE higher chance wins regardless of configured order")
 before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"ROUTE choosing paths does not mutate state or consume randomness")
 g=Game.new(42);g.add_fixture("fingers",4)
 target=g.add_fixture("ankle",8,10,true)
 var second=g.add_fixture("thigh",8,10,true)
 g._gain_card("double_unlock");card=t.hand_card(g,"double_unlock")
 c=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 before=g.export_snapshot()
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and not g._equipment(target.id).locked,"ROUTE mouth fallback actually unlocks despite blocked hands")
 var spell=g.state.logs.filter(func(x):return x.data.has("spell")).back().data.spell
 t.check(spell.part=="mouth" and spell.chance==1 and g.state.mana==before.mana-c.mana,"ROUTE committed spell records the previewed mouth path and pays once")
 var mana=g.state.mana;var magic_rng=g.state.rng.magic
 t.check(t.action(g,"chain",{"target":second.id}).ok and not g._equipment(second.id).locked and g.state.mana==mana and g.state.rng.magic==magic_rng,"ROUTE fallback continuation unlocks without paying or casting again")
 for type in ["henshin","mana_conversion","mana_surge","mana_invocation"]:
  g=Game.new(42);g._gain_card(type);card=t.hand_card(g,type)
  # This checks body routes; both printed face costs must already be affordable.
  g.state.energy=maxi(g.Cards.Rules.energy_cost(type,false),g.Cards.Rules.energy_cost(type,true))
  g._install_template("mouth_band","mouth",24,24,false,"fixture",3,0)
  g.add_fixture("palm",4);g.add_fixture("fingers",4);g.state.pressure=75
  shown=g.get_view().hand.filter(func(e):return e.uid==card.uid)[0]
  t.check(shown.casting.part=="none" and shown.casting.chance==0.25 and shown.availability.bound.usable and shown.availability.free.usable,"ROUTE unrestricted spell ignores all body blocks but keeps probability: "+type)
  for free in [false,true]:
   t.check(g.Cards.uses_magic({"type":type,"free":free}),"ROUTE unrestricted is still a spell on either face: "+type)

static func cost_descriptions(t) -> void:
 var g=Game.new(42)
 var target=g.add_fixture("wrist",8)
 var card=t.hand_card(g,"ease")
 for pressure in [0,55,90]:
  for reserve in [0,1]:
   g.state.pressure=pressure;g.state.temporary_mana=reserve*5
   var view=g.get_view()
   var shown=view.hand.filter(func(item):return item.uid==card.uid)[0]
   var actual=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
   t.check(shown.bound.contains("耗魔"+g.number(actual.mana)) and not shown.bound.contains("{"),"CARD hand description follows formal mana cost after pressure and reserve: %s / %s" % [shown.bound,actual.mana])
 for type in g.Cards.Rules.SPECS:
  var info=g.B.card_info(type)
  t.check(info.all(func(text):return not text.contains("{")),"CARD every display template is fully expanded: "+type)
  var spec=g.Cards.Rules.SPECS[type]
  if spec.has("worn_damage"):
   var shown=g.Cards.face_text(g,type,false)
   t.check(info[1].contains("拘束具数量×"+str(spec.worn_damage.per_item)) and shown.contains("当前"+g.number(g.Cards.base_damage(g,type))),"CARD dynamic damage text includes its formula and current mechanical value: "+type)
  elif spec.has("base"):
   var base_text=g.number(spec.base)
   var multi_text="%s×%d" % [base_text,spec.get("hits",1)]
   t.check(info[1].contains(("挣扎" if spec.mode=="strain" else "滑脱")+base_text) or (spec.get("hits",1)>1 and info[1].contains(multi_text)),"CARD damage text uses the mechanical base and optional hit count: "+type)
 t.check(g.B.card_info("ease",17.5)[1].contains("耗魔17.5"),"CARD formatting accepts changed non-integer costs without matching old wording")
static func prepared_chant(t) -> void:
 var cards=preload("res://tests/curse_cases.gd")
 for free in [false,true]:
  var g=Game.new(42);g._discard_end();g.state.energy=10
  var card=cards.give(g,"prepared_chant")
  var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
  var before=g.export_snapshot()
  t.check(c.valid and c.cost==1 and c.mana==10 and g.Cards.cast_profile(g,"prepared_chant").parts==["mouth"],"CHANT both faces use one energy, ten mana and mouth casting")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"CHANT stale play cannot grant certainty or spend resources")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and not g._magic_failed and g.state.energy==before.energy-1 and g.state.mana==before.mana-10 and g.state.exhaust.any(func(x):return x.uid==card.uid),"CHANT successful play pays and exhausts")
  g.state.pressure=99
  if free:
   t.check(g.cast_view().chance<1 and "prepared_chant_next" in g.state.card_buffs and "prepared_chant" not in g.state.card_buffs,"CHANT free face waits without improving current-turn casting")
   t.check(g.get_view().statuses.any(func(row):return row.id=="power_prepared_chant_next" and row.value=="下回合生效"),"CHANT queued status clearly reports next-turn activation")
   for enemy in g.state.enemies: enemy.intent.delayed=true
   var saved=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"next turn prepared chant")
   t.check(t.action(g,"end").ok and "prepared_chant_next" not in g.state.card_buffs and "prepared_chant" in g.state.card_buffs and g.cast_view().chance==1,"CHANT real next turn activates certainty without double expiration")
   if saved!=null: t.check(t.action(saved,"end").ok and saved.state.card_buffs==g.state.card_buffs and saved.cast_view().chance==1,"CHANT queued save resumes the same next-turn effect")
  g._install_template("mouth_band","mouth",24.0,24.0,false,"fixture",3,0)
  var rng=g.state.rng.magic
  for part in ["mouth","hand","none"]:
   t.check(g.cast_view({"parts":[part],"multiplier":0.1}).chance==1,"CHANT current turn fixes every legal spell route to 100 percent after reductions")
  var target=g.add_fixture("thigh",30,30)
  var spell=cards.give(g,"ease")
  t.check(t.action(g,"card",{"uid":spell.uid,"target":target.id}).ok and not g._magic_failed and g.state.rng.magic==rng and "prepared_chant" in g.state.card_buffs,"CHANT real subsequent spell succeeds without consuming certainty or RNG")
  g.add_fixture("fingers",8)
  t.check(g.cast_view({"parts":["hand"],"multiplier":1.0}).reason!="" and g.cast_view({"parts":["hand"],"multiplier":1.0}).chance==0,"CHANT certainty does not bypass hand casting eligibility")
  t.check(g.get_view().statuses.any(func(s):return s.name=="预备咏唱") and g.cast_view().formula.contains("预备咏唱") and not g.cast_view().formula.contains("熟练而已"),"CHANT status and casting explanation identify the actual source")
  for enemy in g.state.enemies: enemy.intent.delayed=true
  t.check(t.action(g,"end").ok and "prepared_chant" not in g.state.card_buffs and g.cast_view().chance<1,"CHANT expires at the real turn boundary")
 var g=Game.new(42);g._discard_end()
 var card=cards.give(g,"prepared_chant")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.hand.any(func(x):return x.uid==card.uid),"CHANT unplayed card is retained across turn end")
 g=Game.new(42);g._discard_end();g.state.pressure=99
 card=cards.give(g,"prepared_chant")
 var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
 var rng=g.state.rng.magic
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"prepared_chant")).winning_rolls: rng=g.state.rng.magic
 g.state.rng.magic=rng
 var before=g.export_snapshot()
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and g.state.hand.any(func(x):return x.uid==card.uid) and g.state.exhaust.is_empty() and "prepared_chant" not in g.state.card_buffs and g.state.mana==before.mana-c.mana*0.5,"CHANT itself can fail, refunds normally and remains unexhausted without granting the buff")
 g.state.pressure=0;g.state.mana=9;g.state.temporary_mana=0
 before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"CHANT insufficient mana rejects atomically")
 t.check("prepared_chant" in g.Cards.Rules.COMMON and g.Cards.Rules.definition_reason(g.Cards.Rules.SPECS.prepared_chant)=="","CHANT enters the common pool with a valid definition")
 g=Game.new(42);g._discard_end();g.state.energy=10
 for free in [true,false]:
  card=cards.give(g,"prepared_chant")
  t.check(t.action(g,"card",{"uid":card.uid,"free":free}).ok,"CHANT current and next-turn effects can coexist")
 card=cards.give(g,"prepared_chant");before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.export_snapshot()==before,"CHANT duplicate queued effect cannot spend or stack")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and "prepared_chant" in g.state.card_buffs and "prepared_chant_next" not in g.state.card_buffs,"CHANT expiring current effect does not remove the newly activated next-turn effect")
 g=Game.new(42);g._discard_end();card=cards.give(g,"prepared_chant")
 t.action(g,"card",{"uid":card.uid,"free":true});g.Cards.end_powers(g)
 t.check("prepared_chant_next" not in g.state.card_buffs,"CHANT session cleanup discards pending next-turn certainty")

static func magic_slip_free(t) -> void:
 var seen={}
 for seed_value in range(12):
  var g=Game.new(seed_value);var card=t.hand_card(g,"magic_slip")
  g.state.pressure=75;g.state.mana=0
  var choice=t.find_action(g,"card",{"uid":card.uid,"free":true})
  var before=g.export_snapshot()
  t.check(choice.valid and choice.mana==0 and choice.cost==0 and not g.dispatch(g.command(choice.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"MAGIC SLIP free mouth spell remains zero cost and stale dispatch is atomic")
  t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok,"MAGIC SLIP free cast commits")
  var success=g.state.logs.filter(func(x):return x.data.has("spell")).back().data.spell.success
  seen[success]=true
  t.check(g.state.mana==0 and g.state.energy==before.energy and g.state.temporary_mana==before.temporary_mana+(5 if success else 0),"MAGIC SLIP success alone grants preparation without mana payment")
  t.check(g.state.hand.size()==before.hand.size() and (g.state.discard if success else g.state.hand).any(func(c):return c.uid==card.uid) and g.state.draw.size()==before.draw.size()-(1 if success else 0),"MAGIC SLIP success draws one and discards; failure keeps card and does not draw")
 t.check(seen.has(true) and seen.has(false),"MAGIC SLIP free face rolls both successful and failed casts")
 var g=Game.new(42);var card=t.hand_card(g,"magic_slip")
 g._install_template("mouth_band","mouth",24.0,24.0,false,"fixture",3,0)
 var face=g.get_view().hand.filter(func(c):return c.uid==card.uid)[0];var before=g.export_snapshot()
 t.check(face.face_requirements.free==["施法：嘴部"] and face.availability.free.dim and face.availability.free.text.contains("成功率为0%"),"MAGIC SLIP free face exposes mouth condition and zero-chance reason")
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"MAGIC SLIP zero-chance free spell cannot commit")
 t.check(g.Cards.face_mana(g,"magic_slip",false)==10 and g.Cards.face_mana(g,"magic_slip",true)==0,"MAGIC SLIP bound mana remains ten")
