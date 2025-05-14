extends Window

@export var widgets: VBoxContainer
var canvas: CanvasDriver  # Set by Main when the settings window is created

func _ready() -> void:
	for property in Autoload.settings.get_property_list():
		if not property.usage & PROPERTY_USAGE_EDITOR:
			continue
		if property.name.begins_with("resource_") or property.name == "script":
			continue
		widgets.add_child(construct_entry(property, Autoload.settings[property.name], Autoload.settings))

	# Reset button
	var reset := Button.new()
	reset.text = "Reset"
	reset.pressed.connect(func():
		var new := Settings.new()
		for property in Autoload.settings.get_property_list():
			if not property.usage & PROPERTY_USAGE_EDITOR:
				continue
			Autoload.settings[property.name] = new[property.name]
		Autoload.settings.emit_signal("changed")
		Autoload.save_settings()
		queue_free()
	)
	widgets.add_child(reset)

func construct_entry(property: Variant, value: Variant, set_obj: Variant, layer: int = 0) -> Node:
		# Layer margin
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20 * layer)
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.custom_minimum_size = Vector2(0, 32)

		# This row's container
		var container: SplitContainer = (VSplitContainer.new() if property.type == TYPE_DICTIONARY else HSplitContainer.new());
		container.dragger_visibility = SplitContainer.DRAGGER_HIDDEN

		# Name
		var name_label := Label.new()
		name_label.text = property.name.replace("_", " ")
		container.add_child(name_label)

		# Value
		var out: Control
		match property.type as int:
			TYPE_BOOL:
				var checkbox := CheckBox.new()
				checkbox.button_pressed = value as bool
				checkbox.focus_mode = Control.FOCUS_NONE
				checkbox.toggled.connect(func(new):
					set_obj[property.name] = new
					Autoload.settings.emit_signal("changed")
				)
				out = checkbox
			TYPE_STRING:
				var line_edit := LineEdit.new()
				line_edit.text = value as String
				line_edit.text_submitted.connect(func(new):
					set_obj[property.name] = new
					Autoload.settings.emit_signal("changed")
				)
				out = line_edit
			TYPE_COLOR:
				var color_picker := ColorPickerButton.new()
				color_picker.color = value as Color
				color_picker.edit_alpha = true
				color_picker.color_changed.connect(func(new):
					set_obj[property.name] = new
					Autoload.settings.emit_signal("changed")
				)
				out = color_picker
			TYPE_DICTIONARY:
				var dict_prop_container := VBoxContainer.new()

				# Collecting values from the dict
				var value_dict := value as Dictionary
				for key in value_dict:
					var prop := {}
					prop["name"] = key
					prop["type"] = typeof(value_dict[key])
					dict_prop_container.add_child(construct_entry(prop, value_dict[key], set_obj[property.name], layer + 1))
				out = dict_prop_container
			_:
				push_error("Settings type '%s' not implemented for '%s'" % [property.type, property.name])

		# Out stuff idk
		container.add_child(out)
		margin.add_child(container)
		return margin

func _on_close_requested() -> void:
	Autoload.save_settings()
	canvas.queue_redraw()
	queue_free()
