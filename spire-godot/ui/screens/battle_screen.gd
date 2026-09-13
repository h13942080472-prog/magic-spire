extends Control

# The battlefield is the anchor container for the whole battle screen. Enemy
# staging, hero art, resource meters and status strips are all placed by main.gd
# because their positions and scales come from the live view.

func battlefield() -> Control:
 return get_node("BattlefieldLayer")
