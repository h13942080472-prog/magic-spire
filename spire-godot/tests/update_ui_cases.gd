extends RefCounted

# docs/spec/update-check.md「界面判据」: the home notice, both jump buttons and the startup
# switch are driven through the production main.tscn. The suite installs the transport
# stand-in and its own key before the scene enters the tree; the judgement stays in
# UpdateManifest (tests/update_cases.gd), this file only asserts what the player sees.
#
# A scripted harness never auto-checks (update/update_check.gd::auto_allowed), so the suite
# calls check() itself — the same entry the deferred startup call uses in a player session.

const Cases=preload("res://tests/update_cases.gd")
const Palette=preload("res://ui/visual_theme.gd")
const Click=preload("res://tests/interface_ui_cases.gd")
# The static configuration reader is called through the class, not an instance.
const Check=preload("res://update/update_check.gd")
const RunningStore=preload("res://update/update_store.gd")

static func run(t) -> void:
 await startup_offer_renders_notice(t)
 await startup_offline_is_silent(t)
 await startup_bad_signature_is_silent(t)
 await toggle_off_skips_startup(t)
 await check_in_flight_keeps_home_interactive(t)
 await transport_failures_are_silent(t)
 await check_in_flight_ignores_second_call(t)
 await empty_manifest_url_sends_no_request(t)
 await host_free_releases_unparented_check(t)
 await mounted_version_reaches_title_and_report(t)
 await unmounted_patch_reports_baseline(t)
 await start_marks_boot_succeeded(t)

# ---- fixtures -------------------------------------------------------------------------

# One harness shape for every case: request log, launch recorder, the stand-in answer and the
# key table that verifies it. "response" is either a served manifest or {"failure": result}.
static func harness(served: Dictionary, prefs: String="") -> Dictionary:
 var options={"calls":[],"opened":[],"response":served,"keys":served.get("keys",{})}
 if not prefs.is_empty(): options["prefs"]=prefs
 return options

# The notice prints the fixture size in MB; the expected text derives from the same fixture
# constant the manifest is built with, so the expectation cannot drift from the fixture.
static func size_text() -> String:
 return "%.1f" % (float(Cases.SIZE)/1048576.0)

# The running build's version comes from the production reader (Store.effective_version), and the
# "newer" version is derived from it by appending a ".1" segment: UpdateManifest.compare treats
# a missing segment as numeric 0, so the extra non-zero numeric segment always ranks higher,
# whatever the build number is, including a text last segment such as "0.18.3.fix". A literal
# would stop being an update the day the project version is bumped upstream, and the notice
# cases would fail without any product defect.
static func newer_version() -> String:
 return RunningStore.effective_version()+".1"

static func signed(version: String, other_signature: bool=false) -> Dictionary:
 var pair=Cases.keypair()
 var body=Cases.bytes_of(Cases.document(version))
 var payload="another manifest".to_utf8_buffer() if other_signature else body
 return {"manifest":body,"signature":Cases.signature_of(payload,pair),"keys":{"k1":Cases.verifier_pem(pair)}}

# The stand-in answers the two GETs and reads options.response on every call, so one boot can
# serve a second answer after the player asks again.
static func stand_in(ui, options: Dictionary) -> Callable:
 return func(url: String, _method: int) -> int:
  options.calls.append(url)
  var response=options.get("response",{})
  if response.has("failure"):
   ui.update_check.deliver(int(response.failure),0,PackedStringArray(),PackedByteArray())
  elif url.ends_with(".sig"):
   ui.update_check.deliver(HTTPRequest.RESULT_SUCCESS,int(response.get("status",200)),PackedStringArray(),response.get("signature",PackedByteArray()))
  else:
   ui.update_check.deliver(HTTPRequest.RESULT_SUCCESS,int(response.get("status",200)),PackedStringArray(),response.get("manifest",PackedByteArray()))
  return OK

static func boot(t, options: Dictionary) -> Control:
 var old=t.ui
 if is_instance_valid(old):
  t.root.remove_child(old);old.queue_free()
 var ui=load("res://main.tscn").instantiate()
 # The harness never touches the real user:// save store; the settings store keeps its own
 # temp path and is switched on by the case that needs to write (see toggle_off_skips_startup).
 ui.persistence_enabled=false
 ui.feedback_duration=0.04
 ui.game_factory=preload("res://tests/game_fixture.gd")
 ui.game=ui.game_factory.new()
 ui.display_settings.path=String(options.get("prefs",Cases.prefs_path()))
 ui.display_settings.first_battle_tutorial_seen=true
 ui.open_url=func(url): options.opened.append(url)
 ui.update_check.keys=options.get("keys",{})
 ui.update_check.transport=stand_in(ui,options)
 # A case that asserts the startup proof injects its own store; every other case keeps the
 # default, which a scripted run never writes (ui/main.gd only builds it in a player session).
 if options.has("store"): ui.update_store=options.store
 options["state"]=JSON.stringify(ui.game.state)
 t.ui=ui
 t.root.add_child(ui)
 await t.frames()
 return ui

static func open_options(t, ui) -> void:
 await Click.press(t,"HomeOptions")
 await t.frames()
 var scroll=ui.find_child("DisplayOptionsScroll",true,false)
 if scroll!=null:
  scroll.scroll_vertical=100000
  await t.frames(3)

# ---- 主页提示 -------------------------------------------------------------------------

static func startup_offer_renders_notice(t) -> void:
 var served=signed(newer_version())
 var options=harness(served)
 var ui=await boot(t,options)
 t.check(not ui.update_check.auto_allowed(),"UPDATE startup_offer_renders_notice: a scripted harness never auto-checks, so suites stay offline")
 ui.update_check.check()
 await t.frames()
 t.check(options.calls.size()==2 and String(options.calls[0]).ends_with("manifest.json") and String(options.calls[1]).ends_with(".sig"),"UPDATE startup_offer_renders_notice: one check reads the manifest then its signature: "+str(options.calls))
 t.check(JSON.stringify(ui.game.state)==String(options.state),"UPDATE startup_offer_renders_notice: the check never touches the run state")
 var notice=ui.find_child("HomeUpdateNotice",true,false)
 t.check(notice!=null and notice.is_visible_in_tree(),"UPDATE startup_offer_renders_notice: a verified newer version shows the home notice")
 if notice==null: return
 var text=t.visible_text(notice)
 t.check(text.contains(newer_version()) and text.contains(size_text()),"UPDATE startup_offer_renders_notice: the notice names the version and the rounded size: "+text)
 var title=notice.get_child(0).get_child(0)
 t.check(title!=null and title.get_theme_color("font_color")==Palette.GOLD,"UPDATE startup_offer_renders_notice: the notice title is styled from the shared palette")
 var download=ui.find_child("HomeUpdateDownload",true,false)
 var mirror=ui.find_child("HomeUpdateMirror",true,false)
 t.check(download!=null and mirror!=null and download.is_visible_in_tree() and mirror.is_visible_in_tree(),"UPDATE startup_offer_renders_notice: both jump buttons are visible")
 await Click.press(t,"HomeUpdateDownload")
 await Click.press(t,"HomeUpdateMirror")
 t.check(options.opened.size()==2 and String(options.opened[0])==Cases.URL and String(options.opened[1])==Cases.MIRROR,"UPDATE startup_offer_renders_notice: each button opens its own signed link: "+str(options.opened))
 var home=ui.find_child("GameHome",true,false)
 var title_area=home.get_children().filter(func(node):return node is Control and node.position.x<1000)
 t.check(title_area.size()==4 and not home.get_children().has(notice),"UPDATE startup_offer_renders_notice: the notice stays outside the four-child home title area")
 var save_notice=ui.find_child("HomeSettingsSaveNotice",true,false)
 t.check(notice.get_global_rect().end.y<=save_notice.get_global_rect().position.y,"UPDATE startup_offer_renders_notice: the notice does not overlap the settings notice")

static func startup_offline_is_silent(t) -> void:
 var options=harness({"failure":HTTPRequest.RESULT_TIMEOUT})
 var ui=await boot(t,options)
 ui.update_check.check()
 await t.frames()
 t.check(options.calls.size()==1,"UPDATE startup_offline_is_silent: a timeout stays one request and never retries: "+str(options.calls))
 t.check(String(ui.update_check.offer.get("reason",""))=="network" and not ui.update_check.busy,"UPDATE startup_offline_is_silent: the answer is a silent network rejection: "+str(ui.update_check.offer))
 t.check(ui.find_child("HomeUpdateNotice",true,false)==null,"UPDATE startup_offline_is_silent: no notice, no popup: ")
 t.check(ui.find_child("GameHome",true,false)!=null and ui.find_child("HomeContinue",true,false)!=null,"UPDATE startup_offline_is_silent: the home page stays interactive")

static func startup_bad_signature_is_silent(t) -> void:
 var served=signed(newer_version(),true)
 var options=harness(served)
 var ui=await boot(t,options)
 ui.update_check.check()
 await t.frames()
 t.check(options.calls.size()==2,"UPDATE startup_bad_signature_is_silent: a tampered manifest still completes both reads: "+str(options.calls))
 t.check(String(ui.update_check.offer.get("reason",""))=="signature","UPDATE startup_bad_signature_is_silent: the answer is a signature rejection: "+str(ui.update_check.offer))
 t.check(ui.find_child("HomeUpdateNotice",true,false)==null,"UPDATE startup_bad_signature_is_silent: a forged manifest never reaches the player")

# ---- 开关与手动检查 -------------------------------------------------------------------

static func toggle_off_skips_startup(t) -> void:
 var prefs=Cases.prefs_path()
 var served=signed(newer_version())
 var options=harness(served,prefs)
 var ui=await boot(t,options)
 # The harness keeps main's save persistence off; the settings store is the only writer and
 # its file is the temp path above, so the switch exercises the one production store.
 ui.display_settings.persistence_enabled=true
 t.check(ui.display_settings.update_check_enabled,"UPDATE toggle_off_skips_startup: the startup check is on by default")
 await open_options(t,ui)
 var toggle=ui.find_child("UpdateCheckEnabled",true,false)
 t.check(toggle!=null and toggle.is_visible_in_tree() and toggle.button_pressed,"UPDATE toggle_off_skips_startup: the display tab shows the switch on")
 t.check(ui.find_child("UpdateCheckNow",true,false)!=null,"UPDATE toggle_off_skips_startup: the manual check button sits next to the switch")
 await Click.press(t,"UpdateCheckEnabled")
 t.check(not ui.display_settings.update_check_enabled,"UPDATE toggle_off_skips_startup: pressing the switch turns the startup check off")
 var config=ConfigFile.new()
 t.check(config.load(prefs)==OK and config.get_value("update","check_on_start",true)==false,"UPDATE toggle_off_skips_startup: the choice is saved in the existing settings file")
 options.calls=[]
 var again=await boot(t,options)
 again.display_settings.initialize(again.get_window(),true)
 t.check(not again.display_settings.update_check_enabled,"UPDATE toggle_off_skips_startup: the saved choice is loaded on the next launch")
 t.check(options.calls.is_empty() and again.find_child("HomeUpdateNotice",true,false)==null,"UPDATE toggle_off_skips_startup: a disabled startup check sends nothing: "+str(options.calls))
 await open_options(t,again)
 # A fresh manifest needs its own key: the stand-in answers from the same signed document and
 # an old table would reject the new signature.
 var latest=signed(RunningStore.effective_version())
 options["response"]=latest
 options["keys"]=latest.keys
 again.update_check.keys=latest.keys
 await Click.press(t,"UpdateCheckNow")
 await t.frames()
 t.check(options.calls.size()==2 and String(options.calls[0]).ends_with("manifest.json"),"UPDATE toggle_off_skips_startup: the manual button still checks while the startup check is off: "+str(options.calls))
 var status=again.find_child("UpdateCheckStatus",true,false)
 t.check(status!=null and String(status.text)==again._text("ui.update.latest","已是最新版本。"),"UPDATE toggle_off_skips_startup: the panel reports the latest version instead of a notice: "+str(status.text if status!=null else ""))
 t.check(again.find_child("HomeUpdateNotice",true,false)==null,"UPDATE toggle_off_skips_startup: a same-version answer never shows the home notice")

# ---- 检查进行中的主页与失败静默 ------------------------------------------------

# A transport that records the request and answers nothing: the check stays in flight while the
# case talks to the home page, so any synchronous gate or busy modal would be visible here.
static func held_stand_in(options: Dictionary) -> Callable:
 return func(url: String, _method: int) -> int:
  options.calls.append(url)
  return OK

static func check_in_flight_keeps_home_interactive(t) -> void:
 var options=harness({})
 var ui=await boot(t,options)
 ui.update_check.transport=held_stand_in(options)
 ui.update_check.check()
 await t.frames()
 t.check(ui.update_check.busy and options.calls.size()==1,"UPDATE check_in_flight_keeps_home_interactive: the check is pending with one request held: "+str(options.calls))
 var new_game=ui.find_child("HomeNewGame",true,false)
 t.check(new_game!=null and not new_game.disabled,"UPDATE check_in_flight_keeps_home_interactive: home buttons stay enabled while the check is pending")
 await Click.press(t,"HomeOptions")
 await t.frames()
 var status=ui.find_child("UpdateCheckStatus",true,false)
 t.check(ui.show_options and ui.find_child("UpdateCheckEnabled",true,false)!=null,"UPDATE check_in_flight_keeps_home_interactive: a home button still opens the settings page while the check is pending")
 t.check(status!=null and String(status.text)==ui._text("ui.update.checking","正在检查更新…"),"UPDATE check_in_flight_keeps_home_interactive: the settings panel reports the in-flight state instead of freezing: "+str(status.text if status!=null else ""))
 t.check(options.calls.size()==1,"UPDATE check_in_flight_keeps_home_interactive: the pending check issued no extra request: "+str(options.calls))

static func transport_failures_are_silent(t) -> void:
 for row in [{"failure":HTTPRequest.RESULT_TIMEOUT,"reason":"network"},{"status":404,"reason":"http"},{"status":302,"reason":"http"}]:
  var options=harness(row)
  var ui=await boot(t,options)
  ui.update_check.check()
  await t.frames()
  var label="timeout" if row.has("failure") else ("status "+str(row["status"]))
  t.check(options.calls.size()==1,"UPDATE transport_failures_are_silent: "+label+" ends after one request and never retries: "+str(options.calls))
  t.check(String(ui.update_check.offer.get("reason",""))==String(row["reason"]) and not ui.update_check.busy,"UPDATE transport_failures_are_silent: "+label+" is a silent "+String(row["reason"])+" rejection: "+str(ui.update_check.offer))
  t.check(ui.find_child("HomeUpdateNotice",true,false)==null,"UPDATE transport_failures_are_silent: "+label+" shows no home notice")
  var windows=ui.find_children("*","Window",true,false).filter(func(node):return node.visible)
  var root_popups=t.root.get_children().filter(func(node):return node is PopupPanel or node is AcceptDialog)
  t.check(windows.is_empty() and root_popups.is_empty(),"UPDATE transport_failures_are_silent: "+label+" opens no popup or dialog: "+str(windows.size()+root_popups.size()))
  await t.frames(6)
  t.check(options.calls.size()==1,"UPDATE transport_failures_are_silent: "+label+" stays one request after waiting, no retry: "+str(options.calls))
  await Click.press(t,"HomeOptions")
  await t.frames()
  t.check(ui.show_options,"UPDATE transport_failures_are_silent: the home page stays interactive after "+label)

# ---- re-entry and the empty configuration ---------------------------

# A check in flight owns the single result emission. A second check() while busy
# is ignored -- no request, no checked; the in-flight check emits exactly one checked when
# it completes, and the offer it publishes is the one the first call started.
static func check_in_flight_ignores_second_call(t) -> void:
 var served=signed(newer_version())
 var options=harness(served)
 var ui=await boot(t,options)
 # boot already installed the stand-in that answers; keep it for the resume instead of
 # building a second one, and swap in the held transport only for the first read.
 var answers=ui.update_check.transport
 ui.update_check.transport=held_stand_in(options)
 var emitted=[]
 ui.update_check.checked.connect(func(offer): emitted.append(offer))
 ui.update_check.check()
 await t.frames()
 t.check(ui.update_check.busy and options.calls.size()==1,"UPDATE check_in_flight_ignores_second_call: the first check is pending after one request: "+str(options.calls))
 ui.update_check.check()
 await t.frames()
 t.check(options.calls.size()==1,"UPDATE check_in_flight_ignores_second_call: a second check() while busy issues no request: "+str(options.calls))
 t.check(emitted.is_empty(),"UPDATE check_in_flight_ignores_second_call: a second check() while busy emits no checked: "+str(emitted.size()))
 ui.update_check.transport=answers
 ui.update_check.deliver(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),served.manifest)
 await t.frames()
 t.check(options.calls.size()==2,"UPDATE check_in_flight_ignores_second_call: the in-flight check still reads the signature after the ignored call: "+str(options.calls))
 t.check(emitted.size()==1,"UPDATE check_in_flight_ignores_second_call: the finished check emits checked exactly once: "+str(emitted.size()))
 t.check(not ui.update_check.busy and String(ui.update_check.offer.get("version",""))==newer_version(),"UPDATE check_in_flight_ignores_second_call: exactly one offer comes out of the completed check: "+str(ui.update_check.offer))
 t.check(ui.find_child("HomeUpdateNotice",true,false)!=null,"UPDATE check_in_flight_ignores_second_call: the completed check still updates the home notice")

# An empty [update] manifest_url is not a usable target. The startup gate refuses it and
# the manual "check now" entry answers url without a request, so a missing configuration
# never turns into a network attempt and never shows a notice.
static func empty_manifest_url_sends_no_request(t) -> void:
 var previous=ProjectSettings.get_setting("update/manifest_url","")
 ProjectSettings.set_setting("update/manifest_url","")
 var options=harness({})
 var ui=await boot(t,options)
 t.check(String(Check._secure_url()).is_empty(),"UPDATE empty_manifest_url_sends_no_request: an empty manifest_url is not a usable https target")
 t.check(not ui.update_check.auto_allowed(),"UPDATE empty_manifest_url_sends_no_request: the automatic start refuses an empty manifest_url")
 t.check(options.calls.is_empty(),"UPDATE empty_manifest_url_sends_no_request: booting with an empty manifest_url sends no request: "+str(options.calls))
 await open_options(t,ui)
 await Click.press(t,"UpdateCheckNow")
 await t.frames()
 t.check(options.calls.is_empty(),"UPDATE empty_manifest_url_sends_no_request: the manual check sends no request for an empty manifest_url: "+str(options.calls))
 t.check(not ui.update_check.busy and String(ui.update_check.offer.get("reason",""))=="url","UPDATE empty_manifest_url_sends_no_request: the manual check answers url without leaving a pending request: "+str(ui.update_check.offer))
 t.check(ui.find_child("HomeUpdateNotice",true,false)==null,"UPDATE empty_manifest_url_sends_no_request: an empty manifest_url shows no home notice")
 t.check(ui.find_child("UpdateCheckStatus",true,false)==null,"UPDATE empty_manifest_url_sends_no_request: an empty manifest_url shows no settings status text")
 ProjectSettings.set_setting("update/manifest_url",previous)

# docs/spec/update-check.md: the check node is created before the scene enters the tree, so a
# host freed without ever entering it must release the node itself (ui/main.gd::_notification,
# NOTIFICATION_PREDELETE); otherwise it leaks and only shows as an engine exit error.
# The nearest counter-example is a booted host: its check is parented, so the scene tree owns it
# and the PREDELETE branch must not free it a second time.
static func host_free_releases_unparented_check(t) -> void:
 var host=load("res://ui/main.gd").new()
 var check_ref=weakref(host.update_check)
 t.check(check_ref.get_ref()!=null and host.update_check.get_parent()==null,"UPDATE host_free_releases_unparented_check: a host that never entered the tree owns an unparented update check")
 host.free()
 t.check(check_ref.get_ref()==null,"UPDATE host_free_releases_unparented_check: freeing a host before the tree must release its unparented update check")
 var booted=await boot(t,harness({}))
 t.check(booted.update_check.get_parent()!=null,"UPDATE host_free_releases_unparented_check: a booted host's update check is parented, so the scene tree releases it")

# ---- 引导挂载后的版本身份（docs/spec/update-check.md「引导挂载与版本身份」）------------------------
# The window title and the feedback report both read the effective version through the store; a
# scripted harness cannot run boot.gd, so the cases record the mount the way boot.gd does
# (Store.record_mounted) and assert what the production main.tscn shows. Stores are injected under
# res://build/, never the real user://updates.

static func mounted_version_reaches_title_and_report(t) -> void:
 var Store=Cases.boot_load(t,"mounted_version_reaches_title_and_report",Cases.BOOT_STORE_PATH)
 if Store==null: return
 Store.record_mounted(Cases.PATCH_A)
 var ui=await boot(t,harness({}))
 var title=ui.get_window().title
 t.check(title.ends_with(" v"+Cases.PATCH_A),"UPDATE mounted_version_reaches_title_and_report: the window title ends with the mounted version: "+title)
 t.check(title.begins_with(str(ProjectSettings.get_setting("application/config/name",""))),"UPDATE mounted_version_reaches_title_and_report: the title keeps the project name in front: "+title)
 ui.feedback_report.draft.context={}
 ui.feedback_report._capture_context()
 t.check(String(ui.feedback_report.draft.context.get("version",""))==Cases.PATCH_A and String(ui.feedback_report.payload().context.version)==Cases.PATCH_A,"UPDATE mounted_version_reaches_title_and_report: the feedback report describes the mounted code: "+str(ui.feedback_report.draft.context))
 Store.record_mounted("")

# Nearest negative: a patch that was recorded but not mounted never reaches the title or the report.
static func unmounted_patch_reports_baseline(t) -> void:
 var Store=Cases.boot_load(t,"unmounted_patch_reports_baseline",Cases.BOOT_STORE_PATH)
 if Store==null: return
 var baseline=Store.baseline_version()
 var store=Store.new(Cases.boot_root("ui-unmounted"))
 store.write_state(Cases.boot_state(baseline,Cases.boot_entry(store,Cases.PATCH_A)))
 var ui=await boot(t,harness({}))
 var title=ui.get_window().title
 t.check(title.ends_with(" v"+baseline) and not title.contains(Cases.PATCH_A),"UPDATE unmounted_patch_reports_baseline: the title reports the baseline when nothing was mounted: "+title)
 ui.feedback_report.draft.context={}
 ui.feedback_report._capture_context()
 t.check(String(ui.feedback_report.draft.context.get("version",""))==baseline,"UPDATE unmounted_patch_reports_baseline: the feedback report reports the baseline: "+str(ui.feedback_report.draft.context))

# The host proves the session after startup restore: only a pending patch that was actually
# mounted this process is promoted; a pending patch nobody mounted stays pending.
static func start_marks_boot_succeeded(t) -> void:
 var Store=Cases.boot_load(t,"start_marks_boot_succeeded",Cases.BOOT_STORE_PATH)
 if Store==null: return
 var baseline=Store.baseline_version()
 var mounted_store=Store.new(Cases.boot_root("ui-proved"))
 mounted_store.write_state(Cases.boot_state(baseline,{},Cases.boot_entry(mounted_store,Cases.PATCH_A),Cases.PATCH_A))
 Store.record_mounted(Cases.PATCH_A)
 var options=harness({})
 options["store"]=mounted_store
 await boot(t,options)
 var state=mounted_store.load_state()
 t.check(String(state.mounting).is_empty() and String(state.active.get("to",""))==Cases.PATCH_A and state.pending.is_empty(),"UPDATE start_marks_boot_succeeded: startup clears the marker and promotes the mounted pending patch: "+str(state))
 Store.record_mounted("")
 var idle_store=Store.new(Cases.boot_root("ui-idle"))
 idle_store.write_state(Cases.boot_state(baseline,{},Cases.boot_entry(idle_store,Cases.PATCH_B)))
 var idle_options=harness({})
 idle_options["store"]=idle_store
 await boot(t,idle_options)
 var idle_state=idle_store.load_state()
 t.check(String(idle_state.get("pending",{}).get("to",""))==Cases.PATCH_B and idle_state.active.is_empty(),"UPDATE start_marks_boot_succeeded: a pending patch that was not mounted this process is not promoted: "+str(idle_state))
