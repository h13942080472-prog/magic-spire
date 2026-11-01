extends RefCounted
const CLASSIFICATIONS={"weak":["rope","belt","tape","cable_tie","gag","toybox","lock","small_circle","mixed_bundle","drone"],"strong":["binding_box","rope_mass","belt_mass","trader","versatile","ominous_circle","rope_serpent"],"elite":["guard","rope_heap","belt_heap","puppeteer"],"boss":["six_bind","iron_man","rope_master"]}
const VARIANTS={
 "rope_basic":{"type":"rope","grade":1},"belt_basic":{"type":"belt","grade":1},
 "tape_basic":{"type":"tape","grade":1},"cable_tie_basic":{"type":"cable_tie","grade":1},
 "gag_basic":{"type":"gag","grade":1},"toybox_basic":{"type":"toybox","grade":1},"lock_basic":{"type":"lock","grade":1}}
static func members(variants: Array) -> Array:
 var result=[]
 for id in variants: result.append(VARIANTS[id].duplicate(true))
 return result
static func entries(rank: String) -> Array:
 var result=[]
 for type in CLASSIFICATIONS.get(rank,[]): result.append({"id":type,"type":type,"rank":rank})
 return result
