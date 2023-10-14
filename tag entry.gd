extends Control

var tags : Array [StringName]
var selected_entry : Node

func _on_tag_input_text_changed(new_text : String):
	var new_tag := StringName(new_text.to_lower())
	var matches : Array [StringName]
	var matches2 : String = ""
	var matches3 : String = ""
	for tag in tags:
		if tag.begins_with(new_tag):
			matches.append(tag)
			matches2 += tag + "\n"
	for tag in selected_entry.tags:
		if tag.begins_with(new_tag):
			matches3 += tag + "\n"
	%"tag list".text = matches2
	%"existing tags".text = matches3

func _on_tag_input_text_submitted(new_text : String):
	%"tag input".text = ""
	var new_tag := StringName(new_text.to_lower())
	if not selected_entry.tags.has(new_tag):
		selected_entry.tags.append(new_tag)
		selected_entry.save_to_file()
	if not tags.has(new_tag):
		tags.append(new_tag)
		# TODO: Sort tags alphabetically/based on the amount of entries with that tag?
	
	_on_tag_input_text_changed("")
