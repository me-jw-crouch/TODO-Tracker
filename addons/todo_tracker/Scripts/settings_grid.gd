# @tool
# class_name
extends Node
## docstring

# Signals

# Enums

# CONSTANTS

# @export variables

# public variables
var settings_grid : GridContainer

# private variables

# @onready variables

# func _init() -> void:

func _enter_tree() -> void:
	var dock = get_parent()
	var settings_grid = dock.get_node(
			"PanelContainer/VSplitContainer/LowerContainer/SettingsGrid")

# func _ready() -> void:

# remaining built-in virtual methods

# public methods
func add_dict_rows_to_grid(dict):
	for query in dict:
		var color_picker = ColorPickerButton.new()
		color_picker.color = dict[query]
		settings_grid.add_child(color_picker)

		var line_edit = LineEdit.new()
		line_edit.text = query
		line_edit.add_theme_font_size_override("font_size", 10)
		line_edit.expand_to_text_length = true
		settings_grid.add_child(line_edit)


func add_array_rows_to_grid(array): # TODO add blank labels
	for item in array:
		var label = Label.new()
		label.text = " "
		settings_grid.add_child(label)

		var line_edit = LineEdit.new()
		line_edit.text = item
		line_edit.add_theme_font_size_override("font_size", 10)
		line_edit.expand_to_text_length = true
		settings_grid.add_child(line_edit)


func add_branch_color_picker(title, color):
	var label = Label.new()
	label.text = title
	var color_picker = ColorPickerButton.new()
	color_picker.color = color
	color_picker.set_name("branch_color_picker")
	color_picker.connect("color_changed", set_branch_color)
	settings_grid.add_child(label)
	settings_grid.add_child(color_picker)
