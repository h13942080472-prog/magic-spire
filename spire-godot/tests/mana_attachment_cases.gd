extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")
const TYPE="mana_attachment"

static func setup():
 var g=Game.new(42)
 g._discard_end();g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[]
 g.state.relics=[];g.state.energy=30;g.state.mana_max=200;g.state.mana=200;g.state.pressure=0;g.state.charge=0
 return g

static func activate(t,g,free: bool) -> Dictionary:
 var card=Give.give(g,TYPE)
 t.check(t.action(g,"card",{"uid":card.uid,"free":free}).ok,"ATTACHMENT ability plays through normal submission")
 return card

static func toggle(t,g,free: bool) -> Dictionary:
 return t.action(g,"status_toggle",{"status":"power_mana_attachment_"+("free" if free else "bound")})

static func run(t) -> void:
 var g=setup()
 t.check(TYPE in g.Cards.Rules.UNCOMMON and g.Cards.Rules.type_tags(TYPE)==["magic","power"] and g.Cards.Rules.definition_reason(g.Cards.Rules.SPECS[TYPE])=="","ATTACHMENT uncommon magic power has valid definition")
 for free in [false,true]:
  g=setup();var card=Give.give(g,TYPE);var before=g.export_snapshot()
  var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
  t.check(c.valid and c.cost==1 and c.mana==10 and g.Cards.cast_profile(g,TYPE).parts==["none"],"ATTACHMENT both faces cost one energy and ten mana without casting limb")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==before,"ATTACHMENT stale activation rolls back")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==190 and g.state.energy==29 and g.state.charge==1 and g.state.powers.size()==1,"ATTACHMENT successful activation pays once and grants one charge")
  g=setup();card=Give.give(g,TYPE);g.state.mana=9;before=g.export_snapshot()
  t.check(not t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.export_snapshot()==before,"ATTACHMENT unaffordable activation leaves all state unchanged")
  g=setup();card=Give.give(g,TYPE);g.state.pressure=99
  var rng=g.state.rng.magic
  while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,TYPE)).winning_rolls: rng=g.state.rng.magic
  g.state.rng.magic=rng
  var failed_cost=t.find_action(g,"card",{"uid":card.uid,"free":free}).mana
  t.check(t.action(g,"card",{"uid":card.uid,"free":free}).ok and g._magic_failed and g.state.powers.is_empty() and g.state.charge==0 and g.state.mana==200-failed_cost*0.5,"ATTACHMENT failed cast grants neither power nor charge")
 g=setup();activate(t,g,true);g.state.strength=2
 for attack in ["strike","heavy","kick"]:
  for form in range(g.BasicAttacks.forms(g,attack).size()):
   var active=t.find_action(g,"attack",{"type":attack,"form":form})
   toggle(t,g,true)
   var ordinary=t.find_action(g,"attack",{"type":attack,"form":form})
   t.check(active.payload.all and is_equal_approx(active.payload.damage,ordinary.payload.damage*0.5) and active.mana==10 and ordinary.mana==0,"ATTACHMENT every physical form halves full strength/charge damage and pays once")
   toggle(t,g,true)
 var fire=t.find_action(g,"attack",{"type":"fireball"})
 t.check(not fire.payload.all and not fire.payload.has("mana_attachment"),"ATTACHMENT fireball is unaffected")
 var c=t.find_action(g,"attack",{"type":"strike","form":1});var hp=g.state.enemies.map(func(e):return e.hp)
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.export_snapshot()==before,"ATTACHMENT attack preview never spends resources")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==180 and g.state.charge==0,"ATTACHMENT multi-hit AOE consumes ten mana and one charge once")
 for i in range(hp.size()): t.check(is_equal_approx(hp[i]-g.state.enemies[i].hp,c.payload.damage*2*g.Enemies.damage_multiplier(g,g.state.enemies[i].type,"physical")),"ATTACHMENT each living enemy receives every physical hit")
 for mana in [0.0,9.0,10.0]:
  g=setup();activate(t,g,true);g.state.mana=mana;g.state.temporary_mana=0
  c=t.find_action(g,"attack",{"type":"strike","form":0})
  t.check(c.valid and c.payload.all==(mana>=10) and c.mana==(10 if mana>=10 else 0) and c.payload.damage==(5.5 if mana>=10 else 11.0),"ATTACHMENT insufficient-mana boundary restores original target and damage")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==(0 if mana>=10 else mana),"ATTACHMENT insufficient mana still permits ordinary attack without partial charge")
 g=setup();activate(t,g,true);g.state.mana=4;g.state.temporary_mana=6
 c=t.find_action(g,"attack",{"type":"strike","form":0})
 t.check(c.mana_payment.mana==4 and c.mana_payment.temporary_mana==6 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==0 and g.state.temporary_mana==0,"ATTACHMENT AOE draws temporary mana before personal mana")
 g=setup();activate(t,g,false)
 for mana in [4.0,5.0]:
  g.state.mana=mana;var charge=g.state.charge;var skill=Give.give(g,"pot_of_greed")
  t.check(t.action(g,"card",{"uid":skill.uid,"free":true}).ok and g.state.mana==(mana if mana<5 else 0) and g.state.charge==charge+(0 if mana<5 else 1),"ATTACHMENT ordinary skill grants charge only with full extra payment")
 g=setup();activate(t,g,false);g.state.mana=2;g.state.temporary_mana=13
 var skill=Give.give(g,"binding_search");var charge=g.state.charge
 t.check(t.action(g,"card",{"uid":skill.uid,"free":false}).ok and g.state.mana==0 and g.state.temporary_mana==0 and g.state.charge==charge+1,"ATTACHMENT magic skill pays initial ten then extra five across both pools")
 g=setup();activate(t,g,false);g.Cards.grant_buff(g,"echo_cast_bound");skill=Give.give(g,"binding_search");charge=g.state.charge
 t.check(t.action(g,"card",{"uid":skill.uid,"free":false}).ok and g.state.mana==175 and g.state.charge==charge+1,"ATTACHMENT replay is not another played skill or another surcharge")
 g=setup();activate(t,g,false);g.state.pressure=99;skill=Give.give(g,"binding_search");charge=g.state.charge
 var rng=g.state.rng.magic
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"binding_search")).winning_rolls: rng=g.state.rng.magic
 g.state.rng.magic=rng
 var failed_cost=t.find_action(g,"card",{"uid":skill.uid,"free":false}).mana
 t.check(t.action(g,"card",{"uid":skill.uid,"free":false}).ok and g._magic_failed and g.state.mana==190-failed_cost*0.5 and g.state.charge==charge,"ATTACHMENT failed skill cast does not spend five or gain charge")
 g=setup();activate(t,g,true);activate(t,g,false);charge=g.state.charge
 t.check(charge==2 and g.state.mana==180,"ATTACHMENT opposite faces coexist and powers do not trigger skill surcharge")
 before=g.export_snapshot();c=t.find_action(g,"status_toggle",{"status":"power_mana_attachment_free"})
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==before,"ATTACHMENT stale toggle cannot change active state")
 t.check(toggle(t,g,true).ok and toggle(t,g,false).ok and g.state.charge==charge and g.state.mana==180 and g.state.energy==28,"ATTACHMENT independent toggles cost nothing and keep original charges")
 var statuses=g.get_view().statuses
 t.check(statuses.any(func(s):return s.id=="power_mana_attachment_free" and s.disabled) and statuses.any(func(s):return s.id=="power_mana_attachment_bound" and s.disabled),"ATTACHMENT disabled powers remain visible and toggleable")
 skill=Give.give(g,TYPE);before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":skill.uid,"free":true}).ok and g.export_snapshot()==before,"ATTACHMENT disabled same face still rejects duplicate activation")
 skill=Give.give(g,"pot_of_greed");charge=g.state.charge
 t.check(t.action(g,"card",{"uid":skill.uid,"free":true}).ok and g.state.mana==180 and g.state.charge==charge,"ATTACHMENT disabled bound power does not charge for skills")
 var restored=Save.roundtrip(t,g,"attachment disabled faces")
 if restored!=null:
  t.check(restored.state.powers.all(func(card):return not card.power_enabled),"ATTACHMENT snapshot retains both disabled switches")
  t.check(toggle(t,restored,true).ok and t.find_action(restored,"attack",{"type":"strike"}).payload.get("mana_attachment",false),"ATTACHMENT restored free switch re-enables AOE")
 g.Cards.end_powers(g)
 t.check(g.state.powers.is_empty() and g.state.discard.all(func(card):return not card.has("power_enabled")) and g.validate()=="","ATTACHMENT normal session cleanup removes toggle metadata")
 for defect in ["type","zone","source"]:
  g=corrupt_fixture(t,defect)
  t.check(g.Cards.validate(g).contains("开关记录"),"ATTACHMENT debug aggregate rejects invalid switch "+defect)
  var target=setup();before=target.export_snapshot()
  t.check(not target.restore_snapshot(g.export_snapshot()).ok and target.export_snapshot()==before,"ATTACHMENT invalid switch snapshot restores atomically: "+defect)
 g=setup();activate(t,g,true);g.state.relics.append("intellect_cloak")
 c=t.find_action(g,"attack",{"type":"strike"})
 t.check(c.mana==10,"ATTACHMENT fixed attack surcharge is not discounted by card reducers")
 activate(t,g,false);skill=Give.give(g,"binding_search");var mana=g.state.mana
 t.check(t.action(g,"card",{"uid":skill.uid,"free":false}).ok and g.state.mana==mana-14,"ATTACHMENT skill card discount changes initial cost only, extra five stays fixed")

# Shared with the one-off mutation probe; each fixture violates only the switch contract.
static func corrupt_fixture(t, defect: String):
 var g=setup()
 if defect=="source":
  var card=Give.give(g,"formation")
  t.action(g,"card",{"uid":card.uid,"free":true})
 else: activate(t,g,true)
 if defect=="zone": g.state.deck[0].power_enabled=false
 else: g.state.powers[0].power_enabled="off" if defect=="type" else false
 return g
