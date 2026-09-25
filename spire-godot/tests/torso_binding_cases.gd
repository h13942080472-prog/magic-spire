extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
# Living index-off reference for the B7 parity checks (single definition in the architecture suite).
const Arch=preload("res://tests/architecture_cases.gd")

static func sample(kind: String):
 for seed in range(1,100):
  var g=Game.new(seed,true,"torso_binding")
  if g.state.equipment[0].binding.kind==kind: return g
 return null

# docs/spec/equipment-query-seam.md「证据入口」: the connection edge carries only connected forms, and both list consumers read
# the same projection as the live helper.
static func index_connection_edge_parity(t) -> void:
 for kind in ["linked","integrated"]:
  var g=sample(kind)
  t.check(g!=null,"INDEX seeded generation produces "+kind)
  if g==null: continue
  var host=g.state.equipment[0]
  var reference=Arch.UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var previous=g._begin_equipment_read()
  var connections=g._equipment_read.connections.duplicate()
  var parity=connections.size()==g.Binding.connections(g).size()
  parity=parity and connections.is_empty()==(kind=="integrated")
  parity=parity and g.action_targets().map(func(e):return e.id)==reference.action_targets().map(func(e):return e.id)
  for slot in g.B.SLOTS:
   parity=parity and g.targets_at(slot)==reference.targets_at(slot) and g.targets_at(slot).map(func(e):return e.id)==reference.targets_at(slot).map(func(e):return e.id)
  var listed=g.targets_at(host.slot).filter(func(e):return e.get("kind","")!="")
  if kind=="linked":
   parity=parity and connections.size()==g.state.equipment.filter(func(e):return e.binding.kind=="linked").size() and not connections.is_empty()
   parity=parity and connections.all(func(entry):return entry.id=="binding_"+entry.parent_id)
   parity=parity and g.action_targets().any(func(e):return e.id=="binding_"+host.id)
   parity=parity and listed.any(func(e):return e.id=="binding_"+host.id)
  else:
   parity=parity and not g.action_targets().any(func(e):return e.get("kind","")=="integrated") and listed.is_empty()
  g._equipment_read=previous
  t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX connection edge parity with the live path "+kind)

static func run(t) -> void:
 var handbook=preload("res://data/tutorial.gd").entries()
 t.check(handbook.any(func(row):return row.title=="躯干固缚：连接式与一体式" and "二档加固回三档" in row.text),"BIND handbook explains forms and reinforcement refresh")
 index_connection_edge_parity(t)
 for kind in ["linked","integrated"]:
  var g=sample(kind)
  t.check(g!=null,"BIND seeded generation produces "+kind)
  if g==null: continue
  var e=g.state.equipment[0]
  t.check(g.tier(e.durability,e.maximum)==3 and g.Binding.active(g,e),"BIND tier3 automatically attaches "+kind)
  var before=g.state.duplicate(true)
  g.get_view();g.command_facts()
  t.check(g.state==before,"BIND previews do not reroll or mutate "+kind)
  t.check(t.action(g,"hook",{"target":e.id}).ok,"BIND formal hook lowers parent "+kind)
  e=g._equipment(e.id)
  t.check(g.tier(e.durability,e.maximum)==2 and g.Binding.active(g,e),"BIND lowering to integer tier2 preserves "+kind)
  var points=g.HandAssist.profile(g,"left").points
  t.check("thigh_root" not in points and "special_3_a" not in points and "special_1_a" in points and "above_elbow" in points,"BIND forearm blocks exactly thigh and region3 "+kind)
  before=g.state.duplicate(true)
  t.check(g._install_template("belt","forearm",4,10,false,"fixture",1,e.layer+1,0,e.points[0]).is_empty() and g.state==before,"BIND no outer installation or ID/RNG mutation "+kind)
  var other=g._install_template("belt","forearm",10,10,false,"fixture",1,e.layer,0,e.points[0])
  t.check(not other.is_empty() and other.layer==e.layer,"BIND same layer remains legal "+kind)
  var copy=Game.new(100)
  t.check(copy.restore_snapshot(g.export_snapshot()).ok and copy.state.equipment==g.state.equipment,"BIND state and random domain roundtrip "+kind)
  if kind=="linked":
   var connection=e.binding
   t.check(g.escape_preview(connection,"strain",5).divisor==1 and g.escape_preview(connection,"strain",5).reason=="","BIND connection strain ignores neighbour priority and divisor")
   connection.durability=1
   t.check(g.get_view().bodies.filter(func(b):return b.id==e.slot)[0].targets[connection.id].tier==2,"BIND connection uses parent integer tier with independent HP")
   t.check(g.escape_preview(connection,"magic_slip",5).penalty==0.5,"BIND connection slip retains same-layer tightness penalty")
   var card=t.hand_card(g,"strain")
   var host_hp=e.durability
   var splash=g.escape_preview(e,"strain",g.Cards.Rules.SPECS.strain.base*0.5,[],false,false,true,true).damage
   t.check(t.action(g,"card",{"uid":card.uid,"target":connection.id,"free":false}).ok,"BIND connection is a formal selectable card target")
   e=g._equipment(e.id)
   t.check(is_equal_approx(e.durability,host_hp-splash) and e.binding.durability==0 and not g.Binding.present(e),"BIND depletion clears attachment while same-point splash damages surviving host")
   g._cleanup();g.command_facts()
   t.check(not g.Binding.present(e),"BIND cleanup does not recreate depleted attachment")
   # Formal enemy operation performs the same reinforcement used by live enemies.
   var enemy={"id":"fixture_guard","type":"guard","name":"测试警卫"}
   g._enemy_operation(enemy,{"kind":"tighten","target":e.id,"text":"加固","delayed":false})
   e=g._equipment(e.id)
   t.check(g.tier(e.durability,e.maximum)==3 and e.binding.durability==e.binding.maximum,"BIND tier2 to tier3 reinforcement refreshes depleted connection")
   e.binding.durability=0
   t.check(g.Binding.can_tighten(e),"BIND fully tight parent remains eligible when connection exhausted")
   g._enemy_operation(enemy,{"kind":"tighten","target":e.id,"text":"加固","delayed":false})
   t.check(g.Binding.present(g._equipment(e.id)),"BIND reinforcement at tier3 also refreshes")
  else:
   t.check(e.binding.size()==1,"BIND integrated form has no independent HP")
   t.check(g.escape_preview(other,"strain",5).divisor>1,"BIND integrated host keeps ordinary struggle stacking")
  before=g.state.duplicate(true)
  t.check(g._install_assembly("glove","short","fixture",2,2,{"bad_part":{}}).is_empty() and g.state==before,"BIND failed assembly retains all effects")
  var root=g._install_assembly("glove","short","fixture",2,2)
  t.check(not root.is_empty() and not g._equipment(e.id).has("binding"),"BIND successful overlapping assembly cancels attachment atomically")
  t.check(g.validate()=="","BIND assembly and survivors validate")
  var removal=sample(kind)
  var host=removal.state.equipment[0].id
  for i in range(3): t.check(t.action(removal,"hook",{"target":host}).ok,"BIND remove host through formal tier steps "+kind)
  t.check(removal._equipment(host).is_empty() and not removal.Binding.connections(removal).any(func(c):return c.parent_id==host),"BIND parent removal cascades either form "+kind)
 # Only the declared arm subregions trigger; ordinary tier2 and hands do not.
 var g=Game.new(42)
 for slot in ["upper_arm","forearm","wrist","palm","fingers","thigh"]:
  var template=g.Equipment.default_template(slot)
  var e=g._install_template(template,slot,8,10,false,"fixture")
  t.check(not e.has("binding"),"BIND tier2 has no new effect "+slot)
  e.durability=10;g.Binding.refresh(g,e)
  t.check(e.has("binding")== (slot in g.Binding.SLOTS),"BIND trigger excludes hands and legs "+slot)
 var h=Game.new(9)
 var upper=h._install_template("rope","upper_arm",10,10,false,"fixture")
 t.check("thigh_root" not in h.HandAssist.profile(h,"left").points and "special_3_a" in h.HandAssist.profile(h,"left").points,"BIND upper arm blocks thighs but not special region3")
 var old=h.state.duplicate(true)
 var saved=h.export_snapshot();saved.equipment[0].binding={"kind":"linked","durability":"invalid"}
 t.check(not h.restore_snapshot(saved).ok and h.state==old,"BIND malformed nested HP rejects restore atomically")
 upper=h._equipment(upper.id);upper.durability=0;h._cleanup()
 t.check(h.Binding.connections(h).is_empty() and h.state.equipment.is_empty(),"BIND host removal cascades connection")
 h=Game.new(18)
 var outer=h._install_template("belt","upper_arm",4,10,false,"fixture",1,1,0,"above_elbow")
 var inner=h._install_template("rope","upper_arm",10,10,false,"fixture",1,0,0,"above_elbow")
 t.check(h.Binding.present(inner) and not h.Binding.active(h,inner) and "thigh_root" in h.HandAssist.profile(h,"left").points,"BIND covered attachment is dormant")
 outer.durability=0;h._cleanup()
 t.check(h.Binding.active(h,inner) and "thigh_root" not in h.HandAssist.profile(h,"left").points,"BIND exposed attachment becomes effective without reroll")
