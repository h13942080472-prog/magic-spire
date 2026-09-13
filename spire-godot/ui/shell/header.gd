extends Control

# Header chrome carries structure and pixel positions only. Palette styles, button
# text, availability and the conditional wall line are all written by main.gd.

func strip() -> ColorRect:
 return get_node("HeaderStrip")

func trim_line() -> ColorRect:
 return get_node("HeaderTrim")

func info() -> Panel:
 return get_node("HeaderInfo")

func location() -> Panel:
 return get_node("HeaderInfo/Location")

func divider(index: int) -> ColorRect:
 return get_node("HeaderInfo/Divider%d" % index)

func order_badge() -> Panel:
 return get_node("HeaderInfo/HeaderOrderBadge")

func floor_label() -> Label:
 return get_node("HeaderInfo/HeaderFloor")

func round_label() -> Label:
 return get_node("HeaderInfo/HeaderRound")

func order_label() -> Label:
 return get_node("HeaderInfo/HeaderOrder")

func security_label() -> Label:
 return get_node("HeaderInfo/HeaderSecurity")

func tutorial_button() -> Button:
 return get_node("OpenTutorial")

func status_button() -> Button:
 return get_node("OpenStatus")

func items_button() -> Button:
 return get_node("OpenItems")

func deck_button() -> Button:
 return get_node("OpenDeck")

func map_button() -> Button:
 return get_node("OpenMap")

func menu_button() -> Button:
 return get_node("OpenMenu")
