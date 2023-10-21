class_name tidbits

static func link_to_path(link : String, folder_path : String) -> String:
	return folder_path + link.sha256_text()

static func is_valid_url(link : String) -> bool:
	return link.begins_with("http://") or link.begins_with("https://")

static func link_left_click(link : String) -> void:
	if is_valid_url(link):
		OS.shell_open(link)
	else:
		OS.shell_show_in_file_manager(link)

static func link_right_click(link : String) -> void:
	DisplayServer.clipboard_set(link)
