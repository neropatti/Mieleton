extends VBoxContainer

var link : String

func set_link(new_link : String) -> bool:
	link = new_link
	%"webpage fetcher".request(new_link)
	return true

func trim_prefixes(string : String, prefixes : Array [String]) -> String:
	for prefix in prefixes:
		string = string.trim_prefix(prefix)
	return string

func set_title(title : String):
	%title.text = title
	%title.tooltip_text = title

## Load an image from a PackedByteArray. Tries to parse the data as a JPG, PNG, WEBP, TGA & BMP image, returning the first one that succeeds.
func load_image_from_buffer(buffer : PackedByteArray) -> Image:
	var img = Image.new()
	var success : bool = false
	for load_function in [img.load_jpg_from_buffer, img.load_png_from_buffer,
							img.load_webp_from_buffer, img.load_tga_from_buffer,
							img.load_bmp_from_buffer]:
		assert(load_function is Callable)
		var result : int = load_function.call(buffer)
		if result == OK:
			success = true
			break
	if success == false:
		return Image.load_from_file("res://icon.svg")
	assert(not img.is_empty())
	return img

func _on_webpage_fetcher_request_completed(result, response_code, headers, body : PackedByteArray):
	if result != OK or response_code != 200:
		printerr("Failed to load page at link %s" % link)
		return
	
	var page : String = body.get_string_from_utf8()
	var info : Dictionary = {}
	
	var i : int = 0
	while true:
		i = page.find("<meta property", i)
		print(i)
		if i == -1:
			break
		var i2 = page.find(">", i)
		if i2 == -1:
			break
		var meta_tag = page.substr(i, i2 - i + 1)
		parse_meta_tag(meta_tag)
		i += 1
	
	print("Finished!")
	

func parse_meta_tag(meta_tag : String) -> Array [String]:
	assert(meta_tag.begins_with("<meta "))
	assert(meta_tag.ends_with(">"))
	assert(meta_tag.count("<") == 1 and meta_tag.count(">") == 1)
	
	var i := meta_tag.find("property=\"")
	var i2 := meta_tag.find("\"", i + 10)
	assert(i != -1 and i2 != -1)
	var meta_property_name : String = meta_tag.substr(i + 10, i2 - i - 10)
	
	i = meta_tag.find("content=\"")
	i2 = meta_tag.find("\"", i + 9)
	assert(i != -1 and i2 != -1)
	var meta_content : String = meta_tag.substr(i + 9, i2 - i - 9)
	
	return [meta_property_name, meta_content]
