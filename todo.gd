extends Node

var searchButton : Button
var resultsTree : Tree
var root : TreeItem
var falseRoot : TreeItem
var fileList : Dictionary
var directory_array : Array[String] = ["res://"]

func _ready() -> void: # Fully Working
	searchButton = $VSplitContainer/RunBtn
	resultsTree = $VSplitContainer/PanelContainer/ResultsTree
	searchButton.connect("pressed", _on_searchButton_pressed)
	update_tree()

func _on_searchButton_pressed():
	resultsTree.clear()
	update_tree()


func update_tree():
	# Reset anything that needs it
	directory_array = ["res://"]
	resultsTree.clear()

	# Search root directory, if any others are found, get_dir_contents(path)
	# will add them to directory_array, and will
	var dir_to_search = directory_array.pop_back()
	while dir_to_search != null:
		get_dir_contents(dir_to_search)
		dir_to_search = directory_array.pop_back()

	# Create the root of the Tree Node
	root = resultsTree.create_item()
	root.set_text(0, "Files")

	# Creates a sorted array of file names, so the tree
	# will have them added in alpha order.
	var file_array = []
	for file in fileList.keys():
		file_array.append(file)
		file_array.sort()

	for file in file_array:
		_parse_file(fileList[file][&"location"], file)
		create_tree_item(fileList[file], root, file)


# Takes a path, cycles through all items within (ignoring any hidden files/dirs)
# Adds directory to the search list, and adds files to the fileList dictionary
# for parsing later.
func get_dir_contents(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				directory_array.push_back(file_name) # Not caring about order.
			if not file_name.begins_with(".") and file_name.ends_with(".gd"):
				if not fileList.has(file_name):
					fileList[file_name] = {
						&"location" : dir.get_current_dir(),
					}
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		print(dir)


func _parse_file(path, fileName):
	var file = FileAccess.open(path+fileName, FileAccess.READ)
	if file:
		var line = file.get_line()
		var line_number = 1
		while not file.eof_reached():
			if line.find("TODO") != -1:
				fileList[fileName][line_number] = line
			line = file.get_line()
			line_number += 1
		file.close()


func create_tree_item(lines_from_file_dict, file_branch, fileName):
	var parent = resultsTree.create_item(file_branch)
	parent.set_text(0, fileName)
	parent.set_tooltip_text(0, lines_from_file_dict[&"location"])
	var keys_array = lines_from_file_dict.keys()

	for key in keys_array:
		if key is int:
			var child = resultsTree.create_item(parent)
			child.set_text(0, "Ln: " + str(key)  +" : lineValue" )
			child.set_tooltip_text(0, lines_from_file_dict[key])
