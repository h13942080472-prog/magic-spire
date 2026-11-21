extends RefCounted

# D23b legacy directory import (docs/spec/save-fixed-points.md「旧目录导入」).
# This is the only runtime module that opens the old install's directory. It reads the
# old saves with FileAccess.READ, copies both slots through SaveStore.adopt_legacy,
# hands each settings file to its owner module, and only then writes the migration
# marker; nothing inside the old directory is created, renamed, rewritten or deleted.
# Once the marker exists the import never scans again.
const Store=preload("res://core/save_store.gd")
const Snapshot=preload("res://core/snapshot.gd")
const DisplaySettings=preload("res://ui/display_settings.gd")
const KeyBindings=preload("res://ui/key_bindings.gd")

# Only siblings named like a released demo are candidates; the -dev directory and any
# unrelated app under app_userdata never are.
const SOURCE_PREFIX="紧缚尖塔demo v"
const MARKER_NAME="legacy-import.json"
const SAVE_FILES=["tower.json","tower.json.bak","practice.json","practice.json.bak"]
const SETTING_FILES=["display-settings.cfg","key-bindings.cfg"]

# A session imports only when it persists and runs on a desktop build. Android keeps
# its package-scoped directory, and a non-persisting session (tests, tools) must not
# read or write any user path.
static func enabled(persistence_enabled: bool, desktop: bool) -> bool:
 return persistence_enabled and desktop

# Newest sibling release directory that still holds one save passing SaveStore.unpack.
# Ordering uses the newest save mtime (tower.json or practice.json), never the version
# number inside the directory name: a player who downgraded and played again owns the
# newer progress in the lower version directory.
static func find_source(parent: String) -> Dictionary:
 var handle=DirAccess.open(parent)
 if handle==null: return {}
 var best={}
 var best_key=-1
 for name in handle.get_directories():
  var directory=String(name)
  if not directory.begins_with(SOURCE_PREFIX): continue
  var root=parent.path_join(directory)
  var saves=root.path_join("saves")
  var key=_source_key(saves)
  if key<0: continue
  if key>best_key:
   best_key=key
   best={"name":directory,"path":root}
 return best

# Newest save mtime in the directory, or -1 when no save there passes unpack(): an
# unreadable or newer-revision save set never makes a candidate.
static func _source_key(saves: String) -> int:
 var key=-1
 for file in SAVE_FILES:
  var path=saves.path_join(String(file))
  if not FileAccess.file_exists(path): continue
  if not Store.unpack(_read_text(path)).ok: continue
  key=maxi(key,FileAccess.get_modified_time(path))
 return key

# Test seam: every path is a parameter, and the two settings owners are fresh instances
# writing into the given target. Production goes through run_once below.
static func run(parent: String, target: String, marker: String) -> Dictionary:
 var display=DisplaySettings.new()
 display.path=target.path_join("display-settings.cfg")
 var keys=KeyBindings.new()
 keys.path=target.path_join("key-bindings.cfg")
 return _import(parent,target,marker,display,keys)

# The single production entry (ui/main.gd::_ready). The gate is decided before any user
# path is resolved, so a disabled session never resolves app_userdata at all.
static func run_once(host, desktop: bool) -> Dictionary:
 if not enabled(host.persistence_enabled,desktop):
  return {"ok":true,"ran":false,"reason":"disabled","source":"","copied":[],"skipped":[]}
 var target=ProjectSettings.globalize_path("user://").replace("\\","/").trim_suffix("/")
 return _import(target.get_base_dir(),target,target.path_join(MARKER_NAME),host.display_settings,host.keyboard_input.settings)

static func _import(parent: String, target: String, marker: String, display_settings, key_bindings) -> Dictionary:
 if FileAccess.file_exists(marker):
  return {"ok":true,"ran":false,"reason":"marker","source":"","copied":[],"skipped":[]}
 var source=find_source(parent)
 if source.is_empty(): return _finish(marker,"none","",[],[])
 var name=String(source.name)
 var root=String(source.path)
 var store=Store.new(target.path_join("saves"))
 if _target_has_saves(store): return _finish(marker,"target_not_empty",name,[],[{"file":"*","reason":"target_not_empty"}])
 var copied=[]
 var skipped=[]
 var adopted=store.adopt_legacy(root.path_join("saves"))
 for file in adopted.get("copied",[]): copied.append("saves/"+String(file))
 for row in adopted.get("skipped",[]): skipped.append({"file":"saves/"+String(row.get("file","")),"reason":String(row.get("reason","invalid"))})
 for file in SETTING_FILES:
  var path=root.path_join(String(file))
  if not FileAccess.file_exists(path): continue
  var owner=display_settings if String(file)=="display-settings.cfg" else key_bindings
  if owner==null or not owner.import_from(path): skipped.append({"file":String(file),"reason":"invalid"})
  else: copied.append(String(file))
 return _finish(marker,"copied",name,copied,skipped)

static func _target_has_saves(store) -> bool:
 for slot in Snapshot.SLOTS:
  if store.has_files(String(slot)): return true
 return false

static func _finish(marker: String, reason: String, source: String, copied: Array, skipped: Array) -> Dictionary:
 var data={"schema":1,"source":source,"copied":copied,"skipped":skipped,"at":Time.get_datetime_string_from_system(true)+"Z"}
 var written=_write_marker(marker,data)
 return {"ok":written,"ran":true,"reason":reason if written else "marker","source":source,"copied":copied,"skipped":skipped}

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
