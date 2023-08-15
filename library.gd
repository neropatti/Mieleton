extends Control

var link_entry := preload("res://dl.tscn")

# TODO: Figure out what domain the link is from
# TODO: Do specific actions according to the domain

# I want to match youtube.com and www.youtube.com
# but for some domains, like app.element.com, the part before the main domain is important
# hmm

# I guess I can just have 2 entries on a dictionary that covers both XD


func _on_link_input_text_submitted(link : String):
#	print(link)
#	print(get_youtube_video_id(link))
	%"link input".text = ""
	var new_link_entry := link_entry.instantiate()
	%items.add_child(new_link_entry)
	new_link_entry.set_link(link)

func trim_prefixes(string : String, prefixes : Array [String]) -> String:
	for prefix in prefixes:
		string = string.trim_prefix(prefix)
	return string
