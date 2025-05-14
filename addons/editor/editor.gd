@tool
extends EditorPlugin

const ExportWindow := preload("uid://cjxru7lksrkjr")
var export_window: Window = null

func _enter_tree() -> void:
	add_tool_menu_item("Export", func():
		export_window = ExportWindow.instantiate()
		if not export_window.is_inside_tree():
			get_editor_interface().get_base_control().add_child(export_window)
		export_window.popup_centered()
	)

func _exit_tree() -> void:
	remove_tool_menu_item("Export")
	if is_instance_valid(export_window):
		export_window.queue_free()
