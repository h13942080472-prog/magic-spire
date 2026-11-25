extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Encounter="binding_box_plus_solo"

static func run(t) -> void:
 cycle(t)
 tough_durability(t)
 fitting(t)
 curses(t)
 departure(t)

static func cycle(t) -> void:
 var g=Game.new(42,true,Encounter)
 t.check(g.state.enemies.size()==1 and g.state.enemies[0].hp==86 and g.state.enemies[0].intent.kind=="plus_curse","BOX PLUS fixed health and opening intent")
 for move in ["plus_curse","plus_double","plus_boost","plus_fit","plus_tough"]:
  var e=g.state.enemies[0]
  t.check(e.intent.kind==move,"BOX PLUS planned move "+move)
  t.check(t.action(g,"end").ok,"BOX PLUS executes real end turn for "+move)
  if move=="plus_fit" and g.state.round==5:
   t.check(g.state.equipment.any(func(item):return item.slot=="mouth" and item.source==e.id) and g.state.special_equipment.size()==1,"BOX PLUS fitting chooses mouth before other legal regions and installs a toy")
  if move=="plus_tough":
   var item=g.state.equipment.filter(func(piece):return piece.get("enchantment","")=="tough")[0]
   t.check(item.grade==2 and g.equipment_tier(item)==3 and item.maximum==g.Equipment.maximum(2) and item.durability==item.maximum and item.tough_durability==8.0,"BOX PLUS tough attachment uses boosted grade and independent durability")
   var twin=Save.roundtrip(t,g,"box boost and enchanted restraint")
   if twin!=null: Save.step_both(t,g,twin,"end")
   t.check(g.state.enemies[0].intent.kind=="plus_boost" and t.action(g,"end").ok and g.state.enemies[0].intent.kind=="plus_fit","BOX PLUS refresh follows three enhanced turns and resumes the cycle")
 # Start from a retained attack that crosses the end of the enhancement.
 g=Game.new(42,true,Encounter)
 var e=g.state.enemies[0]
 e.plus_step=4;e.plus_boost_until=1;e.intent=g._plan(e);e.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.enemies[0].intent.kind=="plus_tough" and g.state.enemies[0].plus_step==4,"BOX PLUS interrupt retains the old action")
 t.check(t.action(g,"end").ok and g.state.enemies[0].intent.kind=="plus_boost","BOX PLUS renews expired enhancement before the next fresh action")
 var base=g.state.equipment.filter(func(item):return item.get("enchantment","")=="tough")[0]
 t.check(base.grade==1 and base.maximum==g.Equipment.maximum(1) and base.tough_durability==8.0,"BOX PLUS expired boost does not upgrade a delayed installation")
 var invalid=g.export_snapshot()
 invalid.enemies[0].plus_boost_until=g.state.round+9
 var before=g.export_snapshot()
 t.check(not g.restore_snapshot(invalid).ok and g.export_snapshot()==before,"BOX PLUS invalid boost duration rolls back saved state")
 invalid=before.duplicate(true)
 var saved_item=invalid.equipment.filter(func(item):return item.get("enchantment","")=="tough")[0]
 saved_item.maximum-=1;saved_item.durability=saved_item.maximum
 t.check(not g.restore_snapshot(invalid).ok and g.export_snapshot()==before,"BOX PLUS rejects a mismatched enchanted durability ceiling atomically")
 var unsupported=g.BindingBoxPlus.ordinary(g,4)
 unsupported.enchantment="tough"
 unsupported.replace=true
 t.check(not g.Application.execute(g,unsupported,e.id).ok and g.export_snapshot()==before,"BOX PLUS an enchanted replacement fails before changing state or RNG")

static func tough_durability(t) -> void:
 var g=Game.new(42,true,Encounter)
 var spec=g.EnemyPlans.application(["belt"],1,2)
 spec.allow_links=false
 spec.required_slots=["wrist"]
 spec.enchantment="tough"
 var result=g.Application.execute(g,spec,"fixture")
 t.check(result.ok and result.installed.size()==1,"TOUGH supports a new two-tier restraint")
 if not result.ok: return
 var item=result.installed[0]
 var id=item.id
 var base=item.durability
 t.check(g.equipment_tier(item)==2 and item.tough_durability==8.0 and item.maximum==g.Equipment.maximum(1),"TOUGH has independent durability at installation without tightening the restraint")
 var card=t.grant_fixture_card(g,"strain")
 t.check(t.action(g,"card",{"uid":card.uid,"target":id}).ok,"TOUGH uses the normal strain card route")
 item=g._equipment(id)
 t.check(item.durability==base and item.tough_durability>0.0 and item.tough_durability<8.0 and g.equipment_tier(item)==2,"TOUGH strain damage first absorbs into the bonus pool")
 var projected=g.View.equipment_entry(g,item,item.slot)
 t.check(projected.durability==base and projected.tier==2 and projected.card_status.contains(g.number(item.tough_durability)+"/8"),"TOUGH details project the remaining bonus separate from the base")
 var twin=Save.roundtrip(t,g,"partially consumed toughness")
 if twin!=null: t.check(is_equal_approx(twin._equipment(id).tough_durability,item.tough_durability),"TOUGH partially spent bonus survives reload")
 g._apply_equipment_damage(item,item.tough_durability+2.0,"cut")
 t.check(is_zero_approx(item.tough_durability) and is_equal_approx(item.durability,base-2.0),"TOUGH overflow reaches the base after the bonus pool empties")
 var before=g.export_snapshot()
 for bad_bonus in [-1.0,9.0,"8",null]:
  var broken=before.duplicate(true)
  if bad_bonus==null: broken.equipment[0].erase("tough_durability")
  else: broken.equipment[0].tough_durability=bad_bonus
  t.check(not g.restore_snapshot(broken).ok and g.export_snapshot()==before,"TOUGH invalid or missing current bonus fails atomically")
 var orphan=before.duplicate(true)
 orphan.equipment[0].erase("enchantment")
 t.check(not g.restore_snapshot(orphan).ok and g.export_snapshot()==before,"TOUGH bonus cannot be loaded on an unenchanted restraint")
 var old=before.duplicate(true)
 old.save_revision=g.Snapshot.TOUGH_LEGACY_REVISION
 old.equipment[0].erase("tough_durability")
 old.equipment[0].maximum+=8.0
 old.equipment[0].durability=old.equipment[0].maximum*0.5
 var old_copy=old.duplicate(true)
 t.check(g.restore_snapshot(old).ok and old==old_copy,"TOUGH old merged durability migrates without mutating the caller snapshot")
 item=g._equipment(id)
 t.check(g.equipment_tier(item)==2 and item.durability==item.maximum*0.5 and item.tough_durability==4.0 and g.EquipmentEnchantments.total_durability(item)==old.equipment[0].durability,"TOUGH migration preserves total remaining durability and the old tier")
 g._apply_manual_release(item,g.lower_durability(item.durability,item.maximum))
 t.check(g.equipment_tier(item)==1 and item.tough_durability==4.0,"TOUGH direct loosening still acts on the base")
 var maximum=g.Equipment.maximum(1)
 var host=g._install_template("rope","upper_arm",maximum,maximum,false,"fixture")
 var saved=g.export_snapshot()
 var copy=Save.roundtrip(t,g,"restraint with independent shoulder pieces")
 if copy==null: return
 var clean=copy.export_snapshot()
 var invalid_fields={"enchantment":"tough","tough_durability":8.0}
 for bad_field in invalid_fields:
  var broken=saved.duplicate(true)
  var corrupted_host=broken.equipment.filter(func(piece):return piece.id==host.id)[0]
  corrupted_host.shoulders.pieces[0][bad_field]=invalid_fields[bad_field]
  t.check(not copy.restore_snapshot(broken).ok and copy.export_snapshot()==clean,"TOUGH rejects an unsupported shoulder enchantment field without changing state: "+bad_field)

static func fitting(t) -> void:
 for blocked in [true,false]:
  var g=Game.new(42,true,Encounter)
  var e=g.state.enemies[0]
  e.plus_step=3;e.plus_boost_until=3;e.intent=g._plan(e)
  var special=g.EnemyPlans.application_spec(g,e,g.EnemyPlans.special_application(g,e))
  if blocked:
   for attempt in range(20):
    if not g.Application.execute(g,special,"fixture").ok: break
   t.check(not g.Application.can_apply(g,special,e.id),"BOX PLUS special gear has no legal space in the full case")
  else: g.state.evasion=2
  var special_count=g.state.special_equipment.size()
  t.check(t.action(g,"end").ok and g.state.special_equipment.size()==special_count,"BOX PLUS fitting completes when its special install is blocked or evaded")
  var worn=g.state.equipment.filter(func(item):return item.source==e.id)
  var restraint_value=preload("res://data/restraint_value.gd")
  t.check(worn.size()==(3 if blocked else 1) and worn.any(func(item):return item.slot in g.B.LEG_SLOTS) and worn.all(func(item):return restraint_value.from_profile(item.grade,g.equipment_tier(item))==5),"BOX PLUS full toys add one boosted ordinary restraint, evaded toys do not")

static func curses(t) -> void:
 var g=Game.new(42,true,Encounter)
 var magic=t.grant_fixture_card(g,"mana_surge")
 t.check(t.action(g,"card",{"uid":magic.uid,"free":true}).ok and g.state.deck.all(func(c):return c.type!="disrupt"),"BOX PLUS magic before the curse creates no status")
 t.check(t.action(g,"end").ok and "spell_curse" in g.state.card_buffs,"BOX PLUS opening grants the battle curse")
 magic=t.hand_card(g,"mana_surge")
 t.check(t.action(g,"card",{"uid":magic.uid,"free":true}).ok and g.state.draw.filter(func(c):return c.type=="disrupt").size()==1,"BOX PLUS one played magic card inserts a status into the draw pile")
 var skill=t.grant_fixture_card(g,"confluence")
 t.check(t.action(g,"card",{"uid":skill.uid,"free":false}).ok and g.state.draw.filter(func(c):return c.type=="disrupt").size()==1,"BOX PLUS skills do not trigger the curse")
 g.state.strength=4;g.state.dexterity=4
 g._discard_end()
 for i in range(2):
  var index=g.state.draw.find_custom(func(c):return c.type=="disrupt")
  if index<0:
   g._gain_temporary_card("disrupt",true)
   index=g.state.draw.find_custom(func(c):return c.type=="disrupt")
  var status=g.state.draw.pop_at(index)
  g.state.draw.append(status)
  g._draw(1)
 t.check(g.RelicEffects.attribute(g,"strength")==2 and g.RelicEffects.attribute(g,"dexterity")==2,"BOX PLUS two drawn statuses apply stacking negative attributes")
 var status=g.state.hand.filter(func(c):return c.type=="disrupt")[0]
 t.check(not t.action(g,"card",{"uid":status.uid,"free":false}).ok,"BOX PLUS Disruption cannot be played")
 # Isolate expiry from the new turn drawing the same two status cards again.
 for drawn in g.state.hand.filter(func(c):return c.type=="disrupt"):
  g.state.hand.erase(drawn)
  g.state.exhaust.append(drawn)
 t.check(t.action(g,"end").ok and "disrupt_draw" not in g.state.card_buffs,"BOX PLUS temporary losses expire at player turn end")
 g._defeat_enemy(g.state.enemies[0]);g._finish_if_saturated()
 t.check("spell_curse" not in g.state.card_buffs and g.state.deck.all(func(c):return c.type!="disrupt"),"BOX PLUS victory clears curse and statuses before preparation")
 g=Game.new(42,true,Encounter)
 t.action(g,"end")
 var e=g.state.enemies[0]
 g.state.sure_cast=true
 t.check(t.action(g,"attack",{"type":"fireball","enemy":e.id}).ok and g.state.deck.all(func(c):return c.type!="disrupt"),"BOX PLUS the basic Fireball action does not trigger Spell Curse")
 g.state.pressure=75
 var card=t.grant_fixture_card(g,"mana_surge")
 var rng=g.state.rng.magic
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"mana_surge")).winning_rolls: rng=g.state.rng.magic
 g.state.rng.magic=rng
 var count=g.state.draw.size()
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g._magic_failed and g.state.draw.size()==count+1 and g.state.hand.any(func(c):return c.uid==card.uid),"BOX PLUS paid failed magic triggers curse while preserving the original card")

static func fill_equipment(g, e: Dictionary) -> void:
 for plan in g.BindingBoxPlus.installations(g,e):
  var spec=g.EnemyPlans.application_spec(g,e,plan)
  for i in range(100):
   if not g.Application.execute(g,spec,"fixture").ok: break

static func departure(t) -> void:
 var g=Game.new(42,true,Encounter)
 var e=g.state.enemies[0]
 g.state.security=2
 fill_equipment(g,e)
 t.check(g._finish_if_saturated() and e.gone and not e.defeated and g.state.security==3,"BOX PLUS saturating equipment uses withdrawal and raises alert")
 var settled=g.export_snapshot()
 t.check(not g._finish_if_saturated() and g.export_snapshot()==settled,"BOX PLUS alert and rewards settle once")
 g=Game.new(42,true,Encounter);e=g.state.enemies[0];g.state.security=5
 g._depart_enemy(e)
 t.check(g.state.security==5,"BOX PLUS departure respects the alert ceiling")
 g=Game.new(42,true,Encounter);e=g.state.enemies[0]
 fill_equipment(g,e)
 g.state.round=g.B.ENEMY_LONG_BATTLE_ROUND
 t.check(g.EnemyPlans.long_battle_limit(g) and g._finish_if_saturated() and e.gone and g.state.security==1 and g.state.logs.any(func(log):return log.data.get("long_battle_departure","")==e.id),"BOX PLUS long battles also withdraw with one alert rise")
 g=Game.new(42,true,Encounter);e=g.state.enemies[0];g.state.security=1
 g._defeat_enemy(e);g._finish_if_saturated()
 t.check(e.defeated and g.state.security==1,"BOX PLUS killing the box skips the departure penalty")
