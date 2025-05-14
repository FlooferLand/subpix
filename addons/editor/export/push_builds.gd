@tool
extends Node

@export var export: EditorExportScript
@export var progress_bar: ProgressBar
@export var start_button: Button
@export var output: VBoxContainer
@export var starting_label: Label
@export var stylebox_bg: StyleBoxFlat

const channels := ["windows", "linux", "macos", "web"]
var build_threads: Dictionary[String, Thread] = {}

func _process(delta: float) -> void:
	for id in build_threads.keys():
		var thread: Thread = build_threads[id]
		if not thread.is_alive():
			thread.wait_to_finish()
			build_threads.erase(id)
	start_button.disabled = len(build_threads) != 0

func _enter_tree() -> void:
	for id in build_threads:
		var thread: Thread = build_threads[id]
		thread.wait_to_finish()

func push_build(channel: String) -> void:
	var zip_name := export.get_build_name(channel)
	var out_file_name := ""
	if channel == "web":
		starting_label.call_deferred("set_text", "Unzipping %s.." % channel)
		_extract_web_files(zip_name)
		progress_bar.call_deferred("set_value", progress_bar.get_value() + 1)
		out_file_name = "web/"
	else:
		out_file_name = zip_name
	
	# Building
	var version: String = ProjectSettings.get_setting("application/config/version")
	var cli_output: Array[String] = ["Pushing out channels/%s" % channel]
	var exit_code := OS.execute("butler", [
		"push", "builds/"+out_file_name, "flooferland/subpix:"+channel,
		"--fix-permissions", "--userversion", version
	], cli_output, true)
	#var exit_code := OS.execute("butler", [], cli_output, true)
	cli_output.append("Exit code %s" % exit_code)
	push_build_output(channel, cli_output.duplicate())
	progress_bar.call_deferred("set_value", progress_bar.get_value() + 1)

func push_build_output(channel: String, info: Array[String]) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", stylebox_bg)
	
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var label := Label.new()
	label.add_theme_constant_override("line_spacing", 0)
	label.add_theme_constant_override("paragraph_spacing", 0)
	label.text = channel + ':'
	label.clip_text = true
	container.add_child(label)
	
	var edit := TextEdit.new()
	edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(0, 120)
	edit.editable = false
	edit.text = '\n'.join(info)
	container.add_child(edit)
	panel.add_child(container)
	output.call_deferred("add_child", panel)

func _extract_web_files(zip_name: String):
	# Removing past build directory
	DirAccess.remove_absolute("res://builds/web/")
	
	# Extracting
	var reader := ZIPReader.new()
	reader.open("res://builds/"+zip_name)
	DirAccess.make_dir_absolute("res://builds/web/")
	var root_dir := DirAccess.open("res://builds/web/")
	var files := reader.get_files()
	for file_path in files:
		if file_path.ends_with("/"):  # If the current entry is a directory.
			root_dir.make_dir_recursive(file_path)
			continue
		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var file := FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
		var buffer := reader.read_file(file_path)
		file.store_buffer(buffer)

func _on_push_builds_pressed() -> void:
	for child in output.get_children():
		child.queue_free()
	starting_label.text = "Building.."
	progress_bar.value = 0
	progress_bar.max_value = len(channels) + 1  # +1 is the web unzip
	for channel in channels:
		var thread := Thread.new()
		thread.start(push_build.bind(channel))
		build_threads[thread.get_id()] = thread
