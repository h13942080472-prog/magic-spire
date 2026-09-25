extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func arranged(types: Array):
 var g=Game.new(42);g._discard_end()
 g.state.discard.append_array(g.state.draw);g.state.draw=[]
 for type in types:
  var card=Give.give(g,type);g.state.hand.erase(card);g.state.draw.append(card)
 return g

static func run(t) -> void:
 var g=arranged(["strain","ease","brace","wildfire_descent","slip"])
 var card=Give.give(g,"mana_search")
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(c.valid and c.cost==1 and c.mana==0 and g.Cards.Rules.SPECS.mana_search.rarity=="common" and "mana_search" in g.Cards.Rules.COMMON and not g.B.CARD_TRAITS.has("mana_search"),"SEARCH common one-energy skill, no exhaust or spell payment")
 t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SEARCH query and stale command are atomic")
 var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.hand.map(func(v):return v.type)==["wildfire_descent","ease"],"SEARCH free face draws topmost two magic-tag cards including dual-tag power")
 t.check(g.state.draw==before.draw.filter(func(v):return v.type not in ["wildfire_descent","ease"]) and g.state.rng==before.rng and g.state.energy==2 and g.state.mana==before.mana,"SEARCH skips unrelated cards without moving or shuffling them")
 t.check(result.card_feedback.filter(func(v):return v.kind=="draw").size()==2 and g.state.discard.any(func(v):return v.uid==card.uid),"SEARCH uses actual draw animation and discards one physical skill")
 t.check(g.Cards.Rules.type_tags("wildfire_descent")==["magic","power"] and g.Cards.Rules.classification("wildfire_descent").type_name=="魔法／能力" and g.Cards.Rules.SPECS.wildfire_descent.card_type=="power","SEARCH dual tags displayed and primary ability lifecycle retained")
 t.check(not g.Cards.Rules.matches_draw_filter("fire_control",{"tag":"magic"}) and not g.Cards.Rules.matches_draw_filter("mana_search",{"tag":"magic"}),"SEARCH does not infer tags from mana-related name or effect text")
 var tags=g.Cards.Rules.classification("wildfire_descent").type_tags;tags.clear()
 t.check(g.Cards.Rules.type_tags("wildfire_descent").size()==2,"SEARCH tag projection cannot mutate rule data")
 Save.roundtrip(t,g,"SEARCH filtered draw current state")
 # Use the aggregate upper-body level, not each equipped slot's tightness.
 for slot in ["eyes","mouth","upper_arm","forearm","wrist","palm","fingers","thigh"]:
  g=arranged(["strain","mana_surge","ease"]);var piece=g.add_fixture(slot,2.0)
  card=Give.give(g,"mana_search");c=t.find_action(g,"card",{"uid":card.uid,"free":true},false)
  var allowed=slot in ["eyes","mouth","thigh"]
  t.check(c.valid==allowed and c.valid==(g.level("arms")==0),"SEARCH aggregate upper-body level boundary: "+slot)
  if not allowed:
   before=g.export_snapshot()
   t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before and c.reason.contains("束缚等级≤0"),"SEARCH blocked free face preserves all resources and piles")
   g._equipment(piece.id).durability=0.0000001
   g._cleanup()
   t.check(t.find_action(g,"card",{"uid":card.uid,"free":true}).valid,"SEARCH canonical zero tier allows free face")
   g.add_fixture(slot,2.0)
  g.state.mana=0;g.state.pressure=99;before=g.export_snapshot()
  t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.hand.size()==1 and g.state.hand[0].type=="ease" and g.state.rng.magic==before.rng.magic,"SEARCH bound draws one without mana, body or casting check")
 # A single independent arm restraint can have tier 3 while the total is zero.
 g=arranged(["mana_surge","ease"]);var arm=g.add_fixture("upper_arm",10.0)
 g._equipment(arm.id).side="left";card=Give.give(g,"mana_search")
 t.check(g.level("arms")==0 and t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.hand.size()==2,"SEARCH single-side tier-three restraint does not replace aggregate level")
 # Revalidate the same command when the aggregate changes before submission.
 g=arranged(["mana_surge","ease"]);card=Give.give(g,"mana_search")
 c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 g.add_fixture("forearm",2.0);before=g.export_snapshot()
 t.check(g.level("arms")==1 and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"SEARCH commit rechecks total level and rejects atomically")
 g=Game.new(42,true,"guard");g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
 g.CaptureBind.apply_bind(g,g.state.enemies[0]);card=Give.give(g,"mana_search")
 c=t.find_action(g,"card",{"uid":card.uid,"free":true},false)
 t.check(g.level("arms")==1 and not c.valid,"SEARCH capture contributes to the same aggregate level without ordinary arm equipment")
 # Missing matches never shuffle a nonempty pile or borrow a card from discard.
 g=arranged(["strain","brace"]);card=Give.give(g,"mana_search");before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.hand.is_empty() and g.state.draw==before.draw and g.state.rng==before.rng,"SEARCH no matches stops without replacing skipped cards or reshuffling")
 t.check(g.state.logs.any(func(log):return log.data.get("filtered_draw",{}).get("drawn",-1)==0),"SEARCH no-match log reports actual zero")
 g=arranged(["strain","ease"]);card=Give.give(g,"mana_search")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.hand.size()==1 and g.state.draw[0].type=="strain","SEARCH insufficient matches draws only one")
 # An empty draw pile uses the shared shuffle and still respects the filter.
 g=arranged([]);card=Give.give(g,"mana_search");before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.hand.size()==2 and g.state.hand.all(func(v):return "magic" in g.Cards.Rules.type_tags(v.type)) and g.state.rng.deck>before.rng.deck,"SEARCH empty pile shuffles discard once through normal draw")
 g=arranged(["strain","ease","unlock"]);card=Give.give(g,"mana_search")
 for i in range(9): Give.give(g,"strain")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.hand.size()==10 and g.state.draw.any(func(v):return v.type=="ease"),"SEARCH full hand frees one slot by playing, then draws only one")
 # Replayed bound effect draws once more but remains a single paid skill.
 g=arranged(["strain","ease","unlock"]);g.Cards.grant_buff(g,"echo_cast_bound");card=Give.give(g,"mana_search")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.hand.size()==2 and g.state.energy==2 and "echo_cast_bound" not in g.state.card_buffs,"SEARCH compatible with bound-face effect replay")
 g=arranged(["strain","ease"]);card=Give.give(g,"mana_search");g.state.energy=0;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"SEARCH insufficient energy cannot draw or alter piles")
 var spec=g.Cards.Rules.SPECS.mana_search.duplicate(true);spec.self_faces.bound.effects[0].filter={"tag":"missing"}
 t.check(g.Cards.Rules.definition_reason(spec)!="","SEARCH invalid filter rejected by common definition validator")
