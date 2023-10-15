extends Control

var tags : Dictionary

func add_tags(new_tags : Dictionary):
	for new_tag in new_tags:
		var tag := StringName(new_tag)
		tags[tag] = {"how_many_entries_have_this_tag" : new_tags[tag]}

func _ready():
	if FileAccess.file_exists("user://tags"):
		tags = JSON.parse_string(FileAccess.get_file_as_string("user://tags"))

var selected_entry : Node:
	set(value):
		selected_entry = value
		_on_tag_input_text_changed("")

func _unhandled_input(event):
	if not self.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		self.visible = false

func _on_tag_input_text_changed(new_text : String):
	var new_tag := StringName(new_text.to_lower())
	for container in [%"global tag matches", %"entry tag matches"]:
		for child in container.get_children():
			child.queue_free()
	for tag in tags:
		if tag.begins_with(new_tag):
			var new_button := Button.new()
			new_button.text = tag
			%"global tag matches".add_child(new_button)
			new_button.pressed.connect(entry_add_tag.bind(tag))
	for tag in selected_entry.tags:
		if tag.begins_with(new_tag):
			var new_button := Button.new()
			new_button.text = tag
			%"entry tag matches".add_child(new_button)
			new_button.pressed.connect(entry_erase_tag.bind(tag))

func entry_erase_tag(tag : StringName):
	selected_entry.tags.erase(tag)
	selected_entry.save_to_file()
	%"tag input".text = ""
	tags[tag]["how_many_entries_have_this_tag"] -= 1
	save_to_file()
	_on_tag_input_text_changed("")

func entry_add_tag(new_tag : StringName):
	if not selected_entry.tags.has(new_tag):
		selected_entry.tags.append(new_tag)
		selected_entry.save_to_file()
	if not tags.has(new_tag):
		tags[new_tag] = {"how_many_entries_have_this_tag" : 1}
	else:
		tags[new_tag]["how_many_entries_have_this_tag"] += 1
	save_to_file()
	_on_tag_input_text_changed("")

func _on_tag_input_text_submitted(new_text : String):
	%"tag input".text = ""
	entry_add_tag(StringName(new_text.to_lower()))

func save_to_file():
	var file := FileAccess.open("user://tags", FileAccess.WRITE)
	file.store_string(JSON.stringify(tags))
