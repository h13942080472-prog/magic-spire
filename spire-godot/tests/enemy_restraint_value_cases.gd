extends RefCounted
const RestraintValue=preload("res://data/restraint_value.gd")
const Game=preload("res://tests/game_fixture.gd")
const E=preload("res://data/equipment.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Book=preload("res://data/encyclopedia.gd")

static func run(t) -> void:
 profiles(t)
 weak_sources(t)
 declarations(t)
 legality(t)
 shared_consumers(t)

static func profiles(t) -> void:
 var expected={2:[Vector2i(1,1)],3:[Vector2i(1,2),Vector2i(2,1)],4:[Vector2i(1,3),Vector2i(2,2),Vector2i(3,1)],5:[Vector2i(2,3),Vector2i(3,2)],6:[Vector2i(3,3)]}
 for value in expected:
  var seen=[]
  # Fixed small matrix verifies reachability of every profile even in daily runs.
  for seed_value in range(16):
   var g=Game.new(seed_value,true,"rope_solo")
   var spec=g.EnemyPlans.application(["rope"],1,2,1,false,value)
   spec.slot="wrist";spec.allow_links=false
   var before=g.export_snapshot()
   t.check(g.Application.can_apply(g,spec,"fixture") and g.export_snapshot()==before,"VALUE legality query preserves state and random counters")
   var result=g.Application.execute(g,spec,"fixture")
   t.check(result.ok and result.count==1,"VALUE formal installer creates exactly one piece")
   if result.installed.is_empty(): continue
   var item=result.installed[0]
   var pair=Vector2i(item.grade,g.tier(item.durability,item.maximum))
   t.check(pair in expected[value] and item.template=="rope" and item.slot=="wrist","VALUE actual grade and current tightness obey the per-piece budget and scope")
   if pair not in seen: seen.append(pair)
  t.check(seen.size()==expected[value].size(),"VALUE seed matrix reaches every legal combination for "+str(value))
 for value in [-1,0,1,7]:
  var g=Game.new(42,true,"rope_solo")
  var spec=g.EnemyPlans.application(["rope"])
  spec.profiles=RestraintValue.profiles(value)
  var before=g.export_snapshot()
  t.check(not g.Application.can_apply(g,spec,"fixture") and not g.Application.execute(g,spec,"fixture").ok and g.export_snapshot()==before,"VALUE out-of-range profile set rejects without state or RNG changes")

static func weak_sources(t) -> void:
 for type in preload("res://data/enemy_library.gd").CLASSIFICATIONS.weak:
  var g=Game.new(42,true,type+"_solo")
  var enemy=g.state.enemies[0]
  for plan in g.EnemyPlans.installation_intents(g,enemy):
   var before=g.export_snapshot()
   var spec=g.EnemyPlans.application_spec(g,enemy,plan)
   t.check(g.export_snapshot()==before,"WEAK GRADE source specification is readonly: "+type)
   if plan.get("final",false):
    t.check(spec.get("profiles",[])==plan.get("profiles",[]) and spec.grade==plan.grade,"WEAK GRADE final attachment preserves its original specification: "+type)
   else:
    t.check(not spec.profiles.is_empty() and spec.profiles.all(func(p):return p.grade==1),"WEAK GRADE all non-departure application choices are basic: "+type)
 var g=Game.new(42,true,"belt_solo");var enemy=g.state.enemies[0]
 var plan=g.EnemyPlans.application(["eye_leather"],1,2,1,false,3)
 plan.allow_links=false
 var before=g.export_snapshot()
 var spec=g.EnemyPlans.application_spec(g,enemy,plan)
 t.check(not g.Application.can_apply(g,spec,enemy.id) and not g.Application.execute(g,spec,enemy.id).ok and g.export_snapshot()==before,"WEAK GRADE cannot fall back to medium leather blindfold or spend RNG when no basic template fits")
 plan=g.EnemyPlans.application(["belt"],2,2,1,false,5)
 spec=g.EnemyPlans.application_spec(g,enemy,plan)
 t.check(not g.Application.can_apply(g,spec,enemy.id) and not g.Application.execute(g,spec,enemy.id).ok and g.export_snapshot()==before,"WEAK GRADE forbidden-only profiles reject without downgrading or mutation")
 plan.final=true
 g._enemy_operation(enemy,plan)
 t.check(enemy.gone and g.physical_pieces().size()==1 and g.physical_pieces()[0].grade>=2,"WEAK GRADE actual final operation still installs the stronger restraint and leaves")
 # Identical mixed-profile declarations are interpreted using the source's rank.
 for type in ["small_circle","mixed_bundle","rope","ominous_circle","rope_serpent","rope_mass"]:
  g=Game.new(42,true,type+"_solo");enemy=g.state.enemies[0]
  plan=g.EnemyPlans.application(["eye_leather"],1,2,1,false,3);plan.allow_links=false
  spec=g.EnemyPlans.application_spec(g,enemy,plan)
  var weak=type in g.Enemies.Library.CLASSIFICATIONS.weak
  t.check(g.Application.can_apply(g,spec,enemy.id)!=weak,"WEAK GRADE medium-only placement remains available to strong sources: "+type)
  g._enemy_operation(enemy,plan)
  t.check(g.physical_pieces().is_empty() if weak else g.physical_pieces().size()==1 and g.physical_pieces()[0].grade==2,"WEAK GRADE real enemy operation follows the same rank boundary: "+type)

static func declarations(t) -> void:
 for encounter in ["rope_solo","belt_solo","tape_solo","cable_tie_solo","trader_solo","guard"]:
  var g=Game.new(42,true,encounter)
  var before=g.export_snapshot()
  var view=g.get_view();g.command_facts()
  t.check(g.export_snapshot()==before and not JSON.stringify(view).contains("拘束值"),"VALUE backend score is absent from readonly player projection: "+encounter)
  var twin=Save.roundtrip(t,g,"value profiles "+encounter)
  Save.step_both(t,g,twin,"end")
  t.check(g.validate()=="","VALUE real enemy turn and restored twin retain valid equipment: "+encounter)
 var g=preload("res://tests/six_bind_cases.gd").encounter()
 var enemy=g.state.enemies[0]
 enemy.stage=4;enemy.intent=g._plan(enemy)
 t.check(enemy.intent.profiles==RestraintValue.profiles(4) and enemy.intent.count==2,"VALUE six double bind declares two independent value-four pieces")
 var twin=Save.roundtrip(t,g,"six value-four declaration")
 Save.step_both(t,g,twin,"end")
 t.check(g.physical_pieces().size()==2 and g.physical_pieces().all(func(item):return item.grade+g.tier(item.durability,item.maximum)==4),"VALUE six double bind installs actual value-four pieces")
 for enhancement in [0,1,2,5]:
  g=Game.new(42,true,"iron_man_solo");enemy=g.state.enemies[0]
  enemy.iron_enhancements=enhancement
  enemy.stage=3+5*enhancement;enemy.intent=g._plan(enemy)
  var spec=g.IronMan.installation_intents(g,enemy)[0]
  var value=4 if enhancement==0 else (5 if enhancement==1 else 6)
  t.check(spec.profiles==RestraintValue.profiles(value),"VALUE iron ordinary upgrades cap at six")
  var result=g.Application.execute(g,g.EnemyPlans.application_spec(g,enemy,spec),enemy.id)
  t.check(result.ok and result.installed.all(func(item):return item.grade+g.tier(item.durability,item.maximum)==value),"VALUE iron installation uses upgraded per-piece profiles")
  t.check(not g.IronMan.installation_intents(g,enemy)[1].has("profiles"),"VALUE iron composite keeps its fixed specification")
 t.check(g.Guard.application(g.Guard.ordinary_templates(),2).profiles==RestraintValue.profiles(4) and g.EnemyPlans.six_ordinary(g.Enemies.TYPES.six_bind,2,2).profiles==RestraintValue.profiles(4),"VALUE guard cycle and six tease share value four")
 for entry in Book.entries().filter(func(row):return row.category=="enemies"):
  t.check(not entry.text.contains("拘束值"),"VALUE enemy catalogue exposes equipment specifications without backend score")

static func legality(t) -> void:
 var g=Game.new(42,true,"trader_solo")
 var spec=g.EnemyPlans.application(["eye_leather"],1,2,1,false,3)
 spec.allow_links=false
 var result=g.Application.execute(g,spec,"fixture")
 t.check(result.ok and result.installed[0].grade==2 and g.tier(result.installed[0].durability,result.installed[0].maximum)==1,"VALUE excludes impossible low-grade leather blindfold and selects the legal profile")
 spec=g.EnemyPlans.application(["mouth_band"],1,2,1,false,3)
 spec.variants={"mouth_band":0};spec.replace=true
 var old=g._install_template("mouth_band","mouth",24,24,false,"fixture",3,-1,0)
 var before=g.export_snapshot()
 t.check(not g.Application.can_apply(g,spec,"fixture") and not g.Application.execute(g,spec,"fixture").ok and g.export_snapshot()==before and not old.is_empty(),"VALUE cannot replace a stronger occupied restraint or expand its template pool")
 g=Game.new(43,true,"trader_solo")
 spec=g.EnemyPlans.application(["tape"],1,2,2,false,3)
 spec.ready_layers=2
 result=g.Application.execute(g,spec,g.state.enemies[0].id)
 t.check(result.count==2 and result.ready_used==2 and result.installed.all(func(item):return g.tier(item.durability,item.maximum)==3),"VALUE readiness remains an explicit tier-three override consumed per successful piece")

# Live durability changes must feed all consumers without storing a stale score.
static func shared_consumers(t) -> void:
 var g=Game.new(42,true,"rope_solo")
 var mouth=g._install_template("mouth_band","mouth",16,16,false,"fixture",2)
 var before=g.export_snapshot()
 t.check(g.Cards.Hannya.mouth_restraint_value(g)==5 and g.Cards.Hannya.energy_cost(g)==3 and g.Consumables.potion_amount(g,5)==2 and g.Pressure.calm(g).reduction==4,"VALUE live mouth tier three feeds drinking and calm thresholds")
 t.check(g.export_snapshot()==before,"VALUE shared arithmetic queries do not mutate equipment or RNG")
 mouth.durability=12.8
 t.check(g.Cards.Hannya.mouth_restraint_value(g)==4 and g.Cards.Hannya.energy_cost(g)==2 and g.Consumables.potion_amount(g,5)==3 and g.Pressure.calm(g).reduction==8,"VALUE damaged mouth crosses value-four boundary in every existing consumer")
 mouth.locked=true
 t.check(g.Cards.Hannya.mouth_restraint_value(g)==4 and preload("res://core/equipment_replacement.gd").replacement_value(g,mouth)==5,"VALUE lock bonus belongs to replacement and never the base mouth value")
 var special={"template":"special","grade":2,"durability":10.0,"maximum":10.0,"locked":true}
 t.check(preload("res://core/equipment_replacement.gd").replacement_value(g,special)==3,"VALUE special replacement excludes durability tier and retains lock bonus")
 var result=g.Application.execute(g,g.EnemyPlans.application(["toe_cuffs"],2,2),"fixture")
 var shackle={} if result.installed.is_empty() else g._equipment(result.installed[0].id)
 t.check(not shackle.is_empty() and preload("res://core/equipment_replacement.gd").replacement_value(g,shackle)==4 and g.equipment_tier(shackle)==0,"VALUE fixed shackle replacement is four without an extra lock point or fake tier")
 var state=g.export_snapshot()
 var options=preload("res://core/self_binding.gd").options(g,"self_binding",2)
 t.check(not options.is_empty() and options.all(func(option):return option.grade+option.tier==4) and g.export_snapshot()==state,"VALUE self-binding shares inverse profiles without consuming RNG or installing")
