extends RefCounted
const Base=preload("res://tests/witch_expansion_cases.gd")
const Give=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func run(t) -> void:
 _card_revision(t)
 _boundaries(t)
 for side in [false,true]:
  for grade in [1,2,3]:
   for tier in [1,2,3]:
    var g=Base.fresh();g.state.energy=0
    t.check(Base.play(t,g,"witch_binding_lure",side).ok and g.state.energy==0,"INDUCTION both skill faces play at zero energy")
    var part="hand" if side else "mouth"
    var request={"kind":"install","template":"rope" if side else "mouth_band","slot":"wrist" if side else "mouth","grade":grade,"tier":tier,"variant":0}
    var before=g.state.equipment.size();var outcome=g.Application.execute_concrete(g,request,"fixture")
    t.check(outcome.evaded==1 and g.state.equipment.size()==before+1 and not g.occupied(request.slot),"INDUCTION legal targeted application is evaded and redirects exactly one piece")
    var item=g.state.equipment.back()
    t.check(item.grade==grade and g.tier(item.durability,item.maximum)==tier and g.Character.restraint_part(g,item.slot)!=part,"INDUCTION redirect inherits incoming grade and tightness outside protected region")
    t.check("witch_induction_"+part in g.state.card_buffs,"INDUCTION unlimited protection is not consumed by a dodge")
 var g=Base.fresh()
 var spec=g.Cards.Rules.SPECS.witch_binding_lure
 t.check(spec.rarity=="uncommon" and spec.card_type=="skill" and spec.bound_modes==["self","self"] and not g.Cards.Rules.free_effect("witch_binding_lure",true),"INDUCTION uncommon card declares two bound skill faces")
 t.check(g.Character.reward_member(g,"witch_binding_lure","witch") and not g.Character.reward_member(g,"witch_binding_lure","original"),"INDUCTION reward eligibility is witch-exclusive")
 Base.play(t,g,"witch_binding_lure");Base.play(t,g,"witch_binding_lure",true);Base.play(t,g,"witch_binding_lure",true)
 t.check(g.state.card_buffs.count("witch_induction_hand")==1 and "witch_induction_mouth" in g.state.card_buffs,"INDUCTION faces coexist and repeated same face does not multiply redirects")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and not g.dispatch(g.command({"kind":"card","uid":"missing"},g.state.version),g.state.version).ok and g.state==before,"INDUCTION preview and rejected command leave state and random stream intact")
 var mouth={"kind":"install","template":"mouth_band","slot":"mouth","grade":2,"tier":3,"variant":0}
 g.state.witch_charges.hand=4;g.state.witch_charges.mouth=4
 for n in range(2):
  var result=g.Application.execute_concrete(g,mouth,"fixture")
  t.check(result.evaded==1 and not g.occupied("mouth") and g.state.witch_charges.hand==4 and g.state.witch_charges.mouth==4,"INDUCTION repeats and redirected cost bypasses preparation evasion")
 t.check(g.state.equipment.all(func(e):return g.Character.restraint_part(g,e.slot) not in ["mouth","hand"]),"INDUCTION dual protection redirects outside both protected regions")
 var restored=Save.roundtrip(t,g,"induction protection")
 if restored!=null:
  t.check(restored.Application.execute_concrete(restored,mouth,"fixture").evaded==1,"INDUCTION loaded protection still intercepts")
 g.Cards.expire_turn_buffs(g)
 t.check("witch_induction_mouth" in g.state.card_buffs,"INDUCTION ordinary turn end preserves enemy-action window")
 g._begin_player_turn()
 t.check(not g.state.card_buffs.any(func(id):return id.begins_with("witch_induction_")),"INDUCTION next player turn start expires both faces")
 g=Base.fresh();Base.play(t,g,"witch_binding_lure")
 var unrelated={"kind":"install","template":"rope","slot":"wrist","grade":1,"tier":1,"variant":0}
 t.check(g.Application.execute_concrete(g,unrelated,"fixture").ok and g.occupied("wrist"),"INDUCTION other incoming regions are unaffected")
 before=g.export_snapshot();var invalid=mouth.duplicate(true);invalid.slot="eyes"
 t.check(not g.Application.execute_concrete(g,invalid,"fixture").ok and g.state==before,"INDUCTION structurally invalid requests cannot trigger or draw random")
 g=Base.fresh();Base.play(t,g,"witch_binding_lure");g.state.evasion=1
 t.check(g.Application.execute_concrete(g,mouth,"fixture").evaded==1 and g.state.evasion==0 and g.state.equipment.is_empty(),"INDUCTION existing generic evasion retains first priority")
 t.check(g.Application.execute_concrete(g,mouth,"fixture",false,[],true).ok and g.occupied("mouth"),"INDUCTION voluntary card costs are not intercepted")
 g=Base._patience_encounter();Base.play(t,g,"witch_binding_lure")
 var enemy=g.state.enemies[0];enemy.intent=g.EnemyPlans.application(["mouth_band"],2,3);enemy.intent.slot="mouth"
 t.check(t.action(g,"end").ok and not g.occupied("mouth") and g.state.equipment.size()==1 and not "witch_induction_mouth" in g.state.card_buffs,"INDUCTION real enemy turn redirects before next-start expiration")
 _presentation(t)

static func _card_revision(t) -> void:
 var g=Base.fresh()
 for original in ["slip","siphon","magic_hand","magic_hand_gift","adaptability","pleasure_conversion"]:
  t.check(g.B.CARD_NAMES["witch_"+original]==g.B.CARD_NAMES[original]+"（魔女）","WITCH renamed local card keeps original identity "+original)
 t.check(g.Cards.Rules.SPECS.witch_accumulation.cost==2 and g.Cards.energy_cost(g,"witch_prepared_chant")==0 and g.Cards.Rules.SPECS.prepared_chant.cost==1,"WITCH revised costs leave original chant unchanged")
 t.check(g.Cards.Rules.SPECS.witch_siphon.rarity=="common" and g.Cards.Rules.SPECS.siphon.rarity=="uncommon" and "witch_siphon" in g.Character.pool(g,g.Cards.Rules.COMMON) and "witch_siphon" not in g.Character.pool(g,g.Cards.Rules.UNCOMMON),"WITCH siphon rarity changes actual reward pools")
 var patience=Give.give(g,"witch_patience");g._discard_end()
 t.check(g.state.hand.any(func(card):return card.uid==patience.uid),"WITCH patience is retained at actual discard step")
 for free in [false,true]:
  g=Base.fresh();var target=g.add_fixture("wrist",8)
  var card=Give.give(g,"witch_magic_slip")
  var unbuffed=g.Cards.face_damage_values(g,card.type,card.uid)
  g.state.witch_focus=9
  t.check(g.Cards.face_damage_values(g,card.type,card.uid)==unbuffed,"WITCH magic slip preview ignores mental focus")
  t.check(t.action(g,"card",{"uid":card.uid,"free":free,"slot":"eyes" if free else "wrist"}).ok and g.state.witch_focus==9,"WITCH successful magic slip does not consume focus on either face")
 for count in [27,28,34,35]:
  for free in [false,true]:
   g=preload("res://tests/game_fixture.gd").new(42,true,"guard",true,false,25,false,false,"witch")
   g.state.energy=30;g.state.relics=[]
   preload("res://tests/guard_cases.gd").bind(g,g.state.enemies[0],80)
   var target=g._install_template("belt","wrist",24.0,24.0,true,"fixture",3,0)
   var card=Give.give(g,g.Character.Expansion.TRAINING[mini(5,count/7)])
   card.practice_plays=count
   for permanent in g.state.deck:
    if permanent.uid==card.uid: permanent.practice_plays=count
   t.check(t.action(g,"card",{"uid":card.uid,"free":free,"target":target.id}).ok,"WITCH training completes with capture present")
   t.check(not g.state.guard_bind.is_empty(),"WITCH training never clears capture as an extra effect "+str([count,free]))
 for count in [21,27,28,34,35]:
  for free in [false,true]:
   g=Base.fresh();g.state.equipment.clear()
   var target=g._install_template("rope","thigh",0.1,10.0,false,"fixture",1,0)
   var distant=g._install_template("rope","wrist",0.1,10.0,false,"fixture",1,0)
   var card=Give.give(g,g.Character.Expansion.TRAINING[mini(5,count/7)])
   card.practice_plays=count
   for permanent in g.state.deck:
    if permanent.uid==card.uid: permanent.practice_plays=count
   t.check(t.action(g,"card",{"uid":card.uid,"free":free,"target":target.id}).ok,"WITCH training follow-through dispatches on both bound faces")
   t.check(g._equipment(target.id).is_empty() and g._equipment(distant.id).is_empty()==(count>=28),"WITCH level four crosses body regions but level three and the upgrading play remain local "+str([count,free]))
   var evolved=g.Cards.instance(g,card.uid)
   var keywords=g.Cards.metadata(g,evolved.type,evolved.uid).face_keywords["free" if free else "bound"]
   t.check(keywords.any(func(term):return term.name=="超级顺延")== (count+1>=28),"WITCH evolved physical card exposes its current follow-through keyword")
 g=Base.fresh()
 t.check(g.Character.reward_member(g,"witch_magic_circle","witch") and not g.Character.reward_member(g,"witch_magic_circle","original"),"CIRCLE is witch-exclusive uncommon reward")
 for blocked in [false,true]:
  var limited=Base.fresh()
  for slot in (["upper_arm","forearm","wrist","palm","fingers"] if blocked else ["wrist","palm"]): limited.add_fixture(slot,4)
  var card=Give.give(limited,"witch_magic_circle")
  var candidate=t.find_action(limited,"card",{"uid":card.uid,"free":true})
  var snapshot=limited.export_snapshot()
  t.check(limited.level("arms")== (4 if blocked else 3) and candidate.valid==not blocked,"CIRCLE free activation accepts level three and rejects level four")
  if blocked:
   t.check(not limited.dispatch(limited.command(candidate.payload,limited.state.version),limited.state.version).ok and limited.state==snapshot,"CIRCLE failed body requirement preserves resources and powers")
   t.check(t.find_action(limited,"card",{"uid":card.uid,"free":false}).valid,"CIRCLE bound face has no upper-body restriction")
  else: t.check(limited.dispatch(limited.command(candidate.payload,limited.state.version),limited.state.version).ok,"CIRCLE level-three free ability really activates")
 t.check(Base.play(t,g,"witch_magic_circle",true).ok,"CIRCLE free power enters through formal card action")
 g.state.mana=0;g.state.temporary_mana=0
 for part in g.Character.PARTS:
  var c=t.find_action(g,"attack",{"type":"witch_"+part,"form":0})
  t.check(c.valid and c.mana==0 and c.cost==1 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.witch_charges[part]==1 and g.state.mana==0,"CIRCLE all preparation actions work without mana "+part)
 t.check(t.find_action(g,"attack",{"type":"witch_hand","form":1}).mana==5,"CIRCLE release still costs mana")
 var restored=Save.roundtrip(t,g,"circle preparation")
 if restored!=null: t.check(t.find_action(restored,"attack",{"type":"witch_hand","form":0}).mana==0,"CIRCLE power survives save restore")
 g=Base.fresh();Base.play(t,g,"witch_magic_circle")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and g.state.card_buff_uses.witch_circle_skills==3,"CIRCLE previews preserve charge count")
 t.check(Base.play(t,g,"witch_magic_circle",true).ok and g.state.card_buff_uses.witch_circle_skills==3,"CIRCLE ability face does not spend skill discount")
 t.check(Base.play(t,g,"witch_mana_transfer",true).ok and g.state.card_buff_uses.witch_circle_skills==3,"CIRCLE magic face of mixed card does not spend skill discount")
 restored=Save.roundtrip(t,g,"circle skill charges")
 if restored!=null: t.check(restored.state.card_buff_uses.witch_circle_skills==3,"CIRCLE remaining skill uses survive restore")
 for index in range(3):
  var type="witch_binding_lure" if index==0 else "witch_slip"
  var card=Give.give(g,type)
  var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
  before=g.export_snapshot()
  t.check(c.valid and c.cost==0 and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"CIRCLE discounted skill preview and stale rollback")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.card_buff_uses.get("witch_circle_skills",0)==2-index,"CIRCLE each skill including natural zero-cost spends exactly one use")
 t.check(g.Cards.energy_cost(g,"witch_slip",true)==1,"CIRCLE fourth skill returns to normal cost")
 var x_game=Base.fresh();Base.play(t,x_game,"witch_magic_circle");x_game.state.energy=3
 var x_card=Give.give(x_game,"self_binding")
 var x_candidate=t.find_action(x_game,"card",{"uid":x_card.uid,"free":true})
 t.check(x_candidate.valid and x_candidate.cost==2 and x_candidate.payload.x==2 and x_game.dispatch(x_game.command(x_candidate.payload,x_game.state.version),x_game.state.version).ok and x_game.state.energy==1 and x_game.state.card_buff_uses.witch_circle_skills==2,"CIRCLE X skill discounts actual payment and uses the same paid X in its effect")
 Base.play(t,g,"witch_magic_circle");Base.play(t,g,"witch_magic_circle")
 t.check(g.state.card_buff_uses.witch_circle_skills==6 and g.Cards.energy_cost(g,"witch_slip",true)==0,"CIRCLE repeated bound powers add uses without stacking per-card reduction")
 g._begin_player_turn()
 t.check(g.state.card_buff_uses.witch_circle_skills==6,"CIRCLE unused skills persist to next turn")
 g.Cards.end_powers(g)
 t.check(not g.Character.Expansion.free_preparation(g) and not "witch_circle_skills" in g.state.card_buffs,"CIRCLE session cleanup removes both effects")

static func _presentation(t) -> void:
 var g=Base.fresh()
 for count in [0,6,7,27,28,34,35,55]:
  var type=g.Character.Expansion.TRAINING[mini(5,count/7)]
  var card=Give.give(g,type);card.practice_plays=count
  var metadata=g.Cards.metadata(g,type,card.uid)
  var expected="已完成全部升级" if count>=35 else "%d／%d次" % [count,(int(count/7)+1)*7]
  t.check(metadata.note.contains(expected),"WITCH training tooltip exposes physical-instance progress: "+str(count))
 for part in g.Character.PARTS:
  var c=t.find_action(g,"attack",{"type":"witch_"+part,"form":0})
  t.check(c.label==g.Character.NAMES[part]+"施法" and c.brief_tags=="" and c.cost==1 and c.mana==5,"WITCH preparation labels retain real costs without redundant body and stacks")
 g=Base.fresh();Base.play(t,g,"witch_authority",true)
 t.check(g.get_view().end_turn_locked,"WITCH authoritative end lock projects independently of text")
 g.state.enemies.clear();g._finish_battle()
 t.check(not g.get_view().end_turn_locked,"WITCH end lock visual clears after victory")
 g=preload("res://tests/game_fixture.gd").new(42,true,"prison_test",true,false,25,false,false,"witch")
 t.check(not g.command_facts().any(func(c):return c.payload.kind=="attack" and c.payload.type=="fireball"),"WITCH prison offers no original-character fireball")

static func _boundaries(t) -> void:
 var g=Base.fresh()
 g.Cards.grant_buff(g,"witch_induction_hand")
 var spec={"pool":"composite","templates":[{"family":"glove","variant":"short","straps":"straight"}],"grade":2,"tier":3}
 var request=g.Application.choose(g,spec,"probe")
 t.check(not request.is_empty() and g.Application._slots(request).size()>1,"composite fixture uses real multi-part coverage")
 var outcome=g.Application.execute_concrete(g,request,"probe")
 t.check(outcome.evaded==1 and g.state.composites.is_empty() and g.state.equipment.size()==1,"composite induction evades whole root and adds exactly one ordinary item")
 var item=g.state.equipment.back()
 t.check(item.grade==2 and g.tier(item.durability,item.maximum)==3 and g.Character.restraint_part(g,item.slot)!="hand","composite redirected item inherits grade and tier outside protected region")
 t.check(g.validate()=="","composite outcome validates")

 g=Base.fresh()
 var fill={"templates":g.Equipment.TEMPLATES.keys(),"slots":g.B.SLOTS.filter(func(slot):return slot!="mouth"),"allow_links":false,"grade":2,"tier":3,"replace":false}
 var filled=0
 for n in range(120):
  var selected=g.Application.choose(g,fill,"probe_fill","equipment")
  if selected.is_empty(): break
  var result=g.Application.execute_concrete(g,selected,"probe_fill",false,[],true)
  if not result.ok: break
  filled+=1
 t.check(filled>0 and not g.Application.can_apply(g,fill,"probe_fill"),"full-body fixture has no other legal grade-two ordinary position")
 g.Cards.grant_buff(g,"witch_induction_mouth")
 var mouth={"kind":"install","template":"mouth_band","slot":"mouth","grade":2,"tier":3,"variant":0}
 var before=g.state.equipment.duplicate(true)
 var rng=g.state.rng.duplicate(true)
 outcome=g.Application.execute_concrete(g,mouth,"probe")
 t.check(outcome.evaded==1 and g.state.equipment==before and not g.occupied("mouth"),"no redirect position still evades without installing or replacing equipment")
 t.check(g.state.rng==rng,"empty redirect pool does not advance random stream")
 t.check(g.validate()=="","full-body result validates")

 g=Base.fresh();g.Cards.grant_buff(g,"witch_induction_mouth")
 var restored=Save.roundtrip(t,g,"witch induction boundary")
 if restored!=null:
  var live=g.Application.execute_concrete(g,mouth,"probe")
  var loaded=restored.Application.execute_concrete(restored,mouth,"probe")
  t.check(live==loaded and live.evaded==1,"same incoming application returns identical result after restore")
  t.check(g.state.equipment==restored.state.equipment and g.state.rng==restored.state.rng,"restore preserves exact redirect equipment and random stream")
  t.check(Save.same(g.state,restored.state),"full resulting game state matches uninterrupted run except version")
