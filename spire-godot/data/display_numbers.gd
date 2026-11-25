extends RefCounted

# Format only at the point a quantity becomes player-facing text.
static func amount(value: float) -> String:
 var tenths=roundf(value*10.0)
 if tenths==0.0: return "0"
 return String.num(tenths/10.0,1).trim_suffix(".0")

static func measured(value: float) -> String:
 if value>0.0 and value<0.05: return "<0.1"
 return amount(value)

static func probability(chance: float) -> String:
 if chance<1.0 and chance>=0.9995: return ">99.9%"
 return measured(chance*100.0)+"%"

# Short multipliers keep their usual notation. Percentages retain the rule's
# exact value for factors such as 0.125 without adding decimal places.
static func factor(value: float) -> String:
 if is_equal_approx(value*10.0,roundf(value*10.0)): return amount(value)
 return amount(value*100.0)+"%"
