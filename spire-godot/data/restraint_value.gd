extends RefCounted

# Pure backend arithmetic. Callers supply their domain's tightness (zero is valid).
# Locks, broken links and fixed-value equipment are replacement-specific rules.
static func from_profile(grade: int, tightness: int) -> int:
 return grade+tightness

# A named item keeps its grade until slack is exhausted. Unspecified pools keep
# their grade-first budget fallback. Both axes have the same one-point floor.
static func reduced_profile(grade: int, tightness: int, reduction: int, fixed_type: bool=true) -> Dictionary:
 var remaining=maxi(0,reduction)
 if fixed_type:
  var loosen=mini(remaining,tightness-1)
  return {"grade":maxi(1,grade-(remaining-loosen)),"tier":tightness-loosen}
 var downgrade=mini(remaining,grade-1)
 return {"grade":grade-downgrade,"tier":maxi(1,tightness-(remaining-downgrade))}

# Ascending grade order preserves existing self-binding candidates and RNG draws.
# Concrete template/slot legality and random selection belong to Application.
static func profiles(restraint_value: int) -> Array:
 var result=[]
 for grade in [1,2,3]:
  var tier=restraint_value-grade
  if tier>=1 and tier<=3: result.append({"grade":grade,"tier":tier})
 return result
