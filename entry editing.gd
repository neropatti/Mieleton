extends Control

var tags : Dictionary

func add_tags(new_tags : Dictionary):
	for new_tag in new_tags:
		var tag := StringName(new_tag)
		tags[tag] = {"how_many_entries_have_this_tag" : new_tags[tag]}

var selected_entry : library_entry:
	set(value):
		if value == null:
			return
		selected_entry = value
		%thumbnail.texture = value.thumbnail_texture
		%link.text = value.link
		%"name edit".text = value.title
		_on_tag_input_text_changed("")

func _unhandled_input(event):
	if not self.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		self.visible = false
		selected_entry = null

func sort_tags_based_on_how_many_entries_have_them(a : String, b : String, tag_dict : Dictionary):
	if tag_dict[a]["how_many_entries_have_this_tag"] > tag_dict[b]["how_many_entries_have_this_tag"]:
		return true
	else:
		return false

func _on_tag_input_text_changed(new_text : String):
	var new_tag := StringName(new_text.to_lower())
	for container in [%"global tag matches", %"entry tag matches"]:
		for child in container.get_children():
			child.queue_free()
	var tags_sorted : Array = tags.keys()
	var sort_callable : Callable = sort_tags_based_on_how_many_entries_have_them.bind(tags)
	tags_sorted.sort_custom(sort_callable)
	for tag in tags_sorted:
		if tag.begins_with(new_tag):
			if selected_entry.tags.has(tag):
				continue
			var new_button := Button.new()
			new_button.text = tag
			%"global tag matches".add_child(new_button)
			new_button.pressed.connect(entry_add_tag.bind(tag))
	selected_entry.tags.sort_custom(sort_callable)
	for tag in selected_entry.tags:
		if tag.begins_with(new_tag):
			var new_button := Button.new()
			new_button.text = tag
			%"entry tag matches".add_child(new_button)
			new_button.pressed.connect(entry_erase_tag.bind(tag))

func entry_erase_tag(tag : StringName):
	selected_entry.tags.erase(tag)
	selected_entry.save_to_file()
	tags[tag]["how_many_entries_have_this_tag"] -= 1
	save_to_file()
	%"tag input".text = ""
	%"tag input".grab_focus()
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
	%"tag input".text = ""
	%"tag input".grab_focus()
	_on_tag_input_text_changed("")

func _on_tag_input_text_submitted(new_text : String):
	%"tag input".text = ""
	entry_add_tag(StringName(new_text.to_lower()))

func save_to_file():
	var file := FileAccess.open("user://tags", FileAccess.WRITE)
	file.store_string(JSON.stringify(tags))

func _on_name_edit_text_submitted(new_text : String):
	if selected_entry == null:
		print("Selected entry is null?")
		return
	selected_entry.set_title(new_text)
	selected_entry.save_to_file()

func _on_name_edit_focus_exited():
	if selected_entry == null:
		print("Selected entry is null?")
		return
	selected_entry.set_title(%"name edit".text)
	selected_entry.save_to_file()

func _on_delete_entry_pressed():
	selected_entry.delete_from_disk_and_queue_free()
	selected_entry = null
	self.visible = false

func _on_exit_editing_mode_pressed():
	selected_entry = null
	self.visible = false

func entry_clicked(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					OS.shell_open(selected_entry.link)
				MOUSE_BUTTON_RIGHT:
					DisplayServer.clipboard_set(selected_entry.link)
