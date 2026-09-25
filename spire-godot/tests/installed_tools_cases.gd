extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func usable_statuses(t) -> void:
 var g=fresh();var target=g.add_fixture("wrist",8,10,true);g._gain_tool("shard")
 var tool=g.state.items[0];tool.mount="hand_wall"
 t.hand_card(g,"strain")
 var find_item=func():return g.get_view().statuses.filter(func(row):return row.get("item_id","")==tool.id)
 var before=g.export_snapshot();var rows=find_item.call()
 t.check(rows.size()==1 and rows[0].active and rows[0].category=="environment" and rows[0].badge=="3" and rows[0].source==g.Tools.mount_label("hand_wall"),"TOOL STATUS reachable passive cutter appears once as environment with height and charges")
 t.check(g.export_snapshot()==before,"TOOL STATUS reading usable items preserves snapshot and random state")
 g.state.wall_distance=1
 t.check(find_item.call().is_empty(),"TOOL STATUS unreachable wall cutter is absent")
 g.state.wall_distance=0;tool.uses=0
 t.check(find_item.call().is_empty(),"TOOL STATUS exhausted cutter is absent")
 tool.uses=3;g.state.phase="map"
 t.check(find_item.call().is_empty(),"TOOL STATUS cutter without an actionable trigger is absent outside action phases")
 g.state.phase="battle";g.state.overloaded=true
 t.check(find_item.call().is_empty(),"TOOL STATUS forced turn does not advertise passive use")
 g.state.overloaded=false;g.state.posture="stand";tool.mount="high_wall"
 t.check(find_item.call().is_empty(),"TOOL STATUS cutter above its target is absent")
 tool.mount="carry";target.locked=false
 t.check(find_item.call().is_empty(),"TOOL STATUS carried cutter stays out of environment statuses even when usable")
 g.state.items.clear();g.state.equipment.clear();g._gain_tool("mana_potion");g.state.mana=0
 var potion=g.state.items[0]
 var action=t.find_action(g,"item_use",{"item":potion.id})
 t.check(action.valid and not g.get_view().statuses.any(func(row):return row.get("item_id","")==potion.id),"TOOL STATUS usable potions stay out of environment statuses")

static func fresh() -> RefCounted:
 var g=Game.new(42);g.state.equipment.clear();g.state.composites.clear();g.state.links.clear();g.state.items.clear();g.state.strength=0;g.state.dexterity=0;g.state.wall="normal"
 return g

static func play(t,g,target,type: String="strain") -> Dictionary:
 if not g.state.deck.any(func(c):return c.type==type): g._gain_card(type)
 var card=t.hand_card(g,type)
 return t.action(g,"card",{"uid":card.uid,"target":target.id,"free":false})

static func run(t) -> void:
 usable_statuses(t)
 var g=fresh();var target=g.add_fixture("wrist",8,10,true);g._gain_tool("shard")
 var tool=g.state.items[0];tool.mount="hand_wall"
 var card=t.hand_card(g,"strain");var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 t.check(c.valid and c.payload.tool_bonus.damage==5 and g.candidate_detail(c).contains("固定切割"),"PASSIVE preview includes fixed tool contribution")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.export_snapshot()==before,"PASSIVE previews do not spend charges or randomness")
 t.check(not t.find_action(g,"item_use",{"item":tool.id,"target":target.id}).valid,"PASSIVE mounted cutter has no active use")
 var expected=8-c.payload.preview.damage-5
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(target.id).durability,expected) and g._item(tool.id).uses==2 and g.state.energy==2,"PASSIVE fixed five bypasses lock reduction and pays card once")
 t.check(g.state.logs.any(func(e):return e.data.has("tool_bonus") and e.data.tool_bonus.fixed==5),"PASSIVE fixed effect is logged separately")
 before=g.export_snapshot();t.check(not g.dispatch(g.command(c.payload,before.version-1),before.version-1).ok and g.export_snapshot()==before,"PASSIVE stale request does not repeat tool use")
 for mode in ["slip","magic_slip","ease"]:
  g=fresh();target=g.add_fixture("wrist",8);g._gain_tool("shard");tool=g.state.items[0];tool.mount="hand_wall"
  if not g.state.deck.any(func(x):return x.type==mode): g._gain_card(mode)
  card=t.hand_card(g,mode);c=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
  t.check(c.valid,"PASSIVE test action exists "+mode)
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"PASSIVE corresponding card resolves "+mode)
  t.check(g._item(tool.id).uses==(2 if mode in ["slip","magic_slip"] else 3),"PASSIVE matching actual damage types consume tool "+mode)
 g=fresh();target=g.add_fixture("wrist",10);g._gain_tool("shard");tool=g.state.items[0];tool.mount="hand_wall"
 t.check(play(t,g,target,"slip").ok and g._item(tool.id).uses==3 and g._equipment(target.id).durability==10,"PASSIVE immune ordinary slip does not turn into cutting")
 g=fresh();target=g.add_fixture("wrist",1);g._gain_tool("shard");tool=g.state.items[0];tool.mount="hand_wall"
 t.check(play(t,g,target).ok and g._equipment(target.id).is_empty() and g._item(tool.id).uses==3,"PASSIVE card alone destroys target without wasting tool")
 # Height, material and position eligibility are separate from card target selection.
 g=fresh();target=g._install_template("cable_tie","wrist",8,10,false,"fixture");g._gain_tool("shard");tool=g.state.items[0];tool.mount="hand_wall"
 t.check(g.InstalledTools.select(g,target,"strain").is_empty(),"PASSIVE stone cannot cut plastic")
 g._gain_tool("saw");var saw=g.state.items[1];saw.mount="high_wall"
 t.check(g.InstalledTools.select(g,target,"strain").is_empty(),"PASSIVE high tool does not reach standing wrist")
 saw.mount="foot_wall";g.state.posture="sit"
 t.check(g.InstalledTools.select(g,target,"strain").item==saw.id,"PASSIVE posture updates compatible point")
 g.state.wall_distance=1
 t.check(g.InstalledTools.select(g,target,"strain").is_empty(),"PASSIVE leaving wall disables bonus")
 # Two tools can reach the same point; strongest available wins with deterministic tie order.
 g=fresh();g.state.posture="sit";target=g.add_fixture("wrist",8);g._gain_tool("shard");g._gain_tool("saw")
 tool=g.state.items[0];saw=g.state.items[1];tool.mount="hand_wall";saw.mount="foot_wall"
 t.check(g.InstalledTools.select(g,target,"strain").item==saw.id,"PASSIVE overlapping tools choose strongest")
 t.check(play(t,g,target).ok and g._item(tool.id).uses==3 and g._item(saw.id).uses==1,"PASSIVE only strongest tool charge is spent")
 # Automatic segments share one tool usage record and replay from a full snapshot.
 g=fresh();g.state.posture="sit";target=g.add_fixture("wrist",16,20);var other=g.add_fixture("wrist",16,20)
 g._gain_tool("shard");tool=g.state.items[0];tool.mount="hand_wall"
 g._gain_card("peel");t.hand_card(g,"peel")
 var saved=g.export_snapshot();var restored=Game.new(7)
 t.check(restored.restore_snapshot(saved).ok,"PASSIVE restores before automatic multi-hit card")
 t.check(play(t,g,target,"peel").ok and g.state.card_chain.is_empty() and g._item(tool.id).uses==2,"PASSIVE three automatic segments spend same tool only once")
 t.check(play(t,restored,restored._equipment(target.id),"peel").ok and restored._item(tool.id).uses==2 and restored.state.equipment==g.state.equipment,"PASSIVE restored full card reproduces damage and one tool charge")
 t.check(g._equipment(other.id).durability==16 and g.state.logs.filter(func(log):return log.data.has("tool_bonus")).size()==1,"PASSIVE surviving target stays selected without repeating fixed damage")
 # Direct carry targets are projected into legal location groups only.
 g=fresh();target=g.add_fixture("thigh",8);g._gain_tool("shard")
 var item_view=g.get_view().items[0]
 t.check(item_view.target_groups.any(func(group):return group.id=="thigh") and item_view.passive_text==g.InstalledTools.description(g,g.state.items[0]),"PASSIVE carried tool projects legal position menu and installation effect")

 # Different card names share a damage contract; magic delivery is not an exclusion.
 for type in ["brace","inch","tear","magic_slip"]:
  g=fresh();target=g.add_fixture("wrist",80,100);g._gain_tool("shard");tool=g.state.items[0];tool.mount="hand_wall"
  t.check(play(t,g,target,type).ok and g._item(tool.id).uses==2,"PASSIVE damage contract triggers across card names "+type)
 g=fresh();target=g.add_fixture("wrist",8);g._gain_tool("shard");tool=g.state.items[0];tool.mount="hand_wall"
 var zero={"reason":"","immune":false,"release":false,"damage":0.0}
 t.check(g.InstalledTools.preview(g,target,"strain",zero).is_empty(),"PASSIVE no actual damage cannot trigger")
 # A second distinct tool may contribute to the next segment, and its last charge is removed.
 g=fresh();g.state.posture="sit";target=g.add_fixture("wrist",80,100);other=g.add_fixture("wrist",80,100)
 g._gain_tool("shard");g._gain_tool("saw");tool=g.state.items[0];saw=g.state.items[1]
 tool.mount="hand_wall";tool.uses=1;saw.mount="foot_wall"
 t.check(play(t,g,target,"peel").ok and g._item(saw.id).uses==1,"PASSIVE strongest first hit uses saw")
 t.check(g.state.card_chain.is_empty() and g._item(tool.id).is_empty() and g._item(saw.id).uses==1 and g._equipment(other.id).durability==80,"PASSIVE automatic second hit uses other tool and removes exhausted charge")
