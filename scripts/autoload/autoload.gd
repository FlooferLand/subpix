extends Node

@export var settings: Settings
@onready var settings_file := ProjectSettings.globalize_path("res://settings.tres")

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	print("Loading settings from %s" % settings_file)
	if FileAccess.file_exists(settings_file):
		settings = ResourceLoader.load(settings_file, "%s" % Settings)
	else:
		settings = Settings.new()
		save_settings()

func save_settings() -> void:
	print("Saving settings to %s" % settings_file)
	if ResourceSaver.save(settings, settings_file) != OK:
		push_error("Error saving settings")
