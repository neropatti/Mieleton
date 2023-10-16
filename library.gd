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
	new_text = new_text.to_lower()
	for child in %"autofill suggestion list".get_children():
		child.queue_free()
	
	var all_tags : Array = %"entry editing".tags.keys()
	
	if new_text.is_empty():
		var tag_scores : Dictionary = {}
		var visible_entries_count : int = 0
		for tag in all_tags:
			tag_scores[tag] = 0 as int
		for entry in %items.get_children():
			if entry is library_entry:
				if not entry.visible:
					continue
				visible_entries_count += 1
				for tag in all_tags:
					if entry.tags.has(tag):
						tag_scores[tag] += 1
		var fifty_percent : float = visible_entries_count / 2.0
		for tag in all_tags:
			tag_scores[tag] = absf(tag_scores[tag] - fifty_percent)
		
		all_tags.sort_custom(sort_tags_based_on_how_well_they_split_the_population_in_half.bind(tag_scores))
	else:
		all_tags.sort_custom(tag_sort.bind(new_text))
	
	var positive_tags : Array [String]
	var negative_tags : Array [String]
	var neutral_tags : Array [String]
	
	for tag in all_tags:
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
	
	for tag in negative_tags:
		var new_button := state_cycling_button.new()
		%"autofill suggestion list".add_child(new_button)
		new_button.text = tag
		new_button.current_state = state_cycling_button.states.negative
		new_button.state_cycled.connect(add_tag_filter.bind(tag))
	
	for tag in neutral_tags:
		var new_button := state_cycling_button.new()
		%"autofill suggestion list".add_child(new_button)
		new_button.text = tag
		new_button.current_state = state_cycling_button.states.neutral
		new_button.state_cycled.connect(add_tag_filter.bind(tag))

var active_tag_filters : Dictionary

func add_tag_filter(state : state_cycling_button.states, tag : String):
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
