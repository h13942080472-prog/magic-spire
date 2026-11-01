extends RefCounted

# Reuse local transparent assets; match stable template/material facts, never labels.
const Equipment=preload("res://data/equipment.gd")
const MATERIALS={
 "rope":["rope-hemp-rough","rope-cotton-soft","rope-nylon","rope-cotton-reinforced","rope-arcane-fiber"],
 "cord":["fine-cord-hemp-rough","fine-cord-cotton-soft","fine-cord-nylon","fine-cord-cotton-reinforced","fine-cord-arcane-fiber"],
 "leather":["leather-worn","leather-soft","leather-thick","leather-reinforced","leather-arcane-sealed"],
 "fine_belt":["fine-belt-aged-thin-leather","fine-belt-soft-leather","fine-belt-cowhide","fine-belt-reinforced-leather","fine-belt-arcane-leather"],
 "tape":["tape-paper","tape-cloth","tape-duct","tape-fiber-reinforced","tape-arcane-seal"],
 "plastic":["cable-tie-plastic-cheap","cable-tie-nylon-standard","cable-tie-nylon-industrial","cable-tie-resin-reinforced","cable-tie-resin-arcane"]}
const TEMPLATES={"glove_body":"structure-armbinder","leg_body":"structure-legbinder","jacket_body":"structure-straitjacket","head_harness":"head-mouth-harness-gag","eye_cloth":"head-mouth-blindfold","eye_leather":"head-mouth-blindfold","mouth_band":"head-mouth-ball-gag"}
const SPECIAL={"urethral_rod":"focus-c-silicone-urethral-rod"}

static func path(e: Dictionary) -> String:
 if Equipment.lock_only(e): return "res://assets/ui/equipment/restriction-collar.svg"
 if Equipment.is_shackle(e):
  var proxy=e.duplicate();proxy.template="fine_belt" if e.template in ["finger_cuffs","toe_cuffs"] else "belt";proxy.material="leather"
  return path(proxy)
 var template=Equipment.base_template(e.template)
 if template=="special":
  var family=Equipment.Special.TYPES.get(e.get("type",""),{}).get("family","")
  return "res://assets/ui/equipment/"+SPECIAL[family]+".png" if SPECIAL.has(family) else ""
 var file=TEMPLATES.get(template,"")
 if file=="":
  var family=template if template in ["cord","fine_belt"] else e.get("material",Equipment.TEMPLATES.get(template,{}).get("material",""))
  if not MATERIALS.has(family): return ""
  var index=4 if e.grade==3 else (e.grade-1)*2+clampi(e.get("variant",0),0,1)
  file=MATERIALS[family][index]
 return "res://assets/ui/equipment/"+file+".png"
