extends RefCounted

# Presentation only. Never receives Game, state, display facts, or RNG.
signal locale_changed(locale: String)
const DEFAULT_LOCALE="zh_CN"
const LOCALES=["zh_CN","en_US","ja_JP"]
const DIRECTORY="res://assets/localization"
const DISPLAY_ERROR="文字暂时无法显示。"
const MAX_BYTES=4*1024*1024
const MAX_DISPLAY_ENTRIES=512
const MAX_DISPLAY_CHARACTERS=65536
var _display_cache: Dictionary={}
var _display_cache_characters=0
var locale=DEFAULT_LOCALE
var _source: Dictionary={}
var _translations: Dictionary={}
var _legacy: Dictionary={}
var _legacy_patterns: Dictionary={}
var _legacy_prefixes: Dictionary={}
var _diagnostics: Array=[]

func _init() -> void:
 load_directory()

static func supported(value: Variant) -> bool:
 return value is String and value in LOCALES

func set_locale(value: String) -> bool:
 if not supported(value): return false
 if locale!=value:
  _clear_display_cache()
  locale=value
  locale_changed.emit(locale)
 return true

func diagnostics() -> Array:
 return _diagnostics.duplicate(true)

func _record(code: String, key: String="") -> void:
 var issue={"code":code,"key":key}
 if issue not in _diagnostics and _diagnostics.size()<256: _diagnostics.append(issue)

static func _shape(value: Variant, names: Array) -> bool:
 return value is Dictionary and value.size()==names.size() and names.all(func(key):return value.has(key))

static func _identifier(value: Variant) -> bool:
 if not value is String or value.is_empty(): return false
 for part in value.split("."):
  if part.is_empty() or not part.is_valid_identifier() or part!=part.to_lower(): return false
 for i in range(value.length()):
  if value.unicode_at(i)>127: return false
 return true

# Tokenize before substitution so parameter contents are always literal text.
static func _template(value: String) -> Dictionary:
 var tokens=[];var parameters={};var buffer="";var i=0
 while i<value.length():
  var ch=value[i]
  if ch in ["{","}"] and i+1<value.length() and value[i+1]==ch:
   buffer+=ch;i+=2;continue
  if ch=="}": return {"ok":false}
  if ch!="{": buffer+=ch;i+=1;continue
  var end=value.find("}",i+1)
  if end<0: return {"ok":false}
  var key=value.substr(i+1,end-i-1)
  if not _identifier(key) or key.contains("."): return {"ok":false}
  tokens.append({"literal":buffer});buffer=""
  tokens.append({"parameter":key});parameters[key]=parameters.get(key,0)+1
  i=end+1
 tokens.append({"literal":buffer})
 return {"ok":true,"tokens":tokens,"parameters":parameters}

static func _header(document: Variant, language: String) -> bool:
 return _shape(document,["schema_version","locale","messages"]) and document.schema_version==1 and document.locale==language and document.messages is Dictionary

func install_source(document: Variant) -> bool:
 if not _header(document,DEFAULT_LOCALE) or document.messages.is_empty():
  _record("invalid_source");return false
 var staged={}
 for key in document.messages:
  var entry=document.messages[key]
  if not _identifier(key) or not _shape(entry,["text","context"]) or not entry.text is String or entry.text.strip_edges().is_empty() or not entry.context is String or entry.context.strip_edges().is_empty():
   _record("invalid_source_entry",str(key));return false
  if not _template(entry.text).ok:
   _record("invalid_source_template",key);return false
  staged[key]=entry.duplicate(true)
 _source=staged
 # Existing translations must be validated against the new source version.
 _translations.clear()
 return true

func install_translation(language: String, document: Variant) -> bool:
 if not supported(language) or language==DEFAULT_LOCALE or not _header(document,language):
  _record("invalid_translation");return false
 var staged={}
 for key in document.messages:
  var entry=document.messages[key]
  if not _source.has(key) or not _shape(entry,["source","text"]) or not entry.source is String or not entry.text is String:
   _record("invalid_translation_entry",str(key));return false
  if entry.source!=_source[key].text:
   _record("stale_translation",key);return false
  if entry.text.strip_edges().is_empty(): continue
  var parsed=_template(entry.text)
  if not parsed.ok or parsed.parameters!=_template(entry.source).parameters:
   _record("translation_parameters",key);return false
  staged[key]=entry.text
 _translations[language]=staged
 return true

func _read(path: String) -> Variant:
 if not FileAccess.file_exists(path):
  _record("missing_file",path);return null
 var file=FileAccess.open(path,FileAccess.READ)
 if file==null:
  _record("unreadable_file",path);return null
 if file.get_length()>MAX_BYTES:
  _record("oversized_file",path);return null
 var json=JSON.new()
 if json.parse(file.get_as_text())!=OK:
  _record("invalid_json",path);return null
 return json.data

func load_directory(directory: String=DIRECTORY) -> bool:
 _diagnostics.clear()
 if not install_source(_read(directory.path_join(DEFAULT_LOCALE+".json"))): return false
 _legacy.clear();_legacy_patterns.clear();_legacy_prefixes.clear()
 _clear_display_cache()
 var valid=true
 for language in LOCALES:
  if language==DEFAULT_LOCALE: continue
  if not install_translation(language,_read(directory.path_join(language+".json"))): valid=false
  var legacy_path=directory.path_join("legacy-"+language+".json")
  if FileAccess.file_exists(legacy_path) and not install_legacy_translation(language,_read(legacy_path)): valid=false
 return valid

func coverage(language: String) -> Dictionary:
 var total=_source.size()
 var translated=total if language==DEFAULT_LOCALE else _translations.get(language,{}).size()
 return {"total":total,"translated":translated,"missing":total-translated}

func text(key: String, fallback: String, params: Dictionary={}) -> String:
 var selected=fallback
 if not _source.has(key): _record("unknown_key",key)
 elif _source[key].text!=fallback: _record("stale_callsite",key)
 else: selected=_translations.get(locale,{}).get(key,_source[key].text)
 var parsed=_template(selected)
 if not parsed.ok or params.size()!=parsed.parameters.size():
  _record("call_parameters",key);return DISPLAY_ERROR
 for name in parsed.parameters:
  if not params.has(name) or not (params[name] is String or params[name] is int or params[name] is float or params[name] is bool):
   _record("call_parameters",key);return DISPLAY_ERROR
  if params[name] is float and not is_finite(params[name]):
   _record("call_parameters",key);return DISPLAY_ERROR
 var result=""
 for token in parsed.tokens:
  result+=token.literal if token.has("literal") else str(params[token.parameter])
 return result

static func _regex_escape(value: String) -> String:
 var result=""
 for ch in value:
  result+=("\\"+ch) if ch in ["\\",".","^","$","|","?","*","+","(",")","[","]","{","}"] else ch
 return result

static func _legacy_source(value: String) -> Dictionary:
 var pattern="^";var names=[];var literal="";var literal_weight=0;var numeric_only=true;var i=0
 var format=RegEx.new();format.compile(r"%(?:[-+ 0#]*)(?:\d+|\*)?(?:\.(?:\d+|\*))?[diouxXfFeEgGaAcsp]")
 while i<value.length():
  if value.substr(i,2)=="%%": literal+="%";i+=2;continue
  var hit=format.search(value,i)
  if hit!=null and hit.get_start()==i:
   pattern+=_regex_escape(literal);literal=""
   var name="p%d" % names.size();names.append(name)
   var conversion=hit.get_string().right(1)
   if conversion in ["d","i","u"]: pattern+="([+-]?\\d+)"
   elif conversion in ["f","F","e","E","g","G","a","A"]: pattern+="([+-]?\\d+(?:\\.\\d+)?)"
   else: pattern+="(.+?)";numeric_only=false
   i=hit.get_end();continue
  if value[i]=="{" and (i==0 or value[i-1]!="{"):
   var end=value.find("}",i+1)
   if end>=0 and (end+1>=value.length() or value[end+1]!="}"):
    var raw=value.substr(i+1,end-i-1)
    if raw.is_valid_identifier() or raw.is_valid_int():
     pattern+=_regex_escape(literal);literal=""
     var name="p%d" % names.size();names.append(name)
     pattern+="(.+?)";numeric_only=false;i=end+1;continue
  if value.unicode_at(i)>=0x3400 and value.unicode_at(i)<=0x9fff: literal_weight+=1
  literal+=value[i];i+=1
 pattern+=_regex_escape(literal)+"$"
 return {"pattern":pattern,"names":names,"dynamic":not names.is_empty(),"literal_weight":literal_weight,"numeric_only":numeric_only}

func install_legacy_translation(language: String, document: Variant) -> bool:
 if not supported(language) or language==DEFAULT_LOCALE or not _shape(document,["schema_version","locale","messages"]) or document.schema_version!=1 or document.locale!=language or not document.messages is Array:
  _record("invalid_legacy_translation");return false
 var exact={};var patterns=[];var prefixes={};var ids={}
 for entry in document.messages:
  if not _shape(entry,["id","source","text"]) or not _identifier(entry.id) or ids.has(entry.id) or not entry.source is String or not entry.text is String or entry.source.is_empty() or entry.text.strip_edges().is_empty():
   _record("invalid_legacy_entry");return false
  ids[entry.id]=true
  var parsed=_legacy_source(entry.source)
  if parsed.dynamic:
   var target=_template(entry.text)
   var expected={}
   for name in parsed.names: expected[name]=expected.get(name,0)+1
   if not target.ok or target.parameters!=expected:
    _record("legacy_parameters",entry.id);return false
   if parsed.literal_weight>=2 or (parsed.literal_weight>=1 and parsed.numeric_only):
    var regex=RegEx.new()
    if regex.compile(parsed.pattern)!=OK:
     _record("legacy_pattern",entry.id);return false
    patterns.append({"regex":regex,"names":parsed.names,"tokens":target.tokens,"weight":entry.source.length()})
  else:
   exact[entry.source]=entry.text
   if entry.source.unicode_at(0)>=0x3400 and entry.source.unicode_at(0)<=0x9fff:
    var first=entry.source[0]
    if not prefixes.has(first): prefixes[first]=[]
    prefixes[first].append({"source":entry.source,"text":entry.text})
 patterns.sort_custom(func(a,b):return a.weight>b.weight)
 for first in prefixes: prefixes[first].sort_custom(func(a,b):return a.source.length()>b.source.length())
 _legacy[language]=exact;_legacy_patterns[language]=patterns;_legacy_prefixes[language]=prefixes
 _clear_display_cache()
 return true

func _clear_display_cache() -> void:
 _display_cache.clear();_display_cache_characters=0

func _remember_display(value: String, result: String) -> String:
 var characters=value.length()+result.length()
 if characters>MAX_DISPLAY_CHARACTERS: return result
 if _display_cache.size()>=MAX_DISPLAY_ENTRIES or _display_cache_characters+characters>MAX_DISPLAY_CHARACTERS:
  _clear_display_cache()
 _display_cache[value]=result;_display_cache_characters+=characters
 return result

func display(value: String) -> String:
 if locale==DEFAULT_LOCALE or value.is_empty(): return value
 var exact=_legacy.get(locale,{})
 if exact.has(value): return exact[value]
 if _display_cache.has(value): return _display_cache[value]
 var has_chinese=false
 for index in range(value.length()):
  if value.unicode_at(index)>=0x3400 and value.unicode_at(index)<=0x9fff:
   has_chinese=true;break
 if not has_chinese: return value
 for entry in _legacy_patterns.get(locale,[]):
  var hit=entry.regex.search(value)
  if hit==null: continue
  var params={}
  for index in range(entry.names.size()): params[entry.names[index]]=display(hit.get_string(index+1))
  var result=""
  for token in entry.tokens: result+=token.literal if token.has("literal") else str(params[token.parameter])
  return _remember_display(value,result)
 # Transitional path for old UI strings assembled from multiple source literals.
 var prefixes=_legacy_prefixes.get(locale,{})
 var result="";var i=0
 while i<value.length():
  var matched=false
  for entry in prefixes.get(value[i],[]):
   if value.substr(i).begins_with(entry.source):
    result+=entry.text;i+=entry.source.length();matched=true;break
  if not matched: result+=value[i];i+=1
 return _remember_display(value,result)
