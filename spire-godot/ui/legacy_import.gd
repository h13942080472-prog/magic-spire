extends RefCounted

# D23b legacy directory import (docs/spec/save-fixed-points.md「旧目录导入」).
# This is the only runtime module that opens the old install's directory. It reads the old
# saves through the caller's SaveStore (ui never preloads core), copies both slots with
# SaveStore.adopt_legacy, hands each settings file to its owner module, and only then writes
# the migration marker; nothing inside the old directory is created, renamed or deleted.
# Once the marker exists the import never scans again.
const DisplaySettings=preload("res://ui/display_settings.gd")
const KeyBindings=preload("res://ui/key_bindings.gd")

# The two UI-facing slot names, the same literals ui/main.gd and ui/home_screen.gd use; the
# authoritative list stays core/snapshot.gd::Snapshot.SLOTS, which adopt_legacy iterates.
const SLOTS=["tower","practice"]

# Only siblings named like a released demo are candidates; the -dev directory and any
# unrelated app under app_userdata never are.
const SOURCE_PREFIX="紧缚尖塔demo v"
const MARKER_NAME="legacy-import.json"
const SAVE_FILES=["tower.json","tower.json.bak","practice.json","practice.json.bak"]
const SETTING_FILES=["display-settings.cfg","key-bindings.cfg"]

# A session imports only when it persists and runs on a desktop build. Android keeps its
# package-scoped directory, and a non-persisting session (tests, tools) must not read or
# write any user path.
static func enabled(persistence_enabled: bool, desktop: bool) -> bool:
 return persistence_enabled and desktop

# Newest sibling release directory that still holds one readable save. Readability is the
# store's own verdict (SaveStore.read_file), so a corrupt or newer-revision save set never
# makes a candidate; ordering uses the newest save mtime, never the version in the name: a
# player who downgraded and played again owns the newer progress in the lower version folder.
static func find_source(parent: String, store) -> Dictionary:
 var handle=DirAccess.open(parent)
 if handle==null: return {}
 var best={}
 var best_key=-1
 for name in handle.get_directories():
  var directory=String(name)
  if not directory.begins_with(SOURCE_PREFIX): continue
  var root=parent.path_join(directory)
  var key=_source_key(root.path_join("saves"),store)
  if key<0: continue
  if key>best_key:
   best_key=key
   best={"name":directory,"path":root}
 return best

# Newest readable save mtime in the directory, or -1 when no save there passes the store's
# read: an unreadable or newer-revision save set never makes a candidate.
static func _source_key(saves: String, store) -> int:
 var key=-1
 for file in SAVE_FILES:
  var path=saves.path_join(String(file))
  if not FileAccess.file_exists(path): continue
  if not store.read_file(path).ok: continue
  key=maxi(key,FileAccess.get_modified_time(path))
 return key

# Test seam: every path and the store are parameters, and the two settings owners are fresh
# instances writing into the given target. Production goes through run_once below.
static func run(parent: String, target: String, marker: String, store) -> Dictionary:
 var display=DisplaySettings.new()
 display.path=target.path_join("display-settings.cfg")
 var keys=KeyBindings.new()
 keys.path=target.path_join("key-bindings.cfg")
 return _import(parent,target,marker,display,keys,store)

# The single production entry (ui/main.gd::_ready). The gate is decided before any user path
# is resolved, so a disabled session never resolves app_userdata at all. The save store comes
# from the host: ui never preloads core, and host.saves already points at user://saves.
static func run_once(host, desktop: bool) -> Dictionary:
 if not enabled(host.persistence_enabled,desktop):
  return {"ok":true,"ran":false,"code":"disabled","source":"","copied":[],"skipped":[]}
 var target=ProjectSettings.globalize_path("user://").replace("\\","/").trim_suffix("/")
 return _import(target.get_base_dir(),target,target.path_join(MARKER_NAME),host.display_settings,host.keyboard_input.settings,host.saves)

static func _import(parent: String, target: String, marker: String, display_settings, key_bindings, store) -> Dictionary:
 if FileAccess.file_exists(marker):
  return {"ok":true,"ran":false,"code":"marker","source":"","copied":[],"skipped":[]}
 var source=find_source(parent,store)
 if source.is_empty(): return _finish(marker,"none","",[],[])
 var name=String(source.name)
 var root=String(source.path)
 if _target_has_saves(store): return _finish(marker,"target_not_empty",name,[],[{"file":"*","code":"target_not_empty"}])
 var copied=[]
 var skipped=[]
 var adopted=store.adopt_legacy(root.path_join("saves"))
 for file in adopted.get("copied",[]): copied.append("saves/"+String(file))
 for row in adopted.get("skipped",[]): skipped.append({"file":"saves/"+String(row.get("file","")),"code":String(row.get("code","invalid"))})
 for file in SETTING_FILES:
  var path=root.path_join(String(file))
  if not FileAccess.file_exists(path): continue
  var owner=display_settings if String(file)=="display-settings.cfg" else key_bindings
  if owner==null or not owner.import_from(path): skipped.append({"file":String(file),"code":"invalid"})
  else: copied.append(String(file))
 return _finish(marker,"copied",name,copied,skipped)

static func _target_has_saves(store) -> bool:
 for slot in SLOTS:
  if store.has_files(String(slot)): return true
 return false

static func _finish(marker: String, code: String, source: String, copied: Array, skipped: Array) -> Dictionary:
 var data={"schema":1,"source":source,"copied":copied,"skipped":skipped,"at":Time.get_datetime_string_from_system(true)+"Z"}
 var written=_write_marker(marker,data)
 return {"ok":written,"ran":true,"code":code if written else "marker","source":source,"copied":copied,"skipped":skipped}

# The only write of this module; the parameter is named after the file so the architecture
# criterion can pin that the single non-READ open target is the marker itself.
static func _write_marker(marker: String, data: Dictionary) -> bool:
 var file=FileAccess.open(marker,FileAccess.WRITE)
 if file==null: return false
 file.store_string(JSON.stringify(data,"",false))
 file.flush()
 var failed=file.get_error()!=OK
 file.close()
 return not failed

static func _read_text(path: String) -> String:
 var file=FileAccess.open(path,FileAccess.READ)
 if file==null: return ""
 var text=file.get_as_text()
 file.close()
 return text
