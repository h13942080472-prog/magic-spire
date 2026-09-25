extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func run(t) -> void:
 var g=Game.new(42)
 g.state.equipment.clear();g.state.items.clear();g.state.relics=[]
 var thigh=g._install_template("belt","thigh",16,16,false,"fixture",2)
 var calf=g._install_template("rope","calf",16,16,false,"fixture",2)
 g._gain_tool("lubricant_potion")
 var id=g.state.items.back().id
 g.add_fixture("upper_arm",16,16);g.add_fixture("fingers",16,16)
 g._install_template("mouth_band","mouth",16,16,false,"fixture",2)
 var before=g.escape_preview(thigh,"slip",4)
 var mana=g.state.mana;var energy=g.state.energy;var round=g.state.round
 var facts=g.command_facts().filter(func(c):return c.payload.kind=="item_use" and c.payload.item==id)
 t.check(facts.size()==14 and facts.all(func(c):return c.valid),"OIL all panel groups selectable while standing with hands and mouth bound")
 t.check(before.immune and t.action(g,"item_use",{"item":id,"target":"thigh"}).ok,"OIL applies through formal item candidate")
 thigh=g._equipment(thigh.id);calf=g._equipment(calf.id)
 var after=g.escape_preview(thigh,"slip",4)
 t.check(not after.immune and after.damage>before.damage and after.slip_buff_multiplier==2.0,"OIL tier-three slip enabled with full multiplier despite mouth restraint")
 t.check(g.escape_preview(calf,"slip",4).immune,"OIL adjacent untreated body group remains immune")
 t.check(g.state.mana==mana and g.state.energy==energy and g.state.round==round and g._item(id).uses==2,"OIL consumes one charge with no resources or turn")
 t.check(t.action(g,"item_use",{"item":id,"target":"thigh"}).ok and g.state.body_buffs.size()==1 and is_equal_approx(g.escape_preview(thigh,"slip",4).damage,after.damage),"OIL repeated use consumes a charge without stacking")
 var saved=g.export_snapshot()
 var stale=t.find_action(g,"item_use",{"item":id,"target":"hands"})
 t.check(t.action(g,"item_use",{"item":id,"target":"feet"}).ok and g._item(id).is_empty(),"OIL third use removes empty bottle and can coat a second group")
 var current=g.export_snapshot()
 t.check(not g.dispatch(g.command(stale.payload,saved.version),saved.version).ok and g.state==current,"OIL stale group selection rolls back without adding a coating")
 var feet=g._install_template("rope","foot",16,16,false,"fixture",2)
 var toes=g._install_template("cord","toes",16,16,false,"fixture",2)
 t.check(not g.escape_preview(feet,"slip",4).immune and not g.escape_preview(toes,"slip",4).immune,"OIL feet group covers foot and toes including later additions")
 thigh=g._equipment(thigh.id);thigh.durability=12.8
 var coated=g.escape_preview(thigh,"magic_slip",4)
 var buffs=g.state.body_buffs.duplicate(true);g.state.body_buffs=[]
 var ordinary=g.escape_preview(thigh,"magic_slip",4)
 var strain=g.escape_preview(thigh,"strain",4).damage
 g.state.body_buffs=buffs
 t.check(is_equal_approx(coated.damage,ordinary.damage*2) and is_equal_approx(coated.environment_true,ordinary.environment_true*2),"OIL final magic-slip multiplier includes wall additive")
 t.check(is_equal_approx(g.escape_preview(thigh,"strain",4).damage,strain),"OIL does not multiply struggle damage")
 thigh.locked=true
 var locked=g.escape_preview(thigh,"slip",4)
 g.state.body_buffs=[]
 var locked_plain=g.escape_preview(thigh,"slip",4)
 g.state.body_buffs=buffs
 t.check(locked.reason==locked_plain.reason and thigh.locked,"OIL preserves existing lock eligibility and does not unlock equipment")
 thigh.locked=false
 var outer=g._install_template("rope","thigh",16,16,false,"fixture",2,1,0,g.Equipment.physical_points(thigh)[0])
 t.check(g.escape_preview(thigh,"slip",4).reason.contains("覆盖"),"OIL cannot bypass outer-layer coverage")
 g.state.equipment.erase(outer)
 var snapshot=g.export_snapshot()
 g.get_view();g.command_facts()
 t.check(g.state==snapshot and g.get_view().statuses.any(func(s):return s.id=="body_buff_lubricant_potion_thigh"),"OIL state projection is read-only and shows active coated group")
 preload("res://tests/persistence_cases.gd").roundtrip(t,g,"body-group consumable")
 g._finish_battle()
 t.check(g.state.body_buffs==buffs,"OIL victory preserves the current session's coatings")
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare" and g.state.body_buffs==buffs,"OIL reward continuation preserves coatings into preparation")
 g._gain_tool("lubricant_potion");id=g.state.items.back().id
 t.check(t.action(g,"item_use",{"item":id,"target":"hands"}).ok,"OIL can be applied during preparation")
 t.check(t.action(g,"finish_prepare").ok and g.state.body_buffs.is_empty(),"OIL clears at preparation end")
 var hit=Game.new(42)
 hit.state.equipment.clear();hit.state.items.clear();hit.state.relics=[]
 var target=hit._install_template("belt","thigh",16,16,false,"fixture",2)
 hit._gain_tool("lubricant_potion");id=hit.state.items.back().id
 t.check(t.action(hit,"item_use",{"item":id,"target":"thigh"}).ok,"OIL card fixture uses actual potion")
 var card=t.hand_card(hit,"slip")
 var choice=t.find_action(hit,"card",{"uid":card.uid,"target":target.id,"free":false})
 var expected=maxf(0.0,target.durability-choice.payload.preview.damage)
 t.check(choice.valid and not choice.payload.preview.immune and t.action(hit,"card",{"uid":card.uid,"target":target.id,"free":false}).ok,"OIL actual normal slip card works at tier three")
 t.check(is_equal_approx(hit._equipment(target.id).get("durability",0.0),expected),"OIL card execution matches coated preview exactly")
 hit._gain_tool("lubricant_potion");id=hit.state.items.back().id
 t.check(t.action(hit,"item_use",{"item":id,"target":"hands"}).ok,"OIL can coat hands independently")
 for slot in ["palm","fingers"]:
  var hand=hit._install_template("cord",slot,16,16,false,"fixture",2)
  t.check(hit.Consumables.slip_multiplier(hit,hand)==2.0 and hit.Equipment.slip_points(hand).size()==2,"OIL hands include both sides of "+slot)
 var valid_state=hit.export_snapshot()
 for bad in [[{"type":"lubricant_potion","group":"missing"}],[{"type":"mana_potion","group":"thigh"}],[{"type":"lubricant_potion","group":"thigh"},{"type":"lubricant_potion","group":"thigh"}]]:
  var corrupt=valid_state.duplicate(true);corrupt.body_buffs=bad
  t.check(not hit.restore_snapshot(corrupt).ok and hit.state==valid_state,"OIL rejects malformed or duplicate region effects atomically")
