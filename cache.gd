extends Node

const cache_path : String = "user://web_cache/"

func _ready():
	DirAccess.make_dir_recursive_absolute(cache_path)
	DirAccess.make_dir_recursive_absolute("user://entries/")

func create_cache_entry(source_link : String, data) -> void:
	var save_path = tidbits.link_to_path(source_link, cache_path)
	var meta_file := FileAccess.open(save_path + "_meta", FileAccess.WRITE)
	if data is Image:
		meta_file.store_line("image")
		var err = data.save_webp(save_path, true)
		printt(error_string(err), save_path)
	else:
		meta_file.store_line("generic")
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		file.store_var(data)

func has_cache_entry(source_link : String, type : String = "") -> bool:
	var save_path = tidbits.link_to_path(source_link, cache_path)
	if FileAccess.file_exists(save_path) and FileAccess.file_exists(save_path + "_meta"):
		if type.is_empty():
			return true
		var meta_file := FileAccess.open(save_path + "_meta", FileAccess.READ)
		var file_type := meta_file.get_line()
		if file_type == type:
			return true
		else:
			return false
	else:
		return false

func get_cache_entry(source_link : String) -> PackedByteArray:
	var save_path := tidbits.link_to_path(source_link, cache_path)
	return FileAccess.get_file_as_bytes(save_path)
