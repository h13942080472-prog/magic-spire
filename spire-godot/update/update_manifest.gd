extends RefCounted

# docs/spec/update-check.md「清单判定」: the single update judgement. Pure functions only —
# no file, network, singleton or ProjectSettings access; the caller passes the key table, the
# current version and the platform, so the whole decision runs without a window or a network.
#
# The answer is a small dictionary, never an exception:
#   {"kind":"notice","version":String,"bytes":int,"url":String,"mirror":String,
#    "notes":String,"revoked":bool,"platform":String}
#   {"kind":"none","reason":String}
# A rejection reason is one of REJECTIONS; the empty reason means "verified, but this version
# is not newer and not revoked", which is an answer rather than a rejection.

const SCHEMA=1
const MAX_BYTES=65536
const HTTPS="https://"
const REJECTIONS=["signature","key","schema","platform","size","json","url"]

static func none(reason: String) -> Dictionary:
 return {"kind":"none","reason":reason}

# docs/spec/update-check.md「版本比较」: split on ".", compare numeric segments by value, and
# sort a non-numeric segment after a missing one. A missing segment equals a numeric 0, so
# "0.18" == "0.18.0" and "0.18.3.fix" > "0.18.3".
static func compare(a: String, b: String) -> int:
 var left=a.split(".")
 var right=b.split(".")
 for index in range(maxi(left.size(),right.size())):
  var first=_segment(left[index] if index<left.size() else "")
  var second=_segment(right[index] if index<right.size() else "")
  if first[0]!=second[0]: return 1 if first[0]>second[0] else -1
  if first[1]!=second[1]: return 1 if first[1]>second[1] else -1
 return 0

# [0, int] for a numeric segment (an empty segment is 0); [1, lower-case text] otherwise.
static func _segment(value: String) -> Array:
 var text=value.strip_edges().to_lower()
 if text.is_empty(): return [0,0]
 if text.is_valid_int(): return [0,text.to_int()]
 return [1,text]

static func evaluate(manifest_bytes: PackedByteArray, signature: PackedByteArray, keys: Dictionary, current: String, platform: String) -> Dictionary:
 # Size and parse come first: an oversized or broken document must never be parsed, verified
 # or interpreted, and its bytes are the only input the signature covers.
 if manifest_bytes.size()==0 or manifest_bytes.size()>MAX_BYTES: return none("size")
 var document=_document(manifest_bytes)
 if not document is Dictionary: return none("json")
 var manifest=document as Dictionary
 var key_id=String(manifest.get("key_id",""))
 if key_id.is_empty() or not keys.has(key_id): return none("key")
 if not _verified(manifest_bytes,signature,String(keys[key_id])): return none("signature")
 var schema=manifest.get("schema",0)
 if not (schema is int or schema is float) or int(schema)!=SCHEMA: return none("schema")
 var platforms=manifest.get("platforms",{})
 if not platforms is Dictionary or not platforms.has(platform) or not platforms[platform] is Dictionary: return none("platform")
 var release=(platforms as Dictionary)[platform].get("full",{})
 if not release is Dictionary: return none("json")
 var url=String((release as Dictionary).get("url",""))
 var mirror=String((release as Dictionary).get("mirror",""))
 if not url.begins_with(HTTPS) or not mirror.begins_with(HTTPS): return none("url")
 var latest=manifest.get("latest",{})
 if not latest is Dictionary or not (latest as Dictionary).get("version") is String: return none("json")
 var version=String((latest as Dictionary).version)
 var bytes=(release as Dictionary).get("bytes",0)
 if not (bytes is int or bytes is float) or int(bytes)<0: return none("json")
 var offer={"kind":"notice","version":version,"bytes":int(bytes),"url":url,"mirror":mirror,
  "notes":String((latest as Dictionary).get("notes_zh","")),"revoked":_revoked(manifest,current),"platform":platform}
 if offer.revoked or compare(version,current)>0: return offer
 return none("")

# A JSON parser instance keeps a malformed document a plain "no" instead of an engine error.
static func _document(manifest_bytes: PackedByteArray) -> Variant:
 var parser=JSON.new()
 if parser.parse(manifest_bytes.get_string_from_utf8())!=OK: return null
 return parser.data

# RSA PKCS#1 v1.5 over SHA-256; the signature file is base64 text of the raw signature.
static func _verified(manifest_bytes: PackedByteArray, signature: PackedByteArray, public_pem: String) -> bool:
 var text=signature.get_string_from_utf8().strip_edges()
 if text.is_empty(): return false
 var raw=Marshalls.base64_to_raw(text)
 if raw.is_empty(): return false
 var key=CryptoKey.new()
 if key.load_from_string(public_pem)!=OK: return false
 return Crypto.new().verify(HashingContext.HASH_SHA256,manifest_bytes,raw,key)

static func _revoked(manifest: Dictionary, current: String) -> bool:
 var list=manifest.get("revoked",[])
 if not list is Array: return false
 for entry in list:
  if entry is String and compare(entry,current)==0: return true
 return false
