extends Control

# Bottom bar chrome. Resource rows, capture bind, movement, posture, flow and
# surrender remain runtime-built because their existence depends on game state.

func resource_panel() -> Panel:
 return get_node("MainResourcePanel")

func tool_panel() -> Panel:
 return get_node("ResourceToolsPanel")

func tool_divider() -> ColorRect:
 return get_node("ToolDivider")

func medallion() -> TextureRect:
 return get_node("EnergyMedallion")

func energy_label() -> Label:
 return get_node("EnergyMedallion/EnergyValue")

func powers_button() -> Button:
 return get_node("OpenPowers")

func draw_button() -> Button:
 return get_node("DrawPileButton")

func discard_button() -> Button:
 return get_node("DiscardPileButton")

# Turn controls are declared with the bar but only exist on turn-based screens.
func show_turn_controls(enabled: bool) -> void:
 tool_divider().visible=enabled
 medallion().visible=enabled
 draw_button().visible=enabled
 discard_button().visible=enabled

func show_tools(enabled: bool) -> void:
 tool_panel().visible=enabled
