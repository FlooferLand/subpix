@tool
extends Window

func _ready() -> void:
	visible = false
	close_requested.connect(queue_free)
