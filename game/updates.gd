class_name Updates
extends Node
## Whether there's a newer version of the game than this one: asked of the game's own service
## (rooms/, which reads GitHub's latest release and keeps the answer for an hour), once a launch,
## on the title, in a real session, unless the player has turned it off. Nothing is downloaded or
## installed: the title only offers the page where the new builds are.

signal found(version: String, page: String)

## The game's service, by its address for the web rather than for rooms.
const SERVICE := "https://api.tall-order.felterra.games.itrium.id"

var _request: HTTPRequest


## Asks, once: `found` if there's a version newer than this one.
func check(service := SERVICE) -> void:
	if _request != null:
		return
	_request = HTTPRequest.new()
	_request.timeout = 10.0
	add_child(_request)
	_request.request_completed.connect(_answered)
	_request.request(service + "/latest")


func _answered(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or status != 200:
		return
	# Read quietly: an answer that isn't one is nothing to tell, not an error in the player's log.
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return
	var answer: Variant = json.data
	if not answer is Dictionary or not answer.get("version") is String or not answer.get("page") is String:
		return
	var mine: String = ProjectSettings.get_setting("application/config/version", "")
	if Online.older(mine, answer.version) and (answer.page as String).begins_with("https://"):
		found.emit(answer.version, answer.page)


## The web address of a rooms service given as a WebSocket one (wss://, or ws:// run locally).
static func web(rooms: String) -> String:
	return rooms.replace("wss://", "https://").replace("ws://", "http://")
