extends RefCounted

const Game=preload("res://core/game.gd")
const FORMAT=2
const Phases=preload("res://data/phases.gd")
var directory: String

func _init(folder: String="user://saves") -> void:
 directory=folder

func path(slot: String) -> String:
 return directory.path_join(slot+".json")

func has_files(slot: String) -> bool:
 return FileAccess.file_exists(path(slot)) or FileAccess.file_exists(path(slot)+".bak")

static func failure(message: String, code: String="invalid") -> Dictionary:
 return {"ok":false,"error":message,"code":code}

# JSON numbers cannot represent every 64-bit seed. Preserve integer leaves explicitly.
static func encode(value):
 if value is StringName: return {"@name":str(value)}
 if value is int: return {"@integer":str(value)}
 if value is float:
  var bits=PackedByteArray();bits.resize(8);bits.encode_double(0,value)
  return {"@float":bits.hex_encode()}
 if value is Dictionary:
  var result={}
  for key in value: result[key]=encode(value[key])
  return result
 if value is Array: return value.map(func(item):return encode(item))
 return value

static func decode(value, depth: int=0) -> Dictionary:
 if depth>64: return failure("存档内容嵌套过深。")
 if value is Dictionary:
  if value.has("@name"):
   if value.size()!=1 or not value["@name"] is String: return failure("存档名称损坏。")
   return {"ok":true,"value":StringName(value["@name"])}
  if value.has("@float"):
   var bits=value["@float"]
   if value.size()!=1 or not bits is String or bits.length()!=16: return failure("存档小数损坏。")
   for letter in bits:
    if letter not in "0123456789abcdef": return failure("存档小数损坏。")
   var number=bits.hex_decode().decode_double(0)
   if not is_finite(number): return failure("存档数值损坏。")
   return {"ok":true,"value":number}
  if value.has("@integer"):
   var number=value["@integer"]
   if value.size()!=1 or not number is String or not number.is_valid_int() or str(number.to_int())!=number: return failure("存档整数损坏。")
   return {"ok":true,"value":number.to_int()}
  var result={}
  for key in value:
   var child=decode(value[key],depth+1)
   if not child.ok: return child
   result[key]=child.value
  return {"ok":true,"value":result}
 if value is Array:
  var result=[]
  for item in value:
   var child=decode(item,depth+1)
   if not child.ok: return child
   result.append(child.value)
  return {"ok":true,"value":result}
 if value is float and not is_finite(value): return failure("存档数值损坏。")
 return {"ok":true,"value":value}

static func pack(snapshot: Dictionary, map_drawings: Dictionary={}) -> String:
 var payload=JSON.stringify(encode(snapshot),"",false,true)
 var marks={}
 for key in map_drawings:
  marks[key]=[]
  for stroke in map_drawings[key]:
   var points=[]
   for point in stroke: points.append([point.x,point.y])
   marks[key].append(points)
 var ink=JSON.stringify(encode(marks),"",false,true)
 return JSON.stringify({"format":FORMAT,"saved_at":Time.get_datetime_string_from_system(),"payload":payload,"map_drawings":ink,"checksum":(payload+ink).sha256_text()},"",false,true)

static func unpack(text: String) -> Dictionary:
 var parser=JSON.new()
 if parser.parse(text)!=OK or not parser.data is Dictionary: return failure("存档文件不完整或无法读取。")
 var envelope=parser.data
 if not envelope.has("format") or envelope.format!=FORMAT: return failure(Game.Snapshot.INCOMPATIBLE,"version")
 if not envelope.get("payload") is String or not envelope.get("checksum") is String or not envelope.get("saved_at") is String: return failure("存档缺少必要信息。")
 var ink=envelope.get("map_drawings","")
 if not ink is String or (envelope.payload+ink).sha256_text()!=envelope.checksum: return failure("存档校验失败，文件可能已损坏。")
 if parser.parse(envelope.payload)!=OK: return failure("存档内容损坏。")
 var result=decode(parser.data)
 if not result.ok: return result
 if not result.value is Dictionary: return failure("存档没有有效的游戏进度。")
 var probe=Game.new(0,false,"equipment",false)
 var restored=probe.restore_snapshot(result.value)
 if not restored.ok: return restored
 var drawings={}
 if ink!="":
  if parser.parse(ink)!=OK: return failure("地图画线损坏。")
  var decoded=decode(parser.data)
  if not decoded.ok or not decoded.value is Dictionary: return failure("地图画线损坏。")
  for key in decoded.value:
   if not key is String or not decoded.value[key] is Array: return failure("地图画线损坏。")
   drawings[key]=[]
   for line in decoded.value[key]:
    if not line is Array: return failure("地图画线损坏。")
    var points=PackedVector2Array()
    for point in line:
     if not point is Array or point.size()!=2 or not Game.Snapshot.typed(point[0],"n") or not Game.Snapshot.typed(point[1],"n"): return failure("地图画线坐标损坏。")
     points.append(Vector2(point[0],point[1]))
    drawings[key].append(points)
 return {"ok":true,"snapshot":result.value,"map_drawings":drawings,"saved_at":envelope.saved_at}

func read_file(filename: String) -> Dictionary:
 if not FileAccess.file_exists(filename): return failure("尚无存档。")
 var file=FileAccess.open(filename,FileAccess.READ)
 if file==null: return failure("无法打开存档文件。")
 var text=file.get_as_text();file.close()
 return unpack(text)

func read_slot(slot: String) -> Dictionary:
 if slot not in Game.Snapshot.SLOTS: return failure("存档位置不存在。")
 var current=read_file(path(slot))
 if current.ok and current.snapshot.save_slot==slot:
  current.backup=false;return current
 # A newer format must not silently roll back to an older compatible backup.
 if not current.ok and current.get("code","")=="version": return current
 var backup=read_file(path(slot)+".bak")
 if backup.ok and backup.snapshot.save_slot==slot:
  backup.backup=true;return backup
 return failure(current.get("error","存档所属模式不一致。")+" 没有可恢复的备份。")

# Read-only fixed point accessor for the feedback attachment (docs/spec/feedback-deployment.md):
# no file access, no size check, no write, no state change; the single serialization stays pack(),
# so the returned text is byte-identical to what write_game would put in the primary file.
func fixed_point_text(game, map_drawings: Dictionary={}) -> Dictionary:
 var issue=game.validate()
 if issue!="": return failure("无法生成当前进度存档："+issue)
 var slot=game.state.save_slot
 if slot not in Game.Snapshot.SLOTS: return failure("存档位置不存在。")
 return {"ok":true,"slot":slot,"filename":slot+".json","text":pack(game.restart_snapshot(),map_drawings)}

func write_game(game, replace_incompatible: bool=false, map_drawings: Dictionary={}) -> Dictionary:
 var issue=game.validate()
 if issue!="": return failure("保存失败："+issue)
 var slot=game.state.save_slot
 if slot not in Game.Snapshot.SLOTS: return failure("存档位置不存在。")
 var filename=path(slot)
 var old=read_file(filename)
 if not old.ok and old.get("code","")=="version" and not replace_incompatible: return failure("保存已暂停：原存档版本不兼容，只有明确开始新局才会替换。","version")
 var content=pack(game.restart_snapshot(),map_drawings)
 var absolute=ProjectSettings.globalize_path(directory)
 if DirAccess.make_dir_recursive_absolute(absolute)!=OK: return failure("保存失败：无法创建存档文件夹。当前游戏仍可继续。")
 var temp=filename+".tmp"
 var file=FileAccess.open(temp,FileAccess.WRITE)
 if file==null: return failure("保存失败：无法写入存档。原存档保留。")
 file.store_string(content);file.flush()
 var write_error=file.get_error();file.close()
 if write_error!=OK: return failure("保存失败：写入未完成，原存档保留。")
 if not read_file(temp).ok: return failure("保存失败：写入校验未通过，原存档保留。")
 if old.ok:
  if DirAccess.copy_absolute(filename,filename+".bak.tmp")!=OK or DirAccess.rename_absolute(filename+".bak.tmp",filename+".bak")!=OK: return failure("保存失败：无法更新备份，原存档保留。")
 if DirAccess.rename_absolute(temp,filename)!=OK: return failure("保存失败：无法替换存档，原存档保留。")
 return {"ok":true,"slot":slot,"message":"练习场景起点已保存。" if slot=="practice" else "塔路场景起点已保存。"}

func summary(slot: String) -> Dictionary:
 var result=read_slot(slot)
 if not result.ok: return {"available":false,"text":result.error}
 var s=result.snapshot
 if s.demo_finished: return {"available":false,"finished":true,"text":"本次demo已结束"}
 var phase=Phases.DEFINITIONS[s.phase].name
 var room=s.rooms.filter(func(r):return r.id==s.room)[0].name
 return {"available":true,"text":"%s · %s\n%s%s" % [room,phase,result.saved_at," · 将恢复上次备份" if result.backup else ""]}
