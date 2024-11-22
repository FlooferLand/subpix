class_name CanvasDriver
extends Sprite2D

# TODO: Handle resizing of the canvas

@export var main: Main
@export var pixel_rows_filter: ColorRect
@export var brush_strength: Slider
@export var draw_on_top: DrawOnTop
@export var canvas_size: Label
@export var camera: Camera2D
var traveling := false
var tool := Tool.Draw
var move := Vector2.ZERO
var zoom := 1.0
var dragging := 0
var dragged_tiles := Dictionary()
@onready var tile_size: Vector2 = Vector2(48, 48)

var subpixel_info := {
	"hovering": null,
	"start": null,
	"end": null
}
enum Channels {
	RED = 0,
	GREEN = 1,
	BLUE = 2
}
class SubPixel:
	var pixel: Vector2i
	var offset: Channels
	func _init(pixel_pos: Vector2i, subpixel_offset: Channels) -> void:
		pixel = pixel_pos
		offset = subpixel_offset
	func equals(other) -> bool:
		if other is SubPixel:
			return (self.pixel == other.pixel && self.offset == other.offset)
		return false

enum Tool {
	Draw,
	Fill
}

func _ready():
	# Project
	var setup := func():
		main.preview_image.texture = ImageTexture.create_from_image(ProjectManager.current_project.image)

		# Sprites can't have a set size without a texture
		var size := get_canvas_size()
		var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		texture = ImageTexture.create_from_image(image)
		_on_pixels_updated()

	ProjectManager.project_changed.connect(setup)
	setup.call()

	# Settings
	var update_from_settings := func():
		pixel_rows_filter.visible = Autoload.settings.fancy_shader
		main.preview_image_window.visible = Autoload.settings.show_preview
	Autoload.settings.changed.connect(update_from_settings)
	update_from_settings.call()

# Drawing the canvas
func _draw() -> void:
	var image := ProjectManager.current_project.image
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)  # TODO: Cache getting the pixel on each draw
			var pos := Vector2(x, y)

			# Outside
			#draw_rect(Rect2(x * tile_size.x, y * tile_size.y, tile_size.x, tile_size.y), Color.BLACK)

			# Inside
			var pad := Vector2(3.0, 3.0);
			var subpix_sep := Vector2(0.3, 0);
			var padded_rect := Rect2(pos * tile_size, tile_size)
			#draw_rect(padded_rect, Color(0.1, 0.1, 0.1))

			# RGB
			var sub_size := (padded_rect.size - pad) / Vector2(3, 1)
			draw_rect(Rect2(
				padded_rect.position + (pad * Vector2.RIGHT),
				sub_size - subpix_sep
			), Color(pixel.r, 0.0, 0.0))
			draw_rect(Rect2(
				padded_rect.position + (sub_size * Vector2(1, 0)),
				sub_size
			), Color(0.0, pixel.g, 0.0))
			draw_rect(Rect2(
				padded_rect.position + (pad * Vector2.LEFT) + (sub_size * Vector2(2, 0)),
				sub_size + subpix_sep
			), Color(0.0, 0.0, pixel.b))

	var text := "Hello World!"
	for i in len(text):
		draw_char(load("res://fonts/Better VCR 6.1.ttf"), Vector2(i * 16, 0), text[i])

func _on_pixels_updated():
	var image := ProjectManager.current_project.image

	# Updating project stats
	canvas_size.text = "Size: %sx%s\n    (%s MB)" % [
		image.get_width(),
		image.get_height(),
		snapped(image.get_data_size() * 0.000001, 0.001)
	]

	# Marking the project unsaved
	ProjectManager.current_project.mark_dirty()
	queue_redraw()

func set_subpixel(sub: SubPixel, value: float) -> void:
	var image := ProjectManager.current_project.image
	var color := image.get_pixelv(sub.pixel)

	# TODO: This can be optiimzed by using math instead of a match
	match sub.offset:
		Channels.RED:
			color.r = value
		Channels.GREEN:
			color.g = value
		Channels.BLUE:
			color.b = value
	set_pixel(sub.pixel, color.r, color.g, color.b)

func set_pixel(pixel: Vector2i, r: float, g: float, b: float) -> void:
	var image := ProjectManager.current_project.image
	image.set_pixelv(pixel, Color(r, g, b))
	_on_pixels_updated()

func get_canvas_size() -> Vector2:
	return Vector2(ProjectManager.current_project.image.get_size()) * tile_size

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				traveling = event.pressed
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN when event.pressed:
				var modifier := (1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0)
				zoom = clamp(zoom + (0.05 * modifier), 0.3, 2.0)
				#canvas_layer.offset = get_local_mouse_position()
				camera.zoom = Vector2.ONE * zoom
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if subpixel_info["hovering"] == null:
					push_warning("Hovering is null")
					return
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
						if subpixel_info["start"].pixel == subpixel_info["end"].pixel:  # Filling a single pixel
							set_pixel(subpixel_info["start"].pixel, value, value, value)
						else:  # Filling a zone
							var start: Vector2i = subpixel_info["start"].pixel.min(subpixel_info["end"].pixel)
							var end: Vector2i = subpixel_info["start"].pixel.max(subpixel_info["end"].pixel)
							for y in range(start.y, end.y + 1):
								for x in range(start.x, end.x + 1):
									# TODO: Port sub-pixel filling to the new canvas system
									set_pixel(Vector2i(x, y), value, value, value)
						subpixel_info["start"] = null
						subpixel_info["end"] = null
						draw_on_top.queue_redraw()
					dragging = 0
					dragged_tiles.clear()
	elif event is InputEventMouseMotion:
		if traveling:
			var mouse: Vector2 = event.relative
			move -= mouse
			camera.position = move
		elif dragging and subpixel_info["hovering"] != null:
			match tool:
				Tool.Draw:
					# TODO: Make a map of all the cursor locations and paint between them to avoid gaps when moving too fast
					subpixel_info["hovering"].set_subpixel(brush_strength.value if dragging == MOUSE_BUTTON_LEFT else 0.0)
				Tool.Fill:
					draw_on_top.queue_redraw()
