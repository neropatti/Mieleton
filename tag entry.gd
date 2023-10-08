extends Control

var tags : Array [StringName]

func _on_tag_input_text_changed(new_text : String):
	var new_tag := StringName(new_text.to_lower())
	var matches : Array [StringName]
	var matches2 : String = ""
	for tag in tags:
		if tag.begins_with(new_tag):
			matches.append(tag)
			matches2 += tag + "\n"
	$CenterContainer/VBoxContainer/Label.text = matches2
	print(matches)

func _on_tag_input_text_submitted(new_text : String):
	%"tag input".text = ""
	var new_tag := StringName(new_text.to_lower())
	if tags.has(new_tag):
		pass
	else:
		tags.append(new_tag)
	
	_on_tag_input_text_changed("")
