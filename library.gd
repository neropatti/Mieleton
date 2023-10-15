extends Control

var link_entry := preload("res://entry.tscn")

# Actually, we don't need to open the view for links we had open the last time..?
# Still probably a good idea to have timestamps on the links
# Also if someone has thousands of links, we don't want to just load them all to only show the most recent ones
# ALSO if someone has thousands of links with a certain tag, we don't want to load all of those either, probably
# How do you do this efficiently? XD
# I guess tag entries could be a separate thing..?
# OR
# Just make it work for now XDXDXD

# TODO: Assinging tags and doing basic search..?
# I guess we also do need to kind of just view the posts lol

# Make link entries a lightweight class thingy?
# Would allow jamming all the entries into memory that way (I mean I guess I can just do it with a dict lol)

# WELL, don't solve non-existant problems, make mistakes instead

func _ready():
	# TODO: Ditch the links file, just iterate over files in the "entries" directory instead :)
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
			all_tags[tag] = true
		var new_link_entry := link_entry.instantiate()
		%items.add_child(new_link_entry)
		new_link_entry.link = link
		print(title)
		new_link_entry.set_title(title)
		new_link_entry.set_thumbnail(thumbnail_link)
		new_link_entry.tags = tags
		new_link_entry.filename = file_name
		new_link_entry.clicked.connect(open_tag_editor)
	var xd : Array [StringName] = []
	for tag in all_tags.keys():
		xd.append(tag)
	%"tag entry".tags = xd

func _on_link_input_text_submitted(link : String):
	%"link input".text = ""
	var new_link_entry := link_entry.instantiate()
	new_link_entry.filename = str(int(Time.get_unix_time_from_system())) + "_" + str(randi())
	%items.add_child(new_link_entry)
	new_link_entry.set_link(link)
	new_link_entry.clicked.connect(open_tag_editor)

func trim_prefixes(string : String, prefixes : Array [String]) -> String:
	for prefix in prefixes:
		string = string.trim_prefix(prefix)
	return string

const save_path : String = "user://entries/"

func link_to_path(link : String) -> String:
	return save_path + link.replace("/", "_slash_")

func open_tag_editor(entry : Node):
	%"tag entry".visible = true
	%"tag entry".selected_entry = entry
