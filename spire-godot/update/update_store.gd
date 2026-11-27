extends RefCounted

# docs/spec/update-check.md「引导挂载与版本身份」: the only owner of the update directory in the user
# data (state, patch packs, partial downloads) and the only reader of the project's version setting.
# It is a leaf of update/ like its siblings: it never references ui, core, data or tests, and the
# directory is injected (`Store.new(directory)`) so a suite can point it at a temporary tree.
#
# Two versions are kept apart on purpose:
#  - the baseline is what the executable and its main pack are (the project setting, read by
#    baseline_version only);
#  - the effective version is what this process actually runs: the patch that boot.gd mounted
#    successfully, else the baseline. It lives in process memory (record_mounted writes it,
#    effective_version reads it), never in state.json: "recorded" is not "mounted".

const Manifest=preload("res://update/update_manifest.gd")

const ROOT="user://updates"
const STATE_FILE="state.json"
const PATCHES="patches"
const STAGING="staging"
const PATCH_SUFFIX=".pck"
# Process-level storage of the effective version: the Engine singleton lives as long as the
# process, so it outlives the boot scene and any script cache that is dropped with it.
const EFFECTIVE_KEY="update_store_effective_version"

var root: String

func _init(directory: String=ROOT) -> void:
 root=directory

# ---- version identity -----------------------------------------------------------------

# The one reader of the project's version setting: the baseline of the running executable.
static func baseline_version() -> String:
 return str(ProjectSettings.get_setting("application/config/version",""))

# The version this process runs. Reading it never touches the disk.
static func effective_version() -> String:
 return str(Engine.get_meta(EFFECTIVE_KEY,baseline_version()))

# The one writer of the effective version; boot.gd calls it after the engine accepted the pack.
# An empty version forgets the mount (the baseline is effective again).
static func record_mounted(to: String) -> void:
 if to.is_empty():
  if Engine.has_meta(EFFECTIVE_KEY): Engine.remove_meta(EFFECTIVE_KEY)
  return
 if valid_version(to): Engine.set_meta(EFFECTIVE_KEY,to)

# What a patch must match to apply to this install, in the shape UpdateManifest consumes.
func identity() -> Dictionary:
 return {"baseline":baseline_version(),"failed":load_state().failed}

# ---- session kind ---------------------------------------------------------------------

# An engine run started with --script is a harness, a probe or a tool, not a player session.
static func scripted_run() -> bool:
 return OS.get_cmdline_args().has("--script")

# Patch mounting exists on desktop only (the release channel for Android is a full package).
static func player_session() -> bool:
 return OS.has_feature("pc") and not scripted_run()

# ---- state ----------------------------------------------------------------------------

# A version becomes a file name, so every version read from disk passes this grammar before a
# path is built: two to four decimal segments, optionally followed by ".fix" (the grammar of
# tools/package.ps1 with one more numeric segment).
static func valid_version(value: Variant) -> bool:
 if not value is String: return false
 var parts=String(value).split(".")
 if parts.size()>0 and parts[parts.size()-1]=="fix": parts.remove_at(parts.size()-1)
 if parts.size()<2 or parts.size()>4: return false
 for part in parts:
  if part.is_empty() or part.length()>9: return false
  for index in part.length():
   if part[index]<"0" or part[index]>"9": return false
 return true

static func empty_state() -> Dictionary:
 return {"from":"","active":{},"pending":{},"mounting":"","failed":[]}

static func is_blank(state: Dictionary) -> bool:
 return state.active.is_empty() and state.pending.is_empty() and String(state.mounting).is_empty() and state.failed.is_empty()

# The only reader of state.json. A missing, unparsable or hostile document yields the empty
# state; every field is validated, so callers never see a version that is not a legal file name.
func load_state() -> Dictionary:
 var path=root.path_join(STATE_FILE)
 if not FileAccess.file_exists(path): return empty_state()
 return _clean(Manifest.document(FileAccess.get_file_as_bytes(path)))

# One entry of the state: {to, bytes, sha256} or {} when any field is not legal.
static func _entry(value: Variant) -> Dictionary:
 if not value is Dictionary: return {}
 var to=value.get("to","")
 var bytes=value.get("bytes",0)
 var sha=value.get("sha256","")
 if not valid_version(to) or not (bytes is int or bytes is float) or float(bytes)<=0.0 or float(bytes)!=floor(float(bytes)): return {}
 if not sha is String or not Manifest.is_sha256(sha): return {}
 return {"to":to,"bytes":int(bytes),"sha256":sha}

static func _clean(document: Variant) -> Dictionary:
 var state=empty_state()
 if not document is Dictionary: return state
 if valid_version(document.get("from","")): state.from=document.from
 state.active=_entry(document.get("active",{}))
 state.pending=_entry(document.get("pending",{}))
 if valid_version(document.get("mounting","")): state.mounting=document.mounting
 var failed=document.get("failed",[])
 if failed is Array:
  for item in failed:
   if valid_version(item) and item not in state.failed: state.failed.append(item)
 return state

# The only writer of state.json: temp file, read-back, rename. The document is rebuilt from the
# validated fields, so an invalid entry is never persisted.
func write_state(state: Dictionary) -> bool:
 if not _ensure(root): return false
 var bytes=JSON.stringify(_clean(state)).to_utf8_buffer()
 var path=root.path_join(STATE_FILE)
 var temp=path+".tmp"
 var file=FileAccess.open(temp,FileAccess.WRITE)
 if file==null: return false
 file.store_buffer(bytes)
 file.flush()
 var failed=file.get_error()!=OK
 file.close()
 if failed or FileAccess.get_file_as_bytes(temp)!=bytes: return false
 return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),ProjectSettings.globalize_path(path))==OK

# ---- patch files ----------------------------------------------------------------------

# patches/<to>.pck, or "" when `to` is not a legal version: the only place a version becomes a path.
func patch_path(to: String) -> String:
 if not valid_version(to): return ""
 return root.path_join(PATCHES).path_join(to+PATCH_SUFFIX)

# Records `to` as failed, drops every entry that names it and deletes its pack. Idempotent.
func mark_failed(to: String) -> void:
 var state=load_state()
 if valid_version(to) and to not in state.failed: state.failed.append(to)
 for slot in ["active","pending"]:
  if String(state[slot].get("to",""))==to: state[slot]={}
 if String(state.mounting)==to: state.mounting=""
 var path=patch_path(to)
 if not path.is_empty() and FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 write_state(state)

# Persists the marker that says "this version is being tried". A false answer means the marker
# could not be written, and the caller must not mount without it.
func begin_mount(to: String) -> bool:
 if not valid_version(to): return false
 var state=load_state()
 state.mounting=to
 return write_state(state)

# The session proved itself (the host finished its startup restore): clear the marker, promote a
# pending patch that this process really mounted, and delete every pack that no entry names.
func mark_boot_succeeded() -> void:
 var state=load_state()
 var changed=false
 if not String(state.mounting).is_empty():
  state.mounting=""
  changed=true
 if not state.pending.is_empty() and String(state.pending.to)==effective_version():
  state.active=state.pending
  state.pending={}
  changed=true
 if changed: write_state(state)
 var keep=[]
 for slot in ["active","pending"]:
  if not state[slot].is_empty(): keep.append(String(state[slot].to)+PATCH_SUFFIX)
 for name in _files(root.path_join(PATCHES)):
  if name not in keep: DirAccess.remove_absolute(ProjectSettings.globalize_path(root.path_join(PATCHES).path_join(name)))

# The install is another baseline than the one the state was recorded for: drop every pack and
# the whole state, and record the new baseline.
func reset_for_baseline() -> void:
 for folder in [PATCHES,STAGING]:
  for name in _files(root.path_join(folder)):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(root.path_join(folder).path_join(name)))
 var state=empty_state()
 state.from=baseline_version()
 write_state(state)

# Partial downloads never survive a start.
func clear_staging() -> void:
 for name in _files(root.path_join(STAGING)):
  DirAccess.remove_absolute(ProjectSettings.globalize_path(root.path_join(STAGING).path_join(name)))

static func _files(directory: String) -> Array:
 var names=[]
 var handle=DirAccess.open(directory)
 if handle==null: return names
 for name in handle.get_files(): names.append(String(name))
 return names

static func _ensure(directory: String) -> bool:
 return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))==OK
