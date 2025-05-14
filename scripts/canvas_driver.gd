class_name CanvasDriver
extends Sprite2D

# TODO: Handle resizing of the canvas

@export var main: Main
@export var brush_strength: Slider
@export var draw_utils: CanvasDrawUtils
@export var camera: Camera2D
@export var filter: Sprite2D
const tile_size: Vector2 = Vector2(64, 64)
const subpix_pad := Vector2(1.0, 1.0)
const subpix_sep := Vector2(3.0, 3.0);
const subpix_size := tile_size - (subpix_pad * 3.0)
const sub_size := subpix_size / Vector2(3, 1)
var traveling := false
var tool := Tool.Draw
var zoom := 1.0
var dragging := 0
var dragged_tiles := Dictionary()
var zoom_min := 0.2
var zoom_max := 2.0
var canvas_size_text := ""
@onready var pixel_paint_color := main.pixel_paint_color.color

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
	func get_pos() -> Vector2:
		return Vector2(pixel) + (Vector2.RIGHT * offset)
	func equals(other) -> bool:
		if other is SubPixel:
			return (self.pixel == other.pixel && self.offset == other.offset)
		return false

enum Tool {
	Draw,
	Fill
}
enum PaintMode {
	Pixel = 0,
	Subpixel = 1
}


func _ready():
	# Project
	var setup := func():
		main.preview_image.texture = ImageTexture.create_from_image(ProjectManager.current_project.image)

		# FIXME: Sprites can't have a set size without a texture (workaround)
		var size := Vector2i(get_canvas_size())
		var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		texture = ImageTexture.create_from_image(image)
		filter.texture = texture
		_on_pixels_updated()

	ProjectManager.project_changed.connect(setup)
	setup.call()

	# Settings
	var update_from_settings := func():
		filter.visible = Autoload.settings.fancy_shader
		main.preview_image_window.visible = Autoload.settings.show_preview
		draw_utils.queue_redraw()
		queue_redraw()
	Autoload.settings.changed.connect(update_from_settings)
	update_from_settings.call()

func _process(_delta: float) -> void:
	var pos := get_local_mouse_position()
	var pixel_pos = Vector2i(pos / tile_size)
	var sub_offset = Vector2i(((pos / tile_size) - Vector2(pixel_pos)) * 3)
	subpixel_info["hovering"] = SubPixel.new(pixel_pos, sub_offset.x)

# Drawing the canvas
func _draw() -> void:
	var image := ProjectManager.current_project.image
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)  # TODO: Try caching the pixel on each draw
			var pos := Vector2(x, y)

			match paint_mode():
				PaintMode.Subpixel:
					# Outside
					draw_rect(Rect2(x * tile_size.x, y * tile_size.y, tile_size.x, tile_size.y), Color.BLACK)

					# Extra
					var draw_subpixel := func(rect: Rect2, channel: Channels):
						var color: Color
						match channel:
							Channels.RED:
								color = Color(Autoload.settings.subpixel_colours["dot1"] * pixel.r)
							Channels.GREEN:
								color = Color(Autoload.settings.subpixel_colours["dot2"] * pixel.g)
							Channels.BLUE:
								color = Color(Autoload.settings.subpixel_colours["dot3"] * pixel.b)
						color = color.clamp(Color.WHITE * 0.3, Color.WHITE)
						draw_rect(rect, color)

					# RGB interior
					var padded_rect := Rect2(
						(pos * tile_size) + subpix_pad,
						subpix_size
					)
					draw_subpixel.call(Rect2(
						padded_rect.position + subpix_sep,
						sub_size - subpix_sep
					), Channels.RED)
					draw_subpixel.call(Rect2(
						padded_rect.position + (sub_size * Vector2(1, 0)) + subpix_sep,
						sub_size - subpix_sep
					), Channels.GREEN)
					draw_subpixel.call(Rect2(
						padded_rect.position + (sub_size * Vector2(2, 0)) + subpix_sep,
						sub_size - subpix_sep
					), Channels.BLUE)

				PaintMode.Pixel:
					var rect := Rect2(pos * tile_size, tile_size)
					draw_rect(rect, pixel)

	# Info text
	for i in len(canvas_size_text):
		draw_char(preload("res://fonts/Better VCR 6.1.ttf"), Vector2(i * 16, -4), canvas_size_text[i])

func _on_pixels_updated():
	var image := ProjectManager.current_project.image

	# Updating project stats
	canvas_size_text = "Size: %sx%s\n    (%s MB)" % [
		image.get_width(),
		image.get_height(),
		snapped(image.get_data_size() * 0.000001, 0.001)
	]

	# Updating the image preview (costly but can't do anything about it)
	main.preview_image.texture.set_image(image)

	# Marking the project unsaved
	ProjectManager.current_project.mark_dirty()
	queue_redraw()

func set_subpixel(sub: SubPixel, value: float) -> void:
	var image := ProjectManager.current_project.image
	if sub.pixel < Vector2i.ZERO or sub.pixel > image.get_size():
		return
	var color := image.get_pixelv(sub.pixel)

	# TODO: This can be optiimzed by using math instead of a match
	match sub.offset:
		Channels.RED:
			color.r = value
		Channels.GREEN:
			color.g = value
		Channels.BLUE:
			color.b = value
	set_pixel_rgb(sub.pixel, color.r, color.g, color.b)

func set_pixel_rgb(pixel: Vector2i, r: float, g: float, b: float) -> void:
	set_pixel(pixel, Color(r, g, b))
func set_pixel(pixel: Vector2i, color: Color) -> void:
	var image := ProjectManager.current_project.image
	if pixel < Vector2i.ZERO or pixel > image.get_size():
		return
	image.set_pixelv(pixel, color)
	_on_pixels_updated()

func get_canvas_size() -> Vector2:
	return Vector2(ProjectManager.current_project.image.get_size()) * tile_size

func paint_mode() -> PaintMode:
	return main.paint_mode.get_selected_id() as PaintMode

# The intensity of the brush. Returns 0 if the user isn't painting
func get_brush_value() -> float:
	return (brush_strength.value if dragging == MOUSE_BUTTON_LEFT else 0.0)

func get_paint_colour() -> Color:
	return pixel_paint_color * get_brush_value()

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				traveling = event.pressed
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN when event.pressed:
				var modifier := (1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0)
				zoom = clamp(zoom + (0.1 * modifier), zoom_min, zoom_max)
				camera.zoom = Vector2.ONE * zoom
				draw_utils.queue_redraw()
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if subpixel_info["hovering"] == null:
					push_warning("Hovering is null")
					return
				var value := (brush_strength.value if event.button_index == MOUSE_BUTTON_LEFT else 0.0)
				if event.pressed:
					dragging = event.button_index
					match tool:
						Tool.Draw:
							if paint_mode() == PaintMode.Subpixel:
								set_subpixel(subpixel_info["hovering"], value)
							else:
								set_pixel(subpixel_info["hovering"].pixel, get_paint_colour())
						Tool.Fill:
							subpixel_info["start"] = subpixel_info["hovering"]
				else:
					subpixel_info["end"] = subpixel_info["hovering"]

					match tool:
						Tool.Fill:
							var color := get_paint_colour() if paint_mode() == PaintMode.Pixel else (Color.WHITE * get_brush_value())
							if subpixel_info["start"].pixel == subpixel_info["end"].pixel:  # Filling a single pixel
								set_pixel(subpixel_info["start"].pixel, color)
							else:  # Filling a zone
								var start: Vector2i = subpixel_info["start"].pixel.min(subpixel_info["end"].pixel)
								var end: Vector2i = subpixel_info["start"].pixel.max(subpixel_info["end"].pixel)
								for y in range(start.y, end.y + 1):
									for x in range(start.x, end.x + 1):
										# TODO: Port sub-pixel filling to the new canvas system
										set_pixel(Vector2i(x, y), color)
							subpixel_info["start"] = null
							subpixel_info["end"] = null
					draw_utils.queue_redraw()
					dragging = 0
					dragged_tiles.clear()
	elif event is InputEventMouseMotion:
		if traveling:
			var zoomies = clamp(pow(zoom_max - zoom, 20), 0.5, zoom_max);
			camera.position -= event.relative * zoomies

			# TODO: Warping the cursor around edges
			#var pad := 8
			#var mouse: Vector2i = event.position
			#var viewport_max: Vector2i = get_viewport().size - Vector2i(pad, pad)
			#var warp_destination := Vector2i()
			#if mouse.x > viewport_max.x:
				#warp_destination.x = 0
			#elif mouse.x < pad:
				#warp_destination.x = viewport_max.x
			#Input.warp_mouse(warp_destination)
		elif dragging and subpixel_info["hovering"] != null:
			var value := get_brush_value()
			match tool:
				Tool.Draw:
					# TODO: Make a map of all the cursor locations and paint between them to avoid gaps when moving too fast
					if paint_mode() == PaintMode.Subpixel:
						set_subpixel(subpixel_info["hovering"], value)
					else:
						set_pixel(subpixel_info["hovering"].pixel, get_paint_colour())
				Tool.Fill:
					pass
			draw_utils.queue_redraw()
