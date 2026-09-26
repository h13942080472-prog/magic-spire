extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const Follow=preload("res://tests/follow_through_cases.gd")
const TYPE="magic_hand"

static func fresh():
 var g=Game.new(42);g._discard_end();g.state.wall="normal"
 return g

static func use(t,g,target: Dictionary) -> Dictionary:
 var card=Give.give(g,TYPE)
 return t.action(g,"card",{"uid":card.uid,"free":false,"target":target.id})

static func run(t) -> void:
 free_attacks(t)
 fallback_priority(t)
 for amount in [10.0,8.0,4.0,1.0]:
  var g=fresh();var target=g.add_fixture("wrist",amount)
  var card=Give.give(g,TYPE);var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false})
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(c.valid and c.cost==1 and c.mana==20 and TYPE in g.Cards.Rules.UNCOMMON and g.Cards.Rules.definition_reason(g.Cards.Rules.SPECS[TYPE])=="" and g.state==before,"HAND uncommon targeted mouth spell costs one energy and twenty mana with readonly preview")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"HAND stale card refuses all loosening and payment")
  var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version);var hits=Follow.hits(g)
  t.check(result.ok and hits.size()==g.tier(amount,10) and hits.all(func(h):return h.target==target.id and h.before>h.after) and g._equipment(target.id).is_empty(),"HAND lowers one tier at a time, stops early only after final target is removed")
  t.check(g.state.energy==2 and g.state.mana==80 and g.state.exhaust.any(func(x):return x.uid==card.uid) and g.state.card_chain.is_empty() and g.state.logs.filter(func(e):return e.data.has("spell")).size()==1,"HAND whole cascade casts, pays and exhausts once without manual continuation")
  t.check(g.state.logs.filter(func(e):return e.data.has("lower_steps")).all(func(e):return e.text.begins_with("魔术手：") and e.data.lower_steps==1),"HAND loosening logs use the real card name and per-step amount")
 var g=fresh()
 var inner=Follow.piece(g,"thigh","thigh_root",4,10)
 var target=Follow.piece(g,"thigh","thigh_root",4,10,1)
 var middle=Follow.piece(g,"thigh","mid_thigh",4,10)
 var calf=g.add_fixture("calf",4);var wrist=g.add_fixture("wrist",4)
 t.check(use(t,g,target).ok and Follow.hits(g).map(func(h):return h.target)==[target.id,inner.id,middle.id] and not g._equipment(calf.id).is_empty() and not g._equipment(wrist.id).is_empty(),"HAND exact point and body part precede region and whole-body fallback without splash")
 g=fresh();target=g.add_fixture("thigh",4);calf=g.add_fixture("calf",4);wrist=g.add_fixture("wrist",4)
 t.check(use(t,g,target).ok and Follow.hits(g).map(func(h):return h.target)==[target.id,calf.id,wrist.id],"HAND crosses to other regions only after original region has no legal targets")
 g=fresh();target=g.add_fixture("wrist",4);var locked=g.add_fixture("ankle",8,10,true)
 t.check(use(t,g,target).ok and Follow.hits(g).size()==3 and g._equipment(locked.id).is_empty(),"HAND direct loosening retains existing ability to loosen locked equipment")
 g=fresh();inner=g.add_fixture("wrist",4);g.add_fixture("wrist",8,10,false,1)
 var blocked_card=Give.give(g,TYPE);var blocked=t.find_action(g,"card",{"uid":blocked_card.uid,"target":inner.id,"free":false});var blocked_before=g.export_snapshot()
 t.check(not blocked.valid and blocked.reason.contains("覆盖") and not g.dispatch(g.command(blocked.payload,g.state.version),g.state.version).ok and g.state==blocked_before,"HAND cannot bypass a covering outer layer on initial selection")
 for free in [false,true]:
  g=fresh();target=g.add_fixture("wrist",10);var card=Give.give(g,TYPE)
  g.state.pressure=75
  var c=t.find_action(g,"card",{"uid":card.uid,"free":free});var rng=g.state.rng.magic
  while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,TYPE)).winning_rolls: rng=g.state.rng.magic
  g.state.rng.magic=rng;var before=g.export_snapshot()
  t.check(c.mana==g._mana_cost(20) and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and is_equal_approx(g.state.mana,before.mana-c.mana*0.5) and g.state.energy==2,"HAND either face follows current pressure cost and failure probability")
  t.check(g.state.hand==before.hand and g.state.exhaust==before.exhaust and g.state.card_buff_uses.is_empty() and g._equipment(target.id).durability==10,"HAND failed cast leaves card in hand and grants neither loosening nor free attacks")
  g=fresh();target=g.add_fixture("wrist",8);card=Give.give(g,TYPE);g.state.mana=19
  c=t.find_action(g,"card",{"uid":card.uid,"free":free});before=g.export_snapshot()
  t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"HAND both faces reject insufficient mana atomically")
  g.state.mana=0;g.state.temporary_mana=20
  t.check(t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.state.temporary_mana==0 and g.state.mana==0,"HAND both faces accept temporary mana through existing payment")
  g=fresh();g.add_fixture("wrist",8);card=Give.give(g,TYPE);g._install_template("mouth_band","mouth",24,24,false,"fixture",3,0)
  before=g.export_snapshot();c=t.find_action(g,"card",{"uid":card.uid,"free":free})
  t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"HAND mouth casting obstruction blocks either face before payment")
 g=fresh();var card=Give.give(g,TYPE)
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.card_buff_uses.get("magic_hand_free")==2 and g.state.evasion==0 and g.state.energy==2 and g.state.mana==80 and g.state.exhaust.any(func(x):return x.uid==card.uid),"HAND free mouth spell grants two free-state hand attacks and exhausts itself")
 var request={"kind":"install","template":"rope","slot":"wrist","grade":1,"tier":2}
 var result=g.Application.execute_concrete(g,request,"enemy")
 t.check(result.evaded==0 and not g.state.equipment.is_empty() and g.state.card_buff_uses.get("magic_hand_free")==2,"HAND no longer evades incoming restraints or spends attack uses on them")
 g._finish_battle();t.check(g.state.card_buff_uses.get("magic_hand_free")==2,"HAND attack preparation survives victory")
 t.action(g,"reward",{"type":"skip"});t.action(g,"finish_prepare")
 t.check(g.state.card_buff_uses.is_empty() and "magic_hand_free" not in g.state.card_buffs,"HAND attack preparation expires after preparation")
 var info=g.B.card_info(TYPE);var meta=g.B.card_metadata(TYPE)
 t.check(info[1]=="耗魔20。降紧3。超级顺延。消耗。" and info[2].contains("下2次手部体术") and info[2].ends_with("消耗。") and meta.face_keywords.bound.any(func(term):return term.name=="超级顺延"),"HAND concise printed values and super follow-through keyword match formal effects")

static func free_attacks(t) -> void:
 var Attack=preload("res://tests/basic_attack_cases.gd")
 for type in [TYPE,"magic_hand_gift"]:
  for attack in ["strike","heavy"]:
   for form in [0,1]:
    var g=fresh();var card=Give.give(g,type)
    t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok,"HAND both original and gift grant real counted buff")
    g.state.energy=10;g.state.strength=2;g.state.charge=1
    var enemy=g.state.enemies[0];enemy.hp=300;enemy.max_hp=300
    var free_offer=Attack.attack(t,g,attack,form)
    for slot in ["upper_arm","forearm","wrist","palm","fingers","thigh","calf","ankle","foot","toes"]: g.add_fixture(slot,10)
    var equipment=g.state.equipment.duplicate(true)
    var c=Attack.attack(t,g,attack,form);var before=g.export_snapshot()
    t.check(g.level("arms")>=3 and c.valid and c.payload.damage==free_offer.payload.damage and c.payload.hits==free_offer.payload.hits,"HAND fully restrained physical attack matches free-state damage including strength and charge")
    g.command_facts();g.get_view()
    t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"HAND readonly and stale requests do not spend charges")
    t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.card_buff_uses.get("magic_hand_free")==1 and g._enemy(enemy.id).hp==300-c.payload.damage*c.payload.hits and g.state.equipment==equipment,"HAND whole multi-hit attack spends one use and leaves equipment unchanged")
    var row=g.get_view().statuses.filter(func(s):return s.id=="power_magic_hand_free")
    t.check(row.size()==1 and row[0].badge=="1" and row[0].value=="剩余1次","HAND status shows remaining use")
    t.check(g.Cards.validate(g)=="","HAND one remaining use has a valid current-state representation")
    if attack=="heavy":
     var limited=Attack.attack(t,g,attack,form)
     t.check(not limited.valid and limited.reason.contains("本回合"),"HAND heavy per-turn limit stays active")
    g.state.posture="sit";c=Attack.attack(t,g,"strike",0);before=g.export_snapshot()
    t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"HAND still requires standing and rejected use preserves buff")
    g.state.posture="stand";g.state.energy=0;c=Attack.attack(t,g,"strike",0);before=g.export_snapshot()
    t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"HAND does not waive energy cost")
    g.state.energy=10;g.state.weakness_turns=1
    t.check(not Attack.attack(t,g,"strike",0).valid,"HAND unrelated weakness still blocks attacks")
    g.state.weakness_turns=0
    c=Attack.attack(t,g,"strike",1)
    t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.card_buff_uses.is_empty() and "magic_hand_free" not in g.state.card_buffs and not Attack.attack(t,g,"strike",0).valid,"HAND second use expires and restores real restraint restrictions")
 var g=fresh();var card=Give.give(g,TYPE)
 t.action(g,"card",{"uid":card.uid,"free":true});g.state.energy=10
 var c=Attack.attack(t,g,"kick",1)
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.card_buff_uses.get("magic_hand_free")==2,"HAND leg attacks do not spend uses")
 c=Attack.attack(t,g,"fireball",0)
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.card_buff_uses.get("magic_hand_free")==2,"HAND fireball does not spend uses")
 c=Attack.attack(t,g,"strike",0);t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"HAND consume one use before refresh")
 card=Give.give(g,TYPE)
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.card_buff_uses.get("magic_hand_free")==3,"HAND repeated card adds two to the remaining use")
 t.action(g,"end")
 t.check(g.state.card_buff_uses.get("magic_hand_free")==3,"HAND unused charges survive next turn")
 var before=g.export_snapshot();g.state.card_buff_uses.magic_hand_free=-1
 t.check(g.Cards.validate(g)!="","HAND negative counter rejected")
 g.state.card_buff_uses.magic_hand_free=0
 t.check(g.Cards.validate(g)!="","HAND zero counter must be removed with buff")
 g.state.card_buff_uses.clear()
 t.check(g.Cards.validate(g)!="","HAND active buff requires its counter")
 g.state=before.duplicate(true);g.state.card_buffs.erase("magic_hand_free")
 t.check(g.Cards.validate(g)!="","HAND orphan counter rejected")
 g.state=before;g.Guard.capture(g,g.state.enemies[0])
 t.check(g.state.card_buff_uses.is_empty(),"HAND capture clears remaining charges")

static func fallback_priority(t) -> void:
 var g=fresh();var target=g.add_fixture("thigh",4);var wrist=g.add_fixture("wrist",4)
 var finger=g.add_fixture("fingers",4,10,false,0,"cord");var eye=g.add_fixture("eyes",4)
 t.check(use(t,g,target).ok and Follow.hits(g).map(func(h):return h.target)==[target.id,wrist.id,finger.id] and not g._equipment(eye.id).is_empty(),"SUPER outside original region first chooses wrist, then resumes normal arm continuation")
 var seen={}
 for seed_value in range(8):
  g=fresh();g.state.rng.card_target=seed_value;g.state.sure_cast=true
  target=g.add_fixture("thigh",4);var mouth=g.add_fixture("mouth",1)
  finger=g.add_fixture("fingers",4,10,false,0,"cord");eye=g.add_fixture("eyes",4)
  var before=g.export_snapshot();g.command_facts();g.get_view()
  t.check(g.state==before,"SUPER preview never chooses a random fallback")
  t.check(use(t,g,target).ok,"SUPER fallback batch commits")
  var hits=Follow.hits(g)
  t.check(hits.size()==3 and hits[1].target in [mouth.id,finger.id],"SUPER mouth and fingers outrank other body locations only during whole-body fallback")
  seen[hits[1].slot]=true
 t.check(seen.has("mouth") and seen.has("fingers"),"SUPER equal-priority fallback uses random ties rather than list order")
