extends Control

@onready var http_request : HTTPRequest = $HTTPRequest

func _ready():
	http_request.request("https://img.youtube.com/vi/gVC-nhVSH2c/hqdefault.jpg")

func _on_http_request_request_completed(result, response_code, headers, body : PackedByteArray):
	var a := FileAccess.open("res://test.jpg", FileAccess.WRITE)
	a.store_buffer(body)
	a.flush()
	var b := load_image_from_buffer(body)
	$TextureRect.texture = ImageTexture.create_from_image(b)

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
	
	return img
