extends Control

var link_entry := preload("res://entry.tscn")

func _ready():
	DisplayServer.window_set_drop_files_callback(_os_dropped_files)
	var all_tags : Dictionary = {}
	for file_name in DirAccess.get_files_at("user://entries/"):
		assert(FileAccess.file_exists("user://entries/" + file_name))
		var entry := FileAccess.get_file_as_string("user://entries/" + file_name)
		var entry_data : Dictionary = JSON.parse_string(entry)
		var data_version : int = 0 if not entry_data.has("version") else entry_data["version"]
		var locations : Array [String]
		if data_version == 0:
			# Legacy data format handling
			locations.append(entry_data["link"])
			if entry_data.has("alternative_links"):
				for link in entry_data["alternative_links"]:
					assert(link is String)
					locations.append(link)
		else:
			for location in entry_data["locations"]:
				locations.append(location)
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
		new_link_entry.locations = locations
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
	var new_link_entry : library_entry = link_entry.instantiate()
	new_link_entry.filename = str(int(Time.get_unix_time_from_system())) + "_" + str(randi())
	%items.add_child(new_link_entry)
	%items.move_child(new_link_entry, 0)
	new_link_entry.locations.insert(0, link)
	new_link_entry.refresh_primary_link()
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

var we_waiting : bool = false
var do_refresh_after_wait : bool = false

func _on_link_input_text_changed(new_text : String):
	if we_waiting:
		do_refresh_after_wait = true
		return
	
	we_waiting = true
	%"sort refresh wait timer".start()
	
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
	
	var positive_tags : Array [String] = []
	var negative_tags : Array [String] = []
	var neutral_tags : Array [String] = []
	
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
		# TODO: Calculate the scored multi-threaded? Hmm maybe
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
	var a_score : int = a_title.similarity(string_lower) + int(a_title.begins_with(string_lower))
	for location in a.locations:
		if location.begins_with(string):
			a_score += 1
			break
	var b_score : int = b_title.similarity(string_lower) + int(b_title.begins_with(string_lower))
	for location in b.locations:
		if location.begins_with(string):
			b_score += 1
			break
	if a_score == b_score:
		return sort_entries_based_on_filename(a, b)
	elif a_score < b_score:
		return true
	else:
		return false

var active_tag_filters : Dictionary

func add_tag_filter(state : state_cycling_button.states, tag : String):
	%"link input".text = ""
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

func _on_sort_refresh_wait_timer_timeout():
	we_waiting = false
	if do_refresh_after_wait:
		_on_link_input_text_changed(%"link input".text)
	do_refresh_after_wait = false

func _os_dropped_files(files : PackedStringArray):
	# TODO: Display warning when dropping an absurd amount of files
	# And require user confirmation :)
	if %"entry editing".visible:
		for file_path in files:
			%"entry editing"._on_entry_link_input_text_submitted(file_path)
	else:
		for file_path in files:
			_on_link_input_text_submitted(file_path)
