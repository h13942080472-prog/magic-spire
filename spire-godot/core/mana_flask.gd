extends RefCounted
const TRANSFER=10.0
const DEPOSITS=3

static func limit(g, op: String="deposit") -> int:
 if g.state.phase=="battle" or (g.state.phase=="prepare" and op=="deposit"): return DEPOSITS
 if g.state.phase=="prison" and op=="deposit": return 1
 return 0

static func limited(g, op: String="deposit") -> bool:
 return limit(g,op)>0

static func reset_turn(g) -> void:
 g.state.flask_deposits=0
 g.state.combat.flask_withdrawals=0

static func remaining(g, op: String) -> int:
 var used=g.state.flask_deposits if op=="deposit" else int(g.state.combat.get("flask_withdrawals",0))
 return maxi(0,limit(g,op)-used)

static func validate(g) -> String:
 if not g.Snapshot.fields(g.state,"flask_mana:n flask_deposits:i") or g.state.flask_mana<0 or g.state.flask_deposits<0 or g.state.flask_deposits>DEPOSITS: return "贴身魔瓶的魔力或存入次数不正确。"
 # Older snapshots have no withdrawal counter; absence means no uses under the new rule.
 var used=g.state.combat.get("flask_withdrawals",0)
 if not used is int or used<0 or used>DEPOSITS: return "贴身魔瓶的取出次数不正确。"
 return ""

static func available(g) -> bool:
 return g.state.phase not in ["cleared","prison_end"]

static func withdrawal(g) -> Dictionary:
 var room=maxf(0,g.state.mana_max-g.state.mana)
 var limit=minf(TRANSFER,g.state.flask_mana)
 var drawn=minf(limit,room)
 if g.occupied("mouth"):
  drawn=limit
  # At most ten doses; ask the shared potion formula instead of duplicating its rounding.
  for step in range(1,ceili(limit)+1):
   var dose=minf(float(step),limit)
   if minf(dose,g.Consumables.potion_amount(g,dose))>=room:
    drawn=dose;break
 var restored=minf(minf(drawn,g.Consumables.potion_amount(g,drawn)),room)
 return {"drawn":drawn,"restored":restored}

# 魔瓶的显示事实（批 R5：行生产转发改显示事实构建，docs/spec/candidate-removal.md §2.1 T5／T8）。
static func facts(g, withdrawal_only: bool=false) -> Array:
 var out=[]
 if not available(g): return out
 var amount=minf(TRANSFER,g.state.mana)
 var reason="本回合已存入%d次。" % limit(g) if limited(g) and remaining(g,"deposit")==0 else ("没有可存入的魔力。" if amount<=0 else "")
 if not withdrawal_only and g.state.phase!="rest_choice":
  var deposit_args={"amount":amount,"remaining":remaining(g,"deposit"),"limited":limited(g)}
  out.append(g._fact({"kind":"flask","op":"deposit"},"存入",{"kind":"mana_flask.deposit","args":deposit_args,"fallback":deposit_detail(g,deposit_args)},0,0.0,reason,"","flask"))
 var result=withdrawal(g)
 reason=g.Consumables.reason(g,"mana_potion")
 if g.state.flask_mana<=0: reason="魔瓶中没有魔力。"
 elif reason=="" and result.restored<=0: reason="魔瓶余量不足以在嘴部减效后恢复魔力。"
 if limited(g,"withdraw") and remaining(g,"withdraw")==0: reason="本回合已取出%d次。" % limit(g,"withdraw")
 var withdraw_args={"drawn":result.drawn,"restored":result.restored,"remaining":remaining(g,"withdraw"),"limited":limited(g,"withdraw")}
 out.append(g._fact({"kind":"flask","op":"withdraw"},"取出",{"kind":"mana_flask.withdraw","args":withdraw_args,"fallback":withdraw_detail(g,withdraw_args)},0,0.0,reason,"","flask"))
 return out

# R1（docs/ondemand-copy.md §11.5）：生产者提交「类别 + 参数」，正文仍留本模块，路由只做分派。
static func deposit_detail(g, args: Dictionary) -> String:
 if not args.get("limited",false): return "存入%s魔力，战斗外不限次数。" % g.number(float(args.get("amount",0.0)))
 return "存入%s魔力，本回合剩余%d次。" % [g.number(float(args.get("amount",0.0))),int(args.get("remaining",0))]

static func withdraw_detail(g, args: Dictionary) -> String:
 var values=[g.number(float(args.get("drawn",0.0))),g.number(float(args.get("restored",0.0)))]
 if not args.get("limited",false): return "取出%s魔力，恢复自身%s魔力，战斗外不限次数。" % values
 return "取出%s魔力，恢复自身%s魔力，本回合剩余%d次。" % (values+[int(args.get("remaining",0))])

static func execute(g, p: Dictionary) -> void:
 if p.op=="deposit":
  var amount=minf(TRANSFER,g.state.mana)
  g.state.mana-=amount;g.state.flask_mana+=amount
  if limited(g): g.state.flask_deposits+=1
  g._emit("event","向贴身魔瓶存入%s魔力。" % g.number(amount))
 else:
  var result=withdrawal(g)
  g.state.flask_mana-=result.drawn;g.state.mana+=result.restored
  if limited(g,"withdraw"): g.state.combat.flask_withdrawals=int(g.state.combat.get("flask_withdrawals",0))+1
  g._emit("event","从贴身魔瓶取出%s魔力，恢复%s魔力。" % [g.number(result.drawn),g.number(result.restored)])

static func view(g) -> Dictionary:
 return {"mana":g.state.flask_mana,"remaining":remaining(g,"deposit"),"withdraw_remaining":remaining(g,"withdraw"),"limit":limit(g),"withdraw_limit":limit(g,"withdraw"),"limited":limited(g),"withdraw_limited":limited(g,"withdraw"),"available":available(g)}
