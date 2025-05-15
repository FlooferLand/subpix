extends Button
class_name RecentFileWidget

@export var title: Label
@export var thumbnail: TextureRect
var filename := ""  # Filled in via RecentsGallery
var path := ""  # Filled in via RecentsGallery

func _ready() -> void:
	pressed.connect(ProjectManager.load_project.bind(path))
	tooltip_text = "Name: %s\nPath: %s" % [filename, path]
