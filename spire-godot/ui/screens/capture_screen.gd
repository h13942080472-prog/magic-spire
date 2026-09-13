extends Control

# Capture screen frame. Every caption and action row is state-driven.

func panel() -> PanelContainer:
 return get_node("CapturePanel")

func column() -> VBoxContainer:
 return get_node("CapturePanel/Column")
