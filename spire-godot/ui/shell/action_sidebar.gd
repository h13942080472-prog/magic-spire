extends Control

# Action sidebar chrome. The panel keeps its two state-driven rects (normal and
# shop) written by main.gd; only structure and pixel defaults live here.

func panel() -> PanelContainer:
 return get_node("ActionSidebar")

func column() -> VBoxContainer:
 return get_node("ActionSidebar/Column")

func heading() -> HBoxContainer:
 return get_node("ActionSidebar/Column/Heading")

func title() -> Label:
 return get_node("ActionSidebar/Column/Heading/ActionLogTitle")

func pin_button() -> Button:
 return get_node("ActionSidebar/Column/Heading/PinActionLog")

func close_button() -> Button:
 return get_node("ActionSidebar/Column/Heading/CloseActionLog")

func content() -> VBoxContainer:
 return get_node("ActionSidebar/Column/ActionLogScroll/LogContent")

func toggle() -> Button:
 return get_node("OpenActionLog")
