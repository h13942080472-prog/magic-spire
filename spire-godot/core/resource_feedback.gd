extends RefCounted
# Transient transaction receipt; never saved or used for rule decisions.
const FIELDS={"mana":"魔力","flask_mana":"魔瓶魔力","charge":"蓄力","temporary_mana":"临时魔力","next_energy":"下回合能量","pressure":"快感","witch_focus":"精神集中"}
var previous={}
var events=[]
var sounds={}
var scoped_sounds={}
var installed=false
var damaged=false
var pleasure_gained=false

func equipment(target: Dictionary, amount: float, installation: bool=false, direct_damage: bool=true, context: Dictionary={}) -> void:
 # Incremental facts from successful writes only; scratch planning disables this receipt.
 if amount<=0: return
 if target.get("material","") in ["rope","leather"]:
  if context.has("enemy_id"):
   var event={"cue":"rope_leather_tension","enemy_id":context.enemy_id,"sequence":context.sequence,"kind":String(context.cue).trim_prefix("enemy.")}
   scoped_sounds[JSON.stringify([event.enemy_id,event.sequence,event.kind,event.cue])]=event
  else: sounds["rope_leather_tension"]=true
 if installation: installed=true
 elif direct_damage: damaged=true

func sound_events() -> Array:
 # Enemy-scoped records remain transient; voice cues keep their existing contract.
 return sounds.keys()+scoped_sounds.values().duplicate(true)

func capture(state: Dictionary, source: String="") -> void:
 for key in FIELDS:
  # witch_focus exists only on the witch character's state; every other field is
  # always present, so a missing key is skipped instead of aborting the receipt.
  if not state.has(key): continue
  var value=state[key]
  if previous.has(key) and value!=previous[key]:
   if key=="pressure" and value>previous[key]: pleasure_gained=true
   events.append({"field":key,"label":FIELDS[key],"before":previous[key],"after":value,"source":source})
  previous[key]=value

func relic(state: Dictionary, source: String) -> void:
 var count=events.size()
 capture(state,source)
 if events.size()==count: events.append({"field":"","label":source,"source":source})

func voice(card_action: bool, gagged: bool, climax_count: int) -> void:
 var family="orgasm" if climax_count>0 else ("struggle" if card_action and damaged else ("hit" if installed else ("edge" if pleasure_gained else "")))
 if family!="": sounds[preload("res://data/girl_sound_profile.gd").cue(family,gagged)]=true
