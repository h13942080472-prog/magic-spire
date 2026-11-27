extends SceneTree

# Child-process probe for tests/update_cases.gd::engine_mounter_loads_a_real_pack. The real
# engine mount (ProjectSettings.load_resource_pack through update/boot.gd::engine_mount) turns
# res:// directory access into the pack filesystem for the rest of the process, so it must never
# run in the shared rule-suite process. This script runs it in its own engine process: it goes
# through the production entry point (Boot.start with the default mounter) and writes one JSON
# verdict to the absolute path it is given, then quits. Arguments after "--":
#   <store root as res:// path> <absolute result file>
# The mount runs synchronously on the main thread, so a hang inside the engine call also stops
# the main loop and no in-process timer could fire: the parent's timeout and OS.kill
# (tests/update_cases.gd::wait_or_reap) are the only backstop.

const STORE_PATH="res://update/update_store.gd"
const BOOT_PATH="res://update/boot.gd"
const MARKER="res://update_boot_probe/marker.txt"

func _initialize() -> void:
 var arguments=OS.get_cmdline_user_args()
 if arguments.size()!=2:
  push_error("mount_probe: expected <store root> <result file>")
  quit(2)
  return
 var Store=load(STORE_PATH)
 var Boot=load(BOOT_PATH)
 var store=Store.new(arguments[0])
 var before=FileAccess.file_exists(MARKER)
 var result=Boot.start(store,Callable(),true)
 var verdict={"marker_before":before,"mounted":String(result.get("mounted","")),"marker_after":FileAccess.file_exists(MARKER)}
 if verdict.marker_after: verdict["content"]=FileAccess.get_file_as_string(MARKER)
 var handle=FileAccess.open(arguments[1],FileAccess.WRITE)
 if handle==null:
  push_error("mount_probe: cannot write the result file")
  quit(4)
  return
 handle.store_string(JSON.stringify(verdict))
 handle.close()
 quit(0)
