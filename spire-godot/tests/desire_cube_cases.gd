extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Opening=preload("res://core/game.gd")
const TYPE="desire_cube_pro_max"

static func run(t) -> void:
 opening(t)
 boss_pool(t)
 boss_bonus(t)
 curve(t)
 lifecycle(t)
 pool(t)

static func opening(t) -> void:
 for role in ["original"]:
  var g=Opening.new(42,false,"equipment",true,false,25,false,false,role)
  var initial=g.Departure.initial_relic(g)
  var before=g.export_snapshot()
  var choice=t.find_action(g,"departure",{"op":"choose","option":TYPE})
  g.get_view();g.command_facts()
  t.check(g.export_snapshot()==before,"DESIRE opening previews preserve resources and RNG: "+role)
  t.check(g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and initial not in g.state.relics and g.state.relics==[TYPE] and g.state.pressure==50 and g.state.deck.size()==before.deck.size() and g.state.hand.is_empty(),"DESIRE fixed opening replaces starter and basic card without boss bonus: "+role)
  before=g.export_snapshot();g.RelicEffects.gain(g,TYPE)
  t.check(not g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"DESIRE duplicate pickup and repeated choice cannot grant pressure: "+role)
  var restored=Opening.new(9)
  t.check(restored.restore_snapshot(before).ok and restored.state.pressure==50 and TYPE in restored.state.relics,"DESIRE save restores ownership without replaying pickup: "+role)
  t.check(TYPE not in g.Relics.REWARDS and TYPE in g.Relics.BOSS_POOL and TYPE not in g.Relics.shop_pool() and not g.Relics.transformable(TYPE),"DESIRE joins boss rewards but not ordinary rewards shops or transformation: "+role)
 var witch=Opening.new(42,false,"equipment",true,false,25,false,false,"witch")
 var witch_before=witch.export_snapshot()
 t.check(witch.state.departure.options.size()==4 and witch.state.departure.options.all(func(entry):return entry.id!=TYPE) and not t.action(witch,"departure",{"op":"choose","option":TYPE}).ok and witch.export_snapshot()==witch_before,"DESIRE witch keeps four opening choices without a dedicated cube exchange")
 var book=preload("res://data/encyclopedia.gd")
 t.check(book.entries(witch,"witch").any(func(entry):return entry.id==TYPE) and book.entries(witch,"original").any(func(entry):return entry.id==TYPE),"DESIRE encyclopedia exposes the boss relic for both roles")
 var legacy=Opening.new(42).export_snapshot();legacy.departure.options.pop_back();legacy.relic_seen.erase(TYPE)
 var restored=Opening.new(9)
 t.check(restored.restore_snapshot(legacy).ok and restored.get_view().reward_panel.destination.contains("四选一"),"DESIRE old four-option opening snapshot still restores")
 var blocked=Opening.new(42);blocked.state.relics.clear();var before=blocked.export_snapshot()
 t.check(not t.action(blocked,"departure",{"op":"choose","option":TYPE}).ok and blocked.export_snapshot()==before,"DESIRE missing initial relic rejects exchange atomically")

static func boss_pool(t) -> void:
 for role in ["original","witch"]:
  var g=Opening.new(42,false,"equipment",true,false,25,false,false,role)
  var before=g.export_snapshot()
  t.check(TYPE in g.RelicRewards.available(g,"boss") and g.Relics.TYPES[TYPE].rarity=="boss" and g.state==before,"DESIRE both roles have read-only boss eligibility: "+role)
  var excluded=g.Relics.BOSS_POOL.filter(func(id):return id!=TYPE)
  t.check(g.RelicRewards.offer(g,"boss",null,excluded)==TYPE,"DESIRE shared random boss offer can select cube: "+role)
  g.state.room="summit";g._start_battle();g._finish_battle();g.state.pressure=0.0
  for attempt in range(32):
   if TYPE in g.state.boss_relic_options: break
   g.RelicRewards.battle_drop(g)
  t.check(TYPE in g.state.boss_relic_options and g.state.boss_relic_options.size()==3,"DESIRE boss reward generation includes cube in three choices: "+role)
  var saved=g.export_snapshot();var restored=Opening.new(9)
  t.check(restored.restore_snapshot(saved).ok and restored.state.boss_relic_options==saved.boss_relic_options,"DESIRE boss reward survives save without reroll: "+role)
  var c=t.find_action(g,"reward",{"category":"relic","type":TYPE})
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==saved,"DESIRE stale boss pickup is atomic: "+role)
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and TYPE in g.state.relics and g.state.pressure==50 and is_equal_approx(g.cast_view({"parts":["mouth"]}).base,g.Pressure.cast_chance(50,g.Pressure.maximum(g),true)),"DESIRE actual boss pickup grants pressure and cast curve to either role: "+role)
  boss_cards(t,g,saved,role)
  t.check(g.state.relics.filter(func(id):return id not in saved.relics and g.Relics.TYPES[id].get("required_relic","")==TYPE).size()==1,"DESIRE boss pickup adds exactly one themed relic: "+role)
  var preserved=saved.deck.all(func(card):return g.state.deck.any(func(current):return current.uid==card.uid and current.type==card.type))
  var loaded=restored.restore_snapshot(g.export_snapshot())
  t.check(preserved and loaded.ok,"DESIRE boss grant preserves existing basic cards and claimed rewards survive saves: "+role+" "+str([preserved,loaded]))
  before=g.export_snapshot()
  t.check(TYPE not in g.RelicRewards.available(g,"boss") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"DESIRE ownership prevents another offer or duplicate pickup: "+role)

static func boss_cards(t, g, before: Dictionary, label: String) -> void:
 var previous_ids=before.deck.map(func(card):return card.uid)
 var added=g.state.deck.filter(func(card):return card.uid not in previous_ids)
 var heart=g.Character.card_id(g,"itching_heart")
 var hearts=added.filter(func(card):return card.type==heart)
 var rares=added.filter(func(card):return card.type!=heart)
 t.check(g.state.deck.size()==before.deck.size()+2 and added.size()==2 and hearts.size()==1 and g.state.hand.any(func(card):return card.uid==hearts[0].uid and card.type==heart),"DESIRE boss bonus adds a permanent heart and puts that same card into hand: "+label)
 t.check(rares.size()==1 and g.Cards.Rules.SPECS[rares[0].type].rarity=="rare" and g.Cards.Rules.SPECS[rares[0].type].get("reward_pool","")=="lewd_magic" and g.Character.allowed_card(g,rares[0].type),"DESIRE boss bonus adds one role-compatible rare from the themed pool: "+label)

static func boss_bonus(t) -> void:
 var g=preload("res://tests/departure_cases.gd").fixture("boss")
 g.state.departure.options[3].relics=[TYPE]
 if TYPE not in g.state.relic_seen: g.state.relic_seen.append(TYPE)
 var before=g.export_snapshot()
 t.check(t.action(g,"departure",{"op":"choose","option":"boss"}).ok,"DESIRE random opening boss exchange commits")
 boss_cards(t,g,before,"random opening")
 t.check(before.deck.all(func(card):return g.state.deck.any(func(current):return current.uid==card.uid and current.type==card.type)),"DESIRE random opening boss bonus preserves existing basic cards")
 g=Game.new(42)
 for id in g.Relics.REWARDS:
  if g.Relics.TYPES[id].get("required_relic","")==TYPE: g.RelicEffects.gain(g,id)
 while g.state.hand.size()<g.B.HAND_LIMIT: preload("res://tests/curse_cases.gd").give(g,"strain")
 before=g.export_snapshot();g.RelicEffects.gain(g,TYPE,"boss")
 t.check(g.state.relics.has(g.Relics.FALLBACK) and g.state.hand.size()==g.B.HAND_LIMIT and g.state.deck.size()==before.deck.size()+2 and g.state.discard.any(func(card):return card.type=="itching_heart"),"DESIRE exhausted themed relic pool falls back to log and full hand sends permanent heart to discard")
 before=g.export_snapshot();g.RelicEffects.gain(g,TYPE,"boss")
 t.check(g.state==before,"DESIRE duplicate pickup cannot repeat random cards relic or RNG")

static func curve(t) -> void:
 for limit in [75.0,100.0,130.0]:
  for row in [[0.0,0.0],[0.25,0.5],[0.5,1.0],[0.75,0.5],[1.0,0.0]]:
   t.check(is_equal_approx(Game.Pressure.cast_chance(limit*row[0],limit,true),row[1]),"DESIRE normalized curve matches exact anchor "+str(row)+" at cap "+str(limit))
  var previous=-1.0
  for i in range(51):
   var p=i/100.0;var chance=Game.Pressure.cast_chance(limit*p,limit,true)
   t.check(chance>=previous and chance>=0 and chance<=1 and is_equal_approx(chance,Game.Pressure.cast_chance(limit*(1-p),limit,true)),"DESIRE curve rises smoothly and mirrors its falling half")
   previous=chance
 var g=Game.new(42);g.state.relics=[TYPE];g.state.pressure=25
 t.check(is_equal_approx(g.cast_view({"parts":["mouth"]}).chance,0.5),"DESIRE real mouth projection consumes the new curve")
 var gag=g.add_fixture("mouth",4,10,false,1)
 var cast=g.cast_view({"parts":["mouth"]})
 t.check(cast.chance<0.5 and cast.base==0.5 and not cast.factors.is_empty(),"DESIRE mouth restraint factors still multiply after pressure curve")
 gag.durability=0;g._cleanup();g.state.pressure=0
 t.check(g.cast_view({"parts":["hand"]}).chance==0,"DESIRE pressure zero no longer guarantees casting")
 g.state.relics=[]
 t.check(g.cast_view({"parts":["hand"]}).chance==1 and Game.Pressure.cast_chance(25)==1,"DESIRE absent relic and unrelated default-curve callers preserve ordinary rules")
 for pressure in [0,50]:
  g=Game.new(42);g.state.relics=[TYPE];g.state.pressure=pressure
  var target=g.add_fixture("wrist",8);var card=t.hand_card(g,"ease")
  if pressure==0:
   var before=g.export_snapshot()
   t.check(not t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and g.export_snapshot()==before,"DESIRE zero chance preserves existing unusable-cast guard without payment or RNG")
   continue
  t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok,"DESIRE spell passes through formal dispatch")
  var spell=g.state.logs.filter(func(log):return log.data.has("spell")).back().data.spell
  t.check(spell.success==(pressure==50) and g.state.rng.magic==0,"DESIRE guaranteed endpoint failure and peak success use actual casting")

static func lifecycle(t) -> void:
 var g=Game.new(79);g.state.relics=[TYPE];g.state.pressure=40
 g._finish_battle()
 t.check(g.state.pressure==40 and g.state.combat.active,"DESIRE reward stage preserves existing battle-end settlement timing")
 t.action(g,"reward",{"type":"skip"});g.state.pressure=40
 t.check(t.action(g,"finish_prepare").ok and g.state.pressure==50 and not g.state.combat.active,"DESIRE battle session closes with ten pressure through normal preparation exit")
 var before=g.export_snapshot();g.RelicEffects.end_combat(g);g.get_view()
 t.check(g.export_snapshot()==before,"DESIRE completed session and view cannot repeat end effect")
 g=Game.new(79);g.state.relics=[TYPE];g._finish_battle();t.action(g,"reward",{"type":"skip"});g.state.pressure=95
 t.check(t.action(g,"finish_prepare").ok and g.state.pressure==5 and g.state.overload_total==1 and not g.state.overloaded,"DESIRE battle-end threshold uses ordinary overload then clears interruption on departure")
 for phase in ["rest","prison"]:
  g=Game.new(80,true,"prison_test") if phase=="prison" else Game.new(79)
  if phase=="rest": g._start_rest();t.action(g,"rest_begin")
  g.state.relics=[TYPE];g.state.pressure=40;g.RelicEffects.end_combat(g)
  t.check(g.state.pressure==40,"DESIRE non-battle session does not grant ending pressure: "+phase)

static func pool(t) -> void:
 var g=Game.new(42);var spec=g.Cards.Rules.SPECS.fire_control
 # Reuse one real card under a temporary tag; no placeholder card ships.
 var original=spec.duplicate(true);spec.reward_pool="lewd_magic"
 t.check(not g.can_offer_card("fire_control") and g.reward_offer(["fire_control"]).is_empty(),"DESIRE locked pool is absent from actual reward selection")
 g.state.relics.append(TYPE)
 t.check(g.can_offer_card("fire_control") and g.reward_offer(["fire_control"])==["fire_control"],"DESIRE ownership unlocks tagged cards through shared offer eligibility")
 g._gain_card("fire_control");g.state.relics.erase(TYPE)
 t.check(g.state.deck.any(func(card):return card.type=="fire_control") and not g.can_offer_card("fire_control"),"DESIRE losing relic closes future offers without deleting owned cards")
 var shared=g.Cards.Rules.SPECS.prepared_chant;var shared_original=shared.duplicate(true);shared.reward_pool="lewd_magic"
 # Character variants are registered before this temporary pool tag is applied.
 var mapped=g.Cards.Rules.SPECS.witch_prepared_chant;var mapped_original=mapped.duplicate(true);mapped.reward_pool="lewd_magic"
 var witch=Opening.new(42,false,"equipment",true,false,25,false,false,"witch")
 t.check(witch.Character.allowed_card(witch,"witch_prepared_chant") and not witch.can_offer_card("witch_prepared_chant") and witch.reward_offer(["prepared_chant"],"fixed",null,1,"lewd_magic").is_empty(),"DESIRE compatible mapped witch card remains locked until cube ownership")
 witch.RelicEffects.gain(witch,TYPE)
 var pool_cards=witch.Character.pool(witch,["prepared_chant"])
 t.check(witch.can_offer_card("witch_prepared_chant") and "witch_prepared_chant" in pool_cards and "prepared_chant" not in pool_cards and witch.reward_offer(["prepared_chant"],"fixed",null,1,"lewd_magic")==["witch_prepared_chant"],"DESIRE witch ownership unlocks the mapped card through the actual reward offer")
 shared.clear();shared.merge(shared_original)
 mapped.clear();mapped.merge(mapped_original)
 spec.clear();spec.merge(original)
