extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func setup():
 var g=Game.new(42)
 g._discard_end();g.state.energy=40;g.state.mana=20
 return g

static func use(t,g,type: String,free: bool) -> Dictionary:
 var matches=g.state.hand.filter(func(c):return c.type==type)
 var card=matches[0] if not matches.is_empty() else t.hand_card(g,type)
 return t.action(g,"card",{"uid":card.uid,"free":free})

static func run(t) -> void:
 var g=setup();var count=g.state.deck.size()
 for stage in range(1,5):
  var type="hannya_%d" % stage
  var meta=g.B.card_metadata(type)
  for free in [false,true]:
   var side="free" if free else "bound"
   t.check(meta.face_mana[side].size()==1 and meta.face_mana[side][0].kind=="gain" and meta.face_mana[side][0].text=="+5","HANNYA both faces show five own mana in shared metadata")
   t.check(g.Cards.Rules.SPECS[type].card_type=="skill" and not g.Cards.Rules.face_casts(type,free) and "magic" not in g.Cards.Rules.type_tags(type),"HANNYA mana gain does not turn skill into magic")
 g.RelicEffects.gain(g,"gourd_flask");g.RelicEffects.gain(g,"gourd_flask")
 t.check(g.state.deck.size()==count+1 and g.state.deck.back().type=="hannya_1" and "gourd_flask" in g.Relics.BOSS_POOL and "gourd_flask" not in g.Relics.REWARDS,"HANNYA boss-only pickup adds one permanent card once")
 g._start_battle()
 t.check(g.state.hand.any(func(c):return c.type=="hannya_1") and g.state.hand.size()==g.B.DRAW,"HANNYA innate uses opening hand slots after shuffle")
 for free in [false,true]:
  g=setup();g.RelicEffects.gain(g,"gourd_flask")
  for stage in range(1,5):
   var type="hannya_%d" % stage
   var mana=g.state.mana;var energy=g.state.energy
   t.check(use(t,g,type,free).ok and g.Cards.Hannya.level(g)==stage and g.state.energy==energy-1 and g.state.mana==mana+5,"HANNYA stage %d pays once and upgrades on face %s" % [stage,str(free)])
   t.check(g.RelicEffects.attribute(g,"strength")==stage and g.RelicEffects.attribute(g,"dexterity")==stage,"HANNYA cumulative attributes derive from level %d" % stage)
   t.check(g.state.exhaust.any(func(c):return c.type==type),"HANNYA actual physical stage card exhausts")
   if stage<4: t.check(g.state.discard.any(func(c):return c.type=="hannya_%d" % (stage+1)),"HANNYA next stage enters discard")
   var gift={2:"hannya_swallow",3:"hannya_infusion",4:"hannya_henshin"}.get(stage,"")
   if gift!="": t.check(g.state.hand.any(func(c):return c.type==gift),"HANNYA stage gift enters hand")
  t.check(g.state.discard.any(func(c):return c.type=="good_soup"),"HANNYA fourth use creates soup before henshin is played")
  var view=g.get_view();var statuses=view.statuses.filter(func(s):return s.id.begins_with("power_hannya"))
  t.check(statuses.size()==1 and statuses[0].badge=="4" and statuses[0].detail.contains("力量＋4"),"HANNYA one status shows cumulative level and values")
  var restored=Save.roundtrip(t,g,"hannya level and all temporary variants")
  if restored!=null: t.check(restored.Cards.Hannya.level(restored)==4 and restored.RelicEffects.attribute(restored,"strength")==4,"HANNYA current snapshot restores effects without replaying rewards")
  var before=g.state.deck.size();var mana=g.state.mana
  t.check(Give.play(t,g,"hannya_4",free).ok and g.state.deck.size()==before+2 and g.state.mana==mana and g.Cards.Hannya.level(g)==4,"HANNYA capped fourth card gives only soup")
  g._finish_battle();t.check(g.Cards.Hannya.level(g)==4,"HANNYA victory preserves level")
  t.action(g,"reward",{"type":"skip"})
  t.check(g.Cards.Hannya.level(g)==4 and g.state.deck.any(func(c):return c.type=="good_soup"),"HANNYA reward-to-preparation retains buffs and generated deck")
  t.check(t.action(g,"finish_prepare").ok and g.Cards.Hannya.level(g)==0 and g.RelicEffects.attribute(g,"strength")==0,"HANNYA preparation exit clears all attributes and mechanics")
  t.check(g.state.deck.all(func(c):return not g.B.CARD_TRAITS.get(c.type,{}).get("temporary",false)) and g.state.deck.any(func(c):return c.type=="hannya_1") and g.validate()=="","HANNYA cleanup removes every temporary copy but keeps permanent first stage")
 progression(t)
 drinking(t)
 attacks(t)
 gifts(t)

static func progression(t) -> void:
 var g=setup()
 t.check(Give.play(t,g,"hannya_1",true).ok and Give.play(t,g,"hannya_1",false).ok and g.Cards.Hannya.level(g)==2,"HANNYA matching level advances rather than repeating first reward")
 t.check("hannya_short_strike" in g.state.card_buffs and "hannya_justice" not in g.state.card_buffs and g.state.discard.any(func(c):return c.type=="hannya_3"),"HANNYA matching level gets new level reward and does not switch original face bonus")
 var mana=g.state.mana;var size=g.state.deck.size()
 t.check(Give.play(t,g,"hannya_1",false).ok and g.Cards.Hannya.level(g)==2 and g.state.mana==mana and g.state.deck.size()==size+2 and g.state.discard.back().type=="good_soup","HANNYA lower card converts only to soup without downgrade")
 var card=Give.give(g,"hannya_2");var c=t.find_action(g,"card",{"uid":card.uid,"free":false});var before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"HANNYA stale candidate cannot spend, exhaust, advance or generate")
 g.get_view();g.command_facts();t.check(g.state==before,"HANNYA projections do not claim rewards or consume RNG")
 g.state.card_buffs.append("hannya_level_1")
 t.check(g.validate()!="","HANNYA snapshot rejects multiple simultaneous levels")
 g=setup();g.Cards.grant_buff(g,"echo_cast_bound")
 t.check(Give.play(t,g,"hannya_1",false).ok and g.Cards.Hannya.level(g)==1 and g.state.mana==25 and g.state.deck.filter(func(c):return c.type=="hannya_2").size()==1 and "echo_cast_bound" not in g.state.card_buffs,"HANNYA distinct first face can consume replay but one physical play grants only one level reward")
 g=setup();g.state.mana=99
 t.check(Give.play(t,g,"hannya_1",true).ok and g.state.mana==100 and g.state.logs.back().data.mana_gain==1,"HANNYA upgrade logs actual capped mana and still grants the level")
 g=setup();g.RelicEffects.gain(g,"gourd_flask");g.RelicEffects.gain(g,"gourd_flask")
 for i in range(5): g._gain_card("hannya_1")
 g._start_battle()
 t.check(g.state.hand.size()==6 and g.state.hand.all(func(c):return c.type=="hannya_1"),"HANNYA multiple innate cards expand opening draw to fit up to hand limit")
 g=setup();Give.play(t,g,"hannya_1",true)
 var second=g.state.discard.filter(func(c):return c.type=="hannya_2")[0]
 g.state.discard.erase(second);g.state.hand.append(second)
 while g.state.hand.size()<g.B.HAND_LIMIT: Give.give(g,"strain")
 t.check(t.action(g,"card",{"uid":second.uid,"free":false}).ok and g.state.hand.size()==10 and g.state.hand.any(func(c):return c.type=="hannya_swallow") and g.validate()=="","HANNYA ten-card hand frees exactly one slot for the generated gift")

static func drinking(t) -> void:
 for grade in range(1,4):
  for tier in range(1,4):
   var g=setup();g._install_template("mouth_band","mouth",30.0*tier/3,30.0,false,"fixture",grade,0)
   var card=Give.give(g,"hannya_1");var score=grade+tier
   var expected=1 if score<=2 else (2 if score<=4 else 3)
   for free in [false,true]:
    var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
    t.check(c.cost==expected and c.valid==(score<6) and c.mana==0,"HANNYA mouth grade %d tier %d shared cost and blocking both faces" % [grade,tier])
   var before=g.export_snapshot();var result=t.action(g,"card",{"uid":card.uid,"free":true})
   t.check((result.ok and g.state.energy==40-expected and g.state.rng.magic==before.rng.magic) if score<6 else (not result.ok and g.state==before),"HANNYA drink actually pays tier cost without casting or atomically rejects")
 var g=setup();g.add_fixture("upper_arm",1)
 t.check(g.restraint_degree("arms")>0 and g.restraint_degree("arms")<1,"HANNYA fractional upper restraint fixture")
 var card=Give.give(g,"good_soup")
 for posture in ["stand","sit","lie"]:
  g.state.posture=posture
  var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
  t.check(c.valid==(posture!="stand") and (posture!="stand" or c.reason.contains("坐姿或躺姿")),"HANNYA soup shares fractional upper-body sitting/lying restriction: "+posture)
 g.state.mana=97;var mana=g.state.mana
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.mana==100 and g.state.discard.any(func(c):return c.uid==card.uid) and g.Cards.Hannya.level(g)==0,"HANNYA soup caps recovery and discards without upgrading")
 t.check(mana==97,"HANNYA recovery boundary starts below cap")
 g=setup();var soup=Give.give(g,"good_soup");g.state.energy=0
 var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":soup.uid,"free":true}).ok and g.state==before,"HANNYA insufficient energy cannot restore mana or move soup")
 g.state.energy=2
 t.check(t.action(g,"card",{"uid":soup.uid,"free":true}).ok and use(t,g,"good_soup",false).ok and g.state.mana==40 and g.state.energy==0,"HANNYA soup can be redrawn and used repeatedly on either face")

static func attacks(t) -> void:
 for free in [false,true]:
  var g=setup()
  var heavy=t.find_action(g,"attack",{"type":"heavy","form":0})
  var combo=t.find_action(g,"attack",{"type":"heavy","form":1})
  t.check(Give.play(t,g,"hannya_1",free).ok,"HANNYA first-level attack modifier activates")
  var kick=t.find_action(g,"attack",{"type":"kick","form":0})
  t.check(kick.cost==(2 if free else 3) and kick.payload.interrupt==not free and kick.payload.cooldown_turns==(0 if free else 2),"HANNYA justice modifier changes cost interrupt and three-turn cooldown only on bound reward")
  t.check(t.find_action(g,"attack",{"type":"heavy","form":0}).payload.damage==heavy.payload.damage+(3 if free else 1) and t.find_action(g,"attack",{"type":"heavy","form":1}).payload.damage==combo.payload.damage+(2 if free else 1),"HANNYA heavy and combo add face-specific base plus actual strength per hit")
  if not free:
   t.check(g.dispatch(g.command(kick.payload,g.state.version),g.state.version).ok and not t.find_action(g,"attack",{"type":"kick","form":0}).valid,"HANNYA justice commits interrupt and blocks another kick during cooldown")
   g.state.round+=3
   t.check(t.find_action(g,"attack",{"type":"kick","form":0}).valid,"HANNYA justice recovers three turns later")
   g.state.posture="sit"
   t.check(g.kick_profile().cost==g.BasicAttacks.TYPES.kick[0].seated_cost,"HANNYA seated kick retains original cost")

static func gifts(t) -> void:
 var g=setup()
 for free in [false,true]:
  var played=setup();var gift=Give.give(played,"hannya_infusion");played.state.mana=9
  var offer=t.find_action(played,"card",{"uid":gift.uid,"free":free});var before=played.export_snapshot()
  t.check(not offer.valid and not played.dispatch(played.command(offer.payload,played.state.version),played.state.version).ok and played.state==before,"HANNYA infusion under ten mana rejects without mutation")
  played.state.mana=10
  offer=t.find_action(played,"card",{"uid":gift.uid,"free":free})
  t.check(offer.mana==10 and played.dispatch(played.command(offer.payload,played.state.version),played.state.version).ok and played.state.mana==0 and ("infusion_free" if free else "infusion_bound") in played.state.card_buffs and played.state.exhaust.any(func(c):return c.uid==gift.uid),"HANNYA infusion either face really pays ten and grants its matching interrupt")
 t.check(g.Cards.face_mana(g,"infusion",true)==20,"HANNYA infusion discount does not change ordinary infusion")
 for type in ["hannya_swallow","hannya_infusion","hannya_henshin"]:
  var traits=g.B.CARD_TRAITS[type]
  t.check(traits.exhaust and traits.ethereal and traits.temporary and g.Cards.Rules.SPECS[type].reward_excluded and type not in g.Cards.Rules.REWARDS,"HANNYA generated variants are temporary exhaust/ethereal and excluded from ordinary offers: "+type)
  for free in [false,true]:
   t.check(g.Cards.energy_cost(g,type,free)==(2 if type=="hannya_henshin" and free else 0),"HANNYA gift actual energy cost: %s %s" % [type,str(free)])
   var mana=g.Cards.face_mana(g,type,free)
   t.check(mana==(20 if type=="hannya_henshin" else (10 if type=="hannya_infusion" else 0)),"HANNYA gift retains required base mana: %s %s" % [type,str(free)])
 g._install_template("mouth_band","mouth",30,30,false,"fixture",3,0)
 var card=Give.give(g,"hannya_infusion")
 t.check(t.find_action(g,"card",{"uid":card.uid,"free":false}).valid,"HANNYA generated infusion does not inherit drinking block")
 g=setup();g.RelicEffects.gain(g,"binding_pyramid")
 card=Give.give(g,"hannya_swallow");card.retain_until=g.state.tick+8;g._discard_end()
 t.check(g.state.exhaust.any(func(c):return c.uid==card.uid),"HANNYA ethereal takes priority over pyramid and retain")
 g=setup();g.state.mana=100
 t.check(Give.play(t,g,"hannya_henshin",true).ok and g.state.mana==80 and g.state.energy==38 and g.Cards.damage_multiplier(g,"heavy")==2,"HANNYA perfect free henshin consumes twenty mana and two energy for original double damage")
 card=Give.give(g,"henshin");var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"HANNYA perfect and original henshin share nonstacking source")
 g=setup();g.state.mana=100;g.add_fixture("wrist",4)
 t.check(Give.play(t,g,"hannya_henshin",false).ok and g.state.mana==80 and g.state.energy==40 and g.state.equipment.is_empty(),"HANNYA perfect bound henshin retains actual release effect for zero energy")
