extends RefCounted

# docs/spec/update-check.md「判据」: the rule side of the update check. Every judgement is a
# pure call to UpdateManifest.evaluate. Most cases sign with a freshly generated RSA pair and
# hand the verifier only its public half; the OpenSSL case replays a committed fixture (public
# PEM, manifest and signature) so the release pipeline's independent signer is pinned to the
# engine. Nothing here touches the network, the production key table or the player's files.

const Manifest=preload("res://update/update_manifest.gd")
# CC-D22-1: the startup switch is one key of the existing settings file, never a second store.
const Settings=preload("res://ui/display_settings.gd")

const PLATFORM="windows-x64"
const CURRENT="0.18.3.fix"
const URL="https://update.magicspire.xyz/v1/0.18.4/spire-v0.18.4-windows64.zip"
const MIRROR="https://github.com/h13942080472-prog/magic-spire/releases/tag/v0.18.4"
const NOTES="修复若干问题。"
const SIZE=241247340
const OFFER_FIELDS=["kind","version","bytes","url","mirror","notes","revoked","platform"]
# OpenSSL interop fixture: only the public PEM, the manifest and its signature are committed
# (the private half existed while the fixture was generated and was deleted afterwards).
const FIXTURE_DIRECTORY="res://tests/fixtures/update/"
const OPENSSL_MANIFEST=FIXTURE_DIRECTORY+"openssl-manifest.json"
const OPENSSL_SIGNATURE=FIXTURE_DIRECTORY+"openssl-manifest.json.sig"
const OPENSSL_PUBLIC_KEY=FIXTURE_DIRECTORY+"openssl-public.pem"
const OPENSSL_VERSION="0.18.4"

static func run(t) -> void:
 var pair=keypair()
 var keys={"k1":verifier_pem(pair)}
 t.check(pair.size()==2 and not keys.k1.is_empty(),"UPDATE run: the fixture can generate, save and load an RSA public key")
 newer_latest_yields_notice(t,pair,keys)
 same_or_older_latest_yields_none(t,pair,keys)
 version_order_is_numeric_per_segment(t)
 tampered_manifest_fails_signature(t,pair,keys)
 foreign_key_signature_is_rejected(t,pair,keys)
 missing_key_entry_is_rejected(t,pair,keys)
 unusable_signature_is_rejected(t,pair,keys)
 empty_key_table_yields_no_offer(t,pair)
 public_key_pem_verifies_signed_manifest(t)
 private_key_table_entry_is_rejected(t)
 openssl_signed_manifest_interops(t)
 unknown_schema_is_rejected(t,pair,keys)
 missing_platform_yields_none(t,pair,keys)
 revoked_current_yields_notice(t,pair,keys)
 oversized_or_broken_manifest_yields_none(t,pair,keys)
 non_https_url_is_rejected(t,pair,keys)
 patches_are_ignored(t,pair,keys)
 settings_toggle_uses_one_store(t)
 manifest_size_and_shape_domain(t,pair,keys)
 manifest_link_domain(t,pair,keys)
 signature_position_and_shape_domain(t,pair,keys)
 key_table_selection_domain(t)
 version_segment_edges(t)
 version_segment_digit_compare(t)
 signature_outer_whitespace_domain(t,pair,keys)
 missing_field_attribution_domain(t,pair,keys)

# ---- fixtures -------------------------------------------------------------------------

# generate_rsa returns one CryptoKey that carries both halves.
static func keypair() -> Array:
 var made=Crypto.new().generate_rsa(2048)
 return Array(made) if made is Array else [made,made]

# Godot 4.7.2 loads the public half of the pair when load_from_string is asked for public
# material; save_to_string(true) is the SPKI PEM that _verified hands to the engine. The
# verifier therefore receives public material only, exactly as the production key table does.
static func verifier_pem(pair: Array) -> String:
 return pair[0].save_to_string(true)

# schema v1 exactly as docs/spec/update-check.md「清单 schema」declares it.
static func document(version: String, overrides: Dictionary={}) -> Dictionary:
 var release={"url":URL,"mirror":MIRROR,"bytes":SIZE,"sha256":"0".repeat(64)}
 for key in overrides.get("full",{}): release[key]=overrides.full[key]
 var platforms={}
 var platform=String(overrides.get("platform",PLATFORM))
 if not platform.is_empty(): platforms[platform]={"full":release,"patches":overrides.get("patches",[])}
 return {"schema":int(overrides.get("schema",1)),"serial":3,"issued":"2026-11-20T00:00:00Z",
  "key_id":String(overrides.get("key_id","k1")),
  "latest":{"version":version,"notes_zh":String(overrides.get("notes",NOTES))},
  "revoked":overrides.get("revoked",[]),"platforms":platforms}

static func bytes_of(document_value: Dictionary) -> PackedByteArray:
 return JSON.stringify(document_value).to_utf8_buffer()

# The one temp settings path used by both sides: the switch is always exercised on a real
# file, never on the player's user:// store.
static func prefs_path() -> String:
 return "res://build/update-prefs-%d.cfg" % Time.get_ticks_usec()

# Raw bytes of a committed fixture: the signature covers exactly these bytes, so the file is
# never parsed before it is verified.
static func fixture(path: String) -> PackedByteArray:
 var handle=FileAccess.open(path,FileAccess.READ)
 if handle==null: return PackedByteArray()
 var bytes=handle.get_buffer(handle.get_length())
 handle.close()
 return bytes

# Crypto.sign takes the digest, so the fixture hashes the manifest bytes first, exactly like
# the production verifier does.
static func signature_of(body: PackedByteArray, pair: Array) -> PackedByteArray:
 var context=HashingContext.new()
 context.start(HashingContext.HASH_SHA256)
 context.update(body)
 return Marshalls.raw_to_base64(Crypto.new().sign(HashingContext.HASH_SHA256,context.finish(),pair[0])).to_utf8_buffer()

static func judge(body: PackedByteArray, pair: Array, keys: Dictionary, current: String=CURRENT, platform: String=PLATFORM) -> Dictionary:
 return Manifest.evaluate(body,signature_of(body,pair),keys,current,platform)

# ---- 判定 -----------------------------------------------------------------------------

static func newer_latest_yields_notice(t, pair: Array, keys: Dictionary) -> void:
 var offer=judge(bytes_of(document("0.18.4")),pair,keys)
 t.check(offer.get("kind","")=="notice","UPDATE newer_latest_yields_notice: a signed newer latest yields a notice: "+str(offer))
 t.check(String(offer.get("version",""))=="0.18.4" and int(offer.get("bytes",0))==SIZE,"UPDATE newer_latest_yields_notice: the notice carries the published version and size")
 t.check(String(offer.get("url",""))==URL and String(offer.get("mirror",""))==MIRROR,"UPDATE newer_latest_yields_notice: both jump targets come from the signed platform entry")
 t.check(String(offer.get("notes",""))==NOTES and offer.get("revoked",true)==false and String(offer.get("platform",""))==PLATFORM,"UPDATE newer_latest_yields_notice: notes, revoked flag and platform are explicit")
 t.check(offer.keys().all(func(key):return key in OFFER_FIELDS),"UPDATE newer_latest_yields_notice: the notice exposes no field the signature did not cover: "+str(offer.keys()))

static func same_or_older_latest_yields_none(t, pair: Array, keys: Dictionary) -> void:
 var same=judge(bytes_of(document(CURRENT)),pair,keys)
 var older=judge(bytes_of(document("0.18.3")),pair,keys)
 t.check(same.get("kind","")=="none" and same.get("reason","?")=="","UPDATE same_or_older_latest_yields_none: the current version answers none with the empty not-newer reason: "+str(same))
 t.check(older.get("kind","")=="none" and older.get("reason","?")=="","UPDATE same_or_older_latest_yields_none: an older latest never offers a downgrade: "+str(older))

static func version_order_is_numeric_per_segment(t) -> void:
 var rows=[["0.18.10","0.18.9",1],["0.18.3.fix","0.18.3",1],["0.18.3","0.18.3.fix",-1],["0.18","0.18.0",0],["0.19","0.18.99",1],["1.0","0.99.99",1]]
 for row in rows:
  t.check(signi(Manifest.compare(row[0],row[1]))==row[2],"UPDATE version_order_is_numeric_per_segment: compare("+String(row[0])+","+String(row[1])+")=="+str(row[2]))
 var versions=[]
 for major in ["0","9","10"]:
  for minor in ["0","9","10"]:
   versions.append("%s.%s" % [major,minor])
   versions.append("%s.%s.fix" % [major,minor])
 var broken=[]
 for left in versions:
  if Manifest.compare(left,left)!=0: broken.append("reflexive:"+left)
  for right in versions:
   if signi(Manifest.compare(left,right))!=-signi(Manifest.compare(right,left)): broken.append("antisymmetric:"+left+"/"+right)
 t.check(broken.is_empty(),"UPDATE version_order_is_numeric_per_segment: the order is reflexive and antisymmetric over "+str(versions.size())+" versions: "+str(broken.slice(0,4)))
 var unordered=[]
 for left in versions:
  for middle in versions:
   for right in versions:
    if Manifest.compare(left,middle)>=0 and Manifest.compare(middle,right)>=0 and Manifest.compare(left,right)<0: unordered.append(left+"/"+middle+"/"+right)
 t.check(unordered.is_empty(),"UPDATE version_order_is_numeric_per_segment: the order is transitive: "+str(unordered.slice(0,4)))

static func tampered_manifest_fails_signature(t, pair: Array, keys: Dictionary) -> void:
 var text=JSON.stringify(document("0.18.4"))
 var body=text.to_utf8_buffer()
 var signature=signature_of(body,pair)
 var bumped=Manifest.evaluate(text.replace("0.18.4","0.18.5").to_utf8_buffer(),signature,keys,CURRENT,PLATFORM)
 t.check(bumped.get("kind","")=="none" and bumped.get("reason","")=="signature","UPDATE tampered_manifest_fails_signature: a version bumped after signing is a signature failure: "+str(bumped))
 var escaped=[]
 for index in range(mini(64,body.size())):
  var mutated=body.duplicate()
  mutated[index]=0x20 if mutated[index]!=0x20 else 0x21
  if Manifest.evaluate(mutated,signature,keys,CURRENT,PLATFORM).get("kind","")!="none": escaped.append(index)
 t.check(escaped.is_empty(),"UPDATE tampered_manifest_fails_signature: every byte flip in the manifest head is rejected: "+str(escaped))
 var raw=Marshalls.base64_to_raw(signature.get_string_from_utf8())
 var weak=[]
 for index in range(mini(16,raw.size())):
  var modified=raw.duplicate()
  modified[index]=modified[index]^0xff
  var answer=Manifest.evaluate(body,Marshalls.raw_to_base64(modified).to_utf8_buffer(),keys,CURRENT,PLATFORM)
  if answer.get("kind","")!="none" or answer.get("reason","")!="signature": weak.append(index)
 t.check(raw.size()==256 and weak.is_empty(),"UPDATE tampered_manifest_fails_signature: a flipped signature byte is a signature failure: "+str(weak))

static func foreign_key_signature_is_rejected(t, pair: Array, keys: Dictionary) -> void:
 var offer=judge(bytes_of(document("0.18.4")),keypair(),keys)
 t.check(offer.get("kind","")=="none" and offer.get("reason","")=="signature","UPDATE foreign_key_signature_is_rejected: a manifest signed by another key never becomes an offer: "+str(offer))

static func missing_key_entry_is_rejected(t, pair: Array, keys: Dictionary) -> void:
 var unknown=judge(bytes_of(document("0.18.4",{"key_id":"k9"})),pair,keys)
 t.check(unknown.get("kind","")=="none" and unknown.get("reason","")=="key","UPDATE missing_key_entry_is_rejected: an unknown key_id is a key failure, not a signature failure: "+str(unknown))
 var absent=judge(bytes_of(document("0.18.4",{"key_id":""})),pair,keys)
 t.check(absent.get("kind","")=="none" and absent.get("reason","")=="key","UPDATE missing_key_entry_is_rejected: a manifest without key_id is rejected the same way: "+str(absent))

static func unusable_signature_is_rejected(t, pair: Array, keys: Dictionary) -> void:
 var body=bytes_of(document("0.18.4"))
 var empty=Manifest.evaluate(body,PackedByteArray(),keys,CURRENT,PLATFORM)
 var text=Manifest.evaluate(body,"not base64!!".to_utf8_buffer(),keys,CURRENT,PLATFORM)
 t.check(empty.get("kind","")=="none" and empty.get("reason","")=="signature","UPDATE unusable_signature_is_rejected: a missing signature is a signature failure: "+str(empty))
 t.check(text.get("kind","")=="none" and text.get("reason","")=="signature","UPDATE unusable_signature_is_rejected: non-base64 signature text is a signature failure: "+str(text))

# CC-D22-2: with no production public key the only correct answer is "key".
static func empty_key_table_yields_no_offer(t, pair: Array) -> void:
 var body=bytes_of(document("0.18.4"))
 var offer=Manifest.evaluate(body,signature_of(body,pair),{},CURRENT,PLATFORM)
 t.check(offer.get("kind","")=="none" and offer.get("reason","")=="key","UPDATE empty_key_table_yields_no_offer: an empty key table answers key instead of crashing or trusting the manifest: "+str(offer))

# The verifier is handed public material only: save_to_string(true) is the SPKI PEM that
# load_from_string reads when public_only is set, which is the shape the production table uses.
static func public_key_pem_verifies_signed_manifest(t) -> void:
 var pair=keypair()
 var public_pem=verifier_pem(pair)
 t.check(public_pem.begins_with("-----BEGIN PUBLIC KEY-----") and not public_pem.contains("PRIVATE KEY"),"UPDATE public_key_pem_verifies_signed_manifest: the fixture exports the SPKI public PEM, not the private half")
 var loaded=CryptoKey.new()
 t.check(loaded.load_from_string(public_pem,true)==OK,"UPDATE public_key_pem_verifies_signed_manifest: the engine loads the public PEM with public_only=true")
 var body=bytes_of(document("0.18.4"))
 var offer=Manifest.evaluate(body,signature_of(body,pair),{"k1":public_pem},CURRENT,PLATFORM)
 t.check(offer.get("kind","")=="notice" and String(offer.get("version",""))=="0.18.4","UPDATE public_key_pem_verifies_signed_manifest: a table holding only the public key verifies the signer's manifest: "+str(offer))

# A pasted private key is a configuration accident: the key step refuses it even though the
# signature itself would verify, so the table can never carry signing material.
static func private_key_table_entry_is_rejected(t) -> void:
 var pair=keypair()
 var private_pem=pair[0].save_to_string(false)
 t.check(private_pem.contains("PRIVATE KEY"),"UPDATE private_key_table_entry_is_rejected: the generated pair exposes a private PEM for this case")
 var body=bytes_of(document("0.18.4"))
 var offer=Manifest.evaluate(body,signature_of(body,pair),{"k1":private_pem},CURRENT,PLATFORM)
 t.check(offer.get("kind","")=="none" and offer.get("reason","")=="key","UPDATE private_key_table_entry_is_rejected: a private key in the table is a key rejection, never a verified offer: "+str(offer))

# U1b's release pipeline signs with OpenSSL (RSA PKCS#1 v1.5 + SHA-256); the committed fixture
# is the cross-implementation proof, so a release-side signer cannot drift from the engine.
static func openssl_signed_manifest_interops(t) -> void:
 var body=fixture(OPENSSL_MANIFEST)
 var signature=fixture(OPENSSL_SIGNATURE)
 var public_pem=fixture(OPENSSL_PUBLIC_KEY).get_string_from_utf8()
 t.check(body.size()>0 and signature.size()>0 and public_pem.contains("BEGIN PUBLIC KEY"),"UPDATE openssl_signed_manifest_interops: the committed fixture supplies a manifest, its signature and a public PEM")
 t.check(Marshalls.base64_to_raw(signature.get_string_from_utf8()).size()==384,"UPDATE openssl_signed_manifest_interops: the signature is the 3072-bit RSA block of the fixture key")
 var offer=Manifest.evaluate(body,signature,{"k1":public_pem},CURRENT,PLATFORM)
 t.check(offer.get("kind","")=="notice" and String(offer.get("version",""))==OPENSSL_VERSION,"UPDATE openssl_signed_manifest_interops: the OpenSSL-signed manifest verifies through evaluate: "+str(offer))
 var tampered=body.get_string_from_utf8().replace("\"version\": \"0.18.4\"","\"version\": \"0.18.5\"").to_utf8_buffer()
 var changed=0
 if tampered.size()!=body.size(): changed=-1
 else:
  for index in range(body.size()):
   if tampered[index]!=body[index]: changed+=1
 var rejected=Manifest.evaluate(tampered,signature,{"k1":public_pem},CURRENT,PLATFORM)
 t.check(changed==1 and rejected.get("kind","")=="none" and rejected.get("reason","")=="signature","UPDATE openssl_signed_manifest_interops: a one-byte edit after signing is a signature failure: "+str(rejected)+" changed="+str(changed))

static func unknown_schema_is_rejected(t, pair: Array, keys: Dictionary) -> void:
 var offer=judge(bytes_of(document("0.18.4",{"schema":2})),pair,keys)
 t.check(offer.get("kind","")=="none" and offer.get("reason","")=="schema","UPDATE unknown_schema_is_rejected: schema 2 is rejected after the signature, before any field is trusted: "+str(offer))

static func missing_platform_yields_none(t, pair: Array, keys: Dictionary) -> void:
 var offer=judge(bytes_of(document("0.18.4",{"platform":"android"})),pair,keys,PLATFORM)
 t.check(offer.get("kind","")=="none" and offer.get("reason","")=="platform","UPDATE missing_platform_yields_none: a manifest without the running platform never offers that platform's file: "+str(offer))

static func revoked_current_yields_notice(t, pair: Array, keys: Dictionary) -> void:
 var offer=judge(bytes_of(document("0.18.3",{"revoked":["0.18.3.fix"]})),pair,keys)
 t.check(offer.get("kind","")=="notice" and offer.get("revoked",false)==true,"UPDATE revoked_current_yields_notice: a revoked current version is recommended for update: "+str(offer))
 t.check(String(offer.get("version",""))=="0.18.3","UPDATE revoked_current_yields_notice: the revoked offer still names the published version")

static func oversized_or_broken_manifest_yields_none(t, pair: Array, keys: Dictionary) -> void:
 var big="a".repeat(Manifest.MAX_BYTES+1).to_utf8_buffer()
 var over=Manifest.evaluate(big,signature_of(big,pair),keys,CURRENT,PLATFORM)
 t.check(over.get("kind","")=="none" and over.get("reason","")=="size","UPDATE oversized_or_broken_manifest_yields_none: a manifest above the size cap is rejected before parsing: "+str(over))
 var broken="{this is not json".to_utf8_buffer()
 var bad=Manifest.evaluate(broken,signature_of(broken,pair),keys,CURRENT,PLATFORM)
 t.check(bad.get("kind","")=="none" and bad.get("reason","")=="json","UPDATE oversized_or_broken_manifest_yields_none: a broken document answers none without an engine error: "+str(bad))

static func non_https_url_is_rejected(t, pair: Array, keys: Dictionary) -> void:
 var plain=judge(bytes_of(document("0.18.4",{"full":{"url":"http://update.magicspire.xyz/v1/plain.zip"}})),pair,keys)
 var mirror=judge(bytes_of(document("0.18.4",{"full":{"mirror":"ftp://example.test/spire.zip"}})),pair,keys)
 t.check(plain.get("kind","")=="none" and plain.get("reason","")=="url","UPDATE non_https_url_is_rejected: a plain-http target is refused even when signed: "+str(plain))
 t.check(mirror.get("kind","")=="none" and mirror.get("reason","")=="url","UPDATE non_https_url_is_rejected: the mirror is held to the same https rule: "+str(mirror))

static func patches_are_ignored(t, pair: Array, keys: Dictionary) -> void:
 var patch={"version":"0.18.4","engine":"4.7.2","base_pck_sha256":"0".repeat(64),"save_revision":3,
  "url":"https://update.magicspire.xyz/v1/0.18.4/patch.zip","bytes":1024,"sha256":"0".repeat(64),"requires_full":false}
 var offer=judge(bytes_of(document("0.18.4",{"patches":[patch]})),pair,keys)
 t.check(offer.get("kind","")=="notice" and not offer.has("patches"),"UPDATE patches_are_ignored: U1 never reads the patch array and never offers one: "+str(offer))

# CC-D22-1: one key in the existing file, no second store and no new user:// file.
static func settings_toggle_uses_one_store(t) -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
 var path=prefs_path()
 var settings=Settings.new()
 settings.path=path;settings.persistence_enabled=true
 settings.set_update_check(false)
 var config=ConfigFile.new()
 var readable=config.load(path)==OK
 t.check(readable and config.get_value("update","check_on_start",true)==false,"UPDATE settings_toggle_uses_one_store: the switch saves update/check_on_start=false")
 t.check(readable and config.get_value("display","vsync_enabled",null)!=null and config.get_value("localization","locale",null)!=null,"UPDATE settings_toggle_uses_one_store: the switch shares the existing settings file instead of a second store")
 t.check(Settings.new().update_check_enabled,"UPDATE settings_toggle_uses_one_store: a fresh install starts with the startup check on")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

# ---- 输入域穷举（H2）-----------------------------------------------------------------

# A schema-1 document padded with trailing JSON whitespace to exactly the byte cap. Trailing
# spaces are legal JSON, so the only thing that can reject it is the size check itself.
static func document_at_cap() -> PackedByteArray:
 var body=JSON.stringify(document("0.18.4"))
 return (body+" ".repeat(Manifest.MAX_BYTES-body.to_utf8_buffer().size())).to_utf8_buffer()

static func document_with_latest(latest_value: Variant) -> PackedByteArray:
 var manifest=document("0.18.4")
 manifest.latest={"version":latest_value,"notes_zh":NOTES}
 return JSON.stringify(manifest).to_utf8_buffer()

static func manifest_size_and_shape_domain(t, pair: Array, keys: Dictionary) -> void:
 var exact=document_at_cap()
 t.check(exact.size()==Manifest.MAX_BYTES,"UPDATE manifest_size_and_shape_domain: the fixture is exactly the byte cap: "+str(exact.size()))
 var at_cap=judge(exact,pair,keys)
 t.check(at_cap.get("kind","")=="notice" and String(at_cap.get("version",""))=="0.18.4","UPDATE manifest_size_and_shape_domain: a document exactly at the cap is accepted, not refused as oversized: "+str(at_cap))
 var over=exact.duplicate();over.append(0x20)
 var over_answer=judge(over,pair,keys)
 t.check(over_answer.get("kind","")=="none" and over_answer.get("reason","")=="size","UPDATE manifest_size_and_shape_domain: one byte above the cap is a size rejection: "+str(over_answer))
 var empty=Manifest.evaluate(PackedByteArray(),PackedByteArray(),keys,CURRENT,PLATFORM)
 t.check(empty.get("kind","")=="none" and empty.get("reason","")=="size","UPDATE manifest_size_and_shape_domain: an empty body is a size rejection, never parsed or hashed: "+str(empty))
 var not_utf8=judge(PackedByteArray([0x7b,0xff,0xfe,0x7d]),pair,keys)
 t.check(not_utf8.get("kind","")=="none" and not_utf8.get("reason","")=="json","UPDATE manifest_size_and_shape_domain: a body that is not UTF-8 JSON is a json rejection, not an engine error: "+str(not_utf8))
 var typed=judge(document_with_latest(1),pair,keys)
 t.check(typed.get("kind","")=="none" and typed.get("reason","")=="json","UPDATE manifest_size_and_shape_domain: an integer latest.version is a json shape rejection: "+str(typed))

static func manifest_link_domain(t, pair: Array, keys: Dictionary) -> void:
 var variants={
  "upper_scheme":"HTTPS://update.magicspire.xyz/v1/x.zip",
  "single_slash":"https:/update.magicspire.xyz/v1/x.zip",
  "protocol_relative":"//update.magicspire.xyz/v1/x.zip",
 }
 for name in variants:
  var answer=judge(bytes_of(document("0.18.4",{"full":{"url":variants[name]}})),pair,keys)
  t.check(answer.get("kind","")=="none" and answer.get("reason","")=="url","UPDATE manifest_link_domain: url variant "+name+" is refused as url: "+str(answer))
 var manifest=document("0.18.4")
 manifest.platforms[PLATFORM].full.erase("mirror")
 var absent=judge(JSON.stringify(manifest).to_utf8_buffer(),pair,keys)
 t.check(absent.get("kind","")=="none" and absent.get("reason","")=="url","UPDATE manifest_link_domain: an absent mirror is the same url rejection as a non-https one: "+str(absent))

static func signature_position_and_shape_domain(t, pair: Array, keys: Dictionary) -> void:
 var body=bytes_of(document("0.18.4"))
 var signature=signature_of(body,pair)
 var text=signature.get_string_from_utf8()
 var raw=Marshalls.base64_to_raw(text)
 t.check(raw.size()==256,"UPDATE signature_position_and_shape_domain: the fixture signature is a 2048-bit RSA block: "+str(raw.size()))
 var escaped=[]
 for position in [0,raw.size()/2,raw.size()-1]:
  var mutated=raw.duplicate()
  mutated[position]=mutated[position]^0xff
  var answer=Manifest.evaluate(body,Marshalls.raw_to_base64(mutated).to_utf8_buffer(),keys,CURRENT,PLATFORM)
  if answer.get("kind","")!="none" or answer.get("reason","")!="signature": escaped.append(position)
 t.check(escaped.is_empty(),"UPDATE signature_position_and_shape_domain: a flipped signature byte at the head, middle or tail is a signature failure: "+str(escaped))
 for whitespace in [" ","\n"]:
  var spaced=(text.substr(0,64)+whitespace+text.substr(65)).to_utf8_buffer()
  var answer=Manifest.evaluate(body,spaced,keys,CURRENT,PLATFORM)
  t.check(answer.get("kind","")=="none" and answer.get("reason","")=="signature","UPDATE signature_position_and_shape_domain: base64 with an internal "+("space" if whitespace==" " else "newline")+" is not base64 and is a signature failure: "+str(answer))
 var truncated=Manifest.evaluate(body,text.substr(0,text.length()-1).to_utf8_buffer(),keys,CURRENT,PLATFORM)
 t.check(truncated.get("kind","")=="none" and truncated.get("reason","")=="signature","UPDATE signature_position_and_shape_domain: a truncated base64 block is a signature failure: "+str(truncated))

static func key_table_selection_domain(t) -> void:
 var first=keypair()
 var second=keypair()
 var keys={"k1":verifier_pem(first),"k2":verifier_pem(second)}
 var body=bytes_of(document("0.18.4",{"key_id":"k2"}))
 var selected=Manifest.evaluate(body,signature_of(body,second),keys,CURRENT,PLATFORM)
 t.check(selected.get("kind","")=="notice" and String(selected.get("version",""))=="0.18.4","UPDATE key_table_selection_domain: key_id selecting the second entry verifies with that entry's public key: "+str(selected))
 var mismatch=Manifest.evaluate(body,signature_of(body,first),keys,CURRENT,PLATFORM)
 t.check(mismatch.get("kind","")=="none" and mismatch.get("reason","")=="signature","UPDATE key_table_selection_domain: a signature from another table entry never verifies the selected key_id: "+str(mismatch))
 var padded="\n  "+verifier_pem(second)+"\n  "
 var tolerant=Manifest.evaluate(body,signature_of(body,second),{"k1":verifier_pem(first),"k2":padded},CURRENT,PLATFORM)
 t.check(tolerant.get("kind","")=="notice","UPDATE key_table_selection_domain: a public PEM with surrounding whitespace still loads and verifies: "+str(tolerant))

static func version_segment_edges(t) -> void:
 var long="a".repeat(200)
 var rows=[["1.0","1.0.0.0",0],["01.0","1.0",0],["1.00","1.0",0],[long,long,0],["1."+long+"b","1."+long,1],["1."+long,"1."+long+"b",-1]]
 for row in rows:
  t.check(signi(Manifest.compare(row[0],row[1]))==row[2],"UPDATE version_segment_edges: compare("+String(row[0]).left(24)+","+String(row[1]).left(24)+")=="+str(row[2]))
 t.check(Manifest.compare("1.0","1.0.0.0")==0 and Manifest.compare("1.0.0.0","1.0")==0,"UPDATE version_segment_edges: missing trailing segments equal numeric zero in both directions")
 t.check(Manifest.compare("01.0","1.0")==0 and Manifest.compare("1.007","1.7")==0,"UPDATE version_segment_edges: leading zeros compare by numeric value, not by text")

# CC-D22-4: numeric segments compare as decimal digit strings. is_valid_int()/to_int() used to
# overflow int64 on a 20-digit segment, print an engine ERROR and collapse two different
# versions to a tie. The rows below are the gherkin boundary table plus the overflow case.
static func version_segment_digit_compare(t) -> void:
 var overlong="99999999999999999999"
 var overlong_lower="99999999999999999998"
 t.check(Manifest.compare("1."+overlong,"1."+overlong_lower)==1,"UPDATE version_segment_digit_compare: a 20-digit segment compares digit by digit instead of overflowing int64: "+str(Manifest.compare("1."+overlong,"1."+overlong_lower)))
 t.check(Manifest.compare("1."+overlong_lower,"1."+overlong)==-1,"UPDATE version_segment_digit_compare: the 20-digit order is antisymmetric")
 t.check(Manifest.compare("1."+overlong,"1."+overlong)==0,"UPDATE version_segment_digit_compare: an equal 20-digit segment is a tie")
 t.check(Manifest.compare("1."+overlong,"1.1"+"0".repeat(20))==-1,"UPDATE version_segment_digit_compare: one extra digit wins over the same leading digit")
 t.check(Manifest.compare("0.18.10","0.18.9")==1,"UPDATE version_segment_digit_compare: the gherkin boundary 0.18.10>0.18.9 still holds")
 t.check(Manifest.compare("01","1")==0,"UPDATE version_segment_digit_compare: leading zeros are stripped before the length comparison")
 t.check(Manifest.compare("1.007","1.7")==0,"UPDATE version_segment_digit_compare: a padded numeric segment keeps its numeric value")
 t.check(Manifest.compare("1."+"0".repeat(20),"1.0")==0,"UPDATE version_segment_digit_compare: an all-zero segment of any length equals numeric zero")

# CC-D22-5: the signature file is a single base64 line. Outer whitespace and line breaks are
# tolerated by strip_edges(); internal whitespace is not base64 and stays a signature rejection
# (signature_position_and_shape_domain). U1b must emit one line with `openssl base64 -A`.
static func signature_outer_whitespace_domain(t, pair: Array, keys: Dictionary) -> void:
 var body=bytes_of(document("0.18.4"))
 var text=signature_of(body,pair).get_string_from_utf8()
 var variants={"a trailing newline":text+"\n","a leading newline":"\n"+text,"spaces and line breaks at both ends":" \n"+text+"\n "}
 for name in variants:
  var answer=Manifest.evaluate(body,variants[name].to_utf8_buffer(),keys,CURRENT,PLATFORM)
  t.check(answer.get("kind","")=="notice" and String(answer.get("version",""))=="0.18.4","UPDATE signature_outer_whitespace_domain: a signature file with "+name+" still verifies: "+str(answer))

# CC-D22-6: attribution is per field. A latest without a string version is a shape failure
# (json); a missing or empty full.url is a link failure (url), never json. The two checks are
# interleaved in evaluate: the links come first, so a manifest with both defects answers url.
static func missing_field_attribution_domain(t, pair: Array, keys: Dictionary) -> void:
 var without_version=document("0.18.4")
 without_version.latest={"notes_zh":NOTES}
 var no_version=judge(JSON.stringify(without_version).to_utf8_buffer(),pair,keys)
 t.check(no_version.get("kind","")=="none" and no_version.get("reason","")=="json","UPDATE missing_field_attribution_domain: a latest without version is a json shape rejection: "+str(no_version))
 var without_latest=document("0.18.4")
 without_latest.erase("latest")
 var no_latest=judge(JSON.stringify(without_latest).to_utf8_buffer(),pair,keys)
 t.check(no_latest.get("kind","")=="none" and no_latest.get("reason","")=="json","UPDATE missing_field_attribution_domain: an absent latest is the same json rejection: "+str(no_latest))
 var without_url=document("0.18.4")
 without_url.platforms[PLATFORM].full.erase("url")
 var no_url=judge(JSON.stringify(without_url).to_utf8_buffer(),pair,keys)
 t.check(no_url.get("kind","")=="none" and no_url.get("reason","")=="url","UPDATE missing_field_attribution_domain: a full block without url is a url rejection, not json: "+str(no_url))
 var empty_url=judge(bytes_of(document("0.18.4",{"full":{"url":""}})),pair,keys)
 t.check(empty_url.get("kind","")=="none" and empty_url.get("reason","")=="url","UPDATE missing_field_attribution_domain: an empty url is the same url rejection: "+str(empty_url))
 var both=document("0.18.4")
 both.latest={"notes_zh":NOTES}
 both.platforms[PLATFORM].full.erase("url")
 var both_answer=judge(JSON.stringify(both).to_utf8_buffer(),pair,keys)
 t.check(both_answer.get("kind","")=="none" and both_answer.get("reason","")=="url","UPDATE missing_field_attribution_domain: the link check runs first, so a missing url wins over a missing latest version: "+str(both_answer))
