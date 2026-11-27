extends SceneTree

# Child-process probe for tests/update_cases.gd::engine_mounter_loads_a_real_pack. The real
# engine mount (ProjectSettings.load_resource_pack through update/boot.gd::engine_mount) turns
# res:// directory access into the pack filesystem for the rest of the process, so it must never
# run in the shared rule-suite process. This script runs it in its own engine process: it goes
# through the production entry point (Boot.start with the default mounter) and writes one JSON
# verdict to the absolute path it is given, then quits. Arguments after "--":
#   <store root as res:// path> <absolute result file>
# The parent owns the timeout and kills this process if it does not exit; the timer below is
# only a backstop for a hang inside the engine call. BACKSTOP_SECONDS must stay shorter than the
# parent's tests/update_cases.gd::MOUNT_LIMIT_MSEC, so a hung child quits on its own before the parent kills it.

const STORE_PATH="res://update/update_store.gd"
const BOOT_PATH="res://update/boot.gd"
const MARKER="res://update_boot_probe/marker.txt"
const BACKSTOP_SECONDS=40.0

func _initialize() -> void:
 var arguments=OS.get_cmdline_user_args()
 if arguments.size()!=2:
  push_error("mount_probe: expected <store root> <result file>")
  quit(2)
  return
 create_timer(BACKSTOP_SECONDS).timeout.connect(func(): quit(3))
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
