extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Release=preload("res://core/release_view.gd")

static func fresh():
 var g=Game.new(42,true,"rope_solo");g._discard_end();g.state.relics=[];g.state.energy=20;g.state.mana=100;g.state.mana_max=100
 return g

static func install(g, type: String) -> Dictionary:
 var result=g.Application.execute(g,g.EnemyPlans.application([type],2,2),"fixture")
 return {} if result.installed.is_empty() else g._equipment(result.installed[0].id)

static func run(t) -> void:
 for type in preload("res://data/equipment.gd").SHACKLES:
  var g=fresh();var item=install(g,type)
  t.check(not item.is_empty(),"SHACKLE formal installer accepts value-four single-quality template: "+type)
  if item.is_empty(): continue
  t.check(item.maximum==999 and item.durability==999 and item.locked and item.grade==1 and g.equipment_tier(item)==0 and not item.has("binding"),"SHACKLE fixed durability lock and no tightness or torso attachment: "+type)
  t.check(g.Equipment.physical_points(item)==g.Equipment.points(item.slot) and g.jointly_bound(item.slot),"SHACKLE one piece binds both sides through ordinary coverage")
  t.check(not g._can_tighten(item) and g.Cards.worn_count(g)==1 and g.Cards.worn_count(g,true,1)==0,"SHACKLE counts once but never counts as a tightness tier")
  var unchanged=g.export_snapshot()
  g._reinforce_equipment(item,3)
  t.check(g.export_snapshot()==unchanged and g.Equipment.definition_reason(type,item.slot,2,true)!="","SHACKLE reinforcement cannot mutate and second quality rejects")
  var preview=g.escape_preview(item,"strain",100)
  t.check(preview.reason=="" and preview.multiplier==1 and preview.lock_multiplier==1 and is_equal_approx(preview.penalty,0.1),"SHACKLE fixed reduction excludes ordinary lock and tightness multipliers")
  var initial=preview.damage;item.durability=90
  t.check(is_equal_approx(g.escape_preview(item,"strain",100).damage,initial),"SHACKLE damage reduction does not weaken with durability")
  var bad=g.export_snapshot();bad.equipment[0].maximum=998
  var before=g.export_snapshot()
  t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==before,"SHACKLE invalid fixed durability snapshot rejects atomically")
  var twin=Save.roundtrip(t,g,"shackle "+type)
  t.check(twin!=null and twin.equipment_tier(twin.state.equipment[0])==0,"SHACKLE damaged fixed-profile piece survives restore")
  t.check(g.validate()=="","SHACKLE installed state validates")
  g._unlock_equipment(item);g._cleanup()
  t.check(g._equipment(item.id).is_empty(),"SHACKLE common unlock removes whole physical piece")
 actions(t)
 pools(t)
 replacement(t)
 relics_and_preview(t)

static func actions(t) -> void:
 var g=fresh();var item=install(g,"handcuffs")
 var card=Cards.give(g,"strain");var c=t.find_action(g,"card",{"uid":card.uid,"target":item.id,"free":false})
 var before=item.durability
 t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(item.id).durability,before-c.payload.preview.damage),"SHACKLE paid strain applies reduced preview damage exactly once")
 card=Cards.give(g,"ease");var snapshot=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"target":item.id,"free":false}).ok and g.export_snapshot()==snapshot,"SHACKLE lowering has no payment or state effect")
 g.state.sure_cast=true
 card=Cards.give(g,"unlock")
 t.check(t.action(g,"card",{"uid":card.uid,"target":item.id,"free":false}).ok and g._equipment(item.id).is_empty(),"SHACKLE successful unlock card takes off the cuffs")
 item=install(g,"ankle_cuffs");g.state.posture="sit";g._gain_tool("picks");var tool=g.state.items.back()
 var uses=tool.uses
 t.check(t.action(g,"item_use",{"item":tool.id,"target":item.id}).ok and g._equipment(item.id).is_empty() and g._item(tool.id).uses==uses-1,"SHACKLE lockpick takes off the cuffs and spends one use")
 item=install(g,"toe_cuffs");item.durability=0.01
 card=Cards.give(g,"slip")
 t.check(t.action(g,"card",{"uid":card.uid,"target":item.id,"free":false}).ok and g._equipment(item.id).is_empty(),"SHACKLE ordinary slip can break the remaining durability without tier immunity")

static func pools(t) -> void:
 for encounter in ["guard_solo","trader_solo","six_bind_solo","iron_man_solo","drone_solo","binding_box_solo"]:
  var g=Game.new(42,false);g.state.room_encounters.entrance=encounter;g._start_battle()
  var enemy=g.state.enemies[0]
  var spec=g.EnemyPlans.application_spec(g,enemy,g.EnemyPlans.application(["belt"],2,2))
  t.check(g.Equipment.SHACKLES.all(func(type):return type in spec.templates),"SHACKLE human and mechanical ordinary pools include cuffs: "+encounter)
 var g=fresh();var spec=g.EnemyPlans.application_spec(g,g.state.enemies[0],g.EnemyPlans.application(["rope"],2,2))
 t.check(not spec.templates.any(func(type):return type in g.Equipment.SHACKLES),"SHACKLE floating nonhuman equipment cannot generate cuffs")
 for value in [3,4,5]:
  g=fresh();spec=g.EnemyPlans.application(["handcuffs"],2,2,1,false,value)
  var before=g.export_snapshot();var legal=g.Application.can_apply(g,spec,"fixture")
  t.check(legal==(value==4) and g.export_snapshot()==before,"SHACKLE fixed value participates only in matching budget with readonly legality")
 g=fresh();spec=g.EnemyPlans.application(["handcuffs"],2,2);spec.ready_layers=1
 var applied=g.Application.execute(g,spec,"fixture")
 t.check(applied.ok and applied.ready_used==1 and g.equipment_tier(g.state.equipment[0])==0,"SHACKLE successful installation consumes preparation under the shared rule without adding tightness")
 g.state.security=1
 t.check(not g.Prison.equipment_spec(g,1).templates.any(func(type):return type in g.Equipment.SHACKLES),"SHACKLE enemy-only pool does not change prison intake specifications")

static func replacement(t) -> void:
 var g=fresh()
 for i in range(3): install(g,"handcuffs")
 var result=g.Application.execute(g,{"pool":"ordinary","templates":["belt"],"grade":3,"tier":2,"count":1,"slot":"wrist","allow_links":false,"replace":true},"event:fixture")
 t.check(result.ok and result.removed.size()==1 and g.equipment_at("wrist").size()==3,"SHACKLE can be replaced at full capacity by a stronger legal ordinary piece")

static func relics_and_preview(t) -> void:
 var g=fresh();g.state.relics=["silk_ring"]
 var item=install(g,"toe_cuffs");item.durability=0.01
 var card=Cards.give(g,"slip");var hand_count=g.state.hand.size()
 t.check(t.action(g,"card",{"uid":card.uid,"target":item.id,"free":false}).ok and g._equipment(item.id).is_empty() and g.state.hand.size()==hand_count,"SHACKLE slip destruction triggers the ring draw once despite having no tier")
 g=fresh();g.state.relics=["silk_ring"]
 item=install(g,"finger_cuffs")
 var main=g._install_template("belt","palm",70,100,false,"fixture")
 card=Cards.give(g,"slip");hand_count=g.state.hand.size()
 t.check(t.action(g,"card",{"uid":card.uid,"target":main.id,"free":false}).ok and g._equipment(item.id).durability<999 and g._equipment(item.id).durability>0 and g.state.hand.size()==hand_count-1,"SHACKLE collateral damage without destruction never invents a tier-drop relic trigger")
 g=fresh();item=install(g,"handcuffs");g.state.sure_cast=true
 card=Cards.give(g,"unlock")
 var c=t.find_action(g,"card",{"uid":card.uid,"target":item.id,"free":false})
 var preview=Release.preview(g,c)
 t.check(preview.headline=="开锁 → 整件取下" and preview.after==0 and not preview.note.contains("不变"),"SHACKLE unlock preview agrees with immediate removal")
 item.durability=799.21
 card=Cards.give(g,"strain");c=t.find_action(g,"card",{"uid":card.uid,"target":item.id,"free":false})
 preview=Release.preview(g,c)
 t.check(preview.after<799.2 and not preview.note.contains("紧度"),"SHACKLE damage crossing an ordinary tier threshold never displays a tightness change")
 g.state.phase="rest"
 var before=g.export_snapshot()
 t.check(not t.action(g,"hook",{"target":item.id}).ok and g.export_snapshot()==before,"SHACKLE hook cannot spend a use on nonexistent tightness")
 preload("res://tests/event_cases.gd").arrive(g,"alchemist_tasting_stall")
 var selected=g.Events.view(g).selections[0].options[0].selected
 t.check(selected.id==item.id and selected.no_tightness and selected.tier==0,"SHACKLE actual event selector carries no-tightness projection")
