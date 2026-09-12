extends "res://ui/elements/drop_target.gd"

func title_label() -> Label:
 return get_node("TitleLabel")

func price_label() -> Label:
 return get_node("PriceLabel")

func detail_label() -> Label:
 return get_node("DetailLabel")
