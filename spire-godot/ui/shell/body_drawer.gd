extends Control

# Body drawer chrome. The equipment detail overlay stays a runtime panel because
# tests assert it is absent until a slot is inspected.

func panel() -> PanelContainer:
 return get_node("BodyEquipmentPanel")

func canvas() -> Control:
 return get_node("BodyEquipmentPanel/Canvas")

func portrait() -> TextureRect:
 return get_node("BodyEquipmentPanel/Canvas/EquipmentPortrait")

func divider() -> ColorRect:
 return get_node("BodyEquipmentPanel/Canvas/Divider")
