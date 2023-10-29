extends Control

var tags : Dictionary

func add_tags(new_tags : Dictionary):
	for new_tag in new_tags:
		var tag := StringName(new_tag)
		tags[tag] = {"how_many_entries_have_this_tag" : new_tags[tag]}

var selected_entry : library_entry:
	set(value):
		if selected_entry != null:
			selected_entry.thumbnail_changed.disconnect(refresh_thumbnail)
		if value == null:
			selected_entry = value
			return
		selected_entry = value
		%thumbnail.texture = value.thumbnail_texture
		value.thumbnail_changed.connect(refresh_thumbnail)
		%"name edit".text = value.title
		for child in %"links".get_children():
			child.queue_free()
		for link in value.locations:
			add_link_label(link)
		_on_tag_input_text_changed("")

func refresh_thumbnail(new_thumbnail : Texture2D):
	%thumbnail.texture = new_thumbnail

func add_link_label(link : String):
	var link_object : link_container = preload("res://link_container.tscn").instantiate()
	link_object.text = link
	%"links".add_child(link_object)
	link_object.delete_pressed.connect(delete_link.bind(link_object))
	link_object.link_changed.connect(link_edited)

func link_edited(link : link_container):
	var index : int = link.get_index()
	selected_entry.locations[index] = link.text
	selected_entry.save_to_file()

func delete_link(link : link_container):
	selected_entry.locations.erase(link.text)
	link.queue_free()
	selected_entry.save_to_file()

func _ready():
	self.visibility_changed.connect(on_visibility_changed)

func on_visibility_changed():
	if self.visible:
		%"tag input".grab_focus()
	else:
		%"link input".grab_focus()

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
	var new_tag := new_text.to_lower()
	for container in [%"global tag matches", %"entry tag matches"]:
		for child in container.get_children():
			child.queue_free()
	
	var tag_scores : Dictionary = {}
	for tag in tags:
		tag_scores[tag] = 0 as int
	for entry in %items.get_children():
		if entry is library_entry:
			var valid_entry : bool = true
			for tag in selected_entry.tags:
				if not entry.tags.has(tag):
					valid_entry = false
					break
			if valid_entry:
				for tag in entry.tags:
					tag_scores[tag] += 1
	
	var tags_sorted : Array = tags.keys()
	var sort_callable : Callable = func(a : String, b : String):
		if tag_scores[a] == tag_scores[b]:
			return sort_tags_based_on_how_many_entries_have_them(a, b, tags)
		else:
			return tag_scores[a] > tag_scores[b]
#	var sort_callable : Callable = sort_tags_based_on_how_many_entries_have_them.bind(tags)
	tags_sorted.sort_custom(sort_callable)
	for tag in tags_sorted:
		if tag.contains(new_tag) or new_tag.is_empty():
			if selected_entry.tags.has(tag):
				continue
			var new_button := Button.new()
			new_button.text = tag + " (" + str(tags[tag]["how_many_entries_have_this_tag"]) + ")"
			%"global tag matches".add_child(new_button)
			new_button.pressed.connect(entry_add_tag.bind(tag))
	selected_entry.tags.sort_custom(sort_callable)
	for tag in selected_entry.tags:
		if tag.contains(new_tag) or new_tag.is_empty():
			var new_button := Button.new()
			new_button.text = tag + " (" + str(tags[tag]["how_many_entries_have_this_tag"]) + ")"
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
	if not tags.has(new_tag):
		tags[new_tag] = {"how_many_entries_have_this_tag" : 0}
	if not selected_entry.tags.has(new_tag):
		selected_entry.tags.append(new_tag)
		selected_entry.save_to_file()
		tags[new_tag]["how_many_entries_have_this_tag"] += 1
		save_to_file()
	if not Input.is_action_pressed("don't clear text field"):
		%"tag input".text = ""
	_on_tag_input_text_changed(%"tag input".text)
	%"tag input".grab_focus()

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

func _on_entry_link_input_text_submitted(new_text : String):
	selected_entry.locations.append(new_text)
	selected_entry.save_to_file()
	add_link_label(new_text)
	%"entry link input".text = ""
