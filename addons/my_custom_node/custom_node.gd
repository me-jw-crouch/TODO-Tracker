@tool
extends EditorPlugin
## docstring

const EDITOR_ADDON = preload("res://addons/my_custom_node/todo.tscn")

@export var dockedScene : Node
@export var searchButton : Button
@export var resultsTree : Tree
var root : TreeItem
var falseRoot : TreeItem
var fileList : Dictionary

func _enter_tree() -> void:
	dockedScene = EDITOR_ADDON.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, dockedScene)
	searchButton = dockedScene.get_node("RunBtn")
	resultsTree = dockedScene.get_node("ResultsTree")
	searchButton.connect("pressed", _on_searchButton_pressed)
	update_tree()

func _exit_tree() -> void:
	remove_control_from_docks(dockedScene)
	dockedScene.free()

func _on_searchButton_pressed():
	print("dockedScene: " + dockedScene.to_string())
	print("RunBtn: " + searchButton.to_string())
	print("ResultsTree: " + resultsTree.to_string())
	resultsTree.clear()
	fileList = {}
	var dir = DirAccess.open("res://")

	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			if filename.ends_with(".gd"):
				_parse_file("res://" + filename, filename)
			filename = dir.get_next()
		dir.list_dir_end()

		update_tree()

func _parse_file(path, fileName):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var line = file.get_line()
		var line_number = 1
		while not file.eof_reached():
			if line.find("TODO") != -1:
				if not fileList.has(fileName):
					fileList[fileName] = {}
				fileList[fileName][line_number] = line
			line = file.get_line()
			line_number += 1
		file.close()

func update_tree():
	resultsTree.clear()

	# Create the root TreeItem ("model")
	var root = resultsTree.create_item()
	root.set_text(0, "root")

	# Create a subheading
	var file_branch = resultsTree.create_item(root)
	file_branch.set_text(0, "Files")
	file_branch.set_selectable(0, false)

	# Creates a sorted array of file names, so the tree
	# will have them added in alpha order.
	var file_array = []
	for file in fileList.keys():
		file_array.append(file)
		file_array.sort()

	if !file_array.empty():
		for file in file_array:
			create_tree_item(fileList[file], file_branch, file)

func create_tree_item(_item_dictionary, _parent_item, _file):
	var parent = resultsTree.create_item(_parent_item)
	parent.set_text(0, _file.to_string())

	for line in _item_dictionary:
		var child = resultsTree.create_item(parent)
		child.set_text(0, "Ln: " + line.key + ": " + line.value)
	#parent.set_tooltip(0, "this shows when you mouse hover over the item")
