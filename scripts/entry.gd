extends Control

@export var create_button: Button
@export var load_button: Button
@export var info: RichTextLabel

func _ready() -> void:
	create_button.pressed.connect(func(): ProjectManager.new_project(self))
	load_button.pressed.connect(func(): ProjectManager.load_project(self))
	info.text = ""
	add_info_line("Version %s\n" % ProjectSettings.get_setting("application/config/version"))
	add_info_line("NOTE: Subpix is a work in progress. Report any bugs you encounter [url=https://github.com/FlooferLand/subpix/issues]on GitHub![/url]")
	add_info_line("Made with the Godot Engine ([url=godotengine.org/license]godotengine.org/license[/url])")
	info.meta_clicked.connect(
		func(meta):
			OS.shell_open(str(meta))
	)

func add_info_line(line: String):
	info.append_text(
		line.replace("[url=", "[color=cyan][url=")
			.replace("[/url]", "[/url][/color]") + "\n"
	)
