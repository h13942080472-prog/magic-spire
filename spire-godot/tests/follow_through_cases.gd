extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")
const TYPE="boar_emperor_blaze"

static func fresh(seed_value: int=42):
 var g=Game.new(seed_value)
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
 revised_multihit(t)
 repeated_strain(t)
 super_follow_through(t)
 ignore_tightness(t)
 var g=fresh()
 var spec=g.Cards.Rules.SPECS[TYPE]
 var info=g.B.card_info(TYPE)
 t.check(spec.cost==3 and spec.rarity=="rare" and spec.card_type=="skill" and TYPE in g.Cards.Rules.RARE and info[1]=="挣扎6×5。超级顺延。无视紧度减伤。" and info[2]=="蓄力6。","FOLLOW rare three-energy skill has exact concise faces")
 var card=Give.give(g,TYPE)
 var before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.charge==6 and g.state.energy==0 and g.state.mana==before.mana and g.state.rng==before.rng,"FOLLOW free face grants six charge without mana, random rolls or continuation")

 # One surviving target remains selected even after its ratio falls below its peer.
 g=fresh();var target=piece(g,"thigh","thigh_root",100,100)
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
 g=fresh()
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

 g=fresh();target=piece(g,"thigh","thigh_root");hand=piece(g,"fingers","fingers")
 t.check(use(t,g,target).ok and hits(g).map(func(h):return h.target)==[target.id,hand.id] and g.state.card_chain.is_empty() and g._equipment(hand.id).is_empty(),"FOLLOW super continuation crosses regions and ends only when no legal target remains")

 # New targets always use the currently exposed layer, even if an inner layer is tighter.
 g=fresh();target=piece(g,"thigh","thigh_root")
 inner=piece(g,"calf","mid_calf",1,1)
 var outer=piece(g,"calf","mid_calf",0.1,1,1)
 t.check(use(t,g,target).ok and hits(g).map(func(hit):return hit.target)==[target.id,outer.id] and g._equipment(inner.id).is_empty(),"FOLLOW picks outer layer and its splash removes inner before next segment")

 # The existing per-card tool limit and per-hit charge/damage calculation are retained.
 g=fresh();target=piece(g,"wrist","wrist",100,100)
 g._gain_tool("shard");var tool=g.state.items.back();tool.mount="hand_wall"
 var uses=tool.uses;g.state.charge=2
 t.check(use(t,g,target).ok and hits(g).size()==5 and g.state.charge==0,"FOLLOW each strain segment consumes existing charge through original hit pipeline")
 t.check(g._item(tool.id).uses==uses-1 and g.state.logs.filter(func(log):return log.data.has("tool_bonus")).size()==1,"FOLLOW fixed cutting tool triggers at most once for the entire card")

 # Every region and the three foot positions share the declared stable mapping.
 for slot in ["eyes","mouth","neck"]: t.check(g.Cards.Rules.follow_through_region(slot)=="head","FOLLOW head mapping "+slot)
 for slot in ["shoulder","upper_arm","forearm","wrist","palm","fingers"]: t.check(g.Cards.Rules.follow_through_region(slot)=="arms","FOLLOW arm mapping "+slot)
 for slot in ["thigh","calf","ankle","foot","toes"]: t.check(g.Cards.Rules.follow_through_region(slot)=="legs","FOLLOW leg mapping "+slot)
 t.check(g.validate()=="","FOLLOW final state validates after automatic segments")

 # Hand and foot groupings use the exact same data as the equipment sidebar.
 for trio in [["palm","fingers","wrist"],["foot","toes","ankle"]]:
  g=fresh();target=piece(g,trio[0],trio[0]);var same_part=piece(g,trio[1],trio[1]);var other_part=piece(g,trio[2],trio[2])
  t.check(use(t,g,target).ok and hits(g).map(func(hit):return hit.target)==[target.id,same_part.id,other_part.id],"FOLLOW sidebar group finishes before the rest of the region "+trio[0])

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
  t.check(is_equal_approx(hits(g)[0].before-hits(g)[0].after,preview.damage) and preview.base==4 and preview.charge==g.B.CHARGE_BONUS and g.state.charge==1,type+" uses current damage formula and consumes one charge per segment")
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
 var g=fresh()
 var target=piece(g,"thigh","thigh_root")
 var local=piece(g,"calf","mid_calf")
 var wrist=piece(g,"wrist","wrist")
 var mouth=piece(g,"mouth","mouth")
 var eyes=piece(g,"eyes","eyes")
 var fingers=piece(g,"fingers","fingers")
 t.check(use(t,g,target).ok and hits(g).map(func(h):return h.target)==[target.id,local.id,wrist.id,fingers.id,mouth.id],"FOLLOW super strain exhausts local region before wrist priority and then follows the new region")
 t.check(not g._equipment(eyes.id).is_empty() and g.state.energy==0 and g.state.card_chain.is_empty(),"FOLLOW super strain retains five-hit cap and one payment")
 g=fresh();g.state.charge=2
 var card=Give.give(g,TYPE);var before=g.export_snapshot()
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"FOLLOW free super card stale submission grants no charge or payment")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.charge==8 and g.state.discard.any(func(v):return v.uid==card.uid),"FOLLOW free six charge adds to existing charge and discards once")

static func ignore_tightness(t) -> void:
 var g=fresh();var target=piece(g,"thigh","thigh_root",100,100)
 var previous=g._begin_equipment_read()
 var ordinary=g.escape_preview(target,"strain",6)
 var bypass=g.escape_preview(target,"strain",6,[],false,false,false,false,true)
 var ordinary_again=g.escape_preview(target,"strain",6)
 g._equipment_read=previous
 t.check(ordinary.multiplier<1 and bypass.multiplier==1 and ordinary_again==ordinary and bypass.damage>ordinary.damage,"BLAZE preview cache separates tightness bypass from ordinary strain")
 target.durability=20
 ordinary=g.escape_preview(target,"strain",6)
 bypass=g.Cards.target_payload(g,TYPE,"thigh",target).preview
 t.check(ordinary.multiplier>1 and bypass.multiplier==ordinary.multiplier and bypass.damage==ordinary.damage,"BLAZE preserves low-tightness damage bonus")
 target.durability=100;target.locked=true
 var peer=piece(g,"thigh","thigh_root",100,100)
 var card=Give.give(g,TYPE)
 var payload=t.find_action(g,"card",{"uid":card.uid,"target":target.id}).payload
 var splash=g.Cards.Splash.select(g,payload)
 t.check(payload.preview.multiplier==1 and payload.preview.lock_multiplier==0.5 and payload.preview.divisor==2,"BLAZE ignores only tightness reduction and retains lock and stack reductions")
 t.check(splash.size()==1 and splash[0].target==peer.id and splash[0].preview.multiplier==1 and splash[0].preview.divisor==2,"BLAZE splash inherits bypass while preserving stacking")
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok,"BLAZE actual card dispatch succeeds against locked tight target")
 var records=g.state.logs.filter(func(row):return row.data.has("follow_through_hit"))
 var splashes=g.state.logs.filter(func(row):return row.data.has("card_splash"))
 t.check(records.size()==5 and records.all(func(row):return row.data.multiplier==1 and is_equal_approx(row.data.follow_through_hit.before-row.data.follow_through_hit.after,row.data.damage)),"BLAZE all five actual hits bypass tightness with matching damage records")
 t.check(splashes.size()==5 and splashes.all(func(row):return row.data.multiplier==1 and is_equal_approx(row.data.card_splash.before-row.data.card_splash.after,row.data.damage)),"BLAZE all five actual splashes bypass tightness with matching damage records")
 t.check(is_equal_approx(records[0].data.damage,payload.preview.damage) and is_equal_approx(splashes[0].data.damage,splash[0].preview.damage),"BLAZE initial main and splash previews match actual resolution")
