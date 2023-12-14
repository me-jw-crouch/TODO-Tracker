extends ColorPickerButton

# Custom signal with the linked LineEdit object
signal color_changed_with_line_edit(new_color, linked_line_edit)

# Property to store the linked LineEdit
@export var linked_line_edit: LineEdit

# Constructor to set the linked LineEdit and default color
func _init(_linked_line_edit: LineEdit):
	self.linked_line_edit = _linked_line_edit
	self.color = Color("WHITE")  # Set default color to white

func _ready():
	# Connect the color_changed signal of the internal ColorPicker
	get_picker().connect("color_changed", _on_ColorPicker_color_changed)

func _on_ColorPicker_color_changed(new_color: Color):
	# Emit the custom signal with the color and the linked LineEdit
	emit_signal("color_changed_with_line_edit", new_color, linked_line_edit.text)

# Method to set the linked LineEdit
func set_linked_line_edit(new_linked_line_edit: LineEdit):
	linked_line_edit = new_linked_line_edit
