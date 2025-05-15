extends Node

# Handles image loading / saving
# The web code is based on http://kehomsforge.com/tutorials/single/save-load-file-system-godot-html-export (thank you for the amazing tutorial)

class Project:
	var path: String
	var image: Image
	var dirty: bool = false
	func _init(img: Image, project_path: String = "") -> void:
		self.path = project_path
		self.image = img
	func mark_dirty() -> void:
		dirty = true
	func clear_dirty() -> void:
		dirty = false

signal project_changed(new: Dictionary)
var current_project: Project = null
var main_scene := "res://scenes/main.tscn"
var max_image_size := Vector2(128, 128)

## Dialog for creating new projects
func new_project(caller: Node):
	var window := Window.new()
	window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	window.transient = true
	window.exclusive = true
	window.title = "New project"
	window.min_size = Vector2(300, 500)
	window.size = window.min_size

	# Backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK;
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	backdrop.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Main container
	var container := VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Margin container
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(container)
	
	var notice_label := Label.new()
	notice_label.visible = false
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.add_theme_color_override("font_color", Color.YELLOW)
	var check_warn_size := func(text: String):
		if not text.is_valid_int(): return
		var num := int(text)
		if num >= max_image_size.x or num >= max_image_size.y:
			notice_label.text = """
			A size larger than %sx%s is not recommended.\n
			The editor will be very laggy beyond this point
			""" % [int(max_image_size.x), int(max_image_size.y)]
			notice_label.visible = true
		else:
			notice_label.text = ""
			notice_label.visible = false

	var width_edit := LineEdit.new()
	width_edit.placeholder_text = "Width"
	width_edit.text_changed.connect(check_warn_size)
	container.add_child(width_edit)

	var height_edit := LineEdit.new()
	height_edit.placeholder_text = "Height"
	height_edit.text_changed.connect(check_warn_size)
	container.add_child(height_edit)

	var create := Button.new()
	create.text = "Create"
	var make_project := func():
		var width := -1
		var height := -1
		if width_edit.text.is_valid_int() and height_edit.text.is_valid_int():
			width = int(width_edit.text)
			height = int(height_edit.text)
		else:
			OS.alert("Width/height must be numbers")
			return

		# Creating the image
		var image := Image.create_empty(width, height, false, Image.FORMAT_RGB8)
		image.fill(Color.BLACK)
		current_project = Project.new(image)
		caller.get_tree().change_scene_to_file(main_scene)
		window.queue_free()
	create.pressed.connect(make_project)
	container.add_child(create)

	# Window and stuff
	window.close_requested.connect(window.queue_free)
	window.add_child(backdrop)
	window.add_child(margin)
	add_child(window)
	
	# Finishing up
	container.add_child(notice_label)
	height_edit.text_submitted.connect(make_project.unbind(1))
	width_edit.call_deferred("grab_focus")

## Loads a project from a path. NOT supported on web
func load_project(path: String):
	if OS.get_name() == "Web":
		return
	var image := Image.load_from_file(path)
	current_project = Project.new(image, path)
	(Engine.get_main_loop() as SceneTree).change_scene_to_file(main_scene)

## Shows a file picker dialog to load a project
func pick_project(caller: Node):
	var load_func := func(buffer, path=""):
		var image := Image.new()
		var err := image.load_png_from_buffer(buffer)
		if err != OK:
			OS.alert("Loading failed due to error '%s'" % err, "Error")
			return
		current_project = Project.new(image, path)
		caller.get_tree().change_scene_to_file(main_scene)

	if OS.get_name() != "Web":
		var dialog := FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_configure_filedialog(dialog)
		dialog.file_selected.connect(
			func(path):
				var file := FileAccess.open(path, FileAccess.READ)
				var buffer := file.get_buffer(file.get_length())
				load_func.call(buffer, path)
				dialog.queue_free()
		)
		add_child(dialog)
		dialog.popup()
	else:
		WebFilesystem.load_file("project_loaded", ".png", load_func)

func save_project(_caller: Node, inplace: bool = true) -> void:
	# Save function
	var save := (func(path=''):
		var buffer := current_project.image.save_png_to_buffer()
		current_project.clear_dirty()
		print("Saved project to '%s'!" % path)
		return buffer
	)

	# Optional save dialog
	if OS.get_name() != "Web":
		if current_project and !current_project.path.is_empty() and inplace:
			var path := current_project.path
			var buffer: PackedByteArray = save.call(path)
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(buffer)
			file.close()
		else:
			var dialog := FileDialog.new()
			dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			dialog.file_selected.connect(func(path):
				if path != "":
					var buffer: PackedByteArray = save.call(path)
					var file := FileAccess.open(path, FileAccess.WRITE)
					file.store_buffer(buffer)
					file.close()

					current_project.path = path
					dialog.queue_free()
				else:
					OS.alert("Can't save to an empty path!")
			)
			_configure_filedialog(dialog)
			add_child(dialog)
			dialog.popup()
	else:
		var buffer: PackedByteArray = save.call()
		WebFilesystem.save_file("save_project" if inplace else "export_project", buffer, "image.png", "image/png", inplace)

func export_image(caller: Node) -> void:
	save_project(caller, false)

func export_image_large(caller: Node, canvas: CanvasDriver) -> void:
	# Capturing the screenshot
	# TODO: Make sure exporting still works with the new canvas
	var export := func(_path):
		var control := canvas.camera
		var control_og_parent := control.get_parent()

		# Creating a viewport
		var viewport := SubViewport.new()
		viewport.disable_3d = true
		viewport.transparent_bg = true
		viewport.size = canvas.pixel_rows.size
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		caller.add_child(viewport)

		# Reparenting
		control.reparent(viewport, false)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
		control.set_offsets_preset(Control.PRESET_FULL_RECT)

		# Creating the filter
		if Autoload.settings.fancy_shader:
			var filter_mat := ShaderMaterial.new()
			filter_mat.shader = preload("res://shaders/pixelgrid.gdshader")
			var filter := ColorRect.new()
			filter.material = filter_mat
			filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			filter.size_flags_vertical = Control.SIZE_EXPAND_FILL
			filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			viewport.add_child(filter)

		# Rendering
		await RenderingServer.frame_post_draw
		var image: Image = Image.create_empty(viewport.size.x, viewport.size.y, false, Image.FORMAT_RGB8)
		image.fill(Color.BLACK)
		image.copy_from(viewport.get_texture().get_image())
		viewport.queue_free()

		# Reseting parent
		control.reparent(control_og_parent, false)

		#image.resize(size.x * 4.0, size.y * 4.0, Image.INTERPOLATE_NEAREST)
		return image.save_png_to_buffer()

	# Popping up the save dialog
	if OS.get_name() != "Web":
		var dialog := FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		dialog.file_selected.connect(func(path):
			var buffer: PackedByteArray = export.call(path)
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(buffer)
			dialog.queue_free()
		)
		_configure_filedialog(dialog)
		add_child(dialog)
		dialog.popup()
	else:
		var buffer: PackedByteArray = export.call()
		WebFilesystem.save_file("export_project", buffer, "image.png", "image/png", false)

func _configure_filedialog(dialog: FileDialog) -> void:
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.use_native_dialog = true
	dialog.force_native = true
	dialog.min_size = get_window().size * 0.8
	dialog.size = dialog.min_size
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.add_filter("*.png", "Images")

	if OS.is_debug_build():
		dialog.current_dir = ProjectSettings.globalize_path("res://textures/")
	else:
		var pictures := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
		if DirAccess.dir_exists_absolute(pictures):
			dialog.current_dir = pictures

func _ready() -> void:
	if not ResourceLoader.exists(main_scene):
		push_error("Broken reference to main scene inside the project manager script!")
