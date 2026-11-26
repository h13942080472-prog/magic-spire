extends RefCounted

# docs/spec/save-fixed-points.md「加性字段与只读入口」: state.route_history keeps one compact
# entry per tower route (run -> cycle -> route). This module is its only writer: open closes the
# previous entry and appends the next one. The only other direct writes are the _init literal and
# the one-line backfill in core/game.gd::restore_snapshot.
#
# An entry holds stable ids only — no wall clock, no external identity, no random draw — so the
# same seed and the same command sequence reproduce the same history.
#
# A switch lands after the caller has generated the next route, so the closed entry's floor is
# rebuilt from that entry's own region/seed/boss/security: Tower.generate and Tower.prison_route
# are deterministic. A fixture room whose id the generator cannot reproduce falls back to the
# live state.rooms by the same id.

const KEYS=["enter","cycle","generation","region","seed","boss","security","nodes","floor"]
const REGION_TOWER="tower"
const REGION_PRISON="prison"
const ENTER_START="start"
const ENTER_RELEASE="release"
const ENTER_ESCAPE="escape"
const ENTER_GATE_EXIT="gate_exit"
const ENTER_CYCLE="cycle"
const ENTER_UNKNOWN="unknown"

# Sole append point: one entry per real route switch (the three kinds flagged route in TRANSITIONS).
static func open(g, kind: String) -> void:
 var history: Array=g.state.route_history
 if not history.is_empty(): _close(g,history[-1])
 history.append(_entry(g,reason(g,kind)))

# Entry reason. Only tower_restart has more than one answer, decided in this order:
# - cycle first: DemoExit.continue_run raises demo_cycle before _restart_tower(true);
# - a completed sentence is always release, whatever region the closed entry has, because its
#   cell is still in state.prison at the mount (_serving_sentence);
# - gate_exit only for the exit-guard return: the cell is empty and the closed entry is the
#   prison route;
# - anything else is release.
static func reason(g, kind: String) -> String:
 match kind:
  "setup_init": return ENTER_START
  "prison_escape": return ENTER_ESCAPE
  "tower_restart":
   var last=_last(g)
   if int(g.state.demo_cycle)>int(last.get("cycle",0)): return ENTER_CYCLE
   if _serving_sentence(g): return ENTER_RELEASE
   if String(last.get("region",""))==REGION_PRISON: return ENTER_GATE_EXIT
   return ENTER_RELEASE
 return ENTER_UNKNOWN

# Prison.completed_turn mounts while its cell is still in state.prison (core/game.gd::_restart_tower
# empties it only after _apply_transition); the exit-guard return mounts after Prison.escape
# already emptied it. Every writer assigns state.prison a Dictionary and Snapshot.check pins the
# field type, so emptiness alone tells the two tower_restart paths with region=prison apart.
static func _serving_sentence(g) -> bool:
 return not g.state.prison.is_empty()

# Legacy saves without the field start with one unattributable route; nodes/floor wait for the
# next real close. Loading never raises the save revision.
static func backfill(s: Dictionary) -> Array:
 var region=String(s.get("map_region",""))
 var cycle=int(s.get("demo_cycle",0))
 var generation=int(s.get("tower_generation",0))
 var run_seed=int(s.get("seed",0))
 var security=int(s.get("security",0))
 return [_record(ENTER_UNKNOWN,cycle,generation,region,run_seed,security,s.get("room_encounters",{}))]

static func _entry(g, enter: String) -> Dictionary:
 var region=String(g.state.map_region)
 return _record(enter,int(g.state.demo_cycle),int(g.state.tower_generation),region,int(g.state.seed),int(g.state.security),g.state.room_encounters)

# The single record shape: all nine keys of KEYS, nodes/floor still open.
static func _record(enter: String, cycle: int, generation: int, region: String, run_seed: int, security: int, encounters) -> Dictionary:
 var boss=_boss_of(region,encounters)
 return {"enter":enter,
  "cycle":cycle,
  "generation":generation,
  "region":region,
  "seed":run_seed,
  "boss":boss,
  "security":security,
  "nodes":-1,
  "floor":-1}

# The summit encounter is a stable id; a prison route has none (its guard count is security).
static func _boss_of(region: String, encounters) -> String:
 if region==REGION_PRISON or not encounters is Dictionary: return ""
 return String(encounters.get("summit",""))

static func _last(g) -> Dictionary:
 var history: Array=g.state.route_history
 return {} if history.is_empty() else history[-1]

static func _close(g, record: Dictionary) -> void:
 var completed: Array=g.state.completed_rooms
 record["nodes"]=completed.size()
 record["floor"]=_reached_floor(g,record,completed)

# docs/spec/route-history.md「关闭口径」: the highest completed room floor plus one, and zero when
# the route completed nothing. The run-review panel's _progress_text reads differently: it also
# counts the room the player is still in, so the two disagree when that room is deeper than every
# completed one.
static func _reached_floor(g, record: Dictionary, completed: Array) -> int:
 var floors=_floors(g,record)
 var highest=0
 for id in completed:
  var key=String(id)
  if floors.has(key): highest=maxi(highest,int(floors[key])+1)
 return highest

static func _floors(g, record: Dictionary) -> Dictionary:
 var floors={}
 for room in _route_rooms(g,record): floors[String(room.id)]=int(room.floor)
 for room in g.state.rooms:
  if not floors.has(String(room.id)): floors[String(room.id)]=int(room.floor)
 return floors

static func _route_rooms(g, record: Dictionary) -> Array:
 if String(record.get("region",""))==REGION_PRISON: return g.Tower.prison_route(int(record.get("security",0)))
 return g.Tower.generate(int(record.get("seed",0)),String(record.get("boss","")))
