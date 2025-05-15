extends Node

@export var settings: UserSettings
@export var data: UserData
@onready var settings_file := ProjectSettings.globalize_path("res://settings.tres")
@onready var data_file := ProjectSettings.globalize_path("res://data.tres")

func _ready() -> void:
	load_settings()
	load_data()

func _exit_tree() -> void:
	save_data()

func load_settings() -> void:
	print("Loading settings from %s" % settings_file)
	if FileAccess.file_exists(settings_file):
		settings = ResourceLoader.load(settings_file, "%s" % UserSettings)
	else:
		settings = UserSettings.new()
		save_settings()

func save_settings() -> void:
	print("Saving settings to %s" % settings_file)
	if ResourceSaver.save(settings, settings_file) != OK:
		push_error("Error saving settings")

func load_data() -> void:
	print("Loading user data from %s" % data_file)
	if FileAccess.file_exists(data_file):
		data = ResourceLoader.load(data_file, "%s" % UserData)
	else:
		data = UserData.new()
		save_data()

func save_data() -> void:
	print("Saving user data to %s" % data_file)
	if ResourceSaver.save(data, data_file) != OK:
		push_error("Error saving user data")

func update_recent_files() -> void:
	# Remove duplicates / problematic entries
	var new: Array[String] = []
	for item in data.recent_files:
		if not new.has(item) and len(item) != 0:
			new.append(item)
	data.recent_files = new
		
	if ProjectManager.current_project != null && len(ProjectManager.current_project.path) > 0:
		var new_path := ProjectManager.current_project.path
		
		# Don't add path if it already exists
		if new_path not in data.recent_files:
			data.recent_files.append(new_path)
		
		# Max limit
		while len(data.recent_files) > 10:
			data.recent_files.remove_at(0)
