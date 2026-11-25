extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Trio="reinforced_rope_trio"

static func run(t) -> void:
 damage_and_rng(t)
 departure(t)
 enchantment(t)

static func damage_and_rng(t) -> void:
 var health={};var moves={}
 for seed in range(8):
  var g=Game.new(seed,true,Trio)
  var before=g.export_snapshot()
  for e in g.state.enemies:
   health[e.max_hp]=true;moves[e.intent.rope_move]=true
  g.get_view()
  t.check(g.export_snapshot()==before,"REINFORCED ROPE inspection never rerolls its opening")
 t.check(health.size()==6 and moves.size()==3,"REINFORCED ROPE rolls every health value and all opening moves")
 var g=Game.new(42,true,Trio)
 var e=g.state.enemies[0];var hp=e.hp
 var c=t.find_action(g,"attack",{"type":"heavy","form":0,"enemy":e.id})
 t.check(c.valid and c.payload.damage>8 and t.action(g,"attack",{"type":"heavy","form":0,"enemy":e.id}).ok and g._enemy(e.id).hp==hp-8,"REINFORCED ROPE limits a real heavy attack")
 e=g._enemy(e.id);hp=e.hp
 g._damage_enemy(e,30.0,"magic","测试")
 g._damage_enemy(e,30.0,"fixed","测试")
 t.check(e.hp==maxf(0,hp-16),"REINFORCED ROPE two separate hits each receive the cap")

static func departure(t) -> void:
 var g=Game.new(42,true,Trio)
 var e=g.state.enemies[0]
 var ropes=g.ReinforcedRope
 for other in g.state.enemies.slice(1): g._defeat_enemy(other)
 e.rope_strength=1;e.rope_previous="single"
 t.check(g._plan(e).rope_move!="single","REINFORCED ROPE excludes the last executed move")
 e.intent=ropes.declaration(g,e,"strengthen");e.intent.delayed=true
 g._enemy_phase()
 t.check(e.rope_strength==1 and e.intent.rope_move=="strengthen" and not e.intent.delayed,"REINFORCED ROPE interruption keeps the announced move and count")
 g.state.round+=1;g._enemy_phase()
 var plan=g.EnemyPlans.application_spec(g,e,ropes.declaration(g,e,"single"))
 t.check(e.rope_strength==2 and plan.profiles==[{"grade":3,"tier":3}],"REINFORCED ROPE second enhancement can apply the highest profile")
 e.intent=ropes.declaration(g,e,"strengthen")
 g.state.round+=1;g._enemy_phase()
 t.check(e.rope_strength==3 and not e.gone and g._plan(e).kind=="leave","REINFORCED ROPE third strengthening is replaced by a preparation turn")
 g.state.round+=1;e.intent=g._plan(e)
 var twin=Save.roundtrip(t,g,"reinforced rope announced departure")
 if twin!=null: Save.step_both(t,g,twin,"end")
 t.check(g._enemy(e.id).gone and not g._enemy(e.id).defeated and g.state.equipment.any(func(item):return item.source==e.id and item.grade==3 and item.get("enchantment","")=="tighten"),"REINFORCED ROPE departure applies an enchanted advanced restraint")
 g=Game.new(42,true,Trio);e=g.state.enemies[0]
 e.rope_strength=3;e.rope_previous="strengthen";e.intent=g._plan(e)
 g._defeat_enemy(e)
 t.check(g.state.equipment.is_empty() and e.defeated,"REINFORCED ROPE killing an enemy cancels its announced attachment")

static func enchantment(t) -> void:
 var g=Game.new(42,true,Trio)
 var e=g.state.enemies[0];var spec=g.ReinforcedRope.application(g,1,6,true)
 spec.allow_links=true
 for attempt in range(100):
  if not g.Application.execute(g,spec,"fixture").ok: break
 var target=g.ReinforcedRope.fallback(g)
 t.check(not g.Application.can_apply(g,spec,e.id) and not target.is_empty() and g._finish_if_saturated(),"REINFORCED ROPE saturated battle resolves departure attachments")
 var enchanted=g.state.equipment.filter(func(item):return item.get("enchantment","")=="tighten")
 t.check(enchanted.size()==3 and target in enchanted and g.state.enemies.all(func(enemy):return enemy.gone and not enemy.defeated),"REINFORCED ROPE saturated departure enchants three distinct real restraints")
 var finished=g.export_snapshot()
 t.check(not g._finish_if_saturated() and g.export_snapshot()==finished,"REINFORCED ROPE without live sources cannot enchant or reward again")
 g=Game.new(42,true,Trio);e=g.state.enemies[0]
 for attempt in range(100):
  if not g.Application.execute(g,spec,"fixture").ok: break
 g.state.round=g.B.ENEMY_LONG_BATTLE_ROUND
 t.check(g.EnemyPlans.long_battle_limit(g) and g._finish_if_saturated() and g.state.logs.any(func(log):return log.data.get("long_battle_departure","")==e.id) and g.state.equipment.any(func(piece):return piece.get("enchantment","")=="tighten"),"REINFORCED ROPE long-battle departure runs the same enchantment before rewards")
 g=Game.new(42,true,Trio)
 var item=g.add_fixture("wrist",7.9,10,false,0,"rope")
 t.check(g.EquipmentEnchantments.attach(g,item,"tighten","测试") and not g.EquipmentEnchantments.attach(g,item,"tighten","测试"),"REINFORCED ROPE same enchantment cannot stack")
 var twin=Save.roundtrip(t,g,"equipment enchantment")
 if twin!=null: Save.step_both(t,g,twin,"end")
 item=g._equipment(item.id)
 t.check(is_equal_approx(item.durability,9.9) and g.equipment_tier(item)==3,"REINFORCED ROPE player turn end restores two and refreshes tightness")
 g.EquipmentEnchantments.turn_end(g)
 t.check(item.durability==item.maximum,"REINFORCED ROPE healing cannot exceed maximum durability")
 var before=g.export_snapshot();var invalid=before.duplicate(true)
 invalid.equipment.filter(func(piece):return piece.id==item.id)[0].enchantment="invalid"
 t.check(not g.restore_snapshot(invalid).ok and g.export_snapshot()==before,"REINFORCED ROPE unknown equipment enchantment rejects atomically")
 item.durability=0.0;g._cleanup()
 t.check(g._equipment(item.id).is_empty(),"REINFORCED ROPE removing the item removes its enchantment")
