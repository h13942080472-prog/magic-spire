extends Node

# docs/spec/update-check.md「引导挂载与版本身份」: the boot scene (run/main_scene) is the only place a
# patch pack is mounted. It runs before ui/main.gd loads, because a pack mounted after the game
# scripts are cached cannot replace them. It preloads the boot closure only (the store and the
# judgement module): everything under ui/, core/ and data/ is reached through the scene path
# below, after the mount, so the mounted pack can replace those scripts. The closure itself is
# loaded before the mount and is therefore never replaced by a patch; a defect in it ships as a
# full package.
#
# The answer is a dictionary: {"ran": bool, "mounted": String}. "ran" is false outside a
# player session (a scripted run, or a platform without patch mounting); "mounted" is the version
# the engine accepted, or "" when the baseline runs.

const Store=preload("res://update/update_store.gd")
const Manifest=preload("res://update/update_manifest.gd")
const MAIN_SCENE="res://main.tscn"

func _ready() -> void:
 # A scripted run (a test that instantiates this scene) must stay inert: no mount, no scene change.
 if Store.scripted_run(): return
 start(Store.new())
 get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)

# The default mounter: the engine call, with replace_files so the pack overrides res:// paths.
static func engine_mount(path: String) -> bool:
 return ProjectSettings.load_resource_pack(path,true)

# The one mount sequence. `store` is the injected state owner, `mounter` the engine call (a valid
# Callable replaces it for a recorder), `session` forces the session kind (null = ask the store).
static func start(store, mounter: Callable=Callable(), session: Variant=null) -> Dictionary:
 var live=Store.player_session() if session==null else bool(session)
 if not live: return {"ran":false,"mounted":""}
 var mount=mounter if mounter.is_valid() else engine_mount
 var baseline=Store.baseline_version()
 store.clear_staging()
 var state=store.load_state()
 # The recorded patches belong to another baseline (a full package was installed over this one).
 if state.from!=baseline and not Store.is_blank(state):
  store.reset_for_baseline()
  return {"ran":true,"mounted":""}
 # A marker that was never cleared means the last start of that version did not prove itself.
 if not String(state.mounting).is_empty():
  store.mark_failed(state.mounting)
  state=store.load_state()
 for slot in ["pending","active"]:
  var entry=state.get(slot,{})
  if entry.is_empty(): continue
  var to=String(entry.to)
  var path=store.patch_path(to)
  if to in state.failed or not Manifest.is_newer(to,baseline) or not Manifest.verify_patch_file(path,int(entry.bytes),String(entry.sha256)):
   store.mark_failed(to)
   continue
  if not store.begin_mount(to): continue
  if not mount.call(path):
   store.mark_failed(to)
   continue
  Store.record_mounted(to)
  print_verbose("update boot: mounted "+to)
  return {"ran":true,"mounted":to}
 return {"ran":true,"mounted":""}
