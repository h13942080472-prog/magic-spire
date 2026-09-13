extends Control

# Route screen frame: workspace, map column and message column. The map canvas,
# the message list and the re-parented relic strip stay runtime-built because
# they are state-driven and order-sensitive.

func panel() -> PanelContainer:
 return get_node("RouteWorkspace")

func row() -> HBoxContainer:
 return get_node("RouteWorkspace/Row")

func map_column() -> VBoxContainer:
 return get_node("RouteWorkspace/Row/RouteMapColumn")

func map_scroll() -> ScrollContainer:
 return get_node("RouteWorkspace/Row/RouteMapColumn/TowerMapScroll")

func messages() -> VBoxContainer:
 return get_node("RouteWorkspace/Row/RouteMessages")
