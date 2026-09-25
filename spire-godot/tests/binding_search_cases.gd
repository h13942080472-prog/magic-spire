extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const TYPE="binding_search"

static func setup():
 var g=Game.new(42)
 g._discard_end();g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[]
 g.state.relics=[];g.state.energy=20;g.state.mana=100;g.state.pressure=0
 return g

static func run(t) -> void:
 var g=setup();var spec=g.Cards.Rules.SPECS[TYPE]
 t.check(TYPE in g.Cards.Rules.UNCOMMON and g.Cards.Rules.definition_reason(spec)=="" and g.Cards.Rules.type_tags(TYPE)==["magic","skill"],"BIND SEARCH uncommon magic skill is registered in rewards")
 var source=Give.give(g,TYPE)
 for free in [false,true]:
  var c=t.find_action(g,"card",{"uid":source.uid,"free":free})
  t.check(c.valid and c.cost==1 and c.mana==10 and g.Cards.cast_profile(g,TYPE).parts==["none"],"BIND SEARCH both faces cost one energy and ten mana with no casting limb")
 var slots=["eyes","mouth","wrist","thigh","calf","ankle"]
 for count in range(7):
  g=setup();source=Give.give(g,TYPE)
  for slot in slots.slice(0,count): g.add_fixture(slot,8)
  var before=g.export_snapshot()
  var c=t.find_action(g,"card",{"uid":source.uid,"free":false})
  var text=g.Cards.metadata(g,TYPE,source.uid).face_effects.bound
  t.check(g.Cards.occupied_body_count(g)==count and text.contains("抽%d张牌" % int(count/2)) and text.contains("X＝%d" % count),"BIND SEARCH live card and count cover floor boundary "+str(count))
  g.get_view();g.command_facts()
  t.check(g.export_snapshot()==before,"BIND SEARCH preview never advances random or changes resources")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==before,"BIND SEARCH stale play rolls back fully")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.hand.size()==int(count/2) and g.state.energy==19 and g.state.mana==90,"BIND SEARCH bound dispatch draws exact floor and pays once")
 g=setup();var palm=g.add_fixture("palm",8);palm.side="left"
 g.add_fixture("palm",8);g.add_fixture("fingers",8);g.add_fixture("foot",8);g.add_fixture("toes",8)
 g._install_special("nipple_ring_low","special_1_a");g._install_special("shaft_ring_low","special_2_a")
 t.check(g.Cards.occupied_body_count(g)==2,"BIND SEARCH hands and feet merge sides, subslots and layers; intimate equipment never counts")
 g=setup();palm=g.add_fixture("palm",8);palm.side="left"
 t.check(g.Cards.occupied_body_count(g)==1 and not g.occupied("palm"),"BIND SEARCH one covered hand side counts even though the other remains free")
 g=setup();var maximum=g.Equipment.maximum(2)
 var host=g._install_template("rope","upper_arm",maximum,maximum,false,"fixture",2)
 var shoulders=g.Shoulders.attached(g,host)
 t.check(shoulders.size()==2 and g.Cards.occupied_body_count(g)==2,"BIND SEARCH both shoulder straps count neck-shoulder once alongside upper arm")
 shoulders[0].durability=0
 t.check(g.Cards.occupied_body_count(g)==2,"BIND SEARCH one remaining shoulder still counts its sidebar area")
 shoulders[1].durability=0
 t.check(g.Cards.occupied_body_count(g)==1,"BIND SEARCH fully removed shoulders stop contributing immediately")
 g=setup();var root=g._install_assembly("jacket","standard","fixture",2,2)
 t.check(not root.is_empty() and g.Cards.occupied_body_count(g)>1,"BIND SEARCH composite counts actual covered sidebar parts rather than one root")
 g=setup();source=Give.give(g,TYPE);g.state.evasion=2
 var c=t.find_action(g,"card",{"uid":source.uid,"free":true});var before=g.export_snapshot()
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"BIND SEARCH free dispatch succeeds")
 t.check(g.state.equipment.size()==1 and g.state.equipment[0].grade==2 and g.tier(g.state.equipment[0].durability,g.state.equipment[0].maximum)==2 and not g.state.equipment[0].locked,"BIND SEARCH installs one unlocked medium tier-two ordinary restraint")
 t.check(g.state.hand.size()==3 and g.state.energy==before.energy-1 and g.state.mana==90 and g.state.evasion==2 and g.state.discard.any(func(card):return card.uid==source.uid),"BIND SEARCH voluntary equip precedes draw and bypasses evasion; played card discards normally")
 var other=setup();Give.give(other,TYPE);other.state.evasion=2
 t.check(t.action(other,"card",{"free":true,"type":TYPE}).ok and other.state.equipment==g.state.equipment and other.state.hand==g.state.hand,"BIND SEARCH seeded equipment and draws reproduce through the same pipeline")
 g=setup();source=Give.give(g,TYPE)
 var options=g.Cards.SelfBinding.install_options(g,2,2)
 while not options.is_empty():
  g.Application.execute_concrete(g,options[0],"fixture",false,[],true)
  options=g.Cards.SelfBinding.install_options(g,2,2)
 before=g.export_snapshot();c=t.find_action(g,"card",{"uid":source.uid,"free":true})
 t.check(not c.valid and c.reason.contains("没有位置") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"BIND SEARCH full capacity refuses before payment or draw and never replaces equipment")
 for free in [false,true]:
  g=setup();source=Give.give(g,TYPE);g.state.pressure=95
  c=t.find_action(g,"card",{"uid":source.uid,"free":free})
  var rng=g.state.rng.magic
  while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,TYPE)).winning_rolls: rng=g.state.rng.magic
  g.state.rng.magic=rng;before=g.export_snapshot()
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and g.state.hand==before.hand and g.state.equipment==before.equipment and g.state.rng.equipment==before.rng.equipment,"BIND SEARCH failed casting grants neither random equipment nor draws on either face")
 g=setup();source=Give.give(g,TYPE);g.state.mana=9;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":source.uid,"free":true}).ok and g.export_snapshot()==before,"BIND SEARCH insufficient mana refuses atomically")
 g=setup();source=Give.give(g,TYPE);g.Cards.grant_buff(g,"echo_cast_bound")
 for slot in slots.slice(0,4): g.add_fixture(slot,8)
 t.check(t.action(g,"card",{"uid":source.uid,"free":false}).ok and g.state.hand.size()==4 and g.state.energy==19 and g.state.mana==90,"BIND SEARCH bound replay draws the live body amount again without repaying")
 t.check(g.B.card_metadata(TYPE).face_effects.bound.contains("X/2") and not g.B.card_metadata(TYPE).face_effects.bound.contains("X＝"),"BIND SEARCH static catalog retains formula without inventing current count")
