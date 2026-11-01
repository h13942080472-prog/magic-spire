extends RefCounted

const ROOT="res://assets/audio/girl-sound/profile-a/"
const PRIORITY=["orgasm","struggle","hit","edge"]
const POOLS={
 "edge":{"clear":["edge","Edge",25],"gagged":["gagged-edge","GagEdge",24]},
 "hit":{"clear":["hit","NoGagHit",45],"gagged":["gagged-hit","GagHit",37]},
 "orgasm":{"clear":["orgasm","Orgasm",21],"gagged":["gagged-orgasm","GagOrgasm",14]},
 "struggle":{"clear":["struggle","Struggle",[1,2,19,20,21,22,25,26]],"gagged":["gagged-struggle","GagStruggle",[1,2,3,4,5,6,7,9,13,14,15,16]]}}

static func cue(family: String, gagged: bool) -> String:
 return "voice_"+family+("_gagged" if gagged else "")

static func select_cue(cues: Array) -> String:
 for family in PRIORITY:
  for candidate in [cue(family,false),cue(family,true)]:
   if candidate in cues: return candidate
 return ""

static func pool(cue_id: String) -> Array:
 var gagged=cue_id.ends_with("_gagged")
 var family=cue_id.trim_prefix("voice_").trim_suffix("_gagged")
 if not POOLS.has(family): return []
 var definition=POOLS[family]["gagged" if gagged else "clear"]
 var indexes=range(1,int(definition[2])+1) if definition[2] is int else definition[2]
 var result=[]
 for index in indexes:
  result.append(ROOT+definition[0]+"/"+definition[1]+str(index)+".ogg")
 return result
