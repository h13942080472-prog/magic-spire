extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const CoreGame=preload("res://core/game.gd")
const Store=preload("res://core/save_store.gd")
const Guard=preload("res://core/guard.gd")
const EventCases=preload("res://tests/event_cases.gd")
const ExitCases=preload("res://tests/demo_exit_cases.gd")
# D23b：旧目录导入器与两个设置属主模块；夹具父目录/目标/标记全部走参数。导入器在实现前不存在，
# 所以由 legacy_module()（文件末尾）惰性取用，不用 preload。
const DisplaySettings=preload("res://ui/display_settings.gd")
const KeyBindings=preload("res://ui/key_bindings.gd")
const LEGACY_NAME_PREFIX="紧缚尖塔demo v"

# LEGACY-7 的宿主替身：只提供 run_once 解引用的三个字段；属主对象可以缺失，用来证明关闸时
# 在任何路径解析之前返回。
class LegacyImportHost extends RefCounted:
 var persistence_enabled=true
 var display_settings=null
 var keyboard_input=null

# LEGACY-16（A317 F1）的宿主替身：run_once 解引用的全部字段都在，store 与两个设置属主都指向
# res://build/ 下的夹具，用来证明生产入口的路径只从注入的 store 推导。
class LegacyKeyboardStub extends RefCounted:
 var settings=null

class LegacyStoreHost extends RefCounted:
 var persistence_enabled=true
 var saves=null
 var display_settings=null
 var keyboard_input=null

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

# D23a（A279，docs/spec/packaging.md「用户数据目录」）：运行时目录由 project.godot 的固定名决定，
# 与 application/config/name 无关；Windows 上它的父目录是 APPDATA 环境变量，成品探针据此把子进程
# 隔离到检查目录。实测（Godot 4.7.2，`--headless --script`）：editor 特性标签为真，运行时目录因此是
# `.editor` 覆盖的 -dev 名字；本条钉「声明存在」与「运行时目录等于按特性标签解析出的名字」。
static func userdir_normalized(path: String) -> String:
 return path.replace("\\","/").trim_suffix("/")

# Reads the *declared* (unresolved) value of a project setting. ProjectSettings.get_setting does not apply
# feature-tag overrides, so the `.editor` override stays invisible to this helper and callers must add the
# tag branch themselves (editor_tag_isolates_dev_user_dir does). The declared literals are pinned exactly
# once, from the project.godot source text, by architecture_cases.gd::user_dir_name_is_version_free; this
# helper only feeds the runtime-directory comparison, so the two USERDIR criteria do not read the same value twice.
static func userdir_declared_value(key: String) -> String:
 return String(ProjectSettings.get_setting(key,""))

static func user_dir_ignores_project_name(t) -> void:
 var directory=userdir_normalized(OS.get_user_data_dir())
 var project_name=userdir_declared_value("application/config/name")
 t.check(project_name!="" and not directory.contains(project_name),"USERDIR user_dir_ignores_project_name: the runtime directory does not follow application/config/name: dir="+directory+" name="+project_name)
 var appdata=userdir_normalized(OS.get_environment("APPDATA"))
 t.check(OS.get_name()!="Windows" or (appdata!="" and directory.begins_with(appdata+"/")),"USERDIR user_dir_ignores_project_name: on Windows the APPDATA environment variable parents the user directory: appdata="+appdata+" dir="+directory)

static func editor_tag_isolates_dev_user_dir(t) -> void:
 var override=userdir_normalized(userdir_declared_value("application/config/custom_user_dir_name.editor"))
 var base=userdir_normalized(userdir_declared_value("application/config/custom_user_dir_name"))
 var directory=userdir_normalized(OS.get_user_data_dir())
 var activated=OS.has_feature("editor")
 t.check(base!="" and override.ends_with("-dev") and override!=base,"USERDIR editor_tag_isolates_dev_user_dir: project.godot declares a distinct -dev editor override: override="+override)
 t.check(directory.ends_with("/"+(override if activated else base)),"USERDIR editor_tag_isolates_dev_user_dir: the runtime directory follows the feature tags this process has: editor="+str(activated)+" dir="+directory)

static func run(t) -> void:
 user_dir_ignores_project_name(t)
 editor_tag_isolates_dev_user_dir(t)
 legacy_source_is_the_newest_directory_with_a_readable_save(t)
 legacy_source_follows_save_mtime_not_version(t)
 legacy_never_imports_into_a_non_empty_target(t)
 legacy_import_runs_only_once(t)
 legacy_leaves_every_legacy_byte_untouched(t)
 legacy_skips_invalid_saves_and_keeps_the_rest(t)
 legacy_stays_off_without_persistence_or_desktop(t)
 legacy_interrupted_copy_converges(t)
 legacy_directory_matrix_matches_the_plan(t)
 legacy_crash_after_temp_write_converges(t)
 legacy_crash_midway_before_marker_converges(t)
 legacy_source_tie_is_deterministic(t)
 legacy_source_ignores_directories_without_saves(t)
 legacy_source_never_picks_dev_or_target_name(t)
 legacy_source_accepts_non_ascii_and_spaced_names(t)
 legacy_run_once_derives_paths_from_the_injected_store(t)
 legacy_display_import_follows_initialize_domains(t)
 legacy_write_failure_keeps_the_import_retryable(t)
 g3_reject_never_writes(t)
 save_and_random_untouched(t)
 initial_seed_is_fixed_at_run_start(t)
 initial_seed_survives_round_trip(t)
 legacy_save_without_initial_seed_backfills(t)
 initial_seed_uses_the_shared_field_check(t)
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
 g._gain_tool("return_seal") # Preserve existing-item support; absent from generation.
 var seal=g.state.items.filter(func(i):return i.type=="return_seal")[0]
 h=roundtrip(t,g,"retained return seal and frozen cell pool")
 step_both(t,g,h,"item_use",{"item":seal.id,"target":"hero"})
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
 t.check(store.write_game(Game.new(42,true,"component_links")).ok and FileAccess.get_file_as_string(store.path("tower"))==tower_bytes and store.read_slot("practice").ok,"SAVE practice slot never overwrites tower")
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

# ---------------------------------------------------------------------------
# D23b 旧目录导入（docs/spec/save-fixed-points.md「旧目录导入」）。夹具父目录、目标目录与标记都由
# 参数传进 ui/legacy_import.gd；测试只在 res://build/ 下造旧目录，从不读写真实 user://。
static func legacy_root(label: String) -> String:
 return "res://build/d23b-"+label+"-"+str(Time.get_ticks_usec())

# 实现前（C1）模块还不存在：判据先红在「模块存在且可加载」这一句，其余断言在实现后全跑；
# 这样套件不会因为一个缺失的 preload 整体加载失败，红证据按判据逐条具名。
static func legacy_module():
 if not ResourceLoader.exists("res://ui/legacy_import.gd"): return null
 return load("res://ui/legacy_import.gd")

static func legacy_dir(path: String) -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

static func legacy_bytes(path: String) -> PackedByteArray:
 return FileAccess.get_file_as_bytes(path)

static func legacy_same_file(left: String, right: String) -> bool:
 return FileAccess.file_exists(left) and FileAccess.file_exists(right) and legacy_bytes(left)==legacy_bytes(right)

# 旧目录的整棵快照：绝对名、mtime 与字节；只读扫描，不改任何字节。
static func legacy_tree(directory: String) -> Array:
 var rows=[]
 var pending=[directory]
 while not pending.is_empty():
  var current=String(pending.pop_back())
  var handle=DirAccess.open(current)
  if handle==null: continue
  for name in handle.get_files():
   var file=current.path_join(String(name))
   rows.append(file+":"+str(FileAccess.get_modified_time(file))+":"+legacy_bytes(file).hex_encode())
  for name in handle.get_directories(): pending.append(current.path_join(String(name)))
 rows.sort()
 return rows

# 用真实写盘入口造有效旧档：writes=2 时第二写产生 .bak（与生产备份顺序一致）。
static func legacy_saves(directory: String, slot: String, writes: int) -> void:
 legacy_dir(directory)
 var store=Store.new(directory)
 var g=Game.new(42,slot=="practice")
 for index in range(writes): store.write_game(g)

# A317 F2：属主 save() 写的每个键都离开默认值（固定立绘除外：它为真会把锁池三项关回默认，二者只能
# 留一组；固定立绘由 legacy_display_import_follows_initialize_domains 单测），import_from 漏掉的键就不会
# 碰巧读回相等。LEGACY-1 按整份文件比对。
static func legacy_settings(directory: String) -> void:
 legacy_dir(directory)
 var display=DisplaySettings.new()
 display.path=directory.path_join("display-settings.cfg")
 display.mode=1
 display.resolution=Vector2i(1920,1080)
 display.frame_limit=120
 display.vsync_enabled=false
 display.reduced_card_motion=true
 display.locale="ja_JP"
 display.art_choices={"cards":{"strain":"test","binding_enthusiast":"fixed"},"enemies":{"six_bind":"test"}}
 display.chastity_locks_enabled=true
 display.chastity_lock_chance=40
 display.cursed_plate_start=true
 display.cursed_plate_masochist_mode=true
 display.first_battle_tutorial_seen=true
 display.card_music_enabled=false;display.card_music_volume=0.35
 display.doubao_voice_enabled=false;display.doubao_voice_volume=0.5
 display.interaction_audio_enabled=false;display.interaction_audio_volume=0.25
 display.save()
 var keys=KeyBindings.new()
 keys.path=directory.path_join("key-bindings.cfg")
 keys.hold_end=true
 keys.assign("card_1",0,KEY_F1)

# 整份 cfg 的「节/键 → 值」表（读回比对用，键集合与值都要相等）。
static func legacy_cfg_values(path: String) -> Dictionary:
 var config=ConfigFile.new()
 if config.load(path)!=OK: return {}
 var values={}
 for section in config.get_sections():
  for key in config.get_section_keys(section): values[String(section)+"/"+String(key)]=config.get_value(section,key)
 return values

# 两张 cfg 表里缺失或值不同的键（双向），空数组即整份相等。
static func legacy_cfg_diff(left: Dictionary, right: Dictionary) -> Array:
 var keys=[]
 for key in left:
  if not right.has(key) or right[key]!=left[key]: keys.append(String(key))
 for key in right:
  if not left.has(key): keys.append(String(key))
 keys.sort()
 return keys

# 属主新实例 save() 出的默认 cfg 表：夹具自检用，证明夹具确实把各键挪离了默认值。
static func legacy_cfg_defaults(root: String) -> Dictionary:
 legacy_dir(root)
 var display=DisplaySettings.new()
 display.path=root.path_join("display-defaults.cfg")
 display.save()
 var keys=KeyBindings.new()
 keys.path=root.path_join("key-defaults.cfg")
 keys.save()
 return {"display":legacy_cfg_values(display.path),"keys":legacy_cfg_values(keys.path)}

static func legacy_marker(path: String) -> Dictionary:
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
 return parsed if parsed is Dictionary else {}

static func legacy_has_skip(data: Dictionary, file: String, code: String) -> bool:
 var rows=data.get("skipped",[])
 if not rows is Array: return false
 return rows.any(func(row):return row is Dictionary and String(row.get("file",""))==file and String(row.get("code",""))==code)

# 八个 LEGACY 判据共用的夹具头：惰性取模块（判据落地时模块还不存在，缺文件要按判据具名变红，
# 不能整个套件加载失败），再给出一个候选父目录和其中那个版本目录；各判据在其上追加自己的存档
# 与设置。返回空字典表示「模块缺失」这一条已经按判据点红。
static func legacy_ready(t, name: String, label: String) -> Dictionary:
 var module=legacy_module()
 t.check(module!=null,"LEGACY "+name+": ui/legacy_import.gd exists and loads")
 if module==null: return {}
 var root=legacy_root(label)
 var parent=root.path_join("legacy")
 return {"module":module,"root":root,"parent":parent,"source":parent.path_join(LEGACY_NAME_PREFIX+"0.17.1")}

# 夹具文件只经这一个写入口；所有夹具目录都在 res://build/ 下，不碰 user://。
static func legacy_write(path: String, data) -> void:
 var file=FileAccess.open(path,FileAccess.WRITE)
 if file==null: return
 if data is PackedByteArray: file.store_buffer(data)
 else: file.store_string(String(data))
 file.close()

# LEGACY-1：含有效存档的兄弟目录里按存档 mtime 选源；两个位的存档与 .bak 逐字节复制；
# display-settings.cfg 与 key-bindings.cfg 经各自属主模块的 import_from 写出；标记 schema=1 逐项登记。
static func legacy_source_is_the_newest_directory_with_a_readable_save(t) -> void:
 var ready=legacy_ready(t,"legacy_source_is_the_newest_directory_with_a_readable_save","legacy-source")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var parent=String(ready.parent)
 var source=String(ready.source)
 legacy_saves(source.path_join("saves"),"tower",2)
 legacy_settings(source)
 legacy_dir(parent.path_join(LEGACY_NAME_PREFIX+"0.18.3").path_join("logs"))
 legacy_dir(parent.path_join(LEGACY_NAME_PREFIX+"0.18.3").path_join("shader_cache"))
 legacy_saves(parent.path_join("紧缚尖塔-dev").path_join("saves"),"tower",1)
 var target=root.path_join("target")
 legacy_dir(target)
 var marker=target.path_join("legacy-import.json")
 var result=module.run(parent,target,marker,Store.new(target.path_join("saves")))
 t.check(String(result.get("source",""))==LEGACY_NAME_PREFIX+"0.17.1","LEGACY legacy_source_is_the_newest_directory_with_a_readable_save: the source is the newest directory that holds a readable save, not the highest version name or the dev directory: "+str(result.get("source","")))
 t.check(legacy_same_file(source.path_join("saves").path_join("tower.json"),target.path_join("saves").path_join("tower.json")) and legacy_same_file(source.path_join("saves").path_join("tower.json.bak"),target.path_join("saves").path_join("tower.json.bak")),"LEGACY legacy_source_is_the_newest_directory_with_a_readable_save: the two copied save files stay byte identical to the legacy ones")
 # A317 F2: both settings files read back key for key equal to the legacy files (every key the owner
 # writes, display/mode and display/resolution included), and the fixture provably left the defaults.
 var legacy_display=legacy_cfg_values(source.path_join("display-settings.cfg"))
 var display_diff=legacy_cfg_diff(legacy_display,legacy_cfg_values(target.path_join("display-settings.cfg")))
 t.check(not legacy_display.is_empty() and display_diff.is_empty(),"LEGACY legacy_source_is_the_newest_directory_with_a_readable_save: the display settings are written through their owner's save entry and the whole file reads back equal to the legacy one: differing="+str(display_diff))
 var legacy_keys=legacy_cfg_values(source.path_join("key-bindings.cfg"))
 var keys_diff=legacy_cfg_diff(legacy_keys,legacy_cfg_values(target.path_join("key-bindings.cfg")))
 t.check(not legacy_keys.is_empty() and keys_diff.is_empty(),"LEGACY legacy_source_is_the_newest_directory_with_a_readable_save: the key bindings are written through their owner's save entry and the whole file reads back equal to the legacy one: differing="+str(keys_diff))
 var defaults=legacy_cfg_defaults(root.path_join("defaults"))
 var display_defaults=Dictionary(defaults.display)
 var key_defaults=Dictionary(defaults.keys)
 var at_default=[]
 for key in display_defaults:
  if String(key)!="art/fixed_hero_portrait" and legacy_display.get(key)==display_defaults[key]: at_default.append(String(key))
 for key in key_defaults:
  if legacy_keys.get(key)==key_defaults[key]: at_default.append(String(key))
 t.check(display_defaults.size()==legacy_display.size() and key_defaults.size()==legacy_keys.size() and at_default.is_empty(),"LEGACY legacy_source_is_the_newest_directory_with_a_readable_save: the legacy fixture carries every owner key and moves each off its default (fixed_hero_portrait excepted): at_default="+str(at_default))
 var listed=legacy_marker(marker)
 t.check(int(listed.get("schema",0))==1 and listed.get("copied",[])==["saves/tower.json","saves/tower.json.bak","display-settings.cfg","key-bindings.cfg"],"LEGACY legacy_source_is_the_newest_directory_with_a_readable_save: the marker declares schema 1 and lists the four copied files: "+str(listed))

# LEGACY-2：选源按 tower.json/practice.json 的 mtime，不按目录名里的版本号。
static func legacy_source_follows_save_mtime_not_version(t) -> void:
 var ready=legacy_ready(t,"legacy_source_follows_save_mtime_not_version","legacy-mtime")
 if ready.is_empty(): return
 var module=ready.module
 var parent=String(ready.parent)
 var higher=String(ready.source)
 legacy_saves(higher.path_join("saves"),"tower",1)
 OS.delay_msec(1100)
 var lower=parent.path_join(LEGACY_NAME_PREFIX+"0.16")
 legacy_saves(lower.path_join("saves"),"tower",1)
 t.check(FileAccess.get_modified_time(lower.path_join("saves").path_join("tower.json"))>FileAccess.get_modified_time(higher.path_join("saves").path_join("tower.json")),"LEGACY legacy_source_follows_save_mtime_not_version: the fixture puts the newer save mtime on the lower version directory")
 var found=module.find_source(parent,Store.new(lower.path_join("saves")))
 t.check(String(found.get("name",""))==LEGACY_NAME_PREFIX+"0.16","LEGACY legacy_source_follows_save_mtime_not_version: the source follows the save mtime, not the version number in the name: "+str(found.get("name","")))

# LEGACY-3：目标已有任何存档（主档或 .bak）时不复制任何文件，标记记 target_not_empty。
static func legacy_never_imports_into_a_non_empty_target(t) -> void:
 var ready=legacy_ready(t,"legacy_never_imports_into_a_non_empty_target","legacy-nonempty")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var parent=String(ready.parent)
 var source=String(ready.source)
 legacy_saves(source.path_join("saves"),"tower",2)
 legacy_settings(source)
 var target=root.path_join("target")
 legacy_saves(target.path_join("saves"),"practice",1)
 var before=legacy_tree(target.path_join("saves"))
 var marker=target.path_join("legacy-import.json")
 var result=module.run(parent,target,marker,Store.new(target.path_join("saves")))
 t.check(result.get("ok",false)==true and String(result.get("code",""))=="target_not_empty","LEGACY legacy_never_imports_into_a_non_empty_target: a non empty target stops the import before any copy: "+str(result))
 t.check(legacy_tree(target.path_join("saves"))==before,"LEGACY legacy_never_imports_into_a_non_empty_target: a non empty target keeps every byte and mtime of its own saves")
 t.check(not FileAccess.file_exists(target.path_join("display-settings.cfg")) and not FileAccess.file_exists(target.path_join("key-bindings.cfg")),"LEGACY legacy_never_imports_into_a_non_empty_target: a non empty target receives no settings file")
 var listed=legacy_marker(marker)
 t.check(legacy_has_skip(listed,"*","target_not_empty") and listed.get("copied",[]).is_empty(),"LEGACY legacy_never_imports_into_a_non_empty_target: the marker records the target_not_empty skip: "+str(listed))

# LEGACY-4：标记存在即短路，不再扫描也不再复制（第二次运行不读旧目录）。
static func legacy_import_runs_only_once(t) -> void:
 var ready=legacy_ready(t,"legacy_import_runs_only_once","legacy-once")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var parent=String(ready.parent)
 var source=String(ready.source)
 legacy_saves(source.path_join("saves"),"tower",2)
 legacy_settings(source)
 var target=root.path_join("target")
 legacy_dir(target)
 var marker=target.path_join("legacy-import.json")
 var first=module.run(parent,target,marker,Store.new(target.path_join("saves")))
 t.check(String(first.get("source",""))==LEGACY_NAME_PREFIX+"0.17.1" and legacy_marker(marker).get("copied",[]).size()==4,"LEGACY legacy_import_runs_only_once: the first run imports and records the marker")
 var marker_bytes=legacy_bytes(marker)
 var copied=legacy_tree(target)
 # 把旧档改成损坏内容：标记未命中时第二次运行会重新扫描并把标记改写为 none。
 for name in ["tower.json","tower.json.bak"]:
  legacy_write(source.path_join("saves").path_join(name),"{broken")
 var second=module.run(parent,target,marker,Store.new(target.path_join("saves")))
 t.check(second.get("ok",false)==true and second.get("ran",true)==false and String(second.get("code",""))=="marker","LEGACY legacy_import_runs_only_once: a written marker short-circuits the import before any scan: "+str(second))
 t.check(legacy_bytes(marker)==marker_bytes,"LEGACY legacy_import_runs_only_once: the second run leaves the marker bytes untouched")
 t.check(legacy_tree(target)==copied,"LEGACY legacy_import_runs_only_once: the second run copies nothing")

# LEGACY-5：旧目录的字节、mtime 与文件名集合都不变。
static func legacy_leaves_every_legacy_byte_untouched(t) -> void:
 var ready=legacy_ready(t,"legacy_leaves_every_legacy_byte_untouched","legacy-readonly")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var parent=String(ready.parent)
 var source=String(ready.source)
 legacy_saves(source.path_join("saves"),"tower",2)
 legacy_saves(source.path_join("saves"),"practice",1)
 legacy_settings(source)
 var before=legacy_tree(parent)
 var target=root.path_join("target")
 legacy_dir(target)
 var result=module.run(parent,target,target.path_join("legacy-import.json"),Store.new(target.path_join("saves")))
 t.check(result.get("ok",false)==true and result.get("ran",false)==true,"LEGACY legacy_leaves_every_legacy_byte_untouched: the read only import completes: "+str(result))
 t.check(legacy_tree(parent)==before,"LEGACY legacy_leaves_every_legacy_byte_untouched: leaves every legacy byte untouched: "+str(before.size())+" file(s) compared")

# LEGACY-6：坏档与新修订号档不复制且记 invalid/version，其他文件照常复制。
static func legacy_skips_invalid_saves_and_keeps_the_rest(t) -> void:
 var ready=legacy_ready(t,"legacy_skips_invalid_saves_and_keeps_the_rest","legacy-invalid")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var parent=String(ready.parent)
 var source=String(ready.source)
 legacy_saves(source.path_join("saves"),"tower",2)
 legacy_settings(source)
 var tower=source.path_join("saves").path_join("tower.json")
 var envelope=JSON.parse_string(FileAccess.get_file_as_string(tower))
 envelope.checksum="0".repeat(64)
 legacy_write(tower,JSON.stringify(envelope))
 var target=root.path_join("target")
 legacy_dir(target)
 var marker=target.path_join("legacy-import.json")
 module.run(parent,target,marker,Store.new(target.path_join("saves")))
 var listed=legacy_marker(marker)
 t.check(legacy_has_skip(listed,"saves/tower.json","invalid") and listed.get("copied",[])==["saves/tower.json.bak","display-settings.cfg","key-bindings.cfg"],"LEGACY legacy_skips_invalid_saves_and_keeps_the_rest: a damaged save is skipped with reason invalid while the rest is copied: "+str(listed))
 t.check(not FileAccess.file_exists(target.path_join("saves").path_join("tower.json")) and legacy_same_file(source.path_join("saves").path_join("tower.json.bak"),target.path_join("saves").path_join("tower.json.bak")),"LEGACY legacy_skips_invalid_saves_and_keeps_the_rest: the damaged file never lands in the target and the valid backup does")
 var newer=root.path_join("newer")
 var newer_parent=newer.path_join("legacy")
 var newer_source=newer_parent.path_join(LEGACY_NAME_PREFIX+"0.17.2")
 legacy_dir(newer_source.path_join("saves"))
 legacy_saves(newer_source.path_join("saves"),"practice",1)
 var snapshot=Game.new(7).export_snapshot()
 snapshot.save_revision=Game.Snapshot.REVISION+1
 legacy_write(newer_source.path_join("saves").path_join("tower.json"),Store.pack(snapshot))
 var newer_target=newer.path_join("target")
 legacy_dir(newer_target)
 var newer_marker=newer_target.path_join("legacy-import.json")
 module.run(newer_parent,newer_target,newer_marker,Store.new(newer_target.path_join("saves")))
 var newer_listed=legacy_marker(newer_marker)
 t.check(legacy_has_skip(newer_listed,"saves/tower.json","version") and not FileAccess.file_exists(newer_target.path_join("saves").path_join("tower.json")),"LEGACY legacy_skips_invalid_saves_and_keeps_the_rest: a save from a newer revision is skipped with reason version and never lands: "+str(newer_listed))

# LEGACY-7：关持久化的会话与非桌面构建都不导入；替身的属主对象为 null，提前返回就不会解引用。
static func legacy_stays_off_without_persistence_or_desktop(t) -> void:
 var module=legacy_module()
 t.check(module!=null,"LEGACY legacy_stays_off_without_persistence_or_desktop: ui/legacy_import.gd exists and loads")
 if module==null: return
 t.check(module.enabled(true,true) and not module.enabled(false,true) and not module.enabled(true,false),"LEGACY legacy_stays_off_without_persistence_or_desktop: the gate needs both a persisted session and a desktop build")
 var host=LegacyImportHost.new()
 host.persistence_enabled=false
 var off_persistence=module.run_once(host,true)
 host.persistence_enabled=true
 var off_desktop=module.run_once(host,false)
 t.check(bool(off_persistence.get("ran",true))==false and String(off_persistence.get("code",""))=="disabled","LEGACY legacy_stays_off_without_persistence_or_desktop: a session without persistence never runs the import and never touches a path: "+str(off_persistence))
 t.check(bool(off_desktop.get("ran",true))==false and String(off_desktop.get("code",""))=="disabled","LEGACY legacy_stays_off_without_persistence_or_desktop: a non desktop build never runs the import (injected platform stub false): "+str(off_desktop))

# LEGACY-8：复制中断（目标已有前两份、标记未写）下次启动按 target_not_empty 收敛；
# 已落地的文件仍能经正式读档入口读回。
static func legacy_interrupted_copy_converges(t) -> void:
 var ready=legacy_ready(t,"legacy_interrupted_copy_converges","legacy-interrupted")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var parent=String(ready.parent)
 var source=String(ready.source)
 legacy_saves(source.path_join("saves"),"tower",2)
 legacy_settings(source)
 var target=root.path_join("target")
 legacy_dir(target.path_join("saves"))
 for name in ["tower.json","tower.json.bak"]:
  legacy_write(target.path_join("saves").path_join(name),legacy_bytes(source.path_join("saves").path_join(name)))
 var before=legacy_tree(target.path_join("saves"))
 var marker=target.path_join("legacy-import.json")
 t.check(not FileAccess.file_exists(marker),"LEGACY legacy_interrupted_copy_converges: the interrupted fixture has no marker yet")
 var result=module.run(parent,target,marker,Store.new(target.path_join("saves")))
 var listed=legacy_marker(marker)
 t.check(result.get("ok",false)==true and legacy_has_skip(listed,"*","target_not_empty") and listed.get("copied",[]).is_empty(),"LEGACY legacy_interrupted_copy_converges: an interrupted copy converges on target_not_empty: "+str(listed))
 t.check(legacy_tree(target.path_join("saves"))==before,"LEGACY legacy_interrupted_copy_converges: the files copied before the interruption stay byte identical")
 t.check(Store.new(target.path_join("saves")).read_slot("tower").ok,"LEGACY legacy_interrupted_copy_converges: the file copied before the interruption still reads through the formal slot entry")
 t.check(not FileAccess.file_exists(target.path_join("display-settings.cfg")),"LEGACY legacy_interrupted_copy_converges: the interrupted import writes no settings file afterwards")

# ---------------------------------------------------------------------------
# D23b 加固（A311，tmp/io-d23/d23bhard-brief.md 任务 1–3）。以下判据只经 ui/legacy_import.gd 的公开入口
# （find_source／run）与既有 SaveStore 入口观察；夹具全部在 res://build/ 下现造，不读写真实 user://，
# 也不使用玩家存档。

const LEGACY_MARKER_NAME="legacy-import.json"

# 旧目录的字节三元组：相对路径、大小、sha256。brief 要求「按文件逐个比较相对路径、大小、sha256 三元组」，
# legacy_tree 的（绝对名, mtime, hex）形状不能替代这一条。
static func legacy_triples(root: String) -> Array:
 var rows=[]
 var prefix=String(root).trim_suffix("/")+"/"
 var pending=[root]
 while not pending.is_empty():
  var current=String(pending.pop_back())
  var handle=DirAccess.open(current)
  if handle==null: continue
  for name in handle.get_files():
   var file=current.path_join(String(name))
   var bytes=FileAccess.get_file_as_bytes(file)
   rows.append(file.trim_prefix(prefix)+":"+str(bytes.size())+":"+legacy_sha256(bytes))
  for name in handle.get_directories(): pending.append(current.path_join(String(name)))
 rows.sort()
 return rows

static func legacy_sha256(bytes: PackedByteArray) -> String:
 var context=HashingContext.new()
 if context.start(HashingContext.HASH_SHA256)!=OK: return "hash-unavailable"
 context.update(bytes)
 return context.finish().hex_encode()

# 目录树的（名, mtime, 字节）快照，去掉一个顶层文件名（标记）；用来证明「除了标记，目标一个字节没动」。
static func legacy_tree_without(directory: String, name: String) -> Array:
 var head=String(directory).trim_suffix("/")+"/"+String(name)+":"
 return legacy_tree(directory).filter(func(row):return not String(row).begins_with(head))

# 一格的旧目录档：有效＝真实写入口写出的一份塔路档；损坏＝坏 JSON；修订号不兼容＝当前修订号 +1。
static func legacy_matrix_save(saves: String, state: String) -> void:
 legacy_dir(saves)
 if state=="valid":
  legacy_saves(saves,"tower",1)
 elif state=="corrupt":
  legacy_write(saves.path_join("tower.json"),"{broken")
 else:
  var snapshot=Game.new(7).export_snapshot()
  snapshot.save_revision=Game.Snapshot.REVISION+1
  legacy_write(saves.path_join("tower.json"),Store.pack(snapshot))

# 目录组合穷举的格表：旧目录 {0,1,3} × 有无 saves/ × 档 {有效, 损坏, 修订号不兼容} × 目标 {空, 非空}
# × 标记 {有, 无}；三目录的档状态混合（有效＋损坏＋不兼容）单列一行，用来证明候选只由可读档产生。
# 格与期望分开声明：期望按 §2.1 的判定顺序写死，不由被测实现推导。
static func legacy_matrix_cells() -> Array:
 var cells=[]
 for count in [0,1,3]:
  for target in ["empty","nonempty"]:
   for marker in [false,true]:
    if count==0:
     cells.append({"dirs":0,"saves":"nosaves","target":target,"marker":marker})
     continue
    var states=["nosaves","valid","corrupt","version"]
    if count==3: states.append("mixed")
    for state in states: cells.append({"dirs":count,"saves":state,"target":target,"marker":marker})
 return cells

# §2.1 的判定顺序：标记存在 → 短路；目标非空 → target_not_empty（先于扫描）；没有可读档的候选 → none；
# 有候选 → copied。copied 只列夹具里实际会落地的文件（夹具只有一个有效 tower.json）。
static func legacy_matrix_expect(cell: Dictionary) -> Dictionary:
 if bool(cell.marker): return {"code":"marker","copied":[],"skipped":[]}
 if String(cell.target)=="nonempty": return {"code":"target_not_empty","copied":[],"skipped":[{"file":"*","code":"target_not_empty"}]}
 if int(cell.dirs)<=0: return {"code":"none","copied":[],"skipped":[]}
 if String(cell.saves) in ["valid","mixed"]: return {"code":"copied","copied":["saves/tower.json"],"skipped":[]}
 return {"code":"none","copied":[],"skipped":[]}

# 任务 1：目录组合穷举。每格核结果码、是否运行、copied／skipped、标记内容、旧目录三元组不变，
# 以及目标里除标记以外的文件在「不复制」格前后相等。
static func legacy_directory_matrix_matches_the_plan(t) -> void:
 var ready=legacy_ready(t,"legacy_directory_matrix_matches_the_plan","legacy-matrix")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var cells=legacy_matrix_cells()
 for index in range(cells.size()):
  var cell=cells[index]
  var name="[dirs=%d saves=%s target=%s marker=%s]" % [int(cell.dirs),String(cell.saves),String(cell.target),"yes" if bool(cell.marker) else "no"]
  var expect=legacy_matrix_expect(cell)
  var cell_root=root.path_join("cell-%02d" % index)
  var parent=cell_root.path_join("legacy")
  var target=cell_root.path_join("target")
  var marker=target.path_join(LEGACY_MARKER_NAME)
  legacy_dir(target)
  # 三个有效候选的 mtime 必须有先后，否则「取最新」不可判；只给这一格付秒级等待，其他格不依赖顺序。
  var ordered=int(cell.dirs)==3 and String(cell.saves)=="valid" and String(cell.target)=="empty" and not bool(cell.marker)
  var names=[]
  for dir_index in range(int(cell.dirs)):
   var directory_name=LEGACY_NAME_PREFIX+("0.1%d" % dir_index)
   names.append(directory_name)
   var state=String(cell.saves)
   if state=="nosaves": legacy_dir(parent.path_join(directory_name).path_join("logs"))
   else:
    if state=="mixed": state=String(["valid","corrupt","version"][dir_index])
    legacy_matrix_save(parent.path_join(directory_name).path_join("saves"),state)
   if ordered and dir_index<2: OS.delay_msec(1100)
  var expected_source=""
  if String(expect.code)=="copied":
   # Only the valid directory is a candidate: in the mixed cell that is the first one, not the newest name.
   expected_source=String(names[0]) if String(cell.saves)=="mixed" else String(names.back())
  if String(cell.target)=="nonempty": legacy_saves(target.path_join("saves"),"practice",1)
  if bool(cell.marker): legacy_write(marker,JSON.stringify({"schema":1,"source":"kept","copied":[],"skipped":[],"at":"kept"}))
  var marker_before=legacy_bytes(marker)
  var target_before=legacy_tree_without(target,LEGACY_MARKER_NAME)
  var legacy_before=legacy_triples(parent)
  var result=module.run(parent,target,marker,Store.new(target.path_join("saves")))
  t.check(String(result.get("code",""))==String(expect.code),"LEGACY legacy_directory_matrix_matches_the_plan "+name+": the outcome code follows §2.1: "+str(result))
  t.check(bool(result.get("ran",false))==(not bool(cell.marker)),"LEGACY legacy_directory_matrix_matches_the_plan "+name+": only a missing marker lets the import run: "+str(result))
  t.check(Array(result.get("copied",[]))==expect.copied,"LEGACY legacy_directory_matrix_matches_the_plan "+name+": the copied list matches §2.1: "+str(result.get("copied",[])))
  t.check(Array(result.get("skipped",[]))==expect.skipped,"LEGACY legacy_directory_matrix_matches_the_plan "+name+": the skipped list matches §2.1: "+str(result.get("skipped",[])))
  t.check(legacy_triples(parent)==legacy_before,"LEGACY legacy_directory_matrix_matches_the_plan "+name+": the legacy directories keep their (path,size,sha256) triples")
  if bool(cell.marker):
   t.check(legacy_bytes(marker)==marker_before and legacy_tree_without(target,LEGACY_MARKER_NAME)==target_before,"LEGACY legacy_directory_matrix_matches_the_plan "+name+": an existing marker short-circuits before any write")
   continue
  var listed=legacy_marker(marker)
  t.check(int(listed.get("schema",0))==1 and String(listed.get("source",""))==expected_source,"LEGACY legacy_directory_matrix_matches_the_plan "+name+": the marker records schema 1 and the selected source: "+str(listed))
  t.check(Array(listed.get("copied",[]))==expect.copied and Array(listed.get("skipped",[]))==expect.skipped,"LEGACY legacy_directory_matrix_matches_the_plan "+name+": the marker carries the outcome lists: "+str(listed))
  if String(expect.code)=="copied":
   var identical=true
   for file in expect.copied:
    identical=identical and legacy_same_file(parent.path_join(expected_source).path_join(String(file)),target.path_join(String(file)))
   t.check(identical and Store.new(target.path_join("saves")).read_slot("tower").ok,"LEGACY legacy_directory_matrix_matches_the_plan "+name+": every copied file is byte identical and the slot reads back")
  else:
   t.check(legacy_tree_without(target,LEGACY_MARKER_NAME)==target_before,"LEGACY legacy_directory_matrix_matches_the_plan "+name+": nothing in the target changes when the plan copies nothing")

# 任务 2 崩溃点 1：`.tmp` 写完、改名之前进程退出（注入的故障状态＝与源逐字节相同的 .tmp，标记未写）。
# 再次启动时目标仍视为空，复制重试并收敛到完整复制；.tmp 被提交的档替换，不残留。
static func legacy_crash_after_temp_write_converges(t) -> void:
 var ready=legacy_ready(t,"legacy_crash_after_temp_write_converges","legacy-crash-temp")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var parent=String(ready.parent)
 var source=String(ready.source)
 legacy_saves(source.path_join("saves"),"tower",2)
 legacy_settings(source)
 var target=root.path_join("target")
 legacy_dir(target.path_join("saves"))
 legacy_write(target.path_join("saves").path_join("tower.json.tmp"),legacy_bytes(source.path_join("saves").path_join("tower.json")))
 var legacy_before=legacy_triples(parent)
 var marker=target.path_join(LEGACY_MARKER_NAME)
 var result=module.run(parent,target,marker,Store.new(target.path_join("saves")))
 var listed=legacy_marker(marker)
 t.check(String(result.get("code",""))=="copied" and listed.get("copied",[])==["saves/tower.json","saves/tower.json.bak","display-settings.cfg","key-bindings.cfg"],"LEGACY legacy_crash_after_temp_write_converges: the retry finishes the interrupted copy and records it: "+str(listed))
 t.check(not FileAccess.file_exists(target.path_join("saves").path_join("tower.json.tmp")),"LEGACY legacy_crash_after_temp_write_converges: the committed file replaces the leftover temp, so no temp survives")
 t.check(legacy_same_file(source.path_join("saves").path_join("tower.json"),target.path_join("saves").path_join("tower.json")) and legacy_same_file(source.path_join("saves").path_join("tower.json.bak"),target.path_join("saves").path_join("tower.json.bak")),"LEGACY legacy_crash_after_temp_write_converges: the two saves land byte identical to their legacy originals")
 t.check(Store.new(target.path_join("saves")).read_slot("tower").ok,"LEGACY legacy_crash_after_temp_write_converges: the recovered slot reads through the formal entry")
 t.check(legacy_triples(parent)==legacy_before,"LEGACY legacy_crash_after_temp_write_converges: the legacy directories keep their (path,size,sha256) triples")

# 任务 2 崩溃点 2：复制到一半退出（目标已有前 N 个文件、标记未写）。再次启动按 target_not_empty 收敛：
# 已落地的档不重复覆盖（字节与 mtime 都不变），仍能经 read_slot 读出，标记登记 target_not_empty。
static func legacy_crash_midway_before_marker_converges(t) -> void:
 var ready=legacy_ready(t,"legacy_crash_midway_before_marker_converges","legacy-crash-midway")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var parent=String(ready.parent)
 var source=String(ready.source)
 legacy_saves(source.path_join("saves"),"tower",2)
 legacy_settings(source)
 var legacy_before=legacy_triples(parent)
 var halfway=[["saves/tower.json"],["saves/tower.json","saves/tower.json.bak"],["saves/tower.json","saves/tower.json.bak","display-settings.cfg"]]
 for index in range(halfway.size()):
  var copied=halfway[index]
  var name="[after=%d file(s)]" % copied.size()
  var target=root.path_join("target-%d" % index)
  legacy_dir(target)
  for file in copied:
   legacy_dir(target.path_join(String(file)).get_base_dir())
   legacy_write(target.path_join(String(file)),legacy_bytes(source.path_join(String(file))))
  var marker=target.path_join(LEGACY_MARKER_NAME)
  t.check(not FileAccess.file_exists(marker),"LEGACY legacy_crash_midway_before_marker_converges "+name+": the interrupted fixture has no marker yet")
  var target_before=legacy_tree(target)
  var result=module.run(parent,target,marker,Store.new(target.path_join("saves")))
  var listed=legacy_marker(marker)
  t.check(String(result.get("code",""))=="target_not_empty" and legacy_has_skip(listed,"*","target_not_empty") and listed.get("copied",[]).is_empty(),"LEGACY legacy_crash_midway_before_marker_converges "+name+": the next start converges on target_not_empty instead of copying again: "+str(listed))
  t.check(legacy_tree_without(target,LEGACY_MARKER_NAME)==target_before,"LEGACY legacy_crash_midway_before_marker_converges "+name+": the files copied before the interruption keep their bytes and mtimes")
  t.check(Store.new(target.path_join("saves")).read_slot("tower").ok,"LEGACY legacy_crash_midway_before_marker_converges "+name+": the file copied before the interruption still reads through the formal slot entry")
  t.check(legacy_triples(parent)==legacy_before,"LEGACY legacy_crash_midway_before_marker_converges "+name+": the legacy directories keep their (path,size,sha256) triples")

# 任务 3 选源边界 1（A317 CC-D23-2′／F10）：两个候选的主档 mtime 相同时，依次比已读出存档的 saved_at、
# snapshot.save_revision，最后按目录名降序。每组构造具体的平手候选并断言契约指定的那一个；前两组两种朝向
# 都测，所以「只看目录名」与「按目录枚举顺序取第一个」都会在某个朝向上选错。
static func legacy_source_tie_is_deterministic(t) -> void:
 var ready=legacy_ready(t,"legacy_source_tie_is_deterministic","legacy-tie")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var current=int(Game.Snapshot.REVISION)
 var older=int(Game.Snapshot.IRON_DRONE_REVISION)
 var early="2026-01-01T08:00:00"
 var late="2026-01-01T09:00:00"
 var v09=LEGACY_NAME_PREFIX+"0.9"
 var v010=LEGACY_NAME_PREFIX+"0.10"
 var original=LEGACY_NAME_PREFIX+"0.17.1"
 var duplicate=LEGACY_NAME_PREFIX+"0.17.1 副本"
 var groups=[
  {"name":"saved_at decides v0.9 vs v0.10, v0.10 later","rows":[{"name":v09,"saved_at":early,"revision":current},{"name":v010,"saved_at":late,"revision":current}],"expect":v010},
  {"name":"saved_at decides v0.9 vs v0.10, v0.9 later","rows":[{"name":v09,"saved_at":late,"revision":current},{"name":v010,"saved_at":early,"revision":current}],"expect":v09},
  {"name":"save_revision decides a same saved_at, original higher","rows":[{"name":original,"saved_at":early,"revision":current},{"name":duplicate,"saved_at":early,"revision":older}],"expect":original},
  {"name":"save_revision decides a same saved_at, copy higher","rows":[{"name":original,"saved_at":early,"revision":older},{"name":duplicate,"saved_at":early,"revision":current}],"expect":duplicate},
  {"name":"directory name descending settles a full tie","rows":[{"name":LEGACY_NAME_PREFIX+"0.15","saved_at":early,"revision":current},{"name":LEGACY_NAME_PREFIX+"0.16","saved_at":early,"revision":current}],"expect":LEGACY_NAME_PREFIX+"0.16"},
 ]
 var snapshot=Game.new(7).export_snapshot()
 var reader=Store.new(root.path_join("store-never-written"))
 for index in range(groups.size()):
  var group=groups[index]
  var label=" ["+String(group.name)+"]"
  var parent=legacy_tie_parent(root.path_join("group-%d" % index),group.rows,snapshot)
  t.check(parent!="","LEGACY legacy_source_tie_is_deterministic"+label+": the fixture puts both candidate saves in the same second")
  if parent=="": continue
  var unreadable=group.rows.filter(func(row):return not reader.read_file(parent.path_join(String(row.name)).path_join("saves").path_join("tower.json")).ok)
  t.check(unreadable.is_empty(),"LEGACY legacy_source_tie_is_deterministic"+label+": both tied saves pass the store's read, so the rule and not readability decides: "+str(unreadable))
  var found=module.find_source(parent,reader)
  t.check(String(found.get("name",""))==String(group.expect),"LEGACY legacy_source_tie_is_deterministic"+label+": the tie picks the candidate the contract names: "+str(found.get("name","")))
  if index!=groups.size()-1: continue
  # The full tie also runs through two independent imports: each records and copies that same source.
  for target_index in range(2):
   var target=root.path_join("target-%d" % target_index)
   legacy_dir(target)
   var result=module.run(parent,target,target.path_join(LEGACY_MARKER_NAME),Store.new(target.path_join("saves")))
   t.check(String(result.get("source",""))==String(group.expect) and legacy_same_file(parent.path_join(String(group.expect)).path_join("saves").path_join("tower.json"),target.path_join("saves").path_join("tower.json")),"LEGACY legacy_source_tie_is_deterministic: an independent import takes the same tied source and copies its bytes: "+str(result.get("source","")))

# 平手夹具：各候选的主档在同一秒写出，saved_at 与 save_revision 按行指定（校验和只覆盖 payload 与线稿，
# 所以改 saved_at 仍能通过读档）；先打包再连续落盘，四次都没落在同一秒就返回空串。
static func legacy_tie_parent(base: String, rows: Array, snapshot: Dictionary) -> String:
 for attempt in range(4):
  var parent=base.path_join("attempt-%d" % attempt)
  var texts=[]
  for row in rows:
   var copy=snapshot.duplicate(true)
   copy.save_revision=int(row.revision)
   var envelope=JSON.parse_string(Store.pack(copy))
   envelope.saved_at=String(row.saved_at)
   texts.append(JSON.stringify(envelope))
   legacy_dir(parent.path_join(String(row.name)).path_join("saves"))
  for index in range(rows.size()):
   legacy_write(parent.path_join(String(rows[index].name)).path_join("saves").path_join("tower.json"),texts[index])
  var times=rows.map(func(row):return FileAccess.get_modified_time(parent.path_join(String(row.name)).path_join("saves").path_join("tower.json")))
  if times.all(func(time):return time==times[0]): return parent
 return ""

# 任务 3 选源边界 2：名字形如 紧缚尖塔demo v* 但没有 saves/（或 saves/ 为空、只有非存档文件）的目录
# 不是候选；有可读档的目录照样被选中。
static func legacy_source_ignores_directories_without_saves(t) -> void:
 var ready=legacy_ready(t,"legacy_source_ignores_directories_without_saves","legacy-nosaves")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var parent=String(ready.parent)
 legacy_dir(parent.path_join(LEGACY_NAME_PREFIX+"0.19.9").path_join("logs"))
 legacy_dir(parent.path_join(LEGACY_NAME_PREFIX+"0.19.8").path_join("saves"))
 legacy_dir(parent.path_join(LEGACY_NAME_PREFIX+"0.19.7").path_join("saves"))
 legacy_write(parent.path_join(LEGACY_NAME_PREFIX+"0.19.7").path_join("saves").path_join("notes.txt"),"not a save")
 var legacy_before=legacy_triples(parent)
 var target=root.path_join("target")
 legacy_dir(target)
 var marker=target.path_join(LEGACY_MARKER_NAME)
 var result=module.run(parent,target,marker,Store.new(target.path_join("saves")))
 t.check(String(result.get("code",""))=="none" and legacy_marker(marker).get("copied",[]).is_empty(),"LEGACY legacy_source_ignores_directories_without_saves: directories without a readable save never become the source: "+str(result))
 t.check(legacy_tree_without(target,LEGACY_MARKER_NAME).is_empty() and not FileAccess.file_exists(target.path_join("saves").path_join("tower.json")),"LEGACY legacy_source_ignores_directories_without_saves: no file is copied out of a directory that has no readable save")
 t.check(legacy_triples(parent)==legacy_before,"LEGACY legacy_source_ignores_directories_without_saves: the legacy directories keep their (path,size,sha256) triples")
 var readable=parent.path_join(LEGACY_NAME_PREFIX+"0.16")
 legacy_saves(readable.path_join("saves"),"tower",1)
 var with_readable=legacy_triples(parent)
 var second_target=root.path_join("target-readable")
 legacy_dir(second_target)
 var second_marker=second_target.path_join(LEGACY_MARKER_NAME)
 var second=module.run(parent,second_target,second_marker,Store.new(second_target.path_join("saves")))
 t.check(String(second.get("source",""))==LEGACY_NAME_PREFIX+"0.16" and legacy_same_file(readable.path_join("saves").path_join("tower.json"),second_target.path_join("saves").path_join("tower.json")),"LEGACY legacy_source_ignores_directories_without_saves: the only directory with a readable save is the source regardless of the other names: "+str(second))
 t.check(legacy_triples(parent)==with_readable,"LEGACY legacy_source_ignores_directories_without_saves: the second run also leaves the legacy triples untouched")

# 任务 3 选源边界 3：紧缚尖塔-dev 与新目录自身（紧缚尖塔）都不参与选源，即使它们的存档更新。
static func legacy_source_never_picks_dev_or_target_name(t) -> void:
 var ready=legacy_ready(t,"legacy_source_never_picks_dev_or_target_name","legacy-dev-self")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var parent=root.path_join("parent")
 var demo=parent.path_join(LEGACY_NAME_PREFIX+"0.17.1")
 legacy_saves(demo.path_join("saves"),"tower",1)
 # 让 -dev 与自身名字目录的存档 mtime 严格更新：前缀过滤失效时它们会赢。
 OS.delay_msec(1100)
 legacy_saves(parent.path_join("紧缚尖塔-dev").path_join("saves"),"tower",1)
 OS.delay_msec(1100)
 legacy_saves(parent.path_join("紧缚尖塔").path_join("saves"),"tower",1)
 var legacy_before=legacy_triples(parent)
 var target=root.path_join("target")
 legacy_dir(target)
 var marker=target.path_join(LEGACY_MARKER_NAME)
 var result=module.run(parent,target,marker,Store.new(target.path_join("saves")))
 t.check(String(result.get("source",""))==LEGACY_NAME_PREFIX+"0.17.1" and legacy_same_file(demo.path_join("saves").path_join("tower.json"),target.path_join("saves").path_join("tower.json")),"LEGACY legacy_source_never_picks_dev_or_target_name: the demo directory is the source even though the dev and the new-name directory hold newer saves: "+str(result))
 t.check(legacy_triples(parent)==legacy_before,"LEGACY legacy_source_never_picks_dev_or_target_name: the legacy directories keep their (path,size,sha256) triples")
 var only=root.path_join("only-dev")
 legacy_saves(only.path_join("紧缚尖塔-dev").path_join("saves"),"tower",1)
 legacy_saves(only.path_join("紧缚尖塔").path_join("saves"),"tower",1)
 var only_before=legacy_triples(only)
 var empty_target=root.path_join("target-none")
 legacy_dir(empty_target)
 var empty_marker=empty_target.path_join(LEGACY_MARKER_NAME)
 var none=module.run(only,empty_target,empty_marker,Store.new(empty_target.path_join("saves")))
 t.check(String(none.get("code",""))=="none" and legacy_marker(empty_marker).get("copied",[]).is_empty(),"LEGACY legacy_source_never_picks_dev_or_target_name: a dev or new-name directory alone is never a source: "+str(none))
 t.check(legacy_triples(only)==only_before,"LEGACY legacy_source_never_picks_dev_or_target_name: the dev and new-name directories stay untouched")

# 任务 3 选源边界 4：名字里有非 ASCII 字符或多余空格的旧目录仍按前缀匹配，来源名与复制字节逐字保真；
# 前缀内部多一个空格就不再匹配（前缀是精确的 紧缚尖塔demo v）。
static func legacy_source_accepts_non_ascii_and_spaced_names(t) -> void:
 var ready=legacy_ready(t,"legacy_source_accepts_non_ascii_and_spaced_names","legacy-names")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var cases=[
  {"parent":root.path_join("suffix"),"name":LEGACY_NAME_PREFIX+"0.17.1 副本","accepted":true},
  {"parent":root.path_join("parens"),"name":LEGACY_NAME_PREFIX+"0.18.0（旧）","accepted":true},
  {"parent":root.path_join("ideographic"),"name":LEGACY_NAME_PREFIX+"0.16"+char(0x3000),"accepted":true},
  {"parent":root.path_join("extra-space"),"name":LEGACY_NAME_PREFIX.replace(" ","  ")+"0.19","accepted":false},
 ]
 for index in range(cases.size()):
  var parent=String(cases[index].parent)
  var name=String(cases[index].name)
  var source=parent.path_join(name)
  legacy_saves(source.path_join("saves"),"tower",1)
  var legacy_before=legacy_triples(parent)
  var target=root.path_join("target-%d" % index)
  legacy_dir(target)
  var marker=target.path_join(LEGACY_MARKER_NAME)
  var result=module.run(parent,target,marker,Store.new(target.path_join("saves")))
  var listed=legacy_marker(marker)
  if bool(cases[index].accepted):
   t.check(String(result.get("source",""))==name and String(listed.get("source",""))==name,"LEGACY legacy_source_accepts_non_ascii_and_spaced_names ["+name+"]: the directory is selected and its name is recorded verbatim: "+str(listed))
   t.check(legacy_same_file(source.path_join("saves").path_join("tower.json"),target.path_join("saves").path_join("tower.json")),"LEGACY legacy_source_accepts_non_ascii_and_spaced_names ["+name+"]: the copied save stays byte identical")
  else:
   t.check(String(result.get("code",""))=="none" and listed.get("copied",[]).is_empty(),"LEGACY legacy_source_accepts_non_ascii_and_spaced_names ["+name+"]: a name with an extra space inside the prefix is not a demo directory: "+str(result))
  t.check(legacy_triples(parent)==legacy_before,"LEGACY legacy_source_accepts_non_ascii_and_spaced_names ["+name+"]: the legacy directories keep their (path,size,sha256) triples")

# ---------------------------------------------------------------------------
# D23b 返工（协调者 A317，tmp/io-d23/d23bfix-brief.md）。夹具仍只在 res://build/ 下现造；真实 user:// 只比较
# 标记的存在与 mtime，不读内容。

# 真实 user:// 标记的「存在＋mtime」指纹。
static func legacy_user_marker() -> String:
 var path="user://"+LEGACY_MARKER_NAME
 if not FileAccess.file_exists(path): return "absent"
 return "mtime="+str(FileAccess.get_modified_time(path))

# LEGACY-16（A317 F1）：生产入口 run_once 的目标目录、标记与选源父目录一律从宿主注入的 store 的存档目录
# 推导（目标＝存档目录的上一级，父目录＝目标的上一级）。store 指向 res://build/... 时，标记与复制都留在
# build 下，真实 user:// 的标记既不出现也不改变。
static func legacy_run_once_derives_paths_from_the_injected_store(t) -> void:
 var ready=legacy_ready(t,"legacy_run_once_derives_paths_from_the_injected_store","legacy-run-once")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var source=root.path_join(LEGACY_NAME_PREFIX+"0.17.1")
 legacy_saves(source.path_join("saves"),"tower",2)
 legacy_settings(source)
 var legacy_before=legacy_triples(source)
 var target=root.path_join("target")
 var host=LegacyStoreHost.new()
 host.saves=Store.new(target.path_join("saves"))
 host.display_settings=DisplaySettings.new()
 host.display_settings.path=target.path_join("display-settings.cfg")
 host.keyboard_input=LegacyKeyboardStub.new()
 host.keyboard_input.settings=KeyBindings.new()
 host.keyboard_input.settings.path=target.path_join("key-bindings.cfg")
 var user_before=legacy_user_marker()
 var result=module.run_once(host,true)
 var marker=target.path_join(LEGACY_MARKER_NAME)
 var listed=legacy_marker(marker)
 t.check(String(result.get("code",""))=="copied" and String(result.get("source",""))==LEGACY_NAME_PREFIX+"0.17.1","LEGACY legacy_run_once_derives_paths_from_the_injected_store: the production entry scans the parent of the store's target, so the sibling demo directory is the source: "+str(result))
 t.check(FileAccess.file_exists(marker) and listed.get("copied",[])==["saves/tower.json","saves/tower.json.bak","display-settings.cfg","key-bindings.cfg"],"LEGACY legacy_run_once_derives_paths_from_the_injected_store: the marker lands beside the injected store's saves directory and lists the copy: "+str(listed))
 t.check(legacy_same_file(source.path_join("saves").path_join("tower.json"),target.path_join("saves").path_join("tower.json")),"LEGACY legacy_run_once_derives_paths_from_the_injected_store: the legacy save is copied into the injected store")
 t.check(legacy_user_marker()==user_before,"LEGACY legacy_run_once_derives_paths_from_the_injected_store: the real user:// marker neither appears nor changes: before="+user_before+" after="+legacy_user_marker())
 t.check(legacy_triples(source)==legacy_before,"LEGACY legacy_run_once_derives_paths_from_the_injected_store: the legacy directory keeps its (path,size,sha256) triples")

# LEGACY-17（A317 F2）：DisplaySettings.import_from 对窗口模式与分辨率按 initialize() 的取值域读入——合法值
# 照收（含 choices() 收得下的非预设分辨率），越界或类型不符保持属主没读这一键时的取值（新实例即默认），
# 大于最大一档的分辨率按 initialize() 收到最后一档；固定立绘为真时锁池仍被关掉。
static func legacy_display_import_follows_initialize_domains(t) -> void:
 var root=legacy_root("legacy-display-domains")
 legacy_dir(root)
 var rows=[
  {"name":"legal mode and preset resolution","given":{"display/mode":2,"display/resolution":Vector2i(2560,1440)},"expect":{"display/mode":2,"display/resolution":Vector2i(2560,1440)}},
  {"name":"custom resolution inside the choices","given":{"display/resolution":Vector2i(1366,768)},"expect":{"display/mode":0,"display/resolution":Vector2i(1366,768)}},
  {"name":"out of range mode and too small resolution","given":{"display/mode":9,"display/resolution":Vector2i(100,50)},"expect":{"display/mode":0,"display/resolution":Vector2i(1440,810)}},
  {"name":"wrong value types","given":{"display/mode":"全屏","display/resolution":"1920x1080"},"expect":{"display/mode":0,"display/resolution":Vector2i(1440,810)}},
  {"name":"resolution above the largest choice","given":{"display/mode":1,"display/resolution":Vector2i(5000,3000)},"expect":{"display/mode":1,"display/resolution":Vector2i(3840,2160)}},
  {"name":"fixed portrait closes the chastity pool","given":{"art/fixed_hero_portrait":true,"gameplay/chastity_locks_enabled":true},"expect":{"art/fixed_hero_portrait":true,"gameplay/chastity_locks_enabled":false}},
 ]
 for index in range(rows.size()):
  var row=rows[index]
  var source=root.path_join("source-%d.cfg" % index)
  var config=ConfigFile.new()
  for key in row.given: config.set_value(String(key).get_slice("/",0),String(key).get_slice("/",1),row.given[key])
  config.save(source)
  var owner=DisplaySettings.new()
  owner.path=root.path_join("target-%d.cfg" % index)
  var imported=owner.import_from(source)
  var values=legacy_cfg_values(owner.path)
  var wrong=[]
  for key in row.expect:
   if not values.has(key) or values[key]!=row.expect[key]: wrong.append(String(key)+"="+str(values.get(key)))
  t.check(imported and wrong.is_empty(),"LEGACY legacy_display_import_follows_initialize_domains ["+String(row.name)+"]: the imported file holds initialize()'s verdict for every listed key: "+str(wrong))

# LEGACY-18（A317 F4）：写入失败（skipped 出现 write）不落终结标记，下一次启动重试。审查探针 S3：目标的
# saves 是普通文件，存档目录建不起来；挡路的文件移走后，下一次启动完成导入并写标记。
static func legacy_write_failure_keeps_the_import_retryable(t) -> void:
 var ready=legacy_ready(t,"legacy_write_failure_keeps_the_import_retryable","legacy-write-failure")
 if ready.is_empty(): return
 var module=ready.module
 var root=String(ready.root)
 var parent=String(ready.parent)
 var source=String(ready.source)
 legacy_saves(source.path_join("saves"),"tower",2)
 legacy_settings(source)
 var legacy_before=legacy_triples(parent)
 var target=root.path_join("target")
 legacy_dir(target)
 var blocker=target.path_join("saves")
 legacy_write(blocker,"not a directory")
 var marker=target.path_join(LEGACY_MARKER_NAME)
 var first=module.run(parent,target,marker,Store.new(blocker))
 t.check(first.get("ok",true)==false and String(first.get("code",""))=="write" and legacy_has_skip(first,"saves/tower.json","write") and legacy_has_skip(first,"saves/tower.json.bak","write"),"LEGACY legacy_write_failure_keeps_the_import_retryable: saves that cannot be written end the run as an unfinished write: "+str(first))
 t.check(not FileAccess.file_exists(marker),"LEGACY legacy_write_failure_keeps_the_import_retryable: a write failure writes no terminal marker")
 var second=module.run(parent,target,marker,Store.new(blocker))
 t.check(bool(second.get("ran",false)) and String(second.get("code",""))=="write" and not FileAccess.file_exists(marker),"LEGACY legacy_write_failure_keeps_the_import_retryable: the next start retries instead of short-circuiting on a marker: "+str(second))
 t.check(legacy_bytes(blocker)=="not a directory".to_utf8_buffer() and legacy_triples(parent)==legacy_before,"LEGACY legacy_write_failure_keeps_the_import_retryable: the retries leave the blocking file and the legacy directory untouched")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(blocker))
 var third=module.run(parent,target,marker,Store.new(blocker))
 t.check(String(third.get("code",""))=="copied" and legacy_marker(marker).get("copied",[])==["saves/tower.json","saves/tower.json.bak","display-settings.cfg","key-bindings.cfg"] and legacy_same_file(source.path_join("saves").path_join("tower.json"),target.path_join("saves").path_join("tower.json")),"LEGACY legacy_write_failure_keeps_the_import_retryable: once the blocker is gone the retry completes the import and writes the marker: "+str(third))
