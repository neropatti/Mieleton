extends Control

var link_entry := preload("res://entry.tscn")

func _ready():
	var all_tags : Dictionary = {}
	for file_name in DirAccess.get_files_at("user://entries/"):
		assert(FileAccess.file_exists("user://entries/" + file_name))
		var entry := FileAccess.get_file_as_string("user://entries/" + file_name)
		var entry_data : Dictionary = JSON.parse_string(entry)
		var link : String = entry_data["link"]
		var title : String = entry_data["title"]
		var thumbnail_link : String = entry_data["thumbnail_link"]
		var _tags : Array = entry_data["tags"]
		var tags : Array [StringName]
		tags.resize(_tags.size())
		for i in tags.size():
			var tag := StringName(_tags[i])
			tags[i] = tag
			if not all_tags.has(tag):
				all_tags[tag] = 0
			all_tags[tag] += 1
		var new_link_entry := link_entry.instantiate()
		%items.add_child(new_link_entry)
		new_link_entry.link = link
		print(title)
		new_link_entry.set_title(title)
		new_link_entry.set_thumbnail(thumbnail_link)
		new_link_entry.tags = tags
		new_link_entry.filename = file_name
		new_link_entry.clicked.connect(open_tag_editor)
	%"entry editing".add_tags(all_tags)
	_on_link_input_text_changed("")

func _on_link_input_text_submitted(link : String):
	%"link input".text = ""
	var new_link_entry := link_entry.instantiate()
	new_link_entry.filename = str(int(Time.get_unix_time_from_system())) + "_" + str(randi())
	%items.add_child(new_link_entry)
	new_link_entry.set_link(link)
	new_link_entry.clicked.connect(open_tag_editor)
	_on_link_input_text_changed("")

func trim_prefixes(string : String, prefixes : Array [String]) -> String:
	for prefix in prefixes:
		string = string.trim_prefix(prefix)
	return string

const save_path : String = "user://entries/"

func link_to_path(link : String) -> String:
	return save_path + link.replace("/", "_slash_")

func open_tag_editor(entry : Node):
	%"entry editing".visible = true
	%"entry editing".selected_entry = entry

func _on_link_input_text_changed(new_text : String):
	for child in %"autofill suggestion list".get_children():
		child.queue_free()
	
	for tag in %"entry editing".tags:
		if active_tag_filters.has(tag):
			var new_button := CheckBox.new()
			%"autofill suggestion list".add_child(new_button)
			new_button.text = tag
			new_button.button_pressed = true
			new_button.toggled.connect(add_tag_filter.bind(tag))
	
	for tag in %"entry editing".tags:
		if active_tag_filters.has(tag):
			continue # This tag is already present earlier on the list
		if tag.begins_with(new_text):
			var new_button := CheckBox.new()
			%"autofill suggestion list".add_child(new_button)
			new_button.text = tag
			new_button.toggled.connect(add_tag_filter.bind(tag))

var active_tag_filters : Dictionary

func add_tag_filter(enabled : bool, tag : String):
	if enabled:
		active_tag_filters[tag] = true
	else:
		active_tag_filters.erase(tag)
	for entry in %items.get_children():
		entry.visible = true
		for tagg in active_tag_filters:
			if not entry.tags.has(tagg):
				entry.visible = false
				break
