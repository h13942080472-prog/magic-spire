extends Control

# Practice screen frame. Description, hint, summary and flow actions are all
# read from the view, so only the panel skeleton lives here.

func panel() -> PanelContainer:
 return get_node("PracticePanel")

func column() -> VBoxContainer:
 return get_node("PracticePanel/Column")
