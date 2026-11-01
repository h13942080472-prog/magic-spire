extends RefCounted

const Equipment=preload("res://data/equipment.gd")
const CardRules=preload("res://data/card_rules.gd")

# Text-only replacement seam. Never draw random numbers or change gameplay here.
static var texts: Dictionary={}

# Compact log numbers only; keep full precision in state and calculation records.
static func number(value: float) -> String:
 if value>0.0 and value<0.005: return "小于0.01"
 var text="%.2f" % value
 return text.trim_suffix("0").trim_suffix("0").trim_suffix(".") if text.contains(".") else text

static func equipment_result(source: String, target: String, before: float, after: float, kind: String="") -> String:
 var damage_name={"strain":"挣扎","slip":"滑脱","cut":"切割","magic":"魔法"}.get(kind,"")
 var result="%s：%s。" % [source,target]
 if damage_name!="": result+="%s点%s伤害。" % [number(maxf(0.0,before-after)),damage_name]
 return result+"\n耐久%s → %s。" % [number(before),number(after)]

static func result(log: Dictionary) -> String:
 if log.data.get("action_result",null) is String: return log.data.action_result
 if log.data.get("passive_slip",null) is Dictionary: return str(log.data.passive_slip.summary)
 return str(log.text)

static func line(cue: String, params: Dictionary, hero: bool=false) -> String:
 if texts.is_empty():
  var loaded=JSON.parse_string(FileAccess.get_file_as_string("res://data/action_copy.json"))
  if loaded is Dictionary: texts=loaded
 var fallback="" if hero else str(params.get("result","一项行动已经发生。"))
 var template=texts.get(cue,texts.get("action.default",fallback) if not hero else fallback)
 if not template is String or template.strip_edges()=="": return fallback
 return template.format(params)

static func view(logs: Array, need_climax: bool=false) -> Dictionary:
 var speech={};var speech_seen=false;var npc_speech={};var npc_seen=false;var climax={};var climax_seen=false;var actions=[]
 for i in range(logs.size()-1,-1,-1):
  var log=logs[i]
  var note=log.data.get("action_copy",{})
  if actions.size()<40 and note is Dictionary and note.get("cue",null) is String and note.get("params",null) is Dictionary:
   actions.append({"id":i,"round":log.round,"actor":str(note.params.get("actor","事件")),"text":line(note.cue,note.params),"cue":note.cue})
  elif actions.size()<40 and log.data.get("player_action",null) is Dictionary:
   var action=log.data.player_action
   var payment: Array[String]=[]
   if action.get("cost",0)>0: payment.append("%s能量" % number(action.cost))
   if action.get("temporary_mana",0)>0: payment.append("%s临时魔力" % number(action.temporary_mana))
   if action.get("mana",0)>0: payment.append("%s%s" % [number(action.mana),"魔瓶魔力" if action.get("mana_source","")=="flask" else "魔力"])
   var text=result(log)
   if not payment.is_empty(): text+="\n消耗"+"、".join(payment)+"。"
   var actor=str(log.data.get("relic_trigger",{}).get("name",action.get("actor","魔法少女")))
   actions.append({"id":i,"round":log.round,"actor":actor,"text":text,"cue":"player.result"})
  var climax_note=log.data.get("climax_copy",{})
  var is_climax_log=climax_note is Dictionary and climax_note.get("cue",null) is String
  if need_climax and not climax_seen and is_climax_log:
   climax_seen=true
   var climax_text=line(climax_note.cue,{},true)
   if climax_text!="": climax={"id":i,"text":climax_text,"cue":climax_note.cue}
  elif need_climax and not climax_seen and log.data.has("overloads"):
   # Old saves did not persist the prose cue; show the neutral authored fallback.
   climax_seen=true
   var climax_text=line("climax.narration.normal",{},true)
   if climax_text!="": climax={"id":i,"text":climax_text,"cue":"climax.narration.normal"}
  var spoken=log.data.get("hero_copy",{})
  if not speech_seen and spoken is Dictionary and spoken.get("cue",null) is String:
   speech_seen=true
   var hero_text=line(spoken.cue,{},true)
   if hero_text!="": speech={"id":i,"name":"魔法少女","text":hero_text,"cue":spoken.cue}
  elif need_climax and is_climax_log:
   # Never surface an older action line as if it belonged to the current climax.
   speech_seen=true
  var npc=log.data.get("npc_copy",{})
  if not npc_seen and npc is Dictionary and npc.get("cue",null) is String:
   npc_seen=true
   var npc_text=line(npc.cue,{},true)
   if npc_text!="": npc_speech={"id":i,"text":npc_text,"cue":npc.cue,"visual":str(npc.get("visual","guard_purple")),"phase":str(log.get("phase",""))}
  if actions.size()==40 and speech_seen and npc_seen and (climax_seen or not need_climax): break
 actions.reverse()
 return {"speech":speech,"npc_speech":npc_speech,"climax":climax,"actions":actions}

static func mouth_mode(equipment: Array) -> String:
 if equipment.is_empty(): return "clear"
 for item in equipment:
  var template=Equipment.base_template(item.get("template",""))
  if template=="mouth_tape": return "full"
  if template=="mouth_band" and Equipment.mouth_combination(int(item.get("grade",1)),int(item.get("variant",0))).insert: return "full"
  if template!="mouth_band": return "full"
 return "partial"

static func _mouth_rank(mode: String) -> int:
 return {"clear":0,"partial":1,"full":2}.get(mode,2)

static func _combined_mouth(context: Dictionary) -> String:
 var before=str(context.get("mouth_before","clear"))
 var after=str(context.get("mouth_after",before))
 return before if _mouth_rank(before)>=_mouth_rank(after) else after

static func _pleasure_stage(context: Dictionary) -> String:
 if context.get("overloaded",false): return "high"
 var value=maxf(float(context.get("pressure_before",0.0)),float(context.get("pressure_after",0.0)))
 return "high" if value>=70.0 else ("mid" if value>=40.0 else "low")

static func _card_group(payload: Dictionary, context: Dictionary) -> String:
 if context.get("uses_magic",false): return "card.magic_failed" if context.get("spell_failed",false) else "card.magic"
 var free=payload.get("free",false)
 if CardRules.SPECS.has(payload.get("type","")): free=CardRules.free_effect(payload.type,free)
 if free or payload.get("self_target",false): return "card.setup"
 var mode=str(payload.get("mode",""))
 if mode=="strain": return "card.strain"
 if mode=="slip": return "card.slip"
 return "card.setup"

static func _paid_group(payload: Dictionary, context: Dictionary) -> String:
 var kind=str(payload.get("kind",""))
 if payload.get("witch_action",false): return ""
 if kind in ["card","card_continue"] or (kind=="prison" and payload.has("uid")):
  return _card_group(payload,context)
 if kind=="attack" and payload.get("type","")=="fireball":
  return "attack.fireball_failed" if context.get("spell_failed",false) else "attack.fireball"
 if int(context.get("cost",0))<=0: return ""
 if kind=="attack":
  var attack=str(payload.get("type",""))
  return "attack.kick" if attack=="kick" else "attack.upper"
 if kind=="wall_move" or (kind=="prison" and payload.get("action","")=="explore"): return "move"
 if kind=="posture": return "posture"
 if kind=="manual":
  var family=str(context.get("manual_family",""))
  if family=="vaginal_egg": return "toy.vaginal"
  if family=="anal_egg": return "toy.anal"
  return "manual"
 if kind=="item_install": return "item.install"
 if kind=="calm": return "calm"
 if kind=="prison" and payload.get("action","")=="vent_kick": return "prison.vent"
 return ""

static func climax_cues(context: Dictionary) -> Dictionary:
 var variant="normal"
 if float(context.get("mana_before",100.0))<20.0: variant="low"
 elif int(context.get("climax_count",0))>1 or int(context.get("climax_turn_count",0))>1: variant="repeated"
 var mouth=_combined_mouth(context)
 var dialogue="hero.climax.full" if mouth=="full" else "hero.climax.%s.%s" % [variant,mouth]
 return {"dialogue":dialogue,"narration":"climax.narration."+variant}

static func hero_cue(payload: Dictionary, context: Dictionary={}) -> String:
 if payload.get("kind","")=="card" and not context.get("spell_failed",false):
  var cue=CardRules.SPECS.get(payload.get("type",""),{}).get("play_cue","")
  if cue!="": return cue
 if int(context.get("climax_count",0))>0: return climax_cues(context).dialogue
 var group=_paid_group(payload,context)
 if group=="": return ""
 var mouth=_combined_mouth(context)
 if mouth=="full": return "hero.muffled"
 return "hero.%s.%s.%s" % [group,_pleasure_stage(context),mouth]
