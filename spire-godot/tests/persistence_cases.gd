extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const CoreGame=preload("res://core/game.gd")
const Store=preload("res://core/save_store.gd")
const Guard=preload("res://core/guard.gd")
const EventCases=preload("res://tests/event_cases.gd")
const ExitCases=preload("res://tests/demo_exit_cases.gd")

# docs/spec/save-fixed-points.md「证据入口」：进度固定点只由本次提交产生的迁移条目命名，生产侧的写盘规则只有
# 一条（`ui/main.gd` 的 `_submit`：`result.checkpoint` 非空才写盘）。测试侧用同一个 SaveStore 子类计数，
# 并按同一条规则驱动写盘；生产代码不带计数器，也不比较内容或读快照。
class WatchStore extends "res://core/save_store.gd":
 var writes=0
 func write_game(game, replace_incompatible: bool=false, map_drawings: Dictionary={}) -> Dictionary:
  writes+=1
  return super.write_game(game,replace_incompatible,map_drawings)

static func store_for(label: String) -> WatchStore:
 return WatchStore.new("res://build/save-fixed-point-"+label+"-"+str(Time.get_ticks_usec()))

static func text_at(path: String) -> String:
 if not FileAccess.file_exists(path): return ""
 var file=FileAccess.open(path,FileAccess.READ)
 if file==null: return ""
 var text=file.get_as_text();file.close()
 return text

static func modified(path: String) -> int:
 return FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else -1

static func stamp(store, slot: String) -> Dictionary:
 var main=store.path(slot);var backup=main+".bak"
 return {"main":text_at(main),"backup":text_at(backup),
  "main_time":modified(main),"backup_time":modified(backup)}

static func unchanged(t, before: Dictionary, after: Dictionary, label: String) -> void:
 t.check(after.main==before.main and after.main_time==before.main_time,"SAVE "+label+" leaves the primary file bytes and mtime untouched")
 t.check(after.backup==before.backup and after.backup_time==before.backup_time,"SAVE "+label+" leaves the backup file bytes and mtime untouched")

# 正例：真实公开命令（先取候选再 dispatch）；命中 checkpoint 时按 UI 的规则写盘。
# docs/spec/candidate-removal.md「失败语义」（批 R2，写盘时机部分）：拒绝的指令不命名 checkpoint，也不触发写盘。
static func g3_reject_never_writes(t) -> void:
 var g=Game.new(42)
 var store=store_for("g3-reject")
 var before=stamp(store,"main")
 var candidate=t.find_action(g,"end",{},true)
 var version=g.state.version
 var stale=g.dispatch(g.command(candidate.payload,version-1),version-1)
 t.check(not stale.ok and not stale.has("checkpoint"),"SAVE a stale command names no checkpoint")
 var forged=g.dispatch({"kind":"no_such_command","params":{},"expected_version":version},version)
 t.check(not forged.ok and not forged.has("checkpoint"),"SAVE a refused shape names no checkpoint")
 var bogus=g.dispatch({"kind":"end","params":{"uid":"probe"},"expected_version":version},version)
 t.check(not bogus.ok and not bogus.has("checkpoint"),"SAVE an illegal parameter names no checkpoint")
 unchanged(t,before,stamp(store,"main"),"a refused command")

static func submit(t, g, store, kind: String, extra: Dictionary={}) -> Dictionary:
 var candidate=t.find_action(g,kind,extra,true)
 if not candidate.valid:
  t.check(false,"SAVE the fixture command is available: "+kind)
  return {"ok":false,"error":"测试没有找到动作："+kind}
 return submit_candidate(t,g,store,candidate)

static func submit_candidate(t, g, store, candidate: Dictionary) -> Dictionary:
 var result=g.dispatch(g.command(candidate.payload,g.state.version),g.state.version)
 t.check(result.ok,"SAVE the committed command succeeds: "+str(result.get("error","")))
 if result.ok and String(result.get("checkpoint",""))!="":
  t.check(store.write_game(g).ok,"SAVE the named fixed point writes the scene start")
 return result

# 反例：同一条写盘规则在非固定点提交上必须一次都不触发。
static func submit_sample(t, g, store, label: String, kind: String, extra: Dictionary={}, writes_before: int=0) -> Dictionary:
 var candidate=t.find_action(g,kind,extra,true)
 if not candidate.valid:
  t.check(false,"SAVE the "+label+" fixture command is available")
  return {"ok":false,"error":"测试没有找到动作："+kind}
 return sample_candidate(t,g,store,candidate,label,writes_before)

static func sample_candidate(t, g, store, candidate: Dictionary, label: String, writes_before: int=0) -> Dictionary:
 var result=g.dispatch(g.command(candidate.payload,g.state.version),g.state.version)
 if result.ok and String(result.get("checkpoint",""))!="": store.write_game(g)
 t.check(result.ok,"SAVE the "+label+" sample commits: "+str(result.get("error","")))
 t.check(String(result.get("checkpoint",""))=="","SAVE the "+label+" sample names no checkpoint: "+str(result.get("checkpoint","")))
 t.check(store.writes==writes_before,"SAVE the "+label+" sample never calls the write entry")
 return result

# 战斗结束的夹具：只留一个 1 点生命的敌人，用真实攻击候选打出最后一击。
static func last_blow(t, g, store) -> Dictionary:
 var enemies=g.state.enemies
 if enemies.size()>1:
  for i in range(enemies.size()-1): enemies[i].gone=true;enemies[i].hp=0.0
 enemies[-1].hp=1.0
 var outcome={}
 for step in range(8):
  outcome=submit(t,g,store,"attack",{"type":"strike","enemy":g.state.enemies[-1].id})
  if not outcome.ok or String(g.state.phase)!="battle": break
 return outcome

# docs/spec/save-fixed-points.md「证据入口」：进入新的一层是固定点；写盘内容＝写入时刻的场景起点，
# 恢复点＝该层入口（房间与阶段与写入时一致）。
static func save_writes_on_new_floor(t) -> void:
 var store=store_for("floor")
 var g=CoreGame.new(42)
 t.check(String(submit(t,g,store,"departure",{"op":"skip"}).get("checkpoint",""))=="","SAVE the opening choice is not a fixed point")
 t.check(store.write_game(g).ok,"SAVE the floor fixture seeds a baseline file")
 var writes=store.writes
 var before=stamp(store,"tower")
 var source_floor=int(g.room_data(g.state.room).get("floor",0))
 var target=g.room_data(g.state.room).next[0]
 t.check(String(submit(t,g,store,"depart",{"room":target}).get("checkpoint",""))=="","SAVE starting a journey is not a fixed point")
 var arrival={}
 for step in range(12):
  if String(g.state.phase)!="travel": break
  arrival=submit(t,g,store,"travel_step")
 t.check(String(arrival.get("checkpoint",""))=="floor","SAVE arriving at a higher floor names the floor checkpoint: "+str(arrival.get("checkpoint","")))
 t.check(store.writes==writes+1,"SAVE the floor checkpoint writes exactly once")
 var after=stamp(store,"tower")
 t.check(after.main!=before.main and after.main_time>=before.main_time,"SAVE the floor checkpoint replaces the primary file with new bytes")
 t.check(after.backup==before.main,"SAVE the floor checkpoint moves the previous primary into the backup")
 var saved=store.read_slot("tower")
 t.check(saved.ok and not saved.backup,"SAVE the floor checkpoint reads the primary through the formal slot entry: "+str(saved.get("error","")))
 t.check(saved.snapshot==g.restart_snapshot(),"SAVE the floor checkpoint holds the scene start of the write moment")
 t.check(int(g.room_data(g.state.room).get("floor",0))>source_floor and saved.snapshot.room==g.state.room,"SAVE the floor checkpoint is the new floor entry room: "+str(saved.snapshot.room))
 var resumed=g.get_script().new(0,false,"equipment",false)
 t.check(resumed.restore_snapshot(saved.snapshot).ok,"SAVE the floor checkpoint resumes through the formal entry")
 t.check(resumed.state.room==g.state.room and resumed.state.phase==saved.snapshot.phase,"SAVE the resumed floor entry keeps its own room and phase")

# docs/spec/seed-identity.md「证据入口」：本局标识在开局写入一次，真实重建塔路后仍不变；
# 只读投影同步携带（`Game.new(42)`、真实 `demo_continue` 重建、真实投影）。
static func initial_seed_is_fixed_at_run_start(t) -> void:
 var store=store_for("seed-identity")
 var g=Game.new(42)
 t.check(g.state.initial_seed==42 and g.state.seed==42,"SAVE initial_seed is fixed at run start: the opening run takes the parameter seed")
 t.check(g.get_view().initial_seed==42 and g.get_view().tower_generation==0,"SAVE initial_seed is fixed at run start: the projection opens on the first tower")
 t.check(store.write_game(g).ok,"SAVE initial_seed is fixed at run start: the opening run writes its own file")
 preload("res://tests/demo_exit_cases.gd").exit_fixture(g)
 var outcome=submit(t,g,store,"demo_continue")
 t.check(outcome.ok and g.state.tower_generation==1,"SAVE initial_seed is fixed at run start: a real continuation rebuilds the tower exactly once: "+str(g.state.tower_generation))
 t.check(g.state.initial_seed==42 and g.state.seed!=g.state.initial_seed,"SAVE initial_seed is fixed at run start: the rebuilt tower moves the tower seed but not the identity")
 var rebuilt=g.get_view()
 t.check(rebuilt.initial_seed==g.state.initial_seed and rebuilt.tower_generation==g.state.tower_generation,"SAVE initial_seed is fixed at run start: the projection follows both keys after the rebuild")

# docs/spec/seed-identity.md「证据入口」：隔离目录 pack→unpack→正式恢复入口一路还原标识与塔路种子。
static func initial_seed_survives_round_trip(t) -> void:
 var store=store_for("seed-roundtrip")
 var g=Game.new(42)
 preload("res://tests/demo_exit_cases.gd").exit_fixture(g)
 submit(t,g,store,"demo_continue")
 t.check(g.state.initial_seed==42 and g.state.seed!=42,"SAVE initial_seed survives a round trip: the fixture rebuilt the tower before saving")
 t.check(store.write_game(g).ok,"SAVE initial_seed survives a round trip: the rebuilt run writes the primary file")
 var packed=store.read_slot("tower")
 var resumed=g.get_script().new(0,false,"equipment",false)
 t.check(packed.ok and resumed.restore_snapshot(packed.snapshot).ok,"SAVE initial_seed survives a round trip: the file loads through the formal entry: "+str(packed.get("error","")))
 t.check(resumed.state.initial_seed==g.state.initial_seed and resumed.state.initial_seed==42,"SAVE initial_seed survives a round trip: the identity comes back unchanged: "+str(resumed.state.initial_seed))
 t.check(resumed.state.seed==g.state.seed and resumed.state.tower_generation==g.state.tower_generation,"SAVE initial_seed survives a round trip: the current tower seed and iteration come back with it")

# docs/spec/seed-identity.md「证据入口」：缺 initial_seed 的旧档按当时的 seed 回填，且不改调用方字典。
static func legacy_save_without_initial_seed_backfills(t) -> void:
 var g=Game.new(42)
 preload("res://tests/demo_exit_cases.gd").exit_fixture(g)
 submit(t,g,store_for("seed-legacy"),"demo_continue")
 var legacy=g.export_snapshot()
 var tower_seed=int(legacy.seed)
 legacy.erase("initial_seed")
 var resumed=g.get_script().new(0,false,"equipment",false)
 var result=resumed.restore_snapshot(legacy)
 t.check(result.ok,"SAVE legacy save without initial_seed loads and backfills from seed: "+str(result.get("error","")))
 t.check(resumed.state.initial_seed==tower_seed and resumed.state.initial_seed==resumed.state.seed,"SAVE legacy save without initial_seed loads and backfills from seed: the identity equals the tower seed of the file: "+str(resumed.state.initial_seed))
 t.check(not legacy.has("initial_seed") and legacy.seed==tower_seed,"SAVE legacy save without initial_seed loads and backfills from seed: the caller dictionary stays untouched")
 t.check(Store.unpack(Store.pack(legacy)).ok,"SAVE legacy save without initial_seed loads and backfills from seed: the disk path accepts the same file")

# docs/spec/seed-identity.md「证据入口」：类型错误沿用 Snapshot.check 的通用逐字段校验与既有文案。
static func initial_seed_uses_the_shared_field_check(t) -> void:
 var g=Game.new(42)
 var clean=g.export_snapshot()
 var reference=clean.duplicate(true)
 reference.round="broken"
 var wording=String(g.restore_snapshot(reference).get("error",""))
 t.check(wording=="无法继续这份存档：基础数值类型有误。","SAVE initial_seed uses the shared field check: the reference wording comes from an existing integer field: "+wording)
 for broken in ["42",42.0]:
  var saved=clean.duplicate(true)
  saved.initial_seed=broken
  var result=g.restore_snapshot(saved)
  t.check(not result.ok and String(result.get("error",""))==wording,"SAVE initial_seed uses the shared field check: "+str(broken)+" is rejected with the same wording: "+str(result.get("error","")))
  t.check(g.export_snapshot()==clean and saved.initial_seed==broken,"SAVE initial_seed uses the shared field check: a rejected type changes neither the live state nor the caller dictionary")

# docs/spec/save-fixed-points.md「证据入口」：新增只读入口不写盘、不改状态，文本与 write_game 写出的主档逐字一致。
static func fixed_point_text_reads_the_written_bytes(t) -> void:
 var store=store_for("fixed-point-text")
 var g=Game.new(42)
 t.check(store.write_game(g).ok,"SAVE fixed_point_text reads the bytes write_game wrote: the fixture seeds a real file")
 var before=stamp(store,"tower")
 var state_before=g.export_snapshot();var rng_before=g.state.rng.duplicate(true)
 var read=store.fixed_point_text(g)
 t.check(read.ok and read.slot==g.state.save_slot and read.filename==g.state.save_slot+".json","SAVE fixed_point_text reads the bytes write_game wrote: the entry names the current slot and file: "+str(read))
 t.check(read.text==text_at(store.path("tower")),"SAVE fixed_point_text reads the bytes write_game wrote: the text equals the primary file byte for byte")
 var after=stamp(store,"tower")
 t.check(after.main==before.main and after.main_time==before.main_time and after.backup==before.backup and after.backup_time==before.backup_time,"SAVE fixed_point_text reads the bytes write_game wrote: the read creates no file and touches no mtime")
 t.check(g.export_snapshot()==state_before and g.state.rng==rng_before,"SAVE fixed_point_text reads the bytes write_game wrote: the read changes neither state nor randomness")

# docs/spec/save-fixed-points.md「证据入口」：三个 battle_end_* 各一次真提交都写盘，恢复点＝战斗结束后的阶段起点。
static func save_writes_when_battle_finishes(t) -> void:
 var store=store_for("battle-end")
 var g=Game.new(42)
 var outcome=last_blow(t,g,store)
 t.check(String(outcome.get("checkpoint",""))=="battle_end","SAVE a final blow names the battle end checkpoint: "+str(outcome.get("checkpoint","")))
 t.check(store.writes==1 and String(g.state.phase)=="reward","SAVE the victory writes once and enters the reward phase: "+String(g.state.phase))
 var saved=store.read_slot("tower")
 t.check(saved.ok and saved.snapshot==g.restart_snapshot() and saved.snapshot.phase=="reward","SAVE the victory recovery point is the reward scene start")
 var store_saturated=store_for("saturated")
 g=Game.new(42)
 g.state.enemies.clear()
 g._spawn_enemies("rope_solo")
 var enemy=g.state.enemies[0]
 var spec=g.EnemyPlans.application(g.Enemies.TYPES.rope.install_pool,2,3)
 for i in range(200):
  if not g.Application.execute(g,spec,enemy.id).ok: break
 for i in range(200):
  var targets=g.EnemyPlans.targets(g,enemy,"tighten")
  if targets.is_empty(): break
  g._enemy_operation(enemy,{"kind":"tighten","target":targets[0].id,"tier":3,"text":"加固"})
 var saturated=submit(t,g,store_saturated,"end")
 t.check(String(saturated.get("checkpoint",""))=="battle_end","SAVE saturation names the battle end checkpoint: "+str(saturated.get("checkpoint","")))
 t.check(store_saturated.writes==1 and String(g.state.phase)=="reward","SAVE the saturated end writes once and enters the reward phase: "+String(g.state.phase))
 t.check(store_saturated.read_slot("tower").snapshot==g.restart_snapshot(),"SAVE the saturated end recovery point is its own scene start")
 var store_captured=store_for("captured")
 g=Game.new(42)
 var captured=submit(t,g,store_captured,"surrender")
 t.check(String(captured.get("checkpoint",""))=="battle_end","SAVE surrender names the battle end checkpoint: "+str(captured.get("checkpoint","")))
 t.check(store_captured.writes==1 and String(g.state.phase)=="captured","SAVE the capture writes once and enters the captured phase: "+String(g.state.phase))
 t.check(store_captured.read_slot("tower").snapshot==g.restart_snapshot() and store_captured.read_slot("tower").snapshot.room=="prison","SAVE the capture recovery point is the capture scene start in prison")

# docs/spec/save-fixed-points.md「证据入口」：完成整备（含回合用尽与休息房用尽两条真实分支）写盘，
# 恢复点＝整备结束后的场景起点。
static func save_writes_when_prepare_finishes(t) -> void:
 var store=store_for("prepare-end")
 var g=Game.new(42)
 last_blow(t,g,store)
 var writes=store.writes
 t.check(String(submit(t,g,store,"reward",{"type":"skip"}).get("checkpoint",""))=="","SAVE entering preparation is not a fixed point")
 t.check(store.writes==writes,"SAVE entering preparation never writes")
 var finish=submit(t,g,store,"finish_prepare")
 t.check(String(finish.get("checkpoint",""))=="prepare_end","SAVE finishing preparation names the prepare end checkpoint: "+str(finish.get("checkpoint","")))
 t.check(store.writes==writes+1 and String(g.state.phase)!="prepare","SAVE finishing preparation writes once after leaving the phase: "+String(g.state.phase))
 t.check(store.read_slot("tower").snapshot==g.restart_snapshot() and store.read_slot("tower").snapshot.phase==String(g.state.phase),"SAVE the prepare end recovery point is the post-preparation scene start")
 var store_turn=store_for("prepare-turn")
 g=Game.new(42)
 last_blow(t,g,store_turn)
 submit(t,g,store_turn,"reward",{"type":"skip"})
 var turn_writes=store_turn.writes
 g.state.prepare_left=1
 var ended=submit(t,g,store_turn,"end")
 t.check(String(ended.get("checkpoint",""))=="prepare_end","SAVE the last preparation turn names the same checkpoint: "+str(ended.get("checkpoint","")))
 t.check(store_turn.writes==turn_writes+1 and store_turn.read_slot("tower").snapshot==g.restart_snapshot(),"SAVE the last preparation turn writes its own scene start")
 var store_rest=store_for("rest-end")
 g=CoreGame.new(42)
 g.state.room="rest"
 g._start_rest()
 t.check(String(submit(t,g,store_rest,"rest_flask").get("checkpoint",""))=="","SAVE choosing a rest reward is not a fixed point")
 submit(t,g,store_rest,"rest_begin")
 g.state.rest_left=1
 var last=submit(t,g,store_rest,"end")
 t.check(String(last.get("checkpoint",""))=="prepare_end","SAVE the last rest turn leaves preparation through the same declared checkpoint: "+str(last.get("checkpoint","")))
 t.check(store_rest.writes==1 and store_rest.read_slot("tower").snapshot==g.restart_snapshot(),"SAVE the last rest turn writes the scene start it leaves behind")

# docs/spec/save-fixed-points.md「证据入口」：抽样非固定点提交一律不写盘。
static func save_skips_representative_non_points(t) -> void:
 var store=store_for("non-points")
 var seed_game=Game.new(42)
 t.check(store.write_game(seed_game).ok,"SAVE the non-point fixture seeds a baseline file")
 t.action(seed_game,"end")
 t.check(store.write_game(seed_game).ok,"SAVE the non-point fixture seeds a backup file")
 store.writes=0
 var before=stamp(store,"tower")
 var g=Game.new(42)
 var cards=g.command_facts().filter(func(c):return c.valid and c.payload.kind=="card")
 t.check(not cards.is_empty(),"SAVE the battle card fixture has a legal card")
 if not cards.is_empty(): sample_candidate(t,g,store,cards[0],"N1 battle card play")
 g=Game.new(42)
 submit_sample(t,g,store,"N2 battle turn end","end")
 g=CoreGame.new(42,true,"prison_release")
 sample_candidate(t,g,store,t.find_action(g,"prison",{"action":"enter"},true),"N4 same-floor entry")
 g.state.equipment=[];g.state.composites=[];g.state.links=[]
 g.state.special_equipment=[];g.state.prison.baseline=[];g.state.prison.special_baseline=[]
 g.state.prison.served_turns=g.Prison.sentence_limit(g)-1
 submit_sample(t,g,store,"N4 same-floor release","end")
 g=CoreGame.new(42)
 g.state.room=g.state.rooms.filter(func(room):return room.kind=="shop")[0].id
 g.Services.start(g)
 var trade=g.command_facts().filter(func(c):return c.valid and c.group=="service")
 t.check(not trade.is_empty(),"SAVE the shop fixture has a legal transaction")
 if not trade.is_empty(): sample_candidate(t,g,store,trade[0],"N5 shop transaction")
 g=CoreGame.new(42)
 g.state.room=g.state.rooms.filter(func(room):return room.kind=="treasure")[0].id
 g.Services.start(g)
 var claim=g.command_facts().filter(func(c):return c.valid and c.group=="service")
 t.check(not claim.is_empty(),"SAVE the treasure fixture has a legal claim")
 if not claim.is_empty(): sample_candidate(t,g,store,claim[0],"N7 treasure claim")
 g=CoreGame.new(42)
 EventCases.arrive(g,"binding_cleric")
 submit_sample(t,g,store,"N6 event choice","event",{"action":"choose","choice":"leave_free"})
 g=Game.new(42,true,"guard")
 g.state.equipment=[];g.state.composites=[];g.state.links=[]
 g.state.special_equipment=[];g.state.prison.baseline=[];g.state.prison.special_baseline=[]
 Guard.capture(g,g.state.enemies[0])
 sample_candidate(t,g,store,t.find_action(g,"prison",{"action":"enter"},true),"N8 prison entry")
 submit_sample(t,g,store,"N8 prison cell turn","end")
 g.state.prison.left=1
 submit_sample(t,g,store,"N8 prison inspection","end")
 var patrol=g.command_facts().filter(func(c):return c.valid and c.payload.kind=="prison")
 t.check(not patrol.is_empty(),"SAVE the inspection fixture has a legal action")
 if not patrol.is_empty(): sample_candidate(t,g,store,patrol[0],"N8 prison inspection action")
 g=CoreGame.new(42)
 g.state.room="rest"
 g._start_rest()
 submit_sample(t,g,store,"N9 rest reward","rest_flask")
 submit_sample(t,g,store,"N9 begin remaining rest","rest_begin")
 g.state.rest_left=3
 submit_sample(t,g,store,"N9 rest turn","end")
 g=Game.new(42)
 ExitCases.exit_fixture(g)
 submit_sample(t,g,store,"N10 demo end","demo_end")
 g=Game.new(42)
 ExitCases.exit_fixture(g)
 submit_sample(t,g,store,"N12 tower restart","demo_continue")
 var after=stamp(store,"tower")
 unchanged(t,before,after,"the non-point sample set")
 var saved=store.read_slot("tower")
 var resumed=g.get_script().new(0,false,"equipment",false)
 t.check(resumed.restore_snapshot(saved.snapshot).ok,"SAVE reading a save in the sample never writes")
 t.check(store.writes==0,"SAVE a successful resume never calls the write entry")

# docs/spec/save-fixed-points.md「证据入口」：.bak 持有上一个固定点（A），场景内活动与破坏主档后回退到 A。
static func save_backup_holds_previous_fixed_point(t) -> void:
 var store=store_for("backup")
 var g=Game.new(42)
 last_blow(t,g,store)
 t.check(store.writes==1,"SAVE the backup fixture starts with its entrance battle end")
 submit(t,g,store,"reward",{"type":"skip"})
 t.check(String(submit(t,g,store,"finish_prepare").get("checkpoint",""))=="prepare_end","SAVE the backup fixture finishes preparation")
 var target=g.room_data(g.state.room).next[0]
 var source_floor=int(g.room_data(g.state.room).get("floor",0))
 submit(t,g,store,"depart",{"room":target})
 var arrival={}
 for step in range(12):
  if String(g.state.phase)!="travel": break
  arrival=submit(t,g,store,"travel_step")
 t.check(String(arrival.get("checkpoint",""))=="floor" and store.writes==3,"SAVE fixed point A is the floor entry")
 var point_a=store.read_slot("tower").snapshot
 t.check(int(g.room_data(g.state.room).get("floor",0))>source_floor and point_a.room==g.state.room,"SAVE fixed point A really is a higher floor entry")
 var mid_writes=store.writes
 for step in range(2):
  var posture={}
  for candidate in g.command_facts():
   if candidate.valid and String(candidate.payload.kind)=="posture" and String(candidate.payload.get("posture",""))!=String(g.state.posture):
    posture=candidate;break
  t.check(not posture.is_empty(),"SAVE the mid-scene fixture offers a real posture command")
  if posture.is_empty(): break
  sample_candidate(t,g,store,posture,"the mid-scene activity",mid_writes)
 var outcome=last_blow(t,g,store)
 t.check(String(outcome.get("checkpoint",""))=="battle_end" and store.writes==mid_writes+1,"SAVE fixed point B is the battle end")
 var point_b=store.read_slot("tower").snapshot
 t.check(point_b!=point_a and point_b.phase!=point_a.phase,"SAVE fixed point B is a later scene start than A")
 t.check(text_at(store.path("tower")+".bak")!=text_at(store.path("tower")),"SAVE fixed point B left the previous primary as its backup")
 submit(t,g,store,"reward",{"type":"skip"})
 var after_writes=store.writes
 var turn=g.command_facts().filter(func(c):return c.valid and c.payload.kind=="end")
 t.check(not turn.is_empty(),"SAVE the post-fixed-point phase offers a real turn command")
 if not turn.is_empty(): sample_candidate(t,g,store,turn[0],"the post-fixed-point activity",after_writes)
 t.check(store.writes==after_writes,"SAVE the activity after B never writes")
 var file=FileAccess.open(store.path("tower"),FileAccess.WRITE)
 file.store_string("broken");file.close()
 var recovered=store.read_slot("tower")
 t.check(recovered.ok and recovered.backup,"SAVE a damaged primary falls back to the backup: "+str(recovered.get("error","")))
 t.check(recovered.snapshot==point_a,"SAVE the fallback content is fixed point A rather than a copy of B")
 var resumed=g.get_script().new(0,false,"equipment",false)
 t.check(resumed.restore_snapshot(recovered.snapshot).ok,"SAVE the recovered fixed point A resumes through the formal entry")
 t.check(resumed.command_facts().any(func(c):return c.valid),"SAVE the recovered fixed point A offers a legal command")
 var next=resumed.command_facts().filter(func(c):return c.valid)[0]
 t.check(resumed.dispatch(resumed.command(next.payload,resumed.state.version),resumed.state.version).ok,"SAVE the recovered fixed point A continues through a real command")

# docs/spec/save-fixed-points.md「证据入口」：固定点写盘不得改变失败文案、格式校验、read_slot 回退与 summary 语义。
static func save_fixed_point_preserves_failure_and_format_contract(t) -> void:
 var store=store_for("failure")
 var g=Game.new(42)
 t.check(store.write_game(g).ok,"SAVE the failure fixture seeds a file")
 var envelope=JSON.parse_string(text_at(store.path("tower")))
 envelope.format=999
 var file=FileAccess.open(store.path("tower"),FileAccess.WRITE)
 file.store_string(JSON.stringify(envelope));file.close()
 var before=stamp(store,"tower")
 var refused=store.write_game(g)
 t.check(not refused.ok and refused.get("code","")=="version" and String(refused.get("error",""))=="保存已暂停：原存档需匹配版本读取，开始新局后将替换原档。","SAVE the fixed point write keeps the existing incompatible refusal wording: "+str(refused.get("error","")))
 var after=stamp(store,"tower")
 t.check(after.main==before.main and after.backup==before.backup,"SAVE the refused fixed point write keeps both files untouched")
 t.check(store.write_game(g,true).ok and store.read_slot("tower").ok,"SAVE the explicit new run still replaces an incompatible primary")
 var summary=store.summary("tower")
 t.check(summary.available and summary.text.contains(g.room_data(g.state.room).name) and not summary.text.contains("将恢复上次备份"),"SAVE the fixed point save keeps the existing summary semantics: "+str(summary))
 var unpacked=Store.unpack(text_at(store.path("tower")))
 t.check(unpacked.ok and unpacked.snapshot==store.read_slot("tower").snapshot,"SAVE the fixed point file round-trips through pack and unpack")
 var malformed=JSON.parse_string(text_at(store.path("tower")))
 malformed.payload+="x"
 file=FileAccess.open(store.path("tower"),FileAccess.WRITE)
 file.store_string(JSON.stringify(malformed));file.close()
 var broken=store.read_slot("tower")
 t.check(not broken.ok or broken.backup,"SAVE a checksum change never loads as a valid primary: "+str(broken.get("error","")))

static func same(a: Dictionary, b: Dictionary) -> bool:
 var aa=a.duplicate(true);var bb=b.duplicate(true)
 aa.erase("version");bb.erase("version")
 if aa!=bb:
  print("SAVE DIFF "+difference(aa,bb))
 return aa==bb

static func difference(a,b,where: String="state") -> String:
 if a is Dictionary and b is Dictionary:
  for key in a:
   if not b.has(key): return where+" missing "+str(key)
   if a[key]!=b[key]: return difference(a[key],b[key],where+"."+str(key))
  return where+" dictionary key/container types differ"
 if a is Array and b is Array:
  if a.size()!=b.size(): return where+" array size differs"
  for i in range(a.size()):
   if a[i]!=b[i]: return difference(a[i],b[i],where+"["+str(i)+"]")
  return where+" array container types differ"
 return where+": "+str(a)+" ("+str(typeof(a))+") vs "+str(b)+" ("+str(typeof(b))+")"

static func roundtrip(t, g, label: String):
 var before=g.export_snapshot()
 var packed=Store.pack(before)
 var result=Store.unpack(packed)
 t.check(result.ok,"SAVE readable "+label+": "+result.get("error",""))
 if not result.ok: return null
 var restored=g.get_script().new(0,false,"equipment",false)
 t.check(restored.restore_snapshot(result.snapshot).ok and same(before,restored.state),"SAVE exact restore "+label)
 t.check(g.state==before and restored.state.version>before.version,"SAVE readonly export and renewed version "+label)
 var old=restored.export_snapshot()
 restored.get_view();restored.command_facts()
 t.check(restored.state==old,"SAVE restored projection readonly "+label)
 return restored

static func step_both(t,g,h,kind: String,extra: Dictionary={}) -> void:
 if h==null: return
 var a=t.action(g,kind,extra);var b=t.action(h,kind,extra)
 t.check(a.ok and b.ok and same(g.state,h.state),"SAVE next formal action matches uninterrupted run %s; live=%s restored=%s" % [kind,a,b])

static func revision_boundary(t) -> void:
 var g=Game.new(42)
 var before=g.export_snapshot()
 var previous=before.duplicate(true);previous.save_revision=Game.Snapshot.REINFORCEMENT_STATE_REVISION
 var restored=g.restore_snapshot(previous)
 var packed=Store.unpack(Store.pack(previous))
 t.check(restored.ok and packed.ok and g.state.save_revision==Game.Snapshot.REVISION,"SAVE immediately previous reinforcement schema migrates through direct and disk restore")
 g=Game.new(42);before=g.export_snapshot()
 for revision in [null,Game.Snapshot.REINFORCEMENT_STATE_REVISION-1,Game.Snapshot.REVISION+1,"2"]:
  var saved=before.duplicate(true)
  if revision==null: saved.erase("save_revision")
  else: saved.save_revision=revision
  restored=g.restore_snapshot(saved)
  packed=Store.unpack(Store.pack(saved))
  t.check(not restored.ok and restored.get("code")=="version" and not packed.ok and packed.get("code")=="version","SAVE disk and direct restore reject unsupported revision without migration "+str(revision))
  t.check(g.export_snapshot()==before,"SAVE incompatible revision never partially restores "+str(revision))
 var prison=Game.new(42,true,"prison_test")
 var stable=prison.export_snapshot()
 for missing_pool in [true,false]:
  var invalid=stable.duplicate(true)
  if missing_pool: invalid.prison.erase("discovery_pool")
  else: invalid.prison.discovery_pool.append("return_seal");invalid.prison.discoveries.append("return_seal")
  t.check(not prison.restore_snapshot(invalid).ok and prison.export_snapshot()==stable,"SAVE obsolete discovery shapes rejected without filling defaults")

static func unlimited_file_size(t) -> void:
 var g=Game.new(42)
 g._emit("event","large-save fixture")
 var snapshot=g.export_snapshot()
 snapshot.logs[-1].text="x".repeat(8388609)
 t.check(g.restore_snapshot(snapshot).ok,"SAVE large valid log restores through normal state validation")
 var store=store_for("unlimited-size")
 var written=store.write_game(g)
 t.check(written.ok,"SAVE writes a valid file above the former 8 MiB limit: "+str(written.get("error","")))
 if not written.ok: return
 var file=FileAccess.open(store.path("tower"),FileAccess.READ)
 t.check(file.get_length()>8388608,"SAVE fixture file really exceeds the former byte limit")
 file.close()
 var loaded=store.read_slot("tower")
 t.check(loaded.ok and not loaded.backup and loaded.snapshot==g.restart_snapshot(),"SAVE large primary loads without truncation")
 var newer=Game.new(43)
 t.check(store.write_game(newer).ok,"SAVE replacing a large primary keeps normal backup flow")
 file=FileAccess.open(store.path("tower"),FileAccess.WRITE)
 file.store_string("broken");file.close()
 loaded=store.read_slot("tower")
 t.check(loaded.ok and loaded.backup and loaded.snapshot==g.restart_snapshot(),"SAVE large backup still recovers after primary corruption")
 var envelope=JSON.parse_string(text_at(store.path("tower")+".bak"))
 envelope.payload+="x"
 file=FileAccess.open(store.path("tower")+".bak",FileAccess.WRITE)
 file.store_string(JSON.stringify(envelope));file.close()
 t.check(not store.read_slot("tower").ok,"SAVE unlimited size does not bypass checksum validation")

static func map_drawings(t) -> void:
 var g=Game.new(42);var snapshot=g.export_snapshot()
 var marks={"tower":[PackedVector2Array([Vector2(-0.1,0.5),Vector2(0.9,1.05)])],"prison":[]}
 var packed=Store.pack(snapshot,marks);var decoded=Store.unpack(packed)
 t.check(decoded.ok and decoded.map_drawings==marks and decoded.snapshot==snapshot and g.state==snapshot,"SAVE annotations roundtrip separately from game state with exact graph coordinates")
 var envelope=JSON.parse_string(packed)
 envelope.map_drawings="{}"
 t.check(not Store.unpack(JSON.stringify(envelope)).ok,"SAVE checksum protects map annotations together with gameplay")
 envelope.map_drawings=JSON.stringify({"tower":[[["broken",0]]]})
 envelope.checksum=(envelope.payload+envelope.map_drawings).sha256_text()
 t.check(not Store.unpack(JSON.stringify(envelope)).ok,"SAVE malformed annotation coordinates reject before loading")
 envelope.erase("map_drawings");envelope.checksum=envelope.payload.sha256_text()
 decoded=Store.unpack(JSON.stringify(envelope))
 t.check(decoded.ok and decoded.map_drawings.is_empty() and decoded.snapshot==snapshot,"SAVE current-format file without annotations remains readable")

# A frozen option carries its own state condition into the save, so every kind must
# keep its exact key set and an unknown or extra-keyed condition must never load.
static func event_conditions(t) -> void:
 var events=preload("res://tests/event_cases.gd")
 var g=Game.new(42)
 g.state.relics.append("softened_buckle")
 events.arrive(g,"floating_belt_cluster")
 var index=-1
 for i in range(g.state.room_event.options.size()):
  if g.state.room_event.options[i].get("id","")=="leave": index=i
 t.check(index>=0 and g.state.room_event.options[index].availability.kind=="has_relic","SAVE held-relic option keeps its own condition")
 if index<0: return
 var restored=roundtrip(t,g,"event option condition")
 if restored!=null:
  t.check(restored.state.room_event.options.any(func(option):return option.get("availability",{}).get("type","")=="softened_buckle"),"SAVE held-relic condition survives the roundtrip")
 var before=g.export_snapshot()
 for broken in [
  {"kind":"unknown_condition","reason":"条件不成立。"},
  {"kind":"has_relic","reason":"条件不成立。"},
  {"kind":"has_relic","type":"softened_buckle","reason":"条件不成立。","extra":true},
  {"kind":"has_relic","type":"unregistered_relic","reason":"条件不成立。"},
  {"kind":"no_chastity_lock","type":"softened_buckle","reason":"条件不成立。"},
 ]:
  var saved=before.duplicate(true)
  saved.room_event.options[index].availability=broken.duplicate(true)
  t.check(not g.restore_snapshot(saved).ok and g.export_snapshot()==before,"SAVE malformed option condition rejected atomically "+JSON.stringify(broken))

# docs/spec/event-pipeline.md「依赖规范」: the pipeline writes only the declared
# new keys, so the twelve shipped events carry neither conditions nor chain — while a real
# cross-event jump adds exactly chain and the save accepts only its declared shape.
static func event_pipeline_writes_only_declared_keys(t) -> void:
 var events=preload("res://tests/event_cases.gd")
 var flow=preload("res://tests/event_flow_cases.gd")
 var catalog=preload("res://core/content_catalog.gd")
 var g=Game.new(42)
 for id in g.Events.Data.TYPES.keys():
  var walk=Game.new(42)
  events.arrive(walk,id)
  for option in walk.state.room_event.options:
   t.check(not option.has("conditions") and not option.has("chain"),"SAVE shipped option carries no canonical key yet: "+id+"/"+str(option.get("id","")))
  var saved=walk.export_snapshot()
  t.check(not saved.room_event.has("chain"),"SAVE shipped event state carries no chain key: "+id)
  var resumed=Game.new(42)
  t.check(resumed.restore_snapshot(saved).ok,"SAVE shipped event state round-trips: "+id)
  t.check(not resumed.state.room_event.has("chain"),"SAVE restore introduces no undeclared key: "+id)
 # Chain half: the same check against a real jump, where chain is the only new key.
 var baseline=catalog.tables(g)
 var compiled=catalog.compile(g,flow.chain_documents())
 t.check(compiled.ok,"SAVE chain fixtures compile: "+str(compiled.errors))
 if not compiled.ok: return
 catalog.commit(g,compiled.tables)
 var chain=Game.new(42)
 events.arrive(chain,"chain_source_fixture")
 var arrival=chain.export_snapshot()
 t.check(not arrival.room_event.has("chain"),"SAVE an arrival instance carries no chain key")
 var declared=arrival.room_event.keys().map(func(key):return str(key))
 t.check(t.action(chain,"event",{"action":"choose","choice":"depart"}).ok,"SAVE the chain jump commits")
 var jumped=chain.export_snapshot()
 var added=jumped.room_event.keys().map(func(key):return str(key)).filter(func(key):return key not in declared)
 t.check(added==["chain"] and jumped.room_event.chain==["chain_source_fixture"],"SAVE a real jump adds exactly the declared chain key: "+str(added))
 var restored=roundtrip(t,chain,"event chain instance")
 if restored!=null:
  t.check(restored.state.room_event.chain==["chain_source_fixture"] and restored.state.room_event.id=="chain_target_fixture","SAVE the chain instance keeps its chain and current event")
 for broken in [[], "chain_source_fixture", ["no_such_event"], ["chain_source_fixture","chain_source_fixture"], ["chain_source_fixture",42]]:
  var saved=jumped.duplicate(true)
  saved.room_event.chain=broken
  t.check(not chain.restore_snapshot(saved).ok and chain.export_snapshot()==jumped,"SAVE malformed chain rejected atomically: "+JSON.stringify(broken))
 catalog.commit(g,baseline)

# docs/spec/event-pipeline.md「证据入口」: every shipped event's frozen options and
# its room_event survive a real SaveStore pack/unpack plus the formal restore entry byte for
# byte (eight single-node and four multi-node instances). `next` is written only for options
# frozen through the staged layout (the node's frozen_form, or any
# option carrying a selector), and all six malformed `next` shapes reject the whole save with
# the existing wording while the live state stays untouched.
static func event_frozen_options_roundtrip(t) -> void:
 var events=preload("res://tests/event_cases.gd")
 var data=preload("res://data/room_events.gd")
 var single=0
 var staged=0
 var ids=data.TYPES.keys()
 ids.sort()
 for id in ids:
  var g=Game.new(42)
  events.arrive(g,id)
  var definition=g.Events.definition(id)
  if g.Events.node_ids(definition).size()==1: single+=1
  else: staged+=1
  var node=g.Events.node(definition,definition.start_node)
  for option in g.state.room_event.options:
   var source=node.choices.filter(func(choice):return str(choice.get("id",""))==str(option.get("source_choice",option.get("id",""))))
   var staged_layout=str(node.get("frozen_form",""))!="in_place" or (not source.is_empty() and source[0].has("selector"))
   t.check(option.has("next")==staged_layout,"SAVE the frozen layout writes next only for a staged option: "+id+"/"+str(option.get("id","")))
  var options=JSON.stringify(g.state.room_event.options)
  var room_event=JSON.stringify(g.state.room_event)
  var decoded=Store.unpack(Store.pack(g.export_snapshot()))
  t.check(decoded.ok,"SAVE the shipped frozen event unpacks: "+id+": "+str(decoded.get("error","")))
  if not decoded.ok: continue
  var restored=Game.new(0,false,"equipment",false)
  var loaded=restored.restore_snapshot(decoded.snapshot)
  t.check(loaded.ok,"SAVE the shipped frozen event restores through the formal entry: "+id+": "+str(loaded.get("error","")))
  if not loaded.ok: continue
  t.check(JSON.stringify(restored.state.room_event.options)==options and JSON.stringify(restored.state.room_event)==room_event,"SAVE frozen options and room_event stay byte-identical: "+id)
  if JSON.stringify(restored.state.room_event)!=room_event: same(restored.state.room_event,g.state.room_event)
  t.check(restored.validate()=="","SAVE the restored frozen event stays valid: "+id+": "+restored.validate())
 t.check(single==8 and staged==4,"SAVE the shipped sample covers eight single-node and four multi-node events: "+str(single)+"/"+str(staged))
 # A single-node in_place event still freezes its selector options through the shared staged
 # builder, so those instances carry `next` while their plain siblings do not.
 for id in ["alchemist_tasting_stall","enchanters_empty_studio"]:
  var g=Game.new(42)
  for slot in ["thigh","ankle"]: g.add_fixture(slot,6)
  events.arrive(g,id)
  var instances=g.state.room_event.options.filter(func(option):return str(option.get("id","")).contains("__"))
  t.check(not instances.is_empty() and instances.all(func(option):return option.has("next") and option.has("source_choice")),"SAVE a single-node selector instance freezes through the staged layout: "+id)
  t.check(g.state.room_event.options.filter(func(option):return not str(option.get("id","")).contains("__")).all(func(option):return not option.has("next")),"SAVE the plain options of the same in_place instance carry no next: "+id)
  var options=JSON.stringify(g.state.room_event.options)
  var decoded=Store.unpack(Store.pack(g.export_snapshot()))
  var restored=Game.new(0,false,"equipment",false)
  t.check(decoded.ok and restored.restore_snapshot(decoded.snapshot).ok and JSON.stringify(restored.state.room_event.options)==options,"SAVE the expanded selector instance round-trips byte-identically: "+id)
 # The corruption happens on the snapshot copy, never on the live instance (A27).
 var staged_game=Game.new(42)
 events.arrive(staged_game,"binding_cleric")
 var before=staged_game.export_snapshot()
 var index=-1
 for i in range(staged_game.state.room_event.options.size()):
  if staged_game.state.room_event.options[i].has("next"): index=i;break
 t.check(index>=0,"SAVE the staged sample carries a next key to corrupt")
 if index>=0:
  var cases=[
   ["missing key",null],
   ["non string or dictionary",42],
   ["unknown node","no_such_node"],
   ["unregistered event",{"event":"no_such_event","node":"entry"}],
   ["self reference",{"event":"binding_cleric","node":"service"}],
   ["unknown target node",{"event":"floating_belt_cluster","node":"no_such_node"}],
  ]
  for case in cases:
   var saved=before.duplicate(true)
   if case[1]==null: saved.room_event.options[index].erase("next")
   else: saved.room_event.options[index].next=case[1]
   var result=staged_game.restore_snapshot(saved)
   t.check(not result.ok and str(result.get("error",""))=="无法继续这份存档：多阶段事件冻结选项损坏。" and staged_game.export_snapshot()==before,"SAVE a malformed next rejects the whole save with its existing wording and no partial load: "+case[0])

# Scenario 10 (the trace never reaches the state or the save) is not landed: its trace
# assertions failed. Reported for the coordinator.

static func event_trace_never_reaches_state_or_save(t) -> void:
 var events=preload("res://tests/event_cases.gd")
 var off=Game.new(42)
 events.arrive(off,"floating_belt_cluster")
 var off_snapshot=JSON.stringify(off.export_snapshot())
 var off_view=JSON.stringify(off.get_view())
 var off_facts=JSON.stringify(off.command_facts())
 var off_rng=JSON.stringify(off.state.rng)
 var on=Game.new(42)
 on.set_meta("event_trace_enabled",true)
 events.arrive(on,"floating_belt_cluster")
 on.command_facts()
 t.check(not on.Events.event_trace(on).is_empty(),"SAVE trace records rows while the switch is on")
 t.check(JSON.stringify(on.export_snapshot())==off_snapshot,"SAVE the switch does not change the snapshot")
 t.check(JSON.stringify(on.get_view())==off_view and JSON.stringify(on.state.rng)==off_rng,"SAVE the switch does not change the view or the random domains")
 on.state.version=off.state.version
 t.check(JSON.stringify(on.command_facts())==off_facts,"SAVE the switch does not change the candidate set")
 var saved=on.export_snapshot()
 var resumed=Game.new(42)
 t.check(resumed.restore_snapshot(saved).ok and not resumed.state.room_event.has("event_trace") and not resumed.state.has("event_trace"),"SAVE the restored state carries no trace key")
 t.check(not JSON.stringify(saved).contains("event_trace_enabled") and not JSON.stringify(saved).contains("availability_unmet"),"SAVE the save payload carries neither the switch nor a trace row")

# docs/spec/event-pipeline.md「证据入口」: the trace never reaches the state,
# the save or the view, and the switch does not change any digest.
# docs/spec/transition-pipeline.md「证据入口」：迁移日志只在进程内——不进 state、不进 View、不进存档。
static func transition_log_never_reaches_state_or_view(t) -> void:
 var arch=preload("res://tests/architecture_cases.gd")
 var g=Game.new(42)
 g._finish_battle()
 t.check(not arch.transition_log(g).is_empty(),"SAVE the transition log exists in process: "+str(arch.transition_log(g)))
 t.check(not g.state.keys().any(func(key):return String(key).contains("transition")),"SAVE state carries no transition key: "+str(g.state.keys().filter(func(key):return String(key).contains("transition"))))
 var saved=g.export_snapshot()
 var packed=String(Store.pack(saved))
 t.check(not JSON.stringify(saved).contains("battle_end_") and not JSON.stringify(saved).contains("_transition_log"),"SAVE the exported snapshot carries no transition log")
 t.check(not packed.contains("battle_end_") and not packed.contains("demo_continue"),"SAVE the packed save file carries no transition log")
 t.check(not JSON.stringify(g.get_view()).contains("battle_end_") and not JSON.stringify(g.get_view()).contains("transition_log"),"SAVE the projected view carries no transition log")
 var resumed=Game.new(7)
 var restart_log=arch.transition_log(resumed)
 t.check(resumed.restore_snapshot(saved).ok,"SAVE a fresh run accepts the captured save")
 t.check(arch.transition_delta(resumed,restart_log).is_empty() and not JSON.stringify(resumed.export_snapshot()).contains("battle_end_"),"SAVE restoring a save logs no transition and carries no log")
# docs/spec/candidate-removal.md「接口」显示消费（批 R5）：纯显示读取不触存档与随机域。显示事实读取路径
# （get_view／command_facts／display_facts／route_view）与一次成功／一次失败提交之后：全量读取前后
# export_snapshot() 相等、随机域计数不变、core/snapshot.gd::REVISION 不变、快照仍通过共享字段校验；
# 固定点写盘时机不变（仍只由提交结果的 checkpoint 非空触发）。
static func save_and_random_untouched(t) -> void:
 var g=Game.new(42)
 g.get_view()
 var before=g.export_snapshot()
 var rng_before=JSON.stringify(g.state.rng)
 var revision=Game.Snapshot.REVISION
 for i in range(3):
  g._fact_source()
  g.command_facts()
  g.get_view()
  g.route_view()
 t.check(g.export_snapshot()==before,"G9 save_and_random_untouched: pure display reads leave the export snapshot byte-equal")
 t.check(JSON.stringify(g.state.rng)==rng_before,"G9 save_and_random_untouched: pure display reads advance no random domain")
 t.check(g.state.save_revision==revision,"G9 save_and_random_untouched: the save revision is unchanged")
 t.check(Game.Snapshot.check(g.export_snapshot(),g)=="" and g.export_snapshot()==before,"G9 save_and_random_untouched: the snapshot still passes the shared field and shape check with no new save field")
 var store=store_for("g9")
 var writes_before=store.writes
 var usable=g.command_facts().filter(func(c):return c.valid)
 t.check(not usable.is_empty(),"G9 save_and_random_untouched: the fixture exposes a usable command")
 if usable.is_empty(): return
 var ok_result=g.dispatch(g.command(usable[0].payload,g.state.version),g.state.version)
 if ok_result.ok and String(ok_result.get("checkpoint",""))!="": store.write_game(g)
 t.check(ok_result.ok and store.writes==writes_before+(1 if String(ok_result.get("checkpoint",""))!="" else 0),"G9 save_and_random_untouched: the save write still follows the checkpoint rule: writes="+str(store.writes)+" checkpoint="+str(ok_result.get("checkpoint","")))
 var refused_before=store.writes
 var blocked=g.command_facts().filter(func(c):return not c.valid and c.reason!="")
 if not blocked.is_empty():
  var refused=g.dispatch(g.command(blocked[0].payload,g.state.version),g.state.version)
  t.check(not refused.ok and store.writes==refused_before,"G9 save_and_random_untouched: a refused command writes nothing")

# ==== 塔路历史（docs/spec/save-fixed-points.md「加性字段与只读入口」）====
# 判据只观察正式输入（find_action／action／dispatch）、state.route_history、export_snapshot 与
# restore_snapshot 的结果，不直接调用 core/route_history.gd；真实塔路用 CoreGame，夹具塔路只用于
# 需要构造场景的分支。
const ROUTE_KEYS=["boss","cycle","enter","floor","generation","nodes","region","security","seed"]
const ROUTE_START="start"
const ROUTE_RELEASE="release"
const ROUTE_ESCAPE="escape"
const ROUTE_GATE_EXIT="gate_exit"
const ROUTE_CYCLE="cycle"
const ROUTE_UNKNOWN="unknown"

static func route_history_of(g) -> Array:
 var history=g.state.get("route_history",[])
 return history if history is Array else []

static func route_record(g, index: int) -> Dictionary:
 var history=route_history_of(g)
 return history[index] if index>=0 and index<history.size() else {}

static func route_last(g) -> Dictionary:
 return route_record(g,route_history_of(g).size()-1)

# 塔路移动只有 travel_step 一个真实指令；夹具不另造路径。
static func route_travel(t, g) -> void:
 var guard=0
 while g.state.phase=="travel" and guard<20:
  guard+=1
  if not t.action(g,"travel_step").ok: break

static func route_keys_sorted(record: Dictionary) -> Array:
 var keys=record.keys().map(func(key):return String(key))
 keys.sort()
 return keys

# 只缩短生命，攻击、支付、奖励与整备全部走正式候选与提交。
static func route_win_battle(t, g) -> void:
 for enemy in g.state.enemies: enemy.hp=1.0
 var guard=0
 while g.state.phase=="battle" and guard<80:
  guard+=1
  var attack=preload("res://tests/route_driver.gd").attack(g)
  if attack.is_empty():
   if not t.action(g,"end").ok: break
  else:
   var result=g.dispatch(g.command(attack.payload,g.state.version),g.state.version)
   if not result.ok:
    t.check(false,"ROUTEHIST battle attack commits: "+String(result.get("error","")))
    break
 guard=0
 while g.state.phase=="reward" and guard<10:
  guard+=1
  var skip=t.find_action(g,"reward",{"type":"skip"},true)
  if not skip.valid: break
  t.check(t.action(g,"reward",{"type":"skip"}).ok,"ROUTEHIST a reward leaves through the real continue")
 guard=0
 while g.state.phase=="pack" and guard<10:
  guard+=1
  var pack=preload("res://tests/route_driver.gd").packing_action(g)
  if pack.is_empty(): break
  g.dispatch(g.command(pack.payload,g.state.version),g.state.version)
 guard=0
 while g.state.phase=="prepare" and guard<10:
  guard+=1
  var finish=t.find_action(g,"finish_prepare",{},true)
  if not finish.valid: break
  t.check(t.action(g,"finish_prepare").ok,"ROUTEHIST preparation ends through the real command")

static func route_new_run(t):
 var g=CoreGame.new(42)
 t.check(g.state.phase=="departure" and route_history_of(g).size()==1,"ROUTEHIST-1 a real new run opens one record before the first floor")
 t.check(t.action(g,"departure",{"op":"skip"}).ok,"ROUTEHIST-1 the real departure command starts the run")
 var rooms=g.state.rooms.filter(func(room):return int(room.get("floor",-2))==0 and room.next.any(func(target):return String(g.room_data(target).get("pool",""))=="ordinary"))
 t.check(not rooms.is_empty(),"ROUTEHIST-1 the generated tower has a first floor with an ordinary battle neighbour")
 if rooms.is_empty(): return g
 t.check(t.action(g,"depart",{"room":rooms[0].id}).ok,"ROUTEHIST-1 the first-floor departure is a real command")
 route_travel(t,g)
 t.check(g.state.phase=="battle","ROUTEHIST-1 arrival starts the first-floor battle")
 return g

static func route_capture(t, g) -> void:
 t.check(t.action(g,"surrender").ok,"ROUTEHIST the real surrender captures instead of bypassing the battle")
 t.check(g.state.phase=="captured","ROUTEHIST capture reaches the captured phase")
 t.check(t.action(g,"prison",{"action":"enter"}).ok,"ROUTEHIST the real intake enters the cell")

static func route_history_start_record(t) -> void:
 var g=route_new_run(t)
 var record=route_record(g,0)
 t.check(route_keys_sorted(record)==ROUTE_KEYS,"ROUTEHIST-1 the start record has exactly the declared keys")
 t.check(String(record.get("enter",""))==ROUTE_START and int(record.get("cycle",-1))==0 and int(record.get("generation",-1))==0,"ROUTEHIST-1 the start record says start, cycle zero and generation zero")
 t.check(String(record.get("region",""))=="tower" and int(record.get("seed",0))==42 and String(record.get("boss",""))==String(g.state.room_encounters.get("summit","")),"ROUTEHIST-1 the start record keeps region, seed and the summit encounter")
 t.check(int(record.get("security",-1))==0 and int(record.get("nodes",0))==-1 and int(record.get("floor",0))==-1,"ROUTEHIST-1 security starts at zero and nodes/floor wait for the first close")
 var stable=g.export_snapshot()
 g.get_view();g.route_view();g.command_facts()
 t.check(g.export_snapshot()==stable and route_history_of(g).size()==1,"ROUTEHIST-1 pure display reads neither append nor rewrite a record")

static func route_history_practice_isolated(t) -> void:
 for kind in ["equipment","guard"]:
  var g=CoreGame.new(42,true,kind)
  t.check(g.state.has("route_history"),"ROUTEHIST-2 practice "+kind+" carries the declared field with no record")
  t.check(route_history_of(g).is_empty(),"ROUTEHIST-2 practice "+kind+" starts no tower-route record")
  for i in range(3): t.action(g,"end")
  t.check(route_history_of(g).is_empty(),"ROUTEHIST-2 practice "+kind+" turns stay outside the tower history")

static func route_history_release_closes_route(t) -> void:
 var g=route_new_run(t)
 route_win_battle(t,g)
 t.check(g.state.phase=="map" and g.state.completed_rooms.size()==1,"ROUTEHIST-3 one real room is completed before capture")
 var rooms=g.route_view().filter(func(room):return String(room.get("status",""))=="available" and String(room.get("icon","")) in ["battle","boss"])
 t.check(not rooms.is_empty(),"ROUTEHIST-3 the completed room exposes a battle room")
 if rooms.is_empty(): return
 t.check(t.action(g,"depart",{"room":rooms[0].id}).ok,"ROUTEHIST-3 the next battle room departs for real")
 route_travel(t,g)
 route_capture(t,g)
 var k=g.state.completed_rooms.size()
 var expected_floor=0
 for id in g.state.completed_rooms:
  var room=g.room_data(String(id))
  if not room.is_empty(): expected_floor=maxi(expected_floor,int(room.floor)+1)
 t.check(k==1 and expected_floor==1,"ROUTEHIST-3 expected nodes and floor come from the closed route itself")
 g.state.prison.key=true
 g.state.prison.served_turns=g.Prison.sentence_limit(g)-1
 t.check(t.action(g,"end").ok,"ROUTEHIST-3 the sentence ends on a real completed turn")
 var history=route_history_of(g)
 t.check(history.size()==2,"ROUTEHIST-3 release appends exactly one route record")
 var opened=route_record(g,1);var closed=route_record(g,0)
 t.check(String(opened.get("enter",""))==ROUTE_RELEASE and int(opened.get("generation",-1))==1,"ROUTEHIST-3 release opens the next generation")
 t.check(String(opened.get("region",""))=="tower" and int(opened.get("cycle",-1))==0 and String(opened.get("boss",""))==String(closed.get("boss","")),"ROUTEHIST-3 release keeps region, cycle and summit")
 t.check(int(closed.get("nodes",-1))==k and int(closed.get("floor",-1))==expected_floor,"ROUTEHIST-3 the closed record carries the completed node count and reached floor")
 t.check(int(closed.get("cycle",-1))==0 and String(closed.get("enter",""))==ROUTE_START,"ROUTEHIST-3 the start record stays closed in place")

static func route_history_escape_keeps_generation(t) -> void:
 var g=route_new_run(t)
 route_capture(t,g)
 var generation=int(route_record(g,0).get("generation",-1))
 var security=g.state.security
 preload("res://tests/prison_cases.gd").exit_to_route(t,g)
 var history=route_history_of(g)
 t.check(history.size()==2,"ROUTEHIST-4 an escape appends exactly one record")
 var escape=route_record(g,1)
 t.check(String(escape.get("enter",""))==ROUTE_ESCAPE and String(escape.get("region",""))=="prison","ROUTEHIST-4 the escape record says escape and prison")
 t.check(int(escape.get("generation",-2))==generation and String(escape.get("boss",""))=="" and int(escape.get("security",-1))==security,"ROUTEHIST-4 the escape keeps generation, clears the summit and carries security")
 t.check(int(route_record(g,0).get("nodes",-1))==0 and int(route_record(g,0).get("floor",-1))==0,"ROUTEHIST-4 the closed tower record keeps the zero-room backfill")
 for route in ["vent","seal"]:
  var h=preload("res://tests/prison_cases.gd").intake(t)
  preload("res://tests/prison_cases.gd").clear_fixture(h)
  if route=="vent":
   preload("res://tests/exploration_fixture.gd").mark_found(h,"vent")
   h.state.prison.vent_hits=h.B.PRISON_VENT_HITS
   preload("res://tests/exploration_fixture.gd").at_site(h,"vent")
   t.check(t.action(h,"prison",{"action":"vent_exit"}).ok,"ROUTEHIST-4 the vent exit is a real escape")
  else:
   t.check(t.action(h,"relic_discharge",{"relic":"return_seal"}).ok,"ROUTEHIST-4 the return seal is a real escape")
  var record=route_last(h)
  t.check(route_history_of(h).size()==1 and String(record.get("enter",""))==ROUTE_ESCAPE and String(record.get("region",""))=="prison","ROUTEHIST-4 alternative escape "+route+" writes one escape record")
  t.check(String(record.get("boss",""))=="" and int(record.get("generation",-2))==0 and int(record.get("security",-1))==h.state.security,"ROUTEHIST-4 alternative escape "+route+" keeps generation, summit and security")

# 越狱后走到出口守卫战，再用正式奖励与整备回到新塔；-5 与 -8 共用这条真实序列。
static func route_escape_and_gate(t):
 var g=route_new_run(t)
 route_capture(t,g)
 preload("res://tests/prison_cases.gd").exit_to_route(t,g)
 preload("res://tests/prison_cases.gd").travel_route(t,g,"prison_rest")
 t.check(t.action(g,"rest_begin").ok and g.state.phase=="rest","ROUTEHIST-5 the prison rest room starts for real")
 t.check(t.action(g,"finish_rest").ok,"ROUTEHIST-5 rest ends for real")
 preload("res://tests/prison_cases.gd").travel_route(t,g,"prison_gate")
 t.check(g.state.phase=="battle","ROUTEHIST-5 the exit gate starts the guard battle")
 route_win_battle(t,g)
 return g

static func route_history_gate_exit_appends(t) -> void:
 var g=route_escape_and_gate(t)
 t.check(g.state.phase=="map" and g.state.room=="tower_bottom" and g.state.map_region=="tower","ROUTEHIST-5 the gate reward returns to a new tower")
 var history=route_history_of(g)
 t.check(history.size()==3,"ROUTEHIST-5 the gate return appends exactly one record")
 var opened=route_record(g,2);var closed=route_record(g,1)
 t.check(String(opened.get("enter",""))==ROUTE_GATE_EXIT and String(opened.get("region",""))=="tower","ROUTEHIST-5 the return reason is gate_exit")
 t.check(int(opened.get("generation",-1))==int(closed.get("generation",-2))+1 and int(opened.get("cycle",-1))==0,"ROUTEHIST-5 the gate return advances one generation without changing cycle")
 t.check(int(closed.get("nodes",-1))>0 and int(closed.get("floor",-1))>0,"ROUTEHIST-5 the closed escape route records completed prison nodes and floor")
 t.check(int(opened.get("security",-1))==int(closed.get("security",-2)),"ROUTEHIST-5 cumulative security survives the return")

# 换塔后塔底入口的下一层是第 0 层，data/tower.gd::generate 把第 0 层固定为战斗房；只发真实 depart／travel_step。
static func route_depart_first_battle(t, g) -> bool:
 var targets=[]
 for id in g.room_data(g.state.room).get("next",[]):
  var room=g.room_data(String(id))
  if int(room.get("floor",-2))==0 and String(room.get("kind",""))=="battle": targets.append(String(id))
 t.check(not targets.is_empty(),"ROUTEHIST the new tower exposes a first-floor battle")
 if targets.is_empty(): return false
 if not t.action(g,"depart",{"room":targets[0]}).ok: return false
 route_travel(t,g)
 return g.state.phase=="battle"

# 越狱路线走到出口守卫战并以投降再次被收押：只经真实指令推进，不碰 core/route_history.gd。
static func route_escape_to_gate_capture(t):
 var g=route_new_run(t)
 route_capture(t,g)
 preload("res://tests/prison_cases.gd").exit_to_route(t,g)
 preload("res://tests/prison_cases.gd").travel_route(t,g,"prison_rest")
 t.check(t.action(g,"rest_begin").ok and g.state.phase=="rest","ROUTEHIST the prison rest room starts for real")
 t.check(t.action(g,"finish_rest").ok,"ROUTEHIST the prison rest room ends for real")
 preload("res://tests/prison_cases.gd").travel_route(t,g,"prison_gate")
 t.check(g.state.phase=="battle" and g.state.map_region=="prison","ROUTEHIST the exit gate starts the guard battle inside the prison region")
 route_capture(t,g)
 t.check(g.state.map_region=="prison","ROUTEHIST the second capture keeps the prison region, the old gate_exit guess")
 return g

# 越狱路线在出口守卫战再次被收押后服满刑期，进入原因仍是 release。
# 判别信号取挂载点当时的状态（state.prison 仍非空），不按上一条记录的 region。
static func route_history_second_capture_release(t) -> void:
 var g=route_escape_to_gate_capture(t)
 var history=route_history_of(g)
 t.check(history.size()==2,"ROUTEHIST route_history_second_capture_release: the escape route holds two records before serving")
 var escape=route_record(g,1)
 t.check(String(escape.get("enter",""))==ROUTE_ESCAPE and String(escape.get("region",""))=="prison","ROUTEHIST route_history_second_capture_release: the second capture opens no tower record")
 t.check(not g.state.prison.is_empty() and bool(g.state.prison.get("active",false)),"ROUTEHIST route_history_second_capture_release: the mount point still sees the active cell")
 g.state.prison.key=true
 g.state.prison.served_turns=g.Prison.sentence_limit(g)-1
 t.check(t.action(g,"end").ok,"ROUTEHIST route_history_second_capture_release: the sentence ends on a real completed turn")
 history=route_history_of(g)
 t.check(history.size()==3,"ROUTEHIST route_history_second_capture_release: the release appends exactly one record")
 var opened=route_record(g,2)
 t.check(String(opened.get("enter",""))==ROUTE_RELEASE,"ROUTEHIST route_history_second_capture_release: a sentence release after a second capture opens release, not gate_exit: "+String(opened.get("enter","")))
 t.check(int(opened.get("generation",-1))==int(escape.get("generation",-2))+1 and String(opened.get("region",""))=="tower" and int(opened.get("cycle",-1))==0,"ROUTEHIST route_history_second_capture_release: the release opens the next generation on the tower without changing cycle")
 t.check(String(opened.get("boss",""))==String(route_record(g,0).get("boss","")),"ROUTEHIST route_history_second_capture_release: the same cycle keeps the previous summit")
 t.check(int(opened.get("nodes",0))==-1 and int(opened.get("floor",0))==-1,"ROUTEHIST route_history_second_capture_release: the new record stays open")

# cycle 之后在新一代塔路内被捕并服刑，进入原因也是 release。
static func route_history_cycle_capture_release(t) -> void:
 var g=route_new_run(t)
 route_win_battle(t,g)
 preload("res://tests/demo_exit_cases.gd").exit_fixture(g)
 t.check(t.action(g,"demo_continue").ok,"ROUTEHIST route_history_cycle_capture_release: the real continue opens the next cycle")
 var cycle=route_record(g,1)
 t.check(route_history_of(g).size()==2 and String(cycle.get("enter",""))==ROUTE_CYCLE,"ROUTEHIST route_history_cycle_capture_release: the cycle switch is recorded before the capture")
 t.check(g.state.phase=="map" and g.state.room=="tower_bottom","ROUTEHIST route_history_cycle_capture_release: the new generation starts at the tower bottom")
 t.check(route_depart_first_battle(t,g),"ROUTEHIST route_history_cycle_capture_release: a real departure starts the new generation battle")
 route_capture(t,g)
 t.check(not g.state.prison.is_empty(),"ROUTEHIST route_history_cycle_capture_release: the new generation capture opens a real cell")
 g.state.prison.key=true
 g.state.prison.served_turns=g.Prison.sentence_limit(g)-1
 t.check(t.action(g,"end").ok,"ROUTEHIST route_history_cycle_capture_release: the sentence ends on a real completed turn")
 var history=route_history_of(g)
 t.check(history.size()==3,"ROUTEHIST route_history_cycle_capture_release: the release appends exactly one record")
 var opened=route_record(g,2)
 t.check(String(opened.get("enter",""))==ROUTE_RELEASE,"ROUTEHIST route_history_cycle_capture_release: a capture inside the new cycle also opens release: "+String(opened.get("enter","")))
 t.check(int(opened.get("cycle",-1))==1 and int(opened.get("generation",-1))==int(cycle.get("generation",-2))+1 and String(opened.get("region",""))=="tower","ROUTEHIST route_history_cycle_capture_release: the release keeps cycle one and advances the generation")

static func route_history_cycle_and_cleared_rooms(t) -> void:
 var g=route_new_run(t)
 route_win_battle(t,g)
 preload("res://tests/demo_exit_cases.gd").exit_fixture(g)
 t.check(g.state.completed_rooms==["summit","exit"],"ROUTEHIST-6 the fixture reaches the cleared summit boundary")
 t.check(t.action(g,"demo_continue").ok,"ROUTEHIST-6 the real continue command opens the next cycle")
 var history=route_history_of(g)
 t.check(history.size()==2,"ROUTEHIST-6 the cycle switch appends exactly one record")
 var opened=route_record(g,1);var closed=route_record(g,0)
 t.check(String(opened.get("enter",""))==ROUTE_CYCLE and int(opened.get("cycle",-1))==1 and String(opened.get("region",""))=="tower","ROUTEHIST-6 the cycle record carries the new cycle number")
 t.check(int(closed.get("nodes",-1))==2 and int(closed.get("floor",-1))==17,"ROUTEHIST-6 the closed record backfills nodes and the reached floor")

static func route_history_one_per_switch(t) -> void:
 var g=CoreGame.new(42)
 var before=route_history_of(g).size()
 var log=preload("res://tests/architecture_cases.gd").transition_log(g)
 g._restart_tower()
 var delta=preload("res://tests/architecture_cases.gd").transition_delta(g,log)
 t.check(route_history_of(g).size()==before+1,"ROUTEHIST-7 one tower switch appends exactly one record")
 t.check(preload("res://tests/architecture_cases.gd").transition_kinds(delta,"tower_restart").size()==1,"ROUTEHIST-7 the switch stays one declared transition")

static func route_history_is_reproducible(t) -> void:
 var a=route_escape_and_gate(t)
 var b=route_escape_and_gate(t)
 t.check(route_history_of(a).size()>0,"ROUTEHIST-8 the gate exit leaves records to compare")
 t.check(route_history_of(a)==route_history_of(b),"ROUTEHIST-8 same seed and commands reproduce the same history")
 t.check(a.export_snapshot()==b.export_snapshot(),"ROUTEHIST-8 the whole exported state is reproducible")
 for record in route_history_of(a):
  t.check(route_keys_sorted(record)==ROUTE_KEYS,"ROUTEHIST-8 every record keeps the declared key set")

static func route_history_rejected_switch_rolls_back(t) -> void:
 var g=route_new_run(t)
 preload("res://tests/demo_exit_cases.gd").exit_fixture(g)
 var history=route_history_of(g).duplicate(true)
 t.check(history.size()>0,"ROUTEHIST-9 the run holds one record before the rejected switch")
 g.state.security=7
 var version=g.state.version
 var before=g.export_snapshot()
 var candidate=t.find_action(g,"demo_continue")
 var result=g.dispatch(g.command(candidate.payload,version),version)
 t.check(not result.ok,"ROUTEHIST-9 a switch that fails the aggregate check is rejected")
 t.check(g.export_snapshot()==before,"ROUTEHIST-9 the rejection restores the whole state byte-for-byte")
 t.check(route_history_of(g)==history,"ROUTEHIST-9 the rejected switch appends no record")

static func route_history_legacy_backfills(t) -> void:
 var g=CoreGame.new(42)
 var saved=g.export_snapshot()
 saved.erase("route_history")
 var before=saved.duplicate(true)
 var twin=CoreGame.new(7)
 var result=twin.restore_snapshot(saved)
 t.check(result.ok,"ROUTEHIST-10 a save without the field still loads")
 t.check(saved==before,"ROUTEHIST-10 the caller dictionary stays without the field")
 var history=route_history_of(twin)
 t.check(history.size()==1,"ROUTEHIST-10 the legacy save backfills exactly one record")
 var record=route_record(twin,0)
 t.check(String(record.get("enter",""))==ROUTE_UNKNOWN,"ROUTEHIST-10 the backfill is visibly unattributed")
 t.check(int(record.get("cycle",-1))==int(twin.state.demo_cycle) and int(record.get("generation",-1))==int(twin.state.tower_generation) and String(record.get("region",""))==String(twin.state.map_region),"ROUTEHIST-10 the backfill keeps cycle, generation and region")
 t.check(int(record.get("nodes",0))==-1 and int(record.get("floor",0))==-1,"ROUTEHIST-10 nodes and floor wait for the next real close")
 t.check(twin.state.save_revision==CoreGame.Snapshot.REVISION,"ROUTEHIST-10 the backfill does not raise the save revision")
 twin._restart_tower()
 t.check(int(route_record(twin,0).get("nodes",-1))==0 and int(route_record(twin,0).get("floor",-1))==0,"ROUTEHIST-10 the next close fills the backfilled record")

static func route_history_pre_revision_backfill(t) -> void:
 var g=CoreGame.new(42)
 var saved=g.export_snapshot()
 saved.save_revision=CoreGame.Snapshot.IRON_DRONE_REVISION
 saved.erase("route_history")
 var twin=CoreGame.new(7)
 var result=twin.restore_snapshot(saved)
 t.check(result.ok,"ROUTEHIST-11 a pre-revision save still loads")
 t.check(route_history_of(twin).size()==1 and String(route_record(twin,0).get("enter",""))==ROUTE_UNKNOWN,"ROUTEHIST-11 the migration backfills one unattributed record")
 t.check(twin.state.save_revision==CoreGame.Snapshot.REVISION,"ROUTEHIST-11 loading writes only the shared current revision")

static func route_history_roundtrip(t) -> void:
 var g=CoreGame.new(42)
 var history=route_history_of(g).duplicate(true)
 t.check(not history.is_empty(),"ROUTEHIST-12 a new save carries the route history")
 var restored=roundtrip(t,g,"route history")
 if restored==null: return
 t.check(route_history_of(restored)==history,"ROUTEHIST-12 the written and read history is identical")
 t.check(restored.state.save_revision==CoreGame.Snapshot.REVISION,"ROUTEHIST-12 the roundtrip keeps the current revision")

# ==== 加固矩阵：五类真实切换 × 三种存档形态 ====
# 存档形态只改载入路径：本片写出的档、擦掉 route_history 的旧档、同一旧档标成 IRON_DRONE_REVISION。
# 每一格都从真实命令推进到切换点，再经真实 dispatch 触发切换；判据只读 state.route_history 与
# restore_snapshot 的结果（不直接调用 core/route_history.gd）。见 docs/spec/route-history.md「输入域」。
const ROUTE_MATRIX_CAUSES=["start","release","escape","gate_exit","cycle"]

# 切换点夹具：返回切换发生前的真实局面。start 之外都不触发目标切换。
static func route_matrix_prepare(t, cause: String):
 var g=null
 match cause:
  "start":
   g=CoreGame.new(42)
  "release":
   g=route_new_run(t)
   route_win_battle(t,g)
   var rooms=g.route_view().filter(func(room):return String(room.get("status",""))=="available" and String(room.get("icon","")) in ["battle","boss"])
   t.check(not rooms.is_empty(),"ROUTEHIST route_history_switch_matrix: the release fixture exposes a battle room")
   if not rooms.is_empty():
    t.check(t.action(g,"depart",{"room":rooms[0].id}).ok,"ROUTEHIST route_history_switch_matrix: the release fixture departs for a real battle")
    route_travel(t,g)
    route_capture(t,g)
    g.state.prison.key=true
    g.state.prison.served_turns=g.Prison.sentence_limit(g)-1
  "escape":
   g=route_new_run(t)
   route_capture(t,g)
   preload("res://tests/exploration_fixture.gd").at_site(g,"door")
   g.state.prison.key=true
   t.check(t.action(g,"prison",{"action":"key"}).ok,"ROUTEHIST route_history_switch_matrix: the escape fixture holds the cell key")
  "gate_exit":
   g=route_new_run(t)
   route_capture(t,g)
   preload("res://tests/prison_cases.gd").exit_to_route(t,g)
   preload("res://tests/prison_cases.gd").travel_route(t,g,"prison_rest")
   t.check(t.action(g,"rest_begin").ok,"ROUTEHIST route_history_switch_matrix: the gate fixture starts the prison rest room")
   t.check(t.action(g,"finish_rest").ok,"ROUTEHIST route_history_switch_matrix: the gate fixture ends the prison rest room")
   preload("res://tests/prison_cases.gd").travel_route(t,g,"prison_gate")
  "cycle":
   g=route_new_run(t)
   route_win_battle(t,g)
   preload("res://tests/demo_exit_cases.gd").exit_fixture(g)
 return g

# 载入形态：只有存档字节不同。新档保留字段；旧档与迁移档都缺字段，由 restore_snapshot 回填。
static func route_matrix_load(t, source, form: String):
 var saved=source.export_snapshot()
 if form!="new":
  saved.erase("route_history")
  if form=="migration": saved.save_revision=CoreGame.Snapshot.IRON_DRONE_REVISION
 var twin=CoreGame.new(7)
 var result=twin.restore_snapshot(saved)
 t.check(result.ok,"ROUTEHIST route_history_switch_matrix: the "+form+" save loads: "+String(result.get("error","")))
 return twin

# 真实切换：只发正式指令，不碰 RouteHistory。
static func route_matrix_switch(t, cause: String, g) -> void:
 match cause:
  "start":
   return
  "release":
   t.check(t.action(g,"end").ok,"ROUTEHIST route_history_switch_matrix: release closes the sentence through a real turn end")
  "escape":
   t.check(t.action(g,"prison",{"action":"door_exit"}).ok,"ROUTEHIST route_history_switch_matrix: escape leaves through the real door exit")
  "gate_exit":
   route_win_battle(t,g)
  "cycle":
   t.check(t.action(g,"demo_continue").ok,"ROUTEHIST route_history_switch_matrix: the cycle switch is the real continue command")

# §3.5 的期望：条数、进入原因、周目、代数、区域；boss 由区域与 state.room_encounters 决定。
static func route_matrix_expected(form: String, cause: String) -> Dictionary:
 var counts={"new":{"start":1,"release":2,"escape":2,"gate_exit":3,"cycle":2},
  "legacy":{"start":1,"release":2,"escape":2,"gate_exit":2,"cycle":2},
  "migration":{"start":1,"release":2,"escape":2,"gate_exit":2,"cycle":2}}
 var cycles={"start":0,"release":0,"escape":0,"gate_exit":0,"cycle":1}
 var generations={"start":0,"release":1,"escape":0,"gate_exit":1,"cycle":1}
 var regions={"start":"tower","release":"tower","escape":"prison","gate_exit":"tower","cycle":"tower"}
 return {"count":int(counts[form][cause]),"cycle":int(cycles[cause]),"generation":int(generations[cause]),"region":String(regions[cause])}

static func route_history_switch_matrix(t) -> void:
 for cause in ROUTE_MATRIX_CAUSES:
  var source=route_matrix_prepare(t,cause)
  t.check(source!=null,"ROUTEHIST route_history_switch_matrix: the "+cause+" fixture builds a real run")
  if source==null: continue
  var before=route_history_of(source).duplicate(true)
  for form in ["new","legacy","migration"]:
   var g=route_matrix_load(t,source,form)
   var loaded=route_history_of(g).duplicate(true)
   if form=="new":
    t.check(loaded==before,"ROUTEHIST route_history_switch_matrix: "+cause+"/new keeps the field written by this slice")
   else:
    t.check(loaded.size()==1 and String(route_record(g,0).get("enter",""))==ROUTE_UNKNOWN,"ROUTEHIST route_history_switch_matrix: "+cause+"/"+form+" backfills exactly one unknown record")
   route_matrix_switch(t,cause,g)
   var expected=route_matrix_expected(form,cause)
   var history=route_history_of(g)
   var label=" "+cause+"/"+form
   t.check(history.size()==int(expected.count),"ROUTEHIST route_history_switch_matrix:"+label+" keeps "+str(expected.count)+" records: "+str(history.size()))
   if history.is_empty(): continue
   var record=history[-1]
   print("ROUTEHIST MATRIX cell "+cause+"/"+form+" count="+str(history.size())+" first="+String(history[0].get("enter",""))+" last="+String(record.get("enter",""))+" cycle="+str(record.get("cycle",""))+" generation="+str(record.get("generation",""))+" region="+String(record.get("region",""))+" boss="+String(record.get("boss","")))
   var want_enter=cause if form=="new" or cause!="start" else ROUTE_UNKNOWN
   t.check(String(record.get("enter",""))==want_enter,"ROUTEHIST route_history_switch_matrix:"+label+" opens with "+want_enter)
   t.check(int(record.get("cycle",-1))==int(expected.cycle),"ROUTEHIST route_history_switch_matrix:"+label+" records cycle "+str(expected.cycle))
   t.check(int(record.get("generation",-1))==int(expected.generation),"ROUTEHIST route_history_switch_matrix:"+label+" records generation "+str(expected.generation))
   t.check(String(record.get("region",""))==String(expected.region),"ROUTEHIST route_history_switch_matrix:"+label+" records region "+String(expected.region))
   var want_boss="" if String(expected.region)=="prison" else String(g.state.room_encounters.get("summit",""))
   t.check(String(record.get("boss",""))==want_boss,"ROUTEHIST route_history_switch_matrix:"+label+" records the summit id "+want_boss)
   t.check(int(record.get("seed",-1))==int(g.state.seed),"ROUTEHIST route_history_switch_matrix:"+label+" records the opened route seed")
   t.check(int(record.get("security",-1))==int(g.state.security),"ROUTEHIST route_history_switch_matrix:"+label+" records the opened security count")
   t.check(int(record.get("nodes",0))==-1 and int(record.get("floor",0))==-1,"ROUTEHIST route_history_switch_matrix:"+label+" leaves the new record open")
   if history.size()>1:
    var closed=history[-2]
    t.check(int(closed.get("nodes",-1))>=0 and int(closed.get("floor",-1))>=0,"ROUTEHIST route_history_switch_matrix:"+label+" closes the previous record")
   if form!="new" and cause!="start":
    var backfilled=history[0]
    t.check(int(backfilled.get("nodes",-1))>=0 and int(backfilled.get("floor",-1))>=0,"ROUTEHIST route_history_switch_matrix:"+label+" closes the backfilled record")
   if cause=="release":
    t.check(String(record.get("boss",""))==String(route_record(g,0).get("boss","")),"ROUTEHIST route_history_switch_matrix:"+label+" keeps the summit within the cycle")
   if cause=="gate_exit" and form=="new":
    t.check(String(record.get("boss",""))==String(route_record(g,0).get("boss","")),"ROUTEHIST route_history_switch_matrix:"+label+" keeps the previous tower summit")

static func route_history_cases(t) -> void:
 route_history_start_record(t)
 route_history_practice_isolated(t)
 route_history_release_closes_route(t)
 route_history_escape_keeps_generation(t)
 route_history_gate_exit_appends(t)
 route_history_second_capture_release(t)
 route_history_cycle_capture_release(t)
 route_history_cycle_and_cleared_rooms(t)
 route_history_one_per_switch(t)
 route_history_is_reproducible(t)
 route_history_rejected_switch_rolls_back(t)
 route_history_legacy_backfills(t)
 route_history_pre_revision_backfill(t)
 route_history_roundtrip(t)
 route_history_switch_matrix(t)

static func retired_opener(t) -> void:
 var g=Game.new(42)
 var saved=g.export_snapshot();saved.save_revision=g.Snapshot.OPENER_REVISION
 var old={"uid":"card_%d" % saved.next_card,"type":"letter_opener","retain_until":-1}
 saved.next_card+=1;saved.deck.append(old);saved.powers.append(old.merged({"power_face":"bound","power_progress":2}))
 saved.rest_cards=["focus","letter_opener","concentration"]
 var input=saved.duplicate(true)
 var result=g.restore_snapshot(saved)
 t.check(result.ok and saved==input and not g.state.deck.any(func(c):return c.uid==old.uid) and g.state.powers.is_empty(),"SAVE retired card and its active counter leave the copied legacy snapshot")
 t.check(result.ok and g.state.rest_cards.size()==3 and g.state.rest_cards[0]=="focus" and g.state.rest_cards[2]=="concentration" and g.state.rest_cards[1] not in input.rest_cards and g.state.rng==input.rng,"SAVE retired reward is replaced in place without rerolling adjacent choices or RNG")
 t.check(not g.Cards.Rules.SPECS.has(old.type) and old.type not in g.Cards.Rules.REWARDS,"SAVE retired opener has no live definition or reward slot")
 var retain=input.duplicate(true)
 retain.draw.append_array(retain.hand);retain.hand=[old.duplicate()];retain.powers=[]
 retain.pending_retain=true;retain.retain_left=1;retain.retain_draw_after=1
 t.check(g.restore_snapshot(retain).ok and not g.state.pending_retain and g.state.hand.size()==1 and g.state.hand[0].type!=old.type,"SAVE retiring the only retain target finishes the selection and draws its pending card")
 var shop=input.duplicate(true)
 for room in shop.rooms:
  if room.kind=="shop":
   room.remove_used=false;room.stock=[{"kind":"card","type":old.type,"price":25.0,"taken":false},{"kind":"card","type":"pot_of_greed","price":25.0,"taken":false}]
   t.check(g.restore_snapshot(shop).ok and g.room_data(room.id).stock.size()==1 and g.room_data(room.id).stock[0].type=="pot_of_greed","SAVE retired shop slot disappears while neighboring stock remains purchasable")
   break
 var before=g.export_snapshot();saved.save_revision=g.Snapshot.REVISION
 t.check(not g.restore_snapshot(saved).ok and g.state==before,"SAVE current revision rejects a retired card atomically")

static func run(t) -> void:
 retired_opener(t)
 g3_reject_never_writes(t)
 save_and_random_untouched(t)
 initial_seed_is_fixed_at_run_start(t)
 initial_seed_survives_round_trip(t)
 legacy_save_without_initial_seed_backfills(t)
 initial_seed_uses_the_shared_field_check(t)
 route_history_cases(t)
 fixed_point_text_reads_the_written_bytes(t)
 save_writes_on_new_floor(t)
 save_writes_when_battle_finishes(t)
 save_writes_when_prepare_finishes(t)
 save_skips_representative_non_points(t)
 save_backup_holds_previous_fixed_point(t)
 save_fixed_point_preserves_failure_and_format_contract(t)
 transition_log_never_reaches_state_or_view(t)
 event_trace_never_reaches_state_or_save(t)

 event_pipeline_writes_only_declared_keys(t)
 map_drawings(t)
 unlimited_file_size(t)
 preload("res://tests/scene_restart_cases.gd").run(t,same)
 revision_boundary(t)
 event_conditions(t)
 event_frozen_options_roundtrip(t)
 t.check(Game.Snapshot.Phases.DEFINITIONS.values().all(func(stage):return stage.name!="" and stage.caption!=""),"SAVE every accepted phase has a homepage summary label")
 var sample_draw=Game.new(42)
 var unchanged=sample_draw.export_snapshot()
 for field in ["draw_serial","draw_free","point"]:
  var invalid=unchanged.duplicate(true)
  if field=="point": invalid.enemies[0].intent.point=123
  else: invalid.hand[0][field]="invalid"
  t.check(not sample_draw.restore_snapshot(invalid).ok and sample_draw.export_snapshot()==unchanged,"SAVE malformed draw/position field rejected atomically "+field)
 var g=Game.new(9223372036854775806)
 var h=roundtrip(t,g,"64-bit seed")
 step_both(t,g,h,"end")
 for kind in g.Tower.all_practices():
  var sample=Game.new(42,true,kind)
  roundtrip(t,sample,"practice "+kind)
 g=Game.new(42)
 var stale=g.command_facts()[0];var version=g.state.version;var snapshot=g.export_snapshot()
 t.check(g.restore_snapshot(snapshot).ok and not g.dispatch(g.command(stale.payload,version),version).ok,"SAVE old drag version invalid after in-place restore")
 for i in range(4): t.action(g,"end")
 h=roundtrip(t,g,"reward")
 step_both(t,g,h,"reward",{"type":g.state.reward_options[0]})
 step_both(t,g,h,"reward",{"type":"skip"})
 h=roundtrip(t,g,"prepare");step_both(t,g,h,"finish_prepare")
 h=roundtrip(t,g,"map");step_both(t,g,h,"depart",{"room":"west"})
 h=roundtrip(t,g,"travel");step_both(t,g,h,"travel_step")

 var Rewards=preload("res://tests/reward_cases.gd")
 g=Rewards.setup()
 var a=g.add_fixture("wrist",8,10,true);g.add_fixture("wrist",8,10,true);var c=g.add_fixture("wrist",8,10,true)
 var card=Rewards.give(t,g,"double_unlock")
 Rewards.play(t,g,card,"wrist",a.id)
 h=roundtrip(t,g,"pending second unlock")
 step_both(t,g,h,"chain",{"target":c.id})
 g=Rewards.setup();card=Rewards.give(t,g,"focus");Rewards.play(t,g,card,"thigh")
 t.check(g.state.pending_retain,"SAVE selective retain fixture enters a real pending choice")
 h=roundtrip(t,g,"pending selected retain and follow-up draw")
 step_both(t,g,h,"retain",{"uid":g.state.hand[0].uid})
 g=Rewards.setup();g.state.relics.append("break_bracer")
 a=g.add_fixture("wrist",1);g.add_fixture("wrist",1);c=g.add_fixture("wrist",1)
 card=Rewards.give(t,g,"chain")
 h=roundtrip(t,g,"before automatic removal and relic benefits")
 step_both(t,g,h,"card",{"uid":card.uid,"target":a.id})
 t.check(g.state.card_chain.is_empty() and g.state.charge==1,"SAVE automatic removals settle once-per-turn relic benefit")

 g=Game.new(42);preload("res://tests/event_cases.gd").arrive(g,"binding_cleric")
 h=roundtrip(t,g,"current event choice")
 step_both(t,g,h,"event",{"action":"choose","choice":"leave_free"})
 h=roundtrip(t,g,"current event result")
 step_both(t,g,h,"event",{"action":"leave"})

 g=Game.new(42,true,"pressure");g.Pressure.gain(g,160,"测试脉冲")
 h=roundtrip(t,g,"overload");step_both(t,g,h,"end")
 g=Game.new(42,true,"guard");preload("res://tests/guard_cases.gd").ready(g);t.action(g,"end")
 h=roundtrip(t,g,"captured");step_both(t,g,h,"prison",{"action":"enter"})
 h=roundtrip(t,g,"cell");step_both(t,g,h,"end")
 preload("res://tests/prison_cases.gd").inspect(t,g)
 h=roundtrip(t,g,"inspection");step_both(t,g,h,"prison",{"action":"inspect"})
 h=roundtrip(t,g,"inspection result");step_both(t,g,h,"prison",{"action":"accept"})
 h=roundtrip(t,g,"inspection complete");step_both(t,g,h,"prison",{"action":"resist"})
 h=roundtrip(t,g,"resistance battle");step_both(t,g,h,"end")
 g=Game.new(42,true,"guard");g.state.security=4;g.Guard.capture(g,g.state.enemies[0]);t.action(g,"prison",{"action":"enter"})
 roundtrip(t,g,"security five cell")
 g=preload("res://tests/prison_cases.gd").intake(t)
 preload("res://tests/prison_cases.gd").clear_fixture(g)
 for i in range(3): t.action(g,"prison",{"action":"explore"})
 h=roundtrip(t,g,"retained return seal and frozen cell pool")
 step_both(t,g,h,"relic_discharge",{"relic":"return_seal"})
 roundtrip(t,g,"special item escape to regenerated tower")
 g=Game.new(42,true,"equipment");t.action(g,"finish_rest");roundtrip(t,g,"practice completed")
 g=Rewards.setup()
 for i in range(4): g._gain_tool("picks")
 t.action(g,"finish_prepare")
 h=roundtrip(t,g,"over-capacity packing");step_both(t,g,h,"item_discard",{"item":g.state.items[0].id})
 g=Rewards.setup();a=g.add_fixture("thigh",4,10,true);c=g.add_fixture("ankle",4,10,true)
 card=Rewards.give(t,g,"double_unlock");Rewards.play(t,g,card,"thigh",a.id)
 h=roundtrip(t,g,"second magic lock");step_both(t,g,h,"chain",{"target":c.id})

 # Corrupt shapes, ids, references, versions and checksums must reject without mutation.
 g=Game.new(42)
 var clean=g.export_snapshot()
 for domain in g.B.RNG_SALTS:
  for damage in ["missing","fractional","negative"]:
   var bad=clean.duplicate(true)
   match damage:
    "missing": bad.rng.erase(domain)
    "fractional": bad.rng[domain]=0.5
    "negative": bad.rng[domain]=-1
   t.check(not g.restore_snapshot(bad).ok and g.state==clean,"SAVE registered random domain rejects invalid counters atomically "+domain+" "+damage)
 var unknown_domain=clean.duplicate(true)
 unknown_domain.rng.unregistered_domain=0
 t.check(not g.restore_snapshot(unknown_domain).ok and g.state==clean,"SAVE unregistered random domains reject without changing the live state")
 g.state=clean.duplicate(true)
 for change in ["missing","phase","cards","rng","enemy","enemy_kind","id","reference","nan"]:
  var bad=clean.duplicate(true)
  match change:
   "missing": bad.erase("mana")
   "phase": bad.phase="unknown"
   "cards": bad.hand[0].type="missing"
   "rng": bad.rng.deck="broken"
   "enemy": bad.enemies[0].intent={"kind":"install"}
   "enemy_kind": bad.enemies[0].intent={"kind":"unknown","text":"invalid","delayed":false}
   "id": bad.next_card=1
   "reference": bad.rooms[0].next=["missing_room"]
   "nan": bad.mana=NAN
  t.check(not g.restore_snapshot(bad).ok and g.state==clean,"SAVE corrupted state atomically rejected "+change)
 var envelope=JSON.parse_string(Store.pack(clean));envelope.payload+="x"
 t.check(not Store.unpack(JSON.stringify(envelope)).ok,"SAVE checksum detects truncated or changed payload")
 envelope=JSON.parse_string(Store.pack(clean));envelope.format=999
 t.check(not Store.unpack(JSON.stringify(envelope)).ok,"SAVE unknown format rejected")
 t.check(not Store.unpack("{bad").ok,"SAVE broken outer JSON rejected without engine error")

 var store=Store.new("res://build/save-tests-"+str(Time.get_ticks_usec()))
 t.check(not store.read_slot("tower").ok,"SAVE missing file handled")
 t.check(store.write_game(g).ok,"SAVE first real write")
 var first=FileAccess.get_file_as_string(store.path("tower"))
 var first_scene=store.read_slot("tower").snapshot
 t.action(g,"end")
 t.check(store.write_game(g).ok and FileAccess.get_file_as_string(store.path("tower")+".bak")==first,"SAVE next atomic write preserves previous valid backup")
 var newest=store.read_slot("tower")
 t.check(newest.ok and not newest.backup and newest.snapshot==g.restart_snapshot(),"SAVE latest full state reads exactly")
 var file=FileAccess.open(store.path("tower"),FileAccess.WRITE);file.store_string("broken");file.close()
 var recovered=store.read_slot("tower")
 t.check(recovered.ok and recovered.backup and recovered.snapshot==first_scene,"SAVE damaged primary recovers previous valid state")
 t.check(store.write_game(g).ok and store.read_slot("tower").snapshot==g.restart_snapshot(),"SAVE subsequent save repairs primary without losing valid backup")
 var tower_bytes=FileAccess.get_file_as_string(store.path("tower"))
 t.check(store.write_game(Game.new(42,true,"leg_pair")).ok and FileAccess.get_file_as_string(store.path("tower"))==tower_bytes and store.read_slot("practice").ok,"SAVE practice slot never overwrites tower")
 var escaped=preload("res://tests/prison_cases.gd").intake(t)
 preload("res://tests/prison_cases.gd").clear_fixture(escaped)
 preload("res://tests/exploration_fixture.gd").at_site(escaped,"door");escaped.state.posture="stand"
 card=t.grant_fixture_card(escaped,"unlock")
 t.action(escaped,"prison",{"action":"unlock","uid":card.uid})
 t.action(escaped,"prison",{"action":"door_exit"})
 t.check(not escaped.state.practice and escaped.state.phase=="map" and escaped.state.save_slot=="practice","SAVE practice-origin escape keeps its save identity")
 t.check(store.write_game(escaped).ok and FileAccess.get_file_as_string(store.path("tower"))==tower_bytes,"SAVE escaped practice tower still cannot overwrite formal run")
 roundtrip(t,escaped,"escaped practice tower")
 var blocked=Store.new(store.path("tower"))
 t.check(not blocked.write_game(g).ok and FileAccess.get_file_as_string(store.path("tower"))==tower_bytes,"SAVE write failure retains original save and live game")
 envelope=JSON.parse_string(tower_bytes);envelope.format=999
 file=FileAccess.open(store.path("tower"),FileAccess.WRITE);file.store_string(JSON.stringify(envelope));file.close()
 t.check(not store.read_slot("tower").ok and store.read_slot("tower").error.contains("需要匹配的游戏版本"),"SAVE newer primary never silently falls back to old backup")
 var incompatible=FileAccess.get_file_as_string(store.path("tower"))
 t.check(not store.write_game(g).ok and FileAccess.get_file_as_string(store.path("tower"))==incompatible,"SAVE incompatible file appearing mid-session cannot be overwritten automatically")
 t.check(store.write_game(Game.new(42),true).ok and store.read_slot("tower").ok,"SAVE explicit new run can replace incompatible primary")
