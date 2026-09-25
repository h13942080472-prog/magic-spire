extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func setup() -> RefCounted:
 var g=Game.new(42)
 g.state.wall="normal";g.state.phase="prepare";g.state.prepare_left=3
 return g

static func give(t,g,type: String) -> Dictionary:
 g._gain_card(type)
 return t.hand_card(g,type)

static func play(t,g,card: Dictionary,slot: String,target: String="") -> Dictionary:
 if g.Cards.Rules.SPECS[card.type].has("self_faces"): return t.action(g,"card",{"uid":card.uid,"free":target==""})
 return t.action(g,"card",{"uid":card.uid,"slot":slot,"target":target})

static func run(t) -> void:
 preload("res://tests/unique_power_reward_cases.gd").run(t)
 preload("res://tests/battle_reward_cases.gd").run(t)
 card_feedback(t)
 resource_feedback(t)
 hand_limit(t)
 configured_effects(t)
 draw_faces(t)
 reward_sampling(t)
 var g=setup()

 for type in ["focus","tear","chain","peel","double_unlock"]:
  g=setup();var card=give(t,g,type)
  var before=JSON.stringify(g.state)
  g.get_view();g.command_facts()
  t.check(JSON.stringify(g.state)==before,"REWARD new card preview is readonly "+type)
  var energy=g.state.energy;var mana=g.state.mana;var hands=g.state.hand.size()
  t.check(play(t,g,card,"thigh").ok and g.state.energy==energy-g.Cards.Rules.SPECS[type].cost and g.state.mana==mana,"REWARD free branch pays listed energy only "+type)
  if type=="focus":
   t.check(g.state.pending_retain and g.state.hand.size()==hands-1,"REWARD focus retains before drawing")
   t.action(g,"retain_skip")
   t.check(g.state.hand.size()==hands and not g.state.pending_retain,"REWARD focus skip still draws exactly one")
  elif type=="tear": t.check(g.state.charge==1 and g.state.next_energy==1,"REWARD tear free buffs")
  elif type=="chain": t.check(g.state.charge==2 and g.state.hand.size()==hands+1,"REWARD chain free grants two charge and draws two")
  elif type=="peel":
   var retained=g.state.hand.map(func(c):return c.uid)
   t.check(not g.state.pending_retain and retained.size()==hands-1 and g.state.hand.all(func(c):return c.retain_until==g.state.tick+1) and g.state.next_energy==1,"REWARD peel immediately retains the entire remaining hand without a picker")
   var late=preload("res://tests/curse_cases.gd").give(g,"strain")
   g._discard_end()
   t.check(g.state.hand.map(func(c):return c.uid)==retained and g.state.discard.any(func(c):return c.uid==late.uid),"REWARD all held cards survive actual discard but later cards are not retained")
   g._begin_player_turn()
   g._discard_end()
   t.check(g.state.hand.is_empty(),"REWARD retain-all is not a permanent hand-retention power")
  else: t.check(g.state.temporary_mana==5,"REWARD double unlock free reserve")

 # Focus now grants the shared charge and draws without choosing an equipment target.
 var target: Dictionary
 var card: Dictionary
 for mode in ["strain","slip","magic_slip"]:
  g=setup();target=g.add_fixture("ankle",60,100);card=give(t,g,"focus")
  var base=g.Cards.base_damage(g,mode)
  var before_damage=g.escape_preview(target,mode,base).damage
  var hands=g.state.hand.size()
  t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.charge==1 and g.state.hand.size()==hands and target.durability==60,"REWARD focus grants one charge and draws one without equipment damage")
  var enhanced=g.escape_preview(target,mode,base)
  t.check(enhanced.charge==g.B.CHARGE_BONUS and enhanced.damage>before_damage,"REWARD shared charge increases "+mode)
  var strike=give(t,g,mode)
  t.check(play(t,g,strike,"ankle",target.id).ok and g.state.charge==0 and is_equal_approx(g._equipment(target.id).durability,60-enhanced.damage),"REWARD active hit consumes one charge through actual formula: "+mode)
 g=setup();target=g.add_fixture("ankle",10);g.state.charge=1;card=give(t,g,"slip")
 t.check(play(t,g,card,"ankle",target.id).ok and target.durability==10 and g.state.charge==0,"REWARD immune but valid active slip consumes one charge without damage")
 g=setup();card=give(t,g,"focus")
 t.action(g,"card",{"uid":card.uid,"free":false});t.action(g,"end")
 t.check(g.state.charge==1,"REWARD focus uses shared charge duration across turns")
 g=setup();card=give(t,g,"focus")
 t.action(g,"card",{"uid":card.uid,"free":false});t.action(g,"finish_prepare")
 t.check(g.state.phase=="map" and g.state.charge==1,"REWARD preparation-earned charge survives without turtle shell")

 g=setup();target=g.add_fixture("wrist",1);card=give(t,g,"tear")
 t.check(play(t,g,card,"wrist",target.id).ok and g._equipment(target.id).is_empty() and g.state.energy==2,"REWARD tear pays two then refunds one for direct removal")
 g=setup();target=g.add_fixture("wrist",10);card=give(t,g,"tear")
 play(t,g,card,"wrist",target.id)
 t.check(not g._equipment(target.id).is_empty() and g.state.energy==1,"REWARD tear no removal no refund")

 # Automatic follow through keeps a surviving target and settles pressure once.
 g=setup()
 var a=g.add_fixture("wrist",6);var b=g.add_fixture("wrist",6);var c=g.add_fixture("wrist",6)
 card=give(t,g,"peel")
 var action=t.find_action(g,"card",{"uid":card.uid,"target":a.id});var version=g.state.version
 t.check(play(t,g,card,"wrist",a.id).ok and g.state.card_chain.is_empty(),"REWARD peel automatically completes three hits")
 var sequence=preload("res://tests/follow_through_cases.gd").hits(g)
 t.check(sequence.size()==3 and sequence.all(func(hit):return hit.target==a.id) and g._equipment(b.id).durability==6 and g._equipment(c.id).durability==6,"REWARD surviving initial target keeps all three segments")
 t.check(g.state.energy==1 and not g.dispatch(g.command(action.payload,version),version).ok,"REWARD pays once and stale submission cannot replay card")
 g=setup();a=g.add_fixture("wrist",6);b=g.add_fixture("wrist",6);c=g.add_fixture("wrist",6)
 g.state.pressure=95;g.state.pressure_sources=[preload("res://tests/pressure_cases.gd").source("chain_pulse","slip",10)]
 card=give(t,g,"peel");play(t,g,card,"wrist",a.id)
 t.check(preload("res://tests/follow_through_cases.gd").hits(g).size()==3 and g.state.overloaded and g.state.pressure==5 and g.state.card_chain.is_empty() and g.state.overload_count==1,"REWARD pressure pulses once after all three automatic hits")

 # Layered slip follows newly exposed inner piece; no free effect after last removal.
 g=setup();a=g.add_fixture("ankle",1,10,false,0);b=g.add_fixture("ankle",1,10,false,1);card=give(t,g,"peel")
 t.check(play(t,g,card,"ankle",b.id).ok and g._equipment(a.id).is_empty() and g._equipment(b.id).is_empty() and g.state.card_chain.is_empty() and g.state.energy==1,"REWARD two slips recompute newly exposed layer and pay once")
 t.check(not g.state.pending_retain and g.state.next_energy==0,"REWARD bound multihit never switches to free effect")
 g=setup();a=g.add_fixture("ankle",1);card=give(t,g,"peel")
 play(t,g,card,"ankle",a.id)
 t.check(g.state.card_chain.is_empty() and g.state.next_energy==0 and g.state.energy==1,"REWARD missing second target ends remaining effect")

 g=setup();a=g.add_fixture("thigh",4,10,true);b=g.add_fixture("ankle",4,10,true);card=give(t,g,"double_unlock")
 t.check(play(t,g,card,"thigh",a.id).ok and g.state.mana==90 and not g.state.card_chain.is_empty(),"REWARD double unlock pays magic once and offers second lock")
 t.check(t.action(g,"chain",{"target":b.id}).ok and not g._equipment(b.id).locked and g.state.mana==90 and g.state.energy==2,"REWARD second unlock is free and uses actual chosen lock")
 g=setup();g._install_assembly("wrap","left","fixture",1,1);card=give(t,g,"double_unlock")
 var before=JSON.stringify(g.state)
 t.check(play(t,g,card,"thigh").ok and g.state.temporary_mana==5,"REWARD double unlock preparation remains usable with one hand wrapped")

 # Trigger only directly destroyed targets, queue reward after the complete card.
 g=setup();g.state.relics.append("break_bracer");a=g._install_template("rope","calf",1,10,false,"fixture",1,-1,0,"mid_calf");b=g.add_fixture("ankle",1)
 var link=g._install_link(a.id,b.id,8,"fixture",1,[])
 card=give(t,g,"tear");play(t,g,card,"calf",a.id)
 t.check(g.state.charge==1 and g._equipment(link.id).is_empty(),"REWARD bracer grants once for direct destruction, not collateral link")
 g.state.energy=3;card=t.hand_card(g,"strain");play(t,g,card,"ankle",b.id)
 t.check(g.state.charge==0,"REWARD second kill in same player turn cannot grant another charge")
 t.action(g,"end");a=g.add_fixture("wrist",1);card=t.hand_card(g,"strain")
 play(t,g,card,"wrist",a.id)
 t.check(g.state.charge==1,"REWARD bracer refreshes next player turn")

 g=setup();g.state.relics.append("silk_ring");target=g.add_fixture("ankle",7);card=t.hand_card(g,"slip")
 var hand_count=g.state.hand.size();play(t,g,card,"ankle",target.id)
 t.check(not g._equipment(target.id).is_empty() and g.tier(g._equipment(target.id).durability,10)==1 and g.state.hand.size()==hand_count,"REWARD ring draws on actual two-to-one card slip")
 g=setup();g.state.relics.append("silk_ring");target=g.add_fixture("ankle",6);card=t.hand_card(g,"ease")
 hand_count=g.state.hand.size();play(t,g,card,"ankle",target.id)
 t.check(g.state.hand.size()==hand_count-1 and not g.state.relic_used.has("silk_ring:turn"),"REWARD pure downgrade is not card slip damage")
 g=setup();g.state.relics.append("silk_ring");target=g.add_fixture("ankle",1);card=t.hand_card(g,"slip")
 play(t,g,card,"ankle",target.id)
 t.check(g._equipment(target.id).is_empty() and g.state.relic_used.has("silk_ring:turn"),"REWARD direct slip removal triggers ring")
 target=g.add_fixture("wrist",1);card=t.hand_card(g,"slip");hand_count=g.state.hand.size()
 play(t,g,card,"wrist",target.id)
 t.check(g._equipment(target.id).is_empty() and g.state.hand.size()==hand_count-1,"REWARD ring cannot draw twice in one player turn")
 g=setup();g.state.relics.append("silk_ring");target=g.add_fixture("ankle",100,100);card=t.hand_card(g,"slip")
 hand_count=g.state.hand.size();play(t,g,card,"ankle",target.id)
 t.check(g.state.hand.size()==hand_count-1 and not g.state.relic_used.has("silk_ring:turn"),"REWARD blocked tier-three slip without downgrade does not trigger ring")

 g=Game.new(11);g.state.wall="normal";g.state.relics.append("turn_ribbon");g.add_fixture("calf",4)
 var enemy=g.state.enemies[0].id
 t.check(t.action(g,"attack",{"type":"kick","enemy":enemy}).ok and g.state.posture=="lie","REWARD actual bound kick lands")
 var pose=t.find_action(g,"posture",{"dest":"sit","wall":false})
 t.check(pose.valid and pose.cost==0 and pose.detail.contains("缎带"),"REWARD ribbon discounts real adjacent posture candidate")
 t.action(g,"posture",{"dest":"sit","wall":false})
 t.check(g.state.ribbon_tick==-1,"REWARD ribbon consumed even when final fee is zero")


 # A spell begun on the real cell door shares the card pipeline and one payment.
 g=preload("res://tests/prison_cases.gd").intake(t)
 preload("res://tests/prison_cases.gd").clear_fixture(g)
 preload("res://tests/exploration_fixture.gd").at_site(g,"door")
 a=g.add_fixture("thigh",4,10,true);card=give(t,g,"double_unlock");g.state.temporary_mana=5
 var prison_mana=g.state.mana
 t.check(t.action(g,"prison",{"action":"unlock","uid":card.uid}).ok and g.state.prison.door_open and g.state.energy==2 and g.state.temporary_mana==0 and g.state.mana==prison_mana-5,"REWARD door-first double spell shares reserve and one payment")
 t.check(t.action(g,"chain",{"target":a.id}).ok and not g._equipment(a.id).locked and g.state.mana==prison_mana-5 and g.state.card_chain.is_empty(),"REWARD door-first second equipment lock uses same continuation")
 g=preload("res://tests/prison_cases.gd").intake(t)
 preload("res://tests/prison_cases.gd").clear_fixture(g)
 preload("res://tests/exploration_fixture.gd").at_site(g,"door")
 a=g.add_fixture("thigh",4,10,true);card=give(t,g,"double_unlock")
 prison_mana=g.state.mana
 play(t,g,card,"thigh",a.id)
 t.check(t.action(g,"chain",{"target":"prison_door"}).ok and g.state.prison.door_open and g.state.energy==2 and g.state.mana==prison_mana-10,"REWARD equipment-first spell can open cell door as second lock")
 g=setup();a=g.add_fixture("thigh",4,10,true);b=g.add_fixture("ankle",4,10,true);card=give(t,g,"double_unlock")
 play(t,g,card,"thigh",a.id)
 t.check(t.action(g,"chain",{"action":"stop"}).ok and g._equipment(b.id).locked and g.state.energy==2 and g.state.mana==90,"REWARD optional second unlock stops without refund or additional changes")

 g=Game.new(42,true,"guard");g.RelicEffects.gain(g,"cursed_blindfold");g.RelicEffects.gain(g,"cursed_plate_lock");g.state.relics=g.Relics.TYPES.keys()
 a=g.add_fixture("ankle",6);card=give(t,g,"focus");play(t,g,card,"ankle",a.id)
 preload("res://tests/guard_cases.gd").ready(g)
 t.check(t.action(g,"end").ok and g.state.phase=="captured" and g.state.relics.size()==g.Relics.TYPES.size() and g.state.charge==0 and g.state.card_chain.is_empty() and g.state.relic_pending.is_empty(),"REWARD actual capture keeps all relics and clears temporary effects")

 # Invalid continuation is rejected before any damage or cleanup can occur.
 g=setup();g.state.card_chain={"type":"chain","slot":"wrist","remaining":99,"mode":"strain"}
 before=JSON.stringify(g.state)
 t.check(not g.dispatch(g.command({"kind":"card","uid":"anything"},g.state.version),g.state.version).ok and JSON.stringify(g.state)==before,"REWARD malformed multihit rejected atomically")

static func reward_sampling(t) -> void:
 var rules=Game.Cards.Rules
 for unlocked in [false,true]:
  # Reachability covers the declared pool, independently of eligible().
  var expected=rules.REWARDS.filter(func(id):return unlocked or rules.SPECS[id].get("reward_pool","")=="")
  var context="unlocked" if unlocked else "locked"
  var observed={}
  for seed_value in range(maxi(32,rules.REWARDS.size()*8)):
   var g=Game.new(seed_value);var twin=Game.new(seed_value)
   if unlocked:
    for id in rules.REWARD_POOL_RELICS.values():
     g.RelicEffects.gain(g,id);twin.RelicEffects.gain(twin,id)
   var before=g.state.rng.duplicate()
   var offer=g.reward_offer(rules.REWARDS)
   t.check(offer.size()==3 and offer.all(func(id):return offer.count(id)==1 and id in expected),"REWARD unique sample obeys declared pool gates: "+context)
   var unrelated=g.state.rng.duplicate();unrelated.reward=before.reward
   t.check(unrelated==before and g.state.rng.reward>before.reward,"REWARD sampling advances only its own random domain: "+context)
   t.check(offer==twin.reward_offer(rules.REWARDS),"REWARD seed reproduces sample: "+context)
   for id in offer: observed[id]=true
   if seed_value>=31 and expected.all(func(id):return observed.has(id)): break
  for id in expected:
   t.check(observed.has(id),"REWARD configured card reachable in actual sampling: "+context+" / "+id)

static func draw_faces(t) -> void:
 var g=Game.new(42)
 g.state.hand=[];g.state.draw=[g._make_card("strain"),g._make_card("slip")]
 g._draw(2)
 t.check(g.state.hand.all(func(c):return c.draw_free),"DRAW no equipment draws escape cards free-side")
 var first=g.state.hand[0];var serial=first.draw_serial
 var e=g.add_fixture("ankle",10)
 g.state.wall="normal"
 g.state.energy=0;g.state.mana=0
 g.state.draw=g.state.hand.duplicate(true);g.state.hand=[];g._draw(2)
 t.check(g.state.hand.filter(func(c):return c.type=="strain")[0].draw_free==false and g.state.hand.filter(func(c):return c.type=="slip")[0].draw_free,"DRAW tier-three immunity leaves slip free-side, low energy does not hide strain target")
 t.check(g.state.hand.all(func(c):return c.draw_serial>serial),"DRAW redraw gives each card a fresh presentation serial")
 e.durability=4;g.state.draw=g.state.hand.duplicate(true);g.state.hand=[];g._draw(2)
 t.check(g.state.hand.all(func(c):return not c.draw_free),"DRAW loose legal target draws both methods bound-side")
 g.state.equipment=[];g.add_fixture("eyes",4)
 t.check(not g.Cards.has_escape_target(g,"strain") and g.Cards.has_escape_target(g,"slip"),"DRAW eyes support slip only")
 g.add_fixture("mouth",4)
 t.check(g.Cards.has_escape_target(g,"ease"),"DRAW reduced mouth probability retains a real spell route")

# New IDs and changed counts exercise the shared interfaces, not existing-name branches.
static func configured_effects(t) -> void:
 var g=setup()
 var cards=g.Cards.Rules.SPECS.duplicate(true)
 var names=g.B.CARD_NAMES.duplicate(true)
 var info=g.B.CARD_INFO.duplicate(true)
 var relics=g.Relics.TYPES.duplicate(true)
 for pair in [["test_triple","double_unlock"],["test_retainer","focus"],["test_power","brace"]]:
  g.Cards.Rules.SPECS[pair[0]]=cards[pair[1]].duplicate(true)
  g.B.CARD_NAMES[pair[0]]="接口测试牌"
  g.B.CARD_INFO[pair[0]]=info[pair[1]].duplicate(true)
 g.Cards.Rules.SPECS.test_triple.hits=3
 g.Cards.Rules.SPECS.test_retainer.self_faces.free.effects=[{"op":"retain","amount":3,"draw_after":2}]
 g.Cards.Rules.SPECS.test_power.free_effects=[{"op":"charge","amount":3},{"op":"next_energy","amount":2}]
 var a=g.add_fixture("thigh",4,10,true)
 var b=g.add_fixture("ankle",4,10,true)
 var c=g.add_fixture("wrist",4,10,true)
 var card=give(t,g,"test_triple")
 t.check(play(t,g,card,"thigh",a.id).ok and g.state.card_chain.get("remaining")==2 and g.state.play.size()==1 and g.state.play[0].uid==card.uid and not g.state.discard.any(func(item):return item.uid==card.uid),"CONFIG new ID keeps its physical card in play until all three segments finish")
 var saved=g.state.duplicate(true)
 t.check(g.restore_snapshot(saved).ok and g.state.card_chain.get("remaining")==2 and g.state.play.size()==1,"CONFIG three-segment continuation restores with its resolving card")
 var invalid=g.export_snapshot();invalid.play=[];var stable=g.export_snapshot()
 t.check(not g.restore_snapshot(invalid).ok and g.state==stable,"CONFIG pending continuation without its resolving card is rejected atomically")
 t.check(t.action(g,"chain",{"target":b.id}).ok and t.action(g,"chain",{"target":c.id}).ok and g.state.card_chain.is_empty() and g.state.play.is_empty() and g.state.discard.any(func(item):return item.uid==card.uid) and g.state.mana==90 and g.state.energy==2,"CONFIG all three locks share one payment and discard only after the final segment")
 g=setup();a=g.add_fixture("thigh",4,10,true);b=g.add_fixture("ankle",4,10,true);card=give(t,g,"test_triple")
 t.check(play(t,g,card,"thigh",a.id).ok and not g.state.card_chain.is_empty(),"CONFIG interruption fixture starts a pending card")
 g.Pressure.gain(g,g.Pressure.maximum(g),"测试干扰")
 t.check(g.state.card_chain.is_empty() and g.state.play.is_empty() and g.state.discard.any(func(item):return item.uid==card.uid) and g.validate()=="","CONFIG climax interruption settles the resolving card without losing its physical instance")
 g=setup();card=give(t,g,"test_retainer")
 t.check(play(t,g,card,"thigh").ok and g.state.retain_left==3,"CONFIG retain count is not limited to two")
 saved=g.state.duplicate(true)
 t.check(g.restore_snapshot(saved).ok,"CONFIG configured retain pending state restores")
 var hand_count=g.state.hand.size()
 for index in range(3):
  var selected=g.state.hand.filter(func(item):return item.retain_until<0)[0]
  t.check(t.action(g,"retain",{"uid":selected.uid}).ok,"CONFIG retain selection "+str(index))
 t.check(not g.state.pending_retain and g.state.hand.size()==hand_count+2,"CONFIG deferred draw reads configured count")
 g=setup();card=give(t,g,"test_power")
 t.check(play(t,g,card,"thigh").ok and g.state.charge==3 and g.state.next_energy==2,"CONFIG new card ID executes ordered free effects")
 # Hand effects follow the real hand; no cached bonus survives removal or save restore.
 g=setup();a=g.add_fixture("ankle",4)
 var base=g.escape_preview(a,"strain",5).damage
 g.Cards.Rules.SPECS.test_power.hand_modifiers={"strength":2.0}
 card=give(t,g,"test_power")
 t.check(g.escape_preview(a,"strain",5).damage>base and g.get_view().statuses.any(func(row):return row.id=="strength" and row.detail.contains("手牌2")),"CONFIG in-hand modifier affects actual preview and merged attribute projection")
 saved=g.state.duplicate(true)
 t.check(play(t,g,card,"thigh").ok and g.Cards.hand_modifier(g,"strength")==0,"CONFIG played card immediately loses hand modifier")
 t.check(g.restore_snapshot(saved).ok and g.Cards.hand_modifier(g,"strength")==2,"CONFIG restored hand derives modifier without extra state")
 g.Cards.Rules.SPECS.test_power.hand_modifiers.strength=-100.0
 t.check(g.escape_preview(g._equipment(a.id),"strain",5).damage>=0,"CONFIG negative in-hand modifier cannot turn damage into repair")
 g.Cards.Rules.SPECS.test_power.free_effects=[{"op":"unsupported","amount":1}]
 var before=g.state.duplicate(true)
 t.check(not g.dispatch(g.command({"kind":"card","uid":"anything"},g.state.version),g.state.version).ok and g.state==before,"CONFIG unsupported operation rejected without mutation")
 g.Cards.Rules.SPECS=cards;g.B.CARD_NAMES=names;g.B.CARD_INFO=info
 for pair in [["test_charge","break_bracer"],["test_mana","ember_crystal"],["test_pose","turn_ribbon"]]:
  g.Relics.TYPES[pair[0]]=relics[pair[1]].duplicate(true)
  g.Relics.TYPES[pair[0]].name="测试遗物"
 g.Relics.TYPES.test_charge.trigger.amount=2
 g=setup();g.state.relics=["test_charge"];a=g.add_fixture("wrist",1);card=t.hand_card(g,"strain")
 t.check(play(t,g,card,"wrist",a.id).ok and g.state.charge==2 and g.RelicEffects.used(g,"test_charge"),"CONFIG renamed relic triggers its configured amount")
 t.check(g.get_view().relics.any(func(row):return row.id=="test_charge" and row.current.contains("本次机会已使用")) and g.get_view().statuses.all(func(row):return row.category!="relic"),"CONFIG relic trigger scope is shown only in the relic projection")
 a=g.add_fixture("wrist",1);card=give(t,g,"strain");play(t,g,card,"wrist",a.id)
 t.check(g.state.charge==1,"CONFIG renamed relic does not regrant charge consumed by the next strain")
 g=Game.new(12);g.state.relics=["test_mana"];g.state.mana=60
 t.check(t.action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id}).ok and g.state.mana==50 and g.RelicEffects.used(g,"test_mana"),"CONFIG renamed guarantee relic uses its own turn record")
 g=Game.new(11);g.state.wall="normal";g.state.relics=["test_pose"];g.add_fixture("calf",4)
 t.action(g,"attack",{"type":"kick","enemy":g.state.enemies[0].id})
 var pose=t.find_action(g,"posture",{"dest":"sit","wall":false})
 t.check(pose.valid and pose.cost==0 and pose.detail.contains("测试遗物"),"CONFIG renamed posture relic affects candidate and text")
 before=g.state.duplicate(true);saved=before.duplicate(true)
 saved.relic_pending={"test_pose":{"op":"mana","amount":10.0}}
 t.check(not g.restore_snapshot(saved).ok and g.state==before,"CONFIG mismatched deferred relic effect rejected atomically")
 g.Relics.TYPES=relics

static func hand_limit(t) -> void:
 var g=setup()
 for index in range(12): g._gain_card("strain")
 g._draw(4)
 t.check(g.state.hand.size()==9,"HAND nine-card boundary")
 var available=g.state.draw.size()+g.state.discard.size()
 g._draw(4)
 t.check(g.state.hand.size()==10 and g.state.draw.size()+g.state.discard.size()==available-1,"HAND draws only available hand space")
 var rng=g.state.rng.duplicate(true)
 var serial=g.state.draw_serial
 g.state.discard.append_array(g.state.draw);g.state.draw.clear()
 var discard=g.state.discard.duplicate(true)
 g._draw(3)
 t.check(g.state.hand.size()==10 and g.state.draw.is_empty() and g.state.discard==discard and g.state.rng==rng and g.state.draw_serial==serial,"HAND full hand never draws discards or shuffles")
 var card=g.state.hand[0]
 t.check(play(t,g,card,"thigh").ok,"HAND full hand can play a card")
 g._draw(2)
 t.check(g.state.hand.size()==10,"HAND newly freed space can be refilled")
 var saved=g.state.duplicate(true)
 t.check(g.restore_snapshot(saved).ok,"HAND ten-card save restores")
 saved=g.state.duplicate(true)
 saved.hand.append(saved.discard.pop_back() if not saved.discard.is_empty() else saved.draw.pop_back())
 var before=g.state.duplicate(true)
 t.check(not g.restore_snapshot(saved).ok and g.state==before,"HAND oversized save rejected without mutation")

static func resource_feedback(t) -> void:
 var g=Game.new(42)
 g.state.mana=60
 for enemy in g.state.enemies: enemy.hp=0;enemy.gone=true
 g.state.enemies[0].hp=1;g.state.enemies[0].gone=false
 var result=t.action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})
 t.check(result.ok and g.state.phase=="reward" and g.state.mana==50,"FX lethal spell commits payment before preparation ends")
 var mana=result.get("resource_feedback",[]).filter(func(event):return event.field=="mana")
 t.check(mana.size()==1 and mana[0].before==60 and mana[0].after==50,"FX lethal spell receipt contains actual mana payment")
 t.action(g,"reward",{"type":"skip"})
 result=t.action(g,"finish_prepare")
 mana=result.get("resource_feedback",[]).filter(func(event):return event.field=="mana")
 t.check(result.ok and g.state.mana==60 and mana.size()==1 and mana[0].before==50 and mana[0].after==60 and mana[0].source==g.Relics.TYPES.ember.name and g._resource_feedback==null,"FX preparation ending reports recovery with structured relic source and clears receipt")
 var before=g.state.duplicate(true)
 result=g.dispatch(g.command({"kind":"card","uid":"invalid"},g.state.version),g.state.version)
 t.check(not result.ok and not result.has("resource_feedback") and g.state==before,"FX rejected action has no visual receipt")

static func card_feedback(t) -> void:
 var g=setup()
 g.state.discard.append_array(g.state.draw);g.state.draw.clear()
 var before=g.export_snapshot()
 var result=t.action(g,"end")
 var events=result.get("card_feedback",[])
 var kinds=events.map(func(event):return event.kind)
 t.check(result.ok and "discard" in kinds and "shuffle" in kinds and "draw" in kinds and kinds.find("discard")<kinds.find("shuffle") and kinds.find("shuffle")<kinds.find("draw"),"CARD FX preserves discard shuffle draw order even for returning cards")
 t.check(events.filter(func(event):return event.kind=="draw").size()==g.state.hand.size(),"CARD FX records only cards actually drawn")
 var stable=g.export_snapshot()
 var rejected=g.dispatch(g.command({"kind":"card","uid":"missing"},g.state.version),g.state.version)
 t.check(not rejected.ok and not rejected.has("card_feedback") and g.state==stable,"CARD FX rejected action cannot leak or replay transfers")
 var card=g.state.hand[0]
 result=t.action(g,"card",{"uid":card.uid,"free":true})
 t.check(result.ok and result.card_feedback.any(func(event):return event.kind=="play" and event.uid==card.uid),"CARD FX play receipt identifies actual UID")
 g=setup()
 card=give(t,g,"panic")
 result=t.action(g,"card",{"uid":card.uid})
 t.check(result.ok and result.card_feedback.any(func(event):return event.kind=="play_exhaust" and event.uid==card.uid) and g.state.exhaust.any(func(c):return c.uid==card.uid),"CARD FX consumable card uses actual exhaust destination")
 var retained=give(t,g,"sensitive")
 result=t.action(g,"end")
 t.check(result.ok and result.card_feedback.any(func(event):return event.kind=="retain" and event.uid==retained.uid) and g.state.hand.any(func(c):return c.uid==retained.uid),"CARD FX retained card stays in hand and is marked separately")
