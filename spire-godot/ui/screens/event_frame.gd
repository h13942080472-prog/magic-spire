extends Control

# Event screen frame. EventScreen.build() fills this frame, so the panel, the
# artwork and the choice list keep their single source of truth in the module.

func frame() -> Control:
 return get_node("EventFrame")
