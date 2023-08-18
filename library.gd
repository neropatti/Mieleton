extends Control

var link_entry := preload("res://dl.tscn")

func _ready():
	if FileAccess.file_exists("user://links.txt"):
		print("Links file found!")
		var file := FileAccess.open("user://links.txt", FileAccess.READ)
		while file.get_position() < file.get_length():
			var line := file.get_line()
			print(line)
	else:
		printerr("Links file NOT found!")
		
		var file := FileAccess.open("user://links.txt", FileAccess.WRITE)
		file.store_line("LOL")

func _on_link_input_text_submitted(link : String):
	%"link input".text = ""
	var new_link_entry := link_entry.instantiate()
	%items.add_child(new_link_entry)
	new_link_entry.set_link(link)

func trim_prefixes(string : String, prefixes : Array [String]) -> String:
	for prefix in prefixes:
		string = string.trim_prefix(prefix)
	return string
