extends Control

# Reward screen frame. RewardScreen.build() dispatches to the unified reward rows,
# the departure layout or the relic bundle layout, and every one of them lays its
# own root inside this frame.

func frame() -> Control:
 return get_node("RewardFrame")
