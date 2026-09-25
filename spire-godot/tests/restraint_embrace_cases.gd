extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Replace=preload("res://tests/replacement_cases.gd")
const TYPE="restraint_embrace"
const BOUND="restraint_embrace_bound"

static func fresh():
 var g=Game.new(42);g._discard_end();g.state.energy=50;g.state.wall="normal"
 return g

static func activate(t,g,free: bool) -> Dictionary:
 var card=Cards.give(g,TYPE)
 var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(c.valid and c.cost==(2 if free else 1) and c.mana==0 and g.state==before,"EMBRACE both face costs and read-only preview")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"EMBRACE stale activation rejects atomically")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==before.energy-c.cost and g.state.powers.any(func(p):return p.uid==card.uid),"EMBRACE formal activation moves one card into persistent ability zone")
 return card

static func pending(g) -> int:
 return g.Cards.pending_draw(g,BOUND)

static func run(t) -> void:
 var g=fresh();g.add_fixture("ankle",1)
 var free=activate(t,g,true);var bound=activate(t,g,false)
 t.check(TYPE in g.Cards.Rules.UNCOMMON and g.Cards.Rules.SPECS[TYPE].rarity=="uncommon" and pending(g)==0,"EMBRACE uncommon pool registration and no retroactive equipment count")
 var copy=Cards.give(g,TYPE);var before=g.export_snapshot()
 var repeated=t.find_action(g,"card",{"uid":copy.uid,"free":true})
 t.check(repeated.valid and not g.dispatch(g.command(repeated.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"EMBRACE repeat is available but stale activation rejects without payment")
 var target=g.state.equipment[0];var slip=Cards.give(g,"slip")
 var energy=g.state.energy
 var result=t.action(g,"card",{"uid":slip.uid,"target":target.id,"free":false})
 t.check(result.ok and g._equipment(target.id).is_empty() and g.state.hand.size()==before.hand.size()+1 and result.card_feedback.filter(func(e):return e.kind=="draw").size()==1,"EMBRACE actual escape draws once after the paid card leaves hand")
 var serial=g.state.draw_serial;g._cleanup();g._cleanup()
 t.check(g.state.energy==energy,"EMBRACE one release refunds one energy after the one-energy slip, cleanup cannot repeat it")
 t.check(g.state.draw_serial==serial and pending(g)==0,"EMBRACE repeated cleanup never recounts released roots")

 # New equipment is counted on installation; remaining equipped after a turn is not another event.
 var ordinary=g.add_fixture("wrist",4)
 var root=g._install_assembly("leg","upper","fixture",2,1)
 t.check(not root.is_empty() and root.components.size()>1 and pending(g)==2,"EMBRACE ordinary plus multi-component assembly each count once")
 var current=pending(g);ordinary.durability=8;g._refresh_equipment(ordinary)
 t.check(pending(g)==current and g.state.draw_serial==serial,"EMBRACE plain reinforcement and repaired durability do not count as new equipment")
 before=g.export_snapshot();g.get_view();g.command_facts()
 var status=g.get_view().statuses.filter(func(row):return row.id=="power_"+BOUND)[0]
 t.check(g.state==before and status.badge=="2" and status.value=="下回合抽牌＋2" and status.duration=="本场整备结束","EMBRACE pending count lives on the persistent status icon")
 var twin=Save.roundtrip(t,g,"embrace pending draws")
 if twin!=null:
  Save.step_both(t,g,twin,"end")
  t.check(pending(g)==0 and g.state.powers.size()==2 and g.state.logs.any(func(log):return log.data.get("power_trigger",{}).get("id","")==BOUND and log.data.has("power_draw")),"EMBRACE next real turn consumes pending draw count but keeps ability active")
  g.add_fixture("calf",4,10,false,0,"rope")
  t.check(pending(g)==1,"EMBRACE later turns continue to schedule new equipment draws")
 var bad=g.export_snapshot()
 bad.powers.filter(func(p):return p.uid==bound.uid)[0].power_next_draw=-1
 before=g.export_snapshot()
 t.check(not g.restore_snapshot(bad).ok and g.state==before,"EMBRACE invalid pending count cannot alter current snapshot")
 g.RelicEffects.end_combat(g)
 t.check(g.state.powers.is_empty() and pending(g)==0 and g.state.discard.all(func(card):return not card.has("power_next_draw")),"EMBRACE ending session removes both abilities and unspent pending draws")
 g.RelicEffects.begin_combat(g);g._begin_player_turn()
 t.check(pending(g)==0 and g.state.powers.is_empty(),"EMBRACE next battle has no lingering triggers")
 bulk_release(t)
 replacement(t)
 full_hand(t)
 stacked_energy(t)

static func stacked_energy(t) -> void:
 var g=fresh()
 var first=activate(t,g,true);activate(t,g,true)
 # Replay stacks and separate physical copies both add draws and energy.
 g.state.powers.filter(func(card):return card.uid==first.uid)[0].power_stacks=3
 for i in range(20): g.state.draw.append(Cards.give(g,"strain"));g.state.hand.erase(g.state.draw.back())
 var root=g._install_assembly("glove","short","fixture",2,1)
 var energy=g.state.energy;var serial=g.state.draw_serial
 var strap=root.components.filter(func(part):return part.part!="body")[0]
 g._apply_manual_release(strap,0);g._cleanup()
 t.check(g.state.energy==energy and g.state.draw_serial==serial,"EMBRACE partial composite removal grants neither cards nor energy")
 var target=g.add_fixture("ankle",1)
 g._apply_manual_release(target,0);g._cleanup()
 t.check(g.state.energy==energy+4 and g.state.draw_serial==serial+4,"EMBRACE four stacks across two cards grant four cards and four energy")
 var status=g.get_view().statuses.filter(func(row):return row.id=="power_restraint_embrace_free")[0]
 t.check(status.value=="每件抽4张 · 能量＋4" and status.detail.contains("抽牌与回能均可叠加"),"EMBRACE status shows stacked draws and energy")
 while g.state.hand.size()<g.B.HAND_LIMIT: Cards.give(g,"strain")
 target=g.add_fixture("ankle",1);energy=g.state.energy;serial=g.state.draw_serial
 g._apply_manual_release(target,0);g._cleanup();g._cleanup()
 t.check(g.state.energy==energy+4 and g.state.draw_serial==serial,"EMBRACE full hand still gains stacked energy, repeated cleanup cannot duplicate it")
 g.Cards.end_powers(g);energy=g.state.energy
 target=g.add_fixture("ankle",1);g._apply_manual_release(target,0);g._cleanup()
 t.check(g.state.energy==energy,"EMBRACE ended power grants no release energy")

static func bulk_release(t) -> void:
 var g=fresh();activate(t,g,true)
 var root=g._install_assembly("glove","short","fixture",2,1)
 var serial=g.state.draw_serial
 var strap=root.components.filter(func(part):return part.part!="body")[0]
 g._apply_manual_release(strap,0);g._cleanup()
 t.check(g.state.composites.size()==1 and g.state.draw_serial==serial,"EMBRACE removing only a component does not count the whole composite")
 g.add_fixture("ankle",4)
 var expected=g.Cards.restraint_roots(g).size()
 t.check(expected==2 and root.components.size()>1,"EMBRACE release fixture has two roots despite many components")
 var card=Cards.give(g,"henshin")
 var energy=g.state.energy
 var result=t.action(g,"card",{"uid":card.uid,"free":false})
 t.check(result.ok and g.Cards.restraint_roots(g).is_empty() and result.card_feedback.filter(func(e):return e.kind=="draw").size()==expected,"EMBRACE batch release draws per whole physical restraint, not per component")
 t.check(g.state.energy==energy-g.Cards.Rules.energy_cost("henshin",false)+expected,"EMBRACE batch release grants one energy per physical root")
 g=fresh();activate(t,g,true);activate(t,g,false)
 var forearm=Replace.install(g,Replace.request("forearm",1,1,"mid_forearm"))
 var wrist=Replace.install(g,Replace.request("wrist",1,1))
 var link=g._install_link(forearm.id,wrist.id,4,"fixture",1,[],["forearm","wrist"],["mid_forearm","wrist"])
 t.check(not link.is_empty() and pending(g)==3,"EMBRACE independent link installation counts once alongside its two anchors")
 serial=g.state.draw_serial;g._apply_manual_release(link,0);g._cleanup()
 t.check(g.state.links.is_empty() and g.state.draw_serial==serial+1 and g.state.equipment.size()==2,"EMBRACE releasing link draws once without recounting surviving anchors")

static func replacement(t) -> void:
 var g=fresh();Replace.fill(g,"wrist")
 activate(t,g,true);activate(t,g,false)
 var before=g.export_snapshot()
 var plan=Replace.Replacement.plan(g,[Replace.request("wrist",2,2)],"fixture")
 t.check(plan.ok and g.state==before and pending(g)==0,"EMBRACE replacement preview cannot draw or schedule cards")
 if not plan.ok: return
 t.check(Replace.Replacement.execute(g,plan).ok and pending(g)==1 and g.state.hand==before.hand and g.state.draw==before.draw and g.state.energy==before.energy,"EMBRACE replacement counts newly worn piece but never grants escape draws or energy")
 before=g.export_snapshot()
 t.check(not Replace.Replacement.execute(g,plan).ok and g.state==before,"EMBRACE repeated replacement cannot duplicate pending benefit")

static func full_hand(t) -> void:
 var g=fresh();activate(t,g,true);activate(t,g,false)
 g.add_fixture("ankle",4)
 var card=Cards.give(g,"henshin")
 while g.state.hand.size()<g.B.HAND_LIMIT: Cards.give(g,"strain")
 var result=t.action(g,"card",{"uid":card.uid,"free":false})
 t.check(result.ok and g.state.hand.size()==g.B.HAND_LIMIT and pending(g)==1,"EMBRACE immediate release uses the slot vacated by played card at hand limit")
 while g.state.draw.size()<15: g._gain_card("strain");g.state.draw.append(g.state.discard.pop_back())
 g.Cards.begin_turn(g)
 t.check(g.state.hand.size()==10 and pending(g)==0,"EMBRACE full hand consumes scheduled draw without overflow or postponement")
 var size=g.state.draw.size();g.Cards.begin_turn(g)
 t.check(g.state.draw.size()==size and g.state.powers.size()==2,"EMBRACE pending draw is paid once while both powers persist")
