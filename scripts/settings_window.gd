extends Window

@export var widgets: VBoxContainer

func _ready() -> void:
	for property in Autoload.settings.get_property_list():
		if not property.usage & PROPERTY_USAGE_EDITOR:
			continue
		if property.name.begins_with("resource_") or property.name == "script":
			continue

		widgets.add_child(construct_entry(property, Autoload.settings.get(property.name)))

func construct_entry(property: Variant, value: Variant, layer: int = 0) -> Node:
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
		name_label.text = property.name
		container.add_child(name_label)

		# Value
		var out: Control
		match property.type as int:
			TYPE_BOOL:
				var checkbox := CheckBox.new()
				checkbox.button_pressed = value as bool
				out = checkbox
			TYPE_STRING:
				var line_edit := LineEdit.new()
				line_edit.text = value as String
				out = line_edit
			TYPE_COLOR:
				var color_picker := ColorPickerButton.new()
				color_picker.color = value as Color
				color_picker.edit_alpha = false
				out = color_picker
			TYPE_DICTIONARY:
				var dict_prop_container := VBoxContainer.new()

				# Collecting values from the dict
				var value_dict := value as Dictionary
				for key in value_dict:
					var prop := {}
					prop["name"] = key
					prop["type"] = typeof(value_dict[key])
					dict_prop_container.add_child(construct_entry(prop, value_dict[key], layer + 1))
				out = dict_prop_container
			_:
				push_error("Settings type '%s' not implemented for '%s'" % [property.type, property.name])

		# Out stuff idk
		container.add_child(out)
		margin.add_child(container)
		return margin

func _on_close_requested() -> void:
	queue_free()
	Autoload.save_settings()
