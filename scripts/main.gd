class_name Main
extends Control

# Handles UI widgets and window stuff

@export_group("Nodes")
@export var canvas: CanvasDriver
@export var draw_utils: CanvasDrawUtils
@export var canvas_viewport: SubViewport
@export var canvas_container: SubViewportContainer
@export var tool_tree: Tree
@export var brush_strength: Slider
@export var new_button: Button
@export var load_button: Button
@export var save_button: Button
@export var settings_button: Button
@export var export_button: Button
@export var export_large_button: Button
@export var preview_toggle: Button
@export var preview_image_window: Window
@export var preview_image: TextureRect
@export var fps: Label
@export var paint_mode: OptionButton
@export var pixel_paint_color: ColorPickerButton

@export_group("Resources")
@export var settings_scene: PackedScene

@onready var old_canvas_size := canvas_container.size
var preview_window_pad := Vector2i(32, 32)

func _ready() -> void:
	new_button.pressed.connect(func(): ProjectManager.new_project(self))
	load_button.pressed.connect(func(): ProjectManager.load_project(self))
	save_button.pressed.connect(func(): ProjectManager.save_project(self))
	export_button.pressed.connect(func(): ProjectManager.export_image(self))
	export_large_button.pressed.connect(func(): ProjectManager.export_image_large(self, canvas))
	settings_button.pressed.connect(open_settings)

	var update_preview_window_pos := func():
		preview_image_window.position = preview_image_window.position\
			.clamp(Vector2i.ZERO, Vector2i(canvas_container.size) - Vector2i(preview_image_window.size) - preview_window_pad)

	# Canvas viewport
	canvas_container.resized.connect(func():
		var new_canvas_size := Vector2i(canvas_container.size)
		if old_canvas_size.length() < 1:
			return

		# Moving the preview window
		# TODO: Finish moving the preview window when viewport is resized (80% done)
		preview_image_window.position.x = remap(
			preview_image_window.position.x,
			0, old_canvas_size.x,
			0, new_canvas_size.x
		)
		preview_image_window.position.y = remap(
			preview_image_window.position.y,
			0, old_canvas_size.y,
			0, new_canvas_size.y
		)

		# Final
		update_preview_window_pos.call()
		old_canvas_size = new_canvas_size
	)

	# Preview window
	var toggle_preview_window := func():
		preview_image_window.visible = not preview_image_window.visible
		Autoload.settings.show_preview = preview_image_window.visible
		update_preview_window_pos.call()
	preview_image_window.position = Vector2i(get_viewport().size) - Vector2i(preview_image_window.size) - preview_window_pad
	preview_image_window.close_requested.connect(toggle_preview_window)
	preview_toggle.pressed.connect(toggle_preview_window)

	# Tool tree
	var root := tool_tree.create_item()
	init_tool(root, "Draw", CanvasDriver.Tool.Draw)
	init_tool(root, "Fill", CanvasDriver.Tool.Fill)
	tool_tree.item_selected.connect(func():
		canvas.tool = tool_tree.get_selected().get_index() as CanvasDriver.Tool
	)

	# Tool paint mode
	pixel_paint_color.visible = false
	paint_mode.item_selected.connect(func(selected):
		match selected:
			canvas.PaintMode.Pixel:
				preview_image_window.visible = false
				pixel_paint_color.visible = true
			canvas.PaintMode.Subpixel:
				if Autoload.settings.show_preview:
					preview_image_window.visible = true
					pixel_paint_color.visible = false
		draw_utils.queue_redraw()
		canvas.queue_redraw()
	)
	pixel_paint_color.color_changed.connect(func(new):
		canvas.pixel_paint_color = new
	)

	# Not letting the user accidentally quit
	get_tree().set_auto_accept_quit(false)

func _exit_tree() -> void:
	get_tree().set_auto_accept_quit(true)

func _notification(what):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			if ProjectManager.current_project.dirty:
				var dialog := ConfirmationDialog.new()
				dialog.dialog_text = "Are you sure you want to quit?\nYou haven't saved yet!"
				dialog.confirmed.connect(func(): get_tree().quit())
				dialog.canceled.connect(func(): dialog.queue_free())
				add_child(dialog)
				dialog.popup_centered()
			else:
				get_tree().quit()


func _process(_delta: float) -> void:
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
	var settings := settings_scene.instantiate()
	settings.canvas = canvas
	add_child(settings)
