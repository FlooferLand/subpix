class_name Main
extends Control

@export_group("Nodes")
@export var canvas: CanvasDriver
@export var canvas_viewport: SubViewport
@export var tool_tree: Tree
@export var brush_strength: Slider
@export var load_button: Button
@export var save_button: Button
@export var settings_button: Button
@export var export_button: Button
@export var export_large_button: Button
@export var preview_toggle: Button
@export var preview_image_window: Window
@export var preview_image: TextureRect
@export var fps: Label

@export_group("Resources")
@export var settings_scene: PackedScene

func _ready() -> void:
	load_button.pressed.connect(func(): ProjectManager.load_project(self))
	save_button.pressed.connect(func(): ProjectManager.save_project(self))
	export_button.pressed.connect(func(): ProjectManager.export_image(self))
	export_large_button.pressed.connect(func(): ProjectManager.export_image_large(self, canvas))
	settings_button.pressed.connect(open_settings)

	# Preview window
	var toggle_preview_window := func():
		preview_image_window.visible = not preview_image_window.visible
		Autoload.settings.show_preview = preview_image_window.visible
	preview_image_window.position = Vector2(get_viewport().size) - Vector2(preview_image_window.size) - Vector2(32, 32)
	preview_image_window.close_requested.connect(toggle_preview_window)
	preview_toggle.pressed.connect(toggle_preview_window)

	# Tool tree
	var root := tool_tree.create_item()
	init_tool(root, "Draw", CanvasDriver.Tool.Draw)
	init_tool(root, "Fill", CanvasDriver.Tool.Fill)
	tool_tree.item_selected.connect(func():
		canvas.tool = tool_tree.get_selected().get_index() as CanvasDriver.Tool
	)

	# Not letting the user accidentally quit
	get_tree().set_auto_accept_quit(false)

func _exit_tree() -> void:
	get_tree().set_auto_accept_quit(true)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if ProjectManager.current_project.dirty:
			var dialog := ConfirmationDialog.new()
			dialog.dialog_text = "Are you sure you want to quit?\nYou haven't saved yet!"
			dialog.confirmed.connect(func(): get_tree().quit())
			dialog.canceled.connect(func(): dialog.queue_free())
			add_child(dialog)
			dialog.popup_centered()
		else:
			get_tree().quit()

func _process(delta: float) -> void:
	fps.text = "FPS: %s" % Engine.get_frames_per_second()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("brush_strength_add") or event.is_action_pressed("brush_strength_sub") :
		var increment := (0.5 if Input.is_key_pressed(KEY_SHIFT) else 0.1)
		brush_strength.value += (increment * (1.0 if event.is_action_pressed("brush_strength_add") else -1.0))
		brush_strength.value = clamp(brush_strength.value, 0.25, 1.0)

func init_tool(_root: TreeItem, tool_name: String, tool: CanvasDriver.Tool) -> void:
	var item := tool_tree.create_item(null, int(tool))
	item.set_text(0, tool_name)
	if canvas.tool == tool:  # Default selection
		tool_tree.set_selected(item, 0)

func open_settings() -> void:
	add_child(settings_scene.instantiate())
