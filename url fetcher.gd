extends Node

var active_web_requests : Dictionary = {}

func fetch_url(url : String) -> Array:
	if active_web_requests.has(url):
		var web_request : HTTPRequest = active_web_requests[url]
		return await web_request.request_completed
	var new_web_request := HTTPRequest.new()
	add_child(new_web_request)
	var err := new_web_request.request(url)
	if err != OK:
		return [err]
	active_web_requests[url] = new_web_request
	var request_result : Array = await new_web_request.request_completed
	active_web_requests.erase(url)
	new_web_request.queue_free()
	return request_result
