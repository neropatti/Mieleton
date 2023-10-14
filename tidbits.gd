class_name tidbits

static func link_to_path(link : String, folder_path : String) -> String:
	return folder_path + link.sha256_text()
