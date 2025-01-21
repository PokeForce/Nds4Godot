@tool
extends EditorPlugin

const NDS_COMPANION = "NDSCompanion"

func _enable_plugin() -> void:
	add_autoload_singleton(NDS_COMPANION, "res://addons/nds4godot/scripts/NdsCompanion.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton(NDS_COMPANION)
