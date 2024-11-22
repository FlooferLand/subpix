extends Node

class Project:
	var path: String
	var image: Image
	var dirty: bool = false
	func _init(img: Image, path: String = "") -> void:
		self.path = path
		self.image = img
	func mark_dirty() -> void:
		dirty = true
	func clear_dirty() -> void:
		dirty = false

signal project_changed(new: Dictionary)
var current_project: Project = null
var main_scene := "res://scenes/main.tscn"
var max_image_size := Vector2(96, 96)
var max_image_warning := "The image size is currently limited to %sx%s for performance reasons, sorry!\nThis will change as the program improves and gets more efficient." % [max_image_size.x, max_image_size.y]

func new_project(caller: Node, debug: bool = false):
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

	# Widgets
	var width_edit := LineEdit.new()
	width_edit.placeholder_text = "Width"
	container.add_child(width_edit)

	var height_edit := LineEdit.new()
	height_edit.placeholder_text = "Height"
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

		# Checking if size is valid
		if (width > max_image_size.x or height > max_image_size.y) and not debug:
			OS.alert(max_image_warning, "Max limit reached")
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

	# For debug mostly
	if debug:
		width_edit.text  = str(max_image_size.x)
		height_edit.text = str(max_image_size.y)
		make_project.call()

func load_project(caller: Node):
	var save := func(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var buffer := file.get_buffer(file.get_length())
		var image := Image.new()
		var err := image.load_png_from_buffer(buffer)
		if err != OK:
			OS.alert("Loading failed due to error '%s'" % err, "Error")
			return

		if image.get_width() < max_image_size.x and image.get_height() < max_image_size.y:
			current_project = Project.new(image, path)
			caller.get_tree().change_scene_to_file(main_scene)
		else:
			OS.alert(max_image_warning, "Max limit reached")

	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_configure_filedialog(dialog)
	dialog.file_selected.connect(
		func(path):
			save.call(path)
			dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup()

func save_project(_caller: Node) -> void:
	# Save function
	var save := (func(path):
		var err := current_project.image.save_png(path)
		if err != OK:
			OS.alert("Saving failed due to error '%s'" % err, "Error")
			return
		current_project.clear_dirty()
		current_project.path = path
		print("Saved project to '%s'!" % path)
	)

	# Optional save dialog
	if current_project and !current_project.path.is_empty():
		save.call(current_project.path)
	else:
		var dialog := FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		dialog.file_selected.connect(func(path):
			save.call(path)
			dialog.queue_free()
		)
		_configure_filedialog(dialog)
		add_child(dialog)
		dialog.popup()

func export_image(_caller: Node) -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.file_selected.connect(func(path):
		var err := current_project.image.save_png(path)
		if err != OK:
			OS.alert("Exporting failed due to error '%s'" % err, "Error")
		dialog.queue_free()
	)
	_configure_filedialog(dialog)
	add_child(dialog)
	dialog.popup()

func export_image_large(caller: Node, canvas: CanvasDriver) -> void:
	# Capturing the screenshot
	var save := func(path):
		var control := canvas.pixel_rows_container
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
		var err := image.save_png(path)
		if err != OK:
			OS.alert("Exporting failed due to error '%s'" % err, "Error")

	# Popping up the save dialog
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.file_selected.connect(func(path):
		save.call(path)
		dialog.queue_free()
	)
	_configure_filedialog(dialog)
	add_child(dialog)
	dialog.popup()

func _configure_filedialog(dialog: FileDialog) -> void:
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.use_native_dialog = true
	dialog.force_native = true
	dialog.min_size = get_window().size * 0.8
	dialog.size = dialog.min_size
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.add_filter("*.png", "Images")

	var pictures := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	if DirAccess.dir_exists_absolute(pictures):
		dialog.current_dir = pictures

func _ready() -> void:
	if not ResourceLoader.exists(main_scene):
		push_error("Broken reference to main scene inside the project manager script!")
