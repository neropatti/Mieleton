extends VBoxContainer
class_name library_entry

var tags : Array [String]

var locations : Array [String]
var title : String
var thumbnail_link : String

var thumbnail_texture : Texture2D

var filename : String

var score : float = 0.0:
	set(value):
		score = value
		%"score label".text = str(score)

signal data_updated
signal thumbnail_changed(new_texture : Texture2D)
signal title_changed(new_title : String)

func refresh_primary_link():
	var new_link : String = locations[0]
	set_title(new_link)
	if tidbits.is_valid_url(new_link):
		var request_result : Array = await UrlFetcher.fetch_url(new_link)
		if request_result[0] != OK or request_result[1] != 200:
			return
		_on_webpage_fetcher_request_completed(request_result[0], request_result[1], request_result[2], request_result[3])
	elif FileAccess.file_exists(new_link):
		var extension := new_link.get_extension()
		match extension:
			"png", "webp", "jpg", "jpeg":
				var img = Image.load_from_file(new_link)
				Cache.create_cache_entry(new_link, img)
				thumbnail_link = new_link
				save_to_file()
				%"thumbnail".texture = ImageTexture.create_from_image(img)

func set_title(new_title : String):
	title = new_title
	%title.text = new_title
	%title.tooltip_text = new_title
	data_updated.emit()
	title_changed.emit(new_title)

## Load an image from a PackedByteArray. Tries to parse the data as a JPG, PNG, WEBP, TGA & BMP image, returning the first one that succeeds.
func load_image_from_buffer(buffer : PackedByteArray) -> Image:
	var img = Image.new()
	var success : bool = false
	for load_function in [img.load_webp_from_buffer, img.load_png_from_buffer,
							img.load_jpg_from_buffer, img.load_tga_from_buffer,
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
		set_title(String(info["og:title"]).xml_unescape())
	elif info.has("og:site_name"):
		set_title(info["og:site_name"])
	
	if info.has("og:image"):
		# TODO: Do some checks to see that this URL is valid
		# Potential security implications?
		set_thumbnail(info["og:image"])

func set_thumbnail(thumbnail_url : String, update_data : bool = true):
	if not self.get_rect().intersects(get_viewport_rect()):
		# Hack to make loading the app faster :)
		await get_tree().create_timer(randf_range(1.0, 16.0)).timeout
	thumbnail_link = thumbnail_url
	if update_data: data_updated.emit()
	# TODO: Do some checks to see that this URL is valid
	# Potential security implications?
	if Cache.has_cache_entry(thumbnail_link, "image"):
		var img_data : PackedByteArray = Cache.get_cache_entry(thumbnail_link)
		var img := load_image_from_buffer(img_data)
		var orig_size = img.get_size()
		var new_size = orig_size / (orig_size[orig_size.max_axis_index()] / 640.0)
		# Smaller image size = less memory usage :)
		img.resize(new_size.x, new_size.y, Image.INTERPOLATE_CUBIC)
		var texture := ImageTexture.create_from_image(img)
		%thumbnail.texture = texture
		thumbnail_texture = texture
		thumbnail_changed.emit(texture)
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
	thumbnail_texture = texture
	thumbnail_changed.emit(texture)

func _on_webpage_fetcher_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray):
#	print("Webpage headers: ", headers)
	if result != OK or response_code != 200:
		printerr("%s failed to load web data!" % self)
		return
	
	var content_type : int = -1
	
	for header in headers:
		if header.begins_with("Content-Type:"):
			if header.contains("text/html"):
				parse_webpage(body)
			elif header.contains("image"):
				var link := locations[0]
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
				thumbnail_link = ""
				save_to_file()
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
	
	if filename.is_empty():
		return
	
	# For the cache though, it makes sense to have no duplicates. XD
	
	var file := FileAccess.open(save_path + filename, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"locations" : locations,
		"title" : title,
		"thumbnail_link" : thumbnail_link,
		"tags" : tags,
		"version" : 1,
	}))
	print("Saved \"%s\"" % title)

func delete_from_disk_and_queue_free():
	assert(not filename.is_empty())
	DirAccess.remove_absolute(save_path + filename)
	queue_free()

signal clicked

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(self)
