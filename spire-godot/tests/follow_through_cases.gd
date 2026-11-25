extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")
const TYPE="boar_emperor_blaze"

static func fresh(seed_value: int=42, five_hits: bool=false):
 var g=Game.new(seed_value)
 if five_hits:
  g.RelicEffects.gain(g,"fireball_pamphlet")
  g.state.spell_base_bonuses.fireball=17
 g.state.wall="normal";g._discard_end()
 return g

static func piece(g, slot: String, point: String, durability: float=0.1, maximum: float=1.0, layer: int=0) -> Dictionary:
 return g._install_template(g.Equipment.default_template(slot),slot,durability,maximum,false,"fixture",1,layer,0,point if slot in g.Equipment.SEGMENTS else slot)

static func hits(g) -> Array:
 return g.state.logs.filter(func(log):return log.data.has("follow_through_hit")).map(func(log):return log.data.follow_through_hit)

static func use(t,g,target: Dictionary) -> Dictionary:
 var card=Give.give(g,TYPE)
 return t.action(g,"card",{"uid":card.uid,"target":target.id,"free":false})

static func run(t) -> void:
 fireball_scaling(t)
 full_escape(t)
 revised_multihit(t)
 repeated_strain(t)
 super_follow_through(t)
 normal_tightness(t)
 var g=fresh(42,true)
 var spec=g.Cards.Rules.SPECS[TYPE]
 var info=g.B.card_info(TYPE)
 t.check(spec.cost==3 and spec.rarity=="rare" and spec.card_type=="skill" and TYPE in g.Cards.Rules.RARE and info[1]=="挣扎6×X。超级顺延。" and info[2]=="蓄力X。" and info[3].contains("成功施放"),"FOLLOW rare three-energy skill has exact concise faces")
 var card=Give.give(g,TYPE)
 var before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.charge==0 and g.state.energy==0 and g.state.mana==before.mana and g.state.rng==before.rng,"FOLLOW free face grants zero charge before the first Fireball without mana, random rolls or continuation")

 # One surviving target remains selected even after its ratio falls below its peer.
 g=fresh(42,true);var target=piece(g,"thigh","thigh_root",100,100)
 var peer=piece(g,"thigh","thigh_root",99,100)
 card=Give.give(g,TYPE);var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 t.check(g.candidate_detail(c).contains("全身合法目标") and not g.candidate_detail(c).contains("不跨"),"FOLLOW super strain target detail agrees with full-body keyword and behavior")
 before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"FOLLOW previews and stale submission preserve complete state and RNG")
 g.state.energy=2;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and g.state==before,"FOLLOW insufficient three-energy payment refuses atomically")
 g.state.energy=3
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and hits(g).size()==5 and hits(g).all(func(hit):return hit.target==target.id),"FOLLOW surviving target receives all five hits instead of changing to tighter peer")
 t.check(g._equipment(peer.id).durability<99 and g.state.logs.filter(func(row):return row.data.has("card_splash")).size()==5 and g.state.energy==0 and g.state.card_chain.is_empty() and g.state.discard.any(func(item):return item.uid==card.uid) and g.state.rng.card_target==0,"FOLLOW five hits pay and discard once without unnecessary random selection")
 t.check(hits(g).map(func(hit):return hit.hit)==[1,2,3,4,5] and hits(g).all(func(hit):return hit.before>hit.after),"FOLLOW structured events record five separately resolved hits")

 # Exact point -> other segments of thigh -> leg region. Hands cannot be hit.
 g=fresh(42,true)
 var inner=piece(g,"thigh","thigh_root")
 target=piece(g,"thigh","thigh_root",1,1,1)
 var mid=piece(g,"thigh","mid_thigh")
 var knee=piece(g,"thigh","above_knee")
 var calf=piece(g,"calf","mid_calf")
 var foot=piece(g,"toes","toes")
 var hand=piece(g,"fingers","fingers")
 card=Give.give(g,TYPE)
 var twin=Save.roundtrip(t,g,"three-tier follow through before play")
 before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok,"FOLLOW actual initial hit begins automatic cascade")
 var sequence=hits(g).map(func(hit):return hit.target)
 t.check(sequence.size()==5 and sequence[0]==target.id and g._equipment(inner.id).is_empty() and sequence.slice(1,3).has(mid.id) and sequence.slice(1,3).has(knee.id),"FOLLOW exact-point splash removes inner before continuation finishes other segments and region")
 t.check(sequence[4] in [calf.id,foot.id] and not g._equipment(hand.id).is_empty() and g.state.card_chain.is_empty(),"FOLLOW final segment chooses only same region and ends without picker")
 t.check(g.state.rng.card_target==2 and before.rng.keys().filter(func(key):return key!="card_target").all(func(key):return before.rng[key]==g.state.rng[key]),"FOLLOW random ties use only dedicated card target domain")
 if twin!=null:
  t.check(t.action(twin,"card",{"uid":card.uid,"target":target.id}).ok and hits(twin)==hits(g) and twin.state.rng==g.state.rng,"FOLLOW restored state reproduces exact random targets and damage")

 g=fresh(42,true);target=piece(g,"thigh","thigh_root");hand=piece(g,"fingers","fingers")
 t.check(use(t,g,target).ok and hits(g).map(func(h):return h.target)==[target.id,hand.id] and g.state.card_chain.is_empty() and g._equipment(hand.id).is_empty(),"FOLLOW super continuation crosses regions and ends only when no legal target remains")

 # New targets always use the currently exposed layer, even if an inner layer is tighter.
 g=fresh(42,true);target=piece(g,"thigh","thigh_root")
 inner=piece(g,"calf","mid_calf",1,1)
 var outer=piece(g,"calf","mid_calf",0.1,1,1)
 t.check(use(t,g,target).ok and hits(g).map(func(hit):return hit.target)==[target.id,outer.id] and g._equipment(inner.id).is_empty(),"FOLLOW picks outer layer and its splash removes inner before next segment")

 # A multihit card spends charge per hit. A cutting card only spends uses when played.
 g=fresh(42,true);target=piece(g,"wrist","wrist",100,100)
 var knife=t.take_item_card(g,"shard")
 var uses=g.Cards.instance(g,knife).remove_left;g.state.charge=2
 t.check(use(t,g,target).ok and hits(g).size()==5 and g.state.charge==0,"FOLLOW each strain segment consumes existing charge through original hit pipeline")
 t.check(g.state.hand.any(func(c):return c.uid==knife and c.remove_left==uses),"FOLLOW all five hits leave the separate cutting card in hand with its uses intact")

 # Every region and the three foot positions share the declared stable mapping.
 for slot in ["eyes","mouth","neck"]: t.check(g.Cards.Rules.follow_through_region(slot)=="head","FOLLOW head mapping "+slot)
 for slot in ["shoulder","upper_arm","forearm","wrist","palm","fingers"]: t.check(g.Cards.Rules.follow_through_region(slot)=="arms","FOLLOW arm mapping "+slot)
 for slot in ["thigh","calf","ankle","foot","toes"]: t.check(g.Cards.Rules.follow_through_region(slot)=="legs","FOLLOW leg mapping "+slot)
 t.check(g.validate()=="","FOLLOW final state validates after automatic segments")

 # Hand and foot groupings use the exact same data as the equipment sidebar.
 for trio in [["palm","fingers","wrist"],["foot","toes","ankle"]]:
  g=fresh(42,true);target=piece(g,trio[0],trio[0]);var same_part=piece(g,trio[1],trio[1]);var other_part=piece(g,trio[2],trio[2])
  t.check(use(t,g,target).ok and hits(g).map(func(hit):return hit.target)==[target.id,same_part.id,other_part.id],"FOLLOW sidebar group finishes before the rest of the region "+trio[0])

static func fireball_scaling(t) -> void:
 var g=fresh()
 var invalid_spec=g.Cards.Rules.SPECS[TYPE].duplicate(true);invalid_spec.hits=5
 t.check(g.Cards.Rules.definition_reason(invalid_spec)!="","BLAZE declarations reject competing fixed and Fireball-scaled counts")
 g.RelicEffects.gain(g,"fireball_pamphlet")
 var target=piece(g,"thigh","thigh_root",100,100)
 var card=Give.give(g,TYPE)
 var hit_total=floori(g.BasicAttacks.fireball_damage(g))
 var view=g.live_card_text(TYPE,card.uid)
 t.check(hit_total==2 and view.bound.contains("6×2") and view.face_damage.bound==[6.0,6.0],"BLAZE fractional Fireball damage rounds down on the face and in readable damage values")
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and hits(g).size()==hit_total,"BLAZE fractional damage resolves the displayed number of hits")
 g=fresh()
 var fingers=piece(g,"fingers","fingers")
 var survivor=piece(g,"thigh","thigh_root",1000,1000)
 hit_total=floori(g.BasicAttacks.fireball_damage(g))
 t.check(use(t,g,fingers).ok and hits(g).size()==hit_total and hits(g)[-1].target==survivor.id and g.BasicAttacks.fireball_damage(g)>hit_total,"BLAZE releasing the casting hand mid-sequence preserves the initial hit count")
 g=fresh()
 g.Cards.grant_buff(g,"study_bound",3);g.state.charge=2
 target=piece(g,"thigh","thigh_root",100,100)
 t.check(g.BasicAttacks.fireball_damage(g)==0 and g.live_card_text(TYPE).face_damage.bound.is_empty(),"BLAZE zero Fireball damage projects no hits")
 t.check(use(t,g,target).ok and hits(g).is_empty() and target.durability==100 and g.state.charge==2 and g.state.energy==0,"BLAZE zero hits pay once and consume no charge")
 for seed_value in range(8):
  g=fresh(seed_value);g.state.pressure=75
  var probe=fresh(seed_value)
  if probe._random_index("magic",g.B.CAST_ROLL_STEPS)>=g.cast_view().winning_rolls: break
 var attack={"type":"fireball","enemy":g.state.enemies[0].id}
 t.check(t.action(g,"attack",attack).ok and g._magic_failed and g.BasicAttacks.successful_fireballs(g)==0,"BLAZE paid failed Fireball does not earn charge")
 g.state.pressure=0;g.state.sure_cast=true
 t.check(t.action(g,"attack",attack).ok and not g._magic_failed and g.BasicAttacks.successful_fireballs(g)==1 and g.state.combat.fireballs_cast==2,"BLAZE only the successful Fireball counts while attempt-based relics count both")
 t.check(t.action(g,"end").ok and g.live_card_text(TYPE).free=="蓄力1。","BLAZE success persists across player turns")
 var twin=Save.roundtrip(t,g,"boar successful Fireballs")
 if twin!=null:
  var before=twin.export_snapshot();var malformed=before.duplicate(true)
  malformed.combat.fireballs_succeeded=malformed.combat.fireballs_cast+1
  t.check(not twin.restore_snapshot(malformed).ok and twin.state==before,"BLAZE impossible success count rejects atomically")
  var legacy=before.duplicate(true);legacy.combat.erase("fireballs_succeeded")
  t.check(twin.restore_snapshot(legacy).ok and twin.BasicAttacks.successful_fireballs(twin)==0,"BLAZE old saves do not treat unknown casts as successes")
 var charge=g.state.charge
 t.check(Give.play(t,g,TYPE,true).ok and g.state.charge==charge+1,"BLAZE free face grants exactly the displayed success count")
 g._start_battle()
 t.check(g.live_card_text(TYPE).free=="蓄力0。","BLAZE next encounter resets the success count")

static func full_escape(t) -> void:
 var type="full_escape"
 for second in [false,true]:
  var g=fresh()
  var mode="slip" if second else "strain"
  var hand=piece(g,"wrist","wrist",60,100)
  var leg=piece(g,"thigh","mid_thigh",60,100)
  var toy=g._install_special("vaginal_egg_low","special_3_a")
  var card=Give.give(g,type)
  var spec=g.Cards.Rules.SPECS[type]
  var face=g.B.card_info(type)[2 if second else 1]
  t.check(g.Cards.Rules.definition_reason(spec)=="" and type in g.Cards.Rules.UNCOMMON and g.Cards.Rules.energy_label(type)=="X" and face.contains("4×X。顺延。"),"FULL ESCAPE valid uncommon X-cost face and keyword")
  var invalid=spec.duplicate(true)
  invalid.target_slots=["special_3_a"]
  t.check(g.Cards.Rules.definition_reason(invalid)!="","FULL ESCAPE sweep declarations cannot target a sensitive slot")
  g.state.energy=0
  var params={"uid":card.uid,"free":second,"self_target":true}
  var before=g.export_snapshot()
  t.check(not t.action(g,"card",params).ok and g.state==before,"FULL ESCAPE zero X refuses without changing state")
  g.state.energy=2
  var fact=t.find_action(g,"card",params)
  before=g.export_snapshot()
  var forged=fact.payload.duplicate(true);forged.x=3
  t.check(fact.valid and fact.cost==2 and fact.payload.x==2 and fact.payload.mode==mode and not g.dispatch(g.command(forged,g.state.version),g.state.version).ok and g.state==before,"FULL ESCAPE targets automatically and rejects a forged X before payment")
  t.check(t.action(g,"card",params).ok and g.state.energy==0,"FULL ESCAPE pays X energy once through the normal card command")
  var records=g.state.logs.filter(func(log):return log.data.has("follow_through_hit"))
  t.check(hits(g).map(func(h):return h.target)==[hand.id,hand.id,leg.id,leg.id] and records.all(func(log):return log.data.base==4),"FULL ESCAPE both eligible regions each receive X hits of base four")
  t.check(not toy.is_empty() and g.state.special_equipment==before.special_equipment and g.state.card_chain.is_empty() and g.state.discard.any(func(c):return c.uid==card.uid),"FULL ESCAPE leaves sensitive equipment intact and discards just once")

 var g=fresh()
 var card=Give.give(g,type)
 var toy=g._install_special("vaginal_egg_low","special_3_a")
 var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
 t.check(not toy.is_empty() and not c.valid,"FULL ESCAPE sensitive gear alone does not enable play")
 var inner=piece(g,"thigh","thigh_root",0.1,10)
 var outer=piece(g,"thigh","thigh_root",0.2,10,1)
 var arm=piece(g,"wrist","wrist",60,100)
 var twin=Save.roundtrip(t,g,"full escape and layered equipment")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and hits(g).map(func(h):return h.target)==[arm.id,arm.id,arm.id,outer.id,inner.id],"FULL ESCAPE remaining hits follow the exposed layer without moving to another region or reusing a starting target")
 if twin!=null:
  t.check(t.action(twin,"card",{"uid":card.uid,"free":false}).ok and hits(twin)==hits(g) and twin.state.rng==g.state.rng,"FULL ESCAPE save and reload preserve resolution and RNG")

 g=fresh()
 var tight=piece(g,"wrist","wrist",100,100)
 var contact=piece(g,"calf","mid_calf",60,100)
 g.state.energy=2
 g.Cards.grant_buff(g,"echo_cast_bound")
 card=Give.give(g,type)
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.energy==0 and "echo_cast_bound" not in g.state.card_buffs,"FULL ESCAPE replay uses the paid X without charging for the second resolution")
 t.check(hits(g).filter(func(h):return h.target==tight.id).size()==4 and g._equipment(tight.id).durability==100 and hits(g).filter(func(h):return h.target==contact.id).size()==4,"FULL ESCAPE replay honors the second face and ordinary slip immunity")

static func revised_multihit(t) -> void:
 for type in ["peel","chain"]:
  var mode="slip" if type=="peel" else "strain"
  var text="滑脱" if type=="peel" else "挣扎"
  var g=fresh();var spec=g.Cards.Rules.SPECS[type]
  t.check(spec.cost==2 and spec.rarity=="uncommon" and spec.mode==mode and spec.damage_type==mode and spec.base==4 and spec.hits==3 and spec.follow_through,type+" bound face is three four-base hits with follow through")
  t.check(g.B.card_info(type)[1]==text+"4×3。顺延。" and g.B.card_metadata(type).face_keywords.bound.any(func(term):return term.name=="顺延"),type+" shared text and keyword match mechanics")
  var target=piece(g,"thigh","thigh_root",60,100)
  var card=Give.give(g,type);g.state.charge=4
  var preview=t.find_action(g,"card",{"uid":card.uid,"target":target.id}).payload.preview
  var before=g.export_snapshot()
  t.check(not g.dispatch(g.command({"kind":"card","uid":"missing"},g.state.version),g.state.version).ok and g.state==before,type+" invalid submission preserves complete state")
  t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and hits(g).size()==3 and hits(g).all(func(h):return h.target==target.id and h.before>h.after),type+" surviving target receives three actual hits")
  t.check(is_equal_approx(hits(g)[0].before-hits(g)[0].after,preview.damage) and preview.base==4 and preview.charge==4*g.B.CHARGE_BONUS and g.state.charge==0,type+" uses all four charges on the first segment")
  t.check(g.state.energy==1 and g.state.card_chain.is_empty() and g.state.discard.any(func(c):return c.uid==card.uid) and g.state.rng==before.rng,type+" pays and discards once without pending choice or unnecessary random rolls")
  g=fresh();target=piece(g,"thigh","thigh_root",100,100);card=Give.give(g,type)
  t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and hits(g).size()==3 and (g._equipment(target.id).durability==100 if mode=="slip" else g._equipment(target.id).durability<100) and g.state.energy==1,type+" tier three distinguishes slip immunity from strain damage across all three paid hits")
  g=fresh();target=piece(g,"thigh","thigh_root");var mid=piece(g,"thigh","mid_thigh");var foot=piece(g,"toes","toes");var hand=piece(g,"fingers","fingers")
  card=Give.give(g,type)
  t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and hits(g).map(func(h):return h.target)==([target.id,foot.id] if mode=="slip" else [target.id,mid.id,foot.id]) and g._equipment(mid.id).is_empty() and not g._equipment(hand.id).is_empty(),type+" damage follows exact point then sidebar part then original region")
  g=fresh();target=piece(g,"thigh","thigh_root");var inner=piece(g,"thigh","thigh_root",0.1,1,1)
  card=Give.give(g,type);before=g.export_snapshot()
  var blocked=target if mode=="slip" else inner
  var first=inner if mode=="slip" else target
  var second=target if mode=="slip" else inner
  t.check(not t.action(g,"card",{"uid":card.uid,"target":blocked.id}).ok and g.state==before,type+" initial selection retains original layer eligibility")
  t.check(t.action(g,"card",{"uid":card.uid,"target":first.id}).ok and hits(g).map(func(h):return h.target)==([first.id,second.id] if mode=="slip" else [first.id]) and g._equipment(second.id).is_empty() and g.state.charge==0,type+" newly eligible layer follows and no target ends remaining hits without free reward")
  t.check(g.validate()=="",type+" completed sequence validates")

static func repeated_strain(t) -> void:
 var type="repeated_strain"
 var g=fresh()
 var spec=g.Cards.Rules.SPECS[type]
 t.check(spec.rarity=="common" and type in g.Cards.Rules.COMMON and spec.cost==1 and spec.hits==5 and spec.base==1 and g.B.CARD_TRAITS[type].exhaust,"REPEATED common one-energy exhaust card uses existing five-hit follow through")
 var card=Give.give(g,type);g.state.charge=3
 var before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.energy==2 and g.state.charge==5 and g.state.mana==before.mana and g.state.rng==before.rng,"REPEATED free face adds exactly two charge and pays once")
 t.check(g.state.exhaust.any(func(c):return c.uid==card.uid) and not g.state.hand.any(func(c):return c.uid==card.uid) and not g.state.discard.any(func(c):return c.uid==card.uid),"REPEATED free face enters exhaust rather than discard")
 g=fresh();var target=piece(g,"thigh","thigh_root",100,100);card=Give.give(g,type)
 g.state.energy=0;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and g.state==before,"REPEATED unavailable card is neither paid nor exhausted")
 g.state.energy=3
 var result=t.action(g,"card",{"uid":card.uid,"target":target.id})
 var records=g.state.logs.filter(func(log):return log.data.has("follow_through_hit"))
 t.check(result.ok and records.size()==5 and records.all(func(log):return log.data.base==1 and log.data.follow_through_hit.target==target.id) and g.state.energy==2,"REPEATED bound face actually resolves five one-base strain hits for one energy")
 t.check(g.state.exhaust.any(func(c):return c.uid==card.uid) and result.card_feedback.filter(func(e):return e.kind=="play_exhaust" and e.uid==card.uid).size()==1 and g.state.card_chain.is_empty(),"REPEATED five hits exhaust once and leave no continuation picker")
 g=fresh();var inner=piece(g,"thigh","thigh_root",0.01,10);target=piece(g,"thigh","thigh_root",1,10,1)
 var middle=piece(g,"thigh","mid_thigh",0.01,10);var foot=piece(g,"toes","toes",0.01,10)
 var arm=piece(g,"fingers","fingers",0.01,10);card=Give.give(g,type)
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and hits(g).map(func(hit):return hit.target)==[target.id,middle.id,foot.id] and g._equipment(inner.id).is_empty() and not g._equipment(arm.id).is_empty(),"REPEATED exhaust card follows point, body part and region then stops without crossing")
 var restored=Save.roundtrip(t,g,"repeated strain after exhaust and continuation")
 if restored!=null: t.check(restored.state.exhaust.any(func(c):return c.uid==card.uid) and restored.state.card_chain.is_empty(),"REPEATED exhausted physical card survives current snapshot roundtrip")

static func super_follow_through(t) -> void:
 var g=fresh(42,true)
 var target=piece(g,"thigh","thigh_root")
 var local=piece(g,"calf","mid_calf")
 var wrist=piece(g,"wrist","wrist")
 var mouth=piece(g,"mouth","mouth")
 var eyes=piece(g,"eyes","eyes")
 var fingers=piece(g,"fingers","fingers")
 t.check(use(t,g,target).ok and hits(g).map(func(h):return h.target)==[target.id,local.id,wrist.id,fingers.id,mouth.id],"FOLLOW super strain exhausts local region before wrist priority and then follows the new region")
 t.check(not g._equipment(eyes.id).is_empty() and g.state.energy==0 and g.state.card_chain.is_empty(),"FOLLOW super strain retains five-hit cap and one payment")
 g=fresh(42,true);g.state.charge=2
 var card=Give.give(g,TYPE);var before=g.export_snapshot()
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"FOLLOW free super card stale submission grants no charge or payment")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.charge==2 and g.state.discard.any(func(v):return v.uid==card.uid),"FOLLOW zero casts preserve existing charge and discards once")

static func normal_tightness(t) -> void:
 var g=fresh(42,true);var target=piece(g,"thigh","thigh_root",100,100)
 var previous=g._begin_equipment_read()
 var ordinary=g.escape_preview(target,"strain",6)
 var bypass=g.escape_preview(target,"strain",6,[],false,false,false,false,true)
 var ordinary_again=g.escape_preview(target,"strain",6)
 g._equipment_read=previous
 t.check(ordinary.multiplier<1 and bypass.multiplier==1 and ordinary_again==ordinary and bypass.damage>ordinary.damage,"BLAZE preview cache separates tightness bypass from ordinary strain")
 for value in [20.0,40.0,100.0]:
  target.durability=value
  ordinary=g.escape_preview(target,"strain",6)
  var printed=g.Cards.target_payload(g,TYPE,"thigh",target).preview
  t.check(printed.multiplier==ordinary.multiplier and printed.damage==ordinary.damage,"BLAZE uses ordinary strain at loose, neutral and tight durability: "+str(value))
 target.durability=100;target.locked=true
 var peer=piece(g,"thigh","thigh_root",100,100)
 var card=Give.give(g,TYPE)
 var payload=t.find_action(g,"card",{"uid":card.uid,"target":target.id}).payload
 var splash=g.Cards.Splash.select(g,payload)
 t.check(payload.preview.multiplier==ordinary.multiplier and payload.preview.multiplier<1 and payload.preview.lock_multiplier==0.5 and payload.preview.divisor==2,"BLAZE tight target applies tightness, lock and stack reductions")
 t.check(splash.size()==1 and splash[0].target==peer.id and splash[0].preview.multiplier==ordinary.multiplier and splash[0].preview.divisor==2,"BLAZE splash includes tightness and stacking")
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok,"BLAZE actual card dispatch succeeds against locked tight target")
 var records=g.state.logs.filter(func(row):return row.data.has("follow_through_hit"))
 var splashes=g.state.logs.filter(func(row):return row.data.has("card_splash"))
 t.check(records.size()==5 and records.all(func(row):return is_equal_approx(row.data.multiplier,g._damage_multiplier(row.data.follow_through_hit.before/100.0)) and is_equal_approx(row.data.follow_through_hit.before-row.data.follow_through_hit.after,row.data.damage)),"BLAZE all five actual hits scale with current tightness with matching damage records")
 t.check(splashes.size()==5 and splashes.all(func(row):return is_equal_approx(row.data.multiplier,g._damage_multiplier(row.data.card_splash.before/100.0)) and is_equal_approx(row.data.card_splash.before-row.data.card_splash.after,row.data.damage)),"BLAZE all five actual splashes scale with their own current tightness with matching damage records")
 t.check(is_equal_approx(records[0].data.damage,payload.preview.damage) and is_equal_approx(splashes[0].data.damage,splash[0].preview.damage),"BLAZE initial main and splash previews match actual resolution")
