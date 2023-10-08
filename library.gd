extends Control

var link_entry := preload("res://dl.tscn")

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

var links_file : FileAccess

func _ready():
	if FileAccess.file_exists("user://links.txt"):
		print("Links file found!")
		var file := FileAccess.open("user://links.txt", FileAccess.READ)
		while file.get_position() < file.get_length():
			var link := file.get_line()
			# Maybe leave the loading part to dl.gd? lol
			var entry := FileAccess.open("user://entries/%s" % link.replace("/", "_slash_"), FileAccess.READ)
			entry.get_line()
			var title := entry.get_line()
			var thumbnail_link := entry.get_line()
			var tags : Array [StringName]
			while entry.get_position() < entry.get_length():
				tags.append(StringName(entry.get_line()))
			var new_link_entry := link_entry.instantiate()
			%items.add_child(new_link_entry)
			new_link_entry.link = link
			new_link_entry.set_title(title)
			new_link_entry.set_thumbnail(thumbnail_link)
			new_link_entry.tags = tags
	else:
		printerr("Links file NOT found!")
	
	links_file = FileAccess.open("user://links.txt", FileAccess.READ_WRITE)
	links_file.seek_end()

func _on_link_input_text_submitted(link : String):
	%"link input".text = ""
	links_file.store_line(link)
	links_file.flush()
	var new_link_entry := link_entry.instantiate()
	%items.add_child(new_link_entry)
	new_link_entry.set_link(link)

func trim_prefixes(string : String, prefixes : Array [String]) -> String:
	for prefix in prefixes:
		string = string.trim_prefix(prefix)
	return string

const save_path : String = "user://entries/"

func link_to_path(link : String) -> String:
	return save_path + link.replace("/", "_slash_")

