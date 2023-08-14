extends VBoxContainer

@onready var thumbnail_fetcher : HTTPRequest = $"thumbnail fetcher"

const video_thumbnail_url : String = "https://img.youtube.com/vi/%s/hqdefault.jpg"
var video_id : String = "gVC-nhVSH2c"

func set_link(link : String) -> bool:
	var video_id := get_video_id(link)
	set_video_id(video_id)
	return true

func get_video_id(link_or_id : String) -> String:
	link_or_id = trim_prefixes(link_or_id, ["www.", "youtube.com/watch?v=", "youtu.be/"])
	link_or_id = link_or_id.get_slice("&", 0)
	assert(link_or_id.length() == 11) # Youtube video IDs are 11 characters long
	return link_or_id

func trim_prefixes(string : String, prefixes : Array [String]) -> String:
	for prefix in prefixes:
		string = string.trim_prefix(prefix)
	return string

## Set the video ID and refresh things that depend on it (currently just the thumbnail)
func set_video_id(id : String):
	video_id = id
	refresh_thumbnail()

func set_video_title(title : String):
	%title.text = title
	%title.tooltip_text = title

## Fetch a new thumbnail
func refresh_thumbnail():
	thumbnail_fetcher.request(video_thumbnail_url % video_id)
	print("Request fired!")

func _on_thumbnail_fetcher_request_completed(result, response_code, _headers, body : PackedByteArray):
	if result != OK and response_code != 200:
		print("Failed to fetch new thumbnail!")
		return
	var b := load_image_from_buffer(body)
	%thumbnail.texture = ImageTexture.create_from_image(b)

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
