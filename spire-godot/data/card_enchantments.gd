extends RefCounted

# One permanent slot per physical card; names never identify mechanics.
const TYPES={
 "innate":{"name":"固有","rarity":"common","detail":"开场优先进入手牌。"},
 "retain":{"name":"保留","rarity":"common","detail":"回合结束时保留。"},
 "nimble":{"name":"灵动","rarity":"common","detail":"打出后抽1张牌。"},
 "fickle":{"name":"善变","rarity":"common","detail":"非0费牌：自由面打出后恢复5魔力，拘束面获得1层蓄力。"},
 "adept":{"name":"熟练","rarity":"common","detail":"该牌施法必定成功，仍需满足施法条件。"},
 "sow_power":{"name":"播种","rarity":"common","detail":"能力牌打出后获得1能量。"},
 "strengthen":{"name":"强化","rarity":"common","detail":"打出后，本回合力量＋1、灵巧＋1。"},
 "powerful":{"name":"强力","rarity":"common","detail":"该牌最终挣脱伤害×1.5。"},
 "recycle":{"name":"回收","rarity":"common","detail":"打出后回到手牌1次；每场重置。手牌满时弃置。"},
 "absorb":{"name":"吸收","rarity":"rare","detail":"打出后恢复20魔力，每场限1次。"},
 "sow_skill":{"name":"播种","rarity":"rare","detail":"原始费用至少2的技能牌打出后获得1能量。"},
 "blessing":{"name":"祝福","rarity":"rare","detail":"能力牌打出后力量＋2、灵巧＋2，持续到整备结束。"},
 "replay":{"name":"复放","rarity":"rare","detail":"额外免费释放1次；仅对常规牌面生效，唯一面除外。"},
 "exhaust":{"name":"消耗","rarity":"rare","detail":"获得消耗；原有消耗变为消耗2。两面共用次数，每场重置。"},
 "recycle2":{"name":"回收2","rarity":"rare","detail":"打出后回到手牌2次；每场重置。手牌满时弃置。"},
 "swift":{"name":"迅捷","rarity":"rare","detail":"每场第一次打出后抽3张牌。"},
 "nexus":{"name":"枢纽","rarity":"rare","detail":"抽到该牌时获得1能量。"},
}
const TURNS={"common":2,"rare":4}
const RARITIES={"common":"普通","rare":"稀有"}

static func refresh_price(count: int) -> float:
 return 10.0*pow(2.0,floori(count/3.0))
