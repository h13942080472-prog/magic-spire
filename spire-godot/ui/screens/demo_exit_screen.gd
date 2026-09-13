extends Control

# Demo exit screen frame. Copy and exit actions stay runtime-built because they
# come from the candidate list and are absent once the demo is finished.

func panel() -> PanelContainer:
 return get_node("DemoExitPanel")

func column() -> VBoxContainer:
 return get_node("DemoExitPanel/Column")
