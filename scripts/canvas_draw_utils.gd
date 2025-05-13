class_name CanvasDrawUtils
extends Node2D

@export var canvas: CanvasDriver

func _draw() -> void:
	# Fill highlight
	if canvas.tool == CanvasDriver.Tool.Fill and canvas.subpixel_info["start"] != null:
		var start_pos: Vector2 = Vector2(canvas.subpixel_info["start"].pixel) * canvas.tile_size
		var end_pos: Vector2 = Vector2(canvas.subpixel_info["hovering"].pixel) * canvas.tile_size

		var start = start_pos.min(end_pos)
		var end = start_pos.max(end_pos) + (Vector2.ONE * canvas.tile_size)

		var rect: Rect2 = Rect2(start, end - start)
		draw_rect(rect, Color.WHITE.lerp(Color.TRANSPARENT, 0.7), true)
		draw_rect(rect, Color.WHITE, false, 2.0, false)

		# Notice
		if canvas.paint_mode() == canvas.PaintMode.Subpixel:
			var mouse := get_global_mouse_position()
			var notice := ["Subpixel fill not yet implemented!", "This will fill by pixels instead"]
			for y in len(notice):
				var line: String = notice[y]
				for x in len(line):
					var pos := Vector2(mouse.x + (x * 8), mouse.y + (y * 14)) + (Vector2.RIGHT * 32)
					draw_char(load("res://fonts/Better VCR 6.1.ttf"), pos, line[x], 10)
