class_name DrawOnTop
extends Control

@export var canvas: CanvasDriver

func _draw() -> void:
	if canvas.tool == CanvasDriver.Tool.Fill and canvas.subpixel_info["start"] != null:
		var start = canvas.subpixel_info["start"].global_position.min(canvas.subpixel_info["hovering"].global_position)
		var end = (canvas.subpixel_info["start"].global_position + canvas.subpixel_info["start"].size).max(canvas.subpixel_info["hovering"].global_position + canvas.subpixel_info["hovering"].size)

		var rect: Rect2 = Rect2(start, end - start)
		draw_rect(rect, Color.WHITE.lerp(Color.TRANSPARENT, 0.8), true, 2.0, false)
		draw_rect(rect, Color.WHITE, false, 2.0, false)
