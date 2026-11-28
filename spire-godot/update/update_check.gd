extends Node

# docs/spec/update-check.md「网络入口」: the only network entry of the update check. One check
# issues at most two HTTPS GETs (the manifest, then its ".sig"), never retries, never follows a
# redirect, never writes disk and never sends an identifier. The single judgement is
# UpdateManifest.evaluate; this node owns configuration, transport and result plumbing only.

const Manifest=preload("res://update/update_manifest.gd")
const Keys=preload("res://update/update_keys.gd")
const Store=preload("res://update/update_store.gd")
# The body cap and the https requirement have one declaration each, both in the judgement
# module: the transport must not carry a second copy that can drift from what evaluate accepts.
const MAX_BYTES=Manifest.MAX_BYTES
const TIMEOUT_SECONDS=10
const SIGNATURE_SUFFIX=".sig"
const URL_PREFIX=Manifest.HTTPS

signal checked(offer)

var host
# The key table is a field so a probe or a suite can verify a manifest with its own key. The
# shipped default is the only table a player session uses; its entries are the published release keys.
var keys: Dictionary=Keys.KEYS
# Test/probe seam with the same shape as ui/feedback_report.gd::transport: a valid Callable
# replaces HTTPRequest and returns OK; the stand-in answers by calling deliver(), so the
# production and the stand-in path share one result entry.
var transport: Callable
var request: HTTPRequest
# The install identity source (update_store.gd). A player session builds the default store on
# demand; a harness (--script) never does, so an injected store is the only way to give a
# harness run an identity.
var store=null
var busy=false
# GETs issued by the current (or last) check; the contract allows at most two.
var requests=0
var offer={"kind":"none","reason":"idle"}
var _manifest=PackedByteArray()
var _stage=""

func _ready() -> void:
 request=HTTPRequest.new()
 request.timeout=TIMEOUT_SECONDS
 request.max_redirects=0
 request.body_size_limit=MAX_BYTES
 add_child(request)
 request.request_completed.connect(deliver)

# docs/spec/update-check.md「配置」: the single read point for the [update] section.
static func manifest_url() -> String:
 return str(ProjectSettings.get_setting("update/manifest_url","")).strip_edges()

# The check covers Windows and Android. An uncovered platform has no key and yields none, which
# is the same answer a missing platform entry gives.
static func platform_key() -> String:
 if OS.has_feature("android"): return "android"
 if OS.get_name()=="Windows": return "windows-x64"
 return ""

# A player session is an engine run that boots the shipped main scene. A run started with
# --script is a harness, a probe or a tool: it stays offline and starts check() itself.
static func scripted_run() -> bool:
 return Store.scripted_run()

# The automatic start is a player-session decision: the run must be a player session, the
# factory default and the saved player preference must allow it, and the URL must be HTTPS.
# check() itself is the manual entry and never consults the switch.
func auto_allowed() -> bool:
 if scripted_run(): return false
 if not bool(ProjectSettings.get_setting("update/check_on_start",true)): return false
 if is_instance_valid(host) and host.display_settings!=null and not host.display_settings.update_check_enabled: return false
 return not _secure_url().is_empty()

# The one https predicate: the startup gate and the network entry both read it, so a plain-http
# configuration can neither start automatically nor be requested. An unusable URL answers "".
static func _secure_url() -> String:
 var url=manifest_url()
 return url if url.begins_with(URL_PREFIX) else ""

# The only network entry. A finished check always ends in exactly one checked(offer) emission.
func check() -> void:
 if busy: return
 var url=_secure_url()
 if url.is_empty():
  _finish(Manifest.none("url"));return
 busy=true
 requests=0
 _manifest=PackedByteArray()
 _stage="manifest"
 offer={"kind":"none","reason":"idle"}
 if _send(url)!=OK: _fail("network")

func _send(url: String) -> int:
 requests+=1
 if transport.is_valid(): return transport.call(url,HTTPClient.METHOD_GET)
 return request.request(url,PackedStringArray(),HTTPClient.METHOD_GET)

# The single result entry: HTTPRequest completion and the transport stand-in both land here.
# Failure is silent by contract — no popup, no retry, no second request.
func deliver(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
 if not busy: return
 if result==HTTPRequest.RESULT_SUCCESS and status==200:
  if _stage=="manifest":
   _manifest=body
   _stage="signature"
   if _send(manifest_url()+SIGNATURE_SUFFIX)!=OK: _fail("network")
   return
  _finish(Manifest.evaluate(_manifest,body,keys,Store.effective_version(),platform_key(),_identity()))
  return
 _fail("network" if result!=HTTPRequest.RESULT_SUCCESS else "http")

# What a patch must match to apply to this install: the injected store's, else the player
# session's own. Outside a player session (a --script harness, a platform without patch mounting)
# there is no identity and no store is built, so no patch is matched there.
func _identity() -> Dictionary:
 if store!=null: return store.identity()
 if not Store.player_session(): return {}
 return Store.new().identity()

func _fail(reason: String) -> void:
 _finish(Manifest.none(reason))

func _finish(result: Dictionary) -> void:
 busy=false
 _stage=""
 _manifest=PackedByteArray()
 offer=result
 # A rejected or not-newer answer is silent for the player; --verbose keeps it diagnosable.
 print_verbose("update check: "+("none reason="+String(result.get("reason","")) if result.get("kind","")=="none" else "notice version="+String(result.get("version",""))))
 checked.emit(offer)
