extends RefCounted
const RestraintValue=preload("res://data/restraint_value.gd")

const Game=preload("res://tests/game_fixture.gd")
const N=preload("res://data/enemies.gd")
const E=preload("res://data/equipment.gd")
const Book=preload("res://data/encyclopedia.gd")

static func trader(g) -> Dictionary:
 return g.state.enemies.filter(func(enemy):return enemy.type=="trader")[0]

static func sourced(g, id: String) -> Array:
 return g.state.equipment.filter(func(item):return item.source==id)

static func run(t) -> void:
 var spec=N.TYPES.trader
 t.check(spec.opening.size()==4 and spec.repeat_cycle.size()==3 and spec.repeat_count==2,"TRADER ten configured actions precede capture on action eleven")
 for plan in spec.opening:
  t.check(plan.has("text") and not plan.delayed,"TRADER complete plan display fields")
  if plan.kind!="apply": continue
  for template in plan.templates+plan.get("fallback_templates",[]):
   t.check(E.TEMPLATES.has(template) and not E.TEMPLATES[template].slots.is_empty() and E.TEMPLATES[template].get("min_grade",1)<=plan.grade,"TRADER explicitly allowed ordinary template "+template)
 for index in range(3):
  var original=spec.opening[[0,2,3][index]]
  t.check(spec.repeat_cycle[index]==original and not is_same(spec.repeat_cycle[index],original) and not is_same(spec.repeat_cycle[index].templates,original.templates),"TRADER repeat plans own independent nested data")
 var entry=Book.entries().filter(func(row):return row.category=="enemies" and row.id=="trader")[0]
 t.check(entry.group=="强怪" and entry.title=="被魔法控制的奴隶贩子" and entry.visual=="trader" and entry.text.contains("第11次") and entry.text.contains("出手时"),"TRADER catalogue full name, rank, sequence and timing")

 t.check(spec.hp==56 and spec.strength==2 and spec.behavior=="humanoid" and spec.humanoid,"TRADER human strong enemy values")
 t.check(N.ENCOUNTERS.trader_solo.members==[{"type":"trader","grade":2}],"TRADER fixed practice encounter")
 t.check(N.FirstFloor.choices("weak").all(func(id):return not Book.encounter_contains(id,"trader")),"TRADER absent from weak pool")
 t.check(N.FirstFloor.choices("strong").filter(func(id):return Book.encounter_contains(id,"trader"))==["versatile_trader"],"TRADER joins strong pool only with versatile partner")
 t.check(N.FirstFloor.ELITE_ENCOUNTERS.all(func(id):return not Book.encounter_contains(id,"trader")) and N.FirstFloor.SUMMIT_ENCOUNTERS.all(func(id):return not Book.encounter_contains(id,"trader")),"TRADER absent from elite and summit pools")

 var expected=["apply","debuff","apply","apply","apply","apply","apply","apply","apply","apply","capture"]
 var g=Game.new(701,true,"trader_solo")
 var enemy=trader(g)
 for stage in range(1,expected.size()+1):
  enemy.stage=stage
  var plan=g._plan(enemy)
  t.check(plan.kind==expected[stage-1] and not plan.has("target") and not plan.has("slot"),"TRADER untargeted plan at action "+str(stage))
  if stage in [3,6,9]: t.check(plan.get("ready_gain",0)==1,"TRADER readiness gain at action "+str(stage))
 t.check(spec.opening[0].count==2 and spec.opening[0].profiles==RestraintValue.profiles(3) and "mouth_band" not in spec.opening[0].templates,"TRADER opening applies two initial restraints without a ball gag")
 t.check(spec.opening[3].preferred_slots==["mouth","eyes"] and spec.opening[3].variants=={"mouth_band":0},"TRADER fourth action prefers the medium harness gag or eye cover")
 t.check(spec.opening.all(func(plan):return not plan.get("templates",[]).has("eye_cloth") and not plan.get("fallback_templates",[]).has("eye_cloth")),"TRADER removed cloth blindfold is absent from every pool")

 g=Game.new(702,true,"trader_solo")
 enemy=trader(g)
 var id=enemy.id
 t.check(t.action(g,"end").ok,"TRADER first real action commits")
 var first=sourced(g,id)
 t.check(first.size()==2 and first.all(func(item):return item.grade+g.tier(item.durability,item.maximum)==3 and item.template!="mouth_band"),"TRADER first action installs two value-three pieces")
 t.check(t.action(g,"end").ok and g.state.weakness_turns==1,"TRADER second real action applies one player turn of weakness")
 for type in ["strike","heavy","kick"]:
  var candidate=t.find_action(g,"attack",{"type":type,"enemy":id})
  t.check(not candidate.valid and candidate.reason.contains("无力化"),"TRADER weakness blocks "+type+" with a visible reason")
 t.check(t.find_action(g,"attack",{"type":"fireball","enemy":id}).valid,"TRADER weakness leaves fireball usable")
 var before_ids=sourced(g,id).map(func(item):return item.id)
 t.check(t.action(g,"end").ok and g.state.weakness_turns==0,"TRADER weakness expires after the affected player turn")
 enemy=trader(g)
 var third=sourced(g,id).filter(func(item):return item.id not in before_ids)
 t.check(third.size()==1 and third[0].grade+g.tier(third[0].durability,third[0].maximum)==4 and enemy.ready_layers==1,"TRADER third action applies value four then gains readiness")
 before_ids=sourced(g,id).map(func(item):return item.id)
 t.check(t.action(g,"end").ok,"TRADER fourth real action commits")
 enemy=trader(g)
 var fourth=sourced(g,id).filter(func(item):return item.id not in before_ids)
 t.check(fourth.size()==1 and fourth[0].grade==2 and g.tier(fourth[0].durability,fourth[0].maximum)==3 and enemy.ready_layers==0,"TRADER readiness forces the next installed piece to tier three and is consumed")
 t.check(fourth[0].slot in ["mouth","eyes"],"TRADER fourth action uses its preferred head slot when available")
 t.check(g.validate()=="","TRADER opening leaves a valid state")

 g=Game.new(703,true,"trader_solo")
 enemy=trader(g);id=enemy.id
 enemy.ready_layers=2
 t.check(t.action(g,"end").ok,"TRADER stacked readiness action commits")
 enemy=trader(g)
 var stacked=sourced(g,id)
 t.check(stacked.size()==2 and stacked.all(func(item):return g.tier(item.durability,item.maximum)==3) and enemy.ready_layers==0,"TRADER stacked readiness is consumed once per successful piece")

 g=Game.new(704,true,"trader_solo")
 enemy=trader(g);id=enemy.id;enemy.ready_layers=2
 var stage=enemy.stage
 g.state.round=2
 g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.check(t.action(g,"attack",{"type":"kick","form":2,"enemy":id}).ok and trader(g).intent.delayed,"TRADER kick marks the current action delayed")
 t.check(t.action(g,"end").ok and trader(g).stage==stage and trader(g).ready_layers==2,"TRADER interruption preserves action and readiness without consuming either")
 t.check(t.action(g,"end").ok and trader(g).stage==stage+1 and trader(g).ready_layers==0,"TRADER delayed batch executes once on the following enemy phase")

 for seed in [705,706]:
  g=Game.new(seed,true,"trader_solo")
  for action_index in range(10):
   t.check(t.action(g,"end").ok and g.state.phase=="battle","TRADER remains in battle through configured action "+str(action_index+1))
  t.check(trader(g).stage==11 and trader(g).intent.kind=="capture","TRADER announces capture as action eleven")
  t.check(t.action(g,"end").ok and g.state.phase=="captured" and g.state.room=="prison" and g.state.weakness_turns==0,"TRADER action eleven uses the shared capture flow")

 g=Game.new(707,true,"trader_solo")
 enemy=trader(g);enemy.ready_layers=3
 g.state.weakness_turns=1
 var snapshot=g.export_snapshot()
 var restored=Game.new(0,false,"equipment",false)
 t.check(restored.restore_snapshot(snapshot).ok and trader(restored).ready_layers==3 and restored.state.weakness_turns==1,"TRADER current readiness and weakness survive same-version restore")
 for field in ["ready","weakness"]:
  var invalid=snapshot.duplicate(true)
  if field=="ready": invalid.enemies[0].ready_layers=-1
  else: invalid.weakness_turns=2
  var stable=restored.export_snapshot()
  t.check(not restored.restore_snapshot(invalid).ok and restored.export_snapshot()==stable,"TRADER malformed "+field+" state is rejected atomically")
