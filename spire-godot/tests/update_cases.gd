extends RefCounted

# docs/spec/update-check.md「判据」: the rule side of the update check. Every judgement is a
# pure call to UpdateManifest.evaluate. Most cases sign with a freshly generated RSA pair and
# hand the verifier only its public half; the OpenSSL case replays a committed fixture (public
# PEM, manifest and signature) so the release pipeline's independent signer is pinned to the
# engine, and the release-scripts case replays what tools/update-manifest.ps1 and
# tools/sign-update-manifest.ps1 produced. The production key table is only read, by its pin;
# nothing here touches the network or the player's files.

const Manifest=preload("res://update/update_manifest.gd")
const Keys=preload("res://update/update_keys.gd")
# The startup switch is one key of the existing settings file, never a second store.
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
# Production key: the DER sha256 of the k1 public key the maintainer generated offline
# (`openssl pkey -pubin -outform DER | sha256` over the PEM in update/update_keys.gd).
const PRODUCTION_KEY_ID="k1"
const PRODUCTION_KEY_DER_SHA256="a4311195c39051d64a0fc5bec6352316eebc9a836d93f0982d52006bcbb8727c"
# Release-scripts fixture: tools/update-manifest.ps1 built manifest.json from the committed
# inputs (notes.txt, android-package-manifest.json in tools/package-android.ps1's shape, and
# windows.zip) with the links below, -Serial 4, -KeyId t1 and -Revoked 0.18.3;
# tools/sign-update-manifest.ps1 signed it through its -KeyTable test seam with a one-time key
# whose private half was deleted.
const RELEASE_DIRECTORY=FIXTURE_DIRECTORY+"release-scripts/"
const RELEASE_KEY_ID="t1"
const RELEASE_VERSION="0.18.4"
const RELEASE_SERIAL=4
const RELEASE_REVOKED=["0.18.3"]
const RELEASE_LINKS={
 "windows-x64":["https://update.magicspire.xyz/v1/0.18.4/spire-v0.18.4-windows64.zip","https://github.com/h13942080472-prog/magic-spire/releases/tag/v0.18.4"],
 "android":["https://update.magicspire.xyz/v1/0.18.4/spire-v0.18.4.apk","https://github.com/h13942080472-prog/magic-spire/releases/tag/v0.18.4"],
}

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
 production_key_table_pins_k1(t)
 public_key_pem_verifies_signed_manifest(t)
 private_key_table_entry_is_rejected(t)
 openssl_signed_manifest_interops(t)
 release_scripts_manifest_interops(t)
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
 boot_mounts_verified_pending(t)
 boot_skips_bad_patch_and_records_failure(t)
 boot_resets_on_baseline_change(t)
 boot_replaces_active_with_pending(t)
 boot_falls_back_to_active_when_pending_fails(t)
 boot_skips_crash_residue(t)
 boot_is_inert_under_script(t)
 effective_version_follows_mount(t)
 effective_version_requires_mount(t)
 patch_file_verification_domain(t)
 store_rejects_hostile_state(t)
 main_scene_is_boot_scene(t)
 engine_mounter_loads_a_real_pack(t)

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

# SHA-256 (hex) of the DER that a PEM body encodes; the BEGIN/END lines are not part of it.
# This is the value `openssl pkey -pubin -outform DER | sha256` prints for a public PEM.
static func pem_der_sha256(pem: String) -> String:
 var body=""
 for line in pem.replace("\r","").split("\n"):
  var text=line.strip_edges()
  if not text.is_empty() and not text.begins_with("-----"): body+=text
 var der=Marshalls.base64_to_raw(body) if not body.is_empty() else PackedByteArray()
 if der.is_empty(): return ""
 var context=HashingContext.new()
 context.start(HashingContext.HASH_SHA256)
 context.update(der)
 return context.finish().hex_encode()

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

# An empty key table answers "key". The table is passed explicitly: the production
# table carries k1, and its shape is pinned by production_key_table_pins_k1.
static func empty_key_table_yields_no_offer(t, pair: Array) -> void:
 var body=bytes_of(document("0.18.4"))
 var offer=Manifest.evaluate(body,signature_of(body,pair),{},CURRENT,PLATFORM)
 t.check(offer.get("kind","")=="none" and offer.get("reason","")=="key","UPDATE empty_key_table_yields_no_offer: an empty key table answers key instead of crashing or trusting the manifest: "+str(offer))

# The production table holds exactly the maintainer's k1 public key. The pin is the SHA-256
# of the DER that the PEM body encodes, so one edited character of the pasted key is red here.
# The table must also pass evaluate's key step as it is (public material only, no private PEM):
# a k1 manifest with an unverifiable signature then fails at signature, never at key.
static func production_key_table_pins_k1(t) -> void:
 var table=Keys.KEYS
 t.check(table.size()==1 and table.has(PRODUCTION_KEY_ID),"UPDATE production_key_table_pins_k1: the production table holds exactly one entry, k1: "+str(table.keys()))
 var pem=String(table.get(PRODUCTION_KEY_ID,""))
 var block=pem.strip_edges()
 t.check(block.begins_with("-----BEGIN PUBLIC KEY-----") and block.ends_with("-----END PUBLIC KEY-----") and block.count("-----BEGIN ")==1,"UPDATE production_key_table_pins_k1: k1 is exactly one SPKI public PEM block and nothing else")
 var zeros=PackedByteArray()
 zeros.resize(384)
 var unsigned=Manifest.evaluate(bytes_of(document("0.18.4")),Marshalls.raw_to_base64(zeros).to_utf8_buffer(),table,CURRENT,PLATFORM)
 t.check(unsigned.get("kind","")=="none" and unsigned.get("reason","")=="signature","UPDATE production_key_table_pins_k1: the production table passes evaluate's key step as public material; only the signature fails: "+str(unsigned))
 var loaded=CryptoKey.new()
 t.check(not pem.is_empty() and loaded.load_from_string(pem,true)==OK,"UPDATE production_key_table_pins_k1: the engine loads k1 with public_only=true")
 var digest=pem_der_sha256(pem)
 t.check(digest==PRODUCTION_KEY_DER_SHA256,"UPDATE production_key_table_pins_k1: the k1 DER sha256 is the maintainer's key: "+digest)

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

# The release pipeline signs with OpenSSL (RSA PKCS#1 v1.5 + SHA-256); the committed fixture
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

# The release scripts' own output verifies through evaluate on both platforms and carries
# exactly the scripts' inputs. Android bytes/sha256 must equal the package manifest they were
# copied from; the Windows pair must equal an independent hash of the committed ZIP (in the
# release pipeline the generator is the only place that hashes it). One byte changed after
# signing is a signature failure.
static func release_scripts_manifest_interops(t) -> void:
 var names=["manifest.json","manifest.json.sig","public.pem","notes.txt","android-package-manifest.json","windows.zip"]
 var missing=names.filter(func(name):return not FileAccess.file_exists(RELEASE_DIRECTORY+name))
 t.check(missing.is_empty(),"UPDATE release_scripts_manifest_interops: the committed fixture supplies the scripts' manifest, its signature, the one-time public PEM and the three inputs: missing="+str(missing))
 if not missing.is_empty(): return
 var body=fixture(RELEASE_DIRECTORY+"manifest.json")
 var signature=fixture(RELEASE_DIRECTORY+"manifest.json.sig")
 var public_pem=fixture(RELEASE_DIRECTORY+"public.pem").get_string_from_utf8()
 var notes=fixture(RELEASE_DIRECTORY+"notes.txt").get_string_from_utf8().replace("\r\n","\n").strip_edges()
 var package_json=JSON.new()
 var package_read=package_json.parse(fixture(RELEASE_DIRECTORY+"android-package-manifest.json").get_string_from_utf8())==OK and package_json.data is Dictionary
 var zip_path=RELEASE_DIRECTORY+"windows.zip"
 t.check(package_read and not notes.is_empty() and public_pem.contains("BEGIN PUBLIC KEY"),"UPDATE release_scripts_manifest_interops: the inputs parse: the package manifest is a JSON object, the notes are not empty and the PEM is public")
 if not package_read: return
 var line=signature.get_string_from_utf8().strip_edges()
 t.check(not line.contains("\n") and Marshalls.base64_to_raw(line).size()==384,"UPDATE release_scripts_manifest_interops: the signature is one base64 line holding a 3072-bit RSA block")
 var inputs={
  "windows-x64":{"bytes":fixture(zip_path).size(),"sha256":FileAccess.get_sha256(zip_path)},
  "android":{"bytes":int(package_json.data.get("bytes",-1)),"sha256":String(package_json.data.get("sha256",""))},
 }
 var keys={RELEASE_KEY_ID:public_pem}
 for platform in RELEASE_LINKS:
  var expected={"kind":"notice","version":RELEASE_VERSION,"bytes":int(inputs[platform].bytes),"url":RELEASE_LINKS[platform][0],
   "mirror":RELEASE_LINKS[platform][1],"notes":notes,"revoked":false,"platform":platform}
  var offer=Manifest.evaluate(body,signature,keys,CURRENT,platform)
  var wrong=expected.keys().filter(func(key):return not offer.has(key) or offer[key]!=expected[key])
  t.check(wrong.is_empty() and offer.size()==expected.size(),"UPDATE release_scripts_manifest_interops: "+platform+" verifies to a notice carrying exactly the script inputs: wrong="+str(wrong)+" "+str(offer))
  var revoked=Manifest.evaluate(body,signature,keys,RELEASE_REVOKED[0],platform)
  t.check(revoked.get("kind","")=="notice" and revoked.get("revoked",false)==true,"UPDATE release_scripts_manifest_interops: "+platform+": the -Revoked version is recommended for update: "+str(revoked))
 var parser=JSON.new()
 var signed=parser.parse(body.get_string_from_utf8())==OK and parser.data is Dictionary
 t.check(signed and int(parser.data.get("serial",0))==RELEASE_SERIAL and String(parser.data.get("key_id",""))==RELEASE_KEY_ID and parser.data.get("revoked",null)==RELEASE_REVOKED,"UPDATE release_scripts_manifest_interops: serial, key_id and the revoked list are the script inputs")
 if not signed: return
 for platform in RELEASE_LINKS:
  var entry=(parser.data.platforms as Dictionary).get(platform,{})
  var full=entry.get("full",{}) if entry is Dictionary else {}
  t.check(String(full.get("sha256",""))==String(inputs[platform].sha256) and int(full.get("bytes",-1))==int(inputs[platform].bytes) and entry.get("patches",null)==[],"UPDATE release_scripts_manifest_interops: "+platform+" bytes/sha256 come from its single hash source and patches is empty: "+str(full))
 var tampered=body.get_string_from_utf8().replace("\"serial\": 4","\"serial\": 5").to_utf8_buffer()
 var changed=0
 if tampered.size()!=body.size(): changed=-1
 else:
  for index in range(body.size()):
   if tampered[index]!=body[index]: changed+=1
 for platform in RELEASE_LINKS:
  var rejected=Manifest.evaluate(tampered,signature,keys,CURRENT,platform)
  t.check(changed==1 and rejected.get("kind","")=="none" and rejected.get("reason","")=="signature","UPDATE release_scripts_manifest_interops: "+platform+": a one-byte edit after signing is a signature failure: "+str(rejected)+" changed="+str(changed))

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
 t.check(offer.get("kind","")=="notice" and not offer.has("patches"),"UPDATE patches_are_ignored: the update check never reads the patch array and never offers one: "+str(offer))

# One key in the existing file, no second store and no new user:// file.
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

# ---- 输入域穷举 -----------------------------------------------------------------

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
 t.check(Manifest.compare("0.18.3.FIX","0.18.3.fix")==0,"UPDATE version_segment_edges: text segments compare case-insensitively")
 t.check(Manifest.compare("0.18.3. fix ","0.18.3.fix")==0,"UPDATE version_segment_edges: whitespace around a segment is not part of it")
 t.check(Manifest.compare("0.18..1","0.18.0.1")==0,"UPDATE version_segment_edges: an explicit empty segment equals numeric zero")

# Numeric segments compare as decimal digit strings. is_valid_int()/to_int() used to
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

# The signature file is a single base64 line. Outer whitespace and line breaks are
# tolerated by strip_edges(); internal whitespace is not base64 and stays a signature rejection
# (signature_position_and_shape_domain). The release script must emit one line with `openssl base64 -A`.
static func signature_outer_whitespace_domain(t, pair: Array, keys: Dictionary) -> void:
 var body=bytes_of(document("0.18.4"))
 var text=signature_of(body,pair).get_string_from_utf8()
 var variants={"a trailing newline":text+"\n","a leading newline":"\n"+text,"spaces and line breaks at both ends":" \n"+text+"\n "}
 for name in variants:
  var answer=Manifest.evaluate(body,variants[name].to_utf8_buffer(),keys,CURRENT,PLATFORM)
  t.check(answer.get("kind","")=="notice" and String(answer.get("version",""))=="0.18.4","UPDATE signature_outer_whitespace_domain: a signature file with "+name+" still verifies: "+str(answer))

# Attribution is per field. A latest without a string version is a shape failure
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

# ---- boot mount and version identity (docs/spec/update-check.md「引导挂载与版本身份」) ------------
# The store is always injected with a directory under res://build/, so no case reads or writes
# the real user://updates. The modules are loaded by path so a missing module reddens each named
# check instead of failing the whole suite at parse time. Patch versions are derived above any
# real baseline ("99.0.x"), and the mounter is a recorder unless the case is about the engine call.
const BOOT_STORE_PATH="res://update/update_store.gd"
const BOOT_SCRIPT_PATH="res://update/boot.gd"
const BOOT_SCENE_PATH="res://update/boot.tscn"
const PATCH_A="99.0.1"
const PATCH_B="99.0.2"

static func boot_load(t, name: String, path: String):
 if not ResourceLoader.exists(path):
  t.check(false,"UPDATE "+name+": "+path+" exists and loads")
  return null
 return load(path)

static func boot_root(label: String) -> String:
 var root="res://build/update-boot-%s-%d" % [label,Time.get_ticks_usec()]
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root))
 return root

static func sha_hex(bytes: PackedByteArray) -> String:
 var context=HashingContext.new()
 context.start(HashingContext.HASH_SHA256)
 context.update(bytes)
 return context.finish().hex_encode()

static func boot_content(to: String, size: int=64) -> PackedByteArray:
 var bytes=PackedByteArray()
 var seed_text=("patch-"+to).to_utf8_buffer()
 for index in size: bytes.append(seed_text[index%seed_text.size()]^(index&0xff))
 return bytes

static func write_bytes(path: String, bytes: PackedByteArray) -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
 var handle=FileAccess.open(path,FileAccess.WRITE)
 handle.store_buffer(bytes)
 handle.close()

# Writes one patch file into the store's patches directory and returns its state entry.
static func boot_entry(store, to: String, bytes: PackedByteArray=PackedByteArray()) -> Dictionary:
 var content=bytes if bytes.size()>0 else boot_content(to)
 write_bytes(store.patch_path(to),content)
 return {"to":to,"bytes":content.size(),"sha256":sha_hex(content)}

static func boot_state(baseline: String, active: Dictionary={}, pending: Dictionary={}, mounting: String="", failed: Array=[]) -> Dictionary:
 return {"from":baseline,"active":active,"pending":pending,"mounting":mounting,"failed":failed}

static func boot_names(directory: String) -> Array:
 var names=[]
 var handle=DirAccess.open(directory)
 if handle==null: return names
 for name in handle.get_files(): names.append(String(name))
 names.sort()
 return names

# Flips the last byte but keeps the length, so the size matches and only the digest differs.
static func tamper(path: String) -> void:
 var bytes=FileAccess.get_file_as_bytes(path)
 bytes[bytes.size()-1]=bytes[bytes.size()-1]^0xff
 write_bytes(path,bytes)

static func recorder(mounted: Array, answer: bool=true) -> Callable:
 return func(path: String) -> bool:
  mounted.append(path)
  return answer

static func boot_modules(t, name: String) -> Array:
 var store_class=boot_load(t,name,BOOT_STORE_PATH)
 var boot_class=boot_load(t,name,BOOT_SCRIPT_PATH)
 if store_class==null or boot_class==null: return []
 return [store_class,boot_class]

# A verified pending patch is mounted, becomes the effective version and leaves the baseline
# untouched; the next successful start promotes it to active.
static func boot_mounts_verified_pending(t) -> void:
 var modules=boot_modules(t,"boot_mounts_verified_pending")
 if modules.is_empty(): return
 var Store=modules[0]
 var Boot=modules[1]
 var baseline=Store.baseline_version()
 var store=Store.new(boot_root("mount"))
 var entry=boot_entry(store,PATCH_A)
 store.write_state(boot_state(baseline,{},entry))
 var mounted=[]
 var result=Boot.start(store,recorder(mounted),true)
 t.check(mounted==[store.patch_path(PATCH_A)],"UPDATE boot_mounts_verified_pending: the pending patch is mounted exactly once from the store path: "+str(mounted))
 t.check(String(result.get("mounted",""))==PATCH_A,"UPDATE boot_mounts_verified_pending: the start answer names the mounted version: "+str(result))
 t.check(Store.effective_version()==PATCH_A,"UPDATE boot_mounts_verified_pending: the effective version follows the mounted patch: "+Store.effective_version())
 t.check(Store.baseline_version()==baseline and baseline!=PATCH_A,"UPDATE boot_mounts_verified_pending: the baseline version does not move with the mount: "+Store.baseline_version())
 t.check(String(store.load_state().mounting)==PATCH_A,"UPDATE boot_mounts_verified_pending: the mounting marker is on disk until the session proves itself: "+str(store.load_state()))
 store.mark_boot_succeeded()
 var after=store.load_state()
 t.check(String(after.mounting).is_empty() and String(after.active.get("to",""))==PATCH_A and after.pending.is_empty(),"UPDATE boot_mounts_verified_pending: mark_boot_succeeded clears the marker and promotes pending to active: "+str(after))
 Store.record_mounted("")

# Nearest negative: recorded but not mountable. A one-byte tamper keeps the size and breaks the
# digest; a short file breaks the size. Neither is mounted, both are recorded as failed, the file
# is deleted and the next start does not try again.
static func boot_skips_bad_patch_and_records_failure(t) -> void:
 var modules=boot_modules(t,"boot_skips_bad_patch_and_records_failure")
 if modules.is_empty(): return
 var Store=modules[0]
 var Boot=modules[1]
 var baseline=Store.baseline_version()
 for variant in ["digest","size"]:
  var store=Store.new(boot_root("bad-"+variant))
  var entry=boot_entry(store,PATCH_A)
  var path=store.patch_path(PATCH_A)
  if variant=="digest": tamper(path)
  else: write_bytes(path,boot_content(PATCH_A,10))
  store.write_state(boot_state(baseline,{},entry))
  var mounted=[]
  Boot.start(store,recorder(mounted),true)
  var state=store.load_state()
  t.check(mounted.is_empty(),"UPDATE boot_skips_bad_patch_and_records_failure: a "+variant+"-corrupt patch is never mounted: "+str(mounted))
  t.check(PATCH_A in state.failed and state.pending.is_empty() and String(state.mounting).is_empty(),"UPDATE boot_skips_bad_patch_and_records_failure: the "+variant+" failure is recorded and the entry dropped: "+str(state))
  t.check(not FileAccess.file_exists(path),"UPDATE boot_skips_bad_patch_and_records_failure: the corrupt "+variant+" file is deleted")
  t.check(Store.effective_version()==baseline,"UPDATE boot_skips_bad_patch_and_records_failure: the "+variant+" failure leaves the baseline as the effective version: "+Store.effective_version())
  Boot.start(store,recorder(mounted),true)
  t.check(mounted.is_empty() and Store.effective_version()==baseline,"UPDATE boot_skips_bad_patch_and_records_failure: the next start does not try the failed version again: "+str(mounted))
  Store.record_mounted("")

# A full package of another baseline was installed over the player's. The recorded state belongs
# to the old baseline, so patches/, staging/ and the state are cleared.
static func boot_resets_on_baseline_change(t) -> void:
 var modules=boot_modules(t,"boot_resets_on_baseline_change")
 if modules.is_empty(): return
 var Store=modules[0]
 var Boot=modules[1]
 var baseline=Store.baseline_version()
 var store=Store.new(boot_root("reset"))
 var entry=boot_entry(store,PATCH_A)
 write_bytes(store.root.path_join("staging").path_join(PATCH_B+".pck.part"),boot_content(PATCH_B))
 store.write_state(boot_state("0.0.1",entry,{},"",["99.0.9"]))
 var mounted=[]
 Boot.start(store,recorder(mounted),true)
 t.check(mounted.is_empty(),"UPDATE boot_resets_on_baseline_change: a patch of another baseline is never mounted: "+str(mounted))
 t.check(boot_names(store.root.path_join("patches")).is_empty() and boot_names(store.root.path_join("staging")).is_empty(),"UPDATE boot_resets_on_baseline_change: patches/ and staging/ are emptied: "+str(boot_names(store.root.path_join("patches")))+str(boot_names(store.root.path_join("staging"))))
 var state=store.load_state()
 t.check(state.active.is_empty() and state.pending.is_empty() and state.failed.is_empty(),"UPDATE boot_resets_on_baseline_change: the recorded state is reset: "+str(state))
 t.check(Store.effective_version()==baseline,"UPDATE boot_resets_on_baseline_change: the effective version is the new baseline: "+Store.effective_version())
 Store.record_mounted("")

# A pending patch replaces the active one: only one pack is mounted, and once the session proves
# itself only the new file remains.
static func boot_replaces_active_with_pending(t) -> void:
 var modules=boot_modules(t,"boot_replaces_active_with_pending")
 if modules.is_empty(): return
 var Store=modules[0]
 var Boot=modules[1]
 var store=Store.new(boot_root("replace"))
 var active=boot_entry(store,PATCH_A)
 var pending=boot_entry(store,PATCH_B)
 store.write_state(boot_state(Store.baseline_version(),active,pending))
 var mounted=[]
 Boot.start(store,recorder(mounted),true)
 t.check(mounted==[store.patch_path(PATCH_B)],"UPDATE boot_replaces_active_with_pending: only the pending pack is mounted, never both: "+str(mounted))
 t.check(Store.effective_version()==PATCH_B,"UPDATE boot_replaces_active_with_pending: the effective version is the pending target: "+Store.effective_version())
 store.mark_boot_succeeded()
 var state=store.load_state()
 t.check(boot_names(store.root.path_join("patches"))==[PATCH_B+".pck"],"UPDATE boot_replaces_active_with_pending: patches/ keeps only the new pack after the session proves itself: "+str(boot_names(store.root.path_join("patches"))))
 t.check(String(state.active.get("to",""))==PATCH_B and state.pending.is_empty(),"UPDATE boot_replaces_active_with_pending: the replaced active entry is gone: "+str(state))
 Store.record_mounted("")

# Pending is broken, active is sound.
static func boot_falls_back_to_active_when_pending_fails(t) -> void:
 var modules=boot_modules(t,"boot_falls_back_to_active_when_pending_fails")
 if modules.is_empty(): return
 var Store=modules[0]
 var Boot=modules[1]
 var store=Store.new(boot_root("fallback"))
 var active=boot_entry(store,PATCH_A)
 var pending=boot_entry(store,PATCH_B)
 tamper(store.patch_path(PATCH_B))
 store.write_state(boot_state(Store.baseline_version(),active,pending))
 var mounted=[]
 Boot.start(store,recorder(mounted),true)
 var state=store.load_state()
 t.check(PATCH_B in state.failed and state.pending.is_empty(),"UPDATE boot_falls_back_to_active_when_pending_fails: the broken pending is recorded failed and dropped: "+str(state))
 t.check(mounted==[store.patch_path(PATCH_A)] and Store.effective_version()==PATCH_A,"UPDATE boot_falls_back_to_active_when_pending_fails: the sound active patch is mounted and becomes effective: "+str(mounted)+" "+Store.effective_version())
 Store.record_mounted("")

# A marker left by a start that never proved itself (a crash) fails that version once; the same
# version is not retried.
static func boot_skips_crash_residue(t) -> void:
 var modules=boot_modules(t,"boot_skips_crash_residue")
 if modules.is_empty(): return
 var Store=modules[0]
 var Boot=modules[1]
 var baseline=Store.baseline_version()
 var store=Store.new(boot_root("residue"))
 var active=boot_entry(store,PATCH_A)
 store.write_state(boot_state(baseline,active,{},PATCH_A))
 var mounted=[]
 Boot.start(store,recorder(mounted),true)
 var state=store.load_state()
 t.check(mounted.is_empty() and Store.effective_version()==baseline,"UPDATE boot_skips_crash_residue: the version that left its marker is not mounted: "+str(mounted))
 t.check(PATCH_A in state.failed and String(state.mounting).is_empty() and state.active.is_empty(),"UPDATE boot_skips_crash_residue: the version is recorded failed and the marker cleared: "+str(state))
 Boot.start(store,recorder(mounted),true)
 t.check(mounted.is_empty(),"UPDATE boot_skips_crash_residue: the failed version is not retried on the next start: "+str(mounted))
 Store.record_mounted("")

# A scripted run (tests, probes, tools) never mounts and never touches the store.
static func boot_is_inert_under_script(t) -> void:
 var modules=boot_modules(t,"boot_is_inert_under_script")
 if modules.is_empty(): return
 var Store=modules[0]
 var Boot=modules[1]
 var baseline=Store.baseline_version()
 var store=Store.new(boot_root("inert"))
 var entry=boot_entry(store,PATCH_A)
 store.write_state(boot_state(baseline,{},entry))
 var before=FileAccess.get_file_as_string(store.root.path_join("state.json"))
 var mounted=[]
 var result=Boot.start(store,recorder(mounted))
 t.check(not Store.player_session(),"UPDATE boot_is_inert_under_script: this harness is a scripted run")
 t.check(not bool(result.get("ran",true)) and mounted.is_empty(),"UPDATE boot_is_inert_under_script: a scripted run does not mount: "+str(result))
 t.check(FileAccess.get_file_as_string(store.root.path_join("state.json"))==before and FileAccess.file_exists(store.patch_path(PATCH_A)),"UPDATE boot_is_inert_under_script: the store is untouched")
 t.check(Store.effective_version()==Store.baseline_version(),"UPDATE boot_is_inert_under_script: the effective version equals the baseline: "+Store.effective_version())

# The effective version is the one process-level fact record_mounted writes; the baseline is
# read from the project settings and is independent of it.
static func effective_version_follows_mount(t) -> void:
 var Store=boot_load(t,"effective_version_follows_mount",BOOT_STORE_PATH)
 if Store==null: return
 var baseline=Store.baseline_version()
 t.check(not baseline.is_empty() and Store.effective_version()==baseline,"UPDATE effective_version_follows_mount: with nothing mounted the effective version is the baseline: "+Store.effective_version())
 Store.record_mounted(PATCH_A)
 t.check(Store.effective_version()==PATCH_A,"UPDATE effective_version_follows_mount: record_mounted moves the effective version: "+Store.effective_version())
 t.check(Store.baseline_version()==baseline,"UPDATE effective_version_follows_mount: the baseline stays the project setting: "+Store.baseline_version())
 var identity=Store.new(boot_root("identity")).identity()
 t.check(String(identity.get("baseline",""))==baseline and identity.get("failed",null) is Array,"UPDATE effective_version_follows_mount: identity carries the baseline, not the effective version: "+str(identity))
 Store.record_mounted("")
 t.check(Store.effective_version()==baseline,"UPDATE effective_version_follows_mount: an empty record returns to the baseline: "+Store.effective_version())

# Recorded is not mounted: a state that names a patch, and a mount the engine refuses, both
# leave the baseline as the effective version.
static func effective_version_requires_mount(t) -> void:
 var modules=boot_modules(t,"effective_version_requires_mount")
 if modules.is_empty(): return
 var Store=modules[0]
 var Boot=modules[1]
 var baseline=Store.baseline_version()
 var store=Store.new(boot_root("unmounted"))
 var active=boot_entry(store,PATCH_A)
 store.write_state(boot_state(baseline,active))
 t.check(Store.effective_version()==baseline,"UPDATE effective_version_requires_mount: an active entry that nobody mounted does not change the effective version: "+Store.effective_version())
 var refusing=Store.new(boot_root("refused"))
 var pending=boot_entry(refusing,PATCH_B)
 refusing.write_state(boot_state(baseline,{},pending))
 var mounted=[]
 var result=Boot.start(refusing,recorder(mounted,false),true)
 var state=refusing.load_state()
 t.check(mounted==[refusing.patch_path(PATCH_B)],"UPDATE effective_version_requires_mount: the engine was asked to mount the verified pack: "+str(mounted))
 t.check(Store.effective_version()==baseline and String(result.get("mounted",""))=="","UPDATE effective_version_requires_mount: a refused mount leaves the baseline effective: "+Store.effective_version()+" "+str(result))
 t.check(PATCH_B in state.failed and String(state.mounting).is_empty() and not FileAccess.file_exists(refusing.patch_path(PATCH_B)),"UPDATE effective_version_requires_mount: a refused mount is recorded failed, the marker cleared and the file deleted: "+str(state))
 Store.record_mounted("")

# verify_patch_file is the one package judgement: exact length and exact SHA-256, chunked reads.
static func patch_file_verification_domain(t) -> void:
 var directory=boot_root("verify")
 var path=directory.path_join("p.pck")
 var big=PackedByteArray()
 big.resize(2500000)
 for index in big.size(): big[index]=(index*31+7)&0xff
 write_bytes(path,big)
 var sha=sha_hex(big)
 t.check(Manifest.verify_patch_file(path,big.size(),sha),"UPDATE patch_file_verification_domain: a multi-chunk file with the exact length and digest passes")
 t.check(not Manifest.verify_patch_file(path,big.size()+1,sha) and not Manifest.verify_patch_file(path,big.size()-1,sha),"UPDATE patch_file_verification_domain: a length off by one either way fails")
 t.check(not Manifest.verify_patch_file(path,big.size(),"0".repeat(64)) and not Manifest.verify_patch_file(path,big.size(),sha.substr(0,63)),"UPDATE patch_file_verification_domain: a wrong or truncated digest fails")
 t.check(not Manifest.verify_patch_file(path,big.size(),sha.to_upper()),"UPDATE patch_file_verification_domain: the digest is the published lower-case spelling, upper case is not accepted")
 t.check(not Manifest.verify_patch_file(directory.path_join("missing.pck"),big.size(),sha) and not Manifest.verify_patch_file(directory,big.size(),sha),"UPDATE patch_file_verification_domain: a missing file and a directory fail")
 var empty=directory.path_join("empty.pck")
 write_bytes(empty,PackedByteArray())
 t.check(not Manifest.verify_patch_file(empty,0,sha_hex(PackedByteArray())),"UPDATE patch_file_verification_domain: an empty package never verifies, even with a matching zero length")
 t.check(Manifest.is_newer("99.0.1","0.18.4") and not Manifest.is_newer("0.18.4","0.18.4") and not Manifest.is_newer("0.18.3","0.18.4"),"UPDATE patch_file_verification_domain: a boot candidate must be strictly newer than the baseline")

# State read from disk is untrusted: a version becomes a file name, so it must pass the version
# grammar before any path is built; damaged documents fall back to the empty state.
static func store_rejects_hostile_state(t) -> void:
 var Store=boot_load(t,"store_rejects_hostile_state",BOOT_STORE_PATH)
 if Store==null: return
 var root=boot_root("hostile")
 var store=Store.new(root)
 t.check(store.patch_path(PATCH_A)==root.path_join("patches").path_join(PATCH_A+".pck"),"UPDATE store_rejects_hostile_state: a valid version maps to patches/<to>.pck: "+store.patch_path(PATCH_A))
 for bad in ["","../x","a/b","99.0.1/../..","99.0.1.pck","x.y","99","99.0.1.fix.fix","99.0.1 ","99.0.1\n"]:
  t.check(store.patch_path(bad)=="","UPDATE store_rejects_hostile_state: version "+JSON.stringify(bad)+" never becomes a path")
 write_bytes(root.path_join("state.json"),"{ not json".to_utf8_buffer())
 var damaged=store.load_state()
 t.check(damaged.active.is_empty() and damaged.pending.is_empty() and damaged.failed.is_empty() and String(damaged.mounting).is_empty() and String(damaged.from).is_empty(),"UPDATE store_rejects_hostile_state: an unparsable state is the empty state: "+str(damaged))
 var hostile={"from":"0.18.4","active":{"to":"../../evil","bytes":3,"sha256":"0".repeat(64)},"pending":{"to":PATCH_A,"bytes":"x","sha256":"zz"},"mounting":"../y","failed":["99.0.3",5,"../z",null]}
 write_bytes(root.path_join("state.json"),JSON.stringify(hostile).to_utf8_buffer())
 var state=store.load_state()
 t.check(state.active.is_empty() and state.pending.is_empty() and String(state.mounting).is_empty() and state.failed==["99.0.3"],"UPDATE store_rejects_hostile_state: entries with an unsafe version, bad size or bad digest, and non-version failed items are dropped: "+str(state))

# The shipped entry point: the project boots through the boot scene, and the window title is
# built from a version-free project name plus the effective version.
static func main_scene_is_boot_scene(t) -> void:
 var Store=boot_load(t,"main_scene_is_boot_scene",BOOT_STORE_PATH)
 t.check(String(ProjectSettings.get_setting("application/run/main_scene",""))==BOOT_SCENE_PATH,"UPDATE main_scene_is_boot_scene: run/main_scene is the boot scene: "+str(ProjectSettings.get_setting("application/run/main_scene","")))
 var scene=boot_load(t,"main_scene_is_boot_scene",BOOT_SCENE_PATH)
 t.check(scene is PackedScene and scene.can_instantiate(),"UPDATE main_scene_is_boot_scene: the boot scene loads and can be instantiated")
 var name=String(ProjectSettings.get_setting("application/config/name",""))
 t.check(not name.is_empty() and Store!=null and not name.contains(Store.baseline_version()),"UPDATE main_scene_is_boot_scene: config/name carries no version, the window title adds it: "+name)

# A real pack through the real engine call: the default mounter must make the pack's file
# visible under res://. The pack adds a path nothing else uses, so the rest of the run is unaffected.
static func engine_mounter_loads_a_real_pack(t) -> void:
 var modules=boot_modules(t,"engine_mounter_loads_a_real_pack")
 if modules.is_empty(): return
 var Store=modules[0]
 var Boot=modules[1]
 var store=Store.new(boot_root("engine"))
 var source=store.root.path_join("marker-source.txt")
 write_bytes(source,"mounted".to_utf8_buffer())
 var packed=store.patch_path(PATCH_A)
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(packed.get_base_dir()))
 var packer=PCKPacker.new()
 t.check(packer.pck_start(ProjectSettings.globalize_path(packed))==OK and packer.add_file("res://update_boot_probe/marker.txt",ProjectSettings.globalize_path(source))==OK and packer.flush()==OK,"UPDATE engine_mounter_loads_a_real_pack: the fixture pack is written")
 var content=FileAccess.get_file_as_bytes(packed)
 store.write_state(boot_state(Store.baseline_version(),{},{"to":PATCH_A,"bytes":content.size(),"sha256":sha_hex(content)}))
 t.check(not FileAccess.file_exists("res://update_boot_probe/marker.txt"),"UPDATE engine_mounter_loads_a_real_pack: the marker is absent before the mount")
 var result=Boot.start(store,Callable(),true)
 t.check(String(result.get("mounted",""))==PATCH_A and FileAccess.get_file_as_string("res://update_boot_probe/marker.txt")=="mounted","UPDATE engine_mounter_loads_a_real_pack: the default engine mounter exposes the pack's file under res://: "+str(result))
 Store.record_mounted("")
