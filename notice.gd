extends Control

func _ready():
	for label in [$"VBoxContainer/body/2", $"VBoxContainer/body/3"]:
		label.gui_input.connect(_on_label_gui_input.bind(label.text))

func _on_ok_pressed():
	
	if $"VBoxContainer/don't show again".button_pressed:
		var asd = FileAccess.open("user://disable notice 2", FileAccess.WRITE)
		asd.store_string(" ")
	
	self.queue_free()

func _on_label_gui_input(event, text : String):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				tidbits.link_left_click(text)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				tidbits.link_right_click(text)
