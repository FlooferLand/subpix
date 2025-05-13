extends RichTextLabel

const subtexts := [
	"Hated by blue light filters",
	"Built on the worst code imaginable",
	"Inspired by Japhy Riddle's \"Smaller than pixelart\" video",
	"Smaller than a pixel!",
	"\"Sometimes one must sub the pixel, in order to subpixel\" - Sun Tzu"
]

func _ready() -> void:
	change_to_random()

func _process(_delta: float) -> void:
	rotation_degrees = sin(Time.get_ticks_msec() * 0.003) * 5

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		change_to_random()

func change_to_random():
	text = """
		[wave][color=yellow]%s[/color][/wave]
	""".strip_edges() % subtexts[randi_range(0, len(subtexts) - 1)]
