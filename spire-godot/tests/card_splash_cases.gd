extends RefCounted
const F=preload("res://tests/follow_through_cases.gd")
const Give=preload("res://tests/curse_cases.gd")
const Splash=preload("res://core/card_splash.gd")

static func events(g) -> Array:
 return g.state.logs.filter(func(row):return row.data.has("card_splash")).map(func(row):return row.data.card_splash)

static func run(t) -> void:
 face_values(t)
 multi_hit_values(t)
 strain(t)
 slip(t)
 collateral_effects(t)
 special_routes(t)
 for seed_value in range(24): ties(t,seed_value)

static func strain(t) -> void:
 var g=F.fresh();g.state.wall="rough";g.state.wall_distance=0;g.state.charge=3;g.state.strength=2
 var main=F.piece(g,"thigh","thigh_root",80,100)
 var peer=F.piece(g,"thigh","thigh_root",60,100)
 var locked=F.piece(g,"thigh","thigh_root",50,100);locked.locked=true
 var other=F.piece(g,"thigh","mid_thigh",50,100)
 var card=Give.give(g,"concentration");card.damage_bonus=3
 var c=t.find_action(g,"card",{"uid":card.uid,"target":main.id,"free":false},true)
 var before=g.export_snapshot();var choices=Splash.select(g,c.payload)
 t.check(c.payload.preview.face_value==14 and choices.size()==2 and choices.all(func(x):return x.preview.base==7 and x.preview.bonus==0 and x.preview.charge==0 and x.preview.assist.bonus==0 and x.preview.environment_true==0),"SPLASH halves the grown face plus strength and charge exactly once, excluding hands and wall")
 t.check(choices.any(func(x):return x.target==locked.id and x.preview.lock_multiplier==0.5) and choices.all(func(x):return x.preview.divisor>1),"SPLASH each recipient keeps its own lock and stack multipliers")
 g.get_view();g.command_facts()
 t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SPLASH preview and stale commit preserve state and all random streams")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"SPLASH strain commits through original candidate")
 t.check(is_equal_approx(g._equipment(main.id).durability,80-c.payload.preview.damage),"SPLASH primary damage does not double count the displayed bonuses")
 for choice in choices:
  var old=before.equipment.filter(func(e):return e.id==choice.target)[0]
  t.check(is_equal_approx(g._equipment(choice.target).durability,old.durability-choice.preview.damage),"SPLASH actual frozen per-recipient damage matches preview")
 t.check(events(g).size()==2 and g._equipment(other.id).durability==50 and g.state.charge==2 and g.state.energy==before.energy-1 and g.Cards.base_damage(g,card.type,card.uid)==12,"SPLASH stays at precise point, never recurses, pays and grows once, consumes one charge")
 t.check(g.validate()=="","SPLASH strain leaves valid state")

static func slip(t) -> void:
 var g=F.fresh();g.state.dexterity=4;g.state.charge=1
 var main=F.piece(g,"thigh","above_knee",40,100)
 var root=F.piece(g,"thigh","thigh_root",40,100)
 var loose=F.piece(g,"thigh","thigh_root",20,100)
 var mid=F.piece(g,"thigh","mid_thigh",50,100)
 var same=F.piece(g,"thigh","above_knee",30,100)
 var calf=F.piece(g,"calf","mid_calf",40,100)
 var card=Give.give(g,"slip")
 var c=t.find_action(g,"card",{"uid":card.uid,"target":main.id},true)
 var choices=Splash.select(g,c.payload)
 t.check(c.payload.preview.base==6 and c.payload.preview.face_value==13 and choices.all(func(x):return x.preview.base==6.5),"SPLASH slip inherits displayed dexterity and charge once")
 t.check(choices.size()==2 and choices.any(func(x):return x.target==loose.id) and choices.any(func(x):return x.target==mid.id),"SPLASH slip picks one lowest-ratio eligible target at EACH other point in panel group")
 t.check(choices.filter(func(x):return x.target==loose.id)[0].preview.penalty==0.5,"SPLASH weakest same-layer recipient still receives original same-layer penalty")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and events(g).size()==2 and root.durability==40 and same.durability==30 and calf.durability==40,"SPLASH excludes tighter alternative, original point and other panel groups")
 t.check(g.state.charge==0 and events(g).all(func(event):return event.base==13),"SPLASH frozen face value survives primary charge consumption without another charge cost")
 g=F.fresh();main=F.piece(g,"thigh","above_knee",40,100)
 root=F.piece(g,"thigh","thigh_root",100,100)
 mid=F.piece(g,"thigh","mid_thigh",20,100);mid.locked=true
 var p=g.Cards.target_payload(g,"slip","thigh",main)
 choices=Splash.select(g,p)
 t.check(choices.size()==1 and choices[0].target==mid.id,"SPLASH ordinary slip excludes tier-three immunity and retains existing slip route for locks")
 p=g.Cards.target_payload(g,"magic_slip","thigh",main)
 choices=Splash.select(g,p)
 t.check(choices.size()==2 and choices.any(func(x):return x.target==root.id and x.preview.damage>0),"SPLASH magic slip bypasses tier-three immunity with original structural rules")
 g=F.fresh();main=F.piece(g,"thigh","above_knee",40,100)
 var inner=F.piece(g,"thigh","thigh_root",10,100)
 var outer=F.piece(g,"thigh","thigh_root",60,100,1)
 p=g.Cards.target_payload(g,"slip","thigh",main);choices=Splash.select(g,p)
 t.check(choices.size()==1 and choices[0].target==outer.id and not choices.any(func(x):return x.target==inner.id),"SPLASH chooses legal outer target instead of looser covered inner equipment")
 # One physical item covering several neighboring points is damaged once.
 g=F.fresh();main=F.piece(g,"thigh","above_knee",40,100)
 root=F.piece(g,"thigh","thigh_root",40,100);root.points=["thigh_root","mid_thigh"]
 p=g.Cards.target_payload(g,"slip","thigh",main);choices=Splash.select(g,p)
 t.check(choices.size()==1 and choices[0].target==root.id,"SPLASH deduplicates multi-point physical equipment")

static func face_values(t) -> void:
 var g=F.fresh();g.state.strength=2;g.state.dexterity=5;g.state.charge=2
 var card=Give.give(g,"concentration");card.damage_bonus=3
 var before=g.export_snapshot()
 var entry=g.live_card_text(card.type,card.uid)
 t.check(entry.bound.contains("挣扎14") and entry.free.contains("滑脱17") and entry.face_damage=={"bound":[14.0],"free":[17.0]},"FACE VALUES dual bound faces use their own attribute plus charge and physical growth")
 t.check(entry.face_effects.bound.contains("挣扎14") and entry.face_effects.free.contains("滑脱17") and g.live_card_text_set([card]).instances[card.uid]==entry,"FACE VALUES visible effects and deck projections share numeric values")
 var book=preload("res://data/encyclopedia.gd").card(card.type)
 t.check(book.bound.contains("挣扎6") and book.free.contains("滑脱6") and g.state==before,"FACE VALUES encyclopedia remains static and live projections never consume charge")
 entry.face_damage.bound[0]=999
 t.check(g.live_card_text(card.type,card.uid).face_damage.bound==[14.0],"FACE VALUES returned numeric containers are isolated")
 t.check(g.live_card_text("strain").free.contains("蓄力1") and g.live_card_text("ease").bound.contains("降紧1") and g.live_card_text("ease").face_damage.bound.is_empty(),"FACE VALUES resource gains and fixed lowering never receive damage bonuses")
 var sequence=g.live_card_text("chain")
 t.check(sequence.face_damage.bound==[9.0,9.0,6.0] and sequence.bound.contains("挣扎9×2＋6×1"),"FACE VALUES limited charge displays exact per-hit values")
 t.check(t.action(g,"status_toggle",{"status":"charge","enabled":true}).ok,"FACE VALUES full-charge mode changes through formal command")
 sequence=g.live_card_text("chain")
 t.check(sequence.face_damage.bound==[12.0,6.0,6.0] and sequence.bound.contains("挣扎12×1＋6×2"),"FACE VALUES full charge applies only to the first projected hit")
 var target=F.piece(g,"ankle","ankle",40,100)
 g.state.relics.append("smooth_stockings")
 var preview=g.Cards.target_payload(g,"slip","ankle",target).preview
 t.check(preview.face_value==17 and preview.bonus==7 and g.live_card_text("slip").face_damage.bound==[17.0],"FACE VALUES target-only stocking bonus stays outside untargeted card values")
 var witch=preload("res://core/game.gd").new(42,true,"equipment",true,false,25,false,false,"witch")
 witch.state.dexterity=4;witch.state.charge=1
 var training=witch.live_card_text("witch_escape_practice")
 t.check(training.face_damage.free==[8.0,5.0,5.0] and training.free.contains("滑脱8×1＋5×2") and training.bound.contains("挣扎4×1＋1×2"),"FACE VALUES witch training uses dynamic per-face templates and individual charge consumption")

static func multi_hit_values(t) -> void:
 for all_charge in [false,true]:
  var g=F.fresh();g.state.strength=2;g.state.charge=2
  if all_charge: t.check(t.action(g,"status_toggle",{"status":"charge","enabled":true}).ok,"FACE VALUES enable full charge for actual multi-hit cast")
  var target=F.piece(g,"thigh","thigh_root",400,1000)
  F.piece(g,"thigh","thigh_root",200,1000)
  var card=Give.give(g,"chain")
  var values=g.live_card_text(card.type,card.uid).face_damage.bound
  var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false},true)
  var before=g.export_snapshot()
  t.check(c.valid and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"FACE VALUES stale multi-hit cast preserves charge and card")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.card_chain.is_empty() and g.state.charge==0 and g.state.energy==before.energy-2,"FACE VALUES actual multi-hit cast consumes its charge and energy once")
  t.check(events(g).map(func(event):return event.base)==values,"FACE VALUES each actual splash reads the corresponding displayed hit value")
  var hits=g.state.logs.filter(func(row):return row.data.has("follow_through_hit")).map(func(row):return row.data.face_value)
  t.check(hits==values,"FACE VALUES primary hits and splash share the same refreshed per-hit values")

static func ties(t, seed_value: int) -> void:
 var g=F.fresh(seed_value)
 var main=F.piece(g,"thigh","above_knee",40,100)
 var a=F.piece(g,"thigh","thigh_root",30,100)
 var b=F.piece(g,"thigh","thigh_root",30,100)
 var card=Give.give(g,"slip")
 var c=t.find_action(g,"card",{"uid":card.uid,"target":main.id},true)
 var before=g.export_snapshot()
 t.check(g.candidate_detail(c).contains("随机1件") and g.state==before,"SPLASH tied preview lists possibilities without advancing RNG")
 var twin=F.fresh();t.check(twin.restore_snapshot(before).ok,"SPLASH current snapshot restores before random recipient choice")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and twin.dispatch(twin.command(c.payload,twin.state.version),twin.state.version).ok,"SPLASH tie resolves inside formal commit")
 t.check(events(g).size()==1 and events(g)[0].target in [a.id,b.id] and events(g)==events(twin) and g.state.rng==twin.state.rng,"SPLASH tied choice is reproducible and never hits both alternatives")
 t.check(g.state.rng.card_target==before.rng.card_target+1 and before.rng.keys().filter(func(k):return k!="card_target").all(func(k):return g.state.rng[k]==before.rng[k]),"SPLASH tie consumes exactly one card_target roll and no other random domain")

static func collateral_effects(t) -> void:
 var g=F.fresh();g.state.relics.append("break_bracer")
 var main=F.piece(g,"thigh","thigh_root",60,100)
 var peer=F.piece(g,"thigh","thigh_root",0.01,100)
 var card=Give.give(g,"tear")
 t.check(t.action(g,"card",{"uid":card.uid,"target":main.id}).ok and g._equipment(peer.id).is_empty() and not g._equipment(main.id).is_empty(),"SPLASH collateral can independently remove a physical restraint")
 t.check(g.state.energy==1 and g.state.charge==1,"SPLASH removal triggers existing once-per-turn relic but not main-target card refund")
 g=F.fresh();g.state.relics.append("silk_ring")
 main=F.piece(g,"thigh","above_knee",70,100)
 peer=F.piece(g,"thigh","thigh_root",0.01,100)
 var mid=F.piece(g,"thigh","mid_thigh",0.01,100)
 card=Give.give(g,"slip");var hand_count=g.state.hand.size()
 t.check(t.action(g,"card",{"uid":card.uid,"target":main.id}).ok and g._equipment(peer.id).is_empty() and g._equipment(mid.id).is_empty(),"SPLASH slip removes both other-point recipients in one segment")
 t.check(g.state.hand.size()==hand_count and g.state.energy==2,"SPLASH two slip removals trigger ring draw once and never duplicate payment")
 # Non-card damage keeps its existing independent scope.
 g=F.fresh();main=F.piece(g,"thigh","thigh_root",40,100);peer=F.piece(g,"thigh","thigh_root",30,100)
 g._apply_equipment_damage(main,2,"strain",true)
 t.check(peer.durability==30 and events(g).is_empty(),"SPLASH shared damage entry does not recursively add splash to passive or tool damage")

static func special_routes(t) -> void:
 var g=F.fresh();g.state.wall_distance=2
 var main=g._install_special("glans_cup_medium","special_2_b")
 var peer=g._install_special("shaft_ring_low","special_2_a")
 var p=g.Cards.target_payload(g,"slip","special_2_b",main)
 var choices=Splash.select(g,p)
 t.check(choices.size()==1 and choices[0].target==peer.id and choices[0].preview.assist.bonus==0,"SPLASH special body group retains real hand eligibility without adding hand damage")
 g.add_fixture("wrist",8)
 t.check(Splash.options(g,p).is_empty(),"SPLASH special physical route still needs a usable hand or permitted environment")
 p=g.Cards.target_payload(g,"magic_slip","special_2_b",main);choices=Splash.select(g,p)
 t.check(choices.size()==1 and choices[0].target==peer.id,"SPLASH special magic route preserves its environment exemption")
