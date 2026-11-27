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
# The signature file is base64 text; the alphabet check keeps a garbled answer a plain "no"
# instead of an engine error from the decoder.
const BASE64_ALPHABET="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="

static func none(reason: String) -> Dictionary:
 return {"kind":"none","reason":reason}

# docs/spec/update-check.md「版本比较」: split on ".", compare numeric segments as decimal digit
# strings, and sort a non-numeric segment after a missing one. A missing segment equals a
# numeric 0, so "0.18" == "0.18.0" and "0.18.3.fix" > "0.18.3". Numeric segments never pass
# through is_valid_int()/to_int(): a 20-digit segment overflows int64 and collapses two
# different versions to a tie.
static func compare(a: String, b: String) -> int:
 var left=a.split(".")
 var right=b.split(".")
 for index in range(maxi(left.size(),right.size())):
  var first_segment=_segment(left[index] if index<left.size() else "")
  var second_segment=_segment(right[index] if index<right.size() else "")
  # _segment tags its answer: 0 = canonical decimal digits, 1 = text; every numeric segment
  # sorts before every text segment.
  var first_kind=int(first_segment[0])
  var second_kind=int(second_segment[0])
  if first_kind!=second_kind: return 1 if first_kind>second_kind else -1
  var first_text=String(first_segment[1])
  var second_text=String(second_segment[1])
  # Numeric segments are digit strings: more digits is larger; equal lengths compare digit by digit.
  if first_kind==0 and first_text.length()!=second_text.length():
   return 1 if first_text.length()>second_text.length() else -1
  if first_text!=second_text: return 1 if first_text>second_text else -1
 return 0

# [0, canonical decimal digits] for a numeric segment (an empty segment is 0); [1, lower-case
# text] otherwise. A segment is numeric only when every character is 0-9, so a sign-prefixed or
# other text segment keeps the non-numeric ordering. Surrounding whitespace is not part of a
# segment, and text segments compare case-insensitively (the text is lower-cased once).
static func _segment(value: String) -> Array:
 var text=value.strip_edges().to_lower()
 if text.is_empty(): return [0,"0"]
 for index in text.length():
  if text[index]<"0" or text[index]>"9": return [1,text]
 # Drop leading zeros; an all-zero segment is "0" regardless of its length.
 var start=0
 while start<text.length()-1 and text[start]=="0": start+=1
 return [0,text.substr(start)]

static func evaluate(manifest_bytes: PackedByteArray, signature: PackedByteArray, keys: Dictionary, current: String, platform: String) -> Dictionary:
 # Size and parse come first: an oversized or broken document must never be parsed, verified
 # or interpreted, and its bytes are the only input the signature covers.
 if manifest_bytes.size()==0 or manifest_bytes.size()>MAX_BYTES: return none("size")
 var document=_document(manifest_bytes)
 if not document is Dictionary: return none("json")
 var manifest=document as Dictionary
 var key_id=String(manifest.get("key_id",""))
 if key_id.is_empty() or not keys.has(key_id): return none("key")
 var public_pem=String(keys[key_id])
 if not _public_material(public_pem): return none("key")
 if not _verified(manifest_bytes,signature,public_pem): return none("signature")
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

# The key table holds public material only. A pasted private key is a configuration accident
# rather than a failed signature, so it is refused at the key step; both PEM spellings
# ("PRIVATE KEY" / "RSA PRIVATE KEY") carry the marker and the base64 body cannot contain a
# space, so a genuine public PEM never matches.
static func _public_material(pem: String) -> bool:
 return not pem.is_empty() and not pem.contains("PRIVATE KEY")

# RSA PKCS#1 v1.5 over SHA-256; the signature file is base64 text of the raw signature.
# Crypto.verify takes the digest, so the signed bytes are hashed once here. public_only=true is
# required: without it the engine reads the payload as a private key and an SPKI public PEM
# fails with "Error parsing key", which would make every published signature unverifiable.
static func _verified(manifest_bytes: PackedByteArray, signature: PackedByteArray, public_pem: String) -> bool:
 var text=signature.get_string_from_utf8().strip_edges()
 if text.is_empty() or text.length()%4!=0: return false
 for index in text.length():
  if not BASE64_ALPHABET.contains(text[index]): return false
 var raw=Marshalls.base64_to_raw(text)
 if raw.is_empty(): return false
 var key=CryptoKey.new()
 if key.load_from_string(public_pem,true)!=OK: return false
 return Crypto.new().verify(HashingContext.HASH_SHA256,_digest(manifest_bytes),raw,key)

# SHA-256 of the signed bytes: this digest is what the Crypto API signs and verifies.
static func _digest(bytes: PackedByteArray) -> PackedByteArray:
 var context=HashingContext.new()
 context.start(HashingContext.HASH_SHA256)
 context.update(bytes)
 return context.finish()

static func _revoked(manifest: Dictionary, current: String) -> bool:
 var list=manifest.get("revoked",[])
 if not list is Array: return false
 for entry in list:
  if entry is String and compare(entry,current)==0: return true
 return false
