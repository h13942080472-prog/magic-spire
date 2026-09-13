extends Control

# Prison inspection screen frame. Stage-specific captions and prison actions are
# all state-driven, so only the panel and its column live here.

func panel() -> PanelContainer:
 return get_node("InspectionPanel")

func column() -> VBoxContainer:
 return get_node("InspectionPanel/Column")
