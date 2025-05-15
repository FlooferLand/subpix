class_name UserSettings
extends Resource

@export_group("Theme")
@export var subpixel_colours := {
	"dot1": Color(1.0, 0, 0),
	"dot2": Color(0, 1.0, 0),
	"dot3": Color.BLUE
}
@export var grid_colour := Color.WHITE.lerp(Color.TRANSPARENT, 0.3)

@export_group("Misc")
@export var fancy_shader := true
@export var show_preview := true
@export var show_subpixel_grid := true
@export var show_pixel_grid := true
