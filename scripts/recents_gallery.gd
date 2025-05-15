extends HBoxContainer
class_name RecentsGallery

const RecentFile := preload("uid://hccrw35ubsvv")

@export var title_label: Label

func _enter_tree() -> void:
	if OS.get_name() == "Web":
		queue_free()
	title_label.visible = false

func _ready() -> void:
	Autoload.update_recent_files()
	for path in Autoload.data.recent_files:
		var image := Image.load_from_file(path)
		var texture := ImageTexture.create_from_image(image)
		var filename := path.replace('\\', '/').rsplit('/', true, 1)[1]
		
		var file_widget := RecentFile.instantiate()
		file_widget.title.text = filename
		file_widget.thumbnail.texture = texture
		file_widget.path = path
		file_widget.filename = filename
		add_child(file_widget)
	title_label.visible = len(Autoload.data.recent_files) > 0
