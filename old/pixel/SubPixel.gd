#class_name OldSubPixel
#extends ColorRect
#
#@export var id := ""
#@export var pixel: Pixel
#
#var _on := 0.0
#var pos := Vector2i.ZERO
#var color_on: Color
#signal updated(pixel: Pixel, subpixel: SubPixel)
#var hovering := false
#
#func _enter_tree() -> void:
	#update_colour()
#
	## Getting the colour
	#var init_colour_preference := func():
		#var col: Color = Autoload.settings.subpixel_colours[id]
		#color_on = col if col != null else color
	#Autoload.settings.changed.connect(init_colour_preference)
	#init_colour_preference.call()
#
#func _ready() -> void:
	## Connecting signals
	#mouse_entered.connect(
		#func():
			#pixel.canvas.subpixel_info.hovering = self
			#hovering = true
			#update_colour()
	#)
	#mouse_exited.connect(
		#func():
			#hovering = false
			#update_colour()
	#)
#
#func update_colour() -> void:
	#color = pixel.color_off.lerp(color_on, _on)
	#if hovering:
		#color = color.lightened(0.1)
#
#func get_subpixel() -> float:
	#return _on
#func set_subpixel(enabled: float) -> void:
	#_on = enabled
	#update_colour()
	#emit_signal("updated", pixel, self)
