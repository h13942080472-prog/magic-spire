extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func shop(g) -> bool:
 preload("res://tests/service_cases.gd").arrive(g,"shop")
 var id=g.room_data(g.state.room).next.filter(func(next):return g.room_data(next).kind=="shop")[0]
 var departure=g.command_facts().filter(func(c):return c.payload.kind=="depart" and c.payload.room==id)[0]
 if not g.dispatch(g.command(departure.payload,g.state.version),g.state.version).ok: return false
 while g.state.phase=="travel":
  var step=g.command_facts().filter(func(c):return c.payload.kind=="travel_step")[0]
  if not g.dispatch(g.command(step.payload,g.state.version),g.state.version).ok: return false
 return g.state.phase=="shop"

static func run(t) -> void:
 var g=Game.new(42);g.state.relics.append("mana_earring")
 var before=g.export_snapshot();var pick=t.find_action(g,"flask",{"op":"deposit"})
 g.get_view();g.command_facts()
 t.check(g.state==before,"FLASK preview never moves mana or spends deposit uses")
 t.check(g.dispatch(g.command(pick.payload,g.state.version),g.state.version).ok and g.state.mana==90 and g.state.flask_mana==10 and g.state.flask_deposits==1,"FLASK deposit transfers ten")
 var committed=g.export_snapshot()
 t.check(not g.dispatch(g.command(pick.payload,before.version),before.version).ok and g.state==committed,"FLASK stale deposit rejects atomically")
 t.check(t.action(g,"flask",{"op":"deposit"}).ok and g.state.mana==80 and g.state.flask_mana==20,"FLASK second deposit succeeds")
 t.check(t.action(g,"flask",{"op":"deposit"}).ok and g.state.mana==70 and g.state.flask_mana==30,"FLASK third deposit succeeds")
 committed=g.export_snapshot()
 t.check(not t.action(g,"flask",{"op":"deposit"}).ok and g.state==committed,"FLASK fourth deposit refuses without resource changes")
 t.check(["tick","round","energy","rng","charge","temporary_mana","combat"].all(func(key):return g.state[key]==before[key]),"FLASK storage costs no turn or energy and cannot trigger mana-spend relics")
 for i in range(3): t.check(t.action(g,"flask",{"op":"withdraw"}).ok,"FLASK withdrawal allowance is independent of deposits")
 t.check(g.state.mana==100 and g.state.flask_mana==0 and g.state.flask_deposits==3 and g.state.combat.flask_withdrawals==3,"FLASK transfers use separate three-use allowances")
 g.state.mana=70;g.state.flask_mana=30;committed=g.export_snapshot()
 var denied=t.find_action(g,"flask",{"op":"withdraw"},false)
 t.check(not denied.valid and not g.dispatch(g.command(denied.payload,g.state.version),g.state.version).ok and g.state==committed,"FLASK fourth withdrawal rejects despite available mana and capacity")
 var twin=Game.new(42)
 t.check(twin.restore_snapshot(committed).ok and not t.find_action(twin,"flask",{"op":"withdraw"},false).valid,"FLASK snapshot preserves exhausted withdrawal allowance")
 var restored=twin.export_snapshot()
 for invalid in [-1,4,"3"]:
  var broken=committed.duplicate(true);broken.combat.flask_withdrawals=invalid
  t.check(not twin.restore_snapshot(broken).ok and twin.state==restored,"FLASK corrupt withdrawal counter rejects atomically")
 var old=committed.duplicate(true);old.combat.erase("flask_withdrawals")
 t.check(twin.restore_snapshot(old).ok and t.find_action(twin,"flask",{"op":"withdraw"}).valid,"FLASK older snapshot without new counter defaults to unused")
 t.action(g,"end")
 g.state.posture="sit"
 t.check(g.state.flask_deposits==0 and g.state.combat.flask_withdrawals==0 and t.action(g,"flask",{"op":"deposit"}).ok and t.action(g,"flask",{"op":"withdraw"}).ok,"FLASK actual next turn restores both allowances")
 g=Game.new(42);g.state.mana=3.5;g.state.flask_mana=1000000.0
 t.check(t.action(g,"flask",{"op":"deposit"}).ok and g.state.mana==0 and g.state.flask_mana==1000003.5,"FLASK partial deposit preserves fractional mana and has no capacity limit")
 g.state.mana=98.5
 t.check(t.action(g,"flask",{"op":"withdraw"}).ok and g.state.mana==100 and g.state.flask_mana==1000002,"FLASK withdrawal draws only missing mana near the personal cap")
 for grade in [1,2]:
  g=Game.new(42);g.state.mana=40;g.state.flask_mana=9
  g._install_template("mouth_band","mouth",16,16,false,"fixture",grade)
  var expected=g.Consumables.amount(g,"mana_potion",9)
  t.check(t.action(g,"flask",{"op":"withdraw"}).ok and g.state.flask_mana==0 and g.state.mana==40+expected and expected==(5 if grade==1 else 4),"FLASK odd mouth reduction uses potion rounding boundary")
  g.state.mana=99.5;g.state.flask_mana=10
  t.check(t.action(g,"flask",{"op":"withdraw"}).ok and g.state.mana==100 and g.state.flask_mana==(9 if grade==1 else 8),"FLASK fractional deficit remains refillable under both potion rounding rules")
 g=Game.new(42);g.state.mana=40;g.state.flask_mana=50
 g.add_fixture("upper_arm",4);g.add_fixture("forearm",4);g.add_fixture("fingers",8)
 committed=g.export_snapshot()
 t.check(not t.action(g,"flask",{"op":"withdraw"}).ok and g.state==committed,"FLASK standing follows potion arm and grip restrictions")
 t.check(t.action(g,"flask",{"op":"deposit"}).ok,"FLASK deposit is still possible with bound hands")
 g.state.posture="sit"
 for i in range(3):t.check(t.action(g,"flask",{"op":"withdraw"}).ok,"FLASK seated withdrawal bypasses grip within its three-use allowance")
 g=Game.new(42);g._finish_battle();g.state.mana=70
 t.check(t.action(g,"flask",{"op":"deposit"}).ok and g.state.phase=="reward","FLASK remains usable on reward page")
 g=Game.new(42);g.Pressure.gain(g,100,"fixture")
 before=g.export_snapshot()
 t.check(g.state.overloaded and t.action(g,"flask",{"op":"deposit"}).ok and g.state.tick==before.tick and g.state.overloaded,"FLASK deposit remains available during interruption without advancing it")
 g=Game.new(42);t.check(shop(g),"FLASK enters shop through actual travel")
 g.state.mana=1;g.state.flask_mana=300;g.state.temporary_mana=1000
 g._install_template("mouth_band","mouth",16,16,false,"fixture",3)
 var offer=t.find_action(g,"service",{"op":"take","payment":"flask"});var price=offer.mana
 before=g.export_snapshot()
 t.check(not t.find_action(g,"service",{"op":"take","index":offer.payload.index,"payment":"self"}).valid and offer.valid,"FLASK shop rejects temporary mana despite plentiful independent balance")
 t.check(g.dispatch(g.command(offer.payload,g.state.version),g.state.version).ok and g.state.flask_mana==300-price and g.state.mana==1 and g.state.temporary_mana==1000,"FLASK shop pays full price despite blocked mouth and spell discounts")
 t.check(g.state.tick==before.tick and g.state.flask_deposits==before.flask_deposits,"FLASK purchase cannot refresh turn deposit limit")
 committed=g.export_snapshot()
 t.check(not g.dispatch(g.command(offer.payload,g.state.version),g.state.version).ok and g.state==committed,"FLASK sold goods cannot charge either currency again")
 var target=g.add_fixture("thigh",4)
 var release=t.find_action(g,"service",{"op":"release","target":target.id,"payment":"flask"})
 var balance=g.state.flask_mana
 t.check(g.dispatch(g.command(release.payload,g.state.version),g.state.version).ok and g._equipment(target.id).is_empty() and g.state.flask_mana==balance-release.mana and g.state.mana==1,"FLASK release service uses the same selected currency")
 var count=g.state.deck.size()
 t.check(t.action(g,"service",{"op":"remove","payment":"flask"}).ok and g.state.deck.size()==count-1 and g.state.mana==1,"FLASK card removal also accepts bottle mana")
 g.state.flask_mana=0
 var item=t.find_action(g,"service",{"op":"take","payment":"flask"});committed=g.export_snapshot()
 t.check(not item.valid and not g.dispatch(g.command(item.payload,g.state.version),g.state.version).ok and g.state==committed,"FLASK insufficient payment rolls back item and all resources")
 outside_battle(t)
 prison_limits(t)
 var loc=preload("res://ui/localization.gd").new();loc.set_locale("en_US")
 t.check(loc.display("本回合已存入3次。")=="Already deposited 3 times this turn." and loc.display("本回合已取出3次。")=="Already withdrawn 3 times this turn.","FLASK English rejection reasons use current shared limit")
 t.check(loc.display("存入10魔力，战斗外不限次数。")=="Store 10 mana. Unlimited uses outside battle." and loc.display("本回合可取出2次")=="2 withdrawals remaining this turn","FLASK English detail distinguishes unlimited use and remaining withdrawals")
 t.check(loc.display(g.ManaFlask.withdraw_detail(g,{"drawn":10,"restored":10,"remaining":3,"limited":true}))=="Draw 10 mana to restore 10 mana. 3 withdrawals remaining this turn." and loc.display(g.ManaFlask.withdraw_detail(g,{"drawn":10,"restored":5,"limited":false}))=="Draw 10 mana to restore 5 mana. Unlimited uses outside battle.","FLASK complete English withdrawal tooltips preserve amounts and phase limits")

static func outside_battle(t) -> void:
 var g=Game.new(42)
 for i in range(3):
  t.action(g,"flask",{"op":"deposit"});t.action(g,"flask",{"op":"withdraw"})
 g._finish_battle()
 t.check(g.state.phase=="reward" and not g.ManaFlask.view(g).limited,"FLASK victory immediately lifts both limits before combat cleanup")
 for i in range(5):
  t.check(t.action(g,"flask",{"op":"deposit"}).ok and t.action(g,"flask",{"op":"withdraw"}).ok,"FLASK rewards allow repeated transfers with exhausted battle counters")
 t.check(g.state.flask_deposits==3 and g.state.combat.flask_withdrawals==3,"FLASK outside transfers do not change battle counters")
 t.action(g,"reward",{"type":"skip"})
 t.check(g.state.phase=="prepare" and g.ManaFlask.view(g).limit==3 and not g.ManaFlask.view(g).withdraw_limited,"FLASK preparation limits deposits only despite retaining combat state")
 preparation_transfers(t,g)
 t.check(t.action(g,"end").ok and g.state.phase=="prepare" and g.ManaFlask.remaining(g,"deposit")==3,"FLASK next preparation turn restores three deposits")
 t.check(shop(g),"FLASK outside-limit fixture reaches shop through travel")
 for i in range(5): t.check(t.action(g,"flask",{"op":"deposit"}).ok and t.action(g,"flask",{"op":"withdraw"}).ok,"FLASK shop permits more than three transfers")
 g._apply_transition("room_enter",{"room":"entrance"})
 g._start_battle()
 t.check(g.state.phase=="battle" and g.ManaFlask.view(g).limited and g.ManaFlask.remaining(g,"deposit")==3 and g.ManaFlask.remaining(g,"withdraw")==3,"FLASK new battle starts with fresh independent allowances")
 g=Game.new(42);g._start_rest();t.action(g,"rest_begin")
 g.state.mana=50;g.state.flask_mana=100
 var before=g.export_snapshot()
 for i in range(5): t.check(t.action(g,"flask",{"op":"deposit"}).ok and t.action(g,"flask",{"op":"withdraw"}).ok,"FLASK rest allows repeated transfers outside combat")
 t.check(g.state.tick==before.tick and g.state.flask_deposits==before.flask_deposits and g.state.combat==before.combat,"FLASK rest transfers preserve turn and combat counters")

static func prison_limits(t) -> void:
 var Prison=preload("res://tests/prison_cases.gd")
 var g=Prison.intake(t);Prison.clear_fixture(g)
 g.state.mana=50.0;g.state.flask_mana=100.0
 var tick=g.state.tick
 t.check(g.ManaFlask.view(g).limit==1 and not g.ManaFlask.view(g).withdraw_limited,"FLASK cell limits deposits only")
 t.check(t.action(g,"flask",{"op":"deposit"}).ok and g.state.mana==40 and g.state.flask_mana==110 and g.state.flask_deposits==1,"FLASK cell deposit keeps ten-mana transfer and spends one use")
 var saved=g.export_snapshot()
 var denied=t.find_action(g,"flask",{"op":"deposit"},false)
 t.check(not denied.valid and denied.reason=="本回合已存入1次。" and not g.dispatch(g.command(denied.payload,g.state.version),g.state.version).ok and g.state==saved,"FLASK second cell deposit rejects atomically with one-use reason")
 var twin=Game.new(42)
 t.check(twin.restore_snapshot(saved).ok and not t.find_action(twin,"flask",{"op":"deposit"},false).valid,"FLASK loading cell snapshot cannot refresh used deposit")
 for i in range(5): t.check(t.action(g,"flask",{"op":"withdraw"}).ok,"FLASK cell withdrawal remains unlimited after deposit")
 t.check(g.state.flask_deposits==1 and int(g.state.combat.get("flask_withdrawals",0))==0 and g.state.tick==tick,"FLASK cell withdrawals do not refresh deposit or advance time")
 t.check(t.action(g,"end").ok and g.state.phase=="prison" and g.state.tick==tick+1 and g.ManaFlask.remaining(g,"deposit")==1,"FLASK next real cell turn restores deposit")
 g.state.mana=3.5
 t.check(t.action(g,"flask",{"op":"deposit"}).ok and g.state.mana==0 and not t.find_action(g,"flask",{"op":"deposit"},false).valid,"FLASK partial cell deposit still consumes the one use")
 Prison.inspect(t,g)
 g.state.mana=50.0;g.state.flask_mana=100.0
 for i in range(5): t.check(t.action(g,"flask",{"op":"deposit"}).ok and t.action(g,"flask",{"op":"withdraw"}).ok,"FLASK non-turn inspection is not cell exploration")
 g.state.posture="stand"
 t.check(t.action(g,"prison",{"action":"resist"}).ok and g.state.phase=="battle","FLASK boundary enters real guard resistance")
 for i in range(3): t.check(t.action(g,"flask",{"op":"deposit"}).ok and t.action(g,"flask",{"op":"withdraw"}).ok,"FLASK resistance retains three independent uses")
 t.check(not t.find_action(g,"flask",{"op":"deposit"},false).valid and not t.find_action(g,"flask",{"op":"withdraw"},false).valid,"FLASK resistance rejects fourth transfer")
 g.state.enemies[0].hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":g.state.enemies[0].id}).ok and g.state.phase=="reward","FLASK guard defeat enters actual rewards")
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare","FLASK guard rewards enter preparation")
 preparation_transfers(t,g)
 t.check(t.action(g,"finish_prepare").ok and g.state.phase=="prison" and g.ManaFlask.remaining(g,"deposit")==1,"FLASK return from guard preparation starts a fresh one-use cell turn")

static func preparation_transfers(t,g) -> void:
 g.state.mana=60.0;g.state.flask_mana=100.0
 var tick=g.state.tick
 for i in range(3): t.check(t.action(g,"flask",{"op":"deposit"}).ok,"FLASK preparation allows each of three deposits")
 var saved=g.export_snapshot()
 var denied=t.find_action(g,"flask",{"op":"deposit"},false)
 t.check(not denied.valid and denied.reason=="本回合已存入3次。" and not g.dispatch(g.command(denied.payload,g.state.version),g.state.version).ok and g.state==saved,"FLASK fourth preparation deposit rejects atomically")
 var twin=Game.new(42)
 t.check(twin.restore_snapshot(saved).ok and not t.find_action(twin,"flask",{"op":"deposit"},false).valid,"FLASK restore preserves exhausted preparation deposit allowance")
 for i in range(5): t.check(t.action(g,"flask",{"op":"withdraw"}).ok,"FLASK preparation permits more than three withdrawals after deposits exhaust")
 t.check(g.state.mana==80 and g.state.flask_mana==80 and g.state.flask_deposits==3 and int(g.state.combat.get("flask_withdrawals",0))==0 and g.state.tick==tick,"FLASK preparation transfers preserve time and withdrawal allowance without refreshing deposits")
