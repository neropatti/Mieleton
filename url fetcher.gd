extends Node

var active_web_requests : Dictionary = {}

func fetch_url(url : String) -> Array:
	if active_web_requests.has(url):
		print("Waiting on already existing request for \"%s\"" % url)
		var web_request : HTTPRequest = active_web_requests[url]
		return await web_request.request_completed
	var new_web_request := HTTPRequest.new()
	new_web_request.timeout = 20.0
	add_child(new_web_request)
	var err := new_web_request.request(url)
	if err != OK:
		print("Failed making a request for \"%s\" with the error %s" % [url, error_string(err)])
		return [err]
	print("Succesfully made a new request for \"%s\"" % url)
	active_web_requests[url] = new_web_request
	var request_result : Array = await new_web_request.request_completed
	active_web_requests.erase(url)
	new_web_request.queue_free()
	return request_result
