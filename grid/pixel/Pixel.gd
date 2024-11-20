class_name Pixel
extends Control

@export var canvas: CanvasDriver

@export_group("Subs")
@export var sub_red: SubPixel
@export var sub_green: SubPixel
@export var sub_blue: SubPixel
var color_off := Color(0.1, 0.1, 0.1)
var pos := Vector2i.ZERO

func _ready() -> void:
	# process_thread_group = ProcessThreadGroup.PROCESS_THREAD_GROUP_SUB_THREAD
	sub_red.updated.connect(canvas._on_pixel_updated)
	sub_green.updated.connect(canvas._on_pixel_updated)
	sub_blue.updated.connect(canvas._on_pixel_updated)

#region Public
func construct_colour() -> Color:
	return Color(
		sub_red.get_subpixel(),
		sub_green.get_subpixel(),
		sub_blue.get_subpixel()
	)
func set_red(enabled: float) -> void:
	sub_red.set_subpixel(enabled)
func set_green(enabled: float) -> void:
	sub_green.set_subpixel(enabled)
func set_blue(enabled: float) -> void:
	sub_blue.set_subpixel(enabled)
func set_colour(color: Color) -> void:
	set_red(color.r)
	set_green(color.g)
	set_blue(color.b)
#endregion
