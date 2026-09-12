extends Control

func dismiss() -> Button:
 return get_node("DismissDrawer")

func panel() -> PanelContainer:
 return get_node("InformationDrawer")

func content() -> VBoxContainer:
 return get_node("InformationDrawer/Content")

func heading() -> HBoxContainer:
 return get_node("InformationDrawer/Content/Heading")

func crest() -> TextureRect:
 return get_node("InformationDrawer/Content/Heading/Crest")

func title_label() -> Label:
 return get_node("InformationDrawer/Content/Heading/TitleLabel")

func close_button() -> Button:
 return get_node("InformationDrawer/Content/Heading/CloseDrawer")
