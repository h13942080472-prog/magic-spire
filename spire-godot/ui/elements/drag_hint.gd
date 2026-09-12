extends PanelContainer

func column() -> VBoxContainer:
 return get_node("Column")

func title_label() -> Label:
 return get_node("Column/HintTitle")

func detail_label() -> Label:
 return get_node("Column/HintDetail")
