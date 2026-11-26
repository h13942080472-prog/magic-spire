extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func find(g,id: String) -> Dictionary:
 var rows=g.get_view().statuses.filter(func(e):return e.id==id)
 return {} if rows.is_empty() else rows[0]

static func run(t) -> void:
 preload("res://tests/charge_cases.gd").run(t)
 var g=Game.new(42)
 var before=JSON.stringify(g.state)
 t.check(find(g,"arms").value=="0 / 4级" and find(g,"legs").value=="0 / 4级","STATUS zero body levels remain visible")
 t.check(find(g,"strength").value==g.number(g.state.strength),"STATUS environmental true damage is not a character attribute")
 t.check(JSON.stringify(g.state)==before,"STATUS projection does not change any state/random stream")
 g._gain_temporary_card("tease")
 t.check(find(g,"curse").is_empty() and find(g,"status_cards").value=="1张","STATUS temporary status cards do not inflate curse totals")
 g.Cards.purge_temporary(g)
 t.check(find(g,"status_cards").is_empty(),"STATUS temporary cleanup also removes status-card summary")
 var mask=g.add_fixture("eyes",4)
 t.check(find(g,"vision").tone=="bad" and g.get_view().statuses.any(func(status):return status.id=="vision" and status.tone=="bad"),"STATUS real eye restriction has one structured status")
 g.add_fixture("ankle",8)
 t.check(find(g,"legs").value==str(g.level("legs"))+" / 4级" and find(g,"posture").value.contains(g.movement_profile().mode) and find(g,"movement").is_empty(),"STATUS posture and movement share one row using actual rules")
 before=JSON.stringify(g.state)
 var rows=g.get_view().statuses
 g.state.enemies[0].intent.text="尚未公开的测试意图"
 t.check(g.get_view().statuses==rows,"STATUS never reveals hidden enemy plan through status catalogue")
 g=Game.new(42)
 g.state.charge=2;g.state.temporary_mana=15;g.state.next_energy=2
 t.check(find(g,"charge").value=="2层" and find(g,"temporary_mana").value=="15点" and find(g,"charge").detail.contains("滑脱"),"STATUS carried buffs keep separate stacks")
 t.check(t.action(g,"attack",{"type":"strike","enemy":"enemy_1"}).ok and find(g,"charge").is_empty(),"STATUS formal strike consumes all charge and removes the status")
 g=Game.new(42,true,"pressure")
 t.check(g.get_view().statuses.any(func(e):return e.id.begins_with("pressure_")),"STATUS includes active pressure sources")
 var old=g.state.pressure
 t.check(t.action(g,"calm").ok and g.state.pressure<old and find(g,"pressure").value.begins_with(g.number(g.state.pressure)),"STATUS formal calm updates shared pressure fact")
 for key in g.Tower.all_practices():
  var p=Game.new(42,true,key)
  before=JSON.stringify(p.state)
  var entries=p.get_view().statuses
  var ids=[];var valid=true
  for row in entries:
   if row.id in ids or row.name=="" or row.detail=="" or row.source=="" or row.duration=="" or row.icon not in preload("res://ui/status_icon.gd").KINDS: valid=false
   if row.category=="relic" or row.id.begins_with("equipment_") and row.id!="equipment_stimulation": valid=false
   ids.append(row.id)
  t.check(valid and JSON.stringify(p.state)==before,"STATUS complete, unique, read-only projection: "+key)
 # Removal via the actual card transaction must remove its attached status too.
 g=Game.new(20260906)
 mask=g.add_fixture("eyes",4)
 var card=g.state.hand.filter(func(c):return c.type=="slip")[0]
 t.check(t.action(g,"card",{"uid":card.uid,"slot":"eyes","target":mask.id,"free":false}).ok and find(g,"vision").tone=="neutral","STATUS last eye removal immediately restores vision")
 g=Game.new(42)
 g._install_assembly("wrap","left","fixture",1,1)
 t.check(find(g,"hand_left").tone=="bad" and find(g,"hand_right").tone=="neutral" and find(g,"hand_right").source=="当前身体状态","STATUS unilateral equipment never becomes opposite hand source")
 t.check(find(g,"arms").value=="1 / 4级" and find(g,"arms").source!="当前身体状态" and g.hands_can_hold(),"STATUS one-sided wrap contributes one arm point and names source while opposite hand can hold")
 g.add_fixture("toes",4)
 t.check(find(g,"toes").tone=="bad","STATUS actual toe restriction included")
 g=Game.new(42,true,"guard")
 g.state.security=4
 g.Guard.capture(g,g.state.enemies[0])
 t.check(t.action(g,"prison",{"action":"enter"}).ok and g.state.phase=="prison" and g.state.prison.left==g.B.PRISON_INTERVALS[4],"STATUS security five enters the ordinary top-spec cell")
 t.check(find(g,"terminal").is_empty() and find(g,"inspection").value=="剩余8回合","STATUS five shows the shortest patrol timer instead of a terminal row")
 consolidation(t)

static func consolidation(t) -> void:
 var g=Game.new(42)
 g.state.relics=["smooth_stockings","mana_earring","happy_fa","break_bracer"]
 g.state.charge=2;g.state.temporary_mana=5
 var before=g.state.duplicate(true)
 var rows=g.get_view().statuses
 t.check(rows.all(func(row):return row.category!="relic" and row.id not in ["leg_dexterity","mana_earring_progress","hand_strength","hand_dexterity","casting","order","movement"]),"STATUS relic passives and duplicate attribute/casting/movement rows removed")
 t.check(find(g,"charge").badge=="2" and find(g,"temporary_mana").badge=="5" and find(g,"arms").active==false,"STATUS actual buffs keep counters while zero restrictions stay off the battle strip")
 t.check(g.state==before and g.get_view().relics.all(func(relic):return relic.has("current")),"STATUS relic progress and trigger availability projected without state changes")
 var item=g.add_fixture("eyes",4)
 t.check(find(g,"vision").active and find(g,"equipment_"+item.id).is_empty(),"STATUS equipment creates the actual body restriction without a second equipment description")
 var card=g.state.hand.filter(func(c):return c.type=="slip")[0]
 t.check(t.action(g,"card",{"uid":card.uid,"slot":"eyes","target":item.id,"free":false}).ok and not find(g,"vision").active,"STATUS formal removal immediately clears the restriction icon")
 g=Game.new(42,true,"trader_solo")
 var enemy=g.state.enemies[0]
 enemy.ready_layers=3
 t.check(find(g,"ready_"+enemy.id).owner==enemy.id and find(g,"ready_"+enemy.id).badge=="3","STATUS enemy readiness belongs to its own actor")
 enemy.gone=true
 t.check(find(g,"ready_"+enemy.id).is_empty(),"STATUS departing enemy clears its effect icon")
 g=Game.new(42,true,"drone_solo")
 enemy=g.state.enemies[0]
 t.check(find(g,"hard_"+enemy.id).active and g.get_view().enemies[0].intent_icons.all(func(icon):return icon.kind!="hard"),"STATUS mechanical protection appears once, separate from the next action")
 g=Game.new(42)
 g.state.powers=[{"uid":"projection_a","type":"mana_circuit","power_face":"free","power_mana_progress":5.0},{"uid":"projection_b","type":"mana_circuit","power_face":"free","power_mana_progress":20.0}]
 before=g.state.duplicate(true)
 var power=find(g,"power_mana_circuit_free")
 t.check(power.badge=="2" and power.value.contains("5／30") and power.value.contains("20／30") and g.state==before,"STATUS merged power icon retains two independent spending counters")
