class_name CanvasDrawUtils
extends Node2D

@export var canvas: CanvasDriver
@export var aliasing_curve: Curve

# A number that gets bigger the more zoomed in the user is. Used to thicken lines to stop aliasing
func get_zoom_antialiasing(base: float, max: float) -> float:
	var remapped := (1.0 - remap(canvas.zoom, canvas.zoom_min, canvas.zoom_max, 0.0, 1.0))
	remapped = aliasing_curve.sample_baked(remapped)
	return lerp(base, max, remapped)

func _draw() -> void:
	_draw_border()
	_draw_fill_highlight()
	_draw_grid()
	_draw_subpixel_fill_notice()

func _draw_border():
	var image := ProjectManager.current_project.image
	draw_rect(Rect2(
		0, 0,
		image.get_width() * canvas.tile_size.x,
		image.get_height() * canvas.tile_size.y
	), Color.DIM_GRAY, false, get_zoom_antialiasing(2, 10))

func _draw_fill_highlight():
	if canvas.tool == CanvasDriver.Tool.Fill and canvas.subpixel_info["start"] != null:
		var start_pos: Vector2 = Vector2(canvas.subpixel_info["start"].pixel) * canvas.tile_size
		var end_pos: Vector2 = Vector2(canvas.subpixel_info["hovering"].pixel) * canvas.tile_size

		var start = start_pos.min(end_pos)
		var end = start_pos.max(end_pos) + (Vector2.ONE * canvas.tile_size)

		var rect: Rect2 = Rect2(start, end - start)
		draw_rect(rect, Color.WHITE.lerp(Color.TRANSPARENT, 0.7), true)
		draw_rect(rect, Color.WHITE, false, 2.0, false)

func _draw_grid():
	var image := ProjectManager.current_project.image
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)  # TODO: Try caching the pixel on each draw
			var pos := Vector2(x, y)
			match canvas.paint_mode():
				canvas.PaintMode.Pixel:
					if Autoload.settings.show_pixel_grid:
						var color := Autoload.settings.grid_colour.lerp(
							Autoload.settings.grid_colour.inverted(),
							pixel.get_luminance()
						)
						var rect := Rect2(pos * canvas.tile_size, canvas.tile_size)
						draw_rect(rect, color, false, get_zoom_antialiasing(4, 6))
				canvas.PaintMode.Subpixel:
					if Autoload.settings.show_subpixel_grid:
							draw_rect(Rect2(
								(pos * canvas.tile_size) + canvas.subpix_pad,
								canvas.subpix_size + (canvas.subpix_pad / 2)
							), Autoload.settings.grid_colour, false, get_zoom_antialiasing(2, 6))

func _draw_subpixel_fill_notice():
	# TODO: Add subpixel fill and remove this notice
	if canvas.paint_mode() == canvas.PaintMode.Subpixel and canvas.tool == canvas.Tool.Fill:
		var mouse := get_global_mouse_position()
		var notice := ["Subpixel fill not yet implemented!", "This will fill by pixels instead"]
		for y in len(notice):
			var line: String = notice[y]
			for x in len(line):
				var pos := Vector2(mouse.x + (x * 8), mouse.y + (y * 14)) + (Vector2.RIGHT * 32)
				draw_char(load("res://fonts/Better VCR 6.1.ttf"), pos, line[x], 10)
