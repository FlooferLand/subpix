@tool
class_name EditorExportScript
extends Window

func _ready() -> void:
	visible = false
	close_requested.connect(queue_free)

# Gets the build name for a channel
func get_build_name(channel: String) -> String:
	match channel:
		"windows": return "Subpix.Windows.zip"
		"linux": return "Subpix.Linux.zip"
		"macos": return "Subpix.MacOS.zip"
		"web": return "Subpix.Web.zip"
		_:
			push_error("Unknown platform with channel %s" % channel)
			return ""
