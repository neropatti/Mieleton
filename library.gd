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
		%items.move_child(new_link_entry, 0)
		new_link_entry.link = link
		new_link_entry.set_title(title)
		new_link_entry.set_thumbnail(thumbnail_link)
		new_link_entry.tags = tags
		new_link_entry.filename = file_name
		new_link_entry.clicked.connect(open_tag_editor)
	%"entry editing".add_tags(all_tags)
	_on_link_input_text_changed("")

func _on_link_input_text_submitted(link : String):
	if link.is_empty():
		return
	%"link input".text = ""
	var new_link_entry := link_entry.instantiate()
	new_link_entry.filename = str(int(Time.get_unix_time_from_system())) + "_" + str(randi())
	%items.add_child(new_link_entry)
	%items.move_child(new_link_entry, 0)
	new_link_entry.set_link(link)
	new_link_entry.clicked.connect(open_tag_editor)
	_on_link_input_text_changed("")

const save_path : String = "user://entries/"

func link_to_path(link : String) -> String:
	return save_path + link.replace("/", "_slash_")

func open_tag_editor(entry : Node):
	%"entry editing".visible = true
	%"entry editing".selected_entry = entry

func tag_sort(a : String, b : String, search : String) -> bool:
	if a.similarity(search) + int(a.begins_with(search)) > b.similarity(search) + int(b.begins_with(search)):
		return true
	else:
		return false

func sort_tags_based_on_how_well_they_split_the_population_in_half(a : String, b : String, scores : Dictionary) -> bool:
	if scores[a] < scores[b]:
		return true
	else:
		return false

func _on_link_input_text_changed(new_text : String):
	%"refresh tags".disabled = true
	
	for child in %"autofill suggestion list".get_children():
		child.queue_free()
	
	var all_tags : Array = %"entry editing".tags.keys()
	var visible_entries := %items.get_children().filter(func only_visible_elements(entry : Node): return entry.visible)
	
	var visible_tags : Array = []
	
	for tag in all_tags:
		if active_tag_filters.has(tag):
			visible_tags.append(tag)
		else:
			for entry in visible_entries:
				if entry.tags.has(tag):
					visible_tags.append(tag)
					break
	
	if new_text.is_empty():
		var tag_scores : Dictionary = {}
		var visible_entries_count : int = 0
		for tag in visible_tags:
			tag_scores[tag] = 0 as int
		for entry in visible_entries:
			if entry is library_entry:
				visible_entries_count += 1
				for tag in visible_tags:
					if entry.tags.has(tag):
						tag_scores[tag] += 1
		var fifty_percent : float = visible_entries_count / 2.0
		for tag in visible_tags:
			tag_scores[tag] = absf(tag_scores[tag] - fifty_percent)
		
		visible_tags.sort_custom(sort_tags_based_on_how_well_they_split_the_population_in_half.bind(tag_scores))
	else:
		visible_tags.sort_custom(tag_sort.bind(new_text.to_lower()))
	
	var positive_tags : Array [String]
	var negative_tags : Array [String]
	var neutral_tags : Array [String]
	
	for tag in visible_tags:
		if active_tag_filters.has(tag):
			if active_tag_filters[tag] == true:
				positive_tags.append(tag)
			else:
				negative_tags.append(tag)
		else:
			neutral_tags.append(tag)
	
	for tag in positive_tags:
		var new_button := state_cycling_button.new()
		%"autofill suggestion list".add_child(new_button)
		new_button.text = tag
		new_button.current_state = state_cycling_button.states.positive
		new_button.state_cycled.connect(add_tag_filter.bind(tag))
		new_button.right_clicked.connect(edit_tag.bind(tag))
	
	for tag in negative_tags:
		var new_button := state_cycling_button.new()
		%"autofill suggestion list".add_child(new_button)
		new_button.text = tag
		new_button.current_state = state_cycling_button.states.negative
		new_button.state_cycled.connect(add_tag_filter.bind(tag))
		new_button.right_clicked.connect(edit_tag.bind(tag))
	
	for tag in neutral_tags:
		var new_button := state_cycling_button.new()
		%"autofill suggestion list".add_child(new_button)
		new_button.text = tag
		new_button.current_state = state_cycling_button.states.neutral
		new_button.state_cycled.connect(add_tag_filter.bind(tag))
		new_button.right_clicked.connect(edit_tag.bind(tag))
	
	print("Visible entries: %s" % visible_entries.size())
	
	if new_text.is_empty():
		visible_entries.sort_custom(sort_entries_based_on_filename)
	else:
		visible_entries.sort_custom(sort_entries_based_on_string_match.bind(new_text, new_text.to_lower()))
	
	for entry in visible_entries:
		%items.move_child(entry, 0)

func sort_entries_based_on_filename(a : library_entry, b : library_entry):
	if a.filename.naturalnocasecmp_to(b.filename) == -1:
		return true
	else:
		return false

func sort_entries_based_on_string_match(a : library_entry, b : library_entry, string : String, string_lower : String):
	var a_title := a.title.to_lower()
	var b_title := b.title.to_lower()
	var a_score : int = a_title.similarity(string_lower) + int(a_title.begins_with(string_lower)) + int(a.link.begins_with(string))
	var b_score : int = b_title.similarity(string_lower) + int(b_title.begins_with(string_lower)) + int(b.link.begins_with(string))
	if a_score < b_score:
		return true
	else:
		return false

var active_tag_filters : Dictionary

func add_tag_filter(state : state_cycling_button.states, tag : String):
	%"refresh tags".disabled = false
	match state:
		state_cycling_button.states.positive:
			active_tag_filters[tag] = true
		state_cycling_button.states.negative:
			active_tag_filters[tag] = false
		state_cycling_button.states.neutral:
			active_tag_filters.erase(tag)
	for entry in %items.get_children():
		entry.visible = true
		for tagg in active_tag_filters:
			if active_tag_filters[tagg] != entry.tags.has(tagg):
				# If this tag should be included and the entry does not have it, hide the entry.
				# If this tag should be excluded and the entry has it, hide the entry.
				entry.visible = false
				break

func edit_tag(tag : String):
	print("Edit tag: %s" % tag)

func _on_refresh_tags_pressed():
	_on_link_input_text_changed(%"link input".text)
