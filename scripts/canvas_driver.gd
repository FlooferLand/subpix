class_name CanvasDriver
extends Control

@export var main: Main
@export var pixel_rows: VBoxContainer
@export var packed_pixel: PackedScene
@export var brush_strength: Slider
var subpixels: Dictionary = {}
var pixels: Dictionary = {}
var traveling := false
var tool := Tool.Draw
var move := Vector2.ZERO
var zoom := 1.0
var dragging := 0
var dragged_tiles: Array[SubPixel] = []
@onready var tile_size: Vector2 = packed_pixel.instantiate().size
var subpixel_info := {
	"hovering": null,
	"start": null,
	"end": null
}

enum Tool {
	Draw,
	Fill
}

func _ready():
	var setup := func():
		load_image_data(ProjectManager.current_project.image)
	setup.call()
	ProjectManager.project_changed.connect(setup)

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				traveling = event.pressed
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN when event.pressed:
				var modifier := (1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0)
				zoom = clamp(zoom + (0.05 * modifier), 0.5, 2.0)
				pixel_rows.pivot_offset = get_local_mouse_position()
				pixel_rows.scale = Vector2.ONE * zoom
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				var value := (brush_strength.value if event.button_index == MOUSE_BUTTON_LEFT else 0.0)
				if event.pressed:
					dragging = event.button_index
					if tool == Tool.Draw:
						subpixel_info["hovering"].set_subpixel(value)
					elif tool == Tool.Fill:
						subpixel_info["start"] = subpixel_info["hovering"]
						subpixel_info["start"].set_subpixel(value)
				else:
					subpixel_info["end"] = subpixel_info["hovering"]
					subpixel_info["end"].set_subpixel(value)
					if tool == Tool.Fill:
						if subpixel_info["start"] == subpixel_info["end"]:  # Filling a single pixel
							var pixel: Pixel = subpixel_info["start"].pixel
							pixel.set_red(value)
							pixel.set_green(value)
							pixel.set_blue(value)
						else:  # Filling a zone
							var start: Vector2i = subpixel_info["start"].pos.min(subpixel_info["end"].pos)
							var end: Vector2i = subpixel_info["start"].pos.max(subpixel_info["end"].pos)
							for y in range(start.y, end.y + 1):
								for x in range(start.x, end.x + 1):
									subpixels[Vector2i(x, y)].set_subpixel(value)
						subpixel_info["start"] = null
						subpixel_info["end"] = null
						queue_redraw()
					dragging = 0
					dragged_tiles.clear()
	elif event is InputEventMouseMotion:
		if traveling:
			var mouse: Vector2 = event.relative
			move -= mouse
			pixel_rows.position = -move
		elif dragging and subpixel_info["hovering"] != null:
			match tool:
				Tool.Draw:
					# TODO: Make a map of all the cursor locations and paint between them to avoid gaps when moving too fast
					subpixel_info["hovering"].set_subpixel(brush_strength.value if dragging == MOUSE_BUTTON_LEFT else 0.0)
				Tool.Fill:
					queue_redraw()

func _draw() -> void:
	if tool == Tool.Fill and subpixel_info["start"] != null:
		var start = subpixel_info["start"].global_position.min(subpixel_info["hovering"].global_position)
		var end = (subpixel_info["start"].global_position + subpixel_info["start"].size).max(subpixel_info["hovering"].global_position + subpixel_info["hovering"].size)

		var rect: Rect2 = Rect2(start, end - start)
		draw_rect(rect, Color.WHITE, false, 3.0, false)

func _on_pixel_updated(pixel: Pixel, _subpixel: SubPixel):
	var image := ProjectManager.current_project.image
	image.set_pixelv(pixel.pos, pixel.construct_colour())
	ProjectManager.current_project.mark_dirty()

func load_image_data(image: Image) -> void:
	# TODO: Handle resizing instead of clearing all pixels
	pixels.clear()
	subpixels.clear()
	for child in pixel_rows.get_children():
		child.queue_free()

	 # Creating the canvas
	var add_subpixel := func(sub: SubPixel, pos: Vector2i):
		subpixels[pos] = sub
		sub.pos = pos

	for y in range(0, image.get_height()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		var subpixel_x := 0  # too lazy with math rn
		for x in range(0, image.get_width()):
			var pixel := packed_pixel.instantiate() as Pixel
			pixel.set_colour(image.get_pixel(x, y))
			pixel.canvas = self
			row.add_child(pixel)
			pixels[Vector2i(x, y)] = pixel
			pixel.pos = Vector2i(x, y)
			add_subpixel.call(pixel.sub_red,   Vector2i(subpixel_x, y))
			subpixel_x += 1
			add_subpixel.call(pixel.sub_green, Vector2i(subpixel_x, y))
			subpixel_x += 1
			add_subpixel.call(pixel.sub_blue,  Vector2i(subpixel_x, y))
			subpixel_x += 1

		pixel_rows.add_child(row)
