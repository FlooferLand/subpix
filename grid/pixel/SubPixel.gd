class_name SubPixel
extends ColorRect

@export var id := ""
@export var pixel: Pixel

var _on := 0.0
var pos := Vector2i.ZERO
var color_on: Color
signal updated(pixel: Pixel, subpixel: SubPixel)
var hovering := false

func _enter_tree() -> void:
	color = pixel.color_off
	# Getting the colour
	var update_colours := func():
		var col: Color = Autoload.settings.subpixel_colours[id]
		color_on = col if col != null else color
	Autoload.settings.changed.connect(update_colours)
	update_colours.call()

func _ready() -> void:
	# Connecting signals
	mouse_entered.connect(
		func():
			pixel.canvas.subpixel_info.hovering = self
			hovering = true
	)
	mouse_exited.connect(
		func():
			hovering = false
	)

func _process(_delta: float) -> void:
	color = pixel.color_off.lerp(color_on, _on)
	if hovering:
		color = color.lightened(0.1)

func get_subpixel() -> float:
	return _on
func set_subpixel(enabled: float) -> void:
	_on = enabled
	emit_signal("updated", pixel, self)
