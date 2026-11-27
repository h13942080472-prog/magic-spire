extends RefCounted

# Legacy directory import (docs/spec/save-fixed-points.md「旧目录导入」).
# This is the only runtime module that opens the old install's directory. It reads the old
# saves through the caller's SaveStore (ui never preloads core), copies both slots with
# SaveStore.adopt_legacy, hands each settings file to its owner module, and only then commits
# the migration marker through the same store's atomic commit (SaveStore.commit_file); nothing
# inside the old directory is created, renamed or deleted. Once the marker exists the import
# never scans again.
const DisplaySettings=preload("res://ui/display_settings.gd")
const KeyBindings=preload("res://ui/key_bindings.gd")

# The two UI-facing slot names, the same literals ui/main.gd and ui/home_screen.gd use; the
# authoritative list stays core/snapshot.gd::Snapshot.SLOTS, which adopt_legacy iterates. The
# save file names are derived from this list, so a slot is named once in this module.
const SLOTS=["tower","practice"]

# Only siblings named like a released demo are candidates; the -dev directory and any
# unrelated app under app_userdata never are.
const SOURCE_PREFIX="紧缚尖塔demo v"
const MARKER_NAME="legacy-import.json"

# A session imports only when it persists and runs on a desktop build. Android keeps its
# package-scoped directory, and a non-persisting session (tests, tools) must not read or
# write any user path.
static func enabled(persistence_enabled: bool, desktop: bool) -> bool:
 return persistence_enabled and desktop

# Newest sibling release directory that still holds one readable save. Readability is the
# store's own verdict (SaveStore.read_file), so a corrupt or newer-revision save set never
# makes a candidate. Ordering uses the readable primary saves only (tower.json, practice.json;
# a .bak never ranks a directory), never the version in the name: a player who downgraded and
# played again owns the newer progress in the lower version folder. Directories compare by
# _source_rank plus their name, so a tie on mtime falls to the read save's saved_at, then its
# snapshot.save_revision, then the directory name in descending order, and the choice never
# depends on the order the file system lists the directories in.
# Returns {name, path} of that directory, or {} when the parent opens but holds no candidate (the
# none verdict). A parent that cannot be opened returns {"code":"scan"}: an IO failure, not a
# verdict (in production the parent is app_userdata, which holds the user directory itself).
static func find_source(parent: String, store) -> Dictionary:
 var handle=DirAccess.open(parent)
 if handle==null: return {"code":"scan"}
 var best={}
 var best_rank=[]
 for name in handle.get_directories():
  var directory=String(name)
  if not directory.begins_with(SOURCE_PREFIX): continue
  var root=parent.path_join(directory)
  var rank=_source_rank(root.path_join("saves"),store)
  if rank.is_empty(): continue
  rank.append(directory)
  if best_rank.is_empty() or _outranks(rank,best_rank):
   best_rank=rank
   best={"name":directory,"path":root}
 return best

# [mtime, saved_at, save_revision] of the directory's best readable primary save; a directory
# whose only readable files are .bak copies ranks [-1,"",-1], below every readable primary, and
# a directory with no readable save at all returns [] (not a candidate). The read that proves a
# primary readable also supplies its saved_at and revision, so no save is unpacked twice.
static func _source_rank(saves: String, store) -> Array:
 var best=[]
 var backup_only=false
 for slot in SLOTS:
  var primary=saves.path_join(String(slot)+".json")
  var read=store.read_file(primary)
  if read.ok:
   var rank=[FileAccess.get_modified_time(primary),String(read.get("saved_at","")),int(read.snapshot.get("save_revision",-1))]
   if best.is_empty() or _outranks(rank,best): best=rank
  elif store.read_file(primary+".bak").ok:
   backup_only=true
 if best.is_empty() and backup_only: return [-1,"",-1]
 return best

# Element-wise order: the first differing element decides and the larger one ranks higher.
static func _outranks(left: Array, right: Array) -> bool:
 for index in range(mini(left.size(),right.size())):
  if left[index]!=right[index]: return left[index]>right[index]
 return false

# Test seam: every path and the store are parameters, and the two settings owners are fresh
# instances writing into the given target. Production goes through run_once below.
static func run(parent: String, target: String, marker: String, store) -> Dictionary:
 var display=DisplaySettings.new()
 display.path=target.path_join("display-settings.cfg")
 var keys=KeyBindings.new()
 keys.path=target.path_join("key-bindings.cfg")
 return _import(parent,marker,display,keys,store)

# The single production entry (ui/main.gd::_ready). The gate is decided before any user path
# is resolved, so a disabled session never resolves a path at all. Every path comes from the
# host's injected save store (ui never preloads core): the target is the parent of the store's
# saves directory, the marker sits in the target and the scanned parent is the target's parent.
# In production host.saves is user://saves, so the target is the user directory and the parent
# is app_userdata; a test store under res://build/ keeps the marker and every copy under build.
static func run_once(host, desktop: bool) -> Dictionary:
 if not enabled(host.persistence_enabled,desktop):
  return _answer(true,false,"disabled","",[],[])
 var target=ProjectSettings.globalize_path(String(host.saves.directory)).replace("\\","/").trim_suffix("/").get_base_dir()
 var parent=target.get_base_dir()
 if OS.has_feature("linux") and String(host.saves.directory)=="user://saves":
  var legacy_parent=OS.get_data_dir().path_join("godot/app_userdata")
  if DirAccess.dir_exists_absolute(legacy_parent): parent=legacy_parent
 return _import(parent,target.path_join(MARKER_NAME),host.display_settings,host.keyboard_input.settings,host.saves)

static func _import(parent: String, marker: String, display_settings, key_bindings, store) -> Dictionary:
 if FileAccess.file_exists(marker):
  return _answer(true,false,"marker","",[],[])
 # The target guard runs before any scan (docs/spec/save-fixed-points.md legacy import section: the
 # decision order is marker -> target -> source). A session that already owns a save must not
 # enumerate the sibling directories, and its marker still reports target_not_empty with no source.
 if _target_has_saves(store): return _finish_import(marker,"target_not_empty","",[],[{"file":"*","code":"target_not_empty"}],store)
 var found=find_source(parent,store)
 if found.is_empty(): return _finish_import(marker,"none","",[],[],store)
 # A parent that cannot be opened ends the run like a write failure below: unfinished, with no
 # terminal marker, so the next start scans again instead of short-circuiting on a false none.
 if found.has("code"): return _answer(false,true,String(found.code),"",[],[])
 var source_name=String(found.name)
 var source_root=String(found.path)
 var copied=[]
 var skipped=[]
 var adopted=store.adopt_legacy(source_root.path_join("saves"))
 for file in adopted.get("copied",[]): copied.append("saves/"+String(file))
 for row in adopted.get("skipped",[]): skipped.append({"file":"saves/"+String(row.get("file","")),"code":String(row.get("code","invalid"))})
 # A write failure leaves the import unfinished: no terminal marker, so the next start retries. The
 # marker only closes a finished copy or a validation verdict (invalid, version, target_not_empty, none);
 # the two IO failures, scan and write, never close it.
 if skipped.any(func(row):return String(row.code)=="write"): return _answer(false,true,"write",source_name,copied,skipped)
 # Each settings file is validated and written by its owner module; a file the owner rejects is
 # recorded as invalid instead of blocking the save copy. The table keeps the file-to-owner
 # mapping in one place.
 for entry in [{"file":"display-settings.cfg","owner":display_settings},{"file":"key-bindings.cfg","owner":key_bindings}]:
  var path=source_root.path_join(String(entry.file))
  if not FileAccess.file_exists(path): continue
  var owner=entry.owner
  if owner!=null and FileAccess.file_exists(owner.path):
   skipped.append({"file":String(entry.file),"code":"target_not_empty"})
  elif owner==null or not owner.import_from(path):
   var write_failed=owner!=null and (owner.save_error!="" if owner==display_settings else owner.error!="")
   skipped.append({"file":String(entry.file),"code":"write" if write_failed else "invalid"})
   if write_failed: return _answer(false,true,"write",source_name,copied,skipped)
  else: copied.append(String(entry.file))
 return _finish_import(marker,"copied",source_name,copied,skipped,store)

# True when the target already holds a primary or .bak for any slot: copying into it would mix
# two playthroughs, so a non-empty target stops the import before any write.
static func _target_has_saves(store) -> bool:
 for slot in SLOTS:
  if store.has_files(String(slot)): return true
 return false

# Every answer of this module has the same six keys; callers and the marker read one shape.
static func _answer(ok: bool, ran: bool, code: String, source: String, copied: Array, skipped: Array) -> Dictionary:
 return {"ok":ok,"ran":ran,"code":code,"source":source,"copied":copied,"skipped":skipped}

# Import outcome plus the marker write: the marker is the only write this module asks for, and it
# is committed last so an interrupted copy is retried (converging on target_not_empty) instead of
# looking finished.
static func _finish_import(marker: String, code: String, source: String, copied: Array, skipped: Array, store) -> Dictionary:
 var data={"schema":1,"source":source,"copied":copied,"skipped":skipped,"at":Time.get_datetime_string_from_system(true)+"Z"}
 var written=_write_marker(marker,data,store)
 return _answer(written,true,code if written else "marker",source,copied,skipped)

# The marker goes through the store's atomic commit (.tmp, read back byte for byte, rename), so a
# crash never leaves a truncated marker that would short-circuit every later start. The parameter
# is named after the file so the architecture criterion can pin the commit's only target.
static func _write_marker(marker: String, data: Dictionary, store) -> bool:
 var bytes=JSON.stringify(data,"",false).to_utf8_buffer()
 return store.commit_file(marker,bytes,func(temp):return FileAccess.get_file_as_bytes(temp)==bytes)==""
