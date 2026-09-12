extends Control

func art() -> Control:
 return get_node("EnemyArt")

func receiver() -> Button:
 return get_node("Receiver")

func select_button() -> Button:
 return get_node("EnemySelect")

func hp_bar() -> ProgressBar:
 return get_node("HpBar")

func hp_label() -> Label:
 return get_node("HpLabel")
