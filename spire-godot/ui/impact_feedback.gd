extends Control

const Palette=preload("res://ui/visual_theme.gd")

# Transient post-commit impacts: one full-screen pass-through layer for the three
# committed-feedback effects (pleasure filter, coloured border, impact shake).
#
# Contract: inputs are the committed dispatch receipt (`resource_feedback`), the
# committed payload and the post-commit View. The layer never reads state.logs, never
# writes game state, display facts, saves or randomness, and it owns no rule decision.
# Invariants: no _process (one-shot tweens only, hidden when idle) and mouse_filter
# stays IGNORE on every node here, so ordinary clicks keep reaching the layout below.
# The shake displaces main.gd's GameLayout (the container that carries every committed
# control) and restores its recorded origin exactly; the overlay bands never move.
#
# Trigger table, all derived from the committed receipt (net delta of plain top-level
# state fields, see core/resource_feedback.gd) plus the committed payload: pressure rise
# -> pink filter; charge / next_energy rise -> yellow border; mana / temporary_mana /
# witch_focus change (gain or loss) -> blue border, with the gain and loss envelopes and
# bands drawn differently and the peak scaled by the size of the change; payload
# kind=="calm" -> white border; attack / strain / slip payload -> shake. A failed cast
# needs no flag: it nets its mana (and, on the witch, one focus layer) down, so the same
# delta rule selects the blue loss variant.

# ---------------------------------------------------------------------------
# FEEDBACK_* parameter table: the single source of every effect value.
# ---------------------------------------------------------------------------
# Pleasure filter: a soft vignette on the four screen edges. Peak follows the
# current pressure ratio, with a floor relative to this rise so a large gain at low
# pressure is still visible; the fade grows a little for large rises but stays short.
# The floor and cap are set so the lowest intended intensity (small rise at low
# pressure) is measurable against the screenshot baseline, not a faint trace.
const FEEDBACK_FILTER_ALPHA_BASE=0.14
const FEEDBACK_FILTER_ALPHA_PER_RATIO=0.25
const FEEDBACK_FILTER_ALPHA_MIN=0.14
const FEEDBACK_FILTER_ALPHA_MAX=0.38
const FEEDBACK_FILTER_RISE_ALPHA_FLOOR=0.5
const FEEDBACK_FILTER_FADE_BASE=0.12
const FEEDBACK_FILTER_FADE_PER_RATIO=0.6
const FEEDBACK_FILTER_FADE_MIN=0.12
const FEEDBACK_FILTER_FADE_MAX=0.40
# Border families: one row per family, holding the palette token and the timing.
# Colour carries the family (white deep breath, yellow charge/next energy, blue mana
# family); the timing keeps the old force reading: charge is a resource already loaded
# for the next strike and reads short and firm, a deep breath is a slow deliberate act
# and reads longer and softer. The blue family declares its token only and takes peak,
# fade and band from the signed variant row below. Rows are read-only: callers read
# values out, never mutate the table.
const FEEDBACK_BORDERS={
 "calm":{"color":Palette.BORDER_CALM,"alpha":0.30,"fade":0.60},
 "charge":{"color":Palette.BORDER_CHARGE,"alpha":0.50,"fade":0.22},
 "mana":{"color":Palette.BORDER_MANA},
}
# Blue-family envelope variants, one row per sign of the committed family change. `alpha`
# is the peak at a full reference-scale change; the drawn peak is `alpha*|ratio|` (see
# mana_ratio), so a small movement is nearly invisible and there is no minimum-delta
# gate. Gain: a quick ramp then a short fade over a slightly wider band. Loss: immediate
# peak then a slower retreat over a narrower band. The token is shared; envelope, band
# and peak coefficient are what tell the two apart.
const FEEDBACK_MANA_VARIANTS={
 "gain":{"alpha":0.34,"attack":0.10,"fade":0.30,"extent":0.34},
 "loss":{"alpha":0.46,"attack":0.0,"fade":0.55,"extent":0.26},
}
# Reference scale per blue-family field, used only to weight how large a committed change
# reads: mana by the committed mana maximum (View `mana_max`, fallback below), temporary
# mana by its retention cap and witch focus by its 4-layer ceiling (data/balance.gd
# TEMPORARY_MANA_RETENTION and the 2 + retention-bonus cap). Display weights only: they
# never gate, reorder or change a rule.
const FEEDBACK_MANA_REFERENCE=100.0
const FEEDBACK_RESERVE_REFERENCE=20.0
const FEEDBACK_FOCUS_REFERENCE=4.0
# Which receipt fields light which field-driven family, in fixed priority order (the
# first triggered family wins, so one submission still shows one border). The deep breath
# family is payload-driven, checked first, and is not listed here.
const FEEDBACK_BORDER_FIELDS={"charge":["charge","next_energy"],"mana":["mana","temporary_mana","witch_focus"]}
# Families that only read a rise, keeping their committed meaning. The blue family is
# absent on purpose: any nonzero mana-family change is its event, and a net fall is the
# loss variant rather than silence. `FEEDBACK_BORDER_RISE_ONLY` never mutates the fields.
const FEEDBACK_BORDER_RISE_ONLY={"charge":true}
# Edge band extent shared by the filter and the fixed-family borders: the same
# 1-(d/dmax)^2 weight and dmax is this fraction of the half short side, so the lights
# stay on the four screen edges. 0.30 replaced the old per-effect values (1.0 spread the
# filter too thin to read at the alpha floor, 0.18 drew the border as a hairline) and is
# the band the pixel checks measure. The blue family overrides it per variant.
const FEEDBACK_EDGE_EXTENT=0.30
# Impact shake: amplitude and pulse count encode force, never colour, never a layout
# change: the content container is displaced for the pulse and restored exactly. The
# floor is 4px because the earlier 1.2-6px band displaced the content too little to
# read; the peak frame is measured against the pre-effect frame over the content area.
const FEEDBACK_SHAKE_BASE_PX=4.0
const FEEDBACK_SHAKE_PER_DAMAGE_PX=0.25
const FEEDBACK_SHAKE_MIN_PX=4.0
const FEEDBACK_SHAKE_MAX_PX=9.0
const FEEDBACK_SHAKE_ATTACK_PULSES=1
const FEEDBACK_SHAKE_STRAIN_PULSES=2
const FEEDBACK_SHAKE_SLIP_PULSES=1
const FEEDBACK_SHAKE_ATTACK_STEP=0.055
const FEEDBACK_SHAKE_STRAIN_STEP=0.06
const FEEDBACK_SHAKE_SLIP_STEP=0.12
# Each later pulse of one shake swings this much weaker than the first.
const FEEDBACK_SHAKE_PULSE_DECAY=0.35
# Geometry: band count and the weight below which a band is transparent enough to skip.
const FEEDBACK_VIGNETTE_BANDS=18
const FEEDBACK_BAND_WEIGHT_CUTOFF=0.04
const FEEDBACK_FALLBACK_COLOR=Palette.FEEDBACK_FALLBACK
# Layering: above the keyboard hint layer (216) and below every popout, panel and
# float (220 and up), so drawers, drop hints, card motion, feedback and floats stay
# untinted. The only committed layer it covers is `KeyboardTargets`, a read-only hint
# panel whose clicks this layer still lets through.
const FEEDBACK_Z_INDEX=218

var host
var filter_bands: Control
var border_bands: Control
var bands_host: Control
# The shake displaces this container and restores `shake_origin` exactly afterwards.
# The layer resolves it from `host.layout` (main.gd's GameLayout carries every
# committed control) so the visible game content moves; the overlay bands never do.
var shake_target: Control
var shake_origin=Vector2.ZERO
var filter: Fade
var border: Fade
var border_kind=""
var shake_amplitude=0.0
var shake_pulses=0
var shake_step=0.0
var shake_tween
# Last committed trigger set. Kept after the tweens end so callers and checks can
# read what one submission showed without racing the fade.
var last_impact={}

## Summed committed receipt deltas per field. Several changes inside one submission
## (for example two pressure sources) merge here, so one submission is one effect.
static func deltas(events: Array) -> Dictionary:
 var result={}
 for event in events:
  var field=String(event.get("field",""))
  if field=="": continue
  result[field]=float(result.get(field,0.0))+float(event.get("after",0.0))-float(event.get("before",0.0))
 return result

static func pressure_rise(events: Array) -> float:
 return maxf(0.0,float(deltas(events).get("pressure",0.0)))

## Peak and fade follow the committed pressure ratio, never a forecast.
static func filter_peak(ratio_now: float, ratio_rise: float) -> float:
 var peak=clampf(FEEDBACK_FILTER_ALPHA_BASE+FEEDBACK_FILTER_ALPHA_PER_RATIO*ratio_now,FEEDBACK_FILTER_ALPHA_MIN,FEEDBACK_FILTER_ALPHA_MAX)
 return maxf(peak,FEEDBACK_FILTER_RISE_ALPHA_FLOOR*ratio_rise)

static func filter_fade(ratio_rise: float) -> float:
 return clampf(FEEDBACK_FILTER_FADE_BASE+FEEDBACK_FILTER_FADE_PER_RATIO*ratio_rise,FEEDBACK_FILTER_FADE_MIN,FEEDBACK_FILTER_FADE_MAX)

# Damage already exists in the committed payload: damage-dealing cards carry
# preview.damage, basic attacks carry a flat damage amount.
static func damage_of(payload: Dictionary) -> float:
 if payload.has("preview"): return float(payload.preview.get("damage",0.0))
 return float(payload.get("damage",0.0))

## Shake shape per committed payload, empty when this action has no impact.
static func shake_spec(payload: Dictionary) -> Dictionary:
 var kind=String(payload.get("kind",""))
 if kind=="attack": return {"pulses":FEEDBACK_SHAKE_ATTACK_PULSES,"step":FEEDBACK_SHAKE_ATTACK_STEP,"damage":damage_of(payload)}
 if kind!="card": return {}
 var damage=damage_of(payload)
 if damage<=0.0: return {}
 var mode=String(payload.get("mode",""))
 if mode=="strain": return {"pulses":FEEDBACK_SHAKE_STRAIN_PULSES,"step":FEEDBACK_SHAKE_STRAIN_STEP,"damage":damage}
 if mode in ["slip","magic_slip"]: return {"pulses":FEEDBACK_SHAKE_SLIP_PULSES,"step":FEEDBACK_SHAKE_SLIP_STEP,"damage":damage}
 return {}

## Border family per committed submission: "calm", "charge", "mana" or "". Fixed
## priority calm(white) > charge/next_energy(yellow) > mana family(blue), so one
## submission that touches several families still shows exactly one border. The blue
## family triggers on any nonzero net change, so a failed cast (mana paid, half refunded,
## one focus layer burnt) selects it without any extra committed flag.
static func border_kind_of(events: Array, payload: Dictionary) -> String:
 var kind=String(payload.get("kind",""))
 if kind=="calm": return "calm"
 # The right-click charge toggle only flips charge_all and changes no receipt field,
 # so the committed payload is the only evidence that charge was loaded.
 if kind=="status_toggle" and String(payload.get("status","")) in ["charge","charge_all"]: return "charge"
 var totals=deltas(events)
 for family in FEEDBACK_BORDER_FIELDS:
  var rise_only=bool(FEEDBACK_BORDER_RISE_ONLY.get(family,false))
  for field in FEEDBACK_BORDER_FIELDS[family]:
   var delta=float(totals.get(field,0.0))
   if rise_only:
    if delta>0.0: return family
   elif delta!=0.0: return family
 return ""

## Reference scale of one blue-family field: mana uses the committed maximum when the
## View carries one, every other field its own retention scale (table above).
static func mana_reference(snapshot: Dictionary) -> float:
 var maximum=float(snapshot.get("mana_max",0.0))
 return maximum if maximum>0.0 else FEEDBACK_MANA_REFERENCE

## Normalised size of a committed blue-family change: every field's net delta divided by
## its own reference scale, then summed, so several pools paying one submission are one
## amount and the same physical movement reads smaller out of a bigger pool. The sign is
## the variant. No threshold and no minimum: a tiny movement keeps a tiny ratio.
static func mana_ratio(totals: Dictionary, snapshot: Dictionary) -> float:
 var ratio=float(totals.get("mana",0.0))/mana_reference(snapshot)
 ratio+=float(totals.get("temporary_mana",0.0))/FEEDBACK_RESERVE_REFERENCE
 ratio+=float(totals.get("witch_focus",0.0))/FEEDBACK_FOCUS_REFERENCE
 return ratio

## Peak of one blue-family variant at the given normalised change. Scaling is linear up to
## the reference scale and capped there, so the strongest read of a variant stays the
## table value and no movement is ever amplified past its own proportion.
static func mana_peak(variant: String, ratio: float) -> float:
 var row=FEEDBACK_MANA_VARIANTS.get(variant,FEEDBACK_MANA_VARIANTS["gain"])
 return float(row.alpha)*minf(absf(ratio),1.0)

## Resolved border for one committed submission: fixed families take their table row, the
## blue family takes the signed variant and its amount-scaled peak, fade, ramp and band.
static func border_spec(kind: String, totals: Dictionary, snapshot: Dictionary) -> Dictionary:
 var row=border_row(kind)
 if kind!="mana": return {"kind":kind,"variant":"","ratio":0.0,"peak":float(row.alpha),"fade":float(row.fade),"attack":0.0,"extent":FEEDBACK_EDGE_EXTENT,"color":row.color}
 var ratio=mana_ratio(totals,snapshot)
 var variant="loss" if ratio<0.0 else "gain"
 var spec=FEEDBACK_MANA_VARIANTS[variant]
 return {"kind":kind,"variant":variant,"ratio":ratio,"peak":mana_peak(variant,ratio),"fade":float(spec.fade),"attack":float(spec.attack),"extent":float(spec.extent),"color":row.color}

## Read-only row of a border family (see FEEDBACK_BORDERS). An unknown kind falls back
## to the mana row; the only caller passes a kind produced by border_kind_of.
static func border_row(kind: String) -> Dictionary:
 return FEEDBACK_BORDERS.get(kind,FEEDBACK_BORDERS["mana"])

static func will_play(events: Array, payload: Dictionary) -> bool:
 return pressure_rise(events)>0.0 or border_kind_of(events,payload)!="" or not shake_spec(payload).is_empty()

static func shake_amplitude_for(damage: float) -> float:
 return clampf(FEEDBACK_SHAKE_BASE_PX+FEEDBACK_SHAKE_PER_DAMAGE_PX*damage,FEEDBACK_SHAKE_MIN_PX,FEEDBACK_SHAKE_MAX_PX)

func _ready() -> void:
 name="ImpactFeedback"
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 z_index=FEEDBACK_Z_INDEX
 set_process(false)
 # The filter keeps the climax tint from the host; the border takes its family token
 # (calm until a committed trigger says otherwise) and is retinted by _play_border.
 var tint=FEEDBACK_FALLBACK_COLOR if host==null else host.OVERLOAD_COLOR
 bands_host=Control.new()
 bands_host.name="ImpactBandsHost"
 bands_host.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(bands_host)
 bands_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 filter_bands=Bands.new(FEEDBACK_EDGE_EXTENT,tint,FEEDBACK_VIGNETTE_BANDS,FEEDBACK_BAND_WEIGHT_CUTOFF)
 border_bands=Bands.new(FEEDBACK_EDGE_EXTENT,border_row("calm").color,FEEDBACK_VIGNETTE_BANDS,FEEDBACK_BAND_WEIGHT_CUTOFF)
 bands_host.add_child(filter_bands)
 bands_host.add_child(border_bands)
 filter=Fade.new(filter_bands)
 border=Fade.new(border_bands)
 filter.finished=_effect_finished
 border.finished=_effect_finished
 shake_target=host.get("layout") if host!=null else null
 # Fallback keeps the layer usable standalone (host without a layout property);
 # the shipped path always resolves main.gd's GameLayout.
 if not is_instance_valid(shake_target): shake_target=bands_host
 hide()

## One committed submission enters here; a submission with nothing to show is a no-op.
func play(events: Array, payload: Dictionary, snapshot: Dictionary) -> void:
 if not will_play(events,payload): return
 show()
 set_process(false)
 var rise=pressure_rise(events)
 if rise>0.0: _play_filter(rise,snapshot)
 var kind=border_kind_of(events,payload)
 var spec={} if kind=="" else border_spec(kind,deltas(events),snapshot)
 if kind!="": _play_border(spec)
 var shake=shake_spec(payload)
 if not shake.is_empty(): _play_shake(shake)
 # `border_variant` / `border_ratio` / `border_extent` are the resolved blue-family
 # reading of this submission; fixed families report the empty variant and the shared
 # band. Kept after the fade so checks can read what one submission showed.
 last_impact={"rise":rise,"filter_peak":0.0 if rise<=0.0 else filter.peak,"filter_fade":0.0 if rise<=0.0 else filter.fade,
  "border_kind":kind,"border_variant":String(spec.get("variant","")),"border_ratio":float(spec.get("ratio",0.0)),
  "border_peak":0.0 if kind=="" else border.peak,"border_fade":0.0 if kind=="" else border.fade,
  "border_attack":0.0 if kind=="" else border.attack,"border_extent":float(spec.get("extent",FEEDBACK_EDGE_EXTENT)),
  "shake_pulses":shake_pulses,"shake_step":shake_step,"shake_amplitude":shake_amplitude}

func _play_filter(rise: float, snapshot: Dictionary) -> void:
 var pressure=snapshot.get("pressure",{})
 var maximum=float(pressure.get("maximum",0.0))
 if maximum<=0.0: return
 var ratio_now=clampf(float(pressure.get("value",0.0))/maximum,0.0,1.0)
 var ratio_rise=rise/maximum
 # A rise arriving mid-fade only refreshes strength: the clock and the original fade
 # length stay, so repeated gains inside one turn never flash twice.
 if filter.active(): filter.refresh(filter_peak(ratio_now,ratio_rise))
 else: filter.start(filter_peak(ratio_now,ratio_rise),filter_fade(ratio_rise))

func _play_border(spec: Dictionary) -> void:
 border_kind=String(spec.get("kind",""))
 # The band redraws with its committed family token and extent even when the running
 # fade keeps its clock: the newest committed trigger is what the border is labelled as.
 border_bands.set_tint(spec.color)
 border_bands.set_extent(float(spec.get("extent",FEEDBACK_EDGE_EXTENT)))
 if border.active(): border.refresh(float(spec.get("peak",0.0)))
 else: border.start(float(spec.get("peak",0.0)),float(spec.get("fade",0.0)),float(spec.get("attack",0.0)))

func _play_shake(spec: Dictionary) -> void:
 # A shake arriving inside a running one merges: keep the recorded origin so the
 # restore below stays the pre-effect position, and drop the old pulse timeline.
 var continuing=shake_pulses>0
 shake_amplitude=shake_amplitude_for(float(spec.get("damage",0.0)))
 shake_pulses=int(spec.get("pulses",1))
 shake_step=float(spec.get("step",FEEDBACK_SHAKE_ATTACK_STEP))
 if continuing:
  if shake_tween!=null and shake_tween.is_valid(): shake_tween.kill()
 else: shake_origin=shake_target.position
 shake_target.position=shake_origin
 shake_tween=create_tween()
 for index in range(shake_pulses):
  var amplitude=shake_amplitude*(1.0-FEEDBACK_SHAKE_PULSE_DECAY*float(index))
  shake_tween.tween_property(shake_target,"position:x",shake_origin.x+amplitude,shake_step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
  shake_tween.tween_property(shake_target,"position:x",shake_origin.x-amplitude,shake_step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 shake_tween.tween_property(shake_target,"position:x",shake_origin.x,shake_step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 shake_tween.tween_callback(_shake_finished)

func _shake_finished() -> void:
 # Exact restore: "the layout must not change" means the post-effect frame equals
 # the pre-effect one, not that the content may never move during the pulse.
 shake_target.position=shake_origin
 shake_pulses=0
 shake_amplitude=0.0
 _hide_when_idle()

func _exit_tree() -> void:
 # A teardown mid-shake (restart, demo exit) must not leave the content container
 # displaced: the tween dies with this node, so restore here.
 if shake_pulses>0 and is_instance_valid(shake_target): shake_target.position=shake_origin

func _effect_finished() -> void:
 _hide_when_idle()

func _hide_when_idle() -> void:
 if filter.active() or border.active() or shake_pulses>0: return
 hide()
 set_process(false)

# ---------------------------------------------------------------------------
# Band rendering: concentric frames from the screen edge inward, each weighted by
# 1-(d/dmax)^2 over its own extent. Drawn once per effect because modulate carries the
# fade, so an idle layer never redraws.
# ---------------------------------------------------------------------------
class Bands extends Control:
 var reach_ratio=1.0
 var bands=1
 var color=Palette.FEEDBACK_FALLBACK
 var weight_cutoff=0.04

 func _init(extent: float, tint: Color, count: int, cutoff: float) -> void:
  reach_ratio=extent
  color=tint
  bands=maxi(1,count)
  weight_cutoff=cutoff

 ## Retint a live band; the weight profile and the modulate fade are untouched.
 func set_tint(value: Color) -> void:
  if color==value: return
  color=value
  queue_redraw()

 ## Redraw a live band at another edge extent (the blue gain/loss bands differ); the
 ## weight profile and the modulate fade are untouched.
 func set_extent(value: float) -> void:
  if is_equal_approx(reach_ratio,value): return
  reach_ratio=value
  queue_redraw()

 func _ready() -> void:
  mouse_filter=Control.MOUSE_FILTER_IGNORE
  set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  modulate.a=0.0
  resized.connect(queue_redraw)
  hide()

 func _draw() -> void:
  var half=maxf(1.0,minf(size.x,size.y)*0.5)
  var reach=maxf(2.0,half*clampf(reach_ratio,0.02,1.0))
  var width=reach/float(bands)
  for index in range(bands):
   var distance=width*(float(index)+0.5)
   var weight=1.0-pow(distance/reach,2.0)
   if weight<weight_cutoff: break
   var inset=width*float(index)
   draw_rect(Rect2(inset,inset,maxf(0.0,size.x-2.0*inset),maxf(0.0,size.y-2.0*inset)),Color(color,color.a*weight),false,width,true)

# ---------------------------------------------------------------------------
# Fade: peak-then-quadratic-decay envelope (alpha(t) = peak * (1-(t/fade)^2)) over one
# one-shot tween. `ends` is the wall clock of the running fade (ramp plus decay): a
# refresh raises the peak on the same tween and at the same elapsed time, which keeps
# a repeated trigger from restarting. `attack` is the optional ramp from zero to the peak; zero means the
# envelope starts at its peak.
# ---------------------------------------------------------------------------
class Fade:
 var node: Control
 var peak=0.0
 var fade=0.0
 var attack=0.0
 var elapsed=0.0
 var ends=0.0
 var tween
 var finished=Callable()
 # Envelope arms since creation. Refresh only changes the existing envelope's peak.
 var starts=0

 func _init(target: Control) -> void:
  node=target

 func active() -> bool:
  return ends>0.0 and Time.get_ticks_msec()<int(ends)

 func start(new_peak: float, new_fade: float, new_attack: float=0.0) -> void:
  peak=new_peak
  fade=new_fade
  attack=new_attack
  ends=float(Time.get_ticks_msec())+(new_fade+new_attack)*1000.0
  run(new_fade)

 func refresh(new_peak: float) -> void:
  if new_peak<=peak: return
  peak=new_peak
  sample(elapsed)

 func run(duration: float) -> void:
  if tween!=null and tween.is_valid(): tween.kill()
  starts+=1
  node.show()
  node.queue_redraw()
  tween=node.create_tween()
  sample(0.0)
  # Tween advances time once; the sampler reads the latest peak without replacing
  # the running timeline or introducing a resident per-frame process.
  tween.tween_method(sample,0.0,attack+duration,attack+duration)
  tween.tween_callback(finish)

 func sample(seconds: float) -> void:
  elapsed=seconds
  if attack>0.0 and elapsed<attack:
   node.modulate.a=peak*sin(elapsed/attack*PI*0.5)
  else:
   var progress=clampf((elapsed-attack)/fade,0.0,1.0)
   node.modulate.a=peak*(1.0-progress*progress)

 func finish() -> void:
  node.hide()
  node.modulate.a=0.0
  peak=0.0
  ends=0.0
  if finished.is_valid(): finished.call()
