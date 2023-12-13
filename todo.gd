extends Node
## The todo plugin examines all files under 'res://' and documents instances of
## 'TODO' and lists their location, and gives the line in the tooltip on hover.
##
## WIP Features
## Clicking on the file should open up the file at the line within preferred
## editor. Need to implement proper searching and item creating flow so the code
## structures the file tree properly.
##
## @experimental

enum DIR_TYPE { FOLDER, FILE }

var search_strings_array = ["TODO", "FIXME", "WORKAROUND", "WARNING"]
var filetypes_to_search = [".gd", ".txt"]
var folders_to_ignore = ["FolderA"]
var searchButton : Button
var results_tree : Tree
var tree_root : TreeItem

# Connect when ready to children and assign button signal.
# Run update tree on load, button allows for refreshing.
func _ready() -> void:
	searchButton = $VSplitContainer/RunBtn
	results_tree = $VSplitContainer/PanelContainer/ResultsTree
	searchButton.connect("pressed", _on_searchButton_pressed)
	update_tree()

func _on_searchButton_pressed():
	results_tree.clear()
	update_tree()

func update_tree():
	results_tree.clear()

	tree_root = results_tree.create_item()
	tree_root.set_text(0, "Files")

	var root_dir_dictionary = {
		&"path" : "res://",
		&"type": DIR_TYPE.FOLDER,
		&"contents": {}
		}

	# Recursive function, starts at root.
	root_dir_dictionary[&"contents"] = get_dir_contents(root_dir_dictionary)

	# Process the recieved dictionary, recursively again.
	process_directory_contents(root_dir_dictionary)

func get_dir_contents(dir_dictionary):
	var path = dir_dictionary[&"path"]
	var this_directory_contents = {}

	var dir := DirAccess.open(path)
	if dir:
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
					new_directory[&"contents"] = get_dir_contents(new_directory)
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
	else:
		print("An error occurred when trying to access the path: " + path)

	return this_directory_contents

func _parse_file(path, file_name, parent_tree_item):
	var file = FileAccess.open(path+file_name, FileAccess.READ)
	if file:
		var line = file.get_line()
		var line_number = 1
		while not file.eof_reached():
			for query in search_strings_array:
				if line.find(query) != -1:
					create_file_tree_item(parent_tree_item, line_number, line, file_name, query)
			line = file.get_line()
			line_number += 1
		file.close()

func process_directory_contents(dir_dict, parent = null):
	# Iterate through each item in the directory dictionary
	for key in dir_dict[&"contents"]:
		if dir_dict[&"contents"][key][&"type"] == DIR_TYPE.FILE:
			_parse_file(dir_dict[&"path"], key, parent)
		elif dir_dict[&"contents"][key][&"type"] == DIR_TYPE.FOLDER:
			var new_branch_parent = create_dir_tree_item(parent, key)
			process_directory_contents(dir_dict[&"contents"][key], new_branch_parent)

func create_file_tree_item(parent, line_num, line, file_name, query) -> TreeItem:
	var child = results_tree.create_item(parent)
	child.set_text(0, file_name + "  @ ln " + str(line_num) + ": " + query)
	child.set_tooltip_text(0, line)
	# TODO set child's on_selected to run EditorInterface.edit_script(file_name)
	# May need to also pass the file path into this function.
	return child

func create_dir_tree_item(parent, folder_name) -> TreeItem:
	var new_branch_parent = results_tree.create_item(parent)
	new_branch_parent.set_text(0, folder_name)
	new_branch_parent.set_tooltip_text(0, "test")
	new_branch_parent.set_selectable(0, false)
	return new_branch_parent
