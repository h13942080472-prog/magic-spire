extends RefCounted
const Fixture=preload("res://tests/binding_search_cases.gd")
const Give=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Piece=preload("res://tests/follow_through_cases.gd")
const TYPE="liberating_grace"

static func run(t) -> void:
 var g=Fixture.setup()
 var rules=g.Cards.Rules
 t.check(TYPE in g.Character.pool(g,rules.RARE,"original") and TYPE not in g.Character.pool(g,rules.RARE,"witch") and rules.energy_label(TYPE)=="X","GRACE original rare X-cost pool")
 t.check(rules.unique_face(TYPE,true) and not rules.unique_face(TYPE,false) and not g.Enchantments.face_eligible(g,TYPE,"replay",true,3),"GRACE only the free face is unique")
 var bad_spec=rules.SPECS[TYPE].duplicate(true)
 bad_spec.erase("x_cost")
 t.check(rules.definition_reason(bad_spec)!="","GRACE dynamic buff requires an X-cost payment")
 for x in [0,1,2,3,6]:
  g=Fixture.setup()
  var enemy=g.state.enemies[0]
  var args={"type":"strike","form":0,"enemy":enemy.id}
  var base=t.find_action(g,"attack",args).payload.damage
  var card=Give.give(g,TYPE)
  g.state.energy=x
  var fact=t.find_action(g,"card",{"uid":card.uid,"free":true})
  var before=g.export_snapshot()
  t.check(fact.cost==x and fact.payload.x==x and not g.dispatch(g.command(fact.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"GRACE X and stale action rollback "+str(x))
  t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.energy==0 and g.state.exhaust.any(func(c):return c.uid==card.uid),"GRACE free pays all and exhausts "+str(x))
  g.state.energy=3
  var duplicate=Give.give(g,TYPE)
  t.check(not t.action(g,"card",{"uid":duplicate.uid,"free":true}).ok and g.state.card_buff_uses.get("grace_free",-1)==x,"GRACE unique blocks replacement "+str(x))
  var spell=t.find_action(g,"attack",{"type":"fireball","enemy":enemy.id})
  t.check(spell.payload.damage==g.BasicAttacks.fireball_damage(g) and t.action(g,"attack",{"type":"fireball","enemy":g.state.enemies[1].id}).ok and "grace_free" in g.state.card_buffs,"GRACE spell keeps physical multiplier")
  var amount=base*x*0.5
  t.check(t.find_action(g,"attack",args).payload.damage==amount and t.action(g,"attack",args).ok and is_equal_approx(g._enemy(enemy.id).hp,maxf(0.0,enemy.max_hp-amount)) and "grace_free" not in g.state.card_buffs,"GRACE next actual attack matches preview "+str(x))
 g=Fixture.setup()
 t.check(Give.play(t,g,TYPE,true).ok and t.action(g,"end").ok and "grace_free" not in g.state.card_buffs,"GRACE unused free effect expires at turn boundary")
 g=Fixture.setup();g.state.energy=0
 t.check(Give.play(t,g,TYPE,false).ok and "grace_bound" not in g.state.card_buffs and g.state.exhaust.back().type==TYPE,"GRACE zero bound exhausts without creating uses")
 g=Fixture.setup();g.state.energy=2
 t.check(Give.play(t,g,TYPE,false).ok and t.action(g,"end").ok and g.state.card_buff_uses.get("grace_bound")==2,"GRACE bound charges cross a turn")
 g=Save.roundtrip(t,g,"GRACE remaining bound uses")
 var target=Piece.piece(g,"thigh","thigh_root",100,100)
 g.state.energy=10;g.state.charge=0
 var card=Give.give(g,"brace")
 t.check(g.Cards.face_damage_values(g,"brace",card.uid).bound.size()==2 and g.Cards.face_damage_values(g,"brace",card.uid).free.is_empty(),"GRACE extra hit appears only on the escape face")
 var start=target.durability
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id,"free":false}).ok and g.state.card_buff_uses.get("grace_bound")==1,"GRACE one action spends one use")
 t.check(g._equipment(target.id).durability<start and g.state.logs.filter(func(row):return str(row.data.get("action_result","")).begins_with("「绷紧再挣」")).size()==2 and g.state.charge==0,"GRACE appended hit consumes earned charge without granting the on-hit charge again")
 g.state.sure_cast=true
 t.check(Give.play(t,g,"magic_slip",false,{"target":target.id}).ok and "grace_bound" not in g.state.card_buffs,"GRACE magic slip uses the last charge")
 g=Fixture.setup();g.state.energy=2
 t.check(Give.play(t,g,TYPE,false).ok,"GRACE prepare multi-hit")
 target=Piece.piece(g,"thigh","thigh_root",100,100)
 g.state.energy=8
 var old=Piece.hits(g).size()
 t.check(Give.play(t,g,"repeated_strain",false,{"target":target.id}).ok and Piece.hits(g).size()==old+6 and g.state.card_buff_uses.grace_bound==1,"GRACE five-hit follow-through gains a sixth hit and spends one use")
 var knife=Give.give(g,"pocket_knife")
 t.check(t.action(g,"card",{"uid":knife.uid,"target":g.state.enemies[0].id}).ok and g.state.card_buff_uses.grace_bound==1,"GRACE item action preserves escape use")
 var cutter=t.take_item_card(g,"shard")
 t.check(t.action(g,"card",{"uid":cutter,"target":target.id,"free":false}).ok and g.state.card_buff_uses.grace_bound==1,"GRACE an actual cut leaves the remaining use intact")
 g=Fixture.setup();g.state.energy=2
 card=Give.give(g,TYPE);card.enchantment="replay"
 for saved in g.state.deck:
  if saved.uid==card.uid: saved.enchantment=card.enchantment
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.card_buff_uses.grace_bound==4,"GRACE bound replay adds the original X twice")
 g.state.energy=3
 target=Piece.piece(g,"thigh","thigh_root",100,100)
 var other=Piece.piece(g,"thigh","mid_thigh",100,100)
 card=Give.give(g,"brace")
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id,"free":false}).ok and g.state.card_chain.get("remaining")==1,"GRACE extra segment can await a legal target")
 var choice=t.find_action(g,"chain",{"action":"hit","target":other.id})
 var detail=g.candidate_detail(choice)
 t.check(not detail.contains("命中后") and not detail.contains("获得1层蓄力") and not detail.contains("波及：") and not choice.payload.preview.release,"GRACE bonus preview only describes damage")
 var bad_save=g.export_snapshot();bad_save.card_chain.total_hits+=2
 var original=g.export_snapshot()
 t.check(not g.restore_snapshot(bad_save).ok and g.state==original,"GRACE corrupt bonus hit count rejects without replacing state")
 g=Save.roundtrip(t,g,"GRACE pending extra segment")
 t.check(t.action(g,"chain",{"action":"hit","target":other.id}).ok and g.state.card_chain.is_empty() and g._equipment(other.id).durability<100 and g.state.card_buff_uses.grace_bound==3,"GRACE restored bonus deals a single hit")
 for second in [false,true]:
  g=Fixture.setup();g.state.energy=2
  t.check(Give.play(t,g,TYPE,false).ok,"GRACE prepare sweep")
  var wrist=Piece.piece(g,"wrist","wrist",60,100)
  var leg=Piece.piece(g,"thigh","mid_thigh",60,100)
  g.state.energy=2
  t.check(Give.play(t,g,"full_escape",second).ok and g.state.card_buff_uses.grace_bound==1 and Piece.hits(g).map(func(h):return h.target)==[wrist.id,wrist.id,leg.id,leg.id,leg.id],"GRACE two sweep targets at X=2 receive four base hits and one final hit in total")
 for mode in ["slip","strain"]:
  g=Fixture.setup();g.state.wall="normal";g.state.energy=1
  g.RelicEffects.gain(g,"silk_ring" if mode=="slip" else "break_bracer")
  t.check(Give.play(t,g,TYPE,false).ok,"GRACE prepare damage-only relic boundary")
  target=Piece.piece(g,"thigh","mid_thigh",18,100)
  g.state.energy=2
  var draw_before=g.state.draw.size()
  t.check(Give.play(t,g,mode,false,{"target":target.id}).ok and g._equipment(target.id).is_empty() and g.state.logs.filter(func(row):return row.data.has("action_result")).size()==2 and g.state.draw.size()==draw_before and g.state.hand.is_empty() and g.state.charge==0,"GRACE only the extra hit breaks the piece without drawing or granting charge "+mode)
 g=Fixture.setup();g.state.energy=4
 t.check(Give.play(t,g,TYPE,true).ok,"GRACE prepare all-target physical attack")
 g.state.energy=2
 var life=g.state.enemies.map(func(e):return e.hp)
 t.check(t.action(g,"attack",{"type":"kick","form":1,"enemy":g.state.enemies[0].id}).ok and g.state.enemies.map(func(e):return e.hp)==[life[0]-10,life[1]-10] and "grace_free" not in g.state.card_buffs,"GRACE sweep applies one multiplier to both enemies")
 g=Fixture.setup()
 var glove=g._install_assembly("glove","long","fixture",3,2,{},"straight")
 var body=g._composite_body(glove)
 glove.components.filter(func(part):return part.part=="left")[0].durability=0
 g._cleanup()
 var ordinary=g.Cards.target_payload(g,"brace",body.slot,body)
 t.check(ordinary.preview.release,"GRACE glove control is eligible for a whole-piece strain release")
 g.state.card_chain={"type":"brace","slot":body.slot,"mode":"strain","remaining":1,"bonus_escape_hit":true,"total_hits":2}
 var bonus=g.Cards.target_payload(g,"brace",body.slot,body)
 t.check(not bonus.preview.release and not g.Cards.detail(g,bonus).contains("整件单手套"),"GRACE extra segment suppresses the otherwise eligible whole-glove release preview")
 var durability=body.durability
 g.Cards.hit(g,bonus,true)
 t.check(body.durability>0 and body.durability<durability,"GRACE extra segment damages the glove while preserving its remaining durability")
