extends Control

@export var create_button: Button
@export var load_button: Button
@export var version: Label

func _ready() -> void:
	version.text = "Version %s\nNOTE: Subpix is a work in progress. Report any bugs you encounter on the GitHub!\nhttps://github.com/FlooferLand/subpix" % ProjectSettings.get_setting("application/config/version")
	create_button.pressed.connect(func(): ProjectManager.new_project(self))
	load_button.pressed.connect(func(): ProjectManager.load_project(self))
