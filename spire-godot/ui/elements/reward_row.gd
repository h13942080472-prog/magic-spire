extends Button

func title_label() -> Label:
 return get_node("RowTitle")

func subtitle_label() -> Label:
 return get_node("RowSubtitle")

func action_label() -> Label:
 return get_node("RowAction")
