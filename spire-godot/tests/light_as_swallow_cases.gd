extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const BUFF="light_as_swallow_bound"

static func setup():
 var g=Game.new(42);g.state.energy=12;g.state.wall="normal"
 return g

static func run(t) -> void:
 var g=setup();var card=Give.give(g,"light_as_swallow")
 var action=t.find_action(g,"card",{"uid":card.uid,"free":true});var before=g.export_snapshot()
 t.check(action.valid and action.cost==1 and action.mana==0 and "light_as_swallow" in g.Cards.Rules.RARE,"SWALLOW rare skill uses one energy with no spell cost")
 t.check(not g.dispatch(g.command(action.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SWALLOW stale play cannot grant evasion")
 t.check(g.dispatch(g.command(action.payload,g.state.version),g.state.version).ok and g.state.evasion==2 and g.state.energy==11,"SWALLOW free face grants two evasion")
 t.check(Give.play(t,g,"light_as_swallow",true).ok and g.state.evasion==4,"SWALLOW evasion accumulates")
 g.add_fixture("ankle",4);card=Give.give(g,"light_as_swallow");before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"SWALLOW restrained legs block only free face")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and BUFF in g.state.card_buffs,"SWALLOW bound face works with restrained legs")
 g._finish_battle()
 t.check(g.state.evasion==4 and BUFF in g.state.card_buffs,"SWALLOW both effects survive victory")
 t.action(g,"reward",{"type":"skip"});t.action(g,"finish_prepare")
 t.check(g.state.evasion==0 and BUFF not in g.state.card_buffs,"SWALLOW both effects end with this session")
 evasion(t)
 damage(t)

static func evasion(t) -> void:
 var g=setup();Give.play(t,g,"light_as_swallow",true)
 var control=setup();Give.play(t,control,"light_as_swallow",true);control.state.evasion=0
 var spec={"pool":"ordinary","templates":["rope"],"grade":1,"tier":2,"count":3}
 var before=g.export_snapshot();g.Application.can_apply(g,spec,"enemy");g.get_view();g.command_facts()
 t.check(g.state==before,"SWALLOW application and UI queries preserve evasion and randomness")
 var result=g.Application.execute(g,spec,"enemy")
 var once=spec.duplicate();once.count=1
 var expected=control.Application.execute(control,once,"enemy")
 t.check(result.count==1 and result.evaded==2 and g.state.evasion==0 and result.installed==expected.installed and g.state.rng==control.state.rng,"SWALLOW dodged attempts reserve no position or random draws; survivor uses current priority")
 g=setup();Give.play(t,g,"light_as_swallow",true)
 var old=g.add_fixture("mouth",4)
 var empty={"pool":"ordinary","templates":[],"count":1}
 t.check(not g.Application.execute(g,empty,"enemy").ok and g.state.evasion==2,"SWALLOW no possible application spends no evasion")
 var request={"kind":"install","template":"mouth_band","slot":"mouth","grade":2,"tier":2,"variant":0}
 before=g.export_snapshot()
 result=g.Application.execute_concrete(g,request,"enemy",true)
 t.check(result.evaded==1 and g._equipment(old.id).durability==4 and g.state.equipment==before.equipment and g.state.next_equipment==before.next_equipment,"SWALLOW replacement is blocked before removing old equipment or allocating new ids")
 g=setup();g.state.evasion=1
 result=g.Application.execute_concrete(g,{"kind":"assembly","family":"glove","variant":"short","grade":2,"tier":2},"enemy")
 t.check(result.evaded==1 and g.state.composites.is_empty() and g.state.evasion==0,"SWALLOW composite counts as one whole application")
 g=setup();g.state.evasion=1
 result=g.Application.execute_concrete(g,{"kind":"special_install","type":"vaginal_egg_low","slot":"special_3_a","grade":1,"tier":2},"enemy")
 t.check(result.evaded==1 and g.state.special_equipment.is_empty(),"SWALLOW special restraint uses same evasion")
 g=setup();g.state.evasion=2
 var target=g.add_fixture("wrist",4);var enemy=g.state.enemies[0]
 g._enemy_operation(enemy,{"kind":"apply","pool":"ordinary","templates":["rope"],"grade":1,"tier":2,"count":2,"tighten_missing":true,"text":"施加","delayed":false})
 t.check(g.state.evasion==0 and g._equipment(target.id).durability==4 and g.state.equipment.size()==1,"SWALLOW evaded application cannot fall back to reinforcement")
 g=setup();g.state.evasion=1
 var linked=g.add_fixture("wrist",4)
 g._enemy_operation(g.state.enemies[0],{"kind":"tighten","target":linked.id,"tier":2,"text":"加固","delayed":false})
 t.check(g.state.evasion==1 and g._equipment(linked.id).durability>4,"SWALLOW reinforcement is not an application")

static func damage(t) -> void:
 var g=setup();var target=g.add_fixture("wrist",70,100)
 var card=Give.give(g,"slip")
 var ordinary=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 var passive=g.escape_preview(target,"slip",5,[],true).damage
 t.check(Give.play(t,g,"light_as_swallow",false).ok,"SWALLOW prepare next card slip")
 var buffed=t.find_action(g,"card",{"uid":card.uid,"target":target.id});var before=g.export_snapshot()
 t.check(is_equal_approx(buffed.payload.preview.damage,ordinary.payload.preview.damage*2) and g.escape_preview(target,"slip",5,[],true).damage==passive and g.state==before,"SWALLOW doubles card preview without changing passive slip or state")
 t.check(g.dispatch(g.command(buffed.payload,g.state.version),g.state.version).ok and BUFF not in g.state.card_buffs and is_equal_approx(g._equipment(target.id).durability,70-buffed.payload.preview.damage),"SWALLOW actual hit consumes buff once")
 g=setup();target=g.add_fixture("wrist",100,100);Give.play(t,g,"light_as_swallow",false)
 card=Give.give(g,"slip")
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and BUFF in g.state.card_buffs,"SWALLOW zero-damage immune slip preserves buff")
 g.state.pressure=80;g.state.rng.magic=0;card=Give.give(g,"magic_slip")
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and g.state.hand.any(func(c):return c.uid==card.uid) and BUFF in g.state.card_buffs,"SWALLOW failed spell preserves next slip")
 g=setup();target=g.add_fixture("wrist",70,100);Give.play(t,g,"light_as_swallow",false)
 g.state.card_buffs.append("henshin_free");card=Give.give(g,"slip")
 var p=t.find_action(g,"card",{"uid":card.uid,"target":target.id}).payload.preview
 t.check(p.damage_buff_multiplier==4,"SWALLOW multiplies independently with other damage buffs")
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and "henshin_free" in g.state.card_buffs and BUFF not in g.state.card_buffs,"SWALLOW consuming next slip preserves other source buffs")

 g=setup();target=g.add_fixture("wrist",700,1000);Give.play(t,g,"light_as_swallow",false)
 card=Give.give(g,"peel");before=g.state.logs.size()
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok,"SWALLOW multihit card commits")
 var hits=g.state.logs.slice(before).filter(func(log):return log.data.has("follow_through_hit"))
 t.check(hits.size()==3 and hits[0].data.damage_buff_multiplier==2 and hits[1].data.damage_buff_multiplier==1 and hits[2].data.damage_buff_multiplier==1,"SWALLOW only the first actual multihit damage consumes the next-hit effect")
 g=setup()
 var F=preload("res://tests/follow_through_cases.gd")
 target=F.piece(g,"thigh","above_knee",40,100)
 var peer=F.piece(g,"thigh","mid_thigh",40,100)
 Give.play(t,g,"light_as_swallow",false);card=Give.give(g,"slip")
 var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 var choices=g.Cards.Splash.options(g,c.payload)
 t.check(choices.size()==1 and choices[0][0].preview.damage_buff_multiplier==2,"SWALLOW splash preview includes the same hit multiplier")
 var expected=choices[0][0].preview.damage
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(peer.id).durability,40-expected) and BUFF not in g.state.card_buffs,"SWALLOW whole first hit includes collateral then consumes once")
