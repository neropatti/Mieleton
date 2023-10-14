extends VBoxContainer

var tags : Array [StringName]

var link : String:
	set(value):
		var value_changed : bool = link != value
		link = value
		if value_changed:
			data_updated.emit()

var title : String:
	set(value):
		var value_changed : bool = title != value
		title = value
		if value_changed:
			data_updated.emit()

var thumbnail_link : String:
	set(value):
		var value_changed : bool = thumbnail_link != value
		thumbnail_link = value
		if value_changed:
			data_updated.emit()

signal data_updated

func set_link(new_link : String):
	link = new_link
	set_title(new_link)
	var request_result : Array = await UrlFetcher.fetch_url(new_link)
	_on_webpage_fetcher_request_completed(request_result[0], request_result[1], request_result[2], request_result[3])

func trim_prefixes(string : String, prefixes : Array [String]) -> String:
	for prefix in prefixes:
		string = string.trim_prefix(prefix)
	return string

func set_title(new_title : String):
	title = new_title
	%title.text = new_title
	%title.tooltip_text = new_title

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

func parse_webpage(body : PackedByteArray):
	
	var page : String = body.get_string_from_utf8()
	var f := FileAccess.open("user://asd.txt", FileAccess.WRITE)
	f.store_string(page)
	var info : Dictionary = {}
	
	var i : int = 0
	while true:
		i = page.find("<meta ", i)
		if i == -1:
			# There are no more meta tags on the page, break out of the loop
			break
		var i2 = page.find(">", i)
		if i2 == -1:
			printerr("Broken meta tag??")
			break
		var meta_tag = page.substr(i, i2 - i + 1)
		if not is_valid_meta_tag(meta_tag):
			# We don't care about these kinds of meta tags XD
			# OR
			# The tag is invalid somehow XD
			i += 1
			continue
		var tag_parts := parse_meta_tag(meta_tag)
		info[tag_parts[0]] = tag_parts[1]
		i += 1
	
#	print("Finished!")
#	print(info)
	
	if info.has("og:title"):
		set_title(info["og:title"])
	elif info.has("og:site_name"):
		set_title(info["og:site_name"])
	
	if info.has("og:image"):
		# TODO: Do some checks to see that this URL is valid
		# Potential security implications?
		set_thumbnail(info["og:image"])

func set_thumbnail(thumbnail_url : String):
		thumbnail_link = thumbnail_url
		# TODO: Do some checks to see that this URL is valid
		# Potential security implications?
		if Cache.has_cache_entry(thumbnail_link, "image"):
			var img_data : PackedByteArray = Cache.get_cache_entry(thumbnail_link)
			var img := load_image_from_buffer(img_data)
			var texture := ImageTexture.create_from_image(img)
			%thumbnail.texture = texture
		else:
			var request_result : Array = await UrlFetcher.fetch_url(thumbnail_link)
			if request_result[0] == OK:
				_on_thumbnail_fetcher_request_completed(request_result[0], request_result[1], request_result[2], request_result[3])

func is_valid_meta_tag(meta_tag : String) -> bool:
	if meta_tag.contains("property=\"") and meta_tag.contains("content=\""):
		return true
	else:
		return false

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

func parse_image(body : PackedByteArray):
	var img := load_image_from_buffer(body)
	if img == null or not is_instance_valid(img):
		return
	print("Img: %s" % img.get_size())
	Cache.create_cache_entry(thumbnail_link, img)
	var texture := ImageTexture.create_from_image(img)
	%thumbnail.texture = texture

func _on_webpage_fetcher_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray):
	print("Webpage headers: ", headers)
	if result != OK or response_code != 200:
		printerr("%s failed to load web data!" % self)
		return
	
	var content_type : int = -1
	
	for header in headers:
		if header.begins_with("Content-Type:"):
			if header.contains("text/html"):
				parse_webpage(body)
			elif header.contains("image"):
				thumbnail_link = link
				parse_image(body)
				var a : int = link.get_slice_count("/")
				set_title(link.get_slice("/", a - 1))
			else:
				printerr("Invalid/unhandled header: %s" % header)

func _on_thumbnail_fetcher_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray):
	for header in headers:
		if header.begins_with("Content-Type:"):
			if header.contains("text/html"):
				printerr("HTML page passed onto the thumbnail handler!")
			elif header.contains("image"):
				parse_image(body)
			else:
				printerr("Invalid/unhandled header: %s" % header)

func _ready():
	data_updated.connect(save_to_file)

const save_path : String = "user://entries/"

func save_to_file():
	# TODO: Just have a unique ID for each entry instead of saving based on the link
	# I might want to have duplicate entries or something :)
	
	# For the cache though, it makes sense to have no duplicates. XD
	
	var file := FileAccess.open(tidbits.link_to_path(link, save_path), FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"link" : link,
		"title" : title,
		"thumbnail_link" : thumbnail_link,
		"tags" : tags,
	}))
	print("SAVED")

signal clicked

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(self)
