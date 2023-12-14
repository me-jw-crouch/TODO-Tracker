extends Node

var settings_grid : GridContainer
var dock : Control
var query_list : Dictionary
var query_grid : GridContainer
var file_ext_grid : GridContainer
var ignore_grid : GridContainer
var customCPBtn

func _ready() -> void:
	dock = get_node("../../../..")
	settings_grid = $"."
	settings_grid = dock.get_node(
			"PanelContainer/VSplitContainer/LowerContainer/SettingsGrid")
	customCPBtn = preload("res://addons/todo_tracker/Scenes/CustomColorPickerButton.tscn")

	query_grid = $QueryGrid
	file_ext_grid = $FileExtGrid
	ignore_grid = $IgnoreGrid

	query_list = dock.query_list
	print("Settings Grid Initialized")
	update_grids()
	# TODO: Build Arrays for QueryGrid, FileExtGrid, and IgnoreGrid


func _exit_tree() -> void:
	clear_settings_grid()


func update_grids():
	add_dict_rows_to_grid()


func clear_settings_grid():
	var children = settings_grid.get_children(true)
	for child in children:
		if child.has_meta("persist"):
			child.queue_free()


func add_dict_rows_to_grid():
	for query in query_list:
		var color = query_list[query]
		var line_edit = LineEdit.new()
		line_edit.text = query
		line_edit.add_theme_font_size_override("font_size", 10)
		line_edit.expand_to_text_length = true

		var color_picker = customCPBtn.new(line_edit)
		color_picker.color = query_list[query]

		settings_grid.add_child(color_picker)
		settings_grid.add_child(line_edit)


func add_array_rows_to_grid(array, parent):
	for item in array:
		var label = Label.new()
		label.text = " "
		settings_grid.add_child(label)

		var line_edit = LineEdit.new()
		line_edit.text = item
		line_edit.add_theme_font_size_override("font_size", 10)
		line_edit.expand_to_text_length = true
		settings_grid.add_child(line_edit)
