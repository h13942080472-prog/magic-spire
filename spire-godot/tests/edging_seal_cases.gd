extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func setup():
 var g=Game.new(42)
 g.state.relics=["edging_seal"]
 g.state.pressure=0;g._clear_charge()
 return g

static func run(t) -> void:
 var g=setup()
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="edging_seal")
 g.state.relics=[]
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,"uncommon",excluded)=="edging_seal","SEAL joins uncommon reward pool")
 g.state.relics=["edging_seal"]
 var declaration=g.Relics.TYPES.edging_seal.trigger.duplicate(true)
 t.check(g.Relics.trigger_reason(declaration)=="","SEAL trigger declaration is accepted")
 for mutation in [{"event":"fell"},{"op":"charge"},{"scope":"turn"}]:
  var invalid=declaration.duplicate(true);invalid.merge(mutation,true)
  t.check(g.Relics.trigger_reason(invalid)!="","SEAL rejects incompatible content trigger contract")
 for delta in [-0.0000002,-0.00000005,0.0]:
  for route in ["gain","balance","maximum"]:
   var boundary=setup();var value=100.0+delta
   match route:
    "gain": boundary.Pressure.gain(boundary,value,"epsilon",true)
    "balance":
     boundary.state.mana_max=300;boundary.state.mana=value*2
     boundary.Pressure.balance_mana(boundary)
    "maximum":
     boundary.state.pressure=value;boundary.Pressure.settle_maximum(boundary,"epsilon")
   var should_trigger=delta>=-0.0000001
   t.check(boundary.state.overload_total==0 and boundary.RelicEffects.used(boundary,"edging_seal")==should_trigger and boundary.state.charge==(3 if should_trigger else 0),"SEAL numeric routes share overload epsilon and nearest safe boundary: "+route)
 g.Pressure.gain(g,99.9,"boundary",true)
 t.check(not g.RelicEffects.used(g,"edging_seal") and g.state.charge==0,"SEAL below threshold preserves charge and use")
 g.state.pressure=99;g._gain_charge(4)
 var energy=g.state.energy;var mana=g.state.mana;var hand=g.state.hand.duplicate(true)
 g.Pressure.gain(g,1,"boundary",true)
 t.check(g.state.pressure==50 and g.state.charge==7 and g.state.overload_total==0,"SEAL exact limit halves before overload and adds three charge without halving prior charge")
 t.check(g.state.energy==energy and g.state.mana==mana and g.state.hand==hand and not g.state.overloaded,"SEAL prevented overload preserves energy mana hand and action")
 t.check(g.state.logs.back().data.gain==1 and g.RelicEffects.counter(g,"edging_seal").text=="0","SEAL reduction never masquerades as negative source gain and counter updates")
 var snapshot=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==snapshot and not g.dispatch(g.command({"kind":"card","uid":"invalid"},g.state.version),g.state.version).ok and g.state==snapshot,"SEAL projections and refused commands preserve use")
 var restored=Save.roundtrip(t,g,"spent threshold seal")
 if restored!=null:
  restored.Pressure.gain(restored,50,"second",true)
  t.check(restored.state.overload_total==1 and restored.state.charge==3,"SEAL restore does not refund spent use; actual next overload halves charge")
 var serial=g.state.combat.serial
 g._start_preparation()
 t.check(g.state.combat.serial==serial and g.RelicEffects.used(g,"edging_seal"),"SEAL battle preparation shares spent session")
 g.RelicEffects.end_combat(g);g._start_battle()
 t.check(not g.RelicEffects.used(g,"edging_seal") and g.RelicEffects.counter(g,"edging_seal").text=="1","SEAL new session restores one use")
 for phase in ["battle","prepare","rest","prison"]:
  g=Game.new(42,true,"prison_test") if phase=="prison" else setup()
  g.state.relics=["edging_seal"];g.RelicEffects.end_combat(g)
  match phase:
   "battle": g._start_battle()
   "prepare": g._start_preparation()
   "rest": g._start_rest();t.action(g,"rest_begin")
   "prison": g.Prison.enter(g)
  g.state.pressure=99;g._clear_charge();var total=g.state.overload_total
  g.Pressure.gain(g,1,"session",true)
  t.check(g.state.pressure==50 and g.state.charge==3 and g.state.overload_total==total,"SEAL eligible class-combat session: "+phase)
 for relics in [["edging_seal","green_bird"],["green_bird","edging_seal"]]:
  g=setup();g.state.relics=relics;g.state.pressure=98
  g.Pressure.gain(g,250,"bird",true)
  t.check(g.state.pressure==99 and g.state.charge==0 and not g.RelicEffects.used(g,"edging_seal"),"SEAL bird prevents consumption regardless of inventory order")
  g.state.combat.turn=7;g.Pressure.gain(g,1,"expired bird",true)
  t.check(g.state.pressure==50 and g.state.charge==3,"SEAL remains available after bird expires")
 g=setup();g.Pressure.gain(g,250,"large gain",true)
 t.check(g.state.pressure==25 and g.state.overload_total==1 and g.state.charge==1,"SEAL halved total still above limit follows normal overload rules")
 g=setup();g.state.mana_max=300;g.state.mana=200
 g.Pressure.balance_mana(g)
 t.check(g.state.pressure==50 and g.state.charge==3 and g.state.mana==100,"SEAL resource redistribution shares numeric threshold route")
 g=setup();g.state.pressure=110
 g.Pressure.settle_maximum(g,"limit reduction")
 t.check(g.state.pressure==55 and g.state.charge==3 and g.state.overload_total==0,"SEAL changed maximum uses same guard route")
 g=setup();g.RelicEffects.end_combat(g);g.state.phase="event";g.state.pressure=99
 g.Pressure.gain(g,1,"outside",true)
 t.check(g.state.overload_total==1 and not g.RelicEffects.used(g,"edging_seal"),"SEAL inactive scene cannot consume session protection")
 g=setup();g.state.pressure=80
 g.Pressure.scripted_climax(g,"script")
 t.check(g.state.overload_total==1 and not g.RelicEffects.used(g,"edging_seal"),"SEAL direct scripted climax bypasses numeric guard like Green Bird")
 g=setup();g.state.relics.append("ditto");g.state.ditto_form="edging_seal"
 g.Pressure.gain(g,100,"first copy",true)
 t.check(g.RelicEffects.used(g,"edging_seal") and not g.RelicEffects.used(g,"ditto") and g.state.charge==3,"SEAL first copy removes threshold condition without wasting second copy")
 g.Pressure.gain(g,50,"second copy",true)
 t.check(g.state.pressure==50 and g.state.charge==6 and g.RelicEffects.used(g,"ditto"),"SEAL Ditto owns independent session use")
 g=setup();g.state.relics.append("magic_blood");g.state.pressure=98
 var expected=(98-g.Pressure.free_relief(g)+5)/2.0
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.pressure==expected and g.state.charge==3 and not g.state.overloaded,"SEAL real end-turn dispatch survives threshold at next turn start")
