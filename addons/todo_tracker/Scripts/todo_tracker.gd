@tool
extends EditorPlugin
## The todo plugin examines all files under 'res://' and documents instances of
## 'TO-DO' and lists their location, and gives the line in the tooltip on hover.
##
## WIP Features
## Clicking on the file should open up the file at the line within preferred
## editor.
##

enum DIR_TYPE { FOLDER, FILE }

const _DEFAULT_STR_DICT = {
	"TODO": Color("YELLOW"),
	"FIXME": Color("YELLOW"),
	"WARNING": Color("RED"),
	"WORKAROUND": Color("WHITE"),
	"QUESTION": Color("WHITE")
}
const _DEFAULT_FILETYPES = [".gd", ".txt"]
const _DEFAULT_IGNORE = ["addons"]
const _DEFAULT_BRANCH_COLOR = Color("WHITE")

var query_list : Dictionary
var filetypes_to_search : Array
var folders_to_ignore : Array
var branch_color : Color
var set_grid : GridContainer
var search_button : Button
var settings_button : Button
var results_tree : Tree
var tree_root : TreeItem
var dock : Node
var edit_btn_svg : Texture2D
var show_settings := false


func _enter_tree() -> void:
	dock = preload(
			"res://addons/todo_tracker/Scenes/todo_tracker.tscn").instantiate()

	edit_btn_svg = preload(
			"res://addons/todo_tracker/Assets/icons8-edit.svg")
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

	search_button = dock.get_node(
			"PanelContainer/VSplitContainer/HSplitContainer/SearchBtn")
	search_button.connect("pressed", _on_search_button_pressed)

	settings_button = dock.get_node(
			"PanelContainer/VSplitContainer/HSplitContainer/SettingsBtn")
	settings_button.connect("pressed", _on_settings_button_pressed)

	results_tree = dock.get_node(
			"PanelContainer/VSplitContainer/LowerContainer/ResultsTree")
	results_tree.connect("button_clicked", _edit_file_at_line)

	set_grid = dock.get_node(
		"PanelContainer/VSplitContainer/LowerContainer/SettingsGrid")

	load_config()
	_update_tree()


func _exit_tree() -> void:
	create_config_file()
	remove_control_from_docks(dock)
	dock.free()


func _on_search_button_pressed():
	results_tree.clear()
	_update_tree()


func _on_settings_button_pressed():
	if not set_grid.visible:
		initialize_settings_grid()
	else:
		_update_tree()

	set_grid.visible = not set_grid.visible
	results_tree.visible = not results_tree.visible


func create_config_file() -> void:
	var config = ConfigFile.new()
	config.set_value("settings", "query_list", query_list)
	config.set_value("settings", "filetypes_to_search", filetypes_to_search)
	config.set_value("settings", "branch_color", branch_color)
	config.set_value("settings", "folders_to_ignore", folders_to_ignore)

	config.set_value("colors", "", null)

	var err = config.save("res://addons/todo_tracker/tt.cfg")


func load_config() -> void:
	var config := ConfigFile.new()
	if config.load("res://addons/todo_tracker/tt.cfg") == OK:
		query_list = config.get_value(
			"settings",
			"query_list",
			_DEFAULT_STR_DICT)

		filetypes_to_search = config.get_value(
			"settings",
			"filetypes_to_search",
			_DEFAULT_FILETYPES)

		branch_color = config.get_value(
			"settings",
			"branch_color",
			_DEFAULT_BRANCH_COLOR)

		folders_to_ignore = config.get_value(
			"settings",
			"folders_to_ignore",
			_DEFAULT_IGNORE)
	else:
		create_config_file()


func initialize_settings_grid():
	pass


func add_to_queries():
	pass


func add_to_file_types():
	pass


func add_to_ignore_list():
	pass


func set_branch_color(color):
	branch_color = color


func _edit_file_at_line(item: TreeItem, _column, _id, _mouse_btn_index):
	var script : Script = load(item.get_meta("file_path"))
	EditorInterface.edit_script(
		script,
		item.get_meta("line_num")
		)


func _update_tree():
	results_tree.clear()

	tree_root = results_tree.create_item()
	tree_root.set_text(0, "Files")
	tree_root.set_custom_color(0, branch_color)

	var root_dir_dictionary = {
		&"path" : "res://",
		&"type": DIR_TYPE.FOLDER,
		&"contents": {}
		}

	# Recursive function, starts at root.
	root_dir_dictionary[&"contents"] = _get_dir_contents(root_dir_dictionary)

	# Process the recieved dictionary, recursively again.
	_process_directory_contents(root_dir_dictionary)


func _get_dir_contents(dir_dictionary):
	var path = dir_dictionary[&"path"]
	var this_directory_contents = {}

	var dir := DirAccess.open(path)

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not file_name.begins_with("."): # Ignores hidden files
			if dir.current_is_dir() and not folders_to_ignore.has(file_name):
				var new_directory := {
					&"path" : path + file_name + "/",
					&"type": DIR_TYPE.FOLDER,
					&"contents": {},
					}
				new_directory[&"contents"] = _get_dir_contents(new_directory)
				this_directory_contents[file_name] = new_directory
			else:
				for suffix in filetypes_to_search:
					if file_name.ends_with(suffix):
						this_directory_contents[file_name] = {
							&"path": path,
							&"type": DIR_TYPE.FILE
						}
		file_name = dir.get_next()
	dir.list_dir_end()

	return this_directory_contents


## Searches through the file structure under res:// and builds a dictionary for
## processing
func _process_directory_contents(dir_dict, parent = null):
	# Iterate through each item in the directory dictionary
	for key in dir_dict[&"contents"]:
		var new_branch_parent = _build_branch(parent, key)
		if dir_dict[&"contents"][key][&"type"] == DIR_TYPE.FILE:
			_parse_file(dir_dict[&"path"], key, new_branch_parent)
			if new_branch_parent.get_child_count() == 0:
				new_branch_parent.free()
		elif dir_dict[&"contents"][key][&"type"] == DIR_TYPE.FOLDER:
			_process_directory_contents(
				dir_dict[&"contents"][key],
				new_branch_parent
				)
			if new_branch_parent.get_child_count() == 0:
				new_branch_parent.free()


## Parses a file line by line and finds intances of all queries' patterns.
func _parse_file(path, file_name, parent_tree_item):
	var file_path = path + file_name
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var line = file.get_line()
		var line_number = 1
		while not file.eof_reached():
			for query in query_list:
				if line.find(query) != -1:
					_create_line_leaf(
						parent_tree_item,
						line_number,
						line,
						file_name,
						query,
						file_path
						)
			line = file.get_line()
			line_number += 1
		file.close()


## Builds a leaf for the results_tree under the appropriate file branch.
func _create_line_leaf(parent, line_num, line,
		file_name, query, file_path) -> TreeItem:
	var child = results_tree.create_item(parent)
	child.set_custom_color(0, query_list[query])
	child.set_text(0, str(line_num) + ": " + query)
	child.set_tooltip_text(0, line)
	child.set_selectable(0, false)
	child.add_button(1, edit_btn_svg)
	child.set_meta("file_path", file_path)
	child.set_meta("line_num", line_num)
	child.set_meta("query", query)

	return child


## Builds a branch for the results_tree for files and directories.
func _build_branch(parent, folder_name) -> TreeItem:
	var new_branch_parent = results_tree.create_item(parent)
	new_branch_parent.set_text(0, folder_name)
	# new_branch_parent.set_tooltip_text(0, "test")
	new_branch_parent.set_selectable(0, false)
	new_branch_parent.set_custom_color(0, branch_color)
	return new_branch_parent
