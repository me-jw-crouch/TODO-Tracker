class_name CustomColorPickerBtn
extends ColorPickerButton

# Custom signal with the linked LineEdit object
signal color_changed_with_line_edit(new_color, linked_line_edit)

# Property to store the linked LineEdit
@export var linked_line_edit: LineEdit


# Constructor to set the linked LineEdit and default color
func setup(linked_line_edit: LineEdit, new_color):
	self.linked_line_edit = linked_line_edit
	self.color = new_color  # Set default color to white


func _ready():
	# Connect the color_changed signal of the internal ColorPicker
	get_picker().connect("color_changed", _on_color_changed)


# Method to set the linked LineEdit
func set_linked_line_edit(new_linked_line_edit: LineEdit):
	# No need to reassign, update the existing property directly
	self.linked_line_edit = new_linked_line_edit


func _on_color_changed(new_color: Color):
	# Emit the custom signal with the color and the linked LineEdit's text
	emit_signal("color_changed_with_line_edit", new_color, linked_line_edit.text)
