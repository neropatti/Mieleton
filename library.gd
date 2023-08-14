extends Control

var youtube_video_entry := preload("res://dl.tscn")

# TODO: Figure out what domain the link is from
# TODO: Do specific actions according to the domain

# I want to match youtube.com and www.youtube.com
# but for some domains, like app.element.com, the part before the main domain is important
# hmm

# I guess I can just have 2 entries on a dictionary that covers both XD

var domains : Dictionary = {
	"www.youtube.com" : youtube_video_entry,
	"youtube.com" : youtube_video_entry,
	"www.youtu.be" : youtube_video_entry, # (www.youtu.be is *not* a valid youtube link, including it here anyway)
	"youtu.be" : youtube_video_entry,
}

func _on_link_input_text_submitted(link : String):
#	print(link)
#	print(get_youtube_video_id(link))
	%"link input".text = ""
#	var new_video_entry := video_entry.instantiate()
#	%items.add_child(new_video_entry)
#	new_video_entry.set_video_id(get_youtube_video_id(link))
	
	link = trim_prefixes(link, ["https://", "http://"])
	if not domains.has(link):
		# TODO: Come up with a "generic link entry" that's used for everything w/o special logic :)
		# Maybe I actually just want to generically embed everything? Hmm
		return
	
	var new_entry = domains[link].instantiate()
	%items.add_child(new_entry)
	new_entry.set_link(link)

func trim_prefixes(string : String, prefixes : Array [String]) -> String:
	for prefix in prefixes:
		string = string.trim_prefix(prefix)
	return string
