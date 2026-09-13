extends Control

# Card chain screen frame. Segment choices come from the candidate list.

func panel() -> PanelContainer:
 return get_node("ChainPanel")

func content() -> VBoxContainer:
 return get_node("ChainPanel/ChainScroll/ChainContent")
