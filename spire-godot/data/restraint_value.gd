extends RefCounted

# Pure backend arithmetic. Callers supply their domain's tightness (zero is valid).
# Locks, broken links and fixed-value equipment are replacement-specific rules.
static func from_profile(grade: int, tightness: int) -> int:
 return grade+tightness

# Ascending grade order preserves existing self-binding candidates and RNG draws.
# Concrete template/slot legality and random selection belong to Application.
static func profiles(restraint_value: int) -> Array:
 var result=[]
 for grade in [1,2,3]:
  var tier=restraint_value-grade
  if tier>=1 and tier<=3: result.append({"grade":grade,"tier":tier})
 return result
