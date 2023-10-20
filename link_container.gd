extends HBoxContainer
class_name link_container

var text : String:
	set(value):
		text = value
		%Label.text = value
		%"text edit".text = value

@onready var delete_pressed : Signal = %delete.pressed

signal link_clicked(link : String)
signal link_changed(me : link_container)

func _on_label_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				OS.shell_open(text)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				DisplayServer.clipboard_set(text)

func _on_text_edit_text_submitted(new_text : String):
	%Label.visible = true
	%"text edit".visible = false
	if new_text == text:
		return
	text = new_text
	link_changed.emit(self)

func _on_text_edit_focus_exited():
	_on_text_edit_text_submitted(%"text edit".text)

func _on_edit_pressed():
	%Label.visible = false
	%"text edit".visible = true
	%"text edit".grab_focus()
